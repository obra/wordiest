# Wordiest iOS port: Android parity design

Jesse — this document defines “full parity” for the iOS Swift port of the Android app (Wordiest v1.188), and breaks it into testable milestones.

## Goals

- Faithful port of gameplay, UI flow, scoring, rating, history, and cosmetic behavior.
- Use the original shipped assets (`matchdata.packed`, dictionary, font, sounds).
- Keep the codebase pragmatic: small, readable changes; avoid speculative features.

## Non-goals (for now)

- Rebuilding the backend service (`wordiest-service.appspot.com`) — the Android client doesn’t appear to depend on it for core play.
- New art/audio/UX beyond what’s needed for parity.

## Reference behavior (Android v1.188)

Android app structure is a single-activity “stack” that transitions between:

- Splash (`MergedSplash`)
- Match (`MergedMatch`)
- Score (`MergedScore`)
- History (`MergedHistory`)
- Credits/About (`MergedCredits`)

Menu items (popup menu):

- Help
- Remove ads (IAP)
- Sign in / sign out (Google Play Games)
- Enable / disable sound
- Change colors (cycles 1..6)
- Achievements
- Reset rating (also clears history)
- About game
- Privacy policy (opens `https://concreterose.github.io/privacypolicy.html`)

## Product decisions (iOS equivalents)

Android integrations map naturally to iOS, but require external setup:

1) **Local-only parity** (recommended for fastest reliable testing)
   - Implement all offline gameplay + persistence + screens.
   - Stub service integrations behind a feature flag until Apple config exists.
   - Pros: easiest to build/test; no external dependencies.
   - Cons: “Leaders/Achievements/Cloud Save/Remove Ads” are incomplete until later.

2) **Full services parity**
   - Add Game Center, iCloud sync, StoreKit IAP, and (optionally) ads.
   - Pros: closest to shipped Android experience.
   - Cons: requires App Store Connect + entitlement setup; harder to test in CI/simulator.

Plan below assumes (1) first, then (2) as a later milestone.

## Parity matrix (what “full parity” means)

Legend: ✅ done, 🟡 partial, ⬜ todo

### Gameplay: Match screen

- ⬜ Two-word construction from 14 tiles (2 banks of 7) with no tile reuse across words.
- 🟡 Drag-and-drop tiles with snapping and “bring-to-front” behavior while dragging.
- ⬜ Tile scaling while dragging (~1.25x) and overshoot animation on placement.
- ⬜ Shuffle:
  - Only shuffles tiles in banks.
  - Avoids leaving first/last tiles unchanged in trivial cases (see Android shuffle logic).
- ⬜ Reset:
  - Tap Reset: clears both word rows back into banks.
  - Long-press Reset: only clears rows that are currently invalid words.
  - If nothing is cleared, Reset acts like Shuffle.
- ⬜ Word validity is dictionary-driven; invalid shows “Not a word.”
- ⬜ Definition display:
  - Shows formatted definition (with points and “see …” when applicable).
  - Animates definition expand/collapse.
  - Tapping a valid definition prompts to open Wiktionary.
- ⬜ Total score label:
  - Shows sum of valid word scores only.
  - Shows “(best X)” when current < best for this rack.
- ⬜ “Best” restore:
  - Tracks best arrangement during the current rack.
  - Tapping the score restores the best arrangement when current is worse.
- ⬜ Submit behavior:
  - Submit confirmation dialog differs for 0/1/2 valid words.
  - Submitting from review mode is disabled (review uses “OK” button).
- ⬜ Back navigation:
  - If in-progress (either word row non-empty), warns before leaving match.

### Splash / navigation

- ⬜ Splash summary (games played, cumulative score, rating) with first-run message.
- ⬜ Buttons: Play, History, Leaders, plus menu button.
- ⬜ “Loading…” state disables buttons until assets are ready.
- ⬜ Gesture: fling on splash triggers Play (Android uses a left-ish fling).

### Score screen (rating + opponent graph)

- ⬜ Displays submitted tiles as “WORD1 + WORD2” row (includes a “+” tile if two words).
- ⬜ Score summary: “You scored X points, beating Y% of other players.”
- ⬜ Rating summary text:
  - First rating, gain, loss, none.
  - Challenge-mode copy (“Challenges do not affect rating.”) if applicable.
- ⬜ Upset/expected counts:
  - “You beat N higher rated players.” etc.
- ⬜ ScoreGraph:
  - Scatter plot of up to 100 opponents for the rack.
  - Center is always the player.
  - Quadrants are shaded (background/faded).
  - Nearest-point selection while dragging over the graph.
- ⬜ Opponent inspector:
  - Touch opens a popup/overlay.
  - Shows opponent words’ definitions and combined score.
  - Highlight point on graph for selected opponent.
- ⬜ Fireworks/confetti:
  - Trigger when the player has zero “losses” vs the 100 samples.

### History screen

- ⬜ List of past matches (max 100 stored).
- ⬜ Row summary includes words, points, rating delta, and “*” if best vs samples.
- ⬜ Timestamp uses “pretty time” (e.g., “3 hours ago”) based on GMT timestamps.
- ⬜ Tap row opens Score in review mode for that historical match.
- ⬜ Long-press row deletes match (confirmation dialog).
- ⬜ Sparkline:
  - Shows rating over time and highlights visible-range in the list.
  - Marks abnormal deltas in red (delta mismatch vs expected delta).
  - Dragging on header scrubs list position.

### Credits / About

- ⬜ Static credits text (HTML-ish formatting).
- ⬜ Footer shows version + userId + numMatches + rating/ratingDeviation (debug-ish).
- ⬜ Long-press footer opens a dictionary lookup dialog (debug tool).

### Help

- ⬜ Help modal with swipeable pages:
  - Playing
  - Scoring
  - History
  - Sharing (sign-in)

### Settings / cosmetic parity

- ⬜ Color palettes 1..6 (background/foreground/faded) applied consistently.
- ⬜ Sound enabled/disabled toggle in menu (persisted).
- ⬜ Portrait-first layout with responsive scaling.

### Persistence + data flow

- ⬜ Match selection (“upcoming matches”):
  - Reads from `matchdata.packed` locally.
  - Maintains a persistent “next index” counter.
  - First run seeds start index using `nextScatter` (persisted float; random if unset).
- ⬜ Rating update:
  - Uses up to first 100 score samples from rack.
  - Computes percentile and moving-average rating update (alpha=0.2).
  - Rating stored to persistent user data.
- ⬜ Match history store:
  - Stores match_id, match_data JSON, score_list JSON, words encoding, score, rating, new rating, percentile, timestamp, etc.
  - Bounded to 100 entries and supports deletion.
- ⬜ Cloud merge logic (later milestone if we do iCloud):
  - Android merges user data and history from a cloud snapshot.
  - iOS should merge deterministically and avoid clobbering newer local items.

### Social / monetization parity (optional until App Store setup exists)

- ⬜ Leaders: Game Center leaderboards (maps Android’s 3 leaderboards).
- ⬜ Achievements: Game Center achievements (maps Android’s achievements).
- ⬜ Cloud save: iCloud sync for user data + history.
- ⬜ Remove ads: StoreKit purchase toggles ads off permanently.
- ⬜ Ads: banner + (optional) interstitial cadence.

## Proposed milestone plan

### Milestone 1 — “Match parity”

Target: Match screen feels indistinguishable from Android.

- Implement shuffle/reset/best-restore/definitions/Wiktionary prompt.
- Implement submit warnings + review-mode “OK” behavior.
- Add sound toggle and persist it.
- Add palette cycling and apply to tiles/labels/backgrounds.

Acceptance:
- For a fixed match, iOS scoring matches Android for any tile arrangement.
- Long-press Reset preserves valid words only.
- Tapping the score restores the best arrangement.

### Milestone 2 — “Score + rating parity”

Target: Score screen matches Android math + interaction.

- Port ScoreGraph behavior and opponent inspector.
- Implement rating update + summary strings.
- Add fireworks trigger.

Acceptance:
- For a known rack + score list, percentile and new rating match Android to 0.1.
- Graph point selection chooses the same nearest sample as Android (within tolerance).

### Milestone 3 — “History parity”

Target: You can play, submit, and browse history like Android.

- Implement history database, list, deletion, and review entry flow.
- Implement sparkline with selection highlight and abnormal delta coloring.

Acceptance:
- After N games, history list ordering and summary text match Android behavior.

### Milestone 4 — “Shell parity”

Target: Whole app feels like Wordiest.

- Splash summary + loading gating.
- Help modal pages.
- Credits/about, including debug lookup gesture.
- Privacy policy menu action.

### Milestone 5 — “Services parity” (requires Jesse decision + Apple setup)

- Game Center (leaders + achievements).
- iCloud sync (user data + history).
- StoreKit “Remove Ads” and ad presentation if desired.

## Testing strategy

- Keep game logic in `WordiestCore` with unit tests for:
  - matchdata parsing
  - move encoding/decoding
  - scoring (including bonuses)
  - rating update math
  - dictionary/redirect behavior
- Add a small set of “golden” fixtures:
  - Match id 0 tiles and at least 2 known best moves.
  - A handful of definition lookups (present/absent/redirect).
- Add minimal UI tests only where deterministic (navigation, button presence).

## Open questions

- Do we implement ads at all on iOS, or treat “Remove ads” as a no-op and omit ads entirely?
- Do we want iCloud save to mirror Android’s merge rules exactly, or is “latest wins” acceptable?

