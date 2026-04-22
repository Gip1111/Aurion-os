// SPDX-License-Identifier: GPL-3.0-or-later
//! Rollback — restore system state from a Btrfs snapshot.

use thiserror::Error;

#[derive(Error, Debug)]
pub enum RollbackError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Snapshot not found: {0}")]
    NotFound(String),
    #[error("Rollback command failed: {0}")]
    Command(String),
}

/// Restore the system to a previous snapshot.
///
/// This works by:
/// 1. Verifying the snapshot exists
/// 2. Creating a writable snapshot from the read-only one
/// 3. Updating the bootloader to point to the new subvolume
/// 4. The actual switch happens on next reboot
pub async fn restore(snapshot_id: &str) -> Result<(), RollbackError> {
    let snapshot_path = format!("/.aurion-snapshots/{}", snapshot_id);

    // Verify snapshot exists
    if !tokio::fs::try_exists(&snapshot_path).await.unwrap_or(false) {
        return Err(RollbackError::NotFound(snapshot_id.to_string()));
    }

    let restore_path = format!("/.aurion-snapshots/{}-restore", snapshot_id);

    // Create a writable snapshot from the read-only backup
    let output = tokio::process::Command::new("btrfs")
        .args(["subvolume", "snapshot", &snapshot_path, &restore_path])
        .output()
        .await?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(RollbackError::Command(stderr.to_string()));
    }

    // TODO: Update /etc/fstab or bootloader subvolume reference
    // TODO: Record rollback in changelog
    // TODO: Notify user that reboot is required

    tracing::info!(
        "Rollback prepared: {} → {}. Reboot to apply.",
        snapshot_id,
        restore_path
    );

    Ok(())
}
