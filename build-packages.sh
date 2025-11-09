#!/bin/bash
# Build script for creating installable packages for Linux, Windows, and macOS

set -euo pipefail

APP_NAME="rusty-vault"
VERSION=$(grep '^version' Cargo.toml | cut -d'"' -f2)
HOST_TRIPLE=$(rustc -vV | sed -n 's/^host: //p')
OS_TYPE=$(uname -s)

# Check if --all-platforms flag is set
BUILD_ALL=false
if [[ "${1:-}" == "--all-platforms" ]] || [[ "${1:-}" == "--all" ]]; then
    BUILD_ALL=true
fi

echo "Building $APP_NAME v$VERSION"
if [ "$BUILD_ALL" = true ] && [ "$OS_TYPE" = "Linux" ]; then
    echo "Building for ALL platforms (Linux, Windows, macOS)..."
else
    echo "Building for $OS_TYPE ($HOST_TRIPLE)"
fi

# Create dist directory
mkdir -p dist

# Function to build Windows package
build_windows() {
    echo ""
    echo "=== Building for Windows ==="
    # Use GNU target for cross-compilation from Linux (doesn't require MSVC)
    TARGET="x86_64-pc-windows-gnu"
    
    # Check if target is installed
    if ! rustup target list --installed | grep -q "$TARGET"; then
        echo "Installing $TARGET target..."
        rustup target add "$TARGET"
    fi
    
    echo "Cross-compiling for Windows (GNU toolchain)..."
    echo "Note: This requires mingw-w64. Install with: sudo apt-get install mingw-w64"
    cargo build --release --locked --target "$TARGET" 2>&1 | grep -E "(Compiling|Finished|error|warning)" || true
    
    if [ -f "target/$TARGET/release/${APP_NAME}.exe" ]; then
        ZIP_NAME="${APP_NAME}-v${VERSION}-${TARGET}.zip"
        if command -v zip &> /dev/null; then
            cd "target/$TARGET/release"
            zip -q "../../../dist/$ZIP_NAME" "${APP_NAME}.exe"
            cd ../../..
            echo "✓ Created: dist/$ZIP_NAME"
        elif command -v 7z &> /dev/null; then
            cd "target/$TARGET/release"
            7z a -tzip "../../../dist/$ZIP_NAME" "${APP_NAME}.exe" > /dev/null
            cd ../../..
            echo "✓ Created: dist/$ZIP_NAME"
        else
            echo "⚠ zip or 7z not found. Skipping Windows zip creation."
        fi
    else
        echo "✗ Failed to build Windows binary"
    fi
}

# Function to build macOS package
build_macos() {
    echo ""
    echo "=== Building for macOS ==="
    TARGET="x86_64-apple-darwin"
    
    # Check if target is installed
    if ! rustup target list --installed | grep -q "$TARGET"; then
        echo "Installing $TARGET target..."
        rustup target add "$TARGET" || {
            echo "⚠ macOS cross-compilation requires additional setup (osxcross)"
            echo "  Skipping macOS build. Build on macOS for native packages."
            return
        }
    fi
    
    echo "Cross-compiling for macOS..."
    # Note: macOS cross-compilation from Linux requires osxcross and is complex
    # This will likely fail without proper setup, but we'll try
    if cargo build --release --locked --target "$TARGET" 2>/dev/null; then
        if [ -f "target/$TARGET/release/$APP_NAME" ]; then
            TARBALL="${APP_NAME}-v${VERSION}-${TARGET}.tar.gz"
            tar -C "target/$TARGET/release" -czf "dist/$TARBALL" "$APP_NAME"
            echo "✓ Created: dist/$TARBALL"
        fi
    else
        echo "⚠ macOS cross-compilation failed (requires osxcross setup)"
        echo "  To build macOS packages, run this script on macOS or set up osxcross"
    fi
}

# Build for all platforms if requested
if [ "$BUILD_ALL" = true ] && [ "$OS_TYPE" = "Linux" ]; then
    # Build Windows
    build_windows
    
    # Build macOS (may fail without osxcross)
    build_macos
    
    # Build Linux (native)
    echo ""
    echo "=== Building for Linux (native) ==="
    cargo build --release --locked
else
    # Build release binary for current platform
    echo "Building release binary..."
    cargo build --release --locked
fi

case "$OS_TYPE" in
    Linux)
        echo "Creating Linux packages..."
        
        # Create .deb package
        if command -v cargo-deb &> /dev/null; then
            echo "Creating .deb package..."
            cargo deb --no-build
            DEB_FILE=$(ls target/debian/*.deb | head -n1)
            DEB_NAME=$(basename "$DEB_FILE")
            cp "$DEB_FILE" "dist/$DEB_NAME"
            echo "✓ Created: dist/$DEB_NAME"
        else
            echo "⚠ cargo-deb not found. Install with: cargo install cargo-deb"
        fi
        
        # Create tar.gz archive
        echo "Creating tar.gz archive..."
        TARBALL="${APP_NAME}-v${VERSION}-${HOST_TRIPLE}.tar.gz"
        tar -C target/release -czf "dist/$TARBALL" "$APP_NAME"
        echo "✓ Created: dist/$TARBALL"
        
        # Create AppImage (requires appimagetool)
        if command -v appimagetool &> /dev/null; then
            echo "Creating AppImage..."
            APPIMAGE_NAME="${APP_NAME}-v${VERSION}-${HOST_TRIPLE}.AppImage"
            APPDIR="dist/${APP_NAME}.AppDir"
            
            # Create AppDir structure
            mkdir -p "$APPDIR/usr/bin"
            mkdir -p "$APPDIR/usr/share/applications"
            mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
            
            # Copy binary
            cp "target/release/$APP_NAME" "$APPDIR/usr/bin/"
            chmod +x "$APPDIR/usr/bin/$APP_NAME"
            
            # Create AppRun script
            cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}/usr/bin/rusty-vault" "$@"
EOF
            chmod +x "$APPDIR/AppRun"
            
            # Create .desktop file
            cat > "$APPDIR/rusty-vault.desktop" << EOF
[Desktop Entry]
Name=rusty-vault
Comment=Local encrypted password manager
Exec=rusty-vault
Icon=rusty-vault
Terminal=true
Type=Application
Categories=Utility;
EOF
            
            # Also copy to standard location
            mkdir -p "$APPDIR/usr/share/applications"
            cp "$APPDIR/rusty-vault.desktop" "$APPDIR/usr/share/applications/"
            
            # Create a simple placeholder icon (1x1 transparent PNG)
            # You can replace this with a real icon later
            mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
            # Create a minimal valid PNG (1x1 transparent pixel)
            printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xdb\x00\x00\x00\x00IEND\xaeB`\x82' > "$APPDIR/rusty-vault.png"
            cp "$APPDIR/rusty-vault.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/"
            
            # Create AppImage
            appimagetool "$APPDIR" "dist/$APPIMAGE_NAME"
            rm -rf "$APPDIR"
            echo "✓ Created: dist/$APPIMAGE_NAME"
        else
            echo "⚠ appimagetool not found. Install with:"
            echo "  wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
            echo "  chmod +x appimagetool-x86_64.AppImage"
            echo "  sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool"
        fi
        ;;
        
    Darwin)
        echo "Creating macOS packages..."
        
        # Create tar.gz archive
        TARBALL="${APP_NAME}-v${VERSION}-${HOST_TRIPLE}.tar.gz"
        tar -C target/release -czf "dist/$TARBALL" "$APP_NAME"
        echo "✓ Created: dist/$TARBALL"
        
        # Create .dmg (requires create-dmg or hdiutil)
        if command -v create-dmg &> /dev/null; then
            echo "Creating .dmg package..."
            DMG_NAME="${APP_NAME}-v${VERSION}-${HOST_TRIPLE}.dmg"
            DMG_TEMP="dist/${APP_NAME}-dmg"
            mkdir -p "$DMG_TEMP"
            cp "target/release/$APP_NAME" "$DMG_TEMP/"
            create-dmg \
                --volname "$APP_NAME" \
                --volicon "icon.icns" 2>/dev/null || true \
                --window-pos 200 120 \
                --window-size 800 400 \
                --icon-size 100 \
                --icon "$APP_NAME" 200 190 \
                --hide-extension "$APP_NAME" \
                --app-drop-link 600 185 \
                "dist/$DMG_NAME" \
                "$DMG_TEMP"
            rm -rf "$DMG_TEMP"
            echo "✓ Created: dist/$DMG_NAME"
        else
            echo "⚠ create-dmg not found. Install with: brew install create-dmg"
            echo "  Or use hdiutil manually to create .dmg"
        fi
        ;;
        
    MINGW*|MSYS*|CYGWIN*)
        echo "Creating Windows packages..."
        
        # Create zip archive
        ZIP_NAME="${APP_NAME}-v${VERSION}-${HOST_TRIPLE}.zip"
        cd target/release
        if command -v zip &> /dev/null; then
            zip "../../dist/$ZIP_NAME" "${APP_NAME}.exe"
        elif command -v 7z &> /dev/null; then
            7z a "../../dist/$ZIP_NAME" "${APP_NAME}.exe"
        else
            echo "⚠ zip or 7z not found. Please install one to create zip archive."
        fi
        cd ../..
        echo "✓ Created: dist/$ZIP_NAME"
        ;;
        
    *)
        echo "⚠ Unknown OS: $OS_TYPE"
        echo "Creating generic tar.gz archive..."
        TARBALL="${APP_NAME}-v${VERSION}-${HOST_TRIPLE}.tar.gz"
        tar -C target/release -czf "dist/$TARBALL" "$APP_NAME" 2>/dev/null || \
        tar -C target/release -czf "dist/$TARBALL" "${APP_NAME}.exe" 2>/dev/null || true
        if [ -f "dist/$TARBALL" ]; then
            echo "✓ Created: dist/$TARBALL"
        fi
        ;;
esac

echo ""
echo "Packages created in dist/ directory:"
ls -lh dist/ 2>/dev/null || echo "No packages created"

