import 'package:flutter/material.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  bool _running = false;
  double _progress = 0.35;

  @override
  Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text("Focus Bloom"),
            ),
            drawer: const AppDrawer(currentRoute: '/focus'),
            body: Container(
                decoration: const BoxDecoration(gradient: blossomBackground),
                child: Center(
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFFFCCE2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Deep Focus Session', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 18),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 170,
                              height: 170,
                              child: CircularProgressIndicator(
                                value: _progress,
                                strokeWidth: 12,
                                backgroundColor: const Color(0xFFFFE8F2),
                                color: const Color(0xFFFF6FAE),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('18:42', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                                SizedBox(height: 4),
                                Text('Bloom in progress'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: _progress,
                          onChanged: (v) => setState(() => _progress = v),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _running = !_running),
                            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                            label: Text(_running ? 'Pause Session' : 'Start Session'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
        );
  }
}

