# Faction Core System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 세력 가입/평판/이해충돌 시스템의 데이터 모델·비즈니스 로직·UI를 구현한다.

**Architecture:** FactionData(정적 Supabase 데이터)에 visibilityType·joinRankMin·passiveBonusJson·conflictFactionIds 필드를 추가하고, FactionState(Hive)에 reputation·joined를 추가한다. 순수 로직은 FactionJoinService(정적 클래스)에 분리해 테스트하고, FactionStateRepository가 Hive 쓰기를 담당한다. UI 갱신은 `factionRefreshProvider`(StateProvider<int>) 카운터로 트리거한다.

**Tech Stack:** Flutter, Riverpod (StateNotifierProvider 패턴), Hive, freezed/json_serializable, build_runner

---

## File Map

| 상태 | 경로 | 역할 |
|------|------|------|
| **수정** | `lib/features/info/domain/faction_data.dart` | visibilityType 등 5개 필드 추가 |
| **생성** (빌드) | `lib/features/info/domain/faction_data.freezed.dart` | 자동 생성 |
| **생성** (빌드) | `lib/features/info/domain/faction_data.g.dart` | 자동 생성 |
| **수정** | `lib/features/info/domain/faction_state_model.dart` | reputation, joined, joinedAt, facilityLevels HiveField 추가 |
| **생성** (빌드) | `lib/features/info/domain/faction_state_model.g.dart` | 자동 생성 |
| **신규** | `lib/features/info/domain/faction_join_service.dart` | 순수 비즈니스 로직 (가입 가능 여부, 평판 클램핑) |
| **신규** | `test/features/info/domain/faction_join_service_test.dart` | FactionJoinService 단위 테스트 |
| **수정** | `lib/features/info/data/faction_state_repository.dart` | join/leave/addReputation/setReputation 메서드 추가 |
| **수정** | `lib/features/info/domain/faction_codex_providers.dart` | factionRefreshProvider 추가 |
| **수정** | `lib/features/info/view/faction_codex_screen.dart` | 공개 세력 항상 표시, 평판 배지 |
| **수정** | `lib/features/info/view/faction_detail_screen.dart` | 평판 바, 가입/탈퇴 버튼, 이해충돌 경고, 패시브 보너스 |

> 모든 경로 루트: `band_of_mercenaries/`

---

## Task 1: FactionData 모델 확장

**Files:**
- Modify: `band_of_mercenaries/lib/features/info/domain/faction_data.dart`

새 필드 5개를 추가한다. `@Default`를 사용해 기존 Supabase 데이터(새 컬럼 없음)에서도 역직렬화가 깨지지 않도록 한다.

- [ ] **Step 1: faction_data.dart 수정**

```dart
// band_of_mercenaries/lib/features/info/domain/faction_data.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'faction_data.freezed.dart';
part 'faction_data.g.dart';

@freezed
class FactionData with _$FactionData {
  const factory FactionData({
    required String id,
    required String name,
    required String description,
    required String philosophy,
    @JsonKey(name: 'tier_range') required List<int> tierRange,
    required String color,
    // 신규 필드 — Supabase 컬럼 추가 전까지 @Default로 호환
    @JsonKey(name: 'visibility_type') @Default('public') String visibilityType,
    @JsonKey(name: 'join_rank_min') String? joinRankMin,
    @JsonKey(name: 'join_needs_clue') @Default(false) bool joinNeedsClue,
    @JsonKey(name: 'passive_bonus_json')
    @Default(<String, dynamic>{})
    Map<String, dynamic> passiveBonusJson,
    @JsonKey(name: 'conflict_faction_ids')
    @Default(<String>[])
    List<String> conflictFactionIds,
  }) = _FactionData;

  factory FactionData.fromJson(Map<String, dynamic> json) =>
      _$FactionDataFromJson(json);
}
```

- [ ] **Step 2: build_runner 실행**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

Expected: `faction_data.freezed.dart`, `faction_data.g.dart` 재생성됨. 에러 없음.

- [ ] **Step 3: 정적 분석 확인**

```bash
cd band_of_mercenaries && flutter analyze lib/features/info/domain/faction_data.dart
```

Expected: `No issues found!`

- [ ] **Step 4: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/info/domain/faction_data.dart lib/features/info/domain/faction_data.freezed.dart lib/features/info/domain/faction_data.g.dart
git commit -m "feat: extend FactionData with visibility, join conditions, passive bonus, conflict ids"
```

---

## Task 2: FactionState Hive 모델 확장

**Files:**
- Modify: `band_of_mercenaries/lib/features/info/domain/faction_state_model.dart`

HiveField 번호는 기존 0·1에 이어 2~5번 추가. 기존 Hive 데이터 호환 유지 (Hive는 append-only).

- [ ] **Step 1: faction_state_model.dart 수정**

```dart
// band_of_mercenaries/lib/features/info/domain/faction_state_model.dart
import 'package:hive/hive.dart';

part 'faction_state_model.g.dart';

@HiveType(typeId: 10)
class FactionClueRecord extends HiveObject {
  @HiveField(0)
  late String factionId;

  @HiveField(1)
  late int regionId;

  @HiveField(2)
  late String discoveryId;

  @HiveField(3)
  late DateTime foundAt;

  FactionClueRecord({
    required this.factionId,
    required this.regionId,
    required this.discoveryId,
    required this.foundAt,
  });
}

@HiveType(typeId: 9)
class FactionState extends HiveObject {
  @HiveField(0)
  late String factionId;

  @HiveField(1)
  late List<FactionClueRecord> clueRecords;

  // 신규 필드 (기존 Hive 데이터는 null로 읽히므로 생성자에서 0/false/{} 기본값 처리)
  @HiveField(2)
  late int reputation;

  @HiveField(3)
  late bool joined;

  @HiveField(4)
  DateTime? joinedAt;

  @HiveField(5)
  late Map<String, int> facilityLevels;

  FactionState({
    required this.factionId,
    List<FactionClueRecord>? clueRecords,
    this.reputation = 0,
    this.joined = false,
    this.joinedAt,
    Map<String, int>? facilityLevels,
  })  : clueRecords = clueRecords ?? [],
        facilityLevels = facilityLevels ?? {};

  List<int> get discoveredInRegions =>
      clueRecords.map((r) => r.regionId).toSet().toList();

  int get maxClueLevel {
    final uniqueCount = clueRecords.map((r) => r.discoveryId).toSet().length;
    return uniqueCount.clamp(0, 3);
  }
}
```

- [ ] **Step 2: build_runner 실행**

```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

Expected: `faction_state_model.g.dart` 재생성됨. 에러 없음.

- [ ] **Step 3: 정적 분석 확인**

```bash
cd band_of_mercenaries && flutter analyze lib/features/info/domain/faction_state_model.dart
```

Expected: `No issues found!`

- [ ] **Step 4: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/info/domain/faction_state_model.dart lib/features/info/domain/faction_state_model.g.dart
git commit -m "feat: extend FactionState Hive model with reputation, joined, facilityLevels"
```

---

## Task 3: FactionJoinService (TDD)

**Files:**
- Create: `band_of_mercenaries/lib/features/info/domain/faction_join_service.dart`
- Create: `band_of_mercenaries/test/features/info/domain/faction_join_service_test.dart`

Hive 없이 동작하는 순수 정적 클래스. 가입 가능 여부 판별·평판 클램핑·랭크 비교 로직을 담는다.

- [ ] **Step 1: 테스트 파일 작성**

```dart
// band_of_mercenaries/test/features/info/domain/faction_join_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_join_service.dart';

void main() {
  group('FactionJoinService.canJoin', () {
    const baseArgs = (
      factionId: 'faction_a',
      reputation: 1,
      joinNeedsClue: false,
      maxClueLevel: 0,
      joinRankMin: null,
      currentRank: 'F',
      conflictFactionIds: <String>[],
      currentlyJoinedFactionIds: <String>[],
    );

    test('평판 0이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 0,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isFalse,
      );
    });

    test('평판 -1이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: -1,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isFalse,
      );
    });

    test('clue 필요한데 maxClueLevel 2이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: true,
          maxClueLevel: 2,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isFalse,
      );
    });

    test('clue 필요하고 maxClueLevel 3이면 clue 조건 통과', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: true,
          maxClueLevel: 3,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isTrue,
      );
    });

    test('joinRankMin D인데 현재 랭크 E이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: 'D',
          currentRank: 'E',
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isFalse,
      );
    });

    test('joinRankMin D인데 현재 랭크 D이면 가입 가능', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: 'D',
          currentRank: 'D',
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isTrue,
      );
    });

    test('이해충돌 세력이 이미 가입되어 있으면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: 'faction_a',
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: const ['faction_b'],
          currentlyJoinedFactionIds: const ['faction_b'],
        ),
        isFalse,
      );
    });

    test('이미 3개 가입 중이면 가입 불가', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: const ['x', 'y', 'z'],
        ),
        isFalse,
      );
    });

    test('모든 조건 충족 시 가입 가능', () {
      expect(
        FactionJoinService.canJoin(
          factionId: baseArgs.factionId,
          reputation: 5,
          joinNeedsClue: baseArgs.joinNeedsClue,
          maxClueLevel: baseArgs.maxClueLevel,
          joinRankMin: baseArgs.joinRankMin,
          currentRank: baseArgs.currentRank,
          conflictFactionIds: baseArgs.conflictFactionIds,
          currentlyJoinedFactionIds: baseArgs.currentlyJoinedFactionIds,
        ),
        isTrue,
      );
    });
  });

  group('FactionJoinService.clampReputation', () {
    test('미가입 상태에서 +11 시도 → 10으로 클램핑', () {
      expect(FactionJoinService.clampReputation(11, joined: false), 10);
    });

    test('미가입 상태에서 10은 그대로', () {
      expect(FactionJoinService.clampReputation(10, joined: false), 10);
    });

    test('가입 후에는 100까지 허용', () {
      expect(FactionJoinService.clampReputation(80, joined: true), 80);
    });

    test('최소값 -100 이하는 클램핑', () {
      expect(FactionJoinService.clampReputation(-200, joined: true), -100);
    });

    test('최대값 100 이상은 클램핑', () {
      expect(FactionJoinService.clampReputation(150, joined: true), 100);
    });
  });

  group('FactionJoinService.isRankSufficient', () {
    test('F는 F 이상 통과', () => expect(FactionJoinService.isRankSufficient('F', 'F'), isTrue));
    test('E는 F 이상 통과', () => expect(FactionJoinService.isRankSufficient('E', 'F'), isTrue));
    test('E는 D 이상 미통과', () => expect(FactionJoinService.isRankSufficient('E', 'D'), isFalse));
    test('B는 C 이상 통과', () => expect(FactionJoinService.isRankSufficient('B', 'C'), isTrue));
    test('A는 모든 랭크 통과', () => expect(FactionJoinService.isRankSufficient('A', 'B'), isTrue));
  });

  group('FactionJoinService.describePassiveBonus', () {
    test('탐험 보상 +15%', () {
      final result = FactionJoinService.describePassiveBonus({'explore_reward_pct': 15});
      expect(result, contains('탐험 퀘스트 보상 +15%'));
    });

    test('복수 보너스', () {
      final result = FactionJoinService.describePassiveBonus({
        'escort_reward_pct': 15,
        'idle_reward_pct': 10,
      });
      expect(result, contains('호위 퀘스트 보상 +15%'));
      expect(result, contains('방치 보상 +10%'));
    });

    test('빈 맵 → 빈 문자열', () {
      expect(FactionJoinService.describePassiveBonus({}), isEmpty);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행해서 실패 확인**

```bash
cd band_of_mercenaries && flutter test test/features/info/domain/faction_join_service_test.dart
```

Expected: FAIL — `faction_join_service.dart` 없음

- [ ] **Step 3: FactionJoinService 구현**

```dart
// band_of_mercenaries/lib/features/info/domain/faction_join_service.dart

class FactionJoinService {
  static const int maxReputationBeforeJoin = 10;
  static const int minReputation = -100;
  static const int maxReputation = 100;

  static const List<String> _rankOrder = ['F', 'E', 'D', 'C', 'B', 'A'];

  /// 가입 가능 여부 판별
  static bool canJoin({
    required String factionId,
    required int reputation,
    required bool joinNeedsClue,
    required int maxClueLevel,
    required String? joinRankMin,
    required String currentRank,
    required List<String> conflictFactionIds,
    required List<String> currentlyJoinedFactionIds,
  }) {
    if (reputation <= 0) return false;
    if (joinNeedsClue && maxClueLevel < 3) return false;
    if (joinRankMin != null && !isRankSufficient(currentRank, joinRankMin)) {
      return false;
    }
    for (final conflictId in conflictFactionIds) {
      if (currentlyJoinedFactionIds.contains(conflictId)) return false;
    }
    if (currentlyJoinedFactionIds.length >= 3) return false;
    return true;
  }

  /// 평판 클램핑 (미가입 시 최대 10, 가입 후 최대 100)
  static int clampReputation(int rep, {required bool joined}) {
    final cap = joined ? maxReputation : maxReputationBeforeJoin;
    return rep.clamp(minReputation, cap);
  }

  /// 랭크 충분 여부 (currentRank >= requiredRank)
  static bool isRankSufficient(String currentRank, String requiredRank) {
    final currentIdx = _rankOrder.indexOf(currentRank);
    final requiredIdx = _rankOrder.indexOf(requiredRank);
    if (currentIdx < 0 || requiredIdx < 0) return false;
    return currentIdx >= requiredIdx;
  }

  /// passiveBonusJson을 한국어 설명 문자열로 변환
  static String describePassiveBonus(Map<String, dynamic> json) {
    if (json.isEmpty) return '';
    final parts = <String>[];
    void add(String key, String desc) {
      final val = json[key];
      if (val != null) parts.add(desc.replaceAll('{v}', val.toString()));
    }
    add('explore_reward_pct', '탐험 퀘스트 보상 +{v}%');
    add('escort_reward_pct', '호위 퀘스트 보상 +{v}%');
    add('raid_hunt_success_pct', '약탈/토벌 퀘스트 성공률 +{v}%');
    add('idle_reward_pct', '방치 보상 +{v}%');
    add('investigation_success_pct', '지역 조사 성공률 +{v}%');
    add('travel_damage_pct', '이동 이벤트 피해 -{v}%');
    add('injury_recovery_pct', '부상 회복 속도 +{v}%');
    add('all_quest_success_pct', '모든 퀘스트 성공률 +{v}%');
    add('trait_evolution_ease_pct', '트레잇 진화 조건 완화 {v}%');
    add('trait_acquisition_ease_pct', '트레잇 획득 조건 완화 {v}%');
    add('construction_time_pct', '시설 건설 시간 -{v}%');
    add('construction_cost_pct', '시설 건설 비용 -{v}%');
    add('facility_effect_pct', '시설 효과 +{v}%');
    add('high_tier_recruit_pct', 'T4~T5 용병 모집 확률 +{v}%');
    add('group_success_pct', '3명 이상 파견 시 성공률 +{v}%');
    add('raid_reward_pct', '약탈 퀘스트 보상 +{v}%');
    add('escort_success_pct', '호위 퀘스트 성공률 +{v}%');
    add('injury_recovery_time_pct', '부상 회복 시간 -{v}%');
    return parts.join('\n');
  }
}
```

- [ ] **Step 4: 테스트 실행해서 통과 확인**

```bash
cd band_of_mercenaries && flutter test test/features/info/domain/faction_join_service_test.dart -v
```

Expected: 모든 테스트 PASS

- [ ] **Step 5: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/info/domain/faction_join_service.dart test/features/info/domain/faction_join_service_test.dart
git commit -m "feat: add FactionJoinService with reputation clamping and join validation"
```

---

## Task 4: FactionStateRepository 확장 + factionRefreshProvider

**Files:**
- Modify: `band_of_mercenaries/lib/features/info/data/faction_state_repository.dart`
- Modify: `band_of_mercenaries/lib/features/info/domain/faction_codex_providers.dart`

join/leave/addReputation 메서드 추가. UI 갱신을 위해 `factionRefreshProvider` (StateProvider<int>)를 추가.

- [ ] **Step 1: faction_codex_providers.dart에 factionRefreshProvider 추가**

```dart
// band_of_mercenaries/lib/features/info/domain/faction_codex_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';

/// 세력 도감 자동 스크롤 타깃 Provider
final factionCodexScrollTargetProvider = StateProvider<String?>((ref) => null);

/// 세력 목록 Provider (staticDataProvider에서 동기 추출)
final factionListProvider = Provider<List<FactionData>>((ref) {
  return ref.watch(staticDataProvider).value?.factions ?? const [];
});

/// UI 갱신 트리거 Provider — join/leave/평판 변경 후 increment
final factionRefreshProvider = StateProvider<int>((ref) => 0);
```

- [ ] **Step 2: faction_state_repository.dart 확장**

```dart
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
      _box.values.where((s) => s.joined).map((s) => s.factionId).toList();

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
    if (state == null || !state.joined) return;
    state.joined = false;
    await state.save();
    // joinedAt 보존, facilityLevels 보존 (재가입 시 복구용)
  }

  /// 이해충돌 세력에 평판 -100 적용 (가입 시 호출)
  Future<void> applyConflictPenalty(List<String> conflictFactionIds) async {
    for (final id in conflictFactionIds) {
      final state = await _getOrCreate(id);
      // 충돌 세력이 가입 중이면 탈퇴 처리
      if (state.joined) {
        state.joined = false;
      }
      state.reputation = FactionJoinService.minReputation;
      await state.save();
    }
  }

  // ─── 평판 ──────────────────────────────────────────────────────

  Future<void> addReputation(String factionId, int delta) async {
    final state = await _getOrCreate(factionId);
    final newRep = state.reputation + delta;
    state.reputation =
        FactionJoinService.clampReputation(newRep, joined: state.joined);
    await state.save();
  }

  Future<void> setReputation(String factionId, int rep) async {
    final state = await _getOrCreate(factionId);
    state.reputation =
        FactionJoinService.clampReputation(rep, joined: state.joined);
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
```

- [ ] **Step 3: 정적 분석 확인**

```bash
cd band_of_mercenaries && flutter analyze lib/features/info/
```

Expected: No issues found!

- [ ] **Step 4: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/info/data/faction_state_repository.dart lib/features/info/domain/faction_codex_providers.dart
git commit -m "feat: extend FactionStateRepository with join/leave/reputation methods"
```

---

## Task 5: FactionCodexScreen 업데이트

**Files:**
- Modify: `band_of_mercenaries/lib/features/info/view/faction_codex_screen.dart`

**변경 사항:**
1. 공개 세력(`visibilityType == 'public'`)은 단서 없어도 항상 이름 표시
2. 세력 목록 정렬: 공개→발견된 비밀/지역→미발견 순
3. 가입된 세력에 "가입" 배지 표시

- [ ] **Step 1: faction_codex_screen.dart 교체**

```dart
// band_of_mercenaries/lib/features/info/view/faction_codex_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';

class FactionCodexScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onSelectFaction;

  const FactionCodexScreen({
    super.key,
    required this.onBack,
    required this.onSelectFaction,
  });

  @override
  ConsumerState<FactionCodexScreen> createState() =>
      _FactionCodexScreenState();
}

class _FactionCodexScreenState extends ConsumerState<FactionCodexScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeScrollToTarget();
    });
  }

  void _maybeScrollToTarget() {
    final targetId = ref.read(factionCodexScrollTargetProvider);
    if (targetId == null) return;

    final factions = ref.read(factionListProvider);
    final repo = ref.read(factionStateRepositoryProvider);
    final allStates = repo.getAll();
    final stateMap = _buildStateMap(allStates);
    final sorted = _sortedFactions(factions, stateMap);
    final index = sorted.indexWhere((f) => f.id == targetId);
    if (index < 0) return;

    const itemHeight = 76.0;
    final offset = (index * itemHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    ref.read(factionCodexScrollTargetProvider.notifier).state = null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, FactionState> _buildStateMap(List<FactionState> states) {
    return {for (final s in states) s.factionId: s};
  }

  bool _isVisible(FactionData faction, FactionState? state) {
    if (faction.visibilityType == 'public') return true;
    return state != null && state.clueRecords.isNotEmpty;
  }

  int _displayClueLevel(FactionData faction, FactionState? state) {
    if (faction.visibilityType == 'public') {
      // 공개 세력: 최소 level 1 (이름 항상 노출)
      return max(1, state?.maxClueLevel ?? 0);
    }
    return state?.maxClueLevel ?? 0;
  }

  List<FactionData> _sortedFactions(
    List<FactionData> factions,
    Map<String, FactionState> stateMap,
  ) {
    final publicFactions = <FactionData>[];
    final discovered = <FactionData>[];
    final undiscovered = <FactionData>[];

    for (final f in factions) {
      final state = stateMap[f.id];
      if (f.visibilityType == 'public') {
        publicFactions.add(f);
      } else if (state != null && state.clueRecords.isNotEmpty) {
        discovered.add(f);
      } else {
        undiscovered.add(f);
      }
    }

    // 발견된 비밀/지역 세력: clueLevel 내림차순
    discovered.sort((a, b) {
      final aLevel = stateMap[a.id]?.maxClueLevel ?? 0;
      final bLevel = stateMap[b.id]?.maxClueLevel ?? 0;
      return bLevel.compareTo(aLevel);
    });

    return [...publicFactions, ...discovered, ...undiscovered];
  }

  Color _parseFactionColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      final value = int.parse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // factionRefreshProvider를 watch해서 join/leave 후 자동 갱신
    ref.watch(factionRefreshProvider);

    final factions = ref.watch(factionListProvider);
    final repo = ref.read(factionStateRepositoryProvider);
    final allStates = repo.getAll();
    final stateMap = _buildStateMap(allStates);
    final sorted = _sortedFactions(factions, stateMap);

    final hasUndiscovered = factions.any((f) {
      if (f.visibilityType == 'public') return false;
      final state = stateMap[f.id];
      return state == null || state.clueRecords.isEmpty;
    });

    return Column(
      children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                color: AppTheme.textPrimary,
              ),
              const SizedBox(width: 4),
              const Text(
                '세력 도감',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length + (hasUndiscovered ? 1 : 0),
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              if (hasUndiscovered && index == sorted.length) {
                return _UnknownFactionRow();
              }
              final faction = sorted[index];
              final state = stateMap[faction.id];
              final clueLevel = _displayClueLevel(faction, state);
              final joined = state?.joined ?? false;

              return _FactionCard(
                faction: faction,
                clueLevel: clueLevel,
                joined: joined,
                factionColor: clueLevel >= 1
                    ? _parseFactionColor(faction.color)
                    : Colors.grey,
                onTap: () => widget.onSelectFaction(faction.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FactionCard extends StatelessWidget {
  final FactionData faction;
  final int clueLevel;
  final bool joined;
  final Color factionColor;
  final VoidCallback onTap;

  const _FactionCard({
    required this.faction,
    required this.clueLevel,
    required this.joined,
    required this.factionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: factionColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clueLevel >= 1 ? faction.name : '???',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (joined)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: factionColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: factionColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            '가입',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: factionColor,
                            ),
                          ),
                        )
                      else
                        _StarProgress(clueLevel: clueLevel),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clueLevel >= 2 ? faction.description : '???',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StarProgress extends StatelessWidget {
  final int clueLevel;
  const _StarProgress({required this.clueLevel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < clueLevel;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 16,
          color: filled ? Colors.amber : AppTheme.textHint,
        );
      }),
    );
  }
}

class _UnknownFactionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '??? (미발견 세력이 있습니다)',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: 정적 분석 확인**

```bash
cd band_of_mercenaries && flutter analyze lib/features/info/view/faction_codex_screen.dart
```

Expected: No issues found!

- [ ] **Step 3: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/info/view/faction_codex_screen.dart
git commit -m "feat: update FactionCodexScreen — public factions always visible, joined badge"
```

---

## Task 6: FactionDetailScreen 업데이트

**Files:**
- Modify: `band_of_mercenaries/lib/features/info/view/faction_detail_screen.dart`

**추가 섹션:**
1. **평판 바** — -100~+100, 가입 전 캡 10 표시
2. **가입 조건** — visibilityType별 조건 표시 (랭크, clue, 평판 > 0)
3. **가입/탈퇴 버튼** — canJoin 결과로 활성화, 이해충돌 세력명 경고
4. **패시브 보너스** — FactionJoinService.describePassiveBonus()

- [ ] **Step 1: faction_detail_screen.dart 교체**

```dart
// band_of_mercenaries/lib/features/info/view/faction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_join_service.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';

class FactionDetailScreen extends ConsumerWidget {
  final String factionId;
  final VoidCallback onBack;

  const FactionDetailScreen({
    super.key,
    required this.factionId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 가입/탈퇴 후 갱신 트리거
    ref.watch(factionRefreshProvider);

    final factions = ref.watch(factionListProvider);
    final faction = factions.where((f) => f.id == factionId).firstOrNull;

    final repo = ref.read(factionStateRepositoryProvider);
    final state = repo.getState(factionId);

    final clueLevel = _resolvedClueLevel(faction, state);
    final displayName = clueLevel >= 1 ? (faction?.name ?? '???') : '???';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(displayName: displayName, onBack: onBack),
          Expanded(
            child: faction == null
                ? const Center(
                    child: Text(
                      '세력 정보를 찾을 수 없습니다',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                  )
                : _FactionBody(
                    faction: faction,
                    state: state,
                    clueLevel: clueLevel,
                    onJoin: () => _handleJoin(context, ref, faction, repo),
                    onLeave: () => _handleLeave(ref, faction, repo),
                  ),
          ),
        ],
      ),
    );
  }

  int _resolvedClueLevel(FactionData? faction, FactionState? state) {
    if (faction == null) return 0;
    if (faction.visibilityType == 'public') {
      return (state?.maxClueLevel ?? 0).clamp(1, 3);
    }
    return state?.maxClueLevel ?? 0;
  }

  Future<void> _handleJoin(
    BuildContext context,
    WidgetRef ref,
    FactionData faction,
    FactionStateRepository repo,
  ) async {
    // 이해충돌 세력 탈퇴 경고 다이얼로그
    if (faction.conflictFactionIds.isNotEmpty) {
      final joinedFactionIds = repo.getJoinedFactionIds();
      final conflictingJoined = faction.conflictFactionIds
          .where((id) => joinedFactionIds.contains(id))
          .toList();

      if (conflictingJoined.isNotEmpty) {
        final staticData = ref.read(staticDataProvider).value;
        final conflictNames = conflictingJoined.map((id) {
          return staticData?.factions
                  .where((f) => f.id == id)
                  .firstOrNull
                  ?.name ??
              id;
        }).join(', ');

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text(
              '이해충돌 경고',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: Text(
              '$conflictNames\n\n위 세력과 이해충돌 관계입니다. 가입 시 해당 세력의 평판이 -100이 되고 탈퇴 처리됩니다.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  '가입',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await repo.applyConflictPenalty(conflictingJoined);
      }
    }

    await repo.join(faction.id);
    ref.read(factionRefreshProvider.notifier).state++;
  }

  Future<void> _handleLeave(
    WidgetRef ref,
    FactionData faction,
    FactionStateRepository repo,
  ) async {
    await repo.leave(faction.id);
    ref.read(factionRefreshProvider.notifier).state++;
  }
}

class _TopBar extends StatelessWidget {
  final String displayName;
  final VoidCallback onBack;

  const _TopBar({required this.displayName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 4,
        right: 16,
        bottom: 0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.textPrimary,
          ),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactionBody extends ConsumerWidget {
  final FactionData faction;
  final FactionState? state;
  final int clueLevel;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _FactionBody({
    required this.faction,
    required this.state,
    required this.clueLevel,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticDataAsync = ref.watch(staticDataProvider);
    final userData = ref.watch(userDataProvider);
    final repo = ref.read(factionStateRepositoryProvider);

    final clueRecords = state?.clueRecords ?? <FactionClueRecord>[];
    final sortedRecords = List<FactionClueRecord>.of(clueRecords)
      ..sort((a, b) => a.foundAt.compareTo(b.foundAt));
    final discoveredRegionIds =
        clueRecords.map((r) => r.regionId).toSet().toList();

    final reputation = state?.reputation ?? 0;
    final joined = state?.joined ?? false;

    // 가입 가능 여부 계산
    final allFactions = ref.watch(factionListProvider);
    final joinedIds = repo.getJoinedFactionIds();
    final currentRank = staticDataAsync.value?.ranks != null && userData != null
        ? _getCurrentRank(userData.reputation, staticDataAsync.value!.ranks)
        : 'F';

    final canJoin = !joined &&
        FactionJoinService.canJoin(
          factionId: faction.id,
          reputation: reputation,
          joinNeedsClue: faction.joinNeedsClue,
          maxClueLevel: clueLevel,
          joinRankMin: faction.joinRankMin,
          currentRank: currentRank,
          conflictFactionIds: faction.conflictFactionIds,
          currentlyJoinedFactionIds: joinedIds,
        );

    // 이해충돌 세력 이름
    final conflictNames = faction.conflictFactionIds.map((id) {
      return allFactions.where((f) => f.id == id).firstOrNull?.name ?? id;
    }).toList();

    final passiveDesc = FactionJoinService.describePassiveBonus(
        faction.passiveBonusJson);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 세력명 + 분류
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('세력명',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textHint)),
                        const SizedBox(height: 4),
                        Text(
                          clueLevel >= 1 ? faction.name : '???',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  _VisibilityBadge(visibilityType: faction.visibilityType),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 평판 바
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('세력 평판',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textHint)),
                  Text(
                    '$reputation / ${joined ? 100 : 10}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ReputationBar(reputation: reputation, joined: joined),
              if (!joined && reputation >= 1)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '가입 후 최대 100까지 상승 가능',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 가입 조건 + 버튼
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('가입',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 8),
              _JoinConditions(faction: faction, clueLevel: clueLevel,
                  currentRank: currentRank),
              if (conflictNames.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '이해충돌: ${conflictNames.join(', ')}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.orange),
                ),
              ],
              const SizedBox(height: 12),
              if (joined)
                OutlinedButton(
                  onPressed: onLeave,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                  child: const Text('탈퇴'),
                )
              else
                ElevatedButton(
                  onPressed: canJoin ? onJoin : null,
                  child: Text(canJoin ? '가입' : '가입 불가'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 패시브 보너스
        if (clueLevel >= 2 && passiveDesc.isNotEmpty) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('패시브 보너스 (가입 즉시)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Text(passiveDesc,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 설명
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('설명',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 4),
              Text(
                clueLevel >= 2 ? faction.description : '???',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 이념
        if (clueLevel >= 2) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이념',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Text(faction.philosophy,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 활동 티어
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('활동 티어',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 4),
              Text(
                clueLevel >= 2
                    ? '티어 ${faction.tierRange[0]}~${faction.tierRange[1]}'
                    : '???',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 발견 기록
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('발견 기록 (${sortedRecords.length}건)',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 4),
              if (sortedRecords.isEmpty)
                const Text('아직 발견된 기록이 없습니다',
                    style: TextStyle(fontSize: 13, color: AppTheme.textHint))
              else
                ...sortedRecords.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${r.foundAt.toLocal()} — regionId: ${r.regionId}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 발견 리전
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('발견 리전 (${discoveredRegionIds.length}곳)',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textHint)),
              const SizedBox(height: 4),
              if (discoveredRegionIds.isEmpty)
                const Text('아직 없음',
                    style: TextStyle(fontSize: 13, color: AppTheme.textHint))
              else
                staticDataAsync.maybeWhen(
                  data: (staticData) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: discoveredRegionIds.map((regionId) {
                      final region = staticData.regions
                          .where((r) => r.region == regionId)
                          .firstOrNull;
                      final name =
                          region?.regionName ?? 'regionId: $regionId';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          const Text('• ',
                              style:
                                  TextStyle(color: AppTheme.textTertiary)),
                          Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary))),
                        ]),
                      );
                    }).toList(),
                  ),
                  orElse: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: discoveredRegionIds
                        .map((id) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('regionId: $id',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary)),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCurrentRank(int reputation, List<Rank> ranks) {
    final sorted = List<Rank>.of(ranks)
      ..sort((a, b) => b.requiredReputation.compareTo(a.requiredReputation));
    for (final rank in sorted) {
      if (reputation >= rank.requiredReputation) return rank.grade;
    }
    return 'F';
  }
}

class _ReputationBar extends StatelessWidget {
  final int reputation;
  final bool joined;

  const _ReputationBar({required this.reputation, required this.joined});

  @override
  Widget build(BuildContext context) {
    // -100~+100 범위를 0.0~1.0으로 정규화
    final normalized = ((reputation + 100) / 200).clamp(0.0, 1.0);
    final color = reputation < 0
        ? Colors.red
        : reputation == 0
            ? AppTheme.textHint
            : Colors.green;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 8,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('-100', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
            Text('0', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
            Text('+100', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
          ],
        ),
      ],
    );
  }
}

class _JoinConditions extends StatelessWidget {
  final FactionData faction;
  final int clueLevel;
  final String currentRank;

  const _JoinConditions({
    required this.faction,
    required this.clueLevel,
    required this.currentRank,
  });

  @override
  Widget build(BuildContext context) {
    final conditions = <Widget>[];

    // 평판 > 0 조건 (항상)
    conditions.add(_ConditionRow(
      label: '세력 평판 > 0',
      met: true, // 이 화면에 오는 시점엔 항상 표시
    ));

    // clue 조건
    if (faction.joinNeedsClue) {
      conditions.add(_ConditionRow(
        label: '거점 발견 (★★★)',
        met: clueLevel >= 3,
      ));
    }

    // 랭크 조건
    if (faction.joinRankMin != null) {
      final sufficient = FactionJoinService.isRankSufficient(
          currentRank, faction.joinRankMin!);
      conditions.add(_ConditionRow(
        label: '랭크 ${faction.joinRankMin} 이상 (현재: $currentRank)',
        met: sufficient,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: conditions,
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String label;
  final bool met;

  const _ConditionRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? Colors.green : AppTheme.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppTheme.textPrimary : AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final String visibilityType;

  const _VisibilityBadge({required this.visibilityType});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (visibilityType) {
      'secret' => ('비밀', Colors.orange),
      'regional' => ('지역·종족', Colors.blue),
      _ => ('공개', Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 2: 정적 분석 확인**

```bash
cd band_of_mercenaries && flutter analyze lib/features/info/view/faction_detail_screen.dart
```

Expected: No issues found! (`Rank` import가 없어 에러 날 경우 import 추가)

- [ ] **Step 3: 전체 테스트 통과 확인**

```bash
cd band_of_mercenaries && flutter test
```

Expected: All tests pass

- [ ] **Step 4: 커밋**

```bash
cd band_of_mercenaries && git add lib/features/info/view/faction_detail_screen.dart
git commit -m "feat: update FactionDetailScreen with reputation bar, join/leave button, passive bonus"
```

---

## Task 7: 전체 분석 + 최종 검증

- [ ] **Step 1: 전체 정적 분석**

```bash
cd band_of_mercenaries && flutter analyze
```

Expected: No issues found!

- [ ] **Step 2: 전체 테스트 실행**

```bash
cd band_of_mercenaries && flutter test
```

Expected: All tests pass

- [ ] **Step 3: 분석 확인 (Dart 미사용 import 등)**

에러가 있을 경우: `flutter analyze` 출력을 보고 각 파일의 미사용 import, 타입 불일치를 수정한 후 다시 커밋

- [ ] **Step 4: 최종 커밋 (필요시)**

```bash
cd band_of_mercenaries && git add -p
git commit -m "fix: resolve any analyze warnings from faction core system"
```

---

## 스코프 밖 (다음 플랜)

| 기능 | 이유 |
|------|------|
| 퀘스트 세력 태그 시스템 | quest_pools 테이블 수정 + QuestGenerator 확장, 별도 플랜 |
| 세력 전용 시설 | faction_facilities Supabase 테이블 + 시설 탭 확장, 별도 플랜 |
| 세력 거점 배치 | region_discoveries에 거점 타입 추가, 향후 Phase |
| Supabase 데이터 입력 | factions 테이블 14개 세력 데이터 + 신규 필드 — 운영 작업 |

---

## Supabase 운영 작업 체크리스트 (개발자 직접 수행)

Flutter 구현과 병행하여 Supabase에서 수행해야 하는 작업:

```sql
-- 1. factions 테이블 신규 컬럼 추가
ALTER TABLE factions
  ADD COLUMN IF NOT EXISTS visibility_type TEXT NOT NULL DEFAULT 'public',
  ADD COLUMN IF NOT EXISTS join_rank_min TEXT,
  ADD COLUMN IF NOT EXISTS join_needs_clue BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS passive_bonus_json JSONB NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS conflict_faction_ids JSONB NOT NULL DEFAULT '[]';

-- 2. 기존 3개 세력 (검증용) 업데이트 후 14개 세력 신규 입력
-- → Docs/content-design/[content]20260416_faction_system.md 참조
```
