// SPDX-License-Identifier: GPL-3.0-or-later
//! AurionOS Diagnostics Service
//!
//! Provides log collection, Btrfs snapshot management,
//! system changelog, and rollback capabilities.

mod log_collector;
mod snapshot;
mod changelog;
mod rollback;

use tracing::info;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let args: Vec<String> = std::env::args().collect();
    let command = args.get(1).map(|s| s.as_str()).unwrap_or("help");

    match command {
        "collect-logs" => {
            info!("Collecting system logs...");
            match log_collector::collect_all().await {
                Ok(path) => info!("Logs saved to: {}", path),
                Err(e) => tracing::error!("Log collection failed: {}", e),
            }
        }
        "snapshot" => {
            let desc = args.get(2).map(|s| s.as_str()).unwrap_or("manual snapshot");
            info!("Creating snapshot: {}", desc);
            match snapshot::create(desc).await {
                Ok(id) => info!("Snapshot created: {}", id),
                Err(e) => tracing::error!("Snapshot failed: {}", e),
            }
        }
        "snapshots" => {
            info!("Listing snapshots...");
            match snapshot::list().await {
                Ok(snaps) => {
                    for s in &snaps {
                        info!("  {} | {} | {}", s.id, s.timestamp, s.description);
                    }
                    info!("Total: {} snapshots", snaps.len());
                }
                Err(e) => tracing::error!("Failed to list snapshots: {}", e),
            }
        }
        "rollback" => {
            if let Some(id) = args.get(2) {
                info!("Rolling back to snapshot: {}", id);
                match rollback::restore(id).await {
                    Ok(()) => info!("Rollback complete. Reboot to apply."),
                    Err(e) => tracing::error!("Rollback failed: {}", e),
                }
            } else {
                tracing::error!("Usage: aurion-diag rollback <snapshot-id>");
            }
        }
        "changelog" => {
            match changelog::read_recent(20).await {
                Ok(entries) => {
                    for entry in &entries {
                        info!("  [{}] {} — {}", entry.timestamp, entry.action, entry.source);
                    }
                }
                Err(e) => tracing::error!("Failed to read changelog: {}", e),
            }
        }
        "help" | _ => {
            println!("aurion-diag — AurionOS Diagnostics Tool");
            println!();
            println!("Commands:");
            println!("  collect-logs          Collect system logs into a bundle");
            println!("  snapshot [desc]       Create a Btrfs snapshot");
            println!("  snapshots            List all snapshots");
            println!("  rollback <id>        Restore a snapshot");
            println!("  changelog            Show recent system changes");
        }
    }
}
