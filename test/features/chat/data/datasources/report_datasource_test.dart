import 'package:flutter_test/flutter_test.dart';
import 'package:sanbao_flutter/features/chat/data/datasources/report_datasource.dart';

void main() {
  group('ReportReason', () {
    test('has correct API values', () {
      expect(ReportReason.offensive.apiValue, 'offensive');
      expect(ReportReason.inaccurate.apiValue, 'inaccurate');
      expect(ReportReason.spam.apiValue, 'spam');
      expect(ReportReason.other.apiValue, 'other');
    });

    test('has Russian display labels', () {
      expect(ReportReason.offensive.displayLabel, 'Оскорбительный контент');
      expect(ReportReason.inaccurate.displayLabel, 'Неточная информация');
      expect(ReportReason.spam.displayLabel, 'Спам');
      expect(ReportReason.other.displayLabel, 'Другое');
    });

    test('enum has exactly 4 values', () {
      expect(ReportReason.values, hasLength(4));
    });
  });
}
