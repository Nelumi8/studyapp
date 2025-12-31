import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../decks/deck_model.dart';

class CsvDeckRepository {
  static const String _assetPath = 'assets/data/flashcards_gcse.csv';

  Future<List<Deck>> loadDecks() async {
    final csvString = await rootBundle.loadString(_assetPath);

    // Normalise line endings and split into lines
    final lines = const LineSplitter().convert(csvString.trim());

    if (lines.isEmpty) return [];

    // First line is the header – we assume the columns are in this order:
    // deck_id, deck_name, subject, topic, card_id, question, answer
    // (So we don't need to look them up by name anymore.)

    final Map<String, List<Flashcard>> cardsByDeck = {};
    final Map<String, (String deckName, String subject, String topic)>
        metaByDeck = {};

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;

      // TAB-separated
      final cols = line.split('\t');
      if (cols.length < 7) continue;

      final deckId   = cols[0].trim();
      final deckName = cols[1].trim();
      final subject  = cols[2].trim();
      final topic    = cols[3].trim();
      final cardId   = cols[4].trim();
      final question = cols[5].trim();
      final answer   = cols[6].trim();

      final card = Flashcard(
        id: cardId,
        question: question,
        answer: answer,
      );

      cardsByDeck.putIfAbsent(deckId, () => []).add(card);
      metaByDeck[deckId] = (deckName, subject, topic);
    }

    final List<Deck> decks = [];
    cardsByDeck.forEach((deckId, cards) {
      final meta = metaByDeck[deckId]!;
      decks.add(
        Deck(
          id: deckId,
          title: meta.$1,
          subject: meta.$2,
          topic: meta.$3,
          cards: cards,
        ),
      );
    });

    return decks;
  }
}
