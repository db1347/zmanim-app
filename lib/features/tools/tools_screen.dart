import 'package:flutter/material.dart';

import '../alarm/alarm_screen.dart';
import '../bracha/bracha_screen.dart';
import '../compass/compass_screen.dart';
import '../events/events_screen.dart';
import '../hechsher/hechsher_screen.dart';
import '../learning/learning_screen.dart';
import '../omer/omer_screen.dart';
import 'kosher_situations_screen.dart';

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function() builder;

  const _Tool(this.title, this.subtitle, this.icon, this.color, this.builder);
}

/// Tools tab: grid of situational utilities.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static final List<_Tool> _tools = [
    _Tool('מצפן תפילה', 'לכיוון ירושלים', Icons.explore,
        const Color(0xFF185FA5), () => const CompassScreen()),
    _Tool('ספירת העומר', 'הספירה של הערב', Icons.filter_9_plus,
        const Color(0xFF7B5BA6), () => const OmerScreen()),
    _Tool('סורק ברכות', 'צילום או חיפוש', Icons.restaurant,
        const Color(0xFFBA7517), () => const BrachaScreen()),
    _Tool('בדיקת כשרות', 'סריקת ברקוד', Icons.qr_code_scanner,
        const Color(0xFF2E7D52), () => const HechsherScreen()),
    _Tool('שעון מעורר לשבת', 'נכבה מעצמו', Icons.alarm,
        const Color(0xFFA64545), () => const AlarmScreen()),
    _Tool('תאריכים עבריים', 'יארצייט וימי הולדת', Icons.event_note,
        const Color(0xFF54708C), () => const EventsScreen()),
    _Tool('הדף היומי', 'מעקב ורצף', Icons.menu_book,
        const Color(0xFF8C6D46), () => const LearningScreen()),
    _Tool('בשר וחלב', 'זמני המתנה', Icons.help_center,
        const Color(0xFF456FA6), () => const KosherSituationsScreen()),
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
          childAspectRatio: 1.2,
        ),
        itemCount: _tools.length,
        itemBuilder: (context, i) {
          final tool = _tools[i];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => tool.builder()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: tool.color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tool.icon, size: 26, color: tool.color),
                    ),
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
