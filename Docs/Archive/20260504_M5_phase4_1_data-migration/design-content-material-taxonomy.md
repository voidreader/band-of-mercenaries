# 재료 분류 체계와 희귀도 규칙 컨텐츠 기획서

> 작성일: 2026-05-04
> 유형: 신규 컨텐츠 (M5 페이즈 1 — 산출물 1/4)
> 선행 문서:
> - `Docs/content-design/[content]20260418_item_taxonomy.md` — 아이템 분류 체계 (M2a, 3대 카테고리 확정)
> - `Docs/content-design/[content]20260418_essence_system.md` — 정수 시스템 (소모품 카테고리 사용 예시)
> - `Docs/roadmap/master_roadmap.md` 942~1023행 — M5 #포함 시스템 / #작업 상세
> 후속 산출물:
> - 페이즈 1 #2 — 시작 거점 전용 재료 8~12개 + 드랍 출처 매핑표 (본 문서의 slot/tier 규약 사용)
> - 페이즈 1 #3 — 초반 제작 레시피 8~12개 + 첫 제작 목표 3개
> - 페이즈 1 #4 — 인벤토리 재료 탭 + 대장간 제작 UI 컨셉

---

## 개요

M5 "재료와 제작" 마일스톤 인프라의 **최상위 분류 체계 확장**을 확정한다. M2a에서 정의한 3대 카테고리(개인 장비 / 용병단 장비 / 소모품)에 **신규 `category=material` 4번째 카테고리**를 추가하고, 그 안의 slot 5종(광석·가죽·약초·유물 파편·몬스터 부산물)을 정의한다. 희귀도는 기존 `tier(T1~T5)` 컬럼을 "수치 강도 + 획득 희소성"의 통합 의미로 재해석하여 추가 컬럼 없이 사용한다.

본 문서가 확정하는 것:
- **신규 카테고리** `material` 도입 (effect_json은 빈 객체)
- **5종 slot** 정의 (`material_ore`/`material_hide`/`material_herb`/`material_relic_fragment`/`material_monster_part`)
- **지역 특산품 메타** — 신규 컬럼 `items.region_exclusive INTEGER NULL`로 분리
- **희귀도 = 기존 tier 재사용** (T1~T5 색상 체계 그대로)
- **재료 vs 정수 vs 장비 vs 소모품의 4분류 경계** 명확화
- **인벤토리 4탭 구조** 권고 (개인장비/용병단장비/정수/재료)
- **스택 상한 999** (Melvor 패턴, 코드 상수)
- **일반 소모품(회복 포션 등) M5 미도입** 정책

본 문서가 확정하지 않는 것 (후속 페이즈 위임):
- 시작 거점 더스트빌의 구체 재료 8~12종 명칭·출처 — 페이즈 1 #2
- 제작 레시피 — 페이즈 1 #3
- 인벤토리/대장간 UI — 페이즈 1 #4
- 드랍률·제작 시간 곡선 — 페이즈 2

---

## 레퍼런스 분석

### Melvor Idle — Bank의 Tab 분리와 스택 상한

- Bank UI가 Equipment / Consumables / Materials / Currency 등의 명시적 탭으로 분리됨. Bank slot당 수량 상한 999가 표준.
- **차용 포인트**: 인벤토리 4탭 구조(개인장비/용병단장비/정수/재료)와 스택 상한 999를 그대로 가져온다. "스택 가능한 입력재"와 "효과 발동 아이템"의 UX 차이를 탭 분리로 명확화.

### Path of Exile — Currency·Material·Equipment의 효과 축 분리

- 통화(Currency)·소모품(Map Fragment)·장비(Equipment)가 모두 별도 효과 축을 가지며, 인벤토리에서도 별도 탭으로 분리된다. 통화는 "조합 입력"이라 효과 자체가 없고, 장비는 "장착 시 효과"가 있다.
- **차용 포인트**: 본 게임의 재료(material)도 **효과 자체를 갖지 않는** 입력재로 정의. effect_json을 비운다. 정수(consumable)·장비(equipment)와 효과 축을 완전히 분리하여 밸런스 검토 시 독립 변수로 다룬다.

### Diablo / Path of Exile — 등급 색상의 게임 전체 일관성

- 장비 등급(노말/매직/레어/유니크)과 재료 희소성(Common/Magic/Rare)이 **동일 색상 체계**를 공유. 플레이어가 인벤토리에서 색만 보고 가치를 인지.
- **차용 포인트**: 본 게임의 T1~T5 색상(회색/초록/파랑/보라/빨강)을 재료에도 그대로 적용. 기존 장비/정수와 동일한 시각 언어 유지. tier 컬럼 의미를 "수치 강도 + 희소성"으로 자연 통합.

### Stardew Valley — Region-Exclusive 재료의 메타 처리

- 일부 재료는 특정 지역(Calico Desert, Skull Cavern)에서만 드랍. 게임 내부적으로는 일반 재료와 같은 분류를 가지되 "어디서 나오는가" 메타로 분기.
- **차용 포인트**: 로드맵의 "지역 특산품"을 slot으로 두지 않고 별도 메타(`region_exclusive` 컬럼)로 표현. "더스트플레인 특산 광석"은 `slot=material_ore` + `region_exclusive=3`. 분류축의 일관성 보존.

---

## 상세 설계

### 1. 신규 카테고리 `material` 도입

#### 1-1. 도입 근거

M2a 분류 체계 기획서의 3대 카테고리(`personal_equipment` / `guild_equipment` / `consumable`)에 4번째로 `material`을 추가한다.

| 비교 축 | `consumable` (정수) | `material` (재료) |
|---|---|---|
| 보유 형태 | 수량 누적 (stackable) | 수량 누적 (stackable) |
| 사용 모델 | **즉시 소비 → 영구 효과 → 소멸** | **누적 보유 → 레시피로 변환 시 소비** |
| 효과 축 | 영구 스탯 +N (effect_json 사용) | **효과 없음** (effect_json 빈 객체) |
| 사용 횟수 | 1회 (각인 → 소멸) | 1회 (제작 입력 → 소멸) |
| UX 진입 | 용병 상세 또는 인벤토리 → 프리뷰 팝업 | 대장간 → 레시피 선택 → 자동 차감 |

**결론**: 두 카테고리는 보유 형태(stackable)는 같지만 **효과 모델·UX·DB 효과 스키마**가 본질적으로 다르므로 분리한다. `consumable`에 흡수하면 인벤토리 탭 sub-filter가 필수가 되고, effect_json 스키마 분기 부담이 커진다.

#### 1-2. category enum 확장

| `category` | 한국어 명칭 | 효과 축 | 수량 정책 |
|---|---|---|---|
| `personal_equipment` | 개인 장비 | 개인 스탯 (STR/INT/VIT/AGI) | 용병 1명당 각 슬롯 1개 |
| `guild_equipment` | 용병단 장비 | 거시 지표 | 용병단 전체 공유 (각 슬롯 1개) |
| `consumable` | 소모품 (정수) | 영구 스탯 +N (즉시 소비형) | 인벤토리에 수량 보유, 사용 시 소멸 |
| **`material`** (신규) | **재료** | **효과 없음** (제작 입력 전용) | **인벤토리에 수량 누적, 제작 시 소비** |

#### 1-3. 4분류 경계 식별 기준

플레이어/기획자/개발자가 같은 기준으로 카테고리를 판정할 수 있도록 **3축 결정 트리**를 제공한다.

```
질문 1: 장착하는가?
  ├─ 예 → equipment (personal/guild로 추가 분기)
  └─ 아니오 → 질문 2로

질문 2: 효과를 갖는가?
  ├─ 예 (즉시 소비 시 효과 발동) → consumable
  └─ 아니오 (제작 입력 전용) → material
```

이 결정 트리는 **상호 배타적이고 누락 없음**(MECE). 모호한 케이스 예시:
- "포션을 마시면 일시적으로 STR +5"는 `consumable`(즉시 효과 발동)
- "약초는 마시지 않고 회복 포션 레시피 입력"은 `material`(효과 없음, 제작 입력)
- "엘리트 보상으로 떨어지는 송곳니"는 장식·전투용 모두 아니고 제작 입력이면 `material_monster_part`

### 2. material 카테고리의 5종 slot

| `slot` | 한국어 | 출처 패턴 | 예시 (페이즈 1 #2에서 구체화) |
|---|---|---|---|
| `material_ore` | 광석 | 폐광 조사 / 광산 의뢰 / 광산 엘리트 보상 | 거친 광석, 단단한 광석 |
| `material_hide` | 가죽 | 일반 동물·들개·도적 의뢰 / 채집 의뢰 일부 | 들개 가죽, 잘 무두질된 가죽 |
| `material_herb` | 약초 | 채집 의뢰 / 약초상 의뢰 / 야간 순찰 | 마른 약초, 깨끗한 약초 |
| `material_relic_fragment` | 유물 파편 | 조사 숨겨진 발견 / 고정 사건 단계 / 체인 퀘스트 | 폐광의 유물 조각, 고대 인장 파편 |
| `material_monster_part` | 몬스터 부산물 | **엘리트 처치 보상 전용** / 일부 특수 일반 몬스터 | 거대 송곳니, 박쥐 결정체 |

**slot 분류의 일관성 원칙**:
- 5종 모두 **재료 형태/물성 기준**으로 분류축이 일관됨
- 로드맵 원안 "지역 특산품"은 분류축이 다름(=어디서 나왔는지의 메타)이므로 slot에 넣지 않고 별도 메타(§5)로 처리

**`material_hide` vs `material_monster_part` 경계**:
- `material_hide` = **흔한 유기재료**. 일반 동물·들개·도적·짐승 가죽. 일반 의뢰에서도 자주 드랍
- `material_monster_part` = **엘리트 보상의 격을 가진 희귀 부산물**. 송곳니/뿔/괴이한 결정체 등. 엘리트 처치 시에만 드랍 (또는 매우 특수한 일반 몬스터)
- 의도: 인벤토리에서 "흔한 가죽 더미" vs "특별한 트로피"의 인지 차별화

**slot 확장 여지**:
- 5종 고정. 후속 마일스톤에서 새 분류가 필요해지면 slot enum 확장
- "직물(cloth)", "광물 외 광석류 — 보석(gem)" 등은 M5 범위 외. M9 또는 후속 확장에서 결정

### 3. 희귀도 등급 — 기존 `tier(T1~T5)` 재해석

#### 3-1. tier 의미 통합

기존 `tier` 컬럼을 그대로 사용하되, 재료에서는 **"수치 강도 + 획득 희소성"**의 통합 의미로 해석한다.

| 카테고리 | tier 의미 |
|---|---|
| `personal_equipment` / `guild_equipment` | 효과 보정 수치의 강도 (수치 강도) |
| `consumable` (정수) | 영구 스탯 증가량 + 획득 희소성 (양자 일치) |
| `material` (신규) | **획득 희소성 = 레시피에서의 가치** (양자 일치) |

**왜 양자 일치인가**:
- 희소할수록 더 강한 결과물의 입력재가 됨. 따라서 "희소성 5단계"와 "레시피 가치 5단계"가 동일 축
- DB 스키마 변경 0건 (`tier INT CHECK BETWEEN 1 AND 5` 그대로)
- 인벤토리 색상 일관성 (T1 회색 → T5 빨강) 유지

#### 3-2. 색상 체계

기존 그대로 적용한다.

| 티어 | 색상 | 재료 사례 (페이즈 1 #2에서 구체화) |
|---|---|---|
| T1 | 회색 | 거친 광석, 마른 약초, 들개 가죽 |
| T2 | 초록 | 단단한 광석, 깨끗한 약초 |
| T3 | 파랑 | 정련된 광석, 고대의 약초, 폐광의 유물 조각 |
| T4 | 보라 | (M9+) 고티어 리전 한정 |
| T5 | 빨강 | (M9+) 최상위 엘리트 / 전설 발견 |

#### 3-3. M5 데이터 분포 가이드

M5 시작 거점은 T1 region(더스트플레인) 한정이므로 실제 데이터는 T1~T2 위주, T3 일부.

| 티어 | M5 데이터 비중 | 출처 패턴 |
|---|---|---|
| T1 | 다수 (4~6종) | 일반 의뢰 / 채집 의뢰 / 일반 조사 |
| T2 | 일부 (3~4종) | 난이도 2~3 의뢰 / 조사 일반 발견 / 이동 선택지 |
| T3 | 소수 (1~3종) | 폐광 엘리트 보상 / 조사 숨겨진 발견 / 고정 사건 클라이맥스 |
| T4~T5 | (M5에서 0종) | M9 이후 고티어 리전·엘리트 도입과 함께 |

총 8~12종은 페이즈 1 #2에서 확정. T4~T5 자리는 5단계 색상·DB 체계로만 열어두고 데이터는 후속.

### 4. 4분류 경계 명확화 (재료 vs 정수 vs 장비 vs 소모품)

다음 표는 본 문서 §1-3 결정 트리의 결과를 4축으로 정리한 것이다. spec-writer 페이즈 4의 분기 기준이 된다.

| 비교 축 | `personal_equipment` | `guild_equipment` | `consumable` (정수) | `material` (신규) |
|---|---|---|---|---|
| **장착 여부** | 예 (용병별 5슬롯) | 예 (용병단 3슬롯) | 아니오 | 아니오 |
| **수량 보유** | 인스턴스 단위 (개별) | 인스턴스 단위 (개별) | 스택 (수량) | 스택 (수량) |
| **효과 발동 시점** | 장착 중 상시 | 장착 중 상시 | 즉시 소비 시 1회 | 효과 없음 (제작 시 소비) |
| **효과 축** | 개인 스탯 (STR/INT/VIT/AGI) | 거시 지표 (보상 배수 등) | 영구 스탯 +N | 없음 |
| **소멸 조건** | 의도적 폐기 | 의도적 폐기 | 사용 시 1개 소멸 | 제작 시 N개 소멸 |
| **effect_json** | 개인 스탯 키 | 거시 지표 키 | `permanent_stat_gain` | **빈 객체 `{}`** |
| **사용 진입 UX** | 용병 상세 슬롯 그리드 | 용병단 장비 화면 | 용병 상세 / 인벤토리 → 프리뷰 팝업 | 대장간 → 레시피 선택 (자동 차감) |
| **인벤토리 탭** | 1탭 (개인 장비) | 2탭 (용병단 장비) | 3탭 (정수) | **4탭 (재료)** |

**경계 모호 케이스 처리**:
- 회복 포션(즉시 소비 시 부상 회복) → **`consumable`** (M5 범위 외, 후속 마일스톤)
- 회복 포션 제작에 쓰는 약초 → **`material_herb`** (제작 입력)
- 엘리트 처치 시 드랍되는 완제품 송곳니 단검(즉시 장착 가능) → **`personal_equipment`**
- 엘리트 처치 시 드랍되는 송곳니 자체(제작 재료) → **`material_monster_part`**

### 5. 지역 특산품 메타 — 신규 컬럼 `region_exclusive`

#### 5-1. 결정 사항

`items` 테이블에 신규 컬럼 `region_exclusive INTEGER NULL`을 추가한다. NULL이면 지역 한정 없음(범용), 정수 값이면 해당 region_id에서만 드랍/제작 가능.

```
items.region_exclusive  INTEGER  NULL  REFERENCES regions(id)
```

#### 5-2. 사용 예시 (페이즈 1 #2에서 구체화)

```
-- 더스트플레인 특산 약초 (T2)
INSERT INTO items (id, name, category, slot, tier, region_exclusive, effect_json)
VALUES ('mat_herb_dust_002', '더스트 약초', 'material', 'material_herb', 2, 3, '{}');

-- 범용 광석 (T1, region_exclusive=NULL이면 어디서든 드랍 가능)
INSERT INTO items (id, name, category, slot, tier, region_exclusive, effect_json)
VALUES ('mat_ore_common_001', '거친 광석', 'material', 'material_ore', 1, NULL, '{}');
```

#### 5-3. 적용 범위

- M5 시점: `material` 카테고리에서만 사용. 다른 카테고리(equipment·consumable)는 범용
- 후속: M6 위업·칭호에서 "더스트빌 의뢰 다수 성공" 같은 region 추적 데이터는 별도 시스템(`mercenaries.titles` 등)이며 본 컬럼과 무관
- 다중 region 한정(예: 더스트플레인 + 두 번째 거점에서만 드랍)은 M5 범위 외. 단일 region 한정만 지원

#### 5-4. 운영 도구 영향

- operation-bom의 `table-config.ts`에 `items.region_exclusive` 셀렉트 필드 추가 (region_id FK)
- 검증 쿼리: "region_exclusive 설정 재료가 실제 해당 region의 출처(quest_pools/region_discoveries/elite_loot_tables/travel_choice_results)에서 드랍 가능한가" — 본 검증은 페이즈 4 #3 명세에서 SQL 점검 쿼리 제공

### 6. 스택 정책

#### 6-1. 단일 상한 999 (Melvor 패턴)

`material`·`consumable` 카테고리 모든 아이템의 **stack_max = 999** 단일 상한을 적용한다.

| 카테고리 | stack_max | 보유 형태 |
|---|---|---|
| `personal_equipment` | 1 | 인스턴스 단위 (개별 ID) |
| `guild_equipment` | 1 | 인스턴스 단위 (개별 ID) |
| `consumable` | **999** | 스택 (수량) |
| `material` | **999** | 스택 (수량) |

#### 6-2. 저장 위치 — 코드 상수

stack_max는 **DB 컬럼이 아닌 코드 상수**로 관리한다.

```dart
// band_of_mercenaries/lib/core/constants/game_constants.dart 확장 권장
class GameConstants {
  // ... 기존 상수
  static const Map<String, int> stackMaxByCategory = {
    'personal_equipment': 1,
    'guild_equipment': 1,
    'consumable': 999,
    'material': 999,
  };
}
```

**근거**:
- M5 단계에서는 카테고리별 단일 값으로 충분 (티어별 차등 불필요)
- DB 컬럼 신설 시 마이그레이션·운영 도구 변경 비용 발생
- 미래 차등 필요 시(예: T5 정수만 99) DB 컬럼으로 이행하는 마이그레이션은 작업 비용 1회

#### 6-3. 999 상한 근거

- Melvor Idle Bank slot당 999 표준 패턴
- M5 첫 장비 완성 = 재료 누적 30~50개 수준 예상 (페이즈 2 #2에서 검증) → 999는 충분
- 인벤토리 UI 표시 자릿수 일관성 (3자리 고정, "999+" 같은 절단 표기 회피)
- 후속 마일스톤에서 인플레이션 발생 시 페이즈 2 시뮬레이션으로 재검토. 9999 또는 무제한으로 상향 가능

#### 6-4. 정수 stack_max 명시

기존 정수 시스템 기획서(§5)에는 stack 상한이 명시되지 않았다. 본 문서에서 정수도 999로 통일한다. spec-writer 페이즈 4의 InventoryItem 모델에 반영.

### 7. 인벤토리 4탭 구조

#### 7-1. 탭 구성

```
[ 개인 장비 ]  [ 용병단 장비 ]  [ 정수 ]  [ 재료 ]
```

| 탭 | 카테고리 | 표시 내용 |
|---|---|---|
| 개인 장비 | `personal_equipment` | 슬롯 5종(weapon/armor/helmet/boots/accessory) sub-filter, 장착 상태 표시 |
| 용병단 장비 | `guild_equipment` | 슬롯 2종(banner/artifact) sub-filter, 장착 상태 표시 |
| 정수 | `consumable` | 스탯 4종(STR/INT/VIT/AGI) × 티어 5단계 sub-filter, 수량 표시 |
| **재료** (신규) | `material` | **slot 5종(광석/가죽/약초/유물파편/몬스터부산물) sub-filter, 수량 + 제작 가능 표시** |

#### 7-2. 재료 탭 내부 구성 (페이즈 1 #4에서 상세화)

본 문서는 슬롯·티어·메타 체계만 확정하고, 다음은 페이즈 1 #4가 결정한다:

- 재료별 "제작 가능한 레시피" 표시 정책 (보유 시 강조? 아이콘 배지?)
- "어디서 얻을 수 있는가" 힌트 표시 정책 (region_exclusive 활용)
- 재료 정렬 기본값 (티어 desc / slot 그룹 / 보유량 desc)
- region_exclusive 재료의 시각 차별화 (테두리·아이콘 등)

#### 7-3. 후속 진화 경로

- **M5 시점**: 4탭. 정수 탭은 정수 전용
- **후속 마일스톤** (회복 포션 등 일반 소모품 도입 시): 정수 탭 → "소모품" 탭으로 명칭 변경 + sub-filter "정수/포션/두루마리" 추가. 탭 구조 자체는 4탭 유지

### 8. 일반 소모품(회복 포션 등) M5 미도입 정책

M5 roadmap이 명시한 것은 "재료와 제작" — 즉 **재료 분류 추가 + 제작 시스템**. 회복 포션·정찰 두루마리 등 일반 소모품은 M5 범위 외다.

**근거**:
- M5 첫 제작 목표 3개(깃발 복원·광부의 단검·폐광 유물 조각)는 모두 장비/아티팩트
- 회복 포션 도입 시 약초상(M4) vs 의무실(M4) vs 회복 포션의 3축 회복 시스템 충돌 검토 필요 → 별도 마일스톤에서 해결
- 일반 소모품 확장은 분류 체계가 아닌 컨텐츠 추가의 문제이며, 본 문서가 마련한 `consumable` 카테고리에 자연 흡수 가능

**제작 결과물 카테고리 가이드** (페이즈 1 #3 입력):
- 장비 결과물 → `personal_equipment` 또는 `guild_equipment`
- 정수·소모품 결과물 → **M5 범위 외**. 페이즈 1 #3는 장비/아티팩트 결과물에 집중
- 만약 소수의 일회성 강화 결과물(예: "용병단의 깃대 폴리시" 같은 일회 사용 보상)이 필요하면 페이즈 1 #3 단계에서 별도 논의

### 9. DB 스키마 요지 (페이즈 4 명세에서 확정)

본 문서가 권고하는 `items` 테이블 변경:

```sql
-- 1. category enum 확장 (기존 3종 + material)
-- 2. region_exclusive 컬럼 신설
ALTER TABLE items
  ADD COLUMN region_exclusive INTEGER NULL REFERENCES regions(id);

-- 3. 신규 인덱스 (옵션, operation-bom 필터링 용)
CREATE INDEX idx_items_category_slot ON items(category, slot);
CREATE INDEX idx_items_region_exclusive ON items(region_exclusive)
  WHERE region_exclusive IS NOT NULL;
```

**effect_json 스키마 분기** (M2a 기획서 7항 + 본 문서 4항 통합):
- `personal_equipment`: `{ "str": N, "int": N, "vit": N, "agi": N, ...특수 효과 }`
- `guild_equipment`: `{ "gold_reward_multiplier": R, "recruit_high_tier_chance": R, ... }`
- `consumable` (essence): `{ "permanent_stat_gain": { "str": N } }`
- **`material`** (신규): **`{}` (빈 객체)** — 효과 없음

**기존 컬럼은 변경 없음**: id / name / description / flavor_text / category / slot / tier / effect_json / created_at

### 10. crafting_recipes 테이블 (페이즈 1 #3에서 설계, 본 문서는 자리만 명시)

레시피 시스템은 페이즈 1 #3 + 페이즈 4 #1 명세에서 확정한다. 본 문서는 다음만 선언한다:

- 신규 테이블 `crafting_recipes` (또는 JSONB MVP)
- 입력 재료 = `material` 카테고리 아이템 N개 + 수량
- 결과 = `personal_equipment` / `guild_equipment` 아이템 1개 (M5 범위)
- 제작 비용·시간 = 페이즈 2 #2에서 확정

본 문서의 분류 체계가 레시피 입력·결과 카테고리를 제약하는 근거가 됨.

---

## 현재 시스템과의 연관

### 영향받는 기존 시스템

| 시스템 | 영향 | 비고 |
|---|---|---|
| `items` 테이블 | category enum 확장 + region_exclusive 컬럼 신설 | 페이즈 4 #1 SQL 마이그레이션 |
| `ItemData` Freezed 모델 | category enum 갱신 + `regionExclusive` 필드 추가 | spec-writer 페이즈 4 |
| `InventoryItem` Hive 모델 | 변경 최소 (수량 보유 모델은 정수와 동일) | category가 'material'인 경우 효과 없음 — 표시 분기만 필요 |
| 인벤토리 화면 | **3탭 → 4탭** 확장 (재료 탭 신설) | 페이즈 1 #4 + 페이즈 4 #2 명세 |
| `DataLoader` / `SyncService` | items 테이블 동기화 시 신규 컬럼·카테고리 처리 | 기존 SyncService 골격 그대로, 컬럼 매핑만 추가 |
| `GameConstants` | `stackMaxByCategory` 상수 신설 | 페이즈 4 |
| `ItemEffectService` | category가 'material'이면 effect 적용 skip | M2a 서비스에 분기 추가 |
| `EssenceService` | 변경 없음 (정수 한정 서비스) | — |
| `CraftingService` (M5 신규) | material 보유량 → 레시피 충족 → 결과 생성 + 입력 재료 차감 | 페이즈 4 #2 신규 도메인 서비스 |
| `QuestCompletionService` / `InvestigationNotifier` / `EliteLootService` / `TravelChoiceService` | material 드랍 hook 추가 | 페이즈 4 #3 |
| `ChainQuestService` (settlement_*) | 고정 사건 단계 보상에 material 드랍 가능 | 페이즈 4 #3 |
| operation-bom `table-config.ts` | items에 region_exclusive 셀렉트 + crafting_recipes 신규 테이블 정의 | M5 운영 도구 의존 과제 |

### Hive 박스 영향

- **신규 박스 없음**: 재료는 기존 `inventory` 박스(M2a 신설 예정)에 InventoryItem 형태로 저장. category=material 분기만 추가
- **확장 검토**: 페이즈 4 #1 명세에서 InventoryItem 모델에 stack_max 캐시(상수 참조) 또는 quantity 검증 로직 추가 결정

### Supabase 영향

- **신규 컬럼**: `items.region_exclusive` 1개
- **enum 확장**: `items.category` 값 공간에 `'material'` 추가 (실제 enum 제약은 CHECK 제약 또는 enum type 사용 — 페이즈 4 #1에서 결정)
- **신규 테이블**: `crafting_recipes` (또는 JSONB MVP, 페이즈 1 #3+페이즈 4 #1에서 결정)
- **`data_versions` 신규 행**: items 갱신 + crafting_recipes 신설
- **operation-bom 영향**: 운영 도구에서 재료 등록·레시피 편집 UI 추가 (M5 운영 도구 의존 과제)

### 기존 아이디어 / 문서와의 관계

- `Docs/future_ideas.md` "퀘스트 결과 — 보상 다양화 — 장비/아이템 시스템과 연동 필요" → M2a/M2b에서 1차 실현, M5에서 "재료 드랍 → 제작 변환"으로 확장 완성
- `Docs/idea_note.md` (확인 시 누락) — 본 기획에 직접 충돌하는 항목 없음 (재료/제작 시스템은 신규 도입)
- `Docs/content-design/[content]20260418_item_taxonomy.md` 4항 "소모품(essence만)" — 본 기획서의 `material` 카테고리 신설은 분류 체계 기획서의 "소모품 = essence만" 정책과 충돌하지 않음. 회복 포션 등은 후속 마일스톤에서 `consumable` 안에 추가됨
- `Docs/content-design/[content]20260503_starting-settlement.md` "낡은 대장간" 거점 — 본 분류 체계가 마련되어야 페이즈 1 #4(인벤토리/대장간 UI)에서 제작 화면 명세 가능

### 로드맵 의존성 재확인

- **선행**:
  - M1 완료 (세력/랭크/패시브) — 본 문서 영향 없음
  - M2a 완료 (items 테이블, 분류 체계, 정수, 인벤토리 박스) — 본 문서가 직접 확장
  - M2b 완료 (엘리트 드랍 엔진) — material_monster_part 출처
  - M3 완료 (조사·체인·이동선택지) — material_relic_fragment·고정 사건 출처
  - M4 완료 (시작 거점 더스트빌·신뢰도·고정 사건) — M5 시작 거점이 더스트빌 4섹터 위에 얹힘
- **후속**:
  - M6 위업·칭호 — material 제작 완성 위업 ("첫 깃발을 든 자" 등) 트리거 가능
  - M9 (Tier 6~10 종속 시스템) — T4~T5 재료 데이터·고티어 리전 도입

---

## 구현 우선순위 제안

본 문서는 **M5 페이즈 1 산출물 1/4**이며, 후속 페이즈 모두의 베이스라인이다. 우선순위 **높음**.

### 즉시 후속 착수 (페이즈 1 잔여)

1. **시작 거점 전용 재료 8~12개 + 드랍 출처 매핑표** (페이즈 1 #2)
   - 본 문서 §2(slot 5종) + §3-3(M5 데이터 분포) + §5(region_exclusive 메타) 규약 사용
   - 더스트빌 4섹터(폐광 dungeon / 마른초원 field / 먼지 길 field / 더스트빌 village) 5종 출처 매핑
   - 결과물: T1 4~6종 + T2 3~4종 + T3 1~3종 권장 분포
2. **초반 제작 레시피 8~12개 + 첫 제작 목표 3개 시나리오** (페이즈 1 #3)
   - 깃발 복원·광부의 단검·폐광 유물 조각 + 그 외 중간재 레시피
   - 입력: 페이즈 1 #2 재료 + 본 문서 §4 4분류 경계
3. **인벤토리 재료 탭 + 대장간 제작 UI 컨셉** (페이즈 1 #4)
   - 본 문서 §7 4탭 구조 + 재료 탭 내부 정책 상세화
   - 입력: 페이즈 1 #1 + #3

### balance-designer 의존 과제 (페이즈 2)

- 재료 드랍률 곡선 — 5종 slot × 출처 매핑 × T1~T3 분포
- 제작 비용·시간 — 첫 제작 30~45분, 첫 희귀 장비 90~150분 보장
- 완제품 vs 제작 시간 효율 — 제작 루트 무력화 방지

### data-generator 의존 과제 (페이즈 3, 스킵 권장)

본 문서 §1-2의 5종 slot은 단일 거점(더스트빌) 한정 8~12종 + 레시피 8~12개 = 총 20~25행. 페이즈 4 명세 SQL INSERT로 인라인 처리 권장.

만약 후속 마일스톤에서 다중 거점 재료가 추가되어 데이터량이 폭증하면 그 시점에 `.claude/skills/data-generator/types/material.md` 타입 스펙 작성 가능.

### spec-writer 의존 과제 (페이즈 4)

- `items.category` enum 'material' 추가 + `region_exclusive` 컬럼 신설 마이그레이션
- `ItemData` Freezed 모델에 `regionExclusive` 필드 추가
- `GameConstants.stackMaxByCategory` 상수 정의
- `InventoryItem` Hive 모델 + category=material 분기 (효과 미적용)
- `CraftingService` 신규 도메인 서비스 (재료 보유 → 레시피 충족 → 결과 생성 + 입력 차감)
- 인벤토리 화면 4탭 확장 + 재료 탭 sub-filter (slot 5종)
- 낡은 대장간 거점 제작 화면 (페이즈 1 #4 컨셉 따름)
- material 드랍 hook 추가 (Quest/Investigation/Elite/TravelChoice 4개 출처)

### 미결정 / 연기

- T4~T5 재료 데이터 — M9 또는 후속 마일스톤
- 다중 region 한정 재료 — 본 문서 §5-2 단일 region 한정만 지원
- 일반 소모품(회복 포션 등) — 본 문서 §8 미도입 정책. 후속 마일스톤
- 재료 분해/환원 (장비 → 재료 역변환) — M5 범위 외
- 새 slot 추가(직물·보석 등) — M9 또는 후속

---

## data-generator 지시사항

본 기획서는 **분류 체계의 최상위 뼈대**이며, 직접적인 벌크 데이터 생성 대상이 아니다.

페이즈 1 #2(재료 8~12종) + 페이즈 1 #3(레시피 8~12개) = 총 20~25행은 페이즈 4 명세 SQL INSERT로 인라인 처리 권장 (M4 페이즈 3 스킵 결정과 동일 논거 — 단일 거점 한정·데이터량 적음).

페이즈 3 data-generator 호출이 필요한 경우 (선택적):
- 타입 스펙: `.claude/skills/data-generator/types/material.md` 미존재 → 작성 필요
- 입력 기획서: 페이즈 1 #2 + 본 문서
- 대상 테이블: `items` (category=material) + `crafting_recipes`

---

## 체크리스트

- [x] 신규 카테고리 `material` 도입 결정 (4번째 카테고리)
- [x] 4분류 경계 명확화 (장착 / 효과 발동 / 효과 없음 결정 트리)
- [x] 5종 slot 정의 (`material_ore`/`material_hide`/`material_herb`/`material_relic_fragment`/`material_monster_part`)
- [x] `material_hide` vs `material_monster_part` 경계 정의 (흔한 유기재료 vs 엘리트 보상 격)
- [x] 희귀도 = 기존 tier(T1~T5) 재해석 결정 (수치 강도 + 희소성 통합)
- [x] 색상 체계 일관성 유지 (회색/초록/파랑/보라/빨강 그대로)
- [x] M5 데이터 분포 가이드 (T1~T2 위주 + T3 일부)
- [x] 지역 특산품 메타 = 신규 컬럼 `region_exclusive INTEGER NULL`
- [x] 스택 상한 999 단일 정책 결정
- [x] stack_max 코드 상수 처리 (DB 컬럼 신설 안 함)
- [x] 인벤토리 4탭 구조 결정 (개인장비/용병단장비/정수/재료)
- [x] 일반 소모품(회복 포션 등) M5 미도입 정책 명시
- [x] DB 스키마 변경 요지 (category enum 확장 + region_exclusive 컬럼)
- [x] effect_json 분기에 `material = {}` 추가
- [x] crafting_recipes 자리 명시 (페이즈 1 #3 위임)
- [x] 기존 시스템 영향 분석
- [x] 후속 페이즈 안내
