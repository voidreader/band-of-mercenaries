# 트레잇 시스템 고도화 — 구현 로드맵

> 작성일: 2026-04-12
> 기획서: `Docs/content-design/20260412_trait_system_design.md`

---

## Phase 1: 데이터 기반 구축 ✅ 완료

| # | 작업 | 상태 | 비고 |
|---|------|------|------|
| ① | Supabase DDL 적용 (6개 테이블 생성) | ✅ | `003_trait_system.sql` 마이그레이션 적용 |
| ② | 106개 트레잇 + 관계 데이터 입력 | ✅ | `seed-traits.ts` 실행 완료 |
| ③ | operation-bom 웹앱 table-config 확장 | ⬜ | Phase 6에서 진행 |

**생성된 테이블:**
- `trait_categories` (8행) — 카테고리 정의
- `traits` (106행) — 트레잇 본체
- `trait_conflicts` (32행) — 충돌 관계 (16쌍 × 양방향)
- `trait_transitions` (16행) — 단일 진화 경로
- `trait_combo_evolutions` (15행) — 조합 진화 레시피
- `trait_synergies` (39행) — 선천-후천 시너지

**생성된 파일:**
- `operation-bom/supabase/migrations/003_trait_system.sql`
- `operation-bom/scripts/seed-traits.ts`

---

## Phase 2: Flutter 모델/싱크 업데이트 ✅ 완료

| # | 작업 | 상태 | 영향 파일 |
|---|------|------|----------|
| ④ | Dart 모델 변경 (TraitData → 새 구조) + 5개 신규 모델 | ✅ | `core/models/trait_data.dart` 외 5개 신규 |
| ⑤ | SyncService 확장 (신규 5개 테이블 동기화) | ✅ | `core/data/sync_service.dart` |
| ⑥ | StaticGameData 확장 + 참조 수정 11개 파일 | ✅ | `core/providers/static_data_provider.dart` 외 |

**핵심 변경:**
- 기존 `TraitData(id, name, effectType, value)` → `TraitData(key, name, categoryKey, type, description, effectText)`
- `TraitCategory`, `TraitConflict`, `TraitTransition`, `TraitComboEvolution`, `TraitSynergy` 모델 추가
- `SyncService`에 6개 테이블 추가 (data_versions 연동)
- `StaticGameData`에 트레잇 관계 데이터 포함

---

## Phase 3: 핵심 엔진 ✅ 완료

| # | 작업 | 상태 | 영향 파일 |
|---|------|------|----------|
| ⑦ | 행동 지표 추적 시스템 (23개 지표) | ✅ | `mercenary_model.dart` 확장, `mercenary_stat_service.dart` 신규, `quest_provider.dart` |
| ⑧ | 용병 모집 변경 (선천 1~3개 랜덤) | ✅ | `recruitment_service.dart`, `mercenary_repository.dart`, `mercenary_provider.dart` |
| ⑨ | 트레잇 획득 엔진 (지표 → 조건 체크 → 후보 생성) | ✅ | `trait_acquisition_service.dart` 신규, `quest_provider.dart` |
| ⑩ | 파견 효과 처리 변경 (하드코딩 → 데이터 드리븐) | ✅ | `trait_effect_service.dart` 신규, `quest_calculator.dart`, `quest_completion_service.dart` |
| ⑪ | 충돌 관계 검증 | ✅ | `trait_acquisition_service.dart`에 통합 |

**핵심 변경:**
- 용병 모델에 `stats` (Map<String, int>, 23개 지표) + `traitIds` (List<String>) 추가, Hive HiveField(14), (15)
- 퀘스트 완료 시 `MercenaryStatService`로 지표 자동 갱신
- 모집 시 `Physical/Background/Talent` 카테고리에서 랜덤 1~3개 선천 트레잇 부여
- `QuestCalculator`에서 `TraitEffectService` 기반 데이터 드리븐 효과 처리 (`effect_json` 컬럼)
- `TraitAcquisitionService`: 지표 → `acquisition_condition` 비교 → 시너지 감소 → 충돌 검증 → 자동 획득
- quest type ID: `loot` → `raid` 변경
- traits 테이블에 `acquisition_condition`, `effect_json` JSONB 컬럼 추가

**추가 생성 파일:**
- `lib/features/mercenary/domain/mercenary_stat_service.dart`
- `lib/features/mercenary/domain/trait_effect_service.dart`
- `lib/features/mercenary/domain/trait_acquisition_service.dart`
- `operation-bom/supabase/migrations/004_trait_phase3.sql`

**행동 지표 23개:**
```
total_dispatch_count, success_count, failure_count,
great_success_count, great_failure_count,
solo_dispatch_count, team_dispatch_count,
high_difficulty_count, low_difficulty_count,
raid_count, subjugation_count, escort_count, explore_count,
near_death_count, injury_count, survived_great_failure,
tier_max_visited, unique_region_count, total_travel_distance,
total_gold_earned, current_level,
consecutive_success, consecutive_failure
```

---

## Phase 4: 진화 시스템 ✅ 완료

| # | 작업 | 상태 | 영향 파일 |
|---|------|------|----------|
| ⑫ | 단일 진화 엔진 | ✅ | `trait_evolution_service.dart` 신규 |
| ⑬ | 조합 진화 엔진 | ✅ | 동일 서비스 |
| ⑭ | 트레잇 히스토리 (재획득 방지) | ✅ | `mercenary_model.dart` HiveField(16) |

**핵심 변경:**
- 단일 진화: 보유 중인 acquired 트레잇 + conditionJson 지표 조건 충족 → 같은 카테고리 evolved로 교체
- 조합 진화: 보유 중인 2개 트레잇 (서로 다른 카테고리) → 두 원본 소멸 + 결과 트레잇 획득 + 슬롯 해방
- 트레잇 히스토리: HiveField(16) `List<String> traitHistory` → 소멸 트레잇 기록, 재획득 방지
- `quest_provider._applyCompletionResult()`에서 지표 갱신 → 트레잇 획득 → 단일 진화 → 조합 진화 순서 체크
- 한 퀘스트 완료당 최대 1회 진화 (단일 우선, 조합 후순위)
- 진화 선택지 UI (Phase 5에서 구현)

**추가 생성 파일:**
- `lib/features/mercenary/domain/trait_evolution_service.dart`

---

## Phase 5: UI

| # | 작업 | 상태 | 영향 파일 |
|---|------|------|----------|
| ⑮ | 트레잇 관리 UI (상세 정보, 슬롯 시각화) | ⬜ | `mercenary_card.dart`, 신규 위젯 |
| ⑯ | 획득/진화 알림 팝업 | ⬜ | 신규 다이얼로그 |
| ⑰ | 용병 상세 화면 개선 | ⬜ | `recruit_screen.dart` 또는 신규 화면 |

**핵심 변경:**
- 용병 카드에 선천(고정)/후천(획득) 슬롯 구분 표시
- 빈 슬롯 시각화 (잠재적 성장 여지)
- 트레잇 탭 시 상세 팝업 (설명, 효과, 진화 경로)
- 조건 충족 시 "새 트레잇 획득 가능" 알림
- 진화 선택 다이얼로그 (단일 진화 분기, 조합 진화 확인)

---

## Phase 6: operation-bom 웹앱 확장

| # | 작업 | 상태 | 영향 파일 |
|---|------|------|----------|
| ⑱ | table-config.ts에 신규 6개 테이블 설정 추가 | ⬜ | `src/lib/table-config.ts` |
| ⑲ | types.ts에 트레잇 관련 TypeScript 인터페이스 추가 | ⬜ | `src/lib/types.ts` |
| ⑳ | 트레잇 관계 시각화 (진화 경로, 충돌 관계 조회) | ⬜ | 신규 페이지 또는 기존 data/[table] 활용 |

**핵심 변경:**
- `tableConfigs`에 `trait_categories`, `traits`, `trait_conflicts`, `trait_transitions`, `trait_combo_evolutions`, `trait_synergies` 추가
- 각 테이블의 필드 정의, 라벨, 타입 설정 → 자동 CRUD UI 생성
- `traits` 테이블: category_key를 드롭다운으로 표시, type을 select로 제한
- `trait_conflicts`: trait_key 선택 시 traits 테이블에서 조회
- 트레잇 데이터 수정 후 publish version 버튼으로 Flutter 앱 싱크 트리거

---

## 향후 확장 (Phase 이후)

| 컨텐츠 | 설명 | 의존성 |
|--------|------|--------|
| 여행 이벤트 ↔ 선천 트레잇 연계 | 이동 이벤트에서 빈 선천 슬롯에 트레잇 부여 | Phase 3 완료 |
| 특수 임무 시스템 | 희귀 퀘스트, 트레잇 직접 부여 보상 | Phase 3 완료 |
| 아이템/스킬북 시스템 | 스킬북 사용 시 특정 트레잇 부여 | 아이템 시스템 필요 |
| 시설 ↔ 트레잇 연계 | 시설 레벨에 따른 트레잇 기회 | Phase 3 완료 |
| 용병 간 상호작용 이벤트 | 같은 파견 반복 시 우정/라이벌 트레잇 | Phase 3 완료 |
| 트레잇 삭제 시스템 | 후천 트레잇 삭제 (선천 불가). 비용/조건 필요 | Phase 4 완료 |
| 용병 티어 업그레이드 | 성장을 통한 티어 상승 | 별도 기획 필요 |
| 밸런스 튜닝 | 효과 수치, 획득 임계값, 선천 확률 조정 | Phase 3 완료 후 `/balance-designer` |

---

## 참고 문서

| 문서 | 위치 |
|------|------|
| 트레잇 시스템 기획서 | `Docs/content-design/20260412_trait_system_design.md` |
| PD 요구사항 원본 | `Docs/content-design/req-trait-system.md` |
| DDL 마이그레이션 | `operation-bom/supabase/migrations/003_trait_system.sql` |
| Seed 스크립트 | `operation-bom/scripts/seed-traits.ts` |
