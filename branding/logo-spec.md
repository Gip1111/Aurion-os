# AurionOS — Logo Specification

> Working name. Logo will need revision if name changes.

## Concept Direction

### Symbol: "Aurion Star"
A stylized, geometric starburst or aurora-inspired mark:
- Radiating light from a central point
- 6 or 8 rays with varying lengths (asymmetric for dynamism)
- Subtle gradient: primary accent (#6366F1) → violet (#8B5CF6)
- Clean geometry, not illustrative — works at 16px favicon and 512px splash

### Wordmark
- Font: Outfit (600 weight) or custom lettering based on Outfit
- "aurion" in lowercase — modern, approachable
- "OS" in small caps or lighter weight, separated by a thin space
- Color: fg-primary (#F1F5F9) on dark backgrounds

### Lockup
```
[Symbol] aurion os
```
- Symbol left, wordmark right (horizontal lockup)
- Symbol above, wordmark below (vertical lockup — for boot splash)
- Minimum clear space: 1x symbol width on all sides

## Usage Contexts

| Context | Format | Size |
|---------|--------|------|
| Boot splash (Plymouth) | SVG → PNG, vertical lockup | 256px symbol |
| Login screen | Horizontal lockup | 48px symbol |
| Top bar | Symbol only | 20px |
| ISO/installer | Horizontal lockup | 64px symbol |
| Favicon | Symbol only | 16px, 32px |
| Documentation | Horizontal lockup | 32px symbol |

## Color Variants

| Variant | Symbol Color | Wordmark Color | Background |
|---------|-------------|----------------|------------|
| Dark (primary) | Aurora gradient | #F1F5F9 | #0A0E1A |
| Light | #6366F1 solid | #0F172A | #F8FAFC |
| Monochrome | #F1F5F9 | #F1F5F9 | any dark |

## Files to Generate

- [ ] `logo-symbol.svg` — vector symbol mark
- [ ] `logo-horizontal.svg` — horizontal lockup
- [ ] `logo-vertical.svg` — vertical lockup (boot splash)
- [ ] `logo-symbol-16.png` through `logo-symbol-512.png` — raster exports
- [ ] `logo-monochrome.svg` — single-color variant
