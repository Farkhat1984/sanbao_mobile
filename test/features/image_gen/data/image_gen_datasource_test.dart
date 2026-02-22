import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';

/// Lightweight mock for DioClient that delegates to a real Dio + DioAdapter.
///
/// This avoids needing to construct a real DioClient (which requires
/// SecureStorage and interceptors) while still testing the HTTP layer.
class _MockDioClient {
  _MockDioClient(this._dio);
  final Dio _dio;

  Future<T> post<T>(String path, {Object? data}) async {
    final response = await _dio.post<T>(path, data: data);
    return response.data as T;
  }
}

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://sanbao.ai'));
    dioAdapter = DioAdapter(dio: dio);
  });

  group('Image generation API', () {
    test('POST /api/image-generate sends correct body and parses response',
        () async {
      dioAdapter.onPost(
        '/api/image-generate',
        (server) => server.reply(200, {
          'imageBase64': 'data:image/png;base64,abc123',
          'revisedPrompt': 'A beautiful sunset painting',
        }),
        data: {
          'prompt': 'sunset',
          'style': 'vivid',
          'size': '1024x1024',
        },
      );

      final client = _MockDioClient(dio);
      final response = await client.post<Map<String, Object?>>(
        '/api/image-generate',
        data: {
          'prompt': 'sunset',
          'style': 'vivid',
          'size': '1024x1024',
        },
      );

      expect(response['imageBase64'], startsWith('data:image'));
      expect(response['revisedPrompt'], contains('sunset'));
    });

    test('POST /api/image-edit sends correct body', () async {
      dioAdapter.onPost(
        '/api/image-edit',
        (server) => server.reply(200, {
          'imageUrl': 'https://sanbao.ai/generated/edited.png',
        }),
        data: {
          'image': 'data:image/png;base64,original',
          'prompt': 'Make it brighter',
        },
      );

      final client = _MockDioClient(dio);
      final response = await client.post<Map<String, Object?>>(
        '/api/image-edit',
        data: {
          'image': 'data:image/png;base64,original',
          'prompt': 'Make it brighter',
        },
      );

      expect(response['imageUrl'], contains('edited.png'));
    });

    test('handles 429 rate limit error', () async {
      dioAdapter.onPost(
        '/api/image-generate',
        (server) => server.reply(429, {
          'error': 'Too many requests',
          'limit': 5,
        }),
      );

      expect(
        () => dio.post<Map<String, Object?>>('/api/image-generate', data: {'prompt': 'test'}),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('ImageGenStyle enum', () {
    test('vivid has correct API value and label', () {
      expect(ImageGenStyle.vivid.apiValue, 'vivid');
      expect(ImageGenStyle.vivid.label, 'Яркий');
    });

    test('natural has correct API value and label', () {
      expect(ImageGenStyle.natural.apiValue, 'natural');
      expect(ImageGenStyle.natural.label, 'Естественный');
    });
  });

  group('ImageGenSize enum', () {
    test('square has correct API value', () {
      expect(ImageGenSize.square.apiValue, '1024x1024');
      expect(ImageGenSize.square.label, '1024 x 1024');
    });

    test('landscape has correct API value', () {
      expect(ImageGenSize.landscape.apiValue, '1792x1024');
    });

    test('portrait has correct API value', () {
      expect(ImageGenSize.portrait.apiValue, '1024x1792');
    });
  });
}
