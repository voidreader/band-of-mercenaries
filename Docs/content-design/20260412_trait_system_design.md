# 트레잇 시스템 고도화 기획서

> 작성일: 2026-04-12  
> 유형: 고도화  
> 버전: 1.0 초안

## 개요

현재 4개의 단순 패시브 트레잇(강인함, 노련함, 겁쟁이, 광전사)을 **106개의 트레잇 + 진화/충돌 시스템**으로 확장한다. 트레잇은 단순한 스탯 보너스가 아니라 **플레이 기록이 만들어내는 용병의 정체성**이다.

**기대 효과:**
- 용병 개성 강화 → 감정적 애착 증가
- 진화/조합 경로 선택 → 전략적 깊이
- 플레이 스타일 다양화 → 리텐션 상승

---

## 레퍼런스 분석

| 게임/작품 | 차용 포인트 |
|----------|------------|
| **Darkest Dungeon** | Quirk 시스템: 긍정/부정 특성이 공존, 부정 특성도 상황에 따라 유용. "실패도 성장이다" 철학의 원형 |
| **Crusader Kings 3** | 선천(Congenital)/성격(Personality) 분리 구조, 이벤트를 통한 특성 획득, 영구적 선천 특성 |
| **Rimworld** | Pawn 생성 시 배경(Background) 0~2개 랜덤 → 캐릭터의 기본 성격과 능력 방향 결정 |
| **Melvor Idle** | 마스터리 시스템: 특정 활동 반복 → 관련 역량 성장. 방치형 게임에서의 행동 기반 성장 모델 |
| **특성 쌓는 김전사** | 136개 기본 특성의 조합 진화, 슬롯 기반 빌드 구성. 본 게임에서는 "진화 방향 선택 = 빌드"로 적용 |

---

## 시스템 규칙

### 슬롯 구조

```
┌─────────────────────────────────────────────────────┐
│  선천 슬롯 (최대 3개) — 영구 보유, 삭제 불가         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐         │
│  │ Physical  │ │Background │ │  Talent   │         │
│  │ (0~1개)   │ │ (0~1개)   │ │ (0~1개)   │         │
│  └───────────┘ └───────────┘ └───────────┘         │
│  • 모집 시 랜덤 1~3개 부여 (용병 티어 무관)           │
│  • 빈 슬롯은 게임 내 이벤트로 채울 수 있음            │
│  • 한번 획득하면 영구 고정 (향후 삭제 기능에도 면역)    │
├─────────────────────────────────────────────────────┤
│  후천 슬롯 (최대 4개) — 플레이 기반 획득/진화         │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐         │
│  │CombatStyle│ │ Survival  │ │ Behavior  │         │
│  ├───────────┤ ├───────────┤ ├───────────┤         │
│  │  Mental   │ │Experience │ │  (비어짐)  │         │
│  └───────────┘ └───────────┘ └───────────┘         │
│  • 5개 카테고리 중 최대 4개만 보유 → 항상 1개 포기    │
│  • 카테고리당 1개 규칙                               │
│  • 충돌/진화/조합 규칙 적용                          │
└─────────────────────────────────────────────────────┘
  총 최대: 7개 (선천 3 + 후천 4)
```

### 핵심 규칙

| 규칙 | 설명 |
|------|------|
| 카테고리당 1개 | 같은 카테고리의 트레잇은 1개만 보유 가능 |
| 재획득 불가 | 한번 획득 후 소멸된 트레잇은 다시 획득할 수 없음 |
| 선천 영구 | 선천 트레잇은 삭제/교체 불가 (진화도 불가) |
| 단일 진화 | 후천 acquired → 같은 카테고리 evolved (원본 소멸, 대체) |
| 조합 진화 | 후천 A(카테고리X) + 후천 B(카테고리Y) → evolved C(카테고리Z). A, B 모두 소멸 |
| 진화 비가역 | 진화/조합은 되돌릴 수 없음 |
| 슬롯 해방 | 조합 진화 시 원본 카테고리 슬롯이 비워져 새 트레잇 획득 가능 |
| 충돌 배제 | 충돌 관계인 트레잇은 동시에 보유할 수 없음 |

### 선천 트레잇의 트리거 역할

선천 트레잇은 직접 진화하지 않지만, **후천 트레잇 획득의 전제조건 또는 촉진제** 역할을 한다:
- 특정 선천 트레잇 보유 시 관련 후천 트레잇 획득 조건이 **완화** (예: 필요 횟수 30% 감소)
- 일부 후천 트레잇은 특정 선천 트레잇이 **필수 전제**

### 트레잇 효과 정의 방침

> PD 지침: "트레잇이 영향을 주는 수치들은 추후 개발한다. 기획단계에서는 막연하게 트레잇이 영향을 주고싶은 요소를 텍스트로 정의해둔다."

본 기획서의 모든 효과는 **텍스트 기술**이며, 구체적 수치(%, 배수)는 밸런스 설계 단계에서 확정한다.

---

## 카테고리 정의

### 선천 카테고리 (3개)

| key | name | 설명 | 역할 |
|-----|------|------|------|
| Physical | 육체적 특성 | 타고난 신체 조건 | HP, DEF, Speed, 부상/회복에 영향 |
| Background | 배경 | 출신과 과거 경력 | 퀘스트 유형 친화도, 경제적 보너스 |
| Talent | 재능 | 타고난 기질과 잠재력 | 후천 트레잇 획득 촉진, 특수 능력 |

### 후천 카테고리 (5개)

| key | name | 설명 | 역할 |
|-----|------|------|------|
| CombatStyle | 전투 성향 | 경험으로 형성된 전투 방식 | ATK, DEF, 성공률에 영향 |
| Survival | 생존 성향 | 위기를 겪으며 형성된 생존 전략 | 부상/사망 확률, 회복에 영향 |
| Behavior | 행동 스타일 | 파견 패턴에서 드러나는 행동 양식 | 솔로/팀 보너스, 이동/탐험에 영향 |
| Mental | 정신 상태 | 성공/실패 경험이 만든 심리 상태 | 성공률 편차, 특수 판정에 영향 |
| Experience | 경험 | 축적된 경험에서 나오는 역량 | 종합 스탯, 보상, 명성에 영향 |

---

## 행동 지표 (23개)

트레잇 획득 조건 판정에 사용되는 용병별 누적 통계.

| 분류 | key | 설명 |
|------|-----|------|
| **파견 기본** | total_dispatch_count | 총 파견 횟수 |
| | success_count | 성공 횟수 |
| | failure_count | 실패 횟수 |
| | great_success_count | 대성공 횟수 |
| | great_failure_count | 대실패 횟수 |
| **파견 조건** | solo_dispatch_count | 단독 파견 횟수 |
| | team_dispatch_count | 2인 이상 파견 횟수 |
| | high_difficulty_count | 난이도 4+ 성공 횟수 |
| | low_difficulty_count | 난이도 1~2 성공 횟수 |
| **퀘스트 유형** | raid_count | 약탈 퀘스트 완료 수 |
| | subjugation_count | 토벌 퀘스트 완료 수 |
| | escort_count | 호위 퀘스트 완료 수 |
| | explore_count | 탐험 퀘스트 완료 수 |
| **생존** | near_death_count | 근사 경험 횟수 |
| | injury_count | 부상 횟수 |
| | survived_great_failure | 대실패 생존 횟수 |
| **이동/탐험** | tier_max_visited | 방문한 최고 리전 티어 |
| | unique_region_count | 방문한 고유 리전 수 |
| | total_travel_distance | 누적 이동 거리 |
| **경제/성장** | total_gold_earned | 누적 골드 수익 |
| | current_level | 현재 레벨 |
| **연속 기록** | consecutive_success | 연속 성공 횟수 (현재) |
| | consecutive_failure | 연속 실패 횟수 (현재) |

---

## 트레잇 목록

### 선천 — Physical (12개)

타고난 신체 조건. 모집 시 랜덤 부여 또는 이벤트 획득.

| # | key | name | description | effect_text |
|---|-----|------|-------------|-------------|
| 1 | strong_build | 강인한 체격 | 타고난 근육질 체형으로 웬만한 충격에도 끄떡없다 | HP 증가, 부상 확률 감소 |
| 2 | agile_body | 날렵한 몸 | 가볍고 유연한 몸놀림을 타고났다 | Speed 증가, 회피 보너스 |
| 3 | giant | 거구 | 보통 사람보다 한 뼘 이상 큰 거대한 체격 | HP 대폭 증가, Speed 감소 |
| 4 | small_frame | 왜소함 | 작고 눈에 띄지 않는 체형이지만, 그래서 더 빠르다 | Speed 증가, HP 감소, 탐험/정찰 보너스 |
| 5 | iron_skin | 철갑피부 | 유난히 질기고 단단한 피부를 가졌다 | DEF 증가, 부상 확률 감소 |
| 6 | hawk_eye | 매의 눈 | 남다른 시력으로 먼 거리의 위험도 놓치지 않는다 | 탐험/호위 성공률 보너스 |
| 7 | tireless | 끈질긴 체력 | 좀처럼 지치지 않는 놀라운 지구력 | 피로 회복 시간 감소 |
| 8 | frail | 허약체질 | 태어날 때부터 몸이 약했다. 하지만 약한 만큼 조심하는 법을 안다 | HP 감소, 부상 시 회복 느림. Survival 트레잇 획득 촉진 |
| 9 | regenerator | 자연치유 | 상처가 보통 사람보다 놀랍도록 빨리 아문다 | 부상/피로 회복 속도 증가 |
| 10 | beast_blood | 야수의 피 | 억제할 수 없는 야성이 피 속에 흐른다 | ATK 증가, 부상 시 회복 느림 |
| 11 | tough_bones | 단단한 골격 | 뼈가 비정상적으로 단단하여 쉽게 부러지지 않는다 | 부상 확률 감소 |
| 12 | quick_reflex | 빠른 반사신경 | 위험에 대한 몸의 반응이 놀라울 정도로 빠르다 | 사망 확률 감소, 회피 보너스 |

---

### 선천 — Background (12개)

출신과 과거 경력. 모집 시 랜덤 부여 또는 이벤트 획득.

| # | key | name | description | effect_text |
|---|-----|------|-------------|-------------|
| 13 | noble_birth | 귀족 출신 | 몰락했든 아니든, 귀족의 피가 흐른다 | 명성 획득 보너스, 호위 퀘스트 보너스 |
| 14 | soldier_origin | 전직 군인 | 정규군에서 복무한 경험이 몸에 배어있다 | 토벌 퀘스트 보너스, 팀 파견 시 성공률 소폭 증가 |
| 15 | thief_origin | 전직 도둑 | 남의 물건에 손대는 데 익숙한 과거가 있다 | 약탈 퀘스트 보너스, 이동 이벤트 골드 획득 증가 |
| 16 | hunter_origin | 사냥꾼 출신 | 숲과 산에서 짐승을 쫓으며 살았다 | 탐험 퀘스트 보너스, 이동 시간 감소 |
| 17 | merchant_origin | 상인 출신 | 금화의 무게를 손끝으로 가늠할 줄 안다 | 퀘스트 골드 보상 증가 |
| 18 | slave_origin | 노예 출신 | 최악의 환경에서도 살아남은 강인한 생존력 | 사망 확률 감소, Survival 트레잇 획득 촉진 |
| 19 | wanderer_origin | 방랑자 출신 | 정착하지 못하고 대륙을 떠돌던 삶 | 이동 시간 감소, 이동 이벤트 긍정 확률 증가 |
| 20 | gladiator_origin | 투기장 출신 | 관중 앞에서 피를 흘려본 경험이 있다 | ATK 보너스, 고난도 퀘스트 성공률 증가 |
| 21 | outlaw_origin | 무법자 출신 | 법 바깥에서 살아온 위험한 과거 | 약탈 보상 대폭 증가, 명성 획득 감소 |
| 22 | monastery_origin | 수도원 출신 | 기도와 노동으로 점철된 규율적인 과거 | 회복 속도 보너스, Mental 부정 트레잇 저항 |
| 23 | refugee_origin | 난민 출신 | 고향을 잃고 떠돌았던 아픈 기억 | 이동 관련 보너스, Survival 트레잇 획득 촉진 |
| 24 | pit_fighter_origin | 뒷골목 싸움꾼 | 규칙 없는 싸움에서 살아남은 거리의 본능 | ATK/DEF 소폭 증가, 솔로 파견 보너스 |

---

### 선천 — Talent (11개)

타고난 기질과 잠재력. 모집 시 랜덤 부여 또는 이벤트 획득.

| # | key | name | description | effect_text |
|---|-----|------|-------------|-------------|
| 25 | berserker_talent | 광전사의 피 | 전투에서 이성을 잃고 폭주하는 야수적 본능 | ATK 대폭 증가, DEF 감소. CombatStyle 공격형 트레잇 획득 촉진 |
| 26 | fearful_nature | 겁쟁이 | 타고난 소심함. 그러나 누구보다 빨리 위험을 감지한다 | 사망 확률 대폭 감소, 성공률 감소. Survival 트레잇 획득 촉진 |
| 27 | born_leader | 타고난 지도자 | 사람들이 자연스럽게 따르는 카리스마 | 팀 파견 시 성공률 보너스. Behavior 리더십 트레잇 획득 촉진 |
| 28 | quick_learner | 빠른 학습자 | 한 번 보면 체득하는 놀라운 학습 능력 | XP 획득 보너스 |
| 29 | sixth_sense | 육감 | 설명할 수 없는 위험 감지 능력 | 사망 확률 감소, 이동 이벤트 부정 효과 감소 |
| 30 | iron_will | 철의 의지 | 어떤 상황에서도 꺾이지 않는 정신력 | Mental 부정 트레잇 획득 확률 감소 |
| 31 | natural_charisma | 천부적 매력 | 타인의 호감을 사는 자연스러운 매력 | 명성 획득 보너스, 호위 퀘스트 보너스 |
| 32 | lucky_star | 타고난 행운 | 이상하리만큼 운이 좋다 | 대성공 확률 증가, 이동 이벤트 보너스 |
| 33 | cursed_fate | 저주받은 운명 | 불행이 따라다니지만, 역경이 단련을 만든다 | 대실패 확률 증가. Experience 트레잇 획득 촉진 |
| 34 | battle_instinct | 전투 본능 | 싸움에 관해서만큼은 본능적으로 알고 있다 | CombatStyle 트레잇 획득 조건 완화 |
| 35 | survival_instinct | 생존 본능 | 위험에서 살아남는 법을 본능적으로 안다 | Survival 트레잇 획득 조건 완화 |

---

### 후천 — CombatStyle (14개: acquired 8 + evolved 6)

#### acquired (8개)

경험을 통해 형성된 전투 방식.

| # | key | name | description | effect_text | 획득 조건 |
|---|-----|------|-------------|-------------|----------|
| 36 | tactician | 전술가 | 전투의 흐름을 읽고 팀을 이끄는 지휘관 | 팀 파견 성공률 보너스 | team_dispatch >= 15 AND success >= 10 |
| 37 | charger | 돌격대장 | 적진에 가장 먼저 뛰어드는 무모한 용기 | ATK 보너스, 약탈 성공률 보너스 | raid >= 10 AND great_success >= 3 |
| 38 | duelist | 결투가 | 일대일에서 진가를 발휘하는 외길 싸움꾼 | 솔로 파견 시 ATK/성공률 보너스 | solo_dispatch >= 15 AND high_difficulty >= 5 |
| 39 | guardian | 수호자 | 동료를 지키는 것이 최우선인 방패 | DEF 보너스, 팀원 부상 확률 감소 | escort >= 12 AND team_dispatch >= 10 |
| 40 | ambusher | 매복 전문가 | 기습의 달인. 적이 알아차리기 전에 끝낸다 | 성공률 보너스, 탐험 퀘스트 보너스 | explore >= 10 AND success >= 12 |
| 41 | brawler | 난투꾼 | 부상을 두려워하지 않는 거친 전투 스타일 | ATK/DEF 소폭 증가 | total_dispatch >= 20 AND injury >= 5 |
| 42 | skirmisher | 유격대 | 빠르게 치고 빠지는 게릴라 전술 | Speed 보너스, 약탈 성공률 보너스 | raid >= 8 AND total_travel_distance >= 50 |
| 43 | sentinel | 파수꾼 | 한 자리를 목숨 걸고 지키는 끈기 | DEF 보너스, 호위 퀘스트 보너스 | escort >= 15 AND low_difficulty >= 10 |

#### evolved — 단일 진화 (3개)

| # | key | name | description | effect_text | 진화 원본 | 추가 조건 |
|---|-----|------|-------------|-------------|----------|----------|
| 44 | blade_master | 검의 달인 | 수천 번의 결투가 만들어낸 완벽한 검술 | 솔로 ATK 극대화, 성공률 대폭 보너스 | duelist | solo_dispatch >= 30 AND high_difficulty >= 10 |
| 45 | warlord | 전쟁군주 | 전장을 지배하는 압도적인 존재감 | ATK 극대화, 약탈 보상 대폭 보너스 | charger | raid >= 25 AND great_success >= 10 |
| 46 | iron_wall | 철벽 | 그 뒤에 있으면 절대 다치지 않는다 | DEF 극대화, 팀원 보호 극대화 | guardian | escort >= 25 AND team_dispatch >= 20 |

#### evolved — 조합 진화 (3개)

| # | key | name | description | effect_text | 재료 1 | 재료 2 |
|---|-----|------|-------------|-------------|--------|--------|
| 47 | slayer | 학살자 | 돌진하는 자신감이 만든 학살 병기 | ATK 극대화, 대성공 확률 대폭 증가 | charger (CS) | confident (Mental) |
| 48 | shadow_hunter | 그림자 사냥꾼 | 혼자, 조용히, 완벽하게 | 솔로 전체 스탯 보너스, 탐험 보너스 극대화 | ambusher (CS) | lone_wolf (Behavior) |
| 49 | strategist | 전략가 | 경험과 전술이 합쳐진 완벽한 지휘 | 팀 성공률 극대화, 파견 비용 감소 | tactician (CS) | veteran (Experience) |

---

### 후천 — Survival (13개: acquired 7 + evolved 6)

#### acquired (7개)

위기를 겪으며 형성된 생존 전략.

| # | key | name | description | effect_text | 획득 조건 |
|---|-----|------|-------------|-------------|----------|
| 50 | survivor | 생존 전문가 | 죽을 뻔한 경험이 만든 생존의 기술 | 사망 확률 감소, 부상 시 회복 보너스 | near_death >= 3 AND success >= 5 |
| 51 | cautious | 신중함 | 항상 최악을 대비하고 움직인다 | 성공률 소폭 감소, 부상/사망 확률 대폭 감소 | consecutive_success >= 8 |
| 52 | tough | 억척스러움 | 부상을 입어도 끝까지 임무를 수행한다 | 부상 확률 감소, 부상 상태 패널티 완화 | injury >= 8 AND success >= 10 |
| 53 | evasive | 회피의 달인 | 위험을 본능적으로 피해간다 | 사망 확률 대폭 감소, ATK 감소 | survived_great_failure >= 3 AND near_death >= 5 |
| 54 | field_medic | 야전 치료사 | 전장에서 응급 처치하는 법을 익혔다 | 팀 파견 시 팀원 부상 회복 가속 | team_dispatch >= 15 AND injury >= 5 |
| 55 | scavenger | 수색 전문가 | 전장의 잔해에서 유용한 것을 찾아낸다 | 실패한 퀘스트에서도 소량 골드 획득 | failure >= 10 AND total_dispatch >= 15 |
| 56 | endurer | 인내의 화신 | 끝없는 고통을 견디는 데 특화되었다 | 부상 회복 속도 증가, HP 보너스 | injury >= 10 AND total_dispatch >= 25 |

#### evolved — 단일 진화 (3개)

| # | key | name | description | effect_text | 진화 원본 | 추가 조건 |
|---|-----|------|-------------|-------------|----------|----------|
| 57 | unyielding | 불굴 | 절대 무너지지 않는다. 어떤 상황에서도 | 사망 확률 극소화, 부상 확률 대폭 감소 | survivor | near_death >= 10 AND survived_great_failure >= 5 |
| 58 | fortress_mind | 철옹성 | 흔들리지 않는 마음이 몸까지 지배했다 | DEF 보너스, 부상/사망 확률 대폭 감소 | cautious | consecutive_success >= 15 AND total_dispatch >= 30 |
| 59 | unkillable | 죽지 않는 자 | 부상이 일상인 전장에서 만들어진 불사의 육체 | 부상 회복 극대화, 사망 확률 극소화 | tough | injury >= 15 AND near_death >= 8 |

#### evolved — 조합 진화 (3개)

| # | key | name | description | effect_text | 재료 1 | 재료 2 |
|---|-----|------|-------------|-------------|--------|--------|
| 60 | phoenix | 불사조 | 행운과 생존력이 만든 기적. 죽을 뻔할수록 강해진다 | 사망 확률 극소화, 근사 후 일시 스탯 대폭 증가 | survivor (Surv) | lucky (Exp) |
| 61 | iron_body | 강철 육체 | 규율적 훈련과 인내가 빚어낸 철의 몸 | HP/DEF 대폭 증가, 부상 확률 감소 | endurer (Surv) | disciplined (Behavior) |
| 62 | danger_sense | 위기감지 | 경계심과 회피 본능이 하나가 되었다 | 모든 부정 이벤트 확률 대폭 감소 | evasive (Surv) | vigilant (Mental) |

---

### 후천 — Behavior (14개: acquired 8 + evolved 6)

#### acquired (8개)

파견 패턴에서 드러나는 행동 양식.

| # | key | name | description | effect_text | 획득 조건 |
|---|-----|------|-------------|-------------|----------|
| 63 | lone_wolf | 고독한 늑대 | 혼자 해내는 것을 선호하는 독행자 | 솔로 파견 시 성공률/ATK 보너스 | solo_dispatch >= 15 |
| 64 | team_player | 협동가 | 동료와 함께할 때 더 강해진다 | 팀 파견 시 전체 성공률 보너스 | team_dispatch >= 15 |
| 65 | scout | 정찰병 | 미지의 땅을 탐색하는 데 특화되었다 | 탐험 보너스, 이동 이벤트 긍정 확률 증가 | explore >= 10 AND unique_region >= 8 |
| 66 | reckless | 무모함 | 위험을 두려워하지 않는다. 아니, 즐긴다 | 고난도 성공률 보너스, 부상 확률 증가 | high_difficulty >= 8 AND great_failure >= 3 |
| 67 | disciplined | 규율적 | 규칙을 따르고 계획대로 움직인다 | 성공률 안정화(편차 감소), 팀 파견 보너스 | consecutive_success >= 10 AND total_dispatch >= 20 |
| 68 | opportunist | 기회주의자 | 이익이 되는 순간을 놓치지 않는다 | 대성공 시 추가 보상, 골드 보너스 | great_success >= 8 AND total_gold_earned >= 5000 |
| 69 | nomad | 유목민 | 한 곳에 머무르지 않는 바람 같은 존재 | 이동 시간 감소, 이동 이벤트 보너스 | unique_region >= 15 AND total_travel_distance >= 100 |
| 70 | mentor | 조언자 | 후배를 이끄는 노련한 선배 | 팀 파견 시 팀원 XP 보너스 | current_level >= 4 AND team_dispatch >= 20 |

#### evolved — 단일 진화 (3개)

| # | key | name | description | effect_text | 진화 원본 | 추가 조건 |
|---|-----|------|-------------|-------------|----------|----------|
| 71 | shadow | 그림자 | 존재감을 완전히 지운 완벽한 독행자 | 솔로 전체 보너스 극대화 | lone_wolf | solo_dispatch >= 30 AND unique_region >= 10 |
| 72 | commander | 지휘관 | 팀을 이끄는 완벽한 리더십 | 팀 파견 시 전체 성공률/보상 보너스 | team_player | team_dispatch >= 30 AND success >= 25 |
| 73 | pathfinder | 길잡이 | 어디든 길을 찾아내는 대륙의 전문가 | 이동 시간 대폭 감소, 이동 이벤트 극대화 | scout | unique_region >= 25 AND explore >= 15 |

#### evolved — 조합 진화 (3개)

| # | key | name | description | effect_text | 재료 1 | 재료 2 |
|---|-----|------|-------------|-------------|--------|--------|
| 74 | daredevil | 무모한 도전자 | 무모함과 돌격이 결합된 극한의 도전자 | 고난도 성공률 대폭 보너스, 저난도 보상 감소 | reckless (Behavior) | charger (CS) |
| 75 | silent_leader | 침묵의 지도자 | 규율과 경계심이 만든 조용한 카리스마 | 팀 파견 시 부상 확률 감소, 성공률 보너스 | disciplined (Behavior) | vigilant (Mental) |
| 76 | free_spirit | 자유로운 영혼 | 방랑과 생존이 결합된 대륙의 자유인 | 이동 보너스 극대화, 모든 퀘스트 유형 소폭 보너스 | nomad (Behavior) | survivor (Surv) |

---

### 후천 — Mental (15개: acquired 8 + evolved 7)

#### acquired (8개)

성공과 실패의 경험이 만든 심리 상태.

| # | key | name | description | effect_text | 획득 조건 |
|---|-----|------|-------------|-------------|----------|
| 77 | confident | 자신감 | 연속된 성공이 만든 흔들리지 않는 자신감 | 성공률 보너스, 대성공 확률 증가 | consecutive_success >= 5 AND success >= 15 |
| 78 | trauma | 트라우마 | 연이은 실패가 남긴 깊은 상처 | 성공률 감소, 사망 확률 감소(본능적 회피) | consecutive_failure >= 5 |
| 79 | vigilant | 경계심 | 근사 경험이 만든 날카로운 경계 태세 | 사망 확률 감소, 기습 저항 | near_death >= 3 AND survived_great_failure >= 2 |
| 80 | arrogant | 오만 | 능력에 대한 과도한 자신감 | 성공률 보너스(자기 과신), 대실패 확률 증가 | great_success >= 10 AND current_level >= 4 |
| 81 | composed | 침착함 | 어떤 위기에도 냉정함을 유지한다 | 판정 안정화(편차 감소), 고난도 성공률 보너스 | high_difficulty >= 10 AND consecutive_success >= 5 |
| 82 | vengeful | 복수심 | 실패의 분노가 내면에서 불타고 있다 | 실패 후 다음 파견 성공률/ATK 보너스 | injury >= 5 AND great_failure >= 3 |
| 83 | empathic | 공감 | 동료의 감정을 읽고 함께 아파한다 | 팀 파견 시 전체 사기 보너스, 팀원 회복 가속 | team_dispatch >= 20 AND escort >= 10 |
| 84 | paranoid | 편집증 | 모든 것이 위험해 보인다. 그래서 준비를 게을리하지 않는다 | 사망 확률 대폭 감소, 성공률 감소, 부상 확률 감소 | near_death >= 5 AND failure >= 10 |

#### evolved — 단일 진화 (4개)

trauma는 이후 경험에 따라 두 갈래로 분기한다.

| # | key | name | description | effect_text | 진화 원본 | 추가 조건 |
|---|-----|------|-------------|-------------|----------|----------|
| 85 | fearless | 두려움 없음 | 두려움을 완전히 극복한 절대적 정신력 | 고난도 성공률 대폭 보너스, 사망 확률 감소 | confident | high_difficulty >= 15 AND great_success >= 10 |
| 86 | hardened | 무뎌진 마음 | 트라우마를 이겨내고 단단해진 정신 | 모든 판정 안정화, Mental 부정 트레잇 면역 | trauma | consecutive_success >= 5 AND total_dispatch >= 20 |
| 87 | broken | 망가진 자 | 깊어진 상처가 만든 예측 불가한 존재 | 성공률 감소, 하지만 대성공/대실패 확률 동시 증가 | trauma | consecutive_failure >= 8 AND great_failure >= 5 |
| 88 | focused | 극도의 집중 | 침착함의 극치. 잡념이 사라진 상태 | 고난도 성공률 극대화, 모든 판정 안정화 | composed | high_difficulty >= 20 AND success >= 30 |

#### evolved — 조합 진화 (3개)

| # | key | name | description | effect_text | 재료 1 | 재료 2 |
|---|-----|------|-------------|-------------|--------|--------|
| 89 | madman | 광기 | 복수심과 무모함이 결합된 광기 | ATK 대폭 증가, 판정 편차 극대화(높은 변동성) | vengeful (Mental) | reckless (Behavior) |
| 90 | hero | 영웅 | 자신감과 협동심이 결합된 영웅적 기질 | 팀 전체 성공률 보너스, 명성 획득 대폭 증가 | confident (Mental) | team_player (Behavior) |
| 91 | coward_king | 겁쟁이 군주 | 편집증적 신중함이 만든 생존의 달인 | 사망 확률 0%에 근접, 성공률 감소 | paranoid (Mental) | cautious (Surv) |

---

### 후천 — Experience (15개: acquired 9 + evolved 6)

#### acquired (9개)

축적된 경험에서 나오는 역량.

| # | key | name | description | effect_text | 획득 조건 |
|---|-----|------|-------------|-------------|----------|
| 92 | veteran | 베테랑 | 수많은 전장을 경험한 노련한 용병 | 전체 스탯 소폭 증가, 성공률 보너스 | total_dispatch >= 30 AND success >= 20 |
| 93 | lucky | 행운 | 이상하게 좋은 결과가 자주 따라온다 | 대성공 확률 증가 | great_success >= 8 |
| 94 | unlucky | 불운 | 뭘 해도 꼬이지만, 그래서 더 단단해졌다 | 대실패 확률 증가, 부상 회복 속도 증가 | great_failure >= 5 AND failure >= 15 |
| 95 | well_traveled | 노련한 여행자 | 대륙 구석구석을 누빈 경험 | 이동 시간 감소, 이동 이벤트 보너스, 리전 정보 보너스 | unique_region >= 20 AND total_travel_distance >= 150 |
| 96 | specialist | 전문가 | 한 분야에 깊이 파고든 장인 | 해당 퀘스트 유형 성공률/보상 대폭 보너스 | (특정 퀘스트 유형 완료) >= 20 |
| 97 | jack_of_all | 만능인 | 뭐든 어느 정도는 해내는 다재다능함 | 모든 퀘스트 유형 소폭 보너스 | raid >= 5 AND subjugation >= 5 AND escort >= 5 AND explore >= 5 |
| 98 | scarred_veteran | 역전의 용사 | 수많은 부상이 훈장처럼 남아있다 | 부상 확률 감소, 팀 사기 보너스 | injury >= 10 AND success >= 20 |
| 99 | gold_nose | 금 냄새꾼 | 돈이 되는 일을 본능적으로 찾아낸다 | 퀘스트 골드 보상 증가, 이동 이벤트 골드 보너스 | total_gold_earned >= 10000 |
| 100 | seasoned | 노련함 | 오랜 경험이 만든 안정적인 실력 | 성공률 안정화(높은 하한선), 판정 편차 감소 | total_dispatch >= 40 AND current_level >= 3 |

#### evolved — 단일 진화 (3개)

| # | key | name | description | effect_text | 진화 원본 | 추가 조건 |
|---|-----|------|-------------|-------------|----------|----------|
| 101 | elite | 정예 | 수많은 전투가 증명한 최고 수준의 용병 | 전체 스탯 증가, 성공률 보너스 | veteran | total_dispatch >= 50 AND high_difficulty >= 15 |
| 102 | blessed | 축복받은 자 | 행운이 행운을 부르는 선순환 | 대성공 확률 극대화, 이동 이벤트 보너스 | lucky | great_success >= 15 AND success >= 25 |
| 103 | cursed_survivor | 저주의 생존자 | 불운을 뚫고 살아남은 역설적 존재 | 대실패 시 사망 면역, 부상 회복 속도 대폭 증가 | unlucky | survived_great_failure >= 5 AND near_death >= 8 |

#### evolved — 조합 진화 (3개)

| # | key | name | description | effect_text | 재료 1 | 재료 2 |
|---|-----|------|-------------|-------------|--------|--------|
| 104 | legend | 전설 | 베테랑의 경험과 자신감이 합쳐진 전설적 존재 | 명성 획득 극대화, 모든 퀘스트 보상 보너스 | veteran (Exp) | confident (Mental) |
| 105 | treasure_hunter | 보물사냥꾼 | 여행 경험과 정찰 능력이 결합된 보물 탐색가 | 탐험 보상 극대화, 희귀 이벤트 발생 확률 증가 | well_traveled (Exp) | scout (Behavior) |
| 106 | master_of_all | 만물박사 | 다방면의 경험과 치료 지식이 결합된 만능인 | 모든 퀘스트 유형 보너스, 팀원 부상 회복 가속 | jack_of_all (Exp) | field_medic (Surv) |

---

## 관계 테이블

### 충돌 관계 (16쌍)

충돌 관계인 트레잇은 동시에 보유할 수 없다. 하나를 보유한 상태에서 충돌 트레잇의 획득 조건을 충족해도 획득되지 않는다.

| # | 트레잇 A | 카테고리 | 트레잇 B | 카테고리 | 서사적 근거 |
|---|---------|----------|---------|----------|------------|
| 1 | berserker_talent | Talent | cautious | Survival | 광전사의 피와 신중함은 양립 불가 |
| 2 | berserker_talent | Talent | composed | Mental | 광전사의 피와 침착함은 양립 불가 |
| 3 | fearful_nature | Talent | reckless | Behavior | 겁쟁이는 무모해질 수 없다 |
| 4 | fearful_nature | Talent | confident | Mental | 타고난 소심함과 자신감은 양립 불가 |
| 5 | iron_will | Talent | trauma | Mental | 철의 의지는 트라우마에 굴하지 않는다 |
| 6 | born_leader | Talent | lone_wolf | Behavior | 지도자 기질과 고독한 늑대는 양립 불가 |
| 7 | cursed_fate | Talent | lucky | Experience | 저주받은 운명과 행운은 양립 불가 |
| 8 | charger | CombatStyle | cautious | Survival | 돌격과 신중함은 양립 불가 |
| 9 | charger | CombatStyle | evasive | Survival | 돌격하는 자는 회피하지 않는다 |
| 10 | guardian | CombatStyle | lone_wolf | Behavior | 수호자는 혼자 다니지 않는다 |
| 11 | duelist | CombatStyle | team_player | Behavior | 결투가는 팀 플레이에 맞지 않는다 |
| 12 | sentinel | CombatStyle | reckless | Behavior | 파수꾼은 무모하지 않다 |
| 13 | reckless | Behavior | cautious | Survival | 무모함과 신중함은 양립 불가 |
| 14 | arrogant | Mental | team_player | Behavior | 오만한 자는 협동하지 않는다 |
| 15 | lone_wolf | Behavior | field_medic | Survival | 고독한 늑대는 남을 치료하지 않는다 |
| 16 | nomad | Behavior | sentinel | CombatStyle | 유목민은 한자리를 지키지 않는다 |

### 단일 진화 경로 (16개)

같은 카테고리 내에서 acquired → evolved. 원본은 소멸되고 진화 트레잇으로 대체된다.

| # | 원본 (acquired) | → | 결과 (evolved) | 카테고리 | 추가 조건 |
|---|----------------|---|---------------|----------|----------|
| 1 | duelist | → | blade_master | CombatStyle | solo_dispatch >= 30 AND high_difficulty >= 10 |
| 2 | charger | → | warlord | CombatStyle | raid >= 25 AND great_success >= 10 |
| 3 | guardian | → | iron_wall | CombatStyle | escort >= 25 AND team_dispatch >= 20 |
| 4 | survivor | → | unyielding | Survival | near_death >= 10 AND survived_great_failure >= 5 |
| 5 | cautious | → | fortress_mind | Survival | consecutive_success >= 15 AND total_dispatch >= 30 |
| 6 | tough | → | unkillable | Survival | injury >= 15 AND near_death >= 8 |
| 7 | lone_wolf | → | shadow | Behavior | solo_dispatch >= 30 AND unique_region >= 10 |
| 8 | team_player | → | commander | Behavior | team_dispatch >= 30 AND success >= 25 |
| 9 | scout | → | pathfinder | Behavior | unique_region >= 25 AND explore >= 15 |
| 10 | confident | → | fearless | Mental | high_difficulty >= 15 AND great_success >= 10 |
| 11 | trauma | → | hardened | Mental | consecutive_success >= 5 AND total_dispatch >= 20 |
| 12 | trauma | → | broken | Mental | consecutive_failure >= 8 AND great_failure >= 5 |
| 13 | composed | → | focused | Mental | high_difficulty >= 20 AND success >= 30 |
| 14 | veteran | → | elite | Experience | total_dispatch >= 50 AND high_difficulty >= 15 |
| 15 | lucky | → | blessed | Experience | great_success >= 15 AND success >= 25 |
| 16 | unlucky | → | cursed_survivor | Experience | survived_great_failure >= 5 AND near_death >= 8 |

> 참고: trauma는 이후 경험에 따라 hardened(극복) 또는 broken(심화) 두 갈래로 분기한다.  
> 원본 트레잇마다 단일 진화 경로가 있는 것은 아님. 진화 경로가 없는 acquired 트레잇은 조합 진화의 재료로 사용된다.

### 조합 진화 (15개)

서로 다른 카테고리의 후천 트레잇 2개를 조합. 두 원본 모두 소멸하고, 결과 트레잇이 지정된 카테고리 슬롯에 배치된다.

| # | 재료 1 (카테고리) | + | 재료 2 (카테고리) | → | 결과 (카테고리) | 슬롯 효과 |
|---|-----------------|---|-----------------|---|---------------|----------|
| 1 | charger (CS) | + | confident (Mental) | → | slayer (CS) | Mental 슬롯 해방 |
| 2 | ambusher (CS) | + | lone_wolf (Behavior) | → | shadow_hunter (CS) | Behavior 슬롯 해방 |
| 3 | tactician (CS) | + | veteran (Exp) | → | strategist (CS) | Exp 슬롯 해방 |
| 4 | survivor (Surv) | + | lucky (Exp) | → | phoenix (Surv) | Exp 슬롯 해방 |
| 5 | endurer (Surv) | + | disciplined (Behavior) | → | iron_body (Surv) | Behavior 슬롯 해방 |
| 6 | evasive (Surv) | + | vigilant (Mental) | → | danger_sense (Surv) | Mental 슬롯 해방 |
| 7 | reckless (Behavior) | + | charger (CS) | → | daredevil (Behavior) | CS 슬롯 해방 |
| 8 | disciplined (Behavior) | + | vigilant (Mental) | → | silent_leader (Behavior) | Mental 슬롯 해방 |
| 9 | nomad (Behavior) | + | survivor (Surv) | → | free_spirit (Behavior) | Surv 슬롯 해방 |
| 10 | vengeful (Mental) | + | reckless (Behavior) | → | madman (Mental) | Behavior 슬롯 해방 |
| 11 | confident (Mental) | + | team_player (Behavior) | → | hero (Mental) | Behavior 슬롯 해방 |
| 12 | paranoid (Mental) | + | cautious (Surv) | → | coward_king (Mental) | Surv 슬롯 해방 |
| 13 | veteran (Exp) | + | confident (Mental) | → | legend (Exp) | Mental 슬롯 해방 |
| 14 | well_traveled (Exp) | + | scout (Behavior) | → | treasure_hunter (Exp) | Behavior 슬롯 해방 |
| 15 | jack_of_all (Exp) | + | field_medic (Surv) | → | master_of_all (Exp) | Surv 슬롯 해방 |

> **설계 의도**: 하나의 acquired 트레잇이 여러 조합 레시피에 등장할 수 있다.  
> 예: `confident`는 slayer(#1), hero(#11), legend(#13)의 재료. 플레이어는 하나만 선택해야 한다.  
> 이것이 "선택 = 포기" 철학의 핵심 구현이다.

### 선천-후천 시너지 (트리거 관계)

선천 트레잇이 특정 후천 트레잇 획득을 촉진한다. 획득 조건의 수치 요구량이 완화된다.

| 선천 트레잇 | 촉진 대상 | 효과 |
|------------|----------|------|
| berserker_talent | charger, brawler, skirmisher (CS 공격형) | 획득 조건 30% 완화 |
| fearful_nature | survivor, cautious, evasive (Surv) | 획득 조건 30% 완화 |
| born_leader | team_player, mentor, disciplined (Behavior 리더형) | 획득 조건 30% 완화 |
| battle_instinct | CombatStyle 전체 acquired | 획득 조건 20% 완화 |
| survival_instinct | Survival 전체 acquired | 획득 조건 20% 완화 |
| quick_learner | 모든 후천 트레잇 | 획득 조건 10% 완화 (XP 기반 간접 효과) |
| cursed_fate | unlucky, scarred_veteran (Exp 역경형) | 획득 조건 30% 완화 |
| frail (Physical) | survivor, evasive (Surv 방어형) | 획득 조건 20% 완화 |
| slave_origin (Background) | survivor, tough, endurer (Surv) | 획득 조건 20% 완화 |
| refugee_origin (Background) | nomad, scout (Behavior 이동형) | 획득 조건 20% 완화 |
| soldier_origin (Background) | tactician, guardian, sentinel (CS 조직형) | 획득 조건 20% 완화 |
| gladiator_origin (Background) | duelist, brawler, charger (CS 전투형) | 획득 조건 20% 완화 |

> 시너지는 **촉진(완화)** 역할이며 필수 조건이 아니다.  
> 선천 트레잇 없이도 모든 후천 트레잇 획득 가능. 선천은 경로를 빠르게 열어줄 뿐.

---

## 트레잇 수량 요약

| 분류 | 카테고리 | innate | acquired | evolved (단일) | evolved (조합) | 소계 |
|------|----------|--------|----------|---------------|---------------|------|
| 선천 | Physical | 12 | - | - | - | 12 |
| 선천 | Background | 12 | - | - | - | 12 |
| 선천 | Talent | 11 | - | - | - | 11 |
| 후천 | CombatStyle | - | 8 | 3 | 3 | 14 |
| 후천 | Survival | - | 7 | 3 | 3 | 13 |
| 후천 | Behavior | - | 8 | 3 | 3 | 14 |
| 후천 | Mental | - | 8 | 4 | 3 | 15 |
| 후천 | Experience | - | 9 | 3 | 3 | 15 |
| **합계** | | **35** | **40** | **16** | **15** | **106** |

---

## 예시 빌드: 용병 성장 시나리오

### 시나리오 A: "전설의 학살자"

```
[모집]
  선천: 광전사의 피(Talent) + 투기장 출신(Background)  → 2개

[초기 플레이: 약탈 중심 솔로 파견]
  → raid_count 10+ → 돌격대장(CS) 획득 (berserker_talent 시너지로 조건 완화)
  → consecutive_success 5+ → 자신감(Mental) 획득

[조합 진화]
  돌격대장(CS) + 자신감(Mental) → 학살자(CS)
  → Mental 슬롯 해방!

[후속 성장]
  → 비워진 Mental 슬롯에 침착함(Mental) 획득 가능
  → 또는 다른 카테고리 트레잇 추가

최종: 광전사의 피 / 투기장 출신 / 학살자 / 침착함 / ... → ATK 극대화 빌드
```

### 시나리오 B: "불사의 겁쟁이 군주"

```
[모집]
  선천: 겁쟁이(Talent) + 노예 출신(Background) + 강인한 체격(Physical) → 3개

[초기 플레이: 안전한 저난도 팀 파견]
  → fearful_nature 시너지로 Survival 획득 촉진
  → near_death_count 3+ → 생존 전문가(Surv) 획득
  → failure_count 10+ → 편집증(Mental) 획득

[겁쟁이와 자신감 충돌]
  → fearful_nature ↔ confident 충돌 → 자신감 획득 불가
  → 대신 cautious 획득 → consecutive_success 8+

[조합 진화]
  편집증(Mental) + 신중함(Surv) → 겁쟁이 군주(Mental)
  → Surv 슬롯 해방!

최종: 겁쟁이 / 노예 출신 / 강인한 체격 / 겁쟁이 군주 / 생존 전문가 / ... → 절대 죽지 않는 빌드
```

### 시나리오 C: "실패에서 피어난 영웅"

```
[모집]
  선천: 저주받은 운명(Talent) → 1개 (선천 슬롯 2개 비어있음)

[초기 플레이: 잦은 실패]
  → consecutive_failure 5+ → 트라우마(Mental) 획득
  → great_failure 5+ → 불운(Exp) 획득

[반전: 실패를 극복]
  → 이후 연속 성공 5회 → trauma → 무뎌진 마음(Mental, 단일진화)
  → survived_great_failure 5+ → unlucky → 저주의 생존자(Exp, 단일진화)

[이벤트로 선천 획득]
  → 특수 이벤트 발생 → 수도원 출신(Background) 획득

최종: 저주받은 운명 / 수도원 출신 / 무뎌진 마음 / 저주의 생존자 / ... → 역경 극복 서사
```

---

## 강화 필요 컨텐츠 목록

트레잇 시스템 고도화를 위해 게임 내에서 **추가 또는 강화**되어야 하는 컨텐츠.

### 필수 (트레잇 시스템 작동에 반드시 필요)

| # | 컨텐츠 | 설명 | 현재 상태 |
|---|--------|------|----------|
| 1 | **행동 지표 추적 시스템** | 용병별 23개 누적 통계 추적 및 저장 (mercenary_stat 확장) | 미구현 |
| 2 | **트레잇 모델 구조 변경** | 현재 플랫 구조 → 카테고리/타입/관계 테이블 구조로 확장 | 현재 4개 플랫 구조 |
| 3 | **트레잇 획득 엔진** | 퀘스트 완료 시 지표 갱신 → 조건 체크 → 트레잇 후보 생성 → 선택 | 미구현 |
| 4 | **트레잇 진화/조합 엔진** | 진화 조건 충족 시 알림 → 플레이어 선택 → 변환 처리 | 미구현 |
| 5 | **용병 모집 시스템 변경** | 현재 랜덤 1개 → 선천 1~3개 랜덤 (Physical/Background/Talent) | 현재 트레잇 1개 랜덤 |
| 6 | **파견 시스템 효과 처리 변경** | 현재 하드코딩 → 데이터 드리븐 효과 처리 | 현재 trait ID 하드코딩 |
| 7 | **충돌 관계 검증** | 트레잇 획득 시 충돌 테이블 검증 로직 | 미구현 |
| 8 | **Supabase 정적 데이터 확장** | trait_category, trait, trait_conflict, trait_transition, trait_combo 테이블 추가 | CSV 초안만 존재 |

### 중요 (핵심 경험 완성에 필요)

| # | 컨텐츠 | 설명 | 현재 상태 |
|---|--------|------|----------|
| 9 | **트레잇 관리 UI** | 트레잇 상세 정보, 진화 경로 미리보기, 충돌 관계 표시 | 현재 이름만 표시 |
| 10 | **트레잇 획득/진화 알림** | 조건 충족 시 팝업, 진화 선택지 UI | 미구현 |
| 11 | **용병 상세 화면 개선** | 선천/후천 슬롯 시각화, 빈 슬롯 표시 | 미구현 |
| 12 | **활동 로그 연동** | 트레잇 획득/진화/소멸 이벤트 활동 로그 기록 | 활동 로그 존재, 트레잇 미연동 |

### 향후 확장 (트레잇 경험 풍부화)

| # | 컨텐츠 | 설명 | 현재 상태 |
|---|--------|------|----------|
| 13 | **여행 이벤트 ↔ 선천 트레잇 연계** | 이동 중 이벤트에서 빈 선천 슬롯에 트레잇 부여 기회 | 이벤트 존재, 트레잇 미연동 |
| 14 | **특수 임무 시스템** | 특정 조건에서 생성되는 희귀 퀘스트, 트레잇 직접 부여 보상 | 미구현 |
| 15 | **아이템/스킬북 시스템** | 퀘스트 보상에 스킬북 추가, 사용 시 특정 트레잇 부여 | 미구현 (아이템 시스템 없음) |
| 16 | **시설 ↔ 트레잇 연계** | 훈련소 사용 시 훈련 관련 지표 카운트, 시설 레벨에 따른 트레잇 기회 | 시설 존재, 트레잇 미연동 |
| 17 | **용병 간 상호작용 이벤트** | 같은 파견 반복 시 우정/라이벌 트레잇 획득 기회 | 미구현 |
| 18 | **트레잇 삭제 시스템** | 후천 트레잇 삭제 기능 (선천은 삭제 불가). 비용/조건 필요 | 미구현 |
| 19 | **용병 티어 업그레이드** | 성장을 통한 티어 상승 컨텐츠 | 미구현 |

---

## 구현 우선순위 제안

| 우선순위 | 작업 | 이유 |
|---------|------|------|
| **높음** | 행동 지표 추적 시스템 (#1) | 트레잇 획득의 기반 데이터 |
| **높음** | 트레잇 모델/DB 구조 변경 (#2, #8) | 모든 기능의 전제 조건 |
| **높음** | 용병 모집 변경 (#5) | 선천 트레잇 부여의 시작점 |
| **높음** | 트레잇 획득 엔진 (#3) | 핵심 게임 루프 |
| **높음** | 파견 효과 처리 변경 (#6) | 트레잇이 게임에 영향을 주는 핵심 |
| **중간** | 트레잇 진화/조합 엔진 (#4) | 고도화 핵심이나 acquired만으로도 플레이 가능 |
| **중간** | 충돌 관계 검증 (#7) | 시스템 무결성 |
| **중간** | 트레잇 관리 UI (#9, #10, #11) | 플레이어 경험 |
| **낮음** | 이벤트/특수임무/스킬북 (#13~#17) | 컨텐츠 확장 |
| **낮음** | 트레잇 삭제/티어 업그레이드 (#18, #19) | 장기 컨텐츠 |

---

## 부록: DB 테이블 구조 (수정 제안)

PD가 제안한 테이블 구조를 새 프레임워크에 맞게 수정.

```sql
-- 카테고리 (8개)
CREATE TABLE trait_category (
    id SERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,        -- Physical, Background, Talent, CombatStyle, ...
    name TEXT NOT NULL,               -- 한국어 표시명
    slot_type TEXT NOT NULL           -- 'innate' or 'acquired'
);

-- 트레잇 (106개)
CREATE TABLE trait (
    id SERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    category_id INT REFERENCES trait_category(id),
    type TEXT NOT NULL,               -- 'innate', 'acquired', 'evolved'
    description TEXT,                 -- 서사적 설명
    effect_text TEXT                  -- 효과 텍스트 (수치 미확정)
);

-- 트레잇 효과 (추후 밸런스 설계 시 사용)
CREATE TABLE trait_effect (
    id SERIAL PRIMARY KEY,
    trait_id INT REFERENCES trait(id),
    stat_key TEXT NOT NULL,           -- hp_bonus, atk_bonus, success_rate, ...
    value NUMERIC NOT NULL
);

-- 충돌 관계 (16쌍)
CREATE TABLE trait_conflict (
    trait_id INT REFERENCES trait(id),
    conflict_trait_id INT REFERENCES trait(id),
    PRIMARY KEY (trait_id, conflict_trait_id)
);

-- 단일 진화 (16개 경로)
CREATE TABLE trait_transition (
    id SERIAL PRIMARY KEY,
    from_trait_id INT REFERENCES trait(id),
    to_trait_id INT REFERENCES trait(id),
    condition_json JSONB NOT NULL     -- {"solo_dispatch_count": 30, "high_difficulty_count": 10}
);

-- 조합 진화 (15개 레시피)
CREATE TABLE trait_combo_evolution (
    id SERIAL PRIMARY KEY,
    required_trait_1 INT REFERENCES trait(id),
    required_trait_2 INT REFERENCES trait(id),
    result_trait_id INT REFERENCES trait(id)
);

-- 선천-후천 시너지
CREATE TABLE trait_synergy (
    id SERIAL PRIMARY KEY,
    innate_trait_id INT REFERENCES trait(id),     -- 선천 트레잇
    target_trait_id INT REFERENCES trait(id),      -- 촉진 대상 후천 트레잇
    reduction_percent NUMERIC DEFAULT 20           -- 획득 조건 완화 비율
);

-- 용병 트레잇 (런타임)
CREATE TABLE mercenary_trait (
    id SERIAL PRIMARY KEY,
    mercenary_id BIGINT NOT NULL,
    trait_id INT REFERENCES trait(id),
    slot_type TEXT NOT NULL,          -- 'innate' or 'acquired'
    acquired_at TIMESTAMP DEFAULT NOW(),
    is_locked BOOLEAN DEFAULT FALSE   -- 선천은 항상 TRUE
);

-- 용병 행동 지표 (런타임)
CREATE TABLE mercenary_stat (
    mercenary_id BIGINT PRIMARY KEY,
    total_dispatch_count INT DEFAULT 0,
    success_count INT DEFAULT 0,
    failure_count INT DEFAULT 0,
    great_success_count INT DEFAULT 0,
    great_failure_count INT DEFAULT 0,
    solo_dispatch_count INT DEFAULT 0,
    team_dispatch_count INT DEFAULT 0,
    high_difficulty_count INT DEFAULT 0,
    low_difficulty_count INT DEFAULT 0,
    raid_count INT DEFAULT 0,
    subjugation_count INT DEFAULT 0,
    escort_count INT DEFAULT 0,
    explore_count INT DEFAULT 0,
    near_death_count INT DEFAULT 0,
    injury_count INT DEFAULT 0,
    survived_great_failure INT DEFAULT 0,
    tier_max_visited INT DEFAULT 1,
    unique_region_count INT DEFAULT 0,
    total_travel_distance INT DEFAULT 0,
    total_gold_earned INT DEFAULT 0,
    consecutive_success INT DEFAULT 0,
    consecutive_failure INT DEFAULT 0
);

-- 트레잇 히스토리 (재획득 방지용)
CREATE TABLE mercenary_trait_history (
    id SERIAL PRIMARY KEY,
    mercenary_id BIGINT NOT NULL,
    trait_id INT REFERENCES trait(id),
    acquired_at TIMESTAMP NOT NULL,
    lost_at TIMESTAMP,                -- 진화/조합으로 소멸된 시점
    lost_reason TEXT                   -- 'single_evolution', 'combo_evolution', 'deleted'
);
```

### PD 제안 대비 주요 변경

| 항목 | PD 원본 | 변경 |
|------|---------|------|
| trait_category | slot_type 없음 | `slot_type` 추가 (innate/acquired 구분) |
| trait | description만 | `effect_text` 추가 (효과 설명 분리) |
| trait_transition | condition_type + condition_value (단일 조건) | `condition_json` (복합 조건 지원) |
| mercenary_trait | is_locked만 | `slot_type` 추가 |
| mercenary_stat | 4개 필드 | 23개 필드로 확장 |
| mercenary_trait_history | 없음 | 신규 (재획득 방지) |
| trait_synergy | 없음 | 신규 (선천-후천 촉진 관계) |

---

## 후속 작업 안내

- 밸런스 검토가 필요한 수치(효과 값, 획득 임계값, 선천 확률 등)가 포함되어 있으므로 **`/balance-designer`로 밸런스 검토를 권장합니다**
- 구현을 진행하려면 **`/spec-writer @Docs/content-design/20260412_trait_system_design.md`로 개발 명세서를 생성**할 수 있습니다
- CSV 데이터 파일(trait.csv, trait_category.csv 등)은 본 기획서 승인 후 갱신합니다
