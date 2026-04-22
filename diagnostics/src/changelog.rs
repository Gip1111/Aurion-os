// SPDX-License-Identifier: GPL-3.0-or-later
//! System changelog — records all modifications made to the system.

use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ChangelogError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Parse error: {0}")]
    Parse(String),
}

/// A single changelog entry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChangeEntry {
    pub timestamp: String,
    pub action: String,
    pub source: String,       // "user", "ai", "system", "update"
    pub details: String,
    pub reversible: bool,
    pub snapshot_id: Option<String>,
}

const CHANGELOG_PATH: &str = "/var/log/aurion/changelog.json";

/// Record a new change to the system changelog.
pub async fn record(entry: ChangeEntry) -> Result<(), ChangelogError> {
    // Ensure directory exists
    if let Some(parent) = std::path::Path::new(CHANGELOG_PATH).parent() {
        tokio::fs::create_dir_all(parent).await?;
    }

    let mut entries = read_all().await.unwrap_or_default();
    entries.push(entry);

    let json = serde_json::to_string_pretty(&entries)
        .map_err(|e| ChangelogError::Parse(e.to_string()))?;
    tokio::fs::write(CHANGELOG_PATH, json).await?;

    Ok(())
}

/// Read the most recent N changelog entries.
pub async fn read_recent(count: usize) -> Result<Vec<ChangeEntry>, ChangelogError> {
    let entries = read_all().await?;
    let start = entries.len().saturating_sub(count);
    Ok(entries[start..].to_vec())
}

/// Read all changelog entries.
async fn read_all() -> Result<Vec<ChangeEntry>, ChangelogError> {
    match tokio::fs::read_to_string(CHANGELOG_PATH).await {
        Ok(content) => {
            let entries: Vec<ChangeEntry> = serde_json::from_str(&content)
                .map_err(|e| ChangelogError::Parse(e.to_string()))?;
            Ok(entries)
        }
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(Vec::new()),
        Err(e) => Err(ChangelogError::Io(e)),
    }
}
