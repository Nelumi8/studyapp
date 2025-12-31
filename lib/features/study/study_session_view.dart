// lib/features/study/study_session_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../decks/deck_model.dart';
import 'srs_engine.dart';
import 'attempts_repository.dart';
import 'study_providers.dart'; // for uidProvider

import 'package:cloud_firestore/cloud_firestore.dart';

// Service that awards XP/streak/level (aliased to avoid name clash with model UserMeta)
import '../gamification/user_meta_service.dart' as svc;

// Session XP provider (alias to avoid any ambiguous import)
import 'session_xp_provider.dart' as sxp;

// Summary screen
import 'session_summary_view.dart';

// ---------- Behaviour toggles ----------

// Continuous practice: every answered card re-queues so the session never ends
// until the user taps "End session". If false, only "Again" re-queues (classic SRS).
const bool CONTINUOUS_PRACTICE = true;

// When true, ignore Firestore due logic and just queue a short local sample (dev only).
const bool DEV_FORCE_LOCAL_QUEUE = false;

class StudySessionView extends ConsumerStatefulWidget {
  final Deck deck;
  const StudySessionView({super.key, required this.deck});

  @override
  ConsumerState<StudySessionView> createState() => _StudySessionViewState();
}

class _StudySessionViewState extends ConsumerState<StudySessionView> {
  final _engine = SrsEngine();

  bool _loading = true;
  bool showBack = false;

  // Indices of cards in this session
  List<int> _queue = [];
  int _cursor = 0;

  // Cache of attempts loaded at session start: cardId -> last known SRS state
  final Map<String, SrsState?> _attempts = {};

  @override
  void initState() {
    super.initState();
    // Reset session XP at the start of a session
    Future.microtask(() {
      ref.read(sxp.sessionXpProvider.notifier).state = 0;
    });
    _initSession();
  }

  Future<void> _initSession() async {
    final cards = widget.deck.cards;
    debugPrint('[Study] deck.cards=${cards.length}');

    if (DEV_FORCE_LOCAL_QUEUE) {
      final take = math.min(5, cards.length);
      setState(() {
        _queue = List<int>.generate(take, (i) => i);
        _cursor = 0;
        showBack = false;
        _loading = false;
      });
      debugPrint('[Study] DEV queue=${_queue.length}');
      return;
    }

    // ---- Normal path (due-based) ----
    try {
      final uid = ref.read(uidProvider);
      if (uid == null) throw StateError('No UID');

      final repo = ref.read(attemptsRepoProvider);
      final now = DateTime.now();

      final fetched = await Future.wait(cards.map((c) async {
        try {
          return await repo.fetch(uid, c.id);
        } catch (_) {
          return null;
        }
      }));

      for (var i = 0; i < cards.length; i++) {
        _attempts[cards[i].id] = fetched[i];
      }

      final due = <int>[];
      for (int i = 0; i < cards.length; i++) {
        final st = _attempts[cards[i].id];
        if (st == null || !st.nextReview.isAfter(now)) {
          due.add(i);
        }
      }

      setState(() {
        _queue = due.isEmpty
            ? List<int>.generate(math.min(5, cards.length), (i) => i)
            : due;
        _cursor = 0;
        showBack = false;
        _loading = false;
      });
      debugPrint('[Study] queue=${_queue.length} (due=${due.length})');
    } catch (e) {
      // Fallback: short sample
      final take = math.min(5, cards.length);
      setState(() {
        _queue = List<int>.generate(take, (i) => i);
        _cursor = 0;
        showBack = false;
        _loading = false;
      });
      debugPrint('[Study] fallback queue=${_queue.length} due to $e');
    }
  }

  void _flip() => setState(() => showBack = !showBack);

  /// Restart the session (optionally shuffled)
  void _restartSession({bool shuffle = true}) {
    final n = widget.deck.cards.length;
    final newQueue = List<int>.generate(n, (i) => i);
    if (shuffle) newQueue.shuffle();
    setState(() {
      _queue = newQueue;
      _cursor = 0;
      showBack = false;
    });
    ref.read(sxp.sessionXpProvider.notifier).state = 0;
  }

  Future<void> _answer(SrsQuality q) async {
    final uid = ref.read(uidProvider);
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
      return;
    }

    final repo = ref.read(attemptsRepoProvider);
    final cardIndex = _queue[_cursor];
    final card = widget.deck.cards[cardIndex];

    // Compute next SRS state from previous (if any)
    final prev = _attempts[card.id];
    final next = _engine.review(previous: prev, quality: q);
    _attempts[card.id] = next;

    // Save attempt
    try {
      await repo.save(uid, card.id, next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }

    // XP award on correct answers (Good / Easy)
    final isCorrect = (q == SrsQuality.good || q == SrsQuality.easy);
    if (isCorrect) {
      try {
        final applied = await svc.UserMeta.awardOnAnswer(
          db: FirebaseFirestore.instance,
          uid: uid,
          isCorrect: true,
          baseXp: 10,
          dailyCap: 100,
        );
        if (mounted && applied > 0) {
          ref.read(sxp.sessionXpProvider.notifier).update((v) => v + applied);
        }
      } catch (e) {
        debugPrint('XP award failed: $e');
      }
    }

    // Re-queue rule
    if (CONTINUOUS_PRACTICE) {
      // Every answered card re-queues
      _queue.add(cardIndex);
    } else {
      // Classic SRS: only "Again" stays in this session
      if (q == SrsQuality.again) _queue.add(cardIndex);
    }

    // Advance
    setState(() {
      _cursor++;
      showBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = _queue.length;

    // UNIQUE cards for session completion + display
    final uniqueTotal = _queue.toSet().length;
    final uniqueDone = _cursor == 0
        ? 0
        : _queue.take(_cursor).toSet().length; // cards fully answered so far
    final uniqueRemain = (uniqueTotal - uniqueDone).clamp(0, uniqueTotal);
    final progress = uniqueTotal == 0
        ? 0.0
        : (uniqueDone / uniqueTotal).clamp(0.0, 1.0);

    // Session is done once we've seen all unique cards at least once
    final isDone = uniqueDone >= uniqueTotal && uniqueTotal > 0;

    if (isDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final sessionXp = ref.read(sxp.sessionXpProvider);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SessionSummaryView(
              deck: widget.deck,
              cardsReviewed: uniqueDone,
              xpEarned: sessionXp,
            ),
          ),
        );
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Still in-session
    final deckIndex = _queue[_cursor];
    final card = widget.deck.cards[deckIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.deck.title}  •  $uniqueDone/$uniqueTotal  (left: $uniqueRemain)',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
        actions: [
          // End session any time
          IconButton(
            tooltip: 'End session',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: () {
              setState(() {
                // Treat as "all seen"
                _cursor = _queue.length;
              });
            },
          ),
          // Quick restart (reshuffle)
          IconButton(
            tooltip: 'Restart session',
            icon: const Icon(Icons.refresh),
            onPressed: () => _restartSession(shuffle: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Flip card (with simple 3D animation)
              Expanded(
                child: GestureDetector(
                  onTap: _flip,
                  child: TweenAnimationBuilder<double>(
                    tween:
                        Tween<double>(begin: 0, end: showBack ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      final angle = value * math.pi; // 0..π
                      final isFront = angle <= math.pi / 2;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // subtle perspective
                          ..rotateY(angle),
                        child: Card(
                          elevation: 2,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: isFront
                                  ? Text(
                                      card.front,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    )
                                  : Transform(
                                      alignment: Alignment.center,
                                      transform:
                                          Matrix4.rotationY(math.pi),
                                      child: Text(
                                        card.back,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Dev overlay: EF & nextReview (helps verify SRS)
              Opacity(
                opacity: 0.6,
                child: Text(
                  () {
                    final st = _attempts[card.id];
                    final ef = (st?.ease ?? 2.5).toStringAsFixed(2);
                    final next = st?.nextReview
                            .toLocal()
                            .toString()
                            .split('.')
                            .first ??
                        '—';
                    return 'EF: $ef  ·  next: $next';
                  }(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              if (!showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _flip,
                    child: const Text('Show answer'),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => _answer(SrsQuality.again),
                      child: const Text('Again'),
                    ),
                    FilledButton(
                      onPressed: () => _answer(SrsQuality.good),
                      child: const Text('Good'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _answer(SrsQuality.easy),
                      child: const Text('Easy'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
