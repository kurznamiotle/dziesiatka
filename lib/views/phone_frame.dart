import 'package:dziesiatka/views/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _breakpoint = 480.0;
const _maxWidth = 440.0;
const _maxHeight = 860.0;
const _borderRadius = BorderRadius.all(Radius.circular(36));

const _lightThemeOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

const _darkThemeOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

bool get _isMobileApp {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

/// Shows the app as a centered phone on the web and desktop. Android and iOS
/// apps always fill the screen, as does any window too narrow for the frame.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaces>()!;
    if (_isMobileApp) {
      // The home screen has no app bar to set the status bar icon color.
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? _darkThemeOverlay
            : _lightThemeOverlay,
        child: ColoredBox(color: surfaces.frame, child: child),
      );
    }

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
