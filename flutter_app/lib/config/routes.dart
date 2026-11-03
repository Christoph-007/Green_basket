class Routes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Customer shell
  static const String customerHome = '/customer/home';

  // Customer standalone
  static const String categories = '/customer/categories';
  static const String categoryDetail = '/customer/category-detail';
  static const String productDetail = '/customer/product-detail';
  static const String search = '/customer/search';
  static const String cart = '/customer/cart';
  static const String checkout = '/customer/checkout';
  static const String orderSuccess = '/customer/order-success';
  static const String orderList = '/customer/orders';
  static const String orderDetail = '/customer/order-detail';
  static const String orderTracking = '/customer/orders/track';
  static const String profile = '/customer/profile';
  static const String editProfile = '/customer/profile/edit';
  static const String wallet = '/customer/wallet';
  static const String loyalty = '/customer/loyalty';
  static const String wishlist = '/customer/wishlist';
  static const String notifications = '/customer/notifications';
  static const String notificationSettings = '/customer/settings/notifications';
  static const String addresses = '/customer/addresses';
  static const String addAddress = '/customer/address/add';
  static const String referral = '/customer/referral';
  static const String disputes = '/customer/disputes';
  static const String returns = '/customer/returns';
  static const String recipes = '/customer/recipes';
  static const String recipeDetail = '/customer/recipes/detail';
  static const String customerOffers = '/customer/offers';

  // Merchant shell
  static const String merchantDashboard = '/merchant/dashboard';

  // Merchant standalone
  static const String merchantProducts = '/merchant/products';
  static const String merchantAddProduct = '/merchant/product/add';
  static const String merchantEditProduct = '/merchant/product/edit';
  static const String merchantProductStock = '/merchant/product/stock';
  static const String merchantBulkUpload = '/merchant/bulk-upload';
  static const String merchantOrders = '/merchant/orders';
  static const String merchantOrderDetail = '/merchant/order/detail';
  static const String merchantAnalytics = '/merchant/analytics';
  static const String merchantProfile = '/merchant/profile';
  static const String merchantOffers = '/merchant/offers';
  static const String merchantCreateOffer = '/merchant/offer/create';
  static const String merchantOfferAnalytics = '/merchant/offer/analytics';
  static const String merchantZones = '/merchant/zones';
  static const String merchantEditZone = '/merchant/zone/edit';
  static const String merchantFinancial = '/merchant/financial';
  static const String merchantPayouts = '/merchant/payouts';
  static const String merchantSettings = '/merchant/settings';
  // Admin shell
  static const String adminDashboard = '/admin/dashboard';

  // Admin standalone
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/user/detail';
  static const String adminMerchants = '/admin/merchants';
  static const String adminMerchantAnalytics = '/admin/merchant/analytics';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/order/detail';
  static const String adminDisputes = '/admin/disputes';
  static const String adminReturns = '/admin/returns';
  static const String adminProducts = '/admin/products';
  static const String adminCategories = '/admin/categories';
  static const String adminCreateCategory = '/admin/category/create';
  static const String adminRecipes = '/admin/recipes';
  static const String adminCreateRecipe = '/admin/recipe/create';
  static const String adminOffers = '/admin/offers';
  static const String adminPayouts = '/admin/payouts';
  static const String adminCommission = '/admin/commission';
  static const String adminBulkOps = '/admin/bulk-ops';
  static const String adminSettings = '/admin/settings';
  static const String adminNotifications = '/admin/notifications';
  static const String adminAllNotifications = '/admin/notifications/all';
  static const String adminFinance = '/admin/finance';
  static const String adminProductDetail = '/admin/product-detail';

}
