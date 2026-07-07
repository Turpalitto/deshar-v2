---
name: flutter_ui_rules
description: |
  Enforce Nokhchiin's Flutter UI consistency rules whenever writing or editing
  screens, widgets, or layout code in this project. Applies: design tokens
  (context.iosTokens, never hardcoded colors), reuse of NokhchiinXxx design
  system widgets, const constructors, press-scale animations via IosMotion,
  Semantics for accessibility, AppSpacing instead of magic numbers, Riverpod
  for state, go_router for navigation. Use automatically for any task
  mentioning "screen", "widget", "UI", "layout", "экран", "виджет", or when
  implementing a new feature's presentation layer.
---

# Flutter UI Rules — Нохчийн (Deshar)

This is a premium educational app (Disney + Khan Academy + Duolingo + Headspace
tone: warm, calm, accessible). The rules below exist to keep every new screen
feeling like the same product, not a rebuild.

## 1. Design tokens are the only source of color/spacing

Never write a hex color or a bare number for spacing in a widget. Always go
through the design system so dark mode and future palette tweaks propagate
everywhere at once.

```dart
// Good
color: context.iosTokens.accent
SizedBox(height: AppSpacing.md)

// Bad — breaks dark mode, invisible to future retheming
color: const Color(0xFF3D7A5C)
SizedBox(height: 12)
```

Check `lib/core/design_system/design_tokens.dart` for the current values — this
file has been touched by more than one independent work stream before, so
don't assume a color from memory or from an older screenshot.

## 2. Reuse NokhchiinXxx widgets before building new ones

Check `lib/core/design_system/widgets/` first. Most layout needs are already
solved there with the right motion and semantics baked in:

| Need | Widget |
|---|---|
| Card with border + press-scale | `NokhchiinSurfaceCard` |
| Gradient tile (home actions) | `NokhchiinGiftTile` |
| Primary button | `NokhchiinButton` |
| Single metric | `NokhchiinStatTile` / `NokhchiinStatPill` |
| Circular progress | `NokhchiinArcProgress` |
| Bottom nav | `NokhchiinTabBar` |
| Page shell (not `Scaffold`) | `AppScaffold` |

If none fit, build a new one following the same press-scale pattern (see
below) so it doesn't feel foreign next to the rest of the app.

## 3. Const everywhere it's legal

Every `StatelessWidget` gets a `const` constructor. Every child that doesn't
depend on runtime state gets `const` at the call site — Flutter skips
rebuilding const subtrees, and it's how regressions get caught in review.

## 4. Press-scale is the only tap-feedback pattern

```dart
class _MyTileState extends State<_MyTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => _handleTap(),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: IosMotion.curveSnappy,
        child: /* content */,
      ),
    );
  }
}
```

Use `IosMotion.curveGentle` for fades/reveals instead — never invent a new
curve or duration.

## 5. Semantics on every tappable

```dart
Semantics(
  button: true,
  label: 'Продолжить урок',
  child: GestureDetector(...),
)
```

## 6. Keep business logic out of build()

UI reads state via `ref.watch(...)`. It never calls a repository, does async
work, or branches on domain rules inside `build()` — that belongs in a
Riverpod provider or a domain usecase.

## 7. Navigation is go_router only

`context.push('/path')` / `context.go('/path')`. Never `Navigator.push`.

**Watch the pop-then-go race:** if you dismiss a modal/bottom sheet and then
immediately redirect with go_router in the same synchronous block, the two
navigation operations can race and leave the sheet stuck rendered on top of
the destination screen. This is a real bug the E2E smoke test caught, not a
theoretical one. Defer the redirect:

```dart
Navigator.pop(ctx);
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (ctx.mounted) ctx.go('/');
});
```

## 8. Strings go through l10n

`context.l10n.homeTitle`, never a bare Russian string in a widget. Add missing
keys to `lib/l10n/app_ru.arb` first, then run `flutter gen-l10n`.

## Quick self-check before finishing a UI task

- [ ] No hex colors, no magic-number spacing
- [ ] Reused a `NokhchiinXxx` widget where one already fit
- [ ] `const` on every constructor that can take it
- [ ] Tap feedback via `AnimatedScale` + `IosMotion`, not something new
- [ ] `Semantics` on tappables
- [ ] No repository/business logic inside `build()`
- [ ] Navigation via `context.push/go`; any pop-then-go deferred a frame
- [ ] Text via `context.l10n`, not hardcoded
