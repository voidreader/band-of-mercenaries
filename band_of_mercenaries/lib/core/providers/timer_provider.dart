import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/constants/m7_constants.dart';
import 'package:band_of_mercenaries/features/investigation/data/region_state_repository.dart';

final speedMultiplierProvider = StateProvider<double>((ref) => 1.0);

final gameTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// 속도 변경 시 활성 타이머의 endTime을 재계산하는 유틸리티.
DateTime? recalculateEndTime(
  DateTime? endTime,
  DateTime? startTime,
  double oldSpeed,
  double newSpeed,
) {
  if (endTime == null || startTime == null) return endTime;
  final now = DateTime.now();
  if (now.isAfter(endTime)) return endTime; // 이미 완료됨
  final remainingMs = endTime.difference(now).inMilliseconds;
  final remainingBaseMs = (remainingMs * oldSpeed).round();
  final newRemainingMs = (remainingBaseMs / newSpeed).round();
  return now.add(Duration(milliseconds: newRemainingMs));
}

// decay 적용 최소 간격 (시간)
const _decayIntervalHours = 12;

/// M7 페이즈 4 #1 FR-4d — 위험도 점수 decay Provider.
///
/// 60틱(60초)마다 리빙스피어 리전을 순회하여 dangerScore가 음수인 경우
/// +1 decay를 적용한다. 마지막 decay 체크로부터 12시간 이상 경과한 경우에만 실행.
/// app.dart build()에서 ref.watch(regionDangerDecayProvider)로 1회 활성화.
final regionDangerDecayProvider = Provider<void>((ref) {
  int tickCount = 0;
  ref.listen(gameTickProvider, (prev, next) {
    next.whenData((now) async {
      tickCount++;
      if (tickCount % 60 != 0) return;
      final repo = ref.read(regionStateRepositoryProvider);
      for (final regionId in M7Constants.livingsphereRegions) {
        final state = repo.getState(regionId);
        if (state == null) continue;
        if (state.currentDangerScore >= 0) continue;
        final last = repo.getLastDecayCheckedAt(regionId);
        if (now.difference(last).inHours < _decayIntervalHours) continue;
        try {
          await repo.addDangerScore(
            regionId: regionId,
            delta: 1,
            source: 'decay',
            ref: ref,
          );
          await repo.updateLastDecayCheckedAt(regionId, now);
        } on Exception catch (e) {
          debugPrint('[M7] decay trailing 실패 (region $regionId): $e');
        }
      }
    });
  });
});
