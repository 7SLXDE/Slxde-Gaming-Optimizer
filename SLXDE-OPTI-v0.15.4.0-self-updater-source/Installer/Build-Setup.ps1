param(
    [switch]$InstallInnoSetup
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $Root "Gui\SlxdeOptimizer.App\SlxdeOptimizer.App.csproj"
$PublishDir = Join-Path $Root "artifacts\publish"
$InstallerDir = Join-Path $Root "artifacts\installer"
$InstallerScript = Join-Path $PSScriptRoot "SLXDE-OPTI.iss"
[xml]$ProjectXml = Get-Content -LiteralPath $Project
$Version = [string]$ProjectXml.Project.PropertyGroup.Version
if ([string]::IsNullOrWhiteSpace($Version)) {
    throw "The app version is missing from SlxdeOptimizer.App.csproj."
}

function Find-InnoCompiler {
    $Candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\ISCC.exe"
    )

    $Command = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
    if ($Command) {
        return $Command.Source
    }

    $DirectMatch = $Candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($DirectMatch) {
        return $DirectMatch
    }

    $RegistryPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1"
    )

    foreach ($RegistryPath in $RegistryPaths) {
        $InstallLocation = (Get-ItemProperty -LiteralPath $RegistryPath -ErrorAction SilentlyContinue).InstallLocation
        if ($InstallLocation) {
            $RegistryCompiler = Join-Path $InstallLocation "ISCC.exe"
            if (Test-Path -LiteralPath $RegistryCompiler) {
                return $RegistryCompiler
            }
        }
    }

    $SearchRoots = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
        "$env:LOCALAPPDATA\Programs"
    )

    foreach ($SearchRoot in $SearchRoots) {
        if (!(Test-Path -LiteralPath $SearchRoot)) {
            continue
        }

        $FoundCompiler = Get-ChildItem -LiteralPath $SearchRoot -Filter "ISCC.exe" -File -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($FoundCompiler) {
            return $FoundCompiler.FullName
        }
    }

    return $null
}

function Refresh-ProcessPath {
    $MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$MachinePath;$UserPath"
}

function Install-InnoSetupDirect {
    $InnoVersion = "6.7.3"
    $InnoTagVersion = $InnoVersion.Replace(".", "_")
    $DownloadUrl = "https://github.com/jrsoftware/issrc/releases/download/is-$InnoTagVersion/innosetup-$InnoVersion.exe"
    $DownloadedInstaller = Join-Path $env:TEMP "SLXDE-InnoSetup-$InnoVersion.exe"

    Write-Host "Downloading the official Inno Setup $InnoVersion installer..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadedInstaller -UseBasicParsing

    try {
        $Signature = Get-AuthenticodeSignature -FilePath $DownloadedInstaller
        if ($Signature.Status -ne "Valid") {
            throw "The downloaded Inno Setup installer does not have a valid digital signature."
        }

        Write-Host "Installing Inno Setup $InnoVersion for the current user..." -ForegroundColor Cyan
        $InstallProcess = Start-Process -FilePath $DownloadedInstaller `
            -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/SP-", "/CURRENTUSER" `
            -Wait `
            -PassThru

        if ($InstallProcess.ExitCode -ne 0) {
            throw "Inno Setup installation failed with exit code $($InstallProcess.ExitCode)."
        }
    }
    finally {
        Remove-Item -LiteralPath $DownloadedInstaller -Force -ErrorAction SilentlyContinue
    }

    Refresh-ProcessPath
    return Find-InnoCompiler
}

if (!(Get-Command dotnet.exe -ErrorAction SilentlyContinue)) {
    throw "The .NET 8 SDK is required to build the installer. Install it from https://dotnet.microsoft.com/download/dotnet/8.0"
}

$InnoCompiler = Find-InnoCompiler
if (!$InnoCompiler -and $InstallInnoSetup) {
    $InnoCompiler = Install-InnoSetupDirect
}

if (!$InnoCompiler) {
    throw "Inno Setup 6 is required. Install it from https://jrsoftware.org/isdl.php, then run this builder again."
}

if (Test-Path -LiteralPath $PublishDir) {
    Remove-Item -LiteralPath $PublishDir -Recurse -Force
}
if (Test-Path -LiteralPath $InstallerDir) {
    Remove-Item -LiteralPath $InstallerDir -Recurse -Force
}

New-Item -ItemType Directory -Path $PublishDir -Force | Out-Null
New-Item -ItemType Directory -Path $InstallerDir -Force | Out-Null

Write-Host "Publishing SLXDE OPTI $Version as a self-contained Windows app..." -ForegroundColor Cyan
& dotnet.exe publish $Project `
    --configuration Release `
    --runtime win-x64 `
    --self-contained true `
    --output $PublishDir `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -p:DebugType=None `
    -p:DebugSymbols=false

if ($LASTEXITCODE -ne 0) {
    throw "The SLXDE OPTI publish failed with exit code $LASTEXITCODE."
}

$PublishedApp = Join-Path $PublishDir "SlxdeOptimizer.App.exe"
if (!(Test-Path -LiteralPath $PublishedApp)) {
    throw "Publishing completed, but SlxdeOptimizer.App.exe was not created."
}

Write-Host "Building SLXDE-OPTI-Setup.exe..." -ForegroundColor Cyan
& $InnoCompiler `
    "/DMyAppVersion=$Version" `
    "/DPublishDir=$PublishDir" `
    "/DOutputDir=$InstallerDir" `
    $InstallerScript

if ($LASTEXITCODE -ne 0) {
    throw "The installer build failed with exit code $LASTEXITCODE."
}

$Setup = Join-Path $InstallerDir "SLXDE-OPTI-Setup.exe"
if (!(Test-Path -LiteralPath $Setup)) {
    throw "Inno Setup completed, but SLXDE-OPTI-Setup.exe was not created."
}

$ChecksumPath = "$Setup.sha256"
$Checksum = (Get-FileHash -LiteralPath $Setup -Algorithm SHA256).Hash.ToLowerInvariant()
"$Checksum *SLXDE-OPTI-Setup.exe" |
    Set-Content -LiteralPath $ChecksumPath -Encoding ascii -NoNewline

Write-Host ""
Write-Host "Installer ready:" -ForegroundColor Green
Write-Host $Setup -ForegroundColor White
Write-Host "Checksum:" -ForegroundColor Green
Write-Host $ChecksumPath -ForegroundColor White
Write-Host "You can send this single EXE to your friends." -ForegroundColor Cyan
Write-Host ""
