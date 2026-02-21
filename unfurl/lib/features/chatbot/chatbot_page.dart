import 'package:flutter/material.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text("ChatbotPage"),
            ),
            drawer: const AppDrawer(currentRoute: '/chatbot'),
            body: Center(
                child: Column(
                    mainAxisAlignment: .center,
                    children: [
                      Text('helllloooo???'),
                    ],
                ),
            ),
        );
    }
}