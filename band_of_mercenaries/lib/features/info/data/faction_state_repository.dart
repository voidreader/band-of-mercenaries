// band_of_mercenaries/lib/features/info/data/faction_state_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_join_service.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_shop_daily_entry.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';

final factionStateRepositoryProvider = Provider(
  (ref) => FactionStateRepository(),
);

class FactionStateRepository {
  Box<FactionState> get _box =>
      Hive.box<FactionState>(HiveInitializer.factionStateBoxName);

  FactionState? getState(String factionId) {
    try {
      return _box.values.firstWhere((s) => s.factionId == factionId);
    } catch (_) {
      return null;
    }
  }

  List<FactionState> getAll() => _box.values.toList();

  List<String> getJoinedFactionIds() =>
      _box.values.where((s) => s.isJoined).map((s) => s.factionId).toList();

  /// 저장된 모든 세력의 현재 평판 맵을 반환한다.
  /// 반환값: factionId → currentReputation
  Map<String, int> getAllReputations() {
    final result = <String, int>{};
    for (final state in _box.values) {
      result[state.factionId] = state.currentReputation;
    }
    return result;
  }

  /// 특정 리전에서 발견된 세력별 단서 레벨 맵을 반환한다.
  /// 반환값: factionId → clueLevel (해당 리전 기준 고유 discoveryId 수, 0~3 클램프).
  /// 단서가 없는 세력은 맵에 포함되지 않는다.
  Map<String, int> getClueLevelsByRegion(int regionId) {
    final result = <String, int>{};
    for (final state in _box.values) {
      final regionDiscoveryIds = state.clueRecords
          .where((r) => r.regionId == regionId)
          .map((r) => r.discoveryId)
          .toSet();
      if (regionDiscoveryIds.isNotEmpty) {
        result[state.factionId] = regionDiscoveryIds.length.clamp(0, 3);
      }
    }
    return result;
  }

  // ─── Clue 처리 ───────────────────────────────────────────────

  Future<bool> processClue({
    required String factionId,
    required int regionId,
    required String discoveryId,
    required DateTime foundAt,
  }) async {
    final state = await _getOrCreate(factionId);
    final alreadyFound = state.clueRecords.any(
      (r) => r.discoveryId == discoveryId,
    );
    state.clueRecords.add(
      FactionClueRecord(
        factionId: factionId,
        regionId: regionId,
        discoveryId: discoveryId,
        foundAt: foundAt,
      ),
    );
    await state.save();
    return !alreadyFound;
  }

  // ─── 가입 / 탈퇴 ──────────────────────────────────────────────

  Future<void> join(String factionId) async {
    final state = await _getOrCreate(factionId);
    state.joined = true;
    state.joinedAt = DateTime.now();
    await state.save();
  }

  Future<void> leave(String factionId) async {
    final state = getState(factionId);
    if (state == null || !state.isJoined) return;
    state.joined = false;
    await state.save();
    // joinedAt 보존, facilityLevels 보존 (재가입 시 복구용)
  }

  /// 이해충돌 세력에 평판 -100 적용 (가입 시 호출)
  Future<void> applyConflictPenalty(List<String> conflictFactionIds) async {
    for (final id in conflictFactionIds) {
      final state = await _getOrCreate(id);
      // 충돌 세력이 가입 중이면 탈퇴 처리
      if (state.isJoined) {
        state.joined = false;
      }
      state.reputation = FactionJoinService.minReputation;
      await state.save();
    }
  }

  // ─── 평판 ──────────────────────────────────────────────────────

  Future<void> addReputation(String factionId, int delta) async {
    final state = await _getOrCreate(factionId);
    final newRep = state.currentReputation + delta;
    state.reputation = FactionJoinService.clampReputation(
      newRep,
      joined: state.isJoined,
    );
    await state.save();
  }

  Future<void> setReputation(String factionId, int rep) async {
    final state = await _getOrCreate(factionId);
    state.reputation = FactionJoinService.clampReputation(
      rep,
      joined: state.isJoined,
    );
    await state.save();
  }

  // ─── 세력 상점 구매 기록 (FR-D3) ──────────────────────────────

  /// once/daily 분기로 세력 상점 구매를 기록한다 (FR-D3).
  Future<void> recordShopPurchase({
    required String factionId,
    required String itemId,
    required bool isDaily,
    Duration? restockAfter,
  }) async {
    final state = await _getOrCreate(factionId);
    if (isDaily) {
      final daily = Map<String, FactionShopDailyEntry>.from(
        state.effectiveShopDailyPurchases,
      );
      final existing = daily[itemId];
      final now = DateTime.now();
      final restockAt = existing?.restockAt;
      final isRestocked = restockAt != null && !restockAt.isAfter(now);
      final newCount = isRestocked ? 1 : (existing?.count ?? 0) + 1;
      final newRestockAt = restockAfter != null
          ? now.add(restockAfter)
          : existing?.restockAt;
      daily[itemId] = FactionShopDailyEntry(
        count: newCount,
        restockAt: newRestockAt,
      );
      state.shopDailyPurchases = daily;
    } else {
      final history = Map<String, bool>.from(
        state.effectiveShopPurchaseHistory,
      );
      history[itemId] = true;
      state.shopPurchaseHistory = history;
    }
    await state.save();
  }

  // ─── 세력 보상 지급 기록 (FR-E5) ──────────────────────────────

  /// 세력 보상 지급 여부를 멱등으로 기록한다 (FR-E5).
  Future<void> markRewardGranted({
    required String factionId,
    required String rewardId,
  }) async {
    final state = await _getOrCreate(factionId);
    final ids = List<String>.from(state.effectiveGrantedRewardIds);
    if (ids.contains(rewardId)) return;
    ids.add(rewardId);
    state.grantedRewardIds = ids;
    await state.save();
  }

  /// 세력 보상 지급 여부를 동기 조회한다 (FR-E5).
  bool hasGrantedReward({required String factionId, required String rewardId}) {
    final state = getState(factionId);
    if (state == null) return false;
    return state.effectiveGrantedRewardIds.contains(rewardId);
  }

  // ─── 세력 연락처 해금 (FR-A6) ─────────────────────────────────

  /// 세력 연락처 해금 여부를 멱등으로 기록한다 (FR-A6).
  Future<void> markContactUnlocked({
    required String factionId,
    required String contactId,
  }) async {
    final state = await _getOrCreate(factionId);
    final ids = List<String>.from(state.effectiveContactUnlockedIds);
    if (ids.contains(contactId)) return;
    ids.add(contactId);
    state.contactUnlockedIds = ids;
    await state.save();
  }

  /// 세력 연락처 해금 여부를 동기 조회한다 (FR-A6).
  bool hasContactUnlocked({
    required String factionId,
    required String contactId,
  }) {
    final state = getState(factionId);
    if (state == null) return false;
    return state.effectiveContactUnlockedIds.contains(contactId);
  }

  // ─── 내부 헬퍼 ─────────────────────────────────────────────────

  Future<FactionState> _getOrCreate(String factionId) async {
    var state = getState(factionId);
    if (state == null) {
      state = FactionState(factionId: factionId);
      await _box.add(state);
    }
    return state;
  }
}
