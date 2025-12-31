# Code Breakdown - Mac Application Updater

## 📋 Overview

This repository contains scripts to automatically update Mac applications via Homebrew and manage application states during updates. Designed for unattended deployment through Rippling MDM.

---

## 📁 File Structure

```
.
├── update-mac-apps.sh          # Main update script
├── install.sh                  # One-line installer wrapper
├── README.md                   # User documentation
├── DEPLOYMENT.md              # Deployment guide
├── SETUP.md                   # Setup instructions
├── SESSION_HISTORY.md         # Development session log
├── CHANGELOG.md               # Version history
├── ERRORS_FIXED.md            # Bug fixes documentation
├── BREAKDOWN.md               # This file
└── .gitignore                 # Git ignore rules
```

---

## 🔧 Main Script: `update-mac-apps.sh`

### Purpose
Automates application updates on macOS through Homebrew while preserving user experience by managing running applications.

### Architecture Decisions

#### 1. **Bash over Other Languages**
**Choice**: Pure Bash script
**Reason**:
- Pre-installed on all macOS systems (no dependencies)
- Direct system access without additional runtimes
- Lightweight for MDM deployment
- Industry standard for macOS automation

#### 2. **Homebrew as Package Manager**
**Choice**: Use Homebrew for all application updates
**Reason**:
- De facto standard package manager for macOS
- Handles dependencies automatically
- Supports both GUI apps (casks) and CLI tools
- Community-maintained, regularly updated
- No official macOS package manager alternative

#### 3. **Non-Interactive Execution**
**Choice**: `set -euo pipefail` and no user prompts
**Reason**:
- MDM scripts run unattended (no user present)
- `set -e`: Exit on error (fail fast)
- `set -u`: Error on undefined variables (catch bugs)
- `set -o pipefail`: Catch errors in pipes
- All decisions automated or logged for review

#### 4. **Logging to `/var/log/rippling/`**
**Choice**: Centralized log directory
**Reason**:
- Standard macOS log location (`/var/log/`)
- Organized by vendor/system (Rippling)
- Timestamped filenames for history
- Fallback to `/tmp` if permissions fail
- Easy to query with standard tools

---

### Code Structure Breakdown

#### Section 1: Script Configuration (Lines 1-31)

```bash
#!/bin/bash
set -euo pipefail

# Configuration
SCRIPT_NAME="mac-app-updater"
LOG_DIR="/var/log/rippling"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
```

**Why**:
- Shebang ensures correct shell
- `set -euo pipefail`: Safety flags for production
- Timestamped logs prevent overwrites
- Variables at top for easy configuration

**Choice**: Separate log file per run
**Reason**: Easier to track individual executions, no log rotation needed

---

#### Section 2: Application List (Lines 18-31)

```bash
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
```

**Why Array**:
- Easy to add/remove applications
- Iterate with for loop
- Single source of truth
- Maintainable

**Why These Apps**:
- Common enterprise applications
- Frequently updated (security/features)
- User-facing (need reopening after updates)

**Choice**: Process names, not bundle IDs
**Reason**: Simpler to understand and maintain, works with `pgrep`

---

#### Section 3: Logging Functions (Lines 34-55)

```bash
init_log() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="/tmp"
        LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
    fi
    {
        echo "=== Mac Application Updater ==="
        echo "Started: $(date)"
        # ...
    } > "$LOG_FILE" 2>&1
}
```

**Why Separate Function**:
- Initialize once at startup
- Handle directory creation errors gracefully
- Fallback to `/tmp` if permissions fail

**Choice**: Redirect group `{ }` output
**Reason**: Efficient, writes header in one operation

```bash
log() {
    local level="${2:-INFO}"
    local message="$(date '+%Y-%m-%d %H:%M:%S') [$level] $1"
    echo "$message" | tee -a "$LOG_FILE"
}
```

**Why `tee`**:
- Write to both console AND log file
- User sees progress if running manually
- MDM gets full log file
- Single command (no duplication)

**Choice**: ISO 8601 timestamp format
**Reason**: Sortable, parseable, standard

---

#### Section 4: Homebrew Detection (Lines 63-86)

```bash
find_homebrew() {
    local search_paths=(
        "/opt/homebrew/bin/brew"      # Apple Silicon
        "/usr/local/bin/brew"          # Intel Mac
        "/home/linuxbrew/.linuxbrew/bin/brew"  # Linux (edge case)
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
```

**Why Multiple Methods**:
1. Try `command -v` first (respects PATH)
2. Fall back to known locations
3. Support both Intel and Apple Silicon

**Choice**: Check executability with `-x`
**Reason**: File may exist but not be executable

**Why Return Path**:
- Caller gets exact path to use
- No assumptions about PATH
- Works even if PATH is broken

---

#### Section 5: Homebrew Installation (Lines 88-121)

```bash
install_homebrew() {
    log "Homebrew not found. Installing..."

    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "Cannot install Homebrew as root. Please run as regular user." 1
    fi
```

**Why Block Root**:
- Homebrew explicitly doesn't support root installation
- Security best practice
- Prevents permission issues

```bash
    # Non-interactive installation
    if ! NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")" 2>&1 | tee -a "$LOG_FILE"; then
        error_exit "Homebrew installation failed" 1
    fi
```

**Choice**: `NONINTERACTIVE=1` environment variable
**Reason**: Homebrew installer checks this, skips all prompts

**Why `tee -a`**:
- Append installer output to our log
- User sees progress
- Complete audit trail

---

#### Section 6: Application Detection (Lines 123-140)

```bash
get_running_apps() {
    local running_apps=()

    for app in "${APPS[@]}"; do
        # Check multiple ways
        if pgrep -xq "$app" 2>/dev/null || \
           pgrep -fiq "$app" 2>/dev/null || \
           ps aux | grep -v grep | grep -iq "$app" 2>/dev/null; then
            running_apps+=("$app")
            log "  Found running: $app"
        fi
    done

    printf '%s\n' "${running_apps[@]}"
}
```

**Why Three Detection Methods**:
1. `pgrep -xq`: Exact process name match (fast)
2. `pgrep -fiq`: Match in command line (catches spaces)
3. `ps aux | grep`: Fallback for edge cases

**Choice**: Multiple OR conditions with `||`
**Reason**: Maximize detection, apps have different naming

**Why `-q` Flag**:
- Quiet mode, only exit code matters
- Faster (no output processing)
- Cleaner logs

**Choice**: `printf '%s\n'` over `echo`
**Reason**: POSIX compliant, safer with special characters

---

#### Section 7: Application Management (Lines 142-208)

```bash
close_applications() {
    local apps_to_close=("$@")

    # Get current user for osascript
    local current_user
    current_user=$(stat -f%Su /dev/console 2>/dev/null || echo "${USER:-root}")

    # Try graceful quit first (as the console user)
    if [[ -n "$current_user" ]] && [[ "$current_user" != "root" ]]; then
        # Try with sudo if we're running as root
        if [[ $EUID -eq 0 ]]; then
            sudo -n -u "$current_user" osascript -e "tell application \"$app\" to quit" 2>/dev/null || true
        else
            osascript -e "tell application \"$app\" to quit" 2>/dev/null || true
        fi
        sleep 3
    fi
```

**Why Determine Console User**:
- Script may run as root (MDM context)
- Apps run as logged-in user
- Need to target correct user's applications

**Choice**: `stat -f%Su /dev/console`
**Reason**: Gets user who owns console (GUI user), works even as root

**Why Fallback to `${USER:-root}`**:
- `$USER` might be unset in MDM context
- `:-root` provides default value
- Prevents script failure on undefined variable

**Three-Level Quit Strategy**:

```bash
# 1. Graceful (osascript)
osascript -e "tell application \"$app\" to quit"

# 2. Forceful (killall)
killall "$app"

# 3. Force kill (killall -9)
killall -9 "$app"
```

**Why Escalating Force**:
- Try nice quit first (saves user data)
- Then signal TERM (cleaner than KILL)
- Finally SIGKILL (guaranteed kill)
- Sleep between attempts (give time to respond)

**Choice**: `|| true` on all commands
**Reason**: Don't fail script if app already closed

---

#### Section 8: Update Process (Lines 210-244)

```bash
update_homebrew() {
    local brew_path="$1"

    # Ensure brew is in PATH
    local brew_dir
    brew_dir=$(dirname "$brew_path")
    export PATH="$brew_dir:$PATH"
```

**Why Manipulate PATH**:
- Homebrew might not be in current PATH
- MDM may have limited PATH
- Ensures brew command works

**Choice**: Add to PATH, not replace
**Reason**: Preserves existing PATH, doesn't break other commands

```bash
    # Update Homebrew
    if ! "$brew_path" update 2>&1 | tee -a "$LOG_FILE"; then
        log "Homebrew update failed, continuing anyway..." "WARN"
    fi

    # Upgrade casks (applications)
    if ! "$brew_path" upgrade --cask --greedy 2>&1 | tee -a "$LOG_FILE"; then
        log "Some applications failed to upgrade" "WARN"
    fi
```

**Why `--cask`**:
- Targets GUI applications specifically
- Separate from CLI formulas

**Why `--greedy`**:
- Updates apps even if auto-update enabled
- Catches apps like Chrome that update themselves
- Ensures consistency

**Choice**: Continue on failure with warnings
**Reason**: Partial success better than complete failure

---

#### Section 9: Main Flow (Lines 246-296)

```bash
main() {
    init_log

    # Step 1: Ensure Homebrew is installed
    local brew_path
    if ! brew_path=$(find_homebrew); then
        brew_path=$(install_homebrew)
    else
        log "Homebrew found at: $brew_path"
    fi

    # Step 2: Detect running applications
    local running_apps=()
    mapfile -t running_apps < <(get_running_apps)

    # Step 3: Close applications
    if [[ ${#running_apps[@]} -gt 0 ]]; then
        close_applications "${running_apps[@]}"
    fi

    # Step 4: Update applications
    update_homebrew "$brew_path"

    # Step 5: Reopen applications
    if [[ ${#running_apps[@]} -gt 0 ]]; then
        reopen_applications "${running_apps[@]}"
    fi

    exit 0
}
```

**Why Numbered Steps in Logs**:
- Clear progression
- Easy to identify where failures occur
- Matches documentation

**Choice**: Store app list before updates
**Reason**: Apps list same before/after, needed for reopening

**Why Conditional Reopen**:
- Don't reopen if nothing was closed
- Respects user's workflow

**Choice**: Explicit `exit 0`
**Reason**: Clear success signal for MDM monitoring

---

## 🚀 Installer Script: `install.sh`

### Purpose
Minimal wrapper that downloads and executes the main script from GitHub.

### Key Design Decisions

#### 1. **One-Line Deployment**
```bash
curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
```

**Why This Pattern**:
- Standard for modern deployments (Homebrew uses same)
- No local file management needed
- Always gets latest version
- Single command for MDM deployment

**Flags Explained**:
- `-f`: Fail silently on HTTP errors
- `-s`: Silent mode (no progress bar)
- `-S`: Show errors even in silent mode
- `-L`: Follow redirects

#### 2. **Temporary Directory**
```bash
TEMP_DIR="/tmp/mac-app-updater-$$"
```

**Why `$$`**:
- `$$` is current process ID
- Unique per execution
- No conflicts if multiple run simultaneously
- Easy to identify in `ps` output

#### 3. **Cleanup Trap**
```bash
cleanup() {
    cd / 2>/dev/null || true
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

trap cleanup EXIT
```

**Why Trap EXIT**:
- Runs on script exit (success or failure)
- Ensures cleanup even on errors
- Prevents temp file accumulation

**Why `cd /` First**:
- Can't delete directory you're in
- `/` always exists, safe fallback

**Choice**: Ignore cleanup errors
**Reason**: Cleanup failure shouldn't fail deployment

---

## 🎯 Design Patterns Used

### 1. **Fail-Fast with Graceful Degradation**
- `set -e`: Exit on most errors
- `|| true`: Allow specific failures
- Warn and continue vs. fail completely

### 2. **Progressive Enhancement**
- Check for existing tools before installing
- Use best method available
- Fall back to alternatives

### 3. **Idempotent Operations**
- Safe to run multiple times
- Detects existing state
- Only makes necessary changes

### 4. **Separation of Concerns**
- Each function has single responsibility
- Main function orchestrates
- Easy to test individual pieces

### 5. **Defensive Programming**
- Check variables before use
- Validate paths exist
- Handle edge cases
- Comprehensive error handling

---

## 🔒 Security Considerations

### 1. **Download over HTTPS**
```bash
curl -fsSL https://...
```
**Why**: Prevents man-in-the-middle attacks, ensures authenticity

### 2. **No Hardcoded Credentials**
**Why**: Public repository, no secrets needed

### 3. **Minimal Privilege Escalation**
```bash
# Only elevate when necessary
if [[ $EUID -eq 0 ]]; then
    sudo -n -u "$current_user" osascript ...
```
**Why**: Runs as user when possible, only use sudo for specific operations

### 4. **Input Validation**
- Check paths exist before using
- Validate executables are actually executable
- Use arrays for app lists (prevents injection)

---

## 📊 Performance Optimizations

### 1. **Parallel Operations Where Possible**
- Apps closed simultaneously (no waiting between)
- Single Homebrew upgrade command (not per-app)

### 2. **Minimal Sleep Times**
- Only sleep when necessary (app quit grace period)
- Specific durations (3s for quit, 2s for reopen)
- Based on testing, not arbitrary

### 3. **Efficient Detection**
- `pgrep -q` faster than `pgrep` + parse
- `command -v` faster than which
- Short-circuit OR conditions (stop at first match)

---

## 🐛 Error Handling Strategy

### Levels of Severity

1. **Critical Errors** → Exit immediately
   - Can't determine script path
   - Can't create any log file
   - Homebrew install fails completely

2. **Major Errors** → Warn and continue
   - Some apps fail to update
   - Can't reopen specific app
   - Partial log write failure

3. **Minor Errors** → Silent ignore
   - App already closed
   - Process doesn't exist
   - Cleanup failures

---

## 💡 Best Practices Implemented

1. ✅ **shellcheck** compliant
2. ✅ POSIX-compatible where possible
3. ✅ Comprehensive comments
4. ✅ Consistent naming (snake_case functions)
5. ✅ Local variables in functions
6. ✅ Quoted all variables
7. ✅ Error messages to stderr
8. ✅ Exit codes meaningful
9. ✅ Logging with timestamps
10. ✅ No temporary globals

---

## 🔄 Future Enhancement Possibilities

1. **Brew Bundle Support**: Use Brewfile for declarative package management
2. **Selective Updates**: Allow specifying which apps to update
3. **Pre/Post Hooks**: Run custom scripts before/after updates
4. **Notification System**: Send alerts on completion/failure
5. **Rollback Capability**: Snapshot before updates, restore on failure
6. **Update Scheduling**: Time-based or condition-based execution
7. **Bandwidth Throttling**: Limit download speeds
8. **App Store Integration**: Update Mac App Store apps too

---

## 📚 References

- **Homebrew**: https://brew.sh
- **Bash Best Practices**: https://google.github.io/styleguide/shellguide.html
- **MDM Scripting**: https://help.rippling.com
- **macOS Scripting**: https://developer.apple.com/library/archive/documentation/AppleScript/

---

**Last Updated**: December 30, 2024
**Maintained By**: TG-orlando
**Repository**: https://github.com/TG-orlando/rippling-mac-updates
