import 'package:flutter/material.dart';

/// The official Synapse brand logo rendered precisely from the design SVG in:
/// `stitch_saas_dashboard_redesign (1)/code.html` and `screen.png`.
///
/// Features:
/// - Dark elevated tile (`#161922`) with hairline border (`#262B38`) and rounded corners (`rx: 10`).
/// - Upper electric blue connection arc (`#3B82F6`, stroke-width: 2.5, linecap: round).
/// - Central glowing synapse node (`#60A5FA`, radius: 3.5).
/// - Lower chevron bridge (`#94A3B8`, stroke-width: 2.0, linecap/linejoin: round).
class SynapseLogo extends StatelessWidget {
  const SynapseLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SynapseLogoPainter(),
    );
  }
}

class _SynapseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40.0;

    // 1. Background rounded container with border (rect width="40" height="40" rx="10")
    final bgPaint = Paint()
      ..color = const Color(0xFF161922)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF262B38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s;

    final rect = Rect.fromLTWH(
      0.75 * s,
      0.75 * s,
      size.width - 1.5 * s,
      size.height - 1.5 * s,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(10 * s));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // 2. Upper electric blue connection arc:
    // path d="M12 20C12 15.5817 15.5817 12 20 12C24.4183 12 28 15.5817 28 20"
    final arcPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    final arcPath = Path()
      ..moveTo(12 * s, 20 * s)
      ..cubicTo(12 * s, 15.5817 * s, 15.5817 * s, 12 * s, 20 * s, 12 * s)
      ..cubicTo(24.4183 * s, 12 * s, 28 * s, 15.5817 * s, 28 * s, 20 * s);
    canvas.drawPath(arcPath, arcPaint);

    // 3. Central glowing synapse node circle (cx="20" cy="20" r="3.5" fill="#60A5FA")
    final circlePaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(20 * s, 20 * s), 3.5 * s, circlePaint);

    // 4. Lower chevron bridge (path d="M14 27L20 20L26 27" stroke="#94A3B8")
    final chevronPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final chevronPath = Path()
      ..moveTo(14 * s, 27 * s)
      ..lineTo(20 * s, 20 * s)
      ..lineTo(26 * s, 27 * s);
    canvas.drawPath(chevronPath, chevronPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
