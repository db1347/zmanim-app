# יהדות (Yeadut)

A Hebrew-first Jewish lifestyle app for Android and iOS, built with Flutter.
Halachic times (zmanim) by the user's chosen method, a real Hebrew calendar,
Sefirat HaOmer, Hebrew-date events, and Shabbat alarms that ring and stop on
their own without anyone touching the phone — implemented as real OS alarms
(exact Android alarms, AlarmKit on iOS 26+).

אפליקציית סגנון חיים יהודית מקיפה — בעברית, RTL מלא: זמני היום לפי שיטת המשתמש,
לוח עברי, ספירת העומר, אירועים לפי תאריך עברי, ושעון מעורר לשבת שמצלצל ומפסיק לבד.

**Status:** feature-complete v1.0 (Android signed release build; iOS needs Xcode 26).
Designed, written and tested by me (Daniel B). 90 unit tests cover the pure logic:
zmanim, the Hebrew calendar edge cases (Adar in leap years, the night date flip),
the Omer count, reminder rules and the alarm schedules.

What was interesting to build:

- **Time that depends on halacha, not on the clock.** The Hebrew date changes at
  nightfall, not at midnight; zmanim differ by method (Gra, Magen Avraham) and by
  location; reminders must be silenced on Shabbat, Yom Tov, Chol HaMoed and Tisha
  B'Av. These rules live in pure Dart services with no Flutter dependency, so they
  are unit-tested directly.
- **An alarm nobody may touch.** On Shabbat the user can't turn an alarm off, so it
  has to ring for a set time and stop itself, even with the screen locked, in
  Doze, or after the app was killed. See [How the Shabbat alarm works](#how-the-shabbat-alarm-works).
- **Offline first.** Everything deterministic works without a network. The AI
  features use the user's own API key, stored only on the device.

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
2. **AlarmKit alarms (iOS 26+):** real system alarms via Apple's AlarmKit —
   ring through Silent/Focus, full-screen on the Lock Screen, fire even if
   the app was terminated. On older iOS, a self-ending chain of
   notification chimes is scheduled instead.
3. **In-app Shabbat mode:** a dimmed wakelock clock that rings each alarm
   and stops it by itself — the universal backup, recommended on iOS < 26.

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
- Hechsher database is a five-product demonstration dataset to show the barcode
  flow end to end. It is **not** authoritative kashrut information — there is no
  unified public kashrut API, and production would need a real data source.
- iOS Shabbat alarms: on iOS 26+ the app schedules **real AlarmKit
  alarms** — they ring through Silent mode, Focus, and app termination,
  exactly like the system Clock (ring duration is system-managed rather
  than the configured minutes). On older iOS a chain of self-ending
  notification chimes approximates the alarm, and מצב שבת remains the
  recommended path. Building the iOS target requires Xcode 26.
- Ask-the-Rabbi answers are educational only — not a psak halacha.

## Planning docs

See [docs/01-feature-spec.md](docs/01-feature-spec.md),
[docs/02-roadmap.md](docs/02-roadmap.md),
[docs/03-ux-flows.md](docs/03-ux-flows.md).

## License

[MIT](LICENSE)
