# M7 마을 인프라 성장 — 방문 거점·대장간·시장 단계별 개선 기획서

> 작성일: 2026-05-17
> 유형: 신규 컨텐츠 (M7 마일스톤 — 페이즈 1 산출물 3/4)
> 선행 문서:
> - `Docs/content-design/[content]20260516_m7_livingsphere_regions.md` — M7 페이즈 1 #1, 7리전 각각의 "거점 인프라 성장 hook" 항목
> - `Docs/content-design/[content]20260516_m7_region_state_rules.md` — M7 페이즈 1 #2, unlockedFlags List<String> + dangerLevel 전이 + M6 hook 7번째
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` — M4 마을 신뢰도 4단계 + 폐광 재개방 6단계
> - `band_of_mercenaries/lib/features/settlement/` — VillageFacility enum 3종(chiefHouse·oldSmithy·herbalist), HerbalistService.calculateCost/calculateCooldownMinutes (trustLevel 1~4 인자)
> - `band_of_mercenaries/lib/features/crafting/` — RecipeListSection, CraftingService.evaluateState, unlock_condition_json 3종(trustLevel/chainStep/firstAcquiredItem)
>
> 후속:
> - 페이즈 1 #4 "이동 목적 강화 + 생활권 진행 곡선" — 본 문서의 단계 전이 곡선을 입력으로 받아 5~8시간 흐름에 배치
> - 페이즈 2 #3 "마을 인프라 성장 비용·요구 사건 수 확정" — 본 문서의 4단계 전이 조건을 입력으로 받아 unlockedFlags 임계 수치 정량화
> - 페이즈 3 #5 "마을 인프라 성장 narrative + 체인 단계" — 본 문서의 단계별 서사 / 외래 좌판 / 광장 이정표 텍스트를 입력으로 받아 quest_narratives + chain_quests INSERT
> - 페이즈 4 #4 "마을 인프라 성장 시스템 + 진입점 통합" — 본 문서를 명세 입력으로 받아 RegionState 확장 + VillageFacility enum 확장 + RecipeListSection unlock 분기 구현

---

## 개요

M4가 시작 거점 더스트빌의 **사회적 친밀도(settlement-trust 4단계)**를 도입했다면, M7은 더스트빌의 **물리적 인프라 성장(infrastructure tier 4단계)**을 도입한다. 두 축은 독립적으로 작동한다.

- **M4 신뢰도** = "마을 사람들이 외지 용병을 얼마나 받아들였는가" (NPC 인사말 / 약초상 비용 / 채집 의뢰)
- **M7 인프라** = "외곽 사건 해결로 더스트빌이 얼마나 성장했는가" (광장 이정표 / 외래 좌판 / 신규 레시피 / 거점 외관 변화)

본 문서는 다음 4가지를 결정한다.

1. **인프라 단계 4구조** — 고립(Tier 1) / 연결(Tier 2) / 거점화(Tier 3) / 변방의 중심(Tier 4)
2. **단계 전이 트리거** — 7리전의 `unlockedFlags` 합산 N개 임계 도달 (페이즈 1 #2 8개 flag 활용)
3. **단계별 해금 효과** — 광장 이정표(시각 + 이동 시간 -10%), 외래 좌판(VillageFacility 4번째 신규), 신규 레시피 자동 해금, 거점 외관 변화 등
4. **기존 시스템과의 통합 정책** — M4 신뢰도·M5 레시피 unlock_condition_json·M7 dangerScore와의 분리·통합 + 거점 3종(촌장 집·대장간·약초상)의 단일 단계 공유

본 문서는 **컨셉 설계**의 산출물이다. 수치(전이 임계 flag 수·해금 효과 크기)는 페이즈 2 #3 밸런스에서 확정한다.

**핵심 원칙 3가지**:
1. **마을 단위 단일 단계** — 거점 3종이 단일 인프라 단계를 공유한다 (UI·서사 단순화). 거점별 별도 단계는 도입하지 않는다.
2. **신뢰도와 독립** — M7 infrastructureTier는 M4 settlement_trust와 독립 축. 두 시스템 모두 region 3에 공존, 효과는 곱셈 합산 (예: 약초상 비용 = base × trust_modifier × infra_modifier).
3. **외곽 사건이 동력** — 단계 전이는 더스트빌 내부 활동이 아니라 **외곽 6리전(31·127·9·10·146·38) 사건 해결의 보상**으로 발생. region 3 자체 사건(폐광)도 일부 기여.

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| Stardew Valley — Community Center 단계적 해금 (5 Bundles × 6 Rooms) | 외부 활동(채집·낚시·전투)으로 모은 재료를 마을 건물에 헌납하면 마을 인프라(다리·버스·온실 등)가 시각·기능적으로 변화 | M7은 7리전 사건 해결 → unlockedFlags 누적 → 더스트빌 인프라 단계 전이. "외부 활동이 마을을 키운다" 정확한 패턴 |
| Caves of Qud — Joppa Township 진화 | 플레이어가 외부 적을 처치하면 Joppa NPC가 새 기능(상점 확장·NPC 신규 등장)을 자동 해금 | 단계 전이가 명시적 헌납 없이 외부 사건만으로 자동 발생. 더스트빌도 헌납 UI 없음 (자동) |
| Banished — Town Hall 단계별 정보 표시 | 인구·시설 수에 따라 Town Hall이 단계적으로 확장, 단계별 정보 패널 확장 | 단계별로 "어떤 정보가 노출되는가"가 변화 (예: Tier 2부터 광장 이정표 정보, Tier 3부터 외래 좌판 거래 가능) |
| Slay the Spire — Map Marker / Boss Defeat 영구 표시 | 한 번 클리어한 보스는 영구 표시 + 다음 런에 영향 | unlockedFlags는 한 번 켜지면 영속. M5 firstAcquiredMaterialIds 패턴 재사용 |
| Anno 1800 — 마을 단계별 외관 변화 (Farmers → Workers → Artisans) | 한 마을이 단계 진화 시 시각적으로 건물·NPC가 모두 바뀜 | 거점 3종(촌장 집·대장간·약초상)의 인사말·외관이 단계별로 변화. NPC 인사말은 M4 신뢰도가 담당, 거점 외관·기능은 M7 인프라가 담당 |

**기존 게임과의 차별 포인트**: M4까지는 거점이 진입 시 NPC 인사말만 변하는 단순 구조였다(신뢰도 4단계). M7은 거점 **외관·신규 거점·신규 기능 해금**을 추가하여 "마을이 살아난다"는 체감을 만든다. M4 신뢰도가 "관계의 성장"이라면, M7 인프라는 "마을의 성장"이다.

---

## 상세 설계

### 1. 인프라 단계 4구조

#### 1.1 단계 정의

| Tier | 이름 | 핵심 톤 | 진입 조건 (unlockedFlags 합산) | 거점 외관 변화 |
|------|------|---------|--------------------------------|--------------|
| **1** | **고립** (Isolated) | M7 시작 시점. M4 신뢰도와 독립적으로 항상 Tier 1로 시작 | 0개 — 기본값 | 변화 없음 (M4 더스트빌 그대로) |
| **2** | **연결** (Connected) | "외지 용병의 활약이 마을에 변화를 가져온다" | **2개** (페이즈 2 #3 확정) | 거점 외관 약간 변화 (벽 보수, 광장 정리). 광장에 **이정표** 시각 추가 |
| **3** | **거점화** (Hub) | "더스트빌이 인접 생활권의 중심이 되어간다" | **4개** (페이즈 2 #3 확정) | 광장에 **외래 좌판** 신설 (NPC 1명 추가). 거점 외관 본격 변화 (재건된 가옥, 외래 상인 천막) |
| **4** | **변방의 중심** (Beacon) | "더스트빌이 변방 생활권 전체의 거점으로 자리매김했다" | **6개** (페이즈 2 #3 확정) | 광장에 영구 **잔치 분위기** (M4 신뢰도 4단계의 일시적 잔치와 시각 통일). 모든 거점 외관 완전 변화 |

**진입 조건 = unlockedFlags 합산 개수**. 어느 7리전 flag든 합산 N개 도달 시 자동 전이.

**8개 활용 가능 flag** (페이즈 1 #1 4.1절 + 페이즈 1 #2 1.3절):
1. `region_3_pyegwang_reopen_completed` — 폐광 재개방 6단계 완료 (M4 settlement-trust 4단계와 동시 발생)
2. `region_31_bandits_cleared` — 도적 소탕 5회 누적
3. `region_31_shrine_quest_completed` — chain_roadside_shrine 2단계 완주
4. `region_127_nomad_friendly` — 유목민 친교 (faction_clue 3단계 모두)
5. `region_9_giant_beast_killed` — 거대 야수 첫 처치 (elite)
6. `region_10_windrunner_chain_completed` — chain_windrunner_trail 3단계 완주
7. `region_146_mist_cleared` — 안개 사건 해소 (특수 사건)
8. `region_38_ironbound_pact_completed` — chain_ironbound_pact 3단계 완주

→ 총 8개 중 6개 도달 시 Tier 4. **2개 여유** (난이도 조정 여지 확보).

#### 1.2 단계 진입 효과 (요약)

| Tier | 거점 시각 | 광장 시각 | 신규 거점 | 거점 효과 (수치) | 신규 레시피 해금 후보 |
|------|----------|----------|----------|-----------------|-------------------|
| 1 | M4 기본 | 비어있음 | 없음 | M4 기본 (HerbalistService trustLevel만 반영) | M5 10개 + M7 추가 1개 (예: 시작 도구 수리) |
| 2 | 벽 보수 + 광장 정리 | **이정표** 추가 | 없음 | 이동수단 시설과 독립적으로 **region 3 → 인접 6리전 이동 시간 -10%** | M7 페이즈 3 #5에서 1~2개 (예: 야수 가죽 도구 — region 9 야수 처치 hook 연동) |
| 3 | 재건된 가옥 + 외래 천막 | 이정표 유지 + 외래 좌판 | **외래 좌판** (VillageFacility 4번째 신규) | 모든 거점 효과 +10% (HerbalistService.calculateCost 등에 곱셈 적용) | M7 페이즈 3 #5에서 2~3개 (예: 유목민 가죽 장비 — region 127 친교 hook 연동) |
| 4 | 완전 변화 (석조 부분, 등불) | 영구 잔치 분위기 (M4 신뢰도 4단계 통일) | 외래 좌판 거래 종류 확장 | 모든 거점 효과 +20% (Tier 3에서 +10% 누적 아님, Tier 4 새 값) | M7 페이즈 3 #5에서 1개 추가 (예: 부서진 요새 인장 장비 — region 38 hook 연동) |

상세 효과는 1.3~1.6절에서 거점별로 분해.

#### 1.3 시각 정책 (UI 가이드)

| Tier | 권장 UI 색상 (광장 배경) | 진행 바 표시 | 추가 아이콘 |
|------|---------------------|------------|----------|
| 1 | `surface` 회색 (어둡고 단조) | 0% — 25% | 없음 |
| 2 | `secondary` 베이지 | 25% — 50% | 광장 이정표 아이콘 |
| 3 | `tertiary` 따뜻한 brown | 50% — 75% | 광장 이정표 + 외래 천막 아이콘 |
| 4 | `chainGold` (M4 settlement-trust 4단계와 통일) | 75% — 100% (또는 "달성") | 광장 잔치 등불 아이콘 |

**구현 권장** (페이즈 4 #4 명세 입력):
- `AppTheme`에 별도 `infraTierL1~L4` 색상 추가하지 않음 — 기존 surface/secondary/tertiary/chainGold 재사용으로 충분
- M4 신뢰도 시각(`settlementTrustL1~L4`)과 별도로 표시. 거점 화면 상단에 두 시각이 공존: `[신뢰도 ●●○○ 인지]` + `[인프라 ●○○○ 고립]`

### 2. 거점별 단계 효과 분해

#### 2.1 촌장 집 (Chief House) — Tier별 변화

촌장 집은 M4 페이즈 1 #3에서 정의된 3개 버튼 (`상황 듣기`, `신뢰도 확인`, `보상 받기`)을 가진다. M7은 4번째 버튼을 추가한다.

| Tier | 추가/변화 | 비고 |
|------|----------|------|
| 1 | M4 기본 3버튼 | — |
| 2 | **신규 4번째 버튼**: `생활권 정보` 활성. region 3 + 인접 6리전의 dangerLevel·unlockedFlags 진행도 요약 카드 노출 | UI 신규 — 페이즈 4 #4 명세에 포함 |
| 3 | `생활권 정보` 카드 확장 — 외곽 사건 현황 + 다음 추천 사건 힌트 표시 | "다음 사건 추천 알고리즘"은 페이즈 1 #4에서 결정 |
| 4 | `생활권 정보` 최대 노출 + 새 컨텐츠 (예: 외래 손님 풍문) 알림 (M8 빌드업) | M8 의존성 — Tier 4 효과는 페이즈 4 #4에서 stub 가능 |

**서사 변화**: 촌장 파슨의 인사말은 **M4 신뢰도 단계가 우선** (인사말 변주 17개 활용). 인프라 단계 효과는 인사말 끝에 한 줄 첨부:
- Tier 2: "...마을이 좀 잠잠해진 것 같네." (이정표 설치 직후)
- Tier 3: "...외래 손님도 들어오고, 자네 덕분이지." (외래 좌판 직후)
- Tier 4: "...이제 더스트빌도 변방 중심이로구나." (Tier 4 진입 직후)

#### 2.2 낡은 대장간 (Old Smithy) — Tier별 변화

M5 페이즈 4 #2에서 도입된 RecipeListSection 4계층 정렬 + RecipeCard 4상태(locked/insufficient/ready/crafted)를 보유. M7은 단계별 신규 레시피 해금을 추가한다.

| Tier | 추가/변화 | 비고 |
|------|----------|------|
| 1 | M5 기본 10개 레시피 (slot 4종 분포) | — |
| 2 | **+1~2 신규 레시피 해금** (페이즈 3 #5 결정 — 예: "야수 가죽 도구" / region 9 야수 처치 hook 연동) | M5 unlock_condition_json 확장 (3.2절) |
| 3 | **+2~3 신규 레시피 해금** (예: "유목민 가죽 장비" / "안개 늪 인장 장신구") | 외래 좌판 신설과 동기화 |
| 4 | **+1 최종 레시피** (예: "부서진 요새 인장 장비") + 제작 비용 -10% (Tier 4 거점 효과 +20%의 일부) | M5 CraftingService.craft에 infraTier 인자 전달 가능 |

**제작 비용 -10%** 구현 옵션:
- 옵션 A: M5 `crafting_recipes.gold_cost` 컬럼이 있다면 비용 차감 분기 추가
- 옵션 B: M5 레시피는 재료만 사용하고 골드 비용 미사용이라면 효과는 "재료 비용 -10%" (재료 1개 보존 확률)
- 본 문서는 컨셉만 — 페이즈 4 #4 명세에서 옵션 결정

**RecipeListSection UI 변경 없음**: 신규 레시피가 unlock_condition 충족 시 자동 노출. 단, 페이즈 4 #4 명세에서 RecipeCard 위에 "인프라 Tier 3 해금" 같은 배지 추가 검토 (선택).

#### 2.3 약초상 (Herbalist) — Tier별 변화

기존 `HerbalistService` (band_of_mercenaries/lib/features/settlement/domain/herbalist_service.dart):

```dart
static const Map<int, double> _costMultipliers = {1: 1.5, 2: 1.0, 3: 0.9, 4: 0.8};
static const Map<int, int> _cooldownMinutes = {1: 45, 2: 30, 3: 15, 4: 10};
static const Map<int, double> _gatheringMultipliers = {1: 1.0, 2: 1.0, 3: 1.1, 4: 1.2};
```

M7 페이즈 4 #4에서 신규 메서드 추가:

```dart
static int calculateCost(int trustLevel, {int infraTier = 1}) {
  final base = 50 * (_costMultipliers[trustLevel] ?? 1.0);
  final infraMod = _infraCostMultipliers[infraTier] ?? 1.0;
  return (base * infraMod).round();
}

static const Map<int, double> _infraCostMultipliers = {1: 1.0, 2: 1.0, 3: 0.9, 4: 0.8};
static const Map<int, double> _infraGatheringMultipliers = {1: 1.0, 2: 1.05, 3: 1.10, 4: 1.20};
```

**효과 합산 예시 (trust × infra 곱셈)**:
- Tier 1 trust × Tier 1 infra = 50 × 1.5 × 1.0 = **75G** (기본보다 +50%)
- Tier 4 trust × Tier 4 infra = 50 × 0.8 × 0.8 = **32G** (기본보다 -36%)

**채집 의뢰 보상**: 마찬가지로 gatheringMultiplier에 infra 곱셈 추가. Tier 4 도달 시 채집 보상 + 26.4% (1.20 × 1.20 - 1).

#### 2.4 외래 좌판 (Foreign Stall) — Tier 3 신설 거점

**VillageFacility enum 확장** (페이즈 4 #4 마이그레이션):
```dart
enum VillageFacility {
  chiefHouse,
  oldSmithy,
  herbalist,
  foreignStall,  // M7 Tier 3 신설
}
```

**MVP 기능 (3개 버튼)** — 페이즈 4 #4 명세 입력:

| 버튼 | 동작 | 표시 정보 |
|------|------|----------|
| `재료 거래` | 일부 region_exclusive 재료 골드로 구매 (Tier 3: 1~2종 / Tier 4: 3~4종 확장) | 거래 가능 재료 목록 + 단가 |
| `외래 소식 듣기` | M7 페이즈 1 #4에서 결정된 "다음 추천 사건" 텍스트. 촌장 집 [생활권 정보]와 중복되나 톤이 다름 (외래 상인 시선) | 1~2줄 텍스트 |
| `방문 횟수 보기` | 외래 좌판 방문 누적 카운트 + Tier 4 도달 시 보너스 알림 | 단순 정보 |

**Tier 4에서 외래 좌판 확장**: 거래 가능 재료 종류 +50%, "외래 소식" 텍스트가 M8 세력 재도입의 빌드업 (예: "외래 상인이 어떤 거대한 세력의 깃발을 본 것 같다는 풍문") 노출. M8 의존성 — Tier 4 효과는 페이즈 4 #4에서 stub 가능.

**NPC 추가 (Tier 3 시점)**:
- `npc_foreign_merchant_kael` — 외래 상인 케일 (가칭). 페이즈 3 #5에서 이름·인사말 텍스트 확정
- 더스트빌 NPC 5명 + 외래 상인 1명 = 총 6명

#### 2.5 광장 이정표 (Plaza Signpost) — Tier 2 신설 시각

**기능**: 시각 + 효과
- 시각: 광장 중앙에 이정표 아이콘 표시 (Tier 2부터). 이정표에는 인접 6리전 이름이 새겨짐
- 효과: region 3 → 인접 6리전 (31·127·9·10·146·38) 이동 시간 **-10%**

**구현 옵션** (페이즈 4 #4 명세 입력):
- 옵션 A: `MovementService._calculateDistance()` 분기 추가 — 출발 region 3 + 도착 인접 6리전이면 거리 -10%
- 옵션 B: 이동수단 시설 효과의 별도 누적 — 광장 이정표 +10% bonus 이동수단으로 처리

**권장: 옵션 A**. 페이즈 1 #1 5절 `region_adjacency` 신설 테이블이 페이즈 4 #3에서 도입되면, adjacency 거리에 추가 -10% 곱셈 적용으로 자연 통합.

**M3 region-transform과의 비교**: M3 transform이 sector 단위 시각/기능 변화라면, M7 광장 이정표는 region 3 sector 1(village)의 추가 시각 요소. 둘은 독립.

### 3. 단계 전이 시스템

#### 3.1 트리거 — unlockedFlags 합산 임계

```dart
// 의사 코드 (페이즈 4 #4 명세 입력)
int countAllUnlockedFlags(WidgetRef ref) {
  final regionStateRepo = ref.read(regionStateRepositoryProvider);
  int total = 0;
  for (final regionId in [3, 31, 127, 9, 10, 146, 38]) {
    final state = regionStateRepo.getOrCreate(regionId);
    total += state.unlockedFlags.where((flag) =>
      _m7InfrastructureRelevantFlags.contains(flag)).length;
  }
  return total;
}

// 8개 flag만 카운트 (페이즈 2 #3 확정)
final _m7InfrastructureRelevantFlags = {
  'region_3_pyegwang_reopen_completed',
  'region_31_bandits_cleared',
  'region_31_shrine_quest_completed',
  'region_127_nomad_friendly',
  'region_9_giant_beast_killed',
  'region_10_windrunner_chain_completed',
  'region_146_mist_cleared',
  'region_38_ironbound_pact_completed',
};
```

**임계값 (페이즈 2 #3 확정)**:
- Tier 1 → 2: 2개
- Tier 2 → 3: 4개
- Tier 3 → 4: 6개

**갱신 시점**: `RegionStateRepository.toggleFlag()` 호출 직후. flag 추가 후 합산 → 임계 도달 시 자동 전이.

#### 3.2 전이 trigger fail-soft trailing 패턴 (페이즈 4 #4 명세 입력)

M6 hook 패턴(`AchievementService.grant()`의 fail-soft trailing)과 동일:

```dart
// RegionStateRepository.toggleFlag() 메서드 내부
Future<bool> toggleFlag(int regionId, String flag) async {
  final state = getOrCreate(regionId);
  if (state.unlockedFlags.contains(flag)) return false; // 멱등
  state.unlockedFlags.add(flag);
  await state.save();

  // fail-soft trailing — 인프라 전이 평가
  try {
    await _evaluateInfrastructureTransition();
  } catch (_) { /* fail-soft */ }

  // fail-soft trailing — M6 hook 7번째 평가 (페이즈 1 #2 5.4절)
  try {
    await _achievementService.maybeEvaluateRegionStateHook(regionId);
  } catch (_) { /* fail-soft */ }

  return true;
}

Future<void> _evaluateInfrastructureTransition() async {
  final r3 = getOrCreate(3);
  final currentTier = r3.infrastructureTier ?? 1;
  final flagCount = _countAllInfrastructureRelevantFlags();
  final nextTier = _resolveTier(flagCount);

  if (nextTier > currentTier) {
    r3.infrastructureTier = nextTier;
    await r3.save();

    // 전이 이벤트 publish (다이얼로그 큐 + 활동 로그)
    _ref.read(settlementInfrastructureUpgradedProvider.notifier).state =
        InfrastructureUpgradeEvent(fromTier: currentTier, toTier: nextTier);
    await _activityLogService.add(
      ActivityLogType.settlementInfrastructureUpgraded,
      data: {'fromTier': currentTier, 'toTier': nextTier},
    );
  }
}

int _resolveTier(int flagCount) {
  if (flagCount >= 6) return 4;
  if (flagCount >= 4) return 3;
  if (flagCount >= 2) return 2;
  return 1;
}
```

#### 3.3 저장소 결정 — `RegionState` 확장

**권장: M4 settlement_trust와 동일 패턴**. region 3 RegionState에 신규 HiveField 11 추가.

```dart
@HiveType(typeId: 8)
class RegionState extends HiveObject {
  // 기존 0~10 유지 (HiveField 10은 M7 페이즈 1 #2 unlockedFlags)

  /// M7 페이즈 1 #3 — 마을 인프라 단계 (1~4)
  @HiveField(11)
  int? infrastructureTier; // null = 1 fallback (Tier 1: 고립)

  int get currentInfrastructureTier => infrastructureTier ?? 1;
}
```

**대안 (별도 박스 `settlementStates`)**: M4 페이즈 1 #4 settlement-trust 결정 4.1절과 동일 사유로 기각 — M7 시점에 1지역 1마을 매핑이 자연스럽고, M8+ 다중 거점 확장 시 마이그레이션 path 명확.

**M4 settlement_trust(HiveField 4·5) + M7 infrastructureTier(HiveField 11) 공존**: 두 필드 모두 region 3 RegionState에 존재. 의미 분리 명확.

#### 3.4 활동 로그 + 다이얼로그

**ActivityLogType 추가**:
- `settlementInfrastructureUpgraded` (HiveField 34) — 메시지 예: "더스트빌이 [Tier 2: 연결] 단계로 발전했다"

**DialogTypeRegistry 추가** (12 → 13 → 14종 — 페이즈 1 #2가 13번째 추가, 본 문서는 14번째):
- `SettlementInfrastructureUpgradedDialog` — medium priority, `barrierDismissible: true`

**다이얼로그 표시 정보**:
- 단계 이름 + 톤 텍스트 (2~3줄 서사)
- 신규 해금 효과 요약 (예: Tier 2 → "광장 이정표 / 인접 6리전 이동 시간 -10%")
- "더스트빌로 이동" 버튼 (선택 — region 3 sector 1로 이동)

**Provider 추가**:
```dart
final settlementInfrastructureUpgradedProvider =
    StateProvider<InfrastructureUpgradeEvent?>((ref) => null);

class InfrastructureUpgradeEvent {
  final int fromTier;
  final int toTier;
  final List<String> grantedAchievements; // M6 hook 7번째 결과 (페이즈 1 #2 5.4절)
}
```

`app.dart` ref.listen → `dialogQueue.enqueue` 직후 `state = null` 즉시 리셋 (페이즈 1 #2와 동일 이벤트 채널 패턴).

#### 3.5 강등 정책

**M7 MVP에서는 강등 없음**. unlockedFlags가 영구이므로 인프라 단계도 영구 상승 only. 단, 페이즈 1 #2 3.4절의 dangerScore decay (시간 경과 재증가)와 별개 — decay는 위험도 점수에만 적용되며 unlockedFlags는 영향 없음.

**M9+ 확장 검토**: 마을이 외부 위협(예: M8 세력 전쟁)으로 인프라 단계 강등 가능성. 현재 범위 외.

### 4. M5 레시피 unlock_condition_json 확장

기존 M5 페이즈 4 #2 unlock_condition 3종에 신규 2종 추가:

| unlock_condition_json.type | 의미 | 출현 시점 |
|---------------------------|------|----------|
| `trustLevel` (M4 기존) | settlement_trust 단계 N 이상 | M4 페이즈 4 #4 |
| `chainStep` (M4 기존) | 특정 chain의 step 완료 | M4 페이즈 4 #4 |
| `firstAcquiredItem` (M5 기존) | 특정 재료 첫 입수 | M5 페이즈 4 #2 |
| **`infrastructureTier`** (M7 신규) | infrastructureTier N 이상 | M7 페이즈 4 #4 |
| **`regionFlag`** (M7 신규) | 특정 unlockedFlag 보유 | M7 페이즈 4 #4 |

**예시 레시피 unlock_condition_json**:
```json
// "야수 가죽 도구" — region 9 야수 처치 hook 연동
{
  "type": "regionFlag",
  "flag": "region_9_giant_beast_killed"
}

// "유목민 가죽 장비" — Tier 3 + 친교 hook 동시 충족
{
  "type": "all",
  "conditions": [
    {"type": "infrastructureTier", "value": 3},
    {"type": "regionFlag", "flag": "region_127_nomad_friendly"}
  ]
}
```

**복합 조건**: 페이즈 4 #4에서 `all` (AND) / `any` (OR) 분기 추가. M5 단일 조건 패턴에서 확장.

**CraftingService.evaluateState() 분기 확장**:
```dart
RecipeState evaluateState(CraftingRecipeData recipe, {
  required int trustLevel,
  required Map<String, int> chainStepCompletions,
  required Set<String> firstAcquiredMaterialIds,
  required int infrastructureTier, // M7 신규
  required Set<String> unlockedFlags, // M7 신규
}) {
  if (!_isUnlocked(recipe.unlockCondition, ...)) return RecipeState.locked;
  // ... 기존 ingredient 검증
}

bool _isUnlocked(Map<String, dynamic>? condition, ...) {
  // M7 신규 분기 추가
  switch (condition['type']) {
    case 'infrastructureTier':
      return infrastructureTier >= condition['value'];
    case 'regionFlag':
      return unlockedFlags.contains(condition['flag']);
    case 'all':
      return (condition['conditions'] as List).every(_isUnlocked);
    case 'any':
      return (condition['conditions'] as List).any(_isUnlocked);
    // ... 기존 trustLevel / chainStep / firstAcquiredItem 유지
  }
}
```

### 5. M4 신뢰도와의 통합 정책 (5.0절 — 재강조)

**독립 축 — 두 시스템 모두 region 3 RegionState에 공존하며 독립 작동**:

| 항목 | M4 settlement_trust | M7 infrastructureTier |
|------|---------------------|---------------------|
| **저장 필드** | HiveField 4·5 (trust + trustLevel) | HiveField 11 (infrastructureTier) |
| **점수 범위** | 0 ~ ∞ 누적 단방향 | 1~4 단계 단방향 (강등 없음) |
| **단계** | 4단계 (의심·인지·친근·소속) | 4단계 (고립·연결·거점화·변방의 중심) |
| **트리거** | 고정 사건 + 일반 의뢰 + 이동 선택지 | 7리전 unlockedFlags 합산 |
| **의미** | "마을 사람들과의 친밀도" | "마을의 물리적 성장" |
| **거점 효과 적용 방식** | HerbalistService 비용 multiplier | HerbalistService 비용 multiplier (곱셈 합산) |
| **NPC 인사말** | 결정 (M4 인사말 변주 17개) | 인사말 끝에 한 줄 첨부 (M7 신규 텍스트 — 페이즈 3 #5에서 약 8개 추가) |
| **거점 외관** | 변화 없음 (인사말만) | 변화 있음 (벽 보수 → 재건 → 잔치) |
| **신규 거점 추가** | 없음 | Tier 3에서 외래 좌판 추가 |
| **신규 레시피 해금** | M4 trustLevel 조건 (예: trustLevel 2 이상) | M7 infrastructureTier 조건 + regionFlag 조건 |

**이중 보상 사례 (region 3 폐광 재개방 step 6 완료)**:
- M4 settlement_trust +100 (4단계 진입) — 사회적 친밀도
- M7 unlockedFlag `region_3_pyegwang_reopen_completed` 추가 (1개) — 인프라 진행 1/2 (Tier 2 진입에 필요)

→ region 3 사건은 두 시스템 모두 영향. 의도된 동작.

**다른 region (31·127·9·10·146·38) 사건**:
- M4 settlement_trust 영향 없음 (region 3 한정 시스템)
- M7 unlockedFlag만 영향

→ 외곽 사건은 인프라 성장에 직접 기여, 신뢰도에는 간접 (영향 없음).

### 6. 페이즈 1 #4 + 페이즈 2 #3 입력 요약

#### 6.1 페이즈 1 #4 (이동 목적 강화 + 생활권 진행 곡선) 입력

본 문서의 단계 전이 곡선을 5~8시간 흐름에 배치:

```
0~30분  : Tier 1 — 거점 정착 (M4 그대로)

30분~1시간  : 외출 → flag 0~1개 누적 — Tier 1 유지

1~2시간  : flag 2~3개 (region 3 폐광 일부 + region 31 도적 + region 9 야수 일부) → **Tier 2 진입**
            └ 광장 이정표 설치 시각 + 이동 시간 -10% 효과 발생

2~4시간  : flag 4~5개 (region 31 + region 9 + region 127 친교) → **Tier 3 진입**
            └ 외래 좌판 신설 + 신규 레시피 2~3개 해금

4~6시간  : flag 5~6개 (region 10 chain + region 38 chain 진행) — Tier 3 유지

6~8시간  : flag 6+개 (region 146 또는 region 38 완료) → **Tier 4 진입**
            └ 광장 잔치 시각 + 모든 거점 효과 +20%
```

**페이즈 1 #4 검증**: 5~8시간 누적 플레이 기준 ❑ Tier 4 도달 가능 (M7 종료 조건과 정합).

#### 6.2 페이즈 2 #3 (마을 인프라 성장 비용·요구 사건 수 확정) 입력

본 문서에서 결정된 컨셉:
- Tier 1 → 2: flag 2개
- Tier 2 → 3: flag 4개
- Tier 3 → 4: flag 6개
- 거점 효과 곱셈 multiplier: trust × infra (HerbalistService 패턴)

**페이즈 2 #3 산출물 권장 내용**:
- 임계 flag 수 ±1 조정 (예: Tier 2 → 3을 4개에서 3개 또는 5개로)
- infra cost multiplier 수치 조정 (Tier 3: 0.9, Tier 4: 0.8 권장)
- infra gathering multiplier 수치 조정 (Tier 4: 1.20 권장)
- 광장 이정표 이동 시간 단축률 (-10% → -8 또는 -12)
- 신규 레시피 +1~3 분포 검증 (M5 10개 + M7 4~6개 = 14~16개 총량 검증)

---

## 현재 시스템과의 연관

### 영향받는 시스템

| 영역 | 영향 | 마이그레이션 범위 |
|------|------|------------------|
| `RegionState` 모델 (typeId 8) | HiveField 11 신규 추가 (infrastructureTier) | 페이즈 4 #4 |
| `RegionStateRepository` | 신규 메서드 3개 (getInfrastructureTier / `_evaluateInfrastructureTransition` / `toggleFlag`에 trailing trigger) | 페이즈 4 #4 |
| `VillageFacility` enum | `foreignStall` 추가 (3종 → 4종) | 페이즈 4 #4 |
| `VillageVisitSection` | Tier 3 이상 시 foreignStall 카드 노출 분기 | 페이즈 4 #4 |
| `ForeignStallScreen` (신규) | 3 버튼 인라인 (재료 거래·외래 소식·방문 횟수) | 페이즈 4 #4 |
| `ChiefHouseScreen` | 4번째 버튼 `생활권 정보` 추가 (Tier 2 이상) | 페이즈 4 #4 |
| `OldSmithyScreen` / `RecipeListSection` | 신규 레시피 4~6개 자동 노출 (unlock_condition 충족 시) | 페이즈 4 #4 + 페이즈 3 #5 데이터 |
| `HerbalistService` | calculateCost / calculateCooldownMinutes / gatheringMultiplier에 `infraTier` 인자 추가 | 페이즈 4 #4 |
| `CraftingService.evaluateState()` | infrastructureTier / unlockedFlags 인자 추가 + `infrastructureTier` / `regionFlag` / `all` / `any` 분기 추가 | 페이즈 4 #4 |
| `crafting_recipes.unlock_condition_json` | 신규 type 2종 (`infrastructureTier` / `regionFlag`) + 복합 조건 (`all` / `any`) | 페이즈 3 #5 + 페이즈 4 #4 |
| `MovementService._calculateDistance()` | region 3 ↔ 인접 6리전 거리에 Tier 2 이상 시 -10% 곱셈 (region_adjacency 통합 또는 별도 분기) | 페이즈 4 #4 (페이즈 4 #3 region_adjacency 의존) |
| `ActivityLogType` enum | HiveField 34 (settlementInfrastructureUpgraded) 추가 | 페이즈 4 #4 |
| `DialogTypeRegistry` | settlementInfrastructureUpgraded 신규 (13 → 14종, 페이즈 1 #2가 regionStateChanged로 13번째) | 페이즈 4 #4 |
| `settlementInfrastructureUpgradedProvider` (신규) | StateProvider 채널 + dialogQueue 통합 | 페이즈 4 #4 |
| `SettlementInfrastructureUpgradedDialog` (신규) | medium priority 다이얼로그 | 페이즈 4 #4 |
| `settlement_npc_data` | 외래 상인 NPC 1명 추가 (Tier 3 시점) | 페이즈 4 #4 + 페이즈 3 #5 텍스트 |
| `quest_narratives` | 인프라 단계별 narrative 변주 + 외래 상인 인사말 — 페이즈 3 #5에서 약 5~10행 추가 | 페이즈 3 #5 |

### 호환성 검토

- **기존 사용자 세이브**: HiveField 11 nullable이므로 기존 세이브 호환. null = Tier 1 fallback.
- **M4 settlement_trust 시스템**: 독립 작동 (5절). 두 시스템 모두 region 3 RegionState에 저장, 효과는 거점 메서드에서 곱셈 합산. M4 코드 변경은 HerbalistService 시그니처 확장만 (`infraTier = 1` 기본값 추가로 하위호환).
- **M5 RecipeListSection**: 기존 레시피 10개 unlock_condition은 그대로 동작. M7 신규 레시피 4~6개는 새 unlock_condition type 사용. CraftingService.evaluateState() 인자 추가는 default 값으로 하위호환 (`infrastructureTier = 1, unlockedFlags = {}`).
- **M7 페이즈 1 #2 dangerScore / unlockedFlags 시스템**: 본 문서의 인프라 단계는 unlockedFlags를 **읽기 전용으로 활용**. RegionStateRepository.toggleFlag()의 trailing trigger에서 자동 평가. 페이즈 1 #2 시스템에 변경 없이 통합.
- **M6 hook 7번째 (region_state_transition)**: 페이즈 1 #2 5.4절에서 권장된 hook. 본 문서의 인프라 단계 전이도 동일 hook으로 위업 발급 가능 (예: Tier 4 진입 → 위업 "변방의 영주"). 페이즈 3 #5에서 결정.
- **운영 도구 (operation-bom)**: region 3 RegionState 편집 폼에 infrastructureTier 표시 권장 (디버그용). crafting_recipes 편집 폼의 unlock_condition_json은 자유 JSONB이므로 신규 type 자동 호환.

### Tier 6~10 / 다른 region 비영향 확인

본 시스템은 region 3 한정. RegionState.infrastructureTier가 nullable이므로 다른 39개 region은 영향 없음. M8 세력 재도입 시 다른 거점(예: region 38 부서진 요새가 거점화)에 동일 패턴 복제 권장.

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| 인프라 4단계 구조 (1.1·1.2절) | **높음** | 페이즈 1 #4 + 페이즈 2 #3 + 페이즈 3 #5 + 페이즈 4 #4 모두 본 구조에 의존 |
| 단계 전이 트리거 (unlockedFlags 합산 임계, 3.1절) | **높음** | 페이즈 2 #3 임계 수치 결정의 핵심. 페이즈 4 #4 trailing trigger 코드 입력 |
| 거점 3종 단계 효과 + 외래 좌판 신설 (2절) | **높음** | 페이즈 4 #4 명세 직접 입력 |
| M4 신뢰도와의 분리 정책 (5절) | **높음** | 페이즈 4 #4 구현 시 모호함 제거. 곱셈 합산 패턴 확정 |
| M5 unlock_condition 확장 (4절) | **높음** | 페이즈 3 #5 + 페이즈 4 #4 데이터·코드 입력. 복합 조건 (`all`/`any`) 도입 |
| 광장 이정표 효과 (-10% 이동) (2.5절) | **중간** | 페이즈 4 #3 region_adjacency 도입 결정 후 통합 |
| 신규 레시피 4~6개 (페이즈 3 #5에서 텍스트 결정) | **중간** | 페이즈 3 #5의 별도 산출물. 본 문서는 갯수와 unlock 조건만 |
| Tier 4 외래 상인 풍문 (M8 빌드업) | **낮음** | M8 의존성. 페이즈 4 #4에서 stub 가능 |
| 강등 정책 (3.5절) | **낮음** | M7 MVP 미적용. M9+ 검토 |

---

## 후속 작업

페이즈 1 #4 "이동 목적 강화 + 생활권 진행 곡선"이 본 문서 6.1절을 입력으로 받아 5~8시간 흐름에 단계 전이 시점 배치. 누적 플레이 기준 검증 시나리오 작성.

페이즈 2 #3 "마을 인프라 성장 비용·요구 사건 수 확정"이 본 문서 1.1절·3.1절을 입력으로 받아 다음을 정량화한다.
- 임계 flag 수 (Tier 2: 2 / Tier 3: 4 / Tier 4: 6 권장)
- 거점 효과 multiplier (cost / cooldown / gathering)
- 광장 이정표 이동 단축률
- 신규 레시피 +1~3 분포

페이즈 3 #5 "마을 인프라 성장 narrative + 체인 단계"가 본 문서 2절·5절·표를 입력으로 받아 다음을 생성한다.
- 인프라 단계별 NPC 인사말 추가 약 8개 (Tier 2/3/4 × 거점 3종 — 일부 통합)
- 외래 상인 NPC 1명의 인사말 + 거래 멘트 5~10개
- 신규 레시피 4~6개 텍스트 (이름·설명·재료 조합)
- 단계 전이 시 다이얼로그 텍스트 3종 (Tier 2/3/4 진입)
- 인프라 성장 활동 로그 메시지 (Tier 2/3/4)
- M6 hook 7번째 통합 시 위업 텍스트 1~4개 (Tier 4 진입 위업 "변방의 영주" 등)

페이즈 4 #4 "마을 인프라 성장 시스템 + 진입점 통합"이 본 문서 전체를 명세 입력으로 받아 구현한다.

---

## data-generator 지시사항

본 문서는 **시스템 모델·UI 구조 설계** 위주이며 직접적인 벌크 데이터 생성을 유발하지 않는다. 단, 다음 파생 데이터가 후속 페이즈에서 생성된다.

### (A) `quest_narratives` 인프라 변주 약 8~15행 (페이즈 3 #5 영역)

- **대상 타입**: `quest-narrative` (재사용)
- **대상 테이블**: `quest_narratives` 또는 신규 narrative 테이블 (페이즈 3 #5 결정)
- **생성 수량**: 8~15행 (단계별 NPC 인사말 추가 + 외래 상인 멘트 + 단계 전이 다이얼로그 텍스트)
- **톤/세계관 가이드**: 페이즈 1 #1 더스트빌 톤(먼지·메마름·변방의 인정) 유지. 단계가 오를수록 활기·외래 영향 증가. 외래 상인은 외부 세계의 분위기 (M8 세력 빌드업, 미스터리 톤)
- **구조적 제약**: 
  - 인프라 단계별 NPC 인사말: Tier 2·3·4 × 거점 3종 = 9개 (1개 통합 후 8개)
  - 외래 상인 인사말 + 거래 멘트: 5~7개
  - 단계 전이 다이얼로그 텍스트: 3개 (Tier 2/3/4 진입)
- **수치 출처**: 없음 (텍스트만)
- **특수 요구**: 외래 상인은 M8 세력 재도입의 빌드업 — 특정 세력 이름 미언급, 풍문 톤 유지

### (B) `crafting_recipes` 신규 4~6행 (페이즈 3 #5 영역)

- **대상 타입**: 신규 검토 — M5 기존 `crafting-recipe` 타입 재사용
- **대상 테이블**: `crafting_recipes`
- **생성 수량**: 4~6행 (Tier 2: 1~2 / Tier 3: 2~3 / Tier 4: 1)
- **톤/세계관 가이드**: 야수 가죽·유목민 가죽·안개 늪 인장·부서진 요새 인장 키워드 활용. 페이즈 1 #1에서 정의된 8종 신규 region_exclusive 재료와 결합
- **구조적 제약**:
  - unlock_condition_json: 본 문서 4절 표 참조 (`regionFlag` / `infrastructureTier` / `all` 복합)
  - 재료 조합: M5 12종 재료 + M7 페이즈 1 #1 신규 8종 재료 = 20종에서 조합
  - 결과 아이템 카테고리: personal_equipment 또는 guild_equipment (M5 4종 카테고리 내)
- **수치 출처**: 페이즈 2 #3 (제작 비용)
- **특수 요구**: 페이즈 1 #2 신규 unlockedFlag 8종 중 일부와 1:1 매칭 (예: 야수 가죽 도구 = region_9_giant_beast_killed flag 의존)

### (C) `band_achievement_templates` 추가 1~4행 (페이즈 3 #5 영역 — 선택적)

- **대상 타입**: 기존 26행 패턴 재사용 (별도 타입 스펙 불필요)
- **대상 테이블**: `band_achievement_templates`
- **생성 수량**: 1~4행 (인프라 단계 진입 위업)
  - Tier 4 진입: "변방의 영주" 1행 필수
  - Tier 2·3 진입: 추가 위업 0~2개 (선택)
  - 외래 상인 첫 거래: "외래 친교" 1행 선택
- **톤/세계관 가이드**: 위업 이름 7~12자. M6 페이즈 4 #1 26행 톤과 통일
- **구조적 제약**:
  - category = `infrastructure_growth` (신규)
  - hook_type = `infrastructure_tier` (M6 hook 신규 추가 — 페이즈 4 #4 결정 의존)
  - 또는 페이즈 1 #2 5.4절의 `region_state_transition` hook 통합 활용 (Tier 4 진입 → 위업 발급)
- **수치 출처**: 없음
- **특수 요구**: M6 hook 결정에 의존 (페이즈 4 #1·#4 통합 결정 후 INSERT)
