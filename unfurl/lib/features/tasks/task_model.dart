// entity class that stores the data for a single task
class Task {
    String? id;        // Firestore document ID (nullable at first)
    String name;
    int priority;       // Higher number = higher priority
    bool isDone;

    Task({
        this.id,
        required this.name,
        this.priority = 1,
        this.isDone = false,
      });

}