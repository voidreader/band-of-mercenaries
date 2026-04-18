// band_of_mercenaries/lib/features/info/data/faction_state_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_join_service.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';

final factionStateRepositoryProvider = Provider((ref) => FactionStateRepository());

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
    final alreadyFound =
        state.clueRecords.any((r) => r.discoveryId == discoveryId);
    state.clueRecords.add(FactionClueRecord(
      factionId: factionId,
      regionId: regionId,
      discoveryId: discoveryId,
      foundAt: foundAt,
    ));
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
    state.reputation =
        FactionJoinService.clampReputation(newRep, joined: state.isJoined);
    await state.save();
  }

  Future<void> setReputation(String factionId, int rep) async {
    final state = await _getOrCreate(factionId);
    state.reputation =
        FactionJoinService.clampReputation(rep, joined: state.isJoined);
    await state.save();
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
