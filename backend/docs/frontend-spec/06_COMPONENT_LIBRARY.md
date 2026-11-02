# GreenBasket — Reusable Component Library

## 5.1 Buttons

### GBPrimaryButton
- **Props**: `label` (String), `onPressed` (VoidCallback?), `isLoading` (bool), `icon` (IconData?), `fullWidth` (bool, default true)
- **Style**: height 52dp, radius `sm` (8dp), bg `primary`, text `buttonLg` / white, padding horizontal 24dp
- **Loading**: replace label with `CircularProgressIndicator(strokeWidth: 2, color: white, size: 20dp)`
- **Disabled**: `onPressed == null` → opacity 0.5, no ink
- **Press animation**: scale down to 0.97 for 100ms (`button` token)

### GBSecondaryButton
- Same as Primary but: bg `primarySurface` (#D8F3DC), text `buttonLg` / `primary`

### GBOutlinedButton
- bg transparent, border 1.5dp `primary`, text `buttonLg` / `primary`

### GBTextButton
- bg transparent, no border, text `buttonMd` / `primary`, underline optional

### GBIconButton
- 40×40dp circle, `neutral100` bg, icon 20dp `neutral700`. Active: `primarySurface` bg, `primary` icon

### GBDestructiveButton
- Same structure as Primary but: bg `error`, text white

---

## 5.2 Input Fields

### GBTextField
- **Props**: `label` (String?), `hint` (String), `controller`, `prefixIcon` (IconData?), `suffixIcon`, `obscureText`, `keyboardType`, `validator`, `errorText`, `enabled`, `maxLines`, `onChanged`
- **Structure**: Column(label `titleSm` / `neutral700` + SizedBox(6dp) + TextFormField)
- **Dimensions**: height 52dp (single line), radius `sm`, padding horizontal 16dp
- **Colors**:
  - Default: fill `neutral100`, border 1dp `neutral300`
  - Focused: fill white, border 2dp `primary`
  - Error: fill `errorLight`, border 1.5dp `error`
  - Disabled: fill `neutral100`, opacity 0.6
- **Error text**: below field, 4dp top, `caption` / `error`
- **Prefix/suffix icons**: 20dp, `neutral500` (default), `primary` (focused)

### GBPasswordField
- Extends `GBTextField` with obscure toggle (eye icon suffix), strength indicator bar (4dp height below)

### GBPhoneField
- Extends `GBTextField` with "+91" prefix (non-editable), numeric keyboard

### GBSearchBar
- height 48dp, radius `full` (24dp), fill `neutral100`, no label
- Prefix: search icon 20dp / `neutral500`
- Suffix: clear "×" icon when text exists

---

## 5.3 Cards

### ProductCard (Grid Variant)
- **Dimensions**: flexible width (column), aspect ratio ~0.7
- **Structure**:
  - Image: top, aspect ratio 1:1, radius top-left/right `md`, `CachedNetworkImage` with shimmer placeholder
  - Wishlist icon: top-right 8dp from edges, 32×32dp circle, white bg, `low` shadow
  - Discount badge (if comparePrice): top-left 8dp, bg `discount`, radius `xs`, "-25%" `overline` / white
  - Tag chip (if organic/seasonal): below image-left, partially overlapping
  - Body padding 8dp:
    - Name: `titleMd` / `neutral900`, max 2 lines, ellipsis
    - Unit: `caption` / `neutral500` — "per kg"
    - Price row: current `titleLg` / `primary` + compare `bodySm` / `neutral500` / line-through
    - Rating: mini stars (12dp) + `caption` rating number
    - Add button: "Add" 32dp height outlined, radius `sm`, `primary` — or `GBQuantitySelector` (compact) if already in cart
- **Overall**: radius `md`, bg white, `low` shadow

### ProductCard (List Variant)
- Row layout: image 100×100dp (left, radius `md`) + Expanded body (right) + column-end (price + add)
- Height: 120dp, full padding 12dp

### CategoryCard
- 140dp height, full-width, radius `md`, bg image with gradient overlay
- Name overlay: `titleLg` / white, bottom-left 12dp

### CartItemCard
- Row: image 72dp square radius `sm` + Column(name `titleMd` + unit/prep `caption` + price `titleMd`/`primary`) + right: GBQuantitySelector (compact)
- Background: white, radius `md`, padding 12dp, `low` shadow
- Dismissible: left swipe → red bg + trash icon

### OrderCard
- Vertical card, radius `md`, padding 16dp, `low` shadow
- Top row: "Order #GB1234" `titleMd` / `neutral900` + StatusBadge (right)
- Items preview: first 2 items as Row(image 36dp circle + name), "+ 3 more" if >2
- Bottom row: date `caption` / `neutral500` + "₹497" `titleLg` / `neutral900` + "Track" outlined button 32dp height
- Divider above bottom row

### AddressCard
- radius `md`, border 1dp `neutral300`, padding 16dp
- Top: label badge ("Home"/"Office", `primarySurface` bg, `primary` text, `xs` radius) + "Default" badge (if default, `successLight` bg)
- Name: `titleMd` / `neutral900`
- Address: `bodyMd` / `neutral700`, max 2 lines
- Phone: `bodySm` / `neutral500`
- Actions: Edit icon + Delete icon (top-right)

### RecipeCard
- Width 200dp, height 240dp, radius `lg`
- Image: top, height 140dp, radius top `lg`
- Below: name `titleMd` (max 2 lines), row(clock icon + time + difficulty badge)

### ReviewCard
- Avatar 36dp circle + name `titleMd` + date `caption`
- Star row (14dp), comment `bodyMd` / `neutral700` max 3 lines
- "Helpful" text button ("👍 12")

---

## 5.4 Navigation

### GBBottomNavBar
- 5-tab bar as specified in Home Screen (§4.7), persistent across main screens via `StatefulShellRoute`

### GBAppBar (Standard)
- Height 56dp, bg white, `low` shadow, title center `headingLg` / `neutral900`, optional leading/actions

### GBAppBar (Search)
- Contains functional `GBSearchBar` occupying title area

---

## 5.5 Feedback Components

### GBSnackbar
- Bottom-positioned, margin 16dp, radius `sm`, height 48dp
- Variants: success (`success` bg), error (`error` bg), info (`info` bg), warning (`warning` bg)
- Content: icon 20dp + message `bodyMd` / white + optional "Undo" action text

### GBLoadingOverlay
- Semi-transparent black (0.3) overlay + center Lottie spinner (80dp)

### GBShimmer
- Uses `shimmer` package, base `shimmer` color, highlight `shimmerHighlight`
- Pre-built: `ShimmerProductCard`, `ShimmerOrderCard`, `ShimmerList`

### EmptyStateWidget
- Props: `icon`/`lottieAsset`, `title`, `subtitle`, `actionLabel`, `onAction`
- Structure: Column(center): illustration 150dp + title `headingMd` / `neutral700` (16dp gap) + subtitle `bodyMd` / `neutral500` (8dp gap) + button (24dp gap)

### ErrorStateWidget
- Same as EmptyState but with error illustration, red tint, "Retry" button by default

### GBDialog
- radius `lg`, padding 24dp, max-width 320dp
- Title `headingMd` center + content `bodyMd` center + row(cancel text button + confirm primary button)

---

## 5.6 Display Components

### GBQuantitySelector
- **Standard**: Row( "−" circle 36dp / `neutral100` bg + count `titleLg` center min-width 40dp + "+" circle 36dp / `primary` bg)
- **Compact**: Row( "−" 28dp + count `titleMd` 28dp + "+" 28dp) — for cart/product cards
- Min value: 1 (minus disabled/hidden below 1), max: stock limit from product
- Remove behavior when count hits 0: show "Add" button instead

### GBBadge
- Positioned: top-right (-4dp, -4dp), min-diameter 18dp, bg `error`, text `overline` / white center
- If count >99: show "99+"

### GBRating
- Read-only star row OR interactive (tap to rate)
- Star size: configurable (12dp, 14dp, 20dp), filled = `rating`, empty = `neutral300`

### StatusBadge
- Props: `status` (enum string)
- Mapping: pending→`warningLight`/`warning`, confirmed→`infoLight`/`info`, preparing→`primarySurface`/`primary`, delivered→`successLight`/`success`, cancelled→`errorLight`/`error`
- Style: radius `xs`, height 24dp, padding horizontal 8dp, `overline` text weight 600

### GBImageCarousel
- `PageView` + `SmoothPageIndicator`, configurable height, auto-play optional

### GBFilterChip (reusable)
- As specified in Product Listing screen
