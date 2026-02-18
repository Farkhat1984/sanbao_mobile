/// Beautiful plan card for the plan comparison screen.
///
/// Features: plan name, price, feature list with checkmarks, limits,
/// popular badge, gradient styling for pro plan, current/upgrade badges.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/usage.dart';

/// A visually rich plan card for the plan comparison view.
class PlanCard extends StatefulWidget {
  const PlanCard({
    required this.plan,
    super.key,
    this.isCurrent = false,
    this.onSelect,
    this.isLoading = false,
  });

  /// The plan to display.
  final Plan plan;

  /// Whether this is the user's current plan.
  final bool isCurrent;

  /// Callback when the user taps "Upgrade" / "Select".
  final VoidCallback? onSelect;

  /// Whether a checkout action is in progress.
  final bool isLoading;

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final isProGradient = widget.plan.isPopular;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.isCurrent ? null : widget.onSelect,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            gradient: isProGradient
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SanbaoColors.gradientStart,
                      SanbaoColors.gradientEnd,
                    ],
                  )
                : null,
            color: isProGradient ? null : colors.bgSurface,
            borderRadius: SanbaoRadius.lg,
            border: isProGradient
                ? null
                : Border.all(
                    color: widget.isCurrent
                        ? colors.accent
                        : colors.border,
                    width: widget.isCurrent ? 1.5 : 0.5,
                  ),
            boxShadow: isProGradient ? SanbaoShadows.md : SanbaoShadows.sm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(colors, isProGradient),
                const SizedBox(height: 16),
                _buildPrice(colors, isProGradient),
                const SizedBox(height: 20),
                _buildLimits(colors, isProGradient),
                const SizedBox(height: 16),
                _buildFeatures(colors, isProGradient),
                const SizedBox(height: 24),
                _buildAction(colors, isProGradient),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SanbaoColorScheme colors, bool isGradient) {
    final fgColor = isGradient ? colors.textInverse : colors.textPrimary;

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.plan.displayName,
            style: context.textTheme.titleLarge?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (widget.plan.isPopular)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isGradient
                  ? Colors.white.withValues(alpha: 0.2)
                  : colors.accentLight,
              borderRadius: SanbaoRadius.sm,
            ),
            child: Text(
              'Популярный',
              style: context.textTheme.labelSmall?.copyWith(
                color: isGradient ? Colors.white : colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (widget.isCurrent)
          SanbaoBadge(
            label: 'Текущий',
            variant: SanbaoBadgeVariant.success,
            size: SanbaoBadgeSize.small,
          ),
      ],
    );
  }

  Widget _buildPrice(SanbaoColorScheme colors, bool isGradient) {
    final fgColor = isGradient ? colors.textInverse : colors.textPrimary;
    final mutedColor = isGradient
        ? Colors.white.withValues(alpha: 0.7)
        : colors.textSecondary;

    if (widget.plan.isFree) {
      return Text(
        'Бесплатно',
        style: context.textTheme.headlineMedium?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final amount = (widget.plan.price / 100).toStringAsFixed(0);
    final symbol = switch (widget.plan.currency.toUpperCase()) {
      'RUB' => '\u20BD',
      'USD' => '\$',
      'EUR' => '\u20AC',
      _ => widget.plan.currency,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$amount $symbol',
          style: context.textTheme.headlineMedium?.copyWith(
            color: fgColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          widget.plan.interval.displayLabel,
          style: context.textTheme.bodySmall?.copyWith(
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLimits(SanbaoColorScheme colors, bool isGradient) {
    final mutedColor = isGradient
        ? Colors.white.withValues(alpha: 0.7)
        : colors.textSecondary;
    final limits = widget.plan.limits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LimitRow(
          label: 'Сообщений',
          value: Usage.formatCount(limits.messages),
          color: mutedColor,
        ),
        const SizedBox(height: 4),
        _LimitRow(
          label: 'Токенов',
          value: Usage.formatCount(limits.tokens),
          color: mutedColor,
        ),
        const SizedBox(height: 4),
        _LimitRow(
          label: 'Хранилище',
          value: Usage.formatBytes(limits.storage),
          color: mutedColor,
        ),
        const SizedBox(height: 4),
        _LimitRow(
          label: 'Агентов',
          value: limits.agents.toString(),
          color: mutedColor,
        ),
      ],
    );
  }

  Widget _buildFeatures(SanbaoColorScheme colors, bool isGradient) {
    final fgColor = isGradient ? colors.textInverse : colors.textPrimary;
    final checkColor = isGradient
        ? Colors.white.withValues(alpha: 0.9)
        : colors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.plan.features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_rounded, size: 16, color: checkColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: fgColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAction(SanbaoColorScheme colors, bool isGradient) {
    if (widget.isCurrent) {
      return SanbaoButton(
        label: 'Текущий план',
        variant: SanbaoButtonVariant.secondary,
        isDisabled: true,
        isExpanded: true,
      );
    }

    return SanbaoButton(
      label: widget.plan.isFree ? 'Перейти' : 'Выбрать',
      variant: isGradient
          ? SanbaoButtonVariant.secondary
          : SanbaoButtonVariant.primary,
      onPressed: widget.onSelect,
      isLoading: widget.isLoading,
      isExpanded: true,
      leadingIcon: Icons.arrow_forward_rounded,
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(color: color),
          ),
          Text(
            value,
            style: context.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}
