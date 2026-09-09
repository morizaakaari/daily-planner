import 'package:flutter_test/flutter_test.dart';
import 'package:routine_master_app/main.dart';

void main() {
  test('Gemini discovery excludes non-text models', () {
    expect(GeminiService.isTextGenerationModel('models/gemini-2.5-flash-preview-tts'), isFalse);
    expect(GeminiService.isTextGenerationModel('models/gemini-2.5-flash'), isTrue);
  });

  test('TaskItem keeps the original time across persistence', () {
    final item = TaskItem(
      id: '1',
      title: 'Deep work',
      startTime: '08:00',
      durationMinutes: 90,
      category: 'deepwork',
    );

    item.startTime = '10:30';
    final restored = TaskItem.fromMap(item.toMap());

    expect(restored.startTime, '10:30');
    expect(restored.originalStartTime, '08:00');
  });
}
