import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/task_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // root of the app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const MyHomePage(title: 'To Do Least'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class NewTaskIntent extends Intent {
  const NewTaskIntent();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Task> _taskList = [];
  int _pendingTaskCount = 0;
  int? _expandedTaskId;

  void _submitNewTask(String title, {String? description = ''}) {
    if (title.trim().isEmpty) return;

    setState(() {
      _taskList.add(Task(title: title.trim(), description: description ?? ''));
      _updatePendingTaskCount();
    });

    Navigator.of(context).pop();
  }

  void _updatePendingTaskCount() {
    _pendingTaskCount = _taskList.where((task) => !task.isCompleted).length;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final task = _taskList.removeAt(oldIndex);
      _taskList.insert(newIndex, task);
    });
  }

  Future<void> _showAddTaskDialog() async {
    return showDialog(
      context: context,
      builder:
          (BuildContext context) => AddTaskDialog(
            onSubmit:
                (title, description) =>
                    _submitNewTask(title, description: description),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Cmd+N on macOS or Ctrl+N elsewhere
        LogicalKeySet(
              LogicalKeyboardKey.meta, // for macOS Command
              LogicalKeyboardKey.keyN,
            ):
            const NewTaskIntent(),

        LogicalKeySet(
              LogicalKeyboardKey.control, // for Windows/Linux Ctrl
              LogicalKeyboardKey.keyN,
            ):
            const NewTaskIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewTaskIntent: CallbackAction<NewTaskIntent>(
            onInvoke: (intent) {
              _showAddTaskDialog();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
            ),
            body: TaskListBody(
              taskList: _taskList,
              pendingTaskCount: _pendingTaskCount,
              expandedTaskId: _expandedTaskId,
              onReorder: _onReorder,
              onTaskToggle: (task) {
                setState(() {
                  task.toggleCompleted();
                  _updatePendingTaskCount();
                });
              },
              onTaskDelete: (index) {
                setState(() {
                  _taskList.removeAt(index);
                  _updatePendingTaskCount();
                });
              },
              onTaskPrioritize: (task, index) {
                setState(() {
                  _taskList.removeAt(index);
                  _taskList.insert(0, task);
                });
              },
              onTaskExpand: (taskId) {
                setState(() {
                  _expandedTaskId = (_expandedTaskId == taskId) ? null : taskId;
                });
              },
              onTaskEdit: (task, newTitle, newDescription) {
                setState(() {
                  if (newTitle != null) task.title = newTitle;
                  if (newDescription != null) task.description = newDescription;
                });
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _showAddTaskDialog,
              tooltip: 'Add Task',
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }
}

class TaskListBody extends StatelessWidget {
  final List<Task> taskList;
  final int pendingTaskCount;
  final int? expandedTaskId;
  final Function(int, int) onReorder;
  final Function(Task) onTaskToggle;
  final Function(int) onTaskDelete;
  final Function(Task, int) onTaskPrioritize;
  final Function(int?) onTaskExpand;
  final Function(Task, String?, String?) onTaskEdit;

  const TaskListBody({
    super.key,
    required this.taskList,
    required this.pendingTaskCount,
    required this.expandedTaskId,
    required this.onReorder,
    required this.onTaskToggle,
    required this.onTaskDelete,
    required this.onTaskPrioritize,
    required this.onTaskExpand,
    required this.onTaskEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TaskCountHeader(
            pendingCount: pendingTaskCount,
            totalCount: taskList.length,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: taskList.length,
              onReorder: onReorder,
              buildDefaultDragHandles: false,
              itemBuilder:
                  (context, index) => TaskListItem(
                    key: ValueKey(taskList[index].id),
                    task: taskList[index],
                    index: index,
                    isExpanded: expandedTaskId == taskList[index].id,
                    onToggle: onTaskToggle,
                    onDelete: onTaskDelete,
                    onPrioritize: onTaskPrioritize,
                    onExpand: onTaskExpand,
                    onEdit: onTaskEdit,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCountHeader extends StatelessWidget {
  final int pendingCount;
  final int totalCount;

  const TaskCountHeader({
    super.key,
    required this.pendingCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Pending: $pendingCount\nCompleted: ${totalCount - pendingCount}',
      style: GoogleFonts.lato(
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class TaskListItem extends StatelessWidget {
  final Task task;
  final int index;
  final bool isExpanded;
  final Function(Task) onToggle;
  final Function(int) onDelete;
  final Function(Task, int) onPrioritize;
  final Function(int?) onExpand;
  final Function(Task, String?, String?) onEdit;

  const TaskListItem({
    super.key,
    required this.task,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onPrioritize,
    required this.onExpand,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (index == 0) const Divider(height: 1),
        Slidable(
          key: ValueKey(task.id),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.7,
            children: [
              SlidableAction(
                onPressed: (_) => onToggle(task),
                backgroundColor: task.isCompleted ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                icon: task.isCompleted ? Icons.remove_circle : Icons.check,
                label: task.isCompleted ? 'Undo' : 'Complete',
              ),
              SlidableAction(
                onPressed: (_) => onPrioritize(task, index),
                backgroundColor: const Color.fromARGB(255, 13, 105, 210),
                foregroundColor: Colors.white,
                icon: Icons.arrow_upward,
                label: 'Prioritize',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.35,
            children: [
              SlidableAction(
                onPressed: (_) => _showDeleteConfirmation(context),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: TaskTile(
            task: task,
            index: index,
            isExpanded: isExpanded,
            onToggle: onToggle,
            onExpand: onExpand,
            onEdit: onEdit,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onDelete(index);
                  Navigator.of(context).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final Task task;
  final int index;
  final bool isExpanded;
  final Function(Task) onToggle;
  final Function(int?) onExpand;
  final Function(Task, String?, String?) onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
    required this.onExpand,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator_sharp),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    TaskTitleButton(task: task),
                    const SizedBox(width: 8),
                    if (task.description.isNotEmpty)
                      ExpandButton(
                        task: task,
                        isExpanded: isExpanded,
                        onExpand: onExpand,
                      ),
                  ],
                ),
              ),
              TaskCheckbox(task: task, onToggle: onToggle),
              TaskMenuButton(task: task, onEdit: onEdit),
            ],
          ),
          if (isExpanded && task.description.isNotEmpty)
            TaskDescription(description: task.description),
        ],
      ),
    );
  }
}

class TaskTitleButton extends StatelessWidget {
  final Task task;

  const TaskTitleButton({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskPage(task: task)),
        );
      },
      child: Text(
        task.title,
        style: GoogleFonts.lato(
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color:
                task.isCompleted
                    ? const Color.fromARGB(255, 60, 59, 59)
                    : Colors.black,
            decoration:
                task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class ExpandButton extends StatelessWidget {
  final Task task;
  final bool isExpanded;
  final Function(int?) onExpand;

  const ExpandButton({
    super.key,
    required this.task,
    required this.isExpanded,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      onPressed: () => onExpand(isExpanded ? null : task.id),
    );
  }
}

class TaskCheckbox extends StatelessWidget {
  final Task task;
  final Function(Task) onToggle;

  const TaskCheckbox({super.key, required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        task.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        Slidable.of(context)?.close();
        onToggle(task);
      },
    );
  }
}

class TaskMenuButton extends StatelessWidget {
  final Task task;
  final Function(Task, String?, String?) onEdit;

  const TaskMenuButton({super.key, required this.task, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      padding: EdgeInsets.zero,
      itemBuilder:
          (context) => [
            const PopupMenuItem(value: 'edit_name', child: Text('Edit name')),
            const PopupMenuItem(
              value: 'edit_description',
              child: Text('Edit description'),
            ),
          ],
      onSelected: (value) => _handleEdit(context, value),
    );
  }

  Future<void> _handleEdit(BuildContext context, String value) async {
    if (value == 'edit_name') {
      final result = await _showEditDialog(
        context,
        'Edit Task Name',
        task.title,
        'Task name',
      );
      if (result != null && result.trim().isNotEmpty) {
        onEdit(task, result.trim(), null);
      }
    } else if (value == 'edit_description') {
      final result = await _showEditDialog(
        context,
        'Edit Description',
        task.description,
        'Description',
      );
      onEdit(task, null, result);
    }
  }

  Future<String?> _showEditDialog(
    BuildContext context,
    String title,
    String initialValue,
    String hintText,
  ) {
    String newValue = initialValue;
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: TextField(
              autofocus: true,
              controller: TextEditingController(text: initialValue),
              onChanged: (val) => newValue = val,
              decoration: InputDecoration(hintText: hintText),
              onSubmitted: (val) => Navigator.of(context).pop(val),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(newValue),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}

class TaskDescription extends StatelessWidget {
  final String description;

  const TaskDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 32.0),
        child: Text(
          description,
          style: GoogleFonts.lato(
            textStyle: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final Function(String, String?) onSubmit;

  const AddTaskDialog({super.key, required this.onSubmit});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  String newTaskTitle = '';
  String newTaskDescription = '';
  String? newTaskDueDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (value) => newTaskTitle = value,
            decoration: const InputDecoration(hintText: 'Enter task title'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => newTaskDescription = value,
            decoration: const InputDecoration(hintText: 'Enter description'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
                if (pickedDate != null) {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                  },
                  initialEntryMode: TimePickerEntryMode.input,
                );
                if (pickedTime != null) {
                  final DateTime combinedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  setState(() {
                    newTaskDueDate = combinedDateTime.toIso8601String();
                  });
                }
              }
            },
            child: const Text('Choose due date and time'),
          ),
          if (newTaskDueDate != null)
            Text(
                'Due ${DateFormat('MMMM d', 'en_US').format(DateTime.parse(newTaskDueDate!))}'
                '${_getDaySuffix(DateTime.parse(newTaskDueDate!).day)}, '
                '${DateFormat('yyyy', 'en_US').format(DateTime.parse(newTaskDueDate!))} '
                'at ${DateFormat('HH:mm', 'en_US').format(DateTime.parse(newTaskDueDate!))}',
              style: const TextStyle(fontSize: 16),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (newTaskTitle.trim().isNotEmpty) {
              widget.onSubmit(newTaskTitle, newTaskDescription);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class TaskPage extends StatelessWidget {
  final Task task;

  const TaskPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          task.title,
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(task.description, style: TextStyle(fontSize: 32)),
            const SizedBox(height: 16),
            Text('Created ${timeago.format(task.created)}'),
            if (task.dueDate != null)
              Text(
                'Due in ${timeago.format(task.dueDate!, allowFromNow: true)}',
              ),
          ],
        ),
      ),
    );
  }
}


String _getDaySuffix(int day) {
  if (day >= 11 && day <= 13) {
    return 'th';
  }
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}