# SPDX-License-Identifier: GPL-3.0-or-later
"""
AurionOS AI Service — Main entry point (MVP).
"""

import asyncio
import logging
from pathlib import Path

from aurion_ai.provider import ProviderConfig, ProviderType, Message, create_provider
from aurion_ai.dbus_service import run_dbus_service

logger = logging.getLogger(__name__)

CONFIG_PATHS = [
    Path("/etc/aurion/ai.toml"),
    Path.home() / ".config" / "aurion" / "ai.toml",
]

SYSTEM_PROMPT = """You are Aurion AI, the built-in assistant for AurionOS.
You help users with hardware issues, system diagnostics, and settings.
Be concise. Never execute destructive commands without user approval.
If proposing system changes, explain what will change and why."""


def load_config() -> dict:
    """Load config from TOML files."""
    defaults = {
        "provider": "mock",  # mock by default for MVP safety
        "model": "phi3:mini",
        "base_url": "http://localhost:11434",
        "temperature": 0.3,
        "max_tokens": 2048,
    }
    try:
        import tomllib
        for path in CONFIG_PATHS:
            if path.exists():
                with open(path, "rb") as f:
                    data = tomllib.load(f)
                    defaults.update(data.get("ai", {}))
    except ImportError:
        pass
    return defaults


def make_provider(config: dict):
    """Create the LLM provider from config."""
    ptype = config["provider"]

    if ptype == "mock":
        from aurion_ai.providers.mock import MockProvider
        return MockProvider(ProviderConfig(
            provider_type=ProviderType.OLLAMA,  # placeholder
            model="mock",
        ))

    return create_provider(ProviderConfig(
        provider_type=ProviderType(ptype),
        model=config["model"],
        base_url=config["base_url"],
        temperature=config["temperature"],
        max_tokens=config["max_tokens"],
    ))


class AurionAIService:
    """Main AI service."""

    def __init__(self, config: dict):
        self.provider = make_provider(config)
        logger.info("Provider: %s (model: %s)", config["provider"], config.get("model", "n/a"))

    async def ask(self, question: str, context: str = "") -> str:
        messages = [Message(role="system", content=SYSTEM_PROMPT)]
        if context:
            messages.append(Message(role="system", content=f"Context:\n{context}"))
        messages.append(Message(role="user", content=question))
        try:
            resp = await self.provider.generate(messages)
            return resp.content
        except Exception as e:
            logger.error("Generation failed: %s", e)
            return f"Error: {e}. Is the AI backend running?"

    async def diagnose_device(self, device_id: str) -> str:
        return await self.ask(f"Diagnose hardware device: {device_id}")

    async def health(self) -> bool:
        return await self.provider.health_check()


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [aurion-ai] %(levelname)s %(message)s")
    config = load_config()
    logger.info("AurionOS AI Service v0.1.0 starting (provider=%s)", config["provider"])

    service = AurionAIService(config)
    asyncio.run(run_dbus_service(service))


if __name__ == "__main__":
    main()
