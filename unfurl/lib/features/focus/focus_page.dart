import 'package:flutter/material.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text("FocusPage"),
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