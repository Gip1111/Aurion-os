# SPDX-License-Identifier: GPL-3.0-or-later
"""Diagnosis prompt templates for hardware and system issues."""

DIAGNOSE_HARDWARE = """Analyze the following hardware device information and system logs.

Device: {device_id}
Device Info:
{device_info}

Related system logs:
{log_context}

Provide:
1. A plain-language summary of the device status
2. If there are issues, explain what's wrong and why
3. If a fix is possible, describe it clearly
4. Rate the fix safety: safe / requires-review / risky
5. If no fix is available, explain the escalation category:
   - standard driver available
   - firmware missing
   - quirk/fix possible
   - userspace workaround possible
   - VM/passthrough workaround recommended
   - likely requires reverse engineering
"""

DIAGNOSE_GENERAL = """The user is experiencing a system issue.

System context:
{system_context}

User's description: {user_question}

Provide:
1. A clear explanation of what's likely happening
2. Possible causes, ranked by likelihood
3. Recommended steps to investigate or fix
4. For any system changes, clearly state what will be modified
"""
