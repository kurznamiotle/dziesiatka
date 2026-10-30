import 'dart:math';

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
        const categories = [
          'Kosmos',
          'Zwierzęta',
          'Historia',
          'Psychologia',
          'Technologia',
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
