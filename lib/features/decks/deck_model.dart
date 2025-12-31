import 'package:meta/meta.dart';

@immutable
class Flashcard {
  final String id;

  // canonical fields
  final String question;
  final String answer;

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
  });

  // compatibility with existing UI code
  String get front => question;
  String get back  => answer;
}

@immutable
class Deck {
  final String id;
  final String title;
  final String subject;
  final String topic;
  final List<Flashcard> cards;

  const Deck({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.cards,
  });
}
