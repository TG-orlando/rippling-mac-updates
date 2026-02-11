#!/bin/bash

# Mac Application Updater for Rippling MDM
# Automatically installs Homebrew and updates all managed applications
# Designed for unattended execution via MDM

set -euo pipefail

# Configuration
SCRIPT_NAME="mac-app-updater"
LOG_DIR="/var/log/rippling"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
MAX_RETRIES=3
APP_CLOSE_TIMEOUT=30

# Applications to manage (add/remove as needed)
APPS=(
    "Firefox"
    "Rectangle"
    "1Password"
    "Slack"
    "Brave Browser"
    "Google Chrome"
    "zoom.us"
    "Microsoft Excel"
    "Microsoft OneNote"
    "Microsoft Outlook"
    "Microsoft PowerPoint"
    "Microsoft Word"
)

# Initialize logging
init_log() {
    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="/tmp"
        LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
    fi

    {
        echo "=== Mac Application Updater ==="
        echo "Started: $(date)"
        echo "User: $(whoami)"
        echo "EUID: $EUID"
        echo "=============================="
    } > "$LOG_FILE" 2>&1
}

# Logging function
log() {
    local level="${2:-INFO}"
    local message="$(date '+%Y-%m-%d %H:%M:%S') [$level] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

# Error handler
error_exit() {
    log "ERROR: $1" "ERROR"
    exit "${2:-1}"
}

# Find Homebrew installation
find_homebrew() {
    local search_paths=(
        "/opt/homebrew/bin/brew"
        "/usr/local/bin/brew"
        "/home/linuxbrew/.linuxbrew/bin/brew"
    )

    # Check command -v first
    if command -v brew >/dev/null 2>&1; then
        command -v brew
        return 0
    fi

    # Check common paths
    for path in "${search_paths[@]}"; do
        if [[ -x "$path" ]]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

# Install Homebrew (non-interactive)
install_homebrew() {
    log "Homebrew not found. Installing..."

    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "Cannot install Homebrew as root. Please run as regular user." 1
    fi

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        error_exit "curl is required but not found" 1
    fi

    log "Downloading Homebrew installer..."

    # Non-interactive installation
    if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")" 2>&1 | tee -a "$LOG_FILE"; then
        error_exit "Homebrew installation failed" 1
    fi

    # Wait for installation to complete
    sleep 5

    # Find newly installed Homebrew
    local brew_path
    if brew_path=$(find_homebrew); then
        log "Homebrew installed successfully at: $brew_path"
        echo "$brew_path"
        return 0
    else
        error_exit "Homebrew installation completed but brew command not found" 1
    fi
}

# Get currently running applications
get_running_apps() {
    local running_apps=()

    log "Detecting running applications..."

    for app in "${APPS[@]}"; do
        # Check multiple ways to ensure we catch the app
        if pgrep -xq "$app" 2>/dev/null || \
           pgrep -fiq "$app" 2>/dev/null || \
           ps aux | grep -v grep | grep -iq "$app" 2>/dev/null; then
            running_apps+=("$app")
            log "  Found running: $app"
        fi
    done

    printf '%s\n' "${running_apps[@]}"
}

# Close applications gracefully
close_applications() {
    local apps_to_close=("$@")

    if [[ ${#apps_to_close[@]} -eq 0 ]]; then
        log "No applications to close"
        return 0
    fi

    log "Closing ${#apps_to_close[@]} applications..."

    for app in "${apps_to_close[@]}"; do
        log "Closing: $app"

        # Get current user for osascript
        local current_user
        current_user=$(stat -f%Su /dev/console 2>/dev/null || echo "${USER:-root}")

        # Try graceful quit first (as the console user)
        if [[ -n "$current_user" ]] && [[ "$current_user" != "root" ]]; then
            # Try with sudo if we're running as root, otherwise run directly
            if [[ $EUID -eq 0 ]]; then
                sudo -n -u "$current_user" osascript -e "tell application \"$app\" to quit" 2>/dev/null || true
            else
                osascript -e "tell application \"$app\" to quit" 2>/dev/null || true
            fi
            sleep 3
        fi

        # If still running, use killall
        if pgrep -xq "$app" 2>/dev/null || pgrep -fiq "$app" 2>/dev/null; then
            killall "$app" 2>/dev/null || true
            sleep 2
        fi

        # Force kill if still running
        if pgrep -xq "$app" 2>/dev/null || pgrep -fiq "$app" 2>/dev/null; then
            killall -9 "$app" 2>/dev/null || true
            sleep 1
        fi

        log "  Closed: $app"
    done
}

# Reopen applications
reopen_applications() {
    local apps_to_reopen=("$@")

    if [[ ${#apps_to_reopen[@]} -eq 0 ]]; then
        return 0
    fi

    log "Reopening applications..."
    sleep 3

    # Get current console user
    local current_user
    current_user=$(stat -f%Su /dev/console 2>/dev/null || echo "${USER:-root}")

    for app in "${apps_to_reopen[@]}"; do
        log "  Reopening: $app"

        if [[ -n "$current_user" ]] && [[ "$current_user" != "root" ]]; then
            # Try with sudo if we're running as root, otherwise run directly
            if [[ $EUID -eq 0 ]]; then
                sudo -n -u "$current_user" open -a "$app" 2>/dev/null || log "  Failed to reopen: $app" "WARN"
            else
                open -a "$app" 2>/dev/null || log "  Failed to reopen: $app" "WARN"
            fi
        else
            open -a "$app" 2>/dev/null || log "  Failed to reopen: $app" "WARN"
        fi

        sleep 2
    done
}

# Update via Homebrew
update_homebrew() {
    local brew_path="$1"

    log "Starting Homebrew updates..."

    # Ensure brew is in PATH
    local brew_dir
    brew_dir=$(dirname "$brew_path")
    export PATH="$brew_dir:$PATH"

    # Update Homebrew
    log "Updating Homebrew..."
    if ! "$brew_path" update 2>&1 | tee -a "$LOG_FILE"; then
        log "Homebrew update failed, continuing anyway..." "WARN"
    fi

    # Upgrade casks (applications)
    log "Upgrading applications..."
    if ! "$brew_path" upgrade --cask --greedy 2>&1 | tee -a "$LOG_FILE"; then
        log "Some applications failed to upgrade" "WARN"
    fi

    # Upgrade formulas
    log "Upgrading packages..."
    if ! "$brew_path" upgrade 2>&1 | tee -a "$LOG_FILE"; then
        log "Some packages failed to upgrade" "WARN"
    fi

    # Cleanup
    log "Cleaning up..."
    "$brew_path" cleanup 2>&1 | tee -a "$LOG_FILE" || true

    log "Homebrew updates completed"
}

# Main execution
main() {
    init_log

    log "=== Mac Application Updater Started ==="

    # Step 1: Ensure Homebrew is installed
    log "Step 1: Checking Homebrew installation"
    local brew_path
    if ! brew_path=$(find_homebrew); then
        brew_path=$(install_homebrew)
    else
        log "Homebrew found at: $brew_path"
    fi

    # Step 2: Detect running applications
    log "Step 2: Detecting running applications"
    local running_apps=()
    while IFS= read -r app; do
        [[ -n "$app" ]] && running_apps+=("$app")
    done < <(get_running_apps)

    if [[ ${#running_apps[@]} -gt 0 ]]; then
        log "Found ${#running_apps[@]} running applications"

        # Step 3: Close applications
        log "Step 3: Closing applications"
        close_applications "${running_apps[@]}"
    else
        log "No applications currently running"
    fi

    # Step 4: Update applications
    log "Step 4: Updating applications via Homebrew"
    update_homebrew "$brew_path"

    # Step 5: Reopen applications
    if [[ ${#running_apps[@]} -gt 0 ]]; then
        log "Step 5: Reopening applications"
        reopen_applications "${running_apps[@]}"
    fi

    log "=== Mac Application Updater Completed Successfully ==="
    log "Full log: $LOG_FILE"

    exit 0
}

# Cleanup on exit
trap 'echo "Script interrupted or failed" >&2; exit 1' ERR INT TERM

# Run main function
main "$@"
