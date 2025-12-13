# Wordiest iOS Parity Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Build a faithful iOS (Swift) port of Android Wordiest v1.188 (offline parity, original assets, no ads, no iCloud).

**Architecture:** SwiftUI for navigation + screens, SpriteKit for the Match board (tile drag), and `WordiestCore` (SwiftPM) for deterministic game logic and unit tests (match parsing, definitions, scoring, move encoding, rating math).

**Tech Stack:** Xcode 26+, Swift, SwiftUI, SpriteKit, XCTest, SwiftPM, XcodeGen.

---

## Repo context (what already exists)

- Branch: `wip/ios-port`
- App target: `Wordiest/`
- Core logic package: `WordiestCore/`
- Android parity specs:
  - `docs/plans/2025-12-13-android-parity-design.md`
  - `docs/android-layouts.md`

Current app status (rough):

- You can drag tiles between rows and submit to load next match.
- `matchdata.packed`, dictionary, font, and sounds are in `Wordiest/Resources/`.
- Core parsing/scoring/definitions live in `WordiestCore` with unit tests.

This plan covers **the remaining work to reach Android parity**.

---

## Non-goals

- Ads / “Remove ads” IAP.
- iCloud/online cloud save.
- Rebuilding the original backend service (`wordiest-service.appspot.com`).

---

## Build + test commands (known-good in this repo)

**Regenerate Xcode project (when `project.yml` changes):**

Run: `xcodegen generate`
Expected: Generates/updates `Wordiest.xcodeproj`.

**Run WordiestCore tests:**

Run: `swift test --package-path WordiestCore --disable-sandbox`
Expected: PASS.

**Build app (Simulator):**

Run: `xcodebuild -project Wordiest.xcodeproj -scheme Wordiest -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath ./.derivedData build`
Expected: `BUILD SUCCEEDED`.

If SwiftPM/Xcode tries writing outside the repo, use the repo-local dirs already present:

```bash
export SWIFTPM_CACHE_PATH="$PWD/.swiftpm-cache"
export SWIFTPM_CONFIG_DIR="$PWD/.swiftpm-config"
export SWIFTPM_SECURITY_DIR="$PWD/.swiftpm-security"
```

---

## Milestone structure

- Milestone 1: Match parity (feel + rules)
- Milestone 2: Score + rating parity (math + graph + opponent inspector)
- Milestone 3: History parity (store + list + sparkline + review flow)
- Milestone 4: Shell parity (splash + help + credits + menu + privacy)
- Milestone 5 (optional): Game Center leaders/achievements

Every task below is written to be **small**, **test-first**, and **commit-driven**.

---

## Milestone 1 — Match parity

### Task 1: Add move encoding (SubsetEncoding) to WordiestCore

**Why:** Android uses a base-16 “nibble stream” encoding to represent up to two words using tile indices; we need it for:

- decoding opponent samples (`ScoreSample.wordsEncoding`)
- storing player submissions for history

**Files:**
- Create: `WordiestCore/Sources/WordiestCore/SubsetEncoding.swift`
- Test: `WordiestCore/Tests/WordiestCoreTests/SubsetEncodingTests.swift`

**Step 1: Write failing tests**

Test vectors (mirrors Android `SubsetEncoding` and the `w` sample encoding rules):

```swift
import XCTest
@testable import WordiestCore

final class SubsetEncodingTests: XCTestCase {
    func testDecodeNibbleStreamIntoTileIndices() throws {
        // nibble stream: 1,2,3, F, 4,5  (1-based indices)
        let encoded: UInt64 = 0x123F45
        let decoded = try SubsetEncoding.decode(encoded, tileCount: 14)
        XCTAssertEqual(decoded.word1, [0, 1, 2])
        XCTAssertEqual(decoded.word2, [3, 4])
    }
}
```

**Step 2: Run test to verify FAIL**

Run: `swift test --package-path WordiestCore --disable-sandbox`
Expected: FAIL (missing `SubsetEncoding`).

**Step 3: Minimal implementation**

Implement:
- `decode(_:tileCount:) -> (word1:[Int], word2:[Int])` converting 1-based nibbles to 0-based indices and splitting on `0xF`.
- `encode(word1:word2:) -> UInt64` (needed for saving submissions).

**Step 4: Run tests to verify PASS**

Run: `swift test --package-path WordiestCore --disable-sandbox`
Expected: PASS.

**Step 5: Commit**

```bash
git add WordiestCore/Sources/WordiestCore/SubsetEncoding.swift WordiestCore/Tests/WordiestCoreTests/SubsetEncodingTests.swift
git commit -m "core: add subset encoding for two-word moves"
```

---

### Task 2: Add match-level “best” tracking + restore behavior

**Why:** Android tracks a “best score so far” for the rack and restores it when you tap the score label.

**Files:**
- Create: `Wordiest/Match/BestTracker.swift`
- Modify: `Wordiest/GameScene.swift`
- Test: `WordiestTests/BestTrackerTests.swift`

**Step 1: Write failing tests**

`BestTracker` should store the best arrangement based on:
- word1 indices
- word2 indices
- bank assignments (or “everything else”)

Minimal model for tests:

```swift
struct RackState: Equatable {
    var word1: [Int]
    var word2: [Int]
    var bank1: [Int]
    var bank2: [Int]
}
```

Test:

```swift
final class BestTrackerTests: XCTestCase {
    func testTracksBestScoreAndRestoresWhenCurrentIsWorse() throws {
        let tracker = BestTracker()
        let stateA = RackState(word1: [0,1], word2: [], bank1: [2,3,4], bank2: [5,6,7,8,9,10,11,12,13])
        let stateB = RackState(word1: [0], word2: [], bank1: [1,2,3,4], bank2: [5,6,7,8,9,10,11,12,13])

        tracker.observe(state: stateA, bestScoreCandidate: 10)
        tracker.observe(state: stateB, bestScoreCandidate: 5)

        XCTAssertEqual(tracker.restoreIfBetterThanCurrent(currentScore: 5), stateA)
        XCTAssertNil(tracker.restoreIfBetterThanCurrent(currentScore: 10))
    }
}
```

**Step 2: Run test to verify FAIL**

Run: `xcodebuild -project Wordiest.xcodeproj -scheme Wordiest -destination 'platform=iOS Simulator,name=iPhone 17' test`
Expected: FAIL (missing `BestTracker`).

**Step 3: Minimal implementation**

Implement `BestTracker` storing:
- `bestScore: Int`
- `bestState: RackState?`

**Step 4: Run tests to verify PASS**

Run: `xcodebuild ... test`
Expected: PASS.

**Step 5: Commit**

```bash
git add Wordiest/Match/BestTracker.swift WordiestTests/BestTrackerTests.swift
git commit -m "match: track and restore best arrangement"
```

---

### Task 3: Fix Shuffle to match Android behavior (banks only + anti-no-op)

**Files:**
- Modify: `Wordiest/GameScene.swift`
- Test: `WordiestTests/ShuffleTests.swift`

**Step 1: Write failing test**

Extract shuffle algorithm into a pure function for determinism:

- Create (or add to) `Wordiest/Match/Shuffle.swift` (pure Swift).
- Test that shuffle only permutes **bank tiles**, keeps word rows intact.
- Test “anti-no-op”: for N>1, it should not leave all tiles in the same order in trivial cases.

**Step 2: Run test to verify FAIL**

Run: `xcodebuild ... test`
Expected: FAIL.

**Step 3: Implement**

- Port Android logic from `MergedMatch.onShuffle()` (keep the “avoid first tile unchanged / avoid last tile unchanged” behavior).
- Update `GameScene.shuffle()` to:
  - only move tiles in `.bank1` and `.bank2`
  - keep `.word1` and `.word2` as-is

**Step 4: Run tests to verify PASS**

Run: `xcodebuild ... test`
Expected: PASS.

**Step 5: Commit**

```bash
git add Wordiest/GameScene.swift Wordiest/Match/Shuffle.swift WordiestTests/ShuffleTests.swift
git commit -m "match: shuffle banks only with Android anti-no-op behavior"
```

---

### Task 4: Add Reset long-press behavior (clear invalid words only)

**Files:**
- Modify: `Wordiest/ContentView.swift`
- Modify: `Wordiest/GameScene.swift`
- Test: `WordiestTests/ResetTests.swift`

**Step 1: Write failing tests**

Tests should verify:
- Reset tap clears both word rows.
- Reset long-press clears only rows whose current word is invalid (dictionary says nil).
- If nothing gets cleared, it behaves like Shuffle.

**Step 2: Run tests to verify FAIL**

Run: `xcodebuild ... test`
Expected: FAIL.

**Step 3: Implement**

- Add `resetWords(mode:)` or `resetWords(clearOnlyInvalid:)`.
- In SwiftUI, add a long-press gesture to the Reset button:

```swift
Button("Reset") { scene.resetWords(clearOnlyInvalid: false) }
    .simultaneousGesture(
        LongPressGesture(minimumDuration: 0.35).onEnded { _ in
            scene.resetWords(clearOnlyInvalid: true)
        }
    )
```

**Step 4: Run tests to verify PASS**

Run: `xcodebuild ... test`
Expected: PASS.

**Step 5: Commit**

```bash
git add Wordiest/ContentView.swift Wordiest/GameScene.swift WordiestTests/ResetTests.swift
git commit -m "match: implement reset and long-press reset-invalid-only"
```

---

### Task 5: Make scoring/labels match Android strings and plurals

**Files:**
- Create: `Wordiest/Match/Strings.swift`
- Modify: `Wordiest/GameScene.swift`
- Test: `WordiestTests/ScoreLabelTests.swift`

**Step 1: Write failing tests**

Test the score label text formatting:
- `"Total 1 point"`
- `"Total 2 points"`
- `"Total 10 points (best 12)"` when current < best

**Step 2: Run tests to verify FAIL**

Run: `xcodebuild ... test`
Expected: FAIL.

**Step 3: Implement**

Implement a small formatter:

```swift
enum MatchStrings {
    static func totalScore(_ score: Int) -> String { ... }
    static func totalScoreWithBest(_ score: Int, best: Int) -> String { ... }
}
```

Update `GameScene.updateScoreAndDefinitions()` to use it and `BestTracker`.

**Step 4: Run tests to verify PASS**

**Step 5: Commit**

```bash
git add Wordiest/Match/Strings.swift Wordiest/GameScene.swift WordiestTests/ScoreLabelTests.swift
git commit -m "match: match Android score label formatting and best suffix"
```

---

### Task 6: Add Wiktionary prompt and open behavior

**Files:**
- Create: `Wordiest/Wiktionary.swift`
- Modify: `Wordiest/ContentView.swift`
- Modify: `Wordiest/GameScene.swift`

**Step 1: Decide interaction surface**

Android triggers prompt by tapping a displayed valid definition. On iOS:
- Detect taps on `definition1Label` / `definition2Label` in `GameScene`.
- Call a callback `onRequestOpenWiktionary(word:)` set by SwiftUI.

**Step 2: Implement minimal prompt**

In SwiftUI, present `.alert`:
- Message: `Search '<word>' in Wiktionary?`
- OK opens `http://en.m.wiktionary.org/wiki/<word>#English` via `UIApplication.shared.open`.

**Step 3: Manual verification**

Run app; tap a valid definition; confirm alert; opens Safari.

**Step 4: Commit**

```bash
git add Wordiest/Wiktionary.swift Wordiest/ContentView.swift Wordiest/GameScene.swift
git commit -m "match: add Wiktionary open prompt"
```

---

### Task 6.1: Add submit confirmation dialogs (0/1/2 valid words) and review-mode submit behavior

**Why:** Android warns before submitting depending on how many valid words you have, and review matches cannot be re-submitted.

**Files:**
- Create: `Wordiest/Match/SubmissionWarning.swift`
- Modify: `Wordiest/ContentView.swift` (or `Wordiest/Match/MatchView.swift` once navigation is in place)
- Modify: `Wordiest/GameScene.swift`
- Test: `WordiestTests/SubmissionWarningTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import Wordiest

final class SubmissionWarningTests: XCTestCase {
    func testWarningMessageForValidWordCount() {
        XCTAssertEqual(SubmissionWarning.message(validWordCount: 0), "Submit no words?")
        XCTAssertEqual(SubmissionWarning.message(validWordCount: 1), "Submit only one word?")
        XCTAssertEqual(SubmissionWarning.message(validWordCount: 2), "Submit these words?")
    }
}
```

**Step 2: Run test to verify FAIL**

Run: `xcodebuild -project Wordiest.xcodeproj -scheme Wordiest -destination 'platform=iOS Simulator,name=iPhone 17' test`
Expected: FAIL.

**Step 3: Minimal implementation**

- Add `SubmissionWarning.message(validWordCount:) -> String?` returning nil for unexpected counts.
- In `GameScene`, add a method that returns `validWordCount` and the words:
  - `currentWords() -> (word1: String, word2: String)`
  - `currentValidWordCount() -> Int`
- In SwiftUI, wrap Submit in an `.alert` confirmation using the message above.
- Add `GameScene.isReview` flag:
  - If `isReview == true`, replace “Submit” button label with “OK” and do not advance matches.

**Step 4: Run tests to verify PASS**

**Step 5: Commit**

```bash
git add Wordiest/Match/SubmissionWarning.swift Wordiest/ContentView.swift Wordiest/GameScene.swift WordiestTests/SubmissionWarningTests.swift
git commit -m "match: add submit warnings and review-mode submit behavior"
```

---

### Task 6.2: Add “warn before leaving match in progress”

**Why:** Android prompts “Leave game in progress?” when backing out of a match with tiles placed.

**Files:**
- Modify: `Wordiest/ContentView.swift` (or `Wordiest/Match/MatchView.swift`)
- Modify: `Wordiest/GameScene.swift`

**Steps:**
1. Add `GameScene.hasInProgressMove -> Bool` (true if either word row is non-empty).
2. When navigating away from Match screen (back, switching tabs, etc.), if `hasInProgressMove` is true, show a confirmation dialog.
3. Manual verification: place a tile, try to navigate back, confirm prompt appears.

**Commit:**

```bash
git add Wordiest/ContentView.swift Wordiest/GameScene.swift
git commit -m "match: warn before leaving in-progress game"
```

---

### Task 6.3: Match Android drag scaling + “overshoot” feel

**Why:** Android scales the tile up while dragging (~1.25x) and uses overshoot interpolators for placement animations.

**Files:**
- Modify: `Wordiest/GameScene.swift`
- Test: `WordiestTests/DragScaleTests.swift`

**Step 1: Write failing test**

Extract a tiny constant into a testable place:

- Create `Wordiest/Match/DragConstants.swift` with:
  - `static let draggingScaleMultiplier: CGFloat = 1.25`

Test:

```swift
final class DragScaleTests: XCTestCase {
    func testDraggingScaleMultiplierMatchesAndroid() {
        XCTAssertEqual(DragConstants.draggingScaleMultiplier, 1.25, accuracy: 0.0001)
    }
}
```

**Step 2–5: Implement + commit**

- On touch down: scale tile to `currentRowScale * draggingScaleMultiplier`.
- On drop: animate move + scale back to row scale with a spring/overshoot timing.

Commit:

```bash
git add Wordiest/GameScene.swift Wordiest/Match/DragConstants.swift WordiestTests/DragScaleTests.swift
git commit -m "match: add Android-like drag scaling and overshoot animations"
```

---

## Milestone 2 — Score + rating parity

### Task 7: Port Android rating update math (UpdateRating) into WordiestCore

**Files:**
- Create: `WordiestCore/Sources/WordiestCore/UpdateRating.swift`
- Test: `WordiestCore/Tests/WordiestCoreTests/UpdateRatingTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import WordiestCore

final class UpdateRatingTests: XCTestCase {
    func testCeilTenths() {
        XCTAssertEqual(UpdateRating.ceilTenths(12.30), 12.3)
        XCTAssertEqual(UpdateRating.ceilTenths(12.31), 12.4)
        XCTAssertEqual(UpdateRating.ceilTenths(0.01), 0.1)
    }

    func testUpdateComputesPercentileAndNewRating() {
        var update = UpdateRating(rating: 50.0, ratingDeviation: 0.0)
        // Two opponents: one higher score, one lower score. Both rated above us.
        let samples: [UpdateRating.ScoreRating] = [
            .init(score: 10, rating: 60.0, wordsEncoding: nil),
            .init(score: 30, rating: 60.0, wordsEncoding: nil),
        ]
        update.update(playerScore: 20, opponents: samples)

        XCTAssertEqual(update.percentile, 50.0) // one of two scores <= 20
        XCTAssertEqual(update.newRating, 50.0)  // 0.2*50 + 0.8*50
    }
}
```

**Step 2: Run test to verify FAIL**

Run: `swift test --package-path WordiestCore --disable-sandbox`
Expected: FAIL (missing `UpdateRating`).

**Step 3: Minimal implementation**

Port Android `UpdateRating` exactly:

- `ALPHA = 0.2`
- `percentile = ceilTenths(100 * wins / total)`
- `newRating = ceilTenths(percentile * ALPHA + rating * 0.8)`
- track `upsetWins`, `expectedWins`, `upsetLosses`, `expectedLosses`

**Step 4: Run tests to verify PASS**

Run: `swift test --package-path WordiestCore --disable-sandbox`
Expected: PASS.

**Step 5: Commit**

```bash
git add WordiestCore/Sources/WordiestCore/UpdateRating.swift WordiestCore/Tests/WordiestCoreTests/UpdateRatingTests.swift
git commit -m "core: port rating update math"
```

---

### Task 8: Introduce a Score screen view model + summary strings

**Files:**
 - Create: `Wordiest/Score/ScoreSummary.swift`
 - Create: `Wordiest/Score/ScoreViewModel.swift`
 - Test: `WordiestTests/ScoreSummaryTests.swift`

**Behavior to match Android:**
- Score summary: “You scored X point(s), beating Y% of other players.”
- Rating summary: first/gain/loss/none strings
- Upset/expected counts (4 quadrants)

**Step 1: Write failing tests**

```swift
import XCTest
@testable import Wordiest

final class ScoreSummaryTests: XCTestCase {
    func testScoreSummaryPluralization() {
        XCTAssertEqual(ScoreSummary.scoreText(score: 1, percentile: 50), "You scored 1 point, beating 50% of other players.")
        XCTAssertEqual(ScoreSummary.scoreText(score: 2, percentile: 50), "You scored 2 points, beating 50% of other players.")
    }

    func testRatingSummaryGainLossNone() {
        XCTAssertEqual(ScoreSummary.ratingText(old: 50.0, new: 51.2, matchCount: 5), "Your 50.0 rating grew by 1.2 to 51.2!")
        XCTAssertEqual(ScoreSummary.ratingText(old: 50.0, new: 48.8, matchCount: 5), "Your 50.0 rating fell by 1.2 to 48.8.")
        XCTAssertEqual(ScoreSummary.ratingText(old: 50.0, new: 50.0, matchCount: 5), "No rating change, still 50.0.")
        XCTAssertEqual(ScoreSummary.ratingText(old: 0.0, new: 50.0, matchCount: 0), "Your new rating is 50.0!")
    }
}
```

**Step 2: Run test to verify FAIL**

Run: `xcodebuild -project Wordiest.xcodeproj -scheme Wordiest -destination 'platform=iOS Simulator,name=iPhone 17' test`
Expected: FAIL (missing `ScoreSummary`).

**Step 3: Minimal implementation**

In `Wordiest/Score/ScoreSummary.swift`, implement:

```swift
enum ScoreSummary {
    static func scoreText(score: Int, percentile: Int) -> String { ... }
    static func ratingText(old: Double, new: Double, matchCount: Int) -> String { ... }
}
```

**Step 4: Run tests to verify PASS**

**Step 5: Commit**

```bash
git add Wordiest/Score/ScoreSummary.swift WordiestTests/ScoreSummaryTests.swift
git commit -m "score: add summary string formatting"
```

---

### Task 9: Implement ScoreGraphView (SwiftUI Canvas) with Android mapping rules

**Files:**
- Create: `Wordiest/Score/ScoreGraphView.swift`
- Create: `Wordiest/Score/ScoreGraphMath.swift`
- Test: `WordiestTests/ScoreGraphMathTests.swift`

**Must match Android mapping:**
- `recomputeMinMaxEvenlyFromCenter` algorithm (see `decompile/.../ScoreGraphView.java:129`)
- Quadrant shading and axis label coloring
- Highlight color is red
- Nearest-point selection uses mapped points space

**Implementation notes:**
- For up to 100 points, brute-force nearest search is fine; no kd-tree needed.

**Step 1: Write failing tests**

```swift
import XCTest
@testable import Wordiest

final class ScoreGraphMathTests: XCTestCase {
    func testRecomputeMinMaxEvenlyFromCenterMatchesAndroidShape() {
        let values: [Double] = [50, 49, 51, 60, 40, 55, 45, 48, 52]
        let span = ScoreGraphMath.recomputeMinMaxEvenlyFromCenter(values, center: 50)
        XCTAssertGreaterThan(span, 0)
        XCTAssertEqual(ScoreGraphMath.minMax(center: 50, span: span).min, 50 - span)
    }
}
```

**Step 2: Run tests to verify FAIL**

Run: `xcodebuild -project Wordiest.xcodeproj -scheme Wordiest -destination 'platform=iOS Simulator,name=iPhone 17' test`
Expected: FAIL (missing `ScoreGraphMath`).

**Step 3: Minimal implementation**

Port the algorithm directly:
- sort values
- take 1/8 and 7/8 quantiles
- expand by 1.5x
- compute symmetric max distance from center to (clamped) extremes

Also implement:
- `mapX`, `mapY`
- `nearestPointIndex(inScreenSpace:)`

**Step 4: Run tests to verify PASS**

**Step 5: Commit**

```bash
git add Wordiest/Score/ScoreGraphMath.swift Wordiest/Score/ScoreGraphView.swift WordiestTests/ScoreGraphMathTests.swift
git commit -m "score: add score graph mapping and rendering"
```

---

### Task 10: Implement opponent inspector overlay

**Files:**
- Create: `Wordiest/Score/OpponentInspectorView.swift`
- Create: `Wordiest/Score/ScoreView.swift`
- Modify: `Wordiest/Navigation/AppRoute.swift` (if needed)

**Behavior:**
- Touch/drag on graph opens overlay.
- Overlay shows opponent words + definitions + total score.
- Graph highlights the selected point.

**Step 1: Add a decoding helper for opponent moves**

If not already present from Task 1, add a helper that returns the actual word strings:

- Use `SubsetEncoding.decode(...)` to get tile indices.
- Map indices to `Match.tiles` to produce word strings and tile arrays.

**Step 2: Implement overlay view**

Overlay should show (Android parity):
- decoded tiles row (“WORD1 + WORD2”)
- definition blocks (up to two)
- total score line

**Step 3: Manual verification**

Run app, go to Score screen, drag across graph, confirm overlay updates and highlight moves.

**Step 4: Commit**

```bash
git add Wordiest/Score/ScoreView.swift Wordiest/Score/OpponentInspectorView.swift
git commit -m "score: add opponent inspector overlay"
```

---

## Milestone 3 — History parity

### Task 11: Add HistoryStore (local, bounded to 100)

**Files:**
- Create: `Wordiest/History/HistoryStore.swift`
- Create: `Wordiest/History/HistoryEntry.swift`
- Test: `WordiestTests/HistoryStoreTests.swift`

**Storage approach (simple, no over-engineering):**
- Store JSON in `Application Support/wordiest-history.json`.
- Keep max 100 entries (drop oldest).

**Entry fields to preserve parity:**
- `matchId`, `matchData` (tiles JSON), `scoreList` (samples JSON)
- `wordsEncoding` (UInt64), `score`
- `ratingX10`, `newRatingX10`, `percentileX10`
- `timestamp` (GMT string `yyyy-MM-dd HH:mm:ss`)

**Step 1: Write failing tests**

Tests should verify:
- append keeps newest-first ordering
- capacity trims oldest beyond 100
- delete removes the entry
- persistence round-trips

**Step 2–5:** Implement store + commit.

Commit:

```bash
git add Wordiest/History/HistoryEntry.swift Wordiest/History/HistoryStore.swift WordiestTests/HistoryStoreTests.swift
git commit -m "history: add local history store"
```

---

### Task 12: History list UI + delete + review flow

**Files:**
- Create: `Wordiest/History/HistoryView.swift`
- Create: `Wordiest/History/HistoryRowView.swift`
- Modify: `Wordiest/Navigation/AppRoute.swift`

**Behavior:**
- Tap row opens Score screen in review mode.
- Long-press row prompts delete; deletes and updates sparkline.

**Step 1: Implement row summary formatting**

Match Android’s:
- `"WORDS (X pt(s), +Y.Y rtg)"` with `*` appended if this was a “best” score for that rack (no opponent had higher score).

**Step 2: Add delete confirmation**

Use `.confirmationDialog` or `.alert` to match “Delete history item?”.

**Step 3: Commit**

```bash
git add Wordiest/History/HistoryView.swift Wordiest/History/HistoryRowView.swift
git commit -m "history: add history list and delete flow"
```

---

### Task 13: Sparkline UI (SwiftUI Canvas) + highlight range + scrub

**Files:**
- Create: `Wordiest/History/SparklineView.swift`
- Create: `Wordiest/History/SparklineMath.swift`
- Test: `WordiestTests/SparklineMathTests.swift`

**Behavior:**
- Rating min/max round to tens (floor/ceil).
- Highlight currently visible list range.
- Mark abnormal deltas in red (Android uses `abs(expectedDelta - actualDelta) >= 0.1`).
- Drag across header scrubs list position.

**Step 1: Write failing tests**

Test:
- min/max rounding
- abnormal delta detection

**Step 2–5:** Implement + commit.

---

## Milestone 4 — Shell parity
---

## Milestone 4 — Shell parity

### Task 14: Add Splash screen and navigation

**Files:**
- Create: `Wordiest/Splash/SplashView.swift`
- Modify: `Wordiest/ContentView.swift`
- Create: `Wordiest/Navigation/AppModel.swift`

**Behavior:**
- Shows summary: num games, cumulative points, rating (or first-run copy).
- Buttons: Play / History / Leaders + menu.
- Loading gate (disable buttons until assets loaded).

**Step 1: Create a central `AppModel`**

`AppModel` owns:
- `AppSettings` (palette, sound, rating stats, next match index/scatter)
- `HistoryStore`
- current route (`splash`, `match`, `score`, `history`, `credits`, `help`)
- current match bundle (match id + match tiles + score list)

**Step 2: Refactor `ContentView`**

Replace the single-screen ZStack with a route switch:

- SplashView
- MatchView (SpriteView hosting GameScene)
- ScoreView
- HistoryView
- CreditsView
- HelpView

**Step 3: Commit**

```bash
git add Wordiest/Navigation/AppModel.swift Wordiest/ContentView.swift Wordiest/Splash/SplashView.swift
git commit -m "shell: add splash and navigation model"
```

---

### Task 15: Add Credits/About screen + debug lookup gesture

**Files:**
- Create: `Wordiest/Credits/CreditsView.swift`
- Create: `Wordiest/Credits/DictionaryLookupView.swift`

**Behavior:**
- Shows credits HTML-ish content.
- Footer line shows version + userId + numMatches + rating.
- Long-press footer opens a lookup prompt and shows definition (toast-style or alert).

**Commit:**

```bash
git add Wordiest/Credits/CreditsView.swift Wordiest/Credits/DictionaryLookupView.swift
git commit -m "shell: add credits and dictionary lookup tool"
```

---

### Task 16: Add Help screen (paged)

**Files:**
- Create: `Wordiest/Help/HelpView.swift`
- Create: `Wordiest/Help/HelpPages.swift`

**Behavior:**
- Paged UI with titles: Playing / Scoring / History / Sharing
- Copy sourced from Android strings (no need for pixel-perfect layout, but content parity).

**Commit:**

```bash
git add Wordiest/Help/HelpView.swift Wordiest/Help/HelpPages.swift
git commit -m "shell: add help pages"
```

---

### Task 17: Add menu + settings parity (sound + palette + reset)

**Files:**
- Create: `Wordiest/Settings/AppSettings.swift`
- Create: `Wordiest/Settings/ColorPalette.swift`
- Modify: `Wordiest/GameScene.swift`
- Modify: all SwiftUI screens to present the menu

**Behavior:**
- Palette cycles 1..6 (colors ported from Android `colors.xml`).
- Sound enabled/disabled persists; when disabled, do not play pickup/drop.
- “Reset rating”: resets rating + clears history.
- “Privacy policy”: opens `https://concreterose.github.io/privacypolicy.html`.

**Commit:**

```bash
git add Wordiest/Settings/AppSettings.swift Wordiest/Settings/ColorPalette.swift
git commit -m "settings: add palette, sound toggle, and reset actions"
```

---

## Milestone 5 (optional) — Game Center

Implement only if we decide to keep Leaders/Achievements as real online features.

- Leaders: map Android leaderboards to Game Center leaderboards.
- Achievements: map Android achievements to Game Center achievements.

---

## Execution / done criteria

Use the acceptance checklist in `docs/plans/2025-12-13-android-parity-design.md` as the definition of “done”.
