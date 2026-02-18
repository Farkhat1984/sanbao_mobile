/// File attachment state management providers.
///
/// Manages the list of pending file attachments, upload progress,
/// and the file parse lifecycle using Riverpod.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/features/chat/data/datasources/file_remote_datasource.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';

// ---- ID Generation ----

int _fileIdCounter = 0;

/// Generates a locally-unique ID for pending file attachments.
String _generateFileId() {
  _fileIdCounter++;
  return 'file_${DateTime.now().millisecondsSinceEpoch}_$_fileIdCounter';
}

// ---- File Attachments State ----

/// The list of pending file attachments for the current message.
final fileAttachmentsProvider =
    StateNotifierProvider<FileAttachmentsNotifier, List<PendingFileAttachment>>(
  (ref) => FileAttachmentsNotifier(ref),
);

/// Whether there are any files attached to the current message.
final hasFileAttachmentsProvider = Provider<bool>((ref) {
  return ref.watch(fileAttachmentsProvider).isNotEmpty;
});

/// The total number of attached files.
final fileAttachmentCountProvider = Provider<int>((ref) {
  return ref.watch(fileAttachmentsProvider).length;
});

/// Whether all attached files have finished uploading.
final allFilesUploadedProvider = Provider<bool>((ref) {
  final files = ref.watch(fileAttachmentsProvider);
  if (files.isEmpty) return true;
  return files.every((f) => f.status == FileUploadStatus.completed);
});

/// Whether any file is currently uploading.
final isUploadingFilesProvider = Provider<bool>((ref) {
  final files = ref.watch(fileAttachmentsProvider);
  return files.any((f) => f.isInProgress);
});

/// State notifier for managing pending file attachments.
///
/// Handles adding files from picker, starting uploads, tracking progress,
/// removing files, and clearing all attachments after send.
class FileAttachmentsNotifier
    extends StateNotifier<List<PendingFileAttachment>> {
  FileAttachmentsNotifier(this._ref) : super(const []);

  final Ref _ref;
  final Map<String, CancelToken> _cancelTokens = {};

  /// Adds a file to the attachment list and begins uploading it.
  ///
  /// Returns `null` if the file was added successfully, or an error
  /// message string if validation failed.
  String? addFile({
    required String name,
    required int sizeBytes,
    required String mimeType,
    required Uint8List bytes,
    String? localPath,
  }) {
    // Validate file count
    if (state.length >= AppConfig.maxAttachments) {
      return 'Максимум ${AppConfig.maxAttachments} файлов';
    }

    // Validate file size
    if (sizeBytes > AppConfig.maxFileSizeParseBytes) {
      return 'Файл слишком большой (макс. 20 МБ)';
    }

    // Validate MIME type
    if (!AppConfig.allowedFileTypes.contains(mimeType)) {
      return 'Формат файла не поддерживается';
    }

    // Check for duplicates by name and size
    final isDuplicate = state.any(
      (f) => f.name == name && f.sizeBytes == sizeBytes,
    );
    if (isDuplicate) {
      return 'Этот файл уже прикреплен';
    }

    final localId = _generateFileId();
    final attachment = PendingFileAttachment(
      localId: localId,
      name: name,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
      bytes: bytes,
      localPath: localPath,
      status: FileUploadStatus.pending,
    );

    state = [...state, attachment];

    // Start uploading
    _uploadFile(localId);

    return null;
  }

  /// Removes a file from the attachment list and cancels any in-progress upload.
  void removeFile(String localId) {
    _cancelTokens[localId]?.cancel('File removed by user');
    _cancelTokens.remove(localId);
    state = state.where((f) => f.localId != localId).toList();
  }

  /// Clears all attachments and cancels all uploads.
  void clearAll() {
    for (final token in _cancelTokens.values) {
      token.cancel('All files cleared');
    }
    _cancelTokens.clear();
    state = const [];
  }

  /// Retries a failed upload.
  void retryUpload(String localId) {
    final index = state.indexWhere((f) => f.localId == localId);
    if (index < 0) return;

    final file = state[index];
    if (file.status != FileUploadStatus.failed) return;

    _updateFile(localId, (f) => f.copyWith(
      status: FileUploadStatus.pending,
      progress: 0.0,
      errorMessage: null,
    ));

    _uploadFile(localId);
  }

  /// Converts all completed attachments to [MessageAttachment] entities
  /// for inclusion in the sent message.
  List<MessageAttachment> toMessageAttachments() {
    return state
        .where((f) => f.status == FileUploadStatus.completed)
        .map(
          (f) => MessageAttachment(
            id: f.serverId ?? f.localId,
            name: f.name,
            mimeType: f.mimeType,
            sizeBytes: f.sizeBytes,
            url: f.serverUrl,
            thumbnailUrl: f.thumbnailUrl,
          ),
        )
        .toList();
  }

  /// Converts completed attachments to the API payload format.
  List<Map<String, Object?>> toApiAttachments() {
    return state
        .where((f) => f.status == FileUploadStatus.completed)
        .map(
          (f) => <String, Object?>{
            'id': f.serverId,
            'name': f.name,
            'mimeType': f.mimeType,
            'size': f.sizeBytes,
            if (f.parsedText != null) 'parsedText': f.parsedText,
          },
        )
        .toList();
  }

  /// Starts the upload process for a file.
  Future<void> _uploadFile(String localId) async {
    final index = state.indexWhere((f) => f.localId == localId);
    if (index < 0) return;

    final file = state[index];
    final cancelToken = CancelToken();
    _cancelTokens[localId] = cancelToken;

    // Mark as uploading
    _updateFile(localId, (f) => f.copyWith(
      status: FileUploadStatus.uploading,
      progress: 0.0,
    ));

    try {
      final datasource = _ref.read(fileRemoteDataSourceProvider);

      final response = await datasource.uploadAndParse(
        fileName: file.name,
        fileBytes: file.bytes,
        mimeType: file.mimeType,
        cancelToken: cancelToken,
        onProgress: (progress) {
          _updateFile(localId, (f) => f.copyWith(
            progress: progress.clamp(0.0, 0.95),
          ));
        },
      );

      // Mark as completed
      _updateFile(localId, (f) => f.copyWith(
        status: FileUploadStatus.completed,
        progress: 1.0,
        serverId: response.fileId,
        serverUrl: response.url,
        thumbnailUrl: response.thumbnailUrl,
        parsedText: response.parsedText,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;

      _updateFile(localId, (f) => f.copyWith(
        status: FileUploadStatus.failed,
        progress: 0.0,
        errorMessage: _mapUploadError(e),
      ));
    } on Object catch (e) {
      _updateFile(localId, (f) => f.copyWith(
        status: FileUploadStatus.failed,
        progress: 0.0,
        errorMessage: 'Ошибка загрузки: $e',
      ));
    } finally {
      _cancelTokens.remove(localId);
    }
  }

  /// Updates a single file in the state list.
  void _updateFile(
    String localId,
    PendingFileAttachment Function(PendingFileAttachment) updater,
  ) {
    state = [
      for (final f in state)
        if (f.localId == localId) updater(f) else f,
    ];
  }

  /// Maps a Dio upload error to a user-friendly Russian message.
  String _mapUploadError(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout =>
          'Превышено время загрузки файла',
        DioExceptionType.connectionError => 'Нет подключения к серверу',
        _ => 'Ошибка загрузки: ${e.message ?? 'Неизвестная ошибка'}',
      };

  @override
  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel('Provider disposed');
    }
    _cancelTokens.clear();
    super.dispose();
  }
}
