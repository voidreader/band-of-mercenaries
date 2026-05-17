# M7 페이즈 3 산출물 5 메타: 인프라 narrative + 체인 + 신규 레시피 통합

> 작성일: 2026-05-17
> 마일스톤: M7 (지역 생활권 확장)
> 페이즈: 3 #5 (페이즈 3 마지막)
> 산출 파일:
> - `Docs/content-data/m7_phase3_5_recipes_chain.sql` (items 6 + crafting_recipes 6 + chain_quests 2 INSERT)
> - 본 메타 (narrative 텍스트 보존 + 페이즈 4 #4 spec 입력)

---

## 생성 근거

### 참조 기획 문서

- `Docs/content-design/[content]20260517_m7_settlement_infrastructure_growth.md` (페이즈 1 #3) — 인프라 4단계 + 거점 단계별 변화
- `Docs/balance-design/[balance]20260517_m7_infrastructure_growth_curve.md` (페이즈 2 #3) — 단계 전이 보상 + 외래 좌판 가격
- `Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md` (페이즈 1 #4) — 중간 목표 2 + 최종 목표 1 다이얼로그 텍스트
- `Docs/content-data/[region-discovery]20260517_m7-discoveries.csv` (페이즈 3 #3) — `rdsc_m7_r146_mist_omen` chain_m7_mist_clearing 트리거 의존

### 본 산출물 구성

**SQL 마이그레이션 (`m7_phase3_5_recipes_chain.sql`)**:
- (A) items 6행 — M7 신규 6 레시피 결과 아이템 (placeholder effect_json)
- (B) crafting_recipes 6행 — M5 unlock_condition 확장 (regionFlag / all / infrastructureTier)
- (C) chain_quests 2행 — chain_m7_mist_clearing (페이즈 3 #3 hidden_quest 트리거)
- (D) 검증 DO 블록 3종

**본 메타 (narrative 텍스트 보존)**:
- 인프라 단계 전이 다이얼로그 3행 (페이즈 4 #4 spec 인라인 처리)
- 외래 상인 케일 NPC 인사말 5행
- 거점 3종 NPC 인프라 단계별 인사말 8행
- 활동 로그 메시지 템플릿

---

## (1) 인프라 단계 전이 다이얼로그 3종 (페이즈 1 #4 3절)

페이즈 4 #4 `SettlementInfrastructureUpgradedDialog` 표시용 텍스트. 페이즈 4 #4 spec 단계에서 코드 상수로 인라인 처리 (DB 미저장).

### Tier 1 → 2 (170분 시점) — "더스트빌이 변화하기 시작"

```
그날 아침, 광장 한가운데 새 이정표가 세워졌다.
마을 사람들이 모여 외지 용병의 이름을 손가락질하며 서로 수군거렸다.
비웃음이 아니라 처음 보는 종류의 인사였다.
```

- 표시 정보: "광장 이정표 / 인접 6리전 이동 시간 -10%"
- 보상: 100G + 100XP + 50 명성 (페이즈 2 #3 확정)

### Tier 2 → 3 (255분 시점) — "외래 좌판 신설"

```
한밤중에 마차 한 대가 광장에 도착했다.
외지 상인은 변방 마을이 안전해졌다는 소문을 들었다고 했다.
다음 날 광장 한쪽에 좌판이 펼쳐졌다. 외래의 물건이 변방에 들어왔다.
```

- 표시 정보: "외래 좌판 신설 / 신규 레시피 3개 해금 / 거점 효과 -10% 비용"
- 보상: 200G + 200XP + 100 명성

### Tier 3 → 4 (330분 시점) — "변방의 중심 더스트빌"

```
그날 저녁, 광장에 화롯불이 켜졌다.
흙벽 집들은 등불을 켰고, 외래 상인의 좌판에는 옷감과 양념이 쌓였다.
파슨 영감이 다가와 어깨를 두드렸다. "이제 자네는 더스트빌의 영주일세."
```

- 표시 정보: "잔치 분위기 / 모든 거점 효과 +20% / 외래 좌판 -20% 할인"
- 보상: 500G + 500XP + 300 명성 + **위업 "변방의 영주"** (M6 hook 7번째 의존)

---

## (2) 외래 상인 케일 NPC (페이즈 1 #3 2.4절)

Tier 3 도달 시 신설되는 신규 거점 `foreignStall`의 NPC.

### Tier 3 첫 등장 인사말

```
"변방까지 들어와 본 건 오랜만이군. 자네가 이 마을을 변하게 했다고 들었어.
짐을 풀어둘 곳이 있어 다행이지."
```

### 거래 메뉴 멘트 — `[재료 거래]`

```
"이게 다 외래에서 가져온 물건들이지. 변방에선 보기 힘들 거야.
가격은 시간을 사는 셈 치게."
```

### Tier 4 도달 후 인사말 (할인 -20%)

```
"이제 자네 마을 사람이 됐으니 값을 좀 깎아 주지. 외래 손님 환영 인사야."
```

### 외래 소식 멘트 — `[외래 소식 듣기]` (M8 빌드업)

```
"외래의 거대한 깃발 아래 모인 무리를 본 적 있나? 변방 너머 큰 세상에선
용병단을 후원하는 세력이 여럿 있다고 하더군. 언젠가 자네도 그쪽 손길을 받을지도."
```

### 방문 횟수 인사말 — `[방문 횟수 보기]`

```
"자주 들르는 손님은 잊지 않는 법이지. 이번이 자네 N번째 발길이로군."
```

---

## (3) 거점 3종 NPC 인프라 단계별 인사말 (페이즈 1 #3 2.1~2.3절)

기존 M4 신뢰도 4단계 인사말 (page 1 #3 starting-settlement 17개)에 **인프라 단계별 한 줄 첨부** 권장. 페이즈 4 #4 spec에서 코드 상수로 인라인 처리.

### 촌장 파슨 (Chief House)

| Infra | 첨부 인사말 |
|-------|----------|
| Tier 2 | "...마을이 좀 잠잠해진 것 같네." |
| Tier 3 | "...외래 손님도 들어오고, 자네 덕분이지." |
| Tier 4 | "...이제 더스트빌도 변방 중심이로구나." |

### 대장장이 하겐 (Old Smithy)

| Infra | 첨부 인사말 |
|-------|----------|
| Tier 2 | "...야수 가죽을 다루는 기술도 익혀야겠어." |
| Tier 3 | "...외래 재료가 들어오니 작업이 다채로워졌네." |
| Tier 4 | "...자네가 가져온 것들로 마을의 솜씨가 늘었어." |

### 약초상 네리스 (Herbalist)

| Infra | 첨부 인사말 |
|-------|----------|
| Tier 2 | "...들꽃 채집 의뢰가 늘었네요. 자주 와요." |
| Tier 3 | "...해초도 들어오고, 약방이 풍성해졌어요." |
| Tier 4 | "...이젠 손님들이 멀리서도 우리 약을 찾아와요." |

---

## (4) M7 신규 6 레시피 (페이즈 1 #3 4절 + 페이즈 2 #3)

SQL 마이그레이션에 INSERT. 본 메타에서는 unlock_condition 확장 가이드 보존:

### M5 기존 unlock_condition_json 형식 (3종 — 변경 없음)

```json
{"trust_level": 2}                                       // M4 신뢰도 단계
{"chain_step": {"step": 1, "chain_id": "..."}}           // 체인 진행 단계
{"first_acquired_item": "mat_relic_pyegwang_shard"}      // 첫 입수 영속 추적
```

### M7 신규 unlock_condition_json 형식 (2종 + 복합)

```json
{"type": "regionFlag", "flag": "region_9_giant_beast_killed"}

{"type": "infrastructureTier", "value": 3}

{"type": "all", "conditions": [
  {"type": "infrastructureTier", "value": 3},
  {"type": "regionFlag", "flag": "region_127_nomad_friendly"}
]}
```

### CraftingService.evaluateState() 분기 (페이즈 4 #4 spec 입력)

```dart
bool _isUnlocked(Map<String, dynamic>? condition, {
  required int trustLevel,
  required Map<String, int> chainStepCompletions,
  required Set<String> firstAcquiredMaterialIds,
  required int infrastructureTier,    // M7 신규 인자
  required Set<String> unlockedFlags, // M7 신규 인자
}) {
  if (condition == null) return true;

  // M7 신규 type 분기 (먼저 검사)
  final type = condition['type'];
  if (type == 'regionFlag') {
    return unlockedFlags.contains(condition['flag']);
  }
  if (type == 'infrastructureTier') {
    return infrastructureTier >= (condition['value'] as int);
  }
  if (type == 'all') {
    return (condition['conditions'] as List).every((c) =>
      _isUnlocked(c, trustLevel: trustLevel, ...));
  }
  if (type == 'any') {
    return (condition['conditions'] as List).any((c) =>
      _isUnlocked(c, trustLevel: trustLevel, ...));
  }

  // M5 기존 분기 (type 필드 없음 → 기존 키 분기 유지)
  if (condition['trust_level'] != null) return trustLevel >= condition['trust_level'];
  if (condition['chain_step'] != null) { /* 기존 로직 */ }
  if (condition['first_acquired_item'] != null) return firstAcquiredMaterialIds.contains(condition['first_acquired_item']);

  return true;
}
```

---

## (5) chain_m7_mist_clearing 체인 상세

페이즈 1 #4 + 페이즈 2 #2 통합 결과 — 2단계 짧은 chain:

### Step 1: 안개 속 정찰

- region 146, target 146 (외부 이동 없음)
- quest_type: explore, difficulty: 2, combat_power: 30
- duration_seconds: 360 (6분)
- reward_gold: 120, reward_xp: 80
- reward_items: `{"mat_herb_poison":1, "mat_relic_swamp_seal":1}`
- next_step_delay_seconds: 600 (10분 대기)
- description: "늪의 안개가 평소보다 짙어졌다는 보고가 있어. 안개 사이로 무언가 움직인다지만 정체는 모르겠어. 가까이서 확인만 해와도 충분해."

### Step 2: 안개의 야수 추적 (최종)

- region 146, target 146
- quest_type: hunt, difficulty: 3, combat_power: 50
- duration_seconds: 540 (9분)
- reward_gold: 250, reward_xp: 200
- reward_items: `{"mat_relic_swamp_seal":2, "mat_herb_poison":1, "mat_hide_rough_bundle":1}`
- **final_reward: true, final_reputation_bonus: 200**
- description: "안개 속에서 움직이던 게 짐승이었어. 야수가 늪의 인장을 흩어놓아 안개가 짙어진 거였지. 야수를 처리하면 안개도 가라앉을 거야. 끝까지 가서 매듭을 짓자."

### 페이즈 1 #2 트리거 정합

- chain_m7_mist_clearing **완주 시** → `region_146_mist_cleared` flag toggle + dangerScore -50 (특수 단발)
- 페이즈 2 #2 시뮬레이션 430분 시점과 정확 정합

### 페이즈 3 #3 region_discovery 트리거 정합

- `rdsc_m7_r146_mist_omen` (knowledge=85, hidden_quest, discovery_data.chain_id="chain_m7_mist_clearing") → ChainQuestService.tryActivate("chain_m7_mist_clearing") 호출
- 본 INSERT 시 chain 데이터 정합 (외래 키 없음, chain_id TEXT 자유값)

---

## (6) 활동 로그 메시지 템플릿 (페이즈 4 #4 spec 입력)

### ActivityLogType.settlementInfrastructureUpgraded (HiveField 34, 페이즈 1 #3 6절)

```dart
'더스트빌이 {tier_name} 단계로 발전했다 (Tier {N})'
```

tier_name 매핑:
- Tier 2: "연결"
- Tier 3: "거점화"
- Tier 4: "변방의 중심"

### M7 페이즈 4 #2에서 신규 추가 가능한 ActivityLog (페이즈 1 #2 6.1절)

- `regionDangerLevelChanged` (HiveField 32): "{region.name} 상태가 {from} → {to}으로 변화했다"
- `regionUnlockedFlagToggled` (HiveField 33): "{region.name}에서 {flag_description}"

flag_description 매핑 (페이즈 1 #2 6.1절):
- region_31_bandits_cleared → "도적이 소탕되었다"
- region_31_shrine_quest_completed → "폐사당 체인이 완료되었다"
- region_127_nomad_friendly → "유목민과 친교를 맺었다"
- region_9_giant_beast_killed → "거대 야수가 처치되었다"
- region_10_windrunner_chain_completed → "풍신의 자취를 따라갔다"
- region_146_mist_cleared → "회색 늪지의 안개가 걷혔다"
- region_38_ironbound_pact_completed → "부서진 요새의 서약이 매듭지어졌다"
- region_3_pyegwang_reopen_completed → "폐광이 재개되었다"

---

## 검증 결과

### SQL 자체 검증 3종 (스크립트 내 DO 블록)

1. **D1**: items 6행 INSERT 검증
2. **D2**: crafting_recipes 6행 INSERT + unlock_condition_json.type ('regionFlag'/'all'/'infrastructureTier') 검증
3. **D3**: chain_m7_mist_clearing 2행 + step 2 final_reward=true 검증

### narrative 텍스트 검증

- 단계 전이 다이얼로그 3행 (Tier 2/3/4) — 페이즈 1 #4 3절 권장 톤 그대로
- 외래 상인 NPC 인사말 5행 (페이즈 1 #3 2.4절 컨셉 정합)
- 거점 3종 × Tier 2/3/4 인사말 9행 (페이즈 1 #3 2.1~2.3절 정합)
- flag description 8쌍 + tier_name 3종 (페이즈 1 #2·#3 정합)

---

## 적용 절차 (페이즈 4 #4 spec 단계)

본 산출물은 **즉시 적용하지 않는다**. 페이즈 4 #4 "마을 인프라 성장 시스템 + 진입점 통합" spec 단계에서 일괄 적용:

1. **페이즈 4 #4 spec 작성 시 본 SQL + 본 메타 인라인 참조**
2. **operation-bom table-config.ts 갱신**:
   - crafting_recipes 편집 폼에 신규 unlock_condition type (regionFlag/all/infrastructureTier) 편집기 지원
3. **Flutter 코드 변경**:
   - `SettlementInfrastructureConfig` 클래스 (페이즈 2 #3 권장)
   - `CraftingService.evaluateState()` 신규 type 분기 (위 코드 참조)
   - `VillageFacility.foreignStall` enum 추가
   - `ForeignStallScreen` 신규 위젯 (3 버튼: 재료 거래·외래 소식·방문 횟수)
   - `SettlementInfrastructureUpgradedDialog` 신규 다이얼로그 + 본 메타 (1) 텍스트 인라인
   - 거점 3종 화면(`ChiefHouseScreen`/`OldSmithyScreen`/`HerbalistScreen`)에 인프라 단계별 NPC 인사말 첨부 (본 메타 (3) 텍스트 인라인)
4. **신규 아이템 effect_json 최종 확정**: 본 SQL placeholder를 페이즈 4 #4 spec 단계에서 검토 → operation-bom에서 직접 편집 또는 INSERT 시점 보정
5. **chain_m7_mist_clearing 완주 hook**: ChainQuestService.completeChain() trailing 분기 — region 146 dangerScore -50 + flag toggle
6. **SyncService 마이그레이션**: data_versions `items`, `crafting_recipes`, `chain_quests` 버전 ↑
7. **Supabase 실행**: 본 SQL을 단일 트랜잭션으로 실행, DO 블록 3종 검증 후 commit

---

## 다음 단계

- **페이즈 3 산출물 5번 완료** → milestone-runner로 갱신
- **페이즈 3 전체 종료 체크포인트** 진입
- 다음 페이즈 4: 개발 명세 spec-writer 호출

---

## 참고: 페이즈 3 전체 산출물 정리

| 산출물 | 상태 | 적용 시점 |
|--------|------|----------|
| #1 regions/region_adjacency | ✅ 완료 | 페이즈 4 #1·#3 |
| #2 items 8행 region_exclusive | ✅ 완료 + Supabase 즉시 INSERT | M5 패턴 (즉시 적용) |
| #3 region_discoveries 15행 | ✅ 완료 + Supabase 즉시 INSERT | M2b 패턴 (즉시 적용) |
| #4 quest_pools 36행 + 신규 3 컬럼 DDL | ✅ 완료 | 페이즈 4 #2 |
| #5 인프라 narrative + 6 레시피 + chain | ✅ 완료 (본 산출물) | 페이즈 4 #4 |

페이즈 4 spec 4개(#1~#4)가 본 데이터를 모두 명세 입력으로 활용.
