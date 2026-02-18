/// Avatar picker widget.
///
/// Tap avatar to show camera/gallery bottom sheet, preview selected image.
/// Uses image_picker for source selection.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_avatar.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';

/// Callback with the selected image bytes and file name.
typedef OnImageSelected = void Function(Uint8List bytes, String fileName);

/// A tappable avatar that opens a camera/gallery picker sheet.
class AvatarPicker extends StatefulWidget {
  const AvatarPicker({
    super.key,
    this.currentImageUrl,
    this.name,
    this.onImageSelected,
    this.isLoading = false,
  });

  /// Current avatar URL.
  final String? currentImageUrl;

  /// User name for initials fallback.
  final String? name;

  /// Called when a new image is selected.
  final OnImageSelected? onImageSelected;

  /// Whether an upload is in progress.
  final bool isLoading;

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  Uint8List? _selectedBytes;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return GestureDetector(
      onTap: widget.isLoading ? null : () => _showPickerSheet(context),
      child: Stack(
        children: [
          // Avatar display
          if (_selectedBytes != null)
            Container(
              width: SanbaoAvatarSize.xxl.diameter,
              height: SanbaoAvatarSize.xxl.diameter,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                _selectedBytes!,
                fit: BoxFit.cover,
                width: SanbaoAvatarSize.xxl.diameter,
                height: SanbaoAvatarSize.xxl.diameter,
              ),
            )
          else
            SanbaoAvatar(
              imageUrl: widget.currentImageUrl,
              name: widget.name,
              size: SanbaoAvatarSize.xxl,
            ),

          // Edit overlay
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: colors.bgSurface, width: 2),
              ),
              child: widget.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.textInverse,
                      ),
                    )
                  : Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: colors.textInverse,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPickerSheet(BuildContext context) async {
    await showSanbaoBottomSheet<void>(
      context: context,
      builder: (context) => SanbaoBottomSheetContent(
        title: 'Выбрать фото',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PickerOption(
              icon: Icons.camera_alt_outlined,
              label: 'Камера',
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            _PickerOption(
              icon: Icons.photo_library_outlined,
              label: 'Галерея',
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() => _selectedBytes = bytes);
      widget.onImageSelected?.call(bytes, picked.name);
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Не удалось выбрать изображение');
      }
    }
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: SanbaoRadius.md,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: colors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
