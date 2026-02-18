/// Remote data source for file upload, parsing, and retrieval.
///
/// Handles the POST /api/files/parse multipart upload endpoint,
/// file info retrieval, and file download operations.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';

/// The upload status for a single file.
enum FileUploadStatus {
  /// File is queued but not yet uploading.
  pending,

  /// File is currently being uploaded.
  uploading,

  /// Server is parsing/processing the file.
  parsing,

  /// Upload and parsing completed successfully.
  completed,

  /// Upload or parsing failed.
  failed,
}

/// Represents a file selected by the user for attachment.
///
/// Tracks the file's metadata, upload progress, and parsed result.
class PendingFileAttachment {
  const PendingFileAttachment({
    required this.localId,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.bytes,
    this.localPath,
    this.status = FileUploadStatus.pending,
    this.progress = 0.0,
    this.serverId,
    this.serverUrl,
    this.thumbnailUrl,
    this.parsedText,
    this.errorMessage,
  });

  /// Client-side unique identifier for tracking.
  final String localId;

  /// Original file name.
  final String name;

  /// File size in bytes.
  final int sizeBytes;

  /// MIME type (e.g., 'application/pdf', 'image/jpeg').
  final String mimeType;

  /// Raw file bytes for upload.
  final Uint8List bytes;

  /// Local file path (if available from picker).
  final String? localPath;

  /// Current upload status.
  final FileUploadStatus status;

  /// Upload progress (0.0 to 1.0).
  final double progress;

  /// Server-assigned file ID after successful upload.
  final String? serverId;

  /// Server URL for the uploaded file.
  final String? serverUrl;

  /// Thumbnail URL for image files.
  final String? thumbnailUrl;

  /// Parsed text content from the server.
  final String? parsedText;

  /// Error message if upload/parsing failed.
  final String? errorMessage;

  /// Whether this file is an image.
  bool get isImage => mimeType.startsWith('image/');

  /// Whether this file is a PDF.
  bool get isPdf => mimeType == 'application/pdf';

  /// Whether this file is a document (Word, Excel, etc.).
  bool get isDocument =>
      mimeType.contains('word') ||
      mimeType.contains('document') ||
      mimeType.contains('excel') ||
      mimeType.contains('spreadsheet') ||
      mimeType.contains('presentation') ||
      mimeType == 'text/csv' ||
      mimeType == 'text/plain' ||
      mimeType == 'text/html' ||
      mimeType == 'application/rtf';

  /// Whether the upload has completed (success or failure).
  bool get isDone =>
      status == FileUploadStatus.completed ||
      status == FileUploadStatus.failed;

  /// Whether the upload is currently in progress.
  bool get isInProgress =>
      status == FileUploadStatus.uploading ||
      status == FileUploadStatus.parsing;

  /// Creates a copy with modified fields.
  PendingFileAttachment copyWith({
    String? localId,
    String? name,
    int? sizeBytes,
    String? mimeType,
    Uint8List? bytes,
    String? localPath,
    FileUploadStatus? status,
    double? progress,
    String? serverId,
    String? serverUrl,
    String? thumbnailUrl,
    String? parsedText,
    String? errorMessage,
  }) =>
      PendingFileAttachment(
        localId: localId ?? this.localId,
        name: name ?? this.name,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        mimeType: mimeType ?? this.mimeType,
        bytes: bytes ?? this.bytes,
        localPath: localPath ?? this.localPath,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        serverId: serverId ?? this.serverId,
        serverUrl: serverUrl ?? this.serverUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        parsedText: parsedText ?? this.parsedText,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingFileAttachment &&
          runtimeType == other.runtimeType &&
          localId == other.localId;

  @override
  int get hashCode => localId.hashCode;
}

/// Response from the file parse endpoint.
class FileParseResponse {
  const FileParseResponse({
    required this.fileId,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    this.url,
    this.thumbnailUrl,
    this.parsedText,
  });

  /// Creates a [FileParseResponse] from a decoded JSON map.
  factory FileParseResponse.fromJson(Map<String, Object?> json) =>
      FileParseResponse(
        fileId: json['id'] as String? ?? json['fileId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        mimeType: json['mimeType'] as String? ??
            json['contentType'] as String? ??
            'application/octet-stream',
        sizeBytes: (json['size'] as num?)?.toInt() ??
            (json['sizeBytes'] as num?)?.toInt() ??
            0,
        url: json['url'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        parsedText: json['parsedText'] as String? ??
            json['text'] as String?,
      );

  final String fileId;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final String? url;
  final String? thumbnailUrl;
  final String? parsedText;
}

/// Remote data source for file operations.
///
/// Uploads files to `POST /api/files/parse` as multipart form data,
/// retrieves file info, and provides download URLs.
class FileRemoteDataSource {
  FileRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Uploads a file to the parse endpoint.
  ///
  /// Returns a [FileParseResponse] with the server-assigned ID and
  /// any parsed text content. Reports progress through [onProgress].
  Future<FileParseResponse> uploadAndParse({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    final response = await _dioClient.post<Map<String, Object?>>(
      '${AppConfig.filesEndpoint}/parse',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
      cancelToken: cancelToken,
    );

    return FileParseResponse.fromJson(response);
  }

  /// Retrieves file metadata by ID.
  Future<FileParseResponse> getFileInfo(String fileId) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.filesEndpoint}/$fileId',
    );

    return FileParseResponse.fromJson(response);
  }

  /// Returns the download URL for a file.
  String getDownloadUrl(String fileId) =>
      '${AppConfig.baseUrl}${AppConfig.filesEndpoint}/$fileId/download';
}

/// Riverpod provider for [FileRemoteDataSource].
final fileRemoteDataSourceProvider = Provider<FileRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return FileRemoteDataSource(dioClient: dioClient);
});
