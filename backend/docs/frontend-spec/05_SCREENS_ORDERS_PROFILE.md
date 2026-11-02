# GreenBasket — Screen Specifications (Part 3: Orders, Profile & Settings)

## 4.15 Orders List Screen

**Purpose**: View all user orders with filter tabs.

**App Bar**: "My Orders" `headingLg`.

**Tab Bar** (below app bar, scrollable):
- Tabs: "All", "Active", "Completed", "Cancelled" — underline indicator `primary`, `titleMd`

**Order List**: ListView with 12dp spacing, 16dp horizontal padding.
- Uses **OrderCard** (see components)
- Pull-to-refresh, pagination (20 per page)

**Empty State**: "No orders yet" + bag illustration + "Start Shopping" button.

---

## 4.16 Order Detail Screen

**Purpose**: Full order info with tracking.

**App Bar**: "Order #GB1234" `headingLg` + "Help" text button (right).

**Content** (scroll):
- **Status Banner**: 64dp, bg = status-based color (pending=`warningLight`, confirmed=`infoLight`, delivered=`successLight`, cancelled=`errorLight`)
  - Status icon 28dp + status text `titleLg` + estimated time `bodySm`

- **Tracking Timeline** (16dp below):
  - Vertical stepper: 4–6 steps with circle indicators (16dp), connecting line (2dp)
  - Completed: `primary` circle + check; Active: `primary` circle, pulsing; Pending: `neutral300` circle
  - Each step: status `titleMd` + timestamp `caption` / `neutral500`

- **Items Section** (16dp below):
  - Each item: Row(image 48dp circle + name `bodyMd` + qty `bodySm` / `neutral500` + "₹149" `titleMd`)

- **Delivery Address** (card, `md` radius, 16dp padding):
  - Label badge ("Home"/"Office"), full address `bodyMd`, phone `bodySm`

- **Payment Summary**: Same format as cart price summary

- **Actions** (bottom):
  - Active order: "Cancel Order" destructive outlined button (with confirmation dialog)
  - Delivered order: "Rate Order" primary button + "Reorder" outlined button
  - Cancelled: "Reorder" primary button

---

## 4.17 Profile Screen (Tab Index 4)

**Purpose**: User account overview and navigation hub.

**Header Card** (no app bar, custom header):
- Background: `primary` gradient (top 180dp area)
- Profile avatar: 72dp circle, white 3dp border, bottom-edge of gradient
  - Default: initials in `headingMd` / white on `primaryLight`
  - With image: `CachedNetworkImage`, circular crop
- Name: `headingMd` / `neutral900` — 8dp below avatar
- Email: `bodySm` / `neutral500` — 4dp below name
- Loyalty badge: `overline` / `premium` color — "🏅 Gold Member"

**Menu List** (below, 16dp padding):

| Icon | Label | Trailing | Route |
|---|---|---|---|
| `shopping_bag_outlined` | "My Orders" | `chevron_right` | Orders List |
| `location_on_outlined` | "My Addresses" | `chevron_right` | Address Management |
| `account_balance_wallet_outlined` | "Wallet" | "₹250" `titleSm`/`primary` + chevron | Wallet |
| `star_outlined` | "Loyalty Points" | "1,250 pts" `titleSm`/`premium` + chevron | Loyalty |
| `card_giftcard_outlined` | "Referrals" | `chevron_right` | Referral |
| `restaurant_menu_outlined` | "Recipes" | `chevron_right` | Recipes List |
| `settings_outlined` | "Settings" | `chevron_right` | Settings |
| `help_outline` | "Help & Support" | `chevron_right` | Help |
| `logout` | "Log Out" | — | Confirm dialog → logout |

Each menu row: 56dp height, left icon 24dp / `primary`, text `bodyMd` / `neutral900`, divider below (except last).

---

## 4.18 Edit Profile Screen

**Purpose**: Update user name, phone, dietary preferences.

**App Bar**: Back + "Edit Profile" `headingLg` + "Save" text button (right, `primary`).

**Content**:
- Avatar with camera overlay icon (bottom-right, 28dp circle, `primary` bg, camera icon 16dp white) — tap opens image picker
- Fields: Name, Email (read-only / disabled), Phone
- Dietary Preferences: Multi-select chips ("Vegetarian", "Vegan", "Non-Vegetarian", "Gluten-Free", "Organic Only")
- Allergies: Text input with tag-style chips (add via enter key)

---

## 4.19 Address Management Screen

**Purpose**: View, add, edit, delete delivery addresses.

**App Bar**: Back + "My Addresses" `headingLg`.

**Address List**: Each uses **AddressCard** with edit/delete actions.
- Swipe left to delete (with confirm), tap to edit.
- Default address: green border left (3dp), "Default" badge.

**FAB**: "+ Add Address" — circular, `primary`, plus icon.

---

## 4.20 Add/Edit Address Screen

**Purpose**: Form to create or modify an address.

**App Bar**: Back + "Add Address" / "Edit Address" `headingLg`.

**Map Section** (top, height 200dp): Google Map with draggable pin for lat/lng.

**Form**:
| Field | Validation |
|---|---|
| Label | Required — chip select: Home/Office/Other |
| Full Name | Required, 2–50 chars |
| Phone | Required, 10 digits |
| Address Line 1 | Required |
| Address Line 2 | Optional |
| Landmark | Optional |
| City | Required |
| State | Required (dropdown) |
| Pincode | Required, 6 digits |
| Set as Default | Toggle switch |

**Save Button**: Full-width primary, 52dp.

---

## 4.21 Wishlist Screen (Tab Index 3)

**Purpose**: View wishlisted products.

**App Bar**: "Wishlist" `headingLg` + item count `bodySm`.

**Content**: 2-column product grid using **ProductCard** (with remove and "Move to Cart" actions).

**Empty State**: Heart illustration + "Your wishlist is empty" + "Explore Products" button.

---

## 4.22 Notifications Screen

**Purpose**: In-app notification center.

**App Bar**: "Notifications" `headingLg` + "Mark All Read" text button (right).

**List**: Grouped by date ("Today", "Yesterday", "Earlier").
- Each notification: Row(Icon-colored-circle 40dp + Column(title `titleMd` + message `bodySm` / `neutral500` + time `caption` / `neutral500`))
- Unread: bg `primarySurface` / `neutral50` border-left 3dp `primary`
- Tap: navigate based on notification type (order → order detail, offer → product listing)

**Empty State**: Bell illustration + "No notifications" + "We'll notify you about orders and offers".

---

## 4.23 Settings Screen

**Purpose**: App preferences.

**Sections**:
- **Notification Preferences**: Toggle switches for push (order updates, offers, price drops, back in stock)
- **Appearance**: Dark mode toggle (future), language selector (future, default English)
- **About**: App version, Terms of Service link, Privacy Policy link, Open Source Licenses
- **Danger Zone**: "Delete Account" destructive text button (double confirm dialog + password)
