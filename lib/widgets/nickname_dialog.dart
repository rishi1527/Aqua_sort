import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../services/haptic_service.dart';

/// Glassmorphism dialog for updating the player's display nickname with
/// real-time character validation and 7-day cooldown enforcement.
class NicknameDialog extends StatefulWidget {
  final String currentNickname;
  final bool canChange;
  final int daysRemaining;
  final ValueChanged<String> onNicknameSaved;

  const NicknameDialog({
    super.key,
    required this.currentNickname,
    required this.canChange,
    this.daysRemaining = 0,
    required this.onNicknameSaved,
  });

  static Future<String?> show(
    BuildContext context, {
    required String currentNickname,
    required bool canChange,
    int daysRemaining = 0,
    required ValueChanged<String> onNicknameSaved,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NicknameDialog(
        currentNickname: currentNickname,
        canChange: canChange,
        daysRemaining: daysRemaining,
        onNicknameSaved: onNicknameSaved,
      ),
    );
  }

  @override
  State<NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<NicknameDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  static const int minLength = 3;
  static const int maxLength = 15;
  static final RegExp allowedCharsRegex = RegExp(r'^[a-zA-Z0-9_ ]+$');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorMessage = 'Nickname cannot be empty');
      return;
    }
    if (trimmed.length < minLength) {
      setState(
        () => _errorMessage = 'Nickname must be at least $minLength characters',
      );
      return;
    }
    if (trimmed.length > maxLength) {
      setState(
        () => _errorMessage = 'Nickname cannot exceed $maxLength characters',
      );
      return;
    }
    if (!allowedCharsRegex.hasMatch(trimmed)) {
      setState(
        () => _errorMessage = 'Only letters, numbers, spaces, and _ allowed',
      );
      return;
    }
    setState(() => _errorMessage = null);
  }

  void _onSave() {
    if (!widget.canChange) return;

    final trimmed = _controller.text.trim();
    _validateInput(trimmed);

    if (_errorMessage != null) {
      SoundService.instance.playInvalidMove();
      HapticService.instance.invalidMove();
      return;
    }

    SoundService.instance.playButtonTap();
    HapticService.instance.buttonTap();
    widget.onNicknameSaved(trimmed);
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E0854), Color(0xFF140224)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFC084FC).withValues(alpha: 0.50),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: 0.35),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9333EA), Color(0xFF6B21A8)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFC084FC).withValues(alpha: 0.7),
                      ),
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHANGE NICKNAME',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your public leaderboard display name',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: Color(0xFFC084FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Cooldown Banner
              if (!widget.canChange)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFB7185).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_top_rounded,
                        color: Color(0xFFFB7185),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nickname cooldown active. You can change your name again in ${widget.daysRemaining} days.',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFDAD6),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0A3C).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF38BDF8),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nicknames can be changed once every 7 days.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            color: Color(0xFFE9D5FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Text Field
              TextFormField(
                controller: _controller,
                enabled: widget.canChange,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLength: maxLength,
                onChanged: _validateInput,
                decoration: InputDecoration(
                  labelText: 'Nickname (3-15 chars)',
                  labelStyle: const TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFFC084FC),
                  ),
                  counterStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Color(0xFFC084FC),
                    fontSize: 11,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E0A3C).withValues(alpha: 0.55),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF38BDF8),
                      width: 1.8,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE11D48)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE11D48),
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              // Error Text Display
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFB7185),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE9D5FF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: widget.canChange ? _onSave : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.canChange
                            ? const Color(0xFF9333EA)
                            : const Color(0xFF4B5563),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: widget.canChange ? 6 : 0,
                      ),
                      child: Text(
                        widget.canChange ? 'SAVE NICKNAME' : 'LOCKED',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
