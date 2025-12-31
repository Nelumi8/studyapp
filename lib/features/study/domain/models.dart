class Flashcard {
  final String cardId;
  final String question;
  final String answer;

  Flashcard({
    required this.cardId,
    required this.question,
    required this.answer,
  });
}

class Deck {
  final String deckId;
  final String name;
  final String subject;
  final String topic;
  final List<Flashcard> cards;

  Deck({
    required this.deckId,
    required this.name,
    required this.subject,
    required this.topic,
    required this.cards,
  });
}
