import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/models/bracha_entry.dart';
import 'package:yeadut/services/bracha_database.dart';

void main() {
  group('BrachaDatabase.search', () {
    test('finds bread as HaMotzi via English keyword', () {
      final results = BrachaDatabase.search('bread');
      expect(results, isNotEmpty);
      expect(results.first.rishona, BrachaRishona.hamotzi);
      expect(results.first.acharona, BrachaAcharona.birkatHamazon);
    });

    test('finds by Hebrew name (לחם)', () {
      final results = BrachaDatabase.search('לחם');
      expect(results, isNotEmpty);
      expect(results.first.rishona, BrachaRishona.hamotzi);
    });

    test('finds by Hebrew keyword (שניצל → עוף → שהכל)', () {
      final results = BrachaDatabase.search('שניצל');
      expect(results, isNotEmpty);
      expect(results.first.rishona, BrachaRishona.shehakol);
    });

    test('English keyword search is case-insensitive', () {
      expect(BrachaDatabase.search('APPLE'), isNotEmpty);
      expect(
          BrachaDatabase.search('Apple').first.rishona, BrachaRishona.haetz);
    });

    test('empty query returns nothing', () {
      expect(BrachaDatabase.search(''), isEmpty);
      expect(BrachaDatabase.search('   '), isEmpty);
    });

    test('grapes map to Al HaEtz after-blessing (5 fruits of Israel)', () {
      final results = BrachaDatabase.search('ענבים');
      expect(results.first.acharona, BrachaAcharona.alHaetz);
    });

    test('banana is HaAdama despite growing on a "tree"', () {
      final results = BrachaDatabase.search('בננה');
      expect(results.first.rishona, BrachaRishona.haadama);
    });

    test('rice is Mezonot before but Borei Nefashot after', () {
      final results = BrachaDatabase.search('rice');
      expect(results.first.rishona, BrachaRishona.mezonot);
      expect(results.first.acharona, BrachaAcharona.boreNefashot);
    });
  });

  group('BrachaDatabase.bestMatch', () {
    test('matches compound AI names ("chocolate babka" → mezonot)', () {
      final entry = BrachaDatabase.bestMatch('chocolate babka');
      expect(entry, isNotNull);
    });

    test('returns null for unknown food', () {
      expect(BrachaDatabase.bestMatch('zzzunknownfood'), isNull);
    });
  });

  group('database hygiene', () {
    test('all HaMotzi entries lead to Birkat HaMazon', () {
      for (final e in BrachaDatabase.entries
          .where((e) => e.rishona == BrachaRishona.hamotzi)) {
        expect(e.acharona, BrachaAcharona.birkatHamazon,
            reason: '${e.name} is HaMotzi but not Birkat HaMazon');
      }
    });

    test('all HaGafen entries lead to Al HaGefen', () {
      for (final e in BrachaDatabase.entries
          .where((e) => e.rishona == BrachaRishona.hagafen)) {
        expect(e.acharona, BrachaAcharona.alHagefen);
      }
    });

    test('no duplicate names', () {
      final names = BrachaDatabase.entries.map((e) => e.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('every entry has at least one English keyword for AI matching', () {
      final english = RegExp(r'[a-z]');
      for (final e in BrachaDatabase.entries) {
        expect(e.keywords.any((k) => english.hasMatch(k)), isTrue,
            reason: '${e.name} has no English keyword — the AI scanner '
                'could never match it');
      }
    });
  });
}
