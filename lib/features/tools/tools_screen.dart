import 'package:flutter/material.dart';

import '../alarm/alarm_screen.dart';
import '../bracha/bracha_screen.dart';
import '../compass/compass_screen.dart';
import '../hechsher/hechsher_screen.dart';
import 'kosher_situations_screen.dart';

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;

  const _Tool(this.title, this.subtitle, this.icon, this.builder);
}

/// Tools tab: grid of situational utilities.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static final List<_Tool> _tools = [
    _Tool('מצפן תפילה', 'לכיוון ירושלים', Icons.explore,
        () => const CompassScreen()),
    _Tool('סורק ברכות', 'צילום או חיפוש', Icons.restaurant,
        () => const BrachaScreen()),
    _Tool('בדיקת כשרות', 'סריקת ברקוד', Icons.qr_code_scanner,
        () => const HechsherScreen()),
    _Tool('שעון מעורר לשבת', 'נכבה מעצמו', Icons.alarm,
        () => const AlarmScreen()),
    _Tool('בשר וחלב', 'זמני המתנה', Icons.help_center,
        () => const KosherSituationsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('כלים')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: _tools.length,
        itemBuilder: (context, i) {
          final tool = _tools[i];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => tool.builder()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(tool.icon, size: 32, color: scheme.primary),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tool.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(tool.subtitle,
                            style: TextStyle(
                                fontSize: 12, color: scheme.outline)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
