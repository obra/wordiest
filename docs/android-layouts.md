# Android layouts (Wordiest v1.188)

Jesse — this is a full inventory of Android XML layouts from the decompiled APK, grouped into:

- **App layouts**: define Wordiest screens/features we need to port.
- **Library/system layouts**: AppCompat + notification templates; not app-specific.

Source directory: `decompile/apktool2/res/layout/`

## Summary

- Total layout XML files: **60**
- App layouts (Wordiest-specific): **13**
- Library/system layouts (AppCompat/notification/select dialogs/etc.): **47** (includes `tooltip.xml`)

The **only activity** in `AndroidManifest.xml` is `com.concreterose.wordiest.MergedActivity`, which inflates the app layouts below via `fillContentView(R.layout.<screen>)`.

## App layouts (screens + shared components)

### `base_activity.xml`

- File: `decompile/apktool2/res/layout/base_activity.xml`
- Used by: `decompile/jadx/sources/com/concreterose/wordiest/BaseActivity.java` (`setContentView(R.layout.base_activity)`).
- Key IDs:
  - `ad_container`: banner ad container (Android uses AdMob).
  - `fill_into`: the “screen” container where `MergedActivity` inflates each view (splash/match/score/history/credits).
- Port implication: iOS should have a root container and a content container; we can ignore ads initially and treat this as “safe area / top bar” spacing behavior.

### `button_bar.xml`

- File: `decompile/apktool2/res/layout/button_bar.xml`
- Included by: `splash.xml`, `match.xml`, `score.xml`.
- Key IDs:
  - `button_1`, `button_2`, `button_3`: context-dependent labels (Play/History/Leaders, Shuffle/Reset/Submit, etc.).
  - `button_m`: menu button (Android shows a popup menu).
- Port implication: iOS needs a consistent bottom control bar + a menu affordance.

### `splash.xml`

- File: `decompile/apktool2/res/layout/splash.xml`
- Used by: `MergedActivity.createSplash()`.
- Key IDs:
  - `splash_loading`: “Loading…” overlay text (shown while app initializes).
  - `splash_wiktionary_credit`: credit line.
  - `splash_tile_bg`: decorative tile background view (Android overlays a custom `TileView` on top).
  - `splash_summary`: stats summary.
  - `button_bar`: the shared buttons/menu.
- Port implication: need a splash screen with gating (buttons disabled until assets ready) + summary stats + the “Play/History/Leaders” entry points.

### `match.xml`

- File: `decompile/apktool2/res/layout/match.xml`
- Used by: `MergedActivity.createMatch()`.
- Key IDs:
  - `tiles_container`: empty container where Android adds `TileView` instances and animates them.
  - `definition_1a`, `definition_1b`, `definition_2a`, `definition_2b`: animated definition text slots (two per word row).
  - `baseline_1`, `baseline_2`: gradient baseline separators behind the word rows.
  - `player_score`: total/best label (also acts as “tap to restore best”).
  - `match_review`: review-mode banner (visible when replaying history).
  - `button_bar`: shared buttons/menu.
- Port implication: iOS match screen needs (1) a tile scene container, (2) two word rows + definitions, (3) baseline visuals, (4) score label interactions, and (5) review-mode treatment.

### `score.xml`

- File: `decompile/apktool2/res/layout/score.xml`
- Used by: `MergedActivity.createScore()`.
- Key IDs:
  - `score_tile_row`: container where Android lays out tiles showing submitted words (with a “+” tile in between).
  - `rating_summary_layout`:
    - `score_summary` and `rating_summary`
  - Quadrant labels:
    - `quadrant_text_top`: `upset_losses`, `expected_losses`
    - `quadrant_text_bottom`: `expected_wins`, `upset_wins`
  - `score_graph_container`: container where Android adds a custom `ScoreGraphView`.
  - `opponent_summary`: overlay shown while interacting with the graph:
    - `opponent_tiles_container`, `opponent_definition_1`, `opponent_definition_2`, `opponent_score`
  - `button_bar`: shared buttons/menu.
- Port implication: iOS needs a “graph + nearest-point” interaction and an opponent inspector overlay, plus score/rating summary text.

### `history.xml`

- File: `decompile/apktool2/res/layout/history.xml`
- Used by: `MergedActivity.createHistory()` and `MergedHistory`.
- Key IDs:
  - `history_header` containing sparkline UI:
    - `sparkline` (Android adds a custom `SparkLineView`).
    - `sparkline_min_y`, `sparkline_max_y`
    - `sparkline_label`, `sparkline_label_left`, `sparkline_label_right`
  - List:
    - `list_view`: history list
    - `history_empty`: empty-state text
- Port implication: iOS needs a scrollable history list with a header sparkline and scrubbing interaction.

### `history_item.xml`

- File: `decompile/apktool2/res/layout/history_item.xml`
- Used by: `MergedHistory` adapter (`inflate(R.layout.history_item)`).
- Key IDs:
  - `summary`: HTML-formatted match summary (words + points + rating delta, plus “*” best marker).
  - `timestamp`: pretty-time formatted string (“3 hours ago”).
- Port implication: iOS history list rows need both a rich summary and relative timestamp.

### `credits.xml`

- File: `decompile/apktool2/res/layout/credits.xml`
- Used by: `MergedActivity.createCredits()` and `MergedCredits`.
- Key IDs:
  - `credits_header`, `credits`: HTML formatted.
  - `credits_user_data`: debug-ish footer; long-press opens dictionary lookup dialog.
  - `scroll_view`: scroll container.
- Port implication: iOS credits/about screen should preserve the footer long-press “lookup” dev tool for parity.

### Help layouts (used in a ViewPager modal)

#### `help_all.xml`

- File: `decompile/apktool2/res/layout/help_all.xml`
- Used by: `Help.showAll()` (inflates a `ViewPager` + `PagerTitleStrip`).
- Port implication: iOS should present a paged help UI (tabs/pages).

#### `help_match.xml`

- File: `decompile/apktool2/res/layout/help_match.xml`
- Used by: `Help.instantiate(R.layout.help_match, …)`.
- Key IDs:
  - `sample_tiles`: container where `Help` creates sample tiles programmatically.

#### `help_score.xml`

- File: `decompile/apktool2/res/layout/help_score.xml`
- Used by: `Help.instantiate(R.layout.help_score, …)`.
- Key IDs:
  - `quadrants` plus `upset_losses`, `expected_losses`, `expected_wins`, `upset_wins` (a static 2x2 example with axis labels and a centered “you” label).

#### `help_history.xml`

- File: `decompile/apktool2/res/layout/help_history.xml`
- Used by: `Help.instantiate(R.layout.help_history, …)`.

#### `help_sign_in.xml`

- File: `decompile/apktool2/res/layout/help_sign_in.xml`
- Used by:
  - `Help.instantiate(R.layout.help_sign_in, …)`
  - `BaseActivity.doSignIn()` (inflates it inside a dialog)
- Key IDs:
  - `sign_in_button`: Google sign-in control.
- Port implication: even if we defer Game Center, we should still port the help copy and have an iOS-equivalent “sign in” CTA later.

## Library/system layouts (not Wordiest-specific)

These are standard templates from AppCompat / Android framework support libraries and don’t represent unique Wordiest features:

- `abc_*` (AppCompat action bar, dialogs, menus, search)
- `notification_*` (notification templates)
- `select_dialog_*`, `support_simple_spinner_dropdown_item.xml`
- `tooltip.xml` (AppCompat tooltip template; not referenced directly by Wordiest code)

