import 'package:flutter/material.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

class FlowersPage extends StatefulWidget {
  const FlowersPage({super.key});

  @override
  State<FlowersPage> createState() => _FlowersPageState();
}

class _FlowersPageState extends State<FlowersPage> {
  final List<Map<String, String>> sampleBlooms = const [
    {'name': 'Remarkable Rose', 'tier': 'EXCELLENT', 'emoji': 'R'},
    {'name': 'Mindful Mimosa', 'tier': 'MEDIUM', 'emoji': 'M'},
    {'name': 'Grindset Gladiolus', 'tier': 'SMALL', 'emoji': 'G'},
    {'name': 'Dauntless Daisy', 'tier': 'MICRO', 'emoji': 'D'},
  ];

  @override
  Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text("My Bouquet"),
            ),
            drawer: const AppDrawer(currentRoute: '/flowers'),
            body: Container(
                decoration: const BoxDecoration(gradient: blossomBackground),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFFFD1E5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s Garden', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          const Text('Every completed task blooms into something beautiful.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...sampleBlooms.map((bloom) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFDCEC)),
                          ),
                          child: Row(
                            children: [
                              Text(bloom['emoji']!, style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bloom['name']!,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      bloom['tier']!,
                                      style: const TextStyle(
                                        color: Color(0xFF9E5A79),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.auto_awesome, color: blossomPink),
                            ],
                          ),
                        )),
                  ],
                ),
            ),
        );
  }
}

