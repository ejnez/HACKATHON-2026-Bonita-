import 'package:flutter/material.dart';
//import '../task_provider.dart';
import 'package:unfurl/features/tasks/task_model.dart';
import 'package:unfurl/features/tasks/widgets/task_card.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';
import 'package:unfurl/shared/widgets/focus_button.dart';
import 'package:unfurl/shared/widgets/color_cycle_button.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {

    // Example list (replace with your provider/Firestore later)
      final List<Task> _tasks = [
        Task(name: "Buy groceries"),
        Task(name: "Finish Flutter app", priority: 2),
        Task(name: "Meditate", priority: 1),
      ];

  //build page UI code
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(title: const Text("Your Tasks")),
        drawer: const AppDrawer(currentRoute: '/'),
        body: Column(
            children: [

                Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: FocusButton(
                                text: "FOCUS",
                                onPressed: () {
                                    Navigator.pushNamed(context, '/focus');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ColorCycleButton(
                                text: "Unload My Brain",
                                onPressed: () {
                                    Navigator.pushNamed(context, '/chatbot');
                                },
                              ),
                            ),
                          ],
                        ),
                ),

                Expanded (
                    child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return TaskCard(
                              task: task,
                              /*
                              onToggleDone: () {
                                setState(() {
                                  task.toggleDone();
                                });
                              },
                              **/
                            );
                          },
                        ),
                ),

            ]
        ),






      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }//end of build page UI code

  //popup UI code
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(
                decoration: InputDecoration(labelText: "Title"),
              ),
              TextField(
                decoration: InputDecoration(labelText: "Priority"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }//end of popup UI code
}