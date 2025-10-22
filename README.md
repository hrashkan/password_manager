## rusty-vault

A small local, encrypted password manager CLI written in Rust.

### Quick install

- Ubuntu/Debian (.deb): download from the Releases page and install:

```bash
cd ~/Downloads
sudo apt install -y ./password-manager_0.1.0-1_amd64.deb
```

- Linux/macOS (tar.gz): download the tarball, extract, and place on PATH:

```bash
cd ~/Downloads
tar xf rusty-vault-v0.1.0-x86_64-unknown-linux-gnu.tar.gz
sudo install -m 0755 rusty-vault /usr/local/bin/rusty-vault
```

- Windows (zip): download the zip, extract, and add the folder to PATH.

- Releases: https://github.com/hrashkan/password_manager/releases

### Build

- Prerequisites: Rust toolchain (stable). Install via [`https://rustup.rs`](https://rustup.rs).
- Clone and build:

```bash
git clone <your-fork-or-repo-url>.git
cd password_manager
cargo build --release --locked
```

The binary is at `target/release/rusty-vault` (Linux/macOS) or `target\release\rusty-vault.exe` (Windows).

### Usage

The vault is stored at a local data directory (from `dirs::data_local_dir()`), file name `rusty_vault.json`. You can also pass a custom path via `--vault`.

Initialize or open a vault (you will be prompted for a master password unless provided non-interactively):

```bash
rusty-vault init
```

Add or update an entry:

```bash
rusty-vault add <name> --username <user> [--password <pwd>] [--url <url>] [--notes <notes>]
# If --password is omitted, you'll be prompted securely.
```

Retrieve an entry:

```bash
rusty-vault get <name>
```

Delete an entry:

```bash
rusty-vault delete <name>
```

List entries:

```bash
rusty-vault list
```

Use a custom vault file path:

```bash
rusty-vault --vault /path/to/my_vault.json init
```

Non-interactive master password (for CI or scripting):

```bash
# Option 1: Flag
rusty-vault --master-password "secret" init

# Option 2: Environment variable
RUSTY_VAULT_MASTER_PASSWORD="secret" rusty-vault init
```

### Security notes

- Master password is used to derive a 256-bit key via Argon2; entries are encrypted with AES-256-GCM.
- The derived key is zeroized in memory on drop.
- Keep your `rusty_vault.json` safe and backed up. Without the master password, the data cannot be recovered.

### Cross-platform

- Linux, Windows, and macOS are supported. Build with `cargo build --release` on your platform to get a native binary.
- Install from GitHub Releases (prebuilt binaries):

  - Download the archive for your OS/arch from the Releases page (e.g., `rusty-vault-vX.Y.Z-x86_64-unknown-linux-gnu.tar.gz`, `-x86_64-pc-windows-msvc.zip`, `-x86_64-apple-darwin.tar.gz`).
  - Extract and place the binary somewhere on your `PATH`.

- Or install from source locally:

```bash
cargo install --path . --locked
```

This installs the binary into Cargo's bin directory (`~/.cargo/bin` on Linux/macOS, `%USERPROFILE%\.cargo\bin` on Windows).

### Install

- Linux (Debian/Ubuntu): download the `.deb` from Releases and install:

```bash
sudo dpkg -i rusty-vault_*.deb || sudo apt -f install
```

- Linux/macOS (manual): download the `.tar.gz`, extract, and move the binary into a directory on `PATH` (e.g., `/usr/local/bin`).

- Windows: download the `.zip`, extract, and add the folder to your `PATH` (or move `rusty-vault.exe` into a directory already on `PATH`).

### Contributing

1. Fork and create a feature branch.
2. Make changes with clear commits.
3. Run `cargo fmt && cargo clippy && cargo test` if applicable.
4. Open a PR.

### License

MIT
