# GreenBasket — Screen Specifications (Part 1: Auth & Home)

## 4.1 Splash Screen

**Purpose**: Brand intro, token validation, routing decision.

**Layout**:
- Full-screen `primary` (#2D6A4F) background
- Center: Lottie animation (basket logo) — 200×200dp
- Below logo (24dp gap): App name "GreenBasket" in `displayLg` / white / weight 700
- Below name (8dp): Tagline "Farm Fresh to Your Door" in `bodyMd` / white / opacity 0.8
- Bottom 48dp: Circular progress (white, 2dp stroke, 24×24dp)

**Logic**: Check stored tokens → valid → Home; invalid/none → Onboarding (if first launch) or Login.

**Duration**: Minimum 2s (animation), max 4s (includes token check).

---

## 4.2 Onboarding Screens (3 pages)

**Purpose**: First-time user introduction.

**Layout (each page)**:
- Image/Lottie illustration: 280×280dp, top 25% of screen
- Title: `displayMd` / `neutral900` / center — 24dp below image
- Description: `bodyLg` / `neutral500` / center / max 2 lines — 12dp below title
- Page indicator: `smooth_page_indicator` — dot size 8dp, active 10dp, color `primary`
- Located 32dp below description

**Pages**:
1. 🥬 "Fresh from the Farm" / "Browse categories of farm-fresh produce harvested daily"
2. 🛒 "Easy Ordering" / "Add to cart, choose delivery time, pay your way"
3. 🚚 "Fast Delivery" / "Track your order in real-time from farm to door"

**Bottom Bar**: Height 80dp, horizontal padding 16dp
- Page 1–2: "Skip" (text button, left) + "Next" (primary button, right, 120×48dp)
- Page 3: Full-width "Get Started" primary button (48dp height)

**Animations**: `PageView` with `fast` (250ms) swipe, bounce-in illustrations.

---

## 4.3 Login Screen

**Purpose**: User email/password authentication.

**Layout** (top to bottom, padding 16dp horizontal):
- **Back button area**: SizedBox(height: 48dp) — empty on login since it's root auth
- **Logo**: Basket icon 64×64dp center + "GreenBasket" `headingLg` / `primary` — 48dp from top safe area
- **Welcome text**: "Welcome back!" `displaySm` / `neutral900` — 32dp below logo
- **Subtitle**: "Log in to continue" `bodyMd` / `neutral500` — 8dp below

**Form** (24dp below subtitle):

| Field | Type | Icon Prefix | Placeholder | Validation |
|---|---|---|---|---|
| Email | GBTextField | `Icons.email_outlined` 20dp | "Enter your email" | required, valid email regex |
| Password | GBTextField (obscure) | `Icons.lock_outlined` 20dp | "Enter your password" | required, min 6 chars |

- Field height: 52dp, radius 8dp, fill `neutral100`, border `neutral300` (default), `primary` (focused), `error` (error)
- Between fields: 16dp
- "Forgot Password?" — text button, right-aligned, `titleSm` / `primary` — 8dp below password

**Login Button**: Full-width GBPrimaryButton, 52dp height, 24dp below forgot password
- Default: "Log In" `buttonLg` / white, bg `primary`, radius 8dp
- Loading: CircularProgressIndicator (white, 20dp) replacing text
- Disabled: opacity 0.5

**Divider**: 32dp below button — Row: Expanded(Divider) + "or" `bodySm` / `neutral500` + Expanded(Divider)

**Social Login**: 20dp below divider
- Google button: outlined, 52dp height, full-width, radius 8dp, Google SVG icon 20dp + "Continue with Google" `titleSm` / `neutral900`

**Bottom**: Positioned at bottom — "Don't have an account? " `bodyMd` / `neutral500` + "Sign Up" `titleMd` / `primary` (tappable)

**States**: Default | Loading (button spinner + form disabled) | Error (Snackbar red with message)

---

## 4.4 Sign Up Screen

**Purpose**: New user registration.

**Layout**: Same header pattern as Login with back arrow (top-left, 24dp icon)
- Title: "Create Account" `displaySm` / `neutral900`
- Subtitle: "Join GreenBasket today" `bodyMd` / `neutral500`

**Form**:

| Field | Icon | Placeholder | Validation |
|---|---|---|---|
| Full Name | `person_outlined` | "Enter full name" | required, 2–50 chars |
| Email | `email_outlined` | "Enter your email" | required, email regex |
| Phone | `phone_outlined` | "Enter 10-digit number" | required, `^[0-9]{10}$` |
| Password | `lock_outlined` | "Create a password" | required, min 6 chars, 1 uppercase, 1 number |
| Confirm Password | `lock_outlined` | "Confirm your password" | required, must match password |

- Spacing between fields: 16dp
- Password strength indicator: 4dp height bar below password field — red (<6) / orange (6–7) / green (8+)

**Terms**: 16dp below form — Checkbox(20dp) + "I agree to the " `bodySm` + "Terms" (underline, tappable, primary) + " and " + "Privacy Policy" (underline, tappable, primary)

**Button**: "Create Account" full-width primary, 52dp — 24dp below terms
**Bottom**: "Already have an account? " + "Log In" link

---

## 4.5 Forgot Password Screen

**Purpose**: Initiate password reset via email.
**Layout**: Back arrow + "Forgot Password" `headingLg`, illustration (lock icon 120dp), description text, email field, "Send Reset Link" button.

---

## 4.6 OTP / Email Verification Screen

**Purpose**: Verify OTP sent to email.
**Layout**: Back arrow + "Verify Email" title, envelope illustration (100dp), "We sent a code to user@email.com" `bodyMd`, **Pinput** widget (6 fields, 48×52dp each, `sm` radius, `primary` focused border), "Resend in 30s" countdown, auto-submit on 6 digits.

---

## 4.7 Home Screen

**Purpose**: Main landing page — product discovery hub.

**App Bar** (custom, height 56dp, bg white, `low` shadow):
- Left: "📍 Deliver to" `bodySm` / `neutral500` above address `titleMd` / `neutral900` (truncated 200dp max) + chevron_down 16dp (tappable → address bottom sheet)
- Right: Notification bell icon 24dp with red badge circle (8dp, unread count or dot) — taps to Notifications

**Search Bar** (below app bar, horizontal padding 16dp, 12dp top):
- GBSearchBar: height 48dp, radius `full` (24dp), fill `neutral100`, prefix search icon 20dp / `neutral500`, placeholder "Search fruits, vegetables..." `bodyMd` / `neutral500`
- **Not a real search — taps navigate to Search Screen**

**Content** (SingleChildScrollView):

### A. Promotional Banner Carousel
- `PageView` with auto-scroll (5s interval)
- Card: full-width minus 32dp padding, height 160dp, radius `lg` (16dp)
- Gradient overlay (left-to-right, 60% primary-dark → transparent)
- Title inside: `headingMd` / white, CTA button: outlined white 32dp height
- Page indicator: 3 dots (6dp), 12dp below card

### B. Categories Row (24dp below)
- Header: "Shop by Category" `headingSm` / `neutral900` + "See All" `titleSm` / `primary` (right)
- Horizontal scroll ListView (height 100dp), 12dp between items
- **CategoryChip**: Column(CircleAvatar(32dp radius, `primarySurface` bg, icon/image 28dp) + SizedBox(6dp) + Text(`caption` / `neutral700`))
- Show first 8 categories, "See All" navigates to Categories screen

### C. Flash Deals Section (24dp below)
- Header: "⚡ Flash Deals" `headingSm` + countdown timer `titleSm` / `secondary` + "See All"
- Horizontal scroll of **ProductCard** (width 160dp) — 12dp spacing
- See Component Library for ProductCard spec

### D. Popular Products Grid (24dp below)
- Header: "Popular Now" `headingSm` + "See All"
- 2-column `StaggeredGridView`, item spacing 12dp
- Uses **ProductCard** (grid variant)
- Lazy loads, first 6 shown

### E. Recipe Inspiration (24dp below)
- Header: "Recipe Inspiration 🍳" + "See All"
- Horizontal scroll of **RecipeCard** (width 200dp, height 240dp)

### F. Recently Viewed (24dp below, shown if user has history)
- Horizontal scroll of **ProductCard** (compact, 140dp width)

**Bottom Navigation Bar**: 5 tabs, height 64dp + safe area, bg white, `medium` shadow
| Index | Label | Icon (outlined) | Icon (filled, selected) | Color |
|---|---|---|---|---|
| 0 | Home | `home_outlined` | `home` | `primary` active, `neutral500` inactive |
| 1 | Categories | `grid_view_outlined` | `grid_view` | same |
| 2 | Cart | `shopping_cart_outlined` | `shopping_cart` | same + red badge with item count |
| 3 | Wishlist | `favorite_border` | `favorite` | same |
| 4 | Profile | `person_outlined` | `person` | same |

Icon size: 24dp. Label: `caption` (11sp). Selected label: `primary`; unselected: `neutral500`.
