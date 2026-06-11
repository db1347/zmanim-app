# Yeadut — Feature Specification (Reviewed & Refined)

A Jewish lifestyle & utility app, Hebrew-first. Features are grouped into
four pillars, ordered by how often a user touches them (daily → situational).

---

## Pillar A — Foundation & Personalization

### A1. User Profile & Customization
- **Location** (GPS or manual city) — mandatory: every zman, candle-lighting
  time, and the compass depend on it.
- **Gender** — drives smart defaults: tefillin reminders (men),
  candle-lighting reminders (women). Always overridable.
- **Nusach**: אשכנז, ספרד, עדות המזרח, אר״י, תימני.
- **Zmanim calculation method (shita)**:
  - Sha'ot zmaniyot: GRA (default) vs. Magen Avraham
  - Alos: 16.1° / 72 min / 90 min
  - Tzeit / end of Shabbat: 8.5°, 42 min, 50 min, 72 min (Rabbeinu Tam)
  - Candle lighting offset: 18 min standard, 40 min (Jerusalem custom)
- **Israel / Diaspora mode** — 1 vs. 2 days of Yom Tov.
- **Language**: Hebrew-first (implemented), full RTL.

**UX principle:** never force a halachic decision during onboarding — ship
"most common" defaults, refine later in Settings.

---

## Pillar B — Daily Core (deterministic, offline-first)

### B1. Zmanim & Calendar Dashboard
- Daily times per the user's shitot; "next zman" countdown hero.
- Hebrew date, parsha, omer, daf yomi; Shabbat/holiday card with candle
  lighting & havdalah; dual-calendar month view.
- Engine: kosher_dart (KosherJava port) — never hand-rolled astronomy.

### B2. Prayer Compass
- Bearing to the Temple Mount (31.7780° N, 35.2354° E).
- Great-circle AND rhumb-line (genuine halachic debate; ~70° apart from NYC).
- Calibration prompt, haptic + gold "facing Jerusalem" state, distance.

### B3. Smart Reminders
- Tefillin (default ON for men): suppressed on Shabbat, Yom Tov,
  Chol HaMoed, Tisha B'Av — the suppression is the differentiator.
- Candle lighting (default ON for women): N minutes before, every erev
  Shabbat/chag.
- Scheduled day-by-day over a rolling window (not blind daily repeats).

---

## Pillar C — AI-Powered Tools

### C1. "Ask the Rabbi" AI
- Answers in Hebrew. Educational only — persistent "not a psak" banner.
- Pikuach-nefesh override (emergency → call 101 immediately).
- Cited sources; Ashkenazi/Sephardi divergence noted; sensitive topics
  (kashrut accidents, gittin, conversion, medical) → human Rav.

### C2. AI Bracha (Blessing) Scanner
- Photo → Claude vision identifies food (English names) → curated Hebrew
  bracha database does the halachic mapping. AI never invents halacha.
- Confidence chips for ambiguity; ikar v'tafel warning for mixtures;
  offline Hebrew text search always available.

### C3. Kosher Validator → split
- **Hechsher lookup**: barcode → certification DB (starter dataset; real
  agency integration is a data project).
- **Kosher situations**: bounded customs only (meat/milk waiting);
  accidents always routed to a Rav.

---

## Pillar D — Shabbat-Aware Utilities

### D1. Kosher Shabbat Alarm (implemented with two layers)
1. **Real OS alarms (Android)**: exact `AlarmManager` scheduling per
   restricted day (next 10 days), full-screen alarm-channel notification,
   raw looping sound (FLAG_INSISTENT), `timeoutAfter` auto-cancel — rings
   and turns itself off with zero interaction, even in Doze.
2. **In-app Shabbat mode**: dimmed wakelock clock; rings and auto-stops.
   The only reliable iOS path; backup on Android.
- Configured entirely before Shabbat; in-app note to consult a Rav about
  one's custom.

---

## Backlog
Siddur per nusach, minyan finder, kosher restaurant map, yahrzeit reminders,
Daf Yomi tracker, home-screen widgets, watch complications, travel mode,
remote-timezone zmanim.
