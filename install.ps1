#Requires -Version 5.1
<#
.SYNOPSIS
    Installs or updates the pwsh-lastdir feature in your PowerShell profile.

.DESCRIPTION
    Adds (or refreshes) code in your PowerShell profile that:
      - Restores the last visited folder when you open a new terminal normally
      - Records the starting folder when you use "Open in Terminal" from Explorer
      - Saves the folder whenever you cd somewhere

    Re-running this script upgrades an older install in place. The profile is
    backed up to "<profile>.bak-YYYYMMDD-HHMMSS" before any modification.

.EXAMPLE
    .\install.ps1
#>

$script:Version = '1.2'
$profilePath = $PROFILE.CurrentUserAllHosts

$openMarker = "# === pwsh-lastdir v$Version ==="
$endMarker = "# === end pwsh-lastdir ==="
$openPattern = '# === pwsh-lastdir(?: v[\d.]+)? ==='
$endPattern = '# === end pwsh-lastdir ==='
$blockPattern = "(?s)\r?\n?$openPattern.*?$endPattern\r?\n?"
$versionPattern = '# === pwsh-lastdir(?: v([\d.]+))? ==='

$block = @"

$openMarker
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
    if (`$_startPath -ne `$env:USERPROFILE -and -not (`$_lastdirSkip | Where-Object { `$_startPath -like "`$_*" })) {
        try {
            `$_ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=`$PID" -Property ParentProcessId).ParentProcessId
            if ((Get-Process -Id `$_ppid -ErrorAction SilentlyContinue).Name -eq 'explorer') {
                `$_startPath | Out-File `$lastDirFile -Encoding utf8
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
$endMarker
"@

# Ensure profile exists
$profileExisted = Test-Path $profilePath
if (-not $profileExisted) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "Created profile at: $profilePath"
}

$content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if (-not $content) { $content = '' }

$hasOpen = $content -match $openPattern
$hasEnd = $content -match $endPattern

# Abort if the profile contains a half-written block (one marker without its pair).
# Letting install rewrite here risks eating unrelated user content between markers.
if ($hasOpen -ne $hasEnd) {
    Write-Host "Found a partial/malformed pwsh-lastdir block in:" -ForegroundColor Red
    Write-Host "  $profilePath" -ForegroundColor Red
    Write-Host "Run .\uninstall.ps1 (it backs up the profile first) or edit the file by hand, then re-run install." -ForegroundColor Yellow
    exit 1
}

$installedVersion = $null
if ($content -match $versionPattern) {
    $installedVersion = if ($matches[1]) { $matches[1] } else { 'unversioned' }
}

if ($installedVersion -eq $Version) {
    Write-Host "pwsh-lastdir v$Version is already installed (no changes)." -ForegroundColor Yellow
    exit 0
}

$backupPath = $null
if ($profileExisted -and $content.Length -gt 0) {
    $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = "$profilePath.bak-$ts"
    Copy-Item -Path $profilePath -Destination $backupPath -ErrorAction Stop
}

if ($installedVersion) {
    $content = [regex]::Replace($content, $blockPattern, '')
    Set-Content -Path $profilePath -Value $content -Encoding utf8 -NoNewline
}

Add-Content -Path $profilePath -Value $block -Encoding utf8

$action = if ($installedVersion -eq 'unversioned') {
    "Upgraded from unversioned install to v$Version"
} elseif ($installedVersion) {
    "Upgraded from v$installedVersion to v$Version"
} else {
    "Installed v$Version"
}

Write-Host "$action -> $profilePath" -ForegroundColor Green
if ($backupPath) { Write-Host "Backup: $backupPath" }
Write-Host "Restart your terminal for changes to take effect."
