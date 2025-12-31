import 'package:meta/meta.dart';

@immutable
class SrsState {
  final double ease;          // EF (SM-2). Typical start 2.5, min 1.3
  final int repetitions;      // successful reps (q>=3)
  final int intervalDays;     // last assigned interval in days
  final DateTime lastReviewed;
  final DateTime nextReview;

  const SrsState({
    required this.ease,
    required this.repetitions,
    required this.intervalDays,
    required this.lastReviewed,
    required this.nextReview,
  });

  factory SrsState.initial(DateTime now) => SrsState(
        ease: 2.5,
        repetitions: 0,
        intervalDays: 0,
        lastReviewed: now,
        nextReview: now, // due immediately
      );

  SrsState copyWith({
    double? ease,
    int? repetitions,
    int? intervalDays,
    DateTime? lastReviewed,
    DateTime? nextReview,
  }) =>
      SrsState(
        ease: ease ?? this.ease,
        repetitions: repetitions ?? this.repetitions,
        intervalDays: intervalDays ?? this.intervalDays,
        lastReviewed: lastReviewed ?? this.lastReviewed,
        nextReview: nextReview ?? this.nextReview,
      );

  Map<String, dynamic> toJson() => {
        'ease': ease,
        'repetitions': repetitions,
        'intervalDays': intervalDays,
        'lastReviewed': lastReviewed.toUtc().millisecondsSinceEpoch,
        'nextReview': nextReview.toUtc().millisecondsSinceEpoch,
      };

  factory SrsState.fromJson(Map<String, dynamic> j) => SrsState(
        ease: (j['ease'] as num).toDouble(),
        repetitions: j['repetitions'] as int,
        intervalDays: j['intervalDays'] as int,
        lastReviewed: DateTime.fromMillisecondsSinceEpoch(j['lastReviewed'], isUtc: true).toLocal(),
        nextReview: DateTime.fromMillisecondsSinceEpoch(j['nextReview'], isUtc: true).toLocal(),
      );
}

enum SrsQuality { again, good, easy }

class SrsEngine {
  /// Implements SM-2 with common tweaks.
  /// q mapping: Again=1, Good=3, Easy=5.
  SrsState review({SrsState? previous, required SrsQuality quality, DateTime? now}) {
    final DateTime t = now ?? DateTime.now();
    final prev = previous ?? SrsState.initial(t);

    final q = switch (quality) { SrsQuality.again => 1, SrsQuality.good => 3, SrsQuality.easy => 5 };

    double ef = prev.ease;
    int reps = prev.repetitions;
    int interval;

    // Update EF (easiness factor)
    // EF' = EF + (0.1 - (5-q)*(0.08 + (5-q)*0.02))
    ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (ef < 1.3) ef = 1.3;
    if (ef > 3.0) ef = 3.0;

    if (q < 3) {
      // Failed recall → schedule short, reset repetitions
      reps = 0;
      interval = 1; // keep it simple for MVP; you can make this minutes later
    } else {
      // Successful recall
      reps = reps + 1;
      if (reps == 1) {
        interval = 1;
      } else if (reps == 2) {
        interval = 6;
      } else {
        interval = (prev.intervalDays * ef).round().clamp(1, 3650);
      }
    }

    final next = t.add(Duration(days: interval));
    return SrsState(
      ease: ef,
      repetitions: reps,
      intervalDays: interval,
      lastReviewed: t,
      nextReview: next,
    );
  }
}
