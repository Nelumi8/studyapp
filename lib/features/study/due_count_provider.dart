import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_providers.dart';
import '../decks/deck_model.dart';

final dueCountProvider = FutureProvider.family<int, Deck>((ref, deck) async {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return deck.cards.length; // treat all as due if signed-out (shouldn't happen)
  final db = FirebaseFirestore.instance;
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

  // naive: 1 read per card; fine for small decks. Batch later if needed.
  final checks = await Future.wait(deck.cards.map((c) async {
    final snap = await db.collection('users').doc(uid).collection('attempts').doc(c.id).get();
    if (!snap.exists) return true;
    final data = snap.data()!;
    final next = (data['nextReview'] as num?)?.toInt();
    final ts   = data['nextReview']; // allow Timestamp too
    final nextMs = next ?? (ts is Timestamp ? ts.millisecondsSinceEpoch : 0);
    return nextMs <= nowMs;
  }));
  return checks.where((x) => x).length;
});
