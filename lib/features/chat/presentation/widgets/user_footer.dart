/// User footer section for the sidebar drawer.
///
/// Displays the current user's avatar, name, email, and a
/// settings button. Matches the web sidebar footer layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_avatar.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';

/// Bottom footer in the drawer showing user info and settings access.
///
/// Displays:
/// - User avatar (image or initials)
/// - User display name
/// - User email
/// - Settings gear icon button
class UserFooter extends ConsumerWidget {
  const UserFooter({
    super.key,
    this.onSettingsTap,
    this.onProfileTap,
  });

  /// Callback when the settings icon is pressed.
  final VoidCallback? onSettingsTap;

  /// Callback when the user avatar/name area is pressed.
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final user = ref.watch(currentUserProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 12 + context.bottomPadding,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onProfileTap?.call();
            },
            child: SanbaoAvatar(
              imageUrl: user?.image,
              name: user?.displayName,
              size: SanbaoAvatarSize.sm,
            ),
          ),

          const SizedBox(width: 10),

          // Name and email
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onProfileTap?.call();
              },
              child: _UserInfo(user: user),
            ),
          ),

          // Admin badge (if applicable)
          if (user?.isAdmin ?? false)
            _FooterIconButton(
              icon: Icons.shield_rounded,
              tooltip: 'Админ',
              onTap: () {
                HapticFeedback.selectionClick();
                // Admin panel navigation (placeholder)
              },
            ),

          // Settings button
          _FooterIconButton(
            icon: Icons.settings_rounded,
            tooltip: 'Настройки',
            onTap: () {
              HapticFeedback.selectionClick();
              onSettingsTap?.call();
            },
          ),
        ],
      ),
    );
  }
}

/// Displays the user's name and email in a compact layout.
class _UserInfo extends StatelessWidget {
  const _UserInfo({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          user?.displayName ?? 'Гость',
          style: context.textTheme.titleSmall?.copyWith(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          user?.email ?? 'Войдите в аккаунт',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// A small icon button used in the footer row.
class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 16,
              color: colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
