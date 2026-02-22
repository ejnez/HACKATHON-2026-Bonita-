import 'package:flutter/material.dart';
import '../task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({
    super.key,
    required this.task,
  });

  Color _priorityColor(int p) {
    if (p <= 1) return const Color(0xFFFF7BAE);
    if (p <= 3) return const Color(0xFFFFB866);
    if (p <= 6) return const Color(0xFF73BE93);
    return const Color(0xFF8A92D4);
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFFF4FA)],
          ),
          border: Border.all(color: const Color(0xFFFFD4E6)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          leading: CircleAvatar(
            backgroundColor: priorityColor.withValues(alpha: 0.2),
            child: Icon(Icons.local_florist, color: priorityColor),
          ),
          title: Text(
            task.name,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              decoration: task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('P${task.priority}', priorityColor),
                _chip(task.category, const Color(0xFF8F6A80)),
                if (task.estimatedMinutes != null)
                  _chip('${task.estimatedMinutes} min', const Color(0xFF6FAF98)),
              ],
            ),
          ),
          trailing: task.isDone
              ? const Icon(Icons.check_circle, color: Color(0xFF6FAF98))
              : null,
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

