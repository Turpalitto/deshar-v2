import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/design_system/design_system.dart';
import '../../../domain/entities/learning_entities.dart';
import '../learning_path_visual_state.dart';

typedef PathNodeTapCallback = void Function(LearningUnitEntity unit);

class LearningPathNode extends StatefulWidget {
  const LearningPathNode({
    super.key,
    required this.unit,
    required this.visualState,
    required this.position,
    required this.screenWidth,
    required this.onTap,
    required this.subtitle,
    this.playUnlockAnimation = false,
  });

  final LearningUnitEntity unit;
  final PathNodeVisualState visualState;
  final Offset position;
  final double screenWidth;
  final PathNodeTapCallback? onTap;
  final String subtitle;
  final bool playUnlockAnimation;

  static const double nodeSize = 56;
  static const double labelWidth = 148;

  @override
  State<LearningPathNode> createState() => _LearningPathNodeState();
}

class _LearningPathNodeState extends State<LearningPathNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant LearningPathNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.visualState == PathNodeVisualState.current) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.visualState == PathNodeVisualState.current) {
      HapticFeedback.mediumImpact();
    }
    widget.onTap?.call(widget.unit);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;
    final theme = Theme.of(context).textTheme;
    final labelOnRight = widget.position.dx < widget.screenWidth / 2;

    Widget circle = _NodeCircle(
      unit: widget.unit,
      visualState: widget.visualState,
      tokens: tokens,
    );

    if (widget.playUnlockAnimation) {
      circle = circle
          .animate(key: ValueKey('unlock_${widget.unit.id}'))
          .scale(
            begin: const Offset(0.4, 0.4),
            end: const Offset(1, 1),
            duration: IosMotion.celebrate,
            curve: IosMotion.curveBouncy,
          )
          .fadeIn(duration: IosMotion.interact, curve: IosMotion.curveSnappy);
    }

    if (widget.visualState == PathNodeVisualState.current) {
      circle = ScaleTransition(scale: _pulseScale, child: circle);
    }

    final label = SizedBox(
      width: LearningPathNode.labelWidth,
      child: _NodeLabel(
        unit: widget.unit,
        visualState: widget.visualState,
        subtitle: widget.subtitle,
        tokens: tokens,
        theme: theme,
        alignLeft: labelOnRight,
      ),
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: labelOnRight
          ? [
              GestureDetector(onTap: widget.onTap == null ? null : _handleTap, child: circle),
              const SizedBox(width: IosSpacing.x2),
              label,
            ]
          : [
              label,
              const SizedBox(width: IosSpacing.x2),
              GestureDetector(onTap: widget.onTap == null ? null : _handleTap, child: circle),
            ],
    );

  final rowWidth = LearningPathNode.nodeSize + IosSpacing.x2 + LearningPathNode.labelWidth;
    final left = (labelOnRight ? widget.position.dx - LearningPathNode.nodeSize / 2 : widget.position.dx + LearningPathNode.nodeSize / 2 - rowWidth)
        .clamp(0.0, widget.screenWidth - rowWidth);

    return Positioned(
      left: left,
      top: widget.position.dy - LearningPathNode.nodeSize / 2,
      child: row,
    );
  }
}

class _NodeCircle extends StatelessWidget {
  const _NodeCircle({
    required this.unit,
    required this.visualState,
    required this.tokens,
  });

  final LearningUnitEntity unit;
  final PathNodeVisualState visualState;
  final DesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    const size = LearningPathNode.nodeSize;
    final isLocked = visualState == PathNodeVisualState.locked;
    final isCurrent = visualState == PathNodeVisualState.current;

    final fill = switch (visualState) {
      PathNodeVisualState.locked => tokens.surfaceMuted,
      PathNodeVisualState.current => tokens.accent,
      PathNodeVisualState.completed => tokens.accentMuted,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(
          color: isCurrent ? tokens.accent : tokens.separator,
          width: isCurrent ? 2.5 : 1.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.28),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: isLocked
          ? Icon(Icons.lock_rounded, size: 20, color: tokens.textTertiary)
          : visualState == PathNodeVisualState.completed
              ? Icon(Icons.check_rounded, size: 24, color: tokens.accent)
              : Text(
                  unit.icon.isNotEmpty ? unit.icon : '${unit.order}',
                  style: const TextStyle(fontSize: 22, height: 1),
                ),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({
    required this.unit,
    required this.visualState,
    required this.subtitle,
    required this.tokens,
    required this.theme,
    required this.alignLeft,
  });

  final LearningUnitEntity unit;
  final PathNodeVisualState visualState;
  final String subtitle;
  final DesignTokens tokens;
  final TextTheme theme;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final muted = visualState == PathNodeVisualState.locked;

    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          unit.titleCe,
          style: theme.labelMedium?.copyWith(
            color: muted ? tokens.textTertiary : tokens.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: alignLeft ? TextAlign.left : TextAlign.right,
        ),
        Text(
          unit.titleRu,
          style: theme.titleSmall?.copyWith(
            color: muted ? tokens.textTertiary : tokens.textPrimary,
          ),
          textAlign: alignLeft ? TextAlign.left : TextAlign.right,
        ),
        const SizedBox(height: IosSpacing.x1),
        Text(
          subtitle,
          style: theme.bodySmall?.copyWith(color: tokens.textTertiary, fontSize: 11),
          textAlign: alignLeft ? TextAlign.left : TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
