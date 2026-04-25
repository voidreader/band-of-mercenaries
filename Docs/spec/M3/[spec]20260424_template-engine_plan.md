Skill used : implement-agent

# TemplateEngine 공유 모듈 구현 계획서

> 명세서: `Docs/spec/M3/[spec]20260424_template-engine.md`
> 작성일: 2026-04-25
> 범위: M3 페이즈 4-1 (M3 후속 spec 4건의 선행 의존)

## 1. 구현 개요

M3의 퀘스트 서사·연계 퀘스트·변형 팝업·이동 선택지가 공통으로 사용하는 문자열 템플릿 엔진을 Flutter 도메인 레이어에 구현. 변수 치환 `{namespace.field}`, fallback `{field|literal}`, 조건 분기 `[if/elif/else/[/if]]`, 랜덤 변주 `[pick A|B|C]`, 9개 연산자 평가, mercenary/team 평가 범위 분리를 모두 fail-safe 원칙으로 처리.

## 2. 사용자 확인 사항 결정

| Q | 결정 | 사유 |
|---|------|------|
| Q-1 `travel_event_service.dart` 수정 범위 | 옵션 A | `renderDescription` 헬퍼만 추가, 호출부 변경은 페이즈 4-5에서 |
| Q-2 `eliteId` 타입 | 옵션 A | `String? eliteId` 단수로 정정 (FR-11 본문 `List<String>`은 오기) |
| Q-3 `questTypes` 추가 | 옵션 A | FR-11을 정본으로 보고 미추가, 페이즈 4-4에서 검토 |
| Q-4 카탈로그 출처 | 옵션 A | 기획 §2 테이블 28개 + `region.sector_type` 1개 = 29개 |

## 3. 변경 파일 목록

### 신규 생성 (10개)

| 파일 경로 | 역할 | 라인 수 |
|---|---|---|
| `band_of_mercenaries/lib/core/domain/template_context.dart` | TemplateContext freezed + EvaluationScope enum | ~50 |
| `band_of_mercenaries/lib/core/domain/template_context.freezed.dart` | freezed 자동 생성 | (auto) |
| `band_of_mercenaries/lib/core/domain/template_variable_catalog.dart` | 29개 카탈로그 + lookup/isKnown | ~100 |
| `band_of_mercenaries/lib/core/domain/template_validation_error.dart` | TemplateValidationCode 9개 + 값 객체 | ~70 |
| `band_of_mercenaries/lib/core/domain/template_parse_node.dart` | sealed class AST 5종 | ~50 |
| `band_of_mercenaries/lib/core/domain/template_engine.dart` | 메인 구현 (render/evaluate/validate) | ~725 |
| `band_of_mercenaries/lib/core/providers/template_engine_provider.dart` | Provider<TemplateEngine> 싱글턴 | ~5 |
| `band_of_mercenaries/test/core/domain/template_engine_test.dart` | render 테스트 20개 | ~250 |
| `band_of_mercenaries/test/core/domain/template_engine_evaluate_test.dart` | evaluate 테스트 22개 | ~270 |
| `band_of_mercenaries/test/core/domain/template_engine_validate_test.dart` | validate 테스트 11개 | ~110 |

### 수정 (1개)

| 파일 경로 | 변경 유형 | 설명 |
|---|---|---|
| `band_of_mercenaries/lib/features/movement/domain/travel_event_service.dart` | 추가 | static `renderDescription(TravelEvent, TemplateContext, TemplateEngine) → String` 메서드 추가. 토큰 미포함 시 원문 그대로 반환(기존 12종 자동 이벤트 호환성). 기존 메서드 무수정 |

## 4. TASK 실행 결과

| TASK | 내용 | 결과 |
|---|---|---|
| TASK-1 | TemplateContext freezed + EvaluationScope | 완료 |
| TASK-2 | TemplateVariableCatalog (29개) | 완료 (명세서 본문 "30개"는 오기로 판단, 기획 §2 정본 29개 채택) |
| TASK-3 | TemplateValidationError (9 코드) | 완료 |
| TASK-4 | TemplateParseNode sealed AST | 완료 |
| TASK-5 | TemplateEngine 메인 구현 | 완료 |
| TASK-6 | templateEngineProvider | 완료 |
| TASK-7 | TravelEventService.renderDescription | 완료 (Q-1 옵션 A) |
| TASK-8 | render 테스트 ~20 | 완료 (실제 20개) |
| TASK-9 | evaluate 테스트 ~15 | 완료 (실제 22개) |
| TASK-10 | validate 테스트 ~10 | 완료 (실제 11개) |

## 5. 검증 모드 및 결과

**검증 모드**: 풀 검증 (TASK 10건 ≥ 3 → verifier + flutter-reviewer 병렬 호출)

### 1차 검증 결과

- **verifier**: PASS — FR-1~FR-14 모두 충족, 호환성 위반 없음, INFO 2건 (참고만)
  - INFO-1: 명세서 카탈로그 개수 표기 오류 (29 vs 30) — 코드 수정 불필요
  - INFO-2: 호출부 책임 lookup 필드 (`merc.tier`/`quest.enemy`/`region.tier_ko` 등) — fallback 패턴으로 안전 처리
- **flutter-reviewer**: BLOCK — HIGH 4건 + MEDIUM 3건 + LOW 1건

### 1차 → 2차 수정 적용 내역

| 이슈 | 출처 | 수정 |
|---|---|---|
| HIGH-1 `package:flutter/foundation.dart` import | flutter-reviewer | `dart:developer show log` + `dart:math hide log`로 교체, `debugPrint` 9개 → `log(name: 'TemplateEngine')` |
| HIGH-2 `_ExprParser` 결합 | flutter-reviewer | `resolveVariable` 콜백 주입 패턴으로 분리 |
| HIGH-3 `Random.secure()` 비용 | flutter-reviewer | `Random()`로 교체 (게임 텍스트 변주에 암호학적 강도 불필요) |
| HIGH-4 `_parseNot` 무제한 재귀 | flutter-reviewer | `depth > 10` FormatException 추가 (DoS 방어) |
| MEDIUM-1 import 순서 | flutter-reviewer | 모두 `package:band_of_mercenaries/...` 절대경로로 통일 |
| MEDIUM-2 광범위 catch | flutter-reviewer | `on FormatException` + `on Error` 분리, Error에 `assert(false)` |

**보류**: MEDIUM-3 (테스트 헬퍼 중복), LOW-1 (수정 불필요)

### 2차 검증 결과

- **flutter-reviewer**: APPROVE — HIGH/MEDIUM 0건, 회귀 없음, 공개 API 시그니처 무변경 확인

## 6. 빌드/테스트 결과

- `flutter analyze`: No issues found
- `dart run build_runner build --delete-conflicting-outputs`: 8.3초, 5 outputs 생성
- 테스트 53개 모두 통과 (render 20 + evaluate 22 + validate 11)

## 7. build_runner 재실행 필요 파일

- `band_of_mercenaries/lib/core/domain/template_context.dart` (`@freezed` 어노테이션 → `template_context.freezed.dart` 생성)

명세서 적용 시 다음 명령어 실행 필요:
```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

## 8. CLAUDE.md 준수 사항

- 코멘트 정책: 자명한 코드 주석 없음. WHY 1줄 주석만 사용 (예: pick 시드 처리, sentinel 문자, fail-safe 분기)
- 의존성: 신규 외부 패키지 0건. `dart:math`, `dart:developer`, `freezed_annotation`, `flutter_riverpod`만 사용
- 최적화: 카탈로그 lookup O(1) Map, RegExp/sentinel 1회 컴파일, const 생성자 싱글턴, Random 인스턴스 render 호출당 1회
- 위반 사항: 없음

## 9. 알려진 한계 (호출부 책임 위임)

다음 카탈로그 필드들은 외부 lookup 의존이라 TemplateEngine 자체로는 항상 null 반환. 호출부가 fallback 패턴(`{field|literal}`) 또는 별도 데이터 주입으로 처리해야 한다.

- `merc.tier` (jobs FK 조회 필요), `merc.job` (jobId 그대로 반환)
- `quest.type_ko` (quest_types FK), `quest.enemy` (ActiveQuest 필드 부재 — `quest_pools.enemy_name` 별도 조회), `quest.elite_name` (elite_monsters FK)
- `region.tier_ko` (한국어 변환 함수 미부착), `region.knowledge` (RegionState 별도 조회 필요)
- `world.rank`, `world.rank_ko` (ranks FK)

후속 spec(특히 페이즈 4-4 QuestNarrativeService)에서 호출부가 이를 보강하거나 narrative 템플릿 작성자가 fallback 구문을 사용하도록 가이드 필요.

## 10. 다음 단계

본 모듈은 M3의 모든 후속 spec이 의존하는 공유 인프라. 다음 spec 구현 시 본 엔진을 import하여 사용:

- 페이즈 4-2: `chain-quest-system.md` — `chain_quests.description` 렌더
- 페이즈 4-3: `region-transform-system.md` — 변형 팝업 텍스트
- 페이즈 4-4: `quest-narrative-integration.md` — `quest_narratives.template` 렌더 (대표 용병 선정 + pick 시드 저장 책임)
- 페이즈 4-5: `travel-choice-system.md` — `visibility_expr` (team scope) + `conditional_expr` (mercenary scope) 평가

공개 API 사용 예:
```dart
final engine = ref.read(templateEngineProvider);
final text = engine.render(template, TemplateContext(
  user: userData,
  merc: representativeMerc,
  // ...
));

final visible = engine.evaluate(option.visibilityExpr, ctx.copyWith(
  evaluationScope: EvaluationScope.team,
));
```
