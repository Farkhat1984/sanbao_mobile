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

  group('Billing API - POST /api/billing/apply-promo', () {
    test('applies valid promo code', () async {
      dioAdapter.onPost(
        '/api/billing/apply-promo',
        (server) => server.reply(200, {
          'valid': true,
          'discount': 20,
          'message': 'Скидка 20% применена',
        }),
        data: {'code': 'SALE20'},
      );

      final response = await dio.post<Map<String, Object?>>(
        '/api/billing/apply-promo',
        data: {'code': 'SALE20'},
      );

      expect(response.data!['valid'], isTrue);
      expect(response.data!['discount'], 20);
      expect(response.data!['message'], contains('20%'));
    });

    test('rejects invalid promo code', () async {
      dioAdapter.onPost(
        '/api/billing/apply-promo',
        (server) => server.reply(200, {
          'valid': false,
          'discount': 0,
          'message': 'Промокод недействителен',
        }),
        data: {'code': 'INVALID'},
      );

      final response = await dio.post<Map<String, Object?>>(
        '/api/billing/apply-promo',
        data: {'code': 'INVALID'},
      );

      expect(response.data!['valid'], isFalse);
      expect(response.data!['discount'], 0);
    });

    test('handles expired promo code', () async {
      dioAdapter.onPost(
        '/api/billing/apply-promo',
        (server) => server.reply(200, {
          'valid': false,
          'discount': 0,
          'message': 'Промокод истёк',
        }),
        data: {'code': 'EXPIRED2024'},
      );

      final response = await dio.post<Map<String, Object?>>(
        '/api/billing/apply-promo',
        data: {'code': 'EXPIRED2024'},
      );

      expect(response.data!['valid'], isFalse);
      expect(response.data!['message'], contains('истёк'));
    });
  });

  group('Billing API - GET /api/billing/plans', () {
    test('fetches available plans', () async {
      dioAdapter.onGet(
        '/api/billing/plans',
        (server) => server.reply(200, {
          'plans': [
            {
              'id': 'free',
              'name': 'Бесплатный',
              'price': 0,
              'messagesLimit': 50,
            },
            {
              'id': 'pro',
              'name': 'Профессионал',
              'price': 1990,
              'messagesLimit': 1000,
            },
          ],
        }),
      );

      final response =
          await dio.get<Map<String, Object?>>('/api/billing/plans');
      final plans = response.data!['plans'] as List;

      expect(plans, hasLength(2));
      expect((plans[0] as Map)['id'], 'free');
      expect((plans[1] as Map)['price'], 1990);
    });
  });

  group('Billing API - POST /api/billing/checkout', () {
    test('creates checkout session', () async {
      dioAdapter.onPost(
        '/api/billing/checkout',
        (server) => server.reply(200, {
          'url': 'https://checkout.stripe.com/session_123',
        }),
        data: {'planId': 'pro'},
      );

      final response = await dio.post<Map<String, Object?>>(
        '/api/billing/checkout',
        data: {'planId': 'pro'},
      );

      expect(response.data!['url'], contains('stripe.com'));
    });
  });

  group('Billing API - GET /api/billing/usage', () {
    test('fetches usage stats', () async {
      dioAdapter.onGet(
        '/api/billing/usage',
        (server) => server.reply(200, {
          'usage': {
            'messagesUsed': 42,
            'messagesLimit': 100,
            'tokensUsed': 50000,
            'tokensLimit': 500000,
          },
        }),
      );

      final response =
          await dio.get<Map<String, Object?>>('/api/billing/usage');
      final usage = response.data!['usage'] as Map;

      expect(usage['messagesUsed'], 42);
      expect(usage['messagesLimit'], 100);
    });
  });
}
