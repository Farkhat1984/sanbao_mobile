/// Sanbao loading skeleton with shimmer animation.
///
/// Provides skeleton placeholders for various content types
/// to display during data loading.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A shimmer-animated skeleton placeholder.
class SanbaoSkeleton extends StatelessWidget {
  const SanbaoSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.isCircle = false,
  });

  /// Creates a skeleton line for text content.
  const SanbaoSkeleton.line({
    super.key,
    this.width,
    this.height = 14,
  })  : borderRadius = null,
        isCircle = false;

  /// Creates a skeleton box for card/image content.
  const SanbaoSkeleton.box({
    super.key,
    this.width,
    this.height = 120,
    this.borderRadius,
  }) : isCircle = false;

  /// Creates a circular skeleton for avatars.
  const SanbaoSkeleton.circle({
    super.key,
    double size = 40,
  })  : width = size,
        height = size,
        borderRadius = null,
        isCircle = true;

  /// Width of the skeleton. Null means fill available space.
  final double? width;

  /// Height of the skeleton.
  final double height;

  /// Border radius override.
  final BorderRadius? borderRadius;

  /// Whether to render as a circle.
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final baseColor = colors.bgSurfaceAlt;
    final highlightColor = colors.bgSurfaceHover;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: isCircle ? null : (borderRadius ?? SanbaoRadius.sm),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

/// A skeleton placeholder for a conversation list item.
class SanbaoConversationSkeleton extends StatelessWidget {
  const SanbaoConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SanbaoSkeleton.circle(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SanbaoSkeleton.line(
                    width: MediaQuery.sizeOf(context).width * 0.5,
                  ),
                  const SizedBox(height: 8),
                  const SanbaoSkeleton.line(height: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SanbaoSkeleton.line(width: 40, height: 12),
          ],
        ),
      );
}

/// A skeleton placeholder for a message bubble.
class SanbaoMessageSkeleton extends StatelessWidget {
  const SanbaoMessageSkeleton({
    super.key,
    this.isUser = false,
  });

  final bool isUser;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: isUser ? 64 : 16,
          right: isUser ? 16 : 64,
          top: 8,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            SanbaoSkeleton.box(
              height: 60,
              borderRadius: isUser
                  ? SanbaoRadius.userMessage
                  : SanbaoRadius.assistantMessage,
            ),
          ],
        ),
      );
}

/// A list of skeleton items for loading states.
class SanbaoSkeletonList extends StatelessWidget {
  const SanbaoSkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
  });

  /// Number of skeleton items to show.
  final int itemCount;

  /// Custom builder for each skeleton item. Defaults to conversation skeleton.
  final Widget Function(BuildContext, int)? itemBuilder;

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: itemCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: itemBuilder ??
            (context, index) => const SanbaoConversationSkeleton(),
      );
}
