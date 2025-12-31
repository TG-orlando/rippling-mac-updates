# Setup Instructions for rippling-mac-updates

## Step 1: Create GitHub Repository

You have two options:

### Option A: Using GitHub Web Interface
1. Go to https://github.com/TG-orlando
2. Click the "+" icon in the top right → "New repository"
3. Repository name: `rippling-mac-updates`
4. Description: "Automated Mac application updater for Rippling MDM - One-line deployment script"
5. Choose "Public" visibility
6. **Do NOT** initialize with README, .gitignore, or license (we already have these)
7. Click "Create repository"

### Option B: Using Personal Access Token
If you have a GitHub personal access token with repo permissions:

```bash
cd /Users/appleseed/mac-app-updater
curl -X POST -H "Authorization: token YOUR_GITHUB_TOKEN" \
  https://api.github.com/user/repos \
  -d '{"name":"rippling-mac-updates","description":"Automated Mac application updater for Rippling MDM","private":false}'
```

## Step 2: Push to GitHub

Once the repository is created on GitHub, push your local code:

```bash
cd /Users/appleseed/mac-app-updater
git push -u origin main
```

If you're using a personal access token instead of SSH:
```bash
git remote set-url origin https://YOUR_TOKEN@github.com/TG-orlando/rippling-mac-updates.git
git push -u origin main
```

## Step 3: Verify Deployment

After pushing, verify the files are accessible:

```bash
# Test downloading the main script
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/update-mac-apps.sh | head -20

# Test downloading the installer
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | head -20
```

## Step 4: Deploy to Rippling MDM

### For Rippling Custom Scripts:

1. Log into Rippling Admin Console
2. Navigate to: **IT Management** → **Device Management** → **Scripts**
3. Click: **Create Script**
4. Fill in:
   - **Name**: Mac Application Updater
   - **Description**: Automatically updates Mac applications via Homebrew
   - **Script Type**: Shell Script
   - **Script Content**:
   ```bash
   #!/bin/bash
   curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
   ```
5. **Execution Settings**:
   - Run as: Current user (recommended) or root
   - Schedule: Weekly (recommended) or as needed
6. **Deploy to**:
   - Select target devices or device groups
   - Click **Save and Deploy**

### For Rippling Tasks:

1. Navigate to: **Tasks** → **Create Task**
2. Select: **Run Script**
3. Paste the one-liner:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
   ```
4. Set recurrence and target devices
5. Save and activate

## The One-Line Command

Once everything is set up, this is the command that will run on all your Macs:

```bash
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
```

## Testing Before Deployment

Test on a single Mac first:

```bash
# Download and review the script
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/update-mac-apps.sh -o /tmp/test-update.sh
less /tmp/test-update.sh

# Run with verbose output
bash -x /tmp/test-update.sh

# Check the log
tail -f /var/log/rippling/mac-app-updater_*.log
```

## Customizing for Your Organization

To modify the list of applications:

1. Edit `update-mac-apps.sh` in your local repository
2. Update the `APPS` array:
   ```bash
   APPS=(
       "Firefox"
       "Rectangle"
       # Add your apps here
   )
   ```
3. Commit and push:
   ```bash
   git add update-mac-apps.sh
   git commit -m "Update application list"
   git push
   ```
4. Wait ~5 minutes for GitHub to update the raw file cache
5. The next run will use the updated list

## Troubleshooting

### Repository not found error
- Verify the repository was created on GitHub
- Check the repository name is exactly `rippling-mac-updates`
- Ensure repository is public (or use authentication for private repos)

### Script download fails
- GitHub raw files can take a few minutes to become available after first push
- Check repository visibility settings
- Verify the branch is named `main` (not `master`)

### Permission denied when pushing
- Set up SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- Or use HTTPS with personal access token
- Ensure you have write access to the TG-orlando organization

## Security Notes

- The script is public and downloadable by anyone
- No secrets or credentials are stored in the repository
- All operations run with the permissions of the executing user
- Homebrew downloads are from official sources over HTTPS

## Support

If you encounter issues:
1. Check the script logs: `/var/log/rippling/mac-app-updater_*.log`
2. Verify repository accessibility on GitHub
3. Test the one-liner manually on a test Mac
4. Review Rippling MDM deployment logs
