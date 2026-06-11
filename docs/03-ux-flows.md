# Yeadut — UX / UI Flows (Hebrew-first, RTL)

## Information Architecture

Four-tab bottom navigation (RTL order on screen):

```
┌─────────┬─────────┬─────────┬─────────┐
│  היום   │  כלים   │   שאל   │ פרופיל  │
└─────────┴─────────┴─────────┴─────────┘
```

- **היום** (home): zmanim dashboard, Hebrew date, next-zman countdown,
  Shabbat/Holiday card, calendar entry point.
- **כלים**: מצפן תפילה · סורק ברכות · בדיקת כשרות · שעון מעורר לשבת ·
  בשר וחלב.
- **שאל**: Ask-the-Rabbi AI chat (Hebrew, citations, Rav escape hatch).
- **פרופיל**: location, gender, nusach, shitot, reminders, AI key, about.

## Flow 1 — Onboarding (≤ 90 seconds)
ברוכים הבאים → מיקום (GPS או עיר) → מגדר → נוסח → שיטת זמנים → היום.
Every step skippable; defaults marked «הנפוץ ביותר»; ≤ 8 taps to home.

## Flow 2 — Daily check (retention loop)
Open → היום tab → hero «הזמן הבא: מנחה קטנה בעוד 42 דק׳» → zmanim list
(tap → Hebrew explainer sheet) → Shabbat card pinned Thu–Sat.

## Flow 3 — Prayer Compass
כלים → מצפן: calibration coach if needed → live arrow; within ±5° → haptic
+ gold + «פונים לירושלים» → footer: distance + azimuth; settings: great
circle ⇄ rhumb line.

## Flow 4 — Ask the Rabbi
Persistent banner: «תוכן לימודי בלבד — אינו פסק הלכה». Answers in Hebrew:
TL;DR → reasoning → sources; under each answer: «שאלה מורכבת או אישית? פנו
ישירות לרב». Emergency pattern → pikuach-nefesh response first.

## Flow 5 — Bracha Scanner
צילום/גלריה → AI identifies → Hebrew bracha cards (full text לפני ואחרי) →
low confidence: multiple candidate cards → mixture: עיקר וטפל warning +
route to שאל. Offline Hebrew text search always present.

## Flow 6 — Hechsher Lookup
סריקת ברקוד (frame-deduped) or manual entry → found: certification + status
(חלבי/פרווה/בשרי) → not found: report stub + check-the-package guidance.

## Flow 7 — Shabbat Alarm (the must-work flow)
```
כלים → שעון מעורר לשבת
  → add times (24h picker) → saved + OS alarms scheduled immediately for
    every Shabbat/Yom Tov in the next 10 days (exact, full-screen,
    self-cancelling after N minutes of looping alarm sound)
  → optional but recommended: «כניסה למצב שבת» before candle lighting —
    dimmed clock, wakelock, plugged in; rings + auto-stops; long-press exits
  → after havdalah: relaunch tops up the next window automatically
```

## Flow 8 — Reminders management
פרופיל → תזכורות: toggles + timing; visible trust line: «תזכורות לעולם לא
יישלחו בשבת וביום טוב».

---

## Design-language notes
- Hebrew-first: `locale: he` app-wide; framework-mirrored RTL; 24-hour times.
- Calm, trustworthy, modern-traditional: deep blue + warm parchment.
- Zmanim glanceable: large numerals, tabular figures, high contrast.
- Offline states designed, not apologized for.
