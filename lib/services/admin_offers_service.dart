import 'dart:math';

import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/offer_entry.dart';
import 'package:dziesiatka/models/offer_status.dart';
import 'package:dziesiatka/models/offers_summary.dart';

/// Works out the panel's list of offers from the facts it has loaded.
class AdminOffersService {
  const AdminOffersService();

  static final _partnerIdPattern = RegExp(r'^partner-(\d+)$');

  /// Every offer the app may show: partner facts and regular facts with an
  /// offer, without withdrawn or rejected ones. Partner facts come first,
  /// then the soonest to end.
  List<OfferEntry> entries(
    List<AdminFact> facts,
    Map<String, FactUsage> usage,
    DateTime now,
  ) {
    final hasClicks = usage.values.any((item) => item.hasOfferClicks);
    final result = [
      for (final fact in facts)
        if (fact.offer case final offer?
            when fact.status != AdminFact.withdrawn &&
                fact.status != AdminFact.rejected)
          OfferEntry(
            fact: fact,
            offer: offer,
            status: offer.statusOn(now),
            clicks: hasClicks ? usage[fact.id]?.offerClicked ?? 0 : null,
          ),
    ];
    String endOf(OfferEntry entry) => entry.offer.until ?? '9999-12-31';
    result.sort((first, second) {
      if (first.fact.isPartner != second.fact.isPartner) {
        return first.fact.isPartner ? -1 : 1;
      }
      return endOf(first).compareTo(endOf(second));
    });
    return result;
  }

  /// Drafts are not in the app, so they count as neither active nor ending.
  OffersSummary summarize(List<OfferEntry> entries) {
    final known = entries.where((entry) => entry.clicks != null);
    final shown = entries.where(
      (entry) => entry.fact.status == AdminFact.published,
    );
    return OffersSummary(
      active: shown.where((entry) => entry.status != OfferStatus.ended).length,
      endingSoon: shown
          .where((entry) => entry.status == OfferStatus.endingSoon)
          .length,
      clicks: entries.isNotEmpty && known.length == entries.length
          ? known.fold<int>(0, (sum, entry) => sum + entry.clicks!)
          : null,
    );
  }

  /// Regular facts that can take an offer, matching [query] in the title,
  /// short text or id.
  List<AdminFact> withoutOffer(List<AdminFact> facts, String query) {
    final text = query.trim().toLowerCase();
    return facts.where((fact) {
      if (fact.isPartner || fact.offer != null) return false;
      if (fact.status == AdminFact.rejected) return false;
      if (text.isEmpty) return true;
      return fact.title.toLowerCase().contains(text) ||
          fact.shortText.toLowerCase().contains(text) ||
          fact.id.toLowerCase().contains(text);
    }).toList();
  }

  /// Partner facts get their own numbers, apart from the `fact-` ids that
  /// imports count.
  String nextPartnerId(List<AdminFact> facts) {
    final last = facts.fold(0, (last, fact) {
      final match = _partnerIdPattern.firstMatch(fact.id);
      return match == null ? last : max(last, int.parse(match.group(1)!));
    });
    return 'partner-${(last + 1).toString().padLeft(3, '0')}';
  }
}
