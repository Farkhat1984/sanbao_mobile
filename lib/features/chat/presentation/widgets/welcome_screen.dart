/// Welcome screen shown when there are no messages.
///
/// Displays the Sanbao compass animation, agent info (if active),
/// starter prompt cards, and a quick action for image generation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_compass.dart';
import 'package:sanbao_flutter/features/image_gen/presentation/screens/image_gen_screen.dart';

/// Starter prompt definition.
class _StarterPrompt {
  const _StarterPrompt({
    required this.icon,
    required this.title,
    required this.prompt,
  });

  final IconData icon;
  final String title;
  final String prompt;
}

/// Default starter prompts for the Sanbao assistant.
const _defaultPrompts = [
  _StarterPrompt(
    icon: Icons.gavel_rounded,
    title: 'Правовой вопрос',
    prompt: 'Какие права имеет работник при задержке заработной платы?',
  ),
  _StarterPrompt(
    icon: Icons.description_rounded,
    title: 'Создать документ',
    prompt: 'Составь договор оказания услуг между ИП и ТОО',
  ),
  _StarterPrompt(
    icon: Icons.analytics_rounded,
    title: 'Анализ',
    prompt: 'Проанализируй статью 188 УК РК и её судебную практику',
  ),
  _StarterPrompt(
    icon: Icons.lightbulb_rounded,
    title: 'Бизнес-идея',
    prompt: 'Помоги составить бизнес-план для открытия кофейни в Алматы',
  ),
];

/// The welcome screen shown in an empty chat.
///
/// Features the animated Sanbao compass, a greeting message,
/// and interactive starter prompt cards that populate the input.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    this.agentName,
    this.agentDescription,
    this.agentIcon,
    this.agentColor,
    this.onPromptSelected,
  });

  /// Agent's display name (null for default Sanbao).
  final String? agentName;

  /// Agent's description text.
  final String? agentDescription;

  /// Agent's icon name.
  final String? agentIcon;

  /// Agent's color hex string.
  final String? agentColor;

  /// Callback when a starter prompt is tapped.
  final void Function(String prompt)? onPromptSelected;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _staggerController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            400 + (_defaultPrompts.length * SanbaoAnimations.staggerDelay.inMilliseconds),
      ),
    )..forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final isDefault = widget.agentName == null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo animation
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _logoController,
                curve: SanbaoAnimations.springCurve,
              ),
              child: FadeTransition(
                opacity: _logoController,
                child: _buildLogo(colors, isDefault),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            FadeTransition(
              opacity: _logoController,
              child: Text(
                isDefault ? 'Sanbao' : widget.agentName!,
                style: context.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            FadeTransition(
              opacity: _logoController,
              child: Text(
                isDefault
                    ? 'AI-платформа для профессионалов.\nЗадайте вопрос, чтобы начать.'
                    : widget.agentDescription ??
                        'AI-агент. Задайте вопрос, чтобы начать.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Starter prompts
            ..._buildPromptCards(context),

            // Image generation quick action
            if (AppConfig.enableImageGeneration) ...[
              const SizedBox(height: 8),
              _buildImageGenCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(SanbaoColorScheme colors, bool isDefault) {
    if (isDefault) {
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SanbaoColors.accent, SanbaoColors.legalRef],
          ),
          borderRadius: SanbaoRadius.lg,
          boxShadow: SanbaoShadows.md,
        ),
        child: const Center(
          child: SanbaoCompass(
            size: 32,
            color: Colors.white,
          ),
        ),
      );
    }

    // Agent logo
    final agentColor = widget.agentColor?.toColor() ?? SanbaoColors.accent;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: agentColor,
        borderRadius: SanbaoRadius.lg,
        boxShadow: SanbaoShadows.md,
      ),
      child: Center(
        child: Text(
          (widget.agentName ?? 'A').initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPromptCards(BuildContext context) {
    final colors = context.sanbaoColors;

    return List.generate(_defaultPrompts.length, (index) {
      final prompt = _defaultPrompts[index];
      final delay = index * SanbaoAnimations.staggerDelay.inMilliseconds;
      final totalDuration = _staggerController.duration!.inMilliseconds;

      // Calculate staggered animation interval
      final startFraction = delay / totalDuration;
      final endFraction = (delay + 300) / totalDuration;

      return FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            startFraction.clamp(0.0, 1.0),
            endFraction.clamp(0.0, 1.0),
            curve: SanbaoAnimations.smoothCurve,
          ),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              startFraction.clamp(0.0, 1.0),
              endFraction.clamp(0.0, 1.0),
              curve: SanbaoAnimations.smoothCurve,
            ),
          ),),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onPromptSelected?.call(prompt.prompt);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: SanbaoRadius.md,
                  border: Border.all(
                    color: colors.border,
                    width: 0.5,
                  ),
                  boxShadow: SanbaoShadows.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.accentLight,
                        borderRadius: SanbaoRadius.sm,
                      ),
                      child: Icon(
                        prompt.icon,
                        size: 18,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prompt.title,
                            style: context.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prompt.prompt,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Builds the image generation quick action card.
  ///
  /// Uses a distinct rose/pink color scheme to visually separate it
  /// from the text prompt cards.
  Widget _buildImageGenCard(BuildContext context) {
    final colors = context.sanbaoColors;
    const roseColor = Color(0xFFF43F5E);
    const roseBg = Color(0xFFFFF1F2);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        showImageGenSheet(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: SanbaoRadius.md,
          border: Border.all(
            color: roseColor.withValues(alpha: 0.15),
            width: 0.5,
          ),
          boxShadow: SanbaoShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: roseBg,
                borderRadius: SanbaoRadius.sm,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: roseColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Генерация изображения',
                    style: context.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Создайте изображение по текстовому описанию',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: roseColor,
            ),
          ],
        ),
      ),
    );
  }
}
