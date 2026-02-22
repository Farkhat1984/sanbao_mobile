import 'package:flutter_test/flutter_test.dart';
import 'package:sanbao_flutter/features/image_gen/data/models/image_gen_result_model.dart';
import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';

void main() {
  group('ImageGenResultModel', () {
    group('fromJson', () {
      test('parses full response with base64 and URL', () {
        final json = <String, Object?>{
          'imageBase64': 'data:image/jpeg;base64,/9j/4AAQ...',
          'imageUrl': 'https://example.com/image.png',
          'revisedPrompt': 'A beautiful sunset over the ocean',
        };

        final model = ImageGenResultModel.fromJson(json, prompt: 'sunset');

        expect(model.result.prompt, 'sunset');
        expect(model.result.imageBase64, startsWith('data:image'));
        expect(model.result.imageUrl, 'https://example.com/image.png');
        expect(model.result.revisedPrompt, contains('sunset'));
      });

      test('parses response with only imageUrl', () {
        final json = <String, Object?>{
          'imageUrl': 'https://example.com/gen.png',
        };

        final model =
            ImageGenResultModel.fromJson(json, prompt: 'a cat');

        expect(model.result.imageUrl, 'https://example.com/gen.png');
        expect(model.result.imageBase64, isNull);
        expect(model.result.revisedPrompt, isNull);
      });

      test('parses response with only imageBase64', () {
        final json = <String, Object?>{
          'imageBase64': 'data:image/png;base64,abc123',
        };

        final model =
            ImageGenResultModel.fromJson(json, prompt: 'test');

        expect(model.result.imageBase64, 'data:image/png;base64,abc123');
        expect(model.result.imageUrl, isNull);
        expect(model.result.isBase64, isTrue);
      });
    });

    group('generateRequestToJson', () {
      test('includes only prompt when no options', () {
        final json = ImageGenResultModel.generateRequestToJson(
          prompt: 'A dog',
        );

        expect(json, {'prompt': 'A dog'});
        expect(json.containsKey('style'), isFalse);
        expect(json.containsKey('size'), isFalse);
      });

      test('includes style and size when provided', () {
        final json = ImageGenResultModel.generateRequestToJson(
          prompt: 'A dog',
          style: ImageGenStyle.vivid,
          size: ImageGenSize.landscape,
        );

        expect(json['prompt'], 'A dog');
        expect(json['style'], 'vivid');
        expect(json['size'], '1792x1024');
      });

      test('all style values map correctly', () {
        expect(ImageGenStyle.vivid.apiValue, 'vivid');
        expect(ImageGenStyle.natural.apiValue, 'natural');
      });

      test('all size values map correctly', () {
        expect(ImageGenSize.square.apiValue, '1024x1024');
        expect(ImageGenSize.landscape.apiValue, '1792x1024');
        expect(ImageGenSize.portrait.apiValue, '1024x1792');
      });
    });

    group('editRequestToJson', () {
      test('serializes edit request correctly', () {
        final json = ImageGenResultModel.editRequestToJson(
          imageSource: 'data:image/png;base64,abc',
          prompt: 'Make it blue',
        );

        expect(json, {
          'image': 'data:image/png;base64,abc',
          'prompt': 'Make it blue',
        });
      });
    });
  });

  group('ImageGenResult entity', () {
    test('displayImageSource prefers base64', () {
      const result = ImageGenResult(
        prompt: 'test',
        imageBase64: 'data:base64',
        imageUrl: 'https://url',
      );

      expect(result.displayImageSource, 'data:base64');
    });

    test('displayImageSource falls back to URL', () {
      const result = ImageGenResult(
        prompt: 'test',
        imageUrl: 'https://url',
      );

      expect(result.displayImageSource, 'https://url');
    });

    test('isBase64 returns true when base64 present', () {
      const result = ImageGenResult(
        prompt: 'test',
        imageBase64: 'data:image/png;base64,abc',
      );

      expect(result.isBase64, isTrue);
    });

    test('isBase64 returns false when base64 absent', () {
      const result = ImageGenResult(
        prompt: 'test',
        imageUrl: 'https://url',
      );

      expect(result.isBase64, isFalse);
    });

    test('equality works by prompt and image data', () {
      const a = ImageGenResult(prompt: 'test', imageUrl: 'u1');
      const b = ImageGenResult(prompt: 'test', imageUrl: 'u1');
      const c = ImageGenResult(prompt: 'test', imageUrl: 'u2');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
