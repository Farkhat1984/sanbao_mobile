/// Image generation result data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [ImageGenResult] entity.
library;

import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';

/// Data model for [ImageGenResult] with JSON serialization support.
class ImageGenResultModel {
  const ImageGenResultModel._({required this.result});

  /// Creates a model from an API JSON response.
  ///
  /// Expected API format:
  /// ```json
  /// {
  ///   "imageBase64": "data:image/jpeg;base64,...",
  ///   "imageUrl": "https://...",
  ///   "revisedPrompt": "..."
  /// }
  /// ```
  factory ImageGenResultModel.fromJson(
    Map<String, Object?> json, {
    required String prompt,
  }) =>
      ImageGenResultModel._(
        result: ImageGenResult(
          prompt: prompt,
          imageBase64: json['imageBase64'] as String?,
          imageUrl: json['imageUrl'] as String?,
          revisedPrompt: json['revisedPrompt'] as String?,
        ),
      );

  /// The underlying domain entity.
  final ImageGenResult result;

  /// Converts a generation request to JSON for the API.
  static Map<String, Object?> generateRequestToJson({
    required String prompt,
    ImageGenStyle? style,
    ImageGenSize? size,
  }) =>
      {
        'prompt': prompt,
        if (style != null) 'style': style.apiValue,
        if (size != null) 'size': size.apiValue,
      };

  /// Converts an edit request to JSON for the API.
  static Map<String, Object?> editRequestToJson({
    required String imageSource,
    required String prompt,
  }) =>
      {
        'image': imageSource,
        'prompt': prompt,
      };
}
