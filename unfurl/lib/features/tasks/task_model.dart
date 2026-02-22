// entity class that stores the data for a single task
class Task {
    String? id;
    String name;
    int priority;
    bool isDone;
    String category;
    int? estimatedMinutes;

    Task({
        this.id,
        required this.name,
        this.priority = 1,
        this.isDone = false,
        this.category = 'General',
        this.estimatedMinutes,
      });

    factory Task.fromJson(Map<String, dynamic> json) {
      return Task(
        id: (json['task_id'] ?? json['id'])?.toString(),
        name: (json['task_name'] ?? json['name'] ?? 'Untitled task').toString(),
        priority: json['priority_rank'] is int
            ? json['priority_rank'] as int
            : int.tryParse('${json['priority_rank'] ?? 1}') ?? 1,
        isDone: json['completed'] == true || json['isDone'] == true,
        category: (json['category'] ?? 'General').toString(),
        estimatedMinutes: json['estimated_time'] is int
            ? json['estimated_time'] as int
            : int.tryParse('${json['estimated_time'] ?? ''}'),
      );
    }
}
