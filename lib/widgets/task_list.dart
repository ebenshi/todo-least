import 'package:flutter/material.dart';

class Task {
  String title;
  String description;
  int id;
  bool isCompleted;
  DateTime created;
  DateTime? dueDate;
  static int _idCounter = 0;

  Task({
    required this.title,
    this.description = '',
    int? id,
    this.isCompleted = false,
    DateTime? created,
    this.dueDate,
  }) : id = id ?? _idCounter++,
      created = created ?? DateTime.now();

  void toggleCompleted() {
    isCompleted = !isCompleted;
  }
}

class TaskList extends StatefulWidget {
  final List<Task> tasks;
  final Function(int oldIndex, int newIndex) onReorder;

  const TaskList({required this.tasks, required this.onReorder})
    : super(key: const Key('task_list'));

  @override
  TaskListState createState() => TaskListState();
}

class TaskListState extends State<TaskList> {
  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: widget.onReorder,
      children: [
        for (int index = 0; index < widget.tasks.length; index++)
          ListTile(
            key: ValueKey(widget.tasks[index].id),
            title: Text(widget.tasks[index].title),
          ),
      ],
    );
  }
}
