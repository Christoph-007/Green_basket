import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/services/network_status.dart';

/// A slim notice that appears above the bottom navigation while the app
/// cannot reach the server, and disappears by itself when it can again.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!NetworkStatus.isOffline.value) return const SizedBox.shrink();
      return Semantics(
        liveRegion: true,
        child: Material(
          color: AppColors.textPrimary,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You're offline. Information may be out of date.",
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
