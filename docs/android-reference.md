# Wordiest (Android) reference notes

These notes are based on decompiled sources + shipped assets from `Wordiest_1.188_APKPure.apk`.

## Core gameplay loop

- Each match provides exactly 14 tiles.
- You can build up to **two words** (“word 1” and “word 2”) by dragging tiles out of two 7-tile “banks”.
- Tiles cannot be reused across the two words.
- A submission can include:
  - 0 words (both rows invalid/empty)
  - 1 valid word
  - 2 valid words
- The app warns before submit based on how many valid words you have (0/1/2).

## Word validity + definitions

- A word is considered valid if `Definitions.getDefinition(word)` returns non-null.
- Definitions come from two assets loaded on startup:
  - `assets/words.idx` (compressed trie index)
  - `assets/words.def` (definition blobs)
- Definitions support “see” redirects:
  - If the definition for a part of speech starts with `@otherword`, it redirects.
  - If it starts with `@!otherword`, it redirects and also changes the lookup word used for Wiktionary.

## Scoring

- Each tile has:
  - `l` (letter)
  - `x` (base letter value)
  - optional `b` bonus string like `2w` or `5l` (case-insensitive)
- Word score:
  - Sum of `x * letterMultiplier` for each tile in the word
  - Then multiply by the product of any word multipliers
  - `b` parsing is single-digit multiplier + (`L` or `W`)
- Move score:
  - Sum of scores for word 1 + word 2 (if both valid)
  - If a word is invalid, it contributes 0

## “Best” within a match

- The match tracks a “best score so far” for the current rack; tapping the score restores that best arrangement.

## Match data (`assets/matchdata.packed`)

The file is a concatenated stream of JSON values:

1. A JSON array of integers: end offsets for each following match blob
2. Then N match objects (in v1.188, N is 1999)

Each match object has:

- `i`: tile list (length 14), each item is a tile JSON object (`l`, `x`, optional `b`)
- `sl`: a list of “opponent samples” used for rating/graphs

Opponent sample fields we’ve observed:

- `s`: score (int)
- `r`: rating_x10 (int, rating * 10)
- `p`: percentile_x10? (int; observed as 0 in at least one match)
- `w`: packed “two-word move” encoding (integer, fits in unsigned 64-bit in the shipped data)
- `a`: synthetic flag (boolean) for some entries

### Packed move encoding (`w`)

- Encoding is base-16 nibbles.
- Each nibble is either:
  - `0xF`: delimiter between word 1 and word 2
  - `1..14`: index into the 14-tile list (1-based)
- The same tile index cannot appear twice across the two words (enforced by the encoder).
- Move score in `sl[*].s` is the sum of the two decoded word scores.

## Rating update

The app computes a percentile relative to the first 100 `sl` entries for the match, then updates rating:

- `percentile = ceilTenths(100 * (#(opponents with score <= playerScore)) / opponentsCount)`
- `rating = ceilTenths(0.2 * percentile + 0.8 * rating)`

Rating deviation exists in user data/history, but the update step above only uses `rating` and the current match’s percentile.

## Audio + font assets

- `res/raw/pickup.mp3` and `res/raw/drop.mp3` are used for tile drag/drop.
- `assets/IstokWeb-Bold.ttf` is used for tile rendering.

## Open questions (for iOS port)

- Do we want to preserve the original “rating/percentile” meta-game, or focus on core word-building + scoring?
- Should the iOS version keep the exact dictionary/definition format (ported), or replace it with a new word list / built-in dictionary?

