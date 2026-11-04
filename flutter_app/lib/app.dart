import 'package:flutter/material.dart';
import 'package:greenbasket_app/modules/auth/onboarding/onboarding_screen.dart';
import 'package:get/get.dart';
import 'bindings/app_bindings.dart';
import 'config/routes.dart';
import 'config/theme.dart';

// Auth
import 'modules/auth/splash/splash_screen.dart';
import 'modules/auth/login/login_screen.dart';
import 'modules/auth/signup/signup_screen.dart';
import 'modules/auth/otp/otp_screen.dart';
import 'modules/auth/forgot_password/forgot_password_screen.dart';
import 'modules/auth/reset_password/reset_password_screen.dart';

// Customer shell
import 'modules/customer/customer_shell.dart';

// Customer standalone
import 'modules/customer/products/categories_screen.dart';
import 'modules/customer/cart/cart_screen.dart';
import 'modules/customer/products/product_detail_screen.dart';
import 'modules/customer/products/search_screen.dart';
import 'modules/customer/products/recipe_screen.dart';
import 'modules/customer/products/recipe_detail_screen.dart';
import 'modules/customer/products/category_detail_screen.dart';
import 'modules/customer/checkout/checkout_screen.dart';
import 'modules/customer/orders/order_detail_screen.dart';
import 'modules/customer/orders/order_list_screen.dart';
import 'modules/customer/orders/order_success_screen.dart';
import 'modules/customer/orders/order_tracking_screen.dart';
import 'modules/customer/profile/wallet_screen.dart';
import 'modules/customer/profile/loyalty_screen.dart';
import 'modules/customer/profile/wishlist_screen.dart';
import 'modules/customer/profile/notifications_screen.dart';
import 'modules/customer/profile/notification_settings_screen.dart';
import 'modules/customer/profile/referral_screen.dart';
import 'modules/customer/profile/edit_profile_screen.dart';
import 'modules/customer/profile/addresses_screen.dart';
import 'modules/customer/profile/add_address_screen.dart';
import 'modules/customer/profile/disputes_screen.dart';
import 'modules/customer/profile/returns_screen.dart';
import 'modules/customer/offers/offers_screen.dart' as customer_offers;

// Merchant shell
import 'modules/merchant/merchant_shell.dart';

// Merchant standalone
import 'modules/merchant/products/merchant_products_screen.dart';
import 'modules/merchant/products/add_product_screen.dart';
import 'modules/merchant/products/edit_product_screen.dart';
import 'modules/merchant/products/product_stock_screen.dart';
import 'modules/merchant/products/bulk_upload_screen.dart';
import 'modules/merchant/orders/merchant_orders_screen.dart';
import 'modules/merchant/orders/merchant_order_detail_screen.dart';
import 'modules/merchant/offers/offers_screen.dart';
import 'modules/merchant/offers/create_offer_screen.dart';
import 'modules/merchant/offers/offer_analytics_screen.dart';
import 'modules/merchant/zones/delivery_zones_screen.dart';
import 'modules/merchant/zones/edit_zone_screen.dart';
import 'modules/merchant/financial/financial_screen.dart';
import 'modules/merchant/financial/payouts_screen.dart';
import 'modules/merchant/settings/store_settings_screen.dart';
// Admin shell
import 'modules/admin/admin_shell.dart';

// Admin standalone
import 'modules/admin/users/user_detail_screen.dart';
import 'modules/admin/merchants/merchant_analytics_screen.dart';
import 'modules/admin/orders/admin_orders_screen.dart';
import 'modules/admin/orders/admin_order_detail_screen.dart';
import 'modules/admin/orders/disputes_admin_screen.dart';
import 'modules/admin/orders/returns_admin_screen.dart';
import 'modules/admin/products/admin_products_screen.dart';
import 'modules/admin/products/admin_categories_screen.dart';
import 'modules/admin/products/create_category_screen.dart';
import 'modules/admin/products/admin_recipes_screen.dart';
import 'modules/admin/products/create_recipe_screen.dart';

import 'modules/admin/offers/admin_offers_screen.dart';
import 'modules/admin/finance/admin_payouts_screen.dart';
import 'modules/admin/finance/commission_settings_screen.dart';
import 'modules/admin/operations/bulk_ops_screen.dart';
import 'modules/admin/settings/admin_settings_screen.dart';
import 'modules/admin/notifications/admin_notifications_screen.dart';
import 'modules/admin/notifications/admin_all_notifications_screen.dart';
import 'modules/admin/products/admin_product_detail_screen.dart';



class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GreenBasket',
      theme: AppTheme.light,
      initialRoute: Routes.splash,
      initialBinding: AppBindings(),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
      getPages: [
        // ─── Auth ────────────────────────────────────────────────────────
        GetPage(name: Routes.splash, page: () => const SplashScreen()),
        GetPage(name: Routes.onboarding, page: () => const OnboardingScreen()),
        GetPage(name: Routes.login, page: () => const LoginScreen()),
        GetPage(name: Routes.signup, page: () => const SignupScreen()),
        GetPage(name: Routes.otp, page: () => const OtpScreen()),
        GetPage(name: Routes.forgotPassword, page: () => const ForgotPasswordScreen()),
        GetPage(name: Routes.resetPassword, page: () => const ResetPasswordScreen()),

        // ─── Customer Shell ──────────────────────────────────────────────
        GetPage(name: Routes.customerHome, page: () => const CustomerShell()),

        // ─── Customer Standalone ─────────────────────────────────────────
        GetPage(name: Routes.categories, page: () => const CategoriesScreen()),
        GetPage(name: Routes.cart, page: () => const CartScreen()),
        GetPage(name: Routes.productDetail, page: () => const ProductDetailScreen()),
        GetPage(name: Routes.search, page: () => const SearchScreen()),
        GetPage(name: Routes.categoryDetail, page: () => const CategoryDetailScreen()),
        GetPage(name: Routes.recipes, page: () => const RecipeScreen()),
        GetPage(name: Routes.recipeDetail, page: () => const RecipeDetailScreen()),
        GetPage(
          name: Routes.checkout, 
          page: () => const CheckoutScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => CheckoutController());
          }),
        ),
        GetPage(name: Routes.orderList, page: () => const OrderListScreen()),
        GetPage(name: Routes.orderDetail, page: () => const OrderDetailScreen()),
        GetPage(name: Routes.orderSuccess, page: () => const OrderSuccessScreen()),
        GetPage(name: Routes.orderTracking, page: () => const OrderTrackingScreen()),
        GetPage(name: Routes.wallet, page: () => const WalletScreen()),
        GetPage(name: Routes.loyalty, page: () => const LoyaltyScreen()),
        GetPage(name: Routes.wishlist, page: () => const WishlistScreen()),
        GetPage(name: Routes.notifications, page: () => const NotificationsScreen()),
        GetPage(name: Routes.notificationSettings, page: () => const NotificationSettingsScreen()),
        GetPage(name: Routes.referral, page: () => const ReferralScreen()),
        GetPage(name: Routes.editProfile, page: () => const EditProfileScreen()),
        GetPage(name: Routes.addresses, page: () => const AddressesScreen()),
        GetPage(name: Routes.addAddress, page: () => const AddAddressScreen()),
        GetPage(name: Routes.disputes, page: () => const DisputesScreen()),
        GetPage(name: Routes.returns, page: () => const ReturnsScreen()),
        GetPage(name: Routes.customerOffers, page: () => const customer_offers.CustomerOffersScreen()),

        // ─── Merchant Shell ──────────────────────────────────────────────
        GetPage(name: Routes.merchantDashboard, page: () => const MerchantShell()),

        // ─── Merchant Standalone ─────────────────────────────────────────
        GetPage(name: Routes.merchantProducts, page: () => const MerchantProductsScreen()),
        GetPage(name: Routes.merchantAddProduct, page: () => const AddProductScreen()),
        GetPage(name: Routes.merchantEditProduct, page: () => EditProductScreen(product: Get.arguments)),
        GetPage(name: Routes.merchantProductStock, page: () => ProductStockScreen(product: Get.arguments)),
        GetPage(name: Routes.merchantBulkUpload, page: () => const BulkUploadScreen()),
        GetPage(name: Routes.merchantOrders, page: () => const MerchantOrdersScreen()),
        GetPage(name: Routes.merchantOrderDetail, page: () => MerchantOrderDetailScreen(order: Get.arguments)),
        GetPage(name: Routes.merchantOffers, page: () => const OffersScreen()),
        GetPage(name: Routes.merchantCreateOffer, page: () => const CreateOfferScreen()),
        GetPage(name: Routes.merchantOfferAnalytics, page: () => const OfferAnalyticsScreen()),
        GetPage(name: Routes.merchantZones, page: () => const DeliveryZonesScreen()),
        GetPage(name: Routes.merchantEditZone, page: () => const EditZoneScreen()),
        GetPage(name: Routes.merchantFinancial, page: () => const FinancialScreen()),
        GetPage(name: Routes.merchantPayouts, page: () => const PayoutsScreen()),
        GetPage(name: Routes.merchantSettings, page: () => const StoreSettingsScreen()),
        // ─── Admin Shell ─────────────────────────────────────────────────
        GetPage(name: Routes.adminDashboard, page: () => const AdminShell()),

        // ─── Admin Standalone ────────────────────────────────────────────
        GetPage(name: Routes.adminUserDetail, page: () => const UserDetailScreen()),
        GetPage(name: Routes.adminMerchantAnalytics, page: () => const MerchantAnalyticsScreen()),
        GetPage(name: Routes.adminOrders, page: () => const AdminOrdersScreen()),
        GetPage(name: Routes.adminOrderDetail, page: () => const AdminOrderDetailScreen()),
        GetPage(name: Routes.adminDisputes, page: () => const DisputesAdminScreen()),
        GetPage(name: Routes.adminReturns, page: () => const ReturnsAdminScreen()),
        GetPage(name: Routes.adminProducts, page: () => const AdminProductsScreen()),
        GetPage(name: Routes.adminCategories, page: () => const AdminCategoriesScreen()),
        GetPage(name: Routes.adminCreateCategory, page: () => const CreateCategoryScreen()),
        GetPage(name: Routes.adminRecipes, page: () => const AdminRecipesScreen()),
        GetPage(name: Routes.adminCreateRecipe, page: () => const CreateRecipeScreen()),
        GetPage(name: Routes.adminOffers, page: () => const AdminOffersScreen()),
        GetPage(name: Routes.adminPayouts, page: () => const AdminPayoutsScreen()),
        GetPage(name: Routes.adminCommission, page: () => const CommissionSettingsScreen()),
        GetPage(name: Routes.adminBulkOps, page: () => const BulkOpsScreen()),
        GetPage(name: Routes.adminSettings, page: () => const AdminSettingsScreen()),
        GetPage(name: Routes.adminNotifications, page: () => const AdminNotificationsScreen()),
        GetPage(name: Routes.adminAllNotifications, page: () => const AdminAllNotificationsScreen()),
        GetPage(name: Routes.adminProductDetail, page: () => const AdminProductDetailScreen()),


      ],
    );
  }
}
