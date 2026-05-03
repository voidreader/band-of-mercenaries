# M4 40 리전 재편안 + 199→40 매핑표 컨셉 기획서

> 작성일: 2026-05-03
> 유형: 신규 컨텐츠 (M4 마일스톤 — 페이즈 1 산출물 1/5)
> 선행 문서:
> - `Docs/roadmap/master_roadmap.md` (541~939행) — M4 작업 상세, 특히 #지역 축소 정책 577~609행
> 후속:
> - 페이즈 1 #2 "섹터 시스템 재설계" — 본 문서에서 결정한 40개 리전을 입력으로 받아 sector_count·region_sectors·sector_type 정책 설계
> - 페이즈 1 #3 "더스트플레인·더스트빌 컨셉" — 본 문서에서 지정한 시작 리전을 입력으로 받아 분위기·NPC·방문 거점 설계
> - 페이즈 4 #1 "데이터 마이그레이션 + 시작 거점 고정" — 본 문서의 매핑표 CSV를 SyncService 마이그레이션 스크립트에 반영

---

## 개요

현재 199개 리전은 초반 재미를 검증하기에 너무 넓고, 컨텐츠 밀도(quest_pools / chain_quests / region_discoveries)가 얇게 흩뿌려져 있다. M4는 전체 리전을 **40개로 축소**하여 컨텐츠를 의미 있는 장소에 재배치하고, **시작 거점 더스트플레인(mountain) → 더스트빌(village)을 고정**하여 신규 유저의 첫 2시간 경험을 통제 가능한 좁은 공간으로 묶는다.

본 문서는 다음 4가지를 결정한다.

1. **티어별 분포 미세조정** — 로드맵 권장안(T1=3 / T2=5 / T3=7 / T4=6 / T5=5 / T6=4 / T7=4 / T8=3 / T9=1 / T10=2 = 합 40개)을 현재 데이터 분포와 컨텐츠 보존 우선순위를 반영하여 확정한다.
2. **살아남는 40개 region_id 추천** — `regions.region` 값을 그대로 유지한다(재부여 없음). 종속 데이터 변환을 최소화한다.
3. **더스트플레인 신규 지정 정책** — 현재 T1은 모두 plains/coast이므로 mountain 환경의 신규 시작 지역을 만들어야 한다. 신규 region_id 추가 vs 기존 T1 리전 재태깅+재명명 두 옵션 중 후자를 채택한다.
4. **199 → 40 매핑표 CSV 형식 + 종속 데이터 매핑 정책** — chain_quests / region_discoveries / quest_pools / elite_loot_tables 5개 종속 테이블의 region 참조 일괄 변환 룰을 정의한다.

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| Stardew Valley — Pelican Town 중심 설계 | 모든 핵심 컨텐츠가 시작 마을에서 도보 거리 이내에 배치, 광역 맵은 후속 컨텐츠로 확장 | 더스트플레인 인근 T1~T3 리전에 컨텐츠 밀도 집중. 고티어 리전은 M4 시점에 명성 잠금으로 가려 둠 |
| Path of Exile — Act 압축 패치 (1.0 → 3.0) | 너무 긴 초반 흐름을 의미 있는 거점 단위로 재편 | 199 리전(분산형) → 40 리전(거점 단위) 재편. T1~T5에 26개 집중, T6~T10은 데이터만 보존 |
| Stellaris — Galaxy 200 stars 권장값 | "맵이 클수록 재미있다"가 아니라 "한 번의 시야에 들어오는 의미 있는 결정 수"가 재미를 결정 | M4의 첫 2시간 동안 플레이어 시야에 들어오는 "갈 수 있는 리전"을 제한 (T1~T3 = 15개 리전) |
| Slay the Spire — Act 1 노드 수 축소 | 초기 빌드업 단계에서는 선택지가 적어야 학습 부담이 낮다 | T1=3 리전만으로 시작. T2~T3 해금까지 자연스러운 학습 곡선 형성 |

**기존 컨텐츠 보존 원칙**: 현재 chain_quests 7체인 24단계 / region_discoveries 47행 / quest_pools 332행이 특정 region_id에 묶여 있다. 컨텐츠 재작성 부담을 최소화하기 위해 **컨텐츠가 묶인 region_id는 무조건 보존**한다.

---

## 상세 설계

### 1. 현재 199 리전 분포 (실측)

| 티어 | 현재 수 | 환경 | recommend_power 범위 |
|------|---------|------|---------------------|
| T1 | 40 | 초원(22) / 해안(18) — **mountain 없음** | 9~10 |
| T2 | 35 | 숲(24) / 늪(11) | 22~27 |
| T3 | 30 | 폐허(29) / 숲(1) | 40~49 |
| T4 | 25 | 산악(25) | 63~75 |
| T5 | 20 | 전쟁터(20) | 91~109 |
| T6 | 18 | 고대유적(18) — ruins+underground | 130~153 |
| T7 | 15 | 황무지(15) — desert | 171~202 |
| T8 | 10 | 마계경계(10) — mountain | 234~276 |
| T9 | **0** | (없음) | — |
| T10 | 6 | 심연(6) — underground | 466~526 |
| **합계** | **199** | | |

**핵심 인사이트 1**: T1은 plains/coast 일색. 더스트플레인(mountain)은 기존 T1 리전 1개를 재태깅(`environment_tags: ["mountain"]`) + 재명명한다. 신규 region_id를 부여하지 않고 기존 ID를 유지한다.

**핵심 인사이트 2**: T9는 데이터로 0개. 로드맵의 "T9=1개"를 충족하려면 region_id 신규 추가가 필요하다. 200번 부여 권장.

### 2. 티어별 분포 미세조정 (확정안)

| 티어 | 로드맵 권장 | **확정안** | 환경 다양성 권장 | 보존 정책 |
|------|------------|-----------|----------------|----------|
| T1 | 3 | **3** | mountain(더스트플레인) + plains + coast 각 1 | 작업 집중 |
| T2 | 5 | **5** | forest 3 + swamp 2 | 작업 집중 |
| T3 | 7 | **7** | ruins 5 + forest 1 + (신규 환경 1, sector_type 다양화 활용) | 작업 집중 |
| T4 | 6 | **6** | mountain 6 (현 분포 유지) | 작업 집중 |
| T5 | 5 | **5** | plains(전쟁터) 5 | 작업 집중 |
| T6 | 4 | **4** | underground+ruins 4 | 데이터 보존만 (M9) |
| T7 | 4 | **4** | desert 4 | 데이터 보존만 (M9) |
| T8 | 3 | **3** | mountain(마계경계) 3 | 데이터 보존만 (M9) |
| T9 | 1 | **1** | underground 1 (신규) | 데이터 보존만 (M9) |
| T10 | 2 | **2** | underground(심연) 2 | 데이터 보존만 (M9) |
| **합계** | 40 | **40** | T1~T5: **26** / T6~T10: **14** | |

**확정 결정**: 로드맵 권장안을 그대로 채택한다. 미세조정 없음. 환경 다양성은 T1·T3에서 가장 중요한데, 둘 다 현재 environment_tags 분포가 단조롭다(T1: plains/coast만, T3: ruins만 29/30).

### 3. 더스트플레인 신규 지정 정책

**옵션 비교:**

| 옵션 | 설명 | 채택 |
|------|------|------|
| A. 신규 region_id 추가 (200~) | T1 mountain 리전을 region_id 200으로 추가, 기존 T1 40개 중 3개 보존 | ❌ |
| B. **기존 T1 리전 재태깅 + 재명명** | T1 plains/coast 리전 중 종속 데이터 참조가 없는 region_id 1개 선택, `region_name = "더스트플레인"` / `environment_tags = ["mountain"]`으로 변경 | ✅ |

**B안 채택 이유**:
- region_id 보존 원칙(C1)과 자연스럽게 부합한다.
- 신규 region_id 추가는 SyncService 마이그레이션 + StaticGameData 캐시 정합성 추가 부담을 만든다 (B안은 컬럼 UPDATE만으로 끝남).
- 기존 T1 리전 40개 중 chain_quests + region_discoveries 모두 참조 없는 후보가 충분하다(예: 6, 15, 27, 33, 34, 39 등 30+개).

**더스트플레인 region_id 권장: `3`**

| 항목 | 현재 | 변경 후 |
|------|------|--------|
| region | 3 | 3 (그대로) |
| region_tier | 1 | 1 (그대로) |
| region_name | "초원" | **"더스트플레인"** |
| environment_tags | ["plains"] | **["mountain"]** |
| recommend_power | 10 | 10 (그대로) |
| description | (현재 값 유지 또는 신규 작성) | "광산을 품은 변방 산악 지역. 신참 용병들이 첫 발을 떼는 곳." |

**선정 근거**:
- region_id 3은 T1 region_id 중 최저값에 가깝다(1·2는 각각 T5·T7로 점유). `GameConstants.startingRegionId = 3` 상수가 의미 있는 작은 값이 된다.
- chain_quests / region_discoveries 모두 참조 없음 (실측 확인).
- 페이즈 4 명세에서 `initializeNewGame()`이 `region = 3`으로 고정될 때 디버깅 친화적이다.

**대안 후보** (운영 도구에서 최종 결정 가능): region 6, 15, 27 — 모두 기존 컨텐츠 참조 없음.

### 4. 살아남는 40개 region_id 추천

**보존 우선순위:**

1. **1순위 (필수 보존)**: chain_quests 참조 region_id 13개. 살리지 않으면 체인 데이터 재작성 필수.
2. **2순위 (강력 권장 보존)**: region_discoveries 참조 region_id 40개. 살리지 않으면 발견 데이터 재매핑 필요(SyncService 마이그레이션 시 일괄 가능하나, 컨셉 일관성을 위해 보존 권장).
3. **3순위**: 환경 다양성 / 명성 분포 채우기.

**티어별 권장 보존 region_id 리스트:**

| 티어 | 보존 region_id (수) | 비고 |
|------|--------------------|------|
| T1 | **3, 31, 127** (3) | 3=더스트플레인(mountain 재태깅), 31=초원(chain+disc), 127=해안(faction_clue+hidden_quest+info) |
| T2 | **9, 10, 20, 23, 146** (5) | 9·20·23=숲(disc), 10=숲(chain+disc), 146=늪(disc transform) |
| T3 | **5, 38, 49, 50, 51, 52, 65** (7) | 38·49·50·51·65=폐허(chain), 5=숲(disc elite, 환경 다양성), 52=폐허(disc elite) |
| T4 | **13, 16, 21, 24, 28, 35** (6) | 16·21·24·28·35=산악(chain), 13=산악(disc transform) |
| T5 | **1, 25, 67, 90, 105** (5) | 1=전쟁터(disc info+elite+hidden), 나머지 4개는 recommend_power 분포 균형 |
| T6 | **17, 36, 62, 84** (4) | 17·36·62·84=고대유적(disc) |
| T7 | **44, 115** + 2개(예: 56, 154) (4) | 44·115=황무지(disc elite), 나머지 2개는 분포 균형 |
| T8 | **4, 18, 47** (3) | 4·18=마계경계(disc transform), 47=마계경계(chain target) |
| T9 | **200** (1, 신규) | underground 환경, recommend_power ~350~400 |
| T10 | **7** + 1개(예: 11) (2) | 7=심연(disc transform), 11=심연 |
| **합계** | **40** | |

**1순위 누락 region_id 검증**: chain_quests 참조 13개 {10, 16, 21, 24, 28, 31, 35, 38, 47, 49, 50, 51, 65} 모두 보존 ✅

**2순위 누락 region_id (보존 못 한 region_discoveries 참조)**: 2, 7(보존), 12, 14, 19, 26, 32, 74, 99, 102, 110, 116, 129, 147, 178, 190 — 16개 누락. 페이즈 4 명세 단계에서 이 region_id 참조 region_discoveries 행은 **삭제** 처리. 발견 데이터 재배치는 M4 컨텐츠 정책상 필수가 아니므로 허용.

### 5. 199 → 40 매핑표 CSV 형식

**파일 경로**: `Docs/content-data/region_migration_199_to_40.csv` (페이즈 3에서 별도 작성, 또는 페이즈 4 명세 인라인)

**CSV 형식 (3컬럼):**

```csv
old_region_id,new_region_id,note
3,3,KEEP — 더스트플레인 재명명 + environment_tags=["mountain"] 변경 (시작 거점)
6,DELETED,후순위 — 컨텐츠 후보 보관(future_pool/T1_plains_06.md)
9,9,KEEP — T2 숲 (region_discoveries transform 참조 보존)
10,10,KEEP — T2 숲 (chain_quests + region_discoveries 보존)
...
200,200,NEW — T9 underground 신규 추가 (recommend_power=380, region_name="망각의 수면")
```

**CSV 의미론**:
- `new_region_id = old_region_id`이면 **그대로 보존**(C1 원칙). `note`에 변경 컬럼이 있으면 명시.
- `new_region_id = "DELETED"`이면 **삭제**. `note`에 후순위 컨텐츠 보관 경로 또는 사유.
- `new_region_id = "NEW"` (또는 신규 ID)이면 **신규 추가**. `old_region_id`는 빈 값 또는 0.

**예외**: 본 정책상 `new_region_id ≠ old_region_id`인 행(즉, 재부여)은 발생하지 않아야 한다. 만약 발생하면 정책 위반으로 운영 도구 검증 단계에서 차단한다.

### 6. 종속 데이터 매핑 정책

**테이블별 처리 방식:**

| 테이블 | 참조 컬럼 | 매핑 정책 |
|--------|----------|----------|
| `region_discoveries` | `region_id` (INTEGER) | DELETED region 참조 행은 **삭제**. 보존 region 참조 행은 **그대로** |
| `quest_pools` | (현재 region_id 직접 참조 없음, 리전은 difficulty/quest_type/sector_type 기반 동적 매칭) | 변경 없음 |
| `chain_quests` | `region_id`, `target_region_id`, `target_sector_id` (1-based 1..10 → 1..sector_count) | region 매핑은 보존 region만 사용했으므로 변경 없음. **`target_sector_id`는 페이즈 1 #2 산출물에서 sector_count 결정 후 별도 매핑** (10→4 또는 10→sector_count 변환) |
| `elite_loot_tables` | (현재 region 참조 없음, elite_id 기반) | 변경 없음 |
| `factions` | `stronghold_region_id` (M4 #2 산출물에서 신설 예정 컬럼) | M4 #2 산출물 작성 시 본 문서의 살아남는 40개 region_id 안에서만 선택 |
| `regions` | (마스터) | DELETED region 행 삭제, 더스트플레인 region 3 UPDATE, T9 region 200 INSERT |

**chain_quests `target_sector_id` 변환 미해결 문제**:
현재 chain_quests의 `target_sector_id`는 1-based 1..10 (10섹터 기준)로 저장되어 있다. M4에서 sector_count = 4가 기본이 되면 sector_id 5~10 참조 행은 무효해진다. 예를 들어 chain_quests의 target_sector_id = 7이라면 4섹터 리전에서 노출 불가. **본 문제는 페이즈 1 #2 "섹터 시스템 재설계"에서 다룬다** (예: sector_id 5~10 참조 → null로 변환하여 region 전체 하이라이트 fallback / 또는 sector_count = 6짜리 특수 지역으로 승격).

### 7. 삭제 리전 컨텐츠 보관 정책

**보관 디렉토리**: `Docs/content-data/postponed_regions/`

**파일 단위**:
- 삭제되는 리전마다 `T{tier}_{environment}_{old_region_id}.md` 파일 1개 생성
- 내용: 원본 region 데이터(이름·환경 태그·recommend_power) + 해당 리전을 참조하던 region_discoveries / chain_quests / quest_pools 행 스냅샷
- 후속 마일스톤(M7 "지역 생활권 확장" / M8 "세력 재도입")에서 참조하여 재배치 후보로 활용

**수량 추정**: 199 - 39(보존) - 1(T9 신규) = **159개 파일 생성**. 페이즈 3 데이터 생성 단계에서 일괄 추출 가능 (`SELECT * FROM regions WHERE region IN (...) FOR JSON` + `region_discoveries` / `chain_quests` 조인 후 마크다운 변환).

**페이즈 3 처리 옵션**:
- **옵션 A**: 159개 파일 모두 마크다운으로 내보내기 (보관 가치 높음, 파일 수 많음).
- **옵션 B**: 단일 통합 CSV/JSON으로 dump (보관 효율 높음, 검색은 grep으로).
- **옵션 C**: Supabase에 `regions_archive` 백업 테이블 생성 후 199행 옮김 (DB 일관성 좋음, 마크다운 가독성 없음).

**권장**: 옵션 B (`Docs/content-data/postponed_regions_dump.json` 단일 파일). 페이즈 4 명세에서 마이그레이션 스크립트가 수행한다.

### 8. T9 신규 리전 컨셉

| 컬럼 | 값 |
|------|-----|
| region | 200 |
| continent | 1 (기존 동일) |
| region_tier | 9 |
| region_name | "망각의 수면" (제안, 운영 결정) |
| recommend_power | 380 (T8 평균 ~250, T10 최저 466의 중간값) |
| environment_tags | ["underground"] |
| description | "T8 마계경계와 T10 심연 사이의 깊이. 시간이 멈춘 듯한 수면이 펼쳐져 있다. (M9 종속 시스템 확장 예정)" |

T9는 M4 게임플레이상 진입 불가(명성 랭크 부족 + 종속 시스템 미지원). 데이터로만 존재한다.

---

## 현재 시스템과의 연관

### 영향받는 시스템

| 영역 | 영향 | 마이그레이션 범위 |
|------|------|------------------|
| `regions` 테이블 | DELETE 159행 + UPDATE 1행(region 3) + INSERT 1행(region 200) | Supabase 마이그레이션 |
| `region_discoveries` | DELETE ~16행 (DELETED region 참조) | Supabase 마이그레이션 |
| `chain_quests` | 변경 없음 (보존 region만 사용 확인됨) | — |
| `quest_pools` | region 직접 참조 없음. 변경 없음 | — |
| `elite_loot_tables` | 변경 없음 | — |
| `factions` (stronghold_region_id) | M4 #2 산출물에서 신설 컬럼. 본 문서의 40개 region_id 내에서 선택 | M4 #2 의존 |
| `RegionData` Freezed 모델 | 변경 없음 (sector_count 추가는 M4 #2 산출물) | — |
| `StaticGameData` / `DataLoader` | 199 → 40 캐시 갱신. 기존 사용자 캐시는 SyncService가 data_versions 기반 증분 동기화 | 자동 |
| `UserData.region` (Hive) | 매핑표 외 region_id 보유 시 NewGame 강제 (테스트 세이브 초기화) | 페이즈 4 명세 #1 |
| `regionStates.regionId` | 매핑표 외 region_id 보유 행 정리 | 페이즈 4 명세 #1 |
| `factionStates.clueRecords[].regionId` | 매핑표 외 region_id 보유 시 clueRecord 삭제 | 페이즈 4 명세 #1 |
| `chainQuestProgress.chainId` (region 직접 참조 아님) | 변경 없음 | — |

### Tier 6~10 종속 시스템 미지원 정책

본 문서의 T6~T10 보존 region 14개는 데이터로만 존재한다. 다음 종속 시스템은 **M4에서 확장하지 않는다** (M9로 이연):
- `jobs` (현재 1~5만 85개)
- `mercenary_wages` (현재 1~5만 5행)
- `ranks.unlock_tier` (현재 최대 5)
- `elite_monsters.tier` (현재 2~5만 39종)
- `app_theme.tierColor()` (현재 1~5)
- `RecruitmentService` 모집 가중치 (현재 T1:45 / T2:30 / T3:15 / T4:8 / T5:2)
- `difficulties` (현재 5단계)

플레이어가 명성 랭크 부족으로 T6~T10 진입 불가하므로 게임플레이상 영향은 없다. 단, operation-bom 운영 도구는 T6~T10 리전 편집 시 "M9 예정 — 종속 시스템 미지원" 경고를 표시한다.

### 호환성 검토

- **기존 사용자 세이브**: `UserData.region`이 매핑표 DELETED 값이면 NewGame 강제(페이즈 4 명세). 살아남는 40개 region_id를 보유한 세이브는 그대로 호환.
- **operation-bom 웹앱**: `regions` 테이블 편집 폼 변경 없음. 단, T6~T10 편집 경고 추가. 매핑표 임포트 도구 신설(페이즈 4 명세).
- **현재 chain_quests / region_discoveries / quest_pools**: 본 정책으로 chain_quests는 100% 보존. region_discoveries는 약 16행 삭제. quest_pools는 변경 없음.

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| 살아남는 40개 region_id 확정 | **높음** | 페이즈 1 #2~#5 전부 본 결정에 의존 |
| 더스트플레인 region_id 3 재태깅 결정 | **높음** | 시작 거점 고정 + GameConstants 상수 결정의 입력 |
| T9 region 200 신규 추가 | **중간** | M4 게임플레이 영향 없음. 데이터 일관성 차원 |
| 종속 데이터 매핑 정책 합의 | **높음** | 페이즈 4 #1 마이그레이션 명세의 입력 |
| 삭제 리전 159개 컨텐츠 보관 (옵션 B 단일 dump) | **중간** | M7~M8 재활용 자산. 손실 없이 보관 |
| chain_quests `target_sector_id` 변환 | **블로킹** | 페이즈 1 #2 sector_count 결정 후 처리 |

---

## 후속 작업

페이즈 1 #2 "섹터 시스템 재설계"가 본 문서를 입력으로 받아 다음을 결정한다.

- 40개 리전별 `sector_count` (4 기본 / 5~6 특수)
- `region_sectors` 정규화 테이블 컬럼 + 약 160~200행 데이터 컨셉
- `sector_type` 5종(village/ruins/hidden/dungeon/field) 시각·기능 정책
- chain_quests `target_sector_id` 1..10 → 1..sector_count 변환 룰

페이즈 1 #3 "더스트플레인·더스트빌 컨셉"이 본 문서의 region 3 더스트플레인 지정 + #2의 sector_count = 4를 입력으로 받아 분위기·NPC·방문 거점을 설계한다.

---

## data-generator 지시사항

본 문서의 매핑표 CSV (159+ 행)는 단순 ID 매핑이므로 별도 타입 스펙(`types/region-migration.md`) 없이 페이즈 4 명세 #1 "데이터 마이그레이션" 인라인으로 처리 권장. 만약 별도 처리가 필요하다면 다음 가이드를 따른다.

- **대상 타입**: `region-migration` (신규 작성 필요 — 단순 매핑 CSV이므로 권장 안 함)
- **대상 파일**: `Docs/content-data/region_migration_199_to_40.csv` (159행 매핑) + `Docs/content-data/postponed_regions_dump.json` (159행 dump)
- **생성 수량**: 매핑 CSV 199행 / dump JSON 159행
- **수치 출처**: 본 문서 4·5·7절
- **특수 요구**: T9 region 200은 신규 추가이므로 매핑 CSV에 `old_region_id = "" / new_region_id = 200 / note = "NEW"` 행 추가
- **검증**: 매핑 CSV의 KEEP region_id 합계가 정확히 40개인지 검증, DELETED 합계가 정확히 159개인지 검증
