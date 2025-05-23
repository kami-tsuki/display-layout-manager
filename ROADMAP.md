﻿# DisplayLayoutManager.ps1 Roadmap

## Planned Features & Improvements

- [ ] **Script Parameter Support** _(Priority: High)_
  - [ ]  `--no-clear`/`-nc` option to prevent clearing the screen before displaying the layout.
  - [ ]  `--no-preview`/`-np` option to skip the layout preview. (when preview is implemented)
  - [X]  `--layout <0|1|C>` option to specify the layout to apply.
     - create should become another option later
  - [ ]  `--help`/`-h` option to display help information.
  - [ ]  `--version`/`-v` option to display the script version.
  - [x]  `--config <path>` option to specify a custom configuration file path.
  - [ ] `--debug` option to enable debug mode for verbose output.
  - [ ]  `--no-log` option to disable logging.
- [ ] **Paramter add in Shortcut Creator** _(Priority: High)_
  - Add the ability to create shortcuts with parameters for the script.
  - Also apply custom names and icons for the shortcuts.
- [ ] **Automated Testing** _(Priority: Medium)_
  - Implement tests for the PowerShell script.
  - Implement tests for the TOML configuration file.
- [ ] **Undo Functionality** _(Priority: Medium)_
  - Add the ability to undo the last layout change.
- [ ] **Support for Non-Windowed Applications** _(Priority: High)_
  - Allow management of applications that do not create a visible window. (e.g., background processes, services).
- [ ] **Application Start Parameters** _(Priority: Medium)_
  - Add support for passing custom parameters when starting applications.
- [ ] **Hotkey Integration** _(Priority: Medium)_
  - Enable hotkey support for quick layout switching and actions.
- [ ] **Profile-Based Layouts** _(Priority: Medium)_
  - Allow users to create and switch between multiple user profiles, each with its own set of layouts.
- [ ] **Scheduled Layout Switching** _(Priority: Low)_
  - Enable automatic layout changes based on time, day, or events (e.g., work hours, meetings).
- [ ] **Notification Integration** _(Priority: Low)_
  - Provide desktop notifications when layouts are applied or if errors occur.
- [ ] **GUI Frontend** _(Priority: Low)_
  - Develop a simple graphical interface for managing layouts and settings.
- [ ] **Cloud Sync/Backup** _(Priority: Low)_
  - Support syncing layouts to the cloud or backing up configuration files.
- [ ] **Import/Export Layouts** _(Priority: Medium)_
  - Allow users to import/export layouts for sharing or backup.
- [ ] **Per-Application Custom Scripts** _(Priority: Low)_
  - Run custom scripts or commands before/after starting or positioning applications.
- [ ] **Layout Preview** _(Priority: Low)_
  - Show a visual preview of the layout before applying it.
- [ ] **Layout Versioning** _(Priority: Low)_
  - Keep a history of changes to layouts and allow users to revert to previous versions.
- [ ] **Layout Validation** _(Priority: Medium)_
  - Validate configuration files for errors or missing fields before applying layouts.
- [ ] **Error Reporting & Logging** _(Priority: Medium)_
  - Provide detailed error logs and optionally send error reports for troubleshooting.
- [ ] **Multi-User Support** _(Priority: Low)_
  - Allow different users to have their own sets of layouts and preferences.
- [ ] **Command-Line Output Customization** _(Priority: Low)_
  - Allow users to customize the verbosity and format of command-line output.
- [ ] **Integration with Task Scheduler** _(Priority: Low)_
  - Schedule layout changes using Windows Task Scheduler integration.
- [ ] **Layout Dependency Management** _(Priority: Low)_
  - Specify dependencies between applications or layouts (e.g., start app B only if app A is running).
- [ ] **Portable Mode** _(Priority: Low)_
  - Allow the script and its configuration to run from a USB stick or portable drive without installation.
---

Feel free to contribute ideas or improvements!
