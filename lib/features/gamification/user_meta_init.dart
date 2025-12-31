import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String _utcDay(DateTime t) => t.toUtc().toIso8601String().substring(0, 10);

/// Idempotent: ensures /users/{uid}/meta/meta exists with sane defaults.
/// Safe to call on every app entry after login.
Future<void> ensureUserMeta() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final doc = FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('meta').doc('meta');

  final today = _utcDay(DateTime.now());

  await doc.set({
    'totalXp': 0,
    'dailyXp': 0,
    'lastActiveDay': today,
    'streak': 0,
    'level': 1,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
