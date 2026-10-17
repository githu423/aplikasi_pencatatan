import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/repositories/finance_repository.dart';
import '../../widgets/app_mascot.dart';
import 'birthday_manager.dart';
import 'candle_blowing_screen.dart';

/// Widget maskot mengambang di pojok layar saat hari ulang tahun
class BirthdayMascotCornerWidget extends StatefulWidget {
  const BirthdayMascotCornerWidget({super.key});

  @override
  State<BirthdayMascotCornerWidget> createState() => _BirthdayMascotCornerWidgetState();
}

class _BirthdayMascotCornerWidgetState extends State<BirthdayMascotCornerWidget> {
  late ConfettiController _confettiController;
  bool _isDancing = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onMascotTap(BuildContext context) {
    final repo = context.read<FinanceRepository>();
    final isMuted = repo.profile?.isMuted ?? false;

    // Getaran Haptic jika tidak di-mute
    if (!isMuted) {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _isDancing = true;
    });

    _confettiController.play();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isDancing = false;
        });
      }
    });

    _showCelebrationDialog(context);
  }

  void _showCelebrationDialog(BuildContext context) {
    final repo = context.read<FinanceRepository>();
    final birthdayManager = context.read<BirthdayManager>();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const AppMascot(
                size: 80,
                mood: MascotMood.celebrating,
                isDancing: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Selamat Ulang Tahun!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                birthdayManager.currentGreeting.isNotEmpty
                    ? birthdayManager.currentGreeting
                    : 'Semoga harimu menyenangkan dan penuh kebahagiaan!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CandleBlowingScreen(
                              userName: repo.profile?.name ?? 'Kawan',
                              age: birthdayManager.currentAge,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cake_outlined),
                      label: const Text('Tiup Lilin'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () {
                      repo.toggleMute();
                    },
                    icon: Icon(
                      (repo.profile?.isMuted ?? false)
                          ? Icons.volume_off
                          : Icons.volume_up,
                    ),
                    tooltip: 'Bisukan Getaran/Suara',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bday = context.watch<BirthdayManager>();
    if (!bday.isBirthdayToday) return const SizedBox.shrink();

    return Positioned(
      bottom: 84, // Tepat di atas BottomNavigationBar
      right: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 20,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.pink,
              Colors.amber,
              Colors.purple,
            ],
          ),
          Material(
            color: Colors.transparent,
            child: Tooltip(
              message: 'Ketuk aku untuk kejutan!',
              child: AppMascot(
                size: 64,
                mood: MascotMood.celebrating,
                isDancing: _isDancing,
                onTap: () => _onMascotTap(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
