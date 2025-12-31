import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamification/gamification_providers.dart'; // userMetaProvider
import '../decks/deck_model.dart';
import '../decks/deck_providers.dart';                // csvDecksProvider
import '../study/study_session_view.dart';           // StudySessionView

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metaAsync  = ref.watch(userMetaProvider);
    final decksAsync = ref.watch(csvDecksProvider);   // <- from CSV

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: metaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:  (e, _) => Center(child: Text('Error: $e')),
        data:   (m) {
          final totalXp = m?.xp ?? 0;
          final dailyXp = m?.dailyXp ?? 0;
          final streak  = m?.streak ?? 0;
          final level   = m?.level ?? ((totalXp ~/ 100) + 1);

          return decksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('Error loading decks: $e')),
            data:    (decks) {
              final hasDecks = decks.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your Progress',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _StatTile(label: 'Total XP', value: '$totalXp'),
                                _StatTile(label: 'Today',    value: '$dailyXp'),
                                _StatTile(label: 'Streak',   value: '$streak🔥'),
                                _StatTile(label: 'Level',    value: '$level'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          hasDecks ? 'Practice now' : 'No decks available',
                        ),
                        onPressed: hasDecks
                            ? () {
                                final Deck deck = decks.first; // first CSV deck
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudySessionView(deck: deck),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),

                    if (hasDecks) ...[
                      const SizedBox(height: 16),
                      Text('Demo Decks',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...decks.map(
                        (d) => Card(
                          child: ListTile(
                            title: Text(d.title),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudySessionView(deck: d),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),
                    Center(
                      child: Text(
                        m == null
                            ? 'No stats yet. Start a study session to see your progress.'
                            : 'Keep going! Your next review session will boost your streak.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
