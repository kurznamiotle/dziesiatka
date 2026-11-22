import 'dart:math';

import 'package:dziesiatka/models/app_accent.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  return (max(first, second) + 0.05) / (min(first, second) + 0.05);
}

void main() {
  const minimumTextContrast = 4.5;

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final name = theme.brightness.name;
    final colors = theme.colorScheme;
    final surfaces = theme.extension<AppSurfaces>()!;

    group('$name theme', () {
      test('category badges are readable on cards', () {
        final categories = [
          ...CategoryStyle.styledCategories,
          'Moja kategoria',
        ];

        for (final category in categories) {
          final style = CategoryStyle.of(category, theme.brightness);
          final badge = Color.alphaBlend(style.background, surfaces.card);

          expect(
            contrast(style.color, badge),
            greaterThanOrEqualTo(minimumTextContrast),
            reason: category,
          );
        }
      });

      test('white text is readable on category gradients', () {
        final categories = [
          ...CategoryStyle.styledCategories,
          'Moja kategoria',
        ];

        for (final category in categories) {
          final style = CategoryStyle.of(category, theme.brightness);
          for (final color in style.gradient) {
            expect(
              contrast(Colors.white, color),
              greaterThanOrEqualTo(minimumTextContrast),
              reason: category,
            );
          }
        }
      });

      test('category badges are readable on banners', () {
        final style = CategoryStyle.of('Historia', theme.brightness);

        expect(
          contrast(style.color, surfaces.card),
          greaterThanOrEqualTo(minimumTextContrast),
        );
      });

      test('the review badge is readable on cards', () {
        expect(
          contrast(colors.onSecondaryContainer, colors.secondaryContainer),
          greaterThanOrEqualTo(minimumTextContrast),
        );
      });

      test('the streak color is readable on the frame', () {
        expect(
          contrast(surfaces.streak, surfaces.frame),
          greaterThanOrEqualTo(minimumTextContrast),
        );
      });

      test('text is readable on the frame and on cards', () {
        for (final surface in [surfaces.frame, surfaces.card]) {
          for (final text in [colors.onSurface, colors.onSurfaceVariant]) {
            expect(
              contrast(text, surface),
              greaterThanOrEqualTo(minimumTextContrast),
            );
          }
        }
      });

      test('links and primary buttons are readable', () {
        expect(
          contrast(colors.primary, surfaces.card),
          greaterThanOrEqualTo(minimumTextContrast),
        );
        expect(
          contrast(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(minimumTextContrast),
        );
      });

      test('the frame stands out from the backdrop', () {
        expect(surfaces.frame, isNot(surfaces.backdrop));
      });
    });
  }

  for (final accent in AppAccent.values) {
    for (final brightness in Brightness.values) {
      final theme = AppTheme.of(accent, brightness);
      final colors = theme.colorScheme;
      final surfaces = theme.extension<AppSurfaces>()!;

      test('${accent.name} accent is readable in ${brightness.name}', () {
        const minimum = 4.5;
        for (final surface in [surfaces.frame, surfaces.card]) {
          expect(
            contrast(colors.primary, surface),
            greaterThanOrEqualTo(minimum),
          );
        }
        expect(
          contrast(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(minimum),
        );
        expect(
          contrast(colors.onPrimaryContainer, colors.primaryContainer),
          greaterThanOrEqualTo(minimum),
        );
        expect(
          contrast(colors.onSecondaryContainer, colors.secondaryContainer),
          greaterThanOrEqualTo(minimum),
        );
      });
    }
  }

  test('accents are different colors', () {
    final primaries = {
      for (final accent in AppAccent.values)
        AppTheme.of(accent, Brightness.light).colorScheme.primary,
    };
    expect(primaries, hasLength(AppAccent.values.length));
  });

  test('every category has its own icon and colors', () {
    final categories = CategoryStyle.styledCategories.toList();
    for (final brightness in Brightness.values) {
      final styles = [
        for (final name in categories) CategoryStyle.of(name, brightness),
      ];
      expect(styles.map((style) => style.icon).toSet(), hasLength(14));
      expect(styles.map((style) => style.color).toSet(), hasLength(14));
      expect(styles.map((style) => style.gradient.last).toSet(), hasLength(14));
    }
  });

  test('the new categories have their own look', () {
    for (final name in ['Samorozwój', 'Inżynieria & Motoryzacja']) {
      expect(CategoryStyle.styledCategories, contains(name));
      expect(
        CategoryStyle.of(name, Brightness.light).icon,
        isNot(CategoryStyle.of('Moja kategoria', Brightness.light).icon),
      );
    }
  });

  test('dark cards sit above the frame and the backdrop', () {
    final surfaces = AppTheme.dark.extension<AppSurfaces>()!;

    expect(
      surfaces.card.computeLuminance(),
      greaterThan(surfaces.frame.computeLuminance()),
    );
    expect(
      surfaces.frame.computeLuminance(),
      greaterThan(surfaces.backdrop.computeLuminance()),
    );
  });
}
