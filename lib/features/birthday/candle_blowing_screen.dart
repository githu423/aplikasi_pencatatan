import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../widgets/app_mascot.dart';

/// Halaman interaktif tiup lilin kue ulang tahun
class CandleBlowingScreen extends StatefulWidget {
  final String userName;
  final int age;

  const CandleBlowingScreen({
    super.key,
    required this.userName,
    required this.age,
  });

  @override
  State<CandleBlowingScreen> createState() => _CandleBlowingScreenState();
}

class _CandleBlowingScreenState extends State<CandleBlowingScreen> {
  late ConfettiController _confettiController;
  late List<bool> _candlesLit; // true = nyala, false = mati
  int _candlesCount = 1;
  bool _allBlown = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    // Tampilkan lilin sesuai usia (dibatasi maksimal 8 lilin visual agar rapi di layar, atau sesuai usia)
    _candlesCount = widget.age > 0 ? (widget.age > 7 ? 7 : widget.age) : 1;
    _candlesLit = List.generate(_candlesCount, (_) => true);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _blowCandle(int index) {
    if (!_candlesLit[index]) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _candlesLit[index] = false;
      if (_candlesLit.every((lit) => !lit)) {
        _allBlown = true;
        _confettiController.play();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _relightCandles() {
    setState(() {
      _candlesLit = List.generate(_candlesCount, (_) => true);
      _allBlown = false;
    });
  }

  void _shareBirthdayCard() {
    final text = '🎉 Selamat Ulang Tahun ke-${widget.age} untuk ${widget.userName}!\n'
        'Semoga semua harapan, mimpi, dan target tabungan tahun ini tercapai dengan berkah!\n'
        'Dicatat dengan bangga di ${AppConstants.appName} 🎂✨';
    Share.share(text, subject: 'Selamat Ulang Tahun ${widget.userName}!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiup Lilin Ulang Tahun'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan Ucapan',
            onPressed: _shareBirthdayCard,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const AppMascot(
                  size: 90,
                  mood: MascotMood.celebrating,
                  isDancing: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'Selamat Ulang Tahun ke-${widget.age}!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _allBlown
                      ? '✨ Hore! Semua lilin telah padam! Semoga doamu terkabul! ✨'
                      : 'Ketuk tiap api lilin untuk meniupnya!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _allBlown ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: _allBlown ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 30),

                // Kue Ulang Tahun dengan Lilin
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Gambar Kue (Custom Painter)
                        Positioned(
                          bottom: 0,
                          child: CustomPaint(
                            size: const Size(280, 160),
                            painter: _CakePainter(),
                          ),
                        ),

                        // Barisan Lilin di atas kue
                        Positioned(
                          top: 25,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_candlesCount, (index) {
                              final isLit = _candlesLit[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: GestureDetector(
                                  onTap: () => _blowCandle(index),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Api Lilin atau Asap
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        height: 32,
                                        width: 20,
                                        child: isLit
                                            ? CustomPaint(
                                                painter: _FlamePainter(),
                                              )
                                            : const Icon(
                                                Icons.cloud_outlined,
                                                size: 22,
                                                color: Colors.grey,
                                              ),
                                      ),
                                      // Batang Lilin
                                      Container(
                                        width: 14,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: index % 2 == 0
                                                ? [Colors.pinkAccent, Colors.pink.shade200]
                                                : [Colors.lightBlueAccent, Colors.blue.shade200],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(1, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Tombol Aksi
                if (_allBlown) ...[
                  ElevatedButton.icon(
                    onPressed: _shareBirthdayCard,
                    icon: const Icon(Icons.share),
                    label: const Text('Bagikan Kartu Ucapan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _relightCandles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nyalakan Lagi Lilinnya'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      // Tiup semua sekaligus
                      for (int i = 0; i < _candlesLit.length; i++) {
                        _blowCandle(i);
                      }
                    },
                    icon: const Icon(Icons.air),
                    label: const Text('Tiup Semua Lilin Sekaligus'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Hujan Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: math.pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 25,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.amber,
            ],
          ),
        ],
      ),
    );
  }
}

/// Painter Kue Ulang Tahun
class _CakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Piring kue
    final platePaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h - 16, w, 16),
        const Radius.circular(8),
      ),
      platePaint,
    );

    // Lapisan Bawah Kue (Cokelat Lembut)
    final bottomCakePaint = Paint()..color = const Color(0xFF8B5E3C);
    final bottomRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, h - 80, w - 40, 64),
      const Radius.circular(12),
    );
    canvas.drawRRect(bottomRect, bottomCakePaint);

    // Krim Leleh Lapisan Bawah
    final creamPaint = Paint()..color = const Color(0xFFFDF2E9);
    final creamPath = Path();
    creamPath.moveTo(20, h - 80);
    for (double x = 20; x <= w - 20; x += 25) {
      creamPath.quadraticBezierTo(x + 12.5, h - 68, x + 25, h - 80);
    }
    creamPath.close();
    canvas.drawPath(creamPath, creamPaint);

    // Lapisan Atas Kue (Krim Stroberi)
    final topCakePaint = Paint()..color = const Color(0xFFF472B6);
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(45, h - 140, w - 90, 64),
      const Radius.circular(12),
    );
    canvas.drawRRect(topRect, topCakePaint);

    // Krim Cokelat Putih / Vanila di bagian atas
    final topCreamPaint = Paint()..color = Colors.white;
    final topCreamPath = Path();
    topCreamPath.moveTo(45, h - 140);
    for (double x = 45; x <= w - 45; x += 20) {
      topCreamPath.quadraticBezierTo(x + 10, h - 128, x + 20, h - 140);
    }
    topCreamPath.close();
    canvas.drawPath(topCreamPath, topCreamPaint);

    // Topping Buah Ceri
    final cherryPaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(Offset(w * 0.35, h - 146), 8, cherryPaint);
    canvas.drawCircle(Offset(w * 0.50, h - 148), 9, cherryPaint);
    canvas.drawCircle(Offset(w * 0.65, h - 146), 8, cherryPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter Nyala Api Lilin
class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cahaya Luar (Kuning/Oranye)
    final outerFlame = Paint()..color = const Color(0xFFF59E0B);
    final outerPath = Path()
      ..moveTo(w / 2, 0)
      ..quadraticBezierTo(w, h * 0.6, w / 2, h)
      ..quadraticBezierTo(0, h * 0.6, w / 2, 0)
      ..close();
    canvas.drawPath(outerPath, outerFlame);

    // Bagian Dalam (Putih-Kuning)
    final innerFlame = Paint()..color = const Color(0xFFFEF08A);
    final innerPath = Path()
      ..moveTo(w / 2, h * 0.25)
      ..quadraticBezierTo(w * 0.8, h * 0.65, w / 2, h * 0.95)
      ..quadraticBezierTo(w * 0.2, h * 0.65, w / 2, h * 0.25)
      ..close();
    canvas.drawPath(innerPath, innerFlame);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
