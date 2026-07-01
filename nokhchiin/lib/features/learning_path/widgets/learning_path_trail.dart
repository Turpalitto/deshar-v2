import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/design_system.dart';
import '../../../domain/constants/subscription_limits.dart';
import '../../../domain/entities/learning_entities.dart';
import '../learning_path_visual_state.dart';
import 'learning_path_node.dart';
import 'learning_path_trail_painter.dart';

/// Визуальный слой извилистой тропы — данные и навигация с экрана.
class LearningPathTrail extends StatefulWidget {
  const LearningPathTrail({super.key, required this.units});

  final List<LearningUnitEntity> units;

  static const double verticalSpacing = 132;
  static const double topPadding = 48;
  static const double bottomPadding = 48;

  @override
  State<LearningPathTrail> createState() => _LearningPathTrailState();
}

class _LearningPathTrailState extends State<LearningPathTrail> {
  final Set<String> _seenUnlockedIds = {};
  final Set<String> _unlockAnimatingIds = {};

  @override
  void didUpdateWidget(covariant LearningPathTrail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _trackNewlyUnlocked(widget.units);
  }

  @override
  void initState() {
    super.initState();
    for (final u in widget.units) {
      if (u.isUnlocked) _seenUnlockedIds.add(u.id);
    }
  }

  void _trackNewlyUnlocked(List<LearningUnitEntity> units) {
    for (final u in units) {
      if (u.isUnlocked && !_seenUnlockedIds.contains(u.id)) {
        _seenUnlockedIds.add(u.id);
        _unlockAnimatingIds.add(u.id);
      }
    }
  }

  void _onNodeTap(LearningUnitEntity unit) {
    final isPremiumGate =
        !unit.isUnlocked && unit.order > SubscriptionLimits.freeUnitMaxOrder;

    if (unit.isUnlocked) {
      context.push('/unit/${unit.id}');
    } else if (isPremiumGate) {
      context.push('/paywall?return=/path');
    }
  }

  String _subtitle(LearningUnitEntity unit) {
    final isPremiumGate =
        !unit.isUnlocked && unit.order > SubscriptionLimits.freeUnitMaxOrder;
    if (isPremiumGate) {
      return 'Premium · ${unit.masteryPercent}% освоено';
    }
    return '${unit.masteryPercent}% · нужно ${unit.requiredMastery}% для следующей';
  }

  PathNodeTapCallback? _tapHandler(LearningUnitEntity unit) {
    final isPremiumGate =
        !unit.isUnlocked && unit.order > SubscriptionLimits.freeUnitMaxOrder;
    if (unit.isUnlocked || isPremiumGate) return _onNodeTap;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final activeOrder = currentUnitOrder(widget.units);
    final width = MediaQuery.sizeOf(context).width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final positions = windingTrailNodePositions(
          count: widget.units.length,
          width: width - IosSpacing.screenHorizontal * 2,
          topPadding: LearningPathTrail.topPadding,
          verticalSpacing: LearningPathTrail.verticalSpacing,
        );

        final trailHeight = LearningPathTrail.topPadding +
            (widget.units.length - 1) * LearningPathTrail.verticalSpacing +
            LearningPathTrail.bottomPadding +
            72;

        final segments = <TrailSegmentVisual>[];
        for (var i = 0; i < widget.units.length - 1; i++) {
          final nextState = pathNodeVisualState(
            widget.units[i + 1],
            activeOrder: activeOrder,
          );
          segments.add(
            TrailSegmentVisual(
              from: positions[i],
              to: positions[i + 1],
              state: nextState == PathNodeVisualState.locked
                  ? PathNodeVisualState.locked
                  : PathNodeVisualState.completed,
            ),
          );
        }

        final contentWidth = width - IosSpacing.screenHorizontal * 2;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: IosSpacing.screenHorizontal),
          child: SizedBox(
            height: trailHeight,
            width: contentWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(contentWidth, trailHeight),
                  painter: LearningPathTrailPainter(
                    segments: segments,
                    tokens: tokens,
                    strokeWidth: 3,
                  ),
                ),
                ...List.generate(widget.units.length, (i) {
                  final unit = widget.units[i];
                  final visualState = pathNodeVisualState(unit, activeOrder: activeOrder);
                  return LearningPathNode(
                    key: ValueKey(unit.id),
                    unit: unit,
                    visualState: visualState,
                    position: positions[i],
                    screenWidth: contentWidth,
                    subtitle: _subtitle(unit),
                    onTap: _tapHandler(unit),
                    playUnlockAnimation: _unlockAnimatingIds.contains(unit.id),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
