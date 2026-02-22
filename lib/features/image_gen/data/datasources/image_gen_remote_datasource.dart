/// Remote data source for image generation operations.
///
/// Handles POST calls to /api/image-generate and /api/image-edit.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/image_gen/data/models/image_gen_result_model.dart';
import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';

/// Remote data source for image generation via the REST API.
class ImageGenRemoteDataSource {
  ImageGenRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Generates an image from a text prompt.
  Future<ImageGenResult> generate({
    required String prompt,
    ImageGenStyle? style,
    ImageGenSize? size,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.imageGenerateEndpoint,
      data: ImageGenResultModel.generateRequestToJson(
        prompt: prompt,
        style: style,
        size: size,
      ),
    );

    return ImageGenResultModel.fromJson(response, prompt: prompt).result;
  }

  /// Edits an existing image based on a text prompt.
  Future<ImageGenResult> edit({
    required String imageSource,
    required String prompt,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.imageEditEndpoint,
      data: ImageGenResultModel.editRequestToJson(
        imageSource: imageSource,
        prompt: prompt,
      ),
    );

    return ImageGenResultModel.fromJson(response, prompt: prompt).result;
  }
}

/// Riverpod provider for [ImageGenRemoteDataSource].
final imageGenRemoteDataSourceProvider =
    Provider<ImageGenRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ImageGenRemoteDataSource(dioClient: dioClient);
});
