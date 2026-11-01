import 'dart:math';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_artwork.dart';
import 'package:dziesiatka/views/category_badge.dart';
import 'package:dziesiatka/views/pill_badge.dart';
import 'package:dziesiatka/views/share_card_sheet.dart';
import 'package:flutter/material.dart';

/// Below this height, such as on a phone in landscape, the card tightens up.
const _compactHeight = 240.0;
const _compactBannerHeight = 56.0;
const _maxBannerHeight = 300.0;
const _minBannerShare = 0.32;
const _bannerShare = 0.44;

/// What the title, text and buttons need, so a small phone keeps its text
/// readable without scrolling and gives up artwork instead.
const _textRoom = 270.0;
const _iconShare = 1.05;
const _iconOpacity = 0.42;
const _radius = 28.0;

class FactCard extends StatelessWidget {
  const FactCard({
    super.key,
    required this.fact,
    required this.onExpand,
    this.onShare,
    this.isReview = false,
  });

  final Fact fact;
  final VoidCallback onExpand;
  final VoidCallback? onShare;
  final bool isReview;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<AppSurfaces>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: surfaces.border),
        boxShadow: [
          BoxShadow(
            color: surfaces.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < _compactHeight;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBanner(context, constraints.maxHeight, isCompact),
                Expanded(child: _buildText(context, isCompact)),
                _buildActions(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, double cardHeight, bool isCompact) {
    final colors = Theme.of(context).colorScheme;
    final height = isCompact
        ? _compactBannerHeight
        : [
            _maxBannerHeight,
            cardHeight * _bannerShare,
            max(cardHeight * _minBannerShare, cardHeight - _textRoom),
          ].reduce(min);
    return SizedBox(
      height: height,
      child: CategoryArtwork(
        category: fact.category,
        iconSize: height * _iconShare,
        iconOpacity: _iconOpacity,
        showDecoration: !isCompact,
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CategoryBadge(category: fact.category, solid: true),
              if (isReview)
                PillBadge(
                  icon: Icons.refresh_rounded,
                  label: 'Powtórka',
                  color: colors.onSecondaryContainer,
                  background: colors.secondaryContainer,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context, bool isCompact) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 24,
        isCompact ? 8 : 16,
        isCompact ? 16 : 24,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fact.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fact.shortText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 18,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Row(
        spacing: 4,
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onExpand,
              icon: const Icon(Icons.expand_less_rounded),
              label: const Text('Dowiedz się więcej'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Udostępnij',
            onPressed: () {
              onShare?.call();
              ShareCardSheet.show(context, fact);
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
    );
  }
}
