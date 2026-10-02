---
name: Executive Operations & Intelligence System
colors:
  surface: '#121318'
  surface-dim: '#121318'
  surface-bright: '#38393f'
  surface-container-lowest: '#0d0e13'
  surface-container-low: '#1a1b21'
  surface-container: '#1e1f25'
  surface-container-high: '#292a2f'
  surface-container-highest: '#34343a'
  on-surface: '#e3e1e9'
  on-surface-variant: '#c2c6d6'
  inverse-surface: '#e3e1e9'
  inverse-on-surface: '#2f3036'
  outline: '#8c909f'
  outline-variant: '#424754'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e6a'
  primary-container: '#4d8eff'
  on-primary-container: '#00285d'
  inverse-primary: '#005ac2'
  secondary: '#c3c6d5'
  on-secondary: '#2c303c'
  secondary-container: '#434653'
  on-secondary-container: '#b1b4c3'
  tertiary: '#4edea3'
  on-tertiary: '#003824'
  tertiary-container: '#00a572'
  on-tertiary-container: '#00311f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#dfe2f1'
  secondary-fixed-dim: '#c3c6d5'
  on-secondary-fixed: '#171b26'
  on-secondary-fixed-variant: '#434653'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#121318'
  on-background: '#e3e1e9'
  surface-variant: '#34343a'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.005em
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.04em
  mono-metric:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  gutter-desktop: 1rem
  margin: 1rem
  margin-tablet: 1.5rem
  margin-desktop: 2rem
  space-xxs: 0.125rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
  space-2xl: 2rem
---

## Brand & Style

This design system embodies the disciplined precision of modern engineering and productivity software—drawing inspiration from Linear, Raycast, and Granola. It strips away ornamental AI clichés (gimmicky iridescent gradients, noisy mesh blurs, and oversized floating cards) in favor of high-information-density, functional legibility, and architectural clarity.

The visual style is **Corporate Modern with Utilitarian Precision**. Built specifically for high-velocity operators, engineering leads, and executives, the interface treats information triage as a low-latency workflow. Every element is deliberate: dark charcoal backdrops ground the UI, hairline neutral borders establish structural cadence, and focused electric blue accents guide cognitive momentum.

## Colors

The palette establishes an ultra-refined dark room optimized for prolonged operational focus:

- **Base Canvas (`#090A0F`):** Deep obsidian/charcoal neutral background reducing retinal fatigue.
- **Surface Elevation (`#12151D` to `#161922`):** Discrete layers for cards, bottom sheets, and panels, separating content hierarchically without relying on heavy drop shadows.
- **Structural Borders (`#1E222D`):** Hairline container lines with subtle 1px delineations that define modules with pixel-perfect confidence.
- **Primary Accent (`#3B82F6`):** Electric blue reserved for definitive interactive commitments, focused action states, active bottom-navigation tabs, and primary triage buttons.
- **Secondary & Surface Neutral (`#1E222D`):** Dark slate for pill fills, input wells, and segmented controls.
- **Semantic Badges & Accents:**
  - Critical / High Priority: `#EF4444` (Ruby Crimson)
  - Medium Priority / Warning: `#F59E0B` (Amber Ochre)
  - Success / Completed: `#10B981` (Emerald Spruce)
- **Text & Content Hierarchy:**
  - High Contrast / Headings: `#E6EDF3` (Crisp Chalk)
  - Secondary Content / Metadata: `#8B949E` (Slate Graphite)
  - Tertiary / Disabled / Muted: `#484F58` (Deep Muted Iron)

## Typography

Typography prioritizes high-density data parsing and systematic hierarchy. Powered entirely by `Inter`, the type scale leverages tight negative letter-spacing on display and headline tiers to convey an authoritative, engineered feel.

- **Metrics & KPIs:** Number totals (e.g., active meeting counters and progress counters) use tabular numerals (`tnum`) to eliminate layout jitter during live updates.
- **Labels & Micro-Badges:** Uppercase and compact micro-copy uses `label-sm` with a `+0.04em` tracking offset, maximizing readability at 10px within triage priority indicators.
- **Narrative Content:** Meeting summaries use `body-md` (`#8B949E`) with a line height of `18px`, delivering compact paragraphs that can be scanned in seconds without clutter.

## Layout & Spacing

The layout model is governed by an 8pt structural rhythm scaled for mobile viewport efficiency, stepping down to 4pt micro-increments for internal card paddings and metadata clusters.

- **Mobile Viewports (<600px):** Single-column layout with fixed outer margins of `16px` (`margin`). KPI summary cards utilize a rigid 3-column horizontal grid with `12px` (`gutter`) gaps.
- **Vertical Rhythm:** Grouped cards are separated by `space-md` (12px), while distinct functional sections (e.g., summary stats to meeting feeds) maintain an `space-xl` (24px) breathing buffer.
- **Internal Component Density:** Cards employ compact internal padding: `12px` horizontally and `12px` to `14px` vertically to preserve screen real estate on mobile devices.

## Elevation & Depth

Visual hierarchy uses flat, high-definition surface stratification and hairline boundaries rather than heavy drop shadows:

1. **Level 0 (Canvas):** Pure `#090A0F` base background.
2. **Level 1 (Card & Well Surfaces):** `#12151D` with a crisp `1px solid #1E222D` hairline border. Elements sit directly on the canvas without diffused blur shadows.
3. **Level 2 (Active Overlays & Floating Bars):** `#161922` combined with a subtle inset top highlight (`box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05)`) and `1px solid #272C3A`.
4. **Priority Accent Ribbons:** Left-border indicator strips (2px solid) on high-urgency cards (e.g., `#EF4444` for critical security reviews, `#F59E0B` for pending ad-hoc analysis) ground items in an immediate visual triage queue.

## Shapes

The design system adopts **Level 2 Roundedness** (0.5rem / 8px standard radius) to balance modern ergonomic touch targets with architectural structure.

- **Standard Containers & Cards:** `rounded-lg` (12px to 16px) for cards and modals to frame information density neatly.
- **Controls & Buttons:** `rounded` (8px) for buttons, inputs, and segmented controls, ensuring a solid, tactile, click-oriented form factor.
- **Badges & Micro-Pills:** Compact `rounded` (4px to 6px) shapes avoiding ballooned circular pills, reinforcing technical utility.

## Components

### Buttons & Interactive Controls
- **Primary Action (Triage):** Height `36px` to `40px`, background `#3B82F6`, text `#FFFFFF` (`label-md`), subtle top inner highlight `inset 0 1px 0 rgba(255, 255, 255, 0.2)`, `border-radius: 8px`. Optional micro-sparkle or operational icon placed leading with `6px` gap.
- **Secondary / Ghost:** Height `36px`, background `#161922`, border `1px solid #1E222D`, text `#E6EDF3`. Hover/Active state transitions to `#1E222D`.

### Triage & Operations Cards
- **Container:** Background `#12151D`, border `1px solid #1E222D`, border-radius `12px`, padding `14px`.
- **Accent Edge:** 2px or 3px colored indicator hugging the inner left border to convey priority ranking instantly.
- **Progress Track:** Integrated hairline progress bar (height `3px`, track background `#1E222D`, fill `#3B82F6`) displaying completion ratios (e.g., `Actions 1/4`).
- **Metadata Bar:** Linear cluster of icons, relative time, duration, and participant avatars separated by `8px` gap, rendered in `#8B949E` (`body-sm`).

### Status Badges & Chips
- **Priority Badge:** Strict rectangular badge with `4px` radius. Background is a 10% tinted tint of the semantic color (e.g., `rgba(239, 68, 68, 0.1)`), border `1px solid rgba(239, 68, 68, 0.25)`, text uppercase `10px` bold (`label-sm`).
- **Metadata Filter Chips:** Background `#161922`, border `1px solid #1E222D`, text `#8B949E`. Active chip shifts border to `#3B82F6` and text to `#E6EDF3`.

### KPI Stat Blocks
- Small modular card: background `#12151D`, border `1px solid #1E222D`, padding `12px`.
- Features a top-aligned rounded icon container (`24px` with subtle tinted background) followed by a bold metric value in `mono-metric` (`20px`) and muted label in `body-sm`.

### Input Wells & Bottom Navigation
- **Text Inputs:** Height `40px`, background `#0D0F15`, border `1px solid #1E222D`, text `#E6EDF3`, placeholder `#484F58`. Focus state shifts border to `#3B82F6` without outer ring fuzz.
- **Bottom Navigation Bar:** Height `60px`, background `#090A0F/95` with `16px` backdrop-filter blur, anchored by a hairline top border (`1px solid #1E222D`). Active items highlighted via `#3B82F6` tint and a subtle indicator point.