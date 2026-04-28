import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/mercenary/data/mercenary_repository.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';
import 'package:band_of_mercenaries/features/facility/domain/construction_service.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/passive_bonus_service.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/evolution_choice.dart';

final mercenaryRepositoryProvider = Provider((ref) => MercenaryRepository());

final mercenaryListProvider = StateNotifierProvider<MercenaryListNotifier, List<Mercenary>>((ref) {
  return MercenaryListNotifier(ref);
});

class MercenaryListNotifier extends StateNotifier<List<Mercenary>> {
  final Ref ref;
  late final MercenaryRepository _repo;

  MercenaryListNotifier(this.ref) : super([]) {
    _repo = ref.read(mercenaryRepositoryProvider);
    _load();
    ref.listen(gameTickProvider, (prev, next) => _checkTimers());
    // 첫 실행 시 initializeNewGame() 완료 후 용병 목록 다시 로드
    ref.listen(userDataProvider, (prev, next) {
      if (prev == null && next != null) {
        debugPrint('[BOM][Merc] userDataProvider null→non-null 감지 → _load 재실행');
        _load();
      }
    });
  }

  void _load() {
    state = _repo.getAll();
    debugPrint('[BOM][Merc] _load: ${state.length}명');
  }

  void refresh() => _load();

  /// 트레잇 진화 선택 결과를 적용한다.
  /// view(`_showTraitEvents`)가 EvolutionChoice를 받아 본 메서드에 위임한다.
  ///
  /// 책임:
  /// 1. Repository 호출 (단일/조합 분기)
  /// 2. 트레잇 이름 lookup (ActivityLog 메시지용)
  /// 3. ActivityLog "진화!" 메시지 기록 (트레잇/staticData lookup 실패 시 skip)
  /// 4. state refresh
  Future<void> applyEvolution(String mercId, EvolutionChoice choice) async {
    final merc = state.where((m) => m.id == mercId).firstOrNull;
    if (merc == null) return;

    final staticData = ref.read(staticDataProvider).value;

    if (choice.isSingle && choice.single != null) {
      final s = choice.single!;
      await _repo.evolveTrait(mercId, s.fromKey, s.toKey);
      if (staticData != null) {
        final fromTrait = staticData.traits.where((t) => t.key == s.fromKey).firstOrNull;
        final toTrait = staticData.traits.where((t) => t.key == s.toKey).firstOrNull;
        if (fromTrait != null && toTrait != null) {
          ref.read(activityLogProvider.notifier).addLog(
            '${merc.name}의 "${fromTrait.name}"이(가) "${toTrait.name}"(으)로 진화!',
            ActivityLogType.traitEvolved,
          );
        }
      }
    } else if (!choice.isSingle && choice.combo != null) {
      final c = choice.combo!;
      await _repo.comboEvolveTrait(mercId, c.trait1Key, c.trait2Key, c.resultKey);
      if (staticData != null) {
        final t1 = staticData.traits.where((t) => t.key == c.trait1Key).firstOrNull;
        final t2 = staticData.traits.where((t) => t.key == c.trait2Key).firstOrNull;
        final result = staticData.traits.where((t) => t.key == c.resultKey).firstOrNull;
        if (t1 != null && t2 != null && result != null) {
          ref.read(activityLogProvider.notifier).addLog(
            '${merc.name}의 "${t1.name}" + "${t2.name}" → "${result.name}"(으)로 조합 진화!',
            ActivityLogType.traitEvolved,
          );
        }
      }
    }
    refresh();
  }

  void _checkTimers() {
    final now = DateTime.now();
    bool changed = false;
    for (final merc in state) {
      if (merc.status == MercenaryStatus.tired && merc.tiredEndTime != null) {
        if (now.isAfter(merc.tiredEndTime!)) {
          merc.status = MercenaryStatus.normal;
          merc.tiredEndTime = null;
          merc.save();
          changed = true;
        }
      }
      if (merc.status == MercenaryStatus.injured && merc.injuryEndTime != null) {
        if (now.isAfter(merc.injuryEndTime!)) {
          merc.status = MercenaryStatus.normal;
          merc.injuryEndTime = null;
          merc.save();
          changed = true;
        }
      }
    }
    if (changed) _load();
  }

  void recalculateTimers(double oldSpeed, double newSpeed) {
    bool changed = false;
    for (final merc in state) {
      if (merc.status == MercenaryStatus.tired && merc.tiredEndTime != null) {
        final newEnd = recalculateEndTime(merc.tiredEndTime, merc.tiredEndTime, oldSpeed, newSpeed);
        if (newEnd != merc.tiredEndTime) {
          merc.tiredEndTime = newEnd;
          merc.save();
          changed = true;
        }
      }
      if (merc.status == MercenaryStatus.injured && merc.injuryEndTime != null) {
        final newEnd = recalculateEndTime(merc.injuryEndTime, merc.injuryEndTime, oldSpeed, newSpeed);
        if (newEnd != merc.injuryEndTime) {
          merc.injuryEndTime = newEnd;
          merc.save();
          changed = true;
        }
      }
    }
    if (changed) _load();
  }

  Future<bool> dismiss(String mercId, int severancePay) async {
    final userData = ref.read(userDataProvider);
    if (userData == null || userData.gold < severancePay) return false;

    final merc = state.firstWhere((m) => m.id == mercId);
    if (merc.isDispatched) return false;

    // 정수 투입 합산 (삭제 이전에 계산)
    final totalPermanent = merc.permanentStr
        + merc.permanentIntelligence
        + merc.permanentVit
        + merc.permanentAgi;

    await ref.read(userDataProvider.notifier).spendGold(severancePay);
    await _repo.dismiss(mercId);
    _load();

    final logType = totalPermanent > 0
        ? ActivityLogType.essenceLostOnRelease
        : ActivityLogType.mercenaryDismiss;
    final message = totalPermanent > 0
        ? '용병 "${merc.name}" 방출 (퇴직금: ${severancePay}G, 투입 정수 누적 +$totalPermanent 소실)'
        : '용병 "${merc.name}" 방출 (퇴직금: ${severancePay}G)';
    ref.read(activityLogProvider.notifier).addLog(message, logType);

    return true;
  }

  Future<Mercenary?> recruit() async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return null;

    // 주둔지 용량 제한 체크
    final userData = ref.read(userDataProvider);
    final barracksData = staticData.facilities.where((f) => f.id == 'barracks').firstOrNull;
    if (userData != null && barracksData != null) {
      final barracksLevel = userData.facilities['barracks'] ?? 0;
      final maxMercs = FacilityService.getMaxMercenaries(barracksData, barracksLevel);
      final aliveCount = state.where((m) => m.status != MercenaryStatus.dead).length;
      if (aliveCount >= maxMercs) {
      debugPrint('[BOM][Merc] 모집 실패: 용량 초과 ($aliveCount/$maxMercs)');
      return null;
    }
    }

    // 주점 시설 보너스 계산
    double recruitBonus = 0.0;
    final tavernFacility = staticData.facilities.where((f) => f.id == 'tavern').firstOrNull;
    if (userData != null && tavernFacility != null) {
      final tavernLevel = userData.facilities['tavern'] ?? 0;
      recruitBonus = ConstructionService.getEffectValue(tavernFacility, tavernLevel);
    }

    // 세력 패시브 기반 고티어(T4~T5) 확률 부스트 계산
    double extraHighTierBoost = 0.0;
    if (userData != null) {
      final joinedIds = ref.read(factionStateRepositoryProvider).getJoinedFactionIds();
      final joinedFactions = staticData.factions.where((f) => joinedIds.contains(f.id)).toList();
      final effects = PassiveBonusService.collect(
        reputation: userData.reputation,
        allRanks: staticData.ranks,
        joinedFactions: joinedFactions,
      );
      extraHighTierBoost = PassiveBonusService.getRecruitmentTierBoost(effects);
    }

    final merc = await _repo.recruit(
      jobs: staticData.jobs,
      traits: staticData.traits,
      categories: staticData.traitCategories,
      names: staticData.personNames,
      recruitBonus: recruitBonus,
      extraHighTierBoost: extraHighTierBoost,
    );
    debugPrint('[BOM][Merc] 모집 성공: ${merc.name} (job: ${merc.jobId})');
    ref.read(activityLogProvider.notifier).addLog(
      '용병 "${merc.name}" 모집 완료',
      ActivityLogType.mercenaryRecruit,
    );
    _load();
    return merc;
  }
}
