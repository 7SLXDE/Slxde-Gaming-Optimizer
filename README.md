# Slxde Gaming Optimizer

A Windows gaming optimization utility built with PowerShell.

## v0.6.2

### Added
- Restore / Undo Gaming Tweaks
- Restore Game Mode default/on
- Restore Game DVR and Xbox Capture default/on
- Restore HAGS to Windows default
- Restore Windowed Optimizations to Windows default
- Restore Mouse Acceleration to Windows default

### Existing Features
- Hardware analysis
- Game Mode detection
- Game DVR detection
- Xbox Capture detection
- HAGS detection
- Windowed Optimizations detection
- Power Plan detection
- Gaming Score
- Safe Gaming Tweaks
- Restore Point creation
- Logs

## Run

```powershell
cd "$HOME\Documents\Slxde's Gaming Opti"
Unblock-File -Path ".\GamingOptimizer.ps1"
Get-ChildItem ".\Modules" -Filter *.ps1 | Unblock-File
.\GamingOptimizer.ps1
```
