/// Plan comparison screen.
///
/// Displays all available plans in horizontally scrollable cards
/// on mobile, or in a responsive grid on tablet. Each card shows
/// features, limits, pricing, and "Current"/"Upgrade" badges.
/// Includes a promo code input section at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/presentation/providers/billing_provider.dart';
import 'package:sanbao_flutter/features/billing/presentation/widgets/plan_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen showing all available plans for comparison and selection.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  String? _loadingPlanId;
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final plansState = ref.watch(plansProvider);
    final subscriptionState = ref.watch(subscriptionProvider);

    // Extract current plan ID from subscription
    final currentPlanId = switch (subscriptionState) {
      SubscriptionLoaded(:final subscription) => subscription?.planId,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тарифные планы'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: switch (plansState) {
        PlansLoading() => Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.accent,
            ),
          ),
        PlansLoaded(:final plans) => _buildPlansList(
            context,
            plans,
            currentPlanId,
          ),
        PlansError(:final message) => _buildError(context, ref, message),
      },
    );
  }

  Widget _buildPlansList(
    BuildContext context,
    List<Plan> plans,
    String? currentPlanId,
  ) {
    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'Выберите план, подходящий для ваших задач',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: context.isMobile
              ? _buildHorizontalList(plans, currentPlanId)
              : _buildGrid(plans, currentPlanId),
        ),
        _PromoCodeSection(controller: _promoController),
      ],
    );
  }

  Widget _buildHorizontalList(List<Plan> plans, String? currentPlanId) =>
      ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < plans.length - 1 ? 12 : 0,
            ),
            child: PlanCard(
              plan: plan,
              isCurrent: plan.id == currentPlanId,
              isLoading: _loadingPlanId == plan.id,
              onSelect: () => _selectPlan(plan),
            ),
          );
        },
      );

  Widget _buildGrid(List<Plan> plans, String? currentPlanId) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: plans.map((plan) => PlanCard(
              plan: plan,
              isCurrent: plan.id == currentPlanId,
              isLoading: _loadingPlanId == plan.id,
              onSelect: () => _selectPlan(plan),
            ),).toList(),
        ),
      );

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    final colors = context.sanbaoColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: context.textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SanbaoButton(
              label: 'Повторить',
              variant: SanbaoButtonVariant.secondary,
              leadingIcon: Icons.refresh_rounded,
              onPressed: () => ref.read(plansProvider.notifier).loadPlans(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPlan(Plan plan) async {
    setState(() => _loadingPlanId = plan.id);

    try {
      final url = await ref
          .read(billingRepositoryProvider)
          .createCheckoutUrl(planId: plan.id);

      if (url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Не удалось открыть страницу оплаты');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingPlanId = null);
      }
    }
  }
}

// ---- Promo Code Section ----

/// Promo code input section with apply button and validation feedback.
class _PromoCodeSection extends ConsumerWidget {
  const _PromoCodeSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final promoState = ref.watch(promoCodeProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          top: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Промокод',
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SanbaoInput(
                  controller: controller,
                  hint: 'Введите промокод',
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  enabled: promoState is! PromoCodeValidating,
                  onSubmitted: (_) => _onApply(ref),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: SanbaoButton(
                  label: 'Применить',
                  isLoading: promoState is PromoCodeValidating,
                  isDisabled: promoState is PromoCodeValidating,
                  onPressed: () => _onApply(ref),
                ),
              ),
            ],
          ),
          _buildPromoFeedback(context, promoState),
        ],
      ),
    );
  }

  void _onApply(WidgetRef ref) {
    final code = controller.text.trim();
    if (code.isEmpty) return;
    ref.read(promoCodeProvider.notifier).applyPromoCode(code);
  }

  Widget _buildPromoFeedback(BuildContext context, PromoCodeState state) {
    final colors = context.sanbaoColors;

    return switch (state) {
      PromoCodeInitial() || PromoCodeValidating() => const SizedBox.shrink(),
      PromoCodeApplied(:final discount) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.successLight,
              borderRadius: SanbaoRadius.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: colors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Промокод применён: скидка $discount%',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      PromoCodeInvalid(:final message) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.errorLight,
              borderRadius: SanbaoRadius.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: colors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      PromoCodeError(:final message) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.error,
            ),
          ),
        ),
    };
  }
}
