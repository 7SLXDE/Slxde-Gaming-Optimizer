# Slxde Gaming Optimizer

A Windows gaming optimization utility built with PowerShell.

## Version

Current build: **v0.9.65 Debloat Polish**

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


## v0.7.6

### Fixed
- SFC now opens in a separate command window with clear instructions.
- DISM now opens in a separate command window with clear instructions.
- Cleanup / Health Check no longer appears frozen during repair tools.
- AMD Adrenalin launcher checks common install paths.
- GPU Tools now includes AMD/NVIDIA shader cache folder shortcuts.


## v0.7.7

### Fixed / Improved
- Optimal Power Plan now applies fuller desktop gaming power settings:
  - Turn off display: Never
  - Sleep after: Never
  - Hibernate after: Never
  - Hard disk turn off: Never
  - Wake timers: Disabled
  - USB selective suspend: Disabled
  - PCIe link state power management: Off where supported
- Existing Optimal Power Plan is now re-used and re-optimized instead of creating duplicates.


## v0.7.8

### Safety Polish
- Added clearer System File Check warning before running SFC.
- Added clearer Windows Image Repair warning before running DISM.
- DISM warning now explains it can look stuck at certain percentages.
- Repair command windows now remind users to restart if repairs are made.
- Minor restart wording polish.


## v0.8.0 Stable Engine

### Added
- Backup / Restore menu.
- Create Backup Now.
- Restore Latest Backup.
- Show Available Backups.
- Open Backup Folder.
- Backups are saved to:
  `C:\ProgramData\Slxde Gaming Optimizer\Backups`

### Backup includes
- Restore point attempt.
- Active power plan info.
- Optimal Power Plan export where available.
- Key registry areas used by the optimizer:
  - Game Mode / Game Bar / Game DVR
  - Per-game GPU preference
  - Explorer Advanced
  - Mouse settings
  - Multimedia SystemProfile
  - Location privacy setting

### Notes
- Restoring registry backups may require a restart.
- Restore points can be skipped by Windows if System Protection is disabled or if a restore point was created recently.
- This is the stable console-engine base before the GUI/button app work.


## v0.8.1

### Added
- Balanced Power Plan option.
- Laptop / Temperature Safety menu.
- Laptop detection using chassis/battery info.
- Warning before applying the Optimal Power Plan on detected laptops.
- Clear laptop guidance:
  - Use Balanced on battery.
  - Use Optimal Power Plan only when plugged in.
  - Monitor CPU/GPU temperatures.
  - Switch back to Balanced if temperatures or fan noise are too high.

### Power Plan Notes
- Optimal Power Plan is desktop/performance focused.
- Balanced Power Plan is safer for gaming laptops and battery use.


## v0.8.2

### Safety Wording Polish
- Laptop warning is now shown as a top note in Windows Tweaks instead of as a numbered tweak.
- Reworded safety language to cover:
  - gaming laptops
  - small-form-factor PCs
  - stock/basic coolers
  - dusty systems
  - poor airflow
  - already-high temperatures
- Main safety section renamed to Laptop / Cooling Safety.


## v 0.9.65 GUI Preview

### Added
- First WPF GUI app under:
  `Gui\SlxdeOptimizer.App`
- Dark purple / galaxy-inspired SLXDE interface.
- Sidebar navigation.
- Dashboard, Gaming, Windows, GPU, Network, Display, Cleanup, Backup and Logs pages.
- Glowing action cards and Apply buttons.
- Early PowerShell runner for connecting GUI buttons to existing modules.
- Several buttons already wired to existing PowerShell functions.

### Notes
- This is a GUI preview shell.
- Some buttons are intentionally marked PREVIEW and will be wired in later GUI builds.
- Console engine remains available.


## v 0.9.65 GUI Preview

### Fixed
- GUI PowerShell runner now works when the project path contains apostrophes.
- Fixes paths like:
  `Slxde's Gaming Opti`
- Runner now creates a temporary `.ps1` script instead of using one giant quoted command.
- Slight bottom status sizing adjustment.


## v 0.9.65 GUI Preview

### Fixed
- GUI buttons now use PowerShell here-strings for paths.
- Fixes apostrophes in repo paths properly.
- GUI runner now loads all optimizer modules before running a function.
- Fixes shared helper errors when calling individual module functions from the GUI.


## v 0.9.65 GUI Polish

### Changed
- Moved SLXDE'S OPTI branding to the centre of the top bar.
- Brighter white typography for stronger contrast.
- Reworked sidebar icons using a consistent Windows icon style.
- Replaced cheap letter-card icons with proper meaningful icons.
- Added active sidebar highlighting.
- Slightly more original header layout to move away from the HD OPTI look.
- Improved bottom status sizing and spacing.


## v 0.9.65 GUI Build Fix

### Fixed
- Removed unsupported WPF `LetterSpacing` property from TextBlocks.
- Fixes build error MC3072.


## v 0.9.65 GUI Module Fix

### Fixed
- GUI no longer depends on exact module filenames.
- It now loads every `.ps1` file from the `Modules` folder first.
- Fixes errors like:
  `Module not found: Modules\GamingTweaks.ps1`
  `Module not found: Modules\Analyzer.ps1`


## v 0.9.65 GUI Bridge Fix

### Fixed
- Added `GuiBridge.ps1` with GUI-safe wrapper functions.
- Fixed Analyze PC button using a real GUI analysis function.
- Fixed Optimal Power Plan button to avoid hidden console confirmation prompts.
- Fixed Windows Appearance button to use the correct function name.
- Wired View Latest Log, SFC, DISM and Open Backup Folder through GUI-safe wrappers.


## v 0.9.65 GUI Cleanup

### Changed
- Removed bottom CPU/RAM/GPU ready status cards.
- Removed System Status / All systems nominal panel.
- Removed Re-scan System button.
- Removed sidebar "Optimise. Enhance. Dominate." branding box.
- Main UI is cleaner and less cluttered.


## v 0.9.65 GUI Individual Cards

### Changed
- Removed the big shared main content box around the tweak list.
- Each tweak card now feels more individual.
- Increased card spacing.
- Slightly stronger card borders and darker gradients.
- Cleaner, less boxed-in page layout.


## v 0.9.65 GUI Remove Grouped Cards

### Changed
- Removed the grouped "Apply All Safe Gaming Tweaks" card from the Gaming page.
- Gaming page now focuses on individual tweak cards only.


## v 0.9.65 GUI Text Polish

### Changed
- Cleaned GPU page wording.
- Replaced weak "Attempts to open..." text with stronger "Opens..." wording.


## v 0.9.65 GUI Network Wiring

### Fixed
- Network page buttons now say APPLY instead of PREVIEW.
- Network Pack is wired to the real network pack function.
- Reset Network Stack is wired to the real reset function.
- Show Active Adapter Info now displays active adapter details from the GUI.


## v 0.9.65 GUI Wire Remaining Pages

### Fixed
- Display page buttons now use APPLY and are wired.
- Backup / Restore page buttons now use APPLY where functional.
- Logs page button now uses APPLY and reads the latest log.
- Network wiring from v 0.9.65 is included.


## v 0.9.65 GUI Merge Gaming + Windows

### Changed
- Removed separate Gaming section from the sidebar.
- Merged gaming tweaks into the Windows page.
- Windows page now contains:
  - Game Mode
  - Game DVR / Xbox Capture
  - HAGS
  - Windowed Optimizations
  - Mouse Acceleration
  - Power plans
  - Windows appearance
  - Background apps
  - Location tracking
  - USB power saving


## v 0.9.65 GUI Controller / KBM

### Changed
- Moved power plans to the top of the Windows page.
- Moved Disable USB Power Saving out of Windows.
- Added new Controller / KBM sidebar tab.
- Controller / KBM page includes:
  - Disable USB Power Saving
  - Disable Mouse Acceleration
  - Input Responsiveness
  - Open Game Controllers
  - Open Mouse Settings
  - Controller Overclock Info
  - Memory Integrity Settings

### Safety
- Controller overclocking is not applied automatically.
- Memory Integrity is opened as a settings page, not disabled silently.
- The app warns about security trade-offs instead of changing risky settings without consent.


## v 0.9.65 GUI Layout Polish

### Changed
- Made SLXDE'S OPTI title larger, whiter and more central.
- Widened and improved the sidebar.
- Sidebar buttons are taller, clearer and fill the side panel better.
- Added a small clean GUI status footer in the sidebar.
- Kept the old "Optimise / Enhance / Dominate" branding box removed.


## v 0.9.65 GUI Windows Restore

### Added
- Allow Optimizer Scripts at the top of Windows.
- Restore Windows Defaults under Allow Optimizer Scripts.
- Restore Windows Defaults reverts main Windows, gaming and power-plan optimizer changes.

### Changed
- Windows page order now starts with:
  1. Allow Optimizer Scripts
  2. Restore Windows Defaults
  3. Balanced Power Plan
  4. Optimal Power Plan


## v 0.9.65 GUI GPU MSI + NVIDIA

### Added
- Enable GPU MSI Mode button under GPU.
- Check GPU MSI Status button.
- NVIDIA Best Driver Profile Helper.
- NVIDIA shader cache folder shortcut.

### Notes
- GPU MSI Mode requires restart.
- NVIDIA Best Driver Profile Helper opens NVIDIA Control Panel and shows recommended settings.
- Full automatic NVIDIA profile writing needs NVIDIA Profile Inspector/NVAPI and is not silently forced yet.


## v 0.9.65 GUI Windows Display + Header

### Changed
- Removed Display from the sidebar.
- Removed Logs from the sidebar.
- Moved display tools into Windows.
- Added Set All Displays to Max Refresh Rate.
- Made SLXDE'S OPTI title larger and brighter.
- Removed the awkward line behind the title.

### Notes
- Max refresh applies the highest available refresh rate at each display's current resolution.
- Display may briefly flicker when applying.


## v 0.9.65 GUI Quality of Life

### Changed
- Removed Quick Optimise from Dashboard.
- Removed Open Advanced Display Settings from Windows.
- Removed Set All Displays to Max Refresh Rate from Windows.
- Added Quality of Life back to the sidebar.

### Added Quality of Life tweaks
- Enable Right-click End Task.
- Explorer opens This PC.
- Reduce menu / hover delay.
- Disable startup apps delay.
- Open Startup Apps settings.
- Restart Explorer.


## v 0.9.65 GUI Controller Cleanup

### Changed
- Removed Controller Overclock Info.
- Removed Memory Integrity Settings.
- Removed Open Game Controllers.
- Removed Open Mouse Settings.

### Controller / KBM now keeps
- Disable USB Power Saving.
- Disable Mouse Acceleration.
- Input Responsiveness.


## v 0.9.65 GUI Network Pack Fix

### Fixed
- Network Pack now uses a GUI-safe network wrapper.
- Network Pack returns a clear completion message.
- Skips unsupported adapter properties quickly.
- Added a 60-second timeout to GUI PowerShell actions so buttons cannot appear stuck forever.


## v 0.9.65 GUI MSI Analyze

### Changed
- Removed Check GPU MSI Status from the GPU page.
- Analyze PC now includes GPU MSI Mode status.
- GPU page keeps Enable GPU MSI Mode only.


## v 0.9.65 GUI Header + Windows Order

### Changed
- Forced Windows page order:
  1. Allow Optimizer Scripts
  2. Restore Windows Defaults
  3. Load Balanced Power Plan
  4. Load SLXDE Power Plan
- Replaced Windows icon with a clearer Windows-style symbol.
- Reworked the SLXDE'S OPTI title into a cleaner, brighter header.
- Removed the cheap-looking line behind the title.


## v 0.9.65 GUI GPU Guides

### Added
- AMD/NVIDIA branded GPU cards.
- AMD Driver Settings Guide window.
- Bundled AMD Adrenalin screenshots into app assets.
- GPU page reorganised into AMD and NVIDIA helper actions.

### Notes
- AMD Driver Settings Guide opens a scrollable image guide with Next/Previous.
- NVIDIA helper still opens NVIDIA Control Panel and shows recommended settings.


## v 0.9.65 GUI GPU Sections Fix

### Fixed
- GPU page now has clear section headers:
  - All GPU Users
  - AMD GPU Settings
  - NVIDIA GPU Settings
- AMD and NVIDIA cards use branded text markers.
- AMD Driver Settings Guide opens the bundled screenshots in a proper guide window.
- AMD guide images are copied into the app output automatically.


## v 0.9.65 GPU Clean Layout

### Changed
- GPU page now only has:
  - MSI Mode
  - NVIDIA Driver Settings
  - AMD Settings
  - Open AMD Adrenalin
- AMD and NVIDIA cards now use clear branded text/logo markers.
- AMD Settings opens the bundled AMD best settings screenshot guide.
- AMD/NVIDIA shader cache shortcuts moved to Clean-up / Health.


## v 0.9.65 GPU Build Fix

### Fixed
- Fixed duplicate card icon variable declarations in MainWindow.xaml.cs.
- Fixes CS0128 build errors for cardIconText, cardIconFont, cardIconSize and cardIconBrush.


## v 0.9.65 GPU Hard Clean

### Fixed
- GPU page now has ONLY:
  - MSI Mode
  - NVIDIA Driver Settings
  - AMD Settings
- Removed all extra GPU cards:
  - Open AMD Adrenalin
  - Open NVIDIA Control Panel
  - AMD shader cache
  - NVIDIA shader cache
  - Windows graphics settings
- AMD/NVIDIA shader cache shortcuts are now in Clean-up / Health.
- AMD Settings opens the bundled AMD screenshots guide.


## v 0.9.65 GPU Actually Clean

### Fixed
- Hard-replaced the actual GPU page function.
- GPU page now contains only:
  - MSI Mode
  - NVIDIA Driver Settings
  - AMD Settings
- Removed old GPU items from the GPU page:
  - Open Windows Graphics Settings
  - Open AMD Adrenalin
  - Open NVIDIA Control Panel
  - NVIDIA Best Driver Profile Helper
  - AMD/NVIDIA shader cache
- Shader cache shortcuts are placed in Clean-up / Health.


## v 0.9.65 Windows Order + AMD Guide

### Changed
- Removed the first AMD guide image.
- Windows page order is now locked:
  1. Enable Scripts
  2. Revert Windows Opti
  3. Load Balanced Power Plan
  4. Load SLXDE Power Plan
- Rest of Windows tweaks sit underneath those.


## v 0.9.65 Header + Status + Log Fix

### Changed
- Removed the GUI Preview box from the sidebar.
- Top header now uses the provided SLXDE'S OPTI image logo.
- Status pill is cleaner and shorter.
- GPU sidebar/page icon changed away from the generic chip.
- Dashboard View Latest Log is wired to a fixed log lookup.

### Fixed
- Latest Log now checks:
  - repo Logs folder
  - ProgramData Slxde Gaming Optimizer logs
  - ProgramData Slxde's Gaming Opti logs


## v 0.9.65 Visual Mockup Polish

### Changed
- Pushed the app style closer to the provided mockup:
  - darker, cleaner full-window layout
  - larger centered logo banner
  - cleaner status pill
  - subtler card borders
  - more premium card spacing and sizing
  - stronger sidebar spacing
- Renamed visible "SLXDE Power Plan" wording to "Optimal Power Plan".


## v 0.9.65 Exact Mockup Style

### Changed
- Reworked the actual WPF app toward the provided mockup:
  - exact cropped top banner asset from the reference image
  - darker full-window background
  - reference-style version pill and status pill
  - tighter sidebar proportions and spacing
  - darker main panel and cards
  - larger dashboard/card typography
  - stronger purple button styling
  - more GPU-like sidebar icon
- Kept the visible power-plan wording as Optimal Power Plan.


## v 0.9.65 Match Reference UI

### Changed
- Actual WPF app now uses sidebar icon image assets generated from the reference UI.
- Fixed sidebar clipping by shrinking nav text/icons and widening usable label space.
- Rebuilt the top banner as a sharper 2x asset cropped from the reference UI.
- Reduced oversized card/icon typography from v 0.9.65.
- Kept visible wording as Load Optimal Power Plan.


## v 0.9.65 Icon + Spacing Fix

### Fixed
- Regenerated sidebar icon image assets with a larger crop and padding so they are not cut off.
- Sidebar is slightly wider and nav rows have more spacing.
- Sidebar labels use ellipsis only if needed, instead of clipping awkwardly.
- Cards have more vertical spacing so Windows/GPU pages feel less bunched together.
- Apply buttons are a little narrower to avoid right-side clipping.


## v 0.9.65 Icon Size + Page Spacing Fix

### Fixed
- Sidebar icons regenerated again with much larger visible strokes.
- Sidebar icon display size increased.
- Page header icon display size increased.
- Card icons increased.
- Page headers and cards have more vertical spacing.
- Sidebar/page layout should feel less bunched together.


## v 0.9.65 Sidebar Final Fix

### Fixed
- Replaced the tiny cropped sidebar images with clean drawn white icon assets.
- Sidebar icons are now larger and visible.
- Sidebar width increased.
- Sidebar rows are compact enough that Backup / Restore stays visible.
- Sidebar has a scroll fallback on smaller windows.
- Page cards have more vertical breathing room.


## v 0.9.65 Actual GUI Reference Style

### Fixed
- Used the exact sidebar logo strip provided by the user for the nav icon assets.
- Icons are larger and sharper than v 0.9.65.
- Sidebar is wider and less compressed.
- Backup / Restore should remain visible.
- Page/card spacing adjusted so the app feels less squished.


## v 0.9.65 Launch Repair

### Fixed
- Forces WPF startup through App.xaml.cs so dotnet run opens MainWindow instead of exiting.
- Startup exceptions now show a message box instead of silently closing.
- Replaced broken/tiny icon assets with clean high-resolution icons.
- Kept sidebar layout balanced so Backup / Restore remains visible.
- Kept visible wording as Load Optimal Power Plan.


## v 0.9.65 Light Blue Theme

### Changed
- Converted the actual WPF GUI from purple to light-blue/cyan styling.
- Recoloured the top SLXDE banner to blue.
- Updated sidebar active state, card borders, buttons, glows, panels and warnings to blue.
- Kept the launch/startup repair from v 0.9.65.
- Kept visible wording as Load Optimal Power Plan.


## v 0.9.65 Icon Polish

### Changed
- Remade the actual GUI navigation icon PNG assets.
- Kept the Windows icon.
- Improved Dashboard, GPU, Network, Controller / KBM, Clean-up / Health, Quality of Life and Backup / Restore.
- Icons are high-res transparent white PNGs stored in Assets/Nav.
- Kept the light-blue theme from v 0.9.65.


## v 0.9.65 Icon Rework

### Changed
- Kept Windows and Network icons from v 0.9.65.
- Reworked Dashboard, GPU, Controller / KBM, Clean-up / Health, Quality of Life and Backup / Restore icons.
- Icons remain transparent white PNGs in Assets/Nav.
- Kept the light-blue theme.


## v 0.9.65 Reference Icon Fix

### Changed
- Kept Windows and Network icons unchanged.
- Replaced Dashboard, GPU, Controller / KBM, Clean-up / Health, Quality of Life and Backup / Restore with scaled icons extracted from the preferred sidebar reference strip.
- Fixed the previous scaling mistake that made extracted icons tiny.
- Added Assets/Nav/ICON_PREVIEW_v 0.9.65.png for quick checking.


## v 0.9.65 Blue Icon Boxes + GPU/Cleanup Fix

### Changed
- Changed remaining purple icon/card boxes to blue.
- Reworked GPU icon to look more like a real graphics card.
- Reworked Clean-up / Health icon so the shield/check/spark are clearer and less merged.
- Kept Windows and Network icons unchanged.
- Added Assets/Nav/ICON_PREVIEW_v 0.9.65.png.


## v 0.9.65 Revert Icons + Real Blue Boxes

### Changed
- Reverted from the worse v 0.9.65 icon direction.
- Kept Dashboard, Windows, Network, Quality of Life and Backup / Restore.
- Remade only GPU, Controller / KBM and Clean-up / Health.
- Directly fixed the purple page icon box in MainWindow.xaml:
  - BorderBrush #8F35FF -> #2FA8FF
  - Background #22104D -> #052B5C
- Also fixed leftover purple glow/style values in App.xaml and MainWindow.xaml.
- Added Assets/Nav/ICON_PREVIEW_v 0.9.65.png.


## v 0.9.65 Approved Icons

### Changed
- Inserted the approved generated-style icons into the actual GUI app.
- Replaced only:
  - GPU
  - Controller / KBM
  - Clean-up / Health
- Kept Dashboard, Windows, Network, Quality of Life and Backup / Restore unchanged.
- Converted the approved icons into transparent white 256x256 PNG nav assets.
- Re-applied the real blue icon-box colour fixes.
- Added Assets/Nav/ICON_PREVIEW_v 0.9.65.png.


## v 0.9.65 Banner Release Fix

### Fixed
- Fixed the top SLXDE'S OPTI banner disappearing when running the built .exe.
- Brand/Nav/AMD guide PNG assets now copy to both build output and publish output.
- Added a text fallback behind the banner image so the SLXDE'S OPTI name still appears even if the image fails.
- Added Gui/SlxdeOptimizer.App/Publish-Release.ps1 to create a release zip for laptop/friends.


## v 0.9.65 Embedded Asset Fix

### Fixed
- Fixed sidebar icons showing as weird square glyphs.
- Fixed banner falling back to plain text when the app is opened from the .exe.
- PNG assets are now embedded as WPF Resources instead of relying only on copied output folders.
- Nav icons now load from embedded resources first, then fallback to output files.
- Fallback icons now show readable symbols instead of nav_* text boxes if an image ever fails.


## v 0.9.65 Banner and Modules Fix

### Fixed
- Fixed scripts failing with `Modules folder not found: C:\Modules`.
- Modules are now copied into Debug/Release/publish output automatically.
- PowerShellRunner now checks the executable folder, current folder and parent folders for Modules.
- PowerShellRunner no longer falls back to C:\.
- Banner image now uses a proper WPF pack URI:
  `pack://application:,,,/Assets/Brand/slxde_opti_banner_blue.png`
- Publish script updated to create `SLXDE-Gaming-Optimizer-v 0.9.65-win-x64.zip`.


## v 0.9.65 Card Icon Fix

### Fixed
- Fixed action-card icons showing as dots.
- Sidebar PNG icons still load from embedded resources.
- Missing sidebar icon fallbacks still show readable symbols.
- Normal action-card Segoe MDL2 glyph icons now render properly again.
- Kept v 0.9.65 banner/modules fixes.


## v 0.9.65 Dashboard Game Mode

### Added
- Added SLXDE Performance Mode card to Dashboard.
- Auto CPU recommendation: AMD/Ryzen uses AMD Balanced, Intel/Core uses Intel Optimal.
- Game Mode toggle applies safe gaming state: Game Mode on, Game DVR/Captures off, Xbox Game Bar controller shortcut off, Do Not Disturb on while active.

### Fixed
- View Latest Log no longer pops up when no logs exist; it updates status only.
- Input Responsiveness warning now says Restart recommended.
- Input Responsiveness description is now: Applies safe input responsiveness tweaks.

### Planned
- Game Configs page with esports-tuned game config presets, original config backups and restore buttons.


## v 0.9.65 Game Mode Build Fix

### Fixed
- Fixed v 0.9.65 build error where `SetStatus` did not exist in the current project.
- Game Mode now uses the app's existing status update method.
- Kept Dashboard SLXDE Performance Mode card.
- Kept Latest Log no-popup behavior.
- Kept Input Responsiveness text changes.


## v 0.9.65 Stable Game Mode Info Fix

### Fixed
- Rebuilt from the last stable compiling v 0.9.65 base.
- Fixes the broken v 0.9.65/v 0.9.65 MainWindow click-handler build errors.
- Keeps all sidebar click handlers intact.
- Keeps Do Not Disturb removed from Game Mode.
- Adds Dashboard Game Mode instructions/tips safely.
- Keeps Input Responsiveness wording:
  - `Applies safe input responsiveness tweaks.`
  - `Restart recommended`


## v 0.9.65 Performance Mode + Game Configs

### Changed
- Renamed SLXDE Game Mode to SLXDE'S Performance Mode to avoid confusion with Windows Game Mode.
- Moved the Performance Mode explanation/tips above the toggle card.
- Removed the SLXDE MENU label from the sidebar.
- Added GAME CONFIGS sidebar section.

### Added
- Game Configs page with starter esports config helpers:
  - COD BO7
  - Fortnite
  - Rocket League
  - CS2
- Game configs create backups before modifying files.
- Added Open Game Config Backups button.
- Added Restore Latest Game Config Backup placeholder note for manual restore.


## v 0.9.65 COD BO7 Config

### Changed
- Game Configs now uses COD BO7 instead of generic Call of Duty.
- COD BO7 button now calls `Apply-GuiCodBo7Config`.

### COD BO7 preset
- Creates a backup first.
- Attempts to set RendererWorkerCount to 7.
- Attempts to turn heaps/cache-style extras off where matching keys exist.
- Attempts to turn motion blur, film grain, depth of field, ray tracing, SSR, AO, texture streaming and similar competitive visual extras off.
- Attempts low/off competitive visual settings.
- Detects GPU:
  - NVIDIA: writes DLSS / Transformer-style preference notes.
  - AMD: writes FidelityFX CAS preference.
- Adds a SLXDE note block so the user can verify in-game settings.


## v 0.9.65 COD BO7 Lines Fix

### Fixed
- Fixed COD BO7 config error:
  `Cannot bind argument to parameter 'Lines' because it is an empty string.`
- COD BO7 config editing now uses a safer ArrayList handler.
- Empty or odd COD config files are handled properly.
- Backups still happen before changing the config.


## v 0.9.65 COD BO7 Exact Keys

### Fixed
- COD BO7 Config now targets the real `Documents\Call of Duty\players\s.1.0.cod24.txt0/txt1` files.
- Ignores the tiny metadata file.
- Uses the exact BO7 key format found in the user's config:
  - RendererWorkerCount
  - GPUUploadHeaps
  - AMDFidelityFX
  - AMDContrastAdaptiveSharpeningStrength
  - AATechniquePreferredMP
  - VideoMemoryScaleMP
  - DepthOfField
  - TextureQuality
  - ShadowQuality
  - SSRQuality
  - DxrMode
  - VRS
  - and more.
- Keeps backup-before-change behavior.


## v 0.9.65 COD BO7 Exact Graphics Preset

### Changed
- COD BO7 Config is now COD BO7 Graphics Config.
- It copies the user's exact BO7 graphics/performance settings from the provided config.
- It does not copy:
  - audio settings
  - controls
  - mouse/controller settings
  - SoundInputDevice / SoundOutputDevice / VoiceOutputDevice
  - Monitor / GPUName / LastUsedGPU
  - personal device IDs
- Still creates a backup first.

### Exact graphics/performance examples copied
- RendererWorkerCount = 7
- GPUUploadHeaps = false
- AMDFidelityFX = CAS
- AMDContrastAdaptiveSharpeningStrength = 1.000000
- AATechniquePreferredMP = SMAA
- TextureQuality = 3
- GraphicsQuality = Basic
- ShadowQuality = Very_Low
- ParticleQuality = very low
- SSRQuality = Off
- DxrMode = Off
- VRS = true
- VideoMemoryScaleMP = 0.700000


## v 0.9.65 Game Config Wording + No CS2

### Changed
- Updated Game Config descriptions:
  - COD BO7: Applies best BO7 config for max FPS.
  - Fortnite: Applies best Fortnite config for max FPS.
  - Rocket League: Applies best Rocket League config for max FPS.
- Removed CS2 Config from the visible Game Configs page for now.


## v 0.9.65 Debloat

### Added
- New sidebar page: Debloat.
- Chris Titus-style flow:
  - Minimal Debloat preset
  - Gaming Debloat preset
  - Advanced Debloat preset
  - Individual tick/untick options
  - Apply Selected Debloat
  - Restore Debloat Defaults


## v0.9.65 Debloat Polish

### Changed
- Debloat sidebar item moved between Game Configs and Clean-up / Health.
- Debloat icon replaced with the broom logo.
- Removed Chris Titus wording from the Debloat helper text.
- Added cleaner plain-English descriptions for every Debloat option.
- Debloat option cards are slightly taller for cleaner text layout.
