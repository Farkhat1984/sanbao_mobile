/// Abstract image generation repository contract.
///
/// Defines operations for generating and editing images via the API.
library;

import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';

/// Abstract repository for image generation operations.
abstract class ImageGenRepository {
  /// Generates an image from a text prompt.
  ///
  /// [prompt] is the text description of the desired image.
  /// [style] and [size] are optional generation parameters.
  Future<ImageGenResult> generate({
    required String prompt,
    ImageGenStyle? style,
    ImageGenSize? size,
  });

  /// Edits an existing image based on a text prompt.
  ///
  /// [imageSource] is the base64-encoded image or URL to edit.
  /// [prompt] describes the desired edits.
  Future<ImageGenResult> edit({
    required String imageSource,
    required String prompt,
  });
}
