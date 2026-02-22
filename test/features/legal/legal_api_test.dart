import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://sanbao.ai'));
    dioAdapter = DioAdapter(dio: dio);
  });

  group('Legal API - GET /api/articles', () {
    test('fetches article with full data', () async {
      dioAdapter.onGet(
        '/api/articles',
        (server) => server.reply(200, {
          'code': 'gk_rk',
          'article': '15',
          'title': 'Возмещение убытков',
          'text': 'Лицо, право которого нарушено, может требовать...',
          'annotation': 'Статья регулирует порядок возмещения убытков',
          'isValid': true,
          'validFrom': '2015-01-01T00:00:00Z',
          'validTo': null,
          'sourceUrl': 'https://adilet.zan.kz/rus/docs/K990002000_/z990415.htm',
        }),
        queryParameters: {'code': 'gk_rk', 'article': '15'},
      );

      final response = await dio.get<Map<String, Object?>>(
        '/api/articles',
        queryParameters: {'code': 'gk_rk', 'article': '15'},
      );

      expect(response.data!['code'], 'gk_rk');
      expect(response.data!['article'], '15');
      expect(response.data!['title'], 'Возмещение убытков');
      expect(response.data!['text'], isNotEmpty);
      expect(response.data!['isValid'], isTrue);
      expect(response.data!['sourceUrl'], contains('adilet.zan.kz'));
    });

    test('fetches article with content field instead of text', () async {
      dioAdapter.onGet(
        '/api/articles',
        (server) => server.reply(200, {
          'code': 'uk_rk',
          'article': '120',
          'title': 'Убийство',
          'content': 'Умышленное причинение смерти другому человеку...',
          'isValid': true,
        }),
        queryParameters: {'code': 'uk_rk', 'article': '120'},
      );

      final response = await dio.get<Map<String, Object?>>(
        '/api/articles',
        queryParameters: {'code': 'uk_rk', 'article': '120'},
      );

      // API may return 'content' instead of 'text'
      final text = response.data!['text'] ?? response.data!['content'];
      expect(text, isNotNull);
    });

    test('handles 404 for non-existent article', () async {
      dioAdapter.onGet(
        '/api/articles',
        (server) => server.throws(
          404,
          DioException(
            requestOptions: RequestOptions(path: '/api/articles'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/api/articles'),
              statusCode: 404,
              data: {'error': 'Article not found'},
            ),
          ),
        ),
        queryParameters: {'code': 'gk_rk', 'article': '99999'},
      );

      expect(
        () => dio.get<Map<String, Object?>>(
          '/api/articles',
          queryParameters: {'code': 'gk_rk', 'article': '99999'},
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('fetches article marked as invalid', () async {
      dioAdapter.onGet(
        '/api/articles',
        (server) => server.reply(200, {
          'code': 'gk_rk',
          'article': '100',
          'title': 'Утратила силу',
          'text': 'Данная статья утратила силу...',
          'isValid': false,
          'validFrom': '2010-01-01T00:00:00Z',
          'validTo': '2023-06-01T00:00:00Z',
        }),
        queryParameters: {'code': 'gk_rk', 'article': '100'},
      );

      final response = await dio.get<Map<String, Object?>>(
        '/api/articles',
        queryParameters: {'code': 'gk_rk', 'article': '100'},
      );

      expect(response.data!['isValid'], isFalse);
      expect(response.data!['validTo'], isNotNull);
    });
  });

  group('Report API - POST /api/reports', () {
    test('submits report with reason and details', () async {
      dioAdapter.onPost(
        '/api/reports',
        (server) => server.reply(201, null),
        data: {
          'messageId': 'msg_123',
          'reason': 'inaccurate',
          'details': 'Неправильная статья закона',
        },
      );

      final response = await dio.post<void>(
        '/api/reports',
        data: {
          'messageId': 'msg_123',
          'reason': 'inaccurate',
          'details': 'Неправильная статья закона',
        },
      );

      expect(response.statusCode, 201);
    });

    test('submits report without details', () async {
      dioAdapter.onPost(
        '/api/reports',
        (server) => server.reply(201, null),
        data: {
          'messageId': 'msg_456',
          'reason': 'spam',
        },
      );

      final response = await dio.post<void>(
        '/api/reports',
        data: {
          'messageId': 'msg_456',
          'reason': 'spam',
        },
      );

      expect(response.statusCode, 201);
    });
  });
}
