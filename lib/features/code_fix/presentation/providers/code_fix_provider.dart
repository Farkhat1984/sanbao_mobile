/// Code fix state provider.
///
/// Manages the code fix lifecycle: input, loading, success/error states.
/// Follows the sealed state + StateNotifier pattern from image_gen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/code_fix/data/datasources/code_fix_remote_datasource.dart';

// ---- Code Fix State ----

/// Sealed state for the code fix process.
sealed class CodeFixState {
  const CodeFixState();
}

/// Initial state before any fix attempt.
final class CodeFixInitial extends CodeFixState {
  const CodeFixInitial();
}

/// Code fix is in progress.
final class CodeFixLoading extends CodeFixState {
  const CodeFixLoading();
}

/// Code fix completed successfully.
final class CodeFixSuccess extends CodeFixState {
  const CodeFixSuccess({required this.fixedCode});

  /// The corrected code returned by the API.
  final String fixedCode;
}

/// Code fix failed.
final class CodeFixError extends CodeFixState {
  const CodeFixError({required this.message});

  /// User-facing error message.
  final String message;
}

// ---- Code Fix Notifier ----

/// The main code fix state provider.
final codeFixProvider =
    StateNotifierProvider.autoDispose<CodeFixNotifier, CodeFixState>(
  CodeFixNotifier.new,
);

/// Notifier that handles code fix requests.
class CodeFixNotifier extends StateNotifier<CodeFixState> {
  CodeFixNotifier(this._ref) : super(const CodeFixInitial());

  final Ref _ref;

  /// Sends [code] and [error] to the fix-code API.
  Future<void> fix({
    required String code,
    required String error,
  }) async {
    if (code.trim().isEmpty || error.trim().isEmpty) return;

    state = const CodeFixLoading();

    try {
      final datasource = _ref.read(codeFixRemoteDataSourceProvider);
      final fixedCode = await datasource.fixCode(
        code: code.trim(),
        error: error.trim(),
      );

      state = CodeFixSuccess(fixedCode: fixedCode);
    } on Exception catch (e) {
      state = CodeFixError(message: _extractErrorMessage(e));
    }
  }

  /// Resets the state to initial.
  void reset() {
    state = const CodeFixInitial();
  }

  String _extractErrorMessage(Exception e) {
    final message = e.toString();

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

    final errorMatch =
        RegExp(r'message:\s*(.+?)(?:,|\))').firstMatch(message);
    if (errorMatch != null) {
      return errorMatch.group(1) ?? 'Не удалось исправить код';
    }

    return 'Не удалось исправить код';
  }
}
