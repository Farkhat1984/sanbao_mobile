import 'package:flutter_test/flutter_test.dart';
import 'package:sanbao_flutter/features/chat/data/models/chat_event_model.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/artifact.dart';

void main() {
  group('SanbaoTagParser', () {
    group('extractArtifacts', () {
      test('extracts single document artifact', () {
        const content = '''
Вот ваш документ:
<sanbao-doc type="DOCUMENT" title="Договор аренды">
# Договор аренды
Стороны договорились...
</sanbao-doc>
Готово!''';

        final result = SanbaoTagParser.extractArtifacts(content);

        expect(result.artifacts, hasLength(1));
        expect(result.artifacts[0].id, 'artifact_0');
        expect(result.artifacts[0].type, ArtifactType.document);
        expect(result.artifacts[0].title, 'Договор аренды');
        expect(result.artifacts[0].content, contains('Стороны договорились'));
        expect(result.artifacts[0].language, isNull);
        expect(result.cleanContent, contains('Вот ваш документ:'));
        expect(result.cleanContent, contains('Готово!'));
        expect(result.cleanContent, isNot(contains('sanbao-doc')));
      });

      test('extracts code artifact with language detection (python)', () {
        const content = '''
<sanbao-doc type="CODE" title="Скрипт">
import os
def main():
    pass
</sanbao-doc>''';

        final result = SanbaoTagParser.extractArtifacts(content);

        expect(result.artifacts, hasLength(1));
        expect(result.artifacts[0].type, ArtifactType.code);
        expect(result.artifacts[0].language, 'python');
      });

      test('extracts code artifact with language detection (html)', () {
        const content = '''
<sanbao-doc type="CODE" title="Страница">
<!DOCTYPE html>
<html><body>Hello</body></html>
</sanbao-doc>''';

        final result = SanbaoTagParser.extractArtifacts(content);

        expect(result.artifacts[0].language, 'html');
      });

      test('extracts code artifact with language detection (react/jsx)', () {
        const content = '''
<sanbao-doc type="CODE" title="Компонент">
import React from "react"
export default function App() {}
</sanbao-doc>''';

        final result = SanbaoTagParser.extractArtifacts(content);

        expect(result.artifacts[0].language, 'jsx');
      });

      test('defaults to javascript for unknown code', () {
        const content = '''
<sanbao-doc type="CODE" title="Script">
const x = 42;
console.log(x);
</sanbao-doc>''';

        final result = SanbaoTagParser.extractArtifacts(content);

        expect(result.artifacts[0].language, 'javascript');
      });

      test('extracts multiple artifacts with incrementing IDs', () {
        const content = '''
<sanbao-doc type="DOCUMENT" title="Док 1">Содержимое 1</sanbao-doc>
Текст между
<sanbao-doc type="CODE" title="Код 2">console.log("hi")</sanbao-doc>
<sanbao-doc type="ANALYSIS" title="Анализ 3">Выводы</sanbao-doc>''';

        final result = SanbaoTagParser.extractArtifacts(content);

        expect(result.artifacts, hasLength(3));
        expect(result.artifacts[0].id, 'artifact_0');
        expect(result.artifacts[1].id, 'artifact_1');
        expect(result.artifacts[2].id, 'artifact_2');
        expect(result.artifacts[0].type, ArtifactType.document);
        expect(result.artifacts[1].type, ArtifactType.code);
        expect(result.artifacts[2].type, ArtifactType.analysis);
      });

      test('returns empty list and unchanged content when no tags', () {
        const content = 'Обычный текст без артефактов.';

        final result = SanbaoTagParser.extractArtifacts(content);

        expect(result.artifacts, isEmpty);
        expect(result.cleanContent, content);
      });

      test('maps CONTRACT and CLAIM types to document', () {
        const content = '''
<sanbao-doc type="CONTRACT" title="Контракт">...</sanbao-doc>
<sanbao-doc type="CLAIM" title="Иск">...</sanbao-doc>''';

        final result = SanbaoTagParser.extractArtifacts(content);

        expect(result.artifacts[0].type, ArtifactType.document);
        expect(result.artifacts[1].type, ArtifactType.document);
      });
    });

    group('extractClarifyQuestions', () {
      test('extracts select-type questions', () {
        const content = '''
Мне нужно уточнить:
<sanbao-clarify>[{"id":"q1","question":"Тип договора?","type":"select","options":["Аренда","Купля-продажа","Услуги"]}]</sanbao-clarify>''';

        final result = SanbaoTagParser.extractClarifyQuestions(content);

        expect(result.questions, hasLength(1));
        expect(result.questions[0].id, 'q1');
        expect(result.questions[0].question, 'Тип договора?');
        expect(result.questions[0].type, 'select');
        expect(result.questions[0].options, ['Аренда', 'Купля-продажа', 'Услуги']);
        expect(result.questions[0].isSelect, isTrue);
        expect(result.questions[0].isTextInput, isFalse);
        expect(result.cleanContent, 'Мне нужно уточнить:');
      });

      test('extracts text-type questions', () {
        const content = '''
<sanbao-clarify>[{"id":"q1","question":"Укажите ИНН","type":"text","placeholder":"12 цифр"}]</sanbao-clarify>''';

        final result = SanbaoTagParser.extractClarifyQuestions(content);

        expect(result.questions, hasLength(1));
        expect(result.questions[0].isTextInput, isTrue);
        expect(result.questions[0].placeholder, '12 цифр');
      });

      test('extracts multiple questions', () {
        const content = '''
<sanbao-clarify>[
  {"id":"q1","question":"Вопрос 1?","type":"select","options":["А","Б"]},
  {"id":"q2","question":"Вопрос 2?","type":"text"}
]</sanbao-clarify>''';

        final result = SanbaoTagParser.extractClarifyQuestions(content);

        expect(result.questions, hasLength(2));
        expect(result.questions[0].id, 'q1');
        expect(result.questions[1].id, 'q2');
      });

      test('returns empty list for invalid JSON', () {
        const content = '<sanbao-clarify>not valid json</sanbao-clarify>';

        final result = SanbaoTagParser.extractClarifyQuestions(content);

        expect(result.questions, isEmpty);
        expect(result.cleanContent, isEmpty);
      });

      test('returns empty list when no clarify tags', () {
        const content = 'Просто текст без уточнений';

        final result = SanbaoTagParser.extractClarifyQuestions(content);

        expect(result.questions, isEmpty);
        expect(result.cleanContent, content);
      });

      test('handles missing fields gracefully', () {
        const content = '<sanbao-clarify>[{"id":"q1"}]</sanbao-clarify>';

        final result = SanbaoTagParser.extractClarifyQuestions(content);

        expect(result.questions, hasLength(1));
        expect(result.questions[0].id, 'q1');
        expect(result.questions[0].question, '');
        expect(result.questions[0].type, 'select');
        expect(result.questions[0].options, isNull);
      });
    });

    group('Legal references', () {
      test('hasLegalReferences detects legal links', () {
        const content =
            'Согласно [ст. 15 ГК РК](article://gk_rk/15), убытки...';

        expect(SanbaoTagParser.hasLegalReferences(content), isTrue);
      });

      test('hasLegalReferences returns false for plain text', () {
        const content = 'Обычный текст без ссылок';

        expect(SanbaoTagParser.hasLegalReferences(content), isFalse);
      });

      test('extractLegalReferences parses single reference', () {
        const content =
            'Согласно [ст. 15 ГК РК](article://gk_rk/15), убытки...';

        final refs = SanbaoTagParser.extractLegalReferences(content);

        expect(refs, hasLength(1));
        expect(refs[0].code, 'gk_rk');
        expect(refs[0].article, '15');
        expect(refs[0].displayText, 'ст. 15 ГК РК');
      });

      test('extractLegalReferences parses multiple references', () {
        const content = '''
[ст. 15 ГК РК](article://gk_rk/15) и [ст. 917 ГК РК](article://gk_rk/917)
а также [ст. 152.1 УК РК](article://uk_rk/152.1)''';

        final refs = SanbaoTagParser.extractLegalReferences(content);

        expect(refs, hasLength(3));
        expect(refs[0].article, '15');
        expect(refs[1].article, '917');
        expect(refs[2].article, '152.1');
        expect(refs[2].code, 'uk_rk');
      });

      test('extractLegalReferences returns empty for no refs', () {
        final refs = SanbaoTagParser.extractLegalReferences('Текст');
        expect(refs, isEmpty);
      });
    });
  });

  group('ClarifyQuestion', () {
    test('fromJson creates with all fields', () {
      final json = {
        'id': 'q1',
        'question': 'Вопрос?',
        'type': 'select',
        'options': ['А', 'Б', 'В'],
        'placeholder': null,
      };

      final q = ClarifyQuestion.fromJson(json);

      expect(q.id, 'q1');
      expect(q.question, 'Вопрос?');
      expect(q.type, 'select');
      expect(q.options, ['А', 'Б', 'В']);
      expect(q.isSelect, isTrue);
      expect(q.isTextInput, isFalse);
    });

    test('fromJson creates text input question', () {
      final json = {
        'id': 'q2',
        'question': 'ИНН?',
        'type': 'text',
        'placeholder': 'Введите ИНН',
      };

      final q = ClarifyQuestion.fromJson(json);

      expect(q.isTextInput, isTrue);
      expect(q.isSelect, isFalse);
      expect(q.placeholder, 'Введите ИНН');
    });

    test('fromJson handles missing fields with defaults', () {
      final q = ClarifyQuestion.fromJson(<String, dynamic>{});

      expect(q.id, '');
      expect(q.question, '');
      expect(q.type, 'select');
      expect(q.options, isNull);
      expect(q.isSelect, isFalse); // no options → not select
    });
  });

  group('ArtifactType', () {
    test('fromString maps known types', () {
      expect(ArtifactType.fromString('DOCUMENT'), ArtifactType.document);
      expect(ArtifactType.fromString('CONTRACT'), ArtifactType.document);
      expect(ArtifactType.fromString('CLAIM'), ArtifactType.document);
      expect(ArtifactType.fromString('COMPLAINT'), ArtifactType.document);
      expect(ArtifactType.fromString('CODE'), ArtifactType.code);
      expect(ArtifactType.fromString('ANALYSIS'), ArtifactType.analysis);
      expect(ArtifactType.fromString('IMAGE'), ArtifactType.image);
    });

    test('fromString is case-insensitive', () {
      expect(ArtifactType.fromString('document'), ArtifactType.document);
      expect(ArtifactType.fromString('Code'), ArtifactType.code);
    });

    test('fromString defaults to document for unknown', () {
      expect(ArtifactType.fromString('UNKNOWN'), ArtifactType.document);
      expect(ArtifactType.fromString(''), ArtifactType.document);
    });

    test('label returns Russian strings', () {
      expect(ArtifactType.document.label, 'Документ');
      expect(ArtifactType.code.label, 'Код');
      expect(ArtifactType.analysis.label, 'Анализ');
      expect(ArtifactType.image.label, 'Изображение');
    });
  });
}
