import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Tefillat HaDerech — the traveler's prayer, with usage guidance.
class TefilatHaderechScreen extends StatelessWidget {
  const TefilatHaderechScreen({super.key});

  static const String _text = '''
יְהִי רָצוֹן מִלְּפָנֶיךָ ה׳ אֱלֹקֵינוּ וֵאלֹקֵי אֲבוֹתֵינוּ, שֶׁתּוֹלִיכֵנוּ לְשָׁלוֹם וְתַצְעִידֵנוּ לְשָׁלוֹם וְתַדְרִיכֵנוּ לְשָׁלוֹם, וְתַגִּיעֵנוּ לִמְחוֹז חֶפְצֵנוּ לְחַיִּים וּלְשִׂמְחָה וּלְשָׁלוֹם (החוזרים באותו היום מוסיפים: וְתַחְזִירֵנוּ לְשָׁלוֹם), וְתַצִּילֵנוּ מִכַּף כָּל אוֹיֵב וְאוֹרֵב וְלִסְטִים וְחַיּוֹת רָעוֹת בַּדֶּרֶךְ, וּמִכָּל מִינֵי פֻּרְעָנֻיּוֹת הַמִּתְרַגְּשׁוֹת לָבוֹא לָעוֹלָם, וְתִשְׁלַח בְּרָכָה בְּכָל מַעֲשֵׂה יָדֵינוּ, וְתִתְּנֵנוּ לְחֵן וּלְחֶסֶד וּלְרַחֲמִים בְּעֵינֶיךָ וּבְעֵינֵי כָל רוֹאֵינוּ, וְתִשְׁמַע קוֹל תַּחֲנוּנֵינוּ, כִּי אֵל שׁוֹמֵעַ תְּפִלָּה וְתַחֲנוּן אָתָּה. בָּרוּךְ אַתָּה ה׳, שׁוֹמֵעַ תְּפִלָּה.''';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('תפילת הדרך')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'אומרים פעם אחת ביום נסיעה, אחרי שיוצאים מהעיר '
                '(כשעוברים את הבתים האחרונים). נוסעים ברכב — אפשר '
                'לומר בישיבה. הנוסח בלשון רבים גם ליחיד.',
                style: TextStyle(
                    fontSize: 13.5, color: scheme.onSecondaryContainer),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SelectableText(
            _text,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: YeadutTheme.displayFont,
              fontSize: 22,
              height: 1.9,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'יש הבדלי נוסח קלים בין קהילות — הנוסח כאן הוא המקובל. '
            'נסיעה טובה ובטוחה! 🚗',
            style: TextStyle(fontSize: 12.5, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
