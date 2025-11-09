# Packaging Guide

This guide explains how to create installable packages for Linux, Windows, and macOS.

## Prerequisites

- Rust toolchain (stable) - Install from [rustup.rs](https://rustup.rs)
- For Linux `.deb` packages: `cargo install cargo-deb`
- For macOS `.dmg` packages: `brew install create-dmg` (optional)
- For Windows: PowerShell (built-in)

## Building Packages

### Linux (Ubuntu/Debian)

**Option 1: Using the build script**

```bash
chmod +x build-packages.sh
./build-packages.sh
```

**Option 2: Manual steps**

```bash
# Build release binary
cargo build --release --locked

# Create .deb package
cargo deb --no-build

# The .deb file will be in target/debian/
# Example: target/debian/rusty-vault_0.1.0-1_amd64.deb
```

**Installing the .deb package:**

```bash
sudo dpkg -i target/debian/rusty-vault_*.deb
# If dependencies are missing:
sudo apt-get install -f
```

**Creating a tar.gz archive:**

```bash
tar -czf rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.tar.gz -C target/release rusty-vault
```

### Windows

**Option 1: Using PowerShell script**

```powershell
.\build-packages.ps1
```

**Option 2: Manual steps**

```powershell
# Build release binary
cargo build --release --locked

# Create zip archive
Compress-Archive -Path target\release\rusty-vault.exe -DestinationPath rusty-vault-v0.1.0-x86_64-pc-windows-msvc.zip
```

**Installing:**

1. Extract the zip file
2. Add the folder containing `rusty-vault.exe` to your PATH, or
3. Move `rusty-vault.exe` to a directory already on your PATH (e.g., `C:\Windows\System32`)

### macOS

**Option 1: Using the build script**

```bash
chmod +x build-packages.sh
./build-packages.sh
```

**Option 2: Manual steps**

```bash
# Build release binary
cargo build --release --locked

# Create tar.gz archive
tar -czf rusty-vault-v0.1.0-x86_64-apple-darwin.tar.gz -C target/release rusty-vault

# Create .dmg (optional, requires create-dmg)
brew install create-dmg
mkdir rusty-vault-dmg
cp target/release/rusty-vault rusty-vault-dmg/
create-dmg \
  --volname "rusty-vault" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  rusty-vault-v0.1.0-x86_64-apple-darwin.dmg \
  rusty-vault-dmg/
```

**Installing:**

```bash
# From tar.gz:
tar xf rusty-vault-v0.1.0-x86_64-apple-darwin.tar.gz
sudo install -m 0755 rusty-vault /usr/local/bin/rusty-vault

# From .dmg:
# Double-click the .dmg file and drag the app to Applications
```

## Cross-Compilation

To build packages for other platforms, you'll need to set up cross-compilation:

### Linux → Windows

```bash
# Install cross-compilation target
rustup target add x86_64-pc-windows-msvc

# Build for Windows
cargo build --release --target x86_64-pc-windows-msvc
```

### Linux → macOS

```bash
# Install cross-compilation target (requires macOS SDK)
rustup target add x86_64-apple-darwin
# Note: macOS cross-compilation from Linux is complex and may require osxcross
```

### Windows → Linux

```bash
# Install cross-compilation target
rustup target add x86_64-unknown-linux-gnu

# Build for Linux
cargo build --release --target x86_64-unknown-linux-gnu
```

## Package Metadata

The Debian package metadata is configured in `Cargo.toml` under `[package.metadata.deb]`. You can customize:

- Maintainer information
- Description
- Dependencies
- Section and priority

## Distribution

After building packages, they will be in the `dist/` directory (if using build scripts) or in `target/debian/` for .deb packages.

For GitHub Releases:

1. Tag your release: `git tag v0.1.0`
2. Push the tag: `git push origin v0.1.0`
3. The GitHub Actions workflow (`.github/workflows/release.yml`) will automatically build and upload packages

## Testing Packages

Before distributing, test your packages:

**Linux .deb:**

```bash
# Install in a clean environment (use Docker or VM)
sudo dpkg -i rusty-vault_*.deb
rusty-vault --version
```

**Windows:**

```bash
# Extract and test
rusty-vault.exe --version
```

**macOS:**

```bash
# Extract and test
./rusty-vault --version
```
