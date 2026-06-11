import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/bracha_entry.dart';
import '../../services/ai_service.dart';
import '../../services/bracha_database.dart';
import '../../services/settings_service.dart';
import 'bracha_result_card.dart';

/// Bracha scanner: photo → AI food ID → curated bracha mapping,
/// with an always-available offline text search.
class BrachaScreen extends StatefulWidget {
  const BrachaScreen({super.key});

  @override
  State<BrachaScreen> createState() => _BrachaScreenState();
}

class _BrachaScreenState extends State<BrachaScreen> {
  final _ai = AiService();
  final _searchController = TextEditingController();
  final _picker = ImagePicker();

  bool _scanning = false;
  String? _error;
  List<BrachaEntry> _results = const [];
  List<String> _unmatchedAiNames = const [];
  bool _mixtureWarning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    setState(() {
      _error = null;
      _mixtureWarning = false;
      _unmatchedAiNames = const [];
      _results = BrachaDatabase.search(query).take(8).toList();
    });
  }

  Future<void> _scan(ImageSource source) async {
    final profile = context.read<SettingsService>().profile;
    if (profile.anthropicApiKey.isEmpty) {
      setState(() => _error =
          'סריקת תמונה דורשת מפתח API של Anthropic (פרופיל ← בינה '
          'מלאכותית). החיפוש בכתב עובד גם בלי אינטרנט.');
      return;
    }

    final XFile? shot;
    try {
      shot = await _picker.pickImage(
          source: source, maxWidth: 1024, imageQuality: 80);
    } catch (e) {
      if (mounted) setState(() => _error = 'פתיחת המצלמה נכשלה: $e');
      return;
    }
    if (!mounted || shot == null) return;

    setState(() {
      _scanning = true;
      _error = null;
      _results = const [];
      _unmatchedAiNames = const [];
      _mixtureWarning = false;
    });

    final bytes = await shot.readAsBytes();
    final result = await _ai.identifyFood(profile: profile, jpegBytes: bytes);

    if (!mounted) return;
    if (!result.isOk) {
      setState(() {
        _scanning = false;
        _error = result.error;
      });
      return;
    }

    setState(() {
      _scanning = false;
      _applyAiAnswer(result.text!);
    });
  }

  void _applyAiAnswer(String raw) {
    try {
      final cleaned = raw
          .replaceAll(RegExp(r'^```(json)?', multiLine: true), '')
          .replaceAll('```', '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final foods = (json['foods'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      _mixtureWarning = json['mixture'] == true;

      final matched = <BrachaEntry>[];
      final unmatched = <String>[];
      for (final food in foods.take(3)) {
        final name = food['name'] as String? ?? '';
        if (name.isEmpty) continue;
        final entry = BrachaDatabase.bestMatch(name);
        if (entry != null && !matched.contains(entry)) {
          matched.add(entry);
        } else if (entry == null) {
          unmatched.add(name);
        }
      }
      _results = matched;
      _unmatchedAiNames = unmatched;
      if (matched.isEmpty && unmatched.isEmpty) {
        _error = 'לא זוהה מאכל בתמונה — נסו את החיפוש בכתב.';
      }
    } catch (_) {
      _error = 'קריאת תשובת הבינה המלאכותית נכשלה — נסו את החיפוש בכתב.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('סורק ברכות')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      _scanning ? null : () => _scan(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('צילום'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _scanning ? null : () => _scan(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('גלריה'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _runSearch,
            decoration: InputDecoration(
              hintText: 'או חפשו מאכל (עובד גם בלי אינטרנט)…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_error!,
                    style: TextStyle(color: scheme.onErrorContainer)),
              ),
            ),
          if (_mixtureWarning)
            Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'נראה שזו מנה מעורבת (עיקר וטפל). בדרך כלל המרכיב '
                  'העיקרי קובע את הברכה — במקרה של ספק אמיתי שאלו '
                  'בלשונית «שאל» או פנו לרב.',
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSecondaryContainer),
                ),
              ),
            ),
          for (final entry in _results) BrachaResultCard(entry: entry),
          for (final name in _unmatchedAiNames)
            Card(
              child: ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(name),
                subtitle: const Text(
                    'זוהה, אך עדיין לא נמצא במאגר — נסו שם פשוט יותר '
                    'בחיפוש.'),
              ),
            ),
          if (_results.isEmpty &&
              !_scanning &&
              _error == null &&
              _searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  Icon(Icons.restaurant, size: 56, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'צלמו את המאכל או חפשו לפי שם\nכדי לראות את הברכה '
                    'הראשונה והאחרונה.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
