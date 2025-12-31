import 'package:cloud_firestore/cloud_firestore.dart';
import 'srs_engine.dart';

class AttemptsRepository {
  AttemptsRepository(this._db);
  final FirebaseFirestore _db;

  /// Path: users/{uid}/attempts/{cardId}
  DocumentReference<Map<String, dynamic>> _doc(String uid, String cardId) =>
      _db.collection('users').doc(uid).collection('attempts').doc(cardId);

  Future<SrsState?> fetch(String uid, String cardId) async {
    final snap = await _doc(uid, cardId).get();
    if (!snap.exists) return null;
    return SrsState.fromJson(snap.data()!);
    }

  Future<void> save(String uid, String cardId, SrsState state) async {
    await _doc(uid, cardId).set(state.toJson(), SetOptions(merge: true));
  }
}
