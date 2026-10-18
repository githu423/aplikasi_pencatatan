import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../widgets/app_mascot.dart';

/// Layar Kunci Keamanan PIN & Sensor Sidik Jari
class PinLockScreen extends StatefulWidget {
  final String correctPinHash;
  final bool biometricEnabled;
  final VoidCallback? onSuccess;

  const PinLockScreen({
    super.key,
    required this.correctPinHash,
    this.biometricEnabled = false,
    this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String _errorMessage = '';
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    if (widget.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateBiometric();
      });
    }
  }

  Future<void> _authenticateBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari untuk membuka Catatan Keuangan',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (_) {}
  }

  void _onKeyPressed(String key) {
    HapticFeedback.lightImpact();
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += key;
        _errorMessage = '';
      });

      if (_enteredPin.length >= 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _verifyPin() {
    final hashed = sha256.convert(utf8.encode(_enteredPin)).toString();
    if (hashed == widget.correctPinHash) {
      HapticFeedback.mediumImpact();
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      if (_enteredPin.length == 6) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'PIN salah. Silakan coba lagi.';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const AppMascot(size: 80, mood: MascotMood.normal),
            const SizedBox(height: 16),
            Text(
              'Masukkan PIN',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan kode keamanan untuk membuka aplikasi',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),

            // Indikator Titik PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? theme.colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? theme.colorScheme.primary : Colors.grey,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],

            const Spacer(),

            // Keypad Angka
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Tombol Biometrik
                      widget.biometricEnabled
                          ? IconButton(
                              icon: const Icon(Icons.fingerprint, size: 36),
                              onPressed: _authenticateBiometric,
                            )
                          : const SizedBox(width: 64, height: 64),

                      _buildKeypadButton('0'),

                      // Tombol Hapus
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 28),
                        onPressed: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: keys.map((k) => _buildKeypadButton(k)).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    return InkWell(
      onTap: () => _onKeyPressed(key),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        child: Text(
          key,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
