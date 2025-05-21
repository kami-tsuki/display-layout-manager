$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "DisplayLayoutManager.ps1"

# Prompt for shortcut file name
$shortcutFileName = Read-Host "Enter the name for the shortcut file (without extension, e.g. 'MyLayoutShortcut')"
if ([string]::IsNullOrWhiteSpace($shortcutFileName)) {
    $shortcutFileName = "DisplayLayoutManager"
}
$shortcutPath = Join-Path -Path $PSScriptRoot -ChildPath ("$shortcutFileName.lnk")

# Find PowerShell executable (prefer pwsh, fallback to Windows PowerShell)
$pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwsh) {
    $powershellExe = $pwsh.Source
} else {
    $powershellExe = (Get-Command powershell.exe).Source
}

# Prompt for autoselected layout
$layoutIndex = Read-Host "Enter the layout index to auto-select at startup (or leave blank for none)"

# Prompt for config file location
$configPath = Read-Host "Enter the path for the config file to use with --config (or leave blank for default)"

# Create the shortcut
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powershellExe

# Build arguments
$shortcutArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
if ($layoutIndex -ne "") {
    $shortcutArgs += " --layout $layoutIndex"
}
if ($configPath -ne "") {
    $shortcutArgs += " --config `"$configPath`""
}

# noexit?
$noExit = Read-Host "Do you want to keep the PowerShell window open after execution? (y/n)"
if ($noExit -eq "y" -or $noExit -eq "Y") {
    $shortcutArgs += " -NoExit"
}

$shortcut.Arguments = $shortcutArgs
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.IconLocation = $powershellExe
$shortcut.Save()

Write-Host "Shortcut created at: $shortcutPath" -ForegroundColor Green

