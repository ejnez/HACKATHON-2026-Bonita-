import 'package:flutter/material.dart';

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