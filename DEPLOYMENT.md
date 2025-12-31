# 🚀 Ready to Deploy!

Your Mac Application Updater is live on GitHub and ready to use!

## 📍 Repository
https://github.com/TG-orlando/rippling-mac-updates

## ⚡ One-Line Command for Rippling MDM

```bash
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
```

---

## 🔧 Deploy to Rippling MDM

### Quick Setup (5 minutes)

1. **Log into Rippling**
   - Go to your Rippling Admin Console

2. **Navigate to Scripts**
   - IT Management → Device Management → Scripts → Create Script

3. **Configure the Script**
   - **Name**: `Mac Application Updater`
   - **Description**: `Automatically updates Mac applications via Homebrew`
   - **Script Type**: Shell Script
   - **Script Content**:
   ```bash
   #!/bin/bash
   curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
   ```

4. **Set Schedule**
   - Recommended: Weekly (e.g., every Sunday at 2 AM)
   - Or: On-demand when you need to push updates

5. **Deploy**
   - Select target devices or groups
   - Save and deploy!

---

## 📱 What It Does

1. ✅ Installs Homebrew if not present
2. ✅ Detects running applications
3. ✅ Gracefully closes them
4. ✅ Updates all applications via Homebrew
5. ✅ Reopens the applications
6. ✅ Logs everything to `/var/log/rippling/`

---

## 🎯 Managed Applications

Currently updates:
- Firefox
- Rectangle
- 1Password
- Slack
- Brave Browser
- Google Chrome
- Zoom
- Microsoft Office (Excel, OneNote, Outlook, PowerPoint, Word)

---

## ✏️ Customize Applications

Edit `update-mac-apps.sh` in your repo:

```bash
APPS=(
    "Firefox"
    "YourApp"
    # Add more here
)
```

Commit and push - changes apply on next run!

```bash
git add update-mac-apps.sh
git commit -m "Update app list"
git push
```

---

## 🧪 Test First!

Before deploying to all Macs, test on one:

```bash
# Download and inspect
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/update-mac-apps.sh -o /tmp/test.sh
less /tmp/test.sh

# Run it
bash /tmp/test.sh

# Check logs
tail -f /var/log/rippling/mac-app-updater_*.log
```

---

## 📊 Monitor Deployment

Check logs on any Mac:
```bash
ls -lth /var/log/rippling/mac-app-updater_*.log
tail -50 /var/log/rippling/mac-app-updater_*.log
```

---

## 🔐 Security

- ✅ All downloads over HTTPS
- ✅ No credentials stored
- ✅ Runs with user permissions (or as configured in Rippling)
- ✅ Public repo - anyone can view (no secrets!)

---

## 💡 Pro Tips

1. **Schedule wisely** - Run during off-hours to minimize disruption
2. **Start small** - Deploy to a test group first
3. **Monitor logs** - Check after first few runs
4. **Keep it updated** - Update the app list as you add/remove software
5. **Version control** - Use git tags for major changes

---

## 🆘 Troubleshooting

### Script doesn't run
- Check Rippling MDM deployment status
- Verify target devices are online
- Check device permissions

### Homebrew fails to install
- Ensure Xcode Command Line Tools are installed
- Check internet connectivity on devices
- Verify not running as root (should run as user)

### Apps don't update
- Check if apps are installed via Homebrew
- Verify app names match exactly (case-sensitive)
- Review logs: `/var/log/rippling/mac-app-updater_*.log`

---

## 📞 Support

- **Repository**: https://github.com/TG-orlando/rippling-mac-updates
- **Logs**: `/var/log/rippling/`
- **Homebrew Docs**: https://brew.sh

---

## ✨ You're All Set!

Just add the one-line command to Rippling MDM and you're done!

```bash
curl -fsSL https://raw.githubusercontent.com/TG-orlando/rippling-mac-updates/main/install.sh | bash
```

Happy deploying! 🎉
