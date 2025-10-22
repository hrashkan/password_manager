use crate::crypto::{
    DerivedKey, NONCE_SIZE, SALT_SIZE, decrypt, derive_key_from_password, encrypt,
};
use anyhow::{Context, Result, anyhow};
use base64::{Engine as _, engine::general_purpose};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Entry {
    pub username: String,
    pub password: String,
    pub url: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VaultPlain {
    pub entries: BTreeMap<String, Entry>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VaultCipher {
    pub kdf_salt_b64: String,
    pub nonce_b64: String,
    pub ciphertext_b64: String,
}

impl VaultPlain {
    pub fn new() -> Self {
        Self {
            entries: BTreeMap::new(),
        }
    }
}

pub fn default_vault_path() -> Result<PathBuf> {
    let dir = dirs::data_local_dir().unwrap_or(std::env::current_dir()?);
    let path = dir.join("rusty_vault.json");
    Ok(path)
}

pub fn load_or_init(master_password: &str, path: &Path) -> Result<(VaultPlain, DerivedKey)> {
    if path.exists() {
        let data = fs::read_to_string(path)
            .with_context(|| format!("failed to read vault at {}", path.display()))?;
        let cipher: VaultCipher = serde_json::from_str(&data).context("invalid vault format")?;
        let salt = general_purpose::STANDARD
            .decode(cipher.kdf_salt_b64)
            .context("invalid salt b64")?;
        let nonce = general_purpose::STANDARD
            .decode(cipher.nonce_b64)
            .context("invalid nonce b64")?;
        let ciphertext = general_purpose::STANDARD
            .decode(cipher.ciphertext_b64)
            .context("invalid ciphertext b64")?;

        let salt_arr: [u8; SALT_SIZE] = salt.try_into().map_err(|_| anyhow!("bad salt length"))?;
        let nonce_arr: [u8; NONCE_SIZE] =
            nonce.try_into().map_err(|_| anyhow!("bad nonce length"))?;
        let derived = derive_key_from_password(master_password, Some(salt_arr))?;
        let plaintext = decrypt(&derived.key, &nonce_arr, &ciphertext)?;
        let vault: VaultPlain =
            serde_json::from_slice(&plaintext).context("failed to parse decrypted vault")?;
        Ok((vault, derived))
    } else {
        let derived = derive_key_from_password(master_password, None)?;
        Ok((VaultPlain::new(), derived))
    }
}

pub fn save(master_key: &DerivedKey, vault: &VaultPlain, path: &Path) -> Result<()> {
    let serialized = serde_json::to_vec(vault).context("failed to serialize vault")?;
    let (ciphertext, nonce) = encrypt(&master_key.key, &serialized)?;
    let cipher = VaultCipher {
        kdf_salt_b64: general_purpose::STANDARD.encode(master_key.salt),
        nonce_b64: general_purpose::STANDARD.encode(nonce),
        ciphertext_b64: general_purpose::STANDARD.encode(ciphertext),
    };
    let json = serde_json::to_string_pretty(&cipher)?;
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).ok();
    }
    fs::write(path, json)
        .with_context(|| format!("failed to write vault at {}", path.display()))?;
    Ok(())
}
