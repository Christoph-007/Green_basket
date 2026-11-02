# GreenBasket — Design System Specification

## 3.1 Color Palette

### Primary Colors
| Token | Hex | Usage |
|---|---|---|
| `primary` | `#2D6A4F` | Buttons, active states, links, nav selected |
| `primaryLight` | `#40916C` | Hover states, secondary emphasis |
| `primaryDark` | `#1B4332` | App bar, status bar, pressed states |
| `primarySurface` | `#D8F3DC` | Tag backgrounds, light cards, chips |

### Secondary Colors
| Token | Hex | Usage |
|---|---|---|
| `secondary` | `#E76F51` | Accent buttons, sale badges, CTAs |
| `secondaryLight` | `#F4A261` | Warm highlights, price tags |
| `secondaryDark` | `#D62828` | Error-adjacent warnings, urgent badges |

### Neutrals
| Token | Hex | Usage |
|---|---|---|
| `neutral900` | `#1A1A2E` | Primary text |
| `neutral700` | `#4A4A68` | Secondary text, icons |
| `neutral500` | `#7C7C9A` | Placeholder text, disabled |
| `neutral300` | `#C4C4D4` | Borders, dividers |
| `neutral100` | `#F0F0F5` | Card backgrounds, input fills |
| `neutral50` | `#F8F8FC` | Page background |
| `white` | `#FFFFFF` | Cards, sheets, modals |

### Semantic Colors
| Token | Hex | Usage |
|---|---|---|
| `success` | `#2D6A4F` | Checkmarks, success toasts, delivery |
| `successLight` | `#D8F3DC` | Success background |
| `error` | `#D62828` | Validation errors, destructive actions |
| `errorLight` | `#FFE0E0` | Error field background |
| `warning` | `#F4A261` | Low stock, expiring items |
| `warningLight` | `#FFF3E0` | Warning background |
| `info` | `#457B9D` | Informational banners |
| `infoLight` | `#E3F2FD` | Info background |

### Special
| Token | Hex | Usage |
|---|---|---|
| `organic` | `#52B788` | Organic tags |
| `premium` | `#FFD700` | Premium badges, loyalty gold |
| `rating` | `#FFB703` | Star ratings |
| `discount` | `#D62828` | Strikethrough prices, discount badges |
| `shimmer` | `#E8E8EE` | Skeleton loading base |
| `shimmerHighlight` | `#F5F5FA` | Skeleton loading highlight |

---

## 3.2 Typography

**Font Family**: `Poppins` (Google Fonts) — weights 400, 500, 600, 700

| Style Name | Size (sp) | Weight | Line Height | Letter Spacing | Usage |
|---|---|---|---|---|---|
| `displayLg` | 32 | 700 | 40 | -0.5 | Splash headline |
| `displayMd` | 28 | 700 | 36 | -0.25 | Onboarding headlines |
| `displaySm` | 24 | 600 | 32 | 0 | Section headers |
| `headingLg` | 22 | 600 | 28 | 0 | Screen titles |
| `headingMd` | 20 | 600 | 26 | 0 | Card titles, dialog headers |
| `headingSm` | 18 | 600 | 24 | 0 | Sub-section headers |
| `titleLg` | 16 | 600 | 22 | 0.15 | Product name, list titles |
| `titleMd` | 14 | 600 | 20 | 0.1 | Labels, tab titles |
| `titleSm` | 13 | 500 | 18 | 0.1 | Button text (large) |
| `bodyLg` | 16 | 400 | 24 | 0.5 | Descriptions, long text |
| `bodyMd` | 14 | 400 | 20 | 0.25 | Default body text |
| `bodySm` | 12 | 400 | 18 | 0.4 | Secondary info |
| `caption` | 11 | 400 | 16 | 0.4 | Timestamps, helper text |
| `overline` | 10 | 500 | 14 | 1.5 | Overlines, tags |
| `buttonLg` | 16 | 600 | 20 | 0.5 | Primary button text |
| `buttonMd` | 14 | 600 | 18 | 0.5 | Secondary button text |
| `buttonSm` | 12 | 600 | 16 | 0.5 | Small/text buttons |

---

## 3.3 Spacing System

| Token | Value (dp) | Usage |
|---|---|---|
| `xxs` | 2 | Micro gaps |
| `xs` | 4 | Icon-to-text inline, compact list items |
| `sm` | 8 | Chip padding, tight groupings |
| `md` | 12 | Card internal padding, button padding vertical |
| `lg` | 16 | Screen horizontal padding, section spacing |
| `xl` | 20 | Between major sections |
| `xxl` | 24 | Large card padding, modal padding |
| `xxxl` | 32 | Between screen sections, form spacing |
| `huge` | 48 | Splash spacing, hero sections |

**Screen Padding**: Horizontal `16dp`, vertical `16dp` (safe area insets above).

---

## 3.4 Border Radius

| Token | Value (dp) | Usage |
|---|---|---|
| `none` | 0 | Dividers |
| `xs` | 4 | Chips, small badges |
| `sm` | 8 | Input fields, buttons |
| `md` | 12 | Cards, containers |
| `lg` | 16 | Bottom sheets, modals |
| `xl` | 20 | Image crops, large cards |
| `xxl` | 24 | Onboarding cards |
| `full` | 999 | Circular (avatars, FABs) |

---

## 3.5 Shadows & Elevation

| Token | Elevation | Shadow Spec | Usage |
|---|---|---|---|
| `none` | 0 | — | Flat elements |
| `low` | 2 | `0 1dp 3dp rgba(0,0,0,0.08)` | Cards, list items |
| `medium` | 4 | `0 2dp 8dp rgba(0,0,0,0.12)` | Floating action, app bar |
| `high` | 8 | `0 4dp 16dp rgba(0,0,0,0.16)` | Bottom sheets, modals |
| `highest` | 16 | `0 8dp 24dp rgba(0,0,0,0.20)` | Dialogs |

---

## 3.6 Icon System

- **Library**: Material Icons + custom SVG assets for brand-specific icons
- **Standard sizes**: `16dp` (inline), `20dp` (input prefix/suffix), `24dp` (navigation, action buttons), `32dp` (category icons), `48dp` (empty states), `64dp` (onboarding)
- **Default color**: `neutral700` (`#4A4A68`); active/selected: `primary` (`#2D6A4F`)

---

## 3.7 Animation Tokens

| Token | Duration | Curve | Usage |
|---|---|---|---|
| `fast` | 150ms | `easeOut` | Micro-interactions (icon toggle, color change) |
| `normal` | 250ms | `easeInOut` | Page transitions, card expand |
| `slow` | 350ms | `easeInOut` | Bottom sheet slide, modal entry |
| `splash` | 2000ms | `easeIn` → `easeOut` | Splash logo animation |
| `pageTransition` | 300ms | `fastOutSlowIn` | Route transitions |
| `shimmer` | 1500ms | `linear` (loop) | Skeleton loading |
| `success` | 1200ms | `spring` | Order success animation |
| `button` | 100ms | `easeIn` | Button press scale (0.97) |
