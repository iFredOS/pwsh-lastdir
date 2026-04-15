#Requires -Version 5.1
<#
.SYNOPSIS
    Removes the pwsh-lastdir feature from your PowerShell profile.

.EXAMPLE
    .\uninstall.ps1
#>

$profilePath = $PROFILE.CurrentUserAllHosts

if (-not (Test-Path $profilePath)) {
    Write-Host "No profile found at: $profilePath" -ForegroundColor Yellow
    exit 0
}

$content = Get-Content $profilePath -Raw

if (-not $content.Contains("# === pwsh-lastdir ===")) {
    Write-Host "pwsh-lastdir is not installed." -ForegroundColor Yellow
    exit 0
}

# Remove the block between markers (inclusive)
$cleaned = $content -replace "(?s)\r?\n# === pwsh-lastdir ===.*?# === end pwsh-lastdir ===\r?\n?", ""

Set-Content -Path $profilePath -Value $cleaned -Encoding utf8 -NoNewline
Write-Host "Uninstalled successfully from: $profilePath" -ForegroundColor Green

# Optionally remove the saved last-dir file
$lastDirFile = "$env:USERPROFILE\.pwsh_lastdir"
if (Test-Path $lastDirFile) {
    Remove-Item $lastDirFile
    Write-Host "Removed saved directory file: $lastDirFile"
}

Write-Host "Restart your terminal for the changes to take effect."
