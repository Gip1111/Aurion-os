// SPDX-License-Identifier: GPL-3.0-or-later
//! Driver matcher — checks if appropriate drivers are loaded for devices.

use crate::scanner::Device;
use serde::{Deserialize, Serialize};

/// Driver availability status.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DriverStatus {
    /// Driver loaded and bound to device.
    Loaded { module: String },
    /// Driver available in system but not loaded.
    Available { module: String },
    /// Proprietary driver available (e.g., nvidia).
    ProprietaryAvailable { package: String },
    /// No matching driver found.
    Missing,
    /// Status could not be determined.
    Unknown,
}

/// Check driver status for a device.
pub fn check_driver(device: &Device) -> DriverStatus {
    match &device.driver {
        Some(driver) => DriverStatus::Loaded {
            module: driver.clone(),
        },
        None => {
            if device.modalias.is_empty() {
                return DriverStatus::Unknown;
            }
            // TODO: Check modules.alias for available but unloaded drivers
            // TODO: Check ubuntu-drivers list for proprietary options
            DriverStatus::Missing
        }
    }
}

/// Check if a proprietary driver is available for the device.
/// Runs `ubuntu-drivers devices` and parses output.
pub async fn check_proprietary_drivers(device: &Device) -> Option<String> {
    // TODO: Execute `ubuntu-drivers devices` and match by PCI ID
    // For GPU devices with vendor 0x10de (NVIDIA), suggest nvidia-driver-*
    if device.vendor_id.contains("10de") && device.driver.is_none() {
        return Some("nvidia-driver-550".to_string());
    }
    None
}
