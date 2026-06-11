import '../models/bracha_entry.dart';

/// Offline food → bracha database. Works with no connectivity and backs the
/// AI scanner (the vision model only *identifies* the food; the halachic
/// mapping always comes from this curated list).
///
/// Names are Hebrew (the app language); keywords are bilingual — Hebrew for
/// user search, English for matching the vision model's identifications.
class BrachaDatabase {
  const BrachaDatabase._();

  /// Case-insensitive search across names and keywords. Ranking:
  /// exact name → name substring → keyword match ("ענבים" must return
  /// grapes before grape juice).
  static List<BrachaEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final exactHits = <BrachaEntry>[];
    final nameHits = <BrachaEntry>[];
    final keywordHits = <BrachaEntry>[];
    for (final entry in entries) {
      final name = entry.name.toLowerCase();
      if (name == q) {
        exactHits.add(entry);
      } else if (name.contains(q)) {
        nameHits.add(entry);
      } else if (entry.keywords.any((k) => k.contains(q) || q.contains(k))) {
        keywordHits.add(entry);
      }
    }
    return [...exactHits, ...nameHits, ...keywordHits];
  }

  /// Best single match for an AI-identified food name, or null.
  static BrachaEntry? bestMatch(String foodName) {
    final results = search(foodName);
    if (results.isNotEmpty) return results.first;
    // Try individual words ("chocolate babka" → "babka").
    for (final word in foodName.toLowerCase().split(RegExp(r'[\s,]+'))) {
      if (word.length < 3) continue;
      final wordResults = search(word);
      if (wordResults.isNotEmpty) return wordResults.first;
    }
    return null;
  }

  static const List<BrachaEntry> entries = [
    // ── לחם — המוציא ───────────────────────────────────────────────────
    BrachaEntry(
        name: 'לחם',
        keywords: ['bread', 'loaf', 'sourdough', 'rye', 'baguette', 'לחמניה'],
        rishona: BrachaRishona.hamotzi,
        acharona: BrachaAcharona.birkatHamazon),
    BrachaEntry(
        name: 'חלה',
        keywords: ['challah', 'braided bread'],
        rishona: BrachaRishona.hamotzi,
        acharona: BrachaAcharona.birkatHamazon),
    BrachaEntry(
        name: 'פיתה',
        keywords: ['pita', 'laffa', 'flatbread', 'לאפה'],
        rishona: BrachaRishona.hamotzi,
        acharona: BrachaAcharona.birkatHamazon),
    BrachaEntry(
        name: 'בייגל',
        keywords: ['bagel', 'bialy'],
        rishona: BrachaRishona.hamotzi,
        acharona: BrachaAcharona.birkatHamazon),
    BrachaEntry(
        name: 'כריך / סנדוויץ׳',
        keywords: ['sandwich', 'sub', 'toast', 'טוסט'],
        rishona: BrachaRishona.hamotzi,
        acharona: BrachaAcharona.birkatHamazon,
        note: 'הלחם הוא העיקר — ברכת המוציא פוטרת את התוספות שבפנים.'),
    BrachaEntry(
        name: 'פיצה',
        keywords: ['pizza', 'pizza slice'],
        rishona: BrachaRishona.hamotzi,
        acharona: BrachaAcharona.birkatHamazon,
        note: 'המנהג הרווח לברך המוציא על פיצה; יש המברכים מזונות על '
            'כמות של עראי — שאלו רב לפי מנהגכם.'),
    BrachaEntry(
        name: 'מצה',
        keywords: ['matzah', 'matza', 'matzo'],
        rishona: BrachaRishona.hamotzi,
        acharona: BrachaAcharona.birkatHamazon),

    // ── מזונות ─────────────────────────────────────────────────────────
    BrachaEntry(
        name: 'עוגה',
        keywords: ['cake', 'sponge', 'birthday cake', 'עוגת'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.alHamichya),
    BrachaEntry(
        name: 'עוגיות',
        keywords: ['cookies', 'biscuit', 'rugelach', 'babka', 'brownie',
            'רוגלך', 'בראוניז'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.alHamichya),
    BrachaEntry(
        name: 'קרקרים',
        keywords: ['crackers', 'pretzel', 'breadstick', 'בייגלה'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.alHamichya),
    BrachaEntry(
        name: 'פסטה',
        keywords: ['pasta', 'spaghetti', 'noodles', 'macaroni', 'couscous',
            'אטריות', 'קוסקוס', 'פתיתים'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.alHamichya),
    BrachaEntry(
        name: 'דייסת שיבולת שועל',
        keywords: ['oatmeal', 'porridge', 'granola', 'oats', 'גרנולה',
            'קוואקר'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.alHamichya),
    BrachaEntry(
        name: 'דגני בוקר (חיטה/שיבולת שועל)',
        keywords: ['cereal', 'cheerios', 'bran flakes', 'wheat cereal',
            'קורנפלקס חיטה'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.alHamichya,
        note: 'דגנים מחמשת מיני דגן — מזונות; דגני תירס או אורז שונים '
            '(לרוב שהכל) — בדקו את הרכיב העיקרי.'),
    BrachaEntry(
        name: 'אורז מבושל',
        keywords: ['rice', 'cooked rice', 'sushi rice'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.boreNefashot,
        note: 'אורז — מקרה מיוחד: מזונות לפניו אך בורא נפשות אחריו.'),
    BrachaEntry(
        name: 'בורקס',
        keywords: ['bourekas', 'pastry', 'croissant', 'danish', 'קרואסון',
            'מאפה'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.alHamichya,
        note: 'אכילת שיעור קביעות סעודה עשויה לשנות להמוציא וברכת המזון.'),

    // ── יין ────────────────────────────────────────────────────────────
    BrachaEntry(
        name: 'יין',
        keywords: ['wine', 'red wine', 'white wine', 'kiddush wine'],
        rishona: BrachaRishona.hagafen,
        acharona: BrachaAcharona.alHagefen),
    BrachaEntry(
        name: 'מיץ ענבים',
        keywords: ['grape juice', 'grapejuice'],
        rishona: BrachaRishona.hagafen,
        acharona: BrachaAcharona.alHagefen),

    // ── העץ ────────────────────────────────────────────────────────────
    BrachaEntry(
        name: 'תפוח',
        keywords: ['apple', 'apples', 'תפוחים'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'תפוז',
        keywords: ['orange', 'clementine', 'tangerine', 'mandarin', 'citrus',
            'קלמנטינה', 'מנדרינה'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'ענבים',
        keywords: ['grapes', 'grape'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.alHaetz,
        note: 'משבעת המינים — ברכה אחרונה: על העץ.'),
    BrachaEntry(
        name: 'רימון',
        keywords: ['pomegranate'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.alHaetz,
        note: 'משבעת המינים — ברכה אחרונה: על העץ.'),
    BrachaEntry(
        name: 'תמרים',
        keywords: ['dates', 'date', 'medjool', 'תמר'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.alHaetz,
        note: 'משבעת המינים — ברכה אחרונה: על העץ.'),
    BrachaEntry(
        name: 'תאנים',
        keywords: ['figs', 'fig', 'תאנה'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.alHaetz,
        note: 'משבעת המינים — ברכה אחרונה: על העץ.'),
    BrachaEntry(
        name: 'זיתים',
        keywords: ['olives', 'olive', 'זית'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.alHaetz,
        note: 'משבעת המינים — ברכה אחרונה: על העץ.'),
    BrachaEntry(
        name: 'בננה',
        keywords: ['banana', 'bananas'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot,
        note: 'הבננה גדלה על צמח שאינו עץ הלכתי — ברכתה האדמה.'),
    BrachaEntry(
        name: 'אפרסק',
        keywords: ['peach', 'nectarine', 'plum', 'apricot', 'cherry',
            'שזיף', 'משמש', 'דובדבן', 'נקטרינה'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'אגס',
        keywords: ['pear', 'pears'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'מנגו',
        keywords: ['mango', 'mangoes'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'שקדים ואגוזים',
        keywords: ['almonds', 'walnut', 'pecan', 'cashew', 'nuts', 'hazelnut',
            'אגוז', 'שקד', 'קשיו', 'פקאן'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'אבוקדו',
        keywords: ['avocado', 'guacamole'],
        rishona: BrachaRishona.haetz,
        acharona: BrachaAcharona.boreNefashot),

    // ── האדמה ──────────────────────────────────────────────────────────
    BrachaEntry(
        name: 'עגבנייה',
        keywords: ['tomato', 'cherry tomato', 'עגבניות'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'מלפפון',
        keywords: ['cucumber', 'pickles', 'pickle', 'חמוצים'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'גזר',
        keywords: ['carrot', 'carrots'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'תפוח אדמה',
        keywords: ['potato', 'baked potato', 'mashed potato', 'fries',
            'french fries', 'צ׳יפס מטוגן', 'פירה'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'סלט ירקות',
        keywords: ['salad', 'lettuce', 'greens', 'israeli salad', 'coleslaw',
            'חסה', 'סלט ירוק'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot,
        note: 'עם קרוטונים או תוספות משמעותיות ייתכנו כמה ברכות — '
            'מקרה קלאסי של עיקר וטפל.'),
    BrachaEntry(
        name: 'אבטיח ומלון',
        keywords: ['watermelon', 'melon', 'cantaloupe', 'honeydew', 'אבטיח',
            'מלון'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'תות שדה',
        keywords: ['strawberry', 'strawberries', 'pineapple', 'אננס',
            'תותים'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'תירס',
        keywords: ['corn', 'corn on the cob', 'popcorn', 'פופקורן'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'חומוס',
        keywords: ['hummus', 'chickpeas', 'falafel', 'פלאפל'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot,
        note: 'פלאפל בפיתה: הפיתה לרוב המוציא ופוטרת את הכול.'),

    // ── שהכל ───────────────────────────────────────────────────────────
    BrachaEntry(
        name: 'מים',
        keywords: ['water', 'sparkling water', 'seltzer', 'סודה'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'קפה',
        keywords: ['coffee', 'espresso', 'latte', 'cappuccino', 'אספרסו',
            'הפוך'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'תה',
        keywords: ['tea', 'herbal tea', 'חליטה'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'חלב',
        keywords: ['milk', 'yogurt', 'leben', 'יוגורט', 'לבן'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'גבינה',
        keywords: ['cheese', 'cottage cheese', 'mozzarella', 'קוטג׳',
            'גבינה צהובה'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'ביצים',
        keywords: ['eggs', 'egg', 'omelet', 'omelette', 'scrambled eggs',
            'חביתה', 'ביצה'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'בשר',
        keywords: ['meat', 'steak', 'beef', 'lamb', 'shawarma', 'סטייק',
            'שווארמה', 'צלי'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'עוף',
        keywords: ['chicken', 'schnitzel', 'poultry', 'turkey', 'שניצל',
            'הודו'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'דג',
        keywords: ['fish', 'salmon', 'tuna', 'gefilte fish', 'herring',
            'סלמון', 'טונה', 'גפילטע'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'שוקולד',
        keywords: ['chocolate', 'chocolate bar', 'candy', 'gummy', 'ממתק',
            'סוכריה'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot,
        note: 'המנהג הרווח שהכל; יש דעות לברך העץ על שוקולד.'),
    BrachaEntry(
        name: 'גלידה',
        keywords: ['ice cream', 'gelato', 'sorbet', 'frozen yogurt', 'סורבה',
            'ארטיק'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot),
    BrachaEntry(
        name: 'צ׳יפס (חטיף)',
        keywords: ['potato chips', 'chips', 'crisps', 'bamba', 'bissli',
            'במבה', 'תפוצ׳יפס'],
        rishona: BrachaRishona.haadama,
        acharona: BrachaAcharona.boreNefashot,
        note: 'חטיף מפרוסות תפו״א אמיתיות — האדמה; משוחזר (כמו פרינגלס) '
            'לרוב שהכל. במבה — האדמה, ביסלי — מזונות.'),
    BrachaEntry(
        name: 'מיץ פירות',
        keywords: ['juice', 'orange juice', 'apple juice', 'lemonade', 'soda',
            'cola', 'לימונדה', 'קולה', 'מיץ תפוזים'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot,
        note: 'מיצי פירות (חוץ ממיץ ענבים) — שהכל.'),
    BrachaEntry(
        name: 'מרק',
        keywords: ['soup', 'chicken soup', 'broth', 'מרק עוף', 'מרק ירקות'],
        rishona: BrachaRishona.shehakol,
        acharona: BrachaAcharona.boreNefashot,
        note: 'מרק עם ירקות או אטריות בכמות משמעותית עשוי לקבל את ברכתם — '
            'מקרה מורכב נפוץ.'),
    BrachaEntry(
        name: 'סושי',
        keywords: ['sushi', 'sushi roll', 'maki'],
        rishona: BrachaRishona.mezonot,
        acharona: BrachaAcharona.boreNefashot,
        note: 'ברוב הרולים האורז הוא העיקר (מזונות, בורא נפשות אחריו). '
            'סשימי ללא אורז — שהכל.'),
  ];
}
