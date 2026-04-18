# ReputationService 랭크 보너스 + 명성 UI 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260417_rank_bonuses.md` (등급별 보너스 체계)
> - `Docs/balance-design/20260417_rank_bonuses_values.md` (수치 확정, C1~C3·M1)
> 선행 명세:
> - `Docs/spec/[spec]20260418_passive-bonus-service.md` — `ranks.bonus_json` 컬럼·E 임계값 300·14세력 UPDATE 마이그레이션 **이미 포함**. 본 명세는 **데이터/스키마 중복 작업 없음**, 로직 연결만 담당
> - `Docs/spec/[spec]20260418_dispatch-synergy.md` — `SuccessRateBreakdown.rankBonus` 필드 이미 설계됨
> 작성일: 2026-04-18
> 마일스톤: M1 페이즈 4 (4/4, 마지막)
> UI 목업: 사용 안 함 (기존 패턴 재사용 — FactionCodexScreen / 조사 완료 팝업 / investigationCompletedProvider 패턴 준수)

## 1. 개요

`ReputationService`에 `getRankChain()` 등 랭크 체인 조회 API를 추가하여 `PassiveBonusService.collect()`가 F→현재 랭크까지 누적 effects를 수집할 수 있도록 연결한다. 평판 변경 시점에 **랭크업을 감지**하여 `reputationRankUpProvider`로 전역 알림 → `app.dart`에서 전체화면 축하 오버레이 표시 + `ActivityLog` 기록. 홈 화면 기존 명성 배지에 보너스 요약 팝업 추가. 정보 탭에 **RankInfoScreen** 신규 진입점 추가 (F~A 타임라인 + 등급별 보너스 프리뷰). 랭크 하향 로직은 stub (M1은 상향만).

## 2. 요구사항

### 2.1 기능 요구사항

#### FR-1: `ReputationService` 확장

- 파일: `band_of_mercenaries/lib/core/domain/reputation_service.dart` (현재 30행)
- 기존 `getCurrentRank` / `getNextRank` / `calculateQuestReputation` / `getMaxUnlockedTier` / `isRegionAccessible` 유지
- 신규 메서드:

```dart
/// F부터 현재 도달한 랭크까지의 리스트 반환 (순서 보장).
/// PassiveBonusService.collect()에 전달해 누적 bonus_json을 수집하기 위함.
static List<Rank> getRankChain(int reputation, List<Rank> ranks) {
  final sorted = [...ranks]..sort((a, b) => a.requiredReputation.compareTo(b.requiredReputation));
  final result = <Rank>[];
  for (final rank in sorted) {
    if (reputation >= rank.requiredReputation) {
      result.add(rank);
    } else {
      break;
    }
  }
  return result;
}

/// 현재 랭크의 인덱스(F=0, E=1, D=2, C=3, B=4, A=5).
/// 랭크업 감지용 비교 키.
static int getRankLevel(int reputation, List<Rank> ranks) {
  final chain = getRankChain(reputation, ranks);
  return chain.length - 1;  // 빈 체인 방어: F가 required_reputation=0이므로 최소 1개 보장
}
```

**엣지 케이스:** ranks 리스트가 비었거나 F가 누락되어도 `getRankChain()`은 빈 리스트 반환. `getRankLevel()`은 −1 반환 → UI 렌더 방어 로직 필요.

#### FR-2: `PassiveBonusService.collect()` rankChain 연결

- P1 명세의 `collect()` 시그니처는 이미 `rankChain` 파라미터를 받음
- **호출측**(`QuestCompletionService`, `RecruitmentService` 등 PassiveBonusService 호출부)에서 rankChain을 구성:

```dart
final ranks = ref.read(staticDataProvider).ranks;  // List<Rank>
final currentReputation = ref.read(userDataProvider).reputation;
final rankChain = ReputationService.getRankChain(currentReputation, ranks);
final currentRank = ReputationService.getCurrentRank(currentReputation, ranks);
final joinedFactions = /* FactionStateRepository + staticData.factions */;

final effects = PassiveBonusService.collect(
  joinedFactions: joinedFactions,
  currentRank: currentRank,
  rankChain: rankChain,
);
```

**호출부 확정 위치:**
- `QuestCompletionService.calculate()` — 퀘스트 완료 보상/성공률 계산 시
- `QuestCalculator` 관련 UI 미리보기 (DispatchDetailPage)
- `RecruitmentService.effectivePaidCost()` 계산 시 (`recruit_screen.dart`)
- `ConstructionService` 시설 계산 시
- `IdleRewardService.calculateReward()` (`main.dart` 방치 복귀 시)
- `TravelEventService` (이동 이벤트 발생 시)
- **각 호출부에 공통 헬퍼 `PassiveBonusContext` 도입 권장** (FR-3)

#### FR-3: `PassiveBonusContext` 유틸 (선택 권장)

- 새 파일: `band_of_mercenaries/lib/core/domain/passive_bonus_context.dart`
- `Ref`를 받아 joinedFactions + rankChain + currentRank를 조합하여 `CollectedEffects`까지 반환하는 편의 함수:

```dart
class PassiveBonusContext {
  /// 현재 플레이어 상태에서 CollectedEffects를 수집한다.
  /// 호출측에서 Ref/WidgetRef를 주입. 핫패스(퀘스트 완료·UI 렌더)에서 재사용.
  static CollectedEffects collectFor(WidgetRef ref) {
    final staticData = ref.read(staticDataProvider).valueOrNull;
    if (staticData == null) return CollectedEffects.empty();

    final userData = ref.read(userDataProvider);
    final factionStateRepo = ref.read(factionStateRepositoryProvider);
    final joinedIds = factionStateRepo.getJoinedFactionIds();
    final joinedFactions = staticData.factions
        .where((f) => joinedIds.contains(f.id))
        .toList();

    final rankChain = ReputationService.getRankChain(userData.reputation, staticData.ranks);
    final currentRank = ReputationService.getCurrentRank(userData.reputation, staticData.ranks);

    return PassiveBonusService.collect(
      joinedFactions: joinedFactions,
      currentRank: currentRank,
      rankChain: rankChain,
    );
  }

  /// StateNotifier 등 Ref 없이 Reader만 있는 경우용.
  static CollectedEffects collectForRead(Reader read) { /* ... */ }
}
```

Riverpod `Ref`/`WidgetRef` 타입 호환 주의. 내부에서 `ref.read` 사용(감시 X).

#### FR-4: `UserDataNotifier.addReputation()` 랭크업 감지

- 파일: `band_of_mercenaries/lib/core/providers/game_state_provider.dart` (기존 `addReputation`)
- 현재는 reputation을 증가시키기만 함. **본 명세에서 랭크업 이벤트 감지 추가**:

```dart
Future<void> addReputation(int amount) async {
  if (amount == 0) return;

  final ranks = _ref.read(staticDataProvider).valueOrNull?.ranks ?? [];
  final oldLevel = ReputationService.getRankLevel(state.reputation, ranks);

  final newReputation = (state.reputation + amount).clamp(0, 9999999);
  state = state.copyWith(reputation: newReputation);
  await _saveUserData();

  if (ranks.isEmpty) return;
  final newLevel = ReputationService.getRankLevel(newReputation, ranks);

  if (newLevel > oldLevel) {
    // 랭크업 이벤트 발행
    final oldRank = ranks[oldLevel];
    final newRank = ranks[newLevel];
    _ref.read(reputationRankUpProvider.notifier).state =
        RankUpEvent(from: oldRank, to: newRank);

    // 활동 로그 기록
    _ref.read(activityLogProvider.notifier).addLog(
      '명성 상승: ${oldRank.grade} → ${newRank.grade} (${newRank.name})',
      ActivityLogType.reputationRankUp,
    );
  } else if (newLevel < oldLevel) {
    // 랭크 하향 (M2a 이후 발생 가능, 현재 로직만 준비 — FR-9)
    // ...
  }
}
```

**증가 후 결과를 _ref.read(reputationRankUpProvider.notifier)에 publish** → `app.dart`의 `ref.listen`이 감지하여 오버레이 표시.

#### FR-5: `reputationRankUpProvider` 신설

- 새 파일: `band_of_mercenaries/lib/core/providers/reputation_rank_up_provider.dart`

```dart
class RankUpEvent {
  final Rank from;
  final Rank to;
  final List<PassiveEffect> newEffects;  // to.bonus_json에서 파싱한 효과 리스트

  const RankUpEvent({required this.from, required this.to, required this.newEffects});
}

final reputationRankUpProvider = StateProvider<RankUpEvent?>((ref) => null);
```

- 기존 `investigationCompletedProvider`, `constructionCompletedProvider` 패턴 정확히 재현
- 초기값 null. 이벤트 발생 시 instance 저장. 오버레이 닫힐 때 null로 리셋

**`newEffects` 채우기:** `UserDataNotifier.addReputation()`에서 `newRank.bonusJson`을 `PassiveEffect.fromJson`으로 파싱해 리스트 구성 후 RankUpEvent에 포함.

#### FR-6: 랭크업 축하 오버레이

- 새 파일: `band_of_mercenaries/lib/features/home/view/rank_up_overlay.dart`
- 위젯: `RankUpOverlay(RankUpEvent event, VoidCallback onDismiss)`
- 기존 패턴 재사용: `app.dart`에서 `ref.listen(reputationRankUpProvider, (prev, next) { if (next != null) showDialog(...) })`
- **구현 방식:** `showDialog` 또는 전역 오버레이 — 기존 `investigationCompletedProvider` 처리 방식과 동일 (관련 주석 본 명세 4.1)

**오버레이 내용 (기획서 섹션 6.A):**
```
┌───────────────────────────────┐
│  🎖️                           │
│  명성 상승!                    │
│                               │
│  E → D                        │
│  인정된 용병단                 │
│                               │
│  신규 보너스                   │
│  • 전 퀘스트 보상 +3%          │
│  • 부상 회복 시간 -10%         │
│                               │
│       [확인]                   │
└───────────────────────────────┘
```

- 제목 + from→to 등급 표시 + 신규 보너스 목록 (PassiveBonusFormatter 사용)
- 확인 버튼 탭 → `reputationRankUpProvider.notifier.state = null`로 리셋 + 닫기
- `RankUpEvent.newEffects`를 `PassiveBonusFormatter.format(effect)`로 한국어 변환
- 상태 기반: `showDialog(barrierDismissible: false)` 또는 Overlay entry. **Navigator.push 금지**

#### FR-7: 홈 화면 프로필 배지 + 보너스 요약 팝업

- 파일: `band_of_mercenaries/lib/features/home/view/home_screen.dart` (명성/등급 카드 L227-296 주변)
- **현재:** 등급 배지 + LinearProgressIndicator가 이미 있음 (Explore 결과)
- **변경:**
  - 기존 등급 배지를 `GestureDetector` 또는 `InkWell`로 래핑 → 탭 이벤트 추가
  - 탭 시 `showModalBottomSheet` → `RankBonusSummarySheet` 위젯 표시

**`RankBonusSummarySheet` 신규 위젯 (`features/home/view/rank_bonus_summary_sheet.dart`):**

```
명성 D — 인정된 용병단

현재 활성 보너스
  • 전 퀘스트 보상 +3%  (D)
  • 부상 회복 시간 -10%  (D)
  • 모집 비용 -10%       (E)

다음 등급까지: 명성 348 / 2,000

[확인]
```

- **누적 보너스 표시:** `RankChain` 전체 effects를 `PassiveBonusFormatter`로 변환
- **다음 등급 진행도:** `ReputationService.getNextRank()` 결과로 계산
- Material 3 bottom sheet 기본 연출
- 최고 랭크(A) 도달 시 "다음 등급까지" 대신 "최고 등급 도달" 표시

#### FR-8: 정보 탭 "명성" 진입점 + `RankInfoScreen`

- 파일 수정: `band_of_mercenaries/lib/features/info/view/info_screen.dart`
  - 기존 "세력 도감" ListTile 옆/아래에 "**명성**" ListTile 추가
  - 상태 변수 신규: `bool _showRank = false`
  - `onTap` → `setState(() => _showRank = true)` + 전용 화면 렌더링 (기존 `_showCodex` 패턴 정확히 동일)

- 새 파일: `band_of_mercenaries/lib/features/info/view/rank_info_screen.dart`

**화면 구조 (기획서 섹션 6.C):**

```
상단: 현재 랭크 배지 + 평판 수치 + 프로그레스 바
   [D | 인정된 용병단]
   평판: 348 / 2,000 (다음 C)
   ████████░░░░░░░░░░  17%

중단: F~A 타임라인 (가로 또는 세로)
   [F]─[E]─[D]●─[C]○─[B]○─[A]○
   ● 도달 / ○ 미도달
   현재 위치 강조(primary color)

하단: 등급 탭 시 선택 등급의 보너스 프리뷰
   [E] 등록된 용병단
     • 모집 비용 -10%  ✓ 활성

   [D] 인정된 용병단 (현재)
     • 전 퀘스트 보상 +3%   ✓ 활성
     • 부상 회복 시간 -10%  ✓ 활성

   [C] 숙련된 용병단 (잠금)
     • 전 퀘스트 성공률 +3%
     • 파견 슬롯 +1
```

- **상태 변수**: `_selectedRankGrade` (String?, 클릭된 등급 확인용)
- **화면 전환:** `InfoScreen` 내 `_showRank` 토글로 상태 기반 렌더링 (Navigator.push 금지, CLAUDE.md 준수)
- 뒤로 가기 버튼 탭 → `setState(() => _showRank = false)`

#### FR-9: 랭크 하향 처리 (stub)

M1 범위에서는 **상향만 실제 발생** (reputation은 단조 증가). 하지만 로직은 대칭으로 준비:

```dart
// UserDataNotifier.addReputation() 내 (FR-4)
if (newLevel < oldLevel) {
  final oldRank = ranks[oldLevel];
  final newRank = ranks[newLevel];
  _ref.read(activityLogProvider.notifier).addLog(
    '명성 하락: ${oldRank.grade} → ${newRank.grade}',
    ActivityLogType.reputationRankDown,  // 신규 enum 필요
  );
  // UI 알림은 M2a 이후에 추가 (본 명세 범위 밖)
}
```

- `ActivityLogType.reputationRankDown` enum 값 추가 (사용 빈도 0, 안전장치)
- 축하 오버레이는 발생시키지 않음 (하향은 축하할 일 아님)
- **reputation 감소 발생 경로는 M2a 이후**. M1은 로직만 준비

#### FR-10: `ActivityLog` 랭크업 이벤트 타입

- 파일: `band_of_mercenaries/lib/core/domain/activity_log_model.dart`
- 현재 `ActivityLogType` enum에 신규 값 추가:

```dart
enum ActivityLogType {
  // 기존: questResult, mercenaryStatus, levelUp, traitAcquired, facilityUpgrade, investigationSuccess 등
  // 신규:
  @HiveField(N)                 // 다음 가용 HiveField 번호
  reputationRankUp,
  @HiveField(N+1)
  reputationRankDown,          // 하향용(stub)
}
```

- HiveField 번호는 기존 enum 값의 다음 번호 사용 (실제 번호는 구현 시 현재 파일 확인)
- 기존 `addLog(message, type)` 인터페이스 변경 없음

#### FR-11: 파견 화면 성공률 분해에 명성 보너스 항목

- 파일: P3 명세의 `SuccessRateBreakdown` 값 객체에 이미 `rankBonus` 필드 있음
- 본 명세는 **값을 채우는 경로**만 확보:
  - `QuestCalculator.calculateSuccessRateBreakdown()` 호출 시 `CollectedEffects`에서 rank 출처 effects만 분리하여 `rankBonus` 합산
  - **rank 출처 구분 방법:** `PassiveBonusService.collect()` 반환 값을 세력 출처(faction) + 명성 출처(rank)로 분리해서 반환하도록 **P1 API 확장** 필요 → Q-1 참조
- 또는 단순화: `rankBonus`를 `ReputationService.sumRankEffectsSuccessRateBonus(rankChain, questTypeId)`로 별도 계산

**권장: 별도 계산**. `rankChain`에서 직접 `quest_success_rate_bonus all` 값만 합산. 코드:

```dart
// ReputationService 확장
static double sumRankSuccessRateBonus(List<Rank> rankChain, String questTypeId) {
  double sum = 0.0;
  for (final rank in rankChain) {
    final effects = parseBonusJson(rank.bonusJson);  // List<PassiveEffect>
    for (final e in effects) {
      if (e is SuccessRateEffect && (e.questType == 'all' || e.questType == questTypeId)) {
        sum += e.value;
      }
    }
  }
  return sum;
}
```

### 2.2 데이터 요구사항

#### 2.2.1 Supabase 스키마

**신규 작업 없음.** `ranks.bonus_json`·E 임계값 300·6개 등급 보너스 데이터는 **P1 명세 `20260418_ranks_bonus_json.sql`에 이미 포함**. 본 명세는 **로직 연결만** 담당.

#### 2.2.2 Flutter 데이터 모델

**수정 파일:**
- `band_of_mercenaries/lib/core/domain/activity_log_model.dart` — `ActivityLogType` enum에 `reputationRankUp` / `reputationRankDown` 2개 값 추가 (FR-10)
- `band_of_mercenaries/lib/core/domain/reputation_service.dart` — `getRankChain` / `getRankLevel` / `sumRankSuccessRateBonus` 3개 static 메서드 추가 (FR-1, FR-11)
- `band_of_mercenaries/lib/core/providers/game_state_provider.dart` — `UserDataNotifier.addReputation()` 에 랭크업 감지 로직 추가 (FR-4)

**신규 파일:**
- `band_of_mercenaries/lib/core/providers/reputation_rank_up_provider.dart` — StateProvider<RankUpEvent?> (FR-5)
- `band_of_mercenaries/lib/core/domain/passive_bonus_context.dart` — 공통 헬퍼 (FR-3)
- `band_of_mercenaries/lib/features/home/view/rank_up_overlay.dart` — 축하 오버레이 (FR-6)
- `band_of_mercenaries/lib/features/home/view/rank_bonus_summary_sheet.dart` — 홈 배지 탭 시 bottom sheet (FR-7)
- `band_of_mercenaries/lib/features/info/view/rank_info_screen.dart` — 정보 탭 명성 화면 (FR-8)

**Hive 박스 변경:** `activityLogs` 박스의 `ActivityLogType` enum이 확장되나 **typeId 변경 없음**. HiveField 번호만 증가. 기존 로그 호환.

### 2.3 UI 요구사항

#### 2.3.1 랭크업 축하 오버레이 (신규 위젯)

- **진입 조건:** `reputationRankUpProvider`가 non-null 이벤트를 가짐 → `app.dart`에서 `ref.listen` 감지
- **위젯 계층:** `AlertDialog` 또는 `Dialog > Container > Column > [아이콘, 제목, 등급전환 Text, Divider, 보너스 ListView, 확인 Button]`
- **상태 변수:** 없음. Stateless 위젯. RankUpEvent 수신으로 동작
- **화면 전환:** `showDialog(barrierDismissible: false)`. Navigator.push 없음. 닫기는 provider를 null로 리셋
- **연출:** Material 3 fade-in 기본. 추가 애니메이션 없음 (M1 범위)

#### 2.3.2 홈 화면 명성 배지 탭 가능화

- **진입 조건:** 홈 화면 상단 등급 카드 탭
- **위젯 계층:** 기존 등급 카드 `Card > Column`을 `GestureDetector` 또는 `InkWell`로 래핑
- **상태 변수:** 없음. 탭 핸들러에서 `showModalBottomSheet` 호출
- **화면 전환:** `showModalBottomSheet` (허용). Dismissible = true
- **연출:** 기본 슬라이드업

#### 2.3.3 `RankBonusSummarySheet` 위젯

- **위젯 계층:** `SafeArea > Column > [제목 Row, Divider, 보너스 ListView.builder, 진행도 LinearProgressIndicator, 진행도 Text, 닫기 버튼]`
- **상태 변수:** 없음. `ref.watch(userDataProvider).reputation` + `staticDataProvider`로 데이터 조회
- **화면 전환:** bottom sheet dispose 시 자동 닫힘

#### 2.3.4 `RankInfoScreen` (신규 화면)

- **진입 조건:** `InfoScreen._showRank = true` (ListTile "명성" 탭 시 설정)
- **위젯 계층:** `Column > [뒤로가기 + 제목 Row, 현재 랭크 배지, 진행도 바, 타임라인(Row<Icon>), 등급별 보너스 ListView]`
- **상태 변수:** `_selectedRankGrade` (String?, 타임라인 탭 시 선택 등급. 기본값: 현재 랭크 grade)
- **화면 전환:** InfoScreen 내부 상태 기반 (Navigator.push 금지, CLAUDE.md 준수). 뒤로 가기 → `_showRank = false`
- **연출:** 없음. 정적 리스트

#### 2.3.5 InfoScreen 진입점 ListTile

- **위치:** 기존 "세력 도감" ListTile 바로 아래
- **위젯:** `ListTile(leading: Icons.military_tech, title: Text('명성'), subtitle: Text('용병단 명성 등급과 보너스'), trailing: Icons.chevron_right, onTap: () => setState(() => _showRank = true))`

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/domain/reputation_service.dart` | `getRankChain` / `getRankLevel` / `sumRankSuccessRateBonus` 3개 static 메서드 추가 | FR-1, FR-11 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | `UserDataNotifier.addReputation()`에 랭크업 감지 및 provider/로그 발행 로직 추가 | FR-4 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `ActivityLogType`에 `reputationRankUp`·`reputationRankDown` 2개 값 추가 | FR-10 |
| `band_of_mercenaries/lib/app.dart` | `ref.listen(reputationRankUpProvider)` 추가 → showDialog(RankUpOverlay) | FR-6 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | 등급 카드를 탭 가능하게 변경 + `RankBonusSummarySheet` 호출 | FR-7 |
| `band_of_mercenaries/lib/features/info/view/info_screen.dart` | "명성" ListTile + `_showRank` 상태 + `RankInfoScreen` 렌더 | FR-8 |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | `calculateSuccessRateBreakdown` 내 `rankBonus` 필드 채우기 (`ReputationService.sumRankSuccessRateBonus` 호출) | FR-11 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/providers/reputation_rank_up_provider.dart` | `RankUpEvent` 모델 + `reputationRankUpProvider` StateProvider (FR-5) |
| `band_of_mercenaries/lib/core/domain/passive_bonus_context.dart` | 공통 수집 헬퍼 (FR-3) |
| `band_of_mercenaries/lib/features/home/view/rank_up_overlay.dart` | 랭크업 축하 오버레이 위젯 (FR-6) |
| `band_of_mercenaries/lib/features/home/view/rank_bonus_summary_sheet.dart` | 홈 배지 탭 시 bottom sheet (FR-7) |
| `band_of_mercenaries/lib/features/info/view/rank_info_screen.dart` | 정보 탭 명성 상세 화면 (FR-8) |
| `band_of_mercenaries/test/core/domain/reputation_service_test.dart` | getRankChain/getRankLevel 유닛 테스트 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | ActivityLogType enum 값 추가 시 Hive TypeAdapter 재생성 필요 |

`cd band_of_mercenaries && dart run build_runner build` 필수.

### 3.4 관련 시스템

- **명성 시스템**: ReputationService 확장이 본 명세 핵심
- **패시브 시스템**: PassiveBonusService.collect() `rankChain` 파라미터 활용 (P1 명세 설계됨). 호출부 통합
- **퀘스트 시스템**: QuestCalculator.calculateSuccessRateBreakdown에 `rankBonus` 채우기 (P3 명세와 연결)
- **홈/정보 UI**: 홈 배지 탭 가능화 + 정보 탭 명성 진입점
- **활동 로그**: 신규 이벤트 타입 2개 추가 (typeId 변경 없음)
- **app.dart 글로벌 리스너**: constructionCompletedProvider / investigationCompletedProvider와 동일 패턴으로 reputationRankUpProvider 감지

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **`constructionCompletedProvider` / `investigationCompletedProvider`** (`app.dart` 기존 ref.listen 패턴): 완료 이벤트 감지 → showDialog 패턴. 본 명세 FR-6 오버레이도 동일 구조
- **`FactionCodexScreen`** (`features/info/view/faction_codex_screen.dart`): 상단 배지 / 중단 리스트 / 하단 상세 구조. `RankInfoScreen`도 유사 레이아웃
- **`InfoScreen._showCodex` 토글** (`info_screen.dart:17-18`): 상태 변수로 자식 화면 전환. `_showRank`도 동일 패턴
- **`showModalBottomSheet`**: Material 3 표준 bottom sheet. `RankBonusSummarySheet`
- **`ActivityLog.addLog(message, type)`**: 기존 인터페이스 그대로 사용
- **`CLAUDE.md` 용병 상세 오버레이**: `selectedMercenaryIdProvider` StateProvider 패턴. 랭크업도 `reputationRankUpProvider`로 동일 구조

### 4.2 주의사항

- **P1 명세 데이터 중복 작업 방지**: `ranks.bonus_json` 컬럼·E 임계값 300·6등급 데이터 UPDATE는 P1의 `20260418_ranks_bonus_json.sql`에 이미 포함. 본 명세는 **별도 마이그레이션 SQL 생성 금지**. 로직만 연결
- **랭크업 이벤트 중복 방지**: `addReputation(0)`은 조기 반환. 동일 프레임 내 중복 호출 방어를 위해 `oldLevel == newLevel`이면 무시
- **staticData 미로드 시점**: 앱 초기화 중 `staticDataProvider`가 `loading` 상태면 `ranks=[]` fallback. 랭크업 감지 스킵 (해로운 영향 없음). UI 진입점은 `AsyncValue.when`으로 방어
- **CLAUDE.md Navigator.push 금지**: 오버레이는 `showDialog`, 화면 전환은 상태 기반. 이 제약 반드시 준수
- **최고 랭크 A 이후**: `getNextRank()` null 반환. UI에서 "최고 등급 도달" 표시
- **ranks.bonus_json 파싱 오류**: PassiveBonusService.collect()에서 이미 방어 로직 있음. 본 명세에서 재확인 불필요
- **RankUpEvent 닫기 후 재발생 방지**: 오버레이 확인 버튼 → provider state = null 설정. 다음 랭크업 시까지 null 유지

### 4.3 엣지 케이스

- **평판이 한 번에 여러 등급 넘김** (예: 이벤트로 +5000 → E 건너뛰고 D 도달): `oldLevel=0, newLevel=2` → RankUpEvent는 **최종 도달 등급(D)만 표시**. 중간 E는 스킵. ActivityLog 메시지는 "F → D"로 표기. **단순화 결정** — 중간 단계 모두 오버레이 표시는 과다
- **동일 세션에 여러 번 랭크업 (E→D→C)**: 각 `addReputation` 호출에 1회씩 이벤트. 오버레이 닫고 다음 호출 전 provider 리셋되어 안전
- **ranks 리스트 비어있음**: `getRankChain` 빈 리스트 반환 → `getRankLevel` −1 반환. RankInfoScreen은 "랭크 데이터 로딩 중" 표시
- **reputation 음수 (이론상)**: `clamp(0, 9999999)`로 방어 (FR-4)
- **오버레이 표시 중 앱 백그라운드**: `reputationRankUpProvider`는 그대로 유지됨. 복귀 시 다이얼로그 재출현. 문제 없음
- **최고 랭크 A에서 평판 추가 증가**: `oldLevel == newLevel == 5` → 이벤트 미발생. 정상

### 4.4 구현 힌트

- **진입점**: `UserDataNotifier.addReputation()` (기존, 호출 빈도 많음) + `app.dart` `ref.listen` 등록부 + `HomeScreen` 등급 카드 탭 핸들러 + `InfoScreen` ListTile 추가
- **데이터 흐름**:
  ```
  QuestCompletionService.addReputation 호출
    → UserDataNotifier.addReputation(amount)
      → oldLevel = ReputationService.getRankLevel(prevReputation)
      → reputation += amount
      → newLevel = ReputationService.getRankLevel(newReputation)
      → newLevel > oldLevel이면:
         - reputationRankUpProvider.state = RankUpEvent(from, to, newEffects)
         - activityLogProvider.addLog("명성 상승: X → Y", reputationRankUp)

  app.dart
    → ref.listen(reputationRankUpProvider, (prev, next) {
         if (next != null) showDialog(context: ..., builder: RankUpOverlay(next, onDismiss: () => ref.read(...).state = null))
       })

  HomeScreen 등급 카드 탭
    → showModalBottomSheet → RankBonusSummarySheet
      → ref.watch(userDataProvider).reputation
      → ref.watch(staticDataProvider).ranks
      → ReputationService.getRankChain → rankChain
      → rankChain에서 각 rank.bonusJson → PassiveEffect 리스트 → PassiveBonusFormatter로 한국어 변환

  InfoScreen "명성" ListTile 탭 → _showRank = true → RankInfoScreen 렌더
  ```
- **참조 구현**:
  - `app.dart:137-184` — `constructionCompletedProvider`/`investigationCompletedProvider` listen 패턴. RankUpEvent도 동일 구조로 추가
  - `info_screen.dart:17-18, 68-90` — `_showCodex` 상태 토글 + ListTile. `_showRank`도 같은 방식
  - `faction_codex_screen.dart` — 상단 헤더 + 중앙 리스트 + 하단 액션. `RankInfoScreen`은 상단 진행도 + 중단 타임라인 + 하단 보너스
  - `reputation_service.dart:1-30` — 기존 3개 메서드 스타일 유지
  - `activity_log_model.dart` — enum 추가 시 HiveField 번호 규칙 준수
- **확장 지점**:
  - `RankUpEvent.newEffects`: 향후 랭크업 보상(골드, 아이템 등) 확장 시 필드 추가
  - `RankInfoScreen` 타임라인 — 향후 등급 추가(SS·SSS 등) 시 타임라인 스크롤 가능화
  - `PassiveBonusContext` 공통 수집 헬퍼 — 모든 효과 타입 소비자에서 동일하게 호출

### 4.5 PassiveEffect 파싱 재사용

P1 명세의 `PassiveEffect.fromJson(Map<String, dynamic>)` 팩토리를 그대로 재사용:

```dart
// Rank.bonusJson → List<PassiveEffect>
List<PassiveEffect> parseBonusJson(Map<String, dynamic>? json) {
  if (json == null) return [];
  final effectsRaw = json['effects'] as List?;
  if (effectsRaw == null) return [];
  return effectsRaw
      .whereType<Map<String, dynamic>>()
      .map((e) {
        try { return PassiveEffect.fromJson(e); }
        catch (_) { return null; }
      })
      .whereType<PassiveEffect>()
      .toList();
}
```

위 유틸은 `passive_bonus_service.dart` 또는 `passive_effect.dart`에 동반 함수로 두어 재사용.

## 5. 기획 확인 사항

- [Q-1] `SuccessRateBreakdown.rankBonus`를 채우는 방식 — **별도 `ReputationService.sumRankSuccessRateBonus`** vs **`PassiveBonusService.collect()` 반환을 faction/rank로 분리**? → **FR-11 권장: 별도 메서드** (P1 API 변경 없음). `ReputationService`에서 rankChain만으로 계산하는 쪽이 더 단순. P1 재검토 불요.
- [Q-2] 여러 등급 동시 도달 시(예: 대이벤트 보상 +10000 평판) RankUpEvent를 각 등급별로 순차 발생시킬지, 최종 등급만 1회 발생시킬지? → **FR-4 권장: 최종 등급 1회 발생**. UX 단순화. ActivityLog 메시지는 "F → D" 식으로 단일 로그.
- [Q-3] 랭크업 축하 오버레이에서 "신규 보너스" 표시 시 — **신규 등급의 추가 효과만** vs **누적 전체 효과**? → **권장: 신규 효과만** (기획서 섹션 6.A 예시 기준). 플레이어가 "이번 등급에서 뭐가 늘었나"를 명확히 인지.
- [Q-4] `RankBonusSummarySheet`와 `RankInfoScreen` 기능 중복 — 둘 다 등급별 보너스 표시? → **권장 역할 분리**: Summary sheet = 현재 활성 보너스 목록 + 다음 등급 진행도 (빠른 확인). InfoScreen = F~A 전체 타임라인 + 미도달 등급 프리뷰 (계획 파악). 중복 아님.
- [Q-5] `ActivityLogType.reputationRankDown`을 M1에서 enum에 추가하되 실제 발생은 없음 — Hive 호환성 이슈 없는가? → **안전**. Hive enum adapter는 HiveField 번호만 사용. 기존 로그 데이터는 영향 없음. M2a에서 실제 발생 시 즉시 작동.
- [Q-6] 타임라인 UI — 세로 vs 가로 배치? → **권장: 가로** (`[F]─[E]─[D]●─[C]○─[B]○─[A]○`). 모바일 폭 430px 내 6개 등급은 가로 배치가 정보 밀도 좋음. 세로는 스크롤 필요.
- [Q-7] 오버레이 닫기 시 provider를 null로 리셋하는 주체 — 오버레이 내부 onDismiss 콜백 vs app.dart 리스너? → **권장: 오버레이 내부 onDismiss 콜백** (자기책임 원칙). app.dart는 이벤트를 표시만 하고 닫기 책임은 위젯이 가짐.

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260418_rank-bonus-service.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|------|------|------|
| 수정/생성 파일 | 수정 7개 + 신규 6개 = **13개** | **대규모** |
| 영향 시스템 | 명성/패시브/퀘스트(분해)/홈 UI/정보 UI/활동 로그 = **6개 시스템** | **대규모** |
| 신규 클래스 | `RankUpEvent`, `PassiveBonusContext`, `RankUpOverlay`, `RankBonusSummarySheet`, `RankInfoScreen` = **5개 위젯/모델** | **대규모** |
| 데이터 모델 | ActivityLogType enum 2개 값 추가 (Hive typeId 변경 없음). Supabase 스키마 변경 **없음** (P1 포함됨) | **소규모** (경계선) |
| UI 작업 | 신규 오버레이 1 + 신규 bottom sheet 1 + 신규 화면 1 + 기존 위젯 수정 2 = **5지점** | **대규모** |
| 기존 시스템 변경 | ReputationService 확장 + UserDataNotifier 로직 추가 + app.dart 글로벌 리스너 추가 | **대규모** |

**추천: implement-agent** (5/6점)
- 신규 화면 1 + 오버레이 1 + bottom sheet 1 + StateProvider 1 + 로직 연결 5개 서비스로 파이프라인 권장

```
구현을 진행하려면 아래 명령어를 실행해주세요:

/implement-agent @Docs/spec/[spec]20260418_rank-bonus-service.md  ← 추천 (파이프라인)
/implement-spec @Docs/spec/[spec]20260418_rank-bonus-service.md  (올인원, 비추천)
```
