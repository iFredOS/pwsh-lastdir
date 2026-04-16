#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the pwsh-lastdir feature into your PowerShell profile.

.DESCRIPTION
    Adds code to your PowerShell profile that:
      - Restores the last visited folder when you open a new terminal normally
      - Records the starting folder when you use "Open in Terminal" from Explorer
      - Saves the folder whenever you cd somewhere

.EXAMPLE
    .\install.ps1
#>

$marker = "# === pwsh-lastdir ==="
$profilePath = $PROFILE.CurrentUserAllHosts

$block = @"

$marker
`$lastDirFile = "`$env:USERPROFILE\.pwsh_lastdir"
`$_lastdirSkip = @(`$env:LOCALAPPDATA, `$env:APPDATA, `$env:TEMP, `$env:TMP, "C:\Windows")

# Restore on startup unless a meaningful directory was provided (e.g. via "Open in Terminal")
`$_startPath = (Get-Location).Path
`$_startUninformative = (`$_startPath -eq `$env:USERPROFILE) -or (`$_lastdirSkip | Where-Object { `$_startPath -like "`$_*" })
if (`$_startUninformative -and (Test-Path `$lastDirFile)) {
    `$saved = Get-Content `$lastDirFile
    if (Test-Path `$saved) { Microsoft.PowerShell.Management\Set-Location `$saved }
}

# Record the starting directory only when opened via "Open in Terminal" from Explorer
if (`$Host.Name -eq 'ConsoleHost') {
    `$_p = (Get-Location).Path
    if (`$_p -ne `$env:USERPROFILE -and -not (`$_lastdirSkip | Where-Object { `$_p -like "`$_*" })) {
        try {
            `$_ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=`$PID" -Property ParentProcessId).ParentProcessId
            if ((Get-Process -Id `$_ppid -ErrorAction SilentlyContinue).Name -eq 'explorer') {
                `$_p | Out-File `$lastDirFile -Encoding utf8
            }
        } catch {}
    }
}

# Save whenever you cd somewhere
function Set-Location {
    try {
        Microsoft.PowerShell.Management\Set-Location @args
        if (`$Host.Name -eq 'ConsoleHost') {
            `$_p = `$PWD.Path
            if (-not (`$_lastdirSkip | Where-Object { `$_p -like "`$_*" })) {
                `$_p | Out-File "`$env:USERPROFILE\.pwsh_lastdir" -Encoding utf8
            }
        }
    } catch {
        Write-Host "cd: path not found" -ForegroundColor Red
    }
}
# === end pwsh-lastdir ===
"@

# Create profile file if it doesn't exist
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "Created profile at: $profilePath"
}

$content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

if ($content -and $content.Contains($marker)) {
    Write-Host "pwsh-lastdir is already installed in your profile." -ForegroundColor Yellow
    exit 0
}

Add-Content -Path $profilePath -Value $block -Encoding utf8
Write-Host "Installed successfully into: $profilePath" -ForegroundColor Green
Write-Host "Restart your terminal for the changes to take effect."
