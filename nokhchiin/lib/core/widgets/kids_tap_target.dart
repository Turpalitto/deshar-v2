import 'package:flutter/material.dart';

/// Минимальная зона нажатия для детского режима (56–64 dp).
class KidsTapTarget extends StatelessWidget {
  const KidsTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minSize = 56,
    this.expand = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double minSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: expand
          ? SizedBox(width: double.infinity, child: Center(child: child))
          : Center(child: child),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
