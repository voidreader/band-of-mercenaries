# TemplateEngine 공유 모듈 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260423_template_engine.md`
> 후속 반영: 페이즈 1-4(quest_narratives 88행·`region.sector_type` 인라인 분기) / 페이즈 1-5(이동 선택지 `evaluationScope: team`) / 배치 F(11종 실 trait.key 매핑)
> 작성일: 2026-04-24
> 범위: M3 페이즈 4-1 (M3의 모든 후속 spec 선행 의존)

## 1. 개요

M3의 퀘스트 서사(`quest_narratives`)·연계 퀘스트(`chain_quests`)·변형 팝업(`region_discoveries.narrative_template`)·이동 선택지(`travel_choice_events/options/results`)가 **공통으로 사용하는 문자열 템플릿 엔진**을 Flutter 측에 구현한다. 엔진은 (1) 변수 치환 `{namespace.field}`, (2) 조건 분기 `[if …]…[/if]`, (3) 랜덤 변주 `[pick …|…|…]`, (4) 조건식 평가 9개 연산자를 지원한다. 런타임은 **fail-safe**(데이터 오류 시 앱 크래시 금지, `[?var]` 표기로 가시화). 컴파일 타임 검증은 후속 `operation-bom` 편집기 책임이므로 본 spec 범위 밖이지만 Flutter 엔진도 `validate()` API를 동일 규칙으로 제공한다.

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] 변수 치환 토큰 `{namespace.field}` 렌더**
  - 상세: `{merc.name}`, `{region.name}` 등을 런타임 값으로 치환.
  - 네임스페이스 4종: `merc`, `quest`, `region`, `world`
  - 필드 수: **30개** (페이즈 1-1 29개 + `region.sector_type` 신설)
  - 미등록 네임스페이스·필드: `[?:unknown:<토큰>]` 출력 + `debugPrint` 경고
  - 등록된 필드이나 값 `null`: `[?namespace.field]` 출력 + `debugPrint` 경고
  - 이스케이프: `\{`, `\}`, `\[`, `\]`, `\\` 리터럴 처리

- **[FR-2] Fallback 구문 `{field|literal}` 렌더**
  - 상세: 값이 `null`이면 파이프 뒤 리터럴 출력 (경고 없음)
  - 리터럴은 문자열만 허용. 중첩 변수 금지
  - 예: `{quest.enemy|적}` → quest.enemy가 NULL이면 "적" 출력

- **[FR-3] 조건 분기 블록 `[if expr]…[elif expr]…[else]…[/if]` 렌더**
  - 상세: 조건식 결과가 `true`인 첫 분기만 렌더. 모두 `false`면 `[else]` 블록 또는 빈 문자열
  - 중첩 상한 **2단계** (3단계 이상 → `validate()` 오류)
  - 런타임 문법 오류(블록 언밸런스): 원본 템플릿 그대로 출력 + `debugPrint` 경고

- **[FR-4] 랜덤 변주 블록 `[pick A|B|C]` 렌더**
  - 상세: 파이프로 구분한 2~10개 후보 중 균등 확률로 1개 선택
  - 후보 1개 또는 11개 이상: `validate()` 오류
  - pick 블록 내 pick/if 금지 (중첩 없음)
  - 시드: `TemplateContext.seed` 전달 시 재현 가능, 기본은 `Random.secure()`

- **[FR-5] 조건식 평가 9개 연산자**
  - `==`, `!=`: 문자열/enum/int 비교
  - `>=`, `>`, `<=`, `<`: 숫자 비교
  - `has_trait:<key>`: 단일 trait 보유 여부
  - `has_any_trait:<k1>,<k2>,…`: OR 결합, 최대 5개
  - `has_all_traits:<k1>,<k2>,…`: AND 결합, 최대 3개
  - `joined_faction:<faction_id>`: 세력 가입 여부
  - `and` / `or` / `not`: 불린 결합
  - `(` `)`: 그룹핑
  - **금지**: 수식(`+`/`-`/`*`), 변수 간 비교, 정규식, 함수 호출

- **[FR-6] `TemplateContext.evaluationScope: EvaluationScope` 파라미터**
  - enum: `mercenary` | `team`
  - `mercenary`(기본): `has_trait`/`has_any_trait`/`has_all_traits`를 **대표 용병(`context.merc`) 1명 기준** 평가
  - `team`: 위 3개 연산자를 **용병단 전체(`context.rosterForTeam`)** 기준 평가
    - 한 명이라도 보유하면 `true`
  - `joined_faction`, 비교 연산자 등은 scope 무관
  - 호출부 책임:
    - `quest_narratives` 렌더: `mercenary` 사용
    - `chain_quests.description` 렌더: `mercenary` 사용
    - `travel_choice_options.visibility_expr` 평가: `team` 사용
    - `travel_choice_results.conditional_expr` 평가: `mercenary` 사용 (대표 용병 기준)

- **[FR-7] `evaluate(expression, context) → bool` API**
  - 선택지 가시성·결과 분기 조건 평가용
  - 문법 오류: `false` 반환 + `debugPrint` 경고 (크래시 금지)
  - 평가 범위는 `context.evaluationScope`에 따름

- **[FR-8] `render(template, context) → String` API**
  - 토큰·블록 모두 처리한 최종 문자열 반환
  - 에러 처리: FR-1/3/4 fail-safe 규칙에 따름

- **[FR-9] `validate(template) → List<ValidationError>` API**
  - 빈 리스트면 OK. 문제 발견 시 오류 목록 반환
  - 검증 항목:
    - 치환 토큰의 네임스페이스·필드가 카탈로그에 존재
    - 블록 개폐 균형 (`[if]`…`[/if]`, `[pick]`…`[/pick]`)
    - 조건식 문법 합법성 (허용된 연산자만)
    - `has_trait:<key>`의 trait key가 `traits` 테이블에 존재 (런타임 `allTraitKeys` 주입 필요. 주입 없으면 FK 검증 생략)
    - `joined_faction:<id>`의 faction_id가 `factions` 테이블에 존재 (동일 규칙)
    - `pick` 블록 후보 수 2~10
    - 중첩 깊이 ≤ 2
    - 이스케이프 아닌 비매칭 괄호 없음
  - **주의**: FK 검증은 `validate()` 호출 시 `knownTraitKeys`/`knownFactionIds` 파라미터 주입 시에만 수행. Flutter 앱은 주로 렌더만 하므로 기본은 파라미터 없이 호출 → FK 검증 생략

- **[FR-10] 변수 카탈로그 정적 정의**
  - 파일: `lib/core/domain/template_variable_catalog.dart`
  - 4개 네임스페이스 × 30개 필드 enum/const 정의
  - 필드별 `type` (string/int/enum/bool)
  - 기획 1-1 §2 테이블 + `region.sector_type` (string, 값 `village`/`ruins`/`hidden`/`standard`)

- **[FR-11] TemplateContext 구성**
  - Freezed 모델 `TemplateContext`:
    - `Mercenary? merc`
    - `ActiveQuest? quest`
    - `Region? region`
    - `UserData user`
    - `List<FactionState> factionStates`
    - `Map<int, String>? sectorChanges` — `region.sector_type` 렌더용 (`region.id`의 `RegionState.sectorChanges[sectorIndex]` 매핑 결과)
    - `int? currentSectorIndex` — 현재 섹터 인덱스 (런타임에서 `region.sector_type` 해결에 사용)
    - `List<Mercenary> rosterForTeam` — `team` scope 평가용 (`Mercenary` 리스트, 비어있으면 `team` scope 시 `false` 반환)
    - `List<String> eliteId` — (생략 가능, `quest.is_elite`/`quest.elite_name` 채움용)
    - `int? seed` — pick 재현용
    - `EvaluationScope evaluationScope` — 기본 `mercenary`

- **[FR-12] Riverpod Provider 제공**
  - `templateEngineProvider`: `TemplateEngine` 싱글턴 인스턴스 제공
  - 호출부는 `ref.read(templateEngineProvider).render(...)` 형태로 사용

### 2.2 데이터 요구사항

- **Hive 박스 변경**: 없음
- **Supabase 테이블 변경**: 없음 (페이즈 3에서 모든 테이블 준비 완료)
- **신규 enum**: `EvaluationScope { mercenary, team }` (`lib/core/domain/template_context.dart`)
- **신규 클래스**:
  - `TemplateContext` (freezed)
  - `TemplateEngine` (불변 클래스, 스테이트리스 로직)
  - `TemplateParseNode` (sealed class — 내부 AST)
  - `TemplateValidationError` (value object)
  - `TemplateVariableCatalog` (정적 상수 모음 클래스)

### 2.3 UI 요구사항

UI 없음. TemplateEngine은 순수 도메인 로직 모듈. 렌더된 문자열을 UI가 소비한다.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|---|---|---|
| `band_of_mercenaries/lib/features/movement/domain/travel_event_service.dart` | `description` 렌더 시 `TemplateEngine.render()` 적용 (호환성: 치환 토큰 없는 텍스트는 원문 유지) | 기획 §7-1 "기존 12종 자동 이벤트도 렌더" |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `TemplateContext` 생성 시 필요한 데이터 (유저 로스터·RegionState·factionStates) 연결용 helper Provider (필요 시). 단 `TemplateContext` 자체는 호출부가 구성 | 카탈로그 접근 시 Provider 경유 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|---|---|
| `band_of_mercenaries/lib/core/domain/template_engine.dart` | 메인 엔진 (파서·렌더러·평가기) |
| `band_of_mercenaries/lib/core/domain/template_context.dart` | `TemplateContext` freezed 모델 + `EvaluationScope` enum |
| `band_of_mercenaries/lib/core/domain/template_variable_catalog.dart` | 30개 변수 정적 정의 |
| `band_of_mercenaries/lib/core/domain/template_parse_node.dart` | 내부 AST (sealed class: `TextNode` / `VariableNode` / `IfNode` / `PickNode`) |
| `band_of_mercenaries/lib/core/domain/template_validation_error.dart` | 검증 오류 값 객체 |
| `band_of_mercenaries/lib/core/providers/template_engine_provider.dart` | Riverpod Provider (싱글턴) |
| `test/core/domain/template_engine_test.dart` | 렌더러 단위 테스트 (렌더 시나리오 ~20개) |
| `test/core/domain/template_engine_evaluate_test.dart` | 조건식 평가 테스트 (~15개) |
| `test/core/domain/template_engine_validate_test.dart` | 검증 테스트 (~10개) |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|---|---|
| `band_of_mercenaries/lib/core/domain/template_context.freezed.dart` | `TemplateContext` freezed 모델 |
| `band_of_mercenaries/lib/core/domain/template_context.g.dart` | JSON serialization 불필요 시 생략 가능 — 런타임 값 객체이므로 **.g.dart 미생성** |

**build_runner 실행**: `cd band_of_mercenaries && dart run build_runner build`

### 3.4 관련 시스템

- **페이즈 4-2 이후 모든 M3 spec**: TemplateEngine API 사용. 선행 의존성
- **TravelEventService (기존)**: `description` 렌더 흐름에 TemplateEngine 통합
- **Riverpod static_data_provider**: Region/Mercenary/UserData/FactionState는 이미 공급. TemplateContext는 호출부가 `ref.read()`로 수집하여 구성
- **operation-bom (웹 앱)**: 본 spec 범위 밖. 편집기 개발은 별도 트랙

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **Freezed 모델 패턴**: `lib/core/models/region.dart:6-22`, `lib/core/models/travel_event.dart:6-22` — `@freezed` + `@JsonKey(name: 'snake_case')` + `part '…freezed.dart'`. `TemplateContext`는 JSON serialization 불필요(런타임 값만)이므로 `.g.dart`는 생략
- **서비스 클래스 패턴**: `lib/core/domain/experience_service.dart`, `lib/core/domain/idle_reward_service.dart`, `lib/features/quest/domain/quest_calculator.dart` — 스테이트리스 static 메서드 모음 방식 (단, 본 엔진은 파서 상태를 내부에 가질 수 있으므로 인스턴스 기반이 더 적합)
- **Riverpod Provider 패턴**: `lib/core/providers/static_data_provider.dart` — `Provider<T>` 패턴. `templateEngineProvider`도 동일

### 4.2 주의사항

- **파서 구현**: 단순 정규식으로 부족. 2-pass (토큰화 → AST 빌드) 권장. 에스케이프 처리(`\{` 등) 주의
- **fail-safe 원칙**: 어떤 템플릿 입력도 크래시 금지. 예외는 모두 `debugPrint` 경고 + 원본 또는 `[?…]` 표기로 대체
- **trait.key 실존**: 배치 F에서 확정된 11종 `empathic`/`iron_will`/`quick_learner`/`sixth_sense`/`born_leader`/`thief_origin`/`hawk_eye`/`monastery_origin`/`iron_skin`/`survival_instinct`/`agile_body` 등. `traits` 테이블은 페이즈 3에서 안정화됨. 엔진은 FK 검증을 `validate()` 호출자가 `knownTraitKeys` 주입 시에만 수행
- **pick 시드 동작**: 호출부가 퀘스트 완료 후 렌더된 문자열을 Hive(`ActivityLog` 또는 결과 아카이브)에 저장하는 책임 소유. 엔진은 시드를 받아 결정적으로 렌더만. 저장 책임은 **페이즈 4-4 spec 대상** (본 엔진 범위 밖)
- **`region.sector_type` 해결**: 런타임 `RegionState.sectorChanges[currentSectorIndex]` 조회. sectorChanges에 없으면 기본값 `"standard"` 반환. 호출부가 `currentSectorIndex`를 적절히 공급해야 함
- **`quest.*` 필드 해결**: `ActiveQuest`는 현재 `difficulty`, `questTypeId` 등 일부만 보유. `quest.type_ko`는 `quest_types.name` FK 조회 필요 → `TemplateContext`에 `List<QuestType> questTypes` 추가하여 조회. `quest.net_profit`은 `QuestCalculator.calculateNetProfit()` 재사용
- **CLAUDE.md 제약 준수**: `.g.dart`/`.freezed.dart` 재생성 필요 시 `dart run build_runner build`

### 4.3 엣지 케이스

- **빈 템플릿**: `render("", ctx)` → 빈 문자열 반환
- **context가 null인 필드**: `{merc.name}`인데 `ctx.merc == null` → `[?merc.name]` 출력 + 경고
- **중첩 if 3단계**: `validate()`에서 오류, `render()`는 최선 노력 렌더 후 경고
- **pick 후보 11개 이상**: `validate()` 오류, `render()`는 11개째부터 무시하고 10개 중 선택
- **조건식 syntax error**: `evaluate()` → `false` + 경고, `[if]` 블록은 `[else]` 경로 렌더
- **team scope + 빈 로스터**: `has_trait`/`has_any_trait`/`has_all_traits` 모두 `false` 반환
- **team scope + 전원 파견**: 호출부(TravelChoiceService) 책임으로 rosterIdle 필터링. 엔진은 그대로 평가
- **fallback 리터럴에 특수문자**: `{quest.enemy|적|군}` (파이프 2개) → 첫 파이프까지만 field name, 이후 리터럴. 파이프 리터럴이 필요하면 `\|`로 이스케이프
- **변수 이름 중 공백**: `{ merc.name }` 허용 (trim 후 처리). 기획서 예시에도 없으나 관용 허용

### 4.4 구현 힌트

- **진입점**: `templateEngineProvider.read()` → `TemplateEngine.render(template, context)` / `.evaluate(expr, context)` / `.validate(template, knownTraitKeys?)`
- **데이터 흐름**:
  - 퀘스트 서사: `QuestCompletionService` → `ref.read(templateEngineProvider).render(narrative.template, ctx)` → `QuestResultDialog`
  - 이동 선택지 가시성: `TravelChoiceService` → `evaluate(option.visibilityExpr, ctx.copyWith(evaluationScope: team))`
  - 이동 선택지 결과 조건: `evaluate(result.conditionalExpr, ctx.copyWith(evaluationScope: mercenary))`
- **참조 구현**:
  - Freezed 모델 구조: `lib/core/models/region.dart`
  - Riverpod Provider: `lib/core/providers/static_data_provider.dart`
  - 정적 상수 카탈로그: `lib/core/constants/game_constants.dart`
- **확장 지점**: `TemplateVariableCatalog`에 새 필드 추가 시 `template_variable_catalog.dart` + 렌더러의 필드 해결 스위치에 case 추가. 추후 `tool/gen_template_catalog.dart` 도입 시 자동 생성

## 5. 기획 확인 사항

- [Q-1] **`tool/gen_template_catalog.dart` 자동 생성 스크립트 MVP 포함 여부**
  → **결정: MVP 제외**. 30개 변수는 수동 작성으로 충분. operation-bom 의존성 현재 없음. 월 2회+ 변수 추가 필요 발생 시 M4에서 도입

- [Q-2] **`merc.*` 대표 용병 선정 규칙**
  → 기획 Q-2에서 `(b) 파티 내 최고 기여(partyPower 비중)` 확정 (`Docs/balance-design/[balance]20260424_chain_quest_rewards.md` 페이즈 2-1에서 재확인). 체인 퀘스트는 **`ChainQuestProgress.protagonistMercId` 고정**(페이즈 1-2 Q-2 결정). TemplateEngine 자체는 호출부가 `context.merc`에 용병을 주입하는 책임 — **엔진은 선정 로직 미포함**

- [Q-3] **`pick` 시드 고정 저장 시점**
  → 본 spec 범위 밖 (페이즈 4-4 `QuestNarrativeService` spec 대상). 엔진은 `seed` 파라미터만 지원, 저장은 상위 서비스 책임

- [Q-4] **`validate()` FK 검증 주입 방식**
  → 기본은 FK 검증 생략 (Flutter 런타임은 렌더 중심). 선택적으로 `knownTraitKeys: Set<String>?` / `knownFactionIds: Set<String>?` 파라미터 주입 시 FK 검증 수행. operation-bom 편집기는 별도 트랙

- [Q-5] **`quest.net_profit` 계산 시점**
  → 퀘스트 완료 후 `ActiveQuest.totalReward/totalWage/dispatchCost`가 채워진 상태에서만 렌더 가능. 미완료 상태에서 `quest.*` 참조 시 `[?quest.net_profit]` 출력. 호출부(`QuestCompletionService`)가 완료 시점에 렌더해야 함 — **페이즈 4-4 spec 유의점**

- [Q-6] **`world.joined_factions` 개수 제한**
  → 기획상 0~3. `FactionJoinService`의 `getJoinedFactionIds().length` 계산. 현재 구현 이미 3 상한 존재 (`FactionJoinService.canJoin`). 엔진은 그대로 반영

- [Q-7] **`evaluationScope: team` 사용 시 `{merc.*}` 치환**
  → `{merc.*}`은 항상 `context.merc`(대표 용병) 기준. scope와 무관. "Jane이 동료 John의 empathy 덕에 풀뿌리 치료를 받았다" 같은 복수 용병 서사는 MVP 미지원 (기획 1-1 §MVP vs 확장 동일)

- [Q-8] **이스케이프된 `[` `]`에서 블록 파서 동작**
  → 2-pass: 1) 이스케이프 일시 치환(`\{` → `\x00`) 2) 파싱 3) 렌더 후 `\x00` → `{` 복원. 공개 API는 이를 노출하지 않음

## 6. 다음 단계

- **페이즈 4-1 구현**: 이 spec 기반으로 `/implement-spec` 또는 `/implement-agent` 호출
- **페이즈 4-2~4-5**: 본 엔진이 완성되면 각 spec이 TemplateEngine API를 호출. 4-2(연계 퀘스트), 4-3(지역 변형), 4-4(퀘스트 서사 통합), 4-5(이동 선택지) 순서 권장
