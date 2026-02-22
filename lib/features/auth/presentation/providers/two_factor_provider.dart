/// Riverpod provider for 2FA setup wizard state management.
///
/// Manages the multi-step 2FA setup flow: fetching QR code,
/// verifying TOTP code, and enabling/disabling 2FA.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/features/auth/domain/usecases/setup_2fa_usecase.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';

// ---- 2FA Setup State ----

/// Sealed state hierarchy for the 2FA setup wizard.
sealed class TwoFactorSetupState {
  const TwoFactorSetupState();
}

/// Initial state before any action is taken.
final class TwoFactorInitial extends TwoFactorSetupState {
  const TwoFactorInitial();
}

/// Loading state while fetching setup data or verifying.
final class TwoFactorLoading extends TwoFactorSetupState {
  const TwoFactorLoading();
}

/// QR code and secret are ready for the user to scan.
final class TwoFactorQrReady extends TwoFactorSetupState {
  const TwoFactorQrReady({
    required this.qrCodeUrl,
    required this.secret,
  });

  /// Data URL of the QR code image (base64 PNG).
  final String qrCodeUrl;

  /// The TOTP secret for manual entry.
  final String secret;
}

/// Verification is in progress after the user entered a code.
final class TwoFactorVerifying extends TwoFactorSetupState {
  const TwoFactorVerifying({
    required this.qrCodeUrl,
    required this.secret,
  });

  /// Retained for the UI to show the current step context.
  final String qrCodeUrl;

  /// Retained for the UI to show the current step context.
  final String secret;
}

/// 2FA has been successfully enabled.
final class TwoFactorEnabled extends TwoFactorSetupState {
  const TwoFactorEnabled();
}

/// 2FA has been successfully disabled.
final class TwoFactorDisabled extends TwoFactorSetupState {
  const TwoFactorDisabled();
}

/// An error occurred during the setup flow.
final class TwoFactorError extends TwoFactorSetupState {
  const TwoFactorError({
    required this.message,
    this.previousState,
  });

  /// Human-readable error message.
  final String message;

  /// The state before the error, to allow retrying from context.
  final TwoFactorSetupState? previousState;
}

// ---- Notifier ----

/// Manages the 2FA setup wizard state transitions.
///
/// Flow:
/// 1. [fetchSetupData] -- TwoFactorInitial -> TwoFactorLoading -> TwoFactorQrReady
/// 2. [verifyAndEnable] -- TwoFactorQrReady -> TwoFactorVerifying -> TwoFactorEnabled
/// 3. [disable] -- any -> TwoFactorLoading -> TwoFactorDisabled
class TwoFactorSetupNotifier extends StateNotifier<TwoFactorSetupState> {
  TwoFactorSetupNotifier({
    required Setup2faUseCase setup2faUseCase,
  })  : _setup2faUseCase = setup2faUseCase,
        super(const TwoFactorInitial());

  final Setup2faUseCase _setup2faUseCase;

  /// Fetches the QR code and secret from the server.
  ///
  /// Transitions: Initial -> Loading -> QrReady (or Error).
  Future<void> fetchSetupData() async {
    state = const TwoFactorLoading();

    try {
      final result = await _setup2faUseCase.getSetupData();

      if (result.enabled) {
        // 2FA is already enabled -- no need to set up
        state = const TwoFactorEnabled();
        return;
      }

      state = TwoFactorQrReady(
        qrCodeUrl: result.qrCodeUrl,
        secret: result.secret,
      );
    } on Failure catch (f) {
      state = TwoFactorError(
        message: f.message,
        previousState: const TwoFactorInitial(),
      );
    } catch (e) {
      debugPrint('[TwoFactorSetupNotifier] fetchSetupData error: $e');
      state = const TwoFactorError(
        message: 'Не удалось получить данные настройки 2FA',
      );
    }
  }

  /// Verifies the TOTP code and enables 2FA.
  ///
  /// Transitions: QrReady -> Verifying -> Enabled (or Error).
  Future<void> verifyAndEnable({required String code}) async {
    final currentState = state;
    var qrCodeUrl = '';
    var secret = '';

    // Preserve QR data for error recovery
    if (currentState is TwoFactorQrReady) {
      qrCodeUrl = currentState.qrCodeUrl;
      secret = currentState.secret;
    } else if (currentState is TwoFactorVerifying) {
      qrCodeUrl = currentState.qrCodeUrl;
      secret = currentState.secret;
    }

    state = TwoFactorVerifying(
      qrCodeUrl: qrCodeUrl,
      secret: secret,
    );

    try {
      await _setup2faUseCase.enable(code: code);
      state = const TwoFactorEnabled();
    } on Failure catch (f) {
      state = TwoFactorError(
        message: f.message,
        previousState: TwoFactorQrReady(
          qrCodeUrl: qrCodeUrl,
          secret: secret,
        ),
      );
    } catch (e) {
      debugPrint('[TwoFactorSetupNotifier] verifyAndEnable error: $e');
      state = TwoFactorError(
        message: 'Не удалось подтвердить код',
        previousState: TwoFactorQrReady(
          qrCodeUrl: qrCodeUrl,
          secret: secret,
        ),
      );
    }
  }

  /// Disables 2FA with a verification code.
  ///
  /// Transitions: any -> Loading -> Disabled (or Error).
  Future<void> disable({required String code}) async {
    final previousState = state;
    state = const TwoFactorLoading();

    try {
      await _setup2faUseCase.disable(code: code);
      state = const TwoFactorDisabled();
    } on Failure catch (f) {
      state = TwoFactorError(
        message: f.message,
        previousState: previousState,
      );
    } catch (e) {
      debugPrint('[TwoFactorSetupNotifier] disable error: $e');
      state = TwoFactorError(
        message: 'Не удалось отключить 2FA',
        previousState: previousState,
      );
    }
  }

  /// Resets the state back to initial.
  void reset() {
    state = const TwoFactorInitial();
  }

  /// Recovers to the previous state after an error.
  void recoverFromError() {
    final currentState = state;
    if (currentState is TwoFactorError && currentState.previousState != null) {
      state = currentState.previousState!;
    } else {
      state = const TwoFactorInitial();
    }
  }
}

// ---- Providers ----

/// Provider for the 2FA setup wizard state.
final twoFactorSetupProvider =
    StateNotifierProvider.autoDispose<TwoFactorSetupNotifier, TwoFactorSetupState>(
  (ref) => TwoFactorSetupNotifier(
    setup2faUseCase: ref.watch(setup2faUseCaseProvider),
  ),
);

/// Convenience provider that extracts the current user's 2FA status.
///
/// Returns `true` if 2FA is enabled, `false` otherwise.
final isTwoFactorEnabledProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.twoFactorEnabled ?? false;
});
