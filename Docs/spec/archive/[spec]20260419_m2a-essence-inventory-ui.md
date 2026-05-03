# M2a 정수 사용 + 인벤토리 UI 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260418_essence_system.md` (페이즈 1 산출물 2 — 정수 시스템 규칙)
> - `Docs/balance-design/20260418_essence_inflation.md` (페이즈 2 산출물 2 — 효과 곡선 +1/+2/+4/+7/+11, 상한 +10/+20/+40/+70/+120)
>
> 선행 명세 (구현 완료):
> - `Docs/spec/[spec]20260419_m2a-item-inventory-infrastructure.md` (산출물 1 — Hive `inventory` 박스, `ItemData`, `InventoryRepository`)
> - `Docs/spec/[spec]20260419_m2a-item-equipment-effects.md` (산출물 2 — `Mercenary.legendaryDeathPreventionCooldownUntil`, `effectiveStrWith` 등 장비 보정 메서드, HiveField 18 점유)
>
> 작성일: 2026-04-19
> 유형: M2a 마일스톤 페이즈 4 산출물 3/3 (정수 사용 + 인벤토리 UI)

---

## 1. 개요

M2a "아이템의 태동" 마일스톤의 마지막 산출물로, 정수(Essence) 소비 파이프라인과 인벤토리 UI를 구축한다. 산출물 1이 구축한 `InventoryRepository` · `ItemData` · `inventory` 박스 위에, 산출물 2가 도입한 `effectiveStrWith`(장비 보정) 메서드 옆에 **정수 항 `permanent*`를 영구 스탯 축으로 삽입**하여 `effectiveStrWith((base + permanent + equipment) × (1 + levelBonus) × fatigueMod)` 공식을 완성한다. 또한 보유 아이템을 한눈에 조회하는 **인벤토리 화면**을 신설하고, 정수 사용 UX(대상 용병 선택 → 프리뷰 팝업 → 확정 → 소모 연출)와 **사망·방출 시 소멸 경고**를 구현한다.

본 명세가 커버하는 범위:
- `Mercenary` 모델에 HiveField(19~22) `permanentStr` / `permanentIntelligence` / `permanentVit` / `permanentAgi` 추가 (기본 0).
- `EssenceService` 신설 — 정수 1개 소비 → 상한 판정 → `permanent*` 갱신 → 인벤토리 수량 차감.
- `Mercenary.effective*With` 4개 메서드 시그니처·공식 확장 (장비 보정 + 정수 가산).
- 인벤토리 화면(`InventoryScreen`) 신설 — 정보 탭 하위, 카테고리 필터(전체/개인장비/용병단장비/소모품) + 아이템 리스트 + 상세 팝업.
- 정수 사용 프리뷰 팝업(`EssenceApplyPreviewDialog`) — 현재/사용 후 값, 상한 잔량, 3단계 경고(정상/접근/초과).
- 소모 연출 — 각인(inscription) 애니메이션 + 활동 로그.
- 방출 다이얼로그(`recruit_screen.dart`) 확장 — `permanent*` > 0 시 소멸 경고 추가.
- 사망 처리 경로에 투입 정수 소실 활동 로그 기록 (용병 실제 제거 이전 시점).
- `ActivityLogType` 3종 추가: `essenceApplied` / `essenceLostOnDeath` / `essenceLostOnRelease`.

범위 외:
- 다중 소비 UI (M2a 범위 외, 기획서 4-4).
- 정수 드랍 (M2b).
- M6 승급 재료 재사용.

---

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1. Mercenary 모델 — permanent 스탯 4종 추가

- 파일: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart`.
- HiveField 추가 (신규 필드는 **현재 최대 HiveField 18 `legendaryDeathPreventionCooldownUntil` 다음**으로 순차 할당):

  | HiveField | 필드명 | 타입 | 기본값 |
  |:---:|---|---|:---:|
  | 19 | `permanentStr` | `int` | 0 |
  | 20 | `permanentIntelligence` | `int` | 0 |
  | 21 | `permanentVit` | `int` | 0 |
  | 22 | `permanentAgi` | `int` | 0 |

- 생성자 파라미터 추가. 기존 Hive 저장 데이터는 누락 시 0으로 복원(별도 마이그레이션 플래그 불필요, int는 Hive 기본 0 복원).
- **값 변경 정책**: 모든 `permanent*` 값 변경은 `EssenceService.apply`를 통해서만 수행한다. 외부에서 직접 수정 금지. 설정·저장은 `HiveObject.save()` 경로.
- 호환성: `stat_migration_v2` 같은 일회성 초기화 플래그는 추가하지 않는다. 기본값 0이 기존 데이터에 자연 적용된다.

#### FR-2. effective 공식 확장 — permanent 항 삽입

- 파일: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart`.
- 기존 getter 4종(`effectiveStr` · `effectiveIntelligence` · `effectiveVit` · `effectiveAgi`, 라인 111-129)은 **그대로 유지** (하위 호환 + 장비·정수 미적용 순수 베이스 조회용). 단, 공식 내에서 `permanent*`를 함께 가산하여 UI 표시(비파견 화면) 시에도 정수 반영이 유지되도록 한다.

  - 수정 공식:
    ```dart
    int get effectiveStr {
      final withLevel = ((str + permanentStr) * (1.0 + _levelBonus)).round();
      return status == MercenaryStatus.tired
          ? (withLevel * GameConstants.tiredDebuffMultiplier).round()
          : withLevel;
    }
    ```

- `*With(EquipmentStatBonus)` 4개 메서드 공식 확장 (산출물 2에서 추가된 라인 132-158):

  ```dart
  int effectiveStrWith(EquipmentStatBonus bonus) {
    final withLevel = ((str + permanentStr + bonus.str) * (1.0 + _levelBonus)).round();
    return status == MercenaryStatus.tired
        ? (withLevel * GameConstants.tiredDebuffMultiplier).round()
        : withLevel;
  }
  // effectiveIntelligenceWith / effectiveVitWith / effectiveAgiWith 동일 패턴
  ```

- 통일 공식: `effective = (base + permanent + equipment) × (1 + levelBonus) × fatigueMod`. 세 항(base / permanent / equipment) 모두 레벨 증폭을 동일하게 받는다. (기획 확인 사항 Q-1 참조 — `essence_system.md` 6항의 "비증폭 가산" 서술과 불일치하는 부분은 산출물 2에서 이미 확정된 장비 공식 `(base + equipment) × (1 + levelBonus)`과의 정합을 우선한다.)

- `QuestCalculator.calculatePartyPower`(`features/quest/domain/quest_calculator.dart:26-48`)는 이미 `effectiveStrWith` 등을 호출하므로 시그니처 변경 **불필요** — 모델 내부 공식만 확장되면 자동 반영.

#### FR-3. EssenceService 신설

- 파일: `band_of_mercenaries/lib/features/inventory/domain/essence_service.dart` (신설).
- 역할: 정수 1개 소비 → 상한 판정 → `permanent*` 갱신 + 인벤토리 수량 차감. 순수 정적 서비스(Repository 주입 인자 방식).
- 공개 메서드:

  ```dart
  class EssenceService {
    /// 정수 1회 효과 티어별 증가량. balance-design 페이즈 2 확정값.
    static const Map<int, int> tierGainTable = {
      1: 1, 2: 2, 3: 4, 4: 7, 5: 11,
    };

    /// 용병 티어별 축당 permanent 상한. balance-design 페이즈 2 확정값.
    static const Map<int, int> tierCapTable = {
      1: 10, 2: 20, 3: 40, 4: 70, 5: 120,
    };

    /// 정수 아이템의 effect_json에서 (statKey, gain)을 추출.
    /// 카테고리가 consumable이 아니거나 스키마 불일치 시 null.
    /// statKey ∈ {'str', 'intelligence', 'vit', 'agi'}.
    static EssenceDescriptor? resolve(ItemData item);

    /// 사용 전 프리뷰. 적용 가능 여부와 실제 증가량·손실량을 계산.
    static EssencePreview preview({
      required Mercenary mercenary,
      required ItemData essence,
      required int mercenaryTier, // Job.tier 조회 결과 주입
    });

    /// 실제 소비. 실패(카테고리 불일치·상한 완전 도달 등) 시 ApplyResult.failure.
    /// - permanent* 증가 (min(효과, 잔량))
    /// - inventory 수량 -1 (0 되면 자동 삭제)
    /// - activity log 기록
    /// 호출측: 상한 잔량 = 0일 때는 UI가 사전 차단 (본 메서드는 잔량 > 0 전제).
    static Future<EssenceApplyResult> apply({
      required Mercenary mercenary,
      required int mercenaryTier,
      required InventoryItem inventoryRow,
      required ItemData essence,
      required MercenaryRepository mercRepo,
      required InventoryRepository inventoryRepo,
      required ActivityLogNotifier logNotifier,
    });
  }
  ```

- 값 객체(모두 freezed):

  ```dart
  // 정수 effect_json 파싱 결과
  @freezed
  sealed class EssenceDescriptor with _$EssenceDescriptor {
    const factory EssenceDescriptor({
      required String statKey,    // 'str' | 'intelligence' | 'vit' | 'agi'
      required int gain,          // 티어별 곡선 값
      required int tier,          // 정수 아이템 tier
    }) = _EssenceDescriptor;
  }

  // 프리뷰 결과 — UI가 현재/적용 후/손실을 표시
  @freezed
  sealed class EssencePreview with _$EssencePreview {
    const factory EssencePreview({
      required String statKey,
      required int currentPermanent,   // 현재 permanent*
      required int cap,                 // 해당 용병 티어의 상한
      required int gain,                // 정수 1회 효과
      required int appliedGain,         // min(gain, cap - currentPermanent)
      required int lossAmount,          // gain - appliedGain
      required int effectiveBefore,     // 현재 effectiveStr/Int/... (장비·정수 미반영 순수 레벨치 또는 UI가 표시하려는 값)
      required int effectiveAfter,      // 사용 후 effectiveStr/Int/... (permanent만 반영)
      required EssencePreviewLevel warningLevel, // normal | approaching | overflow
    }) = _EssencePreview;
  }

  enum EssencePreviewLevel { normal, approaching, overflow }
  // normal: appliedGain == gain && cap - newPermanent >= gain
  // approaching: appliedGain == gain && cap - newPermanent < gain (남은 잔량이 다음 1회 효과보다 적음)
  // overflow: lossAmount > 0 (이번 사용에서 손실 발생)

  @freezed
  sealed class EssenceApplyResult with _$EssenceApplyResult {
    const factory EssenceApplyResult.success({
      required String statKey,
      required int appliedGain,
      required int lossAmount,
      required int newPermanent,
    }) = EssenceApplySuccess;
    const factory EssenceApplyResult.failure({
      required String reason, // 'schema' | 'full_cap' | 'not_found'
    }) = EssenceApplyFailure;
  }
  ```

- 파싱 규칙 (`resolve`):
  - `item.category == 'consumable'` 아니면 null.
  - `item.effectJson['permanent_stat_gain']`이 Map이고 정확히 1개 키를 포함해야 한다. 키 ∈ `{str, intelligence, vit, agi}`. 값은 int.
  - `gain`은 `item.tier`의 tierGainTable 값과 일치해야 한다(경고 목적, 불일치 시 fromJson 값을 우선 사용하되 debugPrint 경고).

- 상한 판정 (`preview` · `apply`):
  - `cap = tierCapTable[mercenaryTier]`.
  - `jail = cap - currentPermanent` (잔량).
  - `appliedGain = min(gain, max(jail, 0))`.
  - `lossAmount = gain - appliedGain`.
  - `jail <= 0`이면 `warningLevel = overflow`이고 UI는 사용 버튼 비활성화(아래 FR-6 참조). `apply`는 호출되지 않는 것을 전제로 하되, 방어적으로 `EssenceApplyFailure('full_cap')` 반환.

- `apply` 내부 순서:
  1. `preview` 재계산으로 `appliedGain` 확정.
  2. `mercenary.permanent{StatKey}` += appliedGain → `mercenary.save()`.
  3. `inventoryRepo.decrementQuantity(inventoryRow.id)` (0이면 자동 삭제).
  4. `logNotifier.addLog(...)` — FR-9 참조.

- **파티 활성 용병 상한 판정**: 상한은 **현재 용병 티어 기준**으로만 판정한다. 용병이 나중에 승급(M6)되면 새 티어 기준으로 상한이 확장되며, 기존 permanent 값은 유지된다 (M6 기획 범위, 본 명세는 현재 티어만 고려).

#### FR-4. 사망·방출 시 permanent 스탯 소실 처리

- **정책**: 사망·방출 시 permanent 값은 용병 삭제와 함께 자연 소실된다(별도 보존·환원 없음). 본 명세는 **활동 로그 기록**과 **방출 UI 경고**만 추가한다.

- **사망 경로**:
  - 파일: `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart`.
  - 사망 판정 직후(전설 ⑤ 쿨다운 소비 이후, `MercDamageResult.dead` 확정된 시점) **용병 객체가 `MercenaryRepository.removeDead`로 삭제되기 이전**에 permanent 합산을 읽어 활동 로그를 기록한다.
  - 기록 조건: `totalPermanent = permanentStr + permanentIntelligence + permanentVit + permanentAgi > 0`.
  - 로그 메시지 형식: `'${merc.name}이(가) 사망했다. 투입 정수 누적 +${total} 소실'`.
  - `ActivityLogType.essenceLostOnDeath`.

- **방출 경로**:
  - 파일: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` `dismiss` 메서드(라인 87-104).
  - 기존 로직 직전에 `totalPermanent > 0`이면 활동 로그 기록 추가.
  - 로그 메시지 형식: `'용병 "${merc.name}" 방출 (퇴직금: ${severancePay}G, 투입 정수 누적 +${total} 소실)'`.
  - 타입: `ActivityLogType.essenceLostOnRelease` (기존 `mercenaryDismiss` 대신 정수 소실이 있을 때만 사용. 없으면 기존 `mercenaryDismiss` 유지).

#### FR-5. ActivityLogType 확장

- 파일: `band_of_mercenaries/lib/core/domain/activity_log_model.dart`.
- 현재 HiveField 최대 14 (`reputationRankDown`) 다음으로 순차 할당:

  | HiveField | enum 값 | 용도 |
  |:---:|---|---|
  | 15 | `essenceApplied` | 정수 사용 성공 |
  | 16 | `essenceLostOnDeath` | 사망 시 투입 정수 소실 |
  | 17 | `essenceLostOnRelease` | 방출 시 투입 정수 소실 |

- enum 순서 규칙: 기존 필드 번호 불변(Hive 호환), 신규 3개를 말미에 추가.

#### FR-6. 인벤토리 화면 신설

- 파일 신설: `band_of_mercenaries/lib/features/inventory/view/inventory_screen.dart`.
- 진입 경로: **정보 탭(`InfoScreen`) 4번째 ListTile**. 기존 `_showCodex` / `_showRank` / `_showGuildEquipment` 패턴 그대로 `_showInventory` 상태 변수 추가 (라인 18-22).
  - 새 ListTile: 아이콘 `Icons.inventory_2` / 제목 `인벤토리` / 부제 `보유 아이템 관리 · 정수 사용` / onTap `_showInventory = true`.
  - `InfoScreen` 분기 순서: `_selectedFactionId > _showCodex > _showRank > _showGuildEquipment > _showInventory > 기본 ListTile`.
- 화면 구조:

  ```
  Column > [
    헤더 바 (뒤로가기 + 제목 '인벤토리'),
    카테고리 필터 탭 (Row 4개: 전체 / 개인장비 / 용병단장비 / 소모품),
    아이템 리스트 (Expanded ListView),
  ]
  ```

- 카테고리 필터:
  - 상태 변수 `_categoryFilter` (enum `InventoryCategoryFilter { all, personalEquipment, guildEquipment, consumable }`).
  - 각 탭: 선택된 필터는 primary 색상 언더라인 + 굵은 글씨. 개수 배지(해당 필터 매칭 아이템 행 수) 표시.
  - 전체 탭은 `inventory` 박스의 모든 행을 표시.
  - 필터 로직: `InventoryRepository.getAll()` + `getByCategory(category, items)` 중 `all`이면 전체.

- 아이템 리스트 카드:
  - 높이 72px, `Column` 2행:
    - 1행: 아이콘(티어 색상 원형 + 카테고리 기호) · 이름 · 티어 뱃지(`T{1~5}`) · 수량 (소모품만 `×{qty}` 우측 표시. 장비는 수량 숨김).
    - 2행: 장착 상태 (`equippedTo != null` → `"장착 중: {용병 이름}"` / 용병단 장비는 `UserData.bannerItemId / artifactItemIds[0~1]` 매칭 체크 → `"장착 중 (깃발 / 유물 1 / 유물 2)"`).
  - 탭 → 아이템 상세 팝업.

- 빈 상태: 필터 결과 0개일 때 중앙 "보유한 아이템이 없습니다" 텍스트.

- 정렬: 카테고리 → tier 내림차순 → 이름 오름차순. (사용자 체감 "가장 좋은 아이템 최상단".)

#### FR-7. 아이템 상세 팝업

- 파일 신설: `band_of_mercenaries/lib/features/inventory/view/item_detail_sheet.dart`.
- 타입: `showModalBottomSheet(isScrollControlled: true)`.
- 구성:
  - 헤더: 아이콘 + 이름 + 티어 뱃지 · 닫기 버튼.
  - 설명(`description`) · 플레이버 텍스트(`flavorText`, italic).
  - 효과 요약: `effect_json`을 카테고리별로 포맷.
    - 개인 장비: `ItemEffectService.resolvePersonalEquipment`로 `EquipmentStatBonus` + `LegendaryEffect?` 추출 → "STR +5 / 전설: 대성공 확률 +12%" 라인 나열.
    - 용병단 장비: `ItemEffectService.resolveGuildEquipment` → `PassiveBonusFormatter.format` 재사용.
    - 소모품(정수): `EssenceService.resolve` → `"{한글 스탯명} 영구 +{gain}"` (예: "STR 영구 +11").
  - 현재 수량 / 장착 상태 정보.
  - 액션 버튼:
    - 소모품(정수): `[사용]` 버튼 (우측 하단, primary 색상).
    - 개인 장비: `[장착하기]` → 용병 선택 시트 경로 (후속 UX, 본 명세 범위 외 — 기존 `EquipmentSlotGrid`에서 처리 지속. 상세 팝업에는 텍스트 안내 "용병 상세 화면에서 장착하세요" 표시).
    - 용병단 장비: `[장착하기]` → 용병단 장비 화면 안내 (동일 텍스트 안내).

- 정수 [사용] 탭 흐름 → FR-8 대상 용병 선택 시트 진입.

#### FR-8. 정수 사용 UX — 대상 용병 선택 + 프리뷰 팝업

**진입 경로 2가지**(기획서 4-1):

1. **경로 A (Pull, 용병 상세 → 정수 사용)**
   - 파일 수정: `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart`.
   - `_buildHeaderBar` 우측에 `IconButton(Icons.auto_awesome, tooltip: '정수 사용')` 추가. 탭 → **정수 선택 시트**(`EssenceSelectSheet`, 신설).
   - 정수 선택 시트 내용: 보유 consumable 아이템 리스트, 각 행에 `현재 STR: 12 / 상한 잔량: +8 / 효과: +4` 요약 표시 + `[사용]` 버튼.
   - 사용 탭 → **프리뷰 팝업** (`EssenceApplyPreviewDialog`, FR-8 뒤 참조).

2. **경로 B (Push, 인벤토리 → 정수 상세 → 사용)**
   - 파일 신설: `band_of_mercenaries/lib/features/inventory/view/essence_target_sheet.dart`.
   - 인벤토리 → 아이템 상세 팝업 → `[사용]` 탭 → **용병 선택 시트**.
   - 시트 내용: 생존 용병 전체 리스트 (사망 제외, 부상·파견·피로 포함). 각 행:
     - 용병 이름 · 티어 · 레벨 · 현재 permanent·effective (해당 stat) · 상한 잔량.
     - 잔량 = 0인 용병은 행 비활성화(회색) + "상한 도달" 라벨.
     - 잔량 > 0이고 잔량 < gain인 용병은 "일부 손실 경고" 뱃지.
     - 잔량 ≥ gain이면 일반 표시.
   - 용병 탭 → 프리뷰 팝업.

**프리뷰 팝업** (`EssenceApplyPreviewDialog`, 신설 `band_of_mercenaries/lib/features/inventory/view/essence_apply_preview_dialog.dart`):

- 타입: `showDialog<bool>()` (confirm 반환).
- 구성(기획서 4-2):

  ```
  [정수 사용 확인 / ⚠ 상한 초과 경고]  — warningLevel에 따라 헤더 톤 변경

  대상 용병: {이름} (T{jobTier}, Lv{level})
  사용 아이템: {이름} — T{tier} 정수 (+{gain})

  현재 STR:          {base} (base {str} + permanent +{currentPermanent})
  사용 후 STR:       {base + appliedGain} (base {str} + permanent +{newPermanent})
  상한 잔량:         +{jail} → +{jail - appliedGain}
  effective STR:     {effectiveBefore} → {effectiveAfter}  (레벨 보너스 {levelBonus}% 반영)

  [경고 영역 — warningLevel에 따라 조건부 표시]

  [취소]  [사용 / 손실 감수하고 사용]
  ```

- 3단계 경고(`EssencePreviewLevel`):
  - `normal`: 경고 영역 숨김. 우측 버튼 라벨 "사용".
  - `approaching`: 경고 영역에 `"💡 다음 사용 시 상한 초과 가능"` 정보 배너(파란색 정보 톤). 버튼 라벨 "사용" 유지.
  - `overflow`: 경고 영역에 `"⚠ 상한 초과: {lossAmount} 포인트가 손실됩니다"` 빨간색 경고 배너 + 버튼 라벨 "손실 감수하고 사용" + 버튼 색상 경고 톤.

- `appliedGain == 0` (잔량 = 0 이미 도달):
  - 프리뷰 팝업 대신 별도 `showDialog` AlertDialog("STR 상한에 이미 도달했습니다. 사용할 수 없습니다.") 표시 후 사용 차단. (FR-8 경로 B 용병 선택 시트에서 해당 용병은 비활성화되므로 일반적으로 이 경로는 도달하지 않음. 경로 A에서 방어적으로 차단.)

- 확정 시 `EssenceService.apply(...)` → 성공 시 소모 연출(FR-9) 실행.

#### FR-9. 소모 연출 + 활동 로그

- 성공 시 UX:
  1. 프리뷰 팝업 닫기(Navigator.pop(true)).
  2. **각인 연출** — `selectedMercenaryIdProvider`가 설정된 경우(경로 A에서 진입) 용병 상세 오버레이의 스탯 숫자가 200ms 동안 펄스 애니메이션(`AnimatedScale` + primary 색상 플래시). 경로 B(인벤토리)에서 용병 상세로 자동 전환하지 않고 인벤토리 화면에서 `showSnackBar`로 "{용병 이름}이(가) {아이템 이름}을(를) 각인했다. STR +{appliedGain}" 1.5초 표시.
  3. 활동 로그 추가:
     - 메시지: `'${merc.name}이(가) ${item.name}을(를) 각인했다. {한글 스탯명} +{appliedGain}{손실 있으면 " (+{lossAmount} 손실)" 추가}'`.
     - `ActivityLogType.essenceApplied`.
  4. `mercenaryListProvider.refresh()` 호출로 모든 화면의 스탯 표시 갱신.

- 실패 시: SnackBar로 실패 메시지(`full_cap` → "이미 상한에 도달했습니다", `schema` → "정수 데이터 오류", `not_found` → "아이템을 찾을 수 없습니다"). 로그 기록 없음.

- 한글 스탯명 매핑 상수 (`EssenceService` 내부 또는 별도 helper):
  - `str` → "힘(STR)" · `intelligence` → "지혜(INT)" · `vit` → "체력(VIT)" · `agi` → "민첩(AGI)"

#### FR-10. 용병 상세 오버레이 스탯 표시 — permanent 분리

- 파일 수정: `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart`.
- `_buildStatRow(merc)` (라인 296 근처) — 각 스탯 항목에 `permanent*` 값 > 0이면 보조 표기 추가:
  - 포맷: `"STR: 12 (+3)"` (base+permanent 합계를 메인, `+permanent`를 괄호 보조).
  - 툴팁 또는 길게 누르기: "base {str} + 정수 +{permanent}" 상세. (선택 구현 — 본 명세는 단순 괄호 표시만 필수로 규정.)
- 장비 보정은 `_buildStatRow`에 반영하지 않는다 (기존 동작 유지 — 용병 상세는 순수 effective[With permanent]만 표시). 파견 화면 SuccessRateBreakdown이 장비 기여 분해를 담당.

#### FR-11. 방출 다이얼로그 확장 — 정수 소멸 경고

- 파일 수정: `band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart` (라인 195-220 기존 `showDialog<void>` 부분).
- `totalPermanent = merc.permanentStr + merc.permanentIntelligence + merc.permanentVit + merc.permanentAgi`.
- `totalPermanent > 0`이면 다이얼로그 내용에 경고 섹션 추가:

  ```
  용병 "{name}"을 방출합니다.
  퇴직금 {severancePay}G가 차감됩니다.

  ⚠ 이 용병에 투입된 정수 보너스(+{totalPermanent})가 영구히 소실됩니다.

  방출된 용병은 다시 모집할 수 없습니다.
  ```

- 경고 영역 스타일: 연한 붉은색 배경 박스 + 아이콘. 기존 레이아웃 해치지 않는 선에서 `Container(padding, decoration)` 1개 추가.
- 확인 버튼 라벨: `totalPermanent > 0`이면 `[손실 감수하고 방출]`, 아니면 기존 `[방출]`.

### 2.2 데이터 요구사항

**수정 Hive 모델:**
- `Mercenary`(`typeId: 1`) — HiveField 19~22 신규 (`permanentStr` / `permanentIntelligence` / `permanentVit` / `permanentAgi`, 모두 `int` 기본 0). 기존 필드 0~18 불변. 누락 필드는 0 복원.

**수정 enum:**
- `ActivityLogType`(`typeId: 6`) — HiveField 15~17 신규 3종. 기존 0~14 불변.

**신규 freezed 모델:**
- `EssenceDescriptor` (`lib/features/inventory/domain/essence_service.dart` 또는 별도 파일).
- `EssencePreview`.
- `EssencePreviewLevel` enum (일반 enum, freezed 불필요).
- `EssenceApplyResult` sealed (2 variant).

**신규 UI 상태:**
- `InventoryCategoryFilter` enum (UI 로컬).

**Supabase 변경 없음**: 정수 데이터(items 테이블)는 산출물 1에서 생성된 `items` 테이블에 data-generator 페이즈 3으로 적재. 본 명세는 스키마 변경 없음.

**밸런스 수치 — balance-design 확정값:**
- tier별 효과 증가량: T1 +1 / T2 +2 / T3 +4 / T4 +7 / T5 +11.
- 용병 tier별 축당 상한: T1 +10 / T2 +20 / T3 +40 / T4 +70 / T5 +120.
- `EssenceService` 내부 상수로 하드코딩. 향후 operation-bom에서 편집 가능하게 하려면 별도 `balance_config` 테이블 신설 필요(본 명세 범위 외).

### 2.3 UI 요구사항

Visual Companion 생략(기존 패턴 재사용 위주 + 텍스트 명세로 충분).

**A. 인벤토리 화면**
- 진입 조건: 정보 탭 → `인벤토리` ListTile 탭 (`_showInventory = true`).
- 위젯 계층: `InventoryScreen > Column > [헤더, 카테고리 필터, Expanded(ListView of InventoryItemCard), 빈 상태 텍스트]`.
- 상태 변수: `_categoryFilter` (`InventoryCategoryFilter`).
- 화면 전환: 상태 기반 (Navigator.push 금지).
- `ConstrainedBox(maxWidth: 430)` 상속.

**B. 아이템 상세 팝업**
- `showModalBottomSheet(isScrollControlled: true)`.
- 헤더 + 설명 + 효과 요약 + 액션 버튼.

**C. 정수 선택 시트(경로 A)**
- `showModalBottomSheet`.
- 보유 consumable 리스트 + 각 행 요약 + `[사용]` 버튼.

**D. 용병 선택 시트(경로 B)**
- `showModalBottomSheet`.
- 생존 용병 전체 리스트 + 상한 잔량 정보 + 비활성화 처리.

**E. 정수 사용 프리뷰 팝업**
- `showDialog<bool>()`.
- 3단계 경고 톤 (normal → approaching → overflow).
- 취소 / 확인 버튼.

**F. 각인 연출**
- `AnimatedScale`(1.0 → 1.15 → 1.0) + primary 색상 플래시 200ms.
- 경로 A: 용병 상세 오버레이 스탯 행.
- 경로 B: 인벤토리 화면 SnackBar 1.5초.

**G. 방출 다이얼로그 확장**
- 기존 AlertDialog에 경고 박스 1개 삽입.
- 확인 버튼 라벨 조건부.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|---|---|---|
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` | HiveField 19~22 (`permanentStr` · `permanentIntelligence` · `permanentVit` · `permanentAgi`) 추가, 기존 `effective*` getter 4종 공식에 `+ permanent*` 삽입, `effectiveStrWith` 등 4종 공식에 `+ permanent*` 삽입 | FR-1, FR-2 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | HiveField 15~17 enum 3종 추가 | FR-5 |
| `band_of_mercenaries/lib/features/info/view/info_screen.dart` | `_showInventory` 상태 변수 + 4번째 ListTile + 분기 추가 | FR-6 진입점 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` | `_buildHeaderBar` 우측 `IconButton(정수 사용)` 추가, `_buildStatRow`에 permanent 괄호 표시, 각인 연출 상태 변수·애니메이션 | FR-8 경로 A, FR-10, FR-9 |
| `band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart` | 방출 다이얼로그에 정수 소멸 경고 섹션 추가 (라인 195-220) | FR-11 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | `dismiss` 메서드 내 totalPermanent > 0 시 `essenceLostOnRelease` 로그 기록 (라인 87-104) | FR-4 방출 경로 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 사망 판정 직후·용병 삭제 이전 시점에 totalPermanent > 0 시 `essenceLostOnDeath` 로그 기록 | FR-4 사망 경로 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|---|---|
| `band_of_mercenaries/lib/features/inventory/domain/essence_service.dart` | `EssenceService` 정적 서비스 + `EssenceDescriptor` / `EssencePreview` / `EssencePreviewLevel` / `EssenceApplyResult` 값 객체 |
| `band_of_mercenaries/lib/features/inventory/view/inventory_screen.dart` | 인벤토리 화면 (카테고리 필터 + 리스트) |
| `band_of_mercenaries/lib/features/inventory/view/inventory_item_card.dart` | 인벤토리 아이템 카드 위젯 |
| `band_of_mercenaries/lib/features/inventory/view/item_detail_sheet.dart` | 아이템 상세 바텀 시트 |
| `band_of_mercenaries/lib/features/inventory/view/essence_select_sheet.dart` | 경로 A 정수 선택 시트 (용병 상세에서 진입) |
| `band_of_mercenaries/lib/features/inventory/view/essence_target_sheet.dart` | 경로 B 용병 선택 시트 (인벤토리에서 진입) |
| `band_of_mercenaries/lib/features/inventory/view/essence_apply_preview_dialog.dart` | 정수 사용 프리뷰 팝업 (3단계 경고) |
| `band_of_mercenaries/test/features/inventory/domain/essence_service_test.dart` | `EssenceService.resolve` / `preview` / `apply` 단위 테스트 (티어별 상한·손실·실패 케이스) |
| `band_of_mercenaries/test/features/inventory/view/inventory_screen_test.dart` | 카테고리 필터 동작 위젯 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|---|---|
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` | hive_generator (HiveField 19~22 추가) |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | hive_generator (enum HiveField 15~17 추가) |
| `band_of_mercenaries/lib/features/inventory/domain/essence_service.dart` | freezed (`EssenceDescriptor` / `EssencePreview` / `EssenceApplyResult`) |

구현 완료 후 `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 필수.

### 3.4 관련 시스템

- **인벤토리 인프라 (산출물 1)**: `InventoryRepository.decrementQuantity` / `getAll` / `getByCategory`를 본 명세가 정수 소비·리스트 표시에 직접 사용.
- **장비 효과 (산출물 2)**: `Mercenary.effectiveStrWith` 등 4종 메서드 공식에 `permanent*` 항 추가 → `QuestCalculator.calculatePartyPower` · `DispatchDetailPage` 프리뷰에 자동 반영.
- **ItemEffectService (산출물 2)**: 본 명세는 소모품 카테고리를 `EssenceService`가 직접 파싱하므로 `ItemEffectService`에 정수 경로 추가 **불필요**. 개인 장비·용병단 장비 상세 팝업에서는 `ItemEffectService.resolve*`를 읽기 전용으로 호출하여 효과 요약을 표시.
- **활동 로그**: `ActivityLogType` 3종 추가 → 기존 활동 로그 UI 자동 반영 (타입별 필터 있다면 포함 여부 확인 — 현재 활동 로그 탭은 타입 무관 표시 추정).
- **정보 탭**: 기존 `세력 도감` / `명성` / `용병단 장비`에 `인벤토리` 4번째 진입점 추가. 탭 구조(6개)는 변경 없음.
- **Mercenary 모델 HiveField**: 18 → 22로 확장 (4개 증가). CLAUDE.md HiveField 순차 할당 규칙 준수.
- **본 명세에서 건드리지 않는 시스템**:
  - 방출 퇴직금 계산(기존 `wage × level` 유지).
  - 퀘스트 성공률·보상 공식 (permanent 가산은 `effectiveStrWith` 경유로 자동 반영).
  - data-generator 페이즈 3 (정수 20종 생성은 별도 파이프라인).

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **Hive 모델 필드 확장**: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart:75-76` (산출물 2의 HiveField(18) 추가 패턴) — 생성자에 nullable/기본값 파라미터 추가 + `.g.dart` 재생성.
- **Freezed 값 객체 + sealed**: `band_of_mercenaries/lib/features/inventory/domain/legendary_effect.dart` (산출물 2) — `LegendaryEffect` 5 variant 구조를 `EssenceApplyResult` 2 variant로 축소하여 재사용.
- **정적 서비스 패턴**: `band_of_mercenaries/lib/features/inventory/domain/item_effect_service.dart` — 모든 메서드 static, Repository 주입 방식. `EssenceService`도 동일 구조.
- **정보 탭 서브 화면 패턴**: `band_of_mercenaries/lib/features/info/view/info_screen.dart:18-56` — `_showX` 상태 변수 + 분기 우선순위. `_showInventory`를 `_showGuildEquipment` 뒤에 동일 패턴으로 추가.
- **바텀 시트 UX**: `band_of_mercenaries/lib/features/inventory/view/equipment_equip_sheet.dart` (산출물 2) — `showModalBottomSheet(isScrollControlled: true)` + 헤더 + 리스트 + 액션 패턴. `item_detail_sheet.dart` / `essence_select_sheet.dart` / `essence_target_sheet.dart` 모두 재사용.
- **AlertDialog + confirm 반환**: `band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart:195-220` — 취소/확인 버튼 + `Navigator.pop(ctx, true)` 패턴. `EssenceApplyPreviewDialog`에 차용.
- **활동 로그 기록**: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart:98-101` — `ref.read(activityLogProvider.notifier).addLog(message, type)`.
- **AnimatedScale 펄스 연출**: 프로젝트 내 `AnimatedSwitcher` / `AnimatedScale` 검색으로 기존 패턴 확인 후 200ms 펄스 적용.
- **tier 색상**: `band_of_mercenaries/lib/core/theme/app_theme.dart:57-66` `AppTheme.tierColor(int tier)` / `tierBgColor(int tier)`.

### 4.2 주의사항

- **HiveField 번호 순차 할당**: `Mercenary`의 신규 필드는 19~22 연속. 18(`legendaryDeathPreventionCooldownUntil`)은 산출물 2에서 점유했으므로 건너뛰지 말 것. CLAUDE.md "HiveField 번호 규칙" 준수.
- **기존 Hive 데이터 호환**: `permanent*` 필드는 `int` 기본 0. Hive는 누락된 int 필드를 0으로 자동 복원하므로 별도 마이그레이션 코드 불필요.
- **effective 공식 변경의 파급**: `effectiveStr` getter 본문을 수정하면 permanent가 0인 기존 용병의 표시값은 불변이지만, 자동화 테스트(`quest_calculator_test.dart`, `mercenary_stat_*_test.dart` 등)가 스냅샷 비교를 하는 경우 재확인. permanent=0인 상황에서는 수식 결과가 기존과 동일(= str × (1+levelBonus))이어야 함.
- **permanent 음수 방지**: `apply` 내부에서 `appliedGain >= 0` 항상 유지. 방어적으로 `max(appliedGain, 0)` 적용.
- **상한 변경(승급 후)**: 현재 spec은 용병 `Job.tier` 기준 cap만 판정. M6 승급 시 tier가 바뀌면 자동으로 새 cap 반영(permanent 값 유지). 승급 시점의 permanent "재검증"은 본 명세 범위 외.
- **사망 경로 로그 기록 타이밍**: `removeDead` **이전**에 기록해야 `merc.name` · `totalPermanent` 접근 가능. 호출 순서 역전 주의.
- **방출 다이얼로그 확인 버튼 라벨**: `totalPermanent > 0`일 때 기존 `[방출]` 대신 `[손실 감수하고 방출]`. UI 버튼 폭이 기존 다이얼로그에서 넘치지 않는지 확인 (테스트 시 모바일 해상도 430px).
- **`avoid_print` 린트**: `EssenceService` 내부 debug 출력은 `debugPrint` 사용 (fromJson schema mismatch 경고 등).
- **`ConstrainedBox(maxWidth: 430)` 제약**: 인벤토리 화면 · 프리뷰 팝업 모두 `_MobileFrame` 내부에서 렌더. Navigator.push 금지, 상태 기반 전환만.
- **한국어 코멘트**: 코드 주석·사용자 메시지는 한국어 기본 (CLAUDE.md 언어 설정).
- **effect_json 스키마 관대성**: `EssenceService.resolve`는 스키마 불일치 시 debugPrint 경고 + null 반환(fail-soft). 운영 배포 전 data-generator 검증으로 방지.

### 4.3 엣지 케이스

- **정수 아이템이 인벤토리에서 삭제된 상태에서 프리뷰 확인**: 경로 B 용병 선택 → 프리뷰 팝업 표시 중 다른 경로에서 동일 행이 삭제되면 `apply` 시 `not_found` 실패. SnackBar 안내 + 팝업 자동 닫기.
- **잔량 완전 도달 용병에 정수 수량 0개 시도**: `InventoryRepository.decrementQuantity`가 이미 수량 0을 방어하지만, 본 명세에서도 `apply` 진입 전 `inventoryRow.quantity > 0` 체크.
- **effective 공식 `((str + permanent + bonus) × (1 + levelBonus)).round()` 오버플로우**: Dart int는 64비트 — 실질 상한 T5 base 50 + permanent 120 + equipment 10 = 180 × 1.4 = 252. 오버플로우 우려 없음.
- **permanent 부분 적용 후 UI 갱신 지연**: `mercenaryListProvider.refresh()` 호출이 필수. 누락 시 용병 상세 오버레이의 스탯은 업데이트되지만 리스트 화면 스탯이 stale.
- **용병 선택 시트에서 상한 잔량 = 0인 전원**: 모든 용병 비활성화 → "모든 용병이 해당 스탯 상한에 도달했습니다" 안내 배너 표시. 팝업 자동 닫기 옵션 미제공(플레이어가 수동 닫기).
- **정수 아이템 수량 > 1인 상태에서 연속 사용**: 매 회 독립 `apply` 호출. 연속 사용 시 각인 연출이 겹치지 않도록 연출 1회씩 순차 재생. (UI 상세는 구현 시점 판단.)
- **경로 A 용병 상세 아이콘 탭 시 보유 정수 0개**: 정수 선택 시트 빈 상태 ("보유한 정수가 없습니다") 표시.
- **빠른 연타로 `apply` 중복 호출**: 버튼 `onPressed`를 `setState`로 잠금(`_applying` 플래그) 또는 `AbsorbPointer`로 1회 클릭 제한. `EssenceService.apply`는 await 되므로 동기 재호출 방지.
- **용병 사망 처리 중 Hive 박스 lock**: `quest_completion_service.dart`에서 사망 로그 기록 → `removeDead` 순서 준수. `await merc.save()`는 로그 기록 시 불필요 (로그는 별도 박스).

### 4.4 구현 힌트

- **진입점 (정수 사용)**:
  - 경로 A: 용병 카드 탭 → `selectedMercenaryIdProvider` 설정 → `MercenaryDetailOverlay` → 헤더바 `IconButton(auto_awesome)` 탭 → `EssenceSelectSheet` → `[사용]` → `EssenceApplyPreviewDialog` → 확정 → `EssenceService.apply`.
  - 경로 B: 정보 탭 → `인벤토리` → `InventoryScreen` → 카테고리 `소모품` → 정수 카드 탭 → `ItemDetailSheet` → `[사용]` → `EssenceTargetSheet` → 용병 탭 → `EssenceApplyPreviewDialog` → 확정 → `EssenceService.apply`.

- **데이터 흐름 (정수 소비)**:
  ```
  ItemData(Supabase → StaticGameData.items)
    ↓ EssenceService.resolve
  EssenceDescriptor{statKey, gain, tier}
    ↓ EssenceService.preview(mercenary, descriptor, cap)
  EssencePreview{currentPermanent, appliedGain, lossAmount, warningLevel}
    ↓ UI 프리뷰 → 확정
  EssenceService.apply
    ├→ mercenary.permanent{StatKey} += appliedGain → merc.save()
    ├→ inventoryRepo.decrementQuantity(rowId) (0이면 자동 삭제)
    └→ activityLog.addLog(essenceApplied)
  ```

- **데이터 흐름 (permanent → effective)**:
  ```
  Mercenary.permanentStr (+ permanentInt / Vit / Agi) 저장
    ↓ Mercenary.effectiveStrWith(bonus)
  ((str + permanentStr + bonus.str) × (1 + levelBonus)).round() × fatigueMod
    ↓ QuestCalculator.calculatePartyPower(mercs, questType, equipmentBonuses)
  partyPower → calculateSuccessRate → clamp(5, 95)
  ```

- **사망 경로 로그 진입점**: `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart`의 사망 판정 분기(전설 ⑤ 처리 이후, `MercenaryRepository.removeDead` 호출 이전). 변수 접근:
  ```dart
  final total = merc.permanentStr + merc.permanentIntelligence + merc.permanentVit + merc.permanentAgi;
  if (total > 0) {
    logNotifier.addLog('${merc.name}이(가) 사망했다. 투입 정수 누적 +$total 소실', ActivityLogType.essenceLostOnDeath);
  }
  await mercRepo.removeDead(merc.id);
  ```

- **방출 경로 로그 진입점**: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart:98-101`에서 기존 `ActivityLogType.mercenaryDismiss` 대신 조건 분기:
  ```dart
  final total = merc.permanentStr + merc.permanentIntelligence + merc.permanentVit + merc.permanentAgi;
  final logType = total > 0 ? ActivityLogType.essenceLostOnRelease : ActivityLogType.mercenaryDismiss;
  final message = total > 0
    ? '용병 "${merc.name}" 방출 (퇴직금: ${severancePay}G, 투입 정수 +$total 소실)'
    : '용병 "${merc.name}" 방출 (퇴직금: ${severancePay}G)';
  ref.read(activityLogProvider.notifier).addLog(message, logType);
  ```

- **참조 구현**:
  - HiveField 추가: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart:75-76, 97` (HiveField 18 추가 패턴 직전 커밋).
  - freezed sealed 2 variant: `band_of_mercenaries/lib/core/models/passive_effect.dart` 단순화 버전.
  - 정적 서비스 + Repository 주입: `band_of_mercenaries/lib/features/inventory/domain/item_effect_service.dart:100-118` (`aggregateMercenaryEquipment`).
  - 정보 탭 서브 화면 추가: `band_of_mercenaries/lib/features/info/view/info_screen.dart:128-150` (guild equipment ListTile 패턴).
  - 바텀 시트: `showModalBottomSheet` 기존 사용처 (`band_of_mercenaries/lib/features/quest/view/success_rate_breakdown_sheet.dart` 등).
  - AlertDialog confirm 반환: `band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart:195-220`.
  - 활동 로그 provider: `band_of_mercenaries/lib/core/domain/activity_log_provider.dart`.

- **확장 지점 (후속 명세용, 본 명세 범위 외)**:
  - 다중 정수 일괄 소비 (M2b 또는 이후) — `EssenceService.applyBatch(List<InventoryItem>)`.
  - M6 승급 재료 재사용 — `EssenceService.consumeForPromotion(...)` (permanent 값 유지 + tier cap 확장).
  - 정수 드랍 (M2b) — 엘리트 퀘스트 완료 시 `addItem(essenceId)` 자동 호출.
  - 인벤토리 화면 정렬/검색 고도화 (탭 진입 빈도 증가 시).
  - 행동 지표 캐싱(현재는 재계산, 용병 수 확장 시 성능 요구).

---

## 5. 기획 확인 사항

- **[Q-1] effective 공식에서 permanent 항의 레벨 증폭 여부**
  - 질문: `essence_system.md` 6항은 `effectiveStr = (baseStr × (1 + levelBonus) + permanentStr) × 피로디버프` (permanent는 비증폭 가산)로 명시했으나, 산출물 2(`equipment_effects.md`)의 장비 공식은 `(base + equipment) × (1 + levelBonus)` (equipment는 증폭)로 이미 구현됨. 본 명세의 요구("`(base + permanent + equipment) × (1 + levelBonus) × fatigueMod`")는 permanent를 equipment와 동일하게 증폭 처리.
  - 결정: **요구사항대로 증폭 적용** — 세 항 모두 `(1 + levelBonus)` 증폭. 장비/정수 공식 일관성 우선.
  - 근거: (1) 산출물 2가 equipment를 증폭으로 이미 구현하여 공식 재작성 시 기존 테스트 파급. (2) 플레이어 체감상 "레벨 오르면 모든 수치가 함께 오른다"가 직관적. (3) 밸런스 문서(`essence_inflation.md`)의 시뮬레이션(40h 시점 clamp 95% 도달 등)은 effective 증가량 자체 기준이므로 증폭/비증폭 구분이 체감에 결정적 영향을 주지 않음(시뮬레이션 재계산 시 약간의 완화 가능).
  - 필요 시 재검토: 기획자가 "정수는 비증폭, 장비만 증폭" 구분을 원하면 `effectiveStrWith` 재설계 필요.

- **[Q-2] 인벤토리 화면 진입 위치**
  - 질문: 인벤토리 진입점을 (a) 정보 탭 4번째 ListTile, (b) 홈 탭 상단 카드, (c) 신규 7번째 탭 중 어디에 둘지.
  - 결정: **(a) 정보 탭 4번째 ListTile**. 기존 `_showCodex` / `_showRank` / `_showGuildEquipment` 패턴 재사용.
  - 근거: (1) 구현 복잡도 최소. (2) 6탭 구조 불변. (3) 인벤토리 접근 빈도는 "정수 획득 시 즉시 사용" 시점에 집중되며, M2b에서 드랍 알림 토스트 + "인벤토리 보기" 딥링크 추가 시 접근성 보완 가능. (4) 용병단 장비가 이미 정보 탭에 있어 "정적 자원 · 인벤토리 관리" 섹션으로 통일.
  - 필요 시 재검토: 플레이어 피드백에 "정수 사용이 번거롭다" 의견 발생 시 홈 탭 카드 또는 bottom sheet 단축 진입점 추가.

- **[Q-3] 정수 사용 진입 경로 2종 모두 필수 여부**
  - 질문: 기획서 4-1은 Pull(용병 상세→정수 선택)과 Push(인벤토리→용병 선택) 양방향 모두 지원 명시. 구현 복잡도 관점에서 둘 중 하나만 M2a에 담고 나머지는 후속에 둘 수 있음.
  - 결정: **양방향 모두 M2a 필수**. 기획서 4-1 원문 준수.
  - 근거: (1) "자유 사용" 철학이 두 경로 모두를 전제. (2) 경로 B(인벤토리 → 용병 선택)가 사실 "이 정수를 누구에게 쓸까" 비교 선택 UX의 핵심 → 제외 시 플레이어 의사결정 부담. (3) 공통 `EssenceApplyPreviewDialog`로 하류 재사용하므로 추가 구현 비용은 용병 선택 시트 1개 추가 수준.
  - 필요 시 재검토: 일정 긴급 시 경로 A만 남기고 경로 B를 "인벤토리 → 아이템 상세 → 안내 텍스트(용병 상세에서 사용)"로 축소 가능.

- **[Q-4] 용병 선택 시트에서 사망·파견·부상 용병 노출**
  - 질문: 정수 사용 대상에 사망/파견/부상/피로 상태 용병 포함 여부.
  - 결정: **사망 제외, 그 외 모두 포함**. 부상·피로·파견 중 용병도 정수 사용 가능(정수는 전투 외 효과).
  - 근거: (1) 기획서 4-3 "사용 버튼 비활성"은 상한 도달에만 적용, 상태에 따른 제한 없음. (2) 사망 용병은 Hive에서 제거되므로 자연히 리스트에서 빠짐. (3) 파견 중 용병에게 정수를 먹여 다음 파견 시 강화된 상태로 복귀하는 전략 보장.
  - 필요 시 재검토: 파견 중 용병에 정수 먹이는 것을 기획자가 이상하게 여기면 파견 용병 제외.

- **[Q-5] 각인 연출 수준**
  - 질문: 소모 연출의 구현 강도 (단순 SnackBar ~ 복잡한 풀스크린 연출).
  - 결정: **최소 수준** — 경로 A는 스탯 행 200ms 펄스, 경로 B는 SnackBar 1.5초.
  - 근거: (1) M2a는 인프라 검증 마일스톤 → UX 연출 최소. (2) 플레이어가 정수 희귀성을 체감하는 것은 "프리뷰 팝업에서 상한 경고 보는 순간"이 주된 긴장감. (3) 풀스크린 연출은 M2b~M4 폴리시 시점 추가 가능.
  - 필요 시 재검토: 기획자가 "각인" 서사 강조를 원하면 `Stack` + `BlurFilter` + 파티클 애니메이션 확장.

- **[Q-6] 방출 다이얼로그 경고 문구 톤**
  - 질문: `totalPermanent > 0` 시 경고 문구 색상·아이콘 수준.
  - 결정: **연한 붉은색 배경 박스 + ⚠ 아이콘**. 버튼 라벨은 `[손실 감수하고 방출]`.
  - 근거: (1) 사망 리스크와 동일 레벨의 경고 표시. (2) "돌이킬 수 없는 손실" 경고는 붉은색이 관례. (3) 버튼 라벨 전환이 "정말 할 거냐" 재확인 효과.
  - 필요 시 재검토: 과도한 경고라는 판단 시 노란색 톤으로 완화.

- **[Q-7] 상한 `approaching` 경고 기준**
  - 질문: "다음 사용 시 상한 초과" 경고(`approaching`)의 트리거 조건.
  - 결정: **`cap - newPermanent < gain`** (이번 사용 후 잔량이 다음 1회 효과보다 적음).
  - 근거: 플레이어가 "아 다음 건 쓰면 손실이구나"를 선제 인지하도록. 예: T3 용병 STR permanent +36, T3 정수 +4 사용 후 +40(cap 도달), 다음 T3 정수 1개 = 전액 손실 → approaching 표시.
  - 필요 시 재검토: 조건 완화(`cap - newPermanent < gain × 2` 등) 요청 시 조정.

- **[Q-8] 정수 데이터 매트릭스 불완전 상태에서의 동작**
  - 질문: data-generator가 정수 20종 중 일부만 Supabase에 적재된 상태로 본 UI 구현이 먼저 배포되는 경우.
  - 결정: **존재하지 않는 아이템은 인벤토리에 등장하지 않으므로 자연 무해**. `EssenceService.resolve`는 schema 체크로 `null` 반환, UI는 해당 행 상세에 "효과 데이터 누락" 표시. 에러 다이얼로그 없음.
  - 근거: operation-bom 수동 지급 경로로 신중 적재되므로 스키마 완전 일치가 사실상 보장. 본 명세는 단일 지점 예외 처리에 그침.
  - 필요 시 재검토: 초기 QA에서 스키마 누락 빈발 시 UI `overlay` 경고.

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|---|---|---|
| 수정/생성 파일 | 수정 7 + 생성 7(Flutter) + 테스트 2 = **16개** | 대규모 |
| 영향 시스템 | core/models(ActivityLog), features/mercenary(model+view+provider), features/inventory(domain+view), features/quest/domain(사망 경로), features/info/view (**5개**) | 대규모 |
| 신규 클래스 | EssenceService, EssenceDescriptor, EssencePreview, EssenceApplyResult, InventoryScreen, InventoryItemCard, ItemDetailSheet, EssenceSelectSheet, EssenceTargetSheet, EssenceApplyPreviewDialog (**10개 이상**) | 대규모 |
| 데이터 모델 | Mercenary HiveField 4개 추가 + ActivityLogType enum 3개 추가 + freezed 신규 3종 + sealed 1종 | 대규모 |
| UI 작업 | 인벤토리 화면 신설 + 바텀 시트 3종 + 프리뷰 다이얼로그 + 방출 다이얼로그 확장 + 용병 상세 버튼 추가 | 대규모 |
| 기존 시스템 변경 | Mercenary effective 공식 8종 재작성 + 사망 경로 로그 삽입 + 방출 provider 로그 분기 + 용병 상세 헤더바 | 대규모 |

**추천: implement-agent (6/6점)**
- 신규 서비스·UI 다수 + 모델 확장 + 기존 core 경로(사망·방출) 변경 + freezed/hive 코드 생성이 얽혀 있어, 파이프라인(planner→coder→verifier)의 단계별 검증·build_runner 관리가 필수.

---

구현을 진행하려면 아래 명령어를 실행해주세요:

/implement-agent @Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md  ← 추천 (파이프라인)
/implement-spec @Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md  (올인원)
