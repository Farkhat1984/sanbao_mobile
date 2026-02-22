import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sanbao_flutter/features/knowledge/data/models/knowledge_file_model.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://sanbao.ai'));
    dioAdapter = DioAdapter(dio: dio);
  });

  group('Knowledge API - GET /api/user-files', () {
    test('fetches list of files', () async {
      dioAdapter.onGet(
        '/api/user-files',
        (server) => server.reply(200, [
          {
            'id': 'f1',
            'name': 'Документ 1',
            'fileType': 'md',
            'sizeBytes': 1024,
            'createdAt': '2025-06-01T00:00:00Z',
            'updatedAt': '2025-06-01T00:00:00Z',
          },
          {
            'id': 'f2',
            'name': 'Документ 2',
            'fileType': 'txt',
            'sizeBytes': 2048,
            'createdAt': '2025-06-02T00:00:00Z',
            'updatedAt': '2025-06-02T00:00:00Z',
          },
        ]),
      );

      final response = await dio.get<List<Object?>>('/api/user-files');
      final files = KnowledgeFileModel.fromJsonList(response.data!);

      expect(files, hasLength(2));
      expect(files[0].id, 'f1');
      expect(files[0].name, 'Документ 1');
      expect(files[1].id, 'f2');
      expect(files[1].sizeBytes, 2048);
    });

    test('handles empty file list', () async {
      dioAdapter.onGet(
        '/api/user-files',
        (server) => server.reply(200, <Object?>[]),
      );

      final response = await dio.get<List<Object?>>('/api/user-files');
      final files = KnowledgeFileModel.fromJsonList(response.data!);

      expect(files, isEmpty);
    });
  });

  group('Knowledge API - GET /api/user-files/:id', () {
    test('fetches single file with content', () async {
      dioAdapter.onGet(
        '/api/user-files/f1',
        (server) => server.reply(200, {
          'id': 'f1',
          'name': 'Мой файл',
          'description': 'Описание',
          'content': '# Заголовок\nТекст документа',
          'fileType': 'md',
          'sizeBytes': 4096,
          'createdAt': '2025-06-01T10:00:00Z',
          'updatedAt': '2025-06-01T12:00:00Z',
        }),
      );

      final response =
          await dio.get<Map<String, Object?>>('/api/user-files/f1');
      final file = KnowledgeFileModel.fromJson(response.data!).file;

      expect(file.id, 'f1');
      expect(file.name, 'Мой файл');
      expect(file.description, 'Описание');
      expect(file.content, contains('Заголовок'));
      expect(file.sizeBytes, 4096);
    });

    test('handles 404 for unknown file', () async {
      dioAdapter.onGet(
        '/api/user-files/unknown',
        (server) => server.throws(
          404,
          DioException(
            requestOptions: RequestOptions(path: '/api/user-files/unknown'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/api/user-files/unknown'),
              statusCode: 404,
              data: {'error': 'File not found'},
            ),
          ),
        ),
      );

      expect(
        () => dio.get<Map<String, Object?>>('/api/user-files/unknown'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('Knowledge API - POST /api/user-files', () {
    test('creates file with correct body', () async {
      dioAdapter.onPost(
        '/api/user-files',
        (server) => server.reply(201, {
          'id': 'f_new',
          'name': 'Новый файл',
          'content': 'Содержимое',
          'fileType': 'md',
          'sizeBytes': 512,
          'createdAt': '2025-06-15T00:00:00Z',
          'updatedAt': '2025-06-15T00:00:00Z',
        }),
        data: {
          'name': 'Новый файл',
          'content': 'Содержимое',
        },
      );

      final response = await dio.post<Map<String, Object?>>(
        '/api/user-files',
        data: {'name': 'Новый файл', 'content': 'Содержимое'},
      );

      final file = KnowledgeFileModel.fromJson(response.data!).file;
      expect(file.id, 'f_new');
      expect(file.name, 'Новый файл');
    });
  });

  group('Knowledge API - PUT /api/user-files/:id', () {
    test('updates file name', () async {
      dioAdapter.onPut(
        '/api/user-files/f1',
        (server) => server.reply(200, {
          'id': 'f1',
          'name': 'Обновлённое имя',
          'fileType': 'md',
          'sizeBytes': 1024,
          'createdAt': '2025-06-01T00:00:00Z',
          'updatedAt': '2025-06-15T00:00:00Z',
        }),
        data: {'name': 'Обновлённое имя'},
      );

      final response = await dio.put<Map<String, Object?>>(
        '/api/user-files/f1',
        data: {'name': 'Обновлённое имя'},
      );

      final file = KnowledgeFileModel.fromJson(response.data!).file;
      expect(file.name, 'Обновлённое имя');
    });
  });

  group('Knowledge API - DELETE /api/user-files/:id', () {
    test('deletes file successfully', () async {
      dioAdapter.onDelete(
        '/api/user-files/f1',
        (server) => server.reply(204, null),
      );

      final response = await dio.delete<void>('/api/user-files/f1');
      expect(response.statusCode, 204);
    });
  });
}
