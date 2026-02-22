/// Edit profile screen.
///
/// Allows the user to change their avatar (camera/gallery),
/// name, and locale. Saves changes to the server.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/profile/presentation/providers/profile_provider.dart';
import 'package:sanbao_flutter/features/profile/presentation/widgets/avatar_picker.dart';
import 'package:sanbao_flutter/features/profile/presentation/widgets/locale_selector.dart';

/// Screen for editing user profile (avatar, name, locale).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  String _selectedLocale = 'ru';
  Uint8List? _pendingAvatarBytes;
  String? _pendingAvatarName;
  bool _isSaving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _selectedLocale = user?.locale ?? 'ru';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(profileProvider);
    final isLoading = profileState is ProfileLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar picker
          Center(
            child: AvatarPicker(
              currentImageUrl: user?.image,
              name: user?.displayName,
              isLoading: isLoading && _pendingAvatarBytes != null,
              onImageSelected: (bytes, fileName) {
                setState(() {
                  _pendingAvatarBytes = bytes;
                  _pendingAvatarName = fileName;
                });
              },
            ),
          ),
          const SizedBox(height: 32),

          // Name field
          SanbaoInput(
            controller: _nameController,
            label: 'Имя',
            hint: 'Введите ваше имя',
            prefixIcon: Icons.person_outline_rounded,
            errorText: _nameError,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
          ),
          const SizedBox(height: 20),

          // Locale selector
          LocaleSelector(
            label: 'Язык',
            currentLocale: _selectedLocale,
            onLocaleChanged: (locale) {
              setState(() => _selectedLocale = locale);
            },
          ),
          const SizedBox(height: 32),

          // Save button
          SanbaoButton(
            label: 'Сохранить',
            size: SanbaoButtonSize.large,
            isExpanded: true,
            isLoading: _isSaving,
            leadingIcon: Icons.check_rounded,
            onPressed: _isSaving ? null : _save,
          ),
          const SizedBox(height: 16),

          // Cancel button
          SanbaoButton(
            label: 'Отмена',
            variant: SanbaoButtonVariant.ghost,
            isExpanded: true,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  bool _validate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Имя не может быть пустым');
      return false;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Имя должно содержать минимум 2 символа');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(profileProvider.notifier);

      // Upload avatar if changed
      if (_pendingAvatarBytes != null && _pendingAvatarName != null) {
        final avatarSuccess = await notifier.updateAvatar(
          imageBytes: _pendingAvatarBytes!,
          fileName: _pendingAvatarName!,
        );
        if (!avatarSuccess && mounted) {
          context.showErrorSnackBar('Не удалось обновить аватар');
        }
      }

      // Update profile fields
      final success = await notifier.updateProfile(
        name: _nameController.text.trim(),
        locale: _selectedLocale,
      );

      if (mounted) {
        if (success) {
          context
            ..showSuccessSnackBar('Профиль обновлён')
            ..pop();
        } else {
          final state = ref.read(profileProvider);
          if (state is ProfileError) {
            context.showErrorSnackBar(state.message);
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
