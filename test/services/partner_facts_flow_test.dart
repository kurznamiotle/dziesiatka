import 'dart:convert';

import 'package:dziesiatka/services/daily_deck_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/streak_service.dart';
import 'package:dziesiatka/services/supabase_fact_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/keep_order_random.dart';

/// The whole way of a partner fact from the server to a deck, with rows
/// shaped like those `partner_facts()` returns.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> partnerRow(String id, String product) {
    return {
      'id': id,
      'title': 'Ośmiornica myśli inaczej',
      'category': 'Ciekawostka partnerska',
      'kind': 'partner',
      'short_text': 'Większość neuronów ośmiornicy siedzi w ramionach.',
      'long_text': 'Rozwinięcie.',
      'source_label': 'Peter Godfrey-Smith',
      'source_url': null,
      'quiz': null,
      'review_note': null,
      'status': 'published',
      'offer': {
        'url': 'https://www.znak.com.pl/tt-redirect?tt=1',
        'shop': 'Znak',
        'product': product,
      },
      'created_at': '2026-11-25T14:39:34.306856+00:00',
      'updated_at': '2026-11-25T14:39:34.306856+00:00',
    };
  }

  late DateTime now;
  late FactsService facts;

  DailyDeckService deckService() {
    return DailyDeckService(
      facts,
      StreakService(now: () => now),
      now: () => now,
      random: const KeepOrderRandom(),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 25, 16);
    final client = MockClient((request) async {
      final body = request.url.path.endsWith('rpc/partner_facts')
          ? [
              partnerRow('partner-001', 'Inne umysły – Peter Godfrey-Smith'),
              partnerRow('partner-002', 'Geniusz ptaków – Jennifer Ackerman'),
            ]
          : <Object>[];
      return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
    });
    facts = FactsService(
      remote: SupabaseFactSource(
        url: 'https://example.supabase.co',
        publishableKey: 'klucz',
        client: client,
      ),
    );
  });

  test('a download joins today\'s deck behind the current card', () async {
    final logs = <String>[];
    final service = DailyDeckService(
      facts,
      StreakService(now: () => now),
      now: () => now,
      random: const KeepOrderRandom(),
      log: logs.add,
    );
    final first = await service.loadToday();
    expect(logs.single, contains('brak kart partnerskich na urządzeniu'));
    await service.completeCard(first.remaining.first.id, liked: false);

    await facts.syncWithRemote();
    final today = await service.addDownloadedPartner();

    expect(today.facts, hasLength(11));
    final partners = today.remaining.where((fact) => fact.isPartner);
    expect(partners, hasLength(1));
    expect(today.remaining.first.isPartner, isFalse);
    expect(today.remaining.last.isPartner, isFalse);
    expect(today.deck.quizFactIds, isNot(contains(partners.single.id)));
    expect(logs.last, contains('dołącza do dzisiejszej talii'));

    // A second download adds nothing more.
    final again = await service.addDownloadedPartner();
    expect(again.facts, hasLength(11));
    expect(logs.last, contains('talia ma już kartę partnerską'));
  });

  test('a downloaded partner fact reaches the next deck', () async {
    // A fresh install: the first deck comes from the bundled facts only.
    final first = await deckService().loadToday();
    expect(first.facts.where((fact) => fact.isPartner), isEmpty);

    await facts.syncWithRemote();
    final stored = await facts.getFacts();
    expect(stored.where((fact) => fact.isPartner), hasLength(2));

    now = now.add(const Duration(days: 1));
    final next = await deckService().loadToday();

    expect(next.facts.where((fact) => fact.isPartner), hasLength(1));
    expect(next.facts, hasLength(11));
  });
}
