import 'package:flutter/material.dart';

class FlowersPage extends StatefulWidget {
  const FlowersPage({super.key});

  @override
  State<FlowersPage> createState() => _FlowersPageState();
}

class _FlowersPageState extends State<FlowersPage> {

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text("FlowersPage"),
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