/// Image generation state providers.
///
/// Manages the image generation lifecycle: prompt input, style/size
/// selection, generation state, and result display.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/image_gen/data/repositories/image_gen_repository_impl.dart';
import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';

// ---- Generation State ----

/// Sealed state for the image generation process.
sealed class ImageGenState {
  const ImageGenState();
}

/// Initial state before any generation attempt.
final class ImageGenStateInitial extends ImageGenState {
  const ImageGenStateInitial();
}

/// Image generation is in progress.
final class ImageGenStateLoading extends ImageGenState {
  const ImageGenStateLoading();
}

/// Image generation completed successfully.
final class ImageGenStateSuccess extends ImageGenState {
  const ImageGenStateSuccess({required this.result});

  /// The generated image result.
  final ImageGenResult result;
}

/// Image generation failed.
final class ImageGenStateError extends ImageGenState {
  const ImageGenStateError({required this.message});

  /// User-facing error message.
  final String message;
}

// ---- Style & Size Selection ----

/// Selected image generation style.
final imageGenStyleProvider =
    StateProvider<ImageGenStyle>((ref) => ImageGenStyle.vivid);

/// Selected image generation size.
final imageGenSizeProvider =
    StateProvider<ImageGenSize>((ref) => ImageGenSize.square);

// ---- Generation Notifier ----

/// The main image generation state provider.
final imageGenProvider =
    StateNotifierProvider<ImageGenNotifier, ImageGenState>(
  ImageGenNotifier.new,
);

/// Notifier that handles image generation and editing requests.
class ImageGenNotifier extends StateNotifier<ImageGenState> {
  ImageGenNotifier(this._ref) : super(const ImageGenStateInitial());

  final Ref _ref;

  /// Generates an image from the given [prompt].
  ///
  /// Uses the currently selected style and size from their
  /// respective providers.
  Future<void> generate({required String prompt}) async {
    if (prompt.trim().isEmpty) return;

    state = const ImageGenStateLoading();

    try {
      final repo = _ref.read(imageGenRepositoryProvider);
      final style = _ref.read(imageGenStyleProvider);
      final size = _ref.read(imageGenSizeProvider);

      final result = await repo.generate(
        prompt: prompt.trim(),
        style: style,
        size: size,
      );

      state = ImageGenStateSuccess(result: result);
    } on Exception catch (e) {
      state = ImageGenStateError(
        message: _extractErrorMessage(e),
      );
    }
  }

  /// Edits an existing image using the given prompt.
  Future<void> edit({
    required String imageSource,
    required String prompt,
  }) async {
    if (prompt.trim().isEmpty || imageSource.isEmpty) return;

    state = const ImageGenStateLoading();

    try {
      final repo = _ref.read(imageGenRepositoryProvider);

      final result = await repo.edit(
        imageSource: imageSource,
        prompt: prompt.trim(),
      );

      state = ImageGenStateSuccess(result: result);
    } on Exception catch (e) {
      state = ImageGenStateError(
        message: _extractErrorMessage(e),
      );
    }
  }

  /// Resets the state to initial.
  void reset() {
    state = const ImageGenStateInitial();
  }

  /// Extracts a user-friendly error message from an exception.
  String _extractErrorMessage(Exception e) {
    final message = e.toString();

    // Check for common error patterns
    if (message.contains('429') || message.contains('rate')) {
      return 'Слишком много запросов. Подождите минуту.';
    }
    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Требуется авторизация';
    }
    if (message.contains('timeout') || message.contains('Timeout')) {
      return 'Превышено время ожидания. Попробуйте снова.';
    }
    if (message.contains('network') || message.contains('Network')) {
      return 'Нет подключения к интернету';
    }
    if (message.contains('503') || message.contains('не настроена')) {
      return 'Модель генерации изображений не настроена';
    }

    // Try to extract server error message
    final errorMatch =
        RegExp(r'message:\s*(.+?)(?:,|\))').firstMatch(message);
    if (errorMatch != null) {
      return errorMatch.group(1) ?? 'Не удалось сгенерировать изображение';
    }

    return 'Не удалось сгенерировать изображение';
  }
}
