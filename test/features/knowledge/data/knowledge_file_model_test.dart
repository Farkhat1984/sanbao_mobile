import 'package:flutter_test/flutter_test.dart';
import 'package:sanbao_flutter/features/knowledge/data/models/knowledge_file_model.dart';
import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';

void main() {
  group('KnowledgeFileModel', () {
    group('fromJson', () {
      test('parses complete JSON response', () {
        final json = <String, Object?>{
          'id': 'file_123',
          'name': 'Мой документ.md',
          'description': 'Описание файла',
          'content': '# Заголовок\nТекст',
          'fileType': 'md',
          'sizeBytes': 2048,
          'createdAt': '2025-01-15T10:30:00Z',
          'updatedAt': '2025-01-16T14:00:00Z',
        };

        final model = KnowledgeFileModel.fromJson(json);

        expect(model.file.id, 'file_123');
        expect(model.file.name, 'Мой документ.md');
        expect(model.file.description, 'Описание файла');
        expect(model.file.content, '# Заголовок\nТекст');
        expect(model.file.fileType, 'md');
        expect(model.file.sizeBytes, 2048);
        expect(model.file.createdAt, DateTime.utc(2025, 1, 15, 10, 30));
        expect(model.file.updatedAt, DateTime.utc(2025, 1, 16, 14));
      });

      test('handles null optional fields', () {
        final json = <String, Object?>{
          'id': 'file_456',
          'name': 'Файл',
          'description': null,
          'content': null,
          'fileType': 'txt',
          'sizeBytes': 100,
          'createdAt': '2025-01-15T00:00:00Z',
          'updatedAt': '2025-01-15T00:00:00Z',
        };

        final model = KnowledgeFileModel.fromJson(json);

        expect(model.file.description, isNull);
        expect(model.file.content, isNull);
      });

      test('uses defaults for missing fields', () {
        final model = KnowledgeFileModel.fromJson(<String, Object?>{});

        expect(model.file.id, '');
        expect(model.file.name, '');
        expect(model.file.fileType, 'md');
        expect(model.file.sizeBytes, 0);
        // Dates default to now
        expect(
          model.file.createdAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(2),
        );
      });

      test('handles sizeBytes as double from JSON', () {
        final json = <String, Object?>{
          'id': 'f1',
          'name': 'test',
          'sizeBytes': 1024.0, // num, not int
          'createdAt': '2025-01-01T00:00:00Z',
          'updatedAt': '2025-01-01T00:00:00Z',
        };

        final model = KnowledgeFileModel.fromJson(json);

        expect(model.file.sizeBytes, 1024);
      });
    });

    group('toJson', () {
      test('serializes name and content', () {
        final file = KnowledgeFile(
          id: 'f1',
          name: 'Документ',
          content: 'Содержимое',
          sizeBytes: 100,
          fileType: 'md',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = KnowledgeFileModel.fromEntity(file).toJson();

        expect(json['name'], 'Документ');
        expect(json['content'], 'Содержимое');
        expect(json.containsKey('description'), isFalse);
      });

      test('includes description when present', () {
        final file = KnowledgeFile(
          id: 'f1',
          name: 'Документ',
          description: 'Описание',
          sizeBytes: 100,
          fileType: 'md',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = KnowledgeFileModel.fromEntity(file).toJson();

        expect(json['description'], 'Описание');
      });
    });

    group('fromJsonList', () {
      test('parses list of files', () {
        final jsonList = <Object?>[
          {
            'id': 'f1',
            'name': 'File 1',
            'fileType': 'md',
            'sizeBytes': 100,
            'createdAt': '2025-01-01T00:00:00Z',
            'updatedAt': '2025-01-01T00:00:00Z',
          },
          {
            'id': 'f2',
            'name': 'File 2',
            'fileType': 'txt',
            'sizeBytes': 200,
            'createdAt': '2025-01-02T00:00:00Z',
            'updatedAt': '2025-01-02T00:00:00Z',
          },
        ];

        final files = KnowledgeFileModel.fromJsonList(jsonList);

        expect(files, hasLength(2));
        expect(files[0].name, 'File 1');
        expect(files[1].name, 'File 2');
      });

      test('filters out non-map entries', () {
        final jsonList = <Object?>[
          {
            'id': 'f1',
            'name': 'Valid',
            'createdAt': '2025-01-01T00:00:00Z',
            'updatedAt': '2025-01-01T00:00:00Z',
          },
          null,
          'invalid',
          42,
        ];

        final files = KnowledgeFileModel.fromJsonList(jsonList);

        expect(files, hasLength(1));
        expect(files[0].name, 'Valid');
      });

      test('handles empty list', () {
        final files = KnowledgeFileModel.fromJsonList([]);
        expect(files, isEmpty);
      });
    });
  });

  group('KnowledgeFile entity', () {
    test('formattedSize shows bytes', () {
      final file = KnowledgeFile(
        id: 'f1', name: 'test', sizeBytes: 500,
        fileType: 'md', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(file.formattedSize, '500 B');
    });

    test('formattedSize shows KB', () {
      final file = KnowledgeFile(
        id: 'f1', name: 'test', sizeBytes: 2560,
        fileType: 'md', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(file.formattedSize, '2.5 KB');
    });

    test('formattedSize shows MB', () {
      final file = KnowledgeFile(
        id: 'f1', name: 'test', sizeBytes: 1572864,
        fileType: 'md', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(file.formattedSize, '1.5 MB');
    });

    test('equality by id', () {
      final a = KnowledgeFile(
        id: 'f1', name: 'A', sizeBytes: 1,
        fileType: 'md', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final b = KnowledgeFile(
        id: 'f1', name: 'B', sizeBytes: 2,
        fileType: 'txt', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final c = KnowledgeFile(
        id: 'f2', name: 'A', sizeBytes: 1,
        fileType: 'md', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );

      expect(a, equals(b)); // same id
      expect(a, isNot(equals(c))); // different id
    });

    test('copyWith creates modified copy', () {
      final original = KnowledgeFile(
        id: 'f1', name: 'Original', sizeBytes: 100,
        fileType: 'md', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final copy = original.copyWith(name: 'Modified', sizeBytes: 200);

      expect(copy.name, 'Modified');
      expect(copy.sizeBytes, 200);
      expect(copy.id, 'f1'); // unchanged
    });
  });
}
