#Requires -Version 5.1
<#
.SYNOPSIS
    Removes the pwsh-lastdir feature from your PowerShell profile.

.DESCRIPTION
    Strips the pwsh-lastdir block from your PowerShell profile and deletes the
    saved-directory file. The profile is backed up to
    "<profile>.bak-YYYYMMDD-HHMMSS" before any modification.

.EXAMPLE
    .\uninstall.ps1
#>

$profilePath = $PROFILE.CurrentUserAllHosts
$openPattern = '# === pwsh-lastdir(?: v[\d.]+)? ==='
$endPattern = '# === end pwsh-lastdir ==='
$blockPattern = "(?s)\r?\n?$openPattern.*?$endPattern\r?\n?"

if (-not (Test-Path $profilePath)) {
    Write-Host "No profile found at: $profilePath" -ForegroundColor Yellow
    exit 0
}

$content = Get-Content $profilePath -Raw
if (-not $content) { $content = '' }

$hasOpen = $content -match $openPattern
$hasEnd = $content -match $endPattern

if (-not $hasOpen -and -not $hasEnd) {
    Write-Host "pwsh-lastdir is not installed." -ForegroundColor Yellow
    exit 0
}

if ($hasOpen -ne $hasEnd) {
    Write-Host "Found a partial/malformed pwsh-lastdir block in:" -ForegroundColor Red
    Write-Host "  $profilePath" -ForegroundColor Red
    Write-Host "Edit the file by hand to remove the stray marker, then re-run uninstall." -ForegroundColor Yellow
    exit 1
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = "$profilePath.bak-$ts"
Copy-Item -Path $profilePath -Destination $backupPath -ErrorAction Stop

$cleaned = [regex]::Replace($content, $blockPattern, '')
Set-Content -Path $profilePath -Value $cleaned -Encoding utf8 -NoNewline

Write-Host "Uninstalled from: $profilePath" -ForegroundColor Green
Write-Host "Backup: $backupPath"

$lastDirFile = "$env:USERPROFILE\.pwsh_lastdir"
if (Test-Path $lastDirFile) {
    Remove-Item $lastDirFile
    Write-Host "Removed saved directory file: $lastDirFile"
}

Write-Host "Restart your terminal for changes to take effect."
