import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';

/// Storage values holding [facts], for `setMockInitialValues`.
Map<String, Object> storedFacts(List<Fact> facts) {
  return {
    'factContent': jsonEncode(facts.map((fact) => fact.toJson()).toList()),
    'factStates': jsonEncode({
      for (final fact in facts) fact.id: fact.state.toJson(),
    }),
  };
}
