# Editorial review protocol

This app deliberately does not treat automated matches as linguistic truth.
All learner-facing Chechen and Russian material must be approved by a native
speaker or qualified language editor before publication.

## Current review queue

Run from the repository root:

```powershell
python tools/audit_emoji_vocabulary.py
```

The current report is written to `tools/output/vocabulary_emoji_audit.json`.
It flags 59 curated-to-dictionary translation differences. These are review
items, not automatic errors: the full dictionary can contain homonyms and
near-synonyms, while curated lesson translations intentionally use the most
teachable wording.

## Editor checklist

For every lesson word, dialogue, story and culture capsule, verify:

1. Chechen spelling, including `Ӏ`, apostrophes and word boundaries.
2. Russian translation is natural, age-appropriate and matches the intended
   sense—not merely any dictionary sense.
3. Pronunciation/transliteration, example phrase and emoji match the same
   meaning.
4. Content is appropriate for children and adults; no cultural statement is
   presented as universal when it is contextual or family-specific.
5. Each correction is entered in `vocabulary_corrections.json`, then curated
   data is regenerated with `python tools/build_dictionary.py --curate-only --copy-assets`.

## Culture capsules

`nokhchiin/assets/data/culture_capsules.json` contains one short capsule per
learning unit. The current texts are careful learning prompts, not a scholarly
account of culture. They require native-speaker review before store release.
