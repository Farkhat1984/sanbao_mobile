/// Remote data source for content reporting.
///
/// Handles sending report requests to POST /api/reports.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';

/// Reason for reporting a message.
enum ReportReason {
  /// Offensive or abusive content.
  offensive('offensive', 'Оскорбительный контент'),

  /// Inaccurate or misleading information.
  inaccurate('inaccurate', 'Неточная информация'),

  /// Spam or unwanted content.
  spam('spam', 'Спам'),

  /// Other reason (requires details).
  other('other', 'Другое');

  const ReportReason(this.apiValue, this.displayLabel);

  /// Value sent to the API.
  final String apiValue;

  /// Localized display label (Russian).
  final String displayLabel;
}

/// Remote data source for submitting content reports.
class ReportRemoteDataSource {
  ReportRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static String get _basePath => '${AppConfig.apiPath}/reports';

  /// Submits a report for a specific message.
  ///
  /// POST /api/reports
  /// Body: { messageId, reason, details? }
  Future<void> submitReport({
    required String messageId,
    required ReportReason reason,
    String? details,
  }) async {
    await _dioClient.post<Map<String, Object?>>(
      _basePath,
      data: {
        'messageId': messageId,
        'reason': reason.apiValue,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }
}

/// Riverpod provider for [ReportRemoteDataSource].
final reportRemoteDataSourceProvider =
    Provider<ReportRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReportRemoteDataSource(dioClient: dioClient);
});
