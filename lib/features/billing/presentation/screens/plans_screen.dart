/// Plan comparison screen.
///
/// Displays all available plans in horizontally scrollable cards
/// on mobile, or in a responsive grid on tablet. Each card shows
/// features, limits, pricing, and "Current"/"Upgrade" badges.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';
import 'package:sanbao_flutter/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:sanbao_flutter/features/billing/presentation/providers/billing_provider.dart';
import 'package:sanbao_flutter/features/billing/presentation/widgets/plan_card.dart';

/// Screen showing all available plans for comparison and selection.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  String? _loadingPlanId;

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
          children: plans.map((plan) {
            return PlanCard(
              plan: plan,
              isCurrent: plan.id == currentPlanId,
              isLoading: _loadingPlanId == plan.id,
              onSelect: () => _selectPlan(plan),
            );
          }).toList(),
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
