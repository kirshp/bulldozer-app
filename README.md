# BullDozer app

Flutter client for [BullDozer](https://shpara.com/bulldozer) — the world in numbers.
Same pattern as the Ativa app: a thin mobile shell over the site's public JSON endpoints.

> **License / usage.** This repository is public for portfolio and transparency
> only — it is **not** open source. All rights reserved; reuse or redistribution
> is not permitted. See [LICENSE](LICENSE).

## Tabs

- **Home** — brand hero, featured happiness card (live), quick stats.
- **Charts** — 150+ indicators, search + topic filter; per-indicator ranking bars
  with period switcher; tap a country bar for its trend.
- **Countries** — searchable country list (flags); full profile with a locator
  map, Wikipedia summary, values and ranks by topic, tap any indicator for its
  trend line chart, and a **Compare** view (up to 5 countries on one indicator).
- **Maps** — every dataset has a **Map** view: a world choropleth coloured by
  the data; tap a country for its trend. Geometry is pre-projected into
  `assets/world.json` (see `tools/`), painted with `CustomPaint`.
- **Quiz** — "Guess the country": 10 rounds, data facts as hints, fewer hints =
  more points, flag as the last hint.

## Data

All data comes live from `https://shpara.com/bulldozer/data/`:

- `{slug}.json` — one dataset (meta + observations, up to 8 periods)
- `country-index.json` — per-country indicator values and ranks
- `quiz-pool.json` — quiz countries with preformatted facts

The dataset **catalog is baked** into `lib/catalog.dart` (slug/title/topic/unit/source
only). Regenerate it after the site gains new datasets:

```sh
cd ~/Projects/bulldozer   # site repo
npm run build             # refresh dist/data
node tools/gen_catalog.mjs   # run from this repo
```

## Run

```sh
flutter pub get
flutter run            # device/simulator of choice
flutter run -d macos   # desktop quick check
```
