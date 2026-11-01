import 'package:dziesiatka/views/category_style.dart';
import 'package:flutter/material.dart';

/// A category gradient with its icon and soft circles behind [child].
class CategoryArtwork extends StatelessWidget {
  const CategoryArtwork({
    super.key,
    required this.category,
    required this.child,
    this.iconSize = 150,
    this.iconOpacity = 0.24,
    this.showDecoration = true,
  });

  final String category;
  final Widget child;
  final double iconSize;
  final double iconOpacity;
  final bool showDecoration;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category, Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.hardEdge,
        children: [
          if (showDecoration) ...[
            _Circle(
              top: -iconSize * 0.4,
              left: -iconSize * 0.3,
              size: iconSize,
            ),
            _Circle(
              bottom: -iconSize * 0.5,
              right: iconSize * 0.7,
              size: iconSize * 0.8,
            ),
            Positioned(
              right: -iconSize * 0.12,
              bottom: -iconSize * 0.18,
              child: ExcludeSemantics(
                child: Icon(
                  style.icon,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: iconOpacity),
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({
    required this.size,
    this.top,
    this.left,
    this.bottom,
    this.right,
  });

  final double size;
  final double? top;
  final double? left;
  final double? bottom;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
