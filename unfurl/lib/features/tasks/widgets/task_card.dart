import 'package:flutter/material.dart';
import '../task_model.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  Color _priorityColor(int p) {
    if (p <= 1) return const Color(0xFF5F8F7B);
    if (p <= 3) return const Color(0xFFB79A67);
    if (p <= 6) return const Color(0xFF73BE93);
    return const Color(0xFF7891A8);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final priorityColor = _priorityColor(task.priority);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF2F8F4)],
                ),
                border: Border.all(color: const Color(0xFFD8E6DE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _hovered ? 0.14 : 0.08),
                    blurRadius: _hovered ? 16 : 12,
                    offset: Offset(0, _hovered ? 7 : 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 96,
                    margin: const EdgeInsets.only(left: 10, right: 10),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: priorityColor.withValues(alpha: 0.2),
                                child: Icon(Icons.local_florist, color: priorityColor, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  task.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                task.isDone ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                                color: task.isDone ? const Color(0xFF6FAF98) : const Color(0xFF5F8F7B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _chip('P${task.priority}', priorityColor),
                              _chip(task.category, const Color(0xFF657B72)),
                              if (task.estimatedMinutes != null)
                                _chip('${task.estimatedMinutes} min', const Color(0xFF6FAF98)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
