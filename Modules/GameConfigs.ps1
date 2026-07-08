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


function Find-SlxdeCodBo7ConfigFile {
    $Root = Join-Path $env:USERPROFILE "Documents\Call of Duty\players"

    if (!(Test-Path $Root)) {
        return $null
    }

    # Real BO7/COD HQ player settings are usually these txt files.
    $Preferred = @(
        (Join-Path $Root "s.1.0.cod24.txt0"),
        (Join-Path $Root "s.1.0.cod24.txt1")
    )

    foreach ($Path in $Preferred) {
        if (Test-Path $Path) {
            return $Path
        }
    }

    # Fallback: only select the txt settings files, never the tiny metadata file.
    return Get-ChildItem -Path $Root -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^s\.1\.0\.cod24\.txt[0-9]+$' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -ExpandProperty FullName -First 1
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
            break
        }
    }

    if (-not $found) {
        [void]$Lines.Add("$KeyPrefix@0;0;0 = $Value // Added by SLXDE")
    }
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
        $Path = Find-SlxdeCodBo7ConfigFile

        if (!$Path) {
            return "COD BO7 config not found.`n`nLaunch BO7 once, change one graphics setting, close the game, then try again.`nExpected folder:`n$env:USERPROFILE\Documents\Call of Duty\players"
        }

        $Backup = Backup-SlxdeGameConfigFile -Path $Path -Game "COD BO7"

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
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AmdAntilag2" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ResolutionMultiplier" -Value "100"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "NvidiaReflex" -Value "Enabled"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VSync" -Value "disabled"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "CapFps" -Value "true"
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
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDContrastAdaptiveSharpeningStrength" -Value "1.000000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDFidelityFX" -Value "CAS"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDSuperResolutionQuality" -Value "Maximum Quality"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AMDSuperResolution2Quality" -Value "Balanced"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "FSRFrameInterpolation" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DeferredPhysics" -Value "Low Quality"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DxrMode" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DynamicSceneResolution" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DynamicSceneResolutionTarget" -Value "16.670000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "XeSSQuality" -Value "Balanced"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "GPUUploadHeaps" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSMode" -Value "DLSS"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSPerfMode" -Value "Maximum Quality"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSSharpness" -Value "0.500000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSRRPerfMode" -Value "Maximum Performance"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "DLSSFrameGeneration" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "NVIDIAImageScaling" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "NVIDIAImageScalingQuality" -Value "Maximum Quality"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "NVIDIAImageScalingSharpness" -Value "1.000000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AmbientLightingQuality" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "GraphicsQuality" -Value "Basic"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ModelQuality" -Value "Low Quality"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ParticleQuality" -Value "very low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ShadowQuality" -Value "Very_Low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "HDR" -Value "Off"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "PersistentDamageLayer" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ReflectionProbeHalfResolution" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "EnableVelocityBasedBlur" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "ShaderQuality" -Value "Low"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SubdivisionLevel" -Value "0"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SustainabilityMenuSceneResolution" -Value "full"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SustainabilityReduceQualityIdle" -Value "min"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "SustainabilityPauseRendering" -Value "false"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VRS" -Value "true"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VirtualTexturingMemoryMode" -Value "Small"
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
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "RendererWorkerCount" -Value "7"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VideoMemoryScaleMP" -Value "0.700000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "VideoMemoryScale" -Value "0.900000"
        Set-SlxdeCodExactKey -Lines $Lines -KeyPrefix "AATechniquePreferred" -Value "SMAA"

        [void]$Lines.Add("")
        [void]$Lines.Add("// SLXDE COD BO7 EXACT GRAPHICS PRESET APPLIED")
        [void]$Lines.Add("// Backup: $Backup")
        [void]$Lines.Add("// Copied graphics/performance settings only from Sam's provided BO7 config.")
        [void]$Lines.Add("// Audio, controls, device IDs, monitor IDs, mouse/controller settings were not copied.")
        [void]$Lines.Add("// RendererWorkerCount set to 7.")
        [void]$Lines.Add("// AMD FidelityFX CAS / SMAA / low/off visual preset applied.")

        Set-Content -Path $Path -Value ([string[]]$Lines) -Encoding UTF8

        Write-Log "Applied COD BO7 exact graphics preset"
        return "COD BO7 exact graphics preset applied.`nConfig:`n$Path`nBackup created:`n$Backup`n`nRestart BO7 and check graphics settings."
    }
    catch {
        return "Failed: $($_.Exception.Message)"
    }
}

