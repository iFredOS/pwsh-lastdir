# pwsh-lastdir

Remembers your last visited folder across PowerShell terminal sessions on Windows.

Open a new terminal and you're right back where you left off — no setup, no friction.

## Behaviour

| How you open the terminal | What happens |
|---|---|
| New terminal / new tab (no folder specified) | Restores the last folder you were in |
| "Open in Terminal" from Explorer | Opens in that folder, and remembers it for next time |
| `cd` to a new folder | Records it immediately |

## Requirements

- Windows
- PowerShell 5.1 or later

## Install

```powershell
.\install.ps1
```

Restart your terminal. That's it.

## Uninstall

```powershell
.\uninstall.ps1
```

## How it works

The installer appends a small block to your PowerShell profile (`$PROFILE.CurrentUserAllHosts`) that:

1. **On startup** — if the terminal opened in your home directory or a system path (no specific folder was passed), restores the last saved folder.
2. **On startup** — saves the current directory only when the terminal was launched via "Open in Terminal" from Explorer.
3. **On `cd`** — wraps `Set-Location` to save the path every time you navigate.

The last directory is stored in `~\.pwsh_lastdir`.

### Background session protection

Some software (GPU drivers, AI tools, IDEs) spawns PowerShell sessions in the background or in embedded terminals. Without protection, these sessions would overwrite your saved directory.

pwsh-lastdir guards against this in three layers:

- **Interactive check** — only saves when running in a real terminal (`$Host.Name -eq 'ConsoleHost'`), ignoring scripted/background sessions.
- **Path exclusion** — skips paths under `AppData`, `Temp`, and `Windows`.
- **Parent process check** — on startup, only saves the directory if the terminal was launched by Explorer (`explorer.exe`). All other apps (LM Studio, VS Code, GPU utilities, etc.) are ignored on startup; user navigation via `cd` is still tracked normally.

## Updating

If you already have pwsh-lastdir installed and want to apply an update, run:

```powershell
.\uninstall.ps1
.\install.ps1
```

Then restart your terminal.
