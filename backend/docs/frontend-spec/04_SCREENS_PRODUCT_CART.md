# GreenBasket — Screen Specifications (Part 2: Product, Search, Cart, Checkout)

## 4.8 Categories Screen (Tab Index 1)

**Purpose**: Browse all product categories in a grid.

**App Bar**: Standard — title "Categories" `headingLg` / `neutral900`, no actions.

**Content**: 2-column grid, 16dp padding, 12dp gap.
- **CategoryTile**: Card with `md` radius, `low` shadow, height 140dp
  - Background: full-bleed category image (opacity 0.85) with dark gradient bottom 40%
  - Bottom overlay: category name `titleLg` / white, subcategory count `caption` / white/0.7
  - Tap → Product Listing for that category

---

## 4.9 Product Listing Screen

**Purpose**: Display products filtered by category, search, or tag.

**App Bar**: Back arrow + category/search title `headingLg` + filter icon (24dp) + sort icon (24dp).

**Filter Bar** (below app bar, horizontal scroll, 44dp height):
- Chips: "All", subcategories from API, "Organic", "Best Seller", "On Sale"
- **GBFilterChip**: `sm` radius, height 32dp, padding horizontal 12dp
  - Unselected: border `neutral300`, text `bodyMd` / `neutral700`, bg white
  - Selected: bg `primarySurface`, border `primary`, text `titleMd` / `primary`

**Product Grid**: 2-column `StaggeredGridView`, 12dp gap, 16dp horizontal padding.
- Uses **ProductCard** (grid variant)
- Pull-to-refresh: `RefreshIndicator` (color `primary`)
- Pagination: load next 20 on scroll near bottom (300dp threshold)
- Initial: shimmer skeleton (6 cards)

**Sort Bottom Sheet** (triggered by sort icon):
- Options: "Relevance", "Price: Low to High", "Price: High to Low", "Newest First", "Rating"
- Each option: 52dp row, radio button (20dp) + text `bodyMd`, selected = `primary`
- Apply button at bottom

**Filter Bottom Sheet** (triggered by filter icon):
- Sections: Price Range (RangeSlider, `primary` track), Tags (chips), Rating (star row min), Availability ("In Stock" toggle)
- Bottom: "Reset" text button + "Apply" primary button (120dp width, 44dp height)

**Empty State**: EmptyStateWidget with produce illustration + "No products found" + "Try adjusting filters" + "Clear Filters" button.

---

## 4.10 Product Detail Screen

**Purpose**: Full product information, add to cart.

**Image Section**:
- `PageView` carousel, height 300dp, white bg
- Hero animation from ProductCard image
- Page indicator dots (6dp) bottom 12dp
- Wishlist heart icon: top-right 16dp, 40×40dp circle / white / `low` shadow
  - Default: `favorite_border` / `neutral700`; wishlisted: `favorite` / `error` (#D62828), animated scale bounce

**Content** (scrollable, 16dp horizontal padding, starts 12dp below images):

- **Tags row**: Horizontal chips — "Organic" (`organic` bg), "Farm Fresh", etc. — `xs` radius, height 24dp, `overline` text
- **Name**: `headingLg` / `neutral900` — 8dp below tags
- **Rating row**: 5 stars (14dp, `rating` color) + "4.2" `titleMd` / `neutral900` + "(128 reviews)" `bodySm` / `neutral500` — 4dp below name
- **Price row**: 8dp below rating
  - Current: `headingMd` / `primary` / weight 700 — "₹149"
  - Compare (if exists): `bodyMd` / `neutral500` / line-through — "₹199"
  - Discount badge: bg `discount`, radius `xs`, "25% OFF" `overline` / white, 8dp left of current
  - Unit: `bodySm` / `neutral500` — "per kg"

- **Quantity Selector** (16dp below price): GBQuantitySelector (see components)
- **Add to Cart Button**: Full-width, 52dp, `primary` bg, "Add to Cart — ₹149" `buttonLg` / white — 16dp below qty

- **Divider**: 24dp vertical margin, 1dp `neutral300`

- **Merchant Info** (8dp below divider):
  - Row: merchant avatar 36dp circle + name `titleMd` / `neutral900` + "View Store >" `bodySm` / `primary`
  - Below: "📍 2.3 km away" `caption` / `neutral500`

- **Preparation Options** (if available, 16dp below):
  - Header: "Preparation" `titleLg`
  - Horizontal chips: "Whole", "Cut", "Chopped" — same as filter chips, single select

- **Description** (16dp below):
  - Header: "About this product" `titleLg`
  - Body: `bodyMd` / `neutral700`, max 3 lines + "Read more" expandable

- **Nutritional Info** (expandable tile, 16dp below):
  - Row of 4 mini-cards: Calories, Protein, Carbs, Fat — each 72dp wide, `neutral100` bg, `md` radius

- **Origin & Quality** (expandable tile):
  - Farm name, location, harvest date, certifications

- **Reviews Section** (16dp below):
  - Header: "Reviews" `titleLg` + "See All >" `titleSm` / `primary`
  - Top 3 reviews: ReviewCard (see components)

- **Similar Products** (24dp below):
  - Header: "You might also like" `headingSm`
  - Horizontal scroll of ProductCard (compact, 140dp)

---

## 4.11 Search Screen

**Purpose**: Full-featured product search with history and suggestions.

**App Bar**: Auto-focused GBSearchBar (same style as home, but functional), back arrow.

**Before typing** (default state):
- "Recent Searches" `titleLg` — list of recent queries (max 10, `bodyMd` / `neutral900`, clock icon 18dp / `neutral500`, tap to search, `x` to delete)
- "Trending Searches 🔥" `titleLg` — horizontal chips (`primarySurface` bg, `primary` text)

**While typing** (debounce 300ms):
- Suggestions list from `GET /api/search/suggestions?q=...`
- Each: `bodyMd`, matching chars bold, search icon prefix 18dp

**After search**:
- Product grid (same as Product Listing), filter/sort available
- "X results for 'query'" `bodySm` / `neutral500` above grid

---

## 4.12 Cart Screen (Tab Index 2)

**Purpose**: Review cart items, apply coupons, proceed to checkout.

**App Bar**: "My Cart" `headingLg` + item count badge + "Clear All" text button (right, `error` color, with confirm dialog).

**Empty State**: Lottie empty-cart animation (180dp) + "Your cart is empty" `headingMd` + "Browse products to get started" `bodyMd` / `neutral500` + "Start Shopping" primary button.

**Cart Items List** (scrollable):
- Each: **CartItemCard** (see components) — dismissible left-to-right (red bg, trash icon)
- 12dp spacing between cards

**Coupon Section** (16dp below list):
- Row: coupon icon 20dp / `secondary` + "Apply Coupon" `titleMd` / `neutral900` + chevron right
- Tap → Coupon Bottom Sheet: text input + "Apply" button + available coupons list
- Applied: green checkmark, code shown, "Remove" link

**Price Summary Card** (16dp below coupon, `md` radius, `neutral100` bg, 16dp padding):
| Row | Left | Right |
|---|---|---|
| Items total | `bodyMd` / `neutral700` | `bodyMd` / `neutral900` "₹547" |
| Delivery | `bodyMd` / `neutral700` | `bodyMd` / `success` "FREE" or amount |
| Discount | `bodyMd` / `neutral700` | `bodyMd` / `success` "-₹50" |
| Divider | — | — |
| **Total** | `titleLg` / `neutral900` | `titleLg` / `neutral900` "**₹497**" |

**Checkout Button** (sticky bottom, 16dp padding, white bg, `medium` shadow):
- Full-width, 52dp, `primary` — "Proceed to Checkout (₹497)" `buttonLg` / white

---

## 4.13 Checkout Screen (Multi-step)

**Purpose**: Address → Delivery slot → Payment → Confirm.

**Progress Indicator**: Step indicator bar at top (4 steps: Address, Delivery, Payment, Review), 8dp height circles connected by lines, active = `primary`, completed = `primary` + check, inactive = `neutral300`.

### Step 1 — Delivery Address
- List of saved addresses (AddressCard — see components), radio selection
- "+ Add New Address" outlined button
- "Continue" primary button sticky bottom

### Step 2 — Delivery Slot
- Date selector: horizontal scroll of DateChips (next 7 days), 60dp width each
- Time slots: grid of 2-column cards ("9 AM – 11 AM", "11 AM – 1 PM", etc.), 44dp height, single select
- "Continue" button

### Step 3 — Payment Method
- Options list (RadioListTile style, 56dp each):
  - Online Payment (Stripe) — Card / UPI / NetBanking via Stripe PaymentSheet
  - Wallet Balance (show ₹balance, disabled if 0)
  - Cash on Delivery
- Wallet partial pay toggle if wallet + online selected
- Stripe PaymentSheet opens natively on "Continue" for online payment
- "Continue" button

### Step 4 — Order Review
- Collapsed order summary: items list (mini), address card, slot, payment method
- Price breakdown (same as cart)
- "Place Order" primary button — 52dp, `primary`
- Loading state: full-screen overlay with Lottie spinner

---

## 4.14 Order Success Screen

**Purpose**: Confirm order placed.

**Layout**: Center-aligned, white bg.
- Lottie success checkmark animation: 150×150dp
- "Order Placed!" `displayMd` / `success` — 24dp below
- "Your order #GB1234 has been placed" `bodyMd` / `neutral500` — 8dp below
- Estimated delivery: `titleMd` / `neutral900` — 16dp below
- "Track Order" primary button — 32dp below
- "Continue Shopping" outlined button — 12dp below
- **No back navigation** — buttons only
