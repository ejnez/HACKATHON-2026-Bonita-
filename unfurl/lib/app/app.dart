import 'package:flutter/material.dart';
import 'package:unfurl/shared/theme.dart';
import 'routes.dart';
//import 'shared/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unfurl',
      theme: appTheme,
      initialRoute: '/',     // default route
      routes: appRoutes,     // from app/routes.dart
      debugShowCheckedModeBanner: false,
    );
  }
}