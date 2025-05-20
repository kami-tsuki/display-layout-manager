#Requires -Version 5.0

<#
.SYNOPSIS
    Display Layout Manager - Manages window layouts and applications based on connected displays
.DESCRIPTION
    Detects connected displays and peripherals, loads layouts from TOML configuration,
    and applies window layouts and application states based on user selection
#>
#region --- Immersive Startup Banner & Owner Info ---
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WindowManager {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

# Function to read TOML configuration
function Read-TomlConfig {
    param (
        [string]$ConfigPath = $PSScriptRoot + "\layouts-config.toml"
    )

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "No configuration file found at $ConfigPath" -ForegroundColor Yellow
        return $null
    }

    try {
        $configContent = Get-Content $ConfigPath -Raw
        $config = @{}
        $currentSection = ""
        $currentAppSection = $null
        foreach ($line in ($configContent -split "`n")) {
            $line = $line.Trim()
            if (-not $line -or $line.StartsWith("#")) { continue }

            # Match [section] or [section.Applications.app]
            if ($line -match "^\[(.+?)\]$") {
                $sectionName = $Matches[1]
                if ($sectionName -match "^(.+)\.Applications\.(.+)$") {
                    $layout = $Matches[1]
                    $app = $Matches[2]
                    if (-not $config.ContainsKey($layout)) { $config[$layout] = @{} }
                    if (-not $config[$layout].ContainsKey('Applications')) { $config[$layout]['Applications'] = @{} }
                    $currentSection = $layout
                    $currentAppSection = $app
                    if (-not $config[$layout]['Applications'].ContainsKey($app)) {
                        $config[$layout]['Applications'][$app] = @{}
                    }
                } elseif ($sectionName -match "^(.+)$") {
                    $layout = $Matches[1]
                    if (-not $config.ContainsKey($layout)) { $config[$layout] = @{} }
                    $currentSection = $layout
                    $currentAppSection = $null
                }
            }
            elseif ($line -match "^(.+?)\s*=\s*(.+)$" -and $currentSection) {
                $key = $Matches[1].Trim()
                $value = $Matches[2].Trim() -replace '^"(.*)"$', '$1'
                if ($currentAppSection) {
                    $config[$currentSection]['Applications'][$currentAppSection][$key] = $value
                } else {
                    $config[$currentSection][$key] = $value
                }
            }
        }
        return $config
    }
    catch {
        Write-Error "Error reading TOML configuration: $_"
        return $null
    }
}

# Function to write TOML configuration
function Write-TomlConfig {
    param (
        [hashtable]$Config,
        [string]$ConfigPath = ".\layouts-config.toml"
    )
    $tomlContent = ""
    foreach ($section in $Config.Keys) {
        $tomlContent += "[$section]`n"
        if ($Config[$section].Description) {
            $tomlContent += "Description = `"$($Config[$section].Description)`"`n"
        }
        if ($Config[$section].Applications) {
            foreach ($app in $Config[$section].Applications.Keys) {
                $tomlContent += "[$section.Applications.$app]`n"
                $appConfig = $Config[$section].Applications[$app]
                foreach ($key in $appConfig.Keys) {
                    $tomlContent += "$key = `"$($appConfig[$key])`"`n"
                }
                $tomlContent += "`n"
            }
        }
        $tomlContent += "`n"
    }
    Set-Content -Path $ConfigPath -Value $tomlContent
}

# Function to capture current layout
function Capture-CurrentLayout {
    param (
        [string]$ConfigPath = ".\layouts-config.toml"
    )
    $config = Read-TomlConfig -ConfigPath $ConfigPath
    if (-not $config) { $config = @{} }
    $layoutName = Read-Host "Enter a name for the captured layout"
    $description = Read-Host "Enter a description for this layout (optional)"
    $config[$layoutName] = @{ Description = $description; Applications = @{} }
    $processes = Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object Id, ProcessName, MainWindowTitle, Path, MainWindowHandle

    # Get display bounds
    Add-Type -AssemblyName System.Windows.Forms
    $screens = [System.Windows.Forms.Screen]::AllScreens

    # Add GetWindowPlacement API
    $sig = @'
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    public static extern bool GetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT lpwndpl);
    [StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }
    [StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    public struct WINDOWPLACEMENT {
        public int length;
        public int flags;
        public int showCmd;
        public POINT ptMinPosition;
        public POINT ptMaxPosition;
        public RECT rcNormalPosition;
    }
'@
    Add-Type -MemberDefinition $sig -Name 'WinPlacement' -Namespace Win32 -PassThru | Out-Null

    foreach ($proc in $processes) {
        $displayId = 0
        $windowState = "normal"
        $path = $proc.Path
        $handle = $proc.MainWindowHandle
        $x = $y = $width = $height = $null
        if ($handle -and $handle -ne 0) {
            # Get window rectangle
            $rectStruct = New-Object Win32.WinPlacement+RECT
            [Win32.WinPlacement]::GetWindowRect($handle, [ref]$rectStruct) | Out-Null
            $centerX = [int](($rectStruct.Left + $rectStruct.Right) / 2)
            $centerY = [int](($rectStruct.Top + $rectStruct.Bottom) / 2)
            # Find the screen containing the window center
            for ($i = 0; $i -lt $screens.Length; $i++) {
                $bounds = $screens[$i].Bounds
                if ($centerX -ge $bounds.X -and $centerX -lt ($bounds.X + $bounds.Width) -and $centerY -ge $bounds.Y -and $centerY -lt ($bounds.Y + $bounds.Height)) {
                    $displayId = $i
                    break
                }
            }
            # Get window placement
            $placement = New-Object Win32.WinPlacement+WINDOWPLACEMENT
            $placement.length = [System.Runtime.InteropServices.Marshal]::SizeOf($placement)
            [Win32.WinPlacement]::GetWindowPlacement($handle, [ref]$placement) | Out-Null
            switch ($placement.showCmd) {
                1 { $windowState = "normal" }
                2 { $windowState = "minimized" }
                3 { $windowState = "maximized" }
                default { $windowState = "normal" }
            }
            if ($windowState -eq "normal") {
                $x = $placement.rcNormalPosition.Left
                $y = $placement.rcNormalPosition.Top
                $width = $placement.rcNormalPosition.Right - $placement.rcNormalPosition.Left
                $height = $placement.rcNormalPosition.Bottom - $placement.rcNormalPosition.Top
                $windowState = "coordinate-size"
            }
        }
        if (-not $path) { $path = "" }
        $appConfig = @{
            Path = $path
            Action = "ignore"
            DisplayId = $displayId
            WindowState = $windowState
        }
        if ($windowState -eq "coordinate-size") {
            $appConfig["X"] = $x
            $appConfig["Y"] = $y
            $appConfig["Width"] = $width
            $appConfig["Height"] = $height
        }
        $config[$layoutName].Applications[$proc.ProcessName] = $appConfig
    }
    Write-TomlConfig -Config $config -ConfigPath $ConfigPath
    Write-Host "Current layout captured as '$layoutName' in $ConfigPath" -ForegroundColor Green
}

# Function to apply window position
function Set-WindowPosition {
    param (
        [int]$ProcessId,
        [string]$DisplayId,
        [string]$WindowState,
        [int]$X = $null,
        [int]$Y = $null,
        [int]$Width = $null,
        [int]$Height = $null
    )
    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        $hwnd = $process.MainWindowHandle
        if (-not $hwnd -or $hwnd -eq 0) {
            Write-Warning "No main window handle for process $($process.ProcessName) (PID $ProcessId). Skipping window positioning."
            return
        }
        # Always load display bounds for moving to correct screen
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $displayIdx = 0
        if ($DisplayId -match '^[0-9]+$') { $displayIdx = [int]$DisplayId }
        if ($displayIdx -ge $screens.Length) { $displayIdx = 0 }
        $targetBounds = $screens[$displayIdx].Bounds
        # Handle maximized windows
        if ($WindowState -eq "maximized") {
            # Restore window if maximized
            [WindowManager]::ShowWindow($hwnd, 9) # SW_RESTORE
            Start-Sleep -Milliseconds 200
            # Move to correct display (use display bounds)
            [WindowManager]::MoveWindow($hwnd, $targetBounds.X, $targetBounds.Y, $targetBounds.Width, $targetBounds.Height, $true)
            Start-Sleep -Milliseconds 100
            # Maximize again
            [WindowManager]::ShowWindow($hwnd, 3) # SW_MAXIMIZE
        }
        elseif ($WindowState -eq "coordinate-size" -and $X -ne $null -and $Y -ne $null -and $Width -ne $null -and $Height -ne $null) {
            [WindowManager]::MoveWindow($hwnd, $X, $Y, $Width, $Height, $true)
            [WindowManager]::ShowWindow($hwnd, 1) # SW_NORMAL
        }
    } catch {
        Write-Error "Error setting window position for PID ${ProcessId}: $_"
    }
}

# Function to write processing line
function Write-ProcessingLine {
    param(
        [string]$AppName,
        [string]$Action,
        [string]$State,
        [string]$Position = "",
        [string]$Size = "",
        [string]$Status = "spinner"
    )
    $spinner = @('|', '/', '-', '\\')
    switch ($Status) {
        'spinner' {
            $statusChar = $spinner[($global:spinnerIndex % $spinner.Length)]
            Write-Host -NoNewline "`r[$statusChar]> Processing '$AppName' [$Action] [$State] [$Position] [$Size]"
        }
        'success' {
            Write-Host -NoNewline "`r[●]> Processing '$AppName' [$Action] [$State] [$Position] [$Size]" -ForegroundColor Green
        }
        'fail' {
            Write-Host -NoNewline "`r[✗]> Processing '$AppName' [$Action] [$State] [$Position] [$Size]" -ForegroundColor Red
        }
        default {
            Write-Host -NoNewline "`r[ ]> Processing '$AppName' [$Action] [$State] [$Position] [$Size]"
        }
    }
}

# Function to apply a layout
function Apply-Layout {
    param (
        [string]$LayoutName,
        [hashtable]$Config
    )
    if (-not $Config -or -not $Config[$LayoutName]) {
        Write-Error "Layout '$LayoutName' not found in configuration"
        return
    }
    $layout = $Config[$LayoutName]
    Write-Host "Applying layout: $LayoutName - $($layout.Description)" -ForegroundColor Green
    $global:spinnerIndex = 0
    foreach ($appName in $layout.Applications.Keys) {
        $appConfig = $layout.Applications[$appName]
        $action = $appConfig.Action
        $state = $appConfig.WindowState
        $pos = ""
        $size = ""
        if ($appConfig.WindowState -eq "coordinate-size") {
            $pos = "$($appConfig.X),$($appConfig.Y)"
            $size = "$($appConfig.Width)x$($appConfig.Height)"
        } elseif ($appConfig.DisplayId -ne $null) {
            $pos = "Display $($appConfig.DisplayId)"
        }
        $status = 'spinner'
        Write-ProcessingLine -AppName $appName -Action $action -State $state -Position $pos -Size $size -Status $status
        $success = $false
        $logLines = @()
        $process = $null
        # Normalize process name for Get-Process (strip .exe, lowercase)
        $procName = $appName
        if ($procName.ToLower().EndsWith('.exe')) { $procName = $procName.Substring(0, $procName.Length - 4) }
        $procName = $procName.ToLower()
        if ($action -eq 'stop') {
            $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($process) {
                try {
                    $process | Stop-Process -Force
                    $success = $true
                } catch {
                    $success = $false
                    $logLines += "log: $_"
                }
            } else {
                $success = $true # Already stopped
            }
        } elseif ($action -eq 'startup' -or $action -eq 'start') {
            $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if (-not $process) {
                try {
                    $exePath = $appConfig.Path
                    if ($exePath -and (Test-Path $exePath)) {
                        Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command Start-Process -FilePath '$exePath' -WindowStyle Normal"
                        $success = $true
                    } else {
                        $logLines += "log: Executable path not found or does not exist for ${appName}: $exePath."
                    }
                } catch {
                    $logLines += "log: Exception while trying to start ${appName}: $_"
                }
            } else {
                $logLines += "log: $appName is already running."
            }
            # After ensuring process is running, continue to window adjustment
        } else {
            $process = Get-Process -Name $procName -ErrorAction SilentlyContinue
        }
        # Only adjust window if not stop action
        if ($action -ne 'stop' -and $process) {
            foreach ($proc in $process) {
                if ($proc.MainWindowHandle -ne 0) {
                    $params = @{
                        ProcessId = $proc.Id
                        DisplayId = $appConfig.DisplayId
                        WindowState = $appConfig.WindowState
                    }
                    if ($appConfig.WindowState -eq "coordinate-size") {
                        $params.X = [int]$appConfig.X
                        $params.Y = [int]$appConfig.Y
                        $params.Width = [int]$appConfig.Width
                        $params.Height = [int]$appConfig.Height
                    }
                    try {
                        $null = Set-WindowPosition @params
                        $success = $true
                    } catch {
                        $success = $false
                        $logLines += "log: $_"
                    }
                }
            }
        }
        $global:spinnerIndex++
        if ($success) {
            Write-ProcessingLine -AppName $appName -Action $action -State $state -Position $pos -Size $size -Status 'success'
        } else {
            Write-ProcessingLine -AppName $appName -Action $action -State $state -Position $pos -Size $size -Status 'fail'
        }
        Write-Host ""
        foreach ($logLine in $logLines) { Write-Host $logLine -ForegroundColor Yellow }
    }
    Write-Host "Layout '$LayoutName' applied successfully!" -ForegroundColor Green
}

# Function to show layout options
Clear-Host
Write-Host "=== Display Layout Manager ===" -ForegroundColor Cyan

# Add Windows Forms for UI elements
Add-Type -AssemblyName System.Windows.Forms

# Get or create configuration
$configPath = ".\layouts-config.toml"
$config = Read-TomlConfig -ConfigPath $configPath

$interactive = $Host.Name -eq 'ConsoleHost'

if (-not $config) {
    Write-Host "`nNo configuration found. Please capture the current layout to create a configuration." -ForegroundColor Yellow
    if (-not $interactive) {
        Write-Host "Script is running in NonInteractive mode. Please run interactively to capture a layout and create the configuration file (.toml). Exiting." -ForegroundColor Red
        exit 1
    } else {
        $capture = Read-Host "Do you want to capture the current layout now? (Y/N)"
        if ($capture -eq 'Y' -or $capture -eq 'y') {
            Capture-CurrentLayout -ConfigPath $configPath
            $config = Read-TomlConfig -ConfigPath $configPath
        } else {
            Write-Host "No layout captured. Exiting." -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "`nAvailable Layouts:" -ForegroundColor Cyan
$layoutOptions = @()
foreach ($layoutName in $config.Keys) {
    if ($layoutName -and $layoutName -ne 'Applications') {
        $desc = $config[$layoutName].Description
        $layoutOptions += @{ Name = $layoutName; Description = $desc }
    }
}
for ($i = 0; $i -lt $layoutOptions.Count; $i++) {
    Write-Host "[$i] $($layoutOptions[$i].Name) - $($layoutOptions[$i].Description)"
}

if (-not $interactive) {
    if ($layoutOptions.Count -gt 0) {
        Write-Host "NonInteractive mode: Automatically applying the first available layout: $($layoutOptions[0].Name)" -ForegroundColor Yellow
        Apply-Layout -LayoutName $layoutOptions[0].Name -Config $config
        exit 0
    } else {
        Write-Host "No layouts available to apply. Exiting." -ForegroundColor Red
        exit 1
    }
}

# Prompt user to select a layout
$selection = Read-Host "`nSelect a layout to apply (0-$($layoutOptions.Count-1)), or 'C' to capture the current layout"

if ($selection -eq "C" -or $selection -eq "c") {
    Capture-CurrentLayout -ConfigPath $configPath
    $config = Read-TomlConfig -ConfigPath $configPath
    # Rebuild layoutOptions after capture
    $layoutOptions = @()
    foreach ($layoutName in $config.Keys) {
        if ($layoutName -and $layoutName -ne 'Applications') {
            $desc = $config[$layoutName].Description
            $layoutOptions += @{ Name = $layoutName; Description = $desc }
        }
    }
    for ($i = 0; $i -lt $layoutOptions.Count; $i++) {
        Write-Host "[$i] $($layoutOptions[$i].Name) - $($layoutOptions[$i].Description)"
    }
    $selection = 0
}

if ($selection -match '^[0-9]+$' -and [int]$selection -ge 0 -and [int]$selection -lt $layoutOptions.Count) {
    $selectedLayout = $layoutOptions[$selection].Name
    Apply-Layout -LayoutName $selectedLayout -Config $config
    # Do not exit here, allow the user to run again if desired
} else {
    Write-Error "Invalid selection"
}







