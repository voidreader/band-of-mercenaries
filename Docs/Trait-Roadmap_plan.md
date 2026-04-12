Skill used : implement-spec

# Phase 3: 트레잇 핵심 엔진 — 구현 결과

## 참조 문서
- `Docs/Trait-Roadmap.md` (Phase 3 섹션)
- `Docs/content-design/20260412_trait_system_design.md` (전체 기획서)

---

## 구현 계획 및 실제 개발 사항

### Step 1: Supabase 마이그레이션 (MCP 직접 적용)
- traits 테이블에 `acquisition_condition` JSONB, `effect_json` JSONB 컬럼 추가
- 40개 acquired 트레잇에 acquisition_condition 시딩 완료
- quest_types: `loot` → `raid` ID 변경
- data_versions 갱신 (traits, quest_types)

### Step 2: Flutter 모델 변경
- TraitData: acquisitionCondition, effectJson 필드 추가
- Mercenary: HiveField(14) stats `Map<String, int>`, HiveField(15) traitIds `List<String>` 추가
- GameConstants: 트레잇 슬롯 상수 추가
- ActivityLogType: traitAcquired 추가

### Step 3: 행동 지표 추적 시스템
- MercenaryStatService 신규 생성 (23개 지표 갱신 로직)
- MercDamageResult에 damageRoll 필드 추가
- quest_provider._applyCompletionResult()에 지표 갱신 통합

### Step 4: 용병 모집 변경 (선천 1~3개)
- selectInnateTraits() — Physical/Background/Talent에서 각 60% 확률, 최소 1개 보장
- generateMercenary/generateStartingMercenaries에 categories 파라미터 추가
- MercenaryRepository, MercenaryProvider, game_state_provider 호출부 수정

### Step 5: 데이터 드리븐 트레잇 효과
- TraitEffectService 신규 생성 (effect_json 파싱)
- QuestCalculator: traitBonus를 TraitEffectService 호출로 교체
- calculateDamage: traitIds/allTraits 파라미터 추가, 사망/부상률 보정
- QuestCompletionService: allTraitIds, allTraits 전달
- quest_types 매핑: loot → raid

### Step 6: 트레잇 획득 엔진 + 충돌 검증
- TraitAcquisitionService 신규 생성
- 조건 체크: acquisitionCondition vs stats 비교
- 시너지: trait_synergies 기반 임계값 감소
- 충돌: trait_conflicts 기반 검증
- quest_provider에 자동 획득 통합

### Step 7: UI 업데이트
- MercenaryCard: `TraitData? trait` → `List<TraitData> traits` (Wrap 뱃지)
- recruit_screen: allTraitIds 기반 복수 트레잇 조회
- dispatch_detail_page: allTraitIds 사용, allTraits/partySize 전달

### Step 8-9: 테스트 + 검증
- 기존 테스트 4개 수정 (loot→raid, 시그니처 변경)
- 신규 테스트 3개 생성 (stat_service, effect_service, acquisition_service)
- 전체 161개 테스트 통과

---

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `operation-bom/supabase/migrations/004_trait_phase3.sql` | 신규 | DDL + 데이터 시딩 |
| `lib/core/models/trait_data.dart` | 수정 | acquisitionCondition, effectJson 추가 |
| `lib/features/mercenary/domain/mercenary_model.dart` | 수정 | HiveField(14) stats, (15) traitIds, allTraitIds getter |
| `lib/core/constants/game_constants.dart` | 수정 | 트레잇 슬롯 상수 |
| `lib/core/domain/activity_log_model.dart` | 수정 | traitAcquired enum |
| `lib/features/home/view/home_screen.dart` | 수정 | traitAcquired switch case |
| `lib/features/mercenary/domain/mercenary_stat_service.dart` | 신규 | 행동 지표 갱신 |
| `lib/features/mercenary/domain/trait_effect_service.dart` | 신규 | 효과 계산 |
| `lib/features/mercenary/domain/trait_acquisition_service.dart` | 신규 | 획득 엔진 + 충돌 검증 |
| `lib/features/mercenary/domain/recruitment_service.dart` | 수정 | 선천 1~3개 랜덤 선택 |
| `lib/features/mercenary/data/mercenary_repository.dart` | 수정 | updateStats, addTrait 추가 |
| `lib/features/mercenary/domain/mercenary_provider.dart` | 수정 | categories 전달 |
| `lib/core/providers/game_state_provider.dart` | 수정 | categories 전달 |
| `lib/features/quest/domain/quest_calculator.dart` | 수정 | 데이터 드리븐 효과, loot→raid |
| `lib/features/quest/domain/quest_completion_service.dart` | 수정 | allTraitIds, damageRoll |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | 지표 갱신 + 트레잇 획득 통합 |
| `lib/features/mercenary/view/mercenary_card.dart` | 수정 | 복수 트레잇 Wrap 표시 |
| `lib/features/mercenary/view/recruit_screen.dart` | 수정 | allTraitIds 조회 |
| `lib/features/quest/view/dispatch_detail_page.dart` | 수정 | allTraitIds, allTraits 전달 |
| `test/.../recruitment_service_test.dart` | 수정 | categories 추가, 선천 트레잇 검증 |
| `test/.../quest_calculator_test.dart` | 수정 | loot→raid |
| `test/.../quest_calculator_preview_test.dart` | 수정 | loot→raid |
| `test/.../quest_completion_service_test.dart` | 수정 | loot→raid |
| `test/.../mercenary_stat_service_test.dart` | 신규 | 지표 갱신 테스트 |
| `test/.../trait_effect_service_test.dart` | 신규 | 효과 계산 테스트 |
| `test/.../trait_acquisition_service_test.dart` | 신규 | 획득/충돌/시너지 테스트 |

## build_runner 재실행 필요 파일
- `lib/core/models/trait_data.dart` (freezed)
- `lib/features/mercenary/domain/mercenary_model.dart` (hive_generator)
- `lib/core/domain/activity_log_model.dart` (hive_generator)

## CLAUDE.md 금지사항 위반
- 없음
