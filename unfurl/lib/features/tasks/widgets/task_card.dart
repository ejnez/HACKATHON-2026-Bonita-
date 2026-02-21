import 'package:flutter/material.dart';
import '../task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  //final VoidCallback? onToggleDone;

  const TaskCard({
    super.key,
    required this.task,
    //this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: task.priority == 1
              ? Colors.green[200]
              : task.priority == 2
                  ? Colors.amber[200]
                  : Colors.red[200],
          radius: 10,
        ),
        title: Text(
          task.name,
          style: TextStyle(
            fontSize: 18,
            //decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        //subtitle: task.description.isNotEmpty ? Text(task.description) : null,
        //trailing: Checkbox(
          //value: true,
          //onChanged: (_) => onToggleDone?.call(),
        //),
      ),
    );
  }
}