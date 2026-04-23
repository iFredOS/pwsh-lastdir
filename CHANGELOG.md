# Changelog

## v1.2 — 2026-04-23

### Fixed

- Startup save no longer re-records the restored directory on every normal taskbar/Start-menu launch. Previously, after a restore (terminal starts at USERPROFILE → moves to cc-boost), the startup save read the post-restore location (cc-boost) and wrote it back, creating a permanent loop that `cd`-based saves couldn't break. The startup save now uses the actual startup path (captured before any restore), so it only fires when a meaningful directory was genuinely provided (i.e. via "Open in Terminal" from Explorer).

## v1.1 — 2026-04-16

### Added
- Smart upgrade: re-running `install.ps1` now detects the installed version and upgrades in place. No more manual `uninstall → install` dance.
- Profile backups: both `install.ps1` and `uninstall.ps1` write a timestamped backup (`<profile>.bak-YYYYMMDD-HHMMSS`) before any modification.
- Malformed-block detection: both scripts abort with a clear error if the profile contains an opening marker without a closing marker (or vice versa).

### Fixed
- Startup restore no longer fails when a third-party app (e.g. AMD Radeon Software / ATI ACE APL) sets the terminal's starting directory to a system path instead of `USERPROFILE`.
- Uninstall regex now handles edge cases: marker-only profile file, missing trailing newline, CRLF/LF mixed content, and versioned opening markers.

## v1.0 — 2026-04-15

Initial release.

- Restores last visited folder on new terminal open.
- Records starting folder when launched via "Open in Terminal" from Explorer.
- Saves folder on every `cd`.
- Guards against background PowerShell sessions (GPU drivers, AI tools, IDEs) overwriting the saved directory.
