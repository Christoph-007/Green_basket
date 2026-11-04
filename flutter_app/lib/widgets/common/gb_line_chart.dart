import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:greenbasket_app/config/theme.dart';

/// A simple line chart drawn with no extra package: one main series with a
/// soft fill, an optional lighter comparison series, three grid lines and a
/// label at each end of the horizontal axis.
class GBLineChart extends StatelessWidget {
  final List<double> values;
  final List<double> comparison;
  final String startLabel;
  final String endLabel;
  final Color color;
  final double height;

  /// Read aloud by screen readers in place of the drawing.
  final String semanticLabel;

  const GBLineChart({
    super.key,
    required this.values,
    this.comparison = const [],
    this.startLabel = '',
    this.endLabel = '',
    this.color = AppColors.primary,
    this.height = 160,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              values: values,
              comparison: comparison,
              startLabel: startLabel,
              endLabel: endLabel,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<double> comparison;
  final String startLabel;
  final String endLabel;
  final Color color;

  _LineChartPainter({
    required this.values,
    required this.comparison,
    required this.startLabel,
    required this.endLabel,
    required this.color,
  });

  static const double _labelHeight = 20;

  void _text(Canvas canvas, String text, Offset at, {bool alignRight = false}) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      alignRight ? Offset(at.dx - painter.width, at.dy) : at,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plotHeight = size.height - _labelHeight;
    final plotWidth = size.width;

    // The largest value across both lines sets the scale (never below 1).
    var maxValue = 1.0;
    for (final v in [...values, ...comparison]) {
      maxValue = math.max(maxValue, v);
    }

    // Grid: top, middle and bottom lines.
    final grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = plotHeight * i / 2;
      canvas.drawLine(Offset(0, y), Offset(plotWidth, y), grid);
    }

    Offset pointAt(int i, int count, double value) {
      final x = count <= 1 ? plotWidth / 2 : plotWidth * i / (count - 1);
      final y = plotHeight - (value / maxValue) * (plotHeight - 4) - 2;
      return Offset(x, y);
    }

    Path linePath(List<double> series) {
      final path = Path();
      for (var i = 0; i < series.length; i++) {
        final p = pointAt(i, series.length, series[i]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      return path;
    }

    // Comparison line: lighter and thinner.
    if (comparison.length > 1) {
      canvas.drawPath(
        linePath(comparison),
        Paint()
          ..color = AppColors.neutralGrey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Main line with a soft fill beneath it.
    if (values.length > 1) {
      final line = linePath(values);
      final fill = Path.from(line)
        ..lineTo(plotWidth, plotHeight)
        ..lineTo(0, plotHeight)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, 0, plotWidth, plotHeight)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (values.isNotEmpty) {
      final last = pointAt(values.length - 1, values.length, values.last);
      canvas.drawCircle(last, 4, Paint()..color = color);
      canvas.drawCircle(last, 2, Paint()..color = Colors.white);
    }

    _text(canvas, startLabel, Offset(0, plotHeight + 4));
    _text(canvas, endLabel, Offset(plotWidth, plotHeight + 4), alignRight: true);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.values != values ||
      old.comparison != comparison ||
      old.startLabel != startLabel ||
      old.endLabel != endLabel ||
      old.color != color;
}
