# Slxde Gaming Optimizer

A Windows gaming optimization utility built with PowerShell.

## Version

Current build: **v0.7.5**

## Features

### Analyzer
- Windows version detection
- CPU detection
- GPU detection
- RAM detection
- Motherboard detection
- BIOS detection
- Game Mode detection
- Game DVR detection
- Xbox Capture detection
- HAGS detection
- Windowed Optimizations detection
- Power plan detection
- Gaming Score

### Gaming Tweaks
- Enable Game Mode
- Disable Game DVR / Xbox Capture
- Enable Hardware Accelerated GPU Scheduling
- Enable Optimizations for Windowed Games
- Disable Mouse Acceleration
- Create Restore Point
- Restore Gaming Defaults

### Windows Tweaks
- Create SLXDE Power Plan
- Load Balanced Power Plan
- Optimize Windows Appearance
- Disable Background Apps
- Disable Location Tracking
- Disable USB Power Saving
- Disable Startup Apps Delay
- Open Max Refresh Rate Settings
- Open Startup Apps Settings

### Cleanup / Health
- Delete Temp Files
- Delete Log Files
- Open Disk Cleanup
- System File Check
- Windows Image Check and Repair

### Quality of Life
- Right-click End Task
- Explorer opens to This PC
- Reduce Mouse Hover Time
- Disable Startup Apps Delay

### Network
- Reset Network Stack
- Disable NIC Power Saving
- Open Network Adapters

## Notes

Run PowerShell as Administrator for system-level tweaks.

Some settings may require a restart or sign-out to fully apply.


## v0.7.1

### Fixed
- Removed noisy/invalid `powercfg -setacvalueindex` calls from SLXDE Power Plan creation.
- Cleaner output when creating and activating the SLXDE Power Plan.


## v0.7.2

### Fixed
- Suppressed unsupported `powercfg` parameter output from USB power saving tweak.
- USB power saving tweak now applies registry/device changes without showing `Invalid Parameters` spam.


## v0.7.3

### Added
- Display Tweaks tab
- Show current display refresh info
- Max refresh helper via Windows Advanced Display Settings
- GPU Tools tab
- Windows Graphics Settings shortcut
- NVIDIA Control Panel shortcut
- AMD Adrenalin shortcut
- High Performance GPU preference helper
- Overlay detection
- Shader cache cleanup
- Advanced optional registry tweaks:
  - NetworkThrottlingIndex
  - SystemResponsiveness

### Notes
- Max refresh rate uses Windows Settings for safety instead of forcing unsupported display modes.
- Advanced registry tweaks are optional and reversible.


## v0.7.4

### Fixed
- NIC power saving no longer reports a hard failure on adapters/drivers that do not support `Set-NetAdapterPowerManagement`.
- Network tweak now applies supported changes and logs unsupported adapter cases.


## v0.7.5

### Added
- Gaming Tweaks now has a proper menu with one-by-one actions.
- Network Pack with supported adapter tweaks:
  - Energy Efficient Ethernet
  - Green Ethernet
  - Power Saving Mode
  - Wake on Magic Packet
  - Wake on Pattern Match
  - Interrupt Moderation
  - Speed & Duplex Auto Negotiation
- IPv6 Disable / Enable options
- Active Adapter Info screen
- Per-game fullscreen optimization toggle
- Per-game high performance GPU preference
- Confirmation prompts for sensitive actions

### Changed
- Main dashboard is cleaner.
- Apply All Gaming Tweaks moved inside Gaming Tweaks section.
- Network reset is clearly separate from Network Pack.
