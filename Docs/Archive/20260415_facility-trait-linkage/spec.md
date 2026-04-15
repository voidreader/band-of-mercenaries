# Phase B: 시설 ↔ 트레잇 연계 개발 명세서

> 기획 문서: `docs/content-design/roadmap/trait_enrichment_roadmap.md` (Phase B)
> 작성일: 2026-04-15

## 1. 개요

시설(훈련소/의무실/야전병원) 사용 시 용병 개인의 행동 지표를 누적하여, 기존 트레잇 획득 파이프라인(`TraitAcquisitionService`)이 시설 관련 조건의 트레잇도 자동으로 획득하도록 연결한다. 코드 변경은 지표 추가 + 카운트 호출 2개 파일에 국한되며, 트레잇 데이터는 Supabase에 추가하면 코드 변경 없이 확장 가능하다.

## 2. 요구사항

### 2.1 기능 요구사항

- [FR-1] 시설 혜택 지표 3종 추가
  - `training_benefit_count`: 훈련소 레벨 > 0일 때 퀘스트를 완료한 횟수 (용병 개인별)
  - `infirmary_recovery_count`: 의무실 레벨 > 0일 때 부상 상태로 전환된 횟수 (회복시간 단축 혜택을 받은 횟수)
  - `field_hospital_benefit_count`: 야전병원 레벨 > 0일 때 퀘스트 실패에서 부상 없이 생존한 횟수
  - 기존 23개 지표에 추가하여 총 26개 지표로 확장

- [FR-2] 퀘스트 완료 시 시설 지표 카운트
  - `QuestCompletionService.calculate()` 결과와 `UserData.facilities` 상태를 조합하여 판정
  - `MercenaryStatService`에 시설 혜택 판정 메서드 추가
  - 기존 `updateStatsAfterQuest()` 호출 직후에 시설 지표 갱신
  - 트레잇 획득 체크(`TraitAcquisitionService.checkAcquisitionCandidates()`)는 기존 퀘스트 완료 시점 그대로 유지 — 시설 지표도 이 시점에서 자동 체크됨

- [FR-3] Supabase traits 테이블에 시설 조건 기반 트레잇 추가 (검증용 3개)
  - `acquisition_condition` JSON에 새 지표 키를 사용하면 기존 `_meetsCondition()` 로직이 자동 처리
  - 코드 변경 없이 Supabase 데이터 추가만으로 동작
  - 검증용 최소 데이터 3개:

  | key | name | categoryKey | type | acquisition_condition | effect_json |
  |-----|------|-------------|------|----------------------|-------------|
  | `trained_warrior` | 단련된 전사 | CombatStyle | acquired | `{"training_benefit_count": 20}` | `{"success_rate": 0.03}` |
  | `survivor_instinct` | 생존 본능 | Survival | acquired | `{"infirmary_recovery_count": 10, "injury_count": 5}` | `{"injury_reduction": 0.10}` |
  | `iron_guard` | 철벽 수호 | Survival | acquired | `{"field_hospital_benefit_count": 15}` | `{"damage_reduction": 0.05}` |

  - 주의: `survivor_instinct`는 기존 `injury_count` 지표와 신규 `infirmary_recovery_count` 지표를 복합 조건으로 사용하여 교차 검증

### 2.2 데이터 요구사항

- **Hive 변경 없음**: `Mercenary.stats`(HiveField(14), `Map<String, int>`)에 새 키가 자동 추가됨. Hive Map 타입은 키 추가에 스키마 변경 불요
- **Supabase 변경**: `traits` 테이블에 검증용 트레잇 3행 INSERT (operation-bom 웹앱 또는 직접 SQL)
- **정적 데이터 모델 변경 없음**: `TraitData.acquisitionCondition`은 이미 `Map<String, dynamic>?`이므로 새 키에 대한 모델 변경 불요
- **build_runner 재실행 불요**: freezed/json_serializable 모델 변경 없음

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `lib/features/mercenary/domain/mercenary_stat_service.dart` | `updateStatsForFacilityBenefit()` 정적 메서드 추가 | 시설 혜택 지표 카운트 로직 |
| `lib/features/quest/domain/quest_provider.dart` (~line 338 이후) | `updateStatsForFacilityBenefit()` 호출 추가 | 퀘스트 완료 시 시설 지표 갱신 |

### 3.2 신규 생성 파일

없음

### 3.3 코드 생성 필요 파일

없음 (build_runner 재실행 불요)

### 3.4 관련 시스템

- **트레잇 획득 시스템**: `TraitAcquisitionService.checkAcquisitionCandidates()` — 코드 변경 없이 새 지표 키를 자동 인식 (stats Map의 키와 acquisition_condition의 키 직접 매칭)
- **시설 시스템**: 읽기 전용 참조 (`userData.facilities` 레벨 조회). 시설 코드 수정 없음
- **퀘스트 완료 시스템**: `QuestCompletionResult`의 기존 필드(`mercDamages`)를 활용하여 시설 혜택 판정

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `mercenary_stat_service.dart:13-93` (`updateStatsAfterQuest`): 퀘스트 결과 기반 지표 카운트 패턴. 동일한 `Map<String, int>` 입출력 패턴 사용
- `mercenary_stat_service.dart:95-104` (`updateStatsAfterTravel`): 별도 이벤트 기반 지표 추가 패턴. 시설 혜택도 이 패턴으로 별도 메서드 추가
- `quest_provider.dart:326-338`: `updateStatsAfterQuest()` 호출 → `mercRepo.updateStats()` 저장 흐름. 동일 위치에 시설 지표 호출 삽입

### 4.2 주의사항

- `updateStatsForFacilityBenefit()` 호출은 반드시 `updateStatsAfterQuest()` 이후, `mercRepo.updateStats()` 이전에 위치해야 함 (단일 Hive 저장으로 통합)
- 사망한 용병(`damage.newStatus == MercenaryStatus.dead`)에게는 시설 지표를 카운트하지 않음 (기존 로직과 동일: line 324의 `if (damage.newStatus != MercenaryStatus.dead)` 블록 내부)

### 4.3 엣지 케이스

- **시설 레벨 0**: 시설을 아직 건설하지 않은 상태 → 해당 시설 지표 카운트 안 함 (정상)
- **건설 중 시설**: 건설 중이면 현재 레벨(이전 레벨)이 적용됨. Lv0에서 Lv1 건설 중이면 아직 훈련소 효과 없음 → 카운트 안 함 (정상)
- **성공 퀘스트의 야전병원 카운트**: 성공 시에는 부상 판정 자체가 없으므로 `field_hospital_benefit_count` 증가 안 함 (정상 — 야전병원은 실패 시에만 의미)
- **대실패 + 사망 용병**: 사망 용병은 전체 블록에서 제외되므로 시설 지표도 카운트 안 함

### 4.4 구현 힌트

- **진입점**: `quest_provider.dart`의 `_applyCompletionResult()` 메서드 (line 322-409)
- **데이터 흐름**:
  ```
  QuestCompletionService.calculate(facilities: userData.facilities)
    → QuestCompletionResult (resultType, mercDamages)
    → _applyCompletionResult()
      → [각 용병] MercenaryStatService.updateStatsAfterQuest() → newStats
      → [NEW] MercenaryStatService.updateStatsForFacilityBenefit(newStats, ...) → finalStats
      → mercRepo.updateStats(merc.id, finalStats)
      → TraitAcquisitionService.checkAcquisitionCandidates(stats: finalStats, ...)
  ```
- **참조 구현**: `mercenary_stat_service.dart:95-104` (`updateStatsAfterTravel`) — 별도 이벤트 지표 메서드 패턴
- **확장 지점**: `quest_provider.dart:338` — `await mercRepo.updateStats(merc.id, newStats)` 직전에 시설 지표 갱신 삽입
- **시설 레벨 접근**: `ref.read(userDataProvider)!.facilities` (quest_provider.dart 내에서 이미 사용 가능)
- **시설 혜택 판정 조건**:
  - `training_benefit_count`: `facilities['training'] > 0` (성공/실패 무관, 퀘스트 완료 = 훈련 혜택)
  - `infirmary_recovery_count`: `facilities['infirmary'] > 0 AND damage.newStatus == MercenaryStatus.injured`
  - `field_hospital_benefit_count`: `facilities['field_hospital'] > 0 AND (resultType == failure || criticalFailure) AND damage.newStatus != dead AND damage.newStatus != injured`

## 5. 기획 확인 사항

- [Q-1] 대상 시설 범위 → 용병 개인 귀속이 명확한 3종(훈련소/의무실/야전병원)만 대상 (사용자 확인 완료)
- [Q-2] 시설 관련 트레잇 데이터 → 기존 기획 없음. 검증용 3개 예시 포함, 본격 설계는 별도 컨텐츠 작업으로 분리 (사용자 확인 완료)
- [Q-3] 트레잇 체크 타이밍 → 기존 퀘스트 완료 시점 유지 (추가 체크 포인트 불요)
