# Session History - Mac App Updater for Rippling MDM

**Date**: December 30, 2024
**Repository**: https://github.com/TG-orlando/rippling-mac-updates

---

## 📋 Session Overview

Transformed a manual Mac application management script into a GitHub-hosted, one-line deployment solution for Rippling MDM, similar to the ActivTrak deployment model.

---

## 🎯 What Was Accomplished

### 1. Script Improvements

**Original Script Issues:**
- Interactive prompts (not MDM-friendly)
- Required user input for Homebrew installation
- Manual update process
- Limited error handling
- Not suitable for unattended execution

**Improvements Made:**
- ✅ Removed all interactive prompts
- ✅ Automatic Homebrew installation
- ✅ Comprehensive logging to `/var/log/rippling/`
- ✅ Proper error handling and retries
- ✅ MDM-optimized execution (runs as root or user)
- ✅ Non-blocking sudo operations
- ✅ Graceful app closing and reopening

### 2. GitHub Repository Setup

**Created Repository:**
- **Name**: rippling-mac-updates
- **Owner**: TG-orlando
- **Visibility**: Public
- **URL**: https://github.com/TG-orlando/rippling-mac-updates

**Files Created:**
- `update-mac-apps.sh` - Main updater script
- `install.sh` - One-line installer wrapper
- `README.md` - Complete documentation
- `SETUP.md` - Detailed setup instructions
- `DEPLOYMENT.md` - Quick deployment guide
- `.gitignore` - Git configuration

### 3. One-Line Deployment

**Final Command:**
```bash
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
```

This command:
1. Downloads the installer script from GitHub
2. Executes the main updater script
3. Installs Homebrew if needed
4. Closes running applications
5. Updates all managed apps via Homebrew
6. Reopens applications
7. Cleans up temporary files

---

## 🐛 Critical Bugs Fixed

### Bug #1: `set -u` Variable Undefined Error
**Location**: Lines 158, 195
**Problem**:
```bash
current_user=$(stat -f%Su /dev/console 2>/dev/null || echo "$USER")
```
If `$USER` is not set in MDM environment, script crashes with "unbound variable" error.

**Fix**:
```bash
current_user=$(stat -f%Su /dev/console 2>/dev/null || echo "${USER:-root}")
```
Uses parameter expansion with default value.

### Bug #2: Sudo Password Prompts
**Location**: Lines 162, 201
**Problem**:
```bash
sudo -u "$current_user" osascript -e "tell application \"$app\" to quit"
```
In MDM execution, this could hang waiting for password input.

**Fix**:
```bash
if [[ $EUID -eq 0 ]]; then
    sudo -n -u "$current_user" osascript -e "tell application \"$app\" to quit" 2>/dev/null || true
else
    osascript -e "tell application \"$app\" to quit" 2>/dev/null || true
fi
```
Added `-n` flag (non-interactive) and conditional logic based on execution context.

### Bug #3: Error Trap Dependency
**Location**: Line 293
**Problem**:
```bash
trap 'log "Script interrupted or failed" "ERROR"' ERR INT TERM
```
Trap called `log()` function which might not be initialized if error occurs early.

**Fix**:
```bash
trap 'echo "Script interrupted or failed" >&2; exit 1' ERR INT TERM
```
Uses simple echo to stderr instead of log function.

### Bug #4: Install Script Cleanup
**Location**: install.sh
**Problem**: Cleanup code wouldn't run if script failed mid-execution.

**Fix**:
```bash
cleanup() {
    cd / 2>/dev/null || true
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT
```
Added cleanup trap to ensure temp files are always removed.

---

## 📱 Managed Applications

The script currently manages these applications:
- Firefox
- Rectangle
- 1Password
- Slack
- Brave Browser
- Google Chrome
- zoom.us
- Microsoft Excel
- Microsoft OneNote
- Microsoft Outlook
- Microsoft PowerPoint
- Microsoft Word

---

## 🔧 How to Make Future Changes

### Adding/Removing Applications

1. **Clone the repository**:
   ```bash
   cd /Users/appleseed/mac-app-updater
   git pull
   ```

2. **Edit the APPS array** in `update-mac-apps.sh`:
   ```bash
   APPS=(
       "Firefox"
       "Rectangle"
       "YourNewApp"  # Add here
   )
   ```

3. **Test locally**:
   ```bash
   bash update-mac-apps.sh
   ```

4. **Commit and push**:
   ```bash
   git add update-mac-apps.sh
   git commit -m "Add/remove applications from managed list"
   git push
   ```

5. **Wait 2-5 minutes** for GitHub CDN to update

6. **Test the deployment**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
   ```

### Changing Log Location

Edit line 11 in `update-mac-apps.sh`:
```bash
LOG_DIR="/var/log/rippling"  # Change to your preferred location
```

### Adjusting Retry Logic

Edit line 14 in `update-mac-apps.sh`:
```bash
MAX_RETRIES=3  # Change to desired number
```

### Modifying Sleep/Wait Times

- **App close wait**: Line 168 - `sleep 3`
- **App reopen wait**: Line 216 - `sleep 2`
- **Post-install wait**: Line 191 - `sleep 3`

---

## 🚀 Deployment to Rippling MDM

### Setup Instructions

1. **Log into Rippling Admin Console**
   - URL: https://app.rippling.com

2. **Navigate to Scripts**
   - IT Management → Device Management → Scripts

3. **Create New Script**
   - Click "Create Script"

4. **Configure Script**:
   - **Name**: Mac Application Updater
   - **Description**: Automatically updates Mac applications via Homebrew
   - **Script Type**: Shell Script
   - **Execution**: Run as current user (or root)
   - **Script Content**:
     ```bash
     #!/bin/bash
     curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
     ```

5. **Set Schedule**:
   - Recommended: Weekly (e.g., Sundays at 2 AM)
   - Or: Monthly / On-demand as needed

6. **Deploy**:
   - Select target devices or device groups
   - Save and deploy

### Monitoring Deployment

**Check logs on any Mac**:
```bash
# List all logs
ls -lth /var/log/rippling/mac-app-updater_*.log

# View latest log
tail -50 /var/log/rippling/mac-app-updater_*.log

# Follow log in real-time
tail -f /var/log/rippling/mac-app-updater_*.log
```

**Log format**:
```
2024-12-30 19:45:23 [INFO] === Mac Application Updater Started ===
2024-12-30 19:45:24 [INFO] Step 1: Checking Homebrew installation
2024-12-30 19:45:25 [INFO] Homebrew found at: /opt/homebrew/bin/brew
2024-12-30 19:45:26 [INFO] Step 2: Detecting running applications
2024-12-30 19:45:27 [INFO]   Found running: Firefox
2024-12-30 19:45:28 [INFO] Step 3: Closing applications
...
```

---

## 🔐 Security Considerations

### What's Safe
- ✅ Script is public - no secrets stored
- ✅ All downloads over HTTPS
- ✅ Homebrew uses official sources
- ✅ No credentials required
- ✅ Runs with configured user permissions

### What to Watch
- ⚠️ Script can close user applications
- ⚠️ Script can modify installed software
- ⚠️ Script runs with elevated privileges if configured
- ⚠️ Public repository - anyone can view the code

### Best Practices
1. Test on a small group first
2. Schedule during off-hours
3. Monitor logs after deployment
4. Review changes before pushing to GitHub
5. Use git tags for version control

---

## 📊 Git Workflow

### Current Git Configuration
- **User**: TG-orlando
- **Email**: orlando.roberts@theguarantors.com
- **Branch**: main
- **Remote**: https://github.com/TG-orlando/rippling-mac-updates.git

### Making Changes

```bash
# Navigate to repo
cd /Users/appleseed/mac-app-updater

# Pull latest changes
git pull

# Make your changes
# Edit files as needed

# Check what changed
git status
git diff

# Stage changes
git add update-mac-apps.sh  # or specific files
# or
git add -A  # for all changes

# Commit
git commit -m "Brief description of changes"

# Push to GitHub
git push

# Wait 2-5 minutes for GitHub CDN to update
# Then test the deployment
```

### Version Control with Tags

```bash
# Create a version tag
git tag -a v1.0.0 -m "Initial production release"
git push origin v1.0.0

# List tags
git tag -l

# Check out a specific version
git checkout v1.0.0
```

---

## 🧪 Testing Before Deployment

### Local Testing

```bash
# Download and inspect
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/update-mac-apps.sh -o /tmp/test-update.sh
less /tmp/test-update.sh

# Run with verbose output
bash -x /tmp/test-update.sh

# Check logs
tail -f /var/log/rippling/mac-app-updater_*.log
```

### Test Group Deployment

1. Create a test device group in Rippling
2. Add 1-2 Macs to the test group
3. Deploy script to test group only
4. Monitor logs and verify success
5. Once verified, deploy to production groups

---

## 📞 Troubleshooting

### Script doesn't download
- Check GitHub repository is public
- Verify URL is correct
- Check internet connectivity
- Wait a few minutes for GitHub CDN

### Homebrew installation fails
- Ensure not running as root for install
- Check Xcode Command Line Tools: `xcode-select --install`
- Verify internet connectivity
- Check logs for specific error

### Applications don't close
- Check application names are exact (case-sensitive)
- Verify apps are running
- Check logs for permission errors
- Try running script with elevated privileges

### Applications don't reopen
- Check application names match installed apps
- Verify apps are in `/Applications/` folder
- Check logs for specific errors
- May need to add `.app` extension for some apps

### Permission errors
- Script may need elevated privileges
- Check MDM configuration
- Verify executing user has appropriate permissions
- Check `/var/log/rippling/` is writable

---

## 📝 Session Commands Reference

### Git Commands Used

```bash
# Initialize repository
git init
git add -A
git commit -m "Initial commit"

# Configure git
git config user.email "orlando.roberts@theguarantors.com"
git config user.name "TG-orlando"

# Create GitHub repository
curl -X POST \
  -H "Authorization: token TOKEN" \
  https://api.github.com/user/repos \
  -d '{"name":"rippling-mac-updates","description":"...","private":false}'

# Add remote and push
git remote add origin https://github.com/TG-orlando/rippling-mac-updates.git
git branch -M main
git push -u origin main
```

### Testing Commands

```bash
# Test script download
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | head -20

# Test full deployment
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash

# Check logs
tail -f /var/log/rippling/mac-app-updater_*.log
```

---

## 🎯 Quick Reference

### Repository Information
- **GitHub URL**: https://github.com/TG-orlando/rippling-mac-updates
- **Local Path**: /Users/appleseed/mac-app-updater
- **One-Line Command**: `curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash`

### Key Files
- `update-mac-apps.sh` - Main script (modify to change app list)
- `install.sh` - Wrapper (rarely needs changes)
- `README.md` - User documentation
- `DEPLOYMENT.md` - Quick start guide
- `SETUP.md` - Detailed setup
- `SESSION_HISTORY.md` - This file

### Important Locations
- **Logs**: `/var/log/rippling/mac-app-updater_*.log`
- **Homebrew**: `/opt/homebrew/bin/brew` or `/usr/local/bin/brew`
- **Temp Files**: `/tmp/mac-app-updater-*` (auto-cleaned)

---

## 📅 Changelog

### 2024-12-30 - Initial Release

**Commits:**
1. `80b1f0e` - Initial commit: Mac Application Updater for Rippling MDM
2. `3407f80` - Update repository URLs to TG-orlando/rippling-mac-updates
3. `aaa869f` - Add deployment and setup documentation
4. `bcd318e` - Fix critical errors and improve MDM compatibility

**Features:**
- One-line deployment for Rippling MDM
- Automatic Homebrew installation
- Application management (close/update/reopen)
- Comprehensive logging
- Error handling and retries

**Bug Fixes:**
- Fixed `set -u` error with undefined USER variable
- Fixed sudo password prompts in MDM environments
- Fixed error trap dependencies
- Added cleanup trap to installer

---

## 🔮 Future Enhancements

### Possible Improvements
- [ ] Add support for App Store applications
- [ ] Email notifications on completion/failure
- [ ] Slack/Teams webhook integration
- [ ] More granular control over which apps to update
- [ ] Support for custom Homebrew taps
- [ ] Pre/post update hooks
- [ ] Rollback capability
- [ ] Update scheduling per application
- [ ] Bandwidth throttling for large updates
- [ ] Integration with Rippling device inventory

### Enhancement Requests
Add future enhancement requests here as needed.

---

## 💡 Tips & Best Practices

1. **Always test locally first** before pushing to GitHub
2. **Use git tags** for version control in production
3. **Schedule updates during off-hours** to minimize disruption
4. **Start with small test groups** before full deployment
5. **Monitor logs regularly** especially after changes
6. **Keep the app list updated** as software changes
7. **Document custom changes** in git commit messages
8. **Use descriptive commit messages** for easier history tracking

---

## 📚 Resources

- **Homebrew Documentation**: https://brew.sh
- **Rippling Support**: https://help.rippling.com
- **Bash Scripting Guide**: https://www.gnu.org/software/bash/manual/
- **Git Documentation**: https://git-scm.com/doc
- **GitHub API**: https://docs.github.com/en/rest

---

**Last Updated**: December 30, 2024
**Maintained By**: TG-orlando
**Contact**: orlando.roberts@theguarantors.com
