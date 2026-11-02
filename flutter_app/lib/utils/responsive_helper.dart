import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;
  ResponsiveHelper(this.context);

  double get width => MediaQuery.sizeOf(context).width;
  double get height => MediaQuery.sizeOf(context).height;

  // Breakpoints
  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1200;
  bool get isDesktop => width >= 1200;

  // Grid Configuration
  int get gridCrossAxisCount {
    if (isDesktop) return 6;
    if (isTablet) return 4;
    return 2; 
  }

  double get productCardAspectRatio {
    if (isDesktop) return 0.8;
    if (isTablet) return 0.75;
    return 0.7; // Mobile standard
  }

  // Spacing Scaling
  double adaptiveSpacing(double base) {
    if (isDesktop) return base * 1.5;
    if (isTablet) return base * 1.2;
    return base;
  }

  // Font Scaling
  double adaptiveFontSize(double base) {
    if (isDesktop) return base * 1.3;
    if (isTablet) return base * 1.15;
    return base;
  }

  // Layout Constraints
  double get maxContentWidth {
    if (isDesktop) return 1200;
    if (isTablet) return 900;
    return double.infinity;
  }
}
