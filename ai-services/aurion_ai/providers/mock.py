# SPDX-License-Identifier: GPL-3.0-or-later
"""
Mock LLM Provider — for testing the AI service without Ollama.

Returns canned responses for common queries. Useful for:
- Shell UI development (no GPU required)
- CI/CD testing
- Offline development
"""

import asyncio
import logging
from typing import AsyncIterator

from aurion_ai.provider import LLMProvider, LLMResponse, Message, ProviderConfig

logger = logging.getLogger(__name__)

# Canned responses for common queries
CANNED = {
    "hardware": (
        "Here's your hardware status:\n\n"
        "✅ **GPU:** Working (driver loaded)\n"
        "✅ **WiFi:** Working (firmware present)\n"
        "✅ **Audio:** Working\n"
        "✅ **Storage:** Working (NVMe detected)\n"
        "⚠️ **Bluetooth:** Degraded (firmware version outdated)\n\n"
        "Run `aurion-hwcompat --scan` for a full report."
    ),
    "error": (
        "I found 3 recent errors in your system logs:\n\n"
        "1. `iwlwifi: firmware version mismatch` — WiFi firmware needs updating\n"
        "2. `snd_hda_intel: azx_get_response timeout` — Audio driver glitch (transient)\n"
        "3. `ACPI: thermal zone tripped` — CPU ran hot briefly\n\n"
        "None of these are critical. The WiFi firmware warning can be fixed by running:\n"
        "`sudo apt install linux-firmware`"
    ),
    "system": (
        "**System Info:**\n"
        "• OS: AurionOS 0.1 (Ubuntu 24.04 base)\n"
        "• Kernel: 6.8.0-generic\n"
        "• Desktop: Aurion Shell on labwc (Wayland)\n"
        "• Memory: 4.2 / 16.0 GB used\n"
        "• Disk: 34 / 256 GB used\n"
        "• Uptime: 2h 14m"
    ),
}


class MockProvider(LLMProvider):
    """Mock provider that returns instant canned responses."""

    async def generate(self, messages: list[Message]) -> LLMResponse:
        last = messages[-1].content.lower() if messages else ""

        # Match against canned responses
        for key, response in CANNED.items():
            if key in last:
                await asyncio.sleep(0.3)  # Simulate latency
                return LLMResponse(content=response, model="mock", provider="mock")

        # Generic fallback
        await asyncio.sleep(0.2)
        return LLMResponse(
            content=(
                f"I received your question: \"{messages[-1].content}\"\n\n"
                "I'm currently running in **mock mode** (no LLM backend connected). "
                "To get real AI responses, install Ollama and run:\n"
                "```\nollama pull phi3:mini\nsudo systemctl start ollama\n```\n\n"
                "Then update `/etc/aurion/ai.toml` to set `provider = \"ollama\"`."
            ),
            model="mock",
            provider="mock",
        )

    async def generate_stream(self, messages: list[Message]) -> AsyncIterator[str]:
        response = await self.generate(messages)
        for word in response.content.split():
            yield word + " "
            await asyncio.sleep(0.02)

    async def health_check(self) -> bool:
        return True  # Always healthy

    async def list_models(self) -> list[str]:
        return ["mock-instant"]
