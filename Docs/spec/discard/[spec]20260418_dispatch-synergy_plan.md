# P4-3 dispatch-synergy 구현 계획 및 결과

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260418_dispatch-synergy.md`
> 선행 구현: P4-1 PassiveBonusService (commit 689705b), P4-2 faction-quest-system (commit 0ba94e3)
> 구현 일자: 2026-04-18
> 마일스톤: M1 페이즈 4 (3/4)

## 1. 수립한 구현 계획

### 16개 TASK DAG 설계

| 단계 | 태스크 | 설명 |
|:---:|:---|:---|
| 1 (병렬) | TASK-1 | Supabase MCP로 jobs.role 분포 · traits.effect_json 검증 (SQL 생성 금지) |
| 1 (병렬) | TASK-2 | `Job` 모델에 `@Default('specialist') @JsonKey(name: 'role')` 추가 + build_runner |
| 1 (병렬) | TASK-5 | `PassiveBonusService.getQuestSuccessRateBonusWithDetail` 신규 API, 기존 메서드는 래퍼 |
| 1 (병렬) | TASK-6 | `SuccessRateBreakdown` 값 객체 신규 생성 |
| 2 (병렬) | TASK-3 | `RoleSynergyMatrix` 신규 클래스 (6×4 매트릭스 + 3 헬퍼) |
| 2 (병렬) | TASK-4 | `RoleUtils` 신규 유틸 (`extractRoles`, `koreanName`) |
| 3 | TASK-7 | `QuestCalculator` 확장 (`partyRoles` 파라미터 + `traitBonus.clamp(-10, 10)` + `calculateSuccessRateBreakdown` static) |
| 4 (병렬) | TASK-8 | `QuestCompletionService` 호출부 업데이트 (`RoleUtils.extractRoles(...)` 전달) |
| 4 (병렬) | TASK-10 | `SuccessRateBreakdownSheet` 위젯 신규 생성 |
| 4 (병렬) | TASK-13 | `RoleSynergyMatrix` 유닛 테스트 (17 케이스) |
| 4 (병렬) | TASK-14 | `RoleUtils` 유닛 테스트 (5 케이스) |
| 5 (병렬) | TASK-9 | `DispatchDetailPage` 리팩터링 (성공률 분해 진입 + 용병 카드 하이라이트) |
| 5 (병렬) | TASK-11 | `DispatchScreen._buildQuestCard` 추천 role 배지 (Chip × 2) |
| 5 (병렬) | TASK-12 | `MercenaryDetailOverlay` 상성 섹션 추가 |
| 5 (병렬) | TASK-15 | `calculateSuccessRateBreakdown` 유닛 테스트 (10 케이스) |
| 6 | TASK-16 | 전체 회귀 (flutter analyze + flutter test) |

### 설계 결정 (사용자 승인 항목)

- **Q1: sharedCapLoss 처리** → 옵션 A 채택. `PassiveBonusService.getQuestSuccessRateBonusWithDetail()` 신규 API로 `(rawSum, applied, lossAmount)` 레코드 반환. 기존 `getQuestSuccessRateBonus`는 `.applied`만 반환하는 래퍼로 전환 → 기존 22개 테스트 회귀 없음.
- **Q2: DispatchDetailPage preview의 factionPassiveBonus** → 옵션 b 채택. preview에서는 `factionPassiveBonus: 0.0`, `passiveSharedCapLoss: 0.0`으로 근사 처리 (범위 외 `CollectedEffects` 수집 로직 확장 회피, 주석으로 명기).

## 2. 실제 개발 사항

### 2.1 변경 파일 목록

| 파일 | 변경 유형 | 설명 |
|:---|:---:|:---|
| `band_of_mercenaries/lib/core/models/job.dart` | 수정 | `role` 필드 추가 (`@Default('specialist') @JsonKey(name: 'role')`) |
| `band_of_mercenaries/lib/core/models/job.freezed.dart` | 재생성 | build_runner |
| `band_of_mercenaries/lib/core/models/job.g.dart` | 재생성 | build_runner |
| `band_of_mercenaries/lib/core/domain/passive_bonus_service.dart` | 수정 | `getQuestSuccessRateBonusWithDetail` 신규 + 기존 메서드 래퍼 전환 |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | 수정 | `partyRoles` 파라미터 + `traitBonus.clamp(-10, 10)` + 신규 `calculateSuccessRateBreakdown` |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 수정 | 호출부에 `partyRoles: RoleUtils.extractRoles(mercs, staticData.jobs)` 전달 |
| `band_of_mercenaries/lib/features/quest/domain/role_synergy_matrix.dart` | 신규 | 6×4 매트릭스 + `singleBonus` / `partyAverageBonus` / `topRolesForQuest` |
| `band_of_mercenaries/lib/features/quest/domain/role_utils.dart` | 신규 | `extractRoles` + `koreanName` |
| `band_of_mercenaries/lib/features/quest/domain/success_rate_breakdown.dart` | 신규 | 성공률 레이어 분해 값 객체 |
| `band_of_mercenaries/lib/features/quest/view/success_rate_breakdown_sheet.dart` | 신규 | 분해 표 표시 `StatelessWidget` |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | 수정 | `?` 아이콘 → 분해 시트 호출 + 용병 카드 role 하이라이트·배지 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | 수정 | `_buildQuestCard`에 추천 role Chip × 2 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` | 수정 | 트레잇 슬롯 아래 "퀘스트 유형별 상성" 섹션 추가 |
| `band_of_mercenaries/test/features/quest/domain/role_synergy_matrix_test.dart` | 신규 | 17 테스트 |
| `band_of_mercenaries/test/features/quest/domain/role_utils_test.dart` | 신규 | 5 테스트 |
| `band_of_mercenaries/test/features/quest/domain/success_rate_breakdown_test.dart` | 신규 | 10 테스트 |

### 2.2 수정하지 않은 파일 (금지사항 준수)

- `band_of_mercenaries/lib/features/mercenary/domain/trait_effect_service.dart` — 본체에 clamp 추가 시 `trait_effect_service_test.dart` 회귀 발생. 대신 `QuestCalculator` 내부에서만 클램프 적용.
- `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart::calculateReward` — P4-2 완료 상태 유지.
- `band_of_mercenaries/lib/features/investigation/domain/investigation_service.dart` — 동명 메서드 `calculateSuccessRate`는 별개 서비스.
- `supabase/migrations/` — 신규 SQL 파일 생성하지 않음 (DB에 이미 `jobs.role` 85개, `traits.effect_json` 15개 적용 완료).

### 2.3 Supabase 현황 검증 결과 (TASK-1)

```
SELECT role, COUNT(*) FROM jobs GROUP BY role ORDER BY role;
→ warrior 26, specialist 16, mage 16, support 10, ranger 9, rogue 8 (총 85) ✅

SELECT key, effect_json FROM traits WHERE effect_json IS NOT NULL AND effect_json::text != '{}';
→ 15행 반환 (charger/coward_king/focused/guardian/hero/hunter_origin/iron_guard/
    scout/shadow/shadow_hunter/strategist/tactician/treasure_hunter/vigilant/wanderer_origin) ✅
```

## 3. 검증 모드 및 결과

### 검증 모드
**풀 검증** (TASK 16개 ≥ 3 기준, verifier 서브에이전트 호출)

### 검증 결과
- **판정: PASS** (1회차 통과, FAIL/재작업 없음)
- FR-1 ~ FR-11 전 항목 충족
- 금지사항 6개 전부 준수
- `flutter analyze` → `No issues found!`
- `flutter test` → **263/263 PASS** (기존 231 + 신규 32)

## 4. build_runner 재실행 필요 파일

- `lib/core/models/job.dart` 수정으로 인해 재실행 완료
  - `lib/core/models/job.freezed.dart` (재생성됨)
  - `lib/core/models/job.g.dart` (재생성됨)
- 이후 수정자가 build_runner를 재실행할 필요 없음

## 5. CLAUDE.md 금지사항 위반 사유

위반 없음.
