/// Bottom sheet for selecting file attachment source.
///
/// Presents three options: Camera, Gallery, and Documents.
/// Uses image_picker for camera/gallery and file_picker for documents.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Result of a file picker operation.
class PickedFileResult {
  const PickedFileResult({
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.bytes,
    this.path,
  });

  /// Original file name.
  final String name;

  /// File size in bytes.
  final int sizeBytes;

  /// MIME type.
  final String mimeType;

  /// Raw file bytes.
  final Uint8List bytes;

  /// Local file path (if available).
  final String? path;
}

/// Shows a bottom sheet with file attachment source options.
///
/// Returns a list of [PickedFileResult] or `null` if cancelled.
Future<List<PickedFileResult>?> showFilePickerSheet(
  BuildContext context,
) async {
  return showModalBottomSheet<List<PickedFileResult>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _FilePickerSheet(),
  );
}

class _FilePickerSheet extends StatelessWidget {
  const _FilePickerSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final bottomPadding = context.bottomPadding;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.only(
          topLeft: SanbaoRadius.circularLg,
          topRight: SanbaoRadius.circularLg,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: bottomPadding > 0 ? 8 : 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: SanbaoRadius.full,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'Прикрепить файл',
                style: context.textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // Options row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Камера',
                    color: colors.accent,
                    onTap: () => _pickFromCamera(context),
                  ),
                  _PickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Галерея',
                    color: const Color(0xFFF59E0B),
                    onTap: () => _pickFromGallery(context),
                  ),
                  _PickerOption(
                    icon: Icons.folder_rounded,
                    label: 'Документы',
                    color: const Color(0xFF22C55E),
                    onTap: () => _pickDocuments(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Size info
              Text(
                'Макс. размер файла: 20 МБ',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    HapticFeedback.lightImpact();

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) {
        if (context.mounted) Navigator.of(context).pop();
        return;
      }

      final bytes = await image.readAsBytes();
      final result = PickedFileResult(
        name: image.name,
        sizeBytes: bytes.length,
        mimeType: _guessMimeType(image.name, 'image/jpeg'),
        bytes: bytes,
        path: image.path,
      );

      if (context.mounted) Navigator.of(context).pop([result]);
    } on PlatformException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        context.showErrorSnackBar(
          e.code == 'camera_access_denied'
              ? 'Нет доступа к камере'
              : 'Ошибка камеры: ${e.message}',
        );
      }
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    HapticFeedback.lightImpact();

    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
        limit: AppConfig.maxAttachments,
      );

      if (images.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        return;
      }

      final results = <PickedFileResult>[];
      for (final image in images) {
        final bytes = await image.readAsBytes();
        results.add(PickedFileResult(
          name: image.name,
          sizeBytes: bytes.length,
          mimeType: _guessMimeType(image.name, 'image/jpeg'),
          bytes: bytes,
          path: image.path,
        ));
      }

      if (context.mounted) Navigator.of(context).pop(results);
    } on PlatformException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        context.showErrorSnackBar(
          e.code == 'photo_access_denied'
              ? 'Нет доступа к фото'
              : 'Ошибка галереи: ${e.message}',
        );
      }
    }
  }

  Future<void> _pickDocuments(BuildContext context) async {
    HapticFeedback.lightImpact();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc', 'docx',
          'xls', 'xlsx',
          'pptx',
          'csv',
          'txt',
          'rtf',
          'html',
          'png', 'jpg', 'jpeg', 'webp',
        ],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        return;
      }

      final results = <PickedFileResult>[];
      for (final file in result.files) {
        if (file.bytes == null) continue;

        results.add(PickedFileResult(
          name: file.name,
          sizeBytes: file.size,
          mimeType: _guessMimeType(file.name, 'application/octet-stream'),
          bytes: file.bytes!,
          path: file.path,
        ));
      }

      if (context.mounted) Navigator.of(context).pop(results);
    } on PlatformException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        context.showErrorSnackBar('Ошибка выбора файла: ${e.message}');
      }
    }
  }

  /// Guesses MIME type from file extension.
  static String _guessMimeType(String fileName, String fallback) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'csv' => 'text/csv',
      'txt' => 'text/plain',
      'rtf' => 'application/rtf',
      'html' || 'htm' => 'text/html',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => fallback,
    };
  }
}

/// A single picker source option tile.
class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SanbaoAnimations.durationFast,
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: SanbaoRadius.lg,
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
