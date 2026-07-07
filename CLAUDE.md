# Нохчийн (Deshar) — Claude Code Development Guide

## Architecture

**Feature-First Clean Architecture** — mandatory.

```
lib/
  core/
    config/          — Feature flags, constants
    design/          — Material 3 system (deprecated, use design_system)
    design_system/   — iOS-style ThemeExtension (ACTIVE)
      widgets/       — Reusable design widgets (NokhchiinXxx)
      design_tokens.dart
      ios_design_system.dart
      theme_integration.dart
    haptics/
    l10n/
    providers/       — Global Riverpod providers (NOT feature-scoped)
    router/
    services/
    utils/
    widgets/         — Shared UI (app_scaffold, loading_state, etc)
  data/
    datasources/     — Local (Hive) and remote APIs
    repositories/
  domain/
    entities/
    repositories/    — Interfaces only
    usecases/
  features/
    auth/
      data/
      domain/
      presentation/  — Screens + local providers
    home/
    profile/
    ... (each feature repeats structure)
```

**Rules:**
- Each feature is **self-contained**: data + domain + presentation layers.
- No feature imports another feature's presentation (only domain/data).
- `core/` is always accessible. Features never depend on each other.
- `presentation/` = screens + local BLoCs/providers. Business logic lives in domain.

## State Management

**Riverpod only.** No Bloc, Provider, GetX, or competing packages.

**Providers location:**
- Global/shared: `lib/core/providers/`
- Feature-scoped: `lib/features/feature_name/presentation/providers.dart`

**Pattern:**
```dart
final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfileEntity>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<UserProfileEntity> {
  // logic here — always mutate through a private _update(updated) helper,
  // never `state = AsyncData(x)` directly at call sites
}
```

**Never use:**
- `StateNotifier` for new state — only `AsyncNotifier`/`Notifier`
- Global mutable state outside of providers
- `context.read()` — prefer `ref.watch()` in widgets, `ref.read()` in callbacks only
- Logic added directly to barrel files (`providers.dart`, `repository_impl.dart`)

## Navigation

**go_router only.** Routes in `lib/core/router/app_router.dart`.

```dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(path: 'lesson/:id', builder: ..),
      ],
    ),
  ],
);
```

**Never use:**
- Navigator.push/pop (use context.go/push)
- Named routes via strings
- RouteData — go_router is the source of truth

## Design System

**LOCKED VISUAL IDENTITY** — warm, premium, educational (Disney + Khan Academy + Duolingo + Headspace).

**Colors (from design_tokens.dart):** always read the current file — this has
drifted between parallel work streams before. Never hardcode a hex color in
a widget; always go through `context.iosTokens`.

**Spacing:**
- Use `IosSpacing`/`AppSpacing` enums: `sm`, `md`, `lg`, `xl`
- Never magic numbers: `const SizedBox(height: 16)` → `const SizedBox(height: AppSpacing.md)`

**Typography:**
- Use `Theme.of(context).textTheme.*`
- Custom sizes only if design justifies — document why

**Widgets (Reusable):**
Check `lib/core/design_system/widgets/` before building anything new:
- `NokhchiinSurfaceCard` — flat card with border, press-scale
- `NokhchiinButton` — primary action
- `NokhchiinGiftTile` — gradient tile with press-scale
- `NokhchiinTabBar` — bottom tab nav
- `NokhchiinStatTile` / `NokhchiinStatPill` — metrics
- `NokhchiinArcProgress` — progress ring
- `AppScaffold` — page shell (not `Scaffold`)

**Animations:**
- Use `IosMotion.curveSnappy` for press-scale
- `IosMotion.curveGentle` for reveals/fades
- StatefulWidget + `AnimatedScale` for interactive feedback

**Never use:**
- Plain `Container` if `SizedBox` works
- `Scaffold` directly (use `AppScaffold`)
- Custom colors outside of tokens
- `GestureDetector` without `Semantics`

## Code Style

### Constants & Constructors
- All widgets: `const` constructor, mark immutable fields `final`
- Never use mutable default values

### Naming
- Widgets: `NokhchiinXxx` (design system) or `_Xxx` (local, private)
- Providers: `xxxProvider`
- Classes: `XxxEntity`, `XxxRepository`, `XxxNotifier`
- Files: snake_case (`home_screen.dart`, not `HomeScreen.dart`)
- Booleans: start with `is`, `has`, `should` (`isLoading`, `hasError`)

### Comments
- Default: no comments. Code is self-documenting.
- Only add if **WHY is non-obvious**: hidden constraint, subtle invariant, workaround for framework bug.
- Never comment **WHAT** the code does — good names say that.

### Formatting
- `dart format` is law.
- Line length: 120 (Flutter standard)

## Testing

**Location:** `test/` mirrors `lib/`. Also `integration_test/app_smoke_test.dart`
for a real-device E2E smoke test (onboarding → placement test → home → world
nav) — run with `flutter test integration_test/app_smoke_test.dart -d <device>`.
Requires an emulator/device; won't run under plain `flutter test`.

**Riverpod Testing:**
```dart
test('userProfileProvider updates on save', () async {
  final container = ProviderContainer();
  final notifier = container.read(userProfileProvider.notifier);
  await notifier.saveProfile(...);
  expect(container.read(userProfileProvider), ..);
});
```

**Never mock Hive** — use real `LocalProgressDataSource().init()` in setUp,
with a temp Hive directory per test file (see existing tests for the pattern).

## Localization (l10n)

**app_localizations.dart** — auto-generated from `lib/l10n/app_*.arb` files via
`flutter gen-l10n` (run after editing the .arb, not committed by hand).

```dart
final l10n = context.l10n;
Text(l10n.homeTitle);  // DO use generated accessors
Text('Home');          // DON'T hardcode
```

## Forbidden Patterns

❌ **Never do this:**

| Pattern | Why | Use instead |
|---------|-----|--------------|
| `Scaffold` | Custom app shell | `AppScaffold` |
| Hardcoded colors | Breaks dark mode | `context.iosTokens.accent` |
| `Navigator.push` | Go_router is source of truth | `context.push('/path')` |
| Magic numbers (16, 8) | Unmaintainable spacing | `AppSpacing.md`, `IosSpacing.lg` |
| `GlobalKey` | State leaks | Use `ref.read()` or `StatefulWidget` |
| Bloc, Provider packages | Riverpod is standard | Use Riverpod only |
| `context.read()` in build | Invisible dependency | Use `ref.watch()` |
| Custom animations | Inconsistent motion | Use `IosMotion` + `AnimatedScale` |
| `Navigator.pop()` immediately followed by `context.go()` in the same tick | Real race condition — the pop and the declarative redirect can fight over the same Navigator, sometimes leaving a bottom sheet stuck on screen (caught by the E2E smoke test) | `Navigator.pop(ctx)` then defer `ctx.go(...)` via `WidgetsBinding.instance.addPostFrameCallback` |

## Design-First Development

### Senior Product Designer Mindset

Don't just implement features. Think like a **Senior Product Designer**.

**Look for improvements in:**
- UX flows, error states, edge cases
- Visual hierarchy, contrast, sizing
- Consistency with design system
- WCAG accessibility, keyboard nav, color contrast
- Animations, micro-interactions
- Spacing, breathing room
- Typography readability

**Quality bar:** If it can be noticeably better without breaking functionality, improve it.

**Suggest improvements, implement unless told not to.**

### Visual Identity (LOCKED)

**Never redesign the identity.** Preserve and evolve.

**Rules:**
- Warm, premium, educational aesthetic (Disney + Khan Academy + Duolingo + Headspace)
- Preserve colors, proportions, spacing rhythm, emotional tone
- Incremental improvements only: +2% quality, never a new direction
- Every iteration should feel like the same product, more refined

**Before changing UI, ask: "Does this preserve Deshar's identity?"**
- If NO → don't change it
- If YES → implement

## Multiple parallel work streams

This repo has had independent work land on `origin/master` from more than one
session/agent at the same time (design tokens, onboarding flow, and dictionary
loading have all been touched independently more than once). Before making a
sweeping change to a widely-shared file (`design_tokens.dart`, `AppScaffold`,
`onboarding_screen.dart`, provider barrels), `git fetch` and check whether
`origin/master` has moved — a stale local branch here has caused real,
architecture-level duplication before (two different onboarding flows solving
the same problem), not just line-level merge conflicts.

## Tools & Stack

- Flutter 3.44.2 / Dart ^3.12.2
- flutter_riverpod, go_router, hive_flutter, flutter_animate
- sentry_flutter ^9.23.0 (upgrade from 8.x fixed a Kotlin Gradle Plugin
  incompatibility that blocked native Android builds entirely)
- patrol + integration_test (E2E, real device only)

## References

- Design system: `lib/core/design_system/`
- Widgets: `lib/core/design_system/widgets/` (NokhchiinXxx)
- Providers: `lib/core/providers/`
- Routing: `lib/core/router/app_router.dart`
- Tokens: `lib/core/design_system/design_tokens.dart`
- Tests: `test/` (unit/widget), `integration_test/` (E2E, real device)
- Deeper Flutter-specific rules: `nokhchiin/.agents/AGENTS.md`
