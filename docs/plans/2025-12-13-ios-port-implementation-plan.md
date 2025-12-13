# Wordiest iOS Port Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Build a faithful iOS (Swift) port of the Android “Wordiest” match gameplay using the original shipped assets.

**Architecture:** SpriteKit for tile rendering + touch/drag interactions, with pure Swift model/logic types (scoring, match parsing, dictionary lookup) so the core stays testable.

**Tech Stack:** Xcode, Swift, SwiftUI container, SpriteKit, XCTest.

---

### Task 1: Create the iOS project skeleton

**Files:**
- Create: `Wordiest.xcodeproj/project.pbxproj`
- Create: `Wordiest/Info.plist`
- Create: `Wordiest/WordiestApp.swift`
- Create: `Wordiest/ContentView.swift`
- Create: `Wordiest/GameScene.swift`
- Create: `WordiestTests/WordiestTests.swift`

**Steps:**
1. Create a minimal iOS app target (`Wordiest`) + unit test target (`WordiestTests`).
2. Build and run unit tests via CLI.

Run: `xcodebuild -project Wordiest.xcodeproj -scheme Wordiest -destination 'platform=iOS Simulator,name=iPhone 16' test`
Expected: PASS (even if tests are empty initially).

**Commit:**
`git add Wordiest.xcodeproj Wordiest WordiestTests && git commit -m "Create iOS project skeleton"`

---

### Task 2: Add original assets to the iOS bundle

**Files:**
- Create: `Wordiest/Resources/matchdata.packed`
- Create: `Wordiest/Resources/words.idx`
- Create: `Wordiest/Resources/words.def`
- Create: `Wordiest/Resources/IstokWeb-Bold.ttf`
- Create: `Wordiest/Resources/pickup.mp3`
- Create: `Wordiest/Resources/drop.mp3`

**Steps:**
1. Copy assets from the APK into `Wordiest/Resources/`.
2. Ensure they’re included in the app target “Copy Bundle Resources”.

**Commit:**
`git add Wordiest/Resources && git commit -m "Add original Wordiest assets"`

---

### Task 3: Implement match data loading (`matchdata.packed`)

**Files:**
- Create: `Wordiest/Domain/MatchDataStore.swift`
- Create: `Wordiest/Domain/Models.swift`
- Test: `WordiestTests/MatchDataStoreTests.swift`

**Steps:**
1. Write a test that loads header offsets and can parse match #0.
2. Implement `MatchDataStore` using the same offset math as Android `Unpack`:
   - Read bytes until `]` to parse the offsets array
   - Slice the match blob by `(start, length)` and decode JSON

Run: `xcodebuild ... test`
Expected: PASS.

**Commit:**
`git add Wordiest/Domain WordiestTests/MatchDataStoreTests.swift && git commit -m "Load matches from matchdata.packed"`

---

### Task 4: Implement scoring (tile bonuses + two-word move score)

**Files:**
- Create: `Wordiest/Domain/Scoring.swift`
- Test: `WordiestTests/ScoringTests.swift`

**Steps:**
1. Add tests matching Android logic for `2w/3w` and `2l/5l`.
2. Implement:
   - `scoreWord(tiles:)`
   - `scoreMove(word1:, word2:)`

**Commit:**
`git add Wordiest/Domain/Scoring.swift WordiestTests/ScoringTests.swift && git commit -m "Implement scoring"`

---

### Task 5: Implement dictionary lookup + definition formatting

**Files:**
- Create: `Wordiest/Domain/Definitions.swift`
- Test: `WordiestTests/DefinitionsTests.swift`

**Steps:**
1. Add tests that validate at least a few known words from the shipped assets.
2. Port the Android trie traversal:
   - custom varint decode with stop-bit 0x80
   - node header byte requires 0x40 set
   - child pointers use backwards deltas

**Commit:**
`git add Wordiest/Domain/Definitions.swift WordiestTests/DefinitionsTests.swift && git commit -m "Port dictionary lookup"`

---

### Task 6: Build the match UI in SpriteKit

**Files:**
- Modify: `Wordiest/GameScene.swift`
- Create: `Wordiest/UI/TileNode.swift`
- Create: `Wordiest/UI/BoardLayout.swift`

**Steps:**
1. Render 14 tiles with letter/value/bonus.
2. Implement touch drag:
   - pick up tile on touch began
   - move tile with finger
   - drop into nearest row (word1/word2/bank1/bank2)
3. Keep state in a small `GameState` model so UI is a view of state.

**Commit:**
`git add Wordiest/UI Wordiest/GameScene.swift && git commit -m "Render tiles and drag between rows"`

---

### Task 7: Hook up validation + score + basic controls

**Files:**
- Modify: `Wordiest/ContentView.swift`
- Modify: `Wordiest/GameScene.swift`
- Create: `Wordiest/Domain/GameState.swift`

**Steps:**
1. Compute total score using validity rules (invalid word contributes 0).
2. Add buttons:
   - Shuffle: shuffle all tiles back into banks
   - Reset: clear both words back into banks
   - Submit: show a simple result panel and load next match

**Commit:**
`git add Wordiest && git commit -m "Add scoring, shuffle/reset/submit"`

---

### Task 8: Smoke test on simulator

**Steps:**
1. Build + run on iOS Simulator.
2. Verify:
   - tiles drag smoothly
   - score updates
   - submit advances to next match

Run: `xcodebuild -project Wordiest.xcodeproj -scheme Wordiest -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: SUCCEED.

