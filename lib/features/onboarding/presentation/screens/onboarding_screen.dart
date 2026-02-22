/// Four-step onboarding screen with PageView navigation.
///
/// Steps:
/// 1. Welcome -- SanbaoCompass animation + brand message
/// 2. AI Chat -- chat feature introduction
/// 3. Agents -- specialized agents showcase
/// 4. Get Started -- CTA to begin using the app
///
/// Each step features a large illustration, title, description,
/// dot indicators, Skip button, and Next/Start button.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_compass.dart';
import 'package:sanbao_flutter/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:sanbao_flutter/features/onboarding/presentation/widgets/feature_highlight.dart';
import 'package:sanbao_flutter/features/onboarding/presentation/widgets/onboarding_step.dart';

/// Number of onboarding steps.
const int _totalSteps = 4;

/// The main onboarding screen shown to first-time users.
///
/// Uses a [PageView] for horizontal swiping between steps.
/// Persists completion state via [onboardingCompletedProvider].
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _totalSteps - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_isLastPage) {
      _completeOnboarding();
      return;
    }

    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: SanbaoAnimations.durationNormal,
      curve: SanbaoAnimations.smoothCurve,
    );
  }

  void _skip() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    ref.read(onboardingCompletedProvider.notifier).complete();
    context.go(RoutePaths.chat);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with Skip button
            _buildTopBar(colors),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomeStep(),
                  _buildChatStep(),
                  _buildAgentsStep(),
                  _buildGetStartedStep(),
                ],
              ),
            ),

            // Bottom area: dot indicators + action button
            _buildBottomArea(colors),
          ],
        ),
      ),
    );
  }

  /// Top bar with Skip button (hidden on last page).
  Widget _buildTopBar(SanbaoColorScheme colors) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: _isLastPage ? 0.0 : 1.0,
            duration: SanbaoAnimations.durationFast,
            child: TextButton(
              onPressed: _isLastPage ? null : _skip,
              child: Text(
                'Пропустить',
                style: TextStyle(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );

  /// Bottom section with dot indicators and action button.
  Widget _buildBottomArea(SanbaoColorScheme colors) => Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators
          _DotIndicators(
            total: _totalSteps,
            current: _currentPage,
          ),

          const SizedBox(height: 32),

          // Action button
          SanbaoButton(
            label: _isLastPage ? 'Начать' : 'Далее',
            onPressed: _goToNextPage,
            variant: _isLastPage
                ? SanbaoButtonVariant.gradient
                : SanbaoButtonVariant.primary,
            size: SanbaoButtonSize.large,
            isExpanded: true,
            trailingIcon: _isLastPage
                ? Icons.arrow_forward_rounded
                : Icons.chevron_right_rounded,
          ),
        ],
      ),
    );

  // ---- Step Builders ----

  /// Step 1: Welcome with animated compass.
  Widget _buildWelcomeStep() => OnboardingStep(
      title: 'Добро пожаловать\nв Sanbao',
      subtitle: 'Ваш интеллектуальный помощник для работы с правовыми '
          'документами, анализом и юридическими консультациями.',
      child: _WelcomeIllustration(),
    );

  /// Step 2: AI Chat feature.
  Widget _buildChatStep() => OnboardingStep(
      title: 'Общайтесь\nс AI ассистентом',
      subtitle: 'Задавайте вопросы на естественном языке, получайте '
          'развернутые ответы с ссылками на законодательство.',
      child: _ChatIllustration(),
    );

  /// Step 3: Agents feature.
  Widget _buildAgentsStep() => OnboardingStep(
      title: 'Выбирайте\nспециализированных агентов',
      subtitle: 'Каждый агент обучен для конкретной области права. '
          'Создавайте собственных агентов под ваши задачи.',
      child: _AgentsIllustration(),
    );

  /// Step 4: Get Started CTA.
  Widget _buildGetStartedStep() => OnboardingStep(
      title: 'Начните\nпрямо сейчас',
      subtitle: 'Задайте свой первый вопрос и откройте возможности '
          'AI-ассистента для юридической практики.',
      child: _GetStartedIllustration(),
    );
}

// ---- Dot Indicators ----

/// Horizontal row of animated dot indicators.
class _DotIndicators extends StatelessWidget {
  const _DotIndicators({
    required this.total,
    required this.current,
  });

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: SanbaoAnimations.durationNormal,
          curve: SanbaoAnimations.smoothCurve,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive ? colors.accent : colors.border,
            borderRadius: SanbaoRadius.full,
          ),
        );
      }),
    );
  }
}

// ---- Step Illustrations ----

/// Welcome step: Large animated SanbaoCompass with gradient glow.
class _WelcomeIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gradient circle behind compass
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SanbaoColors.gradientStart, SanbaoColors.gradientEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: SanbaoColors.accent.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: SanbaoCompass(
              state: CompassState.thinking,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Brand subtitle
        Text(
          'AI Legal Assistant',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: SanbaoColors.accent.withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
        ),
      ],
    );
}

/// Chat step: Simulated chat bubble layout.
class _ChatIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chat icon circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colors.accentLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: 24),
        // Feature cards
        const FeatureHighlight(
          icon: Icons.chat_rounded,
          label: 'Диалоги на естественном языке',
          color: SanbaoColors.accent,
          delay: Duration(milliseconds: 100),
        ),
        const SizedBox(height: 8),
        const FeatureHighlight(
          icon: Icons.gavel_rounded,
          label: 'Ссылки на статьи законов',
          color: SanbaoColors.legalRef,
          delay: Duration(milliseconds: 200),
        ),
        const SizedBox(height: 8),
        const FeatureHighlight(
          icon: Icons.description_rounded,
          label: 'Генерация документов',
          color: SanbaoColors.success,
          delay: Duration(milliseconds: 300),
        ),
      ],
    );
  }
}

/// Agents step: Grid of agent type previews.
class _AgentsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grid of mini agent cards
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _MiniAgentCard(
              icon: Icons.gavel_rounded,
              label: 'Юрист',
              color: SanbaoColors.legalRef,
              delay: Duration(milliseconds: 60),
            ),
            _MiniAgentCard(
              icon: Icons.account_balance_rounded,
              label: 'Финансы',
              color: SanbaoColors.accent,
              delay: Duration(milliseconds: 120),
            ),
            _MiniAgentCard(
              icon: Icons.description_rounded,
              label: 'Документы',
              color: SanbaoColors.success,
              delay: Duration(milliseconds: 180),
            ),
            _MiniAgentCard(
              icon: Icons.search_rounded,
              label: 'Поиск',
              color: SanbaoColors.info,
              delay: Duration(milliseconds: 240),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FeatureHighlight(
          icon: Icons.add_circle_outline_rounded,
          label: 'Создавайте собственных агентов',
          color: colors.accent,
          delay: const Duration(milliseconds: 320),
        ),
      ],
    );
  }
}

/// Mini agent card for the agents illustration.
class _MiniAgentCard extends StatefulWidget {
  const _MiniAgentCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Duration delay;

  @override
  State<_MiniAgentCard> createState() => _MiniAgentCardState();
}

class _MiniAgentCardState extends State<_MiniAgentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationSlow,
    );

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SanbaoAnimations.springCurve,
      ),
    );

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: SanbaoRadius.lg,
          border: Border.all(
            color: colors.border.withValues(alpha: 0.7),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 22, color: widget.color),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Get Started step: Animated gradient icon with sparkle effect.
class _GetStartedIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rocket/launch icon with gradient
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SanbaoColors.accent.withValues(alpha: 0.15),
                SanbaoColors.legalRef.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.rocket_launch_rounded,
              size: 64,
              color: SanbaoColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Summary features
        const FeatureHighlight(
          icon: Icons.bolt_rounded,
          label: 'Мгновенные ответы',
          color: SanbaoColors.warning,
          delay: Duration(milliseconds: 100),
        ),
        const SizedBox(height: 8),
        const FeatureHighlight(
          icon: Icons.security_rounded,
          label: 'Безопасность данных',
          color: SanbaoColors.success,
          delay: Duration(milliseconds: 200),
        ),
      ],
    );
}
