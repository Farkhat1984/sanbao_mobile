/// Animated thinking/status indicator for AI response generation.
///
/// Shows different animations and labels depending on what the AI
/// is currently doing: thinking, searching, using tools, planning,
/// or answering.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/chat_event.dart';

/// Visual configuration for a specific thinking state.
class _ThinkingVisuals {
  const _ThinkingVisuals({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.dotColor,
  });

  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final Color dotColor;
}

/// An animated indicator showing the AI's current activity.
///
/// Displays an icon with animation, a label, and pulsing dots.
/// The visuals change based on the [phase] and optional [toolName].
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({
    required this.phase,
    super.key,
    this.agentName,
    this.toolName,
  });

  /// The current streaming phase.
  final StreamingPhase phase;

  /// The agent's display name (defaults to "Sanbao").
  final String? agentName;

  /// The name of the tool currently being used (if any).
  final String? toolName;

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationNormal,
    )..forward();
  }

  @override
  void didUpdateWidget(ThinkingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.toolName != widget.toolName) {
      _slideController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  _ThinkingVisuals _resolveVisuals() {
    final name = widget.agentName ?? 'Sanbao';
    final category = ToolCategory.fromToolName(widget.toolName);

    return switch (widget.phase) {
      StreamingPhase.thinking => _ThinkingVisuals(
          icon: Icons.psychology_rounded,
          label: '$name думает',
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          dotColor: const Color(0xFF8B5CF6),
        ),
      StreamingPhase.searching => widget.toolName != null &&
              category != ToolCategory.webSearch
          ? _toolVisuals(category)
          : const _ThinkingVisuals(
              icon: Icons.travel_explore_rounded,
              label: 'Ищет в интернете',
              gradientColors: [Color(0xFF10B981), Color(0xFF0D9488)],
              dotColor: Color(0xFF10B981),
            ),
      StreamingPhase.usingTool => _toolVisuals(category),
      StreamingPhase.planning => _ThinkingVisuals(
          icon: Icons.checklist_rounded,
          label: '$name составляет план',
          gradientColors: const [Color(0xFFF59E0B), Color(0xFFF97316)],
          dotColor: const Color(0xFFF59E0B),
        ),
      StreamingPhase.answering => _ThinkingVisuals(
          icon: Icons.chat_rounded,
          label: '$name отвечает',
          gradientColors: const [
            SanbaoColors.accent,
            SanbaoColors.legalRef,
          ],
          dotColor: SanbaoColors.accent,
        ),
    };
  }

  _ThinkingVisuals _toolVisuals(ToolCategory category) => switch (category) {
        ToolCategory.webSearch => const _ThinkingVisuals(
            icon: Icons.travel_explore_rounded,
            label: 'Ищет в интернете',
            gradientColors: [Color(0xFF10B981), Color(0xFF0D9488)],
            dotColor: Color(0xFF10B981),
          ),
        ToolCategory.knowledge => const _ThinkingVisuals(
            icon: Icons.storage_rounded,
            label: 'Ищет в базе знаний',
            gradientColors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
            dotColor: Color(0xFF6366F1),
          ),
        ToolCategory.calculation => const _ThinkingVisuals(
            icon: Icons.calculate_rounded,
            label: 'Вычисляет',
            gradientColors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)],
            dotColor: Color(0xFF0EA5E9),
          ),
        ToolCategory.memory => const _ThinkingVisuals(
            icon: Icons.bookmark_rounded,
            label: 'Сохраняет в память',
            gradientColors: [Color(0xFFEC4899), Color(0xFFE11D48)],
            dotColor: Color(0xFFEC4899),
          ),
        ToolCategory.task => const _ThinkingVisuals(
            icon: Icons.assignment_rounded,
            label: 'Создает задачу',
            gradientColors: [Color(0xFFF59E0B), Color(0xFFF97316)],
            dotColor: Color(0xFFF59E0B),
          ),
        ToolCategory.notification => const _ThinkingVisuals(
            icon: Icons.notifications_rounded,
            label: 'Отправляет уведомление',
            gradientColors: [Color(0xFFEAB308), Color(0xFFF59E0B)],
            dotColor: Color(0xFFEAB308),
          ),
        ToolCategory.scratchpad => const _ThinkingVisuals(
            icon: Icons.sticky_note_2_rounded,
            label: 'Работает с заметками',
            gradientColors: [Color(0xFF84CC16), Color(0xFF22C55E)],
            dotColor: Color(0xFF84CC16),
          ),
        ToolCategory.chart => const _ThinkingVisuals(
            icon: Icons.bar_chart_rounded,
            label: 'Строит график',
            gradientColors: [Color(0xFF06B6D4), Color(0xFF0D9488)],
            dotColor: Color(0xFF06B6D4),
          ),
        ToolCategory.http => const _ThinkingVisuals(
            icon: Icons.send_rounded,
            label: 'Выполняет запрос',
            gradientColors: [Color(0xFFF97316), Color(0xFFEF4444)],
            dotColor: Color(0xFFF97316),
          ),
        ToolCategory.mcp => const _ThinkingVisuals(
            icon: Icons.extension_rounded,
            label: 'Использует плагин',
            gradientColors: [Color(0xFFA855F7), Color(0xFFD946EF)],
            dotColor: Color(0xFFA855F7),
          ),
        ToolCategory.generic => const _ThinkingVisuals(
            icon: Icons.build_rounded,
            label: 'Использует инструменты',
            gradientColors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
            dotColor: Color(0xFF3B82F6),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final visuals = _resolveVisuals();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: SanbaoAnimations.smoothCurve,
      )),
      child: FadeTransition(
        opacity: _slideController,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon container
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: visuals.gradientColors,
                  ),
                  borderRadius: SanbaoRadius.sm,
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _iconController,
                    builder: (context, child) => Transform.scale(
                      scale: 0.85 + (_iconController.value * 0.15),
                      child: child,
                    ),
                    child: Icon(
                      visuals.icon,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Label text
              Text(
                visuals.label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),

              const SizedBox(width: 8),

              // Pulsing dots
              _PulsingDots(color: visuals.dotColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three pulsing dots animation for loading indication.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots({required this.color});

  final Color color;

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final delay = index * 0.2;
          final t = (_controller.value - delay).clamp(0.0, 1.0);
          final scale = 0.6 + (0.4 * _bounce(t));
          final opacity = 0.3 + (0.7 * _bounce(t));

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Simple bounce function for dot animation.
  double _bounce(double t) {
    if (t < 0.5) return t * 2;
    return (1 - t) * 2;
  }
}
