import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/user_profile.dart';

/// Result of an AI call: either text or a user-friendly error.
class AiResult {
  final String? text;
  final String? error;

  const AiResult.ok(this.text) : error = null;
  const AiResult.fail(this.error) : text = null;

  bool get isOk => text != null;
}

/// Thin client for the Anthropic Messages API.
///
/// The API key is provided by the user and stored only on-device. All AI
/// output in this app is educational — guardrails live in the system
/// prompts below, and the UI repeats the disclaimer persistently.
class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String rabbiSystemPrompt(UserProfile p) => '''
You are the study assistant inside יהדות (Yeadut), a Hebrew-language Jewish
lifestyle app. You answer questions about Judaism, halacha, customs, and
Jewish texts.

User context: nusach ${p.nusach.name}; located in ${p.inIsrael ? 'Israel' : 'the Diaspora'}.

Rules you must always follow:
1. ALWAYS answer in Hebrew. Use clear, modern Hebrew with traditional
   terminology; quote sources in their original Hebrew.
2. You provide educational information, NEVER a psak halacha (practical
   ruling). End any practically-applicable answer with a short reminder to
   consult a competent Rav for a personal ruling.
3. PIKUACH NEFESH OVERRIDE: if a question involves possible danger to life
   (medical emergency on Shabbat, etc.), begin your answer immediately and
   unambiguously with: פיקוח נפש דוחה שבת וכמעט את כל המצוות — התקשרו
   מיד למד״א (101) או לשירותי החירום. Only afterwards add context.
4. Structure answers: short answer first, then reasoning, then sources.
   Cite sources by name and section (e.g., שולחן ערוך או״ח רעא:א,
   משנה ברורה שם) — never invent citations; if unsure, say so.
5. Where Ashkenazi and Sephardi practice differ, present both and note
   which matches the user's nusach. Do not silently pick one.
6. For questions involving kashrut accidents, marriage/divorce, conversion,
   medical decisions, or monetary disputes — give background only and say
   clearly these require a Rav (or doctor) directly.
7. Keep answers concise: under 250 words unless the user asks for depth.
''';

  static const String brachaSystemPrompt = '''
You identify food from a photo for a blessing (bracha) lookup in a Jewish
lifestyle app. Respond ONLY with compact JSON, no markdown fences:
{"foods":[{"name":"...","confidence":0.0-1.0}],"mixture":true|false}
Food names must be in English (they are matched against an English keyword
index). List up to 3 candidate identifications, most likely first.
"mixture" is true if the dish visibly combines several food categories
(e.g., a sandwich, cereal with milk, a salad with croutons). If you cannot
identify any food, return {"foods":[],"mixture":false}.
''';

  /// Sends a chat conversation. [history] alternates user/assistant turns,
  /// ending with the newest user message.
  Future<AiResult> chat({
    required UserProfile profile,
    required List<({String role, String text})> history,
  }) {
    return _post(profile, {
      'model': profile.aiModel,
      'max_tokens': kAiMaxTokens,
      'system': rabbiSystemPrompt(profile),
      'messages': [
        for (final turn in history)
          {'role': turn.role, 'content': turn.text},
      ],
    });
  }

  /// Identifies food in a JPEG photo for the bracha scanner.
  Future<AiResult> identifyFood({
    required UserProfile profile,
    required List<int> jpegBytes,
  }) {
    return _post(profile, {
      'model': profile.aiModel,
      'max_tokens': 512,
      'system': brachaSystemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Encode(jpegBytes),
              },
            },
            {'type': 'text', 'text': 'Identify the food in this photo.'},
          ],
        },
      ],
    });
  }

  Future<AiResult> _post(UserProfile profile, Map<String, Object?> body) async {
    if (profile.anthropicApiKey.isEmpty) {
      return const AiResult.fail(
          'לא הוגדר מפתח API. הוסיפו מפתח Anthropic בפרופיל ← בינה '
          'מלאכותית כדי להפעיל את הכלים החכמים.');
    }
    try {
      final response = await _client
          .post(
            Uri.parse(kAnthropicApiUrl),
            headers: {
              'content-type': 'application/json',
              'x-api-key': profile.anthropicApiKey,
              'anthropic-version': kAnthropicApiVersion,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        final message =
            (json['error'] as Map<String, dynamic>?)?['message'] as String? ??
                'HTTP ${response.statusCode}';
        return AiResult.fail('הבקשה נכשלה: $message');
      }

      final content = json['content'] as List<dynamic>? ?? [];
      final text = content
          .whereType<Map<String, dynamic>>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String? ?? '')
          .join();
      if (text.isEmpty) return const AiResult.fail('התקבלה תשובה ריקה.');
      return AiResult.ok(text);
    } on FormatException {
      return const AiResult.fail('תשובה לא צפויה משירות הבינה המלאכותית.');
    } catch (e) {
      return AiResult.fail('שגיאת רשת — בדקו את החיבור לאינטרנט. ($e)');
    }
  }
}
