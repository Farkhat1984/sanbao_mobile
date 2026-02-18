/// Notification bell icon with animated unread count badge.
///
/// Shows a bell icon with a red badge indicating the number
/// of unread notifications. Tapping opens the notification list.
/// The badge and bell animate when the unread count changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/notifications/presentation/providers/notification_provider.dart';
import 'package:sanbao_flutter/features/notifications/presentation/widgets/notification_list.dart';

/// A bell icon button with an animated unread notification count badge.
///
/// Used in the app bar to provide quick access to notifications.
/// The red badge shows the unread count, and the bell icon shakes
/// briefly when new notifications arrive.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Oscillating rotation: 0 -> -10deg -> 10deg -> -5deg -> 5deg -> 0
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -0.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.15, end: 0.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.15, end: -0.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.08, end: 0.04)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.04, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final colors = context.sanbaoColors;

    // Trigger shake animation when count increases
    if (unreadCount > _previousCount && _previousCount >= 0) {
      _shakeController.forward(from: 0);
    }
    _previousCount = unreadCount;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.rotate(
        angle: _shakeAnimation.value,
        child: child,
      ),
      child: IconButton(
        onPressed: () => showNotificationList(context: context),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedSwitcher(
              duration: SanbaoAnimations.durationFast,
              child: Icon(
                unreadCount > 0
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_outlined,
                key: ValueKey(unreadCount > 0),
                color: unreadCount > 0 ? colors.accent : colors.textMuted,
                size: 24,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -4,
                child: _AnimatedUnreadBadge(count: unreadCount),
              ),
          ],
        ),
        tooltip: 'Уведомления',
      ),
    );
  }
}

/// The red unread count badge with scale-in animation.
class _AnimatedUnreadBadge extends StatefulWidget {
  const _AnimatedUnreadBadge({required this.count});

  final int count;

  @override
  State<_AnimatedUnreadBadge> createState() => _AnimatedUnreadBadgeState();
}

class _AnimatedUnreadBadgeState extends State<_AnimatedUnreadBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: SanbaoAnimations.durationNormal,
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: SanbaoAnimations.springCurve,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedUnreadBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      // Re-animate on count change
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = widget.count > 99 ? '99+' : '${widget.count}';
    final isWide = displayCount.length > 1;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: SanbaoAnimations.durationFast,
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 5 : 0,
          vertical: 1,
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        decoration: BoxDecoration(
          color: SanbaoColors.error,
          borderRadius: isWide
              ? const BorderRadius.all(Radius.circular(8))
              : null,
          shape: isWide ? BoxShape.rectangle : BoxShape.circle,
        ),
        child: Center(
          child: Text(
            displayCount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
