# M4 마을 방문 UI + 거점 3종 + 약초상/의무실 분리 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260503_starting-settlement.md` (페이즈 1 #3 — 4섹터 / 거점 3종 MVP / NPC 5명 / 상태 변화 문구 17개)
> - `Docs/balance-design/[balance]20260503_herbalist-vs-infirmary.md` (페이즈 2 #2 — 약초상 75/50/45/40G + 45/30/15/10m 쿨다운 / 채집 의뢰 골드 배수 ×1.0/×1.1/×1.2)
>
> 작성일: 2026-05-04
> Visual Companion 미사용 (텍스트 기반 UI 명세)
>
> 선행 페이즈:
> - 페이즈 4 #1 region 마이그레이션 (region 3 더스트플레인 고정) — 완료
> - 페이즈 4 #2 region_sectors 데이터 (`RegionSectorFallback.dustplainSectors`) — 완료
> - 페이즈 4 #3 거점 사건/허드렛일 quest_pools 컬럼 확장 (`dustvile_chore_01~10`, `qp_pyegwang_step1~6`) — 완료
> - 페이즈 4 #5 마을 신뢰도 시스템 (`RegionStateRepository.addSettlementTrust`, `settlementTrustProvider`, `settlementTrustLevelUpProvider`) — 완료

---

## 1. 개요

M4 시작 거점인 더스트빌(region 3, sector 1, sector_type='village')에 **마을 방문 영역**을 신설한다. 거점 3종(촌장 집·낡은 대장간·약초상)을 진입할 수 있고, 신뢰도 단계(1~4)에 따라 일부 버튼이 잠긴다. 또한 1회성 즉시 회복 시스템 `HerbalistService`를 신규 추가하여, 자동 회복 기반 의무실 시설과 **역할이 분리된 두 회복 경로**를 제공한다.

본 명세는 컨텐츠·밸런스 결정사항(페이즈 1 #3 / 페이즈 2 #2)을 직접 입력으로 사용하며, 이미 활성화된 `settlementTrustProvider(int regionId)`를 watch하여 단계 변화에 반응한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

#### A. 마을 방문 진입

- **[FR-1]** 이동 화면에서 현재 위치(`UserData.region`/`UserData.sector`)의 sector가 `sector_type == 'village'`일 때만 "마을 내 방문" 영역을 노출한다.
  - 진입점: `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` 하단부 (현재 위치 표시 직후 또는 이동 버튼 직전)
  - 판정: `RegionSectorFallback.lookupSector(currentRegion, currentSector, staticData.regionSectors)?.sectorType == 'village'`
  - 영역에는 광장 풍문 1줄 + 거점 3종 카드(촌장 집 / 낡은 대장간 / 약초상)를 표시한다.
  - 이동 중(`userData.isMoving == true`)에는 영역 비노출.

- **[FR-2]** 거점 카드 탭 시 거점 화면으로 진입한다. **`Navigator.push` 금지**, MovementScreen 내부 상태 변수(`_selectedFacility`)로 상태 기반 렌더링한다.
  - `_selectedFacility == null` → 일반 이동 UI
  - `_selectedFacility == VillageFacility.chiefHouse` / `oldSmithy` / `herbalist` → 해당 거점 화면 위젯 노출

#### B. 촌장 집 (Chief House)

- **[FR-3]** 촌장 집 화면에는 다음 3개 버튼을 표시한다.
  - **상황 듣기**: 활성 거점 사건(`settlement_3_pyegwang_reopen`)의 현재 단계 정보 표시. `chainQuestRepositoryProvider.get('settlement_3_pyegwang_reopen')` 조회 후 `currentStep` 표시(예: "2/6 단계").
    - 사건 미진행 시: 마을 일상 대화(NPC 인사말 단계 1)를 노출.
    - 사건 완료(`UserData.completedChainSet.contains('settlement_3_pyegwang_reopen')`) 시: 사건 완료 직후 24h 노출 메시지(4.3절) 표시 → 24h 경과 후 4단계 인사말로 복귀.
  - **신뢰도 확인**: `settlementTrustProvider(3)` watch로 `(trust, level)` 조회. 4단계 진행 바 + 다음 단계 임계값(`{2:30, 3:80, 4:200}`) 표시.
  - **보상 받기**: M4 MVP에서는 비활성 (보상은 `RegionStateRepository.addSettlementTrust`가 단계 승급 시 자동 지급). 단순히 "단계 진입 시 자동 지급" 안내 문구 표시 + 회색 비활성 처리.
  - 시간 소모: **없음**.

#### C. 낡은 대장간 (Old Smithy)

- **[FR-4]** 낡은 대장간 화면에는 다음 3개 버튼을 표시한다.
  - **제작 목표 보기**: M5 제작 시스템 진입점 예고. 정적 텍스트로 "광부의 단검 (녹슨 쇳조각 ×3 / 마른 가죽끈 ×1)" 등 첫 제작 목표를 표시. M4에서는 보유량 표시·실제 제작 비활성.
  - **수리 의뢰 확인**: 1회/24h 단순 골드 보상 stub. `UserData`에 신규 필드 `lastSmithyRepairAt` 추가하여 24h 쿨다운 관리. 클릭 시 `+50G` 즉시 지급 + 쿨다운 시작 + ActivityLog 기록.
    - 잠금: 신뢰도 1·2단계는 비활성, 3단계 이상에서 활성.
  - **재료 힌트 보기**: 정적 텍스트(섹터별 재료 후보 4줄). 인라인 ExpansionTile로 펼침.

- **[FR-5]** 신뢰도 단계별 잠금:
  - 1단계: 모든 버튼 비활성 + 단계 1 인사말 노출 (하겐: "(고개를 한 번 끄덕이고 다시 모루를 두드린다)").
  - 2단계: 제작 목표 + 재료 힌트 활성, 수리 의뢰 비활성.
  - 3단계: 수리 의뢰 활성.
  - 4단계: 수리 의뢰 보상 ×1.2 (50G → 60G).

#### D. 약초상 (Herbalist)

- **[FR-6]** 약초상 화면에는 다음 3개 버튼을 표시한다.
  - **즉시 회복**: 부상/피로 상태 용병 1명을 즉시 정상 상태로 복구. 골드 차감 + 쿨다운 적용.
  - **채집 정보 보기**: 정적 텍스트(약초 종류 ×3~4 + 출현 섹터). 인라인 ExpansionTile.
  - **재료 힌트 보기**: 정적 텍스트.

- **[FR-7]** **`HerbalistService`** (신규 순수 정적 서비스) — 비용·쿨다운 공식.
  - **비용**: `(50 * multiplier).round()` — multiplier = `{1: 1.5, 2: 1.0, 3: 0.9, 4: 0.8}` → **75G / 50G / 45G / 40G**.
  - **쿨다운(분)**: `{1: 45, 2: 30, 3: 15, 4: 10}`.
  - **단계 조회**: `regionStateRepository.getSettlementTrust(GameConstants.startingRegionId).level`.
  - 시간 소모: **없음** (게임 시간 미사용).

- **[FR-8]** 즉시 회복 적용 흐름:
  1. **버튼 활성 조건**:
     - `now >= UserData.herbalistCooldownEndTime` (쿨다운 종료)
     - 부상(injured) 또는 피로(tired) 용병 ≥ 1명 존재
     - `userData.gold >= calculateCost(trustLevel)`
  2. 버튼 클릭 → 회복 대상 용병 선택 다이얼로그(부상/피로 용병만) → 비용 확인 다이얼로그(`{비용}G + {쿨다운}분 쿨다운`) → 확인.
  3. **회복 처리**: `MercenaryRepository.healInstant(mercId)` 신규 메서드 호출 — 상태를 `MercenaryStatus.normal`로 변경 + `injuryEndTime/tiredEndTime` null 처리 + Hive 저장.
  4. **골드 차감**: `userDataProvider.notifier.spendGold(cost)`.
  5. **쿨다운 설정**: `userDataProvider.notifier.setHerbalistCooldown(now + Duration(minutes: cooldownMinutes))`.
  6. **활동 로그**: `ActivityLogType.herbalistHeal` (신규 enum 값) + 메시지 "약초상이 {용병명}을 즉시 회복시켰다 (-{비용}G)".
  7. `mercenaryListProvider.notifier.refresh()` 호출 → UI 갱신.

- **[FR-9]** 의무실(`facilities['infirmary']`) **변경 없음**: 자동 회복 시간 단축 효과 그대로 유지(`QuestCompletionService.calculate` 내 기존 분기). 약초상 즉시 회복은 `injuryEndTime/tiredEndTime`을 null로 직접 변경하므로 자동 회복 타이머도 즉시 종료된다.

#### E. NPC 인사말 / 광장 풍문

- **[FR-10]** 거점 NPC 3명(파슨/하겐/네리스) + 거리 NPC 2명(도라 할멈/레미) 총 5명 데이터를 const 자료구조로 보관.
  - 거점별 화면 상단에 NPC 이미지(이모지) + 이름 + 신뢰도 단계별 인사말 1줄 노출 (4.1절 12개 표).
  - 광장 풍문(도라/레미)은 마을 방문 영역 상단에 1줄 노출, 단계별 4개 변주(4.2절).
  - 사건 완료 직후 24h 동안 모든 거점 화면 상단에 4.3절 공통 메시지 노출(우선 적용).

#### F. 채집 의뢰 골드 보상 배수

- **[FR-11]** `dustvile_chore_03`(채집 의뢰, `min_trust_level=2`)을 식별하여 신뢰도 단계별 골드 보상 배수 적용.
  - 적용 위치: `QuestCompletionService.calculate` 내 `rewardGold` 계산 직후, `quest.questPoolId == 'dustvile_chore_03'`이고 결과 success/greatSuccess일 때 배수 곱.
  - 단계별 배수: 1단계 미노출 (`min_trust_level=2`), 2단계 ×1.0, 3단계 ×1.1, 4단계 ×1.2.
  - 신뢰도 단계 주입: 호출측 `quest_provider._completeQuest`에서 `regionStateRepository.getSettlementTrust(quest.region).level` 전달.
  - **신뢰도 보상은 단계 곱셈 미적용** (기존 페이즈 4 #5 결정 — 일반 의뢰 신뢰도 점수표 `{1:2, 2:3, 3:5, 4:0, 5:0}` 그대로 적용).

#### G. 광장 풍문·사건 완료 24h 윈도우

- **[FR-12]** 거점 사건 완료 시점을 추적하기 위해 `RegionState`에 신규 필드 `lastEventCompletedAt` (HiveField 6, `DateTime?`) 추가.
  - 페이즈 4 #5의 `QuestListNotifier._applyCompletionResult` 거점 사건 step==6 완료 분기에서 `regionStateRepository`에 위임하여 저장.
  - 본 명세에서는 별도 Repository 메서드 추가 + 호출 분기만 명시.
  - 24h 경과 판정: `now.difference(lastEventCompletedAt!) <= Duration(hours: 24)`이면 사건 완료 메시지 노출.

### 2.2 데이터 요구사항

#### Hive 모델 변경

| 박스 | 클래스 | 신규 필드 | HiveField | 타입 | 용도 |
|------|--------|----------|-----------|------|------|
| `user` | `UserData` | `herbalistCooldownEndTime` | 22 | `DateTime?` | 약초상 다음 사용 가능 시각 (null=쿨다운 없음) |
| `user` | `UserData` | `lastSmithyRepairAt` | 23 | `DateTime?` | 낡은 대장간 수리 의뢰 마지막 사용 시각 (24h 쿨다운) |
| `regionStates` | `RegionState` | `lastEventCompletedAt` | 6 | `DateTime?` | 거점 사건 완료 시각 (24h 인사말 변환 윈도우) |

#### enum 확장

| enum | 신규 항목 | HiveField | 용도 |
|------|----------|-----------|------|
| `ActivityLogType` (typeId 6) | `herbalistHeal` | 25 | 약초상 즉시 회복 활동 로그 |
| `ActivityLogType` | `smithyRepairCompleted` | 26 | 낡은 대장간 수리 의뢰 완료 활동 로그 |

#### 신규 정적 자료 (lib 내 const, Supabase 미사용)

`features/settlement/domain/settlement_npc_data.dart` 신규 파일에 다음 const 자료를 보관:
- NPC 5명 (id, name, location, greetingByLevel: `Map<int, String>`)
- 광장 풍문 4종 (level → text)
- 사건 완료 메시지 1종

`features/settlement/domain/settlement_visual_data.dart` (선택, 또는 npc_data와 통합) — 거점별 분위기 키워드, 약초 종류 텍스트, 재료 힌트 텍스트, 제작 목표 텍스트.

#### 정적 데이터 테이블 변경 (Supabase)

본 명세에서는 **변경 없음**. 채집 의뢰 보상 배수는 코드 상수, NPC/문구는 인라인 const로 처리.

#### 밸런스 수치 (확정)

| 항목 | 값 |
|------|---|
| 약초상 비용 곡선 | 75G / 50G / 45G / 40G |
| 약초상 쿨다운 곡선 | 45m / 30m / 15m / 10m |
| 채집 의뢰 골드 배수 | 1.0 / 1.1 / 1.2 (단계 2/3/4) |
| 낡은 대장간 수리 의뢰 보상 | 단계 3: 50G / 단계 4: 60G (×1.2) |
| 사건 완료 메시지 노출 윈도우 | 24h |

### 2.3 UI 요구사항

> Visual Companion 목업 미사용. 텍스트 기반으로 위젯 계층·상태 변수·기존 패턴 준수를 명시.

#### 화면 진입 조건

- 이동 화면(`MovementScreen`)에서 `userData.region == GameConstants.startingRegionId(3)` AND `userData.sector` 의 sector_type이 `'village'` 일 때 "마을 내 방문" 영역이 노출된다.
- 영역 내 거점 카드(촌장 집/낡은 대장간/약초상) 탭 시 거점 화면으로 진입.

#### 위젯 계층

```
MovementScreen (ConsumerStatefulWidget)
└── Column
    ├── 상단 바 (기존 유지)
    └── Expanded
        └── SingleChildScrollView
            └── Column
                ├── 현재 위치 / 지역 선택 / 섹터 선택 / 이동 버튼 (기존 유지)
                └── _VillageVisitSection (신규, 조건부 노출)
                    ├── _SquareGossipBanner (도라/레미 풍문 1줄)
                    ├── _FacilityCard ×3 (촌장 집/낡은 대장간/약초상)
                    │   └── 탭 → setState(_selectedFacility = ...)
                    └── (조건부) _ChiefHouseScreen / _OldSmithyScreen / _HerbalistScreen
                        ├── 상단: NPC 헤더 (이모지 + 이름 + 단계별 인사말)
                        ├── 본문: 3개 버튼 (단계별 활성/비활성)
                        └── 하단: 닫기 버튼 → setState(_selectedFacility = null)
```

#### 상태 변수 (MovementScreen 추가)

| 변수 | 타입 | 용도 |
|------|------|------|
| `_selectedFacility` | `VillageFacility?` enum {chiefHouse, oldSmithy, herbalist} | 현재 진입한 거점. null 시 마을 영역 메뉴 표시 |

#### 단계별 활성화 규칙 (요약)

| 거점 | 1단계 | 2단계 | 3단계 | 4단계 |
|------|-------|-------|-------|-------|
| 촌장 집 [상황 듣기] | ✅ | ✅ | ✅ | ✅ |
| 촌장 집 [신뢰도 확인] | ✅ | ✅ | ✅ | ✅ |
| 촌장 집 [보상 받기] | ❌ (M4 MVP 자동지급, 비활성+안내) | ❌ | ❌ | ❌ |
| 대장간 [제작 목표 보기] | ❌ | ✅ | ✅ | ✅ |
| 대장간 [수리 의뢰 확인] | ❌ | ❌ | ✅ (50G) | ✅ (60G) |
| 대장간 [재료 힌트 보기] | ❌ | ✅ | ✅ | ✅ |
| 약초상 [즉시 회복] | ✅ (75G + 45m) | ✅ (50G + 30m) | ✅ (45G + 15m) | ✅ (40G + 10m) |
| 약초상 [채집 정보 보기] | ❌ | ✅ | ✅ | ✅ |
| 약초상 [재료 힌트 보기] | ❌ | ✅ | ✅ | ✅ |

비활성 버튼은 **회색 disabled 상태로 노출** (기획 문서 권장 — NPC 인사말이 페널티 사유를 자연스럽게 설명).

#### 화면 전환

- **상태 기반 렌더링** (CLAUDE.md 제약 준수). `Navigator.push` 사용하지 않는다.
- 거점 화면 진입/이탈은 `_selectedFacility` 상태 변수의 set/null 전환으로 처리.
- 마을 내 방문 영역 자체는 인라인 펼침 (탭 토글 불필요, 항상 노출).

#### 연출/애니메이션

- 거점 카드 호버/탭 시 `Material InkWell` 기본 ripple.
- 약초상 즉시 회복 후: `SnackBar` 1초 표시 + `mercenaryListProvider` 자동 갱신으로 부상 표시 즉시 사라짐.
- 단계 1 비활성 버튼은 흐릿한 회색(`AppTheme.borderLight`).

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField 22 `herbalistCooldownEndTime` (DateTime?), HiveField 23 `lastSmithyRepairAt` (DateTime?) 추가 | 약초상 쿨다운 / 대장간 수리 의뢰 쿨다운 영속화 |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | HiveField 6 `lastEventCompletedAt` (DateTime?) 추가 + getter `eventCompletedRecently` | 사건 완료 24h 인사말 윈도우 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | `setEventCompleted(int regionId)` 메서드 추가 | step==6 완료 시 시각 기록 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | HiveField 25 `herbalistHeal`, HiveField 26 `smithyRepairCompleted` 추가 | 활동 로그 항목 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` (또는 UserDataNotifier 위치) | `setHerbalistCooldown(DateTime?)` / `setSmithyRepairAt(DateTime?)` 메서드 추가 | 쿨다운 시각 영속 |
| `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` | `healInstant(String mercId)` 메서드 추가 | 부상/피로 즉시 정상 복귀 + 타이머 null 처리 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | `MercenaryListNotifier.healInstant(String mercId)` wrapper 추가 + ActivityLog 기록 | 도메인 진입점 |
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | sector_type=='village' 분기에서 `_VillageVisitSection` 인라인. `_selectedFacility` 상태 변수 추가 + 거점 화면 분기 | 마을 영역 / 거점 진입 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | `calculate()` 시그니처에 `int currentTrustLevel = 1` 추가. 채집 의뢰(`questPoolId == 'dustvile_chore_03'`) success/greatSuccess 시 보상에 `gatheringMultiplier(level)` 곱 | 채집 의뢰 골드 배수 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | `_completeQuest`에서 `regionStateRepository.getSettlementTrust(quest.region).level`을 `QuestCompletionService.calculate`에 주입 | 신뢰도 단계 전달 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/settlement/domain/herbalist_service.dart` | 비용/쿨다운 정적 서비스. `static int calculateCost(int trustLevel)` / `static int calculateCooldownMinutes(int trustLevel)` / `static double gatheringMultiplier(int trustLevel)` |
| `band_of_mercenaries/lib/features/settlement/domain/settlement_npc_data.dart` | NPC 5명 + 광장 풍문 + 사건 완료 메시지 const 자료. `RegionSectorFallback`과 동일한 인라인 패턴 |
| `band_of_mercenaries/lib/features/settlement/domain/village_facility.dart` | `enum VillageFacility { chiefHouse, oldSmithy, herbalist }` |
| `band_of_mercenaries/lib/features/settlement/view/village_visit_section.dart` | 마을 영역 진입 위젯 (광장 풍문 + 거점 3종 카드) |
| `band_of_mercenaries/lib/features/settlement/view/chief_house_screen.dart` | 촌장 집 화면 위젯 (3개 버튼) |
| `band_of_mercenaries/lib/features/settlement/view/old_smithy_screen.dart` | 낡은 대장간 화면 위젯 (3개 버튼 + 잠금 분기) |
| `band_of_mercenaries/lib/features/settlement/view/herbalist_screen.dart` | 약초상 화면 위젯 (3개 버튼 + 즉시 회복 흐름) |
| `band_of_mercenaries/lib/features/settlement/view/herbalist_heal_dialog.dart` | 즉시 회복 대상 선택 + 비용 확인 다이얼로그 |
| `test/features/settlement/herbalist_service_test.dart` | 비용/쿨다운/배수 공식 테스트 |
| `test/features/settlement/herbalist_heal_flow_test.dart` | healInstant + cooldown + gold deduction 단위 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField 22·23 추가로 `user_data.g.dart` 재생성 |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | HiveField 6 추가로 `region_state_model.g.dart` 재생성 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | enum HiveField 25·26 추가로 `activity_log_model.g.dart` 재생성 |

`cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 1회 실행 필수.

### 3.4 관련 시스템

- **마을 신뢰도 시스템 (페이즈 4 #5)**: `settlementTrustProvider`/`RegionStateRepository.getSettlementTrust` 재사용. 본 명세에서 신뢰도 점수를 직접 변경하지 않는다 (단계 변화는 페이즈 4 #5의 `addSettlementTrust`만 담당).
- **거점 사건 시스템 (페이즈 4 #3 + #5)**: `chainQuestRepositoryProvider.get('settlement_3_pyegwang_reopen')`로 진행 단계 조회. 사건 step==6 완료 시 `lastEventCompletedAt` 기록 (페이즈 4 #5의 step 완료 분기에 1줄 추가).
- **MovementScreen 섹터 시각화**: 본 명세에서 변경 없음. 마을 내 방문 영역은 기존 섹터 그리드 하단에 추가만.
- **의무실 시설 (FacilityService)**: 변경 없음. 약초상은 별도 경로로 작동.
- **ActivityLog 시스템**: enum 항목 2개 추가 외 변경 없음.
- **Dialog Queue**: 본 명세는 다이얼로그 큐를 사용하지 않는다 (즉시 회복은 인라인 다이얼로그·SnackBar로 처리, 신뢰도 단계 승급은 페이즈 4 #5의 `settlementTrustLevelUpProvider`가 이미 담당).

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **상태 기반 화면 전환**: `band_of_mercenaries/lib/features/info/view/info_screen.dart` (`_showCodex`/`_selectedFactionId`/`_showRank` 상태 변수 + 분기 순서). 본 명세의 `_selectedFacility`도 동일 패턴.
- **인라인 const 정적 자료**: `band_of_mercenaries/lib/core/data/region_sector_fallback.dart` (`dustplainSectors` const list). NPC/인사말 자료를 동일 형태로 보관.
- **순수 정적 서비스**: `band_of_mercenaries/lib/features/info/domain/faction_join_service.dart` (Ref 미의존, static 메서드 묶음). `HerbalistService`도 동일 패턴.
- **Repository 신규 메서드**: `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart:45` (`updateStatus`) — `healInstant`도 동일 박스 + Hive `save()` 패턴.
- **Notifier wrapper 메서드**: `mercenary_provider.dart:54` (`applyEvolution`) — Repository 호출 + ActivityLog 기록 + `refresh()` 패턴.
- **신뢰도 watch**: `dispatch_screen` / `quest_provider._getCurrentTrustLevel` (현재 위치 region 기반). 거점 화면은 `GameConstants.startingRegionId(3)` 고정 사용.
- **거점 사건 진행 조회**: `quest_provider._injectFixedSettlementQuest` (`chainQuestRepositoryProvider.get(chainId)` → `currentStep`).

### 4.2 주의사항

- **`Navigator.push` 금지** (CLAUDE.md): 거점 진입은 반드시 상태 기반 렌더링.
- **시간 미소모 원칙** (기획 문서 1·2.3절): 약초상 즉시 회복 / 수리 의뢰 보상 / 거점 화면 모두 게임 시간을 소모하지 않는다. `gameTickProvider` 무관.
- **자동 회복 타이머와 충돌**: `MercenaryRepository.healInstant`가 `injuryEndTime`/`tiredEndTime`을 null로 설정해야 `MercenaryListNotifier._checkTimers`가 더 이상 해당 용병에 대해 트리거되지 않는다.
- **HiveField 번호 충돌 방지**: UserData 22·23, RegionState 6, ActivityLogType 25·26는 현재 미사용 (탐색 확인 완료). 향후 신규 필드 추가 시 25 이상부터 사용하도록 명시.
- **`questPoolId == 'dustvile_chore_03'` 하드코딩**: M4 MVP 한정 단일 채집 의뢰. M5 이후 채집 의뢰 풀이 늘어나면 `quest_pools.tags` JSONB 또는 boolean 컬럼으로 일반화 필요 (본 명세에서는 단일 ID 분기가 가장 단순).
- **수리 의뢰 stub의 보상 경로**: `userDataProvider.notifier.addGold(50)` 직접 호출 + `lastSmithyRepairAt = now` 저장. 퀘스트 시스템 우회 (`quest_pools` 행 추가하지 않음).
- **사건 완료 24h 윈도우**: `RegionState.lastEventCompletedAt`는 페이즈 4 #5에서 step==6 완료 분기에 1줄 추가하여 갱신. 본 명세는 RegionStateRepository에 메서드 추가 + 호출 위치 명시까지만 담당.
- **`settlementTrustProvider` 재계산**: `regionStateRepositoryProvider`는 `Provider`이라 watch만 해서는 RegionState의 settlementTrust 변경을 반영하지 못한다. 단계 승급은 `settlementTrustLevelUpProvider` listen이 이미 처리하므로 거점 화면에서는 진입 시점에 `ref.read`로 fetch + 인사말 갱신.
- **build_runner 실행 시점**: HiveField 추가 후 반드시 `build_runner build`. 미실행 시 adapter 재생성 누락 → Hive 기존 데이터 마이그레이션 실패 위험.

### 4.3 엣지 케이스

- **부상/피로 용병 0명일 때 [즉시 회복] 클릭**: 버튼 자체를 disabled. 잠금 사유 툴팁 "회복 대상 용병이 없습니다".
- **골드 부족**: `userData.gold < cost` → 버튼 disabled + "골드가 부족합니다" 툴팁.
- **쿨다운 진행 중**: `now < herbalistCooldownEndTime` → 버튼 disabled + "다음 사용까지 {남은 시간}분" 툴팁. `gameTickProvider` watch로 1초마다 갱신.
- **사망(dead) 용병**: 즉시 회복 대상에서 제외 (사망은 영구 제거이므로 정의상 불가).
- **파견 중 용병**: `isDispatched == true` 용병도 즉시 회복 대상에서 제외 (파견 중인 용병은 부상 상태가 아님).
- **거점 사건 미진행 + 신뢰도 1단계**: 촌장 집 [상황 듣기]가 단계 1 일상 대화로 fallback. 빈 콘텐츠 방지.
- **앱 재시작 후 쿨다운 복원**: HiveField 22로 영속화되어 자동 복원. 별도 마이그레이션 불필요.
- **신뢰도 4단계 진입 직후 거점 진입**: `settlementTrustLevelUpProvider` 다이얼로그 종료 후 거점 화면 정상 진입. 다이얼로그 큐 충돌 없음.
- **수리 의뢰 stub의 24h 쿨다운 만료 판정**: `now.difference(lastSmithyRepairAt!) >= 24h` 또는 `lastSmithyRepairAt == null`.
- **사건 완료 24h 윈도우 경계**: 23h 59m 시점은 사건 메시지 노출 / 24h 0m 시점부터 단계 4 인사말로 복귀. `Duration` 비교로 단순 처리.
- **다른 region 진입 시 거점 화면 자동 종료**: MovementScreen `initState`/`didChangeDependencies`에서 `userData.region` 변경 감지 시 `_selectedFacility = null`로 강제 리셋.

### 4.4 구현 힌트

- **진입점 (호출 흐름)**:
  - 마을 영역 노출: `MovementScreen.build` → `RegionSectorFallback.lookupSector` → `sectorType == 'village'` 판정.
  - 거점 진입: `_FacilityCard` onTap → `setState(_selectedFacility = ...)`.
  - 즉시 회복: `_HerbalistScreen` 버튼 → `_HerbalistHealDialog` → `mercenaryListProvider.notifier.healInstant(mercId, cost, cooldownMinutes)`.

- **데이터 흐름**:
  - 신뢰도 단계: `settlementTrustProvider(3).level` watch → 단계별 활성/비활성 분기 → NPC 인사말 lookup.
  - 즉시 회복: UI → `MercenaryListNotifier.healInstant` → `MercenaryRepository.healInstant` (Hive write) + `userDataProvider.notifier.spendGold` + `userDataProvider.notifier.setHerbalistCooldown` + `activityLogProvider.notifier.addLog` → state refresh.
  - 채집 의뢰 보상 배수: `quest_provider._completeQuest` → `RegionStateRepository.getSettlementTrust(region).level` 조회 → `QuestCompletionService.calculate(currentTrustLevel: ...)` 주입 → 내부 분기 `quest.questPoolId == 'dustvile_chore_03'` → `rewardGold *= HerbalistService.gatheringMultiplier(level)` → 정수 반올림.
  - 사건 완료 24h: `quest_provider._applyCompletionResult`의 `step == 6` 분기에 1줄 추가 → `regionStateRepository.setEventCompleted(quest.region)` 호출.

- **참조 구현**:
  - `band_of_mercenaries/lib/features/info/view/info_screen.dart` — 상태 기반 다중 화면 전환 패턴.
  - `band_of_mercenaries/lib/features/info/domain/faction_join_service.dart` — 순수 정적 서비스 + 비즈니스 룰.
  - `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart:54` — Notifier wrapper + ActivityLog 패턴.
  - `band_of_mercenaries/lib/core/data/region_sector_fallback.dart` — const 정적 자료 인라인.
  - `band_of_mercenaries/lib/core/widgets/settlement_trust_up_dialog.dart` — 거점 관련 UI 색상·이모지 매핑 reference.

- **확장 지점**:
  - `MovementScreen.build` 의 sector 그리드 직후 (현재 라인 280 부근, "Travel time & button" 직전)에 `_VillageVisitSection` 삽입.
  - `QuestCompletionService.calculate` 의 `rewardGold` 계산 직후 (현재 라인 196 부근, `final mercTiers = ...` 직전) 에 채집 의뢰 배수 분기 삽입.

---

## 5. 기획 확인 사항

> 본 명세는 합리적 권장안을 채택하여 구현 계획을 단일하게 만들었다. 사용자 검토 시 변경 의사가 있으면 다음 항목을 토론한다.

- **[Q-1]** NPC 5명 + 인사말 17개 데이터 위치 → `lib/features/settlement/domain/settlement_npc_data.dart` const 정적 자료로 인라인 (RegionSectorFallback 패턴). Supabase 테이블 미신설.
  - **권장 사유**: M4 MVP는 region 3 단일 거점 한정, 데이터 ~25개 항목, 변경 빈도 낮음. 신규 테이블 운영 비용 대비 가치 낮음.

- **[Q-2]** 채집 의뢰 식별 방법 → `quest_pools.id == 'dustvile_chore_03'` 단일 행 하드코딩. M5에서 채집 의뢰 풀 확장 시 일반화.
  - **권장 사유**: 페이즈 4 #3에서 채집 의뢰는 dustvile_chore_03 1건만 존재. boolean 컬럼/태그 추가는 운영 비용만 늘림.

- **[Q-3]** HerbalistService 위치 → `lib/features/settlement/domain/herbalist_service.dart` 신규 settlement feature 디렉토리.
  - **대안**: `lib/features/facility/domain/herbalist_service.dart` (의무실과 동일 묶음).
  - **권장 사유**: 마을 방문 UI / 거점 3종 / 신뢰도 통합이 하나의 settlement 묶음. facility는 시설 큐·건설 시스템 전용으로 유지.

- **[Q-4]** 거점 화면 구조 → MovementScreen 내부 `_selectedFacility` enum + 분기 (상태 기반 렌더링, CLAUDE.md 준수).
  - **대안 1**: 별도 SettlementScreen + 탭 추가 — 6탭 구조 변경 비용 크고, 시작 거점 한정이라 가치 낮음.
  - **대안 2**: 모달 다이얼로그 — 화면 작아 정보 밀도 부족.
  - **권장 사유**: MovementScreen 라이프사이클과 자연 결합 (region 변경 시 자동 리셋 가능).

- **[Q-5]** UserData HiveField 번호 22·23. RegionState HiveField 6. ActivityLogType HiveField 25·26.
  - **확인**: 충돌 없음 (탐색 완료). UserData 21까지 사용, RegionState 5까지 사용, ActivityLogType 24까지 사용.

- **[Q-6]** 사건 완료 24h 윈도우 추적: `RegionState.lastEventCompletedAt` 신규 필드.
  - **대안**: `UserData.completedChains` 리스트만 보고 24h 윈도우 추적 — 시각 정보 없어 불가능.
  - **권장 사유**: RegionState는 거점별 상태 묶음에 자연스러움. settlement 사건은 region 단위 → 의미 매핑 일치.

- **[Q-7]** 낡은 대장간 [수리 의뢰 확인]은 quest_pools 행 추가 없이 거점 화면 인라인 stub (1회/24h, 50G/60G).
  - **권장 사유**: 페이즈 1 #3 권장(M4 시점 즉시 보상 stub). M5 제작 시스템 진입 시 정식 quest_pools 행으로 마이그레이션.

- **[Q-8]** [채집 정보 보기] / [재료 힌트 보기]는 정적 텍스트 (M4 MVP). M5 인벤토리 시스템 도입 시 동적 보유량 표시로 확장.
  - **권장 사유**: 기획 문서 2.2절·2.3절 명시. 재료 시스템 자체가 M5 이연.

- **[Q-9]** 비활성 버튼 표시 정책: **회색 disabled로 노출** (완전 숨김 X).
  - **권장 사유**: 기획 문서 4.1절 NPC 인사말이 페널티 사유를 자연스럽게 설명. 학습 효과.

- **[Q-10]** 거점 사건 진행 step 표시 (촌장 집 [상황 듣기]): 진행도 "n/6" 형식. 단계별 brief 텍스트는 chain_quests.description 직접 사용.
  - **권장 사유**: chain_quests 테이블 description을 신규 텍스트로 중복하지 않음.

- **[Q-11]** 약초상 즉시 회복 시 `MercenaryRepository.healInstant` 단일 메서드 신규.
  - **대안**: `updateStatus(mercId, MercenaryStatus.normal, endTime: null)` 재사용 — 가능하지만 의도 명확성 위해 신규 메서드 분리.
  - **권장 사유**: 의도 명확 + 향후 회복 효과 변경 시 단일 책임.

- **[Q-12]** 단계 진입 보상 별도 [보상 받기] 버튼 vs 자동 지급: M4 MVP는 자동 지급 (페이즈 4 #5의 `addSettlementTrust`가 단계 승급 시 즉시 지급). [보상 받기] 버튼은 비활성 + 안내 문구.
  - **권장 사유**: 페이즈 4 #5 이미 구현된 자동 지급 흐름 유지. 명시적 수령 단계 추가 시 기존 흐름 변경 비용.

---

## 6. 구현 순서 (참고용)

1. **데이터 레이어** (build_runner 영향)
   - UserData / RegionState / ActivityLogType HiveField 추가 → `build_runner build`
   - RegionStateRepository.setEventCompleted 메서드 추가
   - MercenaryRepository.healInstant + UserDataNotifier.setHerbalistCooldown / setSmithyRepairAt 추가

2. **도메인 레이어**
   - HerbalistService (정적 서비스)
   - MercenaryListNotifier.healInstant wrapper
   - QuestCompletionService 채집 의뢰 배수 분기 + quest_provider 호출측 트러스트 단계 주입

3. **UI 레이어**
   - settlement_npc_data.dart const 자료
   - VillageFacility enum
   - VillageVisitSection / 거점 화면 3종 / HerbalistHealDialog
   - MovementScreen 분기 추가 + region 변경 시 _selectedFacility 리셋

4. **테스트**
   - HerbalistService 비용/쿨다운/배수 단위 테스트
   - healInstant 흐름 테스트

5. **수리 의뢰 stub** (낡은 대장간)
   - lastSmithyRepairAt 영속 + 24h 쿨다운 + addGold + ActivityLog
