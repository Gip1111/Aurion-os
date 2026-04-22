# SPDX-License-Identifier: GPL-3.0-or-later
"""Explanation prompt templates for settings and system concepts."""

EXPLAIN_SETTING = """Explain the following system setting in simple terms:

Setting: {setting_path}
Current value: {current_value}
Available options: {options}

Provide:
1. What this setting controls (1-2 sentences)
2. What changing it would affect
3. The recommended value for most users
4. Any warnings if the setting is security or stability sensitive
"""

EXPLAIN_ERROR = """The user encountered the following error:

Error message: {error_message}
Context: {context}

Explain:
1. What this error means in plain language
2. The most likely cause
3. How to fix it (step by step)
"""
