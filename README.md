# f1-raceweek-infographics

Editorial F1 race-week infographics, generated weekly by [n8n](https://n8n.io) and rendered as a static site on GitHub Pages.

🌐 **Live:** https://hfalsu6.github.io/f1-raceweek-infographics/

## What this repo is

Every race weekend, an n8n workflow:

1. Pulls upcoming race info, standings, weather, tire compounds, news (sources: OpenF1, Pirelli, Open-Meteo, web search via OpenRouter)
2. Composes pre-race data on Thursday morning and post-race data Sunday night
3. Commits a JSON file to this repo
4. GitHub Actions deploys the static site to Pages

The site auto-flips between pre-race and post-race views based on which payload is freshest.

## Repo structure

```
.
├── index.html                  # Auto-flip page (decides pre vs post and redirects)
├── pre-race.html               # Pre-race infographic template (reads ./data/current-race.json)
├── post-race.html              # Post-race template (placeholder for now)
├── assets/
│   ├── css/styles.css          # Shared styles
│   └── tracks/                 # Circuit SVGs, one per slug
│       └── suzuka.svg          # Placeholder — replace via scripts/fetch-track.sh
├── data/
│   ├── current-race.json       # Pre-race payload — overwritten by n8n weekly
│   ├── post-race.json          # Post-race payload — overwritten Sunday night
│   └── archive/{year}/         # Immutable per-race archives (round-NN-slug-{pre|post}.json)
├── scripts/
│   ├── update-race.md          # n8n integration contract — required reading for the workflow
│   └── fetch-track.sh          # Helper to add a circuit SVG
└── .github/workflows/pages.yml # Auto-deploy to GitHub Pages
```

## How the auto-flip works

`index.html` loads both `data/current-race.json` and `data/post-race.json`, then:

- If `post-race.json` exists with a non-null payload, AND its `race.id` matches `current-race.json.race.id` (same weekend), AND its `published_at` is on or after the race's `date_end` → redirect to `post-race.html`
- Otherwise → redirect to `pre-race.html`

This is robust to:
- Late or failed post-race runs (page keeps showing pre-race until post-race actually publishes)
- Off-season visits (last race's post-race remains visible until next pre-race overwrites)
- Network or JSON errors (always falls back to pre-race)

Time math is just ISO date string comparison — no timezone handling needed because both fields are computed in absolute terms.

## Setting up locally

The site is pure static HTML/CSS/JS — no build step. Open `pre-race.html` directly in a browser to preview, but you'll need a local web server because of `fetch()` CORS:

```bash
# from repo root
python3 -m http.server 8000
# then visit http://localhost:8000
```

## Adding a new circuit SVG

```bash
./scripts/fetch-track.sh miami
```

This fetches from [julesr0y/f1-circuits-svg](https://github.com/julesr0y/f1-circuits-svg), normalises the SVG so it tints correctly, and saves to `assets/tracks/miami.svg`. The slug must match what n8n writes to `race.circuit_slug` in the JSON.

## n8n integration

See [`scripts/update-race.md`](./scripts/update-race.md) for the file paths and JSON schema the workflow has to follow.

## Credits & licenses

- Circuit SVGs: [julesr0y/f1-circuits-svg](https://github.com/julesr0y/f1-circuits-svg) — CC BY-SA 4.0
- Race data: [OpenF1](https://openf1.org), [Pirelli](https://www.pirelli.com/tyres/en-gb/motorsport/f1), [Open-Meteo](https://open-meteo.com)
- Fonts: [Fraunces](https://fonts.google.com/specimen/Fraunces), [Inter Tight](https://fonts.google.com/specimen/Inter+Tight), [JetBrains Mono](https://www.jetbrains.com/lp/mono/) — all open licences
- Design: hand-built editorial layout, vibe inspired by *Motor Sport Magazine* / *The Race*
- F1, Grand Prix, and circuit names are trademarks of Formula One Licensing BV — used here for editorial / personal use

This is a personal project, no commercial use, no affiliation with Formula 1 or any team.
