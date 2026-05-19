# M8a 전투 보고서 시스템 구현 계획서

> Skill used : implement-agent
>
> 명세서: `Docs/spec/[spec]20260518_m8a-combat-report-system.md`
> 작성일: 2026-05-18
> 마일스톤: M8a 페이즈 4 #2

## 1. 구현 개요

전투 보고서는 중요한 의뢰(세력/지명/엘리트/연계/세력 전용 고급) 완료 시 한 번 생성되어 영속 저장되는 요약(1문장) + 상세 로그(4~8줄) 기록이다. 본 구현은 다음 5개 축을 다룬다:

- **영속 모델**: `CombatReport` Hive 모델(typeId 21) + `ActiveQuest.combatReport` 임베드(HiveField 27)
- **정적 데이터**: `combat_report_templates`(96행) · `combat_report_keywords`(40행) 두 optional 테이블 + freezed 모델 2종
- **서비스**: `CombatReportService.generate` 정적 helper(14단계 + 8 private static helper + private `ImportanceLevel` enum)
- **TemplateEngine 확장**: `{ally.name}` · `{enemy.name}` namespace(resolver + catalog 동시 갱신)
- **UI**: `QuestResultDialog` `ConsumerStatefulWidget` 전환 + 요약 카드 + 상세 뷰 인라인 전환(Navigator.push 금지)

## 2. TASK 실행 결과

총 12개 TASK 모두 PASS. 순차 격리 모드(continuous execution)로 진행. 각 TASK는 coder → verifier → flutter-reviewer 미니 사이클로 검증.

| TASK | 제목 | 모델 | 결과 |
|------|------|------|------|
| TASK-1 | CombatReport Hive 모델 (typeId 21) | haiku | PASS |
| TASK-2 | CombatReportTemplate/Keyword 정적 모델 | haiku | PASS |
| TASK-3 | TemplateEngine ally/enemy namespace | sonnet | PASS |
| TASK-4 | ActivityLogType.combatReportGenerated (HiveField 39) | haiku | PASS (main 직접 처리) |
| TASK-5 | ActiveQuest.combatReport 필드 (HiveField 27) | haiku | PASS (main 직접 처리) |
| TASK-6 | SyncService 테이블 2건 등록 | haiku | PASS (main 직접 처리) |
| TASK-7 | StaticGameData 4-step 통합 | sonnet | PASS (main 직접 처리) |
| TASK-8 | CombatReportService 정적 helper (14단계) | opus | PASS |
| TASK-9 | HiveInitializer CombatReportAdapter 등록 | haiku | PASS (main 직접 처리) |
| TASK-10 | QuestProvider 트리거 삽입 | sonnet | PASS (out-of-scope reviewer 이슈 reject) |
| TASK-11 | QuestResultDialog ConsumerStatefulWidget + UI | opus | PASS |
| TASK-12 | CombatReportService 단위 테스트 | sonnet | PASS (false-positive reviewer 이슈 reject) |

## 3. 변경 파일 목록

### 신규 생성 (5)

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart` | CombatReport Hive 모델 (typeId 21, HiveField 0~7) |
| `band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart` | 보고서 생성 정적 helper (14단계 + 9 private static helper + private enum ImportanceLevel) |
| `band_of_mercenaries/lib/core/models/combat_report_template.dart` | 정적 데이터 모델 freezed (11 필드 + parsedTags extension) |
| `band_of_mercenaries/lib/core/models/combat_report_keyword.dart` | 정적 데이터 모델 freezed (6 필드 + parsedTags extension) |
| `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` | CombatReportService 단위 테스트 (6 시나리오) |

### 수정 (9 + 1 trailing)

| 파일 경로 | 변경 내용 |
|-----------|----------|
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | `@HiveField(27) CombatReport? combatReport` + 생성자 옵션 인자 + import |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `_applyCompletionResult`에 fail-soft trailing 트리거 블록 + import + userData null 가드 |
| `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart` | ConsumerWidget → ConsumerStatefulWidget 전환 + `_showDetail` 상태 + AnimatedSwitcher(150ms) + `_buildSummaryView` / `_buildDetailView` 분리 + `_CombatReportSummaryCard` 사설 클래스 + protagonist/featured Chip + import |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `@HiveField(39) combatReportGenerated` enum 값 추가 |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | `Hive.registerAdapter(CombatReportAdapter())` (ActiveQuestAdapter 이전) + import |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables` + `optionalTables` 양쪽에 `combat_report_templates` · `combat_report_keywords` 등록 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | 4-step (import 2 + 필드 2 + 생성자 매개변수 2 + loadFromCache 2) 통합 |
| `band_of_mercenaries/lib/core/domain/template_context.dart` | `String? allyName` 필드 추가 (`enemyName`은 기존 재사용) |
| `band_of_mercenaries/lib/core/domain/template_engine/resolver.dart` | switch에 `case 'ally'` · `case 'enemy'` 분기 + `_resolveAllyField` · `_resolveEnemyField` helper 함수 2개 (기존 `_resolveQuestField`의 `case 'enemy'` 보존) |
| `band_of_mercenaries/lib/core/domain/template_variable_catalog.dart` | `namespaces` Set에 `ally`, `enemy` + `entries`에 `ally.name`, `enemy.name` spec |

### 빌드 게이트(PHASE 2.5) trailing 수정 — dart-build-resolver 영역

PHASE 2.5에서 `StaticGameData`에 신규 required 필드 2개가 추가되면서 기존 테스트 fixture 누락 + `ActivityLogType` switch 비포괄로 다음 6 파일 외과적 수정:

| 파일 경로 | 변경 내용 |
|-----------|----------|
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | `ActivityLogType.combatReportGenerated` case 추가 (`📋` 아이콘, normal weight) |
| `band_of_mercenaries/test/features/crafting/domain/crafting_service_test.dart` | `_makeStaticData`에 `combatReportTemplates: const []` · `combatReportKeywords: const []` 추가 |
| `band_of_mercenaries/test/features/inventory/view/inventory_screen_test.dart` | 동일 |
| `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` | 동일 |
| `band_of_mercenaries/test/features/quest/domain/quest_narrative_render_test.dart` | 동일 |
| `band_of_mercenaries/test/features/quest/domain/special_flag_processor_test.dart` | 동일 |

### build_runner 재생성 (5쌍)

- `combat_report_model.g.dart` (Hive 어댑터)
- `quest_model.g.dart` (HiveField 27 추가 → 재생성)
- `activity_log_model.g.dart` (HiveField 39 추가 → 재생성)
- `combat_report_template.freezed.dart` + `combat_report_template.g.dart`
- `combat_report_keyword.freezed.dart` + `combat_report_keyword.g.dart`
- `template_context.freezed.dart` (allyName 필드 추가 → 재생성)

## 4. 실행 모드 및 검증 결과

### 실행 모드
- 순차 격리 모드 (TASK 수 12 ≥ 5, continuous execution)

### 검증 모드
- PHASE 3-C: 순차 격리 모드 final integration sanity check
- PHASE 2 내부에서 TASK별 verifier + flutter-reviewer 모두 PASS 완료

### 결과 요약
- verifier: 12/12 PASS
- flutter-reviewer:
  - APPROVE 10건
  - BLOCK 2건 — 모두 거짓 양성으로 판단하여 reject:
    - TASK-10: 지적된 이슈 2건(quest_provider L1396, app.dart L262)이 TASK-10 변경 범위 외 (기존 코드)
    - TASK-12: 5건 이슈 모두 거짓 양성 (chain not-final 케이스는 의도적 / `importance`는 freezed required 필드 / `partyMercs.isEmpty`는 명세 엣지 케이스 / 팩토리 호출은 const 불가)

### 최종 빌드 게이트 (PHASE 2.5)
- `flutter analyze`: **No issues found**
- `flutter test`: **576/576 통과** (회귀 없음)
- `dart run build_runner build --delete-conflicting-outputs`: PASS

### 최종 통합 검증 (PHASE 3-C)
- typeId 21 충돌 0건 (`combat_report_model.dart`만 1건)
- `CombatReportAdapter` 등록 위치 정확 (`ActiveQuestAdapter` 이전)
- `SyncService.allTables` + `optionalTables` 양쪽 등록 ✓
- `StaticGameData` 4-step 완전 (import → 필드 → 생성자 → loadFromCache) ✓
- `QuestProvider._applyCompletionResult` 트리거 — fail-soft try/catch + 멱등 가드 + ActivityLog 발급 ✓
- `Navigator.push` 0건 (quest_result_dialog.dart, CLAUDE.md UI 제약 준수) ✓
- TemplateEngine resolver + catalog 양쪽 ally/enemy namespace 등록 ✓
- `print(` 사용 0건 (`debugPrint`만 사용, `avoid_print` 준수) ✓

## 5. CLAUDE.md 준수 / 위반

CLAUDE.md 금지사항 위반 없음.

- 한국어 주석/메시지 일관 유지
- Navigator.push 금지 (상태 기반 렌더링) — `_showDetail: bool` 토글로 인라인 전환
- avoid_print 활성 — `debugPrint` 사용
- typeId 12 미사용 보존
- 재생성 파일 직접 편집 금지 — 모두 build_runner로 갱신
- 이벤트 채널 패턴: 본 명세는 dialogQueue 외 별도 신규 진입점 없음 (`QuestResultDialog` 자체는 기존 호출 경로 유지)

## 6. CLAUDE.md 갱신 필요 항목 (finalize-feature 영역)

본 스킬에서는 CLAUDE.md를 직접 수정하지 않는다. `finalize-feature` 단계에서 다음 항목을 반영해야 한다:

### typeId 점유 및 다음 HiveField 번호 표

- ActiveQuest 다음 HiveField: 27 → **28**
- ActivityLogType (enum) 다음 HiveField: 35 → **40** (실제 점유 39까지)
- 신규 모델: **CombatReport** (typeId 21, 다음 HiveField **8**) 추가
- "사용 중 typeId" 표에 **21** 추가 (typeId 12는 여전히 미사용 보존)

### 영속성 (Hive) 박스 — 변경 없음
- 별도 `combatReports` 박스는 만들지 않음 (M8.5/M9에서 검토 — 명세 Q-4)

### 정적 데이터 테이블 — 32개 → 34개
- 신규: `combat_report_templates`(96행, M8a 추가, optional) · `combat_report_keywords`(40행, M8a 추가, optional)
- `SyncService.allTables` 36 · 37번째로 등록

### "게임 핵심 시스템 로직" 절
다음 항목 추가:
- **전투 보고서 시스템 (M8a 페이즈 4 #2)**: `CombatReport` Hive 모델(typeId 21) + `ActiveQuest.combatReport` HiveField 27 임베드. `CombatReportService.generate(quest, partyMercs, resultType, staticData, userData, factionStates, templateEngine, regionState?, sectorChanges?, seed?)` 정적 helper — 14단계(seed → resultKey → importance → scopeChain → summary 1줄 → details N줄 → protagonist → ally → enemy → render → toneTags → templateIds). `QuestProvider._applyCompletionResult` 트리거(fail-soft trailing) — `result.combatReportEligible && quest.combatReport == null` 가드 + try/catch + 성공 시 `ActivityLogType.combatReportGenerated` HiveField 39 발급. `ImportanceLevel { normal, high, veryHigh }` 5분기(유니크 엘리트/일반 엘리트/chain_final/chain_step/faction_named+신뢰/faction_named 기본/fallback). scope 7종(`chain_final`/`chain_step`/`settlement_event`/`unique_elite`/`elite`/`faction_named`/`quest_type` + `scene` 보충풀). `result_type` 매핑(`_resultTypeKey`)으로 CSV snake_case ↔ Dart camelCase 분리. `combat_report_templates`/`combat_report_keywords`는 optional table — 빈 캐시 = 보고서 미생성 fallback. `QuestResultDialog`는 `ConsumerStatefulWidget`로 전환 — `_showDetail: bool` 상태 + `AnimatedSwitcher`(150ms) 인라인 전환(Navigator.push 금지). `_CombatReportSummaryCard` 사설 클래스로 요약 카드 분리. 상세 뷰는 4px 좌측 보더(결과 색상) + protagonist/featured `Chip`(lookup 실패 시 숨김).

### TemplateEngine
- `{ally.name}` · `{enemy.name}` namespace 추가. `TemplateContext.allyName: String?` 필드 추가(`enemyName`은 기존 재사용). resolver와 `TemplateVariableCatalog` 양쪽 등록. 기존 `{quest.enemy}` 분기는 보존(중복 허용).

## 7. 결정사항 / 특이사항

- **chain final 판정**: 명세 의사코드는 `chain.steps.length == (quest.chainStep ?? -1) + 1`로 표기했으나, 실제 `ChainQuestData` 모델은 step + totalSteps 행 단위 구조. `_isChainFinalStep` private helper로 분리 — `chainQuests.where((c) => c.chainId == quest.chainId)` 후 `totalSteps` 최댓값과 `(quest.chainStep ?? -1) + 1` 비교. `_resolveImportance` + `_resolveScopeChain` 양쪽 재사용.
- **scope 시퀀스 끝 'scene'**: 명세 표상 scene은 "decisive 보충용, 직접 선택 안 함". 구현은 `_resolveScopeChain` 반환 리스트 끝에 항상 'scene' 추가 + `_pickSummary`에서는 skip + `_pickDetails`에서만 보충풀로 사용.
- **enemyName 키워드 매칭**: `quest.region`(int)과 tagsJson `region`(String/int/List 가능)을 호환하기 위해 `_matchesTagValue` 헬퍼 도입. `quest_type`도 동일 헬퍼로 매칭.
- **factionId 매칭**: `quest.factionTag`와 비교. `quest.factionTag`가 null이면 factionId가 null인 템플릿만 매칭.
- **`importance` 필드**: `CombatReportTemplate.importance`는 freezed required 필드로 보존되지만, 실제 importance 분기는 `_resolveImportance(quest, staticData, userData)` 내부 로직으로 결정 (템플릿 importance 컬럼은 시드 데이터 분류용으로 미래 확장 여지).
- **detail targetCount 클램프**: 전체 scope 매칭 풀 합산을 먼저 산출 → `_resolveDetailLineCount(importance, random, poolSize)`로 균등 분포 추첨 + poolSize 클램프 → scope별 비복원 순회.
- **RegionState 매개변수**: 명세 시그니처에 `regionState`가 옵션 인자로 명시. 현 generate 본체에서는 직접 사용하지 않지만, 향후 확장(특정 region 상태에 따른 추가 컨텍스트)을 위해 시그니처에 보존. `sectorChanges`는 이미 `TemplateContext.sectorChanges` 변환 입력으로 사용 중.
- **TASK-4·5·6·7·9 main 직접 처리**: mechanical 변경(enum 1행, HiveField 1개, 리스트 인덱스 2건, 4-step 통합)은 coder Agent 호출 없이 main이 직접 Edit으로 처리하여 비용 절감. 모두 PHASE 2.5에서 전체 빌드 게이트로 정합성 검증.

## 8. M8a 범위 밖 (M8.5/M9 위임)

명세서 Q-2, Q-4, Q-5에 따라 다음 항목은 M8a 범위 밖이다 (별도 작업으로 분리):

- 결과 다이얼로그 닫힘 이후 장기 재열람 화면 (별도 `combatReports` 박스 또는 완료 기록 모델 도입 필요)
- `protagonistMercId` 발급 시점 이름 동결 (MercenarySnapshot 활용)
- 의뢰 카드 "보고서 생성" 배지 미리보기

## 9. 후속 작업 안내

- **CLAUDE.md 갱신**: HiveField 표(ActiveQuest 28, ActivityLogType 40), 새 모델(CombatReport typeId 21), 정적 데이터 테이블 수(34개), "게임 핵심 시스템 로직" 절에 전투 보고서 시스템 항목 추가 — `finalize-feature` 단계.
- **CHANGELOG Fragment 생성**: `Docs/changelog-fragments/` — `finalize-feature` 단계.
- **Supabase 시드 SQL**: `combat_report_templates`(96행) + `combat_report_keywords`(40행) INSERT — 데이터 파이프라인 담당자 작업 (본 PR 범위 외).
- **`data_versions` 행 추가**: 두 신규 테이블의 version 행 추가 (Supabase 측, 본 PR 범위 외).
- **git commit & archive**: 명세서·계획서를 `Docs/Archive/`로 이동 + 커밋 — `finalize-feature` 단계.

```
커밋과 아카이브가 필요하시면 finalize-feature 스킬을 실행해주세요.
```
