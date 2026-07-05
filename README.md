# Slxde Gaming Optimizer

A Windows gaming optimization utility built with PowerShell.

## v0.6.1

### Analyzer
- Hardware detection
- Game Mode detection
- Game DVR detection
- Xbox Capture detection
- HAGS detection
- Windowed Optimizations detection
- Power Plan detection
- Mouse Acceleration detection
- Gaming Score

### Safe Tweaks
- Create Restore Point
- Enable Game Mode
- Disable Game DVR / Xbox Capture
- Enable HAGS
- Enable Optimizations for Windowed Games
- Disable Mouse Acceleration

## Run

```powershell
cd "$HOME\Documents\Slxde's Gaming Opti"
Unblock-File -Path ".\GamingOptimizer.ps1"
Get-ChildItem ".\Modules" -Filter *.ps1 | Unblock-File
.\GamingOptimizer.ps1
```
