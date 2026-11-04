import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';

class GBLoader extends StatelessWidget {
  const GBLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class GBShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const GBShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class GBProductCardShimmer extends StatelessWidget {
  const GBProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: double.infinity,
            color: Colors.white,
          ),
          const SizedBox(height: 6),
          Container(height: 12, width: 80, color: Colors.white),
        ],
      ),
    );
  }
}

class GBPageLoader extends StatelessWidget {
  const GBPageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

/// Placeholder rows shown while a list loads, so the screen keeps its shape
/// instead of showing a lone spinner.
class GBListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const GBListSkeleton({super.key, this.itemCount = 6, this.itemHeight = 88});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, __) => GBShimmerBox(
            width: double.infinity,
            height: itemHeight,
            borderRadius: AppRadius.md,
          ),
        ),
      ),
    );
  }
}

/// Placeholder product cards in a two-column grid while products load.
class GBProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const GBProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.72,
          ),
          itemCount: itemCount,
          itemBuilder: (_, __) => const GBProductCardShimmer(),
        ),
      ),
    );
  }
}
