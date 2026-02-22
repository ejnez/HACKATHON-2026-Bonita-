import 'dart:convert';

import 'package:http/http.dart' as http;
import 'task_model.dart';

class TaskProvider {
  // Replace with Person 1 machine IP when testing on physical phone.
  static const String apiBase = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> sendBrainDump({
    required String sessionId,
    required String userId,
    required String message,
  }) async {
    final uri = Uri.parse('$apiBase/chat');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'session_id': sessionId,
        'user_id': userId,
        'message': message,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Chat failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Task>> fetchTasks(String userId) async {
    final uri = Uri.parse('$apiBase/tasks/$userId');
    final res = await http.get(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Fetch tasks failed: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final tasksJson = (data['tasks'] as List<dynamic>? ?? const []);
    return tasksJson
        .whereType<Map<String, dynamic>>()
        .map(Task.fromJson)
        .toList();
  }
}
