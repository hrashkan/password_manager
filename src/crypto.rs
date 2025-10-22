use aes_gcm::{
    Aes256Gcm, Nonce,
    aead::{Aead, KeyInit, OsRng},
};
use anyhow::{Result, anyhow};
use argon2::Argon2;
use rand::RngCore;
use zeroize::Zeroize;

pub const NONCE_SIZE: usize = 12; // AES-GCM standard nonce size
pub const SALT_SIZE: usize = 16; // Argon2 salt size

pub struct DerivedKey {
    pub key: [u8; 32],
    pub salt: [u8; SALT_SIZE],
}

impl Drop for DerivedKey {
    fn drop(&mut self) {
        self.key.zeroize();
    }
}

pub fn derive_key_from_password(
    master_password: &str,
    salt_opt: Option<[u8; SALT_SIZE]>,
) -> Result<DerivedKey> {
    let salt: [u8; SALT_SIZE] = match salt_opt {
        Some(s) => s,
        None => {
            let mut s = [0u8; SALT_SIZE];
            rand::thread_rng().fill_bytes(&mut s);
            s
        }
    };

    let argon2 = Argon2::default();
    let mut key = [0u8; 32];
    argon2
        .hash_password_into(master_password.as_bytes(), &salt, &mut key)
        .map_err(|e| anyhow!("argon2 key derivation failed: {e}"))?;

    Ok(DerivedKey { key, salt })
}

pub fn encrypt(key: &[u8; 32], plaintext: &[u8]) -> Result<(Vec<u8>, [u8; NONCE_SIZE])> {
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|_| anyhow!("invalid key length"))?;
    let mut nonce_bytes = [0u8; NONCE_SIZE];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from(nonce_bytes);
    let ciphertext = cipher
        .encrypt(&nonce, plaintext)
        .map_err(|_| anyhow!("encryption failed"))?;
    Ok((ciphertext, nonce_bytes))
}

pub fn decrypt(key: &[u8; 32], nonce: &[u8; NONCE_SIZE], ciphertext: &[u8]) -> Result<Vec<u8>> {
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|_| anyhow!("invalid key length"))?;
    let nonce = Nonce::from(*nonce);
    let plaintext = cipher
        .decrypt(&nonce, ciphertext)
        .map_err(|_| anyhow!("decryption failed: wrong key or corrupted data"))?;
    Ok(plaintext)
}
