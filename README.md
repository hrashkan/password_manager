# rusty-vault

A small local, encrypted password manager CLI written in Rust.

## Features

- 🔒 **AES-256-GCM encryption** - Industry-standard encryption
- 🔑 **Argon2 key derivation** - Secure password hashing
- 💾 **Local storage** - Your data stays on your machine
- 🚀 **Fast & lightweight** - Built with Rust for performance
- 🌍 **Cross-platform** - Linux, Windows, and macOS support
- 📦 **Multiple package formats** - .deb, AppImage, .zip, .tar.gz

## Installation

Pre-built packages are available in the [`dist/`](dist/) directory of this repository, or you can download them from the [Releases page](https://github.com/hrashkan/password_manager/releases).

### Available Packages

| Platform              | Package     | Size  | Location                                                                                                                 |
| --------------------- | ----------- | ----- | ------------------------------------------------------------------------------------------------------------------------ |
| Linux (Ubuntu/Debian) | `.deb`      | 496KB | [`dist/password-manager_0.1.0-1_amd64.deb`](dist/password-manager_0.1.0-1_amd64.deb)                                     |
| Linux (Portable)      | `.AppImage` | 918KB | [`dist/rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.AppImage`](dist/rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.AppImage) |
| Linux/macOS           | `.tar.gz`   | 723KB | [`dist/rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.tar.gz`](dist/rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.tar.gz)     |
| Windows               | `.zip`      | 1.2MB | [`dist/rusty-vault-v0.1.0-x86_64-pc-windows-gnu.zip`](dist/rusty-vault-v0.1.0-x86_64-pc-windows-gnu.zip)                 |

### Linux (Ubuntu/Debian)

#### Option 1: Debian Package (.deb) - Recommended

```bash
# Download from dist/ directory or Releases page
wget https://github.com/hrashkan/password_manager/raw/master/dist/password-manager_0.1.0-1_amd64.deb
# Or clone the repo and use the file from dist/

# Install
sudo dpkg -i password-manager_0.1.0-1_amd64.deb

# If dependencies are missing:
sudo apt-get install -f
```

#### Option 2: AppImage (Portable)

```bash
# Download from dist/ directory or Releases page
wget https://github.com/hrashkan/password_manager/raw/master/dist/rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.AppImage
# Or clone the repo and use the file from dist/

# Make executable
chmod +x rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.AppImage

# Run directly
./rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.AppImage --version

# Or move to a permanent location
mkdir -p ~/Applications
mv rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.AppImage ~/Applications/
```

#### Option 3: Manual Installation (tar.gz)

```bash
# Download from dist/ directory or Releases page
wget https://github.com/hrashkan/password_manager/raw/master/dist/rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.tar.gz
# Or clone the repo and use the file from dist/

# Extract
tar xf rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.tar.gz

# Install system-wide
sudo install -m 0755 rusty-vault /usr/local/bin/

# Or install to user directory
mkdir -p ~/.local/bin
cp rusty-vault ~/.local/bin/
# Add ~/.local/bin to PATH if not already in ~/.bashrc or ~/.zshrc
```

### Windows

1. Download `rusty-vault-v0.1.0-x86_64-pc-windows-gnu.zip` from the [`dist/`](dist/) directory or [Releases page](https://github.com/hrashkan/password_manager/releases)
2. Extract the ZIP file
3. Copy `rusty-vault.exe` to a folder on your PATH:
   - Option A: Copy to `C:\Windows\System32` (requires admin)
   - Option B: Create a folder (e.g., `C:\Tools`), add it to PATH, and copy the exe there

To add a folder to PATH:

1. Open System Properties → Environment Variables
2. Edit the `Path` variable
3. Add your folder path
4. Restart your terminal

### macOS

```bash
# Download from dist/ directory or Releases page
wget https://github.com/hrashkan/password_manager/raw/master/dist/rusty-vault-v0.1.0-x86_64-apple-darwin.tar.gz
# Or clone the repo and use the file from dist/

# Extract
tar xf rusty-vault-v0.1.0-x86_64-apple-darwin.tar.gz

# Install
sudo install -m 0755 rusty-vault /usr/local/bin/
```

**Note:** macOS packages are built when running the build script on macOS. For Linux users, you'll need to build from source or wait for a macOS release.

### Install from Source

```bash
# Prerequisites: Rust toolchain (install from https://rustup.rs)
git clone https://github.com/hrashkan/password_manager.git
cd password_manager
cargo install --path . --locked
```

This installs to `~/.cargo/bin/rusty-vault` (Linux/macOS) or `%USERPROFILE%\.cargo\bin\rusty-vault.exe` (Windows).

## Usage

### Initialize a Vault

Create a new vault or open an existing one:

```bash
rusty-vault init
```

You'll be prompted for a master password. This password encrypts all your entries.

### Add a Password Entry

```bash
# With all fields
rusty-vault add github \
  --username myuser \
  --password secret123 \
  --url https://github.com \
  --notes "My GitHub account"

# Password will be prompted securely if omitted
rusty-vault add email --username user@example.com --url https://mail.example.com
```

### Retrieve an Entry

```bash
rusty-vault get github
```

Output:

```
username: myuser
password: secret123
url: https://github.com
notes: My GitHub account
```

### List All Entries

```bash
rusty-vault list
```

Output:

```
github
email
```

### Delete an Entry

```bash
rusty-vault delete github
```

### Use a Custom Vault Location

```bash
rusty-vault --vault /path/to/my_vault.json init
```

### Non-Interactive Mode (for Scripts)

```bash
# Using command-line flag
rusty-vault --master-password "your-password" init

# Using environment variable
export RUSTY_VAULT_MASTER_PASSWORD="your-password"
rusty-vault init
```

## Vault Location

By default, the vault is stored at:

- **Linux**: `~/.local/share/rusty_vault.json`
- **Windows**: `%APPDATA%\rusty_vault.json`
- **macOS**: `~/Library/Application Support/rusty_vault.json`

You can specify a custom path with `--vault` option.

## Security

- **Encryption**: AES-256-GCM (authenticated encryption)
- **Key Derivation**: Argon2 (memory-hard password hashing)
- **Memory Safety**: Derived keys are zeroized in memory after use
- **Local Storage**: All data is stored locally on your machine
- **No Cloud Sync**: Your passwords never leave your device

⚠️ **Important**:

- Keep your master password safe - without it, your data cannot be recovered
- Back up your `rusty_vault.json` file regularly
- Never share your master password or vault file

## Building from Source

### Prerequisites

- Rust toolchain (stable) - Install from [rustup.rs](https://rustup.rs)
- For .deb packages: `cargo install cargo-deb`
- For AppImage: `appimagetool` (see build script for installation)

### Build

```bash
git clone https://github.com/hrashkan/password_manager.git
cd password_manager
cargo build --release --locked
```

The binary will be at `target/release/rusty-vault` (Linux/macOS) or `target/release/rusty-vault.exe` (Windows).

### Create Installable Packages

The project includes build scripts to create packages for all platforms:

**Build for current platform:**

```bash
./build-packages.sh
```

**Build for all platforms (Linux only, requires cross-compilation setup):**

```bash
./build-packages.sh --all-platforms
```

This creates:

- Linux: `.deb`, `.AppImage`, `.tar.gz`
- Windows: `.zip`
- macOS: `.tar.gz` (when built on macOS)

Packages are created in the `dist/` directory. See [PACKAGING.md](PACKAGING.md) for detailed instructions.

## Examples

### Complete Workflow

```bash
# 1. Initialize vault
rusty-vault init

# 2. Add entries
rusty-vault add github --username alice --password gh_token_123 --url https://github.com
rusty-vault add email --username alice@example.com --password email_pass_456
rusty-vault add bank --username alice --password bank_pin --notes "Main bank account"

# 3. List all entries
rusty-vault list

# 4. Retrieve an entry
rusty-vault get github

# 5. Update an entry (just add again with same name)
rusty-vault add github --username alice --password new_token --url https://github.com

# 6. Delete an entry
rusty-vault delete bank
```

## Command Reference

```
rusty-vault [OPTIONS] <COMMAND>

Commands:
  init              Initialize a new vault or open existing
  add <NAME>        Add or update an entry by name
  get <NAME>        Retrieve and print an entry
  delete <NAME>     Delete an entry
  list              List entry names
  help              Print help

Options:
  --vault <VAULT>                    Custom vault file path
  --master-password <PASSWORD>        Master password (non-interactive)
  -h, --help                         Print help
  -V, --version                      Print version

Add Options:
  --username <USERNAME>              Username (required)
  --password <PASSWORD>              Password (optional, will prompt if omitted)
  --url <URL>                        URL (optional)
  --notes <NOTES>                    Notes (optional)
```

## Troubleshooting

### "Permission denied" when running AppImage

```bash
chmod +x rusty-vault-*.AppImage
```

### "Command not found" after installation

- Make sure the installation directory is in your PATH
- Restart your terminal
- On Linux, check `/usr/local/bin` or `~/.local/bin`

### Windows: "rusty-vault is not recognized"

- Ensure the folder containing `rusty-vault.exe` is in your PATH
- Restart your terminal/command prompt after adding to PATH

### Forgot master password

Unfortunately, without the master password, your encrypted data cannot be recovered. This is by design for security. Always keep your master password safe and backed up.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with clear commits
4. Run `cargo fmt && cargo clippy` to format and lint
5. Test your changes
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Links

- **Releases**: https://github.com/hrashkan/password_manager/releases
- **Issues**: https://github.com/hrashkan/password_manager/issues
