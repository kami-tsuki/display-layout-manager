# DisplayLayoutManager.ps1

## Overview

**DisplayLayoutManager.ps1** is a PowerShell script for managing and automating the arrangement of application windows across multiple displays on Windows. It allows you to define, capture, and apply custom window layouts for your workspace, including starting, stopping, and positioning applications on specific monitors.

---

## Features

- **Capture Current Layout:** Save the current arrangement of running applications and their window positions to a configuration file.
- **Apply Saved Layouts:** Restore window positions, sizes, and states for your applications as defined in a TOML configuration file.
- **Multi-Display Support:** Assign applications to specific monitors and coordinates.
- **Application Control:** Start, stop, or ignore applications as part of a layout.
- **Flexible Window States:** Supports maximized, normal, minimized, and custom coordinate/size window states.

---

## Requirements

- **Windows 10/11**
- **PowerShell 5.0 or higher**
- **.NET Framework** (for Windows Forms and user32.dll interop)

---

## Usage

### 1. Configuration File

The script uses a TOML file (`layouts-config.toml`) to store and load layouts. Each layout contains a set of applications with their desired state and position.

#### Example `layouts-config.toml`:

```toml
[test1]
Description = "first test"

[test1.Applications.Discord]
Path = "C:\\Path\\To\\Discord.exe"
WindowState = "coordinate-size"
Action = "start"
DisplayId = "0"
X = "320"
Y = "165"
Width = "1280"
Height = "720"
```

- **Path:** Full path to the application executable.
- **WindowState:** `maximized`, `normal`, `minimized`, or `coordinate-size` (with X, Y, Width, Height).
- **Action:** `start`, `stop`, or `ignore`.
- **DisplayId:** Monitor index (0-based).

### 2. Running the Script

1. Open PowerShell and navigate to the script directory.
2. Run the script:
   ```powershell
   .\DisplayLayoutManager.ps1
   ```
3. Follow the prompts to select or capture a layout.

### 3. Capturing a Layout

- Choose `C` when prompted to capture the current window arrangement.
- Enter a name and optional description for the new layout.
- The script will save the current state of all open windows to the configuration file.

### 4. Applying a Layout

- Select a layout by its number from the list.
- The script will start/stop/position applications as defined in the layout.

---

## How It Works

- Uses Windows API (user32.dll) for window manipulation.
- Uses Windows Forms to enumerate displays.
- Reads and writes TOML configuration for layouts.
- Starts and positions applications in the background (no terminal logs from started apps).

---

## Customization

- Edit `layouts-config.toml` to add or modify layouts and application settings.
- You can manually add new applications or change window states and positions.

---

## Troubleshooting

- **App not starting:** Ensure the `Path` is correct and the executable exists.
- **Window not moving:** Some apps may not support programmatic window movement.
- **Permissions:** Run PowerShell as Administrator if you encounter access issues.

> Feel free to open an issue on GitHub if you encounter any problems or have suggestions for improvements.

---

## Author

Created by Tsuki Kami
- [Github](https://github.com/kami-tsuki)
- [Web](https://tsuki.wtf)
- [Contact/Support](mailto:support.lm@tsuki.wtf)---

## Contributions

Feel free to fork and improve this script for your own needs!
Give credit if you use or modify it. 

