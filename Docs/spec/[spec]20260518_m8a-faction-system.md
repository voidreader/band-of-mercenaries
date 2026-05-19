# M8a 세력 접촉점·상점·지명 의뢰 시스템 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260518_m8a_faction_contacts.md`
> - `Docs/content-design/[content]20260518_m8a_faction_vertical_slice.md`
> - `Docs/content-design/[content]20260518_m8a_faction_patronage_flow.md`
> - `Docs/balance-design/[balance]20260518_m8a_faction_shop_unlocks.md`
> - `Docs/balance-design/[balance]20260518_m8a_faction_quest_rewards.md`
>
> 데이터 입력:
> - `Docs/content-data/[faction-contact]20260518_m8a-faction-contacts.csv` (접촉점 3 + 반응 33)
> - `Docs/content-data/[faction-quest]20260518_m8a-faction-named-quests.csv` (12 지명 의뢰)
> - `Docs/content-data/[faction-shop]20260518_m8a-faction-shop-items.csv` (18 상품)
> - `Docs/content-data/[faction-reward]20260518_m8a-faction-rewards.csv` (전용 보상 6)
> - `Docs/content-data/[item]20260518_m8a-faction-rewards.csv` (신규 아이템 4)
>
> 작성일: 2026-05-18

## 1. 개요

M8a는 14세력 전체 확장 대신 모험가 길드·상인 연합·전사 길드 3개 대표 세력에 대해 "접촉점 → 후원 상태 → 가입 → 신뢰" 수직 절편을 구현한다. 본 명세는 (1) 신규 정적 데이터 3 테이블(`faction_contacts`·`faction_reactions`·`faction_shop_items`)과 상점에서 참조하는 아이템 seed 완결성 보장, (2) 가입 전 후원 상태 계산형 헬퍼, (3) 세력 지명 의뢰 12개를 처리하기 위한 `NamedHookEvaluator` 3종 hook 확장(`region_flag`·`faction_contact`·`faction_reputation`), (4) `QuestCompletionService` 세력 평판 보상 분기, (5) `CraftingService` unlock_condition_json 2종 type 확장(`factionReputation`·`factionContact`), (6) `FactionDetailScreen` 접촉점·상점·반응 텍스트 섹션 노출을 단일 명세 단위로 통합한다.

본 명세는 **페이즈 4 #2 전투 보고서 시스템과 #3 정적 데이터 스키마 명세와 별도로 작성**되며, 전투 보고서 저장·뷰는 별도 명세에 위임한다. `special_flags['combat_report']==true`는 본 명세에서 단지 "보고서 생성 대상 의뢰임"을 표기만 하고, 실제 저장 로직은 후속 명세가 담당한다.

## 2. 요구사항

### 2.1 기능 요구사항

#### 2.1.A 세력 접촉점·반응 텍스트

- [FR-A1] **접촉점 정적 데이터 로드**
  - `faction_contacts` 테이블 3행을 `StaticGameData.factionContacts`로 노출한다.
  - 각 접촉점은 `id`, `factionId`, `npcName`, `regionId`(대표 리전), `triggerType`, `triggerValue`, `firstReactionText`, `tagsJson` 필드를 보유한다.
  - 발급 데이터는 CSV `record_type='contact'` 3행을 그대로 매핑한다.
- [FR-A2] **반응 텍스트 정적 데이터 로드**
  - `faction_reactions` 테이블에 CSV `record_type='reaction'` 33행을 그대로 적재한다.
  - 각 반응은 `id`, `factionId`, `contactId`, `triggerType`, `triggerValue`, `relationStage`, `weight`, `text`, `tagsJson` 필드를 보유한다.
  - `triggerType` enum **7종**: `infrastructureTier` · `region_flag` · `achievement` · `faction_reputation` · `faction_joined` · `conflict_hint` · `combat_report`. 미지원 trigger는 silent skip.
  - `faction_reputation` trigger의 `triggerValue`는 4 형태 중 하나로 표기한다: `1..10` (후원 단계) · `31..60` (신뢰 단계) · `61..100` (핵심 단계) · `<0` (적대 단계).
- [FR-A3] **접촉점 활성 판정**
  - `FactionContactService.isActive(contactId, ref)` 동기 헬퍼를 추가하여 `triggerType`이 `infrastructureTier`, `region_flag`, `achievement`(`elite_unique_first_kill:*` 와일드카드 포함) 중 하나일 때 조건 만족 여부를 반환한다.
  - 모험가 길드 접촉점은 `infrastructureTier(region_3) >= 2` 또는 위업 `settlement_event_completed:settlement_3_pyegwang_reopen` 보유로 활성된다.
  - 상인 연합 접촉점은 `infrastructureTier(region_3) >= 3` 또는 `region_127_nomad_friendly` 플래그로 활성된다.
  - 전사 길드 접촉점은 위업 `elite_unique_first_kill:*`(어느 elite든 1개 이상) 또는 `region_38_ironbound_pact_completed` 플래그로 활성된다.
  - 활성된 contactId는 `factionStatesProvider`/`regionStateRepository` watch 결과로부터 매 호출 시 재평가한다(영속 캐시 미사용 — M8a MVP).
- [FR-A4] **후원 상태 계산형 헬퍼**
  - `FactionRelationStage.resolve(factionId, ref)` 헬퍼는 다음 우선순위로 단계를 반환한다: `hostile`(rep<0) → `core`(joined && rep≥61) → `trusted`(joined && rep≥31) → `joined`(joined) → `patronage`(!joined && rep≥1 && rep≤10 && contact_active) → `noticed`(!joined && rep==0 && contact_active) → `untouched`.
  - 본 헬퍼는 Hive 신규 필드를 추가하지 않고 기존 `FactionState.reputation` / `joined` 와 FR-A3 결과만 사용한다.
- [FR-A5] **반응 텍스트 선택 헬퍼**
  - `FactionReactionPicker.pickFor({factionId, relationStage, triggerType?, triggerValue?, random})`는 일치하는 반응 후보 중 `weight` 가중 random 1개를 반환한다.
  - 일치 조건: factionId 일치 AND (relationStage 일치 OR `any`) AND (triggerType 미지정 또는 일치) AND (triggerValue 미지정 또는 일치 — `1..10` 등 범위 표기 파서 포함).
  - 후보 0개일 때 null 반환.
- [FR-A6] **접촉점 도착 이벤트**
  - 신규 `factionContactArrivedProvider: StateProvider<FactionContactArrivedEvent?>` 채널을 추가한다.
  - `gameTickProvider` 또는 `app.dart` 포그라운드 복귀 hook에서 활성 contactId 집합을 직전 계산값과 비교하여 신규 활성된 contactId 1개당 1회 enqueue한다.
  - dedup 기준은 ActivityLog가 아니라 `FactionState.contactUnlockedIds`(HiveField 9 신규)이다. 신규 활성 contactId를 발견하면 해당 세력의 `contactUnlockedIds`에 먼저 기록하고 저장한 뒤 enqueue한다.
  - ActivityLog `factionContactUnlocked`(HiveField 35)는 사용자 기록용 mirror log로만 남긴다. dialogQueue priority `medium`.

#### 2.1.B 세력 지명 의뢰 12개 (`quest_pools` 확장)

- [FR-B1] **`NamedHookEvaluator` 3 hook 확장**
  - `named_hook_type`에 다음 3 case를 switch 분기로 추가한다:
    - `region_flag`: `RegionState.unlockedFlags`에 namedHookValue 포함 또는 위업 templateId(`settlement_event_completed:<id>` 등)로 fallback 매칭한다.
    - `faction_contact`: `FactionContactService.isActive(value, ref)` 결과 true 시 통과.
    - `faction_reputation`: namedHookValue 파싱 `faction_<id>>=<int>` 형식. 해당 세력의 `FactionState.currentReputation`이 임계 이상이면 통과.
  - 미지원 type 또는 파싱 실패는 silent false 유지(기존 default 동작).
  - 위 3 hook 평가에 필요한 컨텍스트로 `NamedHookContext`에 **정확히 3개의 신규 필드**를 추가한다(기존 3 필드 `mercenaries`/`bandAchievements`/`flagshipMercId` 유지):
    - `Map<int, Set<String>> unlockedRegionFlags` — region_flag hook용. key=regionId, value=해당 region의 unlockedFlags Set. `RegionStateRepository.getAll()`로부터 빌드.
    - `Set<String> activeContactIds` — faction_contact hook용. `FactionContactService.isActive(contactId, ref)` true인 contactId 집합.
    - `Map<String, int> factionReputations` — faction_reputation hook용. key=factionId, value=currentReputation. `FactionStateRepository.getAllReputations()` 결과.
  - `joinedFactionIds`는 본 3 hook 평가에 사용하지 않으므로 `NamedHookContext`에 추가하지 않는다(이미 `factionReputations` Map과 `FactionState.isJoined`만으로 충분).
- [FR-B2] **`NamedHookContext` 빌드 변경**
  - `QuestGenerator.generateQuests` 시그니처에 `unlockedRegionFlags`와 `activeContactIds` optional 인자를 추가한다. `factionReputations`는 기존 required 인자를 `NamedHookContext.factionReputations`에도 재사용한다.
  - `QuestGenerator.generateQuests` 내부의 `NamedHookContext` 생성부는 기존 `mercenaries`/`bandAchievements`/`flagshipMercId`에 신규 3 필드(`unlockedRegionFlags`, `activeContactIds`, `factionReputations`)를 모두 채운다.
  - `quest_provider.dart`의 generateQuests 호출부는 빌드 헬퍼 `NamedHookContextBuilder.build(ref)`를 통해 `unlockedRegionFlags`와 `activeContactIds`를 주입한다. 기존 `factionReputations` 인자는 그대로 넘긴다.
- [FR-B3] **`quest_pools` 12행 추가**
  - `Docs/content-data/[faction-quest]20260518_m8a-faction-named-quests.csv`의 12행을 그대로 `quest_pools`에 INSERT한다.
  - `is_named=true`, `faction_tag` ∈ {`faction_adventurers_guild`,`faction_merchants_alliance`,`faction_warriors_guild`}, `is_faction_exclusive=false`.
  - `named_hook_type` 분포: `region_flag` 8개 · `faction_contact` 1개 · `faction_reputation` 2개 · `achievement_count` 1개(기존 hook 재사용).
  - `named_cooldown_hours`: 후원 18 / 기본·신뢰 20~24 / 고급 24.
- [FR-B4] **`computeFinalWeight`의 named α 분기 호환**
  - 기존 `if (pool.isNamed) weight += 3.0`(quest_generator.dart L291~292) 분기는 변경하지 않는다. M8a 세력 지명 의뢰는 동일한 +3.0 가산을 그대로 받는다.
  - `region_state_required` / `region_state_excluded` 필터는 기존 컬럼을 그대로 사용한다(L251~265).
- [FR-B5] **세력 지명 의뢰의 `factionTag` 보존**
  - `QuestGenerator`가 일반 풀(`!isFactionExclusive`)에서 `pool.isNamed == true && pool.factionTag != null`인 풀을 `ActiveQuest`로 생성할 때는 `ActiveQuest.factionTag = pool.factionTag`로 고정한다.
  - 위 조건에 해당하지 않는 일반 의뢰만 기존 `FactionTagResolver.resolve(...)` 결과를 사용한다.
  - 이 규칙은 M8a 세력 지명 의뢰 완료 시 `QuestCompletionService`와 `_applyCompletionResult`가 정확한 세력에 평판을 지급하기 위한 필수 조건이다.

#### 2.1.C 세력 지명 의뢰 보상·평판 처리 (`QuestCompletionService`)

- [FR-C1] **세력 평판 보상 special_flags 우선 적용**
  - `factionRepGain` 계산(quest_completion_service.dart L349~353)을 다음 우선순위로 교체한다:
    1. `pool.specialFlags['faction_named'] == true` 인 경우:
       - 성공: `faction_reputation_success`(int)
       - 대성공: `faction_reputation_great_success`(int)
       - 실패: 0
       - 대실패: `faction_reputation_critical_failure`(int, 음수 가능)
       모두 없을 시 0.
    2. 그 외(기존 일반 세력 태그 의뢰): `quest.reputationReward ?? 0`(성공/대성공 한정).
  - 적용된 `factionRepGain`은 기존 `named_reputation_multiplier`(L252~256) 적용 후의 `repGain`(랭크 명성)과 **독립**이다. 세력 평판은 별도 합산하여 `_applyCompletionResult`에서 `FactionStateRepository.addReputation`으로 지급한다.
- [FR-C2] **보고서 메타 표기**
  - `pool.specialFlags['combat_report'] == true`이면 `QuestCompletionResult`에 `bool combatReportEligible` 필드(default false)를 true로 세팅만 한다. 본 명세에서는 별도 저장 호출 없음(후속 명세 위임).
- [FR-C3] **세력 평판 활동 로그**
  - `_applyCompletionResult`에서 `result.factionTag != null && result.factionRepGain != 0`인 경우 `FactionStateRepository.addReputation`을 호출한다. 기존 `> 0` 조건은 음수 패널티를 누락하므로 사용하지 않는다.
  - 같은 조건에서 ActivityLog `factionReputationChanged`(HiveField 36 신규) 1회 기록.
  - 메시지 포맷: `"{세력명} 평판 {부호}{n}"` (예: `"모험가 길드 평판 +4"`).
- [FR-C4] **세력 평판 변경 후 보상 hook 평가 위치**
  - `FactionStateRepository.addReputation`은 저장소 책임만 유지하고, 칭호·아이템 보상 hook을 직접 호출하지 않는다.
  - `_applyCompletionResult`는 `addReputation` 호출 전후의 평판을 읽어 `oldRep`, `newRep`를 계산한 뒤, fail-soft try/catch로 `TitleService.evaluateFactionReputationHook(...)`과 `FactionRewardService.grantItemRewardIfEligible(...)`를 호출한다.
  - 이 설계는 `FactionStateRepository`가 `TitleService`, `InventoryRepository`, `RegionStateRepository`, `WidgetRef`에 의존하는 순환 구조를 방지한다.

#### 2.1.D 세력 상점 18개

- [FR-D1] **`faction_shop_items` 18행 적재**
  - `Docs/content-data/[faction-shop]20260518_m8a-faction-shop-items.csv` 18행을 정적 테이블로 적재한다.
  - 컬럼: `id`, `factionId`, `itemId`, `shopCategory`(consumable/equipment/material_bundle/recipe_key), `priceGold`, `minReputation`, `requiresJoined`, `unlockType`, `unlockValue`, `stockPolicy`(`once`/`daily`), `stockLimit`, `restockHours`(nullable), `sortOrder`, `grantType`(`item`/`bundle`), `notes`.
  - `faction_shop_items.item_id`가 참조하는 모든 `itemId`는 마이그레이션 완료 시점에 `items.id`에 반드시 존재해야 한다. `[item]20260518_m8a-faction-rewards.csv`의 4행만으로는 부족하므로, 페이즈 4 #3 마이그레이션 SQL은 상점 전용 미정의 itemId를 추가 seed로 생성하거나 해당 상점 행을 제외해야 한다.
  - `unknown_item`은 런타임 방어용 데이터 오류 상태이며 정상 데이터에서 발생하면 안 된다. verifier는 `staticData.factionShopItems.every((s) => staticData.items.any((i) => i.id == s.itemId))`를 PASS 조건으로 삼는다.
- [FR-D2] **상점 해금 평가**
  - `FactionShopService.evaluateUnlock(item, ref)`는 다음 **6단계**를 위에서 아래로 순차 평가한다. 어느 단계든 종결 결과(`Locked`/`SoldOut`/`Ready`)를 반환하면 평가를 즉시 종료한다.
    1. **가입 요구 검사**: `requiresJoined == true && !FactionState.isJoined` → `Locked('not_joined')` 반환.
    2. **최소 평판 검사**: `FactionState.currentReputation < minReputation` → `Locked('reputation:{minReputation}')` 반환.
    3. **`unlockType` 분기 평가**:
       - `faction_contact`: `FactionContactService.isActive(unlockValue, ref)` false → `Locked('contact:{unlockValue}')` 반환.
       - `region_flag`: 매칭되는 region의 `RegionState.unlockedFlags`에 `unlockValue` 미포함 → `Locked('region_flag:{unlockValue}')` 반환.
       - `faction_reputation`: `faction_<id>>=<int>` 파싱 후 해당 세력의 평판 < 임계값 → `Locked('reputation:{n}')` 반환 (step 2와 키 형태 동일하나 다른 세력 참조도 가능 — 본 명세 데이터에는 사용 없음).
       - 기타/null/파싱 실패: 분기 평가 건너뜀(다음 step으로 진행).
    4. **once 재고 검사**: `stockPolicy == 'once' && shopPurchaseHistory[itemId] == true` → `SoldOut(null)` 반환.
    5. **daily 재고 검사** (`stockPolicy == 'daily'` 인 경우에만):
       - `shopDailyPurchases[itemId]` 항목이 존재하고 `restockAt <= now` → 해당 항목을 reset(count=0, restockAt=null) 후 step 5의 다음 조건으로 재진입.
       - reset 후 또는 처음부터 항목이 없거나 `count < stockLimit` → step 6으로 진행.
       - `count >= stockLimit && restockAt > now` → `SoldOut(restockAt)` 반환.
       - reset 시 발생한 변경(count=0)은 본 평가 함수 내에서는 메모리상 변경만 수행하고, 영속 저장은 다음 `purchase` 호출 시 함께 처리한다.
    6. **모두 통과**: `Ready` 반환.
  - 반환은 sealed `FactionShopUnlockResult` 3 case: `Ready` / `Locked(String reason)` / `SoldOut(DateTime? restockAt)`.
  - itemId가 `items` 정적 데이터에 없는 경우 step 1보다 먼저 `Locked('unknown_item')` 반환 (엣지 케이스 가드, 4.3 엣지 케이스 항목 참조).
- [FR-D3] **상점 구매 처리**
  - `FactionShopService.purchase(item, ref)` 절차:
    1. `evaluateUnlock` `Ready` 확인. 아니면 `StateError`.
    2. `UserData.gold >= priceGold` 확인. 부족 시 `StateError('insufficient_gold')`.
    3. `userDataProvider.notifier.addGold(-priceGold)` 차감.
    4. `inventoryRepositoryProvider.addItem(itemId: itemId, quantity: 1, items: staticData.items)`. `material_bundle` 카테고리는 `quantity=1` 고정(M8a MVP — bundle 내 수량은 향후 확장).
    5. `FactionState.shopPurchaseHistory`(once 누적) 또는 `shopDailyPurchases`(daily 카운터+restockAt) 갱신 후 save.
    6. ActivityLog `factionShopPurchased`(HiveField 37 신규).
- [FR-D4] **상점 상태 영속**
  - `FactionState` HiveField 6: `Map<String,bool> shopPurchaseHistory`(once 구매 itemId Set)
  - `FactionState` HiveField 7: `Map<String, FactionShopDailyEntry> shopDailyPurchases`(itemId → count·restockAt). `FactionShopDailyEntry` typeId 20(M8a 신규).

#### 2.1.E 세력 전용 보상 6개

- [FR-E1] **`titles` 2행 추가**
  - `title_m8a_guild_ledger_name`(모험가 길드, "길드 장부에 오른 자") / `title_m8a_duel_marked`(전사 길드, "결투 표식을 받은 자")를 `titles` 테이블에 INSERT.
  - M8a MVP에서는 신규 용병단 칭호 저장소를 만들지 않고 기존 `Mercenary.titleIds`를 재사용한다. 두 title은 `hook_type='faction_reputation'`으로 추가하고, `hook_condition` JSON에 `{"hook_target":"last_dispatch_protagonist","faction_id":"<factionId>","threshold":31}` 형식을 사용한다.
  - 평판 임계값을 넘긴 의뢰의 주인공 용병(`UserData.lastDispatchProtagonistMercId`)이 살아 있으면 해당 용병에게 칭호를 발급한다. 대상 용병이 없거나 사망했으면 silent skip한다.
- [FR-E2] **세력 평판 hook 신규 type 추가**
  - `TitleService.evaluateFactionReputationHook({required String factionId, required int oldRep, required int newRep, required String? targetMercId})`를 추가하여 평판 변화 시 평가한다.
  - hook 조건은 `title.hookType == 'faction_reputation'`, `hook_condition.faction_id == factionId`, `hook_condition.threshold` 존재로 판정한다. `oldRep < threshold && newRep >= threshold`일 때만 신규 발급을 시도한다.
  - hook 평가는 FR-C4에 따라 `_applyCompletionResult`에서 fail-soft trailing으로 호출한다. `FactionStateRepository.addReputation` 내부에서는 호출하지 않는다.
- [FR-E3] **레시피 2행 추가**
  - `recipe_m8a_record_compass`(결과 = `guild_artifact_record_compass`)
  - `recipe_m8a_trade_seal`(결과 = `guild_artifact_trade_seal`)
  - 두 레시피의 `unlock_condition_json`은 FR-F1 신규 type 2종(`factionReputation` / `factionContact`)을 활용한 `all`/`any` 구성. 데이터 행은 `Docs/content-data/[faction-reward]20260518_m8a-faction-rewards.csv`의 `unlock_condition_json` 그대로 사용.
- [FR-E4] **신규 아이템 4행 추가**
  - `items` 테이블에 `guild_artifact_record_compass` · `guild_artifact_trade_seal` · `guild_artifact_merchant_warrant` · `equip_accessory_red_spear_wristwrap` 4행을 INSERT.
  - 각 effectJson은 `Docs/content-data/[item]20260518_m8a-faction-rewards.csv`의 값을 그대로 사용한다.
- [FR-E5] **보상 지급 분기**
  - 칭호 보상(reward_type=`title`)은 FR-E2 hook으로 자동 grant.
  - 레시피 보상(reward_type=`recipe`)은 unlock_condition_json만으로 평가되므로 별도 grant 호출 없음.
  - 아이템 보상(reward_type=`item`)의 `상단 보증서`·`붉은 창의 손목끈`은 평판 임계 + region flag 충족 시 `FactionRewardService.grantItemRewardIfEligible`로 자동 1회 지급(`FactionState.grantedRewardIds` HiveField 8 신규 dedup, Set<String>).
  - 평가 시점: FR-C4에 따라 `_applyCompletionResult`에서 `FactionStateRepository.addReputation` 후 1회. 저장소 내부 trailing hook으로 구현하지 않는다.

#### 2.1.F 제작 unlock_condition_json 확장

- [FR-F1] **`CraftingService._isUnlockedM7`에 2 case 추가**
  - `CraftingService`는 `WidgetRef`를 보유하지 않는 순수 서비스 구조를 유지한다. 생성자에 `FactionStateRepository factionStateRepository`와 `bool Function(String contactId) isFactionContactActive` 콜백을 주입한다.
  - `case 'factionReputation'`: `condition.flag`=factionId, `condition.value`=minReputation. `factionStateRepository.getState(factionId)?.currentReputation ?? 0 >= condition.value` 시 true.
  - `case 'factionContact'`: `condition.flag`=contactId. `isFactionContactActive(condition.flag!)` 시 true.
  - 두 case 모두 null 입력에 대해 false fallback.
- [FR-F2] **재귀 분기 호환**
  - `all`/`any`/`factionReputation`/`factionContact`/`regionFlag`/`infrastructureTier` 6 type이 `all`/`any` 하위에서 자유 조합 가능해야 한다(기존 재귀 호출 유지).

#### 2.1.G UI 노출

- [FR-G1] **세력 상세 화면 확장**
  - `FactionDetailScreen._FactionBody`에 다음 3 섹션을 신규 추가한다(L405 발견 기록 위, "활동 티어" 다음):
    1. **생활권 접촉점 섹션**: 활성 contactId 1개당 카드 — NPC명 + 첫 반응 텍스트 + `FactionRelationStage` 라벨(주목/후원/가입/신뢰/핵심/적대) + (있다면) FactionReactionPicker로 선택된 현재 단계 반응 텍스트 1개.
    2. **세력 지명 의뢰 섹션**: 현재 활성 quest_pools 중 `faction_tag` 일치하는 named pool의 카운트와 진행 중 의뢰 목록(`questListProvider`에서 factionTag 일치 active quest 필터).
    3. **세력 상점 섹션**: `FactionShopService.evaluateUnlock` 결과별 그룹(`ready` / `locked` / `sold_out`) + 각 상품 카드(아이템명·가격·상태·구매 버튼 — Ready 한정).
- [FR-G2] **접촉점 도착 다이얼로그**
  - `FactionContactArrivedDialog`(medium priority) — NPC 한 줄 + 첫 반응 + "정보 탭에서 확인" 버튼. 확인 시 `factionCodexScrollTargetProvider.state = factionId` 설정 후 dismiss.
- [FR-G3] **세력 도감 진입 강조**
  - `FactionCodexScreen._FactionCard`에 활성 contact 보유 세력은 우측 상단에 작은 점(`AppTheme.namedAccent` 0xFFE91E63 4px dot) 표시.

### 2.2 데이터 요구사항

#### 2.2.A 신규/수정 Hive 박스

| 박스 | 모델 | typeId | 신규 HiveField | 비고 |
|------|------|--------|---------------|------|
| `factionStates` | `FactionState` | 9 (기존) | **6**: `shopPurchaseHistory: Map<String,bool>` / **7**: `shopDailyPurchases: Map<String,FactionShopDailyEntry>` / **8**: `grantedRewardIds: List<String>` / **9**: `contactUnlockedIds: List<String>` | 다음 HiveField 10으로 시프트 |
| `factionStates` | `FactionShopDailyEntry` (신규) | **20** | 0: `count`, 1: `restockAt` | typeId 20 신규 점유 |
| `activityLogs` | `ActivityLogType` enum | 6 | **35**: `factionContactUnlocked`, **36**: `factionReputationChanged`, **37**: `factionShopPurchased`, **38**: `factionRewardGranted` | 다음 HiveField 39 |

위 HiveField 신규 추가는 CLAUDE.md "typeId 점유 및 다음 HiveField" 표에서 현재 FactionState 다음=6, ActivityLogType 다음=35와 정합한다. `UserData`는 본 명세에서 신규 HiveField를 추가하지 않는다.

#### 2.2.B 신규 Supabase 정적 테이블 (3개)

| 테이블 | 행수 | 컬럼 핵심 |
|--------|------|----------|
| `faction_contacts` | 3 | id PK · faction_id FK · region_id FK · npc_name · trigger_type · trigger_value · first_reaction_text · tags_json JSONB |
| `faction_reactions` | 33 | id PK · faction_id FK · contact_id FK · trigger_type · trigger_value · relation_stage · weight INT DEFAULT 50 · text · tags_json JSONB |
| `faction_shop_items` | 18 | id PK · faction_id FK · item_id FK · shop_category · price_gold INT · min_reputation INT · requires_joined BOOL · unlock_type · unlock_value · stock_policy · stock_limit INT · restock_hours INT NULL · sort_order INT · grant_type · notes |

SyncService.allTables 33·34·35번째에 등록한다(현재 32번째 `region_adjacency` 다음).

#### 2.2.C 기존 테이블 행 추가

| 테이블 | 추가 행 | 출처 |
|--------|---------|------|
| `quest_pools` | 12 | `[faction-quest]20260518_m8a-faction-named-quests.csv` |
| `items` | 4 | `[item]20260518_m8a-faction-rewards.csv` |
| `crafting_recipes` | 2 | `[faction-reward]20260518_m8a-faction-rewards.csv` (reward_type=recipe) |
| `titles` | 2 | `[faction-reward]20260518_m8a-faction-rewards.csv` (reward_type=title) |

#### 2.2.D 기존 모델 컬럼/필드 변경

- **`titles` 테이블**: `hook_type` CHECK 제약에 `'faction_reputation'` 추가. `hook_target`과 임계값은 별도 컬럼이 아니라 기존 `hook_condition` JSONB에 저장하므로 CHECK 확장 없음.
- **`items_slot_check` CHECK**: 신규 slot 추가 없음(`artifact`·`accessory` 기존 slot 재사용).
- **`crafting_recipes.unlock_condition_json`**: 스키마 변경 없음(JSONB). 신규 type 2종(`factionReputation`/`factionContact`)은 데이터 측 분기만 추가.

#### 2.2.E 신규 enum

- `FactionRelationStage` enum 7종: `untouched` · `noticed` · `patronage` · `joined` · `trusted` · `core` · `hostile`. Dart 측 enum(영속 미사용, 계산형). `Docs/content-design/.../patronage_flow.md` 7단계와 1:1 매핑.
- `FactionShopStockPolicy` enum 2종: `once` · `daily`.
- `FactionShopUnlockResult` sealed: `Ready` · `Locked(String reason)` · `SoldOut(DateTime? restockAt)`.

### 2.3 UI 요구사항

#### 2.3.A 세력 상세 화면 — 3개 신규 섹션

- **진입 조건**: `info_screen.dart` 세력 도감 → 카드 탭 → `FactionDetailScreen` (기존). 본 명세는 화면 신규 추가 없음.
- **위젯 계층** (수정 부분만 발췌):
  ```
  _FactionBody (ListView)
   ├─ 세력명/공개도 배지 (기존)
   ├─ 평판 바 (기존)
   ├─ 가입 조건 (기존)
   ├─ 패시브 보너스 (기존, clueLevel≥2)
   ├─ 설명/이념 (기존)
   ├─ 활동 티어 (기존)
   ├─ [신규] FactionContactSection
   │   ├─ Card × N (활성 contact 수)
   │   │   ├─ Row: NpcAvatar + 이름
   │   │   ├─ Text: 첫 반응 텍스트 또는 단계별 반응
   │   │   └─ Chip: relationStage 라벨
   ├─ [신규] FactionNamedQuestSection
   │   ├─ Header: "지명 의뢰 {N}건 활성"
   │   └─ ListView.builder: 진행 중인 의뢰 카드 (이름·잔여 시간)
   ├─ [신규] FactionShopSection
   │   ├─ Section: "구매 가능"
   │   ├─ Section: "조건 미충족"
   │   └─ Section: "재고 소진"
   │       └─ ShopItemCard (아이템 thumb + 이름 + 가격 + 상태 + 구매 버튼)
   ├─ 발견 기록 (기존)
   └─ 발견 리전 (기존)
  ```
- **상태 변수**: 모두 `ref.watch`로 reactive 갱신. 로컬 StatefulWidget 상태 없음(`FactionShopService.evaluateUnlock`는 매 build 마다 호출 — 18개 상품 × 3 평가 단계로 부담 미미).
- **화면 전환**: 기존 `FactionDetailScreen`은 이미 상태 기반(InfoScreen에서 `selectedFactionId` state) 렌더링. 본 명세에서 추가 화면 전환 없음.
- **연출/애니메이션**: 상품 구매 성공 시 카드에 1.5초 골드 보더 펄스(`AnimatedContainer`). FR-G3 도감 카드 분홍 dot은 정적 표시.

#### 2.3.B 접촉점 도착 다이얼로그

- **진입 조건**: `factionContactArrivedProvider` enqueue → DialogTypeRegistry registry 호출.
- **위젯 계층**: 기존 `RegionStateChangedDialog` 패턴 참조(`features/investigation/view/region_state_changed_dialog.dart`).
- **dialogQueue priority**: medium. `DialogTypeRegistry`에 `factionContactArrived` 키 1개를 신규 추가한다.

### 2.4 비기능 요구사항

- **하위 호환**: 기존 `FactionState` 박스의 typeId 9 객체는 신규 HiveField 6/7/8/9를 nullable 또는 default empty로 받는다. Hive 어댑터 재생성 시 기존 데이터 손실 없음을 보장한다.
- **fail-soft**: M8a 신규 trailing hook(접촉점 도착·세력 보상 grant·세력 평판 칭호 hook)은 모두 try/catch로 감싸 본체 흐름을 막지 않는다. (위업 grant 6 hook과 동일 패턴)
- **N+1 회피**: `FactionDetailScreen` 빌드 시 `evaluateUnlock` 18회 호출은 동기 + Hive 박스 read이므로 허용. `factionStatesProvider` 단일 watch로 충분.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/data/sync_service.dart` (L18~51) | `allTables` 리스트에 `faction_contacts`/`faction_reactions`/`faction_shop_items` 3행 추가 | FR-D1, FR-A1, FR-A2 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` (L39~226) | `StaticGameData` 필드 3개 추가 + `staticDataProvider` 로드 라인 3개 추가 | 정적 데이터 노출 |
| `band_of_mercenaries/lib/features/info/domain/faction_state_model.dart` (L27~70) | HiveField 6/7/8/9 추가 + adapter 재생성 + `FactionShopDailyEntry` typeId 20 신규 모델 | FR-A6, FR-D4, FR-E5 |
| `band_of_mercenaries/lib/features/info/data/faction_state_repository.dart` (L1~132) | `recordShopPurchase` 메서드 + `markRewardGranted`/`hasGrantedReward` + `markContactUnlocked`/`hasContactUnlocked` | FR-A6·D3·E5 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` (L5~77) | ActivityLogType HiveField 35~38 추가(`factionContactUnlocked`/`factionReputationChanged`/`factionShopPurchased`/`factionRewardGranted`) | FR-A6, FR-C3, FR-D3, FR-E5 |
| `band_of_mercenaries/lib/features/quest/domain/named_hook_evaluator.dart` (L9~64) | `NamedHookContext` 필드 3개 추가 + `evaluateNamedHook` switch에 3 case 추가 | FR-B1 |
| `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` (L20~208) | `NamedHookContext` 신규 필드 채움 + 세력 지명 의뢰 `pool.factionTag` 보존 | FR-B2, FR-B5 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` (L250·L467·L667 부근) | `NamedHookContextBuilder.build(ref)` 호출로 4 호출점 통합 | FR-B2 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` (L349~353) | `factionRepGain` 계산 분기 교체(`faction_named` 우선 → 기존 fallback) + `combatReportEligible` 결과 필드 추가 | FR-C1, FR-C2 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` (`_applyCompletionResult` L1311~1316 부근) | `factionRepGain != 0` 시 세력 평판 적용·ActivityLog 추가·칭호/아이템 보상 hook fail-soft 호출 | FR-C3, FR-C4 |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` (L102~129) | 생성자 DI 추가 + `_isUnlockedM7` switch에 `factionReputation`/`factionContact` case 2개 추가 | FR-F1 |
| `band_of_mercenaries/lib/features/title/domain/title_service.dart` | `evaluateFactionReputationHook({factionId, oldRep, newRep, targetMercId})` 메서드 신규 + 기존 `Mercenary.titleIds` grant 로직 재사용 | FR-E1, FR-E2 |
| `band_of_mercenaries/lib/features/info/view/faction_detail_screen.dart` (`_FactionBody` L144~495) | 3개 신규 섹션 위젯 삽입 (활동 티어 다음, 발견 기록 이전) | FR-G1 |
| `band_of_mercenaries/lib/features/info/view/faction_codex_screen.dart` (`_FactionCard` L196~290) | 활성 contact 보유 세력에 분홍 dot 표시 | FR-G3 |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` (`DialogTypeRegistry`) | `FactionContactArrivedDialog` case 추가 (medium priority) | FR-G2 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/info/domain/faction_contact_data.dart` | `FactionContact` freezed + JSON 모델 (3행) |
| `band_of_mercenaries/lib/features/info/domain/faction_reaction_data.dart` | `FactionReaction` freezed + JSON 모델 (33행) |
| `band_of_mercenaries/lib/features/info/domain/faction_shop_item_data.dart` | `FactionShopItem` freezed + JSON 모델 (18행) |
| `band_of_mercenaries/lib/features/info/domain/faction_shop_daily_entry.dart` | `FactionShopDailyEntry` Hive 모델 (typeId 20) |
| `band_of_mercenaries/lib/features/info/domain/faction_contact_service.dart` | `FactionContactService.isActive(contactId, ref)` 정적 헬퍼 |
| `band_of_mercenaries/lib/features/info/domain/faction_relation_stage.dart` | `FactionRelationStage` enum + `resolve(factionId, ref)` 헬퍼 |
| `band_of_mercenaries/lib/features/info/domain/faction_reaction_picker.dart` | `FactionReactionPicker.pickFor` 가중 random 선택 |
| `band_of_mercenaries/lib/features/info/domain/faction_shop_service.dart` | `FactionShopService.evaluateUnlock` / `purchase` 서비스 |
| `band_of_mercenaries/lib/features/info/domain/faction_shop_unlock_result.dart` | `FactionShopUnlockResult` sealed (`Ready`·`Locked`·`SoldOut`) |
| `band_of_mercenaries/lib/features/info/domain/faction_reward_service.dart` | `FactionRewardService.grantItemRewardIfEligible` 트리거 |
| `band_of_mercenaries/lib/features/info/domain/faction_contact_arrived_event.dart` | `FactionContactArrivedEvent` 모델 + `factionContactArrivedProvider` |
| `band_of_mercenaries/lib/features/info/view/faction_contact_section.dart` | 세력 상세 접촉점 섹션 위젯 |
| `band_of_mercenaries/lib/features/info/view/faction_named_quest_section.dart` | 세력 지명 의뢰 섹션 위젯 |
| `band_of_mercenaries/lib/features/info/view/faction_shop_section.dart` | 세력 상점 섹션 위젯 + `_ShopItemCard` |
| `band_of_mercenaries/lib/features/info/view/faction_contact_arrived_dialog.dart` | 접촉점 도착 다이얼로그 |
| `band_of_mercenaries/lib/features/quest/domain/named_hook_context_builder.dart` | `NamedHookContextBuilder.build(ref)` 단일 진입점 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `faction_contact_data.g.dart` / `.freezed.dart` | freezed + json_serializable |
| `faction_reaction_data.g.dart` / `.freezed.dart` | 동일 |
| `faction_shop_item_data.g.dart` / `.freezed.dart` | 동일 |
| `faction_shop_daily_entry.g.dart` | hive_generator |
| `faction_shop_unlock_result.g.dart` / `.freezed.dart` | sealed freezed |
| `faction_state_model.g.dart` | HiveField 6/7/8/9 추가에 따른 adapter 재생성 |
| `activity_log_model.g.dart` | enum HiveField 35~38 추가 |
| `named_hook_evaluator.dart`(순수 클래스, 재생성 불필요) | — |
| `faction_contact_arrived_event.g.dart` / `.freezed.dart` | freezed |

`build_runner build` 1회 실행 필요.

### 3.4 관련 시스템

- **세력 시스템**: FactionState 영속 확장, 후원 상태 도입.
- **지명 의뢰 시스템**: NamedHookEvaluator 3 hook 확장.
- **퀘스트 완료 처리**: 세력 평판 보상 special_flags 분기.
- **제작 시스템**: unlock_condition_json 2 type 확장.
- **칭호 시스템**: hook_type `faction_reputation` 신규. 대상 지정은 `hook_condition.hook_target='last_dispatch_protagonist'`로 기존 분기 의미를 재사용.
- **위업 시스템**: 변경 없음(M8a #1은 위업 grant 추가 없음 — 후속 명세에서 처리).
- **이동 시스템**: 변경 없음.
- **인벤토리 시스템**: 상점 구매 시 기존 `addItem` 재사용. material_bundle 카테고리는 향후 확장 대상.
- **다이얼로그 큐**: DialogTypeRegistry에 `factionContactArrived` 키 1개 추가.
- **정적 데이터 동기화**: SyncService.allTables 32→35로 증가.
- **전투 보고서 시스템(별도 명세)**: 본 명세는 `combat_report` 메타만 마킹.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **신규 정적 테이블 추가 패턴**: M7 페이즈 4 #3 `region_adjacency`(`region_adjacency.dart` + `static_data_provider.dart` L155~158)를 1:1 참조한다. SyncService.allTables 추가 → StaticGameData 필드 → DataLoader.loadFromCache 라인 1개.
- **special_flags 키 분기**: `band_of_mercenaries/lib/features/quest/domain/special_flag_processor.dart`의 `apply` 메서드 다중 case 분기 패턴 참조. 본 명세는 `faction_reputation_success`/`_great_success`/`_critical_failure` 3 키를 `QuestCompletionService`에서 직접 분기(SpecialFlagProcessor 확장 아님).
- **세력 평판 trailing fail-soft**: M7 페이즈 4 #4 `_evaluateInfrastructureTransition`(`region_state_repository.dart`) 인프라 전이 trailing 패턴 참조. 본 명세의 칭호·아이템 보상 hook은 저장소 내부가 아니라 `_applyCompletionResult`에서 평판 저장 직후 try/catch로 평가한다.
- **칭호 hook 신규 type 추가**: M6 페이즈 4 #2 `TitleService.evaluateAchievementHook`(`title_service.dart`) 비동기 fail-soft 패턴 참조.
- **dialogQueue 채널 패턴**: CLAUDE.md "이벤트 채널 패턴" 절 참조 — `StateProvider<Event?>` publish 직후 `enqueue` + `state = null` 즉시 리셋.
- **상태 기반 화면 렌더링**: M7 `FactionDetailScreen` 진입(`info_screen.dart` `selectedFactionId` 상태). Navigator.push 사용 금지(CLAUDE.md "화면 전환").

### 4.2 주의사항

- **HiveField 번호 시프트 금지**: 기존 0~5는 절대 변경하지 않는다. 신규 6/7/8만 nullable 또는 default empty로 추가. typeId 20은 미사용 확인 — CLAUDE.md "사용 중 typeId: 6·8·9·10·11·13·14·15·16·17·18·19. typeId 12 보존" 위반 없음.
- **stat_migration_v2와 충돌 금지**: 신규 마이그레이션 플래그가 필요한 경우 `faction_state_v2_migration` 같은 신규 키를 settings 박스에 추가하되, 기존 `stat_migration_v2`와 키 충돌 없도록 한다.
- **`faction_named`와 `is_faction_exclusive` 혼동 금지**: 기존 `is_faction_exclusive=true`(M1 세력 전용 의뢰)와 M8a `special_flags['faction_named']=true`는 독립 플래그다. 두 플래그가 동시 true인 의뢰는 본 명세 범위 밖(현재 12행 모두 `is_faction_exclusive=false`).
- **`shopDailyPurchases`의 시간 비교**: `DateTime.now()` 기준 비교. 디바이스 시계 변경 시 abuse 가능하지만 M8a MVP에서는 허용. 향후 서버 시각 검증 필요 시 별도 명세.
- **양방향 명세 분리**: 본 명세는 페이즈 4 #1만 다룬다. 전투 보고서 저장(#2), Supabase 마이그레이션 SQL 통합(#3), operation-bom 편집 도구(#3), 통합 검증(#4)은 별도 명세에서 다룬다. 다만 본 명세 구현은 #2가 완성되기 전에도 동작해야 한다(`combatReportEligible` 필드만 마킹, 저장 호출 없음).
- **상인 연합 vs 전사 길드 약한 갈등(-1 평판)**: 본 명세 범위 밖(content-design `patronage_flow.md`에서 "검토" 단계). 추후 별도 FR로 다룬다.

### 4.3 엣지 케이스

- **세력 동시 탈퇴 시 상점 영속**: 충돌 세력 가입으로 자동 탈퇴 시 `shopPurchaseHistory`는 유지(이미 구매한 아이템은 보존). 단 신규 구매는 `requiresJoined=true` 상품 잠금으로 자연 차단.
- **접촉점 활성 후 비활성 전환**: 인프라 Tier 하락 가능성 미고려(M7 인프라는 일방향 증가). region_flag 해제 시나리오는 본 명세 범위 밖.
- **named hook 평가 시 `factionReputations` 동시성**: `addReputation` 후 즉시 다음 `generateQuests` 호출되는 경우, ref 시그널 전파 타이밍에 따라 신규 평판 값이 반영되지 않을 수 있다. 본 명세는 `NamedHookContextBuilder.build(ref)`가 매 호출 시 `read` 기반으로 최신 값을 가져오도록 한다(`ref.read(factionStateRepositoryProvider)` 직접 호출).
- **세력 상품의 itemId가 `items`에 없는 경우**: 정상 데이터에서는 허용하지 않는다. 마이그레이션 SQL은 상점 CSV의 모든 `item_id`가 `items`에 존재하도록 추가 seed를 생성하거나 상점 행을 제외해야 한다. 로드 시 itemId가 정적 데이터에 없으면 `evaluateUnlock`는 `locked:unknown_item`을 반환하되, 이는 verifier FAIL 대상 데이터 오류로 본다.
- **`region_flag` named hook의 위업 fallback**: `settlement_event_completed:settlement_3_pyegwang_reopen`처럼 위업 형태 trigger 값은 `RegionState.unlockedFlags`에 없으므로 위업 보유 여부로 fallback 매칭한다(FR-B1).
- **상점 daily restockAt이 자정 기준이 아닌 24시간 슬라이딩**: `stockPolicy=daily` + `restockHours=24`는 첫 구매 시각 + 24시간이 다음 restockAt이다. 자정 기준 갱신이 아니므로 플레이어가 의식적으로 시각을 맞출 필요 없음.
- **`factionContactArrivedProvider`의 dedup**: `FactionState.contactUnlockedIds`를 dedup 키로 사용. 신규 contact 등장 시 1회만 enqueue. 앱 재시작 후에도 `contactUnlockedIds` 기록이 남아 있으면 재enqueue 안 됨.
- **세력 평판 칭호 대상 용병 부재**: `lastDispatchProtagonistMercId`가 null이거나 대상 용병이 사망/방출 상태이면 title grant는 silent skip한다. 세력 평판 자체와 아이템 보상 평가는 계속 진행한다.

### 4.4 구현 힌트

- **진입점**:
  - 접촉점 활성 판정 — `FactionContactService.isActive(contactId, ref)` 신규.
  - 후원 상태 — `FactionRelationStage.resolve(factionId, ref)` 신규.
  - 세력 지명 의뢰 hook — `NamedHookEvaluator.evaluateNamedHook` 기존 switch 확장(L38).
  - 세력 평판 보상 — `QuestCompletionService.calculate` L349~353 분기 교체.
  - 상점 — `FactionShopService.evaluateUnlock(item, ref)` 신규.
  - 제작 unlock — `CraftingService._isUnlockedM7` L102~129 switch 확장.
  - 칭호 hook — `TitleService.evaluateFactionReputationHook` 신규 + `_applyCompletionResult` trailing.

- **데이터 흐름**:
  - 접촉점 활성: `RegionState.infrastructureTier` / `unlockedFlags` / `BandAchievementsBox` → `FactionContactService.isActive` → `FactionDetailScreen` `FactionContactSection`
  - 지명 의뢰 발급: `quest_provider.generateQuests` → `NamedHookContextBuilder.build(ref)` → `QuestGenerator.generateQuests(..., NamedHookContext(..., unlockedRegionFlags, activeContactIds, factionReputations))` → `NamedHookEvaluator.evaluateNamedHook` → `_weightedSample` → `ActiveQuest` 발급 → `_updateNamedCooldownsForQuests`
  - 지명 의뢰 완료 평판: `QuestCompletionService.calculate` → `factionRepGain` 분기(`faction_named` 우선) → `_applyCompletionResult` → `FactionStateRepository.addReputation` → `_applyCompletionResult` 내부 fail-soft hook(칭호 + 아이템 보상) → ActivityLog
  - 상점 구매: `FactionShopSection` 탭 → `FactionShopService.purchase` → 골드 차감 + addItem + Hive 영속 → ActivityLog

- **참조 구현**:
  - `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` `_evaluateInfrastructureTransition` (M7 페이즈 4 #4): 평판/단계 변경 후 trailing fail-soft 단계 보상 + flag toggle + 위업 grant 패턴.
  - `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart` L78~83, L241~295: pool 필터 + computeFinalWeight 가중치 분기. 본 명세의 hook 확장은 L78~83 evaluateNamedHook 호출 분기만 그대로 사용한다(가중치는 변경 없음).
  - `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` L102~129: switch case 추가 패턴 그대로 따라간다.
  - `band_of_mercenaries/lib/features/info/view/faction_detail_screen.dart` `_FactionBody` L144~495: ListView 섹션 추가 위치(활동 티어 L383~405 다음).
  - `band_of_mercenaries/lib/features/investigation/view/region_state_changed_dialog.dart`: `FactionContactArrivedDialog` 위젯 구조 1:1 참조.

- **확장 지점**:
  - `NamedHookContext`에 신규 3 필드를 추가하는 것은 본 명세 핵심 변경점. 기존 호출부 4곳 + 테스트 코드(`test/features/quest/`)도 함께 갱신해야 한다.
  - `FactionState` HiveField 6/7/8/9 추가 시 어댑터 재생성 필수. `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 실행.
  - SyncService.allTables는 32→35로 증가하지만 기존 영속 캐시는 `validateRequiredCaches`(`data_loader.dart` L19~29)에서 빈 캐시 감지 후 자가치유 풀다운로드한다.

## 5. 기획 확인 사항

- [Q-1] **세력 상점 daily 갱신 기준**
  - 기획서(`shop_unlocks.md` L168~169): "구현 명세에서는 제한 재고를 일일 갱신으로 처리할지, 상점 방문 시각 기준으로 처리할지 결정한다."
  - **본 명세 결정**: **24시간 슬라이딩(첫 구매 시각 + 24h)**. 자정 기준 갱신은 게임 시간 가속과 충돌하며, 슬라이딩은 다른 쿨다운 패턴(약초상 쿨다운·지명 의뢰 쿨다운)과 일관됨.

- [Q-2] **세력 평판 칭호 grant 대상**
  - 기획서(`vertical_slice.md` L122): "칭호는 용병 개인이 아니라 용병단 또는 특정 주인공 용병에 붙을 수 있다. 페이즈 4 명세에서 기존 TitleService의 hook_target을 재사용할지, 세력 보상용 별도 칭호를 만들지 결정한다."
  - **본 명세 결정**: **신규 `band` hook_target을 추가하지 않는다.** M8a MVP는 기존 `Mercenary.titleIds`를 재사용하고 `hook_condition.hook_target='last_dispatch_protagonist'`로 지급한다. 용병단 자체 칭호 저장소와 UI 노출은 M8.5 이후로 넘긴다.

- [Q-3] **상인 연합 vs 전사 길드 약한 갈등(-1 평판)**
  - 기획서(`patronage_flow.md` L86~89): "상인 연합 가입 상태에서 전사 길드 후원 의뢰를 완료하면 상인 연합 평판 -1을 검토한다."
  - **본 명세 결정**: **M8a #1 범위 밖**. 동적 갈등 페널티는 별도 FR로 분리하여 후속 명세(또는 페이즈 4 #4 통합 명세)에서 다룬다. 현재 의뢰 12개 모두 `faction_tag` 단일 매칭으로 처리한다.

- [Q-4] **`named_hook_type='region_flag'` 의 trigger 값에 위업 templateId 포함 시 매핑**
  - CSV `qp_m8a_adv_pyegwang_record_audit` 행: `named_hook_value=settlement_event_completed:settlement_3_pyegwang_reopen` (위업 templateId 형태)
  - **본 명세 결정**: `region_flag` hook 평가 시 1차로 `RegionState.unlockedFlags.contains(value)` 시도, 실패 시 2차로 `:` 포함 시 위업 templateId fallback(`bandAchievementsBox.values.any((a) => a.templateId == value)`). 데이터 정합성을 위해 향후 `named_hook_type='achievement_id'` 직접 사용을 권장.

- [Q-5] **상점 `material_bundle` grant 수량**
  - CSV `shop_m8a_adv_wind_sample_box` `notes`: "mat_herb_wind 1개와 소량 골드 보조 후보"
  - **본 명세 결정**: M8a MVP에서 `material_bundle`은 `addItem(itemId, quantity=1)` 고정. 묶음 내부 추가 보상(소량 골드 등)은 후속 명세 위임. 가격(180G)이 이를 반영한 수치이므로 MVP 충분.

- [Q-6] **`FactionContact.regionId` 결정**
  - CSV에는 `tags_json.region` 필드로 region 매핑(3·3·38). 본 명세는 이를 `regionId INT` 컬럼으로 분리하여 정규화한다.

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260518_m8a-faction-system.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|------|------|------|
| 수정/생성 파일 | 수정 14개 + 신규 16개 = **30개** | 대규모 |
| 영향 시스템 | 세력·지명 의뢰·퀘스트 완료·제작·칭호·다이얼로그 큐·정적 데이터 동기화·UI(세력 도감/상세) (**8개**) | 대규모 |
| 신규 클래스 | FactionContact·FactionReaction·FactionShopItem·FactionShopDailyEntry·FactionContactService·FactionRelationStage·FactionReactionPicker·FactionShopService·FactionShopUnlockResult·FactionRewardService·FactionContactArrivedEvent·NamedHookContextBuilder·FactionContactSection·FactionNamedQuestSection·FactionShopSection·FactionContactArrivedDialog (**16개**) | 대규모 |
| 데이터 모델 | 신규 정적 테이블 3개(`faction_contacts`/`faction_reactions`/`faction_shop_items`) + FactionState HiveField 4 추가 + ActivityLogType 4 enum value + typeId 20 신규 | 대규모 |
| UI 작업 | 신규 위젯 4종 + 기존 화면 2종 수정 + 신규 다이얼로그 1종 | 대규모 |
| 기존 시스템 변경 | NamedHookEvaluator 3 hook 확장 + QuestCompletionService 분기 교체 + CraftingService 2 case 추가 + TitleService 신규 hook + SyncService 3 테이블 등록 | 대규모 |

**추천: implement-agent (6/6점) — 강력 추천**
- 세력 시스템 수직 절편 전체를 한 번에 구현해야 하며 다중 도메인·다중 데이터 모델·신규 UI 위젯이 30개 파일에 걸쳐 분산되어 있어, 단계별 계획·구현·검증·코드 리뷰 파이프라인이 필수다.

구현을 진행하려면 아래 명령어를 실행해주세요:

```
/implement-agent @Docs/spec/[spec]20260518_m8a-faction-system.md  ← 추천 (파이프라인, 6/6점)
/implement-spec @Docs/spec/[spec]20260518_m8a-faction-system.md  (올인원, 비추천)
```
