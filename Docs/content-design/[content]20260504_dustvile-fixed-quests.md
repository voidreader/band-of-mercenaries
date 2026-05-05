# 더스트빌 고정 임무 라인 + 허드렛일 컨텐츠 기획서

> 작성일: 2026-05-04
> 유형: 신규 컨텐츠 (M4 → M5 이행 전 콘텐츠 채우기)
> 선행 문서:
> - `[content]20260503_settlement-trust-and-fixed-events.md` — 6단계 구조·trust_threshold 매핑·저장소 결정
> - `[content]20260503_starting-settlement.md` — NPC 5명·인사말·섹터 구성
> 대상:
> - `quest_pools` 테이블 — `is_fixed=true` 6행 (폐광길 재개방 step 1~6) 텍스트 확정
> - `quest_pools` 테이블 — `is_fixed=false` 허드렛일 15행 텍스트 확정
> - 촌장 집 `상황 듣기` 대화 6개 (각 step 브리핑)

---

## 개요

M4 구현으로 시스템은 갖춰졌지만 실제 의뢰 텍스트와 NPC 대화가 비어 있다. 본 문서는 두 가지 콘텐츠를 확정한다.

1. **고정 사건 라인 "폐광길 재개방"** — 6단계 의뢰의 name·description·enemy_name·촌장 브리핑 텍스트를 완전히 정의한다.
2. **더스트빌 허드렛일 (난이도 1) 15개** — 4섹터에 걸쳐 자연스럽게 노출되는 첫 의뢰 풀을 정의한다.

수치(recommend_power·reward_gold·reward_xp)는 선행 문서(페이즈 2 #4)가 확정했지만, 본 문서의 데이터 입력 시 현재 밸런스 곡선을 참조한다.

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| Stardew Valley — Town Quests 게시판 | 난이도 1 단순 심부름이 마을 NPc 이름과 함께 "콩 10개 가져다줘"로 시작. 첫 30분 플레이어를 방향 없이 두지 않음 | 더스트빌 허드렛일도 마을 사람 이름 언급 + 구체적 장소("초원 북쪽 약초 무리")로 목적지를 암시 |
| Kingdom of Loathing — Council Quests | "The Council of Loathing needs your help" — 단일 허브(카운슬) NPC가 단계별로 다른 임무 부여. 설명이 짧고 직접적 | 파슨이 step마다 다른 브리핑을 준다. 문장 수 2~3줄, 세계관 키워드 포함. 영웅적 과장 없이 실용적 |
| Disco Elysium — 레퀴에 미시오넬 사건들 | 사건 step별로 "지금 상황이 이렇고, 다음에 뭘 해야 하는지"를 짧게 요약. 사건 진행감이 텍스트에서 느껴짐 | step 브리핑은 "지난 step에서 알게 된 것"을 1문장으로 요약한 뒤 "다음 step의 지시"로 넘어간다 |
| 아크메이지 (Archmage) — 미션 퀘스트 | 미션 설명이 짧고 반복성이 높지만, 이름과 지역명이 있어 세계가 살아있는 느낌 | 허드렛일 description은 1~2줄. "더스트빌 광장에서 행상인을 마을 입구까지 호위하라"처럼 장소를 명시 |

---

## 상세 설계

### 1. 고정 사건 라인: "폐광길 재개방" (6단계)

신뢰도 단계와 함께 순차 노출되는 6단계 사건 라인. 선행 문서에서 구조는 확정됨. 본 절은 **텍스트 전체**를 확정한다.

#### 1.1 전체 구조 요약

```
신뢰도 1 → step 1: 폐광 입구 정찰 (explore / D1 / dungeon)
신뢰도 1 → step 2: 도굴꾼 흔적 추적 (hunt / D1 / field)
──── 신뢰도 2 진입 ────
신뢰도 2 → step 3: 박쥐 둥지 소탕 (raid / D2 / dungeon)
신뢰도 2 → step 4: 광부의 도구 회수 (escort / D2 / dungeon)
──── 신뢰도 3 진입 ────
신뢰도 3 → step 5: 갱도 안전 확보 (raid / D3 / dungeon)
신뢰도 3 → step 6: 폐광 재개방식 안전 관리 (survey / D3 / village)
──── 신뢰도 4 진입 ────
```

#### 1.2 step별 완전 텍스트

---

**[step 1] 폐광 입구 정찰**

| 항목 | 값 |
|------|-----|
| `quest_type` | explore |
| `difficulty` | 1 |
| `sector_type` | dungeon |
| `fixed_chain_id` | dustvile_pyegwang_reopen |
| `fixed_step` | 1 |
| `trust_threshold` | 1 |
| `name` | 폐광 입구 정찰 |
| `description` | 무너진 폐광 입구를 살펴보고 진입 가능 여부를 보고하라. 오랫동안 닫혀 있던 탓에 박쥐 떼가 입구 주변에 자리를 잡았다. 가까이 다가서면 반응할 수 있으니 주의가 필요하다. |
| `enemy_name` | 박쥐 떼 |
| `촌장_브리핑` | "광산 입구가 어떻게 됐는지 직접 눈으로 봐와야겠어. 10년 넘게 닫아뒀더니 박쥐들이 자릴 잡았다더군. 가까이만 가봐도 충분하니 무리하진 말고." |

---

**[step 2] 도굴꾼 흔적 추적**

| 항목 | 값 |
|------|-----|
| `quest_type` | hunt |
| `difficulty` | 1 |
| `sector_type` | field |
| `fixed_chain_id` | dustvile_pyegwang_reopen |
| `fixed_step` | 2 |
| `trust_threshold` | 1 |
| `name` | 도굴꾼 흔적 추적 |
| `description` | 누군가 폐광에 몰래 드나든 흔적이 초원 쪽으로 이어진다. 발자국을 따라 추적하여 도굴꾼의 실체를 파악하고, 필요하다면 쫓아내라. 마을 물건을 챙겨갔을 가능성이 있다. |
| `enemy_name` | 도굴꾼 |
| `촌장_브리핑` | "정찰 보고 잘 들었어. 그런데 이번엔 다른 문제가 생겼어. 초원 쪽에 낯선 발자국이 이어진다는 거야. 폐광 안에서 뭔가 들고 나간 것 같은데, 누군지 알아와야겠어." |

---

**[step 3] 박쥐 둥지 소탕**

| 항목 | 값 |
|------|-----|
| `quest_type` | raid |
| `difficulty` | 2 |
| `sector_type` | dungeon |
| `fixed_chain_id` | dustvile_pyegwang_reopen |
| `fixed_step` | 3 |
| `trust_threshold` | 2 |
| `name` | 박쥐 둥지 소탕 |
| `description` | 폐광 내부 깊숙이 거대 박쥐 둥지가 자리 잡고 있다. 둥지를 그대로 두면 광산 재개방이 불가능하다. 소탕에는 상당한 전투력이 필요하며, 여러 용병을 함께 보내는 것을 권장한다. |
| `enemy_name` | 거대 박쥐 |
| `촌장_브리핑` | "이제 본격적으로 들어가야 해. 박쥐 둥지가 안쪽에 있다는군. 평범한 박쥐가 아니야 — 크기가 사람 반 만 하다는 소리도 있어. 조심하게. 여러 명 데려가는 게 좋을 거야." |

---

**[step 4] 광부의 도구 회수**

| 항목 | 값 |
|------|-----|
| `quest_type` | escort |
| `difficulty` | 2 |
| `sector_type` | dungeon |
| `fixed_chain_id` | dustvile_pyegwang_reopen |
| `fixed_step` | 4 |
| `trust_threshold` | 2 |
| `name` | 광부의 도구 회수 |
| `description` | 마을의 노인 데얀이 10년 전 폐광에 두고 나온 곡괭이와 받침목을 찾아달라 한다. 혼자 들어가기는 무서우니 동행해달라는 부탁이다. 폐광 안은 아직 어수선하지만, 박쥐 둥지 소탕 이후 주요 위협은 줄었다. |
| `enemy_name` | null |
| `촌장_브리핑` | "마을 데얀 영감 알지? 그 노인이 10년 전 광산 닫을 때 곡괭이를 두고 나왔대. 오래된 물건이라 꼭 찾고 싶다는데 혼자는 무서운 거지. 자네가 동행해줄 수 있겠나?" |

---

**[step 5] 갱도 안전 확보**

| 항목 | 값 |
|------|-----|
| `quest_type` | raid |
| `difficulty` | 3 |
| `sector_type` | dungeon |
| `fixed_chain_id` | dustvile_pyegwang_reopen |
| `fixed_step` | 5 |
| `trust_threshold` | 3 |
| `name` | 갱도 안전 확보 |
| `description` | 무너진 갱도 내부를 보강하고 마지막으로 남은 위협을 제거하라. 도굴꾼 일당의 잔당이 안쪽에 숨어 있다는 제보가 있다. 이 작업이 끝나면 폐광 재개방이 가능해진다. |
| `enemy_name` | 도굴꾼 잔당 |
| `촌장_브리핑` | "이제 거의 다 왔어. 갱도 안쪽에 도굴꾼들이 아직 숨어있다는군. 마지막 한 고비야. 이번만 끝내주면 마을 사람들이 다시 광산 일을 시작할 수 있어. 부탁하네." |

---

**[step 6] 폐광 재개방식 안전 관리**

| 항목 | 값 |
|------|-----|
| `quest_type` | survey |
| `difficulty` | 3 |
| `sector_type` | village |
| `fixed_chain_id` | dustvile_pyegwang_reopen |
| `fixed_step` | 6 |
| `trust_threshold` | 3 |
| `name` | 폐광 재개방식 안전 관리 |
| `description` | 마을 광장에서 폐광 재개방 기념식이 열린다. 마을 사람 전원이 참석하는 자리인 만큼 만일의 사태를 대비해 안전 관리를 맡아달라는 촌장의 부탁이다. 화려하지 않지만 마을로서는 10년 만의 경사다. |
| `enemy_name` | null |
| `촌장_브리핑` | "마침내 광산 문을 열 수 있게 됐어. 마을 사람이 다 나오는 자리야. 조용하게, 탈 없이 치러야 해. 자네한테 안전을 맡기겠네. 꼭 부탁하네." |

---

#### 1.3 사건 미진행 / 완료 후 대화 (상황 듣기 fallback)

| 상태 | title | body |
|------|-------|------|
| 진행 전 (progress == null) | 파슨의 이야기 | "마을이 이렇게 된 건 10년도 넘은 일이지. 광산이 닫히면서 떠나는 사람이 늘었어. 이제 남은 사람들이라도 먹고 살아야 하는데..." |
| 완료 후 (status == completed) | 파슨의 이야기 | "자네 덕분에 이제 마을이 다시 움직이기 시작했어. 광산에서 일하려는 사람도 돌아오고 있고. 고마워." |

---

### 2. 허드렛일 (난이도 1) 15개

신뢰도 단계와 무관하게 시작부터 파견 탭에 노출되는 기본 의뢰 풀. 4섹터를 골고루 활용하며 게임 초반 2시간의 파견 반복을 뒷받침한다.

#### 2.1 설계 원칙

- 문장 길이: 2줄 이내. "어디서 무엇을"이 명확한 단문
- 보상 임시값: `reward_gold = 80~100` (D1 기본 × 1.0배수 ± 세부 조정은 balance-designer)
- `is_fixed = false` — 일반 자동 갱신 주기에 포함
- 섹터 커버리지: sector 1(village) 2개 / sector 2(dungeon) 5개 / sector 3(field) 4개 / sector 4(field) 4개

#### 2.2 섹터별 허드렛일 목록

**섹터 1 — 더스트빌 (village)**

| ID | name | quest_type | description | enemy_name |
|----|------|-----------|-------------|-----------|
| `qp_dv_v1_guard` | 마을 야간 경비 | escort | 더스트빌 마을 광장의 야간 경비를 서달라는 부탁이다. 최근 밤마다 낯선 인기척이 있다는 주민 신고가 있었다. | 낯선 침입자 |
| `qp_dv_v2_supply` | 행상 짐 내리기 | labor | 외지에서 온 행상의 짐을 창고까지 옮겨달라는 단순 일손 부탁이다. 힘은 필요하지만 위험은 없다. | null |

**섹터 2 — 폐광 (dungeon)**

| ID | name | quest_type | description | enemy_name |
|----|------|-----------|-------------|-----------|
| `qp_dv_d1_scout` | 폐광 외곽 순찰 | explore | 폐광 입구 주변을 한 바퀴 돌며 이상 징후를 확인하라. 완전히 들어가지는 않아도 된다. | null |
| `qp_dv_d2_bat` | 박쥐 쫓기 | hunt | 폐광 입구를 맴도는 박쥐 무리가 마을 창고를 위협한다. 쫓아내거나 처치하라. | 박쥐 |
| `qp_dv_d3_tool` | 버려진 도구 수거 | explore | 폐광 입구 주변에 10년 전 놓고 간 도구들이 흩어져 있다. 쓸 만한 것들을 찾아 마을로 가져오라. | null |
| `qp_dv_d4_rubble` | 잡석 정리 | labor | 폐광 입구 앞에 무너진 잡석이 통행을 막고 있다. 치워야 마을 사람들이 안전하게 다닐 수 있다. | null |
| `qp_dv_d5_check` | 지반 안전 점검 | explore | 폐광 입구 천장 지반이 불안하다는 보고가 있다. 전문가 대신 상태를 살펴보고 위험 여부를 판단하라. | null |

**섹터 3 — 마른 초원 (field)**

| ID | name | quest_type | description | enemy_name |
|----|------|-----------|-------------|-----------|
| `qp_dv_f3_herb` | 약초 채집 | labor | 네리스 약초상에서 의뢰한 약초 채집. 마른 초원 북쪽에 산버섯과 약초 무리가 있다고 한다. 위험하진 않지만 들개에 주의하라. | null |
| `qp_dv_f3_dog` | 들개 퇴치 | hunt | 초원 들개가 마을 경계까지 내려와 양을 위협한다. 쫓아내거나 처치하라. | 들개 |
| `qp_dv_f3_patrol` | 초원 야간 순찰 | escort | 마른 초원 외곽을 야간에 순찰하며 이상 징후를 확인하라. 마을 외곽 안전이 목적이다. | null |
| `qp_dv_f3_water` | 음용수 확인 | explore | 초원 웅덩이 물을 마시고 이상이 생겼다는 주민 신고가 있다. 현장을 조사하여 오염 여부를 확인하라. | null |

**섹터 4 — 먼지로 덮인 길 (field)**

| ID | name | quest_type | description | enemy_name |
|----|------|-----------|-------------|-----------|
| `qp_dv_r4_escort` | 행상인 호위 | escort | 외지에서 온 행상인이 더스트빌까지 안전하게 오고 싶다 한다. 길 입구부터 마을까지 동행하라. | null |
| `qp_dv_r4_guide` | 여행자 길 안내 | escort | 길을 잃은 여행자가 마을로 가는 방향을 물어왔다. 마을 입구까지 안전하게 안내하라. | null |
| `qp_dv_r4_cargo` | 버려진 짐 확인 | explore | 길가에 주인 없는 짐 보따리가 방치되어 있다는 신고가 있다. 가져다 마을 창고에 보고하라. 도적과 관련됐을 수 있으니 주의하라. | 도적 |
| `qp_dv_r4_bandit` | 도적 흔적 조사 | hunt | 먼지 덮인 길 인근에 도적 활동 흔적이 나타났다. 현장을 조사하고 도적을 발견하면 쫓아내라. | 도적 |

---

### 3. 세계관 일관성 체크

신뢰도 단계별로 등장하는 의뢰 분위기가 자연스럽게 이어지는지 점검한다.

| 신뢰도 1단계 (의심) | 신뢰도 2단계 (인지) | 신뢰도 3단계 (친근) |
|-------------------|-------------------|-------------------|
| 허드렛일 중심 | step 3·4 (위험 증가) | step 5·6 (클라이맥스) |
| "쓸 만한지 봐야겠다" 톤 | "믿고 맡겨보자" 톤 | "이제 우리 편이다" 톤 |
| 파슨: 짧고 건조한 말투 | 파슨: 기대와 걱정이 섞임 | 파슨: 신뢰와 감사가 느껴짐 |

**체크포인트**:
- step 1·2는 난이도 1 — 허드렛일과 동일 난이도대에서 시작. "별 거 아닌 일"처럼 시작하는 흐름이 의도적임.
- step 3에서 처음으로 난이도 2로 올라가며 전투 서사가 등장. 신뢰도 2단계가 이 전환의 관문.
- step 6의 survey 타입은 전투 없는 "행사 관리" — 클라이맥스를 전투보다 마을 전체의 참여로 표현. 용병단이 마을의 손님이 아닌 구성원이 됐다는 서사 신호.

---

## 현재 시스템과의 연관

| 항목 | 영향 | 비고 |
|------|------|------|
| `quest_pools` | 6행 INSERT (is_fixed=true) + 15행 INSERT (is_fixed=false) | operation-bom에서 직접 입력 |
| 촌장 집 `상황 듣기` | 1.2절 촌장_브리핑 텍스트를 `chiefHouseScreen.dart` 하드코딩 또는 `chain_quests.description` 필드 재사용 | 현재 코드는 `chainData?.description`을 body로 사용 — chain_quests 테이블의 step별 description이 브리핑 텍스트로 사용됨 |
| `chain_quests` 테이블 | step 1~6의 `description` 필드에 촌장 브리핑 텍스트 입력 | 현재 `상황 듣기`가 chain_quests.description을 참조하므로 이 필드를 브리핑 전용으로 활용 |
| `quest_narratives` | survey 타입에 대한 서사 템플릿 추가 필요 (현재 labor/survey × 4결과 × 2변형 = 16개 존재) | 기존 서사 있음 확인, 추가 불필요 |
| `QuestGenerator` | is_fixed=true 행을 일반 갱신에서 제외하는 로직 — 이미 구현됨 (quest_provider.dart 참조) | 변경 없음 |

---

## 구현 우선순위

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| 폐광길 재개방 6단계 의뢰 텍스트 입력 | **높음** | 촌장 집 `상황 듣기`가 현재 "사건이 진행 중입니다" fallback만 표시. 실 텍스트 입력 즉시 UX 개선 |
| chain_quests 테이블 description 업데이트 | **높음** | 상황 듣기 브리핑이 chain_quests.description 참조이므로 동시 처리 필요 |
| 허드렛일 15개 quest_pools INSERT | **높음** | 현재 더스트빌에서 의미 있는 난이도 1 의뢰가 거의 없어 초반 루프가 공허함 |
| survey 타입 quest_types 테이블 확인 | **중간** | step 6이 survey 타입 사용. 기존 4타입(raid/hunt/escort/explore) 외 survey 유효성 확인 필요 |

---

## data-generator 지시사항

허드렛일 15개의 나머지 수치 필드(recommend_power·reward_gold·reward_xp·min_combat_power 등)와 quest_pools 포맷 전체를 생성할 때 data-generator를 사용한다. 폐광길 재개방 6행은 본 문서에서 완전히 정의되어 있으므로 인라인 처리 권장.

- **대상 타입**: `labor-quest` (허드렛일 특화 신규 타입 — types/labor-quest.md 작성 필요) 또는 기존 `quest-pool` 타입 변형
- **대상 테이블**: `quest_pools`
- **생성 수량**: 15행
- **톤/세계관 가이드**:
  - 더스트플레인 키워드: 먼지·산악·폐광·변방·박쥐·도굴꾼·약초·행상·들개
  - 문장 길이: 2줄 이내. "어디서 무엇을 하라"가 명확한 단문
  - 영웅적 과장 없음. "마을 일손 부탁" 톤이 기본
  - 인명 사용 시 마을 NPC 이름 우선: 파슨(촌장) / 하겐(대장장이) / 네리스(약초상) / 데얀(광부 노인)
- **구조적 제약**:
  - is_fixed = false (전 행)
  - difficulty = 1 (전 행)
  - recommend_power: 10~15 범위 (D1 기준)
  - reward_gold: 80~100 (D1 × 1.0배수 기준)
  - reward_xp: 20~25 (D1 기준)
  - sector_type 분포: village 2 / dungeon 5 / field (초원) 4 / field (길) 4
  - quest_type 분포: labor 3 / explore 4 / hunt 3 / escort 5
  - enemy_name: hunt·escort 일부만 설정 (null 허용)
- **수치 출처**: `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` 페이즈 2 #4 참조
- **특수 요구**:
  - 섹터별 ID 접두사 준수: village=`qp_dv_v*` / dungeon=`qp_dv_d*` / field 초원=`qp_dv_f3_*` / field 길=`qp_dv_r4_*`
  - 2.2절의 name·description·enemy_name을 그대로 사용 (내용 임의 변경 금지)
  - 누락된 수치 필드(recommend_power·reward_gold·reward_xp·min_combat_power)만 data-generator가 채움

---

## 후속 작업

1. **즉시**: operation-bom에서 폐광길 재개방 6행 quest_pools INSERT + chain_quests description 업데이트
2. **즉시**: 허드렛일 15행 quest_pools INSERT (`/data-generator quest-pool --brief @Docs/content-design/[content]20260504_dustvile-fixed-quests.md`)
3. **M5 착수 전**: survey 타입이 quest_types 테이블에 없으면 추가 (6단계 step 6 의존)
4. **향후 (M5+)**: 먼지로 덮인 길(sector 4)을 주무대로 하는 두 번째 사건 라인 추가 가능 (본 문서에서 의도적으로 제외한 섹터)
