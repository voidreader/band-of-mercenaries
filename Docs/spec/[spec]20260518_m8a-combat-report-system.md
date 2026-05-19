# M8a 전투 보고서 저장 모델·서비스·UI 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260518_m8a_combat_report_mvp.md`
> - `Docs/balance-design/[balance]20260518_m8a_combat_report_exposure.md`
> - `Docs/content-data/[combat-report-template]20260518_m8a-combat-report-templates.csv`
> - `Docs/content-data/[combat-report-keyword]20260518_m8a-combat-report-keywords.csv`
>
> 작성일: 2026-05-18
> 마일스톤: M8a 페이즈 4 #2

## 1. 개요

전투 보고서는 중요한 의뢰(세력/지명/엘리트/연계/세력 전용 고급) 완료 시 한 번 생성되어 영속 저장되는 요약(2~4문장) + 상세 로그(4~8줄) 기록이다. 본 명세는 (a) 영속 모델, (b) 96개 템플릿·40개 키워드 정적 데이터 로드, (c) 가중 선택 + TemplateEngine 렌더 서비스, (d) 결과 다이얼로그의 요약 카드 및 상세 보고서 진입 UI를 정의한다. 일반 의뢰의 기존 `renderedNarrative` 1문장 서사는 유지되며, 보고서는 그 위에 덧붙는 확장 계층이다.

생성 트리거는 `QuestCompletionResult.combatReportEligible == true`이다(이미 페이즈 4 #1에서 `quest.specialFlags['combat_report'] == true` 조건으로 셋업됨). 본 명세는 이 플래그가 true인 의뢰 완료 직후 보고서를 1회 생성·저장하고, 결과 다이얼로그가 닫히기 전 앱 재시작 또는 다이얼로그 재표시가 발생해도 동일 보고서가 동일 다이얼로그·상세 화면에 표시되도록 보장한다. 결과 다이얼로그를 닫은 뒤 장기 재열람하는 경로는 M8a 범위 밖이다.

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] 전투 보고서 영속 모델 정의**
  - 신규 Hive 모델 `CombatReport` 클래스(`typeId: 21`)를 도입한다.
  - 필드: `summary`(String), `details`(List<String>), `seed`(int), `protagonistMercId`(String?), `featuredMercIds`(List<String>), `toneTags`(List<String>), `createdAt`(DateTime), `templateIds`(List<String>).
  - `ActiveQuest`에 `combatReport: CombatReport?`(`@HiveField(27)`) 필드를 추가한다.
  - 저장 위치는 `quests` Hive 박스의 `ActiveQuest` 내부 임베드 객체로 한정한다. 별도 `combatReports` 박스는 본 명세에서 만들지 않는다(M8b 확장 후보로 보류).

- **[FR-2] 정적 데이터 로드(템플릿·키워드)**
  - 신규 정적 데이터 모델 2종을 등록한다.
    - `CombatReportTemplate` ← Supabase 테이블 `combat_report_templates`(96행, 페이즈 3 산출 CSV)
    - `CombatReportKeyword` ← Supabase 테이블 `combat_report_keywords`(40행, 페이즈 3 산출 CSV)
  - `SyncService.allTables`·`SyncService.optionalTables`·`StaticGameData`·`staticDataProvider`·`DataLoader`에 모두 등록한다.
  - `combat_report_templates`·`combat_report_keywords`는 M8a 신규 테이블이므로 optional table로 등록한다. 테이블이나 캐시가 없으면 빈 리스트로 로드하고, 보고서 생성은 `null` 반환으로 fail-soft 처리한다.
  - 모델 필드:
    - `CombatReportTemplate`: `id`/`group`/`scope`/`factionId?`/`questType?`/`resultType?`/`lineType`/`importance`/`weight`/`template`/`tagsJson?`
    - `CombatReportKeyword`: `id`/`category`/`key`/`displayText`/`tagsJson?`/`weight`
  - `tagsJson`은 Supabase JSONB 응답과 CSV TEXT 캐시를 모두 허용한다. 모델 필드는 `@JsonKey(name: 'tags_json') Object? tagsJson` 또는 `Map<String, dynamic>? tagsJson`로 받고, helper(`parsedTags`)에서 `Map<String, dynamic>`이면 그대로 사용하고 `String`이면 `jsonDecode` 후 `Map<String, dynamic>`로 변환한다. 파싱 실패 시 빈 Map을 반환한다.

- **[FR-3] 보고서 생성 트리거**
  - `QuestProvider._applyCompletionResult` 내부 기존 `result.renderedNarrative` 처리 직후, `result.combatReportEligible == true`이면 `CombatReportService.generate()`를 호출한다.
  - 생성된 `CombatReport`를 `quest.combatReport = report; await quest.save();`로 영속화한다.
  - 동일 quest에 보고서가 이미 존재하면(`quest.combatReport != null`) 재생성을 건너뛴다(재호출 멱등).
  - `ActivityLogType.combatReportGenerated`(`@HiveField(39)`) 1줄 로그를 추가한다. 메시지 형식: `"전투 보고서: {questName}"`. 로그는 `generate()`가 non-null 보고서를 반환한 성공 케이스에만 발급한다.
  - 생성 실패(템플릿 0개·`StateError` 등) 시 `try/catch`로 swallow하고 본체 흐름은 계속한다(fail-soft trailing). `debugPrint`로 원인 로깅한다.

- **[FR-4] CombatReportService.generate 시그니처**
  - 정적 helper. 시그니처:
    ```dart
    static CombatReport? generate({
      required ActiveQuest quest,
      required List<Mercenary> partyMercs,
      required QuestResult resultType,
      required StaticGameData staticData,
      required UserData userData,
      required List<FactionState> factionStates,
      required TemplateEngine templateEngine,
      RegionState? regionState,
      Map<String, String>? sectorChanges,
      int? seed,
    });
    ```
  - 내부 단계:
    1. `seed`는 호출자가 전달하지 않으면 `DateTime.now().millisecondsSinceEpoch ^ quest.id.hashCode`. `Random(seed)` 1개로 전 과정 사용(재현성).
    2. `_resultTypeKey(resultType)`로 템플릿 매칭용 결과 키를 변환한다. CSV는 snake_case를 사용하고 Dart enum은 camelCase를 사용하므로 `resultType.name`을 직접 비교하지 않는다.

       | `QuestResult` | 템플릿 `result_type` |
       |---------------|----------------------|
       | `greatSuccess` | `great_success` |
       | `success` | `success` |
       | `failure` | `failure` |
       | `criticalFailure` | `critical_failure` |

    3. `_resolveImportance(quest, staticData, userData)` → `normal` | `high` | `very_high` (FR-7 매트릭스).
    4. `_resolveScopeChain(quest, staticData)` → 좁은 → 넓은 순으로 정렬된 scope 시퀀스(아래 표). 시퀀스의 가장 좁은 scope에서 시작해 요약/상세 풀 매칭을 시도한다.

       | scope | 트리거 조건(AND) | summary fallback | detail 보충풀 |
       |-------|------------------|------------------|---------------|
       | `chain_final` | `quest.isChainQuest && staticData.chainQuests[quest.chainId].steps.length == (quest.chainStep ?? -1) + 1` | `chain_step` → `quest_type` | `scene` |
       | `chain_step` | `quest.isChainQuest && !chain_final 조건` | `quest_type` | `scene` |
       | `settlement_event` | `quest.isSettlementStep == true`(`chainId`가 `settlement_` prefix) | `chain_step` → `quest_type` | `scene` |
       | `unique_elite` | `quest.isElite && staticData.eliteMonsters[quest.eliteId].isUnique == true` | `elite` → `quest_type` | `scene` |
       | `elite` | `quest.isElite && !unique_elite` | `quest_type` | `scene` |
       | `faction_named` | `quest.factionTag == template.factionId && (quest.specialFlags ?? {})['faction_named'] == true` | `quest_type` | `scene` |
       | `quest_type` | (기본) `template.questType == quest.questTypeId && template.resultType == resultKey` | (없음 — 최종 fallback) | `scene` |
       | `scene` | (decisive 보충용, 직접 선택 안 함) | — | (자체) |

       모든 매칭은 추가로 `template.resultType == resultKey`(scope=`scene`도 result 일치) AND `template.questType` 조건이 정의된 경우 일치해야 한다.
    5. 요약 1줄 선택: 단계 4의 시퀀스를 좁은 scope부터 순회하며 `lineType == 'summary'` + scope 매칭 + result 일치 후보를 가중 랜덤 추첨. 발견 즉시 종료. 시퀀스 끝까지 미발견 시 `null` 반환(보고서 미생성).
    6. 상세 N줄 선택: importance별 줄 수(FR-7) 만큼 `lineType == 'detail'` 풀에서 비복원 가중 샘플. 단계 4 시퀀스의 가장 좁은 scope를 먼저 시도하고, 부족하면 다음 scope, 최종적으로 `scope == 'scene'` 보충풀에서 채운다. 최소 1줄 이상 확보되지 않으면 보고서를 생성하지 않고 `null` 반환. importance별 목표 줄 수에 미달해도 1줄 이상 확보된 경우 생성한다(fail-soft).
    7. 주인공: `QuestNarrativeService.pickProtagonist(partyMercs, quest.questTypeId)` 재사용. 주인공이 null이면 `{merc.name}` 치환 품질을 보장할 수 없으므로 `null`을 반환하고 보고서를 생성하지 않는다.
    8. 보조(`{ally.name}` 후보): partyMercs 중 protagonist를 제외한 무작위 1명(없으면 protagonist 동일 사용).
    9. `featuredMercIds`: protagonist + ally(중복 제거).
    10. `{enemy.name}` 결정(FR-5 enemy namespace 입력): 우선순위 — (a) `quest.eliteId != null`이면 `staticData.eliteMonsters[eliteId].name` (b) 그 외엔 `staticData.questPools[quest.questPoolId].enemyName`(존재 시) (c) 그것도 null이면 `combat_report_keywords` 중 `category == 'enemy'`이고 `tagsJson`의 `region`이 `quest.region`이거나 `quest_type`이 `quest.questTypeId`인 키워드 중 가중 랜덤(`displayText` 사용) (d) 모두 실패 시 `null` → resolver에서 `'적'` fallback(기존 quest.enemy 동작과 동일).
    11. 각 템플릿 문자열을 `TemplateEngine.render()`로 렌더링한다. 컨텍스트는 `TemplateContext(user: userData, quest: quest, merc: protagonist, region: resolvedRegion, factionStates: factionStates, sectorChanges: convertedSectorChanges, currentSectorIndex: userData.sector, allyName: ally.name, enemyName: enemyName, eliteId: quest.eliteId, seed: seed, evaluationScope: EvaluationScope.mercenary)`를 사용한다.
    12. `toneTags`: 선택된 모든 템플릿의 `tagsJson` 값(`tone`/`beat`/`scene`/`mood`/`faction`)을 평탄화하여 dedup.
    13. `templateIds`: 선택된 템플릿 id 리스트(요약 1 + 상세 N).
    14. `CombatReport`(필드 채워서) 반환.

- **[FR-5] TemplateEngine `ally`·`enemy` namespace 추가**
  - CSV 템플릿에는 `{ally.name}`과 `{enemy.name}`이 등장한다. `template_engine/resolver.dart`에 신규 namespace 분기를 추가한다.
  - `TemplateVariableCatalog`에 namespace와 변수 스펙을 함께 등록한다. 현재 renderer가 resolver 호출 전에 `TemplateVariableCatalog.isKnown(namespace, field)`를 검사하므로 카탈로그 미등록 시 resolver 분기를 추가해도 `[?:unknown:ally.name]` 또는 `[?:unknown:enemy.name]`이 출력된다.
    - `TemplateVariableCatalog.namespaces`에 `ally`, `enemy`를 추가한다.
    - `entries`에 `TemplateVariableSpec(namespace: 'ally', field: 'name', type: TemplateVariableType.string)`와 `TemplateVariableSpec(namespace: 'enemy', field: 'name', type: TemplateVariableType.string)`를 추가한다.
  - **`ally` namespace**:
    - `TemplateContext`(freezed)에 `String? allyName` 필드 추가.
    - resolver에 `case 'ally':` 분기 추가 → `_resolveAllyField(field, ctx.allyName)`. `field == 'name'`이면 `allyName` 반환, null이면 빈 문자열 대신 protagonist `merc.name` fallback. 기타 field는 null 반환.
  - **`enemy` namespace**(신규 namespace):
    - `TemplateContext`에 이미 존재하는 `enemyName: String?`를 namespace `enemy`로도 노출한다. 기존 `{quest.enemy}` 분기(resolver.dart:75)는 보존(중복 허용).
    - resolver에 `case 'enemy':` 분기 추가 → `field == 'name'`이면 `ctx.enemyName ?? '적'` 반환(기존 `quest.enemy` 동작과 동일 fallback). 기타 field는 null 반환.
    - `CombatReportService.generate` 단계 9가 `enemyName` 값을 결정하여 `TemplateContext` 생성 시 주입한다.
  - 기존 호출부(QuestNarrativeService 등)는 default `null`이므로 영향 없음.

- **[FR-6] 결과 다이얼로그 요약 카드**
  - `QuestResultDialog`에 다음 섹션을 기존 서사 카드(L66-85) 직후, 용병 상태(L88) 직전에 삽입한다.
    - 조건: `quest.combatReport != null`
    - 위젯: `_CombatReportSummaryCard(report: quest.combatReport!)`
    - 표시 항목: 카드 헤더 `📜 전투 보고서`, 본문 = `report.summary`, 우측 하단 `[상세 보고서 보기]` `TextButton`
  - 탭 시 `_showCombatReportDetail`(`StateProvider<bool> _isShowingCombatReportDetail` 또는 단일 다이얼로그 내 상태)로 전환한다. 본 다이얼로그는 닫히지 않고 동일 다이얼로그 안에서 `Column` 본체가 상세 보고서 본문으로 교체된다.
  - 일반 의뢰(보고서 없는 의뢰)에는 카드를 표시하지 않는다(`null` early return).

- **[FR-7] 길이·중요도 매트릭스**

  요약 문장 수는 고정값, 상세 줄 수는 페이즈 2 확정안의 범위형(5~7/6~8)을 유지한다. 범위형 줄 수는 `_resolveDetailLineCount(importance, random)`로 [min, max] 범위 내 균등 분포 추첨하며, 추첨 결과가 실제 매칭 풀 크기를 초과하면 풀 크기로 클램프한다(FR-4 단계 5의 fail-soft 분기와 정합).

  | 분류 | importance | 요약 문장 수(고정) | 상세 줄 수(범위) |
  |------|-----------|--------------------|------------------|
  | 일반 세력 지명(faction_named) | `normal` | 2 | 4 |
  | 기존 지명(named)/엘리트(elite) | `high` | 3 | 5~7 |
  | 연계 핵심 단계(chain_step·settlement_event) | `high` | 3 | 5~7 |
  | 신뢰 세력 지명(평판 31+ 또는 고급 트랙) | `high` | 3 | 5~6 |
  | 연계 최종(chain_final) | `very_high` | 4 | 6~8 |
  | 유니크 엘리트(unique_elite) | `very_high` | 4 | 6~8 |

  요약 문장 수는 단일 summary 템플릿이 여러 문장으로 구성된다는 페이즈 1 기획의 전제(요약 1줄 = 1~다문장 단위 템플릿)를 따른다. 본 명세에서는 요약을 1개 템플릿으로 한 줄 추첨하고, 그 템플릿이 자체적으로 importance에 맞는 문장 수를 포함하도록 한다(데이터 책임). 추후 페이즈 3 시드 데이터에서 importance 컬럼에 맞춰 문장 수가 다르게 작성되어 있다(현 CSV는 1문장 기준이므로 단순화 — Q-7 참조).

  **`_resolveImportance(quest, staticData, userData)` 분기 의사코드**:
  ```dart
  // 1. 유니크 엘리트
  if (quest.eliteId != null) {
    final elite = staticData.eliteMonsters
        .where((e) => e.id == quest.eliteId).firstOrNull;
    if (elite?.isUnique == true) return ImportanceLevel.veryHigh;
    return ImportanceLevel.high; // 일반 엘리트
  }
  // 2. 연계 퀘스트
  if (quest.isChainQuest && quest.chainId != null) {
    final chain = staticData.chainQuests
        .where((c) => c.id == quest.chainId).firstOrNull;
    final isFinal = chain != null
        && chain.steps.length == (quest.chainStep ?? -1) + 1;
    if (isFinal) return ImportanceLevel.veryHigh;
    return ImportanceLevel.high; // chain_step·settlement_event
  }
  // 3. 신뢰 세력 지명(평판 31+ 또는 고급 트랙)
  final isFactionNamed =
      (quest.specialFlags ?? const {})['faction_named'] == true;
  if (isFactionNamed) {
    final isAdvancedTrack = quest.isAdvancedTrack == true;
    final reputationOk = userData.reputation >= 31;
    if (isAdvancedTrack || reputationOk) return ImportanceLevel.high;
    return ImportanceLevel.normal; // 일반 세력 지명
  }
  // 4. 기존 지명 의뢰(M6) — quest_pool.isNamed == true
  //    QuestPool lookup: staticData.questPools[quest.questPoolId]
  final pool = staticData.questPools
      .where((p) => p.id == quest.questPoolId).firstOrNull;
  if (pool?.isNamed == true) return ImportanceLevel.high;
  // 5. fallback
  return ImportanceLevel.normal;
  ```

  매핑 모호 시 `normal`로 안전하게 fallback. 신규 enum `ImportanceLevel { normal, high, veryHigh }`는 `combat_report_service.dart` 내부에 정의(외부 노출 불필요).

- **[FR-8] 상세 보고서 화면(인라인 전환)**
  - 신규 위젯 `_CombatReportDetailView`를 `quest_result_dialog.dart` 하단 사설 클래스로 추가한다.
  - 진입은 FR-6의 [상세 보고서 보기] 버튼. Navigator.push 사용하지 않고, `QuestResultDialog` 내부 상태(`_showDetail: bool` — `StatefulWidget` 전환 또는 `useState` 패턴)로 본문만 교체한다.
    - 본 다이얼로그를 `ConsumerStatefulWidget`으로 변환한다.
  - 본문 구성:
    - 헤더: `← 결과로 돌아가기` 버튼 + `${quest.questName} — 전투 보고서`
    - 본문: `report.details`를 `ListView` 또는 `Column`으로 줄 단위 표시. 결과 색상(`AppTheme.greatSuccess/success/failure/criticalFailure`)으로 좌측 4px 보더 강조.
    - 푸터: `protagonistMercId` 칩(`주인공: {merc.name}`) + `featuredMercIds` 추가 칩. 이름은 현재 `mercenaryListProvider`에서 lookup한다. lookup 실패 시 해당 칩은 숨긴다.
  - 닫기 동작: 헤더 뒤로가기 버튼은 `setState(_showDetail = false)`. 다이얼로그 자체 닫기는 기존 확인/수령 버튼 동일.

- **[FR-9] 영속성·재진입 동일성**
  - `quest.combatReport`는 ActiveQuest에 내장되어 Hive 박스에 자동 영속화된다.
  - 결과 다이얼로그가 닫히기 전 앱 재시작 또는 같은 completed quest에 대한 결과 다이얼로그 재표시가 발생하면 동일 `summary`/`details`가 표시되어야 한다(재렌더링 금지).
  - 현재 `DispatchScreen._showResult`는 결과 다이얼로그가 닫힌 뒤 `clearCompleted(quest.id)`로 완료 의뢰를 삭제한다. 따라서 다이얼로그 닫힘 이후 연대기·기록 화면에서 보고서를 다시 여는 기능은 M8a 범위 밖이다. 장기 재열람은 M8.5/M9에서 별도 `combatReports` 박스 또는 완료 기록 모델을 도입할 때 다룬다.
  - 1회 생성 후 동일 의뢰에 대해 `generate()`를 재호출하지 않는다(FR-3 멱등 분기로 보장).

- **[FR-10] 노출 빈도 게이트(외부 의존)**
  - 본 명세는 `combatReportEligible` 플래그가 외부(quest_pool.specialFlags['combat_report'] 셋업)에 의해 결정된다고 가정한다. 페이즈 2 권장 15~25% 비율 유지는 quest_pool 데이터 시드(`combat_report=true` 마킹 범위)에서 관리하며, 본 명세 코드 변경 범위에는 게이트 로직 자체를 두지 않는다.
  - 이 가정이 깨질 경우(예: 모든 의뢰에 true가 부여) 추가 게이트가 필요하므로 [Q-1]에 명시한다.

### 2.2 데이터 요구사항

- **신규 Hive 모델**: `CombatReport` (`typeId: 21`)
  - HiveField 점유: 0=summary, 1=details, 2=seed, 3=protagonistMercId, 4=featuredMercIds, 5=toneTags, 6=createdAt, 7=templateIds
  - 위치: `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart`

- **수정 Hive 모델**: `ActiveQuest`
  - 신규 필드: `@HiveField(27) CombatReport? combatReport;`
  - 생성자 옵션 인자 추가. nullable.

- **신규 enum HiveField**: `ActivityLogType.combatReportGenerated` (`@HiveField(39)`)

- **신규 정적 데이터 모델 2종**:
  - `CombatReportTemplate` (`band_of_mercenaries/lib/core/models/combat_report_template.dart`)
  - `CombatReportKeyword` (`band_of_mercenaries/lib/core/models/combat_report_keyword.dart`)
  - 둘 다 freezed + json_serializable, `@JsonKey(name: 'snake_case')` 어노테이션은 Dart 필드명과 다를 때만 사용(QuestNarrativeData 패턴).
  - `tagsJson`은 `@JsonKey(name: 'tags_json') Object? tagsJson` 또는 `Map<String, dynamic>? tagsJson` + 문자열 fallback helper로 구현한다(Q-3 결정사항 준수).

- **신규 Supabase 테이블**: `combat_report_templates`(96행), `combat_report_keywords`(40행)
  - 페이즈 3 #5 CSV 파일을 SQL INSERT로 시드. 본 명세 범위 외 작업(데이터 파이프라인 담당).
  - `data_versions` 테이블에 두 테이블의 version 행을 추가한다. 단, 앱 코드에서는 두 테이블을 optional table로 취급하여 스키마 적용 전 환경에서도 기동을 막지 않는다.

- **TemplateContext 확장**: `allyName: String?` 신규 필드(`enemyName`은 기존 필드 재사용).
- **TemplateVariableCatalog 확장**: `ally.name`·`enemy.name` 신규 변수 등록.

- **밸런스 수치**(페이즈 2 #3 확정안 그대로):
  - 요약 문장 수: importance별 2/3/4
  - 상세 줄 수: importance별 4/5/6 (높은 중요 케이스에서 최대 7)
  - 노출 빈도 목표: 15~25%(외부 데이터 시드 책임)

### 2.3 UI 요구사항

- **화면 진입 조건**: `QuestResultDialog`가 표시되고 `quest.combatReport != null`인 경우 요약 카드 노출. [상세 보고서 보기] 버튼 탭 시 동일 다이얼로그 본체가 상세 뷰로 교체.
- **위젯 계층**:
  - `QuestResultDialog (ConsumerStatefulWidget)`
    - `_showDetail == false`(요약 모드): `Column` > 헤더 / 결과 배지 / `renderedNarrative` 카드(기존) / **`_CombatReportSummaryCard`(신규)** / 용병 상태 / 보상 / 엘리트 드랍 / 확인 버튼
    - `_showDetail == true`(상세 모드): `Column` > 뒤로가기 헤더 / 상세 줄 리스트 / featured 칩 / 닫기 버튼
- **상태 변수**:
  - `_showDetail: bool` (로컬 `StatefulWidget` 상태)
- **화면 전환**: Navigator.push 금지. 동일 `Dialog` 내부 상태 기반 렌더링(CLAUDE.md 제약 준수).
- **연출/애니메이션**: 전환은 `AnimatedSwitcher`(150ms fade) 권장. 없어도 무관.
- **색상**:
  - 요약 카드 배경: `AppTheme.surfaceAlt`, 보더 `AppTheme.borderLight`. 헤더 아이콘 색은 결과별(`greatSuccess`/`success`/`failure`/`criticalFailure`).
  - 상세 줄 좌측 4px 보더: 위와 동일한 결과 색.
- **반응형**: 상세 모드에서 본문 줄 수가 많을 경우 `SingleChildScrollView`로 감싼다.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/quest_model.dart` | `@HiveField(27) CombatReport? combatReport` 추가 + 생성자 옵션 인자 + import | FR-1: ActiveQuest에 보고서 임베드 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `_applyCompletionResult` 내 `result.renderedNarrative` 처리 직후 `CombatReportService.generate()` 호출 + `quest.combatReport` 저장 + ActivityLog 추가 + fail-soft try/catch | FR-3: 트리거 |
| `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart` | `ConsumerStatefulWidget` 전환 + `_showDetail` 상태 + 요약 카드 위젯 + 상세 뷰 위젯 + 뒤로가기 헤더 | FR-6, FR-8 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `combatReportGenerated` enum 값 추가 (`@HiveField(39)`) | FR-3 |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | `Hive.registerAdapter(CombatReportAdapter());` 추가 | FR-1: 새 어댑터 등록 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables`·`optionalTables` 리스트에 `'combat_report_templates'`, `'combat_report_keywords'` 추가 | FR-2 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | (a) import 2종, (b) StaticGameData 필드 2종, (c) 생성자 매개변수, (d) optional cache 로드 2회 추가 | FR-2 |
| `band_of_mercenaries/lib/core/domain/template_context.dart` | `String? allyName` 필드 추가(`enemyName`은 기존 필드 재사용) | FR-5 |
| `band_of_mercenaries/lib/core/domain/template_engine/resolver.dart` | `case 'ally':` 분기(`_resolveAllyField(field, ctx.allyName)`) + `case 'enemy':` 신규 namespace 분기(`field == 'name'`이면 `ctx.enemyName ?? '적'`). 기존 `quest.enemy` 분기는 그대로 보존 | FR-5 |
| `band_of_mercenaries/lib/core/domain/template_variable_catalog.dart` | `ally.name`·`enemy.name` namespace/field 등록 | FR-5: unknown 변수 출력 방지 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart` | `CombatReport` Hive 모델(`typeId: 21`) |
| `band_of_mercenaries/lib/features/quest/domain/combat_report_service.dart` | 보고서 생성 정적 helper |
| `band_of_mercenaries/lib/core/models/combat_report_template.dart` | 정적 데이터 모델 (freezed/json) |
| `band_of_mercenaries/lib/core/models/combat_report_keyword.dart` | 정적 데이터 모델 (freezed/json) |
| `band_of_mercenaries/test/features/quest/domain/combat_report_service_test.dart` | 단위 테스트(seed 고정 재현성, result_type snake_case 매핑, importance 매핑, scope fallback, optional 데이터 빈 리스트 fallback, 멱등성) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/features/quest/domain/combat_report_model.g.dart` | Hive `CombatReportAdapter` 자동 생성 |
| `band_of_mercenaries/lib/features/quest/domain/quest_model.g.dart` | `ActiveQuest`에 신규 HiveField 27 추가 → 재생성 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | `ActivityLogType.combatReportGenerated` 추가 → 재생성 |
| `band_of_mercenaries/lib/core/models/combat_report_template.{freezed,g}.dart` | freezed + json_serializable 생성 |
| `band_of_mercenaries/lib/core/models/combat_report_keyword.{freezed,g}.dart` | freezed + json_serializable 생성 |
| `band_of_mercenaries/lib/core/domain/template_context.freezed.dart` | `allyName` 필드 추가 → 재생성 |

`cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 실행 필수.

### 3.4 관련 시스템

- **QuestCompletionService**: `combatReportEligible` 플래그는 이미 셋업되어 있어 본 명세에서 수정 불필요. 단, `quest_pool.specialFlags['combat_report']` 마킹은 별도 데이터 시드(페이즈 4 #1 또는 외부) 책임.
- **QuestNarrativeService**: 본 명세에서 수정하지 않음. `pickProtagonist`만 외부 호출로 재사용한다.
- **TemplateEngine**: `ally`·`enemy` namespace 추가로 영향. resolver와 `TemplateVariableCatalog`를 함께 갱신한다. 기존 호출부는 `TemplateContext.allyName` 미설정 시 영향 없음(null fallback).
- **DialogQueueProvider**: `QuestResultDialog`는 본 명세 시점에서 dialogQueue를 통하지 않고 기존 호출 경로(quest_provider)에서 직접 띄워진다고 가정한다. 보고서 자체는 dialogQueue에 별도 진입점을 만들지 않는다.
- **ActivityLogRepository**: `combatReportGenerated` enum 1종 추가 외 변경 없음.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `band_of_mercenaries/lib/features/quest/domain/quest_narrative_service.dart`: 가중 랜덤 + protagonist 선택 + TemplateEngine 렌더 패턴. `CombatReportService`는 이 구조를 확장한다.
- `band_of_mercenaries/lib/core/models/quest_narrative_data.dart`: 정적 데이터 모델 freezed 패턴(snake_case `@JsonKey`).
- `band_of_mercenaries/lib/features/achievement/domain/band_achievement_model.dart`(`typeId: 16/17`): 신규 typeId 할당 + HiveField 점유 + Hive 어댑터 등록 패턴.
- `band_of_mercenaries/lib/features/quest/view/quest_result_dialog.dart`: 결과 다이얼로그 섹션 순서. `_RewardRow`/`_MercStatusRow`처럼 사설 클래스로 위젯 분리.
- `band_of_mercenaries/lib/core/providers/static_data_provider.dart`: 정적 데이터 신규 추가 4-step 패턴(import → 필드 → 생성자 → loadFromCache).

### 4.2 주의사항

- **typeId 21 충돌 확인**: `grep -rn "typeId:" band_of_mercenaries/lib --include="*.dart" | grep -v ".g.dart"` 결과 최댓값은 20(`FactionShopDailyEntry`). 21이 유효함을 명세 시점(2026-05-18)에 검증함. 구현 시점에 다른 마일스톤이 21을 선점했다면 22로 시프트한다.
- **typeId 12는 미사용으로 보존**(CLAUDE.md 명시). `CombatReport`에 12를 부여하지 않는다.
- **HiveField 27 충돌 확인**: `ActiveQuest`의 마지막 점유는 26(`namedTargetMercId`). 27 사용 가능. 동시 진행 마일스톤이 27을 선점하면 다음 가용 번호로 시프트.
- **CLAUDE.md "다음 HiveField 번호" 표 갱신 필요**: ActiveQuest 27→28, ActivityLogType 39→40. 구현 PR에서 반영.
- **재생성 파일은 직접 편집 금지**. `build_runner build`로만 갱신.
- **상세 뷰 진입 시 Navigator.push 사용 금지**(CLAUDE.md UI 제약). 동일 다이얼로그 내 상태 전환만 허용.
- **fail-soft trailing**: 보고서 생성 실패가 의뢰 보상 지급이나 다른 hook(엘리트/체인/위업)을 중단시키지 않도록 try/catch로 감싼다. 실패 시 `debugPrint`만 남기고 다음 단계로 진행.
- **재현성**: seed는 `DateTime.now().millisecondsSinceEpoch ^ quest.id.hashCode`. 동일 quest 재호출 시 `quest.combatReport != null` 분기로 재생성을 막아 결정성 보장. 단위 테스트는 seed 명시 호출 경로로 검증.
- **result_type 매핑**: CSV는 `great_success`·`critical_failure`, Dart enum은 `greatSuccess`·`criticalFailure`를 사용한다. `resultType.name` 직접 비교 금지. 반드시 `_resultTypeKey` helper를 통해 비교한다.
- **optional table 정책**: `combat_report_templates`·`combat_report_keywords`는 `SyncService.optionalTables`에 포함한다. 빈 캐시 또는 테이블 부재는 앱 기동 실패가 아니라 보고서 미생성 fallback으로 처리한다.
- **avoid_print 설정 활성**: `print` 사용 금지. `debugPrint` 사용.

### 4.3 엣지 케이스

- **partyMercs가 빈 리스트**: 모든 용병이 사망/이탈한 극단 케이스. `pickProtagonist`가 null을 반환하면 `{merc.name}` 치환 품질을 보장할 수 없으므로 `CombatReportService.generate()`는 `null`을 반환하고 보고서를 생성하지 않는다.
- **scope 매칭 템플릿 0개**: 단계별 fallback(`scope == 'quest_type'` → 그것도 없으면 `null` 반환 → 보고서 미생성). 호출부는 null을 정상 분기.
- **CSV `tags_json` 파싱 실패**: 잘못된 JSON 문자열 또는 예상과 다른 타입 → `toneTags`에 해당 템플릿의 태그 미포함, 본문 렌더는 정상 진행.
- **`ally`가 protagonist와 동일(파티 1인)**: `featuredMercIds`에서 dedup. `{ally.name}`은 `merc.name` fallback.
- **상세 줄 부족**: importance 매트릭스의 목표 줄 수보다 실제 매칭 템플릿이 적은 경우 가능한 만큼만 반환(최소 1줄 보장 시도, 0줄이면 보고서 미생성).
- **이미 보고서 있는 quest 재완료(이론상 불가지만)**: `quest.combatReport != null` early return으로 멱등.
- **`combatReportEligible == true`인데 페이즈 2의 15~25% 범위 초과 시**: 본 명세 범위 외(quest_pool 데이터 마킹 책임). Q-1에 명시.

### 4.4 구현 힌트

- **진입점**:
  - 트리거: `quest_provider.dart:868` 부근(`if (result.renderedNarrative != null) { ... }` 직후)에 `if (result.combatReportEligible && quest.combatReport == null) { ... }` 블록 삽입.
  - UI: `quest_result_dialog.dart:85` 부근(서사 카드 닫는 `]` 직후, 용병 상태 헤더 `]` 직전)에 요약 카드 삽입.
- **데이터 흐름**:
  1. `_applyCompletionResult(quest, result, mercs, ...)`
  2. → `CombatReportService.generate(quest: ..., partyMercs: ..., staticData: ..., userData: ..., factionStates: ..., templateEngine: ref.read(templateEngineProvider), regionState: ..., sectorChanges: ..., seed: ...)`
  3. → `CombatReport?` 반환
  4. → `quest.combatReport = report; await quest.save();`
  5. → `await ref.read(activityLogProvider.notifier).addLog('전투 보고서: ${quest.questName}', ActivityLogType.combatReportGenerated)`
  6. UI: `staticData.when(data: ...)` 분기 안에서 `quest.combatReport`를 props 없이 `quest`에서 직접 읽음(이미 ConsumerWidget이라 watch 대상 아님 — Hive 직접 접근).
- **참조 구현**:
  - `quest_narrative_service.dart:43-66` — `pickProtagonist` (외부에서 재사용)
  - `quest_narrative_service.dart:68-130` — `renderNarrative` (구조 패턴 거의 동일)
  - `quest_completion_service.dart:60-91` — `QuestCompletionResult` 모델 정의 스타일
  - `quest_result_dialog.dart:54-85` — 카드 컨테이너 스타일(`Container` + `BoxDecoration(color: bgColor.withValues(alpha: 0.3))`)
  - `static_data_provider.dart:163-247` — 신규 정적 데이터 추가 4-step 패턴
  - `band_achievement_model.dart` — 신규 typeId 할당 + 어댑터 등록 패턴
- **확장 지점**:
  - `CombatReportService.generate` 내부 단계 함수(`_resultTypeKey`, `_resolveImportance`, `_resolveScopeFilters`, `_pickSummary`, `_pickDetails`, `_buildContext`, `_parseTags`)는 모두 private static으로 분리 → 단위 테스트 가능.
  - `_CombatReportSummaryCard`와 `_CombatReportDetailView`는 사설 클래스로 `quest_result_dialog.dart`에 추가. `_RewardRow` 스타일 따름.
- **Supabase 시드**: 페이즈 3 #5 CSV → INSERT SQL은 data-generator 스킬 또는 별도 마이그레이션. 본 명세는 Dart 측 로드 코드만 다룬다.

## 5. 기획 확인 사항

- [Q-1] 노출 빈도 게이트 위치: 본 명세는 `combat_report` specialFlag 마킹을 quest_pool 데이터 시드(외부)에서 관리한다고 가정한다. 만약 코드 측에서 추가 게이트(예: "최근 N건 중 25% 초과 시 skip")가 필요하면 그 로직은 별도 명세로 분리한다. → **답변: 데이터 시드 책임으로 통일. 코드 게이트 추가하지 않음.**
- [Q-2] `protagonistMercId`가 가리키는 용병이 본 명세 저장 후 사망/방출되어 본체에서 사라진 경우, 상세 뷰의 protagonist 칩 표시 방식: (a) 이름 lookup 실패 시 "—"로 표기 (b) 발급 시점 이름을 보고서에 함께 저장. → **답변: (a). M8a 범위에서 발급 시점 이름 저장(MercenarySnapshot)은 도입하지 않음. lookup 실패 시 칩 자체를 숨김.**
- [Q-3] CSV의 `tags_json` 컬럼과 Supabase 응답 타입을 어떻게 호환할지: JSONB 컬럼이면 Supabase 클라이언트가 자동 디코드해 Map 형태로 전달할 수 있고, CSV/TEXT 캐시 경로에서는 문자열로 들어올 수 있다. → **답변: 모델은 `Object?` 또는 `Map<String,dynamic>?`를 허용하고 파싱 helper에서 `Map<String,dynamic>` 우선, 문자열일 경우 `jsonDecode` fallback으로 처리한다.**
- [Q-4] 결과 다이얼로그 외에 보고서를 다시 보는 경로(연대기 등): M8a 범위 외. 현재 완료 의뢰는 결과 다이얼로그 닫힘 후 삭제되므로 장기 재열람에는 별도 저장 모델이 필요하다. → **답변: M8a 범위 외 확정. M8.5/M9에서 별도 화면을 도입할 때 `CombatReport`를 완료 기록 또는 전용 박스로 이관·보존하는 설계를 추가한다.**
- [Q-5] 보고서 토큰 효과 미리보기(파견 카드 "보고서 생성" 배지): 페이즈 1 기획서에 권장되었으나 페이즈 2 밸런스에는 의무가 아니다. 본 명세 범위에 포함하지 않는다. → **답변: M8a 범위 외 확정. 의뢰 카드 UI 변경 없음.**
- [Q-6] 보고서가 0줄(템플릿 매칭 실패)일 때 ActivityLog 발급 여부: FR-3에 따르면 `generate()`가 null 반환 시 보고서 미생성. ActivityLog도 미발급(생성 성공 케이스에만 로그). → **답변: 확정.**
- [Q-7] 요약 문장 수의 데이터 표현 방식: 페이즈 1·페이즈 2는 importance별 요약 문장 수를 2/3/4로 명시했으나, 현재 페이즈 3 CSV는 summary 라인이 대부분 1문장으로 작성되어 있다. 본 명세는 "요약 템플릿 1개 추첨"만 정의하며, 다문장 표현은 데이터 시드 책임으로 위임한다. → **답변: 코드 측에서는 요약 1개 템플릿 추첨만 보장. 페이즈 3 데이터 보강 필요 시 별도 작업으로 분리. 본 명세 범위 외.**
- [Q-8] 상세 줄 수 범위형(5~7/6~8) 추첨 방식: `_resolveDetailLineCount(importance, random)`는 `random.nextInt(max - min + 1) + min`로 균등 분포 추첨. 매칭 풀 크기가 부족하면 풀 크기로 클램프(최소 1줄 보장 시도). → **답변: 균등 분포 + 풀 크기 클램프로 확정.**
- [Q-9] `result_type` 표기 방식: CSV는 `great_success`·`critical_failure` snake_case를 사용하고 Dart enum은 `greatSuccess`·`criticalFailure` camelCase를 사용한다. → **답변: `_resultTypeKey(QuestResult)` helper로 snake_case 키를 만들어 매칭한다. `resultType.name` 직접 비교 금지.**
- [Q-10] 전투 보고서 정적 테이블의 로딩 정책: M8a 신규 스키마가 적용되지 않은 환경에서 앱 기동이 막히면 안 된다. → **답변: `combat_report_templates`·`combat_report_keywords`는 optional table로 등록한다. 테이블/캐시 부재 또는 빈 리스트는 보고서 미생성 fallback으로 처리한다.**
- [Q-11] `{ally.name}`·`{enemy.name}` 변수 추가 범위: resolver만 추가하면 renderer의 `TemplateVariableCatalog.isKnown` 검증에서 unknown 처리된다. → **답변: `template_variable_catalog.dart`에 namespace와 field를 함께 등록한다.**
