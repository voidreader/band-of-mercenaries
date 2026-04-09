import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final speedMultiplierProvider = StateProvider<double>((ref) => 1.0);

final gameTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

/// 속도 변경 시 활성 타이머의 endTime을 재계산하는 유틸리티.
DateTime? recalculateEndTime(DateTime? endTime, DateTime? startTime, double oldSpeed, double newSpeed) {
  if (endTime == null || startTime == null) return endTime;
  final now = DateTime.now();
  if (now.isAfter(endTime)) return endTime; // 이미 완료됨
  final remainingMs = endTime.difference(now).inMilliseconds;
  final remainingBaseMs = (remainingMs * oldSpeed).round();
  final newRemainingMs = (remainingBaseMs / newSpeed).round();
  return now.add(Duration(milliseconds: newRemainingMs));
}
