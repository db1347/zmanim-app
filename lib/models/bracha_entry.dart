/// Blessing categories before eating.
enum BrachaRishona {
  hamotzi,
  mezonot,
  hagafen,
  haetz,
  haadama,
  shehakol,
}

/// Blessing categories after eating.
enum BrachaAcharona {
  birkatHamazon,
  alHamichya,
  alHagefen,
  alHaetz,
  boreNefashot,
}

extension BrachaRishonaText on BrachaRishona {
  String get label => switch (this) {
        BrachaRishona.hamotzi => 'המוציא',
        BrachaRishona.mezonot => 'בורא מיני מזונות',
        BrachaRishona.hagafen => 'בורא פרי הגפן',
        BrachaRishona.haetz => 'בורא פרי העץ',
        BrachaRishona.haadama => 'בורא פרי האדמה',
        BrachaRishona.shehakol => 'שהכל',
      };

  /// Closing words of the bracha (all open with
  /// ברוך אתה ה׳ אלקינו מלך העולם).
  String get hebrewEnding => switch (this) {
        BrachaRishona.hamotzi => 'הַמּוֹצִיא לֶחֶם מִן הָאָרֶץ',
        BrachaRishona.mezonot => 'בּוֹרֵא מִינֵי מְזוֹנוֹת',
        BrachaRishona.hagafen => 'בּוֹרֵא פְּרִי הַגָּפֶן',
        BrachaRishona.haetz => 'בּוֹרֵא פְּרִי הָעֵץ',
        BrachaRishona.haadama => 'בּוֹרֵא פְּרִי הָאֲדָמָה',
        BrachaRishona.shehakol => 'שֶׁהַכֹּל נִהְיָה בִּדְבָרוֹ',
      };
}

extension BrachaAcharonaText on BrachaAcharona {
  String get label => switch (this) {
        BrachaAcharona.birkatHamazon => 'ברכת המזון',
        BrachaAcharona.alHamichya => 'על המחיה',
        BrachaAcharona.alHagefen => 'על הגפן',
        BrachaAcharona.alHaetz => 'על העץ',
        BrachaAcharona.boreNefashot => 'בורא נפשות',
      };

  String get description => switch (this) {
        BrachaAcharona.birkatHamazon => 'ברכת המזון המלאה (נאכל לחם)',
        BrachaAcharona.alHamichya => 'מעין שלוש על מיני מזונות',
        BrachaAcharona.alHagefen => 'מעין שלוש על יין או מיץ ענבים',
        BrachaAcharona.alHaetz => 'מעין שלוש על פירות שבעת המינים',
        BrachaAcharona.boreNefashot => 'ברכה אחרונה קצרה',
      };
}

/// One food entry in the offline bracha database.
class BrachaEntry {
  final String name;

  /// Search keywords — both Hebrew (user search) and English (matching the
  /// AI vision model's food identifications).
  final List<String> keywords;
  final BrachaRishona rishona;
  final BrachaAcharona acharona;

  /// Halachic nuance worth surfacing (ikar/tafel, kovea seudah, etc.).
  final String? note;

  const BrachaEntry({
    required this.name,
    required this.keywords,
    required this.rishona,
    required this.acharona,
    this.note,
  });
}
