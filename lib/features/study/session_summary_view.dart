// lib/features/study/session_summary_view.dart
import 'package:flutter/material.dart';
import '../decks/deck_model.dart';
import 'study_session_view.dart';

class SessionSummaryView extends StatelessWidget {
  final Deck deck;
  final int cardsReviewed;
  final int xpEarned;

  const SessionSummaryView({
    super.key,
    required this.deck,
    required this.cardsReviewed,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Session Summary')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(deck.title, style: t.textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Cards reviewed: $cardsReviewed', style: t.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('XP earned: $xpEarned', style: t.textTheme.headlineSmall),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    // Start a fresh run of this same deck
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => StudySessionView(deck: deck),
                      ),
                    );
                  },
                  child: const Text('Redo all now'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
