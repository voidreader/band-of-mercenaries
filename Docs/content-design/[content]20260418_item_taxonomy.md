# 아이템 분류 체계 컨텐츠 기획서

> 작성일: 2026-04-18
> 유형: 신규 컨텐츠 (M2a 페이즈 1 — 산출물 1/3)
> 후속 기획 연동: `[content]20260418_essence_system.md` (산출물 2), `[content]20260418_initial_item_set.md` (산출물 3)

---

## 개요

M2a "아이템의 태동" 마일스톤에서 도입될 아이템 인프라의 **최상위 분류 체계**를 확정한다. 개인 장비 / 용병단 장비 / 소모품의 3대 범주, 각 범주의 슬롯 체계, 티어 정책, 네이밍 규약을 뼈대로 정리하여 이후 정수 시스템 기획, 초기 아이템 세트 기획, balance-designer의 수치 시뮬레이션, spec-writer의 DB 스키마 설계가 일관된 기반 위에서 진행되도록 한다.

이 문서는 "어떤 아이템을 만들 것인가"가 아니라 "아이템을 어떻게 분류할 것인가"의 컨테이너 설계다. 수치·개별 아이템 서사·드랍 경로는 후속 문서가 담당한다.

---

## 레퍼런스 분석

### Melvor Idle — 슬롯 세분화의 기준선
- 9슬롯 체계 (무기/머리/몸통/다리/발/장갑/망토/반지/목걸이). 스킬 레벨을 장착 요구 조건으로 두어 성장 단계별 자연스러운 보상 흐름을 만든다.
- **차용 포인트**: 개인 장비를 무기/방어구/장신구의 3범주 추상화로 유지하되 실 슬롯은 5개(weapon/armor/helmet/boots/accessory)로 세분화하여 조합 깊이를 확보한다. 다만 Melvor의 "스킬 레벨 요구"는 도입하지 않는다 (M2a의 "자유 장착" 철학 유지).

### Diablo / Kingdom of Loathing — 티어와 장착 제한의 분리
- Diablo는 아이템 티어(노말/매직/레어/유니크)와 캐릭터 레벨 요구를 분리하되, 속성 요구치로 실질적 장착 제한을 건다. KoL은 티어 자체는 장착 자유도가 높다.
- **차용 포인트**: 아이템 티어(T1~T5)는 수치 강도의 지표로만 사용하고 장착 자체는 완전 자유. 저티어 용병이 고티어 장비를 끼워 "장비빨로 끌어올리는" 검증 시나리오를 허용한다. 이는 operation-bom 수동 지급 환경에서의 실험 폭을 넓히기 위함이다.

### 아크메이지 — 용병단 장비의 전역 효과
- 길드 깃발, 길드 버프 개념이 파티 전체에 효과를 주는 구조. 개인 장비와 효과 축이 분리되어 있어 밸런싱이 용이하다.
- **차용 포인트**: 용병단 장비(banner 1 + artifact 2 = 3슬롯)는 개인 스탯(STR/INT/VIT/AGI)에 관여하지 않고 **거시 지표**(골드 보상 배수, 모집 확률, 부상률 감소, 여행 이벤트 결과 등)만 조정. 개인 장비와 효과 풀을 분리하여 시뮬레이션 시 교차 오염을 방지한다.

### 게임 속 바바리안으로 살아남기 (웹소설) — 정수의 감성 차용
- 몬스터에게서 획득하는 희귀 정수가 영구 스탯 강화 수단으로 기능. 누적 소비의 감성이 핵심.
- **차용 포인트**: 정수 4종(힘/지혜/수호/민첩)을 STR/INT/VIT/AGI에 1:1 매핑하여 영구 소비 경로를 명확히 한다. 로드맵이 제시한 "힘/수호/생명/상급" 원안은 스탯 4축과의 정합성을 위해 "힘(STR) / 지혜(INT) / 수호(VIT) / 민첩(AGI)"으로 재정렬하고, 원안의 "상급"은 후속 마일스톤에서 "상위 티어 정수(보통 정수의 강화판)"으로 재해석될 여지를 남긴다.

---

## 상세 설계

### 1. 최상위 3대 카테고리

| `category` | 한국어 명칭 | 효과 축 | 수량 정책 |
|---|---|---|---|
| `personal_equipment` | 개인 장비 | 개인 스탯 (STR/INT/VIT/AGI) | 용병 1명당 각 슬롯 1개 |
| `guild_equipment` | 용병단 장비 | **거시 지표만** (골드/모집/부상률/여행 이벤트 등) | 용병단 전체 공유 (각 슬롯 1개) |
| `consumable` | 소모품 | 영구 소비형 | 인벤토리에 수량 보유, 사용 시 소멸 |

**범주 간 경계 규칙**:
- 개인 장비와 용병단 장비는 **효과 축이 서로 겹치지 않는다**. 개인 장비는 파티 전력(STR/INT/VIT/AGI)을 바꾸고, 용병단 장비는 거시 지표(보상 배수/모집/부상률)만 바꾼다. 이 분리는 밸런스 검토 시 두 영향을 독립 변수로 다루기 위해서다.
- 소모품은 장착 슬롯을 차지하지 않고 수량으로 보유한다.

### 2. 개인 장비 슬롯 (5개)

| `slot` | 한국어 | 주 효과 축 |
|---|---|---|
| `weapon` | 무기 | STR 또는 INT |
| `armor` | 갑옷 | VIT |
| `helmet` | 투구 | VIT 또는 복합 |
| `boots` | 신발 | AGI |
| `accessory` | 장신구 | 복합 (단일 스탯 소량 또는 특수 효과) |

**장착 정책**:
- **티어 자유 장착**: T1 용병이 T5 장비를 장착 가능. 장비 효과는 티어 감쇠 없이 100% 적용된다.
- **직업 자유 장착**: 모든 직업(role)이 모든 무기 장착 가능. 무기 네이밍("지팡이", "활")은 서사적 분위기일 뿐 게임 규칙의 제약이 아니다.
- **제약 없음 원칙**: M2a는 인프라 검증 마일스톤이므로 장착 규칙을 단순하게 유지. 직업 정체성 강화나 티어 매칭 강제는 향후 마일스톤에서 별도 논의 대상.

**슬롯 확장 여지**:
- 현 단계에서는 5슬롯 고정. 장신구를 다중 슬롯(accessory_1/accessory_2)으로 확장하는 방안은 M4 또는 후속 밸런스 조정에서 재검토 가능.

### 3. 용병단 장비 슬롯 (3개)

| `slot` | 한국어 | 역할 | 동시 활성 |
|---|---|---|---|
| `banner` | 군기 | 용병단의 상징. 거시 지표 중심 보정 (명성 배수, 모집 확률 등) | 1개 |
| `artifact` | 유물 | 수집형 고대 아이템. 특수 지표 보정 (세력/리전/퀘스트 유형별) | 2개 |

**효과 축 제약 (E1-b 정책)**:
- 용병단 장비는 **개인 스탯(STR/INT/VIT/AGI)을 건드리지 않는다**.
- 허용 효과 축 예시:
  - `gold_reward_multiplier` — 퀘스트 골드 보상 배수
  - `recruit_high_tier_chance` — 고티어 용병 모집 확률
  - `injury_rate_modifier` — 부상 발생률 조정
  - `travel_event_bonus` — 여행 이벤트 결과 우호도
  - `idle_reward_cap` — 방치 보상 상한
  - `reputation_gain_modifier` — 명성 획득 배수
- 개인 장비의 `effect_json`이 개인 스탯 키를 갖는 것과 달리, 용병단 장비는 위 거시 지표 키만 갖는다. balance-designer 페이즈 2에서 구체 보정 범위를 정한다.

### 4. 소모품 (essence만)

| `slot` | 한국어 | 사용 대상 | M2a 소비 경로 | 후속 소비 경로 |
|---|---|---|---|---|
| `essence_str` | 힘의 정수 | 용병 1명 | STR 영구 +N | M6: 티어 승급 재료로 재사용 |
| `essence_int` | 지혜의 정수 | 용병 1명 | INT 영구 +N | M6: 티어 승급 재료로 재사용 |
| `essence_vit` | 수호의 정수 | 용병 1명 | VIT 영구 +N | M6: 티어 승급 재료로 재사용 |
| `essence_agi` | 민첩의 정수 | 용병 1명 | AGI 영구 +N | M6: 티어 승급 재료로 재사용 |

**정수의 이중 역할 (중요)**:
- **M2a 경로**: 정수를 용병에게 사용하면 영구 스탯이 +N 증가하고 정수가 소멸한다. `EssenceService.apply(mercenaryId, essenceItemId)` 형태로 처리.
- **M6 경로 (선반영)**: 동일한 정수 아이템이 용병 티어 업그레이드(T1→T2 등)의 재료로도 요구된다. 즉 플레이어는 "스탯 강화에 쓸 것인가, 승급에 비축할 것인가"의 전략 선택에 직면한다.
- **M2a 기획서 범위**: 영구 스탯 강화 경로만 구현. 다만 정수 아이템 데이터는 M6에서 그대로 재사용되므로 소비 정책을 너무 관대하게 설정하지 않는다. balance-designer 페이즈 2에서 "스탯 강화 N회 후에도 승급용 비축 여력이 남는" 수치 곡선을 검토한다.

**일반 소모품 (general consumable)**:
- M2a 범위에서는 **데이터 생성 없음**. 스키마의 `slot` 값 공간만 열어둔다 (예: `slot=potion`, `slot=scroll` 같은 미래 자리).
- 후속 마일스톤에서 회복 포션, 사기 증진제, 정찰 두루마리 등의 일시 소비형 소모품이 추가될 수 있다. 이때 기존 essence와 카테고리는 동일하게 `consumable`이되 slot 값으로 구분한다.

### 5. 아이템 티어 (T1~T5)

- 리전/용병 티어와 동일한 5단계 체계.
- 공통 티어 색상 규칙 재사용:
  - T1 회색 / T2 초록 / T3 파랑 / T4 보라 / T5 빨강
- 아이템 티어는 **수치 강도의 지표**이다. 장착 가능 여부는 앞서 정의한 대로 자유 장착이며, 티어는 `effect_json`의 보정 수치를 결정하는 축으로만 동작한다.
- **검증용 최소 데이터 수량** (M2a):
  - 정수: 4종 (스탯 4축 각 1종, 티어는 balance-designer가 결정)
  - 개인 장비: 6~8종 (T2~T5 분포, 슬롯별 최소 1종은 포함하지 않음 — 6~8 범위 내 유연 배분)
  - 용병단 장비: 3~4종 (군기 1~2 + 유물 2~3)
  - **총계**: 13~16종

### 6. 서브카테고리 정책 (`sub_category` 필드)

- `slot` 값이 이미 서브카테고리 역할을 겸하므로 **별도의 `sub_category` 필드는 M2a에서 생성하지 않는다**.
  - 개인 장비 서브카테고리 = slot 값 (weapon/armor/helmet/boots/accessory)
  - 용병단 장비 서브카테고리 = slot 값 (banner/artifact)
  - 소모품 서브카테고리 = slot 값 (essence_str/essence_int/essence_vit/essence_agi)
- 장점: DB 스키마가 (`category`, `slot`)의 2축으로 단순. 조회 쿼리 단순화.
- 확장 여지: 무기 내 세부 유형(지팡이/활/검 등)을 구분할 필요가 생기면 후속 마일스톤에서 `sub_category` 추가 컬럼으로 확장. M2a 단계에서는 서사·분위기는 `flavor_text`와 `name`으로만 표현하면 충분.

### 7. DB 스키마 요지 (페이즈 4 명세에서 확정)

아래는 개념적 윤곽이며, 정확한 컬럼 타입과 제약은 spec-writer 페이즈 4에서 확정한다.

```
items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,                     -- 장식 설명
  flavor_text TEXT,                     -- 서사·분위기 텍스트
  category TEXT NOT NULL,               -- personal_equipment / guild_equipment / consumable
  slot TEXT NOT NULL,                   -- weapon/armor/helmet/boots/accessory
                                        --   / banner/artifact
                                        --   / essence_str/essence_int/essence_vit/essence_agi
  tier INTEGER NOT NULL CHECK (tier BETWEEN 1 AND 5),
  effect_json JSONB NOT NULL,           -- 범주별 효과 키가 다름 (아래 스키마)
  created_at TIMESTAMPTZ DEFAULT now()
)
```

**effect_json 스키마 분기 (category별)**:
- `personal_equipment`: `{ "str": N, "int": N, "vit": N, "agi": N, ...특수 효과 }` — 개인 스탯 축만 허용
- `guild_equipment`: `{ "gold_reward_multiplier": R, "recruit_high_tier_chance": R, "injury_rate_modifier": R, ... }` — 거시 지표 축만 허용, 개인 스탯 축 금지
- `consumable` (essence): `{ "permanent_stat_gain": { "str": N } }` 같은 영구 소비형 스키마. M6 승급 재료용 메타 필드는 이 기획서 범위 외 (M6 기획 시 별도 확장)

### 8. 인벤토리 구조 윤곽

- Hive `inventory` 박스 신설 (페이즈 4 명세에서 확정)
- 장착 상태는 `InventoryItem.equippedTo` 필드(용병 ID 또는 `"guild"` 리터럴)로 표현
- 용병 상세 오버레이에 **개인 장비 슬롯 5칸 그리드** 추가
- 별도의 **용병단 화면** 또는 홈/정보 탭 내 "용병단 장비" 섹션에 3슬롯 표시 (페이즈 4 UI 명세에서 결정)
- 인벤토리 화면에 카테고리 필터(개인 장비 / 용병단 장비 / 소모품) 제공

---

## 현재 시스템과의 연관

### 영향받는 기존 시스템

| 시스템 | 영향 | 비고 |
|---|---|---|
| `Mercenary` 모델 | 필드 확장 필요 | 개인 장비 5슬롯 참조 (HiveField 추가). 영구 스탯 누적치(base_str 대비 permanent_str 등) 저장 필드 검토 |
| effectiveStr/effectiveInt/effectiveVit/effectiveAgi getter | 공식 확장 | 기존 (레벨 보너스 + 피로 디버프) → **+ 장비 보정 + 영구 정수 보정** 추가 |
| `QuestCalculator.calculateSuccessRate` | 간접 영향 | 장비로 강화된 partyPower가 자동 반영됨 (공식 자체는 불변). 용병단 장비의 거시 지표는 별도 경로로 주입 |
| `PassiveBonusService` | 충돌 없음 | 세력/랭크 패시브와 용병단 장비의 거시 지표는 효과 축이 겹칠 수 있으나 가산 합산 정책으로 호환 가능. balance-designer에서 공유 상한 정책 검토 |
| `RecruitmentService` | 거시 지표 주입 | 용병단 장비의 `recruit_high_tier_chance`가 여기로 흘러들어감 |
| `IdleRewardService` / 방치 보상 | 거시 지표 주입 | 용병단 장비의 `idle_reward_cap` 반영 |
| `TravelEventService` / 부상 계산 | 거시 지표 주입 | `travel_event_bonus`, `injury_rate_modifier` 반영 |
| `SyncService` | 테이블 추가 | `items` 테이블 동기화. `data_versions`에 행 추가 |
| `DataLoader` | 정적 데이터 로드 | `items` 정적 데이터 캐시 및 역직렬화 |

### Hive 박스 영향

- **신규**: `inventory` 박스 (InventoryItem 모델, typeId는 spec-writer 페이즈 4에서 확정)
- **확장**: `mercenaries` 박스의 Mercenary 모델에 장착 슬롯 참조 필드 추가 (HiveField 번호 순차 할당)
- **확장 검토**: `user` 박스의 UserData에 용병단 장비 장착 슬롯 (`banner_item_id`, `artifact_1_item_id`, `artifact_2_item_id`) 추가 필요

### Supabase 영향

- **신규 테이블**: `items` (18개 → 19개)
- `data_versions` 신규 행 추가
- operation-bom에서 `table-config.ts`에 items 정의 추가 (category/slot/tier 셀렉트 필드)
- operation-bom의 **유저별 수동 지급 인터페이스** 별도 개발 필요 (M2b 드랍 엔진 이전의 검증 경로). 이 기획서 범위 외이나 의존 과제로 명시.

### 기존 아이디어 / 문서와의 관계

- `Docs/future_ideas.md`: "퀘스트 결과 — 보상 다양화 — 장비/아이템 시스템과 연동 필요" 항목이 M2a에서 첫 구현으로 실현됨. 다만 M2a에는 드랍 경로가 없어 퀘스트 보상 연동은 M2b에서 완결됨.
- `Docs/Archive/misc/idea_note.md`: "정수 획득 (게임 속 바바리안으로 살아남기)" 레퍼런스가 본 문서의 정수 4종 네이밍·감성의 근거가 됨.
- `content_status.md` 7. 아키텍처 요약의 서비스 14개 목록에 `ItemEffectService`, `EssenceService`, `InventoryRepository`가 M2a 이후 추가될 예정 (페이즈 4 명세에서 확정).

### 로드맵 선행/후속 의존 재확인

- **선행**: M1 완료 상태 (세력/랭크/패시브 시스템). 본 기획서는 M1 시스템을 변경하지 않는다.
- **후속**:
  - M2b 엘리트 드랍 엔진이 items 테이블을 인벤토리에 지급하는 판정 로직 추가
  - M3 연계 퀘스트 최종 보상으로 items 재사용
  - M4 세력 상점 상품으로 items 재사용
  - M6 용병 티어 승급 재료로 essence 재사용 (본 문서 4항 "이중 역할" 참조)

---

## 구현 우선순위 제안

본 문서는 **페이즈 1 산출물 1/3**이며, 이후 M2a 진행의 베이스라인이다. 뼈대에 해당하므로 우선순위는 **높음**.

### 즉시 후속 착수 (페이즈 1 잔여)

1. **정수 시스템 기획** (`[content]20260418_essence_system.md`) — 정수 4종 각각의 효과 범위, 영구 스탯 강화 세부 규칙, 용병 1명당 정수 사용 상한(있다면), 소비 UX, M6 승급 재료 재사용 정책 선반영.
2. **검증용 초기 아이템 세트 컨셉** (`[content]20260418_initial_item_set.md`) — 개인 장비 6~8종, 용병단 장비 3~4종 각각의 테마/서사/이름/티어 배분 제안. 본 문서의 slot/category/tier 규약을 따름.

### balance-designer 의존 과제 (페이즈 2)

- 정수 영구 강화 수치 × 인플레이션 시뮬레이션 (본 문서 4항 이중 역할 고려)
- 개인 장비 티어별 스탯 보정 범위 × 성공률 영향 측정
- 용병단 장비 거시 지표 보정 범위 × 파티 전력/경제 총합 영향

### spec-writer 의존 과제 (페이즈 4)

- `ItemData` Freezed 모델 정의 (본 문서 7항 DB 스키마 기반)
- `InventoryItem` Hive 모델 + `inventory` 박스 신설
- `ItemEffectService` / `EssenceService` 공식 확정
- 인벤토리 UI + 용병 상세 장비 슬롯 UI + 용병단 장비 UI
- SyncService 확장 (items 테이블 + data_versions 행)

### 미결정 / 연기

- 장신구 다중 슬롯(accessory_1/accessory_2) — M4 이후 재검토
- 무기 서브카테고리(지팡이/활/검 등) 도입 — M4 이후 재검토
- 장비 강화(대장간 시설의 stub 기능 실현) — 별도 마일스톤에서 범위 지정
- 일반 소모품(회복 포션, 사기 증진제 등) — 후속 마일스톤

---

## data-generator 지시사항

본 기획서는 **분류 체계의 최상위 뼈대**이며, 직접적인 벌크 데이터 생성 대상이 아니다. 실제 정수 4종 + 개인 장비 6~8종 + 용병단 장비 3~4종의 벌크 데이터 생성은 다음 산출물 이후에 수행된다:

- 페이즈 1 산출물 2 (정수 기획) → 페이즈 3의 essence 데이터 생성 입력
- 페이즈 1 산출물 3 (초기 아이템 세트 컨셉) → 페이즈 3의 장비 데이터 생성 입력

따라서 본 문서 자체는 data-generator 호출을 유발하지 않는다. 단, **data-generator 타입 스펙(`essence.md`, `item.md`)의 설계 근거 문서**로 본 기획서를 참조한다.

---

## 체크리스트

- [x] 3대 카테고리 확정 (personal_equipment / guild_equipment / consumable)
- [x] 개인 장비 5슬롯 확정 (weapon/armor/helmet/boots/accessory)
- [x] 티어 자유 장착 + role 자유 장착 정책 확정
- [x] 용병단 장비 3슬롯 확정 (banner 1 + artifact 2)
- [x] 용병단 장비 효과 축 분리 정책 확정 (개인 스탯 금지, 거시 지표만)
- [x] 소모품 = essence만 (일반 소모품 M2a 배제)
- [x] 정수 4종 스탯 완전 매핑 확정 (essence_str/int/vit/agi)
- [x] 정수 이중 역할 명시 (M2a 영구 강화 + M6 승급 재료)
- [x] 티어 정책 확정 (T1~T5, 수치 강도 지표)
- [x] 서브카테고리 정책 확정 (slot이 겸함, 별도 필드 불필요)
- [x] DB 스키마 요지 기술
- [x] 기존 시스템과의 연관 명시
- [x] 후속 페이즈 안내
