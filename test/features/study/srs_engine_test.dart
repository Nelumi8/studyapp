import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/features/study/srs_engine.dart'; 

void main() {
  final engine = SrsEngine();
  final now = DateTime(2025, 1, 1);

  test('initial review with Good sets interval=1 and reps=1', () {
    final next = engine.review(previous: null, quality: SrsQuality.good, now: now);
    expect(next.repetitions, 1);
    expect(next.intervalDays, 1);
    expect(next.nextReview.difference(now).inDays, 1);
  });

  test('again resets repetitions and sets short interval', () {
    final prev = engine.review(previous: null, quality: SrsQuality.good, now: now);
    final next = engine.review(previous: prev, quality: SrsQuality.again, now: now);
    expect(next.repetitions, 0);
    expect(next.intervalDays, 1);
  });

  test('three goods grow interval using EF', () {
    var s = engine.review(previous: null, quality: SrsQuality.good, now: now); // day 1
    s = engine.review(previous: s, quality: SrsQuality.good, now: now.add(const Duration(days: 1))); // day 6
    s = engine.review(previous: s, quality: SrsQuality.good, now: now.add(const Duration(days: 7))); // ~6*EF
    expect(s.repetitions, 3);
    expect(s.intervalDays >= 6, true);
    expect(s.ease >= 1.3, true);
  });

  test('EF bounded at 1.3 min', () {
    var s = SrsState.initial(now);
    for (int i = 0; i < 10; i++) {
      s = engine.review(previous: s, quality: SrsQuality.again, now: now);
    }
    expect(s.ease >= 1.3, true);
  });

  test('easy increases EF and interval grows more than good', () {
  final now = DateTime(2025,1,1);
  final engine = SrsEngine();
  var g = engine.review(previous: null, quality: SrsQuality.good, now: now);
  g = engine.review(previous: g, quality: SrsQuality.good, now: now.add(const Duration(days: 1)));
  var e = engine.review(previous: null, quality: SrsQuality.good, now: now);
  e = engine.review(previous: e, quality: SrsQuality.easy, now: now.add(const Duration(days: 1)));
  expect(e.ease > g.ease, true);
  expect(e.intervalDays >= g.intervalDays, true);
  });

}
