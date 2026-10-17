import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Maskot kartun lucu yang digambar 100% menggunakan kode CustomPainter
enum MascotMood { normal, happy, celebrating }

class AppMascot extends StatefulWidget {
  final double size;
  final MascotMood mood;
  final bool isDancing;
  final VoidCallback? onTap;

  const AppMascot({
    super.key,
    this.size = 80,
    this.mood = MascotMood.normal,
    this.isDancing = false,
    this.onTap,
  });

  @override
  State<AppMascot> createState() => _AppMascotState();
}

class _AppMascotState extends State<AppMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _rotateAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AppMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDancing && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final dy = widget.isDancing ? _bounceAnim.value * 2.0 : _bounceAnim.value;
          final angle = widget.isDancing ? _rotateAnim.value * 2.0 : _rotateAnim.value;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: angle,
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _MascotPainter(mood: widget.mood),
          ),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;

  _MascotPainter({required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.54);

    final faceRadius = w * 0.36;

    // 1. Telinga Kucing / Beruang
    final earPaint = Paint()..color = const Color(0xFFFBBF24); // Kuning emas hangat
    final innerEarPaint = Paint()..color = const Color(0xFFF472B6); // Merah muda

    // Telinga Kiri
    final leftEarCenter = Offset(w * 0.26, h * 0.28);
    canvas.drawCircle(leftEarCenter, w * 0.14, earPaint);
    canvas.drawCircle(leftEarCenter, w * 0.08, innerEarPaint);

    // Telinga Kanan
    final rightEarCenter = Offset(w * 0.74, h * 0.28);
    canvas.drawCircle(rightEarCenter, w * 0.14, earPaint);
    canvas.drawCircle(rightEarCenter, w * 0.08, innerEarPaint);

    // 2. Kepala
    canvas.drawCircle(center, faceRadius, earPaint);

    // 3. Pipi Merona (Blushing Cheeks)
    final blushPaint = Paint()
      ..color = const Color(0xFFFF85A1).withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.28, h * 0.58), width: w * 0.16, height: h * 0.10),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.72, h * 0.58), width: w * 0.16, height: h * 0.10),
      blushPaint,
    );

    // 4. Mata
    final eyePaint = Paint()..color = const Color(0xFF1E293B);
    final sparklePaint = Paint()..color = Colors.white;

    if (mood == MascotMood.happy || mood == MascotMood.celebrating) {
      // Mata tersenyum bahagia (lengkungan bulan sabit)
      final happyEyePaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round;

      final leftEyePath = Path()
        ..moveTo(w * 0.30, h * 0.50)
        ..quadraticBezierTo(w * 0.36, h * 0.44, w * 0.42, h * 0.50);
      canvas.drawPath(leftEyePath, happyEyePaint);

      final rightEyePath = Path()
        ..moveTo(w * 0.58, h * 0.50)
        ..quadraticBezierTo(w * 0.64, h * 0.44, w * 0.70, h * 0.50);
      canvas.drawPath(rightEyePath, happyEyePaint);
    } else {
      // Mata bulat imut dengan kilau
      final leftEyePos = Offset(w * 0.36, h * 0.48);
      final rightEyePos = Offset(w * 0.64, h * 0.48);
      final eyeSize = w * 0.07;

      canvas.drawCircle(leftEyePos, eyeSize, eyePaint);
      canvas.drawCircle(rightEyePos, eyeSize, eyePaint);

      // Kilau mata
      canvas.drawCircle(Offset(w * 0.34, h * 0.46), eyeSize * 0.4, sparklePaint);
      canvas.drawCircle(Offset(w * 0.62, h * 0.46), eyeSize * 0.4, sparklePaint);
    }

    // 5. Hidung & Mulut
    final nosePaint = Paint()..color = const Color(0xFF7C2D12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.54), width: w * 0.06, height: h * 0.04),
      nosePaint,
    );

    final mouthPaint = Paint()
      ..color = const Color(0xFF7C2D12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(w * 0.43, h * 0.58)
      ..quadraticBezierTo(w * 0.50, h * 0.64, w * 0.57, h * 0.58);
    canvas.drawPath(mouthPath, mouthPaint);

    // 6. Topi Ulang Tahun jika mood == celebrating
    if (mood == MascotMood.celebrating) {
      final hatPath = Path()
        ..moveTo(w * 0.50, h * 0.02) // Puncak topi
        ..lineTo(w * 0.32, h * 0.24)
        ..lineTo(w * 0.68, h * 0.24)
        ..close();

      final hatPaint = Paint()..color = const Color(0xFF8B5CF6);
      canvas.drawPath(hatPath, hatPaint);

      // Garis pola topi
      final stripePaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = w * 0.03
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.40, h * 0.14), Offset(w * 0.60, h * 0.14), stripePaint);

      // Pom-pom puncak topi
      final pompomPaint = Paint()..color = const Color(0xFFEC4899);
      canvas.drawCircle(Offset(w * 0.50, h * 0.02), w * 0.05, pompomPaint);
    } else {
      // Koin medali keberuntungan finansial di bawah dagu
      final coinPaint = Paint()..color = const Color(0xFFEAB308);
      canvas.drawCircle(Offset(w * 0.50, h * 0.82), w * 0.08, coinPaint);

      final coinInnerPaint = Paint()
        ..color = const Color(0xFFCA8A04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015;
      canvas.drawCircle(Offset(w * 0.50, h * 0.82), w * 0.06, coinInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) {
    return oldDelegate.mood != mood;
  }
}
