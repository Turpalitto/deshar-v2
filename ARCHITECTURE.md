# Architecture

<!-- PROJECT-MEMORY-KIT:GENERATED -->
This file records verified architecture only. The initial scan detected: **Unknown**.

## Major components

Unknown — inspect source and runtime behavior before documenting.

## Module responsibilities

See `graph/project_graph.json` for coarse modules detected from directory structure.

## Data flow / APIs / storage / deployment

Unknown — needs verification.


## Native TV screensaver

`tv-screensaver/android` is an independent Java/Android Gradle module. `prepare_assets.py` reads canonical dictionary mirrors and the researched selection, validates exact Maciev pairs, packages licensed fonts and resampled wallpapers. `Catalog` loads the selected offline data; `WordDeck` owns topic filtering and shuffling; `AppSettings` owns persisted choices; `DreamView` owns rendering, decode and animation lifetime. `LanguageDream` and `PreviewActivity` share the rendering view. `SettingsActivity` exposes remote-operable settings. No Flutter business logic depends on this module.
