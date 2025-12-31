// lib/features/study/session_xp_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// XP earned only in the current study session. Resets when StudySessionView is disposed.
final sessionXpProvider = StateProvider.autoDispose<int>((ref) => 0);
