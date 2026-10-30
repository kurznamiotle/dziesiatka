import 'package:dziesiatka/views/app_theme.dart';
import 'package:flutter/material.dart';

const _breakpoint = 480.0;
const _maxWidth = 440.0;
const _maxHeight = 860.0;
const _borderRadius = BorderRadius.all(Radius.circular(36));

/// Shows the app as a centered phone on wide screens and full-screen otherwise.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<AppSurfaces>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _breakpoint) {
          return ColoredBox(color: surfaces.frame, child: child);
        }

        return ColoredBox(
          color: surfaces.backdrop,
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
                  // A foreground border takes no layout space and stays above
                  // the content, so both themes lay out identically.
                  foregroundDecoration: BoxDecoration(
                    borderRadius: _borderRadius,
                    border: Border.all(color: surfaces.border),
                  ),
                  decoration: BoxDecoration(
                    color: surfaces.frame,
                    borderRadius: _borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: surfaces.shadow,
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
