$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "DisplayLayoutManager.ps1"
$shortcutPath = Join-Path -Path $PSScriptRoot -ChildPath "DisplayLayoutManager.lnk"

# Find PowerShell executable (prefer pwsh, fallback to Windows PowerShell)
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
    $powershellExe = $pwsh.Source
} else {
    $powershellExe = (Get-Command powershell.exe).Source
}

# Create the shortcut
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powershellExe
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.IconLocation = $powershellExe
$shortcut.Save()

Write-Host "Shortcut created at: $shortcutPath" -ForegroundColor Green

