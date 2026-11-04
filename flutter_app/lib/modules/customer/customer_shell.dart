import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import 'home/home_screen.dart';
import 'products/categories_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/order_list_screen.dart';
import 'profile/profile_screen.dart';
import 'cart/cart_controller.dart';
import 'nav_controller.dart';
import 'products/recipe_screen.dart';
import 'home/home_controller.dart';
import '../auth/auth_controller.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late final NavController _nav;

  final _screens = const [
    HomeScreen(),
    CategoriesScreen(),
    RecipeScreen(),
    CartScreen(),
    OrderListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _nav = Get.put(NavController());
    Get.put(CartController());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: IndexedStack(
        index: _nav.currentIndex.value,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _nav.currentIndex.value,
          onTap: (i) {
            _nav.changeIndex(i);
            if (i == 0 && Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().fetchData();
            } else if (i == 1 && Get.isRegistered<CategoriesController>()) {
              Get.find<CategoriesController>().fetchCategories();
            } else if (i == 2 && Get.isRegistered<RecipeController>()) {
              Get.find<RecipeController>().fetchRecipes();
            } else if (i == 5 && Get.isRegistered<AuthController>()) {
              Get.find<AuthController>().fetchProfile();
            }
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Categories',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Recipes',
            ),
            BottomNavigationBarItem(
              icon: Obx(() {
                final count = Get.find<CartController>().itemCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (count > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              count > 9 ? '9+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
              activeIcon: const Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ));
  }
}
