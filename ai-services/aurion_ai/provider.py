# SPDX-License-Identifier: GPL-3.0-or-later
"""
LLM Provider abstraction layer.

All AI interactions go through the LLMProvider interface.
Provider selection is config-driven (/etc/aurion/ai.toml).
Cloud providers are disabled by default and require explicit user opt-in.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
from typing import AsyncIterator


class ProviderType(Enum):
    """Supported provider backends."""
    OLLAMA = "ollama"
    LLAMA_CPP = "llama_cpp"  # future
    OPENAI_COMPAT = "openai_compat"  # future, opt-in only


@dataclass
class Message:
    """A single message in a conversation."""
    role: str  # "system", "user", "assistant"
    content: str


@dataclass
class LLMResponse:
    """Response from an LLM provider."""
    content: str
    model: str
    provider: str
    tokens_used: int = 0
    finish_reason: str = "stop"


@dataclass
class ProviderConfig:
    """Configuration for an LLM provider."""
    provider_type: ProviderType
    model: str = "phi3:mini"
    base_url: str = "http://localhost:11434"
    api_key: str = ""  # only for cloud, never stored in plain text
    enabled: bool = True
    is_cloud: bool = False
    max_tokens: int = 2048
    temperature: float = 0.3
    extra: dict = field(default_factory=dict)


class LLMProvider(ABC):
    """Abstract interface for LLM providers.

    All providers must implement this interface.
    The service layer never calls provider-specific APIs directly.
    """

    def __init__(self, config: ProviderConfig):
        self.config = config

    @abstractmethod
    async def generate(self, messages: list[Message]) -> LLMResponse:
        """Generate a response from a list of messages."""
        ...

    @abstractmethod
    async def generate_stream(self, messages: list[Message]) -> AsyncIterator[str]:
        """Stream a response token by token."""
        ...

    @abstractmethod
    async def health_check(self) -> bool:
        """Check if the provider is available and responsive."""
        ...

    @abstractmethod
    async def list_models(self) -> list[str]:
        """List available models on this provider."""
        ...

    @property
    def name(self) -> str:
        return self.config.provider_type.value

    @property
    def is_cloud(self) -> bool:
        return self.config.is_cloud


def create_provider(config: ProviderConfig) -> LLMProvider:
    """Factory function to create a provider from config."""
    match config.provider_type:
        case ProviderType.OLLAMA:
            from aurion_ai.providers.ollama import OllamaProvider
            return OllamaProvider(config)
        case _:
            raise ValueError(f"Unsupported provider type: {config.provider_type}")
