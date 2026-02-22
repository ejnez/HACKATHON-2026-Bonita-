import 'package:flutter/material.dart';
import '../task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  Color _priorityColor(int p) {
    if (p <= 1) return const Color(0xFF5F8F7B);
    if (p <= 3) return const Color(0xFFB79A67);
    if (p <= 6) return const Color(0xFF73BE93);
    return const Color(0xFF7891A8);
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
            colors: [Colors.white, Color(0xFFF2F8F4)],
          ),
          border: Border.all(color: const Color(0xFFD8E6DE)),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          isThreeLine: true,
          leading: CircleAvatar(
            backgroundColor: priorityColor.withValues(alpha: 0.2),
            child: Icon(Icons.local_florist, color: priorityColor),
          ),
          title: Text(
            task.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                _chip(task.category, const Color(0xFF657B72)),
                if (task.estimatedMinutes != null)
                  _chip('${task.estimatedMinutes} min', const Color(0xFF6FAF98)),
              ],
            ),
          ),
          trailing: task.isDone
              ? const Icon(Icons.check_circle, color: Color(0xFF6FAF98))
              : const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF5F8F7B)),
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

