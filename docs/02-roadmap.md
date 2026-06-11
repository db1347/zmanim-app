# Yeadut — Feature Roadmap

Strategy: deterministic daily-habit core first (offline, low risk), then AI
tools (guardrails + liability), then the hardest engineering (alarms) —
**status: all three phases below have shipped a v1 in the current build.**

---

## Phase 1 — Daily Core MVP ✅ (built)
| # | Deliverable | Status |
|---|------------|--------|
| 1 | Onboarding & Profile (Hebrew, skippable, smart defaults) | ✅ |
| 2 | Zmanim Dashboard with next-zman countdown | ✅ |
| 3 | Hebrew Calendar month view | ✅ |
| 4 | Shabbat/Holiday card (candle lighting + havdalah per shita) | ✅ |
| 5 | Prayer Compass (great-circle + rhumb-line) | ✅ |
| 6 | Smart Reminders with halachic suppression | ✅ |

**Remaining exit criteria:** verify zmanim against MyZmanim/Hebcal for 5
cities including a high-latitude edge case; D1 retention ≥ 25%.

## Phase 2 — AI Layer ✅ (built; rabbinic review pending)
| # | Deliverable | Status |
|---|------------|--------|
| 1 | Ask the Rabbi AI (Hebrew answers, citations, pikuach-nefesh override) | ✅ |
| 2 | Offline Hebrew bracha search (~60 foods) | ✅ |
| 3 | AI Bracha Scanner (vision → curated mapping) | ✅ |
| 4 | Hechsher barcode lookup (starter dataset) | ✅ |

**Launch blockers:** rabbinic advisor review of guardrails + a 200-question
eval set; bracha scanner top-3 accuracy ≥ 95% on a held-out photo set.

## Phase 3 — Shabbat Utilities ✅ / 🔜
| # | Deliverable | Status |
|---|------------|--------|
| 1 | Kosher Shabbat Alarm — OS-scheduled (Android) + Shabbat mode (iOS) | ✅ |
| 2 | Kosher Situations (meat/milk waiting customs) | ✅ |
| 3 | Sefirat HaOmer reminder with streaks | 🔜 |
| 4 | Home-screen zmanim widgets | 🔜 |

## Phase 4 — Backlog
Siddur · minyan finder · kosher restaurants · yahrzeit · Daf Yomi tracker ·
watch complications · travel mode · remote-timezone zmanim · real hechsher
data integration · community product reporting.

---

## Cross-cutting
- **Rabbinic advisory board** — sign-off on AI answer categories, decision
  trees, and the alarm approach. Recruit before public release.
- **Trust & accuracy** — zmanim verification suite as CI; AI eval harness.

## Key risks
1. iOS background alarm limits — Shabbat mode is the primary iOS story.
2. Kosher certification data — no unified API; budget for aggregation.
3. AI liability — wrong psak destroys trust; review is a launch blocker.
4. Zmanim correctness — 2 minutes off loses this audience.
