# SPDX-License-Identifier: GPL-3.0-or-later
"""
Hardware context provider — queries hardware compat service for AI context.

Communicates with aurion-hwcompat via D-Bus to get device status,
driver info, and firmware state for AI-assisted diagnosis.
"""

import logging

logger = logging.getLogger(__name__)


async def get_hardware_summary() -> str:
    """Get a summary of hardware status for AI context.

    In production, this queries org.aurion.HardwareCompat.ScanAll() via D-Bus.
    Returns a formatted string suitable for LLM consumption.
    """
    # TODO: Replace with actual D-Bus call to aurion-hwcompat
    # Stub implementation for development
    return """=== Hardware Status Summary ===
GPU: NVIDIA GeForce RTX 4070 — Status: Working (nvidia-driver-550 loaded)
WiFi: Intel AX211 — Status: Working (iwlwifi loaded, firmware present)
Bluetooth: Intel AX211 BT — Status: Working (btusb loaded)
Audio: Realtek ALC897 — Status: Working (snd_hda_intel loaded)
Storage: Samsung 990 Pro NVMe — Status: Working (nvme loaded)
USB: Various — Status: All recognized
"""


async def get_device_detail(device_id: str) -> str:
    """Get detailed info about a specific device for AI diagnosis.

    Args:
        device_id: Device identifier (e.g., PCI ID, USB ID, or sysfs path)
    """
    # TODO: D-Bus call to org.aurion.HardwareCompat.GetDevice(device_id)
    return f"Device {device_id}: detailed info not yet available (hwcompat service not connected)"
