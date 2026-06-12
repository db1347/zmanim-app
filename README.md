# יהדות (Yeadut)

אפליקציית סגנון חיים יהודית מקיפה — בעברית, RTL מלא. Built with Flutter.

## Features

| Feature | Status | Notes |
|---|---|---|
| Onboarding & profile | ✅ | מיקום (GPS או 33 ערים + חיפוש), מגדר, נוסח, שיטת זמנים |
| Zmanim dashboard | ✅ | כל זמני היום לפי שיטת המשתמש, ספירה לאחור + מד התקדמות |
| Hebrew calendar | ✅ | לוח חודשי עברי/לועזי, חגים, פרשה, דף יומי |
| Shabbat/Holiday card | ✅ | הדלקת נרות והבדלה לפי השיטה, מצב ארץ ישראל/חו״ל |
| **Sefirat HaOmer** | ✅ | נוסח מלא מנוקד לכל 49 הימים, ברכה, ספירות, רצף, תזכורת אחרי צאת הכוכבים (לא בליל שבת/חג) |
| **Hebrew-date events** | ✅ | יארצייט/יום הולדת/נישואין לפי תאריך עברי — כולל אדר בשנה מעוברת ול׳ בחודש חסר; תזכורת נר נשמה בערב + בוקר האירוע |
| **Daf Yomi tracker** | ✅ | הדף של היום + סימון «סיימתי» ורצף לימוד |
| Prayer compass | ✅ | מצפן לכיוון הר הבית — קו גדול או קו ישר, רטט בכיוון מדויק |
| Smart reminders | ✅ | תפילין והדלקת נרות עם השתקה הלכתית (שבת, יו״ט, חוה״מ, ת״ב) |
| **Shabbat alarm (real OS alarms)** | ✅ | התראות מערכת מדויקות בערוץ Alarm: מסך מלא, צליל בלולאה, כיבוי עצמי — בלי מגע. בנוסף: מצב שבת בתוך האפליקציה (חובה ב־iOS) |
| Ask the Rabbi AI | ✅ | עונה בעברית; הסתייגות «לא פסק הלכה», עדיפות פיקוח נפש, מקורות |
| Bracha scanner | ✅ | זיהוי מאכל בתמונה (Claude vision) + מאגר ברכות עברי לא־מקוון |
| Hechsher lookup | ✅ | סריקת ברקוד + מאגר הדגמה |
| Kosher situations | ✅ | זמני המתנה בשר/חלב לפי מנהג; תקלות כשרות מופנות לרב |
| Dark mode | ✅ | לפי המערכת / בהיר / כהה |
| **Hebrew-month calendar** | ✅ | לוח עברי אמיתי: החודש העברי הוא הרשת, תאריך לועזי כהערה; מולד בראש חודש |
| **Backup & restore** | ✅ | ייצוא/ייבוא כל ההגדרות והנתונים דרך הלוח — בלי מפתח ה־API |
| **Tefillat HaDerech** | ✅ | נוסח מנוקד מלא + הנחיות |
| **Night-aware date** | ✅ | אחרי צאת הכוכבים התאריך העברי מתחלף + ספירה לאחור להדלקת נרות בערב שבת |
| Visual identity | ✅ | אייקון מגן דוד מוזהב (adaptive), מסך פתיחה ממותג, גופני Heebo + Frank Ruhl Libre מובנים (לא דורשים רשת) |

## How the Shabbat alarm works

1. **OS-scheduled alarms (Android):** every preset alarm is scheduled with
   `exactAllowWhileIdle` on every Shabbat/Yom Tov in the next 10 days, as a
   full-screen alarm-category notification with a raw alarm sound, the
   `FLAG_INSISTENT` loop, and `timeoutAfter` — it rings, then cancels itself.
   Zero interaction, works from Doze with the screen locked.
2. **In-app Shabbat mode:** a dimmed wakelock clock that rings each alarm
   and stops it by itself. The reliable path on iOS (which does not allow
   long background ringing) and a backup on Android.

## Architecture

```
lib/
  core/        theme, constants
  models/      immutable data models (UserProfile, ZmanItem, ShabbatAlarm, BrachaEntry)
  services/    pure logic + integrations (zmanim, calendar, bearing math,
               reminder rules, notifications+alarms, AI client, offline DBs)
  features/    one folder per screen/flow
```

- **Zmanim:** [kosher_dart](https://pub.dev/packages/kosher_dart) (KosherJava port).
- **Locale:** Hebrew (`he`) app-wide; the framework mirrors the entire UI to RTL.
- **AI:** user-supplied Anthropic API key, stored on-device in its own storage
  entry (never inside the profile blob); the assistant is instructed to answer
  in Hebrew. All deterministic features work fully offline.

## Running

```bash
flutter pub get
flutter run            # device or simulator
flutter test           # unit tests
flutter analyze
```

## Release builds

Release signing reads `android/key.properties` + `android/upload-keystore.jks`
(both git-ignored — **back the keystore up somewhere safe**; losing it means
losing the ability to update a published app). Without them the build falls
back to debug signing.

```bash
flutter build apk --release        # signed, minified APK (sideload)
flutter build appbundle --release  # AAB for Google Play
```

R8 minification + resource shrinking are enabled; keep rules for
flutter_local_notifications (Gson) and ML Kit live in
`android/app/proguard-rules.pro`.

## Known limitations

- Zmanim are computed in the device's timezone — viewing a saved city in
  another timezone shifts times.
- Hechsher database is a starter dataset.
- iOS cannot ring a long background alarm — use מצב שבת with the phone
  plugged in; the scheduled notification still appears with a short sound.
- Ask-the-Rabbi answers are educational only — not a psak halacha.

## Planning docs

See [docs/01-feature-spec.md](docs/01-feature-spec.md),
[docs/02-roadmap.md](docs/02-roadmap.md),
[docs/03-ux-flows.md](docs/03-ux-flows.md).
