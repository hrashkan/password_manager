# PowerShell build script for creating installable packages for Windows

$ErrorActionPreference = "Stop"

$APP_NAME = "rusty-vault"
$VERSION = (Select-String -Path "Cargo.toml" -Pattern '^version\s*=\s*"(.*)"' | ForEach-Object { $_.Matches.Groups[1].Value })
$HOST_TRIPLE = (rustc -vV | Select-String -Pattern '^host: (.*)' | ForEach-Object { $_.Matches.Groups[1].Value })

Write-Host "Building $APP_NAME v$VERSION for Windows ($HOST_TRIPLE)" -ForegroundColor Cyan

# Build release binary
Write-Host "Building release binary..." -ForegroundColor Yellow
cargo build --release --locked

# Create dist directory
New-Item -ItemType Directory -Force -Path "dist" | Out-Null

# Create zip archive
Write-Host "Creating zip archive..." -ForegroundColor Yellow
$ZIP_NAME = "${APP_NAME}-v${VERSION}-${HOST_TRIPLE}.zip"
$EXE_PATH = "target\release\${APP_NAME}.exe"

if (Test-Path $EXE_PATH) {
    Compress-Archive -Path $EXE_PATH -DestinationPath "dist\$ZIP_NAME" -Force
    Write-Host "✓ Created: dist\$ZIP_NAME" -ForegroundColor Green
} else {
    Write-Host "✗ Error: $EXE_PATH not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Packages created in dist\ directory:" -ForegroundColor Cyan
Get-ChildItem -Path "dist" | Format-Table Name, Length, LastWriteTime

