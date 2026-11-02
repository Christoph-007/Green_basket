import 'package:get/get.dart';
import '../data/providers/api_provider.dart';
import '../data/services/storage_service.dart';
import '../data/services/socket_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/merchant_repository.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../data/repositories/loyalty_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/recipe_repository.dart';
import '../modules/auth/auth_controller.dart';
import '../modules/admin/admin_controller.dart';
import '../modules/customer/profile/wishlist_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Core
    Get.put(ApiProvider(), permanent: true);
    Get.put(StorageService(), permanent: true);
    Get.put(SocketService(), permanent: true);

    // Repositories
    Get.put(AuthRepository(), permanent: true);
    Get.put(ProductRepository(), permanent: true);
    Get.put(OrderRepository(), permanent: true);
    Get.put(UserRepository(), permanent: true);
    Get.put(MerchantRepository(), permanent: true);
    Get.put(AdminRepository(), permanent: true);
    Get.put(WalletRepository(), permanent: true);
    Get.put(LoyaltyRepository(), permanent: true);
    Get.put(NotificationRepository(), permanent: true);
    Get.put(RecipeRepository(), permanent: true);

    // Global controllers
    Get.put(AuthController(), permanent: true);
    Get.put(WishlistController(), permanent: true);


    // Admin controller (lazy — created only when first accessed)
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true);
  }
}
