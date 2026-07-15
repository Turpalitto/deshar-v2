# Content readiness

The app currently exposes 13 thematic learning units. `school` and `stories`
remain in the roadmap but are hidden, not locked: they have no dedicated
lesson vocabulary yet, and showing them would make the games silently mix in
unrelated words.

## Current inventory

- 13 lesson sets in `nokhchiin/assets/data/lessons.json`.
- 141 curated entries in `curated_vocabulary.json`.
- 134,104 searchable dictionary entries from the Hugging Face source.
- 2 short stories and 3 bosses.
- 15 cultural capsules; all are editorial drafts pending native-speaker review.
- 59 curated/full-dictionary translation differences in
  `tools/output/vocabulary_emoji_audit.json`; these are review candidates, not
  safe automatic corrections.

## Release rule

A unit may be enabled only when it has a coherent lesson set, age-appropriate
progression, and native-speaker approval. New screens or raw dataset matches do
not count as reviewed curriculum.

The native-speaker workflow and correction pipeline are documented in
`editorial-review.md`.
