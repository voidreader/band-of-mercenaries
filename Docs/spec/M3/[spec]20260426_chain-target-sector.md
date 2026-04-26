# 체인 퀘스트 섹터 단위 하이라이트 — chain_quests.target_sector_id

> 기획 문서: 없음 (인프라 후속 정리, post-coexistence-cleanup §6 deferred 항목)
> 작성일: 2026-04-26

## 1. 배경

`[spec]20260425_coexistence-policy_plan.md` §9에 다음 후속 작업이 명시되어 있다:

> `target_sector_id` 스키마 추가 후 체인 섹터 단위 하이라이트

현재 `MovementScreen`은 active 체인의 `target_region_id`/`region_id`만으로 region 단위 매칭하여, 해당 region의 모든 섹터 타일에 금색 테두리를 그린다. 체인이 region 안의 특정 섹터를 가리킬 수 있도록 `chain_quests` 테이블에 `target_sector_id` 컬럼을 추가하고, MovementScreen이 region+sector 둘 다 매칭하도록 확장한다.

## 2. 요구사항

### REQ-1. 스키마

`chain_quests` 테이블에 `target_sector_id INTEGER NULL` 컬럼을 추가한다.
- nullable. 기본값 없음.
- 기존 24행의 데이터는 변경하지 않는다 (모두 null 유지).
- `data_versions` 테이블의 `chain_quests` 항목 version을 1 증가한다 (Flutter SyncService가 변경을 감지하여 캐시 갱신).

### REQ-2. Flutter 모델

`band_of_mercenaries/lib/core/models/chain_quest_data.dart`의 `ChainQuestData` freezed 모델에 nullable 필드를 추가한다:

```dart
@JsonKey(name: 'target_sector_id') int? targetSectorId,
```

`target_region_id` 필드 다음에 위치. `dart run build_runner build --delete-conflicting-outputs`로 `.g.dart`/`.freezed.dart` 재생성.

### REQ-3. MovementScreen 섹터 매칭 로직

기존 region 단위 fallback 동작을 유지하면서 섹터 단위 매칭을 지원한다.

**현재 (region 단위만):**
```dart
final chainTargetRegionIds = <int>{};
// ...
if (targetId != null) chainTargetRegionIds.add(targetId);
// 렌더 시: chainTargetRegionIds.contains(_selectedRegion)
```

**변경 후 (region + sector):**
```dart
// regionId → 섹터 ID 집합. null 값이 포함되면 region 전체 하이라이트.
final chainTargetSectors = <int, Set<int?>>{};
for (final progress in chainProgressList) {
  if (progress.status != ChainQuestStatus.active) continue;
  final step = data.chainQuests.where(
    (q) => q.chainId == progress.chainId && q.step == progress.currentStep,
  ).firstOrNull;
  if (step == null) continue;
  final regionId = step.targetRegionId ?? step.regionId;
  if (regionId == null) continue;
  chainTargetSectors.putIfAbsent(regionId, () => <int?>{}).add(step.targetSectorId);
}
```

섹터 타일 렌더링 시 매칭:
```dart
final targets = chainTargetSectors[_selectedRegion];
final isChainTarget = targets != null
    && (targets.contains(null) || targets.contains(sectorIndex));
```

- `targets`가 null → 해당 region에 active 체인 단계 없음. 하이라이트 안 함.
- `targets.contains(null)` → 해당 region 단계 중 하나가 sector 미지정. region 전체 하이라이트 (fallback).
- `targets.contains(sectorIndex)` → 해당 섹터만 하이라이트.

기존 24행은 모두 `targetSectorId == null`이므로 동작 변경 없음 (모든 섹터 하이라이트 유지).

### REQ-4. CSV 동기화

`Docs/content-data/[chain-quest]20260424_m3-chains.csv`의 헤더에 `target_sector_id` 컬럼을 `target_region_id` 다음에 추가한다. 24개 데이터 행은 모두 빈 값으로 둔다 (null).

## 3. 비기능 요구

- **검증 모드**: 경량 검증 (TASK 수 3개)
- **호환성**: 기존 24개 chain_quest 단계는 시각적 동작 100% 동일
- **데이터 콘텐츠 작업**: 본 spec 범위 외. sector_id 실제 값 부여는 별도 콘텐츠 디자인 sprint
- **operation-bom 동기화**: 별도 프로젝트의 마이그레이션은 본 spec에서 다루지 않음 (Supabase 컬럼만 추가하여 SyncService가 자동으로 받음)

## 4. 변경 범위 요약

| 파일 | 변경 |
|------|------|
| Supabase `chain_quests` 테이블 | `target_sector_id INTEGER NULL` 컬럼 추가 (마이그레이션) |
| Supabase `data_versions` 테이블 | `chain_quests` row의 version +1 |
| `band_of_mercenaries/lib/core/models/chain_quest_data.dart` | `targetSectorId` 필드 추가 |
| `band_of_mercenaries/lib/core/models/chain_quest_data.g.dart` | build_runner 재생성 |
| `band_of_mercenaries/lib/core/models/chain_quest_data.freezed.dart` | build_runner 재생성 |
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | `chainTargetRegionIds` → `chainTargetSectors` 확장, 섹터 매칭 로직 |
| `Docs/content-data/[chain-quest]20260424_m3-chains.csv` | 헤더 `target_sector_id` 컬럼 추가 |

## 5. 검증 기준

- `flutter analyze`: No issues found
- `flutter test`: 기존 회귀 PASS (movement/chain_quest 테스트 모두 그대로)
- 수동: 활성 체인이 있는 region 진입 → 모든 섹터 하이라이트 (기존과 동일하게 보임)
