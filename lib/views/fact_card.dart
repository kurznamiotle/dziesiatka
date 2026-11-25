import 'dart:math';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/services/link_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_artwork.dart';
import 'package:dziesiatka/views/category_badge.dart';
import 'package:dziesiatka/views/category_style.dart';
import 'package:dziesiatka/views/offer_scope.dart';
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
const _partnerBorderWidth = 2.0;

/// Big enough for a finger, as Apple and Google both ask.
const _minTapHeight = 44.0;

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
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaces>()!;
    final frame = fact.isPartner
        ? CategoryStyle.of(fact.category, theme.brightness).border
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(_radius),
        border: frame == null
            ? Border.all(color: surfaces.border)
            : Border.all(color: frame, width: _partnerBorderWidth),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // A partner card says so in place of its category.
    final hasOffer =
        !fact.isPartner && OfferScope.offerFor(context, fact) != null;
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Expanded(
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
              if (hasOffer)
                PillBadge(
                  icon: Icons.handshake_outlined,
                  label: 'Partner',
                  color: colors.onSurfaceVariant,
                  background: theme.extension<AppSurfaces>()!.card,
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
              ?_buildPartnerOffer(context),
            ],
          ),
        ),
      ),
    );
  }

  /// A button of its own and not a link in the text, so a swipe across the
  /// card cannot open it by accident. A drag that starts on it still moves
  /// the card, because the deck's drag wins over a tap once the finger moves.
  Widget? _buildPartnerOffer(BuildContext context) {
    if (!fact.isPartner) return null;
    final offer = OfferScope.offerFor(context, fact);
    if (offer == null) return null;

    final style = CategoryStyle.of(fact.category, Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: FilledButton(
        onPressed: () => _openOffer(context, offer),
        style: FilledButton.styleFrom(
          backgroundColor: style.background,
          foregroundColor: style.color,
          minimumSize: const Size(0, _minTapHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          side: BorderSide(color: style.border ?? style.color),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(
          '${offer.product} · ${offer.shop} ›',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Opens in the browser, outside the app, so the partner can save the
  /// visit in its cookie.
  Future<void> _openOffer(BuildContext context, FactOffer offer) async {
    OfferScope.reportOpened(context, fact);
    final opened = await const LinkService().open(offer.url);
    if (opened || !context.mounted) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Nie udało się otworzyć linku.')),
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
