# SLXDE OPTI installer

The finished file to send to friends is:

`artifacts\installer\SLXDE-OPTI-Setup.exe`

Version `0.15.4.0` is the final version friends need to install manually. Once it is installed, future GitHub Releases can be downloaded and installed from **Check for Updates** inside SLXDE OPTI.

## Build it on your Windows PC

1. Extract the complete source ZIP.
2. Double-click `BUILD-SETUP.bat`.
3. Allow Inno Setup to be installed if it is not already present.
4. Wait for the installer folder to open.
5. Send only `SLXDE-OPTI-Setup.exe` to your friends.

The builder publishes a self-contained Windows x64 app. Friends do not need the .NET SDK, PowerShell commands or the source ZIP.

## Build it with GitHub

The included `build-installer.yml` workflow builds the same installer on a Windows GitHub runner. Run **Build Windows Installer** from the Actions tab and download the `SLXDE-OPTI-Setup` artifact.

For each public update:

1. Update the version in `SlxdeOptimizer.App.csproj`.
2. Push the source to GitHub.
3. Push a matching version tag, such as `v0.15.4.0`.
4. The workflow creates the GitHub Release and attaches `SLXDE-OPTI-Setup.exe` plus `SLXDE-OPTI-Setup.exe.sha256`.

Installed copies use those two release files for secure in-app updates. Do not rename either release asset.

## Windows SmartScreen

The installer is currently unsigned. Windows may show an “Unknown publisher” SmartScreen warning. Code-sign the setup and application executables with a trusted certificate before selling or widely distributing the app.
