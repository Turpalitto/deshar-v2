import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../../core/design_system/design_system.dart';

/// Горизонтальный свайп карточки с spring-физикой (iOS-style).
class SpringSwipeCard extends StatefulWidget {
  const SpringSwipeCard({
    super.key,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.controller,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final SpringSwipeCardController? controller;
  final bool enabled;

  @override
  State<SpringSwipeCard> createState() => _SpringSwipeCardState();
}

class SpringSwipeCardController {
  _SpringSwipeCardState? _state;

  void _attach(_SpringSwipeCardState state) => _state = state;

  void _detach(_SpringSwipeCardState state) {
    if (_state == state) _state = null;
  }

  void swipeLeft() => _state?._dismiss(toRight: false);
  void swipeRight() => _state?._dismiss(toRight: true);
}

class _SpringSwipeCardState extends State<SpringSwipeCard> with SingleTickerProviderStateMixin {
  static const double _dismissThreshold = 96;

  late AnimationController _controller;
  double _offsetX = 0;
  double _offsetY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() => _offsetX = _controller.value));
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant SpringSwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _controller.dispose();
    super.dispose();
  }

  void _springTo(double target, {double velocity = 0, VoidCallback? onEnd}) {
    _controller.stop();
    final simulation = SpringSimulation(IosMotion.snappy, _offsetX, target, velocity);
    _controller.animateWith(simulation).whenComplete(() => onEnd?.call());
  }

  void _dismiss({required bool toRight}) {
    if (!widget.enabled) return;
    final width = MediaQuery.sizeOf(context).width;
    final target = toRight ? width * 1.2 : -width * 1.2;
    _springTo(target, velocity: toRight ? 800 : -800, onEnd: () {
      if (!mounted) return;
      _controller.value = 0;
      _offsetX = 0;
      _offsetY = 0;
      if (toRight) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _offsetX += details.delta.dx;
      _offsetY += details.delta.dy * 0.15;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (_offsetX > _dismissThreshold || velocity > 600) {
      _dismiss(toRight: true);
    } else if (_offsetX < -_dismissThreshold || velocity < -600) {
      _dismiss(toRight: false);
    } else {
      _springTo(0, velocity: velocity);
      setState(() => _offsetY = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final rotation = (_offsetX / width * 0.08).clamp(-0.12, 0.12);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(_offsetX, _offsetY),
        child: Transform.rotate(
          angle: rotation,
          child: widget.child,
        ),
      ),
    );
  }
}
