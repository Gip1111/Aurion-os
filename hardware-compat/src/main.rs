// SPDX-License-Identifier: GPL-3.0-or-later
//! AurionOS Hardware Compatibility Scanner — CLI entry point (MVP)

mod scanner;
mod classifier;
mod driver_matcher;
mod firmware_checker;

use clap::Parser;
use serde::Serialize;
use tracing::info;

#[derive(Parser)]
#[command(name = "aurion-hwcompat", about = "AurionOS Hardware Compatibility Scanner")]
struct Cli {
    /// Run a full hardware scan
    #[arg(long)]
    scan: bool,

    /// Output as JSON (for piping to AI service)
    #[arg(long)]
    json: bool,

    /// Show only devices with issues
    #[arg(long)]
    issues_only: bool,
}

#[derive(Serialize)]
struct DeviceReport {
    name: String,
    bus: String,
    vendor_id: String,
    device_id: String,
    class: String,
    status: String,
    driver: String,
    firmware: String,
}

#[derive(Serialize)]
struct ScanReport {
    total_devices: usize,
    working: usize,
    degraded: usize,
    not_working: usize,
    unknown: usize,
    devices: Vec<DeviceReport>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    let cli = Cli::parse();

    if !cli.scan {
        println!("aurion-hwcompat — AurionOS Hardware Compatibility Scanner");
        println!();
        println!("Usage:");
        println!("  aurion-hwcompat --scan           Scan all hardware");
        println!("  aurion-hwcompat --scan --json     Output as JSON");
        println!("  aurion-hwcompat --scan --issues-only  Show only problematic devices");
        return;
    }

    info!("Starting hardware scan...");
    let devices = scanner::scan_all_devices().await;
    info!("Found {} raw devices", devices.len());

    let mut report = ScanReport {
        total_devices: 0,
        working: 0, degraded: 0, not_working: 0, unknown: 0,
        devices: Vec::new(),
    };

    for device in &devices {
        // Skip bridge devices and empty entries for cleaner output
        let class = classifier::classify(device);
        if class == classifier::DeviceClass::Bridge { continue; }

        let status = classifier::determine_status(device);
        let driver_status = driver_matcher::check_driver(device);
        let fw_status = firmware_checker::check_firmware(device);

        let status_str = match status {
            classifier::DeviceStatus::Working => { report.working += 1; "working" }
            classifier::DeviceStatus::Degraded => { report.degraded += 1; "degraded" }
            classifier::DeviceStatus::NotWorking => { report.not_working += 1; "not_working" }
            classifier::DeviceStatus::Unknown => { report.unknown += 1; "unknown" }
        };

        if cli.issues_only && status == classifier::DeviceStatus::Working { continue; }

        report.devices.push(DeviceReport {
            name: device.name.clone(),
            bus: device.bus.clone(),
            vendor_id: device.vendor_id.clone(),
            device_id: device.device_id.clone(),
            class: format!("{:?}", class),
            status: status_str.to_string(),
            driver: match &driver_status {
                driver_matcher::DriverStatus::Loaded { module } => format!("loaded: {}", module),
                driver_matcher::DriverStatus::Missing => "missing".to_string(),
                _ => "unknown".to_string(),
            },
            firmware: format!("{:?}", fw_status),
        });

        report.total_devices += 1;
    }

    if cli.json {
        println!("{}", serde_json::to_string_pretty(&report).unwrap());
    } else {
        println!("╔══════════════════════════════════════════════════════╗");
        println!("║         AurionOS Hardware Compatibility Report       ║");
        println!("╠══════════════════════════════════════════════════════╣");
        println!("║ Total: {} │ ✅ {} │ ⚠️  {} │ ❌ {} │ ❓ {}",
            report.total_devices, report.working, report.degraded,
            report.not_working, report.unknown);
        println!("╠══════════════════════════════════════════════════════╣");

        for d in &report.devices {
            let icon = match d.status.as_str() {
                "working" => "✅",
                "degraded" => "⚠️ ",
                "not_working" => "❌",
                _ => "❓",
            };
            println!("║ {} {:10} {:28} {}", icon, d.class, d.name, d.driver);
        }
        println!("╚══════════════════════════════════════════════════════╝");
    }
}
