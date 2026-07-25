# =====================================================
# GameConfigs.ps1
# Safe game config helpers for SLXDE'S OPTI
# Creates backups before changing any file.
# =====================================================

function Get-SlxdeGameConfigBackupRoot {
    $Root = Join-Path $env:ProgramData "Slxde Gaming Optimizer\GameConfigBackups"
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    return $Root
}

function Backup-SlxdeGameConfigFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Game
    )

    if (!(Test-Path $Path)) {
        return $null
    }

    $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $SafeGame = ($Game -replace '[^\w\- ]', '').Trim()
    $DestDir = Join-Path (Get-SlxdeGameConfigBackupRoot) "$SafeGame\$Stamp"
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

    $Dest = Join-Path $DestDir (Split-Path $Path -Leaf)
    Copy-Item -Path $Path -Destination $Dest -Force
    return $Dest
}

function Set-SlxdeIniValue {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][string]$Key,
        [Parameter(Mandatory=$true)][string]$Value
    )

    if (!(Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }

    $Lines = [System.Collections.Generic.List[string]]::new()
    $Existing = Get-Content -Path $Path -ErrorAction SilentlyContinue
    if ($Existing) { $Existing | ForEach-Object { $Lines.Add($_) } }

    $SectionHeader = "[$Section]"
    $SectionIndex = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -ieq $SectionHeader) {
            $SectionIndex = $i
            break
        }
    }

    if ($SectionIndex -lt 0) {
        if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1].Trim() -ne "") { [void]$Lines.Add("") }
        $Lines.Add($SectionHeader)
        $Lines.Add("$Key=$Value")
        Set-Content -Path $Path -Value ([string[]]$Lines) -Encoding UTF8
        return
    }

    $InsertIndex = $Lines.Count
    $KeyIndex = -1

    for ($i = $SectionIndex + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim().StartsWith("[") -and $Lines[$i].Trim().EndsWith("]")) {
            $InsertIndex = $i
            break
        }

        if ($Lines[$i] -match "^\s*$([regex]::Escape($Key))\s*=") {
            $KeyIndex = $i
            break
        }
    }

    if ($KeyIndex -ge 0) {
        $Lines[$KeyIndex] = "$Key=$Value"
    }
    else {
        $Lines.Insert($InsertIndex, "$Key=$Value")
    }

    Set-Content -Path $Path -Value ([string[]]$Lines) -Encoding UTF8
}

function Apply-GuiFortniteConfig {
    try {
        $Path = Join-Path $env:LOCALAPPDATA "FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini"
        if (!(Test-Path $Path)) {
            return "Fortnite config not found.`n`nLaunch Fortnite once, then close it and try again.`nExpected path:`n$Path"
        }

        $Backup = Backup-SlxdeGameConfigFile -Path $Path -Game "Fortnite"

        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.ViewDistanceQuality" -Value "1"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.AntiAliasingQuality" -Value "0"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.ShadowQuality" -Value "0"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.GlobalIlluminationQuality" -Value "0"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.ReflectionQuality" -Value "0"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.PostProcessQuality" -Value "0"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.TextureQuality" -Value "1"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.EffectsQuality" -Value "0"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.FoliageQuality" -Value "0"
        Set-SlxdeIniValue -Path $Path -Section "ScalabilityGroups" -Key "sg.ShadingQuality" -Value "0"

        Write-Log "Applied Fortnite esports config"
        return "Fortnite esports config applied.`nBackup created:`n$Backup`n`nLaunch Fortnite and check your video settings."
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Apply-GuiRocketLeagueConfig {
    try {
        $Path = Join-Path $env:USERPROFILE "Documents\My Games\Rocket League\TAGame\Config\TASystemSettings.ini"
        if (!(Test-Path $Path)) {
            return "Rocket League config not found.`n`nLaunch Rocket League once, then close it and try again.`nExpected path:`n$Path"
        }

        $Backup = Backup-SlxdeGameConfigFile -Path $Path -Game "Rocket League"

        Set-SlxdeIniValue -Path $Path -Section "SystemSettings" -Key "DynamicLights" -Value "False"
        Set-SlxdeIniValue -Path $Path -Section "SystemSettings" -Key "DynamicShadows" -Value "False"
        Set-SlxdeIniValue -Path $Path -Section "SystemSettings" -Key "MotionBlur" -Value "False"
        Set-SlxdeIniValue -Path $Path -Section "SystemSettings" -Key "Bloom" -Value "False"
        Set-SlxdeIniValue -Path $Path -Section "SystemSettings" -Key "DepthOfField" -Value "False"
        Set-SlxdeIniValue -Path $Path -Section "SystemSettings" -Key "LensFlares" -Value "False"
        Set-SlxdeIniValue -Path $Path -Section "SystemSettings" -Key "MaxFPS" -Value "360"

        Write-Log "Applied Rocket League esports config"
        return "Rocket League esports config applied.`nBackup created:`n$Backup"
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}





function Find-SlxdeCs2CfgFolder {
    $Candidates = @(
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg",
        "$env:ProgramFiles\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path $Candidate) { return $Candidate }
    }

    return $null
}

function Apply-GuiCs2Config {
    try {
        $CfgDir = Find-SlxdeCs2CfgFolder
        if (!$CfgDir) {
            return "CS2 cfg folder not found.`n`nIf CS2 is installed on another drive, open Steam > CS2 > Browse local files, then place this file manually later:`nslxde_esports.cfg"
        }

        $Cfg = Join-Path $CfgDir "slxde_esports.cfg"
        if (Test-Path $Cfg) {
            Backup-SlxdeGameConfigFile -Path $Cfg -Game "CS2" | Out-Null
        }

        $Content = @"
fps_max 0
fps_max_ui 120
cl_showfps 0
r_fullscreen_gamma 2.2
rate 786432
cl_net_buffer_ticks 0
engine_low_latency_sleep_after_client_tick true
"@

        Set-Content -Path $Cfg -Value $Content -Encoding ASCII

        Write-Log "Created CS2 SLXDE esports cfg"
        return "CS2 SLXDE esports config created:`n$Cfg`n`nTo use it, add this to CS2 launch options or console:`n+exec slxde_esports.cfg"
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Restore-GuiLatestGameConfigBackup {
    try {
        $Root = Get-SlxdeGameConfigBackupRoot
        $Latest = Get-ChildItem -Path $Root -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (!$Latest) {
            return "No game config backups found yet."
        }

        $GameFolder = Split-Path (Split-Path $Latest.FullName -Parent) -Leaf
        return "Latest backup found:`n$($Latest.FullName)`n`nAutomatic restore needs the original target path saved in v 0.9.65. For now, open backups and copy this file back manually."
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

function Open-GuiGameConfigBackups {
    try {
        $Root = Get-SlxdeGameConfigBackupRoot
        Start-Process explorer.exe $Root
        return "Opened game config backup folder."
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}


function Find-SlxdeCodBo7ConfigFiles {
    $Roots = @(
        (Join-Path $env:LOCALAPPDATA "Activision\Call of Duty\players")
    )

    $Found = [System.Collections.Generic.List[string]]::new()

    foreach ($Root in $Roots) {
        if (!(Test-Path $Root)) {
            continue
        }

        # BO7 uses the current cod25 files in Activision's Local AppData folder.
        $Preferred = @(
            (Join-Path $Root "s.1.0.cod25.txt0"),
            (Join-Path $Root "s.1.0.cod25.txt1")
        )

        foreach ($Path in $Preferred) {
            if ((Test-Path $Path) -and -not $Found.Contains($Path)) {
                [void]$Found.Add($Path)
            }
        }

        # Only select the text settings files, never the tiny metadata file.
        $Fallbacks = Get-ChildItem -Path $Root -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^s\.1\.0\.cod25\.txt[0-9]+$' } |
            Sort-Object LastWriteTime -Descending

        foreach ($Fallback in $Fallbacks) {
            if (-not $Found.Contains($Fallback.FullName)) {
                [void]$Found.Add($Fallback.FullName)
            }
        }
    }

    return $Found.ToArray()
}

function Set-SlxdeCodExactKey {
    param(
        [Parameter(Mandatory=$true)]$Lines,
        [Parameter(Mandatory=$true)][string]$KeyPrefix,
        [Parameter(Mandatory=$true)][string]$Value
    )

    if ($null -eq $Lines) { return }

    $found = $false
    $escaped = [regex]::Escape($KeyPrefix)

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = [string]$Lines[$i]

        if ($line -match "^\s*$escaped@.*?=") {
            $comment = ""
            if ($line -match "(//.*)$") {
                $comment = " " + $Matches[1].Trim()
            }

            $left = ($line -split "=", 2)[0].TrimEnd()
            $Lines[$i] = "$left = $Value$comment"
            $found = $true
        }
    }

    if (-not $found) {
        [void]$Lines.Add("$KeyPrefix@0;0;0 = $Value // Added by SLXDE")
    }
}

function Set-SlxdeCodValueAfterComment {
    param(
        [Parameter(Mandatory=$true)]$Lines,
        [Parameter(Mandatory=$true)][string]$CommentPattern,
        [Parameter(Mandatory=$true)][string]$Value
    )

    $Changed = 0
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Comment = [string]$Lines[$i]
        if ($Comment -notmatch '^\s*//' -or $Comment -notmatch $CommentPattern) { continue }

        for ($j = $i + 1; $j -lt [Math]::Min($Lines.Count, $i + 6); $j++) {
            $Setting = [string]$Lines[$j]
            if ($Setting -match '^\s*//' -or [string]::IsNullOrWhiteSpace($Setting)) { continue }
            if ($Setting -notmatch '=') { break }

            $TrailingComment = ''
            if ($Setting -match '(//.*)$') {
                $TrailingComment = ' ' + $Matches[1].Trim()
            }
            $Left = ($Setting -split '=', 2)[0].TrimEnd()
            $Lines[$j] = "$Left = $Value$TrailingComment"
            $Changed++
            break
        }
    }
    return $Changed
}

function Get-SlxdeGpuVendor {
    try {
        $Names = (Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join " | "
        if ($Names -match "NVIDIA|GeForce|RTX|GTX") { return "NVIDIA" }
        if ($Names -match "AMD|Radeon|RX ") { return "AMD" }
    }
    catch {}
    return "Unknown"
}

function Apply-GuiCodBo7Config {
    try {
        $RunningGame = Get-Process -ErrorAction SilentlyContinue |
            Where-Object { $_.ProcessName -match '^(cod|cod25|blackops7|callofduty)$' } |
            Select-Object -First 1
        if ($RunningGame) {
            return "Close Call of Duty before applying the BO7 config.`n`nThe game writes its settings when it closes and would otherwise replace the SLXDE preset."
        }

        $Paths = @(Find-SlxdeCodBo7ConfigFiles)

        if (!$Paths -or $Paths.Count -eq 0) {
            return "COD BO7 config not found.`n`nLaunch BO7 once, change one graphics setting, close the game, then try again.`n`nChecked:`n$env:LOCALAPPDATA\Activision\Call of Duty\players"
        }

        $GpuControllers = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)
        $Gpu = $GpuControllers |
            Where-Object { $_.Name -match 'NVIDIA|GeForce|RTX|GTX|AMD|Radeon|RX ' } |
            Select-Object -First 1
        if (!$Gpu) { $Gpu = $GpuControllers | Select-Object -First 1 }

        $GpuName = if ($Gpu -and $Gpu.Name) { [string]$Gpu.Name } else { "Unknown GPU" }
        $GpuVendor = if ($GpuName -match 'NVIDIA|GeForce|RTX|GTX') {
            "NVIDIA"
        }
        elseif ($GpuName -match 'AMD|Radeon|RX ') {
            "AMD"
        }
        else {
            "Unknown"
        }

        $DlssQuality = "Balanced"
        $Profile = if ($GpuVendor -eq "NVIDIA") {
            "NVIDIA DLSS Transformer ($DlssQuality)"
        }
        elseif ($GpuVendor -eq "AMD") {
            "AMD FidelityFX CAS"
        }
        else {
            "Universal FidelityFX CAS"
        }

        $PhysicalCores = [int]((Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue |
            Measure-Object -Property NumberOfCores -Sum).Sum)
        if ($PhysicalCores -lt 1) { $PhysicalCores = 8 }
        $WorkerCount = [Math]::Min(7, [Math]::Max(1, $PhysicalCores - 1))

        $AppliedPaths = [System.Collections.Generic.List[string]]::new()
        $Backups = [System.Collections.Generic.List[string]]::new()

        foreach ($Path in $Paths) {
            $Backup = Backup-SlxdeGameConfigFile -Path $Path -Game "COD BO7"
            if ($Backup) { [void]$Backups.Add($Backup) }

            $ConfigItem = Get-Item -LiteralPath $Path -ErrorAction Stop
            if ($ConfigItem.IsReadOnly) { $ConfigItem.IsReadOnly = $false }

            $raw = @(Get-Content -Path $Path -ErrorAction SilentlyContinue)
            $Lines = [System.Collections.ArrayList]::new()
            foreach ($line in $raw) { [void]$Lines.Add([string]$line) }

        # SLXDE exact COD BO7 graphics/performance preset copied from Sam's provided config.
        # This intentionally does NOT copy audio, controls, mouse/controller, device IDs,
        # monitor IDs, speaker/mic IDs, GPUName, LastUsedGPU, or personal system fields.
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AspectRatio" -Value "auto"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DisplayGamma" -Value "BT709_sRGB"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DisplayMode" -Value "Fullscreen"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "FocusedMode" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "FocusedModeOpacity" -Value "0.000000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "PreferredDisplayMode" -Value "Fullscreen"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VSyncInMenu" -Value "disabled"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ResolutionMultiplier" -Value "100"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VSync" -Value "disabled"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "CapFps" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "CorpseLimit" -Value "0"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DepthOfField" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DepthOfFieldQuality" -Value "Low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "MaxFpsInGame" -Value "300"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "MaxFpsInMenu" -Value "60"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "MaxFpsOutOfFocus" -Value "30"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "BloodLimit" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "BloodLimitInterval" -Value "2000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "InvalidCmdHintBlinkInterval" -Value "10000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "InvalidCmdHintDuration" -Value "0"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "MarksEntsPlayerOnly" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ShowBlood" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ShowBrass" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AATechniquePreferredMP" -Value "SMAA"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AbsoluteTargetResolution" -Value "none"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "BulletImpacts" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "CorpsesCullingThreshold" -Value "0.500000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ReflectionProbeRelighting" -Value "1"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ScreenSpaceShadowQuality" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SSRQuality" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "StaticSunshadowClipmapResolution" -Value "0"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "STLodSkip" -Value "0"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "Tessellation" -Value "0_Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "TextureFilter" -Value "aniso 2x"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "TextureQuality" -Value "3"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "UiQuality" -Value "Auto"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "WorldStreamingQuality" -Value "Low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DeferredPhysics" -Value "Low Quality"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DxrMode" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DynamicSceneResolution" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DynamicSceneResolutionTarget" -Value "16.670000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "XeSSQuality" -Value "Balanced"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "GPUUploadHeaps" -Value "false"

        if ($GpuVendor -eq "NVIDIA") {
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "NvidiaReflex" -Value "Enabled"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDFidelityFX" -Value "Off"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AATechniquePreferredMP" -Value "DLSS"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSModeMP" -Value "DLSS"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSPerfModeMP" -Value $DlssQuality
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSModelUI" -Value "TRANSFORMER"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSSharpnessMP" -Value "0.500000"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSFrameGeneration" -Value "false"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "NVIDIAImageScalingMP" -Value "false"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "NVIDIAImageScalingQualityMP" -Value "Native Resolution"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "NVIDIAImageScalingSharpnessMP" -Value "0.300000"
        }
        else {
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AmdAntilag2" -Value "false"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AATechniquePreferredMP" -Value "SMAA"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDContrastAdaptiveSharpeningStrength" -Value "0.700000"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDFidelityFX" -Value "CAS"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDSuperResolutionQuality" -Value "Maximum Quality"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDSuperResolution2Quality" -Value "Balanced"
            Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "FSRFrameInterpolation" -Value "false"
        }
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AmbientLightingQuality" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "CinematicEmissive" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "CinematicQuality" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DxrDenoiser" -Value "Default"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "GraphicsQuality" -Value "Balanced"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ModelQuality" -Value "Low Quality"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ParticleQuality" -Value "very low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ShadowQuality" -Value "Very_Low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "TerrainQuality" -Value "Very Low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "HDR" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "PersistentDamageLayer" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ReflectionProbeHalfResolution" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "EnableVelocityBasedBlur" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ShaderQuality" -Value "Low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SubdivisionLevel" -Value "0"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SustainabilityMenuSceneResolution" -Value "min"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SustainabilityReduceQualityIdle" -Value "off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SustainabilityPauseRendering" -Value "false"
        [void](Set-SlxdeCodValueAfterComment -Lines $Lines -CommentPattern '(?i)eco mode preset' -Value 'Custom')
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VRS" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VolumetricQuality" -Value "QUALITY_LOW"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "WaterCausticsMode" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "WaterWaveWetness" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "WeatherGridVolumesQuality" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SkipIntro" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SkipSeasonIntroVideo" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ShowFPSCounter" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ConfigCloudStorageEnabled" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DisableHWChangeDetection" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "RecommendedSet" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "RendererWorkerCount" -Value ([string]$WorkerCount)
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VideoMemoryScaleMP" -Value "0.700000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VideoMemoryScale" -Value "0.900000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AATechniquePreferred" -Value "SMAA"

        [void]$Lines.Add("")
        [void]$Lines.Add("// SLXDE COD BO7 EXACT GRAPHICS PRESET APPLIED")
        [void]$Lines.Add("// Backup: $Backup")
        [void]$Lines.Add("// Copied graphics/performance settings only from Sam's provided BO7 config.")
        [void]$Lines.Add("// Audio, controls, device IDs, monitor IDs, mouse/controller settings were not copied.")
        [void]$Lines.Add("// Detected GPU: $GpuName")
        [void]$Lines.Add("// Hardware profile: $Profile")
        [void]$Lines.Add("// RendererWorkerCount set to $WorkerCount from $PhysicalCores detected physical cores.")

        $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $ConfigText = (([string[]]$Lines) -join [Environment]::NewLine) + [Environment]::NewLine
        [System.IO.File]::WriteAllText($Path, $ConfigText, $Utf8NoBom)

            $WrittenText = [System.IO.File]::ReadAllText($Path)
            foreach ($Expected in @(
                'GraphicsQuality@.*?=\s*Balanced',
                'TextureQuality@.*?=\s*3',
                'TerrainQuality@.*?=\s*Very Low',
                'ShadowQuality@.*?=\s*Very_Low',
                'GPUUploadHeaps@.*?=\s*false'
            )) {
                if ($WrittenText -notmatch $Expected) {
                    throw "BO7 config verification failed after writing $Path"
                }
            }

            if ($GpuVendor -eq 'NVIDIA') {
                foreach ($ExpectedNvidia in @(
                    'DLSSModeMP@.*?=\s*DLSS',
                    'DLSSPerfModeMP@.*?=\s*Balanced',
                    'DLSSModelUI@.*?=\s*TRANSFORMER'
                )) {
                    if ($WrittenText -notmatch $ExpectedNvidia) {
                        throw "NVIDIA BO7 profile verification failed after writing $Path"
                    }
                }
            }

            [void]$AppliedPaths.Add($Path)
        }

        # BO7 stores on-demand streaming controls in separate g.*.cod25 text files.
        # Match the game's own English setting descriptions so only the four requested
        # streaming options are changed, even if Activision changes the internal key IDs.
        $PlayersRoot = Split-Path -Parent $Paths[0]
        $StreamingFiles = @(Get-ChildItem -LiteralPath $PlayersRoot -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^g\..*cod25.*\.txt[01]$' })

        foreach ($StreamingFile in $StreamingFiles) {
            $StreamingLines = [System.Collections.ArrayList]::new()
            foreach ($line in @(Get-Content -LiteralPath $StreamingFile.FullName -ErrorAction Stop)) {
                [void]$StreamingLines.Add([string]$line)
            }

            $StreamingChanges = 0
            $StreamingChanges += Set-SlxdeCodValueAfterComment -Lines $StreamingLines -CommentPattern '(?i)on[- ]demand.*texture streaming|on[- ]demand.*high[- ]quality streaming' -Value 'Minimal'
            $StreamingChanges += Set-SlxdeCodValueAfterComment -Lines $StreamingLines -CommentPattern '(?i)allocated texture cache size' -Value '16'
            $StreamingChanges += Set-SlxdeCodValueAfterComment -Lines $StreamingLines -CommentPattern '(?i)^\s*//\s*(enable )?download limits?' -Value 'true'
            $StreamingChanges += Set-SlxdeCodValueAfterComment -Lines $StreamingLines -CommentPattern '(?i)daily download limit' -Value '1.000000'

            if ($StreamingChanges -gt 0) {
                $StreamingBackup = Backup-SlxdeGameConfigFile -Path $StreamingFile.FullName -Game "COD BO7"
                if ($StreamingBackup) { [void]$Backups.Add($StreamingBackup) }
                if ($StreamingFile.IsReadOnly) { $StreamingFile.IsReadOnly = $false }

                $StreamingText = (([string[]]$StreamingLines) -join [Environment]::NewLine) + [Environment]::NewLine
                [System.IO.File]::WriteAllText($StreamingFile.FullName, $StreamingText, $Utf8NoBom)
                [void]$AppliedPaths.Add($StreamingFile.FullName)
            }
        }

        # BO7 uses this small marker alongside txt0/txt1. Refreshing it mirrors the
        # game's accepted installer format so the updated configs are loaded reliably.
        $MarkerPath = Join-Path $PlayersRoot "s.1.0.cod25.m"
        if (Test-Path $MarkerPath) {
            $MarkerBackup = Backup-SlxdeGameConfigFile -Path $MarkerPath -Game "COD BO7"
            if ($MarkerBackup) { [void]$Backups.Add($MarkerBackup) }
            $MarkerItem = Get-Item -LiteralPath $MarkerPath -ErrorAction Stop
            if ($MarkerItem.IsReadOnly) { $MarkerItem.IsReadOnly = $false }
        }
        [System.IO.File]::WriteAllBytes($MarkerPath, [byte[]](0x01, 0x01))

        $AppliedList = $AppliedPaths -join "`n"
        $BackupList = $Backups -join "`n"

        Write-Log "Applied SLXDE COD BO7 $Profile profile to $($AppliedPaths.Count) config file(s)"
        return "SLXDE COD config applied and verified successfully.`n`nDetected GPU:`n$GpuName`n`nApplied profile:`n$Profile`n`nPhysical CPU cores: $PhysicalCores`nRenderer Worker Count: $WorkerCount`n`nConfig files updated:`n$AppliedList`n`nBackups created:`n$BackupList`n`nLaunch BO7 and check your graphics settings."
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}
