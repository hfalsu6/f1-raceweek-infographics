# n8n integration contract

This is the only doc the n8n workflow needs to follow. Stick to these rules and the site will keep working.

## What n8n writes

For every race weekend, n8n writes between **two and four files** to this repo via the GitHub Git Data API (same atomic-commit pattern used by the Graveyard workflow):

### Pre-race run (Thursday morning AEST)

1. **`data/current-race.json`** — overwrite with the new race's pre-race payload. Schema below.
2. **`data/post-race.json`** — overwrite with the empty shell:
   ```json
   { "phase": "post", "race": null, "published_at": null }
   ```
   This resets the post-race state so the auto-flip on `index.html` shows pre-race during the build-up week.
3. **`data/archive/{YYYY}/round-{NN}-{slug}-pre.json`** — write a copy of the same pre-race payload. Immutable archive.

### Post-race run (Sunday night AEST, ~2h after race finish)

1. **`data/post-race.json`** — overwrite with the post-race payload. Schema TBD (see post-race step).
2. **`data/archive/{YYYY}/round-{NN}-{slug}-post.json`** — archive copy.

The `current-race.json` file is **not** touched on the post-race run — it stays as the pre-race snapshot. The auto-flip logic compares `post-race.published_at` against `current-race.race.date_end` to decide which page to serve.

## Required fields in current-race.json

The pre-race template will break if any of these are missing. Match this shape exactly:

| Field | Type | Notes |
|---|---|---|
| `phase` | string | Always `"pre"` for current-race.json |
| `round.number` | int | 1–24 |
| `round.total` | int | Total races in season |
| `race.id` | string | Stable identifier, format `{year}-{slug}-gp` (e.g. `2026-miami-gp`). Used by auto-flip to match pre/post for the same weekend. |
| `race.name` | string | Full GP name |
| `race.circuit` | string | Full circuit name |
| `race.circuit_slug` | string | Lowercase slug, must match a file in `assets/tracks/{slug}.svg` |
| `race.country` | string | Country name |
| `race.city` | string | City name |
| `race.cover_title` | string | What appears as the giant cover headline (usually the city, sometimes shortened) |
| `race.date_range` | string | Display string, e.g. "27–29 March 2026" |
| `race.date_start` | string | ISO date YYYY-MM-DD |
| `race.date_end` | string | ISO date YYYY-MM-DD |
| `race.accent_color` | string | Hex colour for the accent. Default `#E10600`. Override per circuit if you want. |
| `track_stats.turns` | int | |
| `track_stats.length_km` | float | |
| `track_stats.lap_record.time` | string | `M:SS.mmm` |
| `track_stats.lap_record.driver` | string | Short form, e.g. "L. Hamilton" |
| `track_stats.lap_record.year` | int | |
| `track_stats.character_note` | string | One-line editorial flavour, ~60–100 chars |
| `sessions[]` | array | Exactly 5 entries: FP1, FP2, FP3 (or Sprint Quali), Qualifying (or Sprint), Race. Each has `name`, `riyadh`, `local`. The Race entry must have `is_main: true`. |
| `session_offsets.riyadh` | string | `"AST"` |
| `session_offsets.local` | string | Local circuit timezone abbrev (e.g. `"JST"`, `"GST"`, `"EDT"`) |
| `tires[]` | array | 3 entries. Each `compound` (e.g. `"C2"`), `label` (`"HARD"`/`"MEDIUM"`/`"SOFT"`), `color` (`"white"`/`"yellow"`/`"red"` — must match the label) |
| `weather[]` | array | 3 entries. `day` is `"FRI"`/`"SAT"`/`"SUN"`. `icon` is one of: `sun`, `cloud`, `rain`, `wind`. `high_c`, `rain_pct`, `wind_kmh` numeric. |
| `drivers[]` | array | 5 entries. `pos`, `name`, `team_color` (hex), `points`, `gap` (0 for leader) |
| `constructors[]` | array | 5 entries. `pos`, `name`, `color` (hex), `points`, `gap` |
| `storylines[]` | array | 2–3 entries. Each `headline`, `blurb`, `tag` (e.g. `"CHAMPIONSHIP"`, `"TECHNICAL"`, `"DRIVER MARKET"`) |
| `things_to_watch` | string | Single editorial paragraph, ~30–50 words |
| `generated_at` | string | ISO date — when the data was assembled |
| `published_at` | string | ISO datetime with timezone — when n8n committed it |
| `sources` | string | Display string for footer |

## Track SVG requirement

`race.circuit_slug` must match a file at `assets/tracks/{slug}.svg`. If the file is missing the page will show a "track map missing" message instead of the map. Add new tracks via the script below before the workflow runs for that circuit.

Slug suggestions (matches the typical f1db naming):
`bahrain · jeddah · albert-park · suzuka · shanghai · miami · imola · monaco · barcelona · montreal · red-bull-ring · silverstone · hungaroring · spa · zandvoort · monza · baku · marina-bay · cota · mexico-city · interlagos · las-vegas · losail · yas-marina`

## How n8n should commit

Use the **GitHub Git Data API** for atomic multi-file commits — same pattern as the Graveyard workflow. One commit per run. Don't use the Contents API (one-file-at-a-time produces multiple commits and multiple Pages deploys per run, which is wasteful).

Sequence per run:
1. `GET /git/ref/heads/main` → get head SHA
2. Two parallel `POST /git/blobs` calls — one for `current-race.json`, one for the archive copy (and one each for `post-race.json` reset)
3. `POST /git/trees` with `base_tree` set to head SHA, listing all the file paths and blob SHAs
4. `POST /git/commits` with the new tree SHA and the head SHA as parent
5. `POST /git/refs/heads/main` to update the branch pointer

Commit message format:
- Pre-race: `Pre-race: {Race Name} ({date_range})`
- Post-race: `Post-race: {Race Name} — {winner_name}`

GitHub Actions workflow at `.github/workflows/pages.yml` deploys to Pages on every push to `main`. Typical deploy completes in 1–2 minutes.
