import 'package:flutter/material.dart';

const _breakpoint = 480.0;
const _maxWidth = 440.0;
const _maxHeight = 860.0;

/// Shows the app as a centered phone on wide screens and full-screen otherwise.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint) {
          return ColoredBox(color: colors.surface, child: child);
        }

        return ColoredBox(
          color: colors.surfaceContainerHigh,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: _maxWidth,
                  maxHeight: _maxHeight,
                ),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: SizedBox.expand(child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
