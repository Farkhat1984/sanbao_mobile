/// File attachment preview grid widget.
///
/// Full implementation supporting:
/// - 2-column grid for images with cached_network_image thumbnails
/// - List layout for documents with type-specific icons
/// - Remove button on each attachment
/// - Upload progress indicator per file
/// - File size display and error state handling
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/utils/formatters.dart';
import 'package:sanbao_flutter/features/chat/data/datasources/file_remote_datasource.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/file_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/image_preview.dart';

// ==========================================================================
// Pending Attachment Grid (used in message input area during composition)
// ==========================================================================

/// Grid of pending file attachments shown below the message input.
///
/// Displays image thumbnails in a 2-column grid and document files
/// in a single-column list. Each item shows upload progress and a
/// remove button.
class PendingAttachmentGrid extends ConsumerWidget {
  const PendingAttachmentGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(fileAttachmentsProvider);

    if (attachments.isEmpty) return const SizedBox.shrink();

    // Separate images and documents
    final images = attachments.where((f) => f.isImage).toList();
    final documents = attachments.where((f) => !f.isImage).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image grid (2 columns)
          if (images.isNotEmpty) _ImagePreviewGrid(images: images),

          if (images.isNotEmpty && documents.isNotEmpty)
            const SizedBox(height: 6),

          // Document list
          if (documents.isNotEmpty) _DocumentList(documents: documents),
        ],
      ),
    );
  }
}

/// 2-column grid of image attachment thumbnails.
class _ImagePreviewGrid extends ConsumerWidget {
  const _ImagePreviewGrid({required this.images});

  final List<PendingFileAttachment> images;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
      spacing: 6,
      runSpacing: 6,
      children: images.map((image) => _PendingImageTile(
          attachment: image,
          onRemove: () =>
              ref.read(fileAttachmentsProvider.notifier).removeFile(image.localId),
          onRetry: image.status == FileUploadStatus.failed
              ? () => ref
                  .read(fileAttachmentsProvider.notifier)
                  .retryUpload(image.localId)
              : null,
        ),).toList(),
    );
}

/// A single pending image thumbnail tile with progress and remove button.
class _PendingImageTile extends StatelessWidget {
  const _PendingImageTile({
    required this.attachment,
    required this.onRemove,
    this.onRetry,
  });

  final PendingFileAttachment attachment;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  static const double _tileSize = 80;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SizedBox(
      width: _tileSize,
      height: _tileSize,
      child: Stack(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: SanbaoRadius.sm,
            child: SizedBox.expand(
              child: _buildThumbnail(colors),
            ),
          ),

          // Upload overlay
          if (attachment.isInProgress)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: SanbaoRadius.sm,
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: attachment.progress > 0
                            ? attachment.progress
                            : null,
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Error overlay
          if (attachment.status == FileUploadStatus.failed)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: SanbaoRadius.sm,
                child: GestureDetector(
                  onTap: onRetry,
                  child: ColoredBox(
                    color: colors.error.withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Remove button
          Positioned(
            top: 2,
            right: 2,
            child: _RemoveButton(onTap: onRemove, size: 20),
          ),
        ],
      ),
    );
  }

  // Show local bytes for preview
  Widget _buildThumbnail(SanbaoColorScheme colors) => Image.memory(
      attachment.bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: colors.bgSurfaceAlt,
        child: Icon(
          Icons.broken_image_rounded,
          size: 24,
          color: colors.textMuted,
        ),
      ),
    );
}

/// List of pending document attachments.
class _DocumentList extends ConsumerWidget {
  const _DocumentList({required this.documents});

  final List<PendingFileAttachment> documents;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
      mainAxisSize: MainAxisSize.min,
      children: documents.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _PendingDocumentTile(
            attachment: doc,
            onRemove: () =>
                ref.read(fileAttachmentsProvider.notifier).removeFile(doc.localId),
            onRetry: doc.status == FileUploadStatus.failed
                ? () => ref
                    .read(fileAttachmentsProvider.notifier)
                    .retryUpload(doc.localId)
                : null,
          ),
        ),).toList(),
    );
}

/// A single pending document tile with icon, name, size, progress.
class _PendingDocumentTile extends StatelessWidget {
  const _PendingDocumentTile({
    required this.attachment,
    required this.onRemove,
    this.onRetry,
  });

  final PendingFileAttachment attachment;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final iconColor = _fileIconColor(attachment.mimeType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurfaceAlt,
        borderRadius: SanbaoRadius.sm,
        border: Border.all(
          color: attachment.status == FileUploadStatus.failed
              ? colors.error.withValues(alpha: 0.3)
              : colors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: SanbaoRadius.sm,
            ),
            child: Icon(
              _fileIcon(attachment.mimeType),
              size: 16,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 8),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      Formatters.formatFileSize(attachment.sizeBytes),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    if (attachment.status == FileUploadStatus.failed) ...[
                      const SizedBox(width: 6),
                      Text(
                        attachment.errorMessage ?? 'Ошибка',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.error,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                // Progress bar
                if (attachment.isInProgress) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: SanbaoRadius.full,
                    child: LinearProgressIndicator(
                      value: attachment.progress > 0
                          ? attachment.progress
                          : null,
                      minHeight: 2,
                      backgroundColor: colors.border,
                      color: colors.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Retry button (for failed uploads)
          if (attachment.status == FileUploadStatus.failed && onRetry != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onRetry?.call();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: colors.accent,
                ),
              ),
            ),

          // Remove button
          _RemoveButton(onTap: onRemove, size: 20),
        ],
      ),
    );
  }
}

// ==========================================================================
// Sent Message Attachment Grid (used in message bubbles)
// ==========================================================================

/// A grid of file attachment previews displayed in sent messages.
///
/// Images are shown as thumbnails; other files show an icon
/// with the file name and size.
class FileAttachmentGrid extends StatelessWidget {
  const FileAttachmentGrid({
    required this.attachments,
    super.key,
    this.onTap,
  });

  /// The list of attachments to display.
  final List<MessageAttachment> attachments;

  /// Callback when an attachment is tapped.
  final void Function(MessageAttachment)? onTap;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    // Separate images and documents
    final images = attachments.where((a) => a.isImage).toList();
    final documents = attachments.where((a) => !a.isImage).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image grid
        if (images.isNotEmpty) _SentImageGrid(images: images, onTap: onTap),

        if (images.isNotEmpty && documents.isNotEmpty)
          const SizedBox(height: 6),

        // Document tiles
        if (documents.isNotEmpty)
          ...documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SentDocumentTile(
                attachment: doc,
                onTap: () => onTap?.call(doc),
              ),
            ),
          ),
      ],
    );
  }
}

/// Grid of sent image thumbnails (supports tap to preview).
class _SentImageGrid extends StatelessWidget {
  const _SentImageGrid({
    required this.images,
    this.onTap,
  });

  final List<MessageAttachment> images;
  final void Function(MessageAttachment)? onTap;

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return _SentImageTile(
        attachment: images.first,
        width: 200,
        height: 160,
        onTap: () => _openPreview(context, images.first),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: images.map((image) {
        final tileSize = images.length <= 2 ? 120.0 : 96.0;
        return _SentImageTile(
          attachment: image,
          width: tileSize,
          height: tileSize,
          onTap: () => _openPreview(context, image),
        );
      }).toList(),
    );
  }

  void _openPreview(BuildContext context, MessageAttachment attachment) {
    if (attachment.url != null || attachment.thumbnailUrl != null) {
      showImagePreview(
        context,
        imageUrl: attachment.url ?? attachment.thumbnailUrl,
        heroTag: 'image_${attachment.id}',
        title: attachment.name,
      );
    }
    onTap?.call(attachment);
  }
}

/// A single sent image thumbnail with cached network image.
class _SentImageTile extends StatelessWidget {
  const _SentImageTile({
    required this.attachment,
    required this.width,
    required this.height,
    this.onTap,
  });

  final MessageAttachment attachment;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final imageUrl = attachment.thumbnailUrl ?? attachment.url;

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'image_${attachment.id}',
        child: ClipRRect(
          borderRadius: SanbaoRadius.sm,
          child: SizedBox(
            width: width,
            height: height,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => ColoredBox(
                      color: colors.bgSurfaceAlt,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SanbaoColors.accent,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => ColoredBox(
                      color: colors.bgSurfaceAlt,
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 24,
                        color: colors.textMuted,
                      ),
                    ),
                  )
                : ColoredBox(
                    color: colors.bgSurfaceAlt,
                    child: Icon(
                      Icons.image_rounded,
                      size: 24,
                      color: colors.textMuted,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A single sent document tile in a message bubble.
class _SentDocumentTile extends StatelessWidget {
  const _SentDocumentTile({
    required this.attachment,
    this.onTap,
  });

  final MessageAttachment attachment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final iconColor = _fileIconColor(attachment.mimeType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.bgSurfaceAlt,
          borderRadius: SanbaoRadius.sm,
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: SanbaoRadius.sm,
              ),
              child: Icon(
                _fileIcon(attachment.mimeType),
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.name,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatFileSize(attachment.sizeBytes),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// Shared helpers
// ==========================================================================

/// Small circular remove/close button with an X icon.
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({
    required this.onTap,
    this.size = 22,
  });

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          size: size * 0.65,
          color: Colors.white,
        ),
      ),
    );
}

/// Returns the icon for a given MIME type.
IconData _fileIcon(String mimeType) {
  if (mimeType.startsWith('image/')) return Icons.image_rounded;
  if (mimeType == 'application/pdf') return Icons.picture_as_pdf_rounded;
  if (mimeType.contains('word') || mimeType.contains('document')) {
    return Icons.description_rounded;
  }
  if (mimeType.contains('excel') ||
      mimeType.contains('spreadsheet') ||
      mimeType == 'text/csv') {
    return Icons.table_chart_rounded;
  }
  if (mimeType.contains('presentation')) return Icons.slideshow_rounded;
  if (mimeType.startsWith('text/')) return Icons.article_rounded;
  return Icons.insert_drive_file_rounded;
}

/// Returns the icon color for a given MIME type.
Color _fileIconColor(String mimeType) {
  if (mimeType.startsWith('image/')) return const Color(0xFFF59E0B);
  if (mimeType == 'application/pdf') return const Color(0xFFEF4444);
  if (mimeType.contains('word') || mimeType.contains('document')) {
    return const Color(0xFF3B82F6);
  }
  if (mimeType.contains('excel') ||
      mimeType.contains('spreadsheet') ||
      mimeType == 'text/csv') {
    return const Color(0xFF22C55E);
  }
  if (mimeType.contains('presentation')) return const Color(0xFFF59E0B);
  return const Color(0xFF8E99AB);
}
