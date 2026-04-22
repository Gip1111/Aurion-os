// SPDX-License-Identifier: GPL-3.0-or-later
//! Hardware scanner — enumerates devices from sysfs.
//!
//! Reads /sys/bus/{pci,usb}/devices/ to discover hardware,
//! extracts modalias strings, vendor/device IDs, and driver bindings.

use serde::{Deserialize, Serialize};

/// A discovered hardware device.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Device {
    /// Sysfs path (e.g., "/sys/bus/pci/devices/0000:01:00.0")
    pub sysfs_path: String,
    /// Human-readable name (from device database or modalias)
    pub name: String,
    /// Bus type (pci, usb, platform, etc.)
    pub bus: String,
    /// Vendor ID (hex string)
    pub vendor_id: String,
    /// Device ID (hex string)
    pub device_id: String,
    /// Modalias string from sysfs
    pub modalias: String,
    /// Currently bound driver module name, if any
    pub driver: Option<String>,
    /// Subsystem (network, graphics, sound, etc.)
    pub subsystem: Option<String>,
}

/// Scan all PCI and USB devices from sysfs.
pub async fn scan_all_devices() -> Vec<Device> {
    let mut devices = Vec::new();

    // Scan PCI bus
    devices.extend(scan_bus("pci").await);

    // Scan USB bus
    devices.extend(scan_bus("usb").await);

    devices
}

/// Scan a specific bus type from /sys/bus/{bus}/devices/
async fn scan_bus(bus: &str) -> Vec<Device> {
    let bus_path = format!("/sys/bus/{}/devices", bus);
    let mut devices = Vec::new();

    let entries = match tokio::fs::read_dir(&bus_path).await {
        Ok(entries) => entries,
        Err(e) => {
            tracing::debug!("Cannot read {}: {} (expected on non-Linux)", bus_path, e);
            return devices;
        }
    };

    let mut entries = entries;
    while let Ok(Some(entry)) = entries.next_entry().await {
        let path = entry.path();
        let path_str = path.to_string_lossy().to_string();

        let modalias = read_sysfs_attr(&path_str, "modalias").await.unwrap_or_default();
        let vendor_id = read_sysfs_attr(&path_str, "vendor").await.unwrap_or_default();
        let device_id = read_sysfs_attr(&path_str, "device").await.unwrap_or_default();
        let driver = read_driver_link(&path_str).await;
        let subsystem = read_sysfs_attr(&path_str, "class").await.ok();

        let name = format!("{}:{}", vendor_id.trim(), device_id.trim());

        devices.push(Device {
            sysfs_path: path_str,
            name,
            bus: bus.to_string(),
            vendor_id: vendor_id.trim().to_string(),
            device_id: device_id.trim().to_string(),
            modalias: modalias.trim().to_string(),
            driver,
            subsystem,
        });
    }

    devices
}

/// Read a sysfs attribute file.
async fn read_sysfs_attr(device_path: &str, attr: &str) -> Result<String, std::io::Error> {
    let attr_path = format!("{}/{}", device_path, attr);
    tokio::fs::read_to_string(&attr_path).await
}

/// Read the driver symlink to find the bound driver module name.
async fn read_driver_link(device_path: &str) -> Option<String> {
    let driver_path = format!("{}/driver", device_path);
    match tokio::fs::read_link(&driver_path).await {
        Ok(target) => target.file_name().map(|n| n.to_string_lossy().to_string()),
        Err(_) => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_device_serialization() {
        let device = Device {
            sysfs_path: "/sys/bus/pci/devices/0000:01:00.0".to_string(),
            name: "0x10de:0x2786".to_string(),
            bus: "pci".to_string(),
            vendor_id: "0x10de".to_string(),
            device_id: "0x2786".to_string(),
            modalias: "pci:v000010DEd00002786sv...".to_string(),
            driver: Some("nvidia".to_string()),
            subsystem: Some("0x030000".to_string()),
        };

        let json = serde_json::to_string(&device).unwrap();
        assert!(json.contains("nvidia"));

        let parsed: Device = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed.vendor_id, "0x10de");
    }
}
