import 'package:flutter/material.dart';

/// App surfaces that have no direct [ColorScheme] role. Material's lowest
/// surface is white in light mode but the darkest tone in dark mode, while
/// cards here must always sit above the frame.
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  const AppSurfaces({
    required this.backdrop,
    required this.frame,
    required this.card,
    required this.border,
    required this.shadow,
    required this.streak,
  });

  final Color backdrop;
  final Color frame;
  final Color card;
  final Color border;
  final Color shadow;
  final Color streak;

  @override
  AppSurfaces copyWith({
    Color? backdrop,
    Color? frame,
    Color? card,
    Color? border,
    Color? shadow,
    Color? streak,
  }) {
    return AppSurfaces(
      backdrop: backdrop ?? this.backdrop,
      frame: frame ?? this.frame,
      card: card ?? this.card,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      streak: streak ?? this.streak,
    );
  }

  @override
  AppSurfaces lerp(AppSurfaces? other, double t) {
    if (other == null) return this;
    return AppSurfaces(
      backdrop: Color.lerp(backdrop, other.backdrop, t)!,
      frame: Color.lerp(frame, other.frame, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      streak: Color.lerp(streak, other.streak, t)!,
    );
  }
}

abstract final class AppTheme {
  static const _seedColor = Color(0xFF4F46E5);

  static const _lightSurfaces = AppSurfaces(
    backdrop: Color(0xFFE9E6F2),
    frame: Color(0xFFFBF9FF),
    card: Color(0xFFFFFFFF),
    border: Color(0x00000000),
    shadow: Color(0x1A000000),
    streak: Color(0xFFC2410C),
  );

  static const _darkSurfaces = AppSurfaces(
    backdrop: Color(0xFF0B0C11),
    frame: Color(0xFF14151C),
    card: Color(0xFF1F2029),
    border: Color(0x14FFFFFF),
    shadow: Color(0x73000000),
    streak: Color(0xFFFB923C),
  );

  static final light = _build(Brightness.light, _lightSurfaces);
  static final dark = _build(Brightness.dark, _darkSurfaces);

  static ThemeData _build(Brightness brightness, AppSurfaces surfaces) {
    final colors = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      surface: surfaces.frame,
    );
    return ThemeData(
      colorScheme: colors,
      extensions: [surfaces],
      // Dropdown menus use the canvas color and would blend into the frame.
      canvasColor: surfaces.card,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaces.frame,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surfaces.card),
      dialogTheme: DialogThemeData(backgroundColor: surfaces.card),
    );
  }
}
