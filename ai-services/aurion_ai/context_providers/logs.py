# SPDX-License-Identifier: GPL-3.0-or-later
"""
Log context provider — reads system logs for AI analysis.

Provides structured log data from journalctl and dmesg
so the AI can diagnose issues with real system context.
"""

import asyncio
import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class LogEntry:
    timestamp: str
    unit: str
    priority: int  # 0=emerg, 3=err, 4=warn, 6=info
    message: str


async def get_recent_errors(lines: int = 50) -> list[LogEntry]:
    """Get recent error-level log entries from journalctl."""
    try:
        proc = await asyncio.create_subprocess_exec(
            "journalctl", "--no-pager", "-p", "err", "-n", str(lines),
            "--output", "json",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await proc.communicate()

        entries = []
        import json
        for line in stdout.decode().strip().split("\n"):
            if not line:
                continue
            try:
                data = json.loads(line)
                entries.append(LogEntry(
                    timestamp=data.get("__REALTIME_TIMESTAMP", ""),
                    unit=data.get("_SYSTEMD_UNIT", "unknown"),
                    priority=int(data.get("PRIORITY", 6)),
                    message=data.get("MESSAGE", ""),
                ))
            except (json.JSONDecodeError, KeyError):
                continue
        return entries
    except FileNotFoundError:
        logger.warning("journalctl not available")
        return []


async def get_dmesg_errors(lines: int = 30) -> list[str]:
    """Get recent dmesg errors (kernel ring buffer)."""
    try:
        proc = await asyncio.create_subprocess_exec(
            "dmesg", "--level=err,warn", "--time-format=reltime",
            "-T", "--nopager",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await proc.communicate()
        all_lines = stdout.decode().strip().split("\n")
        return all_lines[-lines:] if len(all_lines) > lines else all_lines
    except FileNotFoundError:
        logger.warning("dmesg not available")
        return []


async def build_log_context(max_chars: int = 4000) -> str:
    """Build a summarized log context string for AI consumption."""
    errors = await get_recent_errors(20)
    dmesg = await get_dmesg_errors(15)

    parts = ["=== Recent System Errors (journalctl) ==="]
    for entry in errors[:15]:
        parts.append(f"[{entry.unit}] {entry.message}")

    parts.append("\n=== Recent Kernel Messages (dmesg) ===")
    parts.extend(dmesg[:10])

    context = "\n".join(parts)
    return context[:max_chars]
