# AurionOS — Color System

## Philosophy
Dark-first. Depth through light. Glass and bloom, not flat surfaces.
Colors evoke aurora borealis: cool blues, warm accents, luminous highlights.

## Core Palette

### Backgrounds (Dark Theme — Primary)
| Token | Hex | Usage |
|-------|-----|-------|
| `bg-deep` | `#0A0E1A` | Deepest background (desktop, behind everything) |
| `bg-base` | `#111827` | Primary surface (panels, sidebars) |
| `bg-elevated` | `#1E293B` | Elevated surfaces (cards, dropdowns) |
| `bg-overlay` | `rgba(17, 24, 39, 0.85)` | Glass overlays (launcher, AI sidebar) |

### Foregrounds
| Token | Hex | Usage |
|-------|-----|-------|
| `fg-primary` | `#F1F5F9` | Primary text |
| `fg-secondary` | `#94A3B8` | Secondary text, labels |
| `fg-muted` | `#64748B` | Disabled, placeholder text |
| `fg-inverse` | `#0F172A` | Text on light/accent backgrounds |

### Accent Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `accent-primary` | `#6366F1` | Primary actions, focus rings, active states |
| `accent-hover` | `#818CF8` | Hover state for primary accent |
| `accent-glow` | `rgba(99, 102, 241, 0.25)` | Glow/bloom behind accent elements |
| `accent-warm` | `#F59E0B` | Warnings, attention, secondary accent |
| `accent-success` | `#10B981` | Success, working status, confirmations |
| `accent-danger` | `#EF4444` | Errors, destructive actions |

### Glass / Surface Effects
| Token | Value | Usage |
|-------|-------|-------|
| `glass-bg` | `rgba(17, 24, 39, 0.65)` | Glass surface background |
| `glass-border` | `rgba(148, 163, 184, 0.12)` | Subtle border on glass surfaces |
| `glass-blur` | `24px` | Backdrop blur radius |
| `surface-shadow` | `0 8px 32px rgba(0, 0, 0, 0.4)` | Elevation shadow |

### Backgrounds (Light Theme — Secondary)
| Token | Hex | Usage |
|-------|-----|-------|
| `light-bg-base` | `#F8FAFC` | Primary surface |
| `light-bg-elevated` | `#FFFFFF` | Elevated surfaces |
| `light-fg-primary` | `#0F172A` | Primary text |
| `light-fg-secondary` | `#475569` | Secondary text |

## Semantic Tokens

| Token | Dark Value | Light Value | Usage |
|-------|-----------|-------------|-------|
| `status-ok` | `#10B981` | `#059669` | Device working, action succeeded |
| `status-warn` | `#F59E0B` | `#D97706` | Degraded, attention needed |
| `status-error` | `#EF4444` | `#DC2626` | Not working, error |
| `status-unknown` | `#64748B` | `#94A3B8` | Unknown state |

## Gradients

```
aurora-gradient: linear-gradient(135deg, #6366F1 0%, #8B5CF6 50%, #EC4899 100%)
  — Used sparingly: boot splash, login background accent, logo glow

surface-gradient: linear-gradient(180deg, rgba(30, 41, 59, 0.8) 0%, rgba(17, 24, 39, 0.95) 100%)
  — Used on panel backgrounds for depth
```
