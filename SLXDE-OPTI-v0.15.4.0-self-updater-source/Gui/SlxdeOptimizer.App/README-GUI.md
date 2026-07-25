# SLXDE OPTI

Version: v0.15.4.0 Reliable in-app updates

## What this is

This is the Windows WPF app for Slxde Gaming Optimiser.

It includes the clean dark-navy shell, dashboard system summary, Windows/GPU/network/input tools, game configs, selectable debloat profiles, cleanup, quality-of-life tools and backup/restore helpers.

## How to open

Open PowerShell in the repository root and run:

`dotnet restore .\Gui\SlxdeOptimizer.App\SlxdeOptimizer.App.csproj`

`dotnet run --project .\Gui\SlxdeOptimizer.App\SlxdeOptimizer.App.csproj`

Or open this file in Visual Studio:

`Gui\SlxdeOptimizer.App\SlxdeOptimizer.App.csproj`

Then press:

`Ctrl + F5`

or click:

`Start Without Debugging`

Run PowerShell as Administrator before launching if you want system-level actions to work.

## v0.15.4.0

- Added a complete in-app update flow using published GitHub Releases.
- Shows the new version and release notes before installing.
- Downloads updates with visible percentage progress.
- Requires and verifies the release installer SHA-256 checksum.
- Closes the current app, installs silently and reopens SLXDE OPTI automatically.
- GitHub release builds now attach both the installer and its checksum.

## v0.15.3.6

- Replaced the unreliable native visual-settings refresh with a safe Windows per-user refresh.
- Appearance failures now include their actual error message.
- Restores the clean taskbar by disabling unread-count badges such as Discord's red number.
- Hides the Task View button to match the previous clean taskbar.
- Fixed SFC and DISM so they open in visible administrator consoles with progress and results.

## v0.15.3.1

- Fixed the updater build by explicitly importing its file-system dependencies.

## v0.15.3

- Added an in-app update checker that downloads the newest installer from GitHub Releases.
- Removed the automatic Windows appearance preset so the app no longer changes themes, ClearType, taskbar pins or shell visual effects.
- Keeps thumbnails, full-window dragging, ClearType font smoothing and desktop icon-label shadows.
- Applies and broadcasts ClearType immediately to prevent jagged desktop text.

## v0.15.2

- Fixed the installer's final launch failing with Windows error 740 when SLXDE OPTI requires administrator access.
- Removed the nullable-return and uninitialised-field build warnings.

## v0.15.1

- Fixed the setup builder failing immediately after Winget successfully installs Inno Setup.
- Refreshes the current process PATH before continuing.
- Detects Inno Setup in Program Files, per-user Local AppData, Winget links/packages and uninstall registry entries.

## v0.15.0

- Added a proper Windows installer definition that creates one `SLXDE-OPTI-Setup.exe`.
- Publishes the app as self-contained Windows x64 output, so friends do not need .NET or the source files.
- Adds the SLXDE icon, Start-menu shortcut, optional desktop shortcut and normal Windows uninstall support.
- Requests administrator access whenever the optimiser launches so system-level actions work consistently.
- Added a double-click local installer builder and an automated GitHub Actions installer build.
- Keeps backups stored under ProgramData when the app is uninstalled.

## v0.14.5

- Replaced the older AMD guide assets with the four exact supplied screenshots.
- Removed the accidental duplicate guide image and fixed the screenshot order and captions.
- Ships AMD guide images as copied output and publish content so the guide can load them at runtime.
- Increased the guide heading area so its descriptive text is no longer clipped.

## v0.14.4

- Made branded pop-ups compact for short success and information messages.
- Added adaptive medium and wide layouts for confirmations and longer results.
- Preserved comfortable wrapping without leaving short messages in oversized windows.

## v0.14.3

- Restricted automatic game detection to visible game processes and genuine installed game executables.
- Filtered duplicate entries, launchers, overlays, anti-cheat components, helpers and background services.
- Made app-owned pop-ups smaller and cleaner while retaining the dark-navy SLXDE styling.
- Replaced every remaining plain letter badge with the definitive white angular SLXDE S mark.
- Replaced the text success character with a cleaner vector success tick.
- Resized the AMD settings guide to remain inside the Windows work area.
- Locked the four packaged AMD screenshots into the correct order with matching captions.
- Improved game-scanning progress and completion status text.

## v0.14.2

- Replaced the raw white Analyse PC message box with a fully branded SLXDE OPTI results window.
- Added a borderless dark navy window, blue accents, readiness score, system tiles and clean gaming-status cards.
- Parsed the existing analysis output without changing the underlying checks or score calculation.
- Replaced every app-owned Windows message box with one reusable SLXDE-themed dialog for results, errors, warnings and confirmations.
- Restyled the automatic game picker with a borderless SLXDE title bar.
- Restyled the AMD screenshot guide from its older purple/red design to the current navy/blue SLXDE system.
- Filtered AMD Software, Battle.net overlays, launchers and helper executables from automatic game detection.
- Added Restore Windows Default inside the game picker so per-game GPU choices remain reversible without another page card.

## v0.14.1

- Replaced the game GPU feature's file-browser-first flow with an automatic game finder.
- Detects currently running games, Steam libraries, Epic manifests and common publisher installs.
- Presents friendly game names in a clean selector and retains Browse manually as a fallback.

## v0.14.0

- Added a one-click Maximum Refresh Rate action for the primary display.
- Keeps the current resolution, colour depth and display layout while selecting the highest supported refresh rate.
- Tests the chosen display mode with the graphics driver before applying it and verifies the result afterwards.
- Added a normal Windows file picker for assigning individual games to the High performance GPU.
- Kept the established v0.13 design unchanged.

## v0.13.4

- Fixed DNS optimisation failing when Windows exposes an adapter GUID as text rather than a native GUID object.
- Added post-write verification for both selected IPv4 DNS servers.
- DNS failures before any change now correctly report that settings were untouched.
- Failures after a DNS change retain the automatic rollback and report its result accurately.

## v0.13.3

- Changed the launcher to build once and start the compiled app independently.
- The launcher window now closes after the app starts instead of keeping `dotnet run` attached.
- Cached CPU, GPU, memory and Windows information after the initial dashboard load.
- Returning to the Dashboard no longer repeats the slower WMI hardware queries.

## v0.13.2

- Removed the separate Restore NVIDIA Profile card from the GPU page.
- Kept automatic profile backup and failure rollback internally for safety.
- Reduced the NVIDIA feature to one clean, one-click optimisation row.

## v0.13.1

- Added `RUN-SLXDE-OPTI.bat` at the top of the package.
- The app can now be launched by double-clicking one file without pasting a PowerShell command.
- The launcher checks for the .NET SDK and confirms that the complete ZIP was extracted.
- Failed launches remain visible so the error can be photographed instead of the window closing immediately.

## v0.13.0

- Replaced the NVIDIA settings guide with a real one-click NVIDIA Control Panel optimisation.
- Detects an NVIDIA GPU before making any driver-profile changes.
- Creates a timestamped backup of customised NVIDIA profiles before applying anything.
- Applies only portable competitive settings: maximum-performance power mode, highest refresh rate, high-performance texture filtering, shader cache on/unlimited, one pre-rendered frame, frame limiter off, V-Sync off and safe texture-filter optimisations.
- Leaves Low Latency Mode and G-SYNC/VRR game-controlled to avoid breaking NVIDIA Reflex or variable-refresh setups.
- Verifies the written profile and automatically rolls back if verification fails.
- Added a dedicated Restore NVIDIA Profile action.
- Bundles the official MIT-licensed NVIDIA Profile Inspector 3.0.2.1 driver-profile bridge with licence and attribution files.

## v0.12.8

- Removed the unnecessary Open Game Controllers shortcut from the Controller / KBM page.

## v0.12.7

- Added an Optimise DNS action that benchmarks real lookups through Cloudflare, Google and Quad9 and applies the quickest reliable pair.
- Targets only the active physical internet adapter and flushes the DNS cache after applying.
- Preserves the previous manual or automatic DNS state and adds a Restore DNS action.

## v0.12.6

- Matched the BO7 Config description to the concise Fortnite and Rocket League wording.

## v0.12.5

- Renamed the Game Configs action to simply `BO7 Config`.
- NVIDIA now always uses DLSS Balanced with the Transformer model.
- Explicitly forces every `GPUUploadHeaps` occurrence to `false` and verifies it after writing.

## v0.12.4

- Changed the BO7 gameplay frame-rate limit to Unlimited while retaining menu and out-of-focus limits as fallbacks.
- Keeps gameplay/menu V-Sync off, Eco Mode Custom, maximum menu render reduction, inactive quality reduction off, pause rendering off, Focused Mode at 0 and HDR off.
- Added targeted handling for BO7's separate streaming config files: Minimal streaming, 16 GB cache, download limits on and 1 GB daily limit.

## v0.12.3

- Fixed BO7 graphics values only being updated in their first occurrence.
- Corrected NVIDIA BO7 keys to use the current `MP` names.
- Applies and verifies the complete performance preset, including Balanced global quality, low textures, terrain, shadows and effects.
- Clears read-only protection, writes UTF-8 without a BOM and refreshes the BO7 metadata marker.
- Refuses to apply while Call of Duty is running so the game cannot overwrite the preset on exit.

## v0.12.2

- Corrected BO7 config discovery to use only `%LOCALAPPDATA%\Activision\Call of Duty\players`.
- Targets current `cod25` txt0/txt1 files only.
- Removed the obsolete Documents and cod24 fallbacks to avoid changing older COD configs.

## v0.12.1

- Made the COD installer genuinely hardware-aware rather than copying third-party hardware identifiers.
- AMD GPUs receive an AMD FidelityFX CAS profile.
- NVIDIA GPUs receive DLSS with the Transformer model and resolution-aware quality mode.
- Renderer Worker Count is calculated from detected physical CPU cores.
- Applies to both COD txt0 and txt1 settings files when present, backing up each one first.
- Replaced the remaining clock-style System Restore icon with the approved broad return arrow.

## v0.12.0

- Added a clean in-app SLXDE COD config installer with confirmation, progress and completion feedback.
- Kept the safer graphics-only preset and automatic backup instead of copying hardware-specific values from third-party configs.
- Initially added multi-location COD discovery; superseded by v0.12.2's BO7-only AppData path.
- Reduced action-card icon boxes and symbols throughout the app.
- Replaced the USB Power Saving artwork with the approved power/off symbol.

## v0.11.4

- Replaced the old cloud-with-upload-arrow artwork with a clean cloud outline.
- Applied the new cloud consistently to the sidebar, Backup / Restore header and backup creation cards.
- Kept the return arrow specifically for restore actions.

## v0.11.3

- Replaced heavy all-caps page and card titles with cleaner title-case typography.
- Changed headings from pure white and bold to a softer blue-white semibold style.
- Preserved technical acronyms such as GPU, PC, AMD, IPv4 and DVR.
- Removed the remaining yellow/orange help text from the legacy information-card style.

## v0.11.2

- Replaced the Windows revert icon with a broad return arrow.
- Replaced the Game DVR icon with a clean power/off symbol.
- Replaced yellow notices throughout the interface with a soft icy blue.
- Removed the old camera and circular-reset artwork from the icon system entirely.

## v0.11.1

- Replaced the generic Revert arrow with a Windows restore icon.
- Replaced the Game DVR camera with a disabled-video icon.

## v0.11.0

- Added the final angular SLXDE S monogram to the app header.
- Added a proper multi-size Windows executable icon.
- Added a restrained blue accent line and faint S watermark to give the clean UI more identity.

## v0.10.5

- Replaced the generic Restart Explorer arrow with a folder-and-refresh icon.

## v0.10.4

- Replaced the generic gamepad with a combined keyboard-and-mouse input icon.
- Gave Performance Mode its own lightning icon.

## v0.10.3

- Rebalanced the left navigation with smaller icons, larger labels and tighter spacing.

## v0.10.2

- Replaced the old PNG/glyph mix with a consistent code-native vector icon set.
- Flattened GPU tools so all three actions fit without scrolling.
- Expanded Network, Controller / KBM and Backup / Restore to five useful actions.
- Added a reversible Prefer IPv4 option without disabling IPv6.
- Reworked individual Debloat choices into compact two-column rows.

## v 0.9.65

Fixed PowerShell runner path quoting for folders with apostrophes.

## v 0.9.65

Fixed GUI button PowerShell path quoting properly using here-strings and module preloading.

## v 0.9.65

Centered title, brighter fonts, better sidebar icons, and proper action-card icons.

## v 0.9.65

Removed unsupported WPF LetterSpacing property to fix build error MC3072.

## v 0.9.65

GUI now loads all PowerShell modules instead of requiring exact module filenames.

## v 0.9.65

Added GUI bridge functions and fixed mismatched function names.

## v 0.9.65

Removed bottom fake status cards and sidebar branding box.

## v 0.9.65

Removed the large shared content panel and made tweak cards feel more individual.

## v 0.9.65

Removed the grouped Apply All Safe Gaming Tweaks card.

## v 0.9.65

Cleaned GPU page wording.

## v 0.9.65

Network page buttons are now wired and show APPLY instead of PREVIEW.

## v 0.9.65

Display, Backup/Restore and Logs buttons are now wired and show APPLY.

## v 0.9.65

Merged Gaming into Windows and removed the separate Gaming sidebar section.

## v 0.9.65

Added Controller / KBM tab and moved USB power saving there. Power plans moved to top of Windows.

## v 0.9.65

Bigger centered title and improved sidebar spacing/fill.

## v 0.9.65

Added Allow Optimizer Scripts and Restore Windows Defaults to the top of Windows.

## v 0.9.65

Added GPU MSI Mode, MSI status check and NVIDIA driver profile helper.

## v 0.9.65

Removed Display/Logs sidebar items, moved Display into Windows, added max refresh and improved title.

## v 0.9.65

Removed quick/display filler and added Quality of Life page.

## v 0.9.65

Cleaned Controller / KBM page and removed less useful/risky options.

## v 0.9.65

Network Pack now uses a GUI-safe wrapper and the runner has a 60-second timeout.

## v 0.9.65

Removed Check GPU MSI Status card and moved MSI status into Analyze PC.

## v 0.9.65

Fixed Windows order, improved Windows icon, and cleaned the header title.

## v 0.9.65

Added AMD/NVIDIA branded cards and AMD settings guide window.

## v 0.9.65

Fixed GPU page sections and AMD guide display.

## v 0.9.65

Clean GPU layout, branded AMD/NVIDIA markers and shader cache moved to cleanup.

## v 0.9.65

Fixed duplicate icon variable build errors.

## v 0.9.65

Hard cleaned GPU page to exactly three items and moved shader cache shortcuts to cleanup.

## v 0.9.65

Hard-replaced the GPU page so it only has MSI Mode, NVIDIA Driver Settings and AMD Settings.

## v 0.9.65

Removed first AMD guide image and locked Windows top order.

## v 0.9.65

Removed GUI preview footer, added image logo header, cleaner status, fixed latest log and changed GPU icon.

## v 0.9.65

Visual polish pass based on the provided mockup and renamed SLXDE Power Plan to Optimal Power Plan.

## v 0.9.65

Actual WPF UI styled much closer to the provided mockup, with exact cropped top banner asset.

## v 0.9.65

Sidebar icons now use reference image assets, clipping fixed, banner sharpened and sizing reduced.

## v 0.9.65

Regenerated padded sidebar icons and improved spacing/sidebar width to reduce clipping and bunched layout.

## v 0.9.65

Made sidebar/page/card icons larger again and added page/card spacing so things are not bunched together.

## v 0.9.65

Replaced tiny cropped sidebar icons with clean drawn assets and fixed sidebar sizing so Backup / Restore fits.

## v 0.9.65

Uses the user's sidebar logo strip as real app icon assets and improves spacing.

## v 0.9.65

Fixed app startup and repaired sidebar icons/layout.

## v 0.9.65

Converted the actual WPF app theme to light blue/cyan.

## v 0.9.65

Remade the GUI navigation icon PNG assets while keeping the Windows icon.

## v 0.9.65

Kept Windows and Network icons, reworked the rest of the sidebar icons.

## v 0.9.65

Kept Windows/Network and replaced the rest with properly scaled icons from the preferred sidebar strip.

## v 0.9.65

Changed remaining purple icon boxes to blue and reworked GPU/Cleanup icons.

## v 0.9.65

Reverted bad v 0.9.65 icon direction and directly fixed purple icon boxes in XAML.

## v 0.9.65

Inserted approved GPU, Controller and Clean-up icon assets into the actual app.

## v 0.9.65

Fixed banner asset copying for exe/publish and added fallback SLXDE'S OPTI text.

## v 0.9.65

Embedded image assets as WPF Resources so icons/banner work from exe/publish.

## v 0.9.65

Fixed Modules lookup/copying and banner pack URI.

## v 0.9.65

Fixed action-card icons showing as dots by restoring direct glyph rendering.

## v 0.9.65

Added Dashboard SLXDE Performance Mode and cleaned Input Responsiveness/latest log behavior.

## v 0.9.65

Fixed v 0.9.65 build error by replacing SetStatus with the app status method.

## v 0.9.65

Rebuilt Game Mode info from stable v 0.9.65 and fixed broken click-handler build errors.

## v 0.9.65

Renamed Game Mode to Performance Mode, reordered dashboard info, removed sidebar label and added Game Configs.

## v 0.9.65

Changed Game Configs COD button to COD BO7 with a BO7 esports config preset.

## v 0.9.65

Fixed COD BO7 config Lines binding error.

## v 0.9.65

COD config targeting from this early build was superseded by v0.12.2's current BO7 `cod25` handling.

## v 0.9.65

COD BO7 Graphics Config now copies Sam's exact graphics/performance preset only.

## v 0.9.65

Updated Game Config wording and removed CS2 from the visible Game Configs page.

## v 0.9.65

Added Debloat page with profile presets and individual tick/untick options.

## v0.9.65

Moved Debloat in the sidebar, replaced the icon with the broom logo, removed Chris Titus wording and polished option descriptions.
