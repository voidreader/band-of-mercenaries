# 체인 퀘스트 섹터 단위 하이라이트 — 구현 리포트

Skill used : implement-agent
작성일: 2026-04-26
명세서: `Docs/spec/M3/[spec]20260426_chain-target-sector.md`

## 1. 개요

`[spec]20260425_coexistence-policy_plan.md` §9 후속 작업 중 미처리 항목 1건 처리. `chain_quests` 테이블에 `target_sector_id INTEGER NULL` 컬럼을 추가하고 Flutter `ChainQuestData` 모델 + `MovementScreen` 매칭 로직을 region+sector 둘 다 지원하도록 확장. 기존 24행은 모두 `targetSectorId == null`이라 region 단위 fallback으로 동작 100% 동일.

## 2. 구현 결과 (REQ별)

| REQ | 요약 | 구현 |
|-----|------|------|
| REQ-1 | Supabase `chain_quests.target_sector_id INTEGER NULL` + `data_versions` version 1→2 | 마이그레이션 `add_target_sector_id_to_chain_quests` 적용 |
| REQ-2 | `ChainQuestData.targetSectorId` 필드 추가 + 코드 재생성 | `chain_quest_data.dart` + build_runner |
| REQ-3 | `chainTargetRegionIds` → `chainTargetSectors`(`Map<int, Set<int?>>`) 확장, 섹터 매칭 + null fallback | `movement_screen.dart` |
| REQ-4 | CSV 헤더에 `target_sector_id` 컬럼 추가 (24행 빈 값) | `[chain-quest]20260424_m3-chains.csv` |

## 3. 변경 파일 목록

### 데이터베이스 (Supabase 마이그레이션)

| 변경 | 내용 |
|------|------|
| `chain_quests` 테이블 | `target_sector_id INTEGER NULL` 컬럼 추가 |
| `data_versions` 테이블 | `chain_quests` row의 `version` 1→2, `updated_at` 갱신 |

마이그레이션 이름: `add_target_sector_id_to_chain_quests`

### Flutter 코드 (수정 1개 + 자동 재생성 2개)

| 파일 | 변경 |
|------|------|
| `band_of_mercenaries/lib/core/models/chain_quest_data.dart` | `@JsonKey(name: 'target_sector_id') int? targetSectorId` 필드 추가 (target_region_id 다음) |
| `band_of_mercenaries/lib/core/models/chain_quest_data.g.dart` | build_runner 재생성 (`targetSectorId` JSON 매핑) |
| `band_of_mercenaries/lib/core/models/chain_quest_data.freezed.dart` | build_runner 재생성 |
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | `chainTargetRegionIds` → `chainTargetSectors`(`Map<int, Set<int?>>`) 확장, 섹터 타일에서 `targets.contains(null) \|\| targets.contains(sector)` 매칭 |

### 콘텐츠 데이터 (CSV)

| 파일 | 변경 |
|------|------|
| `Docs/content-data/[chain-quest]20260424_m3-chains.csv` | 헤더에 `target_sector_id` 컬럼 추가, 24개 데이터 행은 모두 빈 값 |

## 4. 핵심 설계 결정

### sector 인덱스 컨벤션

**1-based(1..10)** 채택. 근거:
- `UserData.sector`가 1-based 저장 (`game_state_provider.dart`의 초기화: `random.nextInt(GameConstants.sectorCount) + 1`)
- MovementScreen 섹터 타일 루프가 `final sector = i + 1` (1-based 표시)
- `region_states.sectorChanges` 맵은 0-based 문자열 키("0".."9") 사용하지만 별개 도메인 (지역 변형 시각화용)

`target_sector_id`는 사용자 위치 매칭을 위한 값이므로 1-based가 일관성 측면에서 자연스러움.

### Map<int, Set<int?>> 자료구조

같은 region에 여러 active 체인 단계가 동시 존재할 수 있고, 그중 일부만 sector를 지정할 수도 있다. 따라서:

- `targets.contains(null)` → 해당 region에 sector 미지정 단계 1개 이상 → region 전체 하이라이트
- `targets.contains(sectorIndex)` → 해당 섹터 직접 지정
- 둘 다 false → 하이라이트 안 함

null 값이 fallback signal로 자연스럽게 작동.

## 5. 검증 결과

### 빌드/테스트
- `flutter analyze`: **No issues found** (1.6s)
- `flutter test`: **499/499 passed** (4s, 기존 회귀 모두 통과)
- `dart run build_runner build --delete-conflicting-outputs`: 성공 (3 outputs)
- Supabase 마이그레이션: `apply_migration` success, 컬럼 존재 + version 2 확인

### 검증 모드: 경량 검증 (TASK 수 4 → 3개 TASK + 1 검증 TASK)

main 직접 명세 검증으로 진행. flutter-reviewer는 변경 규모가 작고 (모델 1줄 + UI 1개 함수 + CSV 헤더만) 위험도 낮아 생략.

#### main 명세 검증 결과
- REQ-1: ✅ 컬럼 + version +1 확인 (`information_schema.columns` 조회)
- REQ-2: ✅ `targetSectorId` 필드 추가, `.g.dart`에 `target_sector_id` JSON 매핑 생성 확인
- REQ-3: ✅ `chainTargetSectors` 자료구조 + null fallback + 1-based sector 매칭 모두 명세 통과
- REQ-4: ✅ CSV 헤더 21개 컬럼 (기존 20 + `target_sector_id`), 24행 모두 빈 값으로 보존

### 호환성

- 기존 24개 chain_quest 단계: `targetSectorId == null`이므로 `targets.contains(null)`로 전체 region 하이라이트 → **시각적 동작 100% 동일**
- 다른 사용처 영향: `ChainQuestData` 다른 필드 미변경, 추가 필드는 nullable이라 모든 기존 호출부에 영향 없음
- Flutter SyncService: `data_versions.chain_quests.version` 1→2 인식하여 다음 앱 시작/포그라운드 복귀 시 자동 재다운로드

## 6. 후속 작업 (이 spec 범위 외)

- **콘텐츠 디자인**: 24개 단계에 의미 있는 `target_sector_id` 값 부여 (어느 단계가 region 내 어느 섹터를 가리킬지). 별도 콘텐츠 sprint
- **operation-bom 동기화**: 운영 웹앱에서 `target_sector_id` 입력 UI 제공 필요 (별도 프로젝트)
- **post-coexistence-cleanup §9 잔여 항목**:
  - InvestigationResultDialog onDismiss 파라미터 추가 (위젯 인터페이스 수준 정리)
  - AppTheme 색상 변경 회귀 점검 (운영 QA)

## 7. CLAUDE.md 정책 준수 사항

- 새 기능/모듈 추가 없음 → CLAUDE.md 갱신 트리거 미해당
- view → domain → data 레이어 분리 준수 (movement_screen은 view, ChainQuestData는 model, Supabase는 data 레이어)
- 한국어 주석, 비자명한 부분(섹터 인덱스 1-based, null fallback semantics)만 작성
- 의존성 추가 없음

## 8. build_runner 재실행 필요 파일

- `lib/core/models/chain_quest_data.dart` → `chain_quest_data.g.dart` / `chain_quest_data.freezed.dart` 재생성됨

다른 freezed/json_serializable 파일 변경 없음.

## 9. 후속 작업 안내

본 구현 완료 후 다음 순으로 안내:

1. `finalize-feature` 스킬로 commit + 산출물 정리
2. 콘텐츠 디자이너에게 `target_sector_id` 값 부여 요청 (별도 sprint)
3. operation-bom 운영 웹앱에 `target_sector_id` 입력 UI 추가 (별도 프로젝트)
