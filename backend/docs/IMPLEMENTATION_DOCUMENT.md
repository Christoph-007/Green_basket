# 📋 GreenBasket — Complete Implementation Document (All 4 Panels)

> Generated from raw code analysis of 33 route files, 28 model files, and all controllers.
> Source of truth: Backend code only. No existing docs referenced.

---

## Design System Reference

The frontend will be built in **Flutter Web**. All pages must strictly follow the visual design, UI/UX, animations, colors, typography, spacing, and component style from the provided screen recording. Specifically:

- Extract the exact color palette from the recording (hex codes)
- Match all font sizes, weights, and spacing exactly
- Replicate every animation: type, speed, easing, and direction
- Every component (buttons, cards, inputs, tables, modals, sidebar, navbar) must match the recording exactly in style and behavior
- Hover states, active states, loading states must match the recording
- Every new page not shown in the recording must use the same design DNA
- The screen recording is the single and absolute source of truth for all visual and interaction decisions — no exceptions

---

---

## Page 1: Admin Login

- **URL:** `/login`
- **Purpose:** Authenticate admin users into the panel

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/admin/login` | Login with email + password, returns JWT token |

### Page Sections
- **Login Form:** Centered card with app logo, email field, password field, login button
- **Error Banner:** Displays invalid credentials or server errors

### Components Needed
- `LoginCard` — centered container with form
- `TextInput` — email field
- `PasswordInput` — password field with show/hide toggle
- `PrimaryButton` — "Login" submit button
- `ErrorAlert` — conditionally shown error message

### Forms & Inputs
| Field | Type | Validation |
|-------|------|------------|
| email | Email input | Required, must match `/^\S+@\S+\.\S+$/` |
| password | Password input | Required, min 6 characters |

### Actions
| Button | Action |
|--------|--------|
| Login | `POST /api/auth/admin/login` → Store JWT token → Navigate to `/dashboard` |

### States to Handle
- **Loading:** Spinner on button during API call
- **Error:** "Invalid credentials" or network error message
- **Success:** Redirect to Dashboard

---

---

## Page 2: Dashboard

- **URL:** `/dashboard`
- **Purpose:** Platform-wide overview of key metrics

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/stats` | Platform statistics (users, merchants, orders, revenue) |

### Page Sections
- **Stats Cards Row:** Total Users, Total Merchants, Total Orders, Total Revenue, Pending Verifications
- **Recent Orders Table:** Last 10 orders with status badges
- **Quick Actions:** Links to Pending Merchants, Unassigned Orders, Open Disputes

### Components Needed
- `StatCard` — icon + number + label (4-6 cards in a row)
- `RecentOrdersTable` — compact table with order ID, customer, status, amount, date
- `QuickActionButton` — navigation shortcut buttons
- `StatusBadge` — color-coded badge for order status

### Table Columns (Recent Orders)
| Column | Source Field | Notes |
|--------|-------------|-------|
| Order ID | `orderId` | Format: GB + timestamp |
| Customer | `customer.name` | Populated from User ref |
| Merchant | `merchant.businessName` | Populated from Merchant ref |
| Total | `totalAmount` | Currency formatted |
| Status | `status` | Badge: pending(yellow), confirmed(blue), preparing(orange), delivered(green), cancelled(red) |
| Date | `createdAt` | Relative time (e.g., "2h ago") |

### States to Handle
- **Loading:** Skeleton cards and table shimmer
- **Empty:** "No data yet" message
- **Error:** Retry button with error message

---

---

## Page 3: All Users

- **URL:** `/users`
- **Purpose:** View and manage all registered customers

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/users` | List all users (paginated) |
| PATCH | `/api/admin/users/:id/block` | Block or unblock a user |

### Page Sections
- **Search Bar:** Search by name, email, phone
- **Users Table:** Paginated list of all users
- **Block/Unblock Action:** Inline button per row

### Components Needed
- `SearchInput` — search bar with debounce
- `DataTable` — sortable, paginated table
- `UserStatusBadge` — active (green) / blocked (red)
- `ConfirmationModal` — confirm block/unblock with reason input

### Table Columns
| Column | Source Field | Notes |
|--------|-------------|-------|
| Name | `name` | String, 2-50 chars |
| Email | `email` | Unique, lowercase |
| Phone | `phone` | 10-digit format |
| Loyalty Tier | `loyaltyTier` | Enum: bronze/silver/gold/platinum |
| Premium | `isPremium` | Boolean badge |
| Status | `isBlocked` | Active/Blocked badge |
| Joined | `createdAt` | Date formatted |
| Actions | — | Block/Unblock button |

### Forms & Inputs (Block Modal)
| Field | Type | Validation |
|-------|------|------------|
| isBlocked | Toggle/Boolean | Required |
| reason | Textarea | Required when blocking (stored in `blockedReason`) |

### Actions
| Button | Action |
|--------|--------|
| Block User | Opens confirmation modal → `PATCH /api/admin/users/:id/block` with `{ isBlocked: true, reason }` |
| Unblock User | `PATCH /api/admin/users/:id/block` with `{ isBlocked: false }` |

### States to Handle
- **Loading:** Table skeleton
- **Empty:** "No users found"
- **Error:** Error banner with retry
- **Success:** Toast "User blocked/unblocked successfully"

---

---

## Page 4: All Merchants

- **URL:** `/merchants`
- **Purpose:** View all merchants and their verification status

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/merchants` | List all merchants |
| GET | `/api/admin/merchants/pending` | List merchants pending verification |
| PATCH | `/api/admin/merchants/:id/verify` | Approve or reject a merchant |

### Page Sections
- **Tab Bar:** All Merchants | Pending Approvals
- **Merchants Table:** Full list with status filters
- **Verification Action:** Approve/Reject buttons for pending merchants

### Components Needed
- `TabBar` — All / Pending tabs
- `DataTable` — paginated merchants table
- `VerificationBadge` — pending(yellow) / under-review(blue) / approved(green) / rejected(red)
- `VerifyModal` — approve/reject form

### Table Columns
| Column | Source Field | Notes |
|--------|-------------|-------|
| Business Name | `businessName` | Required, trimmed |
| Owner Name | `name` | Required |
| Email | `email` | Unique, lowercase |
| Phone | `phone` | Unique |
| Type | `merchantType` | Enum: home-grower / organic-farmer / local-farmer |
| Status | `verificationStatus` | Enum: pending / under-review / approved / rejected |
| Rating | `averageRating` | 0-5 stars |
| Total Orders | `totalOrders` | Number |
| Joined | `createdAt` | Date |
| Actions | — | View / Verify buttons |

### Forms & Inputs (Verify Modal)
| Field | Type | Validation |
|-------|------|------------|
| status | Dropdown | Required: "approved" or "rejected" |
| rejectionReason | Textarea | Required when status is "rejected" |

### Actions
| Button | Action |
|--------|--------|
| Approve | `PATCH /api/admin/merchants/:id/verify` with `{ status: "approved" }` |
| Reject | `PATCH /api/admin/merchants/:id/verify` with `{ status: "rejected", rejectionReason }` |
| View | Navigate to `/merchants/:id` |

### States to Handle
- **Loading:** Table shimmer
- **Empty (Pending tab):** "No pending merchant applications"
- **Error:** Error banner with retry
- **Success:** Toast "Merchant approved/rejected"

---

---

## Page 5: Merchant Detail

- **URL:** `/merchants/:id`
- **Purpose:** Full merchant profile view

### Page Sections
- **Header:** Business name, type badge, verification status badge
- **Profile Info Card:** name, email, phone, address, location coordinates
- **Business Details Card:** FSSAI license, GST number, PAN number, certifications
- **Documents Section:** List of uploaded documents with status (pending/verified/rejected/expired)
- **Operating Hours:** Weekly schedule grid
- **Delivery Settings:** deliveryRadius, minimumOrderValue, deliveryCharges, freeDeliveryAbove
- **Delivery Zones Table:** name, radiusKm, deliveryCharge, minimumOrder, estimatedDeliveryTime, isActive
- **Bank Details Card:** accountHolderName, accountNumber, ifscCode, bankName, branch
- **Metrics Card:** totalOrders, totalRevenue, averageRating, totalReviews
- **Badges:** List of earned badges (verified, organic-certified, premium-seller, top-rated, fast-delivery)

### Components Needed
- `InfoCard` — labeled key-value pairs
- `DocumentRow` — document type, URL, status badge, verify action
- `ScheduleGrid` — 7-day open/close time display
- `DeliveryZoneTable` — zones data table
- `BadgeChip` — colored badge chips
- `MetricCard` — number + label stat display

---

---

## Page 6: Category Management

- **URL:** `/categories`
- **Purpose:** CRUD categories

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/categories` | List all categories |
| GET | `/api/categories/:id` | Get category by ID |
| POST | `/api/categories` | Create category (Admin) |
| PUT | `/api/categories/:id` | Update category (Admin) |
| DELETE | `/api/categories/:id` | Delete category (Admin) |

### Page Sections
- **Categories Grid/List:** All categories with icons/images
- **Add Category Button:** Opens create modal
- **Edit/Delete Actions:** Per-category inline actions

### Components Needed
- `CategoryCard` — image/icon + name + description + subcategories count
- `CategoryFormModal` — create/edit form
- `DeleteConfirmModal` — "Are you sure?"

### Forms & Inputs (Create/Edit)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text input | Required, unique | `Category.name` |
| description | Textarea | Optional | `Category.description` |
| image | Image URL / Upload | Optional | `Category.image` |
| icon | Icon URL | Optional | `Category.icon` |
| subCategories | Tag input (array of strings) | Optional | `Category.subCategories` |
| isActive | Toggle | Default: true | `Category.isActive` |

### Actions
| Button | Action |
|--------|--------|
| Add Category | Opens form modal → `POST /api/categories` |
| Edit | Opens form modal pre-filled → `PUT /api/categories/:id` |
| Delete | Confirm → `DELETE /api/categories/:id` |

### States to Handle
- **Loading:** Grid skeleton
- **Empty:** "No categories yet. Create your first one!"
- **Error:** Error toast / banner
- **Success:** Toast "Category created/updated/deleted"

---

---

## Page 7: All Orders

- **URL:** `/orders`
- **Purpose:** View all platform orders

### Page Sections
- **Status Filter Tabs:** All / Pending / Confirmed / Preparing / Out for Delivery / Delivered / Cancelled
- **Orders Table:** Paginated, searchable
- **Date Range Filter:** Filter by order date

### Table Columns
| Column | Source Field | Notes |
|--------|-------------|-------|
| Order ID | `orderId` | Format: GBxxxxxxx |
| Customer | `customer.name` | From User ref |
| Merchant | `merchant.businessName` | From Merchant ref |
| Items | `items.length` | Number of items |
| Total | `totalAmount` | Currency |
| Payment | `paymentMethod` | Enum: cod/online/wallet |
| Payment Status | `paymentStatus` | pending/completed/failed/refunded/paid |
| Order Status | `status` | Color-coded badge |
| Delivery Type | `deliveryType` | home-delivery / pickup |
| Date | `orderedAt` | Date + time |
| Actions | — | View Detail link |

### Filters & Search
| Filter | Backend Support | Notes |
|--------|----------------|-------|
| Status | `status` enum | Tab-based or dropdown |
| Payment Status | `paymentStatus` enum | Dropdown filter |
| Date Range | `orderedAt` | Date picker range |
| Search | `orderId` or `customer.name` | Text input |

---

---

## Page 8: Order Detail

- **URL:** `/orders/:id`
- **Purpose:** Full order information, tracking, assignment

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/orders/:id` | Get full order |
| GET | `/api/orders/:id/track` | Enhanced tracking info |
| GET | `/api/orders/:orderId/tracking` | Tracking status |
| POST | `/api/admin/orders/:orderId/assign-agent` | Assign delivery agent |

### Page Sections
- **Order Header:** orderId, status badge, creation date, delivery type
- **Customer Info Card:** name (from User), delivery address (from Address ref), delivery instructions
- **Merchant Info Card:** businessName, merchant contact
- **Items Table:** product name, price, quantity, unit, preparation type, subtotal
- **Pricing Breakdown Card:** itemsTotal, deliveryCharges, discount, couponDiscount, giftCardApplied, totalAmount
- **Payment Info Card:** paymentMethod, paymentStatus, Stripe paymentIntentId, chargeId, cardLast4, upiVpa
- **Status Timeline:** statusHistory array rendered as vertical timeline with timestamps and notes
- **Delivery Assignment Card:** assigned driver info, current location, estimated delivery time
- **Delivery Tracking Map:** Real-time location from deliveryPersonnel.currentLocation
- **Refund Section:** refund status, stripeRefundId, amount, reason, dates
- **Cancellation Info:** cancellationReason, cancelledBy, cancelledAt
- **Actions Panel:** Assign Agent button

### Components Needed
- `OrderStatusTimeline` — vertical step timeline from `statusHistory[]`
- `ItemsTable` — product items list
- `PricingBreakdown` — labeled price rows with total
- `PaymentInfoCard` — payment gateway details
- `DeliveryMap` — map component showing live location
- `AssignAgentModal` — select available agent dropdown

### Forms & Inputs (Assign Agent Modal)
| Field | Type | Validation |
|-------|------|------------|
| agentId | Dropdown (select from available agents) | Required |

### Items Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Product | `items[].name` | String |
| Price | `items[].price` | Currency |
| Qty | `items[].quantity` | Number, min 1 |
| Unit | `items[].unit` | String |
| Prep | `items[].preparation` | Enum: whole/cut/chopped/diced/sliced |
| Subtotal | `items[].subtotal` | Currency |

---

---

## Page 9: Recipe Management

- **URL:** `/recipes`
- **Purpose:** View, create, edit, delete recipes (admin-only CRUD)

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/recipes` | Get all recipes |
| GET | `/api/recipes/search` | Search recipes |
| GET | `/api/recipes/:id` | Get recipe by ID |
| GET | `/api/recipes/:id/calculate-ingredients` | Calculate ingredient amounts per servings |
| POST | `/api/recipes` | Create recipe (Admin) |
| PUT | `/api/recipes/:id` | Full update recipe (Admin) |
| PATCH | `/api/recipes/:id` | Partial update recipe (Admin) |
| DELETE | `/api/recipes/:id` | Delete recipe (Admin) |

### Page Sections
- **Recipe List:** Grid/list of all recipes with image, title, difficulty badge
- **Search Bar:** Search by title/ingredient
- **Add Recipe Button:** Opens create form
- **Recipe Detail View:** Full recipe info

### Components Needed
- `RecipeCard` — image, title, difficulty badge, prep time, servings
- `RecipeFormPage` — full-page form for create/edit
- `IngredientRow` — product reference + quantity + unit (repeatable)
- `StepList` — ordered list of cooking steps
- `DeleteConfirmModal`

### Forms & Inputs (Create/Edit Recipe)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| title | Text input | Required | `Recipe.title` |
| description | Textarea | Optional | `Recipe.description` |
| ingredients | Repeatable row: product (ref) + quantity (number) + unit (string) + name (string) | At least 1 required | `Recipe.ingredients[]` |
| steps | Repeatable text inputs (ordered list) | At least 1 required | `Recipe.steps[]` |
| difficulty | Dropdown | Required: easy/medium/hard | `Recipe.difficulty` |
| prepTime | Number | Optional (minutes) | `Recipe.prepTime` |
| cookTime | Number | Optional (minutes) | `Recipe.cookTime` |
| servings | Number | Optional | `Recipe.servings` |
| tags | Tag input | Optional | `Recipe.tags[]` |
| image | Image upload | Optional, uses uploadRecipeImage middleware | `Recipe.image` |
| isActive | Toggle | Default: true | `Recipe.isActive` |

---

---

## Page 10: Review Management

- **URL:** `/reviews`
- **Purpose:** View and moderate product/merchant reviews

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/reviews/product/:productId` | Get reviews for a product |
| GET | `/api/reviews/merchant/:merchantId` | Get reviews for a merchant |
| DELETE | `/api/reviews/:id` | Delete review (Admin) |

### Page Sections
- **Tab Bar:** By Product | By Merchant
- **Product/Merchant Selector:** Dropdown to pick product or merchant
- **Reviews List:** Cards showing rating, comment, customer name, date

### Components Needed
- `ReviewCard` — star rating, comment text, customer name, date, images, helpfulCount, merchant reply
- `ProductSelector` — searchable dropdown
- `MerchantSelector` — searchable dropdown
- `DeleteButton` — with confirmation

### Table/List Fields (Per Review)
| Field | Source | Notes |
|-------|--------|-------|
| Rating | `rating` | 1-5 stars, required |
| Comment | `comment` | Max 500 chars |
| Customer | `customer.name` | From User ref |
| Product | `product.name` | From Product ref (optional) |
| Images | `images[]` | Array of image URLs |
| Verified | `isVerified` | Boolean badge |
| Helpful | `helpfulCount` | Number |
| Merchant Reply | `merchantReply.comment` | Optional reply text |
| Date | `createdAt` | Timestamp |

### Actions
| Button | Action |
|--------|--------|
| Delete Review | Confirm → `DELETE /api/reviews/:id` |

---

---

## Page 11: Offers & Coupons

- **URL:** `/offers`
- **Purpose:** Manage platform-wide offers, coupons, flash sales

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/offers/admin/all` | Get all offers (Admin) |
| POST | `/api/offers` | Create offer (Admin) |
| PUT | `/api/offers/:id` | Update offer (Admin) |
| DELETE | `/api/offers/:id` | Delete offer (Admin) |
| GET | `/api/offers/:id/analytics` | Offer usage analytics |

### Page Sections
- **Offers Table:** All offers with status, type, dates
- **Create Offer Button:** Opens form modal/page
- **Analytics View:** Per-offer usage stats

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Title | `title` | Max 100 chars |
| Type | `type` | Enum: percentage/flat/bogo/free_delivery/bundle |
| Coupon Code | `couponCode` | Uppercase, optional |
| Discount | `discountPercentage` or `discountAmount` | Based on type |
| Max Cap | `maxDiscountCap` | Number |
| Min Order | `minOrderValue` | Number |
| Start | `startDate` | Date |
| End | `endDate` | Date |
| Flash Sale | `isFlashSale` | Boolean badge |
| Usage | `usedCount / totalUsageLimit` | "5/100" format |
| Status | `status` | Enum: active/inactive/expired/exhausted |
| Actions | — | Edit / Delete / Analytics |

### Forms & Inputs (Create/Edit Offer)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| title | Text | Required, max 100 | `Offer.title` |
| description | Textarea | Optional, max 500 | `Offer.description` |
| type | Dropdown | Required: percentage/flat/bogo/free_delivery/bundle | `Offer.type` |
| discountPercentage | Number | Required if type=percentage, 0-100 | `Offer.discountPercentage` |
| discountAmount | Number | Required if type=flat, min 0 | `Offer.discountAmount` |
| maxDiscountCap | Number | Optional | `Offer.maxDiscountCap` |
| applicableOn | Dropdown | Enum: all/categories/products | `Offer.applicableOn` |
| categories | Multi-select | If applicableOn=categories | `Offer.categories[]` |
| products | Multi-select | If applicableOn=products | `Offer.products[]` |
| minOrderValue | Number | Default 0 | `Offer.minOrderValue` |
| startDate | Date picker | Required | `Offer.startDate` |
| endDate | Date picker | Required, must be after startDate | `Offer.endDate` |
| isFlashSale | Toggle | Default false | `Offer.isFlashSale` |
| totalUsageLimit | Number | Optional | `Offer.totalUsageLimit` |
| usagePerUser | Number | Default 1, min 1 | `Offer.usagePerUser` |
| couponCode | Text | Optional, uppercase | `Offer.couponCode` |
| isPublic | Toggle | Default true | `Offer.isPublic` |

---

---

## Page 12: Financial — Payouts

- **URL:** `/finance/payouts`
- **Purpose:** Manage merchant payouts

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/financial/admin/payouts` | List all payouts |
| POST | `/api/financial/admin/payouts/generate` | Generate new payouts |
| POST | `/api/financial/admin/payouts/:id/process` | Process a payout |
| PATCH | `/api/financial/admin/payouts/:id/hold` | Hold/release a payout |
| GET | `/api/financial/payouts/:id` | Get payout detail |

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Payout ID | `payoutId` | Format: PAY-timestamp |
| Merchant | `merchant.businessName` | From Merchant ref |
| Period | `period.startDate` – `period.endDate` | Date range |
| Total Orders | `totalOrders` | Number |
| Gross Revenue | `grossRevenue` | Currency |
| Commission | `platformCommission.amount` | At rate `platformCommission.rate`% |
| Refunds | `refunds` | Currency |
| Net Amount | `netAmount` | Currency |
| Status | `status` | Enum: pending/processing/completed/failed/on_hold |
| Actions | — | Process / Hold / View Detail |

### Forms & Inputs (Generate Payouts)
| Field | Type | Validation |
|-------|------|------------|
| period | Dropdown | Required: weekly/biweekly/monthly |
| date | Date picker | Required |

### Actions
| Button | Action |
|--------|--------|
| Generate Payouts | `POST /api/financial/admin/payouts/generate` |
| Process | `POST /api/financial/admin/payouts/:id/process` |
| Hold | `PATCH /api/financial/admin/payouts/:id/hold` |
| Release | `PATCH /api/financial/admin/payouts/:id/hold` (toggle) |

---

---

## Page 13: Financial — Reports

- **URL:** `/finance/reports`
- **Purpose:** View financial and tax reports

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/financial/admin/reports/financial` | Financial summary report |
| GET | `/api/financial/admin/reports/gst` | GST/tax report |

### Page Sections
- **Financial Summary:** Revenue, commissions, refunds, net earnings
- **GST Report:** Tax collection breakdown
- **Charts:** Revenue trend line chart, commission pie chart

### Components Needed
- `ReportCard` — stat with label
- `LineChart` — revenue over time
- `PieChart` — commission by category
- `DownloadButton` — export to CSV/PDF

---

---

## Page 14: Financial — Commission Settings

- **URL:** `/finance/settings`
- **Purpose:** Configure platform commission rates

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/api/financial/admin/settings/commission` | Update commission settings |

### Forms & Inputs
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| defaultRate | Number (%) | Required | `PlatformSettings.commission.defaultRate` |
| premiumMerchantRate | Number (%) | Required | `PlatformSettings.commission.premiumMerchantRate` |
| byCategory | Repeatable: category (ref) + rate (number) | Optional | `PlatformSettings.commission.byCategory[]` |
| payoutSchedule | Dropdown | Enum: daily/weekly/biweekly/monthly | `PlatformSettings.payoutSchedule` |
| minimumPayoutAmount | Number | Required | `PlatformSettings.minimumPayoutAmount` |
| gstRate | Number (%) | Required | `PlatformSettings.taxSettings.gstRate` |
| gstNumber | Text | Optional | `PlatformSettings.taxSettings.gstNumber` |
| companyName | Text | Optional | `PlatformSettings.taxSettings.companyName` |

---

---

## Page 15: Dispute Management

- **URL:** `/disputes`
- **Purpose:** View and resolve customer disputes

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/disputes/admin/all` | List all disputes |
| GET | `/api/disputes/:id` | Get dispute detail |
| PUT | `/api/disputes/admin/:id/resolve` | Resolve dispute |
| PATCH | `/api/disputes/admin/:id/status` | Update dispute status |
| POST | `/api/disputes/:id/message` | Add message to conversation |

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Dispute ID | `disputeId` | Format: DISP-timestamp |
| Order | `order.orderId` | Linked to order |
| Raised By | `raisedBy.user.name` | User or Merchant |
| Category | `category` | Enum: product_quality/wrong_item/missing_item/damaged_item/late_delivery/payment_issue/refund_issue/other |
| Priority | `priority` | Enum: low/medium/high/urgent |
| Status | `status` | Enum: open/investigating/resolved/closed/escalated |
| Date | `createdAt` | Timestamp |
| Actions | — | View Detail |

### Filters & Search
| Filter | Values |
|--------|--------|
| Status | open / investigating / resolved / closed / escalated |
| Priority | low / medium / high / urgent |
| Category | product_quality / wrong_item / missing_item / etc. |

### Dispute Detail Page (`/disputes/:id`)
- **Conversation Thread:** List of messages from `conversation[]` with from user, message text, attachments, timestamp
- **Resolution Panel:** type (refund/replacement/partial_refund/compensation/no_action), amount, description

### Forms & Inputs (Resolve Modal)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| resolution.type | Dropdown | Required | Enum: refund/replacement/partial_refund/compensation/no_action |
| resolution.amount | Number | Required if refund type | `Dispute.resolution.amount` |
| resolution.description | Textarea | Required | `Dispute.resolution.description` |

### Forms & Inputs (Add Message)
| Field | Type | Validation |
|-------|------|------------|
| message | Textarea | Required |
| attachments | File upload (optional) | Images |

---

---

## Page 16: Return Management

- **URL:** `/returns`
- **Purpose:** View and process return/exchange requests

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/returns/admin/all` | List all returns |
| GET | `/api/returns/:id` | Get return detail |
| PUT | `/api/returns/admin/:id/process` | Process (approve/reject) return |

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Return ID | `returnId` | Format: RET-timestamp |
| Order | `order.orderId` | From Order ref |
| Customer | `user.name` | From User ref |
| Type | `type` | Enum: return / exchange |
| Reason | `reason` | Required string |
| Status | `status` | Enum: requested/approved/pickup_scheduled/picked_up/processed/refunded/rejected |
| Refund Amount | `refundAmount` | Currency (if applicable) |
| Date | `createdAt` | Timestamp |
| Actions | — | View / Process |

### Return Detail Sections
- **Items List:** product name, quantity, reason, condition (unopened/opened/damaged/wrong_item)
- **Images:** uploaded proof images
- **Exchange Items:** If type=exchange, list of requested exchange products

### Forms & Inputs (Process Return)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| status | Dropdown | Required: approved/rejected | — |
| refundAmount | Number | Required if approving | `Return.refundAmount` |
| refundMethod | Dropdown | wallet / original_payment | `Return.refundMethod` |
| adminNotes | Textarea | Optional | `Return.adminNotes` |
| rejectionReason | Textarea | Required if rejecting | `Return.rejectionReason` |

---

---

## Page 17: Gift Card Management

- **URL:** `/gift-cards`
- **Purpose:** Generate and manage gift cards

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/gift-cards/admin/all` | List all gift cards |
| POST | `/api/gift-cards/admin/generate` | Generate new gift card |
| PATCH | `/api/gift-cards/admin/:id/toggle` | Toggle gift card status |
| DELETE | `/api/gift-cards/admin/:id/cancel` | Cancel gift card |
| GET | `/api/gift-cards/balance/:code` | Check gift card balance |

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Code | `code` | Uppercase, unique |
| Type | `type` | Enum: gift_card / voucher / promotional |
| Original Amount | `originalAmount` | Currency |
| Remaining | `amount` | Currency |
| Status | `status` | Enum: active / used / expired / cancelled |
| Expiry | `expiryDate` | Date |
| Purchased By | `purchasedBy.name` | From User ref |
| Purchased For | `purchasedFor` | Email/phone string |
| Redeemed By | `redeemedBy.name` | From User ref |
| Actions | — | Toggle / Cancel |

### Forms & Inputs (Generate Gift Card)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| amount | Number | Required, min 0 | `GiftCard.amount` |
| expiryDate | Date picker | Required | `GiftCard.expiryDate` |
| purchasedFor | Text (email/phone) | Optional | `GiftCard.purchasedFor` |
| message | Textarea | Optional | `GiftCard.message` |
| type | Dropdown | Default: gift_card | Enum: gift_card/voucher/promotional |
| minOrderValue | Number | Default 0 | `GiftCard.minOrderValue` |

---

---

## Page 18: Membership Management

- **URL:** `/memberships`
- **Purpose:** View all user memberships

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/membership/admin/all` | List all memberships |

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| User | `user.name` | From User ref |
| Plan | `plan` | Enum: basic / premium / premium_plus |
| Status | `status` | Enum: active / cancelled / expired |
| Start Date | `startDate` | Date |
| End Date | `endDate` | Date |
| Auto Renew | `autoRenew` | Boolean |
| Stripe Sub ID | `stripeSubscriptionId` | String |

---

---

## Page 19: Pre-Booking Management

- **URL:** `/pre-bookings`
- **Purpose:** View all seasonal product pre-bookings

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/prebooking/admin/all` | List all pre-bookings |

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| User | `user.name` | From User ref |
| Product | `product.name` | From Product ref |
| Merchant | `merchant.businessName` | From Merchant ref |
| Quantity | `quantity` | Number, min 1 |
| Expected Availability | `expectedAvailability` | Date |
| Status | `status` | Enum: pending / available / ordered / cancelled / expired |
| Notify | `notifyWhenAvailable` | Boolean |
| Converted Order | `convertedToOrder` | Order ref if converted |
| Date | `createdAt` | Timestamp |

---

---

## Page 20: Document Verification

- **URL:** `/documents`
- **Purpose:** Verify merchant-uploaded business documents

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/documents/admin/pending` | Get pending documents |
| PUT | `/api/documents/admin/:merchantId/:documentId/verify` | Approve/reject document |
| GET | `/api/documents/admin/expiring-soon` | Get documents expiring soon |

### Page Sections
- **Tab Bar:** Pending Verification | Expiring Soon
- **Documents Table:** Document info with verify actions

### Table Columns (Pending)
| Column | Source | Notes |
|--------|--------|-------|
| Merchant | `merchant.businessName` | From Merchant ref |
| Document Type | `documents[].type` | Enum: fssai/gst/pan/aadhaar/bank_details/organic_certificate/farm_ownership/other |
| Document Number | `documents[].documentNumber` | String |
| Document URL | `documents[].documentUrl` | Link to view |
| Expiry Date | `documents[].expiryDate` | Date |
| Status | `documents[].status` | pending / verified / rejected / expired |
| Uploaded At | `documents[].uploadedAt` | Date |
| Actions | — | Verify / Reject |

### Forms & Inputs (Verify Modal)
| Field | Type | Validation |
|-------|------|------------|
| status | Dropdown | Required: "approved" or "rejected" |
| comment | Textarea | Optional notes |
| rejectionReason | Textarea | Required if rejecting |

---

---

## Page 21: Delivery Agent Management

- **URL:** `/agents`
- **Purpose:** Manage delivery agents

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/agents` | List all agents |
| GET | `/api/admin/agents/analytics` | Agent performance analytics |
| GET | `/api/admin/agents/:id` | Get agent detail |
| GET | `/api/admin/agents/:id/assignments` | Assignment history |
| PATCH | `/api/admin/agents/:id/verify` | Verify/approve agent |
| PATCH | `/api/admin/agents/:id/toggle-active` | Activate/deactivate agent |

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Name | `name` | Required |
| Email | `email` | Unique |
| Phone | `phone` | Required |
| Vehicle | `vehicleType` | Enum: bike / scooter / van / truck |
| Vehicle # | `vehicleNumber` | Uppercase |
| Status | `status` | Enum: available / busy / offline |
| Rating | `rating` | 0-5, default 5.0 |
| Deliveries | `totalDeliveries` | Number |
| Earnings | `totalEarnings` | Currency |
| Verified | `isVerified` | Boolean badge |
| Active | `isActive` | Boolean badge |
| Actions | — | View / Verify / Toggle Active |

### Agent Detail Page (`/agents/:id`)
- **Profile Card:** name, email, phone, photo, vehicle info, license number
- **Stats Card:** rating, totalDeliveries, totalEarnings
- **Verification Documents:** type (license/vehicle_registration/id_proof/address_proof), URL, upload date, verified date
- **Assignment History Table:** order, status (assigned/picked_up/in_transit/delivered/failed/cancelled), assignedAt, deliveredAt, duration, deliveryFee

---

---

## Page 22: Wallet Admin Controls

- **URL:** `/wallets`
- **Purpose:** Admin wallet operations

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/wallet/admin/credit` | Credit money to user wallet |
| PATCH | `/api/wallet/admin/:userId/lock` | Lock/unlock user wallet |
| POST | `/api/wallet/credit-refund` | Process refund to wallet |

### Components Needed
- `CreditWalletForm` — select user + amount + reason
- `LockWalletAction` — toggle with reason input

### Forms & Inputs (Credit Wallet)
| Field | Type | Validation |
|-------|------|------------|
| userId | User search/select | Required |
| amount | Number | Required, min > 0 |
| reason | Textarea | Required |

---

---

## Page 23: Loyalty Management

- **URL:** `/loyalty`
- **Purpose:** Award loyalty points to users

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/loyalty/admin/award-points` | Award points to a user |

### Forms & Inputs
| Field | Type | Validation |
|-------|------|------------|
| userId | User search/select | Required |
| points | Number | Required, min > 0 |
| reason | Textarea | Required (e.g., "Promotional event") |

### Related User Model Fields
- `loyaltyPoints` — current balance
- `loyaltyTier` — bronze / silver / gold / platinum
- `pointsHistory[]` — type (earned/redeemed/expired/bonus), points, source (order/review/referral/birthday/redemption/expiry)

---

---

## Page 24: Notification Center

- **URL:** `/notifications`
- **Purpose:** Send notifications to users

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/notifications/admin/test` | Send test notification to single user |
| POST | `/api/notifications/admin/bulk-send` | Bulk send notifications |

### Forms & Inputs (Send Test)
| Field | Type | Validation |
|-------|------|------------|
| userId | User search/select | Required |
| title | Text | Required |
| message | Textarea | Required |
| type | Dropdown | Enum from Notification model: order/offer_available/flash_sale/etc. |
| priority | Dropdown | low / medium / high / urgent |

### Forms & Inputs (Bulk Send)
| Field | Type | Validation |
|-------|------|------------|
| userIds | Multi-select or "All Users" toggle | Required |
| title | Text | Required |
| message | Textarea | Required |
| type | Dropdown | Same enum as above |

---

---

## Page 25: Upload Management

- **URL:** `/uploads`
- **Purpose:** View and manage uploaded files

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/upload/image` | Upload single image |
| POST | `/api/upload/images` | Upload multiple images |
| POST | `/api/upload/document` | Upload document |
| GET | `/api/upload/my-uploads` | View all uploads |
| GET | `/api/upload/:uploadId` | Get upload detail |
| DELETE | `/api/upload/:uploadId` | Delete upload |
| POST | `/api/upload/bulk-delete` | Bulk delete uploads |

### Components Needed
- `UploadGrid` — grid of uploaded images/documents with thumbnails
- `UploadButton` — drag-and-drop or file picker
- `BulkDeleteAction` — multi-select and delete
- `UploadDetailModal` — view full-size image/document

---

---

## Global Components (Shared Across All Pages)

### Sidebar Navigation
- Dashboard
- Users
- Merchants (with badge for pending count)
- Products
- Categories
- Orders (with badge for pending count)
- Recipes
- Reviews
- Subscriptions
- Notifications
- Offers & Coupons
- Finance (expandable: Payouts / Reports / Settings)
- Wallets
- Loyalty
- Referrals
- Disputes (with badge for open count)
- Returns
- Gift Cards
- Memberships
- Pre-Bookings
- Documents (with badge for pending count)
- Delivery Agents
- Uploads

### Top Navbar
- Global Search Bar (backed by `/api/search`)
- Notification Bell
- Admin Profile dropdown (Logout)

### Shared Components
| Component | Usage |
|-----------|-------|
| `DataTable` | Every list page — sortable, paginated, filterable |
| `StatusBadge` | Color-coded status chips used everywhere |
| `ConfirmationModal` | Delete, block, cancel actions |
| `FormModal` | Create/edit popups |
| `Toast` | Success/error feedback |
| `EmptyState` | Illustrated empty state with message |
| `LoadingSkeleton` | Shimmer effect for all loading states |
| `ErrorState` | Error message with retry button |
| `DateRangePicker` | Date filtering |
| `SearchInput` | Debounced search |
| `StatCard` | Number + label cards |
| `Breadcrumbs` | Page navigation trail |

---

---

# PART B — MERCHANT PANEL PAGES

---

## Page M1: Merchant Auth (Signup + Login)

- **URL:** `/signup`, `/login`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/merchant/signup` | Register merchant |
| POST | `/api/auth/merchant/login` | Login merchant |

### Forms & Inputs (Signup)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Required, trimmed | `Merchant.name` |
| email | Email | Required, unique, lowercase | `Merchant.email` |
| phone | Text | Required, unique | `Merchant.phone` |
| password | Password | Required, min 6 | `Merchant.password` |
| businessName | Text | Required, trimmed | `Merchant.businessName` |
| merchantType | Dropdown | Required: home-grower / organic-farmer / local-farmer | `Merchant.merchantType` |
| businessDescription | Textarea | Optional, max 500 | `Merchant.businessDescription` |

### Forms & Inputs (Login)
| Field | Type | Validation |
|-------|------|------------|
| email | Email | Required |
| password | Password | Required |

---

## Page M2: Merchant Dashboard

- **URL:** `/dashboard`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/merchants/dashboard-stats` | Dashboard statistics |
| PATCH | `/api/merchants/toggle-store` | Toggle store open/closed |

### Page Sections
- **Stats Cards:** Total orders, revenue, active products, average rating
- **Store Toggle:** Open/Close with vacation mode option
- **Recent Orders:** Last 10 orders for this merchant

---

## Page M3: Merchant Profile

- **URL:** `/profile`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/merchants/profile` | Get merchant profile |
| PUT | `/api/merchants/profile` | Update profile |

### Forms & Inputs
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Required | `Merchant.name` |
| businessName | Text | Required | `Merchant.businessName` |
| businessDescription | Textarea | Max 500 | `Merchant.businessDescription` |
| phone | Text | Required | `Merchant.phone` |
| address.street | Text | Optional | `Merchant.address.street` |
| address.city | Text | Optional | `Merchant.address.city` |
| address.state | Text | Optional | `Merchant.address.state` |
| address.pincode | Text | Optional | `Merchant.address.pincode` |
| profileImage | Image upload | Optional | `Merchant.profileImage` |
| farmImages | Multi-image upload | Optional | `Merchant.farmImages[]` |
| operatingHours | 7-day grid (open/close/isOpen per day) | Optional | `Merchant.operatingHours` |
| deliveryRadius | Number (km) | Default 10 | `Merchant.deliveryRadius` |
| minimumOrderValue | Number | Default 0 | `Merchant.minimumOrderValue` |
| deliveryCharges | Number | Default 0 | `Merchant.deliveryCharges` |
| freeDeliveryAbove | Number | Optional | `Merchant.freeDeliveryAbove` |
| bankDetails.accountHolderName | Text | Optional | `Merchant.bankDetails.accountHolderName` |
| bankDetails.accountNumber | Text | Optional | `Merchant.bankDetails.accountNumber` |
| bankDetails.ifscCode | Text | Optional | `Merchant.bankDetails.ifscCode` |
| bankDetails.bankName | Text | Optional | `Merchant.bankDetails.bankName` |
| notificationSettings | Toggles (email, sms, newOrders, lowStock) | Optional | `Merchant.notificationSettings` |

### Sections
- **Vacation Mode:** isActive toggle, startDate, endDate, message

---

## Page M4: My Products

- **URL:** `/products`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products` | List merchant's products |
| POST | `/api/products` | Create product |
| PUT | `/api/products/:id` | Update product |
| DELETE | `/api/products/:id` | Delete product |
| PATCH | `/api/products/:id/stock` | Update stock |

### Forms & Inputs (Create/Edit Product)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Required, text-indexed | `Product.name` |
| description | Textarea | Required, max 1000 | `Product.description` |
| category | Dropdown (from categories) | Required | `Product.category` |
| subCategory | Text | Optional | `Product.subCategory` |
| price | Number | Required, min 0 | `Product.price` |
| comparePrice | Number | Optional (original price for discount display) | `Product.comparePrice` |
| unit | Dropdown | Enum: kg/g/piece/dozen/bundle/liter | `Product.unit` |
| stock | Number | Required, min 0 | `Product.stock` |
| lowStockThreshold | Number | Default 10 | `Product.lowStockThreshold` |
| tags | Multi-select | Enum: organic/farm-fresh/home-grown/seasonal/new-arrival/best-seller | `Product.tags[]` |
| preparationOptions | Repeatable: type(enum) + additionalPrice | Optional | `Product.preparationOptions[]` |
| images | Multi-image upload | Optional | `Product.images[]` |
| primaryImage | Image upload | Required | `Product.primaryImage` |
| nutritionalInfo | Group: calories, protein, carbs, fat, fiber, vitamins | Optional | `Product.nutritionalInfo` |
| origin | Group: farm, location, harvestDate | Optional | `Product.origin` |
| isSeasonal | Toggle | Default false | `Product.isSeasonal` |
| availableMonths | Multi-select numbers (1-12) | If seasonal | `Product.availableMonths[]` |
| isPremiumExclusive | Toggle | Default false | `Product.isPremiumExclusive` |
| isPreBookable | Toggle | Default false | `Product.isPreBookable` |
| expectedAvailabilityDate | Date picker | If pre-bookable | `Product.expectedAvailabilityDate` |

### Table Columns (Product List)
| Column | Source | Notes |
|--------|--------|-------|
| Image | `primaryImage` | Thumbnail |
| Name | `name` | Text-indexed |
| Category | `category.name` | From Category ref |
| Price | `price` | Currency |
| Stock | `stock` | Number, red if below threshold |
| Status | `status` | Enum: active/out-of-stock/coming-soon/discontinued |
| Rating | `averageRating` | Stars |
| Sales | `totalSales` | Number |
| Actions | — | Edit / Delete / Update Stock |

---

## Page M5: Bulk Operations

- **URL:** `/products/bulk`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/bulk/products/bulk-upload` | Bulk upload products (CSV/file) |
| PUT | `/api/bulk/products/bulk-update-price` | Bulk price update |
| PUT | `/api/bulk/products/bulk-update-stock` | Bulk stock update |
| GET | `/api/bulk/products/export` | Export products |

### Page Sections
- **Upload Tab:** File upload for bulk product import
- **Price Update Tab:** Select products → enter new prices
- **Stock Update Tab:** Select products → enter new stock values
- **Export Tab:** Download all products as CSV

---

## Page M6: Merchant Orders

- **URL:** `/orders`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/orders/merchant/orders` | Get merchant's orders |
| PATCH | `/api/orders/merchant/:id/status` | Update order status |

### Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Order ID | `orderId` | Format: GBxxxxxxx |
| Customer | `customer.name` | From User ref |
| Items | `items.length` | Count |
| Total | `totalAmount` | Currency |
| Status | `status` | Color-coded badge |
| Payment | `paymentMethod` | cod/online/wallet |
| Delivery | `deliveryType` | home-delivery / pickup |
| Date | `orderedAt` | Timestamp |
| Actions | — | Update Status button |

### Actions
| Button | Action |
|--------|--------|
| Confirm | `PATCH /api/orders/merchant/:id/status` → `{ status: "confirmed" }` |
| Preparing | `PATCH /api/orders/merchant/:id/status` → `{ status: "preparing" }` |
| Ready | `PATCH /api/orders/merchant/:id/status` → `{ status: "ready" }` |

---

## Page M7: Analytics

- **URL:** `/analytics`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/merchants/analytics/sales` | Sales analytics |
| GET | `/api/merchants/analytics/products` | Product performance analytics |
| GET | `/api/merchants/analytics/customers` | Customer analytics |
| GET | `/api/merchants/analytics/inventory` | Inventory analytics |
| GET | `/api/merchants/analytics/forecast` | Revenue forecast |
| GET | `/api/merchants/analytics/reviews` | Review analytics |

### Page Sections
- **Sales Tab:** Revenue charts, order volume, average order value
- **Products Tab:** Best sellers, lowest sellers, product views
- **Customers Tab:** New vs returning, top customers
- **Inventory Tab:** Stock levels, low stock alerts, out-of-stock items
- **Forecast Tab:** Revenue prediction line chart
- **Reviews Tab:** Rating distribution, recent reviews, reply rate

---

## Page M8: Delivery Zones

- **URL:** `/delivery-zones`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| PUT | `/api/merchants/zones/location` | Set store location |
| POST | `/api/merchants/zones/delivery-zones` | Create zone |
| PUT | `/api/merchants/zones/delivery-zones/:zoneId` | Update zone |
| DELETE | `/api/merchants/zones/delivery-zones/:zoneId` | Delete zone |
| POST | `/api/merchants/zones/check-serviceability` | Check if address is serviceable |

### Forms & Inputs (Create/Edit Zone)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Optional, trimmed | `Merchant.deliveryZones[].name` |
| radiusKm | Number | Required, 0.1-100 | `Merchant.deliveryZones[].radiusKm` |
| deliveryCharge | Number | Required, min 0 | `Merchant.deliveryZones[].deliveryCharge` |
| minimumOrder | Number | Default 0, min 0 | `Merchant.deliveryZones[].minimumOrder` |
| freeDeliveryAbove | Number | Optional, min 0 | `Merchant.deliveryZones[].freeDeliveryAbove` |
| estimatedDeliveryTime | Text | Default "30-45 mins" | `Merchant.deliveryZones[].estimatedDeliveryTime` |
| isActive | Toggle | Default true | `Merchant.deliveryZones[].isActive` |

### Forms & Inputs (Set Location)
| Field | Type | Validation |
|-------|------|------------|
| latitude | Number | Required |
| longitude | Number | Required |

---

## Page M9: Merchant Finance

- **URL:** `/finance`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/financial/merchants/earnings` | View earnings summary |
| GET | `/api/financial/merchants/payouts` | View payout history |
| GET | `/api/financial/payouts/:id` | View payout detail |

### Page Sections
- **Earnings Summary:** Total revenue, commission deducted, net earnings, pending payouts
- **Payouts Table:** Same columns as Admin payout table but filtered to this merchant

---

## Page M10: Merchant Offers

- **URL:** `/offers`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/offers/merchant` | My offers |
| POST | `/api/offers` | Create offer |
| PUT | `/api/offers/:id` | Update offer |
| DELETE | `/api/offers/:id` | Delete offer |
| GET | `/api/offers/:id/analytics` | Offer usage stats |

### Forms & Inputs
Same as Admin Offers form (Page 11 in Part A), but `createdBy` is auto-set to "merchant" and `merchant` is auto-set to current merchant ID.

---

## Page M11: Merchant Pre-Bookings

- **URL:** `/pre-bookings`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/prebooking/merchant/all` | List pre-bookings for this merchant |
| PATCH | `/api/prebooking/products/:id/mark-available` | Mark product as available |
| PATCH | `/api/prebooking/:id/update-status` | Update pre-booking status |
| PATCH | `/api/prebooking/merchant/products/:productId/prebooking` | Configure pre-booking settings |

---

## Page M12: Merchant Documents

- **URL:** `/documents`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/documents/upload` | Upload verification document |
| GET | `/api/documents` | View my documents |
| GET | `/api/documents/history` | View document history |
| DELETE | `/api/documents/:documentId` | Delete document |

### Forms & Inputs (Upload Document)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| type | Dropdown | Required: fssai/gst/pan/aadhaar/bank_details/organic_certificate/farm_ownership/other | `Merchant.documents[].type` |
| documentNumber | Text | Optional | `Merchant.documents[].documentNumber` |
| documentFile | File upload | Required | Uploaded to `documentUrl` |
| expiryDate | Date picker | Optional | `Merchant.documents[].expiryDate` |
| notes | Textarea | Optional, max 500 | `Merchant.documents[].notes` |

---

## Page M13: Merchant Subscriptions

- **URL:** `/subscriptions`
- **Backend:** `GET /api/subscriptions/merchant/all`
- **Purpose:** View recurring delivery subscriptions assigned to this merchant
- **Same table structure as admin subscriptions but filtered to this merchant**

---

## Page M14: Merchant Reviews

- **URL:** `/reviews`
- **Backend:** `GET /api/reviews/merchant/:merchantId`
- **Purpose:** View reviews left by customers, review analytics
- **Same card structure as admin review list**

---

## Page M15: Merchant Notifications

- **URL:** `/notifications`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/notifications` | Get notifications |
| GET | `/api/notifications/unread-count` | Unread count |
| PATCH | `/api/notifications/read-all` | Mark all read |
| PATCH | `/api/notifications/:id/read` | Mark one read |
| DELETE | `/api/notifications/:id` | Delete notification |
| DELETE | `/api/notifications/clear-all` | Clear all notifications |

### Notification Types (Merchant-relevant from Notification model)
- `new_order`, `low_stock`, `merchant_approved`, `payment_received`, `review_reminder`

---

---

# PART C — USER (CUSTOMER) PANEL PAGES

---

## Page U1: User Auth

- **URL:** `/login`, `/signup`, `/forgot-password`, `/verify-email`, `/reset-password`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/user/signup` | Register |
| POST | `/api/auth/user/login` | Login |
| POST | `/api/auth/user/verify-email` | Verify email |
| POST | `/api/auth/user/forgot-password` | Forgot password |
| POST | `/api/auth/user/reset-password` | Reset password |
| POST | `/api/auth/refresh-token` | Refresh JWT |
| POST | `/api/auth/logout` | Logout |

### Forms & Inputs (Signup)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Required, 2-50 chars | `User.name` |
| email | Email | Required, unique | `User.email` |
| phone | Text | Required, 10-digit | `User.phone` |
| password | Password | Required, min 6 | `User.password` |
| referralCode | Text | Optional (to apply referral) | `User.referral.referredBy` |

---

## Page U2: Home Page

- **URL:** `/home`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/categories` | All categories |
| GET | `/api/products` | Featured/all products |
| GET | `/api/search/trending` | Trending searches |
| GET | `/api/offers/flash-sales` | Active flash sales |

### Page Sections
- **Category Carousel:** Horizontal scrollable category icons
- **Flash Sale Banner:** Countdown timer for active flash sales
- **Featured Products Grid:** Product cards with image, name, price, rating
- **Trending Searches:** Suggestion chips

---

## Page U3: Product Listing & Search

- **URL:** `/products`, `/search`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products` | All products with filters |
| GET | `/api/products/search` | Search products |
| GET | `/api/search` | Full-text search |
| GET | `/api/search/suggestions` | Autocomplete suggestions |

---

## Page U4: Product Detail

- **URL:** `/products/:id`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products/:id` | Product detail |
| GET | `/api/reviews/product/:productId` | Product reviews |
| POST | `/api/cart/add` | Add to cart |
| POST | `/api/wishlist/add` | Add to wishlist |
| GET | `/api/wishlist/check/:productId` | Check if in wishlist |

### Page Sections
- **Image Gallery:** Product images carousel
- **Info Section:** Name, price (with compare price strikethrough), unit, tags, status
- **Preparation Options:** Select cut/whole/chopped/etc. with additional price
- **Nutritional Info:** Expandable section (calories, protein, carbs, fat, fiber, vitamins)
- **Origin Info:** Farm, location, harvest date
- **Quality Certifications:** name + document link
- **Reviews Section:** Recent reviews with ratings, option to view all
- **Add to Cart Button:** With quantity selector + preparation option
- **Add to Wishlist Button**

---

## Page U5: Cart

- **URL:** `/cart`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/cart` | Get cart |
| POST | `/api/cart/add` | Add item |
| PUT | `/api/cart/update/:productId` | Update quantity |
| DELETE | `/api/cart/remove/:productId` | Remove item |
| DELETE | `/api/cart/clear` | Clear cart |
| POST | `/api/cart/recipe-to-cart` | Add recipe ingredients to cart |
| POST | `/api/offers/cart/apply-coupon` | Apply coupon code |
| DELETE | `/api/offers/cart/remove-coupon` | Remove coupon |

### Page Sections
- **Cart Items List:** Product image, name, price, quantity stepper, preparation option, subtotal, remove button
- **Coupon Section:** Input field + Apply button, applied coupon display with remove
- **Price Summary:** Items total, delivery charges, discount, coupon discount, total
- **Checkout Button**

---

## Page U6: Checkout

- **URL:** `/checkout`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/addresses` | Get saved addresses |
| POST | `/api/orders` | Place order |
| POST | `/api/payment/create-order` | Create payment intent |
| POST | `/api/payment/verify` | Verify payment |
| GET | `/api/payment/methods` | Get available payment methods |

### Page Sections
- **Address Selection:** Saved addresses (radio list) + "Add New" button
- **Delivery Time Slot:** Date picker + time slot picker
- **Payment Method:** cod / online / wallet selection
- **Order Summary:** Items, pricing breakdown
- **Special Requests:** Textarea for special instructions
- **Place Order Button**

---

## Page U7: My Orders

- **URL:** `/orders`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/orders/my-orders` | Get user's orders |

### Table/List Columns
| Column | Source | Notes |
|--------|--------|-------|
| Order ID | `orderId` | Clickable → Detail |
| Merchant | `merchant.businessName` | From Merchant ref |
| Items | `items.length` | Count |
| Total | `totalAmount` | Currency |
| Status | `status` | Color badge |
| Date | `orderedAt` | Relative time |

---

## Page U8: Order Detail & Tracking

- **URL:** `/orders/:id`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/orders/:id` | Full order |
| GET | `/api/orders/:id/track` | Enhanced tracking |
| GET | `/api/orders/:orderId/tracking` | Tracking status |
| PATCH | `/api/orders/:id/cancel` | Cancel order |
| PATCH | `/api/orders/:id/location` | Update delivery location |

### Page Sections
- **Status Timeline:** Visual timeline from `statusHistory[]`
- **Live Tracking Map:** If out-for-delivery, show real-time driver location
- **Items List:** Product names, qty, subtotals
- **Pricing Breakdown:** Full price details
- **Cancel Button:** Only if status is `pending` or `confirmed`
- **Payment Info:** Method, status, transaction ID

---

## Page U9: Recipes

- **URL:** `/recipes`, `/recipes/:id`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/recipes` | Browse recipes |
| GET | `/api/recipes/search` | Search recipes |
| GET | `/api/recipes/:id` | Recipe detail |
| GET | `/api/recipes/:id/calculate-ingredients` | Calculate for servings |
| POST | `/api/cart/recipe-to-cart` | Add all ingredients to cart |

### Page Sections (Detail)
- **Recipe Header:** Image, title, difficulty badge, prep time, cook time, servings
- **Servings Adjuster:** Number input → recalculates ingredients via `/calculate-ingredients`
- **Ingredients List:** Product name, quantity, unit
- **Steps List:** Ordered numbered steps
- **"Add All to Cart" Button:** Adds calculated ingredients to cart

---

## Page U10: Wishlist

- **URL:** `/wishlist`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/wishlist` | Get wishlist |
| POST | `/api/wishlist/add` | Add to wishlist |
| DELETE | `/api/wishlist/remove/:productId` | Remove |
| POST | `/api/wishlist/move-to-cart/:productId` | Move to cart |
| GET | `/api/wishlist/check/:productId` | Check if wishlisted |

---

## Page U11: Profile & Addresses

- **URL:** `/profile`, `/profile/addresses`, `/profile/notifications`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users/profile` | Get profile |
| PUT | `/api/users/profile` | Update profile |
| GET | `/api/users/addresses` | Get addresses |
| POST | `/api/users/addresses` | Add address |
| PUT | `/api/users/addresses/:id` | Update address |
| DELETE | `/api/users/addresses/:id` | Delete address |
| GET | `/api/users/notification-preferences` | Get notification prefs |
| PUT | `/api/users/notification-preferences` | Update notification prefs |
| POST | `/api/users/fcm-token` | Register FCM token |

### Forms & Inputs (Edit Profile)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Required, 2-50 | `User.name` |
| phone | Text | Required, 10-digit | `User.phone` |
| profileImage | Image upload | Optional | `User.profileImage` |
| dietaryPreferences | Multi-select | Enum: vegetarian/vegan/non-vegetarian/gluten-free/organic-only | `User.dietaryPreferences[]` |
| allergies | Tag input | Optional array of strings | `User.allergies[]` |

### Forms & Inputs (Add/Edit Address)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| label | Dropdown | Enum: home/office/other | `Address.label` |
| name | Text | Optional | `Address.name` |
| phone | Text | Optional | `Address.phone` |
| addressLine1 | Text | Required | `Address.addressLine1` |
| addressLine2 | Text | Optional | `Address.addressLine2` |
| landmark | Text | Optional | `Address.landmark` |
| city | Text | Required | `Address.city` |
| state | Text | Required | `Address.state` |
| pincode | Text | Required, 6-digit | `Address.pincode` |
| isDefault | Toggle | Default false | `Address.isDefault` |

---

## Page U12: Wallet

- **URL:** `/wallet`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/wallet` | Get wallet balance |
| GET | `/api/wallet/transactions` | Transaction history |
| POST | `/api/wallet/add-money` | Initiate top-up |
| POST | `/api/wallet/verify-topup` | Verify top-up payment |
| POST | `/api/wallet/use-for-payment` | Use wallet for order payment |

### Page Sections
- **Balance Card:** Current balance with "Add Money" button
- **Transaction History:** List of credits/debits with source, amount, date, balanceBefore/After

---

## Page U13: Loyalty & Rewards

- **URL:** `/loyalty`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/loyalty/redeem` | Redeem points |
| GET | `/api/loyalty/history` | Points history |
| GET | `/api/loyalty/tier-benefits` | Tier info and benefits |

### Page Sections
- **Points Balance:** Current points + tier badge (bronze/silver/gold/platinum)
- **Tier Progress:** Progress bar to next tier
- **Benefits Card:** Current tier benefits (extraPointsPercentage, freeDeliveryThreshold, prioritySupport)
- **History List:** earned/redeemed/expired/bonus entries with source and date

---

## Page U14: Referrals

- **URL:** `/referrals`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/referral/generate` | Generate referral code |
| GET | `/api/referral/stats` | Referral stats |
| POST | `/api/referral/apply` | Apply someone's code |
| GET | `/api/referral/validate/:code` | Validate referral code |

### Page Sections
- **My Code Card:** Display referral code + share button + copy button
- **Stats Card:** Total referrals, completed, totalEarned
- **Referral List:** Each referral with status (pending/completed), rewardEarned, date

---

## Page U15: Membership

- **URL:** `/membership`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/membership/plans` | View available plans |
| GET | `/api/membership/my-membership` | Current membership |
| POST | `/api/membership/initiate` | Initiate purchase |
| POST | `/api/membership/activate` | Activate after payment |
| POST | `/api/membership/cancel` | Cancel membership |
| GET | `/api/membership/premium-products` | Browse premium-exclusive products |
| GET | `/api/membership/history` | Payment history |

### Page Sections
- **Plans Comparison:** basic vs premium vs premium_plus cards with pricing and benefits
- **Current Plan Card:** Active plan, expiry date, auto-renew toggle
- **Premium Products:** Grid of isPremiumExclusive products
- **Payment History:** Membership payment entries

---

## Page U16: Gift Cards

- **URL:** `/gift-cards`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/gift-cards/my-cards` | My gift cards |
| POST | `/api/gift-cards/purchase/initiate` | Buy gift card |
| POST | `/api/gift-cards/purchase/verify` | Verify purchase payment |
| POST | `/api/gift-cards/validate` | Validate code |
| POST | `/api/gift-cards/redeem` | Redeem to wallet |
| GET | `/api/gift-cards/balance/:code` | Check balance |

### Page Sections
- **Buy Gift Card:** Amount selector + recipient email/phone + message
- **My Cards List:** Cards with code, balance, status, expiry
- **Redeem Section:** Input code → validate → redeem

---

## Page U17: Pre-Bookings

- **URL:** `/pre-bookings`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/prebooking` | Create pre-booking |
| GET | `/api/prebooking/my-prebookings` | My pre-bookings |
| DELETE | `/api/prebooking/:id` | Cancel pre-booking |
| POST | `/api/prebooking/:id/convert-to-order` | Convert to order |

---

## Page U18: Subscriptions

- **URL:** `/subscriptions`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/subscriptions` | Create subscription |
| GET | `/api/subscriptions` | My subscriptions |
| GET | `/api/subscriptions/:id` | Detail |
| PUT | `/api/subscriptions/:id` | Update |
| DELETE | `/api/subscriptions/:id` | Delete |
| PATCH | `/api/subscriptions/:id/status` | Pause/resume/cancel |

### Forms & Inputs (Create/Edit Subscription)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Required | `Subscription.name` |
| merchant | Merchant selector | Required | `Subscription.merchant` |
| frequency | Dropdown | Enum: daily/weekly/bi-weekly/monthly | `Subscription.frequency` |
| items | Repeatable: product + quantity + preparation | At least 1 | `Subscription.items[]` |
| deliveryDay | Dropdown | Enum: monday–sunday | `Subscription.deliveryDay` |
| deliveryTime | Time picker | Optional | `Subscription.deliveryTime` |
| deliveryAddress | Address selector | Required | `Subscription.deliveryAddress` |
| startDate | Date picker | Required | `Subscription.startDate` |

---

## Page U19: Disputes & Returns

- **URL:** `/disputes`, `/returns`

### API Endpoints Used (Disputes)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/disputes` | Raise dispute |
| GET | `/api/disputes/my-disputes` | My disputes |
| GET | `/api/disputes/:id` | Dispute detail |
| POST | `/api/disputes/:id/message` | Add message |
| PATCH | `/api/disputes/:id/escalate` | Escalate dispute |

### Forms & Inputs (Raise Dispute)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| order | Order selector | Required | `Dispute.order` |
| category | Dropdown | Required: product_quality/wrong_item/missing_item/damaged_item/late_delivery/payment_issue/refund_issue/other | `Dispute.category` |
| description | Textarea | Required | `Dispute.description` |
| images | Multi-image upload | Optional | `Dispute.images[]` |

### API Endpoints Used (Returns)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/returns` | Request return |
| GET | `/api/returns/my-returns` | My returns |
| GET | `/api/returns/:id` | Return detail |
| DELETE | `/api/returns/:id` | Cancel return request |

### Forms & Inputs (Request Return)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| order | Order selector | Required | `Return.order` |
| type | Dropdown | Required: return / exchange | `Return.type` |
| reason | Textarea | Required | `Return.reason` |
| items | Repeatable: product + quantity + reason + condition | At least 1 | `Return.items[]` |
| images | Multi-image upload | Optional | `Return.images[]` |
| exchangeItems | If type=exchange: product + quantity | Required for exchange | `Return.exchangeItems[]` |

---

---

## Global Components Summary (All Panels)

| Component | Where Used |
|-----------|------------|
| `DataTable` | Every list page (sortable, paginated, filterable) |
| `StatusBadge` | Orders, merchants, disputes, returns, payouts, etc. |
| `ConfirmationModal` | Delete, block, cancel, logout actions |
| `FormModal` | Create/edit popups |
| `Toast/Snackbar` | Success/error feedback |
| `EmptyState` | Illustrated empty state with action CTA |
| `LoadingSkeleton` | Shimmer/skeleton for all loading states |
| `ErrorState` | Error message with retry button |
| `DateRangePicker` | Date filtering in tables |
| `SearchInput` | Debounced search with suggestions |
| `StatCard` | Dashboard and analytics pages |
| `Breadcrumbs` | Deep navigation trail |
| `Sidebar` | Main navigation (different per panel) |
| `Navbar` | Global search, notification bell, profile menu |
| `PricingBreakdown` | Cart, checkout, order detail |
| `StarRating` | Reviews, product cards |
| `ImageGallery` | Product detail, recipe detail |
| `MapWidget` | Delivery tracking, zone management, store location |
| `StatusStepper` | Delivery status progression (Agent panel) |
| `BottomNavBar` | Mobile navigation for Agent panel |

---

---

# PART D — DELIVERY AGENT PANEL PAGES

---

## Page D1: Agent Auth (Register + Login)

- **URL:** `/register`, `/login`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/agents/register` | Register new delivery agent |
| POST | `/api/agents/login` | Login |

### Forms & Inputs (Register)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Required, trimmed | `Driver.name` |
| email | Email | Required, unique, lowercase | `Driver.email` |
| password | Password | Required, min 6 | `Driver.password` (hashed via pre-save hook) |
| phone | Text | Required, unique | `Driver.phone` |
| vehicleType | Dropdown | Required: bike / scooter / van / truck | `Driver.vehicleType` |
| vehicleNumber | Text | Optional | `Driver.vehicleNumber` |
| licenseNumber | Text | Optional | `Driver.licenseNumber` |

### Forms & Inputs (Login)
| Field | Type | Validation |
|-------|------|------------|
| email | Email | Required |
| password | Password | Required |

### States to Handle
- **Pending Verification:** After registration, show "Your account is pending admin verification" message
- **Account Deactivated:** If `isActive` is false, show blocked message
- **Login Error:** Invalid credentials toast
- **Success:** Store JWT token (role=agent) → Navigate to Dashboard

---

## Page D2: Agent Dashboard

- **URL:** `/dashboard`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agents/assignments/current` | Get active delivery assignment |
| GET | `/api/agents/earnings` | Today's earnings summary |
| PUT | `/api/agents/me/status` | Toggle available/offline |

### Page Sections
- **Status Toggle Header:** Large available/offline toggle switch with status indicator
  - Cannot go available if `isVerified` is false (show warning)
- **Active Delivery Card:** Current assignment (if any) — order ID, merchant name, customer address, status stepper
  - If no active assignment: "No active deliveries. Waiting for new assignment..." card
- **Today's Earnings Card:** Total earnings today, number of deliveries, average per delivery
- **Quick Stats:** totalDeliveries, totalEarnings, rating, isVerified badge

### Components Needed
- `StatusToggle` — large prominent available/offline switch with color indication (green=available, gray=offline)
- `ActiveDeliveryCard` — card showing current delivery details with action buttons
- `EarningsCard` — stat card with earnings metrics
- `VerificationBanner` — "Pending verification" warning if not verified

---

## Page D3: Agent Profile

- **URL:** `/profile`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agents/me` | Get profile |
| PUT | `/api/agents/me` | Update profile |

### Forms & Inputs (Edit Profile)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| name | Text | Required | `Driver.name` |
| phone | Text | Required | `Driver.phone` |
| vehicleType | Dropdown | bike / scooter / van / truck | `Driver.vehicleType` |
| vehicleNumber | Text | Optional | `Driver.vehicleNumber` |
| licenseNumber | Text | Optional | `Driver.licenseNumber` |
| profilePhotoUrl | Image upload | Optional | `Driver.profilePhotoUrl` |

### Read-Only Display Fields
| Field | Source | Notes |
|-------|--------|-------|
| Email | `email` | Not editable after registration |
| Verification Status | `isVerified` | Boolean badge (Verified / Pending) |
| Active Status | `isActive` | Boolean badge (set by admin) |
| Rating | `rating` | Stars display, default 0 |
| Total Deliveries | `totalDeliveries` | Number |
| Total Earnings | `totalEarnings` | Currency |
| Current Status | `status` | available / busy / offline |
| Member Since | `createdAt` | Date |

### States to Handle
- **Loading:** Profile shimmer
- **Success:** Toast "Profile updated successfully"
- **Error:** Error toast

---

## Page D4: Current Assignment (Active Delivery)

- **URL:** `/assignments/current`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agents/assignments/current` | Get current active assignment with populated data |
| PUT | `/api/agents/assignments/:id/status` | Update delivery status |
| POST | `/api/agents/me/location` | Update GPS location (background) |

### Page Sections
- **Delivery Status Stepper:** Visual progress indicator showing `assigned → picked_up → in_transit → delivered`
- **Order Info Card:**
  - Order ID (`order.orderId`)
  - Total Amount (`order.totalAmount`)
  - Items list (`order.items[]` — name, quantity, unit)
  - Delivery Instructions (`order.deliveryInstructions`)
- **Customer Info Card:**
  - Name (`order.customer.name`)
  - Phone (`order.customer.phone`) — with tap-to-call button
- **Delivery Address Card:**
  - Full address (`order.deliveryAddress.fullAddress`, street, city, state, pincode)
  - Map showing delivery location with route
  - Navigate button (open in Google Maps / Apple Maps)
- **Action Buttons Panel:** Based on current status

### Action Buttons (Status Transitions)
| Current Status | Available Actions |
|---------------|-------------------|
| `assigned` | **Picked Up** button, **Report Issue** button |
| `picked_up` | **In Transit** button, **Report Issue** button |
| `in_transit` | **Delivered** button, **Report Issue** button |

### Forms & Inputs (Update Status)
| Field | Type | Validation | Source |
|-------|------|------------|--------|
| status | Action button | Required: picked_up / in_transit / delivered / failed | `DeliveryAssignment.status` |
| note | Textarea | Optional (required for failed) | Sent as body param |
| latitude | Number (auto from GPS) | Optional | Location tracking |
| longitude | Number (auto from GPS) | Optional | Location tracking |

### Forms & Inputs (Report Issue / Failed)
| Field | Type | Validation |
|-------|------|------------|
| note | Textarea | Required — reason for failure |

### States to Handle
- **No Assignment:** "No active deliveries" empty state with illustration
- **Loading:** Assignment card shimmer
- **Delivered Success:** Celebration animation + "Order delivered!" + auto-navigate to dashboard
- **Failed:** Confirmation dialog + reason input → assignment removed, driver goes back to available

---

## Page D5: Assignment History

- **URL:** `/assignments`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agents/assignments` | List all assignments (paginated) |
| GET | `/api/agents/assignments/:id` | Assignment detail |

### Table/List Columns (History)
| Column | Source | Notes |
|--------|--------|-------|
| Order ID | `order.orderId` | From populated Order ref |
| Total | `order.totalAmount` | Currency |
| Status | `status` | Enum: assigned/picked_up/in_transit/delivered/failed/cancelled |
| Delivery Fee | `deliveryFee` | Currency |
| Assigned At | `assignedAt` | Timestamp |
| Delivered At | `deliveredAt` | Timestamp (if delivered) |
| Distance | `actualDistance` | km (if tracked) |
| Actions | — | View Detail |

### Filters
| Filter | Values |
|--------|--------|
| Status | assigned / picked_up / in_transit / delivered / failed / cancelled |
| Date Range | startDate, endDate |

### Assignment Detail Page (`/assignments/:id`)
- **Order Details:** orderId, items, totalAmount, delivery address
- **Customer Info:** name, phone
- **Status History:** `statusHistory[]` — status, timestamp, location, note rendered as timeline
- **Delivery Metrics:** estimatedDistance, actualDistance, deliveryFee, assignedAt, pickedUpAt, deliveredAt
- **Notes:** Any failure or cancellation reasons
- **Location Trail:** Map showing pickup to delivery path (from `locationHistory[]`)

---

## Page D6: Earnings

- **URL:** `/earnings`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agents/earnings` | Get earnings with date filters |

### Page Sections
- **Summary Cards:**
  - Total Earnings (`totalEarnings`) — currency
  - Total Deliveries (`totalDeliveries`) — number
  - Average Per Delivery (`averagePerDelivery`) — currency
- **Date Range Filter:** startDate + endDate pickers
- **Earnings Breakdown Table:** List of delivered assignments with fee per delivery
- **Earnings Chart:** Bar chart of daily earnings over selected period

### Earnings Table Columns
| Column | Source | Notes |
|--------|--------|-------|
| Order ID | `order.orderId` | From assignment's populated order |
| Delivery Fee | `deliveryFee` | Currency |
| Distance | `actualDistance` | km |
| Delivered At | `deliveredAt` | Date + time |

---

## Page D7: Notifications

- **URL:** `/notifications`

### API Endpoints Used
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/notifications` | Get agent notifications |
| GET | `/api/notifications/unread-count` | Unread badge count |
| PATCH | `/api/notifications/read-all` | Mark all as read |
| PATCH | `/api/notifications/:id/read` | Mark one as read |
| DELETE | `/api/notifications/:id` | Delete notification |
| DELETE | `/api/notifications/clear-all` | Clear all |

### Notification Types (Agent-relevant)
- `new_assignment` — New delivery assigned
- `assignment_update` — Assignment status changed
- `earning_credited` — Delivery fee credited
- `account_verified` — Admin verified the account
- `account_deactivated` — Admin deactivated the account

### Components Needed
- `NotificationCard` — icon, title, message, timestamp, read/unread indicator
- `NotificationBadge` — unread count badge on nav bar bell icon

---

## Page D8: Verification Pending Screen

- **URL:** `/verification-pending`
- **Purpose:** Shown to agents whose `isVerified` is false after login
- **Content:**
  - Icon/illustration of pending verification
  - Message: "Your account is pending admin verification. You will be notified once approved."
  - Contact support link
  - Logout button
- **Note:** This is a blocking screen — agent cannot access Dashboard or go available until verified

---

---

## Global Components Summary (All 4 Panels)

| Component | Where Used |
|-----------|------------|
| `DataTable` | Every list page (sortable, paginated, filterable) |
| `StatusBadge` | Orders, merchants, disputes, returns, payouts, etc. |
| `ConfirmationModal` | Delete, block, cancel, logout actions |
| `FormModal` | Create/edit popups |
| `Toast/Snackbar` | Success/error feedback |
| `EmptyState` | Illustrated empty state with action CTA |
| `LoadingSkeleton` | Shimmer/skeleton for all loading states |
| `ErrorState` | Error message with retry button |
| `DateRangePicker` | Date filtering in tables |
| `SearchInput` | Debounced search with suggestions |
| `StatCard` | Dashboard and analytics pages |
| `Breadcrumbs` | Deep navigation trail |
| `Sidebar` | Main navigation (Admin, Merchant) |
| `Navbar` | Global search, notification bell, profile menu |
| `BottomNavBar` | Mobile navigation (Agent, User) |
| `PricingBreakdown` | Cart, checkout, order detail |
| `StarRating` | Reviews, product cards |
| `ImageGallery` | Product detail, recipe detail |
| `MapWidget` | Delivery tracking, zone management, store location, agent navigation |
| `StatusStepper` | Delivery status progression (Agent panel, Order tracking) |
| `StatusToggle` | Agent available/offline toggle |
| `VerificationBanner` | Agent pending verification alert |

---

## Final Totals

| Panel | Pages | Backend Endpoints |
|-------|-------|-------------------|
| Admin Panel | 25 pages | ~90 endpoints |
| Merchant Panel | 15 pages | ~55 endpoints |
| User Panel | 19 pages | ~76 endpoints |
| Delivery Agent Panel | 8 pages | ~17 endpoints |
| **Grand Total** | **67 pages** | **232+ endpoints** |

**All backend endpoints are mapped. All 28 Mongoose schemas are referenced.**
