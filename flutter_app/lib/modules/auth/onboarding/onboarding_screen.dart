import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/routes.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/services/storage_service.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';

/// Three short pages shown once, on first launch, before the login screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.eco,
      title: 'Fresh from local sellers',
      body:
          'Buy fruits, vegetables and more straight from farmers and growers near you.',
    ),
    _OnboardingPage(
      icon: Icons.location_on,
      title: 'See what is close to you',
      body:
          'Nearby mode shows products within the distance you choose. Change it any time on the home screen.',
    ),
    _OnboardingPage(
      icon: Icons.local_shipping,
      title: 'Follow your order',
      body: 'Watch your order go from the seller to your door.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    StorageService().setOnboarded();
    Get.offAllNamed(Routes.login);
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _pages[i],
              ),
            ),
            Semantics(
              label: 'Page ${_index + 1} of ${_pages.length}',
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: AppMotion.normal,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: i == _index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: GBButton(
                label: _isLast ? 'Get started' : 'Next',
                isFullWidth: true,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: AppColors.primaryText),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
