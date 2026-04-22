// SPDX-License-Identifier: GPL-3.0-or-later
//! Log collector — gathers system logs from multiple sources.

use std::path::PathBuf;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum LogError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Command failed: {0}")]
    Command(String),
}

/// Collect all system logs into a bundle directory.
pub async fn collect_all() -> Result<String, LogError> {
    let timestamp = chrono::Utc::now().format("%Y%m%d_%H%M%S");
    let bundle_dir = format!("/tmp/aurion-logs-{}", timestamp);
    tokio::fs::create_dir_all(&bundle_dir).await?;

    // Collect journalctl output
    collect_journalctl(&bundle_dir).await?;

    // Collect dmesg
    collect_dmesg(&bundle_dir).await?;

    // Collect hardware info
    collect_hardware_info(&bundle_dir).await?;

    Ok(bundle_dir)
}

async fn collect_journalctl(bundle_dir: &str) -> Result<(), LogError> {
    let output_path = PathBuf::from(bundle_dir).join("journalctl.log");
    let output = tokio::process::Command::new("journalctl")
        .args(["--no-pager", "-b", "-p", "warning", "--output", "short-precise"])
        .output()
        .await?;

    tokio::fs::write(&output_path, &output.stdout).await?;
    Ok(())
}

async fn collect_dmesg(bundle_dir: &str) -> Result<(), LogError> {
    let output_path = PathBuf::from(bundle_dir).join("dmesg.log");
    let output = tokio::process::Command::new("dmesg")
        .args(["--time-format=iso", "-T"])
        .output()
        .await?;

    tokio::fs::write(&output_path, &output.stdout).await?;
    Ok(())
}

async fn collect_hardware_info(bundle_dir: &str) -> Result<(), LogError> {
    let output_path = PathBuf::from(bundle_dir).join("lspci.txt");
    let output = tokio::process::Command::new("lspci")
        .args(["-vnn"])
        .output()
        .await?;

    tokio::fs::write(&output_path, &output.stdout).await?;
    Ok(())
}
