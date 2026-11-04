import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbasket_app/config/theme.dart';

/// WCAG contrast ratio between two colours.
double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('text meets 4.5:1', () {
    test('textPrimary on surface and background', () {
      expect(contrast(AppColors.textPrimary, AppColors.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textPrimary, AppColors.background), greaterThanOrEqualTo(4.5));
    });
    test('textSecondary on surface and background', () {
      expect(contrast(AppColors.textSecondary, AppColors.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textSecondary, AppColors.background), greaterThanOrEqualTo(4.5));
    });
    test('textMuted on surface and background', () {
      expect(contrast(AppColors.textMuted, AppColors.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textMuted, AppColors.background), greaterThanOrEqualTo(4.5));
    });
    test('primary text on surface', () {
      expect(contrast(AppColors.primary, AppColors.surface), greaterThanOrEqualTo(4.5));
    });
  });

  group('filled colours with their text meet 4.5:1', () {
    test('white on successFill, errorFill, infoFill and primary', () {
      for (final fill in [
        AppColors.successFill,
        AppColors.errorFill,
        AppColors.infoFill,
        AppColors.primary,
      ]) {
        expect(contrast(Colors.white, fill), greaterThanOrEqualTo(4.5));
      }
    });
    test('dark text on orange and amber', () {
      expect(contrast(AppColors.textPrimary, AppColors.secondary), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textPrimary, AppColors.warning), greaterThanOrEqualTo(4.5));
    });
  });

  test('textHint is placeholder-only (documented as below 4.5:1)', () {
    expect(contrast(AppColors.textHint, AppColors.surface), lessThan(4.5));
  });
}
