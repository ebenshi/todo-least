import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_intro/widgets/task_list.dart';

void main() {
  test('Task.fromJson updates id counter', () {
    final map = {
      'title': 'existing',
      'description': '',
      'id': 5,
      'isCompleted': false,
      'created': DateTime.now().toIso8601String(),
      'dueDate': null,
      'photoPath': null,
    };

    final restored = Task.fromJson(map);
    final newTask = Task(title: 'new');

    expect(newTask.id, restored.id + 1);
  });
}
