# Changelog

All notable changes to the Mac Application Updater for Rippling MDM will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2024-12-30

### Added
- Initial release of Mac Application Updater for Rippling MDM
- One-line deployment command for Rippling MDM
- Automatic Homebrew installation if not present
- Graceful application closing and reopening
- Comprehensive logging to `/var/log/rippling/`
- Support for 11 managed applications:
  - Firefox
  - Rectangle
  - 1Password
  - Slack
  - Brave Browser
  - Google Chrome
  - zoom.us
  - Microsoft Office Suite (Excel, OneNote, Outlook, PowerPoint, Word)
- Error handling and retry logic
- Non-interactive execution for MDM environments
- Complete documentation (README, SETUP, DEPLOYMENT guides)

### Fixed
- Fixed `set -u` error with undefined `$USER` variable in MDM environments
- Fixed sudo password prompts that could hang script execution
- Fixed error trap to not depend on log function initialization
- Added cleanup trap to installer for proper temp file cleanup

### Security
- All downloads over HTTPS
- No credentials or secrets stored
- Public repository for transparency
- Non-interactive sudo operations

---

## How to Update

When making changes, follow this format:

```markdown
## [Version] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```

---

## Version History

- **1.0.0** (2024-12-30) - Initial release

---

**Repository**: https://github.com/TG-orlando/rippling-mac-updates
**Maintainer**: TG-orlando (orlando.roberts@theguarantors.com)
