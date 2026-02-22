/// Widget that displays the generated image result.
///
/// Shows the image in a rounded container with action buttons
/// for saving and sharing.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';
import 'package:share_plus/share_plus.dart';

/// Displays a generated image with action buttons.
///
/// Supports both base64-encoded images and network URLs.
/// Provides save-to-gallery and share functionality.
class ImageGenResultView extends StatelessWidget {
  const ImageGenResultView({
    required this.result,
    required this.onReset,
    super.key,
  });

  /// The generation result to display.
  final ImageGenResult result;

  /// Callback to reset and generate a new image.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          'РЕЗУЛЬТАТ',
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Image container
        ClipRRect(
          borderRadius: SanbaoRadius.md,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: colors.bgSurfaceAlt,
              borderRadius: SanbaoRadius.md,
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.2),
              ),
              boxShadow: SanbaoShadows.sm,
            ),
            child: _buildImage(context),
          ),
        ),

        // Revised prompt (if available)
        if (result.revisedPrompt != null &&
            result.revisedPrompt!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            result.revisedPrompt!,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: 12),

        // Action buttons
        _buildActions(context),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    if (result.isBase64) {
      final bytes = _decodeBase64Image(result.imageBase64!);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildImageError(context),
        );
      }
    }

    if (result.imageUrl != null && result.imageUrl!.isNotEmpty) {
      return Image.network(
        result.imageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageLoading(context, loadingProgress);
        },
        errorBuilder: (_, __, ___) => _buildImageError(context),
      );
    }

    return _buildImageError(context);
  }

  Widget _buildImageLoading(
    BuildContext context,
    ImageChunkEvent loadingProgress,
  ) {
    final colors = context.sanbaoColors;
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded /
            loadingProgress.expectedTotalBytes!
        : null;

    return SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.5,
          color: colors.accent,
        ),
      ),
    );
  }

  Widget _buildImageError(BuildContext context) {
    final colors = context.sanbaoColors;

    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 40,
              color: colors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'Не удалось загрузить изображение',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      children: [
        // Share button
        _ActionButton(
          icon: Icons.share_rounded,
          label: 'Поделиться',
          onTap: () => _handleShare(context),
        ),
        const SizedBox(width: 8),

        // Reset button
        _ActionButton(
          icon: Icons.refresh_rounded,
          label: 'Сначала',
          onTap: () {
            HapticFeedback.lightImpact();
            onReset();
          },
        ),

        const Spacer(),

        // Prompt copy button
        GestureDetector(
          onTap: () {
            unawaited(
              Clipboard.setData(ClipboardData(text: result.prompt)),
            );
            context.showSuccessSnackBar('Промпт скопирован');
          },
          child: Icon(
            Icons.copy_rounded,
            size: 18,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    unawaited(HapticFeedback.lightImpact());

    try {
      if (result.isBase64) {
        final bytes = _decodeBase64Image(result.imageBase64!);
        if (bytes != null) {
          await Share.shareXFiles(
            [
              XFile.fromData(
                bytes,
                mimeType: 'image/png',
                name: 'sanbao-generated.png',
              ),
            ],
            text: result.prompt,
          );
          return;
        }
      }

      // Fallback to sharing the URL or prompt text
      final shareText = result.imageUrl ?? result.prompt;
      await Share.share(shareText, subject: 'Sanbao - Сгенерированное изображение');
    } on Exception {
      if (context.mounted) {
        context.showErrorSnackBar('Не удалось поделиться изображением');
      }
    }
  }

  /// Decodes a base64 data URI to bytes.
  Uint8List? _decodeBase64Image(String dataUri) {
    try {
      // Strip the data URI prefix (data:image/...;base64,)
      final base64String = dataUri.contains(',')
          ? dataUri.split(',').last
          : dataUri;
      return base64Decode(base64String);
    } on FormatException {
      return null;
    }
  }
}

/// A small action button with icon and label.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.bgSurfaceAlt,
          borderRadius: SanbaoRadius.sm,
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
