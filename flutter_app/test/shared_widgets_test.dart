// Shared widgets: they render, they stay inside the screen at the largest
// system text size, and they say what they are to screen readers.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/widgets/common/empty_state.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_line_chart.dart';
import 'package:greenbasket_app/widgets/common/gb_loader.dart';
import 'package:greenbasket_app/widgets/common/gb_network_image.dart';
import 'package:greenbasket_app/widgets/common/gb_stat_card.dart';
import 'package:greenbasket_app/widgets/common/gb_status_chip.dart';

import 'helpers/pump_app.dart';

void main() {
  group('GBButton', () {
    testWidgets('shows its label and calls onPressed', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        GBButton(label: 'Pay now', onPressed: () => taps++),
      );
      expect(find.text('Pay now'), findsOneWidget);
      await tester.tap(find.text('Pay now'));
      expect(taps, 1);
    });

    testWidgets('does nothing while loading', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        GBButton(label: 'Pay now', isLoading: true, onPressed: () => taps++),
        settle: false,
      );
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('every variant is at least 48 tall (touch target)', (
      tester,
    ) async {
      for (final v in GBButtonVariant.values) {
        await pumpApp(
          tester,
          GBButton(label: 'Go', variant: v, onPressed: () {}),
        );
        final box = tester.getSize(find.byType(GBButton));
        expect(box.height, greaterThanOrEqualTo(48), reason: '$v');
      }
    });

    testWidgets('a long label wraps instead of overflowing at 2x text', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const GBButton(
          label: 'Place order and pay securely with the saved card',
          onPressed: null,
          isFullWidth: true,
        ),
        textScale: 2.0,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('is announced with its label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, GBButton(label: 'Pay now', onPressed: () {}));
      expect(find.bySemanticsLabel('Pay now'), findsOneWidget);
      handle.dispose();
    });
  });

  group('GBStatusChip', () {
    testWidgets('carries the status in words, not only colour', (tester) async {
      await pumpApp(tester, const GBStatusChip(status: 'delivered'));
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('can hide the icon', (tester) async {
      await pumpApp(
        tester,
        const GBStatusChip(status: 'delivered', showIcon: false),
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('fits at 2x text on a narrow screen', (tester) async {
      await pumpApp(
        tester,
        const GBStatusChip(status: 'out-for-delivery'),
        textScale: 2.0,
        size: const Size(200, 400),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('GBStatCard', () {
    testWidgets('reads as one labelled item', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const SizedBox(
          width: 160,
          child: GBStatCard(
            title: 'Orders today',
            value: '24',
            icon: Icons.receipt_long,
            color: AppColors.primary,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Orders today: 24'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a huge value shrinks and a long title is cut, at 2x text', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 160,
          child: GBStatCard(
            title: 'Pending payout requests this month',
            value: '₹12,34,56,789.50',
            icon: Icons.payments,
            color: AppColors.primary,
          ),
        ),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyState / ErrorState', () {
    testWidgets('EmptyState shows title, message and an action that works', (
      tester,
    ) async {
      var tapped = false;
      await pumpApp(
        tester,
        SizedBox(
          height: 600,
          child: EmptyState(
            icon: Icons.shopping_basket_outlined,
            title: 'Your basket is empty',
            message: 'Add something fresh.',
            actionLabel: 'Browse',
            onAction: () => tapped = true,
          ),
        ),
      );
      expect(find.text('Your basket is empty'), findsOneWidget);
      expect(find.text('Add something fresh.'), findsOneWidget);
      await tester.tap(find.text('Browse'));
      expect(tapped, isTrue);
    });

    testWidgets('ErrorState offers Try Again only when it can retry', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(height: 600, child: ErrorState(message: 'Offline')),
      );
      expect(find.text('Try Again'), findsNothing);

      var retried = 0;
      await pumpApp(
        tester,
        SizedBox(
          height: 600,
          child: ErrorState(message: 'Offline', onRetry: () => retried++),
        ),
      );
      await tester.tap(find.text('Try Again'));
      expect(retried, 1);
    });

    testWidgets('both fit at 2x text on a small phone', (tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          height: 800,
          child: EmptyState(
            icon: Icons.favorite_border,
            title: 'Nothing in your wishlist yet',
            message: 'Tap the heart on any product to save it for later.',
            actionLabel: 'Start browsing',
            onAction: _noop,
          ),
        ),
        textScale: 2.0,
        size: const Size(320, 900),
      );
      expect(tester.takeException(), isNull);

      await pumpApp(
        tester,
        const SizedBox(
          height: 800,
          child: ErrorState(
            message: 'We could not reach the server. Check your connection and try again.',
            onRetry: _noop,
          ),
        ),
        textScale: 2.0,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('GBLineChart', () {
    testWidgets('is one image to a screen reader, described in words', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const GBLineChart(
          values: [1, 3, 2, 5],
          comparison: [2, 2, 2, 2],
          startLabel: '1 Nov',
          endLabel: '4 Nov',
          semanticLabel: 'Revenue this month: ₹11, up 10% on last month.',
        ),
      );
      expect(
        find.bySemanticsLabel('Revenue this month: ₹11, up 10% on last month.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('draws without error for empty, single and flat data', (
      tester,
    ) async {
      for (final data in const [
        <double>[],
        <double>[5],
        <double>[0, 0, 0],
        <double>[3, 3, 3],
      ]) {
        await pumpApp(
          tester,
          GBLineChart(values: data, semanticLabel: 'Revenue'),
        );
        expect(tester.takeException(), isNull, reason: '$data');
      }
    });
  });

  group('GBNetworkImage', () {
    testWidgets('shows the icon tile when there is no address', (tester) async {
      for (final url in <String?>[null, '', '   ']) {
        await pumpApp(tester, GBNetworkImage(url: url, width: 72, height: 72));
        expect(
          find.byIcon(Icons.eco_outlined),
          findsOneWidget,
          reason: '"$url"',
        );
      }
    });

    testWidgets('uses the icon it was given', (tester) async {
      await pumpApp(
        tester,
        const GBNetworkImage(
          url: null,
          width: 72,
          height: 72,
          fallbackIcon: Icons.restaurant,
        ),
      );
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });
  });

  group('Skeletons', () {
    testWidgets(
      'list skeleton shows the requested number of rows and is one "Loading" item',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpApp(
          tester,
          const SizedBox(
            height: 600,
            child: GBListSkeleton(itemCount: 4, itemHeight: 60),
          ),
          settle: false,
        );
        expect(find.byType(GBShimmerBox), findsNWidgets(4));
        expect(find.bySemanticsLabel('Loading'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('product grid skeleton builds', (tester) async {
      await pumpApp(
        tester,
        const SizedBox(height: 600, child: GBProductGridSkeleton(itemCount: 4)),
        settle: false,
      );
      expect(find.byType(GBProductCardShimmer), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppMotion', () {
    testWidgets(
      'durations collapse to zero when the system asks to reduce motion',
      (tester) async {
        late Duration reduced;
        late Duration normal;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = AppMotion.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(reduced, Duration.zero);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Builder(
              builder: (context) {
                normal = AppMotion.of(context);
                return const SizedBox();
              },
            ),
          ),
        );
        expect(normal, AppMotion.normal);
      },
    );
  });
}

void _noop() {}
