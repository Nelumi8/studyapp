import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_providers.dart';
import 'attempts_repository.dart';


final attemptsRepoProvider = Provider<AttemptsRepository>((ref) {
  return AttemptsRepository(FirebaseFirestore.instance);
});

/// Current UID (non-null after AuthGate)
final uidProvider = Provider<String?>((ref) => ref.watch(authStateProvider).value?.uid);