# SPDX-License-Identifier: GPL-3.0-or-later
"""
D-Bus service implementation for Aurion AI.

Registers on session bus as org.aurion.AI with methods:
  - Ask(question: str, context: str) -> str
  - Health() -> bool

Uses dbus_next for async D-Bus integration.
Falls back to a simple socket-based IPC if dbus_next is not available.
"""

import asyncio
import logging
import signal

logger = logging.getLogger(__name__)

# Try to import dbus_next; if not available, use fallback
try:
    from dbus_next.aio import MessageBus
    from dbus_next.service import ServiceInterface, method
    HAS_DBUS = True
except ImportError:
    HAS_DBUS = False
    logger.warning("dbus_next not installed — using stdout fallback mode")


if HAS_DBUS:
    class AurionAIDBusInterface(ServiceInterface):
        """D-Bus interface: org.aurion.AI"""

        def __init__(self, ai_service):
            super().__init__("org.aurion.AI")
            self._ai = ai_service

        @method()
        async def Ask(self, question: 's', context: 's') -> 's':
            """Ask the AI a question with optional context."""
            logger.info("D-Bus Ask: %s", question[:80])
            response = await self._ai.ask(question, context)
            return response

        @method()
        async def Health(self) -> 'b':
            """Check if the AI backend is healthy."""
            return await self._ai.health()

        @method()
        async def DiagnoseDevice(self, device_id: 's') -> 's':
            """Request AI diagnosis for a hardware device."""
            return await self._ai.diagnose_device(device_id)


async def run_dbus_service(ai_service):
    """Start the D-Bus service loop."""
    if not HAS_DBUS:
        logger.info("Running in stdout-only mode (no D-Bus)")
        # Simple REPL for testing
        while True:
            try:
                line = await asyncio.get_event_loop().run_in_executor(
                    None, input, "aurion-ai> "
                )
                if line.strip():
                    response = await ai_service.ask(line.strip())
                    print(f"\n{response}\n")
            except (EOFError, KeyboardInterrupt):
                break
        return

    bus = await MessageBus().connect()
    interface = AurionAIDBusInterface(ai_service)
    bus.export("/org/aurion/AI", interface)

    await bus.request_name("org.aurion.AI")
    logger.info("D-Bus service registered: org.aurion.AI")
    logger.info("Methods: Ask(s,s)->s, Health()->b, DiagnoseDevice(s)->s")

    # Wait forever (or until signal)
    stop = asyncio.Event()
    loop = asyncio.get_event_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, stop.set)

    await stop.wait()
    logger.info("Shutting down D-Bus service")
