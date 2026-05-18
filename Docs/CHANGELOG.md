# CHANGELOG

## 2026-05-17

### M7 페이즈 4 — 지역 생활권 시스템 통합 구현

- 더스트빌 인근 7리전(3·31·127·9·10·146·38)에 **위험도 4단계** 시스템 도입 (안정/평온/긴장/위협). 의뢰 완료·체인 완주·엘리트 처치로 위험도가 변하면 큰 전이 시 알림이 뜨고 "도적길 평정자" 같은 위업 7종이 발급된다.
- **QuestGenerator 가중치 매트릭스** 도입 — 같은 region에서도 상태(위협↔안정)에 따라 raid/hunt/escort/explore 의뢰 빈도가 차별화. 도적 5회 소탕 후 안정 상태 진입 시 호위 의뢰 약 49% 점유로 체감 변화.
- 신규 quest_pools 36행 + 36개 의뢰 풀별 cumulative/oneshot 효과 + 8개 영속 flag 토글 시스템.
- **마을 인프라 4단계** 시스템 (고립/연결/거점화/변방의 중심). 외곽 7리전 사건 해결로 unlockedFlags 2/4/6개 도달 시 더스트빌 인프라가 자동 성장 + 보상 100/200/500G + XP/명성 합산. Tier 4 진입 시 "변방의 영주" 위업 발급.
- **외래 좌판** 신규 거점 (Tier 3+) — 외래 상인 케일 NPC + 8종 재료 거래(Tier 4 -20% 할인) + 외래 소식 + 방문 횟수.
- 약초상 비용/쿨다운/채집 보상이 신뢰도 × 인프라 단계 곱셈 합산 — Tier 4 도달 시 비용 -57%, 쿨다운 -84%, 채집 +44%.
- 촌장 집에 "생활권 정보" 버튼 추가 (Tier 2+) — 7리전 위험도 한눈에 확인.
- **이동 화면 확장** — 7리전 빠른 점프 칩 + dangerLevel 4색 배지 + unlockedFlags 미니 배지 + 환경 아이콘(🏔️/🌊/🌳/🌫️/🏛️/🌾) + 잠금 사유 명시.
- **region_adjacency** 인접 그래프 신설 (22행) — region 이동 거리가 더 자연스러운 지리적 거리로 계산. region 3 ↔ 도적길·해안 2칸, 외곽 숲·풍신 숲 3칸, 부서진 요새·회색 늪지 4칸.
- **광장 이정표** 효과 — Tier 2+ 도달 시 region 3 출발/도착 이동 시간 -10%.
- 신규 6 제작 레시피 (Tier 2~4) — 야수 가죽 도구·들꽃 약초 향료·유목민 가죽 장비·해안 약물·안개 늪 인장 장신구·부서진 요새 인장 장비. unlock_condition `regionFlag`/`infrastructureTier`/`all`/`any` 4 type 지원.
- 시간 경과(12시간) 시 안정화된 region이 자연 회귀하는 decay 메커니즘 — 재방문 동기.
- chain_m7_mist_clearing 2단계 추가 — 회색 늪지 안개 해소 (특수 단발 -50).

## 2026-05-15

### M6 페이즈 4 #2 — 칭호·간판 용병 시스템

- 칭호 시스템 추가 — 위업/행동지표/상태 hook 3종으로 자동 발급되는 11종 칭호 (마을의 은인·도적길 추적자·백전노장·정찰의 눈·호위의 노련함 등). 사망/방출 후에도 mercSnapshot에 영구 보존.
- 간판 용병 시스템 추가 — 5단계 정렬(칭호 수→위업 주인공→레벨→partyPower→가입 빠른 순)로 자동 선정. 홈 야영지 카드 노출 + 용병 상세에서 수동 지정 토글 (자동/수동 4상태 전환).
- 위업 발급 시 칭호 1줄 인라인 — AchievementUnlockedDialog 본체에 "칭호 획득" 1줄 통합 표시. (b)/(c) hook은 신규 TitleUnlockedDialog (high priority).
- 칭호 효과 — PassiveBonusService 통합 (mercenary 단위 자동 가산). questRewardMultiplier·mercenaryXpBonus 가산 상한 +0.30 명시.
- Supabase `titles` 테이블 신규 (31번째) + 11행 시드. 행동 지표 임계 페이즈 2 #1 결정값 반영(raid 20·dispatch 80·explore 15·escort 12).
- 페이즈 4 #1 `band_achievement_templates` 테이블 (30번째) + 26행 시드도 함께 적용.
- ActivityLog "칭호 획득" 항목 노출 (홈 활동 로그 + 연대기 ✩ 아이콘).

### M6 페이즈 4 #3 — 지명 의뢰 시스템 (M6 마일스톤 완료)

- 지명 의뢰 시스템 추가 — 칭호/위업 누적/간판 용병 정체성을 의뢰인이 알아보고 의뢰를 보내는 7종 지명 의뢰. hook 3종(title 3 / achievement_count 2 / flagship 2) + 24h 쿨다운 + 가중치 +α=3로 노출 빈도 자연 분산.
- 의뢰 카드 차별화 — 신규 `namedAccent` 분홍 마젠타 색상으로 사이드바·이름·테두리·배지 일관 강조. ✩ 지명 배지에 hook별 설명("칭호 — {name}" / "위업 N개 이상" / "간판 용병 지명").
- 잠금 UI — title hook은 보유 용병 전원 파견 중일 때, flagship hook은 동결 용병 파견 중일 때 카드 dim + 토스트 "지명 용병 {name}이(가) 복귀해야 수행할 수 있습니다".
- 보상 보너스 — 골드 +30~50% + 명성 +30~50% 자동 적용 (`special_flags.named_reward_multiplier` / `named_reputation_multiplier`).
- 자동 종료 — 사망/방출 시 진행 중인 flagship 의뢰 자동 정리 + ActivityLog "지명 의뢰 '{name}'가 지명 용병의 부재로 종료되었다" 발급.
- 파견 화면 정렬 6슬롯 → 7슬롯 — 신규 `NamedTier`가 거점 사건 다음, 세력 전용 위에 배치.
- `quest_pools` 4 컬럼 확장(M4 `is_fixed` 패턴 재사용) + CHECK 2종 + 부분 INDEX + 7행 데이터 시드.
- M6 마일스톤 전체 완료 — roadmap 종료 조건 4건 모두 충족 (3~5h 내 용병 이름·칭호 기억 / 시작 거점 사건 해결 용병 지명 의뢰 1회 이상 / 사망 용병 연대기 영구 보존 / 간판 용병 시스템).

## 2026-05-13

### M6 페이즈 4 #1 — 위업·연대기 시스템

- 용병단의 영구 기록을 추적하는 위업·연대기 시스템 신규 도입. 7 카테고리(체인 완주 / 거점 사건 / 거점 신뢰도 4단계 / 명성 등급 / 엘리트 유니크 첫 처치 / 희귀 첫 제작 / 추모) 단일 인터페이스로 통합.
- 6 hook 자동 통합: 체인 완주(`ChainQuestService.completeChain`) · 거점 신뢰도 4단계(`RegionStateRepository.addSettlementTrust`) · 명성 등급 진입(`UserDataNotifier.addReputation`) · 엘리트 유니크 첫 처치(`quest_provider._applyCompletionResult`) · T3+ 첫 제작(`CraftingService.craft`) · 사망/방출 memorial(`quest_provider` dead 분기 + `MercenaryRepository.dismiss` 직전 snapshot 구성). 모두 fail-soft trailing side effect로 본 흐름과 격리.
- `AchievementUnlockedDialog` high priority 다이얼로그 신규 — 카테고리별 Material Icons + chainGold 강조 + TemplateEngine 렌더 description. `reputation_rank` 카테고리는 RankUpDialog 본체 인라인("✨ 이 순간은 연대기에 새겨졌다")으로 대체하여 dialog 폭주 방지.
- 신규 `ChronicleScreen` 영구 기록 화면 — ChoiceChip 7종 카테고리 필터(다중 선택) + 50개 페이징 + 카드 탭으로 dialog 재노출. HomeScreen 야영지 아래 연대기 카드(최근 1행 + 24시간 NEW 배지) + InfoScreen "용병단 연대기" 진입점 두 경로로 접근. 상태 기반 렌더링(`_showChronicle` + `onBack`) 적용.
- `MercenarySnapshot` 5필드(id/name/jobId/jobName/tier) 발급 시점 영속 보존 — 용병 사망·방출 이후에도 위업 카드/연대기 화면에 주인공 정보 유지. 페이즈 4 #2(칭호)에서 `titleIds` 필드 추가 호환 예정.
- Hive 신규 박스 `bandAchievements`(typeId 16~19 4종 어댑터) + Supabase 30번째 테이블 `band_achievement_templates`(26행 시드, 7 카테고리 CHECK + chronicle_variants JSONB + default_priority CHECK) + `ActivityLogType.achievementUnlocked` HiveField 29 + `AppTheme.memorialGray` 추가.
- 멱등성 보장: `AchievementService.hasAchievement(templateId)` 사전 체크로 6 hook 모두 일회성. memorial은 `(mercSnapshot.id, cause)` 조합으로 중복 차단.

## 2026-05-05

### M5 페이즈 4 #2: CraftingService + 인벤토리 4탭(MaterialTab) + 낡은 대장간 정식 제작 화면

- **CraftingService 도메인 서비스 신설**: `evaluateState(recipe)` 4상태 평가(잠김/부족/충족) + `craft(recipeId)` 실행(재료 차감 → 결과물 추가 → ActivityLog `craftCompleted` 기록). 콜백 DI 패턴(ChainQuestService 정합). `RecipeUnlockCondition` 3종 분기 평가(trustLevel·chainStep·firstAcquiredItem) — firstAcquiredItem은 임시 InventoryRepository 보유량 평가, 페이즈 4 #3 영속화 위임.
- **InventoryRepository 확장**: `addItem` 분기를 `stackMaxByCategory[category] > 1` 일반화로 교체하여 material/consumable stack 누적 통합 + 999 클램프 + 신규 `consumeMaterial(itemId, qty)` 다중 행 fold + 신규 `getQuantityForItemId(itemId)` 합산 메서드.
- **인벤토리 4탭째 MaterialTab 신설**: `InventoryCategoryFilter.material` enum 추가로 5탭 확장. `MaterialTabContent`(slot 6칩 가로 sub-filter + 정렬 tier desc → 보유량 desc → id asc) + `MaterialItemCard`(좌측 tier 색 바 + 이름·slot 라벨·tier + 🔨 ×N 점프 배지 + 보유량 3자리 + region_exclusive settlementAccent 테두리 + "더스트빌" 라벨 + 펼침 출처 힌트) + `EmptyMaterialState`(빈 인벤토리에서 5종 slot 출처 가이드 토글).
- **낡은 대장간 정식 제작 화면**: M4 stub 3 tile(`_CraftGoalTile`/`_RepairMissionTile`/`_MaterialHintTile`) 폐기 → `_NpcHeader` 유지 + `_EmptySmithyMessage`(신뢰도 1단계 잠금) / `RecipeListSection` 4계층 정렬(ready < insufficient < locked → banner < weapon < armor < accessory < artifact → tier desc → id asc) + 그룹 헤더(banner "용병단 깃발 양자택일"·artifact "용병단 아티팩트 동시 장착") + 자동 필터 칩 + 2버튼([인벤토리에서 재료 보기]/[닫기]). 320줄 → 149줄.
- **RecipeCard 4상태 위젯**: locked(Opacity 0.5 + 🔒 + `???` + 해금 조건 텍스트) / insufficient(Opacity 0.6 + 입력 재료 X/Y `tier2` 초록 ✓ / `dangerRed` 빨강 ✗ + [제작] 비활성 + 카드 클릭 시 부족 재료 한국어 이름 + 출처 힌트 + [인벤토리에서 보기] 링크) / ready(또렷 + 좌상단 "제작 가능" 라벨 + 모두 ✓ + [제작] 활성). [제작] 클릭 → 50ms 비활성 → `craftingService.craft` → 성공 시 `'{결과물 이름} 제작 완료 ✨'` SnackBar 1.5초.
- **양방향 점프 인터랙션**: `recipeFilterMaterialIdProvider`(인벤토리→대장간 자동 필터 컨텍스트) + `materialJumpTargetItemIdProvider`(대장간→인벤토리 스크롤 타겟). 부족 재료 [인벤토리에서 보기] → `materialJumpTargetItemIdProvider.set` + `currentTabProvider = 5`(정보 탭) + 대장간 onClose → InfoScreen listen으로 `_showInventory = true` → InventoryScreen listen으로 `_categoryFilter = material` → MaterialTabContent listen으로 slot 자동 + scroll → state 즉시 리셋. 마을 진입 상태 자동 대장간 진입은 SnackBar 안내로 통일(InfoScreen 경유 구조 한계 — 향후 작업 위임).
- **AppTheme `dangerRed`(0xFFC62828) 1상수 추가** — RecipeCard insufficient 부족 재료 텍스트 전용. 페이즈 4 #1 인프라(`CraftingRecipeData`/`ActivityLogType.craftCompleted` HiveField 27/`GameConstants.stackMaxByCategory`/`StaticGameData.craftingRecipes`/`SyncService` 'crafting_recipes' 등록) 그대로 재사용 — 모델·typeId·SyncService 변경 0건.
- **명세 외 보완 1줄**: `info_screen.dart`에 `materialJumpTargetItemIdProvider` listen 추가 — non-null 감지 시 `_showInventory = true` 자동 전환(`factionCodexScrollTargetProvider` 패턴 차용).

### M5 페이즈 4 #3: 드랍 출처 hook 5종 + 거대 박쥐 step 3 강제 spawn + 신뢰도 단계 진입 보너스 + region_discoveries 발견 hook + firstAcquiredItem 영속 추적 (M5 마일스톤 종결)

- **5종 드랍 출처 hook 활성화**: `QuestListNotifier._applyCompletionResult`(quest_pool_material_drops 매핑) + `EliteLootService.rollDrops`(drop_type='material' fallthrough) + `InvestigationNotifier._completeInvestigation`(`_applyDiscoveryItems` 헬퍼 추출 — 5분기 faction_clue/elite/hidden_quest/transform/normal 모두 호출) + `MovementNotifier.applyTravelChoiceEffect`(material_drop case + region 3 한정 영속 추적) + `ChainQuestService.onStepCompleted`(`addRewardItems` 콜백 DI 추가). 5종 모두 동일 패턴(staticData null 가드 → 999 stack 사전 평가 → addItem → addAcquiredMaterial 멱등 호출).
- **거대 박쥐 step 3 강제 spawn**: `QuestGenerator.generateQuests` 시그니처에 `currentChainId/currentChainStep` 인자 2개 신규 + elite spawn 루프에 `quest.fixedChainId == 'settlement_3_pyegwang_reopen' && fixedStep == 3 && monster.id == 'elite_giant_bat'` 강제 spawn 분기 추가. `quest_provider.dart` 호출부 3곳(`generateQuests`/`fillQuests`/`_refreshExpiredQuests`) 모두 chain progress 조회 후 인자 전달. M6+ 다중 거점 시 데이터 모델 마이그레이션 위임 TODO 주석.
- **신뢰도 단계 진입 일회성 재료 보너스**: `RegionStateRepository.addSettlementTrust`에 region 3 한정 분기 추가. 2단계 진입 시 #6 빛바랜 천 조각 ×1 / 3단계 진입 시 #1 녹슨 쇳조각 ×3 자동 지급. 다중 단계 동시 도달(`oldLevel=1 → newLevel=3`) 시 `>=` 비교로 두 보너스 모두 지급. 4단계는 기존 골드/명성 보상만 유지(페이즈 2 #1 §1-6 정합).
- **firstAcquiredItem 영속 추적**: `RegionState` Hive 모델에 `firstAcquiredMaterialIds: List<String>` HiveField 7 신규 추가(typeId 8 유지, 기존 세이브 호환 default `[]`). `RegionStateRepository.addAcquiredMaterial(regionId, itemId)` 멱등 메서드 신규 — 5종 hook 모두에서 `inv.addItem` 직후 호출. `CraftingService.evaluateState` firstAcquiredItem 분기를 페이즈 4 #2 임시 평가(InventoryRepository 보유량) → RegionState 영속 평가로 교체. `recipe_dustvile_miner_charm` 첫 입수 후 모두 소비해도 해금 유지.
- **999 stack 도달 활동 로그**: `ActivityLogType.inventoryStackCapped` HiveField 28 신규 enum 값 추가(typeId 6 유지). 5종 hook 모두 addItem 호출 전 `getQuantityForItemId >= 999` 사전 평가 → `'{재료 이름} 보유량이 가득 찼습니다 (999 도달)'` 메시지로 로그 1행. `home_screen.dart` switch에 ⚠️ + settlementAccent 색상 표시 추가.
- **region_discoveries 발견 hook 통합 패턴**: `_applyDiscoveryItems(d, regionId, staticData)` private helper로 추출. `discoveryData['items']` JSONB 배열을 순회하며 `drop_rate` 확률 평가 + addItem + addAcquiredMaterial 일괄 처리. faction_clue/elite/hidden_quest/transform/normal 5분기 각각 helper 호출 + default 로그 1행만 normal에서 발생(중복 방지).
- **Supabase 데이터 INSERT 적용**: `quest_pool_material_drops` 16행(UNIQUE(pool_id, item_id) 제약으로 chore_03 #5 두 행 1.0 확정+0.2 보너스를 `qty_max=2` 단일 행으로 병합 — 평균 산출량 1.2→1.5개/회 미세 차이) + `travel_choice_events` 3행(마른 초원 야간 순찰/폐광길 짐 더미/먼지 길 여행자 조우 — 각 1 이벤트당 2 옵션 구조) + `travel_choice_options` 6행 + `travel_choice_results` 6행(effect_type='material_drop' + effect_target=item_id + effect_magnitude=qty) + `travel_choice_results.effect_type` CHECK 제약 DROP/ADD로 'material_drop' 추가. `data_versions` 4 테이블 갱신.
- **collection 패키지 직접 의존성 추가**: `package:collection/collection.dart`의 `firstWhereOrNull` 활용 — 4개 파일(movement_provider.dart / region_state_repository.dart / 등)에서 firstWhere orElse throw 패턴을 silent skip 패턴으로 교체. async 체인 무음 실패 위험 해소.
- **M5 마일스톤 종결**: 종료 조건 모두 충족 — 재료 인벤토리 별도 구분 / 제작 레시피 4상태 표시 / 5종 출처 모두 연결 / 첫 제작 목표 3개 달성 가능 / 완제품 vs 제작 공존 / 첫 제작 38분(이상) / 첫 희귀 광부 단검 60분 + 폐광 유물 조각 98분(페이즈 2 #1 시뮬레이션 정합).

### 신규 유저 파견·모집 하향 게이팅

- 명성 등급(F/E/D+)별 신규 유저 보호 게이트 도입.
  - F 등급(0~299): 모집 T1 100% / 파견 difficulty 1만
  - E 등급(300~1999): 모집 T1 90%·T2 10% / 파견 d1 + d2(weight 0.25), d3 차단
  - D 이상(2000+): 기존 분포 유지
- 시작 4인 파티 사망 기댓값 시간당 1.71명 → 0.24명(F) / 0.32명(E)으로 감소.
- 사건 step 6 완료(+500 명성)로 자연스러운 D 진입 곡선과 결합.
- 신규 유저 플로우에서 고정 사건 의뢰(폐광 입구 정찰 step 1)가 등장하지 않던 타이밍 버그 수정.

## 2026-05-04

### M4 페이즈 4 #4: 마을 방문 UI + 거점 3종 + 약초상/의무실 분리

- 더스트빌(region 3, sector_type='village') 진입 시 이동 화면 하단에 "마을 내 방문" 영역 신설. 광장 풍문 1줄 + 거점 3종(촌장 집·낡은 대장간·약초상) 카드 메뉴. 거점 진입은 `_selectedFacility` enum 상태 기반 렌더링(Navigator.push 미사용), region 변경 시 자동 리셋.
- **촌장 집**: NPC 헤더(파슨) + 24h 사건 완료 배너(조건부) + 신뢰도 4단계 진행 바 + [상황 듣기]/[신뢰도 확인]/[보상 받기] 3개 버튼. 보상 받기는 자동 지급 안내(페이즈 4 #5 흐름 그대로 유지)로 disabled.
- **낡은 대장간**: NPC 헤더(하겐) + [제작 목표 보기]/[수리 의뢰 확인]/[재료 힌트 보기] 3개 버튼. 단계별 잠금: 1단계 모두 disabled, 2단계 제작 목표·재료 힌트 활성, 3단계 수리 의뢰 활성(50G), 4단계 ×1.2(60G). 수리 의뢰는 `UserData.lastSmithyRepairAt` 24h 쿨다운 stub.
- **약초상 (1회성 즉시 회복)**: NPC 헤더(네리스) + [즉시 회복]/[채집 정보]/[재료 힌트] 3개 버튼. 비용 75/50/45/40G + 쿨다운 45/30/15/10m 곡선. 부상/피로 용병 1명을 즉시 정상 복귀시키며 의무실 자동 회복 타이머도 함께 종료. 의무실 효과는 변경 없음.
- 채집 의뢰(`dustvile_chore_03`) 골드 보상 단계별 ×1.0/×1.1/×1.2 배수 — `QuestCompletionService.calculate(currentTrustLevel)` 시그니처 추가, `quest_provider`가 `regionStateRepository.getSettlementTrust(quest.region).level` 주입.
- 사건 완료(`settlement_3_pyegwang_reopen` step==6) 시 `RegionState.lastEventCompletedAt` 기록 → 24h 동안 모든 거점 화면 상단에 사건 완료 메시지 노출 → 24h 경과 후 4단계 인사말로 복귀.
- 신규 feature 모듈 `features/settlement/` 신설 — `HerbalistService`(정적 서비스 3개 메서드)/`VillageFacility` enum/`SettlementNpcData`(NPC 5명 + 인사말 17개 + 광장 풍문 + 사건 완료 메시지 const 인라인)/거점 화면 4종 + 즉시 회복 다이얼로그.
- `MercenaryRepository.healInstant(mercId)` + `MercenaryListNotifier.healInstant({mercId, cost, cooldownMinutes})` wrapper 추가 — Repository는 단일 책임(상태 normal + 두 endTime null + Hive save), Notifier가 spendGold/setHerbalistCooldown/ActivityLog 일괄 처리.
- `RegionStateRepository.setEventCompleted(regionId)` + `UserDataNotifier.setHerbalistCooldown`/`setSmithyRepairAt` setter 메서드 추가.
- HiveField 추가: `UserData` 22 `herbalistCooldownEndTime`·23 `lastSmithyRepairAt` / `RegionState` 6 `lastEventCompletedAt` + `eventCompletedRecently` getter / `ActivityLogType` 25 `herbalistHeal`·26 `smithyRepairCompleted` (홈 화면 `_logIcon` 매핑 추가).
- 단위 테스트 13건 신규 — `HerbalistService` 비용/쿨다운/배수 10케이스 + `MercenaryRepository.healInstant` Hive 인메모리 흐름 3케이스.

### M5 페이즈 4 #1: 데이터 모델 확장 + 시드 마이그레이션 (재료/제작 인프라)

- **신규 Supabase 테이블 2종**: `crafting_recipes`(제작 레시피 — id/result_item_id/result_quantity/inputs_json/unlock_condition_json/craft_location_id 9컬럼·10행 INSERT) + `quest_pool_material_drops`(의뢰 풀 재료 드랍 매핑 — pool_id/item_id/drop_rate/qty_min/qty_max·스키마만, INSERT는 페이즈 4 #3 위임). 인덱스 4종 + UNIQUE(pool_id, item_id) + drop_rate CHECK 제약.
- **items 테이블 확장**: `region_exclusive INTEGER NULL REFERENCES regions(id)` 컬럼 추가. category CHECK 4종(`material` 추가) + slot CHECK 16종(신규 `material_ore`/`material_hide`/`material_herb`/`material_relic_fragment`/`material_monster_part` 5종 추가) DROP/ADD 갱신. 인덱스 2종 추가.
- **items 신규 INSERT 20행**: 재료 10종(녹슨 쇳조각·마른 가죽끈·마른 약초·산기슭 버섯·접착 수액·빛바랜 천 조각·녹슨 곡괭이 머리·폐광의 유물 파편·거대 박쥐 송곳니·고대 인장 조각) + 중간재 2종(거친 가죽끈 묶음·연마된 쇳조각) + 결과물 8종(낡은 용병단 깃발·광부의 단검·폐광의 유물 조각·단단한 갑옷 조각·녹슨 곡괭이·약초사 인장·약초 향낭·광부의 부적). region_exclusive로 region 3 한정 6종 마킹.
- **엘리트 신규 1종**: `elite_giant_bat`(거대 박쥐·tier 2·power 80·spawn_rate 0.15·beast·환경 태그 mountain/dungeon — fixed_region_environments 환경 태그 형식 적용) + 시그니처 트로피 1행(`elite_giant_bat_fang_drop` drop_type='material'·drop_rate 1.0·rarity 'rare').
- **region_discoveries 신규 3행**: region 3 폐광 발견 (knowledge 25/50/80 — `disc_dustvile_pyegwang_normal`/`hidden`/`deepest`). discovery_type CHECK에 'normal' 추가하여 6종(info/elite/hidden_quest/faction_clue/transform/normal) 갱신.
- **chain_quests UPDATE 6행**: `settlement_3_pyegwang_reopen` step 1·2·4·5·6 reward_items에 mat_xxx 보상 부여. step 3은 elite_loot_tables(거대 박쥐)·quest_pool drop hook으로 처리하므로 빈 맵 유지.
- **신규 Freezed 모델 2종**: `CraftingRecipeData`(+ `RecipeInput`/`RecipeUnlockCondition`/`ChainStepCondition` 4 클래스 단일 파일·JSONB inputs_json/unlock_condition_json 매핑·trustLevel/chainStep/firstAcquiredItem 3 옵션 nullable 단순 매핑) + `QuestPoolMaterialDropData`. `ItemData.regionExclusive: int?` 필드 1개 추가.
- **`ActivityLogType.craftCompleted` HiveField 27 추가** (typeId 6 유지·실제 사용은 페이즈 4 #2 `CraftingService.craft()` 위임). `GameConstants.stackMaxByCategory` Map 상수(개인/길드 1, 소모품/재료 999) 사전 등록.
- **`StaticGameData` 확장**: craftingRecipes/questPoolMaterialDrops 2 필드 추가 + `SyncService.allTables`에 신규 2 테이블 등록 + `data_versions` INSERT 2행. `DataLoader` 분기 추가 0건(제네릭 진입점 활용).
- **`mcp__plugin_supabase_supabase__apply_migration`로 단일 트랜잭션 적용**. 적용 중 명세서 가정 위반 2건(`items_slot_check`/`region_discoveries_discovery_type_check` CHECK 제약 존재) 발견 → 사용자 승인 후 DROP/ADD로 처리.

## 2026-05-03

### M4 페이즈 4 #3: 고정 의뢰 시스템 + 더스트빌 허드렛일 풀 (페이즈 4 #5 stub 상태)

- `quest_pools` 테이블에 9개 컬럼 추가 — `is_fixed`/`fixed_chain_id`/`fixed_step`/`trust_threshold` (페이즈 1 #4) + `reward_gold_override`/`reward_xp_bonus_override`/`duration_override_seconds`/`trust_reward_override` (페이즈 2 #4 보상·시간 override) + `min_trust_level` (페이즈 2 #3 단계별 노출 제어). Partial UNIQUE 인덱스 `(fixed_chain_id, fixed_step) WHERE is_fixed = true`.
- "폐광길 재개방" 6단계 거점 사건 라인 데이터 추가 (`settlement_3_pyegwang_reopen`). explore → hunt → raid → escort → raid → survey 순, `trust_threshold` 1·1·2·2·3·3, `duration_override_seconds` 300·300·360·300·600·600, `trust_reward_override` 10·15·20·25·30·100, `reward_gold_override` step3 이후 200·185·270·500G, step6 `reward_xp_bonus_override` +50.
- 더스트빌 허드렛일 10건 (`dustvile_chore_NN`) 추가 — labor 6 + escort 1 + explore 2 + hunt 1, 모두 난이도 1, `min_region_diff=1`/`max_region_diff=1` (T1 한정). `dustvile_chore_03` 약초 채집 의뢰만 `min_trust_level=2`.
- `QuestPool` Freezed 모델 9개 필드 확장 + build_runner 재생성.
- `QuestGenerator.generateQuests`에 `currentTrustLevel` 파라미터 + `!isFixed` / `minTrustLevel <= currentTrustLevel` 필터 2개 추가.
- `QuestListNotifier`에 `_getCurrentTrustLevel` stub (페이즈 4 #5 연결용 0 fallback) + `_injectFixedSettlementQuest` (settlement_3_pyegwang_reopen 진행 조회 후 ActiveQuest 생성) + `refreshAvailableQuests` 공개 메서드 추가. `_checkQuestRefresh` / `_refreshExpiredQuests`에 `settlement_` prefix 만료 제외 분기.
- `ActiveQuest.isSettlementStep` getter 추가 (chainId? startsWith settlement_).
- `QuestSortService.QuestSortResult`에 `settlementTier` 신규 필드 + `chainTier0` 분류에서 settlement_ prefix 분리 + `sortedRest`는 `[...settlementTier, ...tier1~4]` 순서로 일반 목록 최상단 배치.
- `AppTheme.settlementAccent`(0xFFFFA000) 신규 색상 상수 — 변형 섹터 `transformVillage` 0xFF2E7D32 와 의미 충돌 회피.
- 파견 화면 `_QuestCard`에 "📜 마을 사건" 인라인 배지 추가 (`AppTheme.settlementAccent` 알파 0.15 배경 + 1px 테두리).
- Supabase 마이그레이션 SQL은 페이즈 4 #1·#2와 동일하게 보류 (옵션 B 연장, 페이즈 4 #4·#5 완료 후 일괄 적용). `_getCurrentTrustLevel() = 0` stub이라 `trust_threshold ≥ 1` 조건 실패 → 고정 의뢰 미노출 안전 fallback. 페이즈 4 #5에서 `RegionStateRepository.getSettlementTrust(regionId).level` 한 줄 교체로 활성화.

### M4 데이터 마이그레이션 + 시작 거점 고정

- 199개 리전을 40개로 축소(보존 39 + T9 신규 region 200). 삭제 160개 리전과 종속 region_discoveries 15행은 dump JSON으로 rollback 가능 보관.
- 시작 거점을 더스트플레인(region 3) sector 1로 고정. 기존 random Tier 1 부여 로직 제거.
- 시작 골드 500G → 200G 하향. baseQuestCount 5 → 6 상향(시작 의뢰 슬롯 6개 정책 정합).
- 살아남지 못한 리전을 참조하는 기존 세이브는 자동 복구 — `regionStates` 박스 정리, `UserData.region`을 region 3으로 강제 이동, `factionStates.clueRecords`에서 무효 단서 삭제.
- `GameConstants.sectorCount`를 `@Deprecated` 마킹(M4 페이즈 4 #2에서 region_sectors.sector_count 동적 조회로 대체 예정).

### M4 region_sectors 신규 테이블 + 섹터 데이터 기반 렌더링

- regions.sector_count 컬럼 신설(1~6 가변, 기본 4). 4개 거점급 region(1·23·127·146)은 5섹터로 승격. 기존 하드코딩된 10섹터 그리드 제거 + region별 동적 렌더링.
- region_sectors 정규화 테이블 신설(sector_index 1-based, sector_type 5종 — village/ruins/hidden/dungeon/field). 데이터 시드는 후속 페이즈 위임.
- 더스트플레인(시작 거점) 4섹터를 코드 fallback 상수로 인라인 — 더스트빌(village)·폐광(dungeon)·마른 초원(field)·먼지로 덮인 길(field). 시드 미배포 상태에서도 시작 거점 진입 보장.
- MovementScreen 그리드에 dungeon ⛏️ / field 🌾 신규 시각 마커 추가(LayerSidebar·QuestCardBadges는 기존 변형 3종 정책 보존).
- region_discoveries 3행 sector_index 재매핑 SQL — region 18·23·146의 transform hidden 데이터 정합성 확보.
- GameConstants.sectorCount stub 상수 완전 제거 — region.sectorCount 동적 조회로 일괄 마이그레이션.
- 기존 세이브 자동 복구 — RegionMigrationService에 sectorCount 초과 sectorChanges 키 정리 단계 추가(별도 멱등성 플래그 `region_sector_count_v1`로 1회 실행).

### M4 페이즈 4 #5: 마을 신뢰도 시스템 + 거점 사건 활성화 + 페이즈 4 #3 stub 해제

- 더스트빌(region 3) 마을 신뢰도 시스템 도입 — 의뢰 완료로 신뢰도가 누적되며 4단계(의심/인지/친근/소속)로 승급. 임계값 30/80/200점, 단계 진입 시 일회성 보상(2단계 +100G+50XP / 3단계 +200G+100XP / 4단계 +500G+200XP+100명성). XP는 살아있는 용병에 균등 분배.
- 일반 의뢰 신뢰도 점수 — region 3 + 일반 의뢰(체인/세력 태그 제외) + 성공/대성공 시 난이도별 2/3/5/0/0점 누적.
- 거점 사건 라인 "폐광길 재개방" 6단계 활성화 (`settlement_3_pyegwang_reopen`) — `trust_threshold` 단계별 노출, `duration_override_seconds`(300~600s)/`reward_gold_override`/`trust_reward_override`(10~100점)로 일반 의뢰 보상 곡선과 분리.
- 단계 승급 시 단계별 색상 + 일회성 보상 요약 다이얼로그(`SettlementTrustUpDialog`) 표시. 4단계 진입 시 명성 +100으로 인한 랭크업 발생 시 critical(rankUp) → high(trustUp) → high(chainCompleted) 순으로 dialog 큐 직렬화.
- `RegionState` HiveField 4·5 (`settlementTrust`/`settlementTrustLevel`) 추가 + null fallback getter — 기존 세이브 호환 보장.
- `RegionStateRepository`에 `addSettlementTrust`/`getSettlementTrust`/`setSettlementTrust` 3개 메서드 + 임계값/보상/단계명 상수 맵.
- `TrustLevelUpEvent` + `settlementTrustLevelUpProvider` StateProvider + `settlementTrustProvider` Provider.family 신규.
- `ChainQuestService.tryActivateSettlement` 메서드 추가 + `checkDormant` settlement_ prefix skip(14일 미적용) + `onStepCompleted` protagonist resolution skip.
- `QuestCalculator`(`rewardGoldOverride`/`durationOverrideSeconds`/`isFixedWithDurationOverride`) + `ExperienceService`(`rewardXpBonusOverride`) 시그니처 확장 — `is_fixed=true` 행은 baseReward·rewardMultiplier·trackBonus 등 기존 보상 경로 우회.
- `QuestCompletionService.calculate`에 pool 조회 + override 인자 전달 + `QuestCompletionResult.settlementTrustGain` 필드 추가.
- `QuestListNotifier`: `_getCurrentTrustLevel` stub 해제(`getSettlementTrust(region).level`로 교체) + `dispatch` override 적용 + `_injectFixedSettlementQuest` 중복 방어(`_load()` 선행) + `_refreshExpiredQuests` 가독성 개선(이중 필터 제거) + `_applyCompletionResult`에 settlement_ step 신뢰도 누적 + 일반 의뢰 신뢰도 점수 분기 추가.
- `ActivityLogType` HiveField 22~24 (`settlementTrustUp`/`settlementEventStep`/`settlementEventCompleted`) + 홈 화면 `_logIcon` 매핑 추가.
- `DialogTypeRegistry.settlementTrustUp` 키 추가(8종) + `app.dart`에 listen 블록 + dialogQueue high priority enqueue.
- `ChainTopSection` `actives` 필터에 `!chainId.startsWith('settlement_')` 추가 — 거점 사건은 일반 목록의 settlementTier로만 노출(페이즈 4 #3 후속 권고 #1).
- 게임 시작(`UserDataNotifier.initializeNewGame`) + region 3 진입(`MovementNotifier._completeMovement`) 시 자동 RegionState 초기화 + `tryActivateSettlement` 호출. 기존 세이브에서 `settlementTrust=null`인 경우 기존 객체 직접 수정 패턴(`saveState` 우회)으로 마이그레이션.

## 2026-04-26

### M3 공존 정책 — 파견 화면 정렬 + 도착 팝업 큐 통합

- 전역 다이얼로그 큐 도입 (`DialogQueueNotifier`): priority(critical/high/medium/low) + FIFO + id dedup. Hive `dialogQueue` 박스로 24h 영속화, 만료/실패 시 ActivityLog "알림 일부 유실됨" 기록
- 5개 독립 팝업 채널(건설·조사·랭크업·체인 완주·지역 변형) + 이동 도착 팝업 2종(자동 이벤트·선택지 회상) 모두 단일 큐로 통합. critical은 `barrierDismissible: false`
- 파견 화면 5계층 정렬 (`QuestSortService.sort`): Tier 0 체인 → Tier 1 세력 전용 → Tier 2 엘리트(유니크 우선) → Tier 3 변형 섹터 → Tier 4 일반. 같은 tier는 추정 보상↓ → 난이도↑ → id 사전순
- 체인 다음 단계 카드를 `ChainTopSection`(최대 3장, 활성/비활성 분기, 비활성은 "이동 화면으로" 버튼)으로 분리. 인라인 `ChainStepCard` 호출 제거
- `LayerSidebar`(8단계 우선순위 fold) + `QuestCardBadges`(체인/엘리트/섹터/세력 4종 배지) 공유 위젯 도입. 퀘스트 카드 시각 통합
- 이동 화면 체인 하이라이트: 체인 대상 리전 모든 섹터에 금색 2px 테두리 + "체인" 마이크로 배지
- ActivityLog 4종 신규 아이콘 매핑: 🗺️ regionTransform / ⛓️ chainProgressed / ⛓️(굵음) chainCompleted / 🛤️ travelChoiceCompleted
- AppTheme `chainGold`(`#D4AF37`) 신규, `transformVillage/Ruins/Hidden` + `eliteAccent/UniqueAccent` 명세 색상으로 갱신
- 신규 Hive 박스 `dialogQueue`(typeId 15) — 빌드 후 첫 실행 시 자동 생성

### M3 공존 정책 후속 정리 — 트레잇 진화 domain 이전 / 정렬 메모이제이션 / 다이얼로그 dismiss 일관성

- 트레잇 진화 적용 로직(Repository 호출/트레잇 이름 lookup/ActivityLog 기록/refresh)을 view에서 `MercenaryListNotifier.applyEvolution()`으로 이전. dispatch_screen은 위젯 위임 한 줄로 단순화
- `EvolutionChoice` 데이터 클래스를 view → domain 레이어로 이동 (`features/mercenary/domain/evolution_choice.dart`)
- 파견 화면 정렬을 `sortedPendingQuestsProvider`(derived Provider)로 메모이제이션. 1초 주기 `gameTickProvider`로 매 tick 정렬 재계산되던 비용 제거. 세력 가입/탈퇴(`factionRefreshProvider`) + 지역 변형(`currentRegionSectorChangesProvider`) 시 자동 무효화
- 다이얼로그 큐 5개 채널(건설·조사·랭크업·체인 완주·지역 변형) dismiss 책임 일원화: `enqueue` 직후 즉시 `state = null` 호출, builder/onDismiss 콜백은 `dismiss` 단순 참조만 수행
- `InvestigationResultDialog`의 누락된 state 리셋 보완 (재발화 위험 제거)
- 동작 변경 없음 (사용자 시각 동일성 보장 — 정렬 결과·진화 메시지·다이얼로그 표시 시퀀스 모두 동일)

### 퀘스트 서사 통합 (M3 페이즈 4-4)

- 퀘스트 완료 시 `quest_narratives` 88행에서 서사 템플릿을 weight 기반 가중 랜덤 선택 후 TemplateEngine으로 렌더링
- 렌더된 서사를 `ActiveQuest.renderedNarrative`에 저장, `QuestResultDialog` 완료 팝업에 이탤릭 텍스트로 표시
- 활동 로그 메시지에 서사 포함 (`'퀘스트 "이름" 결과! — 서사'` 포맷)
- `{quest.enemy}` 변수 지원 — 일반 퀘스트: `quest_pools.enemy_name` 필드, 엘리트: 몬스터 이름, null 시 `"적"` fallback
- 엘리트 퀘스트 전용 서사 8행 분리 적용 (`is_elite` 매트릭스)
- `AppTheme.elite*` 색상 상수 6개 추가 — `dispatch_screen`, `dispatch_detail_page`, `quest_result_dialog` 색상 리터럴 통일
- `QuestResultDialog` `_build*` 헬퍼 메서드 → `_EliteLootSection`, `_MercStatusRow`, `_RewardRow` StatelessWidget 추출

### 이동 선택지 시스템 (M3 페이즈 4-5)

- 이동 완료 시 확률 기반으로 선택지 이벤트 발생 — `P = min(base + coeff × distance, 0.30)`, 리전 티어별 coeff 조정
- `TravelChoiceRecallDialog` 2단계 팝업: 상황 서사 + 선택지 → 결과 서사 + 효과 요약
- 선택지 3종 risk_level (safe/risky/hidden) + `visibility_expr` TemplateEngine 평가로 숨겨진 선택지 조건부 노출
- 결과 8종 효과: gold_gain/gold_loss/xp_gain/reputation_gain/reputation_loss/trait_learning_boost/item_drop/trait_innate
- `UserData.choiceEventId` HiveField(21) — 앱 재시작 시에도 미표시 선택지 이벤트 보존
- `travel_choice_events` / `travel_choice_options` / `travel_choice_results` 정적 테이블 3개 Supabase 동기화 추가
- `TravelChoiceService` 순수 서비스 (5개 static 메서드) + 단위 테스트 19개

### M3 체인 퀘스트 섹터 단위 하이라이트 — chain_quests.target_sector_id 추가

- Supabase `chain_quests` 테이블에 `target_sector_id INTEGER NULL` 컬럼 추가 (1-based 1..10). `data_versions.chain_quests` version 1→2 갱신
- `ChainQuestData` freezed 모델에 `targetSectorId` 필드 추가, build_runner 재생성
- MovementScreen이 `chainTargetRegionIds`(Set) → `chainTargetSectors`(`Map<int, Set<int?>>`)로 자료구조 확장. `null in set` 시 region 전체 fallback, `sector in set` 시 해당 섹터 타일만 금색 테두리/배지 표시
- 기존 24개 chain_quest 단계는 모두 `targetSectorId == null` 상태이므로 region 단위 하이라이트로 동작 동일 (시각적 변경 없음)
- CSV(`Docs/content-data/[chain-quest]20260424_m3-chains.csv`) 헤더에 `target_sector_id` 컬럼 추가, 24행은 빈 값 유지 (콘텐츠 입력은 후속 sprint)

---

## 2026-04-25

### 연계 퀘스트 시스템 (M3)

- 지역 조사 완료 시 숨겨진 퀘스트 발견으로 체인 퀘스트 활성화 (7체인 24단계)
- 파견 화면 최상단에 현재 연계 단계 카드 고정 표시 (이동/대기/휴면 상태 오버레이)
- 주인공 용병 선정 및 체인 내 추적 — 주인공 사망률 50% 감소
- 단계 완료 시 다음 단계 지연 후 활성화, 14일 비활동 시 휴면 전환
- 체인 완주 시 명성 보너스 지급 + 완주 팝업 (서사 텍스트 템플릿 치환)
- 템플릿 엔진 구현: 변수 치환/조건 분기/랜덤 변주를 이동 이벤트·퀘스트 서사에 적용

### 지역 변형 시스템 (M3)

- 지역 조사 완료 시 섹터가 village/ruins/hidden 3종 중 하나로 영구 변형 — 변형 팝업(TemplateEngine 렌더)
- 변형 섹터에서 전용 퀘스트 34개 생성 (`quest_pools.sector_type` 필터 기반)
- 특수 플래그 6종: 트레잇 학습 부스트 / 길드 장비 드랍(희귀·초희귀) / 정수 드랍 / 장비 드랍 / 평판 패널티
- 이동 화면에서 변형 섹터 시각 구분 (아이콘 🏘️/🏛️/✨ + 색상 테두리)

---

## 2026-04-23

### 코드 품질 전수 점검 (flutter-reviewer)

HIGH 6 / MEDIUM 6 / LOW 2 이슈 수정. 테스트 372개 전부 통과.

- **Riverpod 반응성 버그 수정**
  - `DispatchScreen`의 `ref.listen<List<ActiveQuest>>`가 3개 early return 이후에 배치되어 `userData == null` 또는 이동 중에 퀘스트 완료 이벤트가 유실되던 문제 수정 — `build()` 최상단으로 이동
  - `RecruitScreen`/`FacilityTabScreen`이 세력 가입/탈퇴 후 모집·건설 비용 배수를 갱신하지 못하던 문제 수정 — `ref.watch(factionRefreshProvider)` 구독 추가
  - `HomeScreen`의 여행 이벤트 다이얼로그 표시 로직을 `build()` 내부 `_wasMoving && !isMovingNow` 패턴 → `ref.listen<MovementState?>`로 전환
- **레이어 경계 정리**
  - `view/` → `data/` 직접 import 6곳 제거. `factionStateRepositoryProvider`/`regionStateRepositoryProvider`를 domain 레이어(`faction_codex_providers.dart`/`investigation_notifier.dart`)에서 `export ... show`로 재노출
  - `PassiveBonusFormatter` 중복 파일(`core/domain` + `features/info/domain`) 통합 — `core/domain` 버전에 `describe`/`describeEffect` 메서드 추가하여 API 일원화, `features/info/domain/passive_bonus_formatter.dart` 삭제
- **위젯 재빌드 최적화**
  - `DispatchScreen._buildQuestCard` → `class _QuestCard extends ConsumerWidget` (리스트 순회 element 재사용)
  - `HomeScreen._buildActivityLog` → `class _ActivityLog extends ConsumerWidget` (로그 추가 시 전체 홈 화면 재빌드 → 해당 서브트리만)
  - `MercenaryDetailOverlay._buildStatChip`/`_buildXpBar`/`_buildSynergySection` → `const` 위젯 클래스 (element 재사용)
- **UI/UX 개선**
  - `DispatchDetailPage` 뒤로가기: `GestureDetector`+`Padding`+`Icon` → `IconButton` (터치 타겟 48×48 확보)
  - `QuestResultDialog` 정적 데이터 로드 실패 시 `barrierDismissible: false` 상태에서 닫을 수 없던 문제 수정 — error 브랜치에 닫기 버튼 추가
- **정리 및 방어 코드**
  - `main.dart`에 `FlutterError.onError` + `PlatformDispatcher.instance.onError` 전역 에러 핸들러 설치 (Crashlytics/Sentry 연동 플레이스홀더)
  - `MercenaryDetailOverlay` 티어 색상 리터럴 4개 → `AppTheme.tierN` 상수
  - `_parseFactionColor` 중복(`dispatch_screen`/`dispatch_detail_page`) → `FactionData.parseColor` static 메서드로 통합
  - `essence_service.dart` `debugPrint` 5건 제거
  - `dispatch_screen.dart`의 `ref.read(speedMultiplierProvider)` → `ref.watch` 의미론 교정

### M2b: 엘리트 몬스터 시스템

- 리전 `environment_tags` JSONB 컬럼 추가 — 지형/환경 태그로 퀘스트 풀 필터링 지원
- `EliteMonsterData` / `EliteLootTableData` 정적 데이터 모델 추가 (Supabase 동기화 대상 2개 테이블 신규)
- `EliteSpawnService`: 퀘스트 생성 시 리전 티어·환경 태그·난이도 조건으로 엘리트 몬스터 확률 배정
- `EliteLootService`: 드랍 테이블 가중 확률 롤 → 보너스 골드 + 아이템 드랍 계산
- `QuestGenerator` / `QuestCompletionService` 연동 — 엘리트 스폰·완료 처리 통합
- 파견 카드 엘리트 UI: 좌측 색상 사이드바·배지·이름 강조 (보통 🔥 오렌지 / 유니크 ★ 퍼플 2계층)
- 파견 상세 페이지: 엘리트 서사 카드(이름·설명/로어, 그라디언트 배경) 조건부 삽입
- 퀘스트 완료 팝업: 엘리트 드랍 섹션(보너스 골드·아이템 목록) 조건부 표시

---

## 2026-04-18

### 세력 태그 + 전용 퀘스트 시스템

- 가입 세력 단서를 보유한 리전에서 일반 퀘스트에 세력 태그가 자동 부여되어 완료 시 세력 평판을 획득한다 (가입 세력 100%, 비가입 거점 근접도 기반 5~30%).
- `quest_pools`에 세력 전용 퀘스트 98행(14세력 × 기본 3 + 고급 4) 추가. 가입 세력 + 평판(기본 11 / 고급 61) 조건 충족 시 파견 목록에 노출되며 완료 시 평판 5~10을 지급한다.
- 전용 퀘스트는 세력당 `min(가입수×2, 슬롯수×0.5)` 상한으로 노출되고 완료 후 6시간 쿨다운이 적용된다.
- 보상 공식이 패시브/랭크 보너스 + 트랙 보너스(기본 +0.30 / 고급 +0.40)의 가산 상한 +0.80으로 일원화되어 중복 가산이 제거되었다.
- 파견 화면 퀘스트 카드에 세력명 배지와 전용 퀘스트 강조 표시(좌측 세로 막대 + 테두리)가 추가되었고, 파견 상세 페이지는 세력명과 트랙 구분을 상단에 노출한다.

### 파견 상성 시스템 + 성공률 분해 UI

- 6개 role(전사/순찰자/마법사/도적/지원/전문가) × 4개 퀘스트 유형(약탈/토벌/호위/탐험) 상성 매트릭스가 도입되어, 파티 평균 보정값(-10 ~ +10%p 독립 상한)이 성공률에 가산된다. 85개 직업이 role로 전수 분류됐고, 트레잇 시너지도 독립 상한 ±10%p로 묶여 엔드게임에서도 전술 선택의 가치가 유지된다.
- 파견 화면에 추천 role 배지 2개(퀘스트 카드), +5 이상 상성 용병 하이라이트(카드 배경 tint + 보정값 배지), 성공률 옆 `?` 아이콘 → 분해 시트(기본값/파티력/유형/상성/트레잇/세력 패시브/거리 패널티 레이어별 표시)가 추가되었다.
- 용병 상세 오버레이 하단에 "퀘스트 유형별 상성" 섹션이 추가되어 각 용병의 role 보정값과 트레잇 시너지를 한눈에 확인할 수 있다.

### 명성 랭크 보너스 + 랭크업 연출 + 명성 정보 화면

- 명성이 증가하여 등급(F→E→D→C→B→A)이 상승하면 전체화면 축하 오버레이가 표시되고, 신규 등급의 보너스 목록이 한국어로 함께 안내된다. 활동 로그에도 `명성 상승: E → D` 기록이 추가된다 (🎖 아이콘).
- 홈 화면의 등급 카드를 탭하면 **보너스 요약 시트**가 열려 현재 활성화된 누적 보너스(세력 패시브 + 랭크 보너스 모두)와 다음 등급까지의 진행도를 확인할 수 있다. 최고 등급(A) 도달 시 "최고 등급 도달" 메시지로 전환된다.
- 정보 탭에 **"명성"** 진입점이 추가되어 F~A 전체 타임라인(도달/미도달 배지)과 등급별 보너스 프리뷰를 볼 수 있다. 타임라인에서 등급을 탭하면 해당 등급의 보너스 상세가 하단에 표시된다.
- 내부적으로 `ReputationService.getRankChain`/`getRankLevel`, `PassiveBonusContext` 공통 수집 헬퍼, `PassiveBonusFormatter`(17개 효과 타입 → 한국어 변환)가 추가되었다. 명성 하향 로직은 M2a 대비 stub으로 준비되었다.

---

## 2026-04-15

### 세력 발견 시스템 (World Expansion Phase 6)

- 지역 조사 완료 시 세력 단서(`faction_clue`) 발견 흐름 추가 — clue_level 1~3 단계별 정보 공개
- 하단 탭 6번째를 설정에서 정보 탭으로 교체, 설정은 홈 화면 상단 아이콘 버튼으로 이전
- 세력 도감 화면 신설 — 발견된 세력 목록(별 진행도), 세력 상세(description/philosophy/tierRange 단계별 공개)
- 조사 완료 팝업에 단서 인라인 표시 및 "도감에서 확인" 버튼 추가 (자동 스크롤 연동)
- `factionStates` Hive 박스 신설 (FactionState typeId:9, FactionClueRecord typeId:10)
- Supabase `factions` 테이블 동기화 대상 추가 (18번째 테이블)

### 세계 확장 Phase 1 — 지역 조사 시스템

- 용병 1명을 현재 리전에 파견과 독립된 "지역 조사" 슬롯에 배치하여 지식 포인트(0~100) 누적
- 지식 임계값 도달 시 `region_discoveries` 테이블 기반 발견 자동 트리거 (정보/엘리트/숨겨진 퀘스트)
- 조사 진행 중 이동 불가, 이동 중 조사 불가 (양방향 상호 배제)
- 조사 중인 용병은 퀘스트 파견 목록에서 자동 제외
- 시간 가속 설정 변경 시 조사 타이머도 비례 재계산
- Supabase `region_discoveries` 테이블 추가 (RLS anon read 정책 포함)

### 시설 ↔ 트레잇 연계 (Phase B)

- 시설 혜택 행동 지표 3종 추가 (training_benefit_count, infirmary_recovery_count, field_hospital_benefit_count)
- 퀘스트 완료 시 훈련소/의무실/야전병원 사용 여부에 따라 용병별 지표 자동 누적
- 시설 조건 기반 검증용 트레잇 3개 추가 (단련된 전사, 생존 본능, 철벽 수호)

---

## 2026-04-14

### 시설 시스템 고도화

- 시설 12종으로 확장 (기존 4종 + 신규 8종: 대장간/주점/연구소/방어시설/금고/게시판/이동수단/야전병원)
- 최대 레벨 25, OGame 스타일 건설 시간 + 기하급수 골드 비용 도입
- 건설 큐 1개 제한 (한 번에 하나만 건설, 취소 시 전액 환불)
- 하단 네비게이션 6탭 확장 (시설 전용 탭 추가)
- 시설 화면 전면 재설계 (건설 큐 상태 바, 시설 카드, 이정표 타임라인)
- 홈 화면 건설 미니 위젯 추가
- 로그 스케일 효과 공식 + 기능 해금 이정표 stub UI
- 시설 효과 적용: 주점(모집 확률), 방어시설(피해 감소), 금고(방치 보상 상한), 이동수단(이동 시간 단축), 야전병원(부상 확률 감소)

### 스탯 체계 재설계 — STR/INT/VIT/AGI 4스탯 전환

- 용병 스탯을 ATK/DEF/HP/speed에서 STR/INTELLIGENCE/VIT/AGI로 전환
- partyPower 계산을 퀘스트 유형별 가중치 공식으로 변경 (raid/hunt/escort/explore 각 가중치 차별화)
- AGI가 파견 소요 시간에 반영됨 (파티 평균 AGI 기반 속도 보정, 기준값 50)
- 기존 DEF·HP 유령 스탯 문제 해결 — VIT/INT로 퀘스트 전략 다양화
- Supabase jobs 테이블 컬럼 변환 및 85개 직업 INT 수치 직업 아키타입 기반 재설계
- operation-bom 웹앱 jobs 테이블 UI/타입 정의 갱신

---

## 2026-04-13

### Phase 6: operation-bom 트레잇 웹앱 확장

- operation-bom에 트레잇 시스템 6개 테이블 CRUD 관리 기능 추가 (trait_categories, traits, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies)
- FieldType에 "json" 타입 추가 — JSONB 컬럼의 입력(Textarea + JSON 검증), 목록 축약 표시 지원
- 복합 PK 테이블(trait_conflicts) 지원 — 추가/삭제만 허용, 편집 링크 숨김
- 사이드바에 "트레잇" 카테고리 신설 (6개 테이블 + 시각화 페이지)
- 트레잇 관계 시각화 페이지 (/traits/visualization) — 충돌/단일 진화/조합 진화/시너지 4개 섹션, 카테고리 필터

### Phase A: 트레잇 라이프사이클 완성

- 후천 트레잇 삭제 시스템 추가 (acquired 200G / evolved 500G, 의무실 레벨 해금)
- 용병 상세 오버레이에서 TraitDetailDialog 연결 (트레잇 탭 → 상세 다이얼로그)
- 트레잇 히스토리에 삭제 구분 표시 (`(삭제)` 라벨)
- 여행 이벤트로 빈 선천 슬롯에 트레잇 부여 (3종 신규 이벤트: 혹독한 지형/노련한 여행자/재능의 발현)
- TravelEvent 모델에 targetCategory 필드 추가
- trait_innate 이벤트 재롤링 로직 (최대 3회)

---

## 2026-04-12

### Refactors (코드 리뷰 Phase 1~3)

**Phase 1 — 안정성 확보**
- 퀘스트/이동 틱 레이스 컨디션 수정 (중복 처리 방지 가드 추가)
- `_completeQuest()` 185줄 God 메서드를 `QuestCompletionService`로 분리 (순수 계산 + 부수효과 분리)
- `ExperienceService.resultMultiplier` String → `QuestResult` enum 타입으로 변경
- `QuestCalculator.calculateSuccessRate` enemyPower <= 0 방어 코드 추가
- `mocktail` dev dependency 추가, `QuestCompletionService` 테스트 9개 신규

**Phase 2 — 아키텍처 정리**
- `UserData` 모델을 `features/movement/domain/` → `core/models/`로 이동
- `ActivityLog`, `ExperienceService`, `ReputationService`를 `core/domain/`으로 승격 (feature 간 그물망 의존성 해소)
- `QuestResultType` 삭제, `QuestResult`로 enum 통일 (이중 정의 + 수동 매핑 제거)
- `SettingsKeys` 상수 클래스 도입 (매직 스트링 중앙화)
- `addGold(0)` 해킹을 `UserDataNotifier.refresh()`로 교체
- `MovementNotifier` state를 `UserData?` → `MovementState?`로 분리 (SSOT 복원)
- 미사용 `XxxList` 래퍼 클래스 11개 삭제 (-2,000줄)

**Phase 3 — 품질 강화**
- `GameConstants` 상수 클래스 신규 (매직 넘버 10개 중앙화)
- timer 재계산 로직을 `recalculateEndTime()` 유틸리티로 통일 (3개 Notifier)
- `QuestCalculator.calculateSuccessRatePreview()` 추가 (랜덤 편차 없는 결정적 미리보기)
- View 레이어 비즈니스 로직 도메인으로 이동 (RecruitmentService 쿨다운, IdleRewardService, UserDataNotifier.recordFreeRecruit)
- `SyncService._fullDownload()` 부분 실패 시 캐시 롤백 처리
- `avoid_print` 린트 룰 추가
- 테스트 23개 신규 (총 138개)

### Bug Fixes
- Android 릴리스 빌드 시 네트워크 연결 실패 수정 (`AndroidManifest.xml`에 INTERNET 퍼미션 추가)

### Docs
- 코드베이스 종합 리뷰 리포트 및 Phase 1~3 구현 결과 문서 추가
- CLAUDE.md 아키텍처 섹션 업데이트 (core/domain, core/constants, SettingsKeys 반영)

### 트레잇 시스템 고도화 (Phase 1-2)

- Supabase에 트레잇 시스템 6개 테이블 생성 (trait_categories, traits, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies)
- 106개 트레잇 + 관계 데이터 (충돌 16쌍, 단일진화 16개, 조합진화 15개, 시너지 39개) 입력
- Flutter 모델 교체 (TraitData 구조 변경 + 5개 신규 모델 추가)
- SyncService 16개 테이블 동기화 대응
- 트레잇 카테고리 기반 색상 시스템 적용

### 트레잇 시스템 핵심 엔진 (Phase 3)

- 행동 지표 추적 시스템: 23개 지표(파견/생존/퀘스트유형/경제/연속기록) 퀘스트 완료 시 자동 갱신
- 용병 모집 변경: 선천 트레잇 1~3개 랜덤 부여 (Physical/Background/Talent 카테고리별 선택)
- 트레잇 획득 엔진: 행동 지표 → acquisition_condition 비교 → 시너지 감소 → 충돌 검증 → 자동 획득
- 데이터 드리븐 트레잇 효과: effect_json 기반 성공률/사망률/부상률 보정 (밸런스 수치는 향후 입력)
- quest type ID 변경: loot → raid (약탈)
- UI: 용병 카드에 복수 트레잇 뱃지 표시

### 트레잇 진화 시스템 (Phase 4)

- 단일 진화 엔진: acquired 트레잇 + 행동 지표 조건 충족 → 같은 카테고리 evolved 트레잇으로 교체
- 조합 진화 엔진: 서로 다른 카테고리의 acquired 2개 보유 시 → 원본 소멸 + evolved 트레잇 획득 + 슬롯 해방
- 트레잇 히스토리: 소멸된 트레잇 기록 (HiveField 16) → 재획득 방지 활성화
- 퀘스트 완료 시 자동 진화 체크 (단일 우선, 조합 후순위, 1회/턴 제한)

---

## 2026-04-11

### Features
- Supabase 기반 버전별 델타 동기화 시스템 구축 (1217d8b → 50437ee)
  - `SupabaseInitializer`: dotenv(.env) 기반 Supabase 연결 초기화 (2318607)
  - `DataLoader`: 캐시 파일 I/O 및 Supabase 응답 파싱 (9b5a9fb)
  - `SyncService`: `data_versions` 테이블 비교 → 변경 테이블만 다운로드하는 델타 동기화 (15c3270)
  - 앱 생명주기(시작 + 포그라운드 복귀)에 SyncService 통합 (ed6a6ab)

### Refactors
- 번들 JSON 파일 및 `JsonLoader` 제거 → Supabase 동기화로 대체 (e735d94)
- 전체 정적 데이터 모델 `@JsonKey` 어노테이션을 snake_case로 변환 (Supabase 컬럼명 일치) (5a896e5, 321c3b5)
- 캐시 저장소를 `path_provider` → Hive `staticDataCache` 박스로 교체 (웹 호환성) (3744a76)

### Docs
- Supabase 데이터 동기화 설계 스펙 및 구현 계획 추가 (6d285db, 3e3a92c)
- CLAUDE.md Supabase 데이터 동기화 아키텍처 반영 업데이트 (86dd3d6)

---

## 2026-04-10

- `update` (e3d7a6e)

---

## 2026-04-09

### Features
- 방치형 오프라인 보상 추가 (분당 1G, 최대 480G) (e3ddfed)
- 용병 방출 기능 추가 (퇴직금: 인건비 × 레벨) (0529a2e)
- 파견 중 이동 불가 제한 추가 (33983cf)
- 홈 화면에 용병 대시보드, 활동 로그, 퀘스트 완료 알림 추가 (37a04c8)
- Hive 기반 활동 로그 시스템 추가 (f52bc2e → f52bc2e)
- 파티 선택 UI를 드래그 가능한 바텀 시트로 교체 (f52bc2e)
- 활성 퀘스트가 최대치 미만일 때 퀘스트 채우기 버튼 추가 (6643e93)
- 대기 중 퀘스트 1시간마다 자동 갱신 + 카운트다운 타이머 (fc4ed52 → e2e2ced)
- 첫 실행 시 퀘스트 자동 생성 및 `createdAt` 필드 추가 (75995d8 → fc4ed52)
- 난이도별 min~max 범위 내 파견 비용 시간 비례 계산 (23c5201 → 75995d8)

### Bug Fixes
- `_showResult` 반환 타입을 `Future<void>`로 수정 (23c5201)
- 퀘스트 결과 다이얼로그 깜빡임 및 버튼 무반응 수정 (4ae9770)
- 시간 가속 시 모든 활성 타이머 endTime 재계산 수정 (d4cf610)

### Docs
- 20260409 요구사항 구현 계획 및 설계 문서 추가 (44f8902, 6f8c915)
- 구현 현황 업데이트 (3086895)
- Android 빌드 설정 가이드 추가 (aa27f2d)

---

## 2026-04-08

### Features
- 파견 비용/수익 분석 UI 추가 및 스탯 표시 수정 (9691d4a)
- 용병 모집 시 주둔지 용량 제한 적용 (ddafea8 → 731ed72)
- 레벨/XP 표시, 랭크 배지, 이동 이벤트 다이얼로그, 리전 잠금 UI 추가 (ddafea8)
- 시설 관리 화면 및 업그레이드 UI 추가 (0127bdf)
- 명성 랭크 기반 리전 티어 잠금 추가 (3fcb8fe)
- 퀘스트 완료 흐름에 XP, 명성, 시설 효과 통합 (3a780a8)
- 퀘스트 시스템에 파견 비용 및 인건비 차감 통합 (92c68ba)
- 이동 시스템에 이동 이벤트 통합 (af86de2)
- `ReputationService`: 랭크 결정 및 리전 접근 가능 여부 계산 (3f25caf)
- `FacilityService`: 업그레이드 검증 및 효과 계산 (3ec0554)
- `ExperienceService`: XP 계산 및 레벨업 로직 (61a19d8)
- `QuestCalculator`에 인건비 및 파견 비용 계산 추가 (3ec83aa)
- `TravelEventService`: 이벤트 확률, 필터링, 지연 처리 (f83ad6f)
- `UserData` 모델에 명성 및 시설 필드 추가 (de09320 → d0bc294)
- `Mercenary` 모델에 XP/레벨 필드 및 레벨 기반 스탯 보너스 추가 (d1fe218 → de09320)
- 새 정적 데이터 모델 `JsonLoader` 및 `StaticDataProvider`에 연결 (d1fe218)
- JSON 데이터 파일 추가 및 `Difficulty`에 파견 비용 필드 추가 (93d15bd)
- 이동 이벤트, 시설, 랭크, 인건비 정적 데이터 모델 추가 (97fd136 → 174be2f)

### Docs
- 게임 깊이 및 목표 시스템 구현 계획 추가 (97fd136)
- 브레인스토밍 미래 아이디어 문서화 (f9a2e3e)
- 게임 깊이/목표 설계 스펙 및 미래 아이디어 문서 추가 (d0df72f)

### Chore
- Android 플랫폼 추가 및 테스트 오류 수정 (ab4f9ff)

---

## 2026-04-07

### Features
- `main.dart` 추가: Hive 초기화 및 앱 부트스트랩 (2edd4ae)
- 모집 화면, 용병 카드, 설정 화면 추가 (e0f1a89)
- 파견 화면 및 퀘스트 결과 다이얼로그 추가 (6014878)
- 이동 화면: 리전/섹터 선택 UI (6dd0bbb)
- 하단 네비게이션, 홈 화면(야영지 페인터), 앱 셸 추가 (c809a5e)
- 용병/퀘스트/이동 Provider 및 게임 로직 통합 (642992b)
- 용병/퀘스트/이동 Repository 추가 (3de9691)
- 정적 데이터, 타이머, 게임 상태 핵심 Provider 추가 (4a1e3aa)
- 앱 테마, `StatusBadge`, `TimerDisplay` 위젯 추가 (5228482)
- `RecruitmentService` 및 `QuestGenerator` 추가 (전체 테스트 포함) (086d478)
- `QuestCalculator` 추가: 성공률, 결과, 피해, 소요시간 로직 (5e01cbe)
- Hive 어댑터 및 `HiveInitializer`가 포함된 런타임 데이터 모델 추가 (32b096a)
- 모든 정적 데이터 파싱 메서드 포함 `JsonLoader` 추가 (b2e283c)
- freezed + json_serializable 정적 데이터 모델 추가 (f6c4f42)
- Flutter 프로젝트 초기화: 의존성 및 디렉토리 구조 (8f0f8dd)

### Docs
- 프로토타입 구현 계획 추가 (3c222f2)
- 프로토타입 설계 스펙 추가 (de75b52)

### Chore
- Claude Code 설정 파일 추가 (9ee3f86)
- `.gitignore` 추가 (2ad86de)
- 나머지 미추적 파일 추가 (Docs, Json, iOS 빌드 아티팩트) (4ae0349)
