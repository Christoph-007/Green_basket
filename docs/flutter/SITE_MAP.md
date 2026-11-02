# 🗺️ GreenBasket Flutter App - Site Map

## App Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GREENBASKET FLUTTER APP                           │
│                    (Multi-Role: User | Merchant | Admin)                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              AUTHENTICATION FLOW                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐               │
│   │ SplashScreen │────▶│  RoleSelect  │────▶│ Login Screen │               │
│   │              │     │   (User/     │     │   (Unified)  │               │
│   │  Logo +      │     │ Merchant/    │     │              │               │
│   │  Animation   │     │    Admin)    │     │  • Email     │               │
│   │              │     │              │     │  • Password  │               │
│   └──────────────┘     └──────────────┘     └──────────────┘               │
│                                                    │                        │
│                        ┌───────────────────────────┘                        │
│                        ▼                                                    │
│               ┌────────────────┐    ┌────────────────┐                     │
│               │  Signup Screen │◄──▶│  Forgot Pass   │                     │
│               │                │    │                │                     │
│               │  • User Info   │    │  • Email Input │                     │
│               │  • Phone       │    │  • OTP/Reset   │                     │
│               │  • Password    │    │                │                     │
│               │  • Role-based  │    └────────────────┘                     │
│               │    fields      │                                           │
│               └────────────────┘                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           CUSTOMER (USER) APP FLOW                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     MAIN NAVIGATION (BottomNav)                     │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │   Home   │ │ Categories│ │   Cart   │ │  Orders  │ │ Profile  │  │   │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘  │   │
│  │       │            │            │            │            │         │   │
│  └───────┼────────────┼────────────┼────────────┼────────────┼─────────┘   │
│          ▼            ▼            ▼            ▼            ▼             │
│  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │  HOME TAB    │ │CATEGORY  │ │ CART TAB │ │ORDERS TAB│ │ PROFILE TAB  │  │
│  │              │ │   TAB    │ │          │ │          │ │              │  │
│  │ • Banner     │ │          │ │• Items   │ │• Active   │ │• User Info   │  │
│  │ • Categories │ │• List    │ │• Coupons │ │• History  │ │• Addresses   │  │
│  │ • FlashSales │ │• Grid    │ │• Checkout│ │• Tracking │ │• Wallet      │  │
│  │ • Featured   │ │• Search  │ │• Payment │ │• Reorder  │ │• Loyalty     │  │
│  │ • Nearby     │ │• Filters │ │          │ │• Reviews  │ │• Referrals   │  │
│  │ • Recipes    │ │          │ │          │ │• Returns  │ │• Settings    │  │
│  └──────┬───────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│         │              │            │            │              │          │
│         ▼              ▼            ▼            ▼              ▼          │
│  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ProductDetail │ │Category  │ │ Checkout │ │Order     │ │  EditProfile │  │
│  │              │ │Detail    │ │          │ │Detail    │ │              │  │
│  │• Images      │ │          │ │• Address │ │• Status   │ │• Name/Email  │  │
│  │• Price/Stock │ │• Products│ │• TimeSlot│ │• Items    │ │• Phone       │  │
│  │• Add to Cart │ │• Filters │ │• Payment │ │• Tracking │ │• Preferences │  │
│  │• Reviews     │ │• Sort    │ │• Coupon  │ │• Invoice  │ │• Dietary     │  │
│  │• Merchant    │ │          │ │• Notes   │ │• Support  │ │• Allergies   │  │
│  │• Related     │ │          │ │          │ │          │ │              │  │
│  └──────────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│                                                                             │
│  OTHER SCREENS:                                                             │
│  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │   Recipe     │ │  Search  │ │  Wallet  │ │ Wishlist │ │ Notifications│  │
│  │   Detail     │ │  Results │ │          │ │          │ │              │  │
│  │              │ │          │ │• Balance │ │• Products│ │• List        │  │
│  │• Ingredients │ │• Filters │ │• History │ │• Move    │ │• Unread     │  │
│  │• Calculate   │ │• Sort    │ │• Add $   │ │  to Cart │ │• Settings    │  │
│  │• Add to Cart │ │• History │ │• Use     │ │          │ │              │  │
│  └──────────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│                                                                             │
│  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │   Referral   │ │  GiftCard│ │Membership│ │ Disputes │ │   Returns    │  │
│  │              │ │          │ │          │ │          │ │              │  │
│  │• Code/Share  │ │• Balance │ │• Plans   │ │• Raise   │ │• Request     │  │
│  │• Stats       │ │• Buy     │ │• Benefits│ │• History │ │• Status      │  │
│  │• Earnings    │ │• Redeem  │ │• Subscribe│ │• Messages│ │• Refund      │  │
│  └──────────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                          MERCHANT APP FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     MERCHANT NAVIGATION (BottomNav)                 │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │   │
│  │  │Dashboard │ │ Products │ │  Orders  │ │ Analytics│ │  Profile │  │   │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘  │   │
│  └───────┼────────────┼────────────┼────────────┼────────────┼─────────┘   │
│          ▼            ▼            ▼            ▼            ▼             │
│  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ DASHBOARD    │ │ PRODUCTS │ │  ORDERS  │ │ ANALYTICS│ │   PROFILE    │  │
│  │              │ │  TAB     │ │   TAB    │ │   TAB    │ │    TAB       │  │
│  │• Stats Cards │ │• List    │ │• New     │ │• Sales   │ │• Business    │  │
│  │• Recent Ord. │ │• Add/Edit│ │• Active  │ │• Products│ │  Info        │  │
│  │• Low Stock   │ │• Stock   │ │• History │ │• Customers│ │• Documents   │  │
│  │• Pending     │ │• Bulk    │ │• Status  │ │• Revenue │ │• Bank Details│  │
│  │  Verifications│  Upload  │ │• Assign  │ │• Forecast│ │• Settings    │  │
│  │• Alerts      │ │• Reviews │ │  Agent   │ │• Reviews │ │• Store Hours │  │
│  └──────┬───────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│         │              │            │            │              │          │
│         ▼              ▼            ▼            ▼              ▼          │
│  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ Add/Edit     │ │Product   │ │Order     │ │   Full   │ │DeliveryZones │  │
│  │ Product      │ │Detail    │ │Detail    │ │ Analytics│ │              │  │
│  │              │ │          │ │          │ │          │ │• Zone Map    │  │
│  │• Images      │ │• Stats   │ │• Items   │ │• Charts  │ │• Radius      │  │
│  │• Pricing     │ │• Edit    │ │• Customer│ │• Reports │ │• Charges     │  │
│  │• Inventory   │ │• Stock   │ │• Status  │ │• Export  │ │• Min Order   │  │
│  │• Categories  │ │• Reviews │ │• Update  │ │          │ │              │  │
│  │• Preparation │ │          │ │• Print   │ │          │ │              │  │
│  └──────────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│                                                                             │
│  OTHER MERCHANT SCREENS:                                                    │
│  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │   Offers/    │ │Document  │ │ Financial│ │ Payouts  │ │  Subscriptions│  │
│  │   Coupons    │ │Upload    │ │          │ │          │ │              │  │
│  │              │ │          │ │• Earnings│ │• History │ │• View        │  │
│  │• Create      │ │• FSSAI   │ │• Reports │ │• Request │ │• Manage      │  │
│  │• Analytics   │ │• GST     │ │• Invoices│ │• Status  │ │              │  │
│  │• Flash Sales │ │• Organic │ │• Tax     │ │          │ │              │  │
│  └──────────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                          ADMIN APP FLOW                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                       ADMIN NAVIGATION (Drawer/Nav)                 │   │
│  │                                                                     │   │
│  │  Dashboard │ Users │ Merchants │ Orders │ Products │ Finance │ More │   │
│  └─────┬──────┴───┬───┴─────┬─────┴───┬────┴────┬─────┴────┬────┴───┬──┘   │
│        ▼          ▼         ▼         ▼         ▼          ▼        ▼      │
│  ┌──────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │
│  │ DASHBOARD│ │ USERS  │ │MERCHANT│ │ ORDERS │ │PRODUCTS│ │ FINANCE│       │
│  │          │ │        │ │        │ │        │ │        │ │        │       │
│  │• Stats   │ │• List  │ │• Pending│ │• All   │ │• All   │ │• Payouts│      │
│  │• Charts  │ │• Block/ │ │  Verify │ │• Status │ │• Manage│ │• Reports│     │
│  │• Alerts  │ │  Unblock│ │• Approved│ │• Assign │ │• Categories│ │• GST   │      │
│  │• Recent  │ │• Search │ │• Documents│ │• Disputes│ │• Recipes │ │• Commission│   │
│  │  Activity│ │        │ │• Analytics│ │• Returns │ │• Featured │ │• Settings │   │
│  └────┬─────┘ └────┬───┘ └────┬───┘ └────┬───┘ └────┬───┘ └────┬───┘       │
│       │            │          │          │          │          │           │
│       ▼            ▼          ▼          ▼          ▼          ▼           │
│  ┌──────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │
│  │ AGENTS   │ │GIFT    │ │OFFERS  │ │MEMBERSHIP│ │BULK    │ │SETTINGS│       │
│  │          │ │CARDS   │ │        │ │PLANS    │ │OPS     │ │        │       │
│  │• All     │ │• Generate│ │• All   │ │• Plans  │ │• Upload │ │• General│      │
│  │• Verify  │ │• Manage  │ │• Flash  │ │• Pricing│ │• Export │ │• Payment│      │
│  │• Assign  │ │• Analytics│ │• Analytics│ │• Subscribers│ │• Update │ │• Notifications││
│  │• Track   │ │         │ │         │ │         │ │         │ │• Security│     │
│  └──────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                       DELIVERY AGENT APP FLOW                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    AGENT NAVIGATION (BottomNav)                     │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐               │   │
│  │  │ Current  │ │ History  │ │ Earnings │ │ Profile  │               │   │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘               │   │
│  └───────┼────────────┼────────────┼────────────┼──────────────────────┘   │
│          ▼            ▼            ▼            ▼                          │
│  ┌──────────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐              │
│  │ CURRENT JOB  │ │ HISTORY  │ │ EARNINGS │ │   PROFILE    │              │
│  │              │ │          │ │          │ │              │              │
│  │• Order Info  │ │• Past    │ │• Today   │ │• Personal    │              │
│  │• Customer    │ │  Orders  │ │• Weekly  │ │  Details     │              │
│  │  Details     │ │• Earnings │ │• Monthly │ │• Documents   │              │
│  │• Navigation  │ │• Stats    │ │• Total   │ │• Vehicle     │              │
│  │• Status Btn  │ │          │ │• Breakdown│ │• Status      │              │
│  │• Call/Chat   │ │          │ │          │ │• Settings    │              │
│  └──────────────┘ └──────────┘ └──────────┘ └──────────────┘              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Screen Details by Module

### 1. Authentication Module
| Screen | Route | Description |
|--------|-------|-------------|
| SplashScreen | `/splash` | App logo, loading animation |
| RoleSelect | `/select-role` | Choose User/Merchant/Admin/Agent |
| Login | `/login` | Unified login for all roles |
| Signup | `/signup` | Role-based registration |
| ForgotPassword | `/forgot-password` | Email-based password reset |
| VerifyEmail | `/verify-email` | Email verification screen |
| ResetPassword | `/reset-password` | New password input |

### 2. Customer Module (User)
| Screen | Route | Key Features |
|--------|-------|--------------|
| HomeScreen | `/home` | Banners, categories, flash sales, featured products |
| ProductList | `/products` | Grid/list view, filters, sorting |
| ProductDetail | `/product/:id` | Images, price, add to cart, reviews |
| CategoryScreen | `/category/:id` | Category products with filters |
| SearchScreen | `/search` | Search with suggestions, history |
| RecipeScreen | `/recipes` | Recipe list, ingredients calculator |
| RecipeDetail | `/recipe/:id` | Recipe details, add ingredients to cart |
| CartScreen | `/cart` | Cart items, coupon, checkout button |
| CheckoutScreen | `/checkout` | Address, timeslot, payment, notes |
| PaymentScreen | `/payment` | Payment methods, card/UPI/wallet |
| OrderSuccess | `/order-success` | Confirmation, order ID, track button |
| OrdersScreen | `/orders` | Tab: Active, History |
| OrderDetail | `/order/:id` | Items, status, tracking, invoice |
| OrderTracking | `/track/:id` | Real-time map tracking |
| ProfileScreen | `/profile` | User info, menu options |
| EditProfile | `/profile/edit` | Name, email, phone, image |
| AddressesScreen | `/addresses` | List, add, edit, delete addresses |
| AddAddress | `/address/add` | Map picker, address form |
| WalletScreen | `/wallet` | Balance, transactions, add money |
| LoyaltyScreen | `/loyalty` | Points, tier, benefits, history |
| ReferralScreen | `/referral` | Code, share, stats |
| WishlistScreen | `/wishlist` | Saved products, move to cart |
| Notifications | `/notifications` | Push notifications list |
| GiftCardScreen | `/gift-cards` | Balance, buy, redeem |
| MembershipScreen | `/membership` | Plans, benefits, subscribe |
| DisputesScreen | `/disputes` | Raise, track, message |
| ReturnsScreen | `/returns` | Request return, status |
| ReviewScreen | `/review/:orderId` | Rate and review order |

### 3. Merchant Module
| Screen | Route | Key Features |
|--------|-------|--------------|
| MerchantDashboard | `/merchant/dashboard` | Stats, recent orders, alerts |
| ProductsScreen | `/merchant/products` | Product list, search |
| AddProduct | `/merchant/product/add` | Multi-step product creation |
| EditProduct | `/merchant/product/:id/edit` | Edit product details |
| ProductStock | `/merchant/product/:id/stock` | Update inventory |
| BulkUpload | `/merchant/bulk-upload` | CSV upload products |
| MerchantOrders | `/merchant/orders` | New, preparing, ready, history |
| MerchantOrderDetail | `/merchant/order/:id` | Order info, status update |
| AnalyticsScreen | `/merchant/analytics` | Sales, products, customers charts |
| AnalyticsDetail | `/merchant/analytics/:type` | Detailed reports |
| OffersScreen | `/merchant/offers` | List, create offers |
| CreateOffer | `/merchant/offer/create` | Discount/flash sale setup |
| OfferAnalytics | `/merchant/offer/:id/analytics` | Offer performance |
| DocumentsScreen | `/merchant/documents` | Upload, view, status |
| UploadDocument | `/merchant/document/upload` | Document upload form |
| DeliveryZones | `/merchant/zones` | Map, radius, charges |
| EditZone | `/merchant/zone/:id/edit` | Zone configuration |
| FinancialScreen | `/merchant/financial` | Earnings, reports |
| PayoutsScreen | `/merchant/payouts` | Payout history, request |
| StoreSettings | `/merchant/settings` | Hours, notification, profile |
| Subscriptions | `/merchant/subscriptions` | View customer subscriptions |

### 4. Admin Module
| Screen | Route | Key Features |
|--------|-------|--------------|
| AdminDashboard | `/admin/dashboard` | Platform stats, charts |
| UsersScreen | `/admin/users` | User list, block/unblock |
| UserDetail | `/admin/user/:id` | User info, orders, actions |
| MerchantsScreen | `/admin/merchants` | Pending, approved list |
| VerifyMerchant | `/admin/merchant/:id/verify` | Review docs, approve/reject |
| MerchantAnalytics | `/admin/merchant/:id/analytics` | Merchant performance |
| AllOrders | `/admin/orders` | All orders, filters |
| AdminOrderDetail | `/admin/order/:id` | Full order management |
| DisputesAdmin | `/admin/disputes` | All disputes, resolve |
| ReturnsAdmin | `/admin/returns` | Process returns |
| ProductsAdmin | `/admin/products` | All products, manage |
| CategoriesAdmin | `/admin/categories` | Category management |
| CreateCategory | `/admin/category/create` | Add new category |
| RecipesAdmin | `/admin/recipes` | Recipe management |
| CreateRecipe | `/admin/recipe/create` | Add recipe |
| AgentsScreen | `/admin/agents` | Agent list, verify |
| AgentDetail | `/admin/agent/:id` | Agent info, assignments |
| AgentTrack | `/admin/agent/:id/track` | Live tracking |
| AssignOrder | `/admin/order/:id/assign` | Manual assignment |
| GiftCardsAdmin | `/admin/gift-cards` | Generate, manage |
| GenerateGiftCard | `/admin/gift-card/generate` | Create gift card |
| OffersAdmin | `/admin/offers` | All offers management |
| MembershipPlans | `/admin/membership/plans` | Create, edit plans |
| Subscribers | `/admin/membership/subscribers` | Premium members |
| PayoutsAdmin | `/admin/payouts` | Process payouts |
| CommissionSettings | `/admin/commission` | Set commission rates |
| BulkOpsAdmin | `/admin/bulk-operations` | Platform bulk actions |
| AdminSettings | `/admin/settings` | Platform configuration |
| NotificationsAdmin | `/admin/notifications` | Send bulk notifications |

### 5. Delivery Agent Module
| Screen | Route | Key Features |
|--------|-------|--------------|
| AgentDashboard | `/agent/dashboard` | Online toggle, current job |
| CurrentJob | `/agent/job/current` | Order details, actions |
| JobHistory | `/agent/jobs` | Completed deliveries |
| JobDetail | `/agent/job/:id` | Delivery details |
| NavigationScreen | `/agent/navigate/:orderId` | Map navigation to customer |
| AgentEarnings | `/agent/earnings` | Daily, weekly, monthly |
| EarningDetail | `/agent/earnings/:period` | Detailed breakdown |
| AgentProfile | `/agent/profile` | Personal info, documents |
| EditAgentProfile | `/agent/profile/edit` | Update details |
| AgentDocuments | `/agent/documents` | Upload verification docs |
| AgentSettings | `/agent/settings` | Preferences, logout |

## Navigation Flow Patterns

### Customer Flow
```
Home → Product → Add to Cart → Cart → Checkout → Payment → Success → Track
                    ↓
                Wishlist (Save for later)
                    ↓
                Share → Referral (Earn points)
```

### Merchant Flow
```
Dashboard → Orders → Order Detail → Update Status → Assign Agent
     ↓
Products → Add/Edit → Upload Images → Set Stock
     ↓
Analytics → View Reports → Export Data
```

### Order Status Flow
```
Pending → Confirmed → Ready → Out for Delivery → Delivered
   ↓
Cancelled (by customer/merchant/admin)
```

## Deep Linking URLs

| Screen | Deep Link |
|--------|-----------|
| Product | `greenbasket://product/:id` |
| Order | `greenbasket://order/:id` |
| Category | `greenbasket://category/:id` |
| Referral | `greenbasket://referral/:code` |
| Offer | `greenbasket://offer/:id` |
| Recipe | `greenbasket://recipe/:id` |

## State Management Map

```
┌─────────────────────────────────────────────────────────────────┐
│                     STATE MANAGEMENT (GetX/BLoC)                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │  AuthState  │  │  UserState  │  │ CartState   │             │
│  │             │  │             │  │             │             │
│  │• isLoggedIn │  │• profile    │  │• items      │             │
│  │• token      │  │• addresses  │  │• coupon     │             │
│  │• role       │  │• wallet     │  │• total      │             │
│  │• user       │  │• loyalty    │  │• count      │             │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │
│         │                │                │                     │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐             │
│  │  OrderState │  │ProductState │  │  UI State   │             │
│  │             │  │             │  │             │             │
│  │• orders     │  │• products   │  │• theme      │             │
│  │• current    │  │• categories │  │• language   │             │
│  │• tracking   │  │• filters    │  │• loading    │             │
│  │• history    │  │• search     │  │• toast msgs │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```
