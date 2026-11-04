// Dark mode: the palette switches, the dark theme is really dark, building a
// theme never leaves the wrong palette behind, and dark text stays readable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbasket_app/config/theme.dart';

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  tearDown(() => AppColors.usePalette(AppPalette.light));

  test('switching the palette changes surface and text colours', () {
    AppColors.usePalette(AppPalette.light);
    final lightBackground = AppColors.background;
    final lightText = AppColors.textPrimary;
    expect(AppColors.isDark, isFalse);

    AppColors.usePalette(AppPalette.dark);
    expect(AppColors.isDark, isTrue);
    expect(AppColors.background, isNot(lightBackground));
    expect(AppColors.textPrimary, isNot(lightText));
    // Dark means a dark page with light text.
    expect(AppColors.background.computeLuminance(), lessThan(0.1));
    expect(AppColors.textPrimary.computeLuminance(), greaterThan(0.6));
  });

  test('brand and fill colours are the same in both palettes', () {
    AppColors.usePalette(AppPalette.light);
    final lightPrimary = AppColors.primary;
    final lightErrorFill = AppColors.errorFill;
    AppColors.usePalette(AppPalette.dark);
    expect(AppColors.primary, lightPrimary);
    expect(AppColors.errorFill, lightErrorFill);
  });

  test('building a theme does not change the palette in use', () {
    AppColors.usePalette(AppPalette.light);
    final dark = AppTheme.dark;
    expect(AppColors.isDark, isFalse);
    expect(dark.brightness, Brightness.dark);

    AppColors.usePalette(AppPalette.dark);
    final light = AppTheme.light;
    expect(AppColors.isDark, isTrue);
    expect(light.brightness, Brightness.light);
  });

  test('each theme carries its own palette colours', () {
    AppColors.usePalette(AppPalette.light);
    expect(AppTheme.light.scaffoldBackgroundColor, AppPalette.light.background);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppPalette.dark.background);
    expect(AppTheme.dark.cardTheme.color, AppPalette.dark.surface);
  });

  group('dark text meets contrast on dark surfaces', () {
    const p = AppPalette.dark;
    final grounds = {
      'background': p.background,
      'surface': p.surface,
    };
    grounds.forEach((name, ground) {
      test('on $name', () {
        expect(contrast(p.textPrimary, ground), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textSecondary, ground), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textMuted, ground), greaterThanOrEqualTo(4.5));
        expect(contrast(p.primaryText, ground), greaterThanOrEqualTo(4.5));
        expect(contrast(p.errorText, ground), greaterThanOrEqualTo(4.5));
      });
    });

    test('white text on the primary fill still passes', () {
      expect(contrast(Colors.white, AppColors.primary), greaterThanOrEqualTo(4.5));
    });
  });
}
