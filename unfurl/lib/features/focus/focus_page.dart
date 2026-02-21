import 'package:flutter/material.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

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
            drawer: const AppDrawer(currentRoute: '/focus'),
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