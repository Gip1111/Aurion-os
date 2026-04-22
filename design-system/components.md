# AurionOS — Component Design Specs

## Shell Components

### Top Bar
- **Height:** 36px
- **Background:** `glass-bg` with `glass-blur`
- **Border bottom:** `glass-border`, 1px
- **Layout:** `[Logo 20px] [spacer] [clock] [spacer] [tray icons] [quick-settings trigger]`
- **Logo:** Aurion symbol, 20px, `fg-primary`
- **Clock:** `body-md` weight 500, centered
- **Tray icons:** 18px, `fg-secondary`, 8px gap
- **Quick settings trigger:** combined Wi-Fi + Volume + Battery indicator

### Dock
- **Height:** 56px (icon 40px + 8px padding top/bottom)
- **Position:** bottom center, floating (16px margin from bottom edge)
- **Background:** `glass-bg` with `glass-blur`, `radius-xl` (24px)
- **Border:** `glass-border`, 1px
- **Icons:** 40px, with tooltip on hover
- **Running indicator:** 4px dot, `accent-primary`, centered below icon
- **Separator:** 1px vertical line, `glass-border`, between pinned and running apps
- **Animation:** icon scales to 1.1x on hover (120ms, spring easing)

### Launcher
- **Trigger:** Super key press
- **Background:** full-screen `bg-overlay` with blur
- **Search bar:** centered, 600px wide, `bg-elevated`, `radius-lg`
- **Search input:** `heading-md`, placeholder "Search apps, files, actions..."
- **Results:** max 8 items, below search bar, 600px wide
- **Result item:** 48px height, icon (32px) + name (`body-lg`) + description (`body-sm`, `fg-secondary`)
- **Selection:** keyboard arrows, `bg-elevated` highlight with `accent-glow` left border
- **Categories:** tabs below search: All | Apps | Files | Settings | AI
- **Dismiss:** Escape key or click outside

### AI Sidebar
- **Trigger:** Super+A
- **Position:** right edge, full height
- **Width:** 420px
- **Background:** `bg-base` with `glass-border` left edge
- **Animation:** slide in from right, 350ms, out easing
- **Header:** "Aurion AI" label + close button + status indicator (model loaded/offline)
- **Chat area:** scrollable, messages with clear user/AI distinction
- **User message:** right-aligned, `accent-primary` bg, `fg-inverse` text, `radius-lg`
- **AI message:** left-aligned, `bg-elevated` bg, `fg-primary` text, `radius-lg`
- **Input:** bottom-pinned, 1-line expanding textarea, send button
- **Context chips:** above input — "System Logs", "Hardware", "Current Error"
- **Quick actions:** "Why is X not working?", "Check hardware", "Explain last error"

## Common Patterns

### Glass Surface
```
background: glass-bg
backdrop-filter: blur(glass-blur)
border: 1px solid glass-border
border-radius: radius-lg
box-shadow: surface-shadow
```

### Interactive Item
```
default:  bg transparent, fg-primary
hover:    bg-elevated, transition 120ms
active:   bg-elevated + accent-glow left border (3px)
focused:  accent-primary outline (2px), offset 2px
disabled: fg-muted, no interaction
```

### Status Badge
```
dot (8px circle) + label (label-sm)
ok:      status-ok dot, "Working" label
warn:    status-warn dot, "Degraded" label
error:   status-error dot, "Not Working" label
unknown: status-unknown dot, "Unknown" label
```
