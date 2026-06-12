import 'package:kosher_dart/kosher_dart.dart';

import '../models/user_profile.dart';
import 'zmanim_service.dart';

/// Tonight's/today's omer count, with awareness that the Jewish day flips
/// at nightfall: after tzeit the count shown is the one said that evening.
class OmerCount {
  final int day; // 1..49
  final bool isEveningCount; // true if shown after tzeit (tonight's count)
  const OmerCount({required this.day, required this.isEveningCount});
}

/// Pure Sefirat HaOmer logic: count math and fully-vocalized Hebrew text,
/// generated formulaically for all 49 days (matching standard siddurim).
class OmerService {
  const OmerService._();

  static const String bracha =
      'בָּרוּךְ אַתָּה ה׳ אֱלֹקֵינוּ מֶלֶךְ הָעוֹלָם, אֲשֶׁר קִדְּשָׁנוּ '
      'בְּמִצְוֹתָיו וְצִוָּנוּ עַל סְפִירַת הָעוֹמֶר.';

  static const String harachaman =
      'הָרַחֲמָן הוּא יַחֲזִיר לָנוּ עֲבוֹדַת בֵּית הַמִּקְדָּשׁ לִמְקוֹמָהּ, '
      'בִּמְהֵרָה בְיָמֵינוּ. אָמֵן סֶלָה.';

  /// The omer day relevant *right now*: before tzeit it's the day that was
  /// counted last night; after tzeit it's the new evening's count.
  /// Returns null outside the omer period.
  static OmerCount? currentCount(UserProfile p, DateTime now) {
    final todayJc = JewishCalendar.fromDateTime(now)..inIsrael = p.inIsrael;
    final tzeit = ZmanimService.tzeit(
        ZmanimService.calendarFor(p, now), p.tzeitShita);
    final isEvening = tzeit != null && now.isAfter(tzeit);

    if (isEvening) {
      final tomorrow = JewishCalendar.fromDateTime(
          DateTime(now.year, now.month, now.day + 1))
        ..inIsrael = p.inIsrael;
      final day = tomorrow.getDayOfOmer();
      if (day >= 1 && day <= 49) {
        return OmerCount(day: day, isEveningCount: true);
      }
      return null;
    }
    final day = todayJc.getDayOfOmer();
    if (day >= 1 && day <= 49) {
      return OmerCount(day: day, isEveningCount: false);
    }
    return null;
  }

  // ── Hebrew number words (masculine, as used for counting days) ──────

  static const List<String> _units = [
    '', 'אֶחָד', 'שְׁנַיִם', 'שְׁלוֹשָׁה', 'אַרְבָּעָה', 'חֲמִשָּׁה',
    'שִׁשָּׁה', 'שִׁבְעָה', 'שְׁמוֹנָה', 'תִּשְׁעָה',
  ];

  static const Map<int, String> _tens = {
    20: 'וְעֶשְׂרִים',
    30: 'וּשְׁלוֹשִׁים',
    40: 'וְאַרְבָּעִים',
  };

  /// "Days" phrase: יוֹם אֶחָד / שְׁנֵי יָמִים / שְׁלוֹשָׁה יָמִים …
  /// אַחַד עָשָׂר יוֹם / שְׁלוֹשָׁה וְעֶשְׂרִים יוֹם …
  static String _daysPhrase(int n) {
    assert(n >= 1 && n <= 49);
    if (n == 1) return 'יוֹם אֶחָד';
    if (n == 2) return 'שְׁנֵי יָמִים';
    if (n <= 10) {
      const ten = 'עֲשָׂרָה';
      return '${n == 10 ? ten : _units[n]} יָמִים';
    }
    if (n == 11) return 'אַחַד עָשָׂר יוֹם';
    if (n == 12) return 'שְׁנֵים עָשָׂר יוֹם';
    if (n < 20) return '${_units[n - 10]} עָשָׂר יוֹם';
    if (n == 20) return 'עֶשְׂרִים יוֹם';
    if (n == 30) return 'שְׁלוֹשִׁים יוֹם';
    if (n == 40) return 'אַרְבָּעִים יוֹם';
    final tens = (n ~/ 10) * 10;
    return '${_units[n % 10]} ${_tens[tens]} יוֹם';
  }

  /// "Weeks" phrase: שָׁבוּעַ אֶחָד / שְׁנֵי שָׁבוּעוֹת / … שִׁבְעָה שָׁבוּעוֹת.
  static String _weeksPhrase(int w) {
    if (w == 1) return 'שָׁבוּעַ אֶחָד';
    if (w == 2) return 'שְׁנֵי שָׁבוּעוֹת';
    return '${_units[w]} שָׁבוּעוֹת';
  }

  /// Remainder days after full weeks: וְיוֹם אֶחָד / וּשְׁנֵי יָמִים / …
  static String _remainderPhrase(int d) {
    const joined = {
      1: 'וְיוֹם אֶחָד',
      2: 'וּשְׁנֵי יָמִים',
      3: 'וּשְׁלוֹשָׁה יָמִים',
      4: 'וְאַרְבָּעָה יָמִים',
      5: 'וַחֲמִשָּׁה יָמִים',
      6: 'וְשִׁשָּׁה יָמִים',
    };
    return joined[d]!;
  }

  /// Full count sentence for [day], e.g. day 33:
  /// הַיּוֹם שְׁלוֹשָׁה וּשְׁלוֹשִׁים יוֹם, שֶׁהֵם אַרְבָּעָה שָׁבוּעוֹת
  /// וַחֲמִשָּׁה יָמִים לָעוֹמֶר.
  static String countText(int day) {
    assert(day >= 1 && day <= 49);
    final base = 'הַיּוֹם ${_daysPhrase(day)}';
    if (day < 7) return '$base לָעוֹמֶר.';
    final weeks = day ~/ 7;
    final rest = day % 7;
    final weekPart = rest == 0
        ? _weeksPhrase(weeks)
        : '${_weeksPhrase(weeks)} ${_remainderPhrase(rest)}';
    return '$base, שֶׁהֵם $weekPart לָעוֹמֶר.';
  }

  // ── Kabbalistic sefirah of the day (as printed in most siddurim) ────

  static const List<String> _sefirot = [
    'חֶסֶד', 'גְּבוּרָה', 'תִּפְאֶרֶת', 'נֶצַח', 'הוֹד', 'יְסוֹד', 'מַלְכוּת',
  ];

  /// e.g. day 33 → הוֹד שֶׁבְּהוֹד.
  static String sefirahOfDay(int day) {
    assert(day >= 1 && day <= 49);
    final week = (day - 1) ~/ 7;
    final inWeek = (day - 1) % 7;
    final inner = _sefirot[inWeek];
    final outer = _sefirot[week];
    // שֶׁבְּ + sefirah (the ב is part of the construct).
    final connected = switch (outer) {
      'חֶסֶד' => 'שֶׁבְּחֶסֶד',
      'גְּבוּרָה' => 'שֶׁבִּגְבוּרָה',
      'תִּפְאֶרֶת' => 'שֶׁבְּתִפְאֶרֶת',
      'נֶצַח' => 'שֶׁבְּנֶצַח',
      'הוֹד' => 'שֶׁבְּהוֹד',
      'יְסוֹד' => 'שֶׁבִּיסוֹד',
      _ => 'שֶׁבְּמַלְכוּת',
    };
    return '$inner $connected';
  }
}
