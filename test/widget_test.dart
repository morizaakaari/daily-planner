import 'package:flutter_test/flutter_test.dart';
import 'package:routine_master_app/main.dart';

void main() {
  test('default task serializes without losing its schedule', () {
    final task = TaskItem(
      id: 'wake-up',
      title: 'Wake up',
      startTime: '04:00',
      durationMinutes: 30,
      category: 'routine',
    );

    final restored = TaskItem.fromMap(task.toMap());

    expect(restored.title, 'Wake up');
    expect(restored.startTime, '04:00');
    expect(restored.originalStartTime, '04:00');
  });
}
