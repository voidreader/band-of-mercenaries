import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/region_state_model.dart';
import 'package:band_of_mercenaries/features/investigation/domain/trust_level_up_event.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';

final regionStateRepositoryProvider = Provider((ref) => RegionStateRepository());

class RegionStateRepository {
  Box<RegionState> get _box => Hive.box<RegionState>(HiveInitializer.regionStateBoxName);

  // ─── 신뢰도 단계 임계값 (단계 → 최소 누적 점수) ─────────────────────────
  static const Map<int, int> _trustThresholds = {1: 0, 2: 30, 3: 80, 4: 200};

  // 단계 진입 일회성 보상 (단계 → 보상). 1단계는 초기값이라 보상 없음.
  // 여러 단계를 한 번에 통과할 때 합산하는 이유: amount가 크면 1단계를 건너뛸 수 있으므로
  // 중간 단계 보상을 빠짐없이 지급해야 공정하다.
  static const Map<int, ({int gold, int xp, int rep})> _trustRewards = {
    2: (gold: 100, xp: 50, rep: 0),
    3: (gold: 200, xp: 100, rep: 0),
    4: (gold: 500, xp: 200, rep: 100),
  };

  // 단계별 한국어 명칭
  static const Map<int, String> _trustLevelNames = {1: '의심', 2: '인지', 3: '친근', 4: '소속'};

  RegionState? getState(int regionId) {
    try {
      return _box.values.firstWhere((s) => s.regionId == regionId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveState(RegionState state) async {
    final existing = getState(state.regionId);
    if (existing == null) {
      await _box.add(state);
    } else {
      await existing.save();
    }
  }

  // knowledge를 delta만큼 증가시키고 clamp(0, 100), 업데이트된 RegionState 반환
  Future<RegionState> updateKnowledge(int regionId, int delta) async {
    var state = getState(regionId);
    if (state == null) {
      state = RegionState(regionId: regionId);
      await _box.add(state);
    }
    state.knowledge = (state.knowledge + delta).clamp(0, 100);
    await state.save();
    return state;
  }

  Future<void> addTriggeredDiscovery(int regionId, String discoveryId) async {
    final state = getState(regionId);
    if (state == null) return;
    if (!state.triggeredDiscoveries.contains(discoveryId)) {
      state.triggeredDiscoveries.add(discoveryId);
      await state.save();
    }
  }

  // 섹터 변환을 적용한다. MVP: 리전당 최대 1섹터 변형 제약. 성공 시 true 반환
  Future<bool> applyTransform({
    required int regionId,
    required int sectorIndex,
    required String transformType,
  }) async {
    var state = getState(regionId);
    if (state == null) {
      state = RegionState(regionId: regionId);
      await _box.add(state);
    }

    // MVP: 리전당 최대 1섹터 변형 제약
    if (state.sectorChanges.isNotEmpty) return false;

    final key = sectorIndex.toString();
    if (state.sectorChanges.containsKey(key)) return false;

    state.sectorChanges[key] = transformType;
    await state.save();
    return true;
  }

  // ─── 마을 신뢰도 조회 ──────────────────────────────────────────────────────

  /// 현재 신뢰도 점수와 단계를 반환한다. RegionState가 없으면 초기값 (trust:0, level:1)
  ({int trust, int level}) getSettlementTrust(int regionId) {
    final state = getState(regionId);
    if (state == null) return (trust: 0, level: 1);
    return (trust: state.currentTrust, level: state.currentTrustLevel);
  }

  // ─── 마을 신뢰도 디버그 설정 ───────────────────────────────────────────────

  /// 운영·디버그 전용 직접 설정. 일회성 보상 우회, publish/ActivityLog/XP 부여 없음.
  Future<void> setSettlementTrust(int regionId, int trust, int level) async {
    var state = getState(regionId) ?? RegionState(regionId: regionId);
    state.settlementTrust = trust;
    state.settlementTrustLevel = level;
    await saveState(state);
  }

  // ─── 마을 신뢰도 증가 (핵심 메서드) ──────────────────────────────────────

  /// 신뢰도 점수를 [amount]만큼 증가시킨다.
  ///
  /// 단계 승급 발생 시 통과한 모든 단계의 보상을 합산 지급하고
  /// [settlementTrustLevelUpProvider]에 이벤트를 publish한다.
  Future<({int newTrust, int newLevel, TrustLevelUpEvent? levelUpEvent})> addSettlementTrust({
    required int regionId,
    required int amount,
    required String source,
    required Ref ref,
  }) async {
    // amount가 0이면 변경 없음 — addReputation 패턴 모방
    if (amount == 0) {
      final current = getSettlementTrust(regionId);
      return (newTrust: current.trust, newLevel: current.level, levelUpEvent: null);
    }

    var state = getState(regionId) ?? RegionState(regionId: regionId);
    final oldLevel = state.currentTrustLevel;

    state.settlementTrust = (state.currentTrust + amount).clamp(0, 999999);

    // 임계값 표를 순회하여 새 단계 계산 (오름차순 순회로 최고 충족 단계 확정)
    int newLevel = 1;
    for (final entry in _trustThresholds.entries) {
      if (state.settlementTrust! >= entry.value) newLevel = entry.key;
    }
    state.settlementTrustLevel = newLevel;

    await saveState(state);

    TrustLevelUpEvent? event;

    if (newLevel > oldLevel) {
      // 중간 단계를 한 번에 건너뛴 경우를 포함해 통과한 모든 단계 보상 합산
      int rewardGold = 0, rewardXp = 0, rewardRep = 0;
      for (int lv = oldLevel + 1; lv <= newLevel; lv++) {
        final r = _trustRewards[lv];
        if (r == null) continue;
        rewardGold += r.gold;
        rewardXp += r.xp;
        rewardRep += r.rep;
      }

      // 보상 지급
      if (rewardGold > 0) {
        await ref.read(userDataProvider.notifier).addGold(rewardGold);
      }
      if (rewardRep > 0) {
        await ref.read(userDataProvider.notifier).addReputation(rewardRep);
      }
      if (rewardXp > 0) {
        await _grantXpEvenly(ref, rewardXp);
      }

      // 거점명 동적 조회 — 미발견 시 '시작 거점' fallback
      final staticData = ref.read(staticDataProvider).valueOrNull;
      final settlementName = staticData?.regions
              .where((r) => r.region == regionId)
              .map((r) => r.regionName)
              .firstOrNull ??
          '시작 거점';

      ref.read(activityLogProvider.notifier).addLog(
        '마을 신뢰도가 $newLevel단계(${_trustLevelNames[newLevel]})에 도달했다',
        ActivityLogType.settlementTrustUp,
      );

      event = TrustLevelUpEvent(
        regionId: regionId,
        fromLevel: oldLevel,
        toLevel: newLevel,
        settlementName: settlementName,
        rewardGold: rewardGold > 0 ? rewardGold : null,
        rewardXp: rewardXp > 0 ? rewardXp : null,
        rewardReputation: rewardRep > 0 ? rewardRep : null,
      );

      // 신뢰도 단계 승급 이벤트 발행
      ref.read(settlementTrustLevelUpProvider.notifier).state = event;

      // 단계 승급 후 퀘스트 풀 갱신 (min_trust_level 조건 재평가)
      await ref.read(questListProvider.notifier).refreshAvailableQuests();
    }

    return (newTrust: state.settlementTrust!, newLevel: newLevel, levelUpEvent: event);
  }

  // ─── 내부 헬퍼 ────────────────────────────────────────────────────────────

  /// 살아있는 용병 전원에게 XP를 균등 분배한다.
  /// 정수 나눗셈 잔여분은 0번째 용병에게 가산.
  Future<void> _grantXpEvenly(Ref ref, int totalXp) async {
    final mercRepo = ref.read(mercenaryRepositoryProvider);
    final aliveList = mercRepo.getAll()
        .where((m) => m.status != MercenaryStatus.dead)
        .toList();
    if (aliveList.isEmpty) return;
    final per = totalXp ~/ aliveList.length;
    final remainder = totalXp - (per * aliveList.length);
    for (int i = 0; i < aliveList.length; i++) {
      final xp = per + (i == 0 ? remainder : 0);
      if (xp > 0) {
        await mercRepo.addXpAndCheckLevel(aliveList[i].id, xp);
      }
    }
  }
}
