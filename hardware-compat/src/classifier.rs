// SPDX-License-Identifier: GPL-3.0-or-later
//! Device classifier — categorizes devices by type and function.

use crate::scanner::Device;
use serde::{Deserialize, Serialize};

/// High-level device category.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DeviceClass {
    GPU,
    Network,
    Audio,
    Storage,
    Input,
    Bluetooth,
    USB,
    Bridge,
    Other,
}

/// Overall device status.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DeviceStatus {
    Working,
    Degraded,
    NotWorking,
    Unknown,
}

/// Classify a device based on its PCI class code or USB class.
pub fn classify(device: &Device) -> DeviceClass {
    // PCI class codes (first 2 bytes of class field):
    // 0x03 = Display, 0x02 = Network, 0x04 = Multimedia,
    // 0x01 = Storage, 0x06 = Bridge, 0x0c = Serial bus
    if let Some(ref subsystem) = device.subsystem {
        let class_str = subsystem.trim().trim_start_matches("0x");
        if class_str.len() >= 2 {
            let class_byte = u8::from_str_radix(&class_str[..2], 16).unwrap_or(0);
            return match class_byte {
                0x03 => DeviceClass::GPU,
                0x02 => DeviceClass::Network,
                0x04 => DeviceClass::Audio,
                0x01 => DeviceClass::Storage,
                0x09 => DeviceClass::Input,
                0x06 => DeviceClass::Bridge,
                0x0c => DeviceClass::USB,
                _ => DeviceClass::Other,
            };
        }
    }

    // Fallback: check driver name for hints
    if let Some(ref driver) = device.driver {
        let d = driver.to_lowercase();
        if d.contains("nvidia") || d.contains("amdgpu") || d.contains("i915") {
            return DeviceClass::GPU;
        }
        if d.contains("iwl") || d.contains("ath") || d.contains("rtl") || d.contains("e1000") {
            return DeviceClass::Network;
        }
        if d.contains("snd") || d.contains("hda") {
            return DeviceClass::Audio;
        }
        if d.contains("nvme") || d.contains("ahci") {
            return DeviceClass::Storage;
        }
        if d.contains("btusb") || d.contains("bluetooth") {
            return DeviceClass::Bluetooth;
        }
    }

    DeviceClass::Other
}

/// Determine the operating status of a device.
pub fn determine_status(device: &Device) -> DeviceStatus {
    if device.driver.is_some() {
        DeviceStatus::Working
    } else if device.modalias.is_empty() {
        DeviceStatus::Unknown
    } else {
        // Has a modalias but no driver loaded — likely not working
        DeviceStatus::NotWorking
    }
}
