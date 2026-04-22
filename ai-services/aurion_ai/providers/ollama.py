# SPDX-License-Identifier: GPL-3.0-or-later
"""
Ollama LLM Provider — Default local-first backend.

Communicates with Ollama via its HTTP API (localhost:11434).
No data leaves the machine. No cloud dependency.
"""

import logging
from typing import AsyncIterator

import httpx

from aurion_ai.provider import LLMProvider, LLMResponse, Message, ProviderConfig

logger = logging.getLogger(__name__)


class OllamaProvider(LLMProvider):
    """Ollama provider using the HTTP API."""

    def __init__(self, config: ProviderConfig):
        super().__init__(config)
        self._client = httpx.AsyncClient(
            base_url=config.base_url,
            timeout=120.0,
        )

    async def generate(self, messages: list[Message]) -> LLMResponse:
        """Generate a complete response."""
        payload = {
            "model": self.config.model,
            "messages": [{"role": m.role, "content": m.content} for m in messages],
            "stream": False,
            "options": {
                "temperature": self.config.temperature,
                "num_predict": self.config.max_tokens,
            },
        }

        try:
            response = await self._client.post("/api/chat", json=payload)
            response.raise_for_status()
            data = response.json()

            return LLMResponse(
                content=data["message"]["content"],
                model=data.get("model", self.config.model),
                provider="ollama",
                tokens_used=data.get("eval_count", 0),
            )
        except httpx.HTTPError as e:
            logger.error("Ollama request failed: %s", e)
            raise

    async def generate_stream(self, messages: list[Message]) -> AsyncIterator[str]:
        """Stream response tokens."""
        payload = {
            "model": self.config.model,
            "messages": [{"role": m.role, "content": m.content} for m in messages],
            "stream": True,
            "options": {
                "temperature": self.config.temperature,
                "num_predict": self.config.max_tokens,
            },
        }

        try:
            async with self._client.stream("POST", "/api/chat", json=payload) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line:
                        import json
                        chunk = json.loads(line)
                        if "message" in chunk and "content" in chunk["message"]:
                            yield chunk["message"]["content"]
        except httpx.HTTPError as e:
            logger.error("Ollama stream failed: %s", e)
            raise

    async def health_check(self) -> bool:
        """Check if Ollama is running and responsive."""
        try:
            response = await self._client.get("/api/tags")
            return response.status_code == 200
        except httpx.HTTPError:
            return False

    async def list_models(self) -> list[str]:
        """List models available in Ollama."""
        try:
            response = await self._client.get("/api/tags")
            response.raise_for_status()
            data = response.json()
            return [m["name"] for m in data.get("models", [])]
        except httpx.HTTPError as e:
            logger.error("Failed to list Ollama models: %s", e)
            return []
