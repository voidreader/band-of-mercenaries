# 더스트빌 시작 거점 재료 + 드랍 출처 매핑 컨텐츠 기획서

> 작성일: 2026-05-04
> 유형: 신규 컨텐츠 (M5 페이즈 1 — 산출물 2/4)
> 선행 문서:
> - `Docs/content-design/[content]20260504_material-taxonomy.md` — 분류 체계(slot 5종/tier 재해석/region_exclusive 메타)
> - `Docs/content-design/[content]20260503_starting-settlement.md` — 더스트빌 4섹터 + 거점 3종 stub 텍스트
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` — 신뢰도 4단계 + 폐광길 재개방 6단계
> - `Docs/settlement-quest-flow.md` (2026-05-04 작성) — **M4 실제 구현 후 진실의 원천**
> - `Docs/roadmap/master_roadmap.md` 942~1023행 — M5 #드랍 출처 연결 / #초반 대표 제작 목표
> 후속 산출물:
> - 페이즈 1 #3 — 본 문서의 재료 10종을 입력으로 받아 제작 레시피 8~12개 + 첫 제작 목표 3개 시나리오 확정
> - 페이즈 1 #4 — 본 문서의 region_exclusive 재료를 시각 차별화하는 인벤토리 정책
> - 페이즈 2 #1 — 본 문서의 출처 매핑을 입력으로 받아 드랍률 곡선 + 첫 30~45분 첫 제작 시뮬레이션
> - 페이즈 4 #1 — 재료 10종 SQL INSERT (인라인 처리)
> - 페이즈 4 #3 — 본 문서의 출처 매핑을 SQL UPDATE/INSERT로 적용

---

## 개요

M5 시작 거점 더스트빌(region 3) 4섹터에서 획득 가능한 **재료 10종**을 정의하고, 5종 출처(의뢰·조사·엘리트·이동선택지·고정사건) 모두에 최소 1종을 연결한다. 본 문서는 페이즈 1 #1 분류 체계의 slot 5종(`material_ore`/`material_hide`/`material_herb`/`material_relic_fragment`/`material_monster_part`)과 tier 분포 가이드(T1 4~6 / T2 3~4 / T3 1~3)에 따라 더스트빌 단일 거점에서 충분한 다양성과 출처 분포를 만든다.

본 문서가 확정하는 것:
- 재료 10종 명단 (이름·slot·tier·region_exclusive)
- 각 재료의 **5종 출처 매핑** (의뢰/조사/엘리트/이동선택지/고정사건 모두 연결)
- **첫 제작 목표 3개**(깃발 복원·광부의 단검·폐광 유물 조각)의 입력 재료 검증
- region_exclusive 정책 (4종 한정 / 6종 범용)
- M4 실제 구현 인프라(`settlement_3_pyegwang_reopen` 체인 / 기존 quest_pools 16행 / 신뢰도 4단계)와의 정합

본 문서가 확정하지 않는 것 (후속 위임):
- 제작 레시피 입력 수량의 최종 밸런스 — 페이즈 2 #2
- 드랍률 확률값 — 페이즈 2 #1
- 거대 박쥐 엘리트 스탯 — M5 페이즈 4 #3에서 elite_monsters에 INSERT
- 인벤토리에서 region_exclusive 시각 차별화 — 페이즈 1 #4

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| Stardew Valley — Forage 시스템 | 계절·지역별로 다른 채집물이 등장. "어디서 무엇이 나오는지" 학습이 게임 자체 | 더스트빌 4섹터에 slot별 재료를 분산 배치. 폐광=ore/relic / 마른초원=herb/hide / 먼지길=hide / 더스트빌=신뢰도 보상 |
| Melvor Idle — Mining Loot Table | 광맥 1개에서 여러 등급의 ore가 다른 확률로 드랍. 일반 ore + 희귀 ore + 보너스 gem | 폐광 quest_pools 1건이 녹슨 쇳조각(T1, 흔함) + 녹슨 곡괭이 머리(T2, 가끔) + 폐광의 유물 파편(T2, 드물게) 다중 드랍 |
| Path of Exile — Boss-Specific Drop | 특정 보스에서만 떨어지는 시그니처 재료(예: Atziri's Splendour) | step 3 거대 박쥐 엘리트의 시그니처 = 거대 박쥐 송곳니(T3 monster_part). 이 엘리트 처치만이 입수 경로 |
| Kingdom of Loathing — Adventure 결과 다양성 | 같은 위치에서 동일 행동을 해도 결과가 무작위로 다른 재료/이벤트 | 마른 초원 hunt 의뢰 1건이 마른 가죽끈(보통) + 산기슭 버섯(가끔) + 도적 흔적(이동 선택지 트리거) 분기 |
| Disco Elysium — One-Off Reward | 사건 라인 클라이맥스에서만 단 1회 획득되는 고유 아이템 | 고대 인장 조각 = step 6 폐광 재개방식 보상 1회. 이후 재획득은 폐광 최심부 숨겨진 발견(reset)을 통해서만 |

**기존 게임과의 차별 포인트**: 본 게임은 "다양한 출처 5종이 모두 다른 재료를 제공"하는 구조로 플레이어가 한 활동에 갇히지 않게 한다. 한 장비를 완성하려면 의뢰·조사·엘리트·이동·고정사건을 모두 거쳐야 한다(첫 제작 목표 3개 검증 §4 참조).

---

## 상세 설계

### 1. 재료 10종 명단

#### 1-1. 분포 요약

| 분포 축 | 재료 수 | 비고 |
|---|---|---|
| **slot 분포** | ore 2 / hide 2 / herb 3 / relic_fragment 2 / monster_part 1 = **10종** | 5종 slot 모두 1개 이상 |
| **tier 분포** | T1 5 / T2 3 / T3 2 = **10종** | 페이즈 1 #1 가이드(T1 4~6 / T2 3~4 / T3 1~3) 정합 |
| **region_exclusive 분포** | NULL 6 / region 3 한정 4 = **10종** | 흔한 재료는 범용, 더스트플레인 색채는 한정 |

#### 1-2. 재료 10종 상세표

| # | id (페이즈 4 권장) | 이름 | slot | tier | region_exclusive | 서사 톤 |
|---|---|---|---|---|---|---|
| 1 | `mat_ore_rusty_scrap` | **녹슨 쇳조각** | `material_ore` | 1 | NULL | 폐광 갱도에서 흩어진 평범한 쇳조각. 한때 곡괭이 끝이었거나 광차 부속이었을 것이다 |
| 2 | `mat_hide_dry_strap` | **마른 가죽끈** | `material_hide` | 1 | NULL | 마른 초원 들개·도적 가방에서 풀린 짧은 가죽끈. 마을 어디서나 쓰인다 |
| 3 | `mat_herb_dry` | **마른 약초** | `material_herb` | 1 | NULL | 마른 초원에 흔하게 자라는 잡초성 약초. 약초상의 가장 기본 재료 |
| 4 | `mat_herb_mountain_mushroom` | **산기슭 버섯** | `material_herb` | 1 | NULL | 마른 초원 가장자리 바위틈에 무리 짓는 작은 버섯. 야간 순찰 중 자주 발견된다 |
| 5 | `mat_herb_dust_resin` | **접착 수액** | `material_herb` | 1 | **3** | 더스트플레인 특산 식물의 점착성 분비물. 먼지를 머금어 더 끈끈해진다 |
| 6 | `mat_hide_faded_cloth` | **빛바랜 천 조각** | `material_hide` | 2 | NULL | 더스트빌 광장에 모인 잡동사니에서 풀린 오래된 천. 깃발의 원래 재질을 짐작케 한다 |
| 7 | `mat_ore_rusty_pickaxe_head` | **녹슨 곡괭이 머리** | `material_ore` | 2 | **3** | 폐광 깊숙이 박힌 채 부러진 곡괭이의 머리. 단단한 강철의 흔적 |
| 8 | `mat_relic_pyegwang_shard` | **폐광의 유물 파편** | `material_relic_fragment` | 2 | **3** | 폐광 안쪽에서 발견되는 정체 모를 고대 유물의 작은 조각. 마을 사람도 못 알아본다 |
| 9 | `mat_monster_giant_bat_fang` | **거대 박쥐 송곳니** | `material_monster_part` | 3 | NULL | step 3 박쥐 둥지의 우두머리에서 얻는 시그니처 트로피. 비정상적으로 크고 단단하다 |
| 10 | `mat_relic_ancient_seal_piece` | **고대 인장 조각** | `material_relic_fragment` | 3 | **3** | step 6 폐광 재개방식에서 우연히 발굴되는 고대 인장의 일부. 마을 역사보다 오래된 것 |

**서사 톤 통일**:
- T1 = 평범한 한국어 ("녹슨", "마른", "산기슭")
- T2 = 한국어 + 형용사 강화 ("빛바랜", "녹슨~머리")
- T3 = 강한 형용사 + 고대성 ("거대", "고대")
- 페이즈 1 #1의 분류 체계 기획서 작명 톤 (`[content]20260418_initial_item_set.md` §1 — T2 평범 / T3 형용사·외래어 / T4 판타지 / T5 강렬)과 동일 방향. T4~T5가 본 문서에 없는 이유는 시작 거점 데이터 분포 가이드(T1~T3 위주)에 부합

### 2. 5종 출처 매핑표

#### 2-1. 출처별 연결 재료

| 출처 종류 | 더스트빌 기준 구체 위치 | 연결 재료 (#번호) | M4 인프라와의 관계 |
|---|---|---|---|
| **(a) 의뢰** (`quest_pools`) | 폐광 labor·explore / 마른 초원 hunt·explore / 약초상 채집 의뢰 (M4 신뢰도 2단계 노출) | #1 #2 #3 #4 #6 | **기존 16행 quest_pools에 재료 드랍 보상 추가** (허드렛일 10 + 고정사건 6) |
| **(b) 조사 발견** (`region_discoveries`) | 폐광 일반 발견 / 폐광 숨겨진 발견 (M3 인프라) | #1 (일반) / #7 #8 #10 (숨겨진) | 기존 region_discoveries 행 UPDATE 또는 신규 행 INSERT |
| **(c) 엘리트** (`elite_loot_tables`) | step 3 박쥐 둥지 우두머리 = **거대 박쥐**(M5 신규 elite_monsters 1행) | #9 (시그니처) | **신규 elite_monsters + elite_loot_tables 1행씩 INSERT** |
| **(d) 이동 선택지** (`travel_choice_results`) | 마른 초원 야간 순찰 / 폐광길 짐 더미 / 먼지 길 여행자 조우 | #4 #8 (드물게 양측에서) | 기존 travel_choice_results 행에 재료 드랍 추가 또는 신규 옵션 |
| **(e) 고정 사건** (`settlement_3_pyegwang_reopen` step 1~6) | 폐광길 재개방 6단계 step별 보상 | #2 (step 2) / #5 (step 4) / #7 (step 1) / #9 (step 3) / #10 (step 6) | **기존 6행 quest_pools에 step별 재료 보상 추가** (chain_id 정정: `settlement_3_pyegwang_reopen`) |
| **(f) 신뢰도 단계 진입 보상** (보너스 트랙) | 신뢰도 2/3/4단계 진입 시 일회성 재료 지급 | #6 (2단계) / #1 또는 #3 (3단계) | `RegionStateNotifier.addSettlementTrust` 또는 `chain_quests` 단계 보상 컬럼 |

> **5종 출처(a~e) 모두에 최소 1종 연결 충족** ✅
> M5 완료 조건 "출처 3개 이상 연결" 초과 충족 ✅
> (f) 신뢰도 진입 보상은 (a)와 별도 트랙으로 보너스 출처 — 페이즈 4 #3에서 구현 분리

#### 2-2. 재료별 1차 출처(주 출처) + 2차 출처(보조)

| 재료 | 주 출처 (가장 빈번) | 보조 출처 (드물게) | 출처 다양성 |
|---|---|---|---|
| #1 녹슨 쇳조각 | (a) 폐광 labor 의뢰 | (b) 폐광 일반 조사 / (f) 3단계 진입 보상 | 의뢰 + 조사 + 신뢰도 = **3축** |
| #2 마른 가죽끈 | (a) 마른 초원 hunt / 도적 의뢰 | (e) step 2 도굴꾼 보상 | 의뢰 + 고정사건 = 2축 |
| #3 마른 약초 | (a) 약초상 채집 의뢰 (신뢰도 2단계 노출) | (a) 마른 초원 일반 채집 | 의뢰 단일 (가장 흔한 자원) |
| #4 산기슭 버섯 | (a) 마른 초원 채집 의뢰 | (d) 야간 순찰 이동 선택지 결과 | 의뢰 + 이동 = 2축 |
| #5 접착 수액 | (a) 약초상 채집 의뢰 (신뢰도 2단계 노출) | (e) step 4 광부 도구 회수 부수 보상 | 의뢰 + 고정사건 = 2축 |
| #6 빛바랜 천 조각 | (f) 신뢰도 2단계 진입 일회성 보상 | (a) 더스트빌 광장 잡동사니 의뢰(허드렛일 1건) | 신뢰도 진입 + 의뢰 = 2축 |
| #7 녹슨 곡괭이 머리 | (e) step 1 폐광 입구 정찰 보상 | (b) 폐광 숨겨진 발견 | 고정사건 + 조사 = 2축 |
| #8 폐광의 유물 파편 | (b) 폐광 숨겨진 발견 | (d) 폐광길 이동 선택지 / (a) 폐광 explore 의뢰 | 조사 + 이동 + 의뢰 = **3축** |
| #9 거대 박쥐 송곳니 | (c) step 3 거대 박쥐 엘리트 처치 | — (시그니처, 단일 출처) | 엘리트 단일 (희귀성 강조) |
| #10 고대 인장 조각 | (e) step 6 폐광 재개방식 클라이맥스 보상 | (b) 폐광 최심부 숨겨진 발견 (재시작 후 reset) | 고정사건 + 조사 = 2축 |

**설계 의도**:
- T1 흔한 재료(#1~#5)는 출처 단일 또는 2축. 일반 플레이로 자연스럽게 모임
- T2 핵심 재료(#6~#8)는 2~3축. "어디서 나오는지" 학습 동기 부여
- T3 희귀 재료(#9·#10)는 단일 출처 또는 2축. **시그니처 출처**로 사건의 격을 부여 (거대 박쥐만이 #9를 / step 6만이 #10을 줌)

#### 2-3. 4섹터별 재료 출처 다양성

| 섹터 | sector_type | 주 출처 재료 | slot 다양성 |
|---|---|---|---|
| sector 1 — 더스트빌 (village) | village | #6 신뢰도 보상 / #10 step 6 클라이맥스 | hide + relic |
| sector 2 — 폐광 (dungeon) | dungeon | #1 #7 #8 #9 #10 | ore + relic + monster_part (제작 핵심) |
| sector 3 — 마른 초원 (field) | field | #2 #3 #4 #5 | hide + herb (소비·기초) |
| sector 4 — 먼지로 덮인 길 (field) | field | (보조) #2 도적 호위 / #4 야간 이동 / #8 짐 더미 | hide + herb + relic 보조 |

**섹터 4(먼지로 덮인 길)는 주 출처 재료 0개**가 되도록 설계: M5 페이즈 1 단계에서 4번 섹터를 의도적으로 비워둔다(폐광/마른초원이 핵심 무대). 이는 **M5+ 다른 거점·다른 사건 라인**의 주 무대로 보존하려는 의도이며, settlement-trust-and-fixed-events.md §2.2의 "폐광길 재개방은 sector 4를 활용 안 함" 정책과 정합.

### 3. region_exclusive 정책

#### 3-1. NULL (범용) 6종 — `region_exclusive = NULL`

| # | 이름 | 범용 사유 |
|---|---|---|
| #1 녹슨 쇳조각 | M5+ 다른 광산 거점에서도 자연스러움 (보편적 자원) |
| #2 마른 가죽끈 | 어디든 가죽이 존재하는 가장 보편적 재료 |
| #3 마른 약초 | 가장 기본적인 약초. 어느 거점에서도 채집 가능 |
| #4 산기슭 버섯 | 산악·초원 환경 어디서나 발견 가능 |
| #6 빛바랜 천 조각 | 마을 잡동사니로부터 나오는 보편 재료 |
| #9 거대 박쥐 송곳니 | "거대 박쥐"는 더스트빌 한정 엘리트지만, 송곳니 자체는 다른 박쥐 엘리트에서도 같은 종류 드랍 가능 (M9+ 확장성 고려) |

#### 3-2. region_exclusive = 3 (더스트플레인 한정) 4종

| # | 이름 | 한정 사유 |
|---|---|---|
| #5 접착 수액 | 더스트플레인 먼지 환경 특산 식물의 분비물. 다른 거점 환경에선 분비 자체가 안 됨 |
| #7 녹슨 곡괭이 머리 | 더스트플레인 폐광의 역사적 잔재. 다른 거점 광산에는 동일 모델이 없음 |
| #8 폐광의 유물 파편 | 더스트플레인 폐광 한정 고대 유물 시리즈 |
| #10 고대 인장 조각 | 폐광 최심부 한정. 사건 라인의 시그니처 재료 |

**설계 의도**: 4종은 모두 "더스트플레인 폐광"의 정체성과 직결되는 재료. M5+ 다른 거점이 추가되어도 이 4종은 더스트빌에서만 나오게 한다 → **거점별 재료 차별화의 베이스라인**.

#### 3-3. M5 시작 거점 한정의 의미

M5는 시작 거점(region 3) 단일 거점에서만 플레이가 일어나므로, NULL/3 구분의 즉각적 차이는 없다(둘 다 더스트빌에서만 드랍). 그러나 후속 마일스톤(M7 다중 거점)에서:
- NULL 6종 → 다른 거점에서도 자연스럽게 등장 (거점간 재료 공유)
- region 3 한정 4종 → 더스트플레인 회귀 동기 (다른 거점 진출 후에도 폐광 깊이 들어가야 얻음)

이 정책이 **거점간 재료 차별화의 첫 사례**가 된다.

### 4. 첫 제작 목표 3개 입력 재료 검증

roadmap M5(라인 962~968)의 3개 대표 제작 목표가 본 문서의 재료 10종으로 모두 더스트빌 안에서 완성 가능한지 검증한다.

#### 4-1. 낡은 용병단 깃발 복원 (guild_equipment artifact, T2~T3)

**입력 재료** (수량은 페이즈 2 #2에서 최종 확정, 본 문서는 권고):

| 재료 | 수량 | 출처 |
|---|---|---|
| #2 마른 가죽끈 | ×3 | 마른 초원 hunt 의뢰 (다수 입수 가능) |
| #5 접착 수액 | ×2 | 약초상 채집 의뢰 (신뢰도 2단계 이후) |
| #6 빛바랜 천 조각 | ×1 | 신뢰도 2단계 진입 일회성 보상 (또는 광장 잡동사니 허드렛일) |

**서사**: 잘린 가죽끈으로 깃대와 천을 묶고, 접착 수액으로 봉합한다. 광장에서 발견된 오래된 천이 깃발의 원형이 된다.

**출처 다양성**: 의뢰(마른초원 hunt) + 의뢰(약초상 채집) + 신뢰도 진입 보상 = **3축**
**검증**: 모두 더스트빌 안에서 입수 가능 ✅
**권장 완성 시점**: 신뢰도 2단계 도달 직후 (첫 30~45분, 페이즈 2 #1 시뮬레이션 기준)

#### 4-2. 광부의 단검 (personal_equipment weapon, T2)

| 재료 | 수량 | 출처 |
|---|---|---|
| #1 녹슨 쇳조각 | ×3 | 폐광 labor 의뢰 (다수 입수 가능) |
| #2 마른 가죽끈 | ×1 | 마른 초원 hunt 의뢰 |
| #7 녹슨 곡괭이 머리 | ×1 | step 1 폐광 입구 정찰 보상 (또는 폐광 숨겨진 발견) |

**서사**: 폐광에서 회수한 곡괭이 머리를 단검 형태로 다듬고, 녹슨 쇳조각을 손잡이 보강에 쓰며, 가죽끈으로 마무리한다.

**출처 다양성**: 의뢰(폐광 labor) + 의뢰(마른초원 hunt) + 고정사건(step 1 보상) = **3축**
**검증**: 모두 더스트빌 안에서 입수 가능 ✅
**권장 완성 시점**: step 1 완료 직후 (첫 60~90분 — 페이즈 2 #2의 "첫 희귀 장비 90~150분" 곡선 시작점)

#### 4-3. 폐광의 유물 조각 (guild_equipment artifact, T3)

| 재료 | 수량 | 출처 |
|---|---|---|
| #8 폐광의 유물 파편 | ×3 | 폐광 숨겨진 발견 (다수 입수 가능) |
| #9 거대 박쥐 송곳니 | ×1 | step 3 거대 박쥐 엘리트 처치 (단일 입수) |
| #10 고대 인장 조각 | ×1 | step 6 폐광 재개방식 클라이맥스 (단일 입수) |

**서사**: 폐광에서 모은 유물 파편을 거대 박쥐의 송곳니로 다듬고, 마지막 발굴된 고대 인장 조각으로 봉인한다. 마을의 첫 지역 아티팩트.

**출처 다양성**: 조사(폐광 숨겨진) + 엘리트(거대 박쥐) + 고정사건(step 6) = **3축**
**검증**: 모두 더스트빌 안에서 입수 가능 ✅
**권장 완성 시점**: step 6 완료 직후 (첫 120~180분 — M5 누적 플레이 기준 첫 희귀 장비 90~150분에 근접)

#### 4-4. 3개 목표 통합 검증

| 검증 항목 | 결과 |
|---|---|
| 모든 입력 재료(8종 사용)가 더스트빌 안에서 입수 가능한가 | ✅ #1·#2·#5·#6·#7·#8·#9·#10 모두 더스트빌 |
| 사용되지 않은 재료 (#3 마른 약초, #4 산기슭 버섯) | M5 회복 포션 같은 후속 추가 레시피의 입력재로 페이즈 1 #3에서 활용 — 또는 향후 마일스톤 |
| 5종 출처 모두 첫 제작 목표 입력에 사용되는가 | ✅ 의뢰·조사·엘리트·이동선택지(권장 #4 결과로 #4 사용 시)·고정사건 모두 활용 |
| 3개 목표 누적 플레이 시간 정합 | 깃발 30~45분 / 단검 60~90분 / 유물조각 120~180분 — 페이즈 2 #2 검증 입력 |

### 5. M4 실제 구현 인프라와의 정합

본 문서는 settlement-quest-flow.md(2026-05-04 작성, M4 페이즈 4 #5 구현 종결)의 진실의 원천을 기준으로 한다.

#### 5-1. chain_id 네이밍 정정

| 변경 전 (페이즈 1 #1 작성 시 가정) | 변경 후 (실제 구현) |
|---|---|
| `settlement_pyegwang_reopen` | **`settlement_3_pyegwang_reopen`** |

**근거**: `tryActivateSettlement(regionId: 3, eventName: 'pyegwang_reopen')` 호출이 `settlement_{regionId}_{eventName}` 패턴으로 chain_id를 생성. M5 페이즈 4의 모든 SQL은 이 chain_id를 사용해야 한다.

#### 5-2. 기존 인프라 활용 — 신규 INSERT 최소화

M5 페이즈 4가 INSERT/UPDATE할 데이터의 형태:

| 테이블 | M5 작업 형태 | 비고 |
|---|---|---|
| `quest_pools` (16행: 허드렛일 10 + 고정사건 6) | **UPDATE** (신규 INSERT 아님) | 기존 행에 재료 드랍 보상 추가 |
| `chain_quests` (1행: `settlement_3_pyegwang_reopen`) | **UPDATE** (신규 INSERT 아님) | 단계별 추가 보상 컬럼 활용 또는 final_reward_json 확장 |
| `region_discoveries` (폐광 일반/숨겨진) | UPDATE 또는 신규 INSERT | 재료 드랍 추가 |
| `travel_choice_results` (기존 폐광/마른초원 결과) | UPDATE 또는 신규 INSERT | 일부 결과에 재료 드랍 추가 |
| `elite_monsters` | **신규 INSERT 1행** | 거대 박쥐 (region 3, sector 2) |
| `elite_loot_tables` | **신규 INSERT 1행** | 거대 박쥐 → #9 거대 박쥐 송곳니 |
| `items` | **신규 INSERT 10행** | M5 재료 10종 |

#### 5-3. 신뢰도 단계 진입 보상 트랙 분리

| 트랙 | 기존 (M4) | M5 추가 |
|---|---|---|
| 신뢰도 점수 (`RegionState.settlementTrust`) | step별 +10/+15/+20/+25/+30/+100 / 허드렛일 +2/+3/+5 | **변경 없음** |
| 단계 진입 일회성 보상 | 100G+50XP / 200G+100XP / 500G+200XP+100명성 | **재료 보상 추가** (#6 빛바랜 천 조각: 2단계 진입 ×1) |

**구현 방식 권고** (페이즈 4 #3 위임):
- (옵션 A) `RegionStateNotifier.addSettlementTrust` 내부에서 단계 변경 감지 시 InventoryItem 추가 호출
- (옵션 B) `chain_quests`에 `step_completion_extra_reward_json` 컬럼 추가 후 step 완료 시 적용
- (옵션 C) 신규 매핑 테이블 `settlement_trust_level_rewards(region_id, level, item_id, quantity)` 신설

→ 페이즈 4 명세에서 결정. 본 문서는 **2단계 진입 시 #6 ×1 / 3단계 진입 시 #1 ×3 또는 #3 ×3 / 4단계 진입 시 별도 없음** 정책만 권고.

#### 5-4. 페이즈 4 #3에서의 데이터 모델 결정

**본 문서 권고 강도**: **중간 위임**

기존 인프라에 재료 드랍을 연결할 때 다음 둘 중 페이즈 4 spec-writer가 결정:
- (a) 기존 행에 JSONB 컬럼 추가 (예: `quest_pools.material_reward_json`)
- (b) 신규 매핑 테이블 (`quest_pool_material_drops` / `chain_quest_step_material_rewards` 등)

본 문서는 모델 결정에 관여하지 않고, 페이즈 4 명세에서 위 둘 중 선택 + Hive 모델 갱신을 동반하는 마이그레이션을 권고한다.

### 6. 거대 박쥐 엘리트 신규 추가 권고

settlement-trust-and-fixed-events.md §2.2가 "step 3 박쥐 둥지 소탕 — 첫 엘리트 후보 (거대 박쥐 — M4 시점에 elite_monsters에 추가 검토)"로 명시했으나 M4에서는 미추가. M5에서 #9 거대 박쥐 송곳니의 시그니처 출처로 신규 추가한다.

#### 6-1. 거대 박쥐 elite_monsters 권고 행

| 컬럼 | 값 |
|---|---|
| id | `elite_giant_bat` (또는 페이즈 4 명명 규약) |
| name | 거대 박쥐 (또는 "갱도의 우두머리") |
| region_id | 3 |
| sector_index | 2 (폐광) |
| tier | 2 (T1 region이므로 T2 엘리트는 적정 도전 — 페이즈 2 #1에서 검증) |
| stat_overrides_json | (페이즈 2 / 페이즈 4에서 확정) |
| spawn_trigger | step 3 박쥐 둥지 소탕 quest_pool 진입 시 100% 확정 스폰 (선택적) 또는 일반 raid 시 확률 스폰 |
| 비고 | step 3 클리어 후 일반 raid에서도 낮은 확률 스폰 가능 — 송곳니 재획득 경로 |

#### 6-2. elite_loot_tables 권고 행

| 컬럼 | 값 |
|---|---|
| elite_monster_id | `elite_giant_bat` |
| item_id | `mat_monster_giant_bat_fang` (#9) |
| drop_rate | 1.0 (확정) — 시그니처 트로피 |
| quantity_min/max | 1 / 1 |

**M4 시점에 미추가된 이유 추정**: M4는 시작 거점 시스템 인프라 검증이 우선이었고, 엘리트 추가는 elite_loot_tables 데이터 채우기 부담을 동반함. M5에서 재료 시스템 도입과 함께 자연스럽게 추가하는 것이 인프라 분량의 분산.

### 7. 미사용 재료(#3·#4)의 후속 활용 가이드

첫 제작 목표 3개에서 사용되지 않는 #3 마른 약초·#4 산기슭 버섯의 향후 활용을 페이즈 1 #3에 위임한다.

| 재료 | 권장 후속 활용 |
|---|---|
| #3 마른 약초 | 회복 포션 / 약초상 의무실 시간 단축 보너스 / 사기 회복 소모품 (모두 M5 범위 외 또는 M5 부가 레시피) |
| #4 산기슭 버섯 | 야간 정찰 식량 / 식료품 / 사기 회복 소모품 (M5+ 일반 소모품 도입 시) |

**M5 페이즈 1 #3 권장**: 깃발/단검/유물조각 외 **부가 레시피 1~2개** ("응급 약 ×3" 같은 회복 보조 — 단, 회복 포션은 페이즈 1 #1 §8 "일반 소모품 M5 미도입" 정책과 충돌 가능. 대안: "약초 묶음 → 약초상 의뢰 보상 +20% 보너스 1회" 같은 **시스템 부가 효과** 결과물).

본 문서는 #3·#4가 단순히 미사용으로 남지 않게 페이즈 1 #3가 부가 레시피로 활용하는 지침을 제공함으로써 **재료 10종 전체의 활용 보장**을 명시한다.

---

## 현재 시스템과의 연관

### 영향받는 기존 시스템

| 시스템 | 영향 | 비고 |
|---|---|---|
| `quest_pools` (16행 기존) | UPDATE — 재료 드랍 보상 추가 | 페이즈 4 #3 |
| `chain_quests` (`settlement_3_pyegwang_reopen` 1행) | UPDATE — step별 재료 보상 / final reward 확장 | 페이즈 4 #3 |
| `region_discoveries` (폐광 행) | UPDATE 또는 신규 행 INSERT — 재료 드랍 추가 | 페이즈 4 #3 |
| `travel_choice_results` (폐광/마른초원 결과 일부) | UPDATE — 재료 드랍 옵션 추가 | 페이즈 4 #3 |
| `elite_monsters` | 신규 INSERT 1행 (거대 박쥐) | 페이즈 4 #3 |
| `elite_loot_tables` | 신규 INSERT 1행 (거대 박쥐 → #9) | 페이즈 4 #3 |
| `items` | 신규 INSERT 10행 (M5 재료 10종) | 페이즈 4 #1 |
| `RegionStateNotifier.addSettlementTrust` | 단계 진입 시 InventoryItem 추가 hook (옵션 A) | 페이즈 4 #3 |
| `ChainQuestService.onStepCompleted` | step 완료 시 InventoryItem 추가 hook | 페이즈 4 #3 |
| `EliteLootService.roll` | 거대 박쥐 처치 시 #9 드랍 (기존 로직 그대로 활용) | 변경 없음 (loot_tables 행 추가만) |
| `QuestCompletionService` | 의뢰 완료 시 InventoryItem 추가 hook | 페이즈 4 #3 |
| `InvestigationNotifier` | 조사 발견 시 InventoryItem 추가 hook | 페이즈 4 #3 |
| `TravelChoiceService` | 이동 선택 결과 시 InventoryItem 추가 hook | 페이즈 4 #3 |

### Hive 박스 영향

- **신규 박스 없음**. M2a 시점에 `inventory` 박스 신설 예정 → M5는 그 박스에 material 카테고리 행 추가만
- 기존 `regionStates` / `chainQuestProgress` / `mercenaries` 등 박스 모두 변경 없음

### Supabase 영향

- 신규 행: items 10 + elite_monsters 1 + elite_loot_tables 1 = **12행 신규 INSERT**
- 기존 행 UPDATE: quest_pools 16 + chain_quests 1 + region_discoveries N + travel_choice_results N
- `data_versions` 갱신 (items / elite_monsters / elite_loot_tables / quest_pools / chain_quests / region_discoveries / travel_choice_results 6~7개 테이블)

### 기존 아이디어 / 문서와의 관계

- `Docs/content-design/[content]20260504_material-taxonomy.md` (페이즈 1 #1) — 본 문서가 직접 적용
- `Docs/content-design/[content]20260503_starting-settlement.md` 거점 stub 텍스트 — 본 문서가 정식 재료로 채택 (녹슨 쇳조각·마른 가죽끈·마른 약초·산기슭 버섯·접착 수액 등)
- `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` — 본 문서가 step별 재료 보상 매핑으로 직접 확장
- `Docs/settlement-quest-flow.md` (M4 구현 후 진실의 원천) — chain_id 정정 + 기존 인프라 활용 명시

### 로드맵 의존성 재확인

- **선행**: M2a (items 테이블) / M2b (엘리트 인프라 + elite_loot_tables) / M3 (region_discoveries 숨겨진 발견 / travel_choice_results) / M4 (시작 거점 / 신뢰도 / 폐광길 6단계 인프라) — 모두 완료
- **후속**:
  - 페이즈 1 #3 — 본 문서의 재료 10종을 입력으로 제작 레시피 8~12개 + 첫 제작 목표 3개 시나리오 확정
  - 페이즈 2 #1 — 출처별 드랍률 곡선 + 첫 30~45분 첫 제작 시뮬레이션
  - 페이즈 4 #1 — items 10행 INSERT + elite_monsters/loot_tables 신규 행
  - 페이즈 4 #3 — 기존 quest_pools/chain_quests/region_discoveries/travel_choice_results UPDATE + 5종 출처 hook 추가

---

## 구현 우선순위 제안

본 문서는 **M5 페이즈 1 산출물 2/4**이며, 페이즈 1 #3·#4와 페이즈 2·4 모두의 입력이다. 우선순위 **높음**.

### 즉시 후속 착수 (페이즈 1 잔여)

1. **초반 제작 레시피 8~12개 + 첫 제작 목표 3개 시나리오** (페이즈 1 #3)
   - 본 문서 §4 첫 제작 목표 3개 입력 재료 검증을 입력으로 받아 수량·시간 곡선 확정
   - #3·#4 미사용 재료를 부가 레시피 1~2개로 활용
2. **인벤토리 재료 탭 + 대장간 제작 UI 컨셉** (페이즈 1 #4)
   - 본 문서 §3 region_exclusive 정책의 시각 차별화(테두리·아이콘) 정책 결정
   - 본 문서 §1 재료 10종을 인벤토리 sub-filter(slot 5종)에 어떻게 그룹핑할지

### balance-designer 의존 과제 (페이즈 2)

1. **재료 드랍률 곡선** (페이즈 2 #1) — 5종 slot × 출처 매핑 × T1~T3 분포 시뮬레이션
2. **제작 비용·시간** (페이즈 2 #2) — 첫 제작 30~45분, 첫 희귀 장비 90~150분 보장
3. **거대 박쥐 엘리트 스탯** (페이즈 2 #1 또는 #2) — T2 엘리트 적정 도전 곡선

### data-generator 의존 과제 (페이즈 3, 스킵 권장)

본 문서가 정의한 재료 10종 + 페이즈 1 #3 레시피 10~15개 = 총 20~25행은 페이즈 4 명세 SQL INSERT로 인라인 처리 권장 (페이즈 1 #1 §"data-generator 지시사항"과 동일 논거).

### spec-writer 의존 과제 (페이즈 4)

- **페이즈 4 #1**: items 10행 SQL INSERT + elite_monsters/elite_loot_tables 1행씩 INSERT
- **페이즈 4 #3**: 기존 quest_pools/chain_quests/region_discoveries/travel_choice_results UPDATE + 신뢰도 단계 진입 보상 hook + 5종 출처별 재료 드랍 hook

### 미결정 / 연기

- 첫 제작 목표 3개 입력 재료 수량의 최종 밸런스 — 페이즈 2 #2
- 출처별 드랍률 확률값 — 페이즈 2 #1
- 거대 박쥐 엘리트 스탯·스폰 트리거 정책 — 페이즈 2 / 페이즈 4
- 신뢰도 단계 진입 보상 트랙 구현 방식(옵션 A/B/C) — 페이즈 4 #3
- M5+ 다른 거점 도입 시 NULL 6종의 다른 거점 출처 매핑 — 후속 마일스톤
- region_exclusive 4종의 다중 region 한정 확장 — 후속 마일스톤

---

## data-generator 지시사항

본 기획서는 **재료 10종 명단 + 출처 매핑**을 정의하며, 페이즈 1 #3의 레시피와 합쳐 페이즈 4 명세 SQL INSERT로 인라인 처리한다. 별도 data-generator 호출 불필요.

페이즈 3 data-generator 호출이 필요한 경우 (선택적, 후속 마일스톤에서 다중 거점 재료가 추가될 시):
- 타입 스펙: `.claude/skills/data-generator/types/material.md` 미존재 → 작성 필요
- 입력 기획서: 페이즈 1 #1 + 본 문서
- 대상 테이블: `items` (category=material)
- 톤/세계관 가이드: 본 문서 §1-2 서사 톤 표 참조

---

## 체크리스트

- [x] 재료 10종 명단 확정 (slot ore 2 / hide 2 / herb 3 / relic_fragment 2 / monster_part 1)
- [x] tier 분포 확정 (T1 5 / T2 3 / T3 2)
- [x] region_exclusive 정책 확정 (NULL 6 / region 3 한정 4)
- [x] 5종 출처 매핑표 (의뢰·조사·엘리트·이동선택지·고정사건 모두 1종 이상 연결)
- [x] M5 완료 조건 "출처 3개 이상 연결" 충족 (실제 5개 모두 연결)
- [x] 4섹터별 재료 출처 다양성 (sector 4 의도적 비움 정책)
- [x] 첫 제작 목표 3개 입력 재료 검증 (모두 더스트빌 안에서 입수 가능)
- [x] 깃발 복원 / 광부의 단검 / 폐광의 유물 조각 각 출처 다양성 3축 확보
- [x] M4 실제 구현 인프라 정합 (chain_id `settlement_3_pyegwang_reopen` 정정)
- [x] 기존 quest_pools 16행 UPDATE 정책 명시 (신규 INSERT 아님)
- [x] 신뢰도 단계 진입 보상 트랙 분리 (#6 빛바랜 천 조각 2단계 진입)
- [x] 거대 박쥐 elite_monsters 신규 INSERT 권고 (M4 stub 정식화)
- [x] elite_loot_tables 신규 행 권고 (#9 거대 박쥐 송곳니)
- [x] 미사용 재료(#3·#4) 페이즈 1 #3 부가 레시피 활용 가이드
- [x] 페이즈 4 #3 데이터 모델 결정(JSONB vs 매핑 테이블) 위임
- [x] 후속 페이즈 안내 (페이즈 1 #3·#4 / 페이즈 2 #1·#2 / 페이즈 4 #1·#3)
