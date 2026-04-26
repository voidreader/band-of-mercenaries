# TemplateEngine 공유 모듈 컨텐츠 기획서

> 작성일: 2026-04-23
> 유형: 신규 시스템 설계 (M3 페이즈 1-1 · 공유 인프라)
> 후속 페이즈 의존: 페이즈 1-4(퀘스트 서사 48~80개), 페이즈 1-5(이동 선택지 10~15종), 페이즈 4-1(엔진 구현 spec)

## 개요

M3의 **퀘스트 서사**와 **이동 선택지**는 각각 상황별 텍스트를 출력하지만, 둘 다 아래 5가지 기능을 공통으로 필요로 한다.

1. 용병 이름·직업·지역명 등 런타임 값 치환
2. 트레잇/스탯/세력 등 조건에 따른 분기 텍스트
3. 동일 퀘스트 유형×결과 조합에서도 매번 다른 변주
4. 트레잇 기반 숨겨진 선택지의 가시성 판정
5. operation-bom 편집기에서 변수 자동완성·구문 검증

엔진을 **한 번 설계하고 두 영역이 공유**하면, 편집기·검증 툴·조건 분기 로직을 한 번만 만든다. 분리하면 동일 기능을 두 번 만들고 데이터 운영자는 두 문법을 외워야 한다.

이 문서는 TemplateEngine의 **문법 스펙, 변수 카탈로그, 조건 평가 규칙, 에러 처리, 편집기 계약**을 확정한다. 구체 서사 텍스트와 선택지 이벤트는 페이즈 1-4/1-5에서 작성한다.

## 레퍼런스 분석

| 게임 | 참고 포인트 | 차용/변형 |
|------|-----------|----------|
| **Kingdom of Loathing** | `<Player>`, `<enemy>` 등 `< >` 태그 치환. 조건 분기 없음. | 치환 문법 단순성 참고. `< >`는 HTML과 충돌 위험 → `{ }` 채택 |
| **Fallen London (Sunless Sea)** | `{if …}{else}{/if}` + 품질(Quality) 임계치 분기. 선택지별 `visible_if` | 본 엔진의 조건 분기 문법 기반으로 차용. 품질 대신 트레잇·스탯·세력 |
| **Darkest Dungeon / FTL** | 선택지별 결과 확률 테이블. 선행 조건이 있는 숨겨진 선택지 | 선택지 가시성 flag + 트레잇 선행 조건 차용 |
| **AI Dungeon / Inform 7** | 복잡한 조건 분기·상태 머신. 학습 곡선 가파름 | **반면교사** — 과도한 표현력은 데이터 운영 비용 폭증. MVP에서 배제 |
| **Mustache / Handlebars 템플릿** | 변수 치환·블록 헬퍼. 널리 알려진 표준 | `{{ }}`는 토큰 이스케이프가 복잡. 본 엔진은 `{ }` + `[ ]` 2종 구분 채택 |

**핵심 설계 원칙**: "**Fallen London의 표현력 − AI Dungeon의 복잡성**". 데이터 운영자(operation-bom)가 코드 없이 작성·검증 가능한 수준으로 한정.

## 상세 설계

### 1. 두 종류의 구문 구분

| 구문 | 형태 | 용도 |
|------|------|------|
| **치환 토큰** | `{namespace.field}` | 런타임 값을 문자열로 끼워 넣음. 중괄호 |
| **제어 블록** | `[keyword ...] ... [/keyword]` | 조건 분기·랜덤 변주. 대괄호 |

두 구문을 시각적으로 분리한 이유: 편집기에서 구문 하이라이팅이 단순해지고, 데이터 운영자가 "값 치환인지 제어 흐름인지" 즉시 구별할 수 있다.

**이스케이프:**
- 리터럴 `{`/`}`/`[`/`]`는 `\{`, `\}`, `\[`, `\]`로 표기
- `\\`로 역슬래시 리터럴

### 2. 변수 카탈로그 (MVP 고정 세트)

네임스페이스 4개. 미등록 네임스페이스·필드는 컴파일 타임 검증 실패.

#### 2-1. `merc.*` (용병) — 주체 용병 1명 기준

퀘스트 서사의 **대표 용병**(파티의 가장 높은 기여 용병)과 선택지 이벤트의 **대상 용병**에 할당된다. 여러 용병을 참조하는 케이스는 MVP 제외(다음 섹션 "확장 가능 지점" 참조).

| 변수 | 타입 | 예시 값 | 비고 |
|------|------|---------|------|
| `merc.name` | string | "김철수" | |
| `merc.job` | string | "정찰병" | `jobs.name` |
| `merc.tier` | int | 3 | 1~5 |
| `merc.level` | int | 3 | 1~5 |
| `merc.str` | int | 45 | effectiveStr (레벨 보너스+피로 반영) |
| `merc.int` | int | 22 | effectiveIntelligence |
| `merc.vit` | int | 30 | effectiveVit |
| `merc.agi` | int | 28 | effectiveAgi |
| `merc.state` | enum | "normal"/"tired"/"injured" | 현재 상태 |

#### 2-2. `quest.*` (퀘스트) — 주체 퀘스트 기준

퀘스트 서사에서 필수. 이동 선택지에서는 `null` (사용 시 fallback 발동).

| 변수 | 타입 | 예시 값 | 비고 |
|------|------|---------|------|
| `quest.name` | string | "산적 토벌" | `quest_pools.name` |
| `quest.type` | enum | "raid"/"hunt"/"escort"/"explore" | |
| `quest.type_ko` | string | "약탈"/"토벌"/"호위"/"탐험" | `quest_types.display_name` |
| `quest.result` | enum | "greatSuccess"/"success"/"fail"/"greatFail" | |
| `quest.difficulty` | int | 3 | 1~5 |
| `quest.reward_gold` | int | 240 | 최종 지급 골드 |
| `quest.net_profit` | int | 95 | 인건비/파견비 차감 후 순수익 |
| `quest.enemy` | string | "산적단" | `quest_pools.enemy_name` (신규 컬럼, 페이즈 3-0-3에서 스키마 확정) |
| `quest.is_elite` | bool | true/false | M2b 엘리트 퀘스트 여부 |
| `quest.elite_name` | string\|null | "폐광의 울부르" | 엘리트 퀘스트일 때만 |

#### 2-3. `region.*` (지역) — 이벤트 발생 지역

| 변수 | 타입 | 예시 값 | 비고 |
|------|------|---------|------|
| `region.name` | string | "검은 숲" | |
| `region.tier` | int | 2 | 1~5 |
| `region.tier_ko` | string | "평화로운"/"약간 위험한"/"숙련자 지역"/"고난도"/"극한" | 서사 톤 결정용 |
| `region.sector` | int | 3 | 0~9 |
| `region.knowledge` | int | 45 | 0~100. 지식 포인트 |

#### 2-4. `world.*` (월드 상태)

| 변수 | 타입 | 예시 값 | 비고 |
|------|------|---------|------|
| `world.rank` | enum | "F"/"E"/.../"A" | 현재 명성 랭크 |
| `world.rank_ko` | string | "무명"/"신출내기"/.../"전설" | 표시용 |
| `world.gold` | int | 1530 | 현재 골드 |
| `world.joined_factions` | int | 2 | 가입 세력 수 0~3 |

네임스페이스당 필드 수를 9개 이하로 제한했다. 필드 수가 많아지면 데이터 운영자가 외우지 못하고, 편집기 자동완성 UX가 나빠진다.

### 3. 변수 치환 문법

#### 3-1. 기본 치환

```
{merc.name}님이 {region.name}에서 {quest.enemy}를 처치했다.
```

**변환 예시** (김철수 / 검은 숲 / 산적단):
```
김철수님이 검은 숲에서 산적단을 처치했다.
```

#### 3-2. Fallback 구문 (optional)

```
{quest.elite_name|보통 적}
```

값이 `null`·`undefined`이면 파이프 뒤 리터럴을 대체. 리터럴은 **문자열만** 지원. 중첩 변수 금지.

#### 3-3. 숫자 포맷 (MVP 범위)

숫자 변수는 **그대로 출력**(천단위 콤마 없음). 표시 포맷이 필요하면 엔진 확장 시 `{world.gold:comma}` 같은 필터 문법을 추가(MVP 제외). M3 범위에서는 수치가 텍스트 흐름에 거의 나오지 않으므로 지연 허용.

### 4. 조건 분기 문법

#### 4-1. if / elif / else / endif

```
[if merc.state == "injured"]
{merc.name}은 부상을 무릅쓰고 임무를 완수했다.
[elif merc.level >= 4]
{merc.name}의 노련한 솜씨가 빛났다.
[else]
{merc.name}이 임무를 해냈다.
[/if]
```

**중첩 상한**: 2단계까지만 허용 (3단계 이상 시 검증 오류). 깊은 중첩은 편집기에서 추적이 어렵고, 데이터 운영자의 실수가 잦아진다. 더 깊은 분기가 필요하면 템플릿을 2개로 분리하여 `type × result` 풀 내에서 다른 변형으로 처리.

#### 4-2. pick — 랜덤 변주

동일 퀘스트 유형×결과 조합에서 **문장 수준 다양성**을 확보하기 위한 블록. 파이프(`|`)로 구분한 후보 중 균등 확률로 하나를 선택.

```
{merc.name}이 [pick]일격에|한 호흡에|눈 깜짝할 새에[/pick] 적을 제압했다.
```

**3~5개 후보 권장, 10개 상한**. 상한을 두는 이유: 10개 넘으면 템플릿 자체를 새 행으로 분리하는 것이 편집·검토에 유리.

pick 블록 안에 다시 pick이나 if는 넣을 수 없다 (MVP 제약).

**시드 결정**: pick은 렌더 시마다 새 랜덤 시드. 같은 로그를 다시 봐도 같은 문장이 유지되어야 한다면 호출부에서 시드를 고정해 전달(엔진 API에서 optional seed 파라미터).

#### 4-3. 조건식 연산자 (expression)

조건식은 **최소 집합**만 지원. 복잡 수식은 금지.

| 연산자 | 예시 | 의미 |
|--------|------|------|
| `==` / `!=` | `quest.result == "fail"` | 값 비교. 문자열/enum/int |
| `>=` / `>` / `<=` / `<` | `merc.str >= 30` | 숫자 비교 |
| `has_trait:<trait_id>` | `has_trait:berserker` | 단일 트레잇 보유 여부 |
| `has_any_trait:<a>,<b>,…` | `has_any_trait:berserker,bloodlust` | OR 관계. 최대 5개 |
| `has_all_traits:<a>,<b>,…` | `has_all_traits:scholar,eagle_eye` | AND 관계. 최대 3개 |
| `joined_faction:<faction_id>` | `joined_faction:ironblood` | 가입 여부 |
| `and` / `or` / `not` | `merc.level >= 3 and has_trait:brave` | 불린 결합 |
| `(` `)` | `(a or b) and not c` | 그룹핑 |

**금지되는 것**: 수식 연산(`+`, `-`, `*`), 변수 간 비교(`merc.str > merc.vit`), 정규식, 함수 호출. 이런 요구는 데이터가 아니라 코드 로직 영역이므로, 필요 시 Dart 측에서 파생 필드를 추가 (예: 새 `merc.*` 필드).

#### 4-4. 선택지 가시성 (이동 선택지 전용)

이동 선택지의 **선택지 데이터 행**에 `visibility_expr` 컬럼을 둔다. 엔진이 평가 결과가 `false`이면 해당 선택지를 목록에서 제외.

```
visibility_expr: has_trait:empathy and merc.level >= 2
```

`visibility_expr`가 비어 있으면 항상 표시.

공개된 선택지가 없는 이벤트는 발동하지 않는다 (이동 완료 회상 생략).

### 5. 트레잇·조건 평가 3가지 적용 지점

| 적용 지점 | 어디에 사용되나 | 문법 |
|----------|---------------|------|
| **가시성** (선택지 전용) | 이동 선택지의 `visibility_expr` 컬럼 | 단일 표현식 |
| **텍스트 변주** | 서사·선택지 본문 안의 `[if ...][/if]` | 블록 내부 조건 |
| **결과 변주** | 선택지의 결과 행 `conditional_result_expr` 컬럼 (선택지 선택 후 복수 결과 중 하나 선정) | 단일 표현식 |

세 지점 모두 **동일 문법**을 공유한다. 엔진 구현 측에서도 "조건식 파서 1개 + 블록 파서 1개"로 끝나도록 통일.

### 6. 누락 변수 fallback, 검증 규칙

#### 6-1. 런타임 동작 (Flutter 앱)

| 상황 | 동작 |
|------|------|
| 등록된 네임스페이스·필드, 값이 `null` | `[?merc.name]` 형태로 출력 + `debugPrint` 경고 |
| 등록된 필드, fallback 구문 사용 | fallback 리터럴 출력, 경고 없음 |
| 미등록 네임스페이스·필드 | `[?:unknown:<토큰>]` 출력 + `debugPrint` 경고 (프로덕션 빌드에서도 크래시 금지) |
| 문법 오류(블록 언밸런스 등) | 원본 템플릿 그대로 출력 + `debugPrint` 경고 |

**원칙**: "데이터 오류로 앱이 크래시하지 않는다. 다만 눈에 띄게 표시해서 운영자가 즉시 알아챈다."

#### 6-2. 컴파일 타임 검증 (operation-bom 편집기)

편집기는 템플릿 저장 시 다음을 검증:

1. 치환 토큰의 네임스페이스·필드가 변수 카탈로그에 존재
2. 제어 블록의 개폐 균형 (`[if]`...`[/if]`, `[pick]`...`[/pick]`)
3. 조건식 문법 합법성 (허용된 연산자·리터럴만)
4. `has_trait:<id>`의 trait_id가 `traits` 테이블에 존재 (FK 체크)
5. `joined_faction:<id>`의 faction_id가 `factions` 테이블에 존재
6. `pick` 블록의 후보 수가 2~10개
7. 중첩 깊이가 2 이하
8. 이스케이프가 아닌 비매칭 괄호 없음

위반 시 저장 불가 + 어느 행 어느 위치인지 표시.

### 7. operation-bom 편집기 계약

#### 7-1. 변수 카탈로그 배포 방식

`operation-bom/src/constants/template_variables.ts` 정적 파일로 다음 구조를 export:

```typescript
export const TEMPLATE_VARIABLES = {
  merc: { name: 'string', job: 'string', tier: 'int', ... },
  quest: { name: 'string', type: 'enum:raid|hunt|escort|explore', ... },
  region: { ... },
  world: { ... },
};

export const TEMPLATE_OPERATORS = [
  'has_trait', 'has_any_trait', 'has_all_traits', 'joined_faction'
];
```

Flutter 측에서도 **동일 카탈로그**를 공유해야 한다. 해법:
- **Option A (권장)**: operation-bom의 TS 파일을 진실의 원천으로 삼고, 빌드 타임 스크립트로 Dart enum/const를 자동 생성 (`dart run tool/gen_template_catalog.dart`)
- **Option B**: Supabase의 메타 테이블 `template_variables`로 관리 (런타임 fetch). 유연성은 높지만 오프라인 플레이 시 카탈로그 누락 위험

**결정**: **Option A를 페이즈 4-1에서 채택.** 변수 카탈로그는 데이터가 아니라 스키마다. 자주 바뀌지 않고, 스키마 변경 = 앱 빌드 필요 = 카탈로그 동기화는 빌드 스크립트에서.

#### 7-2. 편집기 UX 요구사항

| 기능 | 설명 |
|------|------|
| **변수 자동완성** | `{` 입력 시 네임스페이스 드롭다운, `.` 입력 시 필드 드롭다운 |
| **구문 하이라이팅** | 치환 토큰(청록), 제어 블록 키워드(보라), 문자열 리터럴(주황) 색상 구분 |
| **미리보기 패널** | 우측에 샘플 변수 값을 입력하면 실제 렌더 결과 표시 |
| **검증 오류 표시** | 저장 시도 시 위반 항목을 줄 번호와 함께 리스트업 |
| **변수 참조 카운트** | 템플릿에서 어떤 변수가 쓰였는지 사이드바에 표시 (누락 감지 용이) |

미리보기 샘플 변수 값 세트는 **6개 프리셋**으로 제공:

1. `default` — 모든 필드에 평균적 값 (T3 용병, 약탈 성공)
2. `low_tier_fail` — T1 용병, 난이도 1, 실패
3. `high_tier_great_success` — T5 용병, 난이도 5, 대성공
4. `elite_encounter` — 엘리트 퀘스트
5. `trait_specialist` — `berserker`, `bloodlust` 보유
6. `faction_member` — `ironblood` 가입, 평판 60

프리셋은 `operation-bom/src/constants/template_preview_presets.ts`로 관리.

### 8. 엔진 API 윤곽 (페이즈 4-1 상세화 대상)

데이터 운영 관점에서 참고할 **최소 호출 인터페이스**:

```dart
class TemplateContext {
  final Mercenary? merc;        // merc.* 네임스페이스 소스
  final ActiveQuest? quest;     // quest.* 소스
  final RegionData? region;     // region.* 소스
  final UserData user;          // world.* 소스
  final List<FactionState> factionStates;
  final Random? seed;           // pick 재현용 optional
}

String render(String template, TemplateContext ctx);
bool evaluate(String expression, TemplateContext ctx);
List<String> validate(String template); // 빈 리스트 = OK
```

호출부는 퀘스트 완료 시 `render(narrative.template, ctx)`, 이동 선택지 평가 시 각 선택지의 `evaluate(visibility_expr, ctx)`를 호출.

## MVP vs 확장 가능 지점

| 범주 | MVP (페이즈 4-1에서 구현) | 확장 가능 지점 (M3 이후 검토) |
|------|--------------------------|----------------------------|
| 치환 | 4개 네임스페이스, 29개 필드 | 네임스페이스 추가(길드/장비), 필터(`:comma`, `:upper`) |
| 조건 연산자 | 9개 연산자 + 불린 | 정규식, 수식, 변수간 비교 |
| 블록 | if/else/elif, pick | for 반복, include(다른 템플릿 참조) |
| 중첩 | if 2단계 | 3단계, pick 중첩 |
| 참조 용병 | 대표 용병 1명(`merc.*`) | 복수 용병(`party[0].name`, `party.size`) |
| 변주 카운트 | pick 2~10개 | 가중치 지정(`[pick weighted]A:3|B:1[/pick]`) |
| 편집기 | 자동완성, 하이라이팅, 검증, 미리보기 | 버전 관리, A/B 비교, 통계(렌더 빈도) |

**M3 범위에서는 MVP 그대로 충분**하다. 48~80개 서사 + 10~15개 선택지는 이 표현력으로 작성 가능. 확장 요구가 누적되면 M4 이후 엔진 v2에서 다룬다.

## 현재 시스템과의 연관

### 영향받는 기존 시스템

| 시스템 | 영향 내용 |
|--------|---------|
| `TravelEventService` | 기존 12종 자동 이벤트의 `description`도 이번 엔진을 통해 렌더(변수 치환 적용). 호환성: 치환 토큰이 없는 텍스트는 원문 그대로 출력되므로 기존 데이터 무변경 유지 가능 |
| `QuestCompletionService` | 완료 팝업에 서사 영역 추가. 페이즈 4-4 spec 대상 |
| operation-bom `table-config.ts` | `quest_narratives`, `travel_choice_events` 테이블 정의에 `template_editor` 필드 타입 명시 |
| Supabase | 3개 신규 테이블에 template 컬럼 + 검증 로직 없는 raw text (저장은 편집기 쪽에서 검증) |

### 신규 인프라

| 파일 | 용도 |
|------|------|
| `band_of_mercenaries/lib/core/domain/template_engine.dart` | 메인 엔진 클래스 (render, evaluate, validate) |
| `band_of_mercenaries/lib/core/domain/template_context.dart` | 렌더 컨텍스트 값 객체 |
| `band_of_mercenaries/lib/core/domain/template_variable_catalog.dart` | 변수 카탈로그 enum/const. **빌드 스크립트로 자동 생성** |
| `operation-bom/src/constants/template_variables.ts` | 진실의 원천 카탈로그 |
| `operation-bom/src/components/TemplateEditor.tsx` | 편집기 UI |
| `band_of_mercenaries/tool/gen_template_catalog.dart` | TS → Dart 자동 생성 스크립트 |

### 호환성·회귀 리스크

- **낮음**: 기존 `TravelEvent` 레코드의 `description`은 치환 토큰이 없으므로 엔진 통과 시 동일 출력
- **중간**: operation-bom 편집기 UX는 신규 구성. React 컴포넌트 개발 분량 있음 (페이즈 4-1 이후 operation-bom 측 별도 작업)
- **낮음**: Dart 자동 생성 스크립트는 빌드 타임만 실행, 런타임 성능 영향 없음

## 구현 우선순위 제안

**우선순위: 높음 (M3 크리티컬 패스)**

사유:
- M3의 4개 핵심 spec(페이즈 4-1 ~ 4-5) 중 4-1이 다른 모든 spec의 의존 루트
- 서사 48~80개와 선택지 10~15종을 작성하는 데이터 작업(페이즈 3-4, 3-5)도 엔진 문법에 의존
- 엔진 문법이 늦게 바뀌면 이미 작성한 템플릿 전체 재작성 리스크

**M3 내 착수 순서 권장:**

1. **페이즈 4-1 spec 먼저 확정** (이 문서의 설계를 spec-writer가 구현 명세화)
2. **엔진 코드 구현과 operation-bom 편집기 개발을 병렬 진행 가능** (변수 카탈로그가 계약 역할)
3. 엔진 MVP 동작 확인 후 페이즈 3-4(서사) 벌크 생성
4. 그다음 페이즈 4-4(서사 통합), 4-5(선택지) 순

## 오픈 질문

페이즈 4-1(spec-writer)에서 결론짓기 전에 확인해야 할 항목.

- **Q-1 (변수 카탈로그 자동 생성 도구 선정)**: Option A의 `gen_template_catalog.dart`를 어떤 스크립트로 구현할지(dart 코드 vs 외부 codegen). 이 결정은 페이즈 4-1 spec 내에서 처리 가능하므로 M3 범위에 포함. → **페이즈 4-1 검토 항목**

- **Q-2 (퀘스트 서사 대표 용병 선정 규칙)**: 파티가 여러 명인 퀘스트에서 `merc.*`에 어느 용병을 바인딩할지. 후보:
  - (a) 파티 내 최고 레벨
  - (b) 파티 내 최고 기여(STR×가중치 등 partyPower 비중이 가장 큰 용병)
  - (c) 랜덤
  → **권장**: (b) 기여 기준. "대활약한 용병의 이야기"가 서사 감성에 적합. **페이즈 1-4(서사 기획)에서 최종 확정.**

- **Q-3 (pick 블록 시드 재현)**: 활동 로그에서 같은 결과를 다시 볼 때 문장이 바뀌면 어색할 수 있음.
  → **권장**: 퀘스트 완료 시점에 pick 결과를 **렌더링한 문자열을 Hive에 저장** (활동 로그 또는 ActiveQuest의 완료 아카이브). 매 표시 때마다 렌더하지 않는다. 페이즈 4-4 spec에서 확정.

- **Q-4 (선택지 결과 적용 시점)**: 이동 완료 "회상" 형식으로 선택지를 제시할 때, 선택지 결과(골드/평판 등)를 즉시 반영할지 미루어 일괄 반영할지.
  → **권장**: 이동 완료 직후 팝업에서 사용자가 선택 → 결과 즉시 반영 + 팝업 닫기 + 활동 로그 기록. 페이즈 1-5(선택지 기획)에서 확정.

- **Q-5 (변수 카탈로그 확장 정책)**: 기획에서 새 변수가 필요할 때 추가 경로. 매번 앱 빌드가 필요하면 반응성이 떨어질 수 있음.
  → **결정**: 우선 빌드-타임 방식(Option A) 유지. 변수 추가 빈도가 월 2회 이상이면 Option B(Supabase 메타 테이블) 재검토. M3 이후 운영 데이터로 판단.

- **Q-6 (`quest.enemy` 필드 신설)**: 기획서 §2-2에서 `quest_pools.enemy_name` 신규 컬럼을 가정. 이미 `quest_pools`에 유사 필드(`description`)가 있는지 / 신규 컬럼 추가가 M3 스키마 확장 범위에 포함되는지 확인 필요.
  → **페이즈 3-0-3(`types/quest-narrative.md`) 타입 스펙 작성 시 `quest_pools.enemy_name` 또는 `quest_narratives.enemy_override` 중 어디에 두는 게 맞는지 확정.**

## 다음 단계 후속 안내

**동일 페이즈(1) 남은 산출물**:
- 페이즈 1-2: 연계 퀘스트 시나리오 기획 (`/content-designer`)
- 페이즈 1-3: 지역 변형 기획
- **페이즈 1-4: 퀘스트 서사 템플릿 기획** — 이 문서의 문법·변수 카탈로그를 그대로 사용
- **페이즈 1-5: 이동 선택지 이벤트 기획** — `visibility_expr`, `conditional_result_expr`를 그대로 사용
- 페이즈 1-6: 공존 정책 정의

**후속 페이즈 연결**:
- 페이즈 4-1: `/spec-writer @Docs/content-design/[content]20260423_template_engine.md` — 이 기획서를 구현 명세로 변환

**밸런스 검토 필요 여부**: 없음. 이 문서는 시스템 설계로 수치 결정이 없다.

**벌크 데이터 생성 필요 여부**: 없음. 구체 서사·선택지 텍스트는 페이즈 1-4/1-5에서 기획된 후, 페이즈 3-4/3-5에서 `/data-generator`로 생성.
