import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountService {
  final FirebaseFirestore db;
  DeleteAccountService({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;

  Future<void> deleteUserData(String uid) async {
    // Adjust these paths to match your real schema

    final userDoc = db.collection('users').doc(uid);

    // Delete attempts / SRS state subcollection
    final attemptsSnap =
        await userDoc.collection('attempts').get(); // if you use 'attempts'
    for (final doc in attemptsSnap.docs) {
      await doc.reference.delete();
    }

    // Delete meta doc
    final metaDoc = userDoc.collection('meta').doc('meta');
    await metaDoc.delete();

    // Finally delete user doc itself
    await userDoc.delete();
  }
}
