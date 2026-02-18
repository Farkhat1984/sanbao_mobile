/// Voice input button with speech-to-text integration.
///
/// Features pulsing ring animation while recording, simple waveform
/// visualization, auto-stop on silence, Russian language recognition,
/// and runtime permission handling via permission_handler.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Callback signature for voice recognition results.
typedef VoiceResultCallback = void Function(String recognizedText);

/// The current state of the voice recording session.
enum VoiceRecordingState {
  /// No recording in progress.
  idle,

  /// Actively listening for speech input.
  listening,

  /// Processing the final recognition result.
  processing,
}

/// A microphone button with full speech-to-text capability.
///
/// Tapping toggles recording on/off. While recording, displays a pulsing
/// ring animation and a simple sound level waveform. Automatically stops
/// after a silence timeout. Recognition language defaults to Russian.
class VoiceButton extends StatefulWidget {
  const VoiceButton({
    super.key,
    this.onResult,
    this.onPartialResult,
    this.onRecordingStateChanged,
    this.onTap,
    this.size = 44,
    this.locale = 'ru_RU',
    this.silenceTimeout = const Duration(seconds: 3),
  });

  /// Called when a final recognition result is available.
  final VoiceResultCallback? onResult;

  /// Called with interim/partial recognition results.
  final VoiceResultCallback? onPartialResult;

  /// Called when the recording state changes.
  final void Function({required bool isRecording})? onRecordingStateChanged;

  /// Fallback tap callback (when speech-to-text is unavailable).
  final VoidCallback? onTap;

  /// The button size in logical pixels (minimum 48 for accessibility).
  final double size;

  /// Recognition language locale code.
  final String locale;

  /// Duration of silence before auto-stopping.
  final Duration silenceTimeout;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isAvailable = false;
  VoiceRecordingState _recordingState = VoiceRecordingState.idle;
  double _soundLevel = 0.0;
  Timer? _silenceTimer;

  late final AnimationController _pulseController;
  late final AnimationController _waveController;

  /// Stores recent sound levels for the waveform visualization.
  final List<double> _waveformLevels = List.filled(12, 0.0);
  int _waveformIndex = 0;

  bool get _isListening => _recordingState == VoiceRecordingState.listening;
  bool get _isActive => _recordingState != VoiceRecordingState.idle;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      _isInitialized = true;
      if (mounted) setState(() {});
    } on Object {
      _isAvailable = false;
      _isInitialized = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  // ---- Speech Callbacks ----

  void _onStatus(String status) {
    // speech_to_text reports: 'listening', 'notListening', 'done'
    if (status == 'notListening' || status == 'done') {
      _stopRecording();
    }
  }

  void _onError(Object error) {
    _stopRecording();
    if (mounted) {
      final errorStr = error.toString();
      // Silence/no-match is not a user-facing error -- ignore gracefully
      if (errorStr.contains('error_no_match') ||
          errorStr.contains('error_speech_timeout')) {
        return;
      }
      context.showErrorSnackBar('Ошибка распознавания речи');
    }
  }

  void _onSoundLevelChange(double level) {
    // Normalize level (speech_to_text reports dB, typically -2 to 10+)
    final normalized = ((level + 2) / 12).clamp(0.0, 1.0);

    _waveformLevels[_waveformIndex % _waveformLevels.length] = normalized;
    _waveformIndex++;

    if (mounted) {
      setState(() {
        _soundLevel = normalized;
      });
    }

    // Reset silence timer on significant sound
    if (normalized > 0.15) {
      _resetSilenceTimer();
    }
  }

  // ---- Recording Control ----

  Future<void> _toggleRecording() async {
    await HapticFeedback.mediumImpact();

    if (_isListening) {
      _stopRecording();
      return;
    }

    // Check & request microphone permission
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (mounted) {
        if (permissionStatus.isPermanentlyDenied) {
          _showPermissionDeniedDialog();
        } else {
          context.showErrorSnackBar(
            'Нет разрешения на использование микрофона',
          );
        }
      }
      return;
    }

    // Check speech recognition availability
    if (!_isAvailable) {
      if (!_isInitialized) {
        await _initializeSpeech();
      }
      if (!_isAvailable) {
        widget.onTap?.call();
        return;
      }
    }

    _startRecording();
  }

  void _startRecording() {
    setState(() => _recordingState = VoiceRecordingState.listening);
    _pulseController.repeat(reverse: true);

    // Reset waveform
    _waveformLevels.fillRange(0, _waveformLevels.length, 0.0);
    _waveformIndex = 0;

    widget.onRecordingStateChanged?.call(isRecording: true);

    _speech.listen(
      onResult: _onRecognitionResult,
      onSoundLevelChange: _onSoundLevelChange,
      localeId: widget.locale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
      ),
    );

    _resetSilenceTimer();
  }

  void _stopRecording() {
    if (!_isActive) return;

    _silenceTimer?.cancel();
    _speech.stop();

    setState(() {
      _recordingState = VoiceRecordingState.idle;
      _soundLevel = 0.0;
    });

    _pulseController
      ..stop()
      ..reset();

    widget.onRecordingStateChanged?.call(isRecording: false);
  }

  void _onRecognitionResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      setState(() => _recordingState = VoiceRecordingState.processing);

      final text = result.recognizedWords.trim();
      if (text.isNotEmpty) {
        widget.onResult?.call(text);
      }
      _stopRecording();
    } else {
      final partialText = result.recognizedWords.trim();
      if (partialText.isNotEmpty) {
        widget.onPartialResult?.call(partialText);
      }
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(widget.silenceTimeout, () {
      if (_isListening) {
        _stopRecording();
      }
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.sanbaoColors;
        return AlertDialog(
          backgroundColor: colors.bgSurface,
          shape: const RoundedRectangleBorder(borderRadius: SanbaoRadius.lg),
          title: Text(
            'Доступ к микрофону',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Text(
            'Для голосового ввода необходимо разрешение на использование '
            'микрофона. Вы можете включить его в настройках приложения.',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Отмена',
                style: TextStyle(color: colors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
              child: Text(
                'Настройки',
                style: TextStyle(color: colors.accent),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Semantics(
      button: true,
      label: _isActive ? 'Остановить запись' : 'Голосовой ввод',
      child: GestureDetector(
        onTap: _toggleRecording,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing ring (visible only when recording)
              if (_isActive)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.35);
                    final opacity = 1.0 - (_pulseController.value * 0.7);

                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SanbaoColors.error,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Sound level ring (visible when recording)
              if (_isActive)
                _SoundLevelRing(
                  size: widget.size - 4,
                  level: _soundLevel,
                ),

              // Button circle
              AnimatedContainer(
                duration: SanbaoAnimations.durationFast,
                width: widget.size - 8,
                height: widget.size - 8,
                decoration: BoxDecoration(
                  color: _isActive
                      ? SanbaoColors.error.withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isActive ? Icons.stop_rounded : Icons.mic_none_rounded,
                  size: 22,
                  color: _isActive ? SanbaoColors.error : colors.textMuted,
                ),
              ),

              // Waveform visualization (compact, below the button)
              if (_isActive)
                Positioned(
                  bottom: -2,
                  child: _MiniWaveform(
                    levels: List<double>.from(_waveformLevels),
                    width: widget.size - 12,
                    height: 4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a thin ring whose opacity scales with the current sound level.
class _SoundLevelRing extends StatelessWidget {
  const _SoundLevelRing({
    required this.size,
    required this.level,
  });

  final double size;
  final double level;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 80),
        opacity: (level * 0.6).clamp(0.0, 0.6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: size + (level * 6),
          height: size + (level * 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: SanbaoColors.error.withValues(alpha: 0.4),
              width: 1.5 + (level * 1.5),
            ),
          ),
        ),
      );
}

/// A minimal waveform visualization showing recent sound levels.
class _MiniWaveform extends StatelessWidget {
  const _MiniWaveform({
    required this.levels,
    required this.width,
    required this.height,
  });

  final List<double> levels;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(width, height),
        painter: _WaveformPainter(
          levels: levels,
          color: SanbaoColors.error.withValues(alpha: 0.5),
        ),
      );
}

/// Custom painter for the mini waveform bars.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.levels,
    required this.color,
  });

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    final barCount = levels.length;
    final spacing = size.width / barCount;

    for (var i = 0; i < barCount; i++) {
      final level = levels[i].clamp(0.05, 1.0);
      final barHeight = size.height * level;
      final x = (i * spacing) + (spacing / 2);
      final y = (size.height - barHeight) / 2;

      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}
