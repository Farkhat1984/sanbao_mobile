/// Image generation result entity.
///
/// Represents the output of an image generation or image editing
/// API call, containing the generated image data and the prompt used.
library;

/// Result of an image generation or editing operation.
///
/// At least one of [imageBase64] or [imageUrl] will be non-null.
/// The [revisedPrompt] may be returned by certain models that
/// rephrase the user's prompt for better results.
class ImageGenResult {
  const ImageGenResult({
    required this.prompt,
    this.imageBase64,
    this.imageUrl,
    this.revisedPrompt,
  }) : assert(
          imageBase64 != null || imageUrl != null,
          'At least one of imageBase64 or imageUrl must be provided',
        );

  /// The original prompt used for generation.
  final String prompt;

  /// Base64-encoded image data with data URI prefix
  /// (e.g., `data:image/jpeg;base64,...`).
  final String? imageBase64;

  /// Direct URL to the generated image (if the API returns a URL).
  final String? imageUrl;

  /// The revised/enhanced prompt returned by the model, if applicable.
  final String? revisedPrompt;

  /// Returns the best available image source for display.
  ///
  /// Prefers base64 data URI over URL for offline display.
  String get displayImageSource => imageBase64 ?? imageUrl ?? '';

  /// Whether the result contains a base64-encoded image.
  bool get isBase64 => imageBase64 != null && imageBase64!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageGenResult &&
          runtimeType == other.runtimeType &&
          prompt == other.prompt &&
          imageBase64 == other.imageBase64 &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(prompt, imageBase64, imageUrl);

  @override
  String toString() =>
      'ImageGenResult(prompt=${prompt.length > 40 ? '${prompt.substring(0, 40)}...' : prompt}, '
      'hasBase64=${imageBase64 != null}, hasUrl=${imageUrl != null})';
}

/// Available image generation styles.
enum ImageGenStyle {
  /// Vivid, highly detailed and saturated images.
  vivid('vivid', 'Яркий'),

  /// Natural, more subdued and realistic images.
  natural('natural', 'Естественный');

  const ImageGenStyle(this.apiValue, this.label);

  /// Value sent to the API.
  final String apiValue;

  /// Russian display label.
  final String label;
}

/// Available image generation sizes.
enum ImageGenSize {
  /// Square 1024x1024.
  square('1024x1024', '1024 x 1024'),

  /// Landscape 1792x1024.
  landscape('1792x1024', '1792 x 1024'),

  /// Portrait 1024x1792.
  portrait('1024x1792', '1024 x 1792');

  const ImageGenSize(this.apiValue, this.label);

  /// Value sent to the API.
  final String apiValue;

  /// Display label.
  final String label;
}
