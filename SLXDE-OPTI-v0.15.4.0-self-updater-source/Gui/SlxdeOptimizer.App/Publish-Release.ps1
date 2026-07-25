$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

dotnet restore
dotnet publish -c Release -r win-x64 --self-contained true `
  /p:PublishSingleFile=true `
  /p:IncludeNativeLibrariesForSelfExtract=true `
  /p:EnableCompressionInSingleFile=true

$publish = Join-Path $PSScriptRoot "bin\Release\net8.0-windows\win-x64\publish"
$zip = Join-Path $PSScriptRoot "SLXDE-OPTI-v0.15.4.0-win-x64.zip"

if (Test-Path $zip) {
    Remove-Item $zip -Force
}

Compress-Archive -Path (Join-Path $publish "*") -DestinationPath $zip -Force

Write-Host ""
Write-Host "Release zip created:" -ForegroundColor Cyan
Write-Host $zip -ForegroundColor Green
Write-Host ""
Write-Host "Send this ZIP to your laptop/friends. Extract it, then run SlxdeOptimizer.App.exe as Administrator."
