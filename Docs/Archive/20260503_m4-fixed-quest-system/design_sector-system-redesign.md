# M4 섹터 시스템 재설계 컨텐츠 기획서

> 작성일: 2026-05-03
> 유형: 신규 컨텐츠 (M4 마일스톤 — 페이즈 1 산출물 2/5)
> 선행 문서:
> - `Docs/content-design/[content]20260503_region-40-redesign.md` — 살아남는 40개 region_id, T6~T10 데이터 보존 정책
> - `Docs/roadmap/master_roadmap.md` (610~657행) — M4 #섹터 축소 정책 + 섹터 이름 시스템
> 후속:
> - 페이즈 1 #3 "더스트플레인·더스트빌 컨셉" — 본 문서의 sector_count = 4 + sector_type 5종을 입력으로 받아 4섹터 구성 확정
> - 페이즈 4 #2 "region_sectors 신규 테이블 + 섹터 데이터 기반 렌더링" — 본 문서의 테이블 스펙·변환 룰을 마이그레이션 명세에 반영

---

## 개요

현재 모든 리전은 10섹터 하드코딩(`GameConstants.sectorCount = 10`)이지만, M3 변형 섹터·체인 퀘스트 시스템 도입 후 실측 컨텐츠 밀도는 리전당 1~3섹터에 집중되어 있다. M4는 섹터 수를 데이터 기반으로 전환하여 일반 리전은 4섹터, 컨텐츠 밀도가 높은 특수 리전은 5~6섹터를 사용한다.

본 문서는 다음 4가지를 결정한다.

1. **sector_count 정책 + 40 리전별 분포 권장** — `regions.sector_count INT NOT NULL DEFAULT 4` 컬럼 신규.
2. **`region_sectors` 정규화 테이블 스펙** — 컬럼 정의 + 약 165행 추정 데이터 컨셉.
3. **sector_type 5종 (village/ruins/hidden + 신규 dungeon/field) 시각·기능 정책** — LayerSidebar/QuestCardBadges 아이콘·색상 권장안.
4. **레거시 sector_index 변환 룰** — chain_quests의 target_sector_id(실측 모두 null)·region_discoveries의 sector_index(0-based) ↔ 신규 region_sectors의 1-based 인덱싱 호환 정책.

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| Stardew Valley — Map 영역 분할 | 한 맵 안에 명확한 이름·기능을 가진 4~5개 sub-area로 구획화 | 일반 리전 4섹터 + 각 섹터에 의미 있는 이름·sector_type 부여 |
| Slay the Spire — Map 노드 압축 | 동일한 Act 안에서도 노드 수를 ~15개로 제한하여 한 화면에 들어오게 | 4섹터 그리드 = 한 화면에 모두 보이는 의미 있는 선택지 수 |
| OGame — Planet의 6개 슬롯 | 한 행성 안에 최대 슬롯이 명확히 제한되어 있고, 각 슬롯은 고유한 건물 타입 점유 | 특수 리전 5~6섹터에서 마을 1번 슬롯 고정 + 던전/필드/유적 등 타입별 슬롯 |
| EVE Online — System 별 행성·달 위계 | 같은 시스템 안에서도 행성/달/문라인 등 위계가 명확히 구분 | sector_type 5종으로 같은 리전 안에서 위계 구분 (마을 = 안전 / 던전 = 위험 / 필드 = 일반) |

**기존 게임과의 차별 포인트**: M3까지는 모든 섹터가 시각적으로 동일하고 인덱스만 달랐다(`sectorChanges` 변형 트리거 외에는 구분 없음). M4는 섹터 자체에 정체성(`sector_type`)을 부여하여 "이 리전의 1번 섹터는 마을이고, 2번은 폐광이다"가 데이터로 표현된다.

---

## 상세 설계

### 1. sector_count 정책

#### 1.1 컬럼 신설

```
regions 테이블 신규 컬럼:
  sector_count   INT NOT NULL DEFAULT 4
                 -- 1..6 범위. CHECK 제약 권장
```

#### 1.2 분포 규칙

| 구분 | sector_count | 권장 적용 | 비고 |
|------|--------------|-----------|------|
| 일반 리전 | **4** | 대부분의 리전 | 기본 4섹터 그리드 (2x2 또는 1x4 렌더링) |
| 특수 리전 | **5** | 컨텐츠 밀도가 높은 거점·시작 지역 | 마을(1) + 4개 보조 섹터 |
| 특수 리전 | **6** | 매우 특별한 거점 (현재 M4 시점에서는 없음) | 미래 거점 확장 여지 (M7) |

`sector_count = 6`은 M4 MVP에서 사용하지 않는다. 컨셉적 여지만 남긴다.

#### 1.3 40 리전별 sector_count 분포 권장

페이즈 1 #1 산출물의 살아남는 40개 region_id 기준.

| 티어 | region_id | sector_count | 환경 | 특수 사유 |
|------|-----------|--------------|------|----------|
| T1 | 3 (더스트플레인) | **4** | mountain | 시작 거점. 단순함 우선 |
| T1 | 31 | 4 | plains | chain_roadside_shrine 시작점 |
| T1 | 127 | **5** | coast | faction_clue + hidden_quest + info 다중 발견 — 거점급 컨텐츠 밀도 |
| T2 | 9, 10, 20 | 4 | forest | |
| T2 | 23 | **5** | forest | transform sector_index 7 보존을 위해 5섹터 승격 (재매핑) |
| T2 | 146 | **5** | swamp | transform sector_index 6 보존을 위해 5섹터 승격 (재매핑) |
| T3 | 5 | 4 | forest | |
| T3 | 38, 49, 50, 51, 52, 65 | 4 | ruins | |
| T4 | 13, 16, 21, 24, 28, 35 | 4 | mountain | |
| T5 | 1 | **5** | plains | info + elite + hidden_quest 다중 발견 — 거점급 |
| T5 | 25, 67, 90, 105 | 4 | plains | |
| T6 | 17, 36, 62, 84 | 4 | underground | M9 이연. 게임플레이 영향 없음 |
| T7 | 44, 56, 115, 154 | 4 | desert | M9 이연 |
| T8 | 4, 18, 47 | 4 | mountain | M9 이연. region 18의 transform sector_index 5는 4섹터 한도 외 (변환 룰 적용) |
| T9 | 200 (신규) | 4 | underground | M9 이연 |
| T10 | 7, 11 | 4 | underground | M9 이연 |
| **합계** | **40** | 4×36 + 5×4 = **164행** | | |

**5섹터 특수 리전: 4개** (3개 transform 보존 + 1개 거점 컨셉)
- region 23, 146: 기존 transform 데이터 보존 (sector_index 7, 6 → 변환 룰)
- region 127: 시작 거점 인근 거점급 (페이즈 1 #3에서 더스트플레인 인근으로 확정)
- region 1: T5 전쟁터 거점급 (다중 발견 컨텐츠 밀도)

### 2. `region_sectors` 정규화 테이블 스펙

#### 2.1 컬럼 정의

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | TEXT | PK | 섹터 ID. 명명 규칙: `r{region_id}_s{sector_index}` (예: `r3_s1`) |
| `region_id` | INTEGER | NOT NULL, FK → regions.region | 소속 리전 |
| `sector_index` | INTEGER | NOT NULL, CHECK (sector_index BETWEEN 1 AND 6) | **1-based** (1..6) |
| `name` | TEXT | NOT NULL | 섹터 이름 (예: `더스트빌`, `폐광`) |
| `sector_type` | TEXT | NOT NULL, CHECK (sector_type IN ('village','ruins','hidden','dungeon','field')) | 섹터 유형 |
| `environment_tags` | JSONB | NOT NULL DEFAULT '[]' | 섹터 단위 환경 태그 (엘리트 스폰 필터 보강) |
| `description` | TEXT | nullable | 섹터 짧은 설명 (UI 노출용, 1~2문장) |

**유니크 제약**: `(region_id, sector_index)` UNIQUE — 동일 리전 내 섹터 인덱스 중복 방지.

#### 2.2 인덱싱 일관성 정책 (중요)

기존 데이터와 신규 region_sectors 사이에 sector_index 베이스가 다르다.

| 위치 | 인덱싱 베이스 | 정책 |
|------|--------------|------|
| `region_sectors.sector_index` | **1-based** (1..6) | 신규. 마스터 데이터 가독성 우선 |
| `RegionState.sectorChanges` Map 키 | **0-based** ("0".."9") | 기존 Hive 데이터. 마이그레이션 부담으로 보존 |
| `region_discoveries.discovery_data->sector_index` | **0-based** (0..9) | 기존 JSONB 데이터. 보존 |
| `chain_quests.target_sector_id` | **1-based** (1..10) (master_roadmap.md 기재) | 기존 SQL 데이터. **실측 24행 모두 null이므로 변환 불필요** |

**변환 책임은 Flutter 어댑터 레이어에 위임**한다.
- `RegionStateRepository` 또는 `MovementScreen` 측에 `_to0Based(int oneBased) => oneBased - 1`, `_to1Based(int zeroBased) => zeroBased + 1` 헬퍼 도입.
- Hive 박스 `sectorChanges`는 0-based 유지(스키마 호환성). UI 렌더링 시점에 region_sectors의 1-based와 매칭하여 표시.

#### 2.3 데이터 컨셉 (40 리전 × 평균 ~4.1섹터 = 164행 추정)

페이즈 3 데이터 생성에서 약 164행 입력. 본 문서에서는 더스트플레인의 4섹터를 예시로 제시하고, 나머지 39개 리전 분량은 페이즈 1 #3과 페이즈 3에서 확정.

**더스트플레인 (region 3) 4섹터 예시:**

| sector_index | name | sector_type | environment_tags | description |
|--------------|------|-------------|------------------|-------------|
| 1 | 더스트빌 | village | ["mountain","village"] | 산기슭의 작은 마을. 촌장 집·낡은 대장간·약초상이 있다 |
| 2 | 폐광 | dungeon | ["mountain","dungeon"] | 한때 번성했던 광산. 지금은 도굴꾼과 거대 박쥐가 자리 잡았다 |
| 3 | 마른 초원 | field | ["mountain","plains"] | 마을 외곽의 거친 풀밭. 약초 채집과 야간 순찰 의뢰가 자주 나온다 |
| 4 | 먼지로 덮인 길 | field | ["mountain","road"] | 외부로 통하는 유일한 산길. 호위와 여행자 조우 의뢰가 일어난다 |

**환경 태그 규칙**:
- 부모 리전의 environment_tags(예: `["mountain"]`)를 기본 상속.
- 섹터 특성을 반영하는 태그를 추가 (예: 폐광 → `dungeon`, 길 → `road`).
- 엘리트 몬스터 스폰 필터(`elite_monsters.environment_tags` 교집합)에 사용되므로 최소 1개 필수.

### 3. sector_type 5종 시각·기능 정책

#### 3.1 5종 정의

| sector_type | 의미 | 출처 | 신규/기존 |
|-------------|------|------|----------|
| `village` | 마을·도시. **1번 섹터 고정**(마을 있는 리전) | M3 변형 + M4 시작 거점 | 기존 |
| `ruins` | 변형된 폐허 | M3 변형 시스템 | 기존 |
| `hidden` | 숨겨진 장소 | M3 변형 시스템 | 기존 |
| `dungeon` | 던전·폐광. 위험 의뢰·엘리트 후보 | M4 신규 | **신규** |
| `field` | 들판·길·평원. 일반 의뢰·호위/이동 의뢰 | M4 신규 | **신규** |

#### 3.2 시각 정책 (AppTheme 색상 권장)

| sector_type | 아이콘 | 권장 색상 | AppTheme 신규 키 | 사유 |
|-------------|--------|----------|-----------------|------|
| `village` | 🏘️ | 따뜻한 amber `0xFFFFA000` | 기존 `transformVillage` 재사용 | 친근함·안전 |
| `ruins` | 🏛️ | 차가운 stone gray `0xFF78909C` | 기존 `transformRuins` 재사용 | 폐허·고대 |
| `hidden` | ✨ | 미스테리 보라 `0xFF7E57C2` | 기존 `transformHidden` 재사용 | 신비 |
| `dungeon` | ⛏️ (또는 🕳️) | 위험 적갈색 `0xFFB71C1C` | **신규 `sectorDungeon`** | 위험·전투 |
| `field` | 🌾 (또는 🌿) | 평온 녹색 `0xFF558B2F` | **신규 `sectorField`** | 평이·일상 |
| (기본 / 무지정) | (없음) | `surface` | — | 일반 섹터 |

**아이콘 대안**:
- dungeon: ⛏️(곡괭이) 채택 권장 — 광산 컨셉 부합. 🕳️(구멍)는 가독성 떨어짐.
- field: 🌾(벼) 또는 🌿(잎) 중 환경에 따라 — 본 문서는 🌾로 통일 권장 (mountain에서도 마른 초원 컨셉 부합).

#### 3.3 기능 정책

| sector_type | 파견 메뉴 영향 | 마을 방문 UI | 엘리트 스폰 | 변형 |
|-------------|--------------|--------------|------------|------|
| `village` | quest_pools.sector_type='village' 12개 노출 | **노출 트리거** (M4 #4 산출물) | 차단 (안전 지역) | 트리거 가능 (변형 결과) |
| `ruins` | quest_pools.sector_type='ruins' 12개 노출 | 미노출 | 가능 | 트리거 결과 |
| `hidden` | quest_pools.sector_type='hidden' 10개 노출 | 미노출 | 가능 | 트리거 결과 |
| `dungeon` | **신규 quest_pools.sector_type='dungeon' 권장** | 미노출 | 우선 가능 (위험 지역) | 트리거 안 함 |
| `field` | **신규 quest_pools.sector_type='field' 권장** | 미노출 | 가능 | 트리거 안 함 |

**quest_pools 신규 sector_type 풀 권장 (페이즈 3 또는 페이즈 4 인라인)**:
- `dungeon`: 6~8개 풀 (raid/hunt 위주, 난이도 2~4)
- `field`: 6~8개 풀 (escort/explore/하드렛일 위주, 난이도 1~2)

본 산출물에서는 컨셉만 명시. 실제 풀 수치·텍스트는 페이즈 2 #3 (허드렛일 보상 곡선) + 페이즈 3 또는 페이즈 4 명세에서 확정.

#### 3.4 LayerSidebar / QuestCardBadges 적용

기존 `LayerSidebar` 8단계 우선순위 fold(체인 → 세력 전용 → 엘리트 → 변형 섹터 → 일반)에 sector_type 시각 정보가 추가된다.

- **변형 섹터(현재)**: village/ruins/hidden 3종만 LayerSidebar에 명시 색상 표기.
- **M4 확장**: 변형이 아닌 일반 dungeon/field 섹터는 **퀘스트 카드의 보조 시각 마커**로만 표기 (LayerSidebar 우선순위에는 포함하지 않음). MovementScreen 섹터 그리드에서만 아이콘+색상 테두리 표시.

이는 LayerSidebar 8단계 fold의 의미 보존을 위함이다. dungeon/field가 LayerSidebar에 포함되면 일반 퀘스트 정렬 우선순위가 흐려진다.

### 4. 레거시 sector_index 변환 룰

#### 4.1 chain_quests.target_sector_id (변환 불필요)

**실측 결과**: 24행 모두 `target_sector_id = null`. 변환 작업 자체가 불필요.

**정책 명시 (방어적)**: 페이즈 4 #1 마이그레이션 명세에 다음 검증 단계만 포함.
```
ASSERT: SELECT COUNT(*) FROM chain_quests WHERE target_sector_id IS NOT NULL = 0
  → 0 아니면 마이그레이션 실패 처리
```

#### 4.2 region_discoveries.discovery_data->sector_index (변환 필요 — 살아남는 region 한정)

**실측 결과**: transform 18행 중 살아남는 region에 속한 7행, 그 중 sector_index ≥ 4인 행 3개.

| region_id | 기존 sector_index (0-based) | sector_count | 처리 방안 |
|-----------|---------------------------|--------------|----------|
| 18 (T8 마계경계) | 5 | 4 | **sector_count는 4 유지**. region 18은 M9 이연 / 게임플레이 진입 불가. **sector_index를 0~3 중 1로 재매핑** (예: 1번 = ruins 변형 가능 위치). 게임 영향 없음 |
| 23 (T2 숲) | 7 | **5로 승격** | 5섹터 승격 후 **sector_index 7 → 4 재매핑** (1-based로는 5번 섹터). hidden 변형 보존 |
| 146 (T2 늪) | 6 | **5로 승격** | 5섹터 승격 후 **sector_index 6 → 4 재매핑**. hidden 변형 보존 |

**페이즈 4 #1 명세 작성 시 SQL 예시**:
```sql
-- region 18: sector_count=4 유지, sector_index 5→1 재매핑
UPDATE region_discoveries
SET discovery_data = jsonb_set(discovery_data, '{sector_index}', '1')
WHERE region_id = 18 AND discovery_type = 'transform';

-- region 23, 146: sector_count=5 승격 + sector_index 6/7 → 4 재매핑
UPDATE regions SET sector_count = 5 WHERE region IN (23, 146, 127, 1);
UPDATE region_discoveries
SET discovery_data = jsonb_set(discovery_data, '{sector_index}', '4')
WHERE region_id IN (23, 146) AND discovery_type = 'transform';
```

#### 4.3 RegionState.sectorChanges (Hive — 변환 필요)

기존 사용자 세이브의 `sectorChanges` 키(0-based "0".."9")가 신규 sector_count 4 미만 키만 유효해진다.

**페이즈 4 #1 처리 방안**: SyncService 또는 마이그레이션 게이트에서 다음 검증.

```dart
// 의사 코드
final regionData = staticData.regions[regionState.regionId];
if (regionData == null) {
  // 매핑표 외 region — 테스트 세이브 초기화 (페이즈 1 #1 정책)
  regionState.delete();
} else {
  final maxIdx = regionData.sectorCount - 1;  // 0-based 최대
  regionState.sectorChanges.removeWhere((k, _) => int.parse(k) > maxIdx);
}
```

매핑표 외 region을 보유한 세이브는 NewGame 강제(페이즈 1 #1 정책 일관). 매핑표 내 region이지만 sector_index 초과 키는 무시·정리.

### 5. operation-bom 운영 도구 영향

페이즈 4 #2 명세 입력으로 다음 운영 도구 변경이 필요하다.

- `regions` 편집 폼: `sector_count` 필드 추가 (1..6). T6~T10 리전 편집 시 "M9 이연 — 종속 시스템 미지원" 경고 (페이즈 1 #1 정책).
- `region_sectors` 신규 CRUD 페이지: 일반 폼. region_id 드롭다운 + sector_index 1..6 + sector_type 5종 select.
- `chain_quests.target_sector_id` 입력 시 1-based(1..sector_count) 검증 (현재는 자유 입력).
- `data_versions`에 `region_sectors` 신규 항목 추가.

---

## 현재 시스템과의 연관

### 영향받는 시스템

| 영역 | 영향 | 마이그레이션 범위 |
|------|------|------------------|
| `regions` 테이블 | `sector_count` 컬럼 신규 + UPDATE 4행 (region 1, 23, 127, 146 → 5) | Supabase 마이그레이션 |
| `region_sectors` 신규 테이블 | CREATE + 약 164행 INSERT | Supabase 마이그레이션 + 페이즈 3 데이터 생성 |
| `region_discoveries` | 3행 sector_index 재매핑 (region 18 / 23 / 146) | Supabase 마이그레이션 |
| `chain_quests.target_sector_id` | 변경 없음 (실측 모두 null) | — |
| `quest_pools.sector_type` | dungeon/field 신규 풀 12~16개 추가 권장 (페이즈 3) | Supabase INSERT |
| `RegionData` Freezed 모델 | `sectorCount` 필드 추가 (`@JsonKey('sector_count')`) | 페이즈 4 #2 |
| `RegionSectorData` Freezed 모델 | **신규** (`core/models/region_sector_data.dart`) | 페이즈 4 #2 |
| `StaticGameData` / `DataLoader` | `regionSectors` 필드 추가, 캐시 로딩 | 페이즈 4 #2 |
| `SyncService` | `region_sectors` 동기화 + `data_versions` 신규 항목 | 페이즈 4 #2 |
| `GameConstants.sectorCount` 상수 | **폐기**. `RegionData.sectorCount` 사용 | 페이즈 4 #2 |
| `MovementScreen` | `List.generate(10, ...)` 하드코딩 → `region.sectorCount` 동적 렌더링 + 섹터 이름·아이콘 표시 | 페이즈 4 #2 |
| `RegionState.sectorChanges` | sector_count 초과 키 정리 어댑터 | 페이즈 4 #2 |
| `LayerSidebar` / `QuestCardBadges` | 변형 섹터 시각은 그대로. dungeon/field는 MovementScreen 그리드에만 적용 | 페이즈 4 #2 |
| `AppTheme` | `sectorDungeon`(0xFFB71C1C) / `sectorField`(0xFF558B2F) 신규 색상 | 페이즈 4 #2 |
| Hive `RegionState` 모델 | 변경 없음 (sectorChanges는 0-based 유지) | — |

### 호환성 검토

- **기존 사용자 세이브**: `RegionState.sectorChanges` 키 정리는 SyncService가 자동 처리. 데이터 손실 없음(어차피 4섹터 외 변형은 새 sector_count에서 무효).
- **operation-bom 웹앱**: `region_sectors` 신규 CRUD 페이지 필요. M4 데이터 입력의 핵심 도구.
- **현재 chain_quests / region_discoveries / quest_pools**: 본 정책으로 chain_quests 100% 보존, region_discoveries 3행 재매핑, quest_pools 신규 풀 추가만 필요.
- **`GameConstants.sectorCount` 폐기**: 페이즈 4 #2 명세에서 grep으로 모든 사용처 찾아 `region.sectorCount`로 교체. `core/providers/game_state_provider.dart`의 `initializeNewGame()` 섹터 random 선택 로직은 페이즈 4 #1에서 `startingSector` 상수로 이미 교체 예정.

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| sector_count 정책 + 40 리전별 분포 확정 | **높음** | 페이즈 1 #3 더스트플레인 4섹터 결정의 기반 |
| `region_sectors` 정규화 테이블 스펙 확정 | **높음** | 페이즈 3 데이터 생성 + 페이즈 4 #2 명세 입력 |
| sector_type 5종 시각·기능 정책 | **높음** | 페이즈 4 #2 + 운영 도구 폼 디자인 |
| 인덱싱 베이스 일관성 정책 (1-based vs 0-based) | **중간** | 페이즈 4 #2 어댑터 구현 시 명확화. 본 문서로 정책 확정 |
| chain_quests target_sector_id 변환 | **낮음 (불필요)** | 실측 모두 null. 검증 ASSERT만 명세에 포함 |
| region_discoveries 3행 sector_index 재매핑 | **중간** | 페이즈 4 #1 마이그레이션 SQL에 인라인. 변환 룰 4.2절 참조 |
| dungeon/field quest_pools 풀 추가 (12~16개) | **중간** | 페이즈 2 #3 보상 곡선 + 페이즈 3 또는 페이즈 4 인라인 |
| AppTheme `sectorDungeon`/`sectorField` 색상 신규 | **낮음** | 페이즈 4 #2 에서 함께 처리 |

---

## data-generator 지시사항

본 문서의 `region_sectors` 약 164행은 **신규 타입 스펙 작성 필요**.

- **대상 타입**: `region-sector` (신규 작성 필요)
- **타입 스펙 경로**: `Docs/data-generator/types/region-sector.md` (페이즈 3 진입 시 작성)
- **대상 테이블**: `region_sectors`
- **생성 수량**: 약 164행 (40 리전 × 평균 4.1섹터)
- **톤/세계관 가이드**: 한국어 실지명 스타일. "더스트빌", "마른 초원", "먼지로 덮인 길" 등 구체적인 장소감 우선. 추상적 명사("동쪽 구역", "1구역") 지양
- **구조적 제약**:
  - 마을 있는 리전(村이 있는 리전)의 1번 섹터는 **반드시** `sector_type='village'`
  - 더스트플레인(region 3)의 4섹터는 본 문서 2.3절 예시를 그대로 사용 (페이즈 1 #3에서 확정)
  - sector_type 분포: village ~5 + ruins ~12 (변형 결과 보존) + hidden ~10 (변형 결과 보존) + dungeon ~30 + field ~107 (대다수)
  - environment_tags는 부모 리전 environment_tags를 기본 상속, 섹터 특성에 따라 추가
- **수치 출처**: 본 문서 1.3절 분포표
- **특수 요구**:
  - region 23 (T2 숲), region 146 (T2 늪), region 127 (T1 해안), region 1 (T5 전쟁터)는 sector_count = 5
  - 나머지 36개 리전은 sector_count = 4
  - region 200 (T9 신규)은 sector_count = 4 (M9 이연이지만 데이터 일관성 차원)
  - T6~T10 리전 14개는 게임플레이 진입 불가하므로 섹터 이름은 분위기만 맞으면 충분 (실제 노출 없음)
- **검증**:
  - `(region_id, sector_index)` UNIQUE 제약 만족
  - 모든 region의 sector_count와 region_sectors 행 수 일치 (40 리전 × 자기 sector_count = 164)
  - sector_type 5종만 사용
  - region 18·23·146·127·1의 transform/discovery sector_index와 region_sectors의 sector_index 정합성 검증
