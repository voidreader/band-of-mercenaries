import 'package:flutter/material.dart';

class CampsitePainter extends CustomPainter {
  final int mercenaryCount;

  CampsitePainter({required this.mercenaryCount});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Ground
    final groundPaint = Paint()..color = const Color(0xFFE8E0D0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: size.width * 0.7, height: 40),
      groundPaint,
    );

    // Campfire logs
    final logPaint = Paint()..color = const Color(0xFF8B4513)..strokeWidth = 4;
    canvas.drawLine(Offset(cx - 12, cy + 8), Offset(cx + 12, cy + 8), logPaint);
    canvas.drawLine(Offset(cx - 8, cy + 12), Offset(cx + 8, cy + 4), logPaint);

    // Fire
    final firePaint = Paint()..color = const Color(0xFFFF6600);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 16, height: 24),
      firePaint,
    );
    final innerFire = Paint()..color = const Color(0xFFFFCC00);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 2), width: 8, height: 14),
      innerFire,
    );

    // Sparks
    final sparkPaint = Paint()..color = const Color(0xFFFFAA00)..strokeWidth = 2;
    canvas.drawCircle(Offset(cx - 4, cy - 20), 2, sparkPaint);
    canvas.drawCircle(Offset(cx + 6, cy - 24), 1.5, sparkPaint);

    // Mercenaries (simple dot figures)
    final bodyPaint = Paint()..color = const Color(0xFF444444);
    final headPaint = Paint()..color = const Color(0xFF666666);
    final positions = [
      Offset(cx - 50, cy + 5),
      Offset(cx + 50, cy + 5),
      Offset(cx - 30, cy + 15),
      Offset(cx + 30, cy + 15),
      Offset(cx - 60, cy + 18),
      Offset(cx + 60, cy + 18),
    ];

    for (var i = 0; i < mercenaryCount.clamp(0, positions.length); i++) {
      final pos = positions[i];
      // Body
      canvas.drawRect(Rect.fromCenter(center: pos, width: 8, height: 12), bodyPaint);
      // Head
      canvas.drawCircle(Offset(pos.dx, pos.dy - 10), 5, headPaint);
    }

    // Tent (left)
    final tentPaint = Paint()..color = const Color(0xFF9E8E7E);
    final tentPath = Path()
      ..moveTo(cx - 80, cy - 10)
      ..lineTo(cx - 60, cy - 35)
      ..lineTo(cx - 40, cy - 10)
      ..close();
    canvas.drawPath(tentPath, tentPaint);

    // Tent (right)
    final tentPath2 = Path()
      ..moveTo(cx + 40, cy - 10)
      ..lineTo(cx + 60, cy - 35)
      ..lineTo(cx + 80, cy - 10)
      ..close();
    canvas.drawPath(tentPath2, tentPaint);
  }

  @override
  bool shouldRepaint(CampsitePainter oldDelegate) =>
      mercenaryCount != oldDelegate.mercenaryCount;
}
