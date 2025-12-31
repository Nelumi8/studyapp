import 'package:cloud_firestore/cloud_firestore.dart';

class UserMeta {
  final int totalXp;
  final int dailyXp;
  final String lastActiveDay; // UTC YYYY-MM-DD
  final int streak;
  final int level;

  const UserMeta({
    required this.totalXp,
    required this.dailyXp,
    required this.lastActiveDay,
    required this.streak,
    required this.level,
  });

  factory UserMeta.initial(String day) =>
      UserMeta(totalXp: 0, dailyXp: 0, lastActiveDay: day, streak: 0, level: 1);

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'dailyXp': dailyXp,
        'lastActiveDay': lastActiveDay,
        'streak': streak,
        'level': level,
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      };

  static String _utcDay(DateTime t) => t.toUtc().toIso8601String().substring(0,10);

  /// Transactional award with daily cap + streak logic
  static Future<int> awardOnAnswer({
    required FirebaseFirestore db,
    required String uid,
    required bool isCorrect,           // Good/Easy = true
    int baseXp = 10,
    int dailyCap = 100,
  }) async {
    if (!isCorrect) return 0;

    final metaRef = db.collection('users').doc(uid).collection('meta').doc('meta');
    final today = _utcDay(DateTime.now());

    return await db.runTransaction<int>((tx) async {
      final snap = await tx.get(metaRef);
      final data = snap.data();

      int totalXp = data?['totalXp'] is num ? (data!['totalXp'] as num).toInt() : 0;
      int dailyXp  = data?['dailyXp']  is num ? (data!['dailyXp']  as num).toInt() : 0;
      String last  = data?['lastActiveDay'] is String ? data!['lastActiveDay'] as String : today;
      int streak   = data?['streak']   is num ? (data!['streak']   as num).toInt() : 0;

      // rollover daily bucket
      if (last != today) {
        // streak advance if you earned XP yesterday
        final yesterday = DateTime.now().toUtc().subtract(const Duration(days:1))
                             .toIso8601String().substring(0,10);
        if (last == yesterday && dailyXp > 0) {
          streak += 1;
        } else {
          streak = dailyXp > 0 ? 1 : 0; // start fresh if gap
        }
        dailyXp = 0;
        last = today;
      }

      // streak multiplier: 1.0 + min(streak,10)*0.1  (cap 2.0)
      final double multiplier = (1.0 + (streak.clamp(0, 10) * 0.1)).clamp(1.0, 2.0);
      final int grant = (baseXp * multiplier).round();

      final int remaining = (dailyCap - dailyXp).clamp(0, dailyCap);
      final int applied = grant.clamp(0, remaining);

      if (applied > 0) {
        dailyXp += applied;
        totalXp += applied;
      }

      final level = (totalXp ~/ 100) + 1;

      tx.set(metaRef, {
        'totalXp': totalXp,
        'dailyXp': dailyXp,
        'lastActiveDay': last,
        'streak': streak,
        'level': level,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return applied; // how much XP you actually got (0..cap)
    });
  }
}
