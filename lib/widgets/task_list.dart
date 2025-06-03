import 'package:flutter/material.dart';
// import 'dart:convert';

class Task {
  String title;
  String description;
  int id;
  bool isCompleted;
  DateTime created;
  DateTime? dueDate;
  String? photoPath;
  static int _idCounter = 0;

  Task({
    required this.title,
    this.description = '',
    int? id,
    this.isCompleted = false,
    DateTime? created,
    this.dueDate,
    this.photoPath,
  }) : id = id ?? _idCounter++,
       created = created ?? DateTime.now();

  // Toggle the completed status
  void toggleCompleted() {
    isCompleted = !isCompleted;
  }

  // Convert Task to Map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'id': id,
      'isCompleted': isCompleted,
      'created': created.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'photoPath': photoPath,
    };
  }

  // Create Task from Map
  factory Task.fromJson(Map<String, dynamic> json) {
    final task = Task(
      title: json['title'],
      description: json['description'],
      id: json['id'],
      isCompleted: json['isCompleted'],
      created: DateTime.parse(json['created']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      photoPath: json['photoPath'],
    );

    // Ensure the next generated id is greater than any restored id.
    if (task.id >= _idCounter) {
      _idCounter = task.id + 1;
    }

    return task;
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


// use shared pref, option to edit from task page, update data on main page immediately
//