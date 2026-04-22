# AurionOS — Typography

## Font Stack

### Primary: Inter
- **Source:** Google Fonts / bundled
- **Usage:** All UI text — labels, body, controls, menus
- **Why:** Optimized for screens, excellent legibility at small sizes, modern and neutral

### Monospace: JetBrains Mono
- **Source:** JetBrains / bundled
- **Usage:** Terminal, code, log output, AI responses with code blocks
- **Why:** Ligatures, clear distinction between similar characters, widely loved

### Display (optional): Outfit
- **Source:** Google Fonts / bundled
- **Usage:** Login screen clock, large headings, branding text
- **Why:** Geometric, modern, premium feel at large sizes

## Type Scale

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `display-xl` | 48px | 700 | 1.1 | Login clock, hero text |
| `display-lg` | 32px | 600 | 1.2 | Section headings |
| `heading-lg` | 24px | 600 | 1.3 | Panel titles |
| `heading-md` | 18px | 600 | 1.3 | Card titles, dialog headings |
| `heading-sm` | 15px | 600 | 1.4 | Subsection headings |
| `body-lg` | 15px | 400 | 1.5 | Primary body text |
| `body-md` | 13px | 400 | 1.5 | Secondary body text, descriptions |
| `body-sm` | 11px | 400 | 1.4 | Captions, timestamps |
| `label-md` | 13px | 500 | 1.2 | Button labels, menu items |
| `label-sm` | 11px | 500 | 1.2 | Badges, tags, status labels |
| `mono-md` | 13px | 400 | 1.5 | Code, terminal output |
| `mono-sm` | 11px | 400 | 1.4 | Inline code, small log text |

## Principles

1. **Readability over style.** Never sacrifice legibility for aesthetics.
2. **Consistent scale.** Use only the defined tokens. No arbitrary sizes.
3. **Weight for hierarchy.** Use weight (400/500/600/700) to create hierarchy, not just size.
4. **Monospace for data.** Any system output, log, path, or code uses the monospace stack.
