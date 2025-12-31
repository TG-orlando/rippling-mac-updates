# Mac Application Updater for Rippling MDM

Automatically installs Homebrew and updates all managed Mac applications. Designed for unattended deployment via Rippling MDM.

## Features

- ✅ Automatic Homebrew installation if not present
- ✅ Graceful application closing and reopening
- ✅ Unattended execution (no user prompts)
- ✅ Comprehensive logging
- ✅ One-line deployment for MDM systems
- ✅ Error handling and retries

## Managed Applications

The script currently manages these applications:
- Firefox
- Rectangle
- 1Password
- Slack
- Brave Browser
- Google Chrome
- Zoom
- Microsoft Office Suite (Excel, OneNote, Outlook, PowerPoint, Word)

## Deployment Options

### Option 1: One-Line Command (Recommended for Rippling MDM)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/mac-app-updater/main/install.sh | bash
```

### Option 2: Direct Script Execution

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/mac-app-updater/main/update-mac-apps.sh | bash
```

### Option 3: Download and Run

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/mac-app-updater/main/update-mac-apps.sh -o update-mac-apps.sh
chmod +x update-mac-apps.sh
./update-mac-apps.sh
```

## Rippling MDM Configuration

### Custom Script Configuration

1. Log into Rippling Admin Console
2. Navigate to **IT Management** → **Device Management** → **Scripts**
3. Click **Create Script**
4. Configure:
   - **Name**: Mac Application Updater
   - **Description**: Updates all managed Mac applications via Homebrew
   - **Script Type**: Shell Script
   - **Execution**: Run as current user (or root if needed)
   - **Script Content**:
   ```bash
   #!/bin/bash
   curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/mac-app-updater/main/install.sh | bash
   ```

5. Set schedule (recommended: weekly)
6. Deploy to target devices or groups

### Task Configuration (Alternative)

1. Navigate to **Tasks** → **Create Task**
2. Select **Run Script**
3. Paste the one-line command
4. Set recurrence and target devices

## Customization

### Adding/Removing Applications

Edit the `APPS` array in `update-mac-apps.sh`:

```bash
APPS=(
    "Firefox"
    "Rectangle"
    # Add more apps here
)
```

### Changing Log Location

Modify the `LOG_DIR` variable:

```bash
LOG_DIR="/var/log/rippling"  # Default
# or
LOG_DIR="/Library/Logs/YourCompany"
```

## Logs

Logs are stored in:
```
/var/log/rippling/mac-app-updater_YYYYMMDD_HHMMSS.log
```

If the directory cannot be created, logs fall back to `/tmp/`.

## Requirements

- macOS 10.15 or later
- Internet connection
- curl (pre-installed on macOS)
- Sudo privileges (for Homebrew installation)

## How It Works

1. **Checks for Homebrew** - Installs if not present
2. **Detects Running Apps** - Identifies which managed apps are currently running
3. **Closes Apps** - Gracefully closes running applications
4. **Updates via Homebrew** - Runs `brew upgrade --cask --greedy`
5. **Reopens Apps** - Restores previously running applications

## Troubleshooting

### Homebrew Installation Fails

- Ensure the script is not running as root
- Check internet connectivity
- Verify Xcode Command Line Tools are installed: `xcode-select --install`

### Applications Don't Reopen

- Check logs in `/var/log/rippling/`
- Verify application names match exactly (case-sensitive)
- Ensure applications are installed in `/Applications/`

### Permission Errors

- Script may need to run with elevated privileges
- Ensure the executing user has sudo access (for MDM, this is usually configured)

## Testing

Test the deployment manually before scheduling:

```bash
# Test with verbose output
bash -x update-mac-apps.sh
```

## Security Considerations

- Script runs with current user privileges (or root if deployed that way)
- Downloads are from official Homebrew sources
- All downloads use HTTPS
- No secrets or credentials are stored

## Contributing

To modify this for your organization:

1. Fork this repository
2. Update the `APPS` array with your organization's applications
3. Update the repository URL in `install.sh` and this README
4. Customize logging paths if needed
5. Test thoroughly before deploying to production

## License

MIT License - Feel free to modify and use for your organization.

## Support

For issues or questions:
- Check logs in `/var/log/rippling/`
- Review Homebrew documentation: https://brew.sh
- File an issue in this repository
