// lib/features/profile/profile_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamification/gamification_providers.dart'; // userMetaProvider
import '../auth/auth_providers.dart';                 // auth state (email/uid)

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final metaAsync = ref.watch(userMetaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: userAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Auth error: $e'),
                data: (u) {
                  final email       = u?.email ?? '(no email)';
                  final uid         = u?.uid ?? '';
                  final displayName = u?.displayName;
                  final photoUrl    = u?.photoURL;

                  final primaryLabel =
                      (displayName != null && displayName.isNotEmpty)
                          ? displayName
                          : email;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                primaryLabel
                                    .trim()
                                    .characters
                                    .first
                                    .toUpperCase(),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryLabel,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            if (displayName != null &&
                                displayName.isNotEmpty)
                              Text(
                                email,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              uid,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Gamification
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: metaAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Meta error: $e'),
                data: (m) {
                  final totalXp = m?.xp ?? 0;
                  final dailyXp = m?.dailyXp ?? 0;
                  final streak  = m?.streak ?? 0;
                  final level   = m?.level ?? ((totalXp ~/ 100) + 1);
                  final last    = m?.lastActiveDate ?? '—';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Chip(label: Text('XP $totalXp')),
                          Chip(label: Text('Today $dailyXp')),
                          Chip(label: Text('Streak $streak🔥')),
                          Chip(label: Text('Level $level')),
                          Chip(label: Text('Last active $last')),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
