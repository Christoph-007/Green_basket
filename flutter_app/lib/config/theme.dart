import 'package:flutter/material.dart';

class AppColors {
  // Primary brand green
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryContainer = Color(0xFFE8F5E9);

  // Secondary / accent
  static const Color secondary = Color(0xFFFFA726);
  static const Color secondaryLight = Color(0xFFFFCC02);
  static const Color secondaryDark = Color(0xFFE65100);

  // Background
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F8F8);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666); // 5.7:1 on white, 5.3:1 on background
  static const Color textHint = Color(0xFFBDBDBD); // placeholders and disabled states only
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);

  // Order status
  static const Color statusPending = Color(0xFFFFF9C4);
  static const Color statusConfirmed = Color(0xFFE3F2FD);
  static const Color statusPreparing = Color(0xFFFFF3E0);
  static const Color statusDispatched = Color(0xFFE8F5E9);
  static const Color statusDelivered = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFFFFEBEE);

  // Border & divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowFaint = Color(0x0D000000);
  // Green-tinted shadows used by admin cards
  static const Color shadowTint = Color(0x201F5C35);
  static const Color shadowTintLight = Color(0x141F5C35);
  static const Color shadowTintFaint = Color(0x101F5C35);

  // ── Extended palette ─────────────────────────────────────────────
  // These hold colours that screens previously declared inline. The values
  // are unchanged; they now live in one place.

  // Brand greens used by admin headers and accents
  static const Color brandDeep = Color(0xFF1B4332);
  static const Color brandDeepLight = Color(0xFF2D6A4F);
  static const Color brandForest = Color(0xFF1A4D2E);
  static const Color brandMid = Color(0xFF2D7A4A);
  static const Color brandAccent = Color(0xFF1F5C35);
  static const Color primarySoft = Color(0xFFE8F2EC);
  static const Color primarySofter = Color(0xFFE8F0E8);

  // Neutrals
  static const Color borderLight = Color(0xFFE8E8E8);
  static const Color textMuted = Color(0xFF6F6F6F); // 5.0:1 on white (was #9C9B99, 2.8:1)
  static const Color neutralGrey = Color(0xFF9E9E9E);
  static const Color neutralSoft = Color(0xFFE8EAE6);
  static const Color backgroundWarm = Color(0xFFF5F4F1);
  static const Color backgroundAlt = Color(0xFFF9F9F9);

  // Reds
  static const Color errorStrong = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color errorSoft = Color(0xFFFEE2E2);

  // Ambers and oranges
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningDeep = Color(0xFFD97706);
  static const Color amber = Color(0xFFFFC107);
  static const Color amberDark = Color(0xFFFF8F00);
  static const Color amberContainer = Color(0xFFFEF3C7);
  static const Color orange = Color(0xFFFF9800);
  static const Color deepOrange = Color(0xFFFF5722);

  // Fills that carry white text and meet WCAG 4.5:1 (used by the shared snackbar helper).
  // The plain success/error/info tokens stay for icons and borders.
  static const Color successFill = Color(0xFF2E7D32);
  static const Color errorFill = Color(0xFFC62828);
  static const Color infoFill = Color(0xFF1565C0);

  // Purples, blues and others (charts, badges)
  static const Color purple = Color(0xFF9C27B0);
  static const Color chartPurple = Color(0xFF7B1FA2);
  static const Color purpleDeep = Color(0xFF6A1B9A);
  static const Color purpleContainer = Color(0xFFF3E5F5);
  static const Color chartBrown = Color(0xFF8D6E63);
  static const Color blue = Color(0xFF2196F3);
  static const Color blueDark = Color(0xFF1565C0);
  static const Color cyan = Color(0xFF00BCD4);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Screen horizontal padding
  static const double screenPadding = 16.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0;
}

class AppTextStyles {
  static const String fontFamily = 'Poppins';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  /// 13 px body text, used by compact rows and list subtitles.
  static const TextStyle bodyCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppTextStyles.fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.titleLarge,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          labelStyle: AppTextStyles.bodyMedium,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          space: 1,
          thickness: 1,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          // Same size for selected and unselected so icons stay level, and
          // small enough for six tabs in Poppins.
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primaryContainer,
          selectedColor: AppColors.primary,
          labelStyle: AppTextStyles.labelSmall,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      );
}
