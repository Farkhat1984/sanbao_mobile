/// Billing overview screen.
///
/// Shows the current plan card, usage indicators (messages/tokens/storage
/// progress bars), payment history list, and upgrade/cancel buttons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/usage.dart';
import 'package:sanbao_flutter/features/billing/presentation/providers/billing_provider.dart';
import 'package:sanbao_flutter/features/billing/presentation/widgets/subscription_badge.dart';
import 'package:sanbao_flutter/features/billing/presentation/widgets/usage_indicator.dart';

/// Main billing overview screen showing plan, usage, and payment history.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписка'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(subscriptionProvider.notifier).loadSubscription();
          await ref.read(usageProvider.notifier).loadUsage();
          await ref.read(paymentHistoryProvider.notifier).loadHistory();
        },
        color: colors.accent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CurrentPlanSection(),
            const SizedBox(height: 24),
            _UsageSection(),
            const SizedBox(height: 24),
            _PaymentHistorySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---- Current Plan Section ----

class _CurrentPlanSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final subscriptionState = ref.watch(subscriptionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Текущий план',
          style: context.textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        switch (subscriptionState) {
          SubscriptionLoading() => _buildLoadingCard(context),
          SubscriptionLoaded(:final subscription) =>
            _buildPlanCard(context, ref, subscription),
          SubscriptionError(:final message) =>
            _buildErrorCard(context, ref, message),
        },
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) => SanbaoCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.sanbaoColors.accent,
              ),
            ),
          ),
        ),
      );

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    Subscription? subscription,
  ) {
    final colors = context.sanbaoColors;
    final planName =
        subscription?.plan?.displayName ?? 'Бесплатный';
    final isFree = subscription == null ||
        (subscription.plan?.isFree ?? false);

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFree
                      ? Icons.star_border_rounded
                      : Icons.workspace_premium_rounded,
                  color: colors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subscription != null) ...[
                      const SizedBox(height: 4),
                      SubscriptionBadge(
                        status: subscription.status,
                        size: SanbaoBadgeSize.small,
                      ),
                    ],
                  ],
                ),
              ),
              if (subscription != null && !isFree)
                Text(
                  subscription.plan?.formattedPrice ?? '',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (subscription != null && !isFree) ...[
            const SizedBox(height: 16),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 12),
            _buildPeriodInfo(context, subscription),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SanbaoButton(
                  label: isFree ? 'Улучшить план' : 'Сменить план',
                  size: SanbaoButtonSize.small,
                  leadingIcon: Icons.upgrade_rounded,
                  onPressed: () => context.push('/billing/plans'),
                ),
              ),
              if (subscription != null &&
                  !isFree &&
                  !subscription.cancelAtPeriodEnd) ...[
                const SizedBox(width: 12),
                SanbaoButton(
                  label: 'Отменить',
                  variant: SanbaoButtonVariant.ghost,
                  size: SanbaoButtonSize.small,
                  onPressed: () => _confirmCancel(context, ref),
                ),
              ],
            ],
          ),
          if (subscription != null && subscription.cancelAtPeriodEnd) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Подписка будет отменена ${_formatDate(subscription.currentPeriodEnd)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodInfo(BuildContext context, Subscription subscription) {
    final colors = context.sanbaoColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Период: ${_formatDate(subscription.currentPeriodStart)} '
          '- ${_formatDate(subscription.currentPeriodEnd)}',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        Text(
          '${subscription.daysRemaining} дн. осталось',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    final colors = context.sanbaoColors;

    return SanbaoCard(
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SanbaoButton(
            label: 'Повторить',
            variant: SanbaoButtonVariant.secondary,
            size: SanbaoButtonSize.small,
            leadingIcon: Icons.refresh_rounded,
            onPressed: () =>
                ref.read(subscriptionProvider.notifier).loadSubscription(),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showSanbaoConfirmDialog(
      context: context,
      title: 'Отменить подписку?',
      message: 'Подписка будет активна до конца текущего периода. '
          'После этого вы перейдёте на бесплатный план.',
      confirmLabel: 'Отменить подписку',
      cancelLabel: 'Оставить',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(subscriptionProvider.notifier).cancelSubscription();
    }
  }

  String _formatDate(DateTime date) =>
      DateFormat('dd.MM.yyyy', 'ru').format(date);
}

// ---- Usage Section ----

class _UsageSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final usageState = ref.watch(usageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Использование',
          style: context.textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        switch (usageState) {
          UsageLoading() => _buildLoadingIndicators(context),
          UsageLoaded(:final usage) => _buildUsageCards(context, usage),
          UsageError(:final message) => _buildError(context, ref, message),
        },
      ],
    );
  }

  Widget _buildLoadingIndicators(BuildContext context) => SanbaoCard(
        child: SizedBox(
          height: 100,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.sanbaoColors.accent,
              ),
            ),
          ),
        ),
      );

  Widget _buildUsageCards(BuildContext context, Usage usage) => SanbaoCard(
        child: Column(
          children: [
            UsageIndicator(
              label: 'Сообщения',
              currentValue: Usage.formatCount(usage.messagesUsed),
              maxValue: Usage.formatCount(usage.messagesLimit),
              progress: usage.messagesProgress,
            ),
            const SizedBox(height: 20),
            UsageIndicator(
              label: 'Токены',
              currentValue: Usage.formatCount(usage.tokensUsed),
              maxValue: Usage.formatCount(usage.tokensLimit),
              progress: usage.tokensProgress,
            ),
            const SizedBox(height: 20),
            UsageIndicator(
              label: 'Хранилище',
              currentValue: usage.formattedStorageUsed,
              maxValue: usage.formattedStorageLimit,
              progress: usage.storageProgress,
            ),
          ],
        ),
      );

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    final colors = context.sanbaoColors;

    return SanbaoCard(
      child: Column(
        children: [
          Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SanbaoButton(
            label: 'Повторить',
            variant: SanbaoButtonVariant.secondary,
            size: SanbaoButtonSize.small,
            onPressed: () => ref.read(usageProvider.notifier).loadUsage(),
          ),
        ],
      ),
    );
  }
}

// ---- Payment History Section ----

class _PaymentHistorySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final historyState = ref.watch(paymentHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'История платежей',
          style: context.textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        switch (historyState) {
          PaymentHistoryLoading() => _buildLoading(context),
          PaymentHistoryLoaded(:final payments) =>
            _buildPayments(context, payments),
          PaymentHistoryError(:final message) =>
            _buildError(context, ref, message),
        },
      ],
    );
  }

  Widget _buildLoading(BuildContext context) => SanbaoCard(
        child: SizedBox(
          height: 80,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.sanbaoColors.accent,
              ),
            ),
          ),
        ),
      );

  Widget _buildPayments(
    BuildContext context,
    List<PaymentHistoryItem> payments,
  ) {
    final colors = context.sanbaoColors;

    if (payments.isEmpty) {
      return SanbaoCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: colors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'История платежей пуста',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SanbaoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < payments.length; i++) ...[
            _PaymentRow(payment: payments[i]),
            if (i < payments.length - 1)
              Divider(
                color: colors.border,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    final colors = context.sanbaoColors;

    return SanbaoCard(
      child: Column(
        children: [
          Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SanbaoButton(
            label: 'Повторить',
            variant: SanbaoButtonVariant.secondary,
            size: SanbaoButtonSize.small,
            onPressed: () =>
                ref.read(paymentHistoryProvider.notifier).loadHistory(),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final PaymentHistoryItem payment;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final dateStr = DateFormat('dd.MM.yyyy', 'ru').format(payment.createdAt);

    final statusVariant = switch (payment.status) {
      PaymentStatus.succeeded => SanbaoBadgeVariant.success,
      PaymentStatus.pending => SanbaoBadgeVariant.warning,
      PaymentStatus.failed => SanbaoBadgeVariant.error,
      PaymentStatus.refunded => SanbaoBadgeVariant.neutral,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.bgSurfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.receipt_outlined,
              size: 18,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description ?? 'Оплата подписки',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment.formattedAmount,
                style: context.textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              SanbaoBadge(
                label: payment.status.displayLabel,
                variant: statusVariant,
                size: SanbaoBadgeSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
