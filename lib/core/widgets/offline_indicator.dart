/// Animated offline indicator banner.
///
/// Displays a persistent banner at the top of the screen when the
/// device has no internet connection. Automatically shows and hides
/// with a slide + fade animation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/network/connectivity_provider.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';

/// Height of the offline indicator banner.
const double _kBannerHeight = 36.0;

/// Animated banner that slides in from the top when the device goes offline.
///
/// Uses [ConnectivityStatus] from [connectivityStatusProvider] to determine
/// visibility. The banner animates smoothly with a combined slide and fade
/// transition.
///
/// Place this widget at the top of a [Column] or [Stack] in your layout.
/// It will take zero vertical space when online (fully collapsed).
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     const OfflineIndicator(),
///     Expanded(child: content),
///   ],
/// )
/// ```
class OfflineIndicator extends ConsumerStatefulWidget {
  const OfflineIndicator({super.key});

  @override
  ConsumerState<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends ConsumerState<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ),);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);

    // Drive the animation based on connectivity state
    if (!isOnline) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // When fully hidden, take no space
        if (_controller.isDismissed) {
          return const SizedBox.shrink();
        }

        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _controller.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: FractionalTranslation(
                translation: Offset(0.0, _slideAnimation.value),
                child: child,
              ),
            ),
          ),
        );
      },
      child: _OfflineBannerContent(),
    );
  }
}

/// The visual content of the offline banner.
///
/// Separated from the animation logic for clarity and to avoid
/// rebuilding the content on every animation frame.
class _OfflineBannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<SanbaoColorScheme>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: _kBannerHeight,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2D1F08) // warningLight dark
            : SanbaoColors.warningLight,
        border: Border(
          bottom: BorderSide(
            color: SanbaoColors.warning.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: colors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            'Нет подключения к интернету',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? SanbaoColors.warning
                  : const Color(0xFF92400E), // amber-800
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact offline chip indicator for use in app bars or headers.
///
/// Shows a small "Офлайн" badge with a warning icon. More subtle than
/// the full-width [OfflineIndicator] banner.
class OfflineChip extends ConsumerWidget {
  const OfflineChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    if (isOnline) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<SanbaoColorScheme>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.warning.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 12,
            color: colors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            'Офлайн',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
