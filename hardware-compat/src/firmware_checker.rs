// SPDX-License-Identifier: GPL-3.0-or-later
//! Firmware checker — verifies firmware availability for devices.

use crate::scanner::Device;
use serde::{Deserialize, Serialize};

/// Firmware status for a device.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum FirmwareStatus {
    /// Firmware loaded successfully.
    Loaded,
    /// Firmware file present in /lib/firmware but not confirmed loaded.
    Available,
    /// Required firmware file missing from /lib/firmware.
    Missing { expected_path: String },
    /// Device doesn't require firmware.
    NotRequired,
    /// Firmware update available via fwupd.
    UpdateAvailable { current: String, available: String },
    /// Could not determine firmware status.
    Unknown,
}

/// Check firmware status for a device.
pub fn check_firmware(device: &Device) -> FirmwareStatus {
    // Devices without drivers generally can't report firmware needs
    if device.driver.is_none() {
        return FirmwareStatus::Unknown;
    }

    // TODO: Parse dmesg for firmware load messages related to this device
    // Pattern: "firmware: requesting <path>" or "Direct firmware load for <path> failed"
    //
    // TODO: Check /lib/firmware/ for expected firmware files based on driver
    // Known mappings:
    //   iwlwifi → /lib/firmware/iwlwifi-*.ucode
    //   amdgpu  → /lib/firmware/amdgpu/*.bin
    //   i915    → /lib/firmware/i915/*.bin

    // Default: assume loaded if driver is bound
    FirmwareStatus::Loaded
}

/// Check fwupd for available firmware updates.
pub async fn check_fwupd_updates(_device: &Device) -> Option<FirmwareStatus> {
    // TODO: Query fwupd via D-Bus (org.freedesktop.fwupd)
    // or parse `fwupdmgr get-updates` output
    None
}
