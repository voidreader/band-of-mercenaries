# 퀘스트 서사 템플릿 컨텐츠 기획서

> 작성일: 2026-04-24
> 유형: 신규 컨텐츠 (M3 페이즈 1-4)
> 선행 의존: 페이즈 1-1 TemplateEngine(`Docs/content-design/[content]20260423_template_engine.md`), 페이즈 1-2 체인 퀘스트, 페이즈 1-3 지역 변형
> 후속 페이즈 의존: 페이즈 3-0-3(`types/quest-narrative.md` 타입 스펙), 페이즈 3-4(서사 88행 벌크 생성), 페이즈 3-6(일반 퀘스트 200행 유형 재분류 + `enemy_name` 채움), 페이즈 4-4(서사 통합 spec)

## 개요

퀘스트 결과 팝업에 **1~2문장의 상황 서사**를 표시한다. 같은 유형·같은 결과라도 **매번 다른 변주**를 내고, 용병의 이름·트레잇·소속 세력·지역 컨텍스트가 문장 안에 자연스럽게 녹는다. M3의 표어 "**숫자가 아닌 이야기로 결과를 기억한다**"의 구현체다.

이 문서는 **매트릭스 범위(quest_type 6 × result_type 4 확장)**, **스키마(`quest_narratives`)**, **엘리트·변형 섹터 분기 전략**, **대표 용병 선정 규칙 확정(Q-2)**, **pick·톤·길이 정책**, **88행 풀 배분**, **서사 샘플**을 확정한다. 구체 서사 텍스트는 페이즈 3-4에서 data-generator가 생성, 구현 명세는 페이즈 4-4에서 spec-writer가 작성한다.

## 레퍼런스 분석

| 게임 | 참고 포인트 | 차용/변형 |
|------|-----------|----------|
| **Fallen London** | 결과 텍스트가 조건 분기와 품질(Quality)에 따라 변형되며 재방문 시에도 살짝 다르게 읽힘 | 본 풀의 조건 분기 근거. 품질은 트레잇/세력/섹터로 치환 |
| **Darkest Dungeon** | 짧은 나레이션 + 결과 재해석("그가 돌아올 수 없게 됐다" 류 비극 톤) | `greatFail` 비극 톤 차용. 한 문장으로 무게 있게 |
| **Sunless Sea** | 항해 결과에 "장면"을 끼워 넣어 반복 플레이의 피로도를 낮춤 | 반복 퀘스트 피로도 완화 목적으로 pick/행 변형 필요 |
| **RimWorld — 사건 로그** | 캐릭터 이름·상태·사건이 절차적으로 합성된 짧은 문장 | 대표 용병(`merc.*`) + 퀘스트 컨텍스트(`quest.*`) 조합으로 사실적 문장 합성 |
| **Kingdom of Loathing** | 결과 나레이션이 **반 농담 톤** — 본 게임은 판타지 정통 톤이므로 반면교사 | 유머는 labor 유형에서만 살짝 허용 (일상적 가벼움) |

**핵심 설계 원칙**: "**1~2문장에 용병의 이름, 장소, 결과의 질감을 담는다**". 장문 서사는 체인 퀘스트(`chain_quests.description`) 책임. 본 풀은 **범용 반복 변주**.

## 상세 설계

### 1. 매트릭스 범위 — 옵션 β(88행) 확정

#### 1-1. 유형 축

`quest_types` 테이블 현황(2026-04-24 기준, 6유형):

| quest_type | 한글 | 보상 | 시간(분) | 리스크 | 현재 quest_pools 활성 |
|-----------|------|------|---------|-------|-------------------|
| raid | 약탈 | 100 | 60 | 0.30 | ✅ 220행 |
| hunt | 토벌 | 120 | 80 | 0.50 | ✅ 25행 |
| escort | 호위 | 90 | 75 | 0.25 | ✅ 24행 |
| explore | 탐험 | 80 | 70 | 0.20 | ✅ 29행 |
| labor | 노동 | 50 | 60 | 0.05 | ⏳ 0행 (스키마만) |
| survey | 지역조사 | 0 | 180 | 0.10 | ⏳ 0행 (스키마만) |

**raid 220이 비정상적으로 높은 이유**: 일반 퀘스트 200행 전체가 스키마 기본값(`DEFAULT 'raid'`)으로 마이그레이션 흔적을 남겼다. 페이즈 3-6에서 재분류한다.

#### 1-2. 결과 축

`quest.result` enum: `greatSuccess` / `success` / `fail` / `greatFail`. 4값 고정.

#### 1-3. 매트릭스 배분(88행)

| 유형 | 칸 수 | 변형 수 | 소계 | is_elite 확장 | 유형 합계 |
|------|------|--------|------|------------|---------|
| raid | 4 | 4 | 16 | +4 | **20** |
| hunt | 4 | 4 | 16 | +4 | **20** |
| escort | 4 | 4 | 16 | 0 | 16 |
| explore | 4 | 4 | 16 | 0 | 16 |
| labor | 4 | 2 | 8 | 0 | 8 |
| survey | 4 | 2 | 8 | 0 | 8 |
| **계** | 24 | — | 80 | 8 | **88** |

**왜 labor/survey는 칸당 2변형인가**:
- 두 유형은 `quest_pools`에 활성 행이 없고(M3 시점), 도입 M에서 톤이 재확정될 여지가 큼
- labor는 `risk_factor=0.05`로 `greatFail` 실제 발생 빈도가 거의 0 — 변형 다수 투입 비효율
- survey는 기존 지역조사(`InvestigationNotifier`) 별도 슬롯과의 포지셔닝이 아직 불명확

**왜 엘리트 확장은 hunt/raid만 4+4=8인가**:
- 엘리트 몬스터 스폰 로직(`EliteSpawnService.trySpawn`)은 quest_type 무관이나, **서사 차별화 가치**는 전투형(hunt/raid)에 집중
- escort/explore/labor/survey에 엘리트가 붙으면 `is_elite=FALSE` 일반 풀 서사로 fallback. 서사 품질은 약간 떨어지지만 **빈도가 낮아 체감 비용 작음**
- 엘리트 확장도 `greatFail` 포함 4 result 전 칸에 1변형씩 → "엘리트에게 당한 비극" 서사도 커버

#### 1-4. 칸당 변형의 역할

같은 칸(예: `raid × greatSuccess`) 내 4변형이 추구하는 다양성:

1. **톤 폭**: 영웅담형 ↔ 담담한 수행형 ↔ 잔혹한 처단형 ↔ 트릭스터형
2. **주인공 비중**: `merc.*` 전면 등장 ↔ 파티 전체 암시("동료들과 함께") ↔ 적 중심 서술
3. **트레잇 조건**: 무분기 1 + `[if has_trait:...]` 분기 2 + `[if joined_faction:...]` 분기 1
4. **섹터 분기**: 4변형 중 1~2개에 `[if region.sector_type=="ruins|village|hidden"]` 인라인 분기

### 2. 스키마 설계

#### 2-1. `quest_narratives` 신규 테이블

```sql
CREATE TABLE quest_narratives (
  id TEXT PRIMARY KEY,                          -- qn_{type}_{result}_{seq} 규칙
  quest_type TEXT NOT NULL REFERENCES quest_types(id),
  result_type TEXT NOT NULL,                    -- greatSuccess | success | fail | greatFail
  is_elite BOOLEAN NOT NULL DEFAULT FALSE,      -- 엘리트 전용 8행만 TRUE
  template TEXT NOT NULL,                       -- TemplateEngine 원본 템플릿
  weight INT NOT NULL DEFAULT 1,                -- 가중치(1=기본). 실험·튜닝용
  description TEXT,                             -- 내부 메모(변형 의도)
  created_at TIMESTAMP DEFAULT NOW(),

  CONSTRAINT quest_narratives_result_check
    CHECK (result_type IN ('greatSuccess','success','fail','greatFail'))
);

CREATE INDEX idx_quest_narratives_lookup
  ON quest_narratives(quest_type, result_type, is_elite);
```

**설계 판단**:
- `id`를 `seq` 포함 TEXT PK로 잡는다 → operation-bom 편집기에서 "이 행이 어느 칸 어느 번째인지" 파악 쉬움
- `weight`는 지금은 전부 1로 시작하되, 나중에 "이 변형이 특별히 자주 보이게" 원하면 조정. 스키마 여유
- `is_elite`는 BOOLEAN으로 단순화. 엘리트 유형 구분(보통/유니크)은 `quest.elite_name` 변수 치환으로 문장 내 처리
- result_type은 CHECK 제약으로 오타 방지

#### 2-2. `quest_pools.enemy_name` 컬럼 추가 (Q-6 해소)

```sql
ALTER TABLE quest_pools ADD COLUMN enemy_name TEXT NULL;
```

**사유**:
- `quest.enemy` 변수(TemplateEngine 카탈로그 §2-2)가 `quest_pools.enemy_name`에서 바인딩
- nullable → **점진 채움** 허용. 페이즈 3-6 재분류 작업과 병행하여 한 번에 값 세팅
- 템플릿에서는 `{quest.enemy|적}` fallback 문법으로 안전 처리:

```
{merc.name}이 {quest.enemy|적}을 제압했다.
```

enemy_name이 NULL이면 "적"으로 렌더. 서사 풀 88행은 enemy_name 채움 진도와 무관하게 즉시 작동.

**엘리트 전용 8행은 `{quest.elite_name}`을 우선 사용** (is_elite=TRUE 행은 이 변수를 쓰는 것이 관례):

```
{merc.name}이 [pick]거대한|사나운[/pick] {quest.elite_name}을 베어 넘겼다.
```

#### 2-3. 선택 알고리즘

```
입력: ActiveQuest (type, result, is_elite, faction_tag, sector_type), TemplateContext

1. candidates ← quest_narratives WHERE
     quest_type = ctx.quest.type
     AND result_type = ctx.quest.result
     AND is_elite = ctx.quest.is_elite

2. IF candidates.isEmpty AND ctx.quest.is_elite = TRUE:
     // 엘리트 행이 없으면 일반 풀로 fallback
     candidates ← WHERE ... AND is_elite = FALSE

3. IF candidates.isEmpty:
     return FALLBACK_TEMPLATE  // 컴파일타임 1개 상수
         = "{merc.name}이 {region.name}에서 임무를 마쳤다."

4. selected ← weighted_random(candidates, by: weight)
5. rendered ← TemplateEngine.render(selected.template, ctx)
6. return rendered
```

**FALLBACK_TEMPLATE**: 데이터가 완전히 비는 악성 상황에서도 팝업이 비어 보이지 않도록 코드 상수. 이 상수는 `QuestNarrativeService` Dart 코드에 고정.

### 3. 대표 용병 선정 규칙 (Q-2 확정)

**(b) 파티 기여 1위** 확정.

```dart
Mercenary selectProtagonist(List<Mercenary> party, String questType) {
  if (party.length == 1) return party.first;

  final weights = QuestCalculator.statWeights[questType];
  // 예: raid → {str: 0.70, int: 0.0, vit: 0.15, agi: 0.15}

  return party.reduce((a, b) {
    final ca = a.effectiveStr * weights.str
             + a.effectiveIntelligence * weights.int
             + a.effectiveVit * weights.vit
             + a.effectiveAgi * weights.agi;
    final cb = b.effectiveStr * weights.str
             + b.effectiveIntelligence * weights.int
             + b.effectiveVit * weights.vit
             + b.effectiveAgi * weights.agi;
    return ca >= cb ? a : b;
  });
}
```

**엣지 케이스 처리**:
- 동률: `Mercenary.id`의 lexical 순서로 tie-break (결정론적)
- 파티 = [] (빈 파티): 절대 발생 안 함. QuestCompletionService 단계에서 가드 있음. 만약 발생하면 FALLBACK_TEMPLATE 직행
- 파견 중 사망: 보상 팝업 시점에는 아직 로스터에 존재. 서사 렌더에 영향 없음. 로그 기록 시점에도 살아있는 id로 기록

**labor/survey의 경우 대표 용병**:
- labor는 보통 1명 파견이 합리적(저보상·저위험). 1인 파견이면 선택 고민 없음
- 2인 이상 파견 시 기본 규칙(파티 기여 1위) 적용하되, labor는 statWeights가 없을 수 있음 → **labor/survey 전용 기본 가중치** 추가:
  - labor: `{str: 0.25, int: 0.25, vit: 0.25, agi: 0.25}` — 균등(단순 작업)
  - survey: `{str: 0.10, int: 0.40, vit: 0.20, agi: 0.30}` — 관찰·기민함 우선

이 가중치는 페이즈 4-4 spec에서 `QuestCalculator.statWeights` 확장으로 반영.

### 4. TemplateEngine 변수 확장 — `region.sector_type`

페이즈 1-1 기획서(§2-3)에 **1필드 후속 추가**:

```
| region.sector_type | string\|null | "village"/"ruins"/"hidden"/null | 변형 섹터 유형. 변형되지 않은 섹터는 null |
```

- 네임스페이스 총 필드: 29 → **30**
- `null` 가능 — 본 풀에서 `[if region.sector_type == "ruins"]`로 쓸 때 null은 자동 false
- operation-bom 카탈로그 TS 파일(`template_variables.ts`)과 Dart 자동 생성 카탈로그 동시 갱신 (페이즈 4-1 spec 반영)

**사용 예시**:
```
[if region.sector_type == "ruins"]
{merc.name}은 고대 수호 장치의 경보를 피해 {quest.enemy|적}을 제압했다.
[elif region.sector_type == "village"]
{merc.name}은 마을 주민들의 환호 속에 {quest.enemy|적}을 쫓아냈다.
[else]
{merc.name}은 {quest.enemy|적}을 제압했다.
[/if]
```

### 5. 엘리트 분기 전략 — 옵션 D 상세

#### 5-1. 엘리트 전용 8행 분포

| 세부 | raid | hunt |
|------|------|------|
| greatSuccess | 1 | 1 |
| success | 1 | 1 |
| fail | 1 | 1 |
| greatFail | 1 | 1 |

총 8행. 모두 `is_elite=TRUE`. 템플릿에서 `{quest.elite_name}`을 적극 사용.

#### 5-2. 엘리트 서사 톤 차별화

| result | 일반 풀 톤 | 엘리트 풀 톤 |
|--------|----------|-----------|
| greatSuccess | 영웅담 | **전설 격파** — "{quest.elite_name}의 이름은 오늘로 끝이다" |
| success | 담담한 완수 | **간신히 제압** — "힘겹게 {quest.elite_name}을 끌어내렸다" |
| fail | 부상·후퇴 | **공포 퇴각** — "{quest.elite_name}의 기세를 끊지 못했다" |
| greatFail | 비극 | **전설의 대가** — "{quest.elite_name} 앞에서 동료를 잃었다" |

유니크 엘리트(`is_unique=TRUE`)는 별도 분기 없이 `{quest.elite_name}`만 바꿔 렌더. "폐광의 울부르" 같은 고유명사가 자연 치환됨.

#### 5-3. escort/explore/labor/survey에 엘리트가 붙은 경우

- fallback 경로 발동: `is_elite=FALSE` 일반 풀에서 선택. 단 렌더 시 `{quest.elite_name}`이 context에 존재하므로 **문장에 쓰진 않지만 사용 가능**
- escort/explore의 경우 엘리트 서사 부재가 체감 손실 — 필요 시 M4 이후 확장 고려(본 M3 범위 외)

### 6. 섹터 변형 인라인 분기 전략

#### 6-1. 분기 적용 대상 행

**모든 88행에 섹터 분기를 강제하지 않는다**. 규칙:

- **quest_type별 4변형 중 1~2행**에 `[if region.sector_type=="..."]` 인라인 분기 포함
- 분기 가능한 섹터 유형은 기획서(페이즈 1-3) 기준 3종: village / ruins / hidden
- **escort/explore**는 섹터 분기 가치가 높음(탐사·호송 서사가 섹터 맥락과 강결합)
- **raid/hunt**는 섹터 분기가 중간 수준(전투 서사는 섹터 유형에 덜 의존)
- **labor/survey**는 변형 수가 2개뿐이므로 섹터 분기 없음(생활·관찰 톤에 섹터 독립)

#### 6-2. 섹터 톤 가이드

| sector_type | 서사 톤 키워드 |
|-------------|-------------|
| village | 주민·환호·의뢰·공동체·마을 중심부 |
| ruins | 고대·경보·수호 장치·침묵·먼지 |
| hidden | 은둔·지도 없는·별빛·침묵 속 발견 |

### 7. pick 정책

| 항목 | 규칙 |
|------|------|
| 행당 pick 블록 수 | 최대 **2개** |
| pick 후보 수 | **2~4개** (TemplateEngine 상한 10보다 엄격) |
| 88행 중 pick 포함 행 비율 | **약 50%** (목표: 44행 내외) |
| pick 중첩 | 금지 (TemplateEngine MVP 제약) |
| 시드 | 페이즈 4-4에서 결정(Q-3 권장: ActiveQuest 완료 시점 렌더 결과를 Hive 저장) |

**pick 사용 의도**:
- 어휘 변주 ("일격에|한 호흡에|눈 깜짝할 새에")
- 질감 변주 ("잔돈|품삯|수고의 대가")
- 주체 변주 ("용병들은|일행은|동료들은")

**안티 패턴 (금지)**:
- 서사 결과 자체를 pick으로 분기 (예: "승리|패배") — 이건 result_type 분류 오류
- 고유명사 pick (예: 적 이름을 pick으로 변주) — enemy_name 컬럼 책임

### 8. 서사 길이·톤 가이드

#### 8-1. 길이 규격

| 항목 | 값 |
|------|---|
| 문장 수 | 1~2문장 |
| 자 수 | 40~120자 (공백 포함) |
| 최대 자 수 상한 | 150자 (렌더 후 기준, 넘으면 편집기 경고) |

완료 팝업 UI(`QuestResultDialog`) 기준 2줄 이내.

#### 8-2. 공통 톤 규칙

- **문어체 기본** — "~했다" 종결. 현대 구어체 금지("조졌다", "쎼게 털었다")
- **판타지 정통 톤** — 현대어·영단어·전문 용어 금지
- **수치 노출 최소화** — 골드·XP 등은 팝업의 보상 섹션이 별도 표시. 서사에는 필요 최소한만(`world.gold` 등)
- **레퍼런스 고유명사 금지** — 타 게임 지명·인명·종족명 차용 금지(저작권 회피)

#### 8-3. result_type별 톤 매트릭스

| result | 권장 톤 | 전형적 표현 | 금지 표현 |
|--------|--------|----------|---------|
| greatSuccess | 영웅담·대활약·압도·일방적 | "전투의 교본 같았다", "{merc.name}이 기세를 끊었다" | 과장된 허풍("혼자 백명을"), 만화적 연출 |
| success | 담담한 완수·계획대로·안정 | "임무를 마쳤다", "{merc.name}은 약속된 몫을 챙겼다" | 감정 과잉, 영웅 찬양 |
| fail | 아쉬움·부상·후퇴·간신히 | "간신히 물러났다", "상처를 안고 귀환했다" | 사망 암시, 완전 궤멸 |
| greatFail | 비극·사망 암시·세계 압박 | "돌아오지 못한 이가 있다", "{region.name}이 이름 하나를 삼켰다" | 유머, 과장된 설명, 수치 |

#### 8-4. 유형별 톤 구체화

| quest_type | 톤 중심 |
|-----------|--------|
| raid(약탈) | 기습·속도·이득 중심. 때때로 은근한 양심 갈등 |
| hunt(토벌) | 의무·처단·경계·사냥꾼의 눈 |
| escort(호위) | 책임·보호·귀환·의뢰인 만족 |
| explore(탐험) | 발견·미지·지도·흔적 |
| labor(노동) | 일상·담담·품삯·땀·하루 |
| survey(지역조사) | 관찰·기록·수첩·조심스러움 |

labor는 유일하게 **가벼운 유머** 허용 (예: "발바닥이 저렸다"). 다른 유형은 유머 금지.

### 9. 서사 샘플 (16개 프리뷰)

**범례**: `[pick]` 블록은 렌더 시 하나 선택. `[if]` 블록은 조건 충족 시에만 렌더.

#### 9-1. raid (약탈) × 4 result

**greatSuccess (변형 1/4)**
```
{merc.name}이 [pick]기습을 주도하며|앞장서서[/pick] {quest.enemy|적}의 대열을 무너뜨렸다.
[if has_trait:berserker]피에 굶주린 눈빛이 모두를 질리게 했다.[/if]
```

**success (변형 2/4)**
```
{region.name}에서의 약탈은 계획대로 진행됐다. {merc.name}은 노획물을 [pick]침착하게|빠르게[/pick] 정리했다.
```

**fail (변형 3/4)**
```
[if region.sector_type == "ruins"]
경비가 허술할 줄 알았으나 고대 장치가 깨어났다. {merc.name}은 상처를 안고 물러났다.
[else]
{quest.enemy|적}의 대비가 생각보다 단단했다. {merc.name}은 간신히 귀환했다.
[/if]
```

**greatFail (변형 4/4)**
```
{region.name}의 어둠 속에서 {merc.name}의 [pick]비명은|발소리는[/pick] 돌아오지 못했다.
```

#### 9-2. hunt (토벌) × 4 result

**greatSuccess (변형 1/4)**
```
{merc.name}은 {quest.enemy|적}의 숨통을 [pick]단번에|차갑게[/pick] 끊었다.
[if joined_faction:silver_company]은빛 깃발 아래의 처단은 흔들림 없었다.[/if]
```

**success (변형 2/4)**
```
{quest.enemy|적}의 추격은 길었으나, {merc.name}은 약속된 토벌을 완수했다.
```

**fail (변형 3/4)**
```
{quest.enemy|적}은 끈질겼다. {merc.name}은 [pick]부상을 입고|한쪽 팔을 끌며[/pick] 후퇴했다.
```

**greatFail (변형 4/4)**
```
{quest.enemy|적}의 이빨 앞에 {merc.name}의 이름이 {region.name}의 바람에 실려 사라졌다.
```

#### 9-3. escort (호위) × 4 result

**greatSuccess (변형 1/4)**
```
{merc.name}은 의뢰인을 단 한 방울의 피도 흘리지 않고 호송했다. [if has_trait:guardian]본능이 길을 열었다.[/if]
```

**success (변형 2/4)**
```
[if region.sector_type == "village"]
마을 어귀에 도착했을 때 의뢰인은 {merc.name}의 손을 오래 쥐었다.
[else]
호송은 [pick]무탈히|조용히[/pick] 끝났다. {merc.name}은 약속된 몫을 받았다.
[/if]
```

**fail (변형 3/4)**
```
습격이 있었다. {merc.name}은 의뢰인을 지켰으나 [pick]상처 입었고|지쳤고[/pick] 목적지는 더 멀어졌다.
```

**greatFail (변형 4/4)**
```
{region.name}의 길목에서 의뢰인도, {merc.name}도 약속의 자리에 닿지 못했다.
```

#### 9-4. explore (탐험) × 4 result

**greatSuccess (변형 1/4)**
```
[if region.sector_type == "hidden"]
{merc.name}은 지도에 없던 길을 밟고, 한 번도 보지 못한 풍경을 가지고 돌아왔다.
[else]
{merc.name}은 {region.name}의 깊은 곳에서 [pick]귀중한|낯선[/pick] 흔적을 들고 귀환했다.
[/if]
```

**success (변형 2/4)**
```
발자국을 따라간 {merc.name}은 [pick]수첩 한 권치의|두 손 가득한[/pick] 기록을 남겼다.
```

**fail (변형 3/4)**
```
{region.name}의 [pick]험한 지형에|낯선 길에[/pick] 발목 잡혀, {merc.name}은 임무를 접고 돌아왔다.
```

**greatFail (변형 4/4)**
```
{region.name}의 안개 너머로 {merc.name}의 발자국이 끊겼다. 돌아온 것은 [pick]침묵뿐이었다|바람뿐이었다[/pick].
```

#### 9-5. labor (노동) × 4 result (각 2변형의 샘플 1개씩)

**greatSuccess**
```
{merc.name}은 오늘치 일감을 해가 지기 전에 해치우고 덤까지 챙겼다.
```

**success**
```
{merc.name}은 하루치 일감을 마치고 {world.gold}G의 [pick]잔돈을|품삯을[/pick] 벌었다.
```

**fail**
```
{merc.name}은 일감을 절반만 끝낸 채 [pick]발바닥이 저린 채|녹초가 된 채[/pick] 돌아왔다.
```

**greatFail**
```
{merc.name}은 일하다 [pick]손을 삐끗해|크게 넘어져[/pick] 하루를 통째로 날렸다.
```

#### 9-6. survey (지역조사) × 4 result (각 2변형의 샘플 1개씩)

**greatSuccess**
```
{merc.name}은 {region.name}의 구석까지 훑고, 수첩 한 권을 빼곡히 채워 돌아왔다.
```

**success**
```
{merc.name}은 의뢰받은 구간을 조용히 돌아보고, 필요한 것을 [pick]기록해|그려[/pick] 두었다.
```

**fail**
```
날씨가 궂었다. {merc.name}은 절반의 기록만 들고 돌아왔다.
```

**greatFail**
```
{merc.name}은 길을 잃었다. 돌아온 수첩의 페이지는 [pick]젖어 있었고|비어 있었고[/pick], 아무것도 읽히지 않았다.
```

#### 9-7. 엘리트 전용 샘플 (is_elite=TRUE) — 2개

**hunt × greatSuccess (엘리트)**
```
{merc.name}은 {quest.elite_name}의 이름을 오늘로 끝냈다. [if joined_faction:silver_company]은빛 깃발 아래의 전설이 하나 더 생겼다.[/if]
```

**raid × greatFail (엘리트)**
```
{quest.elite_name}의 눈빛 한 번에 {region.name}의 흙이 붉어졌다. {merc.name}의 이름은 돌아오지 않았다.
```

### 10. 체인 퀘스트와의 독립성

페이즈 1-2 연계 퀘스트(`chain_quests`)는 자체 `description` 필드로 단계별 서사를 직접 보유한다. **본 풀은 체인 퀘스트에 적용되지 않는다**.

판정 로직(페이즈 4-4 spec에서 상세화):
```
IF activeQuest.chainId IS NOT NULL:
  // 체인 퀘스트 → chain_quests.description (이미 저장된 템플릿) 렌더
ELSE:
  // 일반·세력전용·엘리트·변형섹터 퀘스트 → quest_narratives 풀 선택
```

이 분리로 체인 퀘스트의 서사 무게(스토리)와 반복 퀘스트의 서사 리듬(변주)을 구분한다.

### 11. 변형 섹터 퀘스트 호환성 (페이즈 1-3 연계)

페이즈 1-3 지역 변형에서 설계한 34개 전용 퀘스트(village 12 / ruins 12 / hidden 10)는 모두 `quest_type` 중 하나를 가진다. 따라서:

- 완료 시 본 풀의 `(quest_type, result_type)` 매트릭스에서 선택됨 (자동 호환)
- `region.sector_type` 인라인 분기가 활성화되어 섹터 톤이 서사에 반영됨
- 별도 전용 풀 불필요 → 유지보수 단순

### 12. 세력 전용 퀘스트와의 호환성 (M1 연계)

세력 전용 퀘스트 98행도 동일하게 본 풀 사용. 다만 서사에 세력 깃발·이름을 반영하려면 `[if joined_faction:...]` 분기가 필요.

**세력 톤 분기 예시**:
```
{merc.name}은 {quest.enemy|적}의 숨통을 끊었다.
[if joined_faction:silver_company]은빛 깃발 아래의 처단은 흔들림 없었다.
[elif joined_faction:crimson_pact]피의 맹약은 오늘 밤도 채워졌다.
[/if]
```

88행 중 **약 10~15행**에 `joined_faction` 분기 포함 권장. 모든 행에 넣으면 피로도 상승.

## MVP vs 확장 가능 지점

| 범주 | MVP (본 문서) | 확장 가능 지점 |
|------|--------------|-------------|
| quest_type 커버 | raid/hunt/escort/explore (4) + labor/survey 최소(2) | labor/survey 도입 M에서 칸당 4변형으로 보강 |
| is_elite 분기 | hunt/raid만 전용 8행 | escort/explore 엘리트 확장 (M4+) |
| 섹터 분기 | `region.sector_type` 인라인 | 섹터 전용 풀 분리 (M6+) |
| 세력 톤 | `joined_faction` 인라인 분기, 약 10~15행 | 세력별 전용 서사 풀 (M4 세력 확장 연계) |
| 주인공 | 파티 기여 1위 1명 | 파티 전체 서사(`party[*]` 참조, TemplateEngine v2) |
| pick | 행당 2개, 후보 2~4개 | 가중치 pick(`[pick weighted]A:3|B:1[/pick]`) |
| 저장·재현 | 페이즈 4-4에서 결정 (Q-3 권장: Hive 저장) | 렌더 이력 분석·A/B 테스트 (운영 통계) |

## 현재 시스템과의 연관

### 영향받는 기존 시스템

| 시스템 | 영향 내용 |
|--------|---------|
| `QuestCompletionService` | 완료 시점에 대표 용병 선정 + `QuestNarrativeService.pick(ctx)` 호출 → 렌더 문자열 획득 → `ActiveQuest.renderedNarrative` 필드(페이즈 4-4에서 추가)에 저장 |
| `QuestResultDialog` | 팝업 상단에 서사 영역 추가 (기존 보상 섹션 위). 페이즈 4-4 UI spec |
| `QuestCalculator.statWeights` | labor/survey 가중치 추가 (`{str: 0.25, int: 0.25, vit: 0.25, agi: 0.25}` / `{str: 0.10, int: 0.40, vit: 0.20, agi: 0.30}`). 대표 용병 선정 로직 의존 |
| `ActiveQuest` | `renderedNarrative: String?` HiveField 추가 (페이즈 4-4) — 재렌더 방지용 |
| `ActivityLog` | 퀘스트 결과 로그 메시지에 기존 요약문 대신 `renderedNarrative` 표시 옵션(페이즈 4-4 결정) |
| TemplateEngine(페이즈 1-1) | `region.sector_type` 필드 1개 추가 (29→30). TS 카탈로그 + Dart 자동 생성 카탈로그 갱신 |
| `quest_pools` | `enemy_name TEXT NULL` 컬럼 추가. 재분류 작업(페이즈 3-6)과 병행 |
| operation-bom 편집기 | `quest_narratives` 테이블 편집 UI(신규). TemplateEditor 컴포넌트 재사용 |

### 신규 인프라 (페이즈 4-4 spec 대상)

| 파일 | 용도 |
|------|------|
| `lib/features/quest/domain/quest_narrative_service.dart` | 서사 풀 선택·렌더 서비스. `pick(ctx)` / `pickForChain(...)` 분기 |
| `lib/core/models/quest_narrative_data.dart` | Freezed 모델 (id/quest_type/result_type/is_elite/template/weight/description) |
| `QuestNarrativeService.FALLBACK_TEMPLATE` | 코드 상수 |

### 호환성 리스크

- **낮음**: `quest_narratives` 신규 테이블 — 기존 데이터 흐름에 역영향 없음. Supabase SyncService 테이블 목록에 1건 추가
- **낮음**: `quest_pools.enemy_name` nullable 추가 — 기존 쿼리 영향 없음
- **중간**: `QuestCompletionService`가 대표 용병 선정 로직을 추가로 담당. 성능 영향은 없으나 파견 결과 처리 순서가 "결과 계산 → 대표 용병 선정 → 서사 렌더 → 팝업 표시"로 확장. 페이즈 4-4 spec에서 단위 테스트 대상
- **낮음**: TemplateEngine 카탈로그 29→30 확장 — 페이즈 4-1 spec에서 자동 생성 스크립트 1줄 변경

## 구현 우선순위 제안

**우선순위: 높음 (M3 중심 체감 기능)**

사유:
- M3의 감성 축 중 하나: "반복되는 퀘스트가 숫자 이상의 기억을 남긴다"
- 페이즈 1-1 TemplateEngine의 첫 번째 실사용 영역 — 엔진 검증 기회
- labor/survey 도입 M에서도 본 풀 인프라 그대로 활용 가능(재사용성)

**M3 내 착수 순서 권장**:
1. 페이즈 3-0-3 타입 스펙 `types/quest-narrative.md` 작성 (본 문서 스키마 그대로 반영)
2. 페이즈 3-4 data-generator 88행 벌크 생성
3. 페이즈 3-6 일반 퀘스트 200행 재분류 + `enemy_name` 채움 (병렬 가능)
4. 페이즈 4-4 구현 명세 작성 → 구현

## data-generator 지시사항

본 기획서는 **한 개의 data-generator 호출 + 한 개의 Supabase 직접 UPDATE 트랙**을 유발한다.

### (A) `quest_narratives` 88행 벌크 생성

- **대상 타입**: `quest-narrative` (신규 — 타입 스펙 페이즈 3-0-3 선행)
- **대상 테이블**: `quest_narratives` (신규 테이블)
- **생성 수량**: **88행**
  - raid 20 (일반 16 + 엘리트 4)
  - hunt 20 (일반 16 + 엘리트 4)
  - escort 16
  - explore 16
  - labor 8
  - survey 8
- **톤/세계관 가이드**:
  - §8 톤 매트릭스 준수
  - §9 샘플 스타일 참조 (과장 금지, 문어체 기본)
  - labor/survey 특수 톤 준수 (일상·관찰)
  - 레퍼런스 고유명사·현대어 금지
- **구조적 제약**:
  - `id` 명명: `qn_{type}_{result_abbr}_{seq:03d}` (예: `qn_raid_gs_001`, `qn_hunt_elite_gf_004`)
    - result_abbr: gs / s / f / gf
    - elite 행은 `{type}_elite_{result_abbr}_{seq}`
  - `template` 1~2문장, 40~120자 (렌더 전)
  - `weight` 기본 1
  - `description`에 변형 의도 한 줄 기록 (예: "트레잇 분기형", "섹터 분기형")
  - pick 포함 행 비율 약 50% (목표 44행)
  - `[if ...]` 분기 포함 행 비율 약 30% (트레잇 10~15 + 세력 10~15 + 섹터 10~12)
  - TemplateEngine 제약 준수(중첩 2단계 이하, pick 2~10개, pick 중첩 금지, 이스케이프 규칙)
- **수치 출처**: 밸런스 검토 불필요 (이 영역은 수치가 아닌 서사)
- **특수 요구**:
  - **변수 사용 분포 커버**: `merc.name` 전 행 필수, `merc.job`/`merc.level`/`merc.state` 30~40%, `quest.enemy` raid/hunt 우선, `quest.elite_name` 엘리트 행 전원, `region.name` 50% 이상, `region.sector_type` 인라인 분기 10~12행, `world.gold` labor에 1~2행, `joined_faction` 분기 10~15행, `has_trait` 분기 10~15행
  - 같은 칸(type+result) 4변형은 **서로 다른 톤 축**을 점유 — §1-4 변주 역할 참조
  - 엘리트 8행은 `is_elite=TRUE`, `{quest.elite_name}` 사용 의무

### (B) Supabase 직접 트랙 — 스키마 변경 + 일반 퀘스트 200행 재분류

이 트랙은 페이즈 3-6에서 Supabase MCP로 직접 처리(data-generator 경유).

#### B-1. 스키마 변경(DDL)

```sql
ALTER TABLE quest_pools ADD COLUMN enemy_name TEXT NULL;

CREATE TABLE quest_narratives (...); -- §2-1 DDL 참조
CREATE INDEX idx_quest_narratives_lookup ON quest_narratives(quest_type, result_type, is_elite);
```

#### B-2. 일반 퀘스트 200행 유형 재분류

- **대상**: `quest_pools WHERE is_faction_exclusive = FALSE` 200행
- **방법**:
  1. data-generator에 `quest-retagging` 타입으로 200행의 `name` + 기존 `description`을 전달
  2. 4 유형(raid/hunt/escort/explore) 중 자연 정합되는 것으로 재분류
  3. 동시에 `enemy_name` 값도 생성(퀘스트명·적 성격 근거)
- **목표 분포** (기획자 판단 — balance-designer 호출 없음):
  - raid: 25~35% (50~70행)
  - hunt: 25~35% (50~70행)
  - escort: 15~25% (30~50행)
  - explore: 15~25% (30~50행)
- **검증**: 재분류 후 GROUP BY type_id 쿼리로 분포 확인 후 UPDATE 일괄 실행
- **특수 요구**:
  - 재분류 작업은 페이즈 3-4(서사 88행 생성)와 **병렬 가능**
  - MCP `apply_migration`(DDL) + `execute_sql`(UPDATE) 경로 활용

## 오픈 질문

- **Q-1 (labor/survey 대표 용병 가중치)**: §3의 임시 가중치가 적절한지. labor는 균등이 맞나? 주둔지 스탯이 STR에 편중된 용병이 항상 선정되는 편향 우려. → **페이즈 4-4 spec 작성 시 구현 확인**. 대안: labor/survey는 대표 용병 = **최고 레벨**(옵션 a)로 단순화

- **Q-2 (지역 조사와 survey의 관계)**: 기존 지역조사(`InvestigationNotifier`)는 리전 슬롯 1개. survey는 quest_pools 행으로 등장. 두 시스템이 공존하는가, 통합되는가? → **현 시점: 공존 가정**. survey 퀘스트는 퀘스트 슬롯에서 파견, 지역조사는 별도 슬롯. 통합은 미래 M 검토

- **Q-3 (세력 톤 분기 적용 범위)**: `[if joined_faction:...]` 분기 포함 행을 88 중 10~15 정도로 잡았는데, 14개 세력 전부 커버 안 됨. 특정 세력(silver_company, crimson_pact 등)만 분기하고 나머지는 일반 톤 유지할지, 모든 세력을 균등 커버할지. → **페이즈 3-4 data-generator 생성 시점**에 세력 대표성(가입자 체감 빈도) 기준으로 2~4개 세력 중심 분기. 나머지는 일반 톤 fallback

- **Q-4 (pick 시드 재현)**: 페이즈 1-1 Q-3와 동일. 활동 로그 재조회 시 같은 문장이 보이려면 렌더 결과를 저장해야 함. → **페이즈 4-4 spec에서 확정**. 권장: `ActiveQuest.renderedNarrative: String?` HiveField 추가(완료 시점 1회 렌더 후 저장). 활동 로그는 해당 문자열만 표시

- **Q-5 (enemy_name 미채움 기간 UX)**: 페이즈 3-6 재분류 전까지는 `{quest.enemy|적}`이 대부분 "적"으로 렌더됨. 초기 사용자 체감이 단조로울 수 있음. → **페이즈 3-6 우선순위 상향**. 서사 풀 88행 생성과 **동시 진행** 권장

- **Q-6 (엘리트 fallback 품질)**: escort/explore/labor/survey에 엘리트가 붙으면 일반 풀 서사가 렌더됨. `{quest.elite_name}`이 컨텍스트에 있어도 서사에 쓰이지 않음. 유저는 "엘리트 퀘스트 완료했는데 서사에 이름이 없다"고 느낄 수 있음. → **권장**: escort/explore/labor/survey 일반 풀 88행 중 각 1~2행에 `[if quest.is_elite]{quest.elite_name}의 기세가 남아있었다.[/if]` 정도의 가벼운 인라인 분기 포함. 페이즈 3-4 생성 시 반영

- **Q-7 (`is_elite` 전용 8행의 quest.enemy 사용 여부)**: 엘리트 행은 `quest.elite_name`을 쓰므로 `quest.enemy`는 안 쓴다고 했으나, 엘리트가 거느리는 부하 묘사에는 `quest.enemy`가 여전히 유용 (예: "엘리트와 그가 이끄는 {quest.enemy|무리}를 처단했다"). → **허용**. 페이즈 3-4 생성 가이드에 "엘리트 행도 quest.enemy 자유 사용 가능" 명시

- **Q-8 (가중치 1 기본 유지 vs 초기 차등)**: 모든 행 weight=1로 시작하면 균등 노출. 초기 데이터에서 특정 변형(예: 가장 톤이 안정된 것)에 weight=2를 줘서 "무난한 변형이 자주 나오게"할지. → **권장**: 전부 1로 시작. 운영 중 유저 피드백(변형이 어색/과격한 경우) 보고 조정

## 다음 단계 후속 안내

**동일 페이즈(1) 남은 산출물**:
- 페이즈 1-5: 이동 선택지 이벤트 10~15종 (`visibility_expr`, `conditional_result_expr`, 트레잇 숨겨진 선택지)
- 페이즈 1-6: 공존 정책 정의 (파견 화면 정렬·강조·UI 슬롯 규칙 — 본 풀의 렌더 서사 영역도 UI 규칙 대상)

**후속 페이즈 연결**:
- 페이즈 3-0-3: `/data-generator types/quest-narrative.md` 타입 스펙 선행 작성
- 페이즈 3-4: `/data-generator quest-narrative --brief @Docs/content-design/[content]20260424_quest_narratives.md` 88행 생성
- 페이즈 3-6: Supabase MCP로 `quest_pools` 일반 200행 재분류 + `enemy_name` 채움(DDL: `ALTER TABLE quest_pools ADD COLUMN enemy_name TEXT NULL;` 먼저 적용)
- 페이즈 4-1 반영: `region.sector_type` 변수 1필드 TemplateEngine 카탈로그 확장 (기존 기획서 §2-3 후속 갱신)
- 페이즈 4-4: `/spec-writer @Docs/content-design/[content]20260424_quest_narratives.md` — 본 기획서를 구현 명세로 변환 (TemplateEngine 구현 선행 필요)

**밸런스 검토 필요 여부**: **없음.** 본 문서는 서사 설계로 수치 결정이 없다. 일반 퀘스트 재분류 목표 분포(raid 25~35% 등)는 기획 판단으로 확정 — balance-designer 호출 불필요.

**벌크 데이터 생성 필요 여부**: **예.** 페이즈 3-0-3 타입 스펙 선행 후 페이즈 3-4에서 data-generator 호출.
