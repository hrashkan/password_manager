mod crypto;
mod vault;

use anyhow::Result;
use clap::{Parser, Subcommand};
use colored::*;
use inquire::{Password, PasswordDisplayMode};
use is_terminal::IsTerminal;
use rpassword::read_password;
use std::path::PathBuf;
use vault::{Entry, default_vault_path, load_or_init, save};

#[derive(Parser)]
#[command(
    name = "rusty-vault",
    version,
    about = "Local encrypted password manager"
)]
struct Cli {
    /// Optional custom vault file path
    #[arg(long)]
    vault: Option<PathBuf>,

    /// Optional master password to avoid interactive prompt (or set env RUSTY_VAULT_MASTER_PASSWORD)
    #[arg(long)]
    master_password: Option<String>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize a new vault or open existing
    Init,
    /// Add or update an entry by name
    Add {
        name: String,
        #[arg(long)]
        username: String,
        #[arg(long)]
        password: Option<String>,
        #[arg(long)]
        url: Option<String>,
        #[arg(long)]
        notes: Option<String>,
    },
    /// Retrieve and print an entry
    Get { name: String },
    /// Delete an entry
    Delete { name: String },
    /// List entry names
    List,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let path = cli.vault.unwrap_or(default_vault_path()?);

    let master_password = match cli
        .master_password
        .or_else(|| std::env::var("RUSTY_VAULT_MASTER_PASSWORD").ok())
    {
        Some(p) => p,
        None => prompt_master_password()?,
    };
    let (mut vault, key) = load_or_init(&master_password, &path)?;

    match cli.command {
        Commands::Init => {
            save(&key, &vault, &path)?;
            println!(
                "{} {}",
                "✔".green(),
                format!("Vault ready at {}", path.display()).green()
            );
        }
        Commands::Add {
            name,
            username,
            password,
            url,
            notes,
        } => {
            let pwd = match password {
                Some(p) => p,
                None => prompt_secret("Password: ")?,
            };
            vault.entries.insert(
                name,
                Entry {
                    username,
                    password: pwd,
                    url,
                    notes,
                },
            );
            save(&key, &vault, &path)?;
            println!("{}", "Saved.".green());
        }
        Commands::Get { name } => {
            if let Some(e) = vault.entries.get(&name) {
                println!("{} {}", "username:".cyan(), e.username);
                println!("{} {}", "password:".cyan(), e.password);
                if let Some(u) = &e.url {
                    println!("{} {}", "url:".cyan(), u);
                }
                if let Some(n) = &e.notes {
                    println!("{} {}", "notes:".cyan(), n);
                }
            } else {
                eprintln!("{} {}", "✖".red(), "Not found".red());
            }
        }
        Commands::Delete { name } => {
            if vault.entries.remove(&name).is_some() {
                save(&key, &vault, &path)?;
                println!("{}", "Deleted.".green());
            } else {
                eprintln!("{} {}", "✖".red(), "Not found".red());
            }
        }
        Commands::List => {
            for k in vault.entries.keys() {
                println!("{}", k.cyan());
            }
        }
    }

    Ok(())
}

fn prompt_master_password() -> Result<String> {
    if std::io::stdin().is_terminal() {
        let pwd = Password::new("Master password")
            .with_display_mode(PasswordDisplayMode::Masked)
            .without_confirmation()
            .prompt()?;
        Ok(pwd)
    } else {
        eprintln!("Enter master password:");
        let pwd = read_password()?;
        Ok(pwd.trim_end_matches(['\r', '\n']).to_string())
    }
}

fn prompt_secret(prompt: &str) -> Result<String> {
    if std::io::stdin().is_terminal() {
        let pwd = Password::new(prompt)
            .with_display_mode(PasswordDisplayMode::Masked)
            .without_confirmation()
            .prompt()?;
        Ok(pwd)
    } else {
        eprint!("{}", prompt);
        let pwd = read_password()?;
        Ok(pwd.trim_end_matches(['\r', '\n']).to_string())
    }
}
