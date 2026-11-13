$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Install Flutter stable and add flutter/bin to PATH first.'
}
# Flutter creates only missing platform files; keep existing application source.
flutter create --platforms=android,ios,web --project-name kinkin --org com.kinkin .
if ($LASTEXITCODE -ne 0) { throw 'Flutter platform generation failed.' }
Write-Host 'Platform files created. Follow README.md to configure Maps keys and location permissions.'
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' }
