// SPDX-License-Identifier: GPL-3.0-or-later
//! Btrfs snapshot manager — create, list, and manage filesystem snapshots.

use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum SnapshotError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Btrfs not available or root is not Btrfs")]
    NotBtrfs,
    #[error("Snapshot command failed: {0}")]
    Command(String),
}

/// A Btrfs snapshot record.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Snapshot {
    pub id: String,
    pub timestamp: String,
    pub description: String,
    pub path: String,
}

const SNAPSHOT_DIR: &str = "/.aurion-snapshots";

/// Create a new Btrfs snapshot of the root subvolume.
pub async fn create(description: &str) -> Result<String, SnapshotError> {
    // Ensure snapshot directory exists
    tokio::fs::create_dir_all(SNAPSHOT_DIR).await?;

    let timestamp = chrono::Utc::now().format("%Y%m%d_%H%M%S").to_string();
    let snap_id = format!("aurion-snap-{}", timestamp);
    let snap_path = format!("{}/{}", SNAPSHOT_DIR, snap_id);

    // Create read-only Btrfs snapshot
    let output = tokio::process::Command::new("btrfs")
        .args(["subvolume", "snapshot", "-r", "/", &snap_path])
        .output()
        .await?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(SnapshotError::Command(stderr.to_string()));
    }

    // Record snapshot metadata
    let snapshot = Snapshot {
        id: snap_id.clone(),
        timestamp: timestamp.clone(),
        description: description.to_string(),
        path: snap_path,
    };

    // Append to snapshot index
    let index_path = format!("{}/index.json", SNAPSHOT_DIR);
    let mut snapshots = read_index(&index_path).await.unwrap_or_default();
    snapshots.push(snapshot);
    let json = serde_json::to_string_pretty(&snapshots).map_err(|e| {
        SnapshotError::Command(format!("JSON error: {}", e))
    })?;
    tokio::fs::write(&index_path, json).await?;

    Ok(snap_id)
}

/// List all available snapshots.
pub async fn list() -> Result<Vec<Snapshot>, SnapshotError> {
    let index_path = format!("{}/index.json", SNAPSHOT_DIR);
    read_index(&index_path).await
}

async fn read_index(path: &str) -> Result<Vec<Snapshot>, SnapshotError> {
    match tokio::fs::read_to_string(path).await {
        Ok(content) => {
            let snaps: Vec<Snapshot> = serde_json::from_str(&content)
                .map_err(|e| SnapshotError::Command(format!("Parse error: {}", e)))?;
            Ok(snaps)
        }
        Err(_) => Ok(Vec::new()),
    }
}
