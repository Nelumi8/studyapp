import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deck_model.dart';
import '../study/data/csv_deck_repository.dart';

/// Loads decks from the CSV asset asynchronously.
final csvDecksProvider = FutureProvider<List<Deck>>((ref) async {
  final repo = CsvDeckRepository();
  return repo.loadDecks();
});
