# M8a 페이즈 4 통합 구현 명세 및 검증 계획

> 기획 문서:
> - `Docs/milestone-runs/M8a/state.md` (M8a 마일스톤 상태)
>
> 통합 대상 산출물(페이즈 4 #1~#3):
> - `Docs/spec/[spec]20260518_m8a-faction-system.md` + `_plan.md`
> - `Docs/spec/[spec]20260518_m8a-combat-report-system.md` + `_plan.md`
> - `Docs/spec/[spec]20260519_m8a-static-data-sync-and-ops.md`
>
> 페이즈 1·2·3 산출물:
> - `Docs/content-design/[content]20260518_m8a_*.md` (4 문서)
> - `Docs/balance-design/[balance]20260518_m8a_*.md` (3 문서)
> - `Docs/content-data/*20260518_m8a-*.csv` (5 산출물, CSV/MD 페어)
>
> 작성일: 2026-05-19
> 마일스톤: M8a 페이즈 4 #4

## 1. 개요

본 명세는 **M8a "세력의 귀환" 마일스톤의 통합 회고 및 검증 계획**이다. 페이즈 4 #1~#3에서 코드·데이터·정책이 모두 적용 완료된 상태이며, 본 #4는 신규 코드 변경을 동반하지 않는다. 목적은 다음 5가지를 단일 문서로 통합하는 것이다.

1. 페이즈 1~4 산출물 통합 결과 요약(회고)
2. 명세 vs 실제 구현 정합성 검증 결과
3. M1~M7 회귀 검증 및 M8a 완료 기준 9개 체크리스트 충족 여부
4. `band_of_mercenaries/CLAUDE.md` 갱신 필요 항목 목록
5. `finalize-feature` 인계 사항 및 후속 마일스톤(M8b) 잔여 백로그

본 문서가 PASS되면 사용자는 `finalize-feature` 스킬을 실행하여 CHANGELOG fragment 작성·CLAUDE.md 갱신·Archive 이동·commit/PR을 일괄 처리한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### 2.1.A 마일스톤 회고

- **[FR-A1] 페이즈 1~4 산출물 매트릭스**
  - 페이즈 1(컨텐츠 설계) 4 산출물, 페이즈 2(밸런스 확정) 3 산출물, 페이즈 3(데이터 생성) 5 산출물 + CSV 페어, 페이즈 4(개발 명세) 4 산출물(본 문서 포함)을 단일 매트릭스로 정리한다.
  - 매트릭스는 본 명세 2.2.A 절에 표로 첨부한다.

- **[FR-A2] 코드 변경 통계 요약**
  - 페이즈 4 #1 구현: 35 파일 변경(신규 16 + 수정 14 + 빌드 게이트 외과적 5).
  - 페이즈 4 #2 구현: 20 파일 변경(신규 5 + 수정 9 + 빌드 게이트 trailing 6).
  - 페이즈 4 #3: 코드 변경 0 파일(정책 문서).
  - 합계: **55 파일 변경** + build_runner 재생성 12쌍(faction 7쌍 + combat-report 5쌍).
  - 변경 파일 상세는 각 산출물의 `_plan.md`를 단일 진실원(SSOT)으로 둔다.

- **[FR-A3] 정적 데이터·Hive·Supabase 변경 요약**
  - 신규 Supabase 정적 테이블 5개: `faction_contacts`(3행) · `faction_reactions`(33행) · `faction_shop_items`(18행) · `combat_report_templates`(96행) · `combat_report_keywords`(40행). 5개 모두 `SyncService.optionalTables` 등록.
  - 기존 테이블 행 추가: `quest_pools` +12 (세력 지명 의뢰) · `items` +4 (세력 보상 아이템) · `crafting_recipes` +2 (세력 레시피) · `titles` +2 (세력 칭호).
  - 신규 Hive typeId: 20 `FactionShopDailyEntry` · 21 `CombatReport`.
  - 신규 HiveField: `FactionState` 6/7/8/9 · `ActiveQuest` 27 · `ActivityLogType` 35/36/37/38/39.

#### 2.1.B 실제 구현 vs 명세 정합성 검증

- **[FR-B1] SyncService 등록 정합성**
  - `band_of_mercenaries/lib/core/data/sync_service.dart` L18~56 `allTables` 리스트가 정확히 37개를 포함하며, M8a 신규 5 테이블이 인덱스 33~37에 등록되어 있음을 verifier가 grep로 확인한다.
  - `optionalTables` Set(L60~66)이 M8a 신규 5 테이블만 포함함을 확인한다.

- **[FR-B2] Hive typeId·HiveField 정합성**
  - 다음 grep 결과로 typeId 점유 상태를 확인한다(`band_of_mercenaries/lib/**/*.dart`에서 `.g.dart` / `.freezed.dart` 제외).
    - 사용 중 typeId: 0·1·2·3·4·5·6·7·8·9·10·11·13·14·15·16·17·18·19·**20·21**
    - typeId 12 미사용 보존 ✓
  - HiveField 분포(M8a 추가분):
    - `FactionState`(typeId 9) HiveField 6/7/8/9
    - `ActiveQuest` HiveField 27 (`combatReport: CombatReport?`)
    - `ActivityLogType`(typeId 6) HiveField 35~39 (5종 신규)
    - `CombatReport`(typeId 21) HiveField 0~7 (8 필드)
    - `FactionShopDailyEntry`(typeId 20) HiveField 0~1 (2 필드)

- **[FR-B3] 빌드 게이트 통과 상태**
  - 본 명세 작성 시점(2026-05-19) 검증:
    - `flutter analyze` → `No issues found! (ran in 2.4s)`
    - `flutter test` → **578 tests PASS** (페이즈 4 #1 종료 568 → #2 종료 576 → +2개 추가 PASS, 회귀 0)
  - 빌드 게이트가 통과 상태에서 verifier가 본 명세를 검토해야 한다. 검증 실패 시 본 명세 PASS 보류.

- **[FR-B4] CLAUDE.md UI 제약 준수 확인**
  - `QuestResultDialog` 상세 뷰 전환은 `Navigator.push` 사용하지 않고 `_showDetail: bool` + `AnimatedSwitcher`(150ms)로 인라인 처리됨.
  - `FactionContactArrivedDialog` 진입도 `dialogQueueProvider`(medium) + `factionCodexScrollTargetProvider` 상태 기반 렌더링 사용.
  - `avoid_print`(analysis_options.yaml 활성) 위반 0건. `debugPrint`만 사용.

- **[FR-B5] 명세서에서 명시적으로 보존된 reviewer 이슈**
  - 페이즈 4 #1 구현 시 flutter-reviewer가 BLOCK한 5건 중 4건은 명세서가 명시적으로 지시한 설계 결정으로 보존(WidgetRef DI / StateError 흐름 제어 / 매직 스트링 reason / 도메인 테스트 별도 작업 분리). 본 검증에서는 "명세 의도 보존"으로 PASS 처리한다.
  - 페이즈 4 #2 구현 시 BLOCK 2건은 모두 거짓 양성으로 판단되어 reject. 본 검증 대상 외.

#### 2.1.C M1~M7 회귀 검증 결과

- **[FR-C1] 테스트 수치 추적**
  - 마일스톤 진입 시점(M7 종료) 테스트 수: 547개 추정(M7 페이즈 4 #4 종료 시).
  - 페이즈 4 #1 종료(2026-05-18T17:45): **568 PASS**.
  - 페이즈 4 #2 종료(2026-05-18T21:54): **576 PASS** (CombatReportService 단위 테스트 +6 + 기타 +2 추정).
  - 페이즈 4 #3 종료(2026-05-19T07:40): 코드 변경 0, 테스트 수치 유지.
  - 본 명세 작성 시점(2026-05-19): **578 PASS** (M8a 진행 중 발생한 +2 추가 — 출처는 verifier가 git log로 확인).
  - 회귀(이전 PASS → FAIL 전환) **0건**.

- **[FR-C2] flutter analyze 정적 분석 결과**
  - 본 명세 작성 시점: `No issues found!`
  - 마일스톤 전 기간 0 issues 유지(페이즈 4 #1 빌드 게이트에서 13 errors → 0, 페이즈 4 #2 빌드 게이트에서 trailing 6 파일 외과적 수정으로 0 유지).

- **[FR-C3] 기존 시스템 영향 무중단 확인**
  - 본 명세는 다음 기존 시스템의 사이드이펙트가 모두 fail-soft trailing으로 추가되었음을 확인한다(실패 시 본체 흐름 중단 없음):
    - `_applyCompletionResult`(quest_provider.dart) → 세력 평판 hook + 세력 보상 hook + 전투 보고서 생성 hook (3개 모두 try/catch)
    - `RegionStateRepository.toggleFlag` → 인프라 전이(기존 M7) 보존
    - `RegionStateRepository.addDangerScore` → 위업 grant(기존 M7) 보존
    - `app.dart` `factionContactArrivedProvider` ref.listen + initState/resumed hook(M8a #1 신규)
  - QuestNarrativeService의 `renderedNarrative` 1회 렌더 정책은 그대로 유지(전투 보고서는 그 위에 덧붙는 확장 계층).

#### 2.1.D M8a 완료 기준 9개 체크리스트 충족 여부

마일스톤 상태 파일(`Docs/milestone-runs/M8a/state.md` L134~144)의 9개 완료 기준 각각에 대해 현재 충족 여부를 평가한다.

| # | 완료 기준 | 충족 상태 | 근거 |
|---|----------|----------|------|
| 1 | 대표 세력 2~3개가 생활권 사건과 연결되어 등장한다. | **충족** | 페이즈 1 #1에서 모험가 길드·상인 연합·전사 길드 3 세력 확정. 페이즈 4 #1 `FactionContactService.isActive`로 region 3 인프라/위업/region_flag와 연결된 활성 평가 구현. CSV 33행 반응 텍스트로 시드. |
| 2 | 세력 지명 의뢰가 위업, 신뢰도, 칭호, 지역 상태 조건으로 노출된다. | **충족** | `NamedHookEvaluator` 3 hook 확장(region_flag / faction_contact / faction_reputation) + 기존 achievement_count hook. `quest_pools` 12행 시드. |
| 3 | 세력 상점 상품이 제작 재료 또는 레시피와 연결된다. | **충족** | `faction_shop_items` 18행 중 material_bundle 카테고리 상품 + 레시피 보상 2종(`recipe_m8a_record_compass`·`recipe_m8a_trade_seal`). |
| 4 | 세력 보상이 용병단 위상 또는 지역 상태에 영향을 준다. | **충족** | 칭호 2종(`title_m8a_guild_ledger_name`·`title_m8a_duel_marked`)이 `Mercenary.titleIds`에 발급되어 `flagshipMercenaryProvider` 정렬에 반영. 아이템 보상 4종은 `FactionState.grantedRewardIds`로 dedup. |
| 5 | 세력·지명·엘리트·연계 의뢰 결과에 전투 보고서가 저장된다. | **충족** | `CombatReport` typeId 21 + `ActiveQuest.combatReport` HiveField 27 임베드. `CombatReportService.generate` 14단계가 `quest.specialFlags['combat_report']==true` 의뢰 완료 시 fail-soft trailing으로 생성·저장. |
| 6 | 전투 보고서는 요약과 상세 로그를 구분하여 표시된다. | **충족** | `QuestResultDialog`가 `ConsumerStatefulWidget`으로 전환되어 `_showDetail: bool` + `AnimatedSwitcher`(150ms)로 요약 카드 ↔ 상세 뷰 인라인 전환. 상세 뷰는 4px 좌측 보더 + protagonist/featured `Chip`. |
| 7 | 전투 보고서는 완료 후 재접속해도 동일하게 유지된다. | **충족** | `ActiveQuest` 내 임베드로 Hive 박스에 자동 영속화. `quest.combatReport != null` 멱등 가드로 재생성 차단. 단 **결과 다이얼로그 닫힘 이후 장기 재열람은 M8a 범위 외**(M8.5/M9 위임 — 명세 #2 Q-4 결정). |
| 8 | 14세력 전체 확장을 전제로 하지 않아도 MVP가 완결된다. | **충족** | 대표 3 세력만 깊게 구현. 11 미구현 세력은 기존 M1 시드 그대로 유지. `FactionContactService.isActive`는 contactId가 없는 세력에 대해 빈 결과 반환으로 fail-soft. |
| 9 | M1~M7 기능 회귀 이상 없음. | **충족** | 578 tests PASS(회귀 0). `flutter analyze` 0 issues. CLAUDE.md UI 제약 위반 0건. |

**최종 판정**: 9/9 충족. 본 명세 PASS 시점에 M8a 완료 기준 모두 충족 상태로 전환.

#### 2.1.E CLAUDE.md 갱신 필요 항목 목록

본 명세는 CLAUDE.md를 직접 수정하지 않는다. `finalize-feature` 단계에서 다음 7개 영역을 반영한다.

- **[FR-E1] 정적 데이터 테이블 카운트**
  - 현재(L115): `**테이블 (32개):**` → **`**테이블 (37개):**`** 로 갱신.
  - 본문 마지막에 5 테이블 추가 텍스트 첨가:
    - `faction_contacts(M8a 페이즈 4 #1 신설 3행, optional)`
    - `faction_reactions(M8a 페이즈 4 #1 신설 33행, optional)`
    - `faction_shop_items(M8a 페이즈 4 #1 신설 18행, optional, 18종 가격 80~750G·평판 1/11/31/61 해금)`
    - `combat_report_templates(M8a 페이즈 4 #2 신설 96행, optional, scope 7종 + scene 보충풀)`
    - `combat_report_keywords(M8a 페이즈 4 #2 신설 40행, optional, category battlefield/enemy/decisive)`
  - 기존 `quest_pools(341행)` → `quest_pools(353행·M8a +12 세력 지명 의뢰)` 또는 별도 명시.
  - 기존 `items` 확장 → `+4 (M8a 세력 보상 4종: guild_artifact_record_compass·guild_artifact_trade_seal·guild_artifact_merchant_warrant·equip_accessory_red_spear_wristwrap)`.
  - 기존 `crafting_recipes(16행)` → `crafting_recipes(18행·M8a +2)`.
  - 기존 `titles(11행)` → `titles(13행·M8a +2)`.
  - 기존 `band_achievement_templates(34행)` → 변경 없음(M8a는 위업 신규 추가 없음).

- **[FR-E2] typeId 점유 및 다음 HiveField 표 갱신**
  - L131~147 표에 다음 행 추가/수정:
    - `ActiveQuest` 다음 HiveField: **27 → 28**
    - `ActivityLogType (enum)` 다음 HiveField: **35 → 40**
    - `FactionState` 다음 HiveField: **6 → 10**
    - 신규 행: `FactionShopDailyEntry | 20 | 2`
    - 신규 행: `CombatReport | 21 | 8`
  - L149: `사용 중 typeId: 6·8·9·10·11·13·14·15·16·17·18·19.` → **`6·8·9·10·11·13·14·15·16·17·18·19·20·21.`** (typeId 12는 여전히 미사용 보존)
  - `신규 모델은 **20+** 사용` 문구는 → **`22+`** 로 갱신.

- **[FR-E3] "게임 핵심 시스템 로직" 절 신규 항목 2개 추가**
  - **세력 수직 절편 시스템(M8a 페이즈 4 #1)**: 페이즈 4 #1 `_plan.md` 6번 표의 핵심 내용을 1 단락으로 압축. 핵심 키워드 — `FactionContactService.isActive` 동기 헬퍼 · `FactionRelationStage.resolve` 7단계 enum · `FactionShopService.evaluateUnlock` 6단계 + `purchase` 5단계 · `NamedHookEvaluator` 3 hook 확장(region_flag/faction_contact/faction_reputation) · `QuestCompletionService` `factionRepGain` 분기 교체(`faction_named` 우선) · `_applyCompletionResult` trailing fail-soft 3 hook(평판/칭호/아이템 보상) · `CraftingService._isUnlockedM7` 2 case 추가(factionReputation/factionContact) · `TitleService.evaluateFactionReputationHook` 신규 · `FactionState` HiveField 6~9 (shopPurchaseHistory/shopDailyPurchases/grantedRewardIds/contactUnlockedIds) · `FactionShopDailyEntry` typeId 20 · `FactionContactArrivedDialog`(medium, dialogQueueProvider) · 3 신규 섹션(`FactionContactSection`·`FactionNamedQuestSection`·`FactionShopSection`).
  - **전투 보고서 시스템(M8a 페이즈 4 #2)**: 페이즈 4 #2 `_plan.md` L150의 단락을 그대로 사용 가능. 핵심 키워드 — `CombatReport` typeId 21 + `ActiveQuest.combatReport` HiveField 27 임베드 · `CombatReportService.generate` 14단계 + 9 private static helper · scope 7종 + scene 보충풀 · `ImportanceLevel { normal, high, veryHigh }` · `_resultTypeKey` snake_case↔camelCase 매핑 helper · `_resolveScopeChain` 좁은→넓은 fallback · `TemplateEngine` `ally`/`enemy` namespace 추가 · `QuestResultDialog` `ConsumerStatefulWidget` 전환 + `_showDetail: bool` + `AnimatedSwitcher`(150ms) 인라인 전환 · `_CombatReportSummaryCard` 사설 클래스 · `combat_report_templates`·`combat_report_keywords` optional table · `ActivityLogType.combatReportGenerated` HiveField 39.

- **[FR-E4] M6 페이즈 4 #3 지명 의뢰 시스템 절(L180) M8a 후속 확장 명시**
  - 기존 `NamedHookEvaluator` 4종 hook 설명에 **3 hook 확장(M8a 페이즈 4 #1)** 추가:
    - `region_flag`: `RegionState.unlockedFlags` 또는 위업 templateId fallback.
    - `faction_contact`: `FactionContactService.isActive(contactId)`.
    - `faction_reputation`: `faction_<id>>=<int>` 파싱.
  - `NamedHookContext`에 3 신규 필드(`unlockedRegionFlags` · `activeContactIds` · `factionReputations`) 추가 명시.
  - 세력 지명 의뢰 카드는 기존 `AppTheme.namedAccent`(0xFFE91E63) 그대로 사용.

- **[FR-E5] 마을 인프라 절(L184) 외래 좌판/제작 unlock 후속 확장 명시**
  - `CraftingService._isUnlockedM7` switch 4 type → **6 type**(추가: `factionReputation` · `factionContact`).
  - `RecipeUnlockCondition` freezed 4 nullable 필드 보존(기존 M7 구조 재사용).

- **[FR-E6] 데이터 흐름 절(L88~94) 갱신 — 변경 없음**
  - 본 마일스톤은 새로운 데이터 흐름 패턴을 추가하지 않음(기존 `사용자 액션 → Repository → Hive → StateNotifier → UI` 패턴 그대로 사용).

- **[FR-E7] AppTheme 색상 절(`namedAccent` 등) 갱신 — 변경 없음**
  - M8a는 기존 색상을 그대로 사용(전투 보고서 카드는 결과 색상 4종 `greatSuccess/success/failure/criticalFailure` 재사용).

#### 2.1.F finalize-feature 인계 사항

- **[FR-F1] CHANGELOG fragment 작성**
  - `Docs/changelog-fragments/` 디렉토리에 다음 3개 fragment 생성:
    - `2026-05-18-m8a-faction-system.md` — 페이즈 4 #1 (세력 수직 절편)
    - `2026-05-18-m8a-combat-report-system.md` — 페이즈 4 #2 (전투 보고서)
    - `2026-05-19-m8a-static-data-and-integration.md` — 페이즈 4 #3+#4 (정적 데이터 정책 + 통합 회고)
  - 각 fragment는 사용자 관점(features added / data added / fixes / known issues) 항목을 한국어로 1~3줄씩 기재.

- **[FR-F2] Archive 이동 대상 파일 목록**
  - `Docs/spec/` → `Docs/Archive/` (또는 `Docs/Archive/M8a/`)로 이동할 파일:
    - 페이즈 1 산출물 4개 (`Docs/content-design/[content]20260518_m8a_*.md`)
    - 페이즈 2 산출물 3개 (`Docs/balance-design/[balance]20260518_m8a_*.md`)
    - 페이즈 3 산출물 5쌍 CSV + MD (10개 파일, `Docs/content-data/*20260518_m8a-*`)
    - 페이즈 4 산출물 4개 + 2개 `_plan.md` (총 6개, `Docs/spec/[spec]20260518_m8a-*` 및 `[spec]20260519_m8a-*`)
  - **finalize-feature 이전 단계의 사용자 메모리 정책**: Archive 단계에서 spec/plan 원본 git rm 금지, 복사만 수행. (참조: `memory/feedback_finalize_feature_archive.md`)

- **[FR-F3] git commit 메시지 권장 구조**
  - 단일 통합 커밋 권장(브랜치 단위가 M8a 마일스톤 1개로 정렬). 메시지 예시:
    ```
    M8a 세력의 귀환 — 세력 수직 절편 + 전투 보고서 + 정적 데이터 정책

    - 세력 접촉점/상점/지명 의뢰: 35 파일 (신규 16 + 수정 14 + 빌드 게이트 5)
    - 전투 보고서: 20 파일 (신규 5 + 수정 9 + 빌드 게이트 6)
    - 정적 데이터 동기화 정책: 코드 변경 없음 (운영 정책 문서)
    - 통합 회고 및 검증 계획: M8a 완료 기준 9/9 충족, 회귀 0

    flutter analyze: 0 issues
    flutter test: 578 PASS
    CLAUDE.md 갱신 7개 영역 동시 반영
    ```
  - 커밋 분리가 필요하면 페이즈 4 #1/#2/#3+#4 3 커밋으로 분리 가능.

- **[FR-F4] M8a 마일스톤 상태 파일 종료 처리**
  - `Docs/milestone-runs/M8a/state.md`의 페이즈 4 #4 체크박스([ ] → [x])로 갱신.
  - 상태 헤더 `현재 페이즈: 4` → `완료` 또는 `archived`로 전환.
  - 마일스톤 종료 시각 기록(예: 2026-05-19T08:30:00+09:00).
  - 완료 기준 9개 체크박스 모두 [x]로 갱신.

#### 2.1.G 후속 마일스톤(M8b) 진입 시 잔여 백로그

- **[FR-G1] Q-1 잔여 검증 작업 — `faction_*` Supabase 시드 상태 확인**
  - 페이즈 4 #3 명세 Q-1: M8a #1 마이그레이션이 실제 Supabase에 적용되었고, `data_versions`에 `faction_contacts` · `faction_reactions` · `faction_shop_items` 행이 존재하는지 미검증 상태.
  - **검증 SQL**(verifier 또는 finalize-feature 단계에서 실행):
    ```sql
    SELECT table_name, version, updated_at
    FROM data_versions
    WHERE table_name IN (
      'faction_contacts', 'faction_reactions', 'faction_shop_items',
      'combat_report_templates', 'combat_report_keywords'
    )
    ORDER BY table_name;
    ```
    기대 결과: 5 row 반환, 모두 version >= 1.
  - **행 카운트 SQL**:
    ```sql
    SELECT 'faction_contacts' AS table_name, COUNT(*) AS rows FROM faction_contacts
    UNION ALL SELECT 'faction_reactions', COUNT(*) FROM faction_reactions
    UNION ALL SELECT 'faction_shop_items', COUNT(*) FROM faction_shop_items
    UNION ALL SELECT 'combat_report_templates', COUNT(*) FROM combat_report_templates
    UNION ALL SELECT 'combat_report_keywords', COUNT(*) FROM combat_report_keywords;
    ```
    기대 결과: 3 · 33 · 18 · 96 · 40.
  - 미적용 환경에서는 `optionalTables` fail-soft로 클라이언트 기동은 보장되지만, 게임 기능은 빈 데이터로 동작. 마일스톤 완료 선언 전 검증 필요.

- **[FR-G2] Q-2 잔여 작업 — operation-bom `table-config.ts` 일괄 등록**
  - 현재 `/Users/radiogaga/git/operation-bom/src/lib/table-config.ts`에 17개 테이블만 등록되어 있어, **M2a~M8a 신규 다수 미등록** 상태.
  - 미등록 추정 테이블(검증 필요):
    - M2a: `items` · `elite_monsters` · `elite_loot_tables`
    - M3: `chain_quests` · `quest_narratives` · `travel_choice_events` · `travel_choice_options` · `travel_choice_results`
    - M4: `region_sectors`
    - M5: `crafting_recipes` · `quest_pool_material_drops`
    - M6: `band_achievement_templates` · `titles`
    - M7: `region_adjacency`
    - M8a: `faction_contacts` · `faction_reactions` · `faction_shop_items` · `combat_report_templates` · `combat_report_keywords`
  - 일괄 등록 PR은 별도 백로그로 분리. 본 마일스톤 완료 선언과 독립.
  - `category` 분류 4종(world/mercenary/balance/quest/trait)에 신규 `faction` 카테고리 신설 검토.
  - `tags_json` JSONB 컬럼은 `FieldType: "json"` 사용.

- **[FR-G3] M8b 진입 시 추가 인계 항목**
  - **결과 다이얼로그 닫힘 이후 장기 재열람**(M8a #2 Q-4): 별도 `combatReports` 박스 또는 완료 기록 모델 도입 필요. M8b 또는 M8.5에서 처리.
  - **`protagonistMercId` 발급 시점 이름 동결**(M8a #2 Q-2): `MercenarySnapshot` 활용. M8a #2 명세에서 범위 외로 결정.
  - **세력 갈등 페널티 (-1 평판)**(M8a #1 Q-3): 상인 연합 vs 전사 길드 약한 갈등. M8a #1에서 범위 외로 결정.
  - **`material_bundle` 묶음 보상 확장**(M8a #1 Q-5): 묶음 내부 추가 보상(소량 골드 등). 가격 책정은 이미 반영.
  - **의뢰 카드 "보고서 생성" 배지 미리보기**(M8a #2 Q-5): 페이즈 1 기획에서 권장, 페이즈 2 밸런스에서는 의무 아님.
  - **턴 기반 전투 시뮬레이터**: M8b에서 구현 예정. 본 M8a 보고서는 기존 성공/실패 4 결과를 해석하여 생성. M8b에서 실제 전투 엔진 결과를 보고서의 원천으로 전환.
  - **나머지 11 세력 확장**(14세력 전체): 본 M8a는 대표 3 세력만 깊게 구현. 후속 마일스톤에서 점진적 확장.

### 2.2 데이터 요구사항

#### 2.2.A 페이즈 산출물 매트릭스

| 페이즈 | 산출물 # | 산출물 파일 경로 | 완료 일시 |
|--------|---------|------------------|----------|
| 1 | 1 | `Docs/content-design/[content]20260518_m8a_faction_contacts.md` | 2026-05-18T12:46 |
| 1 | 2 | `Docs/content-design/[content]20260518_m8a_faction_vertical_slice.md` | 2026-05-18T12:46 |
| 1 | 3 | `Docs/content-design/[content]20260518_m8a_faction_patronage_flow.md` | 2026-05-18T12:46 |
| 1 | 4 | `Docs/content-design/[content]20260518_m8a_combat_report_mvp.md` | 2026-05-18T12:46 |
| 2 | 1 | `Docs/balance-design/[balance]20260518_m8a_faction_shop_unlocks.md` | 2026-05-18T12:56 |
| 2 | 2 | `Docs/balance-design/[balance]20260518_m8a_faction_quest_rewards.md` | 2026-05-18T12:56 |
| 2 | 3 | `Docs/balance-design/[balance]20260518_m8a_combat_report_exposure.md` | 2026-05-18T12:56 |
| 3 | 1 | `[faction-contact]20260518_m8a-faction-contacts.csv` (+ .md) | 2026-05-18T13:12 |
| 3 | 2 | `[faction-quest]20260518_m8a-faction-named-quests.csv` (+ .md) | 2026-05-18T13:12 |
| 3 | 3 | `[faction-shop]20260518_m8a-faction-shop-items.csv` (+ .md) | 2026-05-18T13:12 |
| 3 | 4 | `[faction-reward]20260518_m8a-faction-rewards.csv` (+ .md) + `[item]20260518_m8a-faction-rewards.csv` | 2026-05-18T13:12 |
| 3 | 5 | `[combat-report-template]20260518_m8a-combat-report-templates.csv` + `[combat-report-keyword]20260518_m8a-combat-report-keywords.csv` (+ .md) | 2026-05-18T13:12 |
| 4 | 1 | `Docs/spec/[spec]20260518_m8a-faction-system.md` + `_plan.md` | 2026-05-18T17:45 |
| 4 | 2 | `Docs/spec/[spec]20260518_m8a-combat-report-system.md` + `_plan.md` | 2026-05-18T21:54 |
| 4 | 3 | `Docs/spec/[spec]20260519_m8a-static-data-sync-and-ops.md` | 2026-05-19T07:40 |
| 4 | 4 | `Docs/spec/[spec]20260519_m8a-integration-and-verification.md` (본 문서) | 2026-05-19 (작성 중) |

#### 2.2.B 신규/수정 Hive 박스 통합

본 명세는 신규 Hive 박스/필드를 추가하지 않는다. 다음은 페이즈 4 #1+#2 합산 요약(SSOT는 각 산출물 명세).

| 모델 | typeId | 추가된 HiveField | 마일스톤 |
|------|--------|----------------|---------|
| `FactionState` | 9 (기존) | 6/7/8/9 (총 4) | M8a #1 |
| `FactionShopDailyEntry` | **20** (신규) | 0/1 (총 2) | M8a #1 |
| `ActiveQuest` | (기존) | 27 (총 1) | M8a #2 |
| `CombatReport` | **21** (신규) | 0/1/2/3/4/5/6/7 (총 8) | M8a #2 |
| `ActivityLogType` (enum) | 6 (기존) | 35/36/37/38/39 (총 5) | M8a #1+#2 |

다음 HiveField 번호 시프트:
- `ActiveQuest`: 27 → **28**
- `ActivityLogType`: 35 → **40**
- `FactionState`: 6 → **10**
- `FactionShopDailyEntry`: — → **2**
- `CombatReport`: — → **8**

#### 2.2.C 신규/기존 Supabase 정적 테이블 통합

본 명세는 신규 Supabase 테이블을 추가하지 않는다. 다음은 페이즈 4 #1+#2 합산.

| 테이블 | 행수 | 등록 위치 | optional? | 마일스톤 |
|--------|------|----------|----------|---------|
| `faction_contacts` | 3 | `SyncService.allTables[32]` | ✓ | M8a #1 |
| `faction_reactions` | 33 | `[33]` | ✓ | M8a #1 |
| `faction_shop_items` | 18 | `[34]` | ✓ | M8a #1 |
| `combat_report_templates` | 96 | `[35]` | ✓ | M8a #2 |
| `combat_report_keywords` | 40 | `[36]` | ✓ | M8a #2 |
| `quest_pools` | +12 | (기존) | — | M8a #1 |
| `items` | +4 | (기존) | — | M8a #1 |
| `crafting_recipes` | +2 | (기존) | — | M8a #1 |
| `titles` | +2 | (기존) | — | M8a #1 |

### 2.3 UI 요구사항

해당 사항 없음. 본 명세는 코드 변경 없는 통합 회고·검증·인계 문서이다.

UI 변경은 페이즈 4 #1(`FactionDetailScreen` 3 신규 섹션 + `FactionCodexScreen` 분홍 dot + `FactionContactArrivedDialog`)과 페이즈 4 #2(`QuestResultDialog` `ConsumerStatefulWidget` 전환 + 요약 카드 + 상세 뷰 인라인 전환)에서 모두 적용 완료.

## 3. 영향 범위

### 3.1 수정 대상 파일

본 명세는 코드 변경을 동반하지 않는다.

CLAUDE.md 갱신은 `finalize-feature` 단계에서 처리하므로 본 PR 범위 외이다(2.1.E 절 참조).

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `Docs/spec/[spec]20260519_m8a-integration-and-verification.md` | 본 명세 |

### 3.3 코드 생성 필요 파일

해당 사항 없음.

### 3.4 관련 시스템

- **M8a 페이즈 4 #1 산출물 시스템**: 세력 접촉점 · 후원 상태 · 상점 · 지명 의뢰 hook 3종 · 세력 평판 보상 · 칭호 hook · 제작 unlock 2 case (변경 없음, 검증만 수행)
- **M8a 페이즈 4 #2 산출물 시스템**: 전투 보고서 모델·서비스·UI · TemplateEngine ally/enemy namespace (변경 없음, 검증만 수행)
- **M8a 페이즈 4 #3 산출물 정책**: `SyncService.optionalTables` 운영 정책 · `data_versions` 발행 규약 · 후속 마일스톤 워크플로 8단계 (변경 없음, 검증만 수행)
- **finalize-feature 스킬**: 본 명세 PASS 이후 사용자 호출 대상.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **마일스톤 회고 명세 패턴**: M7 페이즈 4 #4 통합 명세를 직접적인 선례로 참조 가능(찾아 비교). 일반 회고 + 체크리스트 + finalize-feature 인계 + 후속 백로그 4 축 구조를 그대로 유지.
- **CLAUDE.md 갱신 위임 패턴**: M5/M6/M7 마일스톤 종료 시 `finalize-feature` 스킬이 CLAUDE.md를 일괄 갱신한 선례를 따른다(본 명세는 갱신 항목 목록만 명시).
- **Archive 이동 보존 정책**: `memory/feedback_finalize_feature_archive.md` — Archive 단계에서 spec/plan 원본 git rm 금지, 복사만 수행.

### 4.2 주의사항

- **본 명세는 검증 PASS 시점에 모든 코드·데이터가 적용 완료 상태여야 한다**. PASS 이후 코드 추가 변경이 있으면 다른 명세로 분리하여 새 PR로 처리한다.
- **CLAUDE.md 갱신은 본 PR에 포함하지 않는다**. `finalize-feature` 단계에서 단일 commit으로 일괄 처리하여 마일스톤 단위 변경 추적 가능성을 유지.
- **`faction_*` Supabase 시드 미적용 환경 위험**: 페이즈 4 #1 구현 후 Supabase 마이그레이션이 실제로 적용되었는지 본 명세 작성 시점 미검증 ([Q-1] 답변 참조). finalize-feature 이전에 검증 SQL 실행 필수.
- **operation-bom 미동기화**: M2a~M8a 다수 테이블이 미등록 상태로 운영 웹앱에서 편집 불가. 본 마일스톤 종료와 독립한 별도 백로그로 분리하되, 운영 부담 가시화 필요.
- **회귀 기준선 추적**: 테스트 수치 547 → 568 → 576 → 578의 +개수 산출이 verifier 추적 가능해야 함. M7 종료 시점 547은 추정값이므로 finalize 단계에서 git log 기반 확정 필요.

### 4.3 엣지 케이스

- **본 명세 PASS 이후 페이즈 4 #1·#2 코드 회귀**: 명세 PASS 시점은 일시적 스냅샷. PR 머지 직전 `flutter test` + `flutter analyze` 재실행 필수.
- **CLAUDE.md 갱신 누락**: `finalize-feature` 단계에서 7개 영역 중 일부 누락 시 후속 마일스톤에서 파악 어려움. 본 명세의 FR-E1~E7 체크리스트 항목 단위로 finalize 검증 필요.
- **Supabase 마이그레이션 미적용**: optionalTables fail-soft로 기동은 가능하나 게임 기능이 빈 데이터로 동작. 사용자 인지 없이 마일스톤 완료 선언 위험. FR-G1 검증 SQL을 finalize 직전 실행 필수.

### 4.4 구현 힌트

본 명세는 코드 구현이 없다. 다음은 verifier가 PASS 판정을 위해 수행해야 할 검증 절차다.

- **검증 SQL** (Supabase MCP `execute_sql`):
  ```sql
  -- data_versions 5 row 확인
  SELECT table_name, version, updated_at
  FROM data_versions
  WHERE table_name IN (
    'faction_contacts', 'faction_reactions', 'faction_shop_items',
    'combat_report_templates', 'combat_report_keywords'
  )
  ORDER BY table_name;

  -- 행 카운트 확인 (기대: 3·33·18·96·40)
  SELECT 'faction_contacts' AS t, COUNT(*) FROM faction_contacts
  UNION ALL SELECT 'faction_reactions', COUNT(*) FROM faction_reactions
  UNION ALL SELECT 'faction_shop_items', COUNT(*) FROM faction_shop_items
  UNION ALL SELECT 'combat_report_templates', COUNT(*) FROM combat_report_templates
  UNION ALL SELECT 'combat_report_keywords', COUNT(*) FROM combat_report_keywords;
  ```

- **로컬 빌드 게이트**:
  ```bash
  cd band_of_mercenaries
  flutter analyze        # 기대: No issues found!
  flutter test           # 기대: 578 tests PASS
  ```

- **SyncService 등록 검증**:
  ```bash
  grep -n "M8a 페이즈 4" band_of_mercenaries/lib/core/data/sync_service.dart
  # 기대: 5 매칭 (33·34·35·36·37 인덱스)

  grep -A 6 "optionalTables = {" band_of_mercenaries/lib/core/data/sync_service.dart
  # 기대: 5 row (M8a 신규 5 테이블)
  ```

- **typeId 점유 검증**:
  ```bash
  grep -rn "typeId:" band_of_mercenaries/lib --include="*.dart" \
    | grep -v ".g.dart" | grep -v ".freezed.dart" \
    | sort -t: -k3 -n
  # 기대: 0·1·2·3·4·5·6·7·8·9·10·11·13·14·15·16·17·18·19·20·21 (12 미사용 보존)
  ```

- **HiveField 27 / 39 검증**:
  ```bash
  grep -n "HiveField(27)" band_of_mercenaries/lib/features/quest/domain/quest_model.dart
  # 기대: combatReport 필드

  grep -n "HiveField(39)" band_of_mercenaries/lib/core/domain/activity_log_model.dart
  # 기대: combatReportGenerated enum

  grep -n "HiveField([6-9])" band_of_mercenaries/lib/features/info/domain/faction_state_model.dart
  # 기대: shopPurchaseHistory/shopDailyPurchases/grantedRewardIds/contactUnlockedIds
  ```

- **Navigator.push 0건 검증** (CLAUDE.md UI 제약):
  ```bash
  grep -rn "Navigator.push" band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart
  grep -rn "Navigator.push" band_of_mercenaries/lib/features/info/view/faction_*.dart
  # 기대: 두 경로 모두 결과 0건
  ```

- **avoid_print 검증**:
  ```bash
  grep -rn "print(" band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart
  grep -rn "print(" band_of_mercenaries/lib/features/info/domain/faction_*.dart
  # 기대: 'debugPrint' 외 'print(' 0건
  ```

## 5. 기획 확인 사항

- [Q-1] **본 명세의 PASS 조건은 무엇인가?**
  - **본 명세 결정**: verify-spec 5개 항목(intent / completeness / consistency / clarity / actionability)을 모두 PASS로 통과하면 즉시 finalize-feature 진입 가능. **추가 코드 검증(flutter analyze/test/grep)은 finalize-feature 단계의 사전 체크리스트로 위임**한다. 본 명세는 회고+계획 문서이므로 PASS 시점 빌드 게이트와 명세 작성 시점이 일치하면 충분.

- [Q-2] **CLAUDE.md 갱신을 본 PR에 포함할지 분리할지**
  - **본 명세 결정**: **분리**. `finalize-feature` 단계에서 CHANGELOG fragment 합산 + Archive 이동 + commit과 함께 단일 commit으로 처리하여 마일스톤 단위 변경 추적 가능성을 유지. 본 명세는 갱신 항목 목록(FR-E1~E7)만 명시한다.

- [Q-3] **`faction_*` 3 테이블 Supabase 시드 미검증 상태로 마일스톤 완료 선언 가능한가?**
  - **본 명세 결정**: **미검증 상태로는 불가**. FR-G1 검증 SQL을 `finalize-feature` 단계의 사전 체크리스트로 추가하여 finalize 진입 전 반드시 실행. 미적용 환경 발견 시 별도 마이그레이션 PR로 분리 후 본 마일스톤 완료 선언.

- [Q-4] **operation-bom 일괄 등록을 M8b 진입 전 처리할지**
  - **본 명세 결정**: **M8b와 독립**. operation-bom 미동기화는 운영 부담이지만 게임 기능과 무관. 별도 백로그(FR-G2)로 추적하고 M8b 진입에 블로커로 작용하지 않는다.

- [Q-5] **테스트 수치 547 → 578 추적의 정확도 보장 방법**
  - **본 명세 결정**: 본 명세는 페이즈 4 #1 종료 568 / #2 종료 576 / 현재 578만 확정. M7 종료 시점 547 추정은 finalize 단계에서 `git log --grep="M7"` + 해당 시점 `flutter test` 출력으로 재확인. 비핵심 수치(M7 종료)는 명세 PASS 차단 사유 아님.

- [Q-6] **M8a 마일스톤 완료 선언 시점 정의**
  - **본 명세 결정**: 다음 4 조건 모두 만족 시 완료 선언:
    1. 본 명세 verify-spec PASS
    2. FR-G1 Supabase 시드 검증 SQL 5 row + 행 카운트 정합
    3. `finalize-feature` 스킬 실행 완료(CHANGELOG fragment + Archive 이동 + CLAUDE.md 갱신 + commit)
    4. `Docs/milestone-runs/M8a/state.md` 완료 기준 9/9 [x] 갱신 + 상태 `archived` 전환

- [Q-7] **본 통합 명세 자체의 Archive 처리**
  - **본 명세 결정**: 본 명세 + 페이즈 4 #1·#2·#3 명세 + #1·#2 `_plan.md`까지 모두 `Docs/Archive/M8a/`(또는 `Docs/Archive/`)로 일괄 이동. 원본은 복사 형태로 보존(`memory/feedback_finalize_feature_archive.md` 정책 준수). 이동 후 `Docs/spec/` 디렉토리는 진행 중 산출물만 남도록 정리.

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260519_m8a-integration-and-verification.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|------|------|------|
| 수정/생성 파일 | 신규 1개 (본 명세서만) — 코드 변경 0 | 소규모 |
| 영향 시스템 | 회고 대상 시스템 다수(세력·전투 보고서·정적 데이터·CLAUDE.md), 직접 영향 0 | 소규모 |
| 신규 클래스 | 0개 | 소규모 |
| 데이터 모델 | 변경 없음(검증만) | 소규모 |
| UI 작업 | 변경 없음 | 소규모 |
| 기존 시스템 변경 | 변경 없음(정책 문서) | 소규모 |

**추천: finalize-feature (코드 변경 없음, 0/6점)**

본 명세는 implement-spec 또는 implement-agent 실행 대상이 아니다. PASS 판정 후 `finalize-feature` 스킬로 진행한다.

구현 명령어 안내:

```
# 구현 실행 대상 아님 (코드 변경 0)
/finalize-feature  ← 추천 (CHANGELOG + Archive + CLAUDE.md 갱신 + commit)
```
