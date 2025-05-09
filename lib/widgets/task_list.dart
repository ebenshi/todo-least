import 'package:flutter/material.dart';


class Task {
  String title;
  String description = '';
  int id;
  bool isCompleted;
  static int _idCounter = 0; // Add this line

  Task({
    required this.title,
    required this.description,
    this.isCompleted = false,
  }) : id = _idCounter++; // Auto-increment id
  void toggleCompleted() {
    isCompleted = !isCompleted;
  }
}

class TaskList extends StatefulWidget {
  final List<Task> tasks;
  final Function(int oldIndex, int newIndex) onReorder;

  const TaskList({required this.tasks, required this.onReorder}) : super(key: const Key('task_list'));

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
            key: ValueKey(widget.tasks[index].id), // Ensure unique key
            title: Text(widget.tasks[index].title),
          ),
      ],
    );
  }
}