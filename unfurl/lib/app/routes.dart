import 'package:flutter/material.dart';
import '../features/tasks/task_list_page.dart';
import '../features/focus/focus_page.dart';
import '../features/flowers/flowers_page.dart';
import '../features/login/login_page.dart';
import '../features/chatbot/chatbot_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => TaskListPage(),
  '/focus': (context) => FocusPage(),
  '/flowers': (context) => FlowersPage(),
  '/login': (context) => LoginPage(),
  '/chatbot': (context) => ChatbotPage(),
};