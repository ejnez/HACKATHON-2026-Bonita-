import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'task_model.dart';

class TaskProvider {
  static const String _apiBaseFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get _apiBase {
    if (_apiBaseFromEnv.isNotEmpty) {
      return _apiBaseFromEnv;
    }

    // Android emulator uses 10.0.2.2 to access host machine localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  Future<Map<String, dynamic>> sendBrainDump({
    required String sessionId,
    required String userId,
    required String message,
  }) async {
    final uri = Uri.parse('$_apiBase/chat');
    late final http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'session_id': sessionId,
              'user_id': userId,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception(
        'Chat request timed out. Check that backend is running and API host is correct.',
      );
    } catch (e) {
      throw Exception(
        'Cannot reach backend at $_apiBase. If using a physical device, run with --dart-define=API_BASE_URL=http://<your-pc-ip>:8000. Error: $e',
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Chat failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Task>> fetchTasks(String userId) async {
    final uri = Uri.parse('$_apiBase/tasks/$userId');
    late final http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception(
        'Fetch tasks timed out. Check that backend is running and API host is correct.',
      );
    } catch (e) {
      throw Exception(
        'Cannot reach backend at $_apiBase. If using a physical device, run with --dart-define=API_BASE_URL=http://<your-pc-ip>:8000. Error: $e',
      );
    }

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
