/// Sanbao avatar widget with image/initials and deterministic color.
///
/// Supports network images with cached fallback and initials-based
/// avatars with a deterministic background color based on the name.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Size presets for the avatar.
enum SanbaoAvatarSize {
  /// 24px diameter.
  xs(24),

  /// 32px diameter.
  sm(32),

  /// 40px diameter.
  md(40),

  /// 48px diameter.
  lg(48),

  /// 64px diameter.
  xl(64),

  /// 96px diameter.
  xxl(96);

  const SanbaoAvatarSize(this.diameter);

  /// The diameter in logical pixels.
  final double diameter;

  /// Font size for initials, scaled to the diameter.
  double get fontSize => diameter * 0.38;
}

/// A circular avatar that shows an image or initials with a
/// deterministic background color.
class SanbaoAvatar extends StatelessWidget {
  const SanbaoAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = SanbaoAvatarSize.md,
    this.backgroundColor,
    this.borderColor,
    this.showBorder = false,
    this.onTap,
  });

  /// URL for the avatar image. If null or loading fails, initials are shown.
  final String? imageUrl;

  /// Name used to generate initials and deterministic color.
  final String? name;

  /// Size preset.
  final SanbaoAvatarSize size;

  /// Override for the background color.
  final Color? backgroundColor;

  /// Border color (only if [showBorder] is true).
  final Color? borderColor;

  /// Whether to show a border around the avatar.
  final bool showBorder;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final effectiveBgColor =
        backgroundColor ?? name?.avatarColor ?? SanbaoColors.avatarPalette[0];

    Widget avatar = Container(
      width: size.diameter,
      height: size.diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBgColor,
        border: showBorder
            ? Border.all(
                color: borderColor ?? colors.bgSurface,
                width: 2,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(effectiveBgColor),
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildContent(Color bgColor) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: size.diameter,
        height: size.diameter,
        fit: BoxFit.cover,
        placeholder: (_, __) => _InitialsContent(
          name: name,
          size: size,
          bgColor: bgColor,
        ),
        errorWidget: (_, __, ___) => _InitialsContent(
          name: name,
          size: size,
          bgColor: bgColor,
        ),
      );
    }

    return _InitialsContent(name: name, size: size, bgColor: bgColor);
  }
}

/// Initials content for the avatar fallback.
class _InitialsContent extends StatelessWidget {
  const _InitialsContent({
    required this.name,
    required this.size,
    required this.bgColor,
  });

  final String? name;
  final SanbaoAvatarSize size;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final initials = name?.initials ?? '?';

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size.fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// A group of overlapping avatars for displaying multiple users.
class SanbaoAvatarGroup extends StatelessWidget {
  const SanbaoAvatarGroup({
    required this.avatars,
    super.key,
    this.maxDisplay = 4,
    this.size = SanbaoAvatarSize.sm,
    this.overlapFraction = 0.3,
  });

  /// List of (imageUrl, name) pairs for each avatar.
  final List<({String? imageUrl, String name})> avatars;

  /// Maximum number of avatars to display before showing a count.
  final int maxDisplay;

  /// Size preset.
  final SanbaoAvatarSize size;

  /// Fraction of overlap between adjacent avatars (0-1).
  final double overlapFraction;

  @override
  Widget build(BuildContext context) {
    final displayCount =
        avatars.length > maxDisplay ? maxDisplay : avatars.length;
    final remaining = avatars.length - displayCount;
    final offset = size.diameter * (1 - overlapFraction);

    return SizedBox(
      width: offset * (displayCount + (remaining > 0 ? 1 : 0)) +
          size.diameter * overlapFraction,
      height: size.diameter,
      child: Stack(
        children: [
          for (var i = 0; i < displayCount; i++)
            Positioned(
              left: i * offset,
              child: SanbaoAvatar(
                imageUrl: avatars[i].imageUrl,
                name: avatars[i].name,
                size: size,
                showBorder: true,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: displayCount * offset,
              child: Container(
                width: size.diameter,
                height: size.diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.sanbaoColors.bgSurfaceAlt,
                  border: Border.all(
                    color: context.sanbaoColors.bgSurface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      fontSize: size.fontSize * 0.8,
                      fontWeight: FontWeight.w600,
                      color: context.sanbaoColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
