import 'package:flutter/material.dart';

/// The colours that change between the light and dark looks. Everything else
/// in [AppColors] (brand greens, status colours, fills that carry white text)
/// is the same in both.
class AppPalette {
  final Color primaryContainer;
  final Color primarySoft;
  final Color primarySofter;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color backgroundWarm;
  final Color backgroundAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textMuted;
  final Color border;
  final Color borderLight;
  final Color divider;
  final Color neutralSoft;
  final Color errorSoft;
  final Color amberContainer;
  final Color purpleContainer;
  final Color shadow;
  final Color shadowFaint;
  final Color shadowTint;
  final Color shadowTintLight;
  final Color shadowTintFaint;
  final Color primaryText;
  final Color errorText;

  const AppPalette({
    required this.primaryContainer,
    required this.primarySoft,
    required this.primarySofter,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.backgroundWarm,
    required this.backgroundAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textMuted,
    required this.border,
    required this.borderLight,
    required this.divider,
    required this.neutralSoft,
    required this.errorSoft,
    required this.amberContainer,
    required this.purpleContainer,
    required this.shadow,
    required this.shadowFaint,
    required this.shadowTint,
    required this.shadowTintLight,
    required this.shadowTintFaint,
    required this.primaryText,
    required this.errorText,
  });

  static const AppPalette light = AppPalette(
    primaryContainer: Color(0xFFE8F5E9),
    primarySoft: Color(0xFFE8F2EC),
    primarySofter: Color(0xFFE8F0E8),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF8F8F8),
    backgroundWarm: Color(0xFFF5F4F1),
    backgroundAlt: Color(0xFFF9F9F9),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF666666),
    textHint: Color(0xFFBDBDBD),
    textMuted: Color(0xFF6F6F6F),
    border: Color(0xFFE0E0E0),
    borderLight: Color(0xFFE8E8E8),
    divider: Color(0xFFF0F0F0),
    neutralSoft: Color(0xFFE8EAE6),
    errorSoft: Color(0xFFFEE2E2),
    amberContainer: Color(0xFFFEF3C7),
    purpleContainer: Color(0xFFF3E5F5),
    shadow: Color(0x1A000000),
    shadowFaint: Color(0x0D000000),
    shadowTint: Color(0x201F5C35),
    shadowTintLight: Color(0x141F5C35),
    shadowTintFaint: Color(0x101F5C35),
    primaryText: Color(0xFF2E7D32),
    errorText: Color(0xFFE53935),
  );

  static const AppPalette dark = AppPalette(
    primaryContainer: Color(0xFF1C3326),
    primarySoft: Color(0xFF1B2B22),
    primarySofter: Color(0xFF1B2A1F),
    background: Color(0xFF0F1512),
    surface: Color(0xFF18201C),
    surfaceVariant: Color(0xFF1F2823),
    backgroundWarm: Color(0xFF121915),
    backgroundAlt: Color(0xFF141B17),
    textPrimary: Color(0xFFEAF0EC),
    textSecondary: Color(0xFFB4C0B8),
    textHint: Color(0xFF6E7B73),
    textMuted: Color(0xFF9AA79F),
    border: Color(0xFF2F3A34),
    borderLight: Color(0xFF2A342F),
    divider: Color(0xFF26302B),
    neutralSoft: Color(0xFF26302B),
    errorSoft: Color(0xFF3B1F1F),
    amberContainer: Color(0xFF3A2F14),
    purpleContainer: Color(0xFF2E1F33),
    shadow: Color(0x66000000),
    shadowFaint: Color(0x33000000),
    shadowTint: Color(0x66000000),
    shadowTintLight: Color(0x4D000000),
    shadowTintFaint: Color(0x33000000),
    primaryText: Color(0xFF66BB6A),
    errorText: Color(0xFFEF5350),
  );
}

class AppColors {
  static AppPalette _p = AppPalette.light;

  /// Switches every palette-based colour. The app is rebuilt afterwards (see ThemeController).
  static void usePalette(AppPalette palette) => _p = palette;
  static AppPalette get palette => _p;
  static bool get isDark => identical(_p, AppPalette.dark);

  // Green and red that stay readable as text/icons on the current background.
  static Color get primaryText => _p.primaryText;
  static Color get errorText => _p.errorText;

  // Primary brand green
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static Color get primaryContainer => _p.primaryContainer;

  // Secondary / accent
  static const Color secondary = Color(0xFFFFA726);
  static const Color secondaryLight = Color(0xFFFFCC02);
  static const Color secondaryDark = Color(0xFFE65100);

  // Background
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceVariant => _p.surfaceVariant;

  // Text
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary; // 5.7:1 on white, 5.3:1 on background
  static Color get textHint => _p.textHint; // placeholders and disabled states only
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
  static Color get border => _p.border;
  static Color get divider => _p.divider;

  // Shadow
  static Color get shadow => _p.shadow;
  static Color get shadowFaint => _p.shadowFaint;
  // Green-tinted shadows used by admin cards
  static Color get shadowTint => _p.shadowTint;
  static Color get shadowTintLight => _p.shadowTintLight;
  static Color get shadowTintFaint => _p.shadowTintFaint;

  // ── Extended palette ─────────────────────────────────────────────
  // These hold colours that screens previously declared inline. The values
  // are unchanged; they now live in one place.

  // Brand greens used by admin headers and accents
  static const Color brandDeep = Color(0xFF1B4332);
  static const Color brandDeepLight = Color(0xFF2D6A4F);
  static const Color brandForest = Color(0xFF1A4D2E);
  static const Color brandMid = Color(0xFF2D7A4A);
  static const Color brandAccent = Color(0xFF1F5C35);
  static Color get primarySoft => _p.primarySoft;
  static Color get primarySofter => _p.primarySofter;

  // Neutrals
  static Color get borderLight => _p.borderLight;
  static Color get textMuted => _p.textMuted; // 5.0:1 on white (was #9C9B99, 2.8:1)
  static const Color neutralGrey = Color(0xFF9E9E9E);
  static Color get neutralSoft => _p.neutralSoft;
  static Color get backgroundWarm => _p.backgroundWarm;
  static Color get backgroundAlt => _p.backgroundAlt;

  // Reds
  static const Color errorStrong = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFD32F2F);
  static Color get errorSoft => _p.errorSoft;

  // Ambers and oranges
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningDeep = Color(0xFFD97706);
  static const Color amber = Color(0xFFFFC107);
  static const Color amberDark = Color(0xFFFF8F00);
  static Color get amberContainer => _p.amberContainer;
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
  static Color get purpleContainer => _p.purpleContainer;
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

/// Animation lengths and curves, so movement feels the same everywhere.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;

  /// True when the person has asked the system to reduce animation.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// [normal] normally, instant when animations are reduced.
  static Duration of(BuildContext context, [Duration d = normal]) =>
      reduced(context) ? Duration.zero : d;
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

  static TextStyle get displayLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get displaySmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get titleLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get titleMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  /// 13 px body text, used by compact rows and list subtitles.
  static TextStyle get bodyCompact => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get labelLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );
}

class AppTheme {
  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  /// Builds a theme with [palette] active, then puts the previous palette back,
  /// so the app's own state is never changed by constructing a theme.
  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final previous = AppColors.palette;
    AppColors.usePalette(palette);
    try {
      return _themeData(brightness);
    } finally {
      AppColors.usePalette(previous);
    }
  }

  static ThemeData _themeData(Brightness brightness) => ThemeData(
        useMaterial3: true,
        brightness: brightness,
        fontFamily: AppTextStyles.fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
          primary: brightness == Brightness.dark ? AppColors.primaryText : AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: brightness == Brightness.dark ? AppColors.errorText : AppColors.error,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
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
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: AppColors.primaryText, width: 1.5),
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
            foregroundColor: AppColors.primaryText,
            side: BorderSide(color: AppColors.primaryText),
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
            foregroundColor: AppColors.primaryText,
          ),
        ),
        dividerTheme: DividerThemeData(
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
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primaryText,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          // Same size for selected and unselected so icons stay level, and
          // small enough for six tabs in Poppins.
          selectedLabelStyle: TextStyle(fontSize: 11),
          unselectedLabelStyle: TextStyle(fontSize: 11),
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
