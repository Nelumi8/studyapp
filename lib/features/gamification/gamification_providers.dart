// lib/features/gamification/gamification_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_providers.dart';

/// Strongly typed model for user metadata
class UserMeta {
  final int xp;                 // total XP (backward compatible with totalXp)
  final int level;
  final int streak;
  final int? dailyXp;           // optional if you track daily XP
  final String? lastActiveDate;

  const UserMeta({
    required this.xp,
    required this.level,
    required this.streak,
    this.dailyXp,
    this.lastActiveDate,
  });

  factory UserMeta.fromJson(Map<String, dynamic> json) {
    final xpVal = (json['xp'] ?? json['totalXp'] ?? 0) as int;
    final levelVal = (json['level'] ?? 0) as int;
    final streakVal = (json['streak'] ?? 0) as int;

    int? daily;
    final dx = json['dailyXp'];
    if (dx is num) daily = dx.toInt();

    return UserMeta(
      xp: xpVal,
      level: levelVal,
      streak: streakVal,
      dailyXp: daily,
      lastActiveDate: json['lastActiveDate'] as String?,
    );
  }

  /// Legacy compatibility so existing code using m?['key'] still compiles
  dynamic operator [](String key) {
    switch (key) {
      case 'xp':
      case 'totalXp':
        return xp;
      case 'level':
        return level;
      case 'streak':
        return streak;
      case 'dailyXp':
        return dailyXp;
      case 'lastActiveDate':
        return lastActiveDate;
      default:
        return null;
    }
  }
}

/// Watches the current user’s gamification metadata in Firestore
final userMetaProvider = StreamProvider<UserMeta?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return const Stream.empty();

  final doc = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('meta')
      .doc('meta');

  return doc.snapshots().map((s) {
    final data = s.data();
    return data == null ? null : UserMeta.fromJson(data);
  });
});
