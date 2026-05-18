# Game Depth & Goals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add travel events, dispatch risk-reward, mercenary/facility growth, and reputation/rank systems to deepen the core game loop and provide long-term goals.

**Architecture:** 4 systems layered onto existing MVP. New static data models + JSON files feed into new domain services. Services integrate into existing providers (movement, quest, mercenary). UserData and Mercenary Hive models extended with new fields (backward-compatible via defaults). UI updated per feature.

**Tech Stack:** Flutter, Riverpod (StateNotifier), Hive (NoSQL), freezed + json_serializable, build_runner, flutter_test

---

## File Structure

### New Files

```
band_of_mercenaries/
├── assets/json/
│   ├── TravelEvent.json          # Travel event pool
│   ├── Facility.json             # Facility definitions
│   ├── Rank.json                 # Rank/reputation table
│   └── MercenaryWage.json        # Tier-based mercenary wages
├── lib/
│   ├── core/models/
│   │   ├── travel_event.dart     # TravelEvent freezed model
│   │   ├── facility.dart         # Facility freezed model
│   │   ├── rank.dart             # Rank freezed model
│   │   └── mercenary_wage.dart   # MercenaryWage freezed model
│   ├── features/
│   │   ├── movement/domain/
│   │   │   └── travel_event_service.dart  # Event roll + effect calculation
│   │   ├── quest/domain/
│   │   │   └── experience_service.dart    # XP calc + level-up logic
│   │   ├── mercenary/domain/
│   │   │   └── facility_service.dart      # Facility upgrade logic
│   │   └── home/domain/
│   │       └── reputation_service.dart    # Reputation gain + rank logic
│   └── features/settings/view/
│       └── facility_screen.dart           # Facility management UI
├── test/
│   ├── features/movement/domain/
│   │   └── travel_event_service_test.dart
│   ├── features/quest/domain/
│   │   ├── quest_calculator_test.dart     # (modify: add wage/cost tests)
│   │   └── experience_service_test.dart
│   ├── features/mercenary/domain/
│   │   └── facility_service_test.dart
│   └── features/home/domain/
│       └── reputation_service_test.dart
Json/
├── TravelEvent.json
├── Facility.json
├── Rank.json
└── MercenaryWage.json
```

### Modified Files

```
lib/core/models/              — (no changes to existing model files)
lib/core/data/json_loader.dart         — Add 4 parse methods
lib/core/data/hive_initializer.dart    — (no changes needed, new fields auto-handled)
lib/core/providers/static_data_provider.dart — Add 4 new data fields
lib/features/movement/domain/movement_model.dart  — Add reputation, facilities fields to UserData
lib/features/movement/domain/movement_provider.dart — Travel event integration + region lock
lib/features/mercenary/domain/mercenary_model.dart  — Add xp, level fields
lib/features/mercenary/domain/mercenary_provider.dart — Level-up check
lib/features/quest/domain/quest_calculator.dart  — Add wage + dispatch cost methods
lib/features/quest/domain/quest_provider.dart    — Dispatch cost, XP, reputation integration
lib/features/quest/view/dispatch_screen.dart     — Show cost/profit breakdown
lib/features/mercenary/view/mercenary_card.dart   — Level badge + XP bar
lib/features/home/view/home_screen.dart           — Rank badge + reputation bar
lib/features/movement/view/movement_screen.dart   — Region tier lock
lib/features/settings/view/settings_screen.dart   — Link to facility screen
lib/app.dart                                      — (possibly update nav for facility)
```

---

## Task 1: Static Data Models

Create freezed models for TravelEvent, Facility, Rank, and MercenaryWage.

**Files:**
- Create: `band_of_mercenaries/lib/core/models/travel_event.dart`
- Create: `band_of_mercenaries/lib/core/models/facility.dart`
- Create: `band_of_mercenaries/lib/core/models/rank.dart`
- Create: `band_of_mercenaries/lib/core/models/mercenary_wage.dart`

- [ ] **Step 1: Create TravelEvent model**

```dart
// lib/core/models/travel_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'travel_event.freezed.dart';
part 'travel_event.g.dart';

@freezed
class TravelEvent with _$TravelEvent {
  const factory TravelEvent({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Type') required String type,
    @JsonKey(name: 'EffectType') required String effectType,
    @JsonKey(name: 'Magnitude') required double magnitude,
    @JsonKey(name: 'MinTier') required int minTier,
    @JsonKey(name: 'MaxTier') required int maxTier,
    @JsonKey(name: 'Description') required String description,
  }) = _TravelEvent;

  factory TravelEvent.fromJson(Map<String, dynamic> json) =>
      _$TravelEventFromJson(json);
}

@freezed
class TravelEventList with _$TravelEventList {
  const factory TravelEventList({
    @JsonKey(name: 'TravelEvents') required List<TravelEvent> items,
  }) = _TravelEventList;

  factory TravelEventList.fromJson(Map<String, dynamic> json) =>
      _$TravelEventListFromJson(json);
}
```

- [ ] **Step 2: Create Facility model**

```dart
// lib/core/models/facility.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'facility.freezed.dart';
part 'facility.g.dart';

@freezed
class Facility with _$Facility {
  const factory Facility({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'EffectType') required String effectType,
    @JsonKey(name: 'MaxLevel') required int maxLevel,
    @JsonKey(name: 'Costs') required List<int> costs,
    @JsonKey(name: 'Values') required List<double> values,
  }) = _Facility;

  factory Facility.fromJson(Map<String, dynamic> json) =>
      _$FacilityFromJson(json);
}

@freezed
class FacilityList with _$FacilityList {
  const factory FacilityList({
    @JsonKey(name: 'Facilities') required List<Facility> items,
  }) = _FacilityList;

  factory FacilityList.fromJson(Map<String, dynamic> json) =>
      _$FacilityListFromJson(json);
}
```

- [ ] **Step 3: Create Rank model**

```dart
// lib/core/models/rank.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rank.freezed.dart';
part 'rank.g.dart';

@freezed
class Rank with _$Rank {
  const factory Rank({
    @JsonKey(name: 'Grade') required String grade,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'RequiredReputation') required int requiredReputation,
    @JsonKey(name: 'UnlockTier') required int unlockTier,
  }) = _Rank;

  factory Rank.fromJson(Map<String, dynamic> json) =>
      _$RankFromJson(json);
}

@freezed
class RankList with _$RankList {
  const factory RankList({
    @JsonKey(name: 'Ranks') required List<Rank> items,
  }) = _RankList;

  factory RankList.fromJson(Map<String, dynamic> json) =>
      _$RankListFromJson(json);
}
```

- [ ] **Step 4: Create MercenaryWage model**

```dart
// lib/core/models/mercenary_wage.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mercenary_wage.freezed.dart';
part 'mercenary_wage.g.dart';

@freezed
class MercenaryWage with _$MercenaryWage {
  const factory MercenaryWage({
    @JsonKey(name: 'Tier') required int tier,
    @JsonKey(name: 'Wage') required int wage,
  }) = _MercenaryWage;

  factory MercenaryWage.fromJson(Map<String, dynamic> json) =>
      _$MercenaryWageFromJson(json);
}

@freezed
class MercenaryWageList with _$MercenaryWageList {
  const factory MercenaryWageList({
    @JsonKey(name: 'MercenaryWages') required List<MercenaryWage> items,
  }) = _MercenaryWageList;

  factory MercenaryWageList.fromJson(Map<String, dynamic> json) =>
      _$MercenaryWageListFromJson(json);
}
```

- [ ] **Step 5: Run build_runner to generate freezed/json files**

Run: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`
Expected: Build completes with new `.freezed.dart` and `.g.dart` files generated for all 4 models.

- [ ] **Step 6: Verify no analysis errors**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No errors (warnings OK)

- [ ] **Step 7: Commit**

```bash
git add band_of_mercenaries/lib/core/models/travel_event.dart \
  band_of_mercenaries/lib/core/models/facility.dart \
  band_of_mercenaries/lib/core/models/rank.dart \
  band_of_mercenaries/lib/core/models/mercenary_wage.dart \
  band_of_mercenaries/lib/core/models/*.freezed.dart \
  band_of_mercenaries/lib/core/models/*.g.dart
git commit -m "feat: add static data models for travel events, facilities, ranks, and wages"
```

---

## Task 2: JSON Data Files

Create the 4 new JSON data files and add dispatch_cost to Difficulty.json.

**Files:**
- Create: `Json/TravelEvent.json` + `band_of_mercenaries/assets/json/TravelEvent.json`
- Create: `Json/Facility.json` + `band_of_mercenaries/assets/json/Facility.json`
- Create: `Json/Rank.json` + `band_of_mercenaries/assets/json/Rank.json`
- Create: `Json/MercenaryWage.json` + `band_of_mercenaries/assets/json/MercenaryWage.json`
- Modify: `Json/Difficulty.json` + `band_of_mercenaries/assets/json/Difficulty.json`

- [ ] **Step 1: Create TravelEvent.json**

Create in both `Json/` and `band_of_mercenaries/assets/json/`:

```json
{
  "TravelEvents": [
    {
      "ID": "te_find_gold_s",
      "Name": "금화 주머니 발견",
      "Type": "discovery",
      "EffectType": "gold",
      "Magnitude": 20.0,
      "MinTier": 1,
      "MaxTier": 2,
      "Description": "길가에 떨어진 작은 금화 주머니를 발견했다."
    },
    {
      "ID": "te_find_gold_m",
      "Name": "상인의 분실물 발견",
      "Type": "discovery",
      "EffectType": "gold",
      "Magnitude": 50.0,
      "MinTier": 2,
      "MaxTier": 4,
      "Description": "상인이 떨어뜨린 듯한 금화 자루를 발견했다."
    },
    {
      "ID": "te_find_gold_l",
      "Name": "숨겨진 보물상자",
      "Type": "discovery",
      "EffectType": "gold",
      "Magnitude": 120.0,
      "MinTier": 4,
      "MaxTier": 5,
      "Description": "오래된 나무 밑에서 보물상자를 발견했다."
    },
    {
      "ID": "te_bandit_s",
      "Name": "산적 습격",
      "Type": "raid",
      "EffectType": "gold",
      "Magnitude": -30.0,
      "MinTier": 1,
      "MaxTier": 3,
      "Description": "이동 중 산적의 습격을 받아 금화를 빼앗겼다."
    },
    {
      "ID": "te_bandit_m",
      "Name": "도적단 매복",
      "Type": "raid",
      "EffectType": "gold",
      "Magnitude": -60.0,
      "MinTier": 3,
      "MaxTier": 5,
      "Description": "도적단의 매복에 걸려 상당한 금화를 잃었다."
    },
    {
      "ID": "te_bandit_injury",
      "Name": "야수 습격",
      "Type": "raid",
      "EffectType": "injury",
      "Magnitude": 1.0,
      "MinTier": 2,
      "MaxTier": 5,
      "Description": "이동 중 야수의 습격을 받아 용병 한 명이 부상당했다."
    },
    {
      "ID": "te_storm_s",
      "Name": "갑작스런 폭우",
      "Type": "weather",
      "EffectType": "delay",
      "Magnitude": 0.2,
      "MinTier": 1,
      "MaxTier": 5,
      "Description": "갑작스런 폭우로 이동이 지연되었다."
    },
    {
      "ID": "te_storm_l",
      "Name": "거센 눈보라",
      "Type": "weather",
      "EffectType": "delay",
      "Magnitude": 0.5,
      "MinTier": 3,
      "MaxTier": 5,
      "Description": "거센 눈보라로 이동이 크게 지연되었다."
    },
    {
      "ID": "te_merchant",
      "Name": "떠돌이 상인과 거래",
      "Type": "luck",
      "EffectType": "gold",
      "Magnitude": 40.0,
      "MinTier": 1,
      "MaxTier": 3,
      "Description": "떠돌이 상인에게 좋은 거래를 성사시켰다."
    },
    {
      "ID": "te_healer",
      "Name": "방랑 치료사",
      "Type": "luck",
      "EffectType": "heal_tired",
      "Magnitude": 1.0,
      "MinTier": 1,
      "MaxTier": 4,
      "Description": "방랑 치료사를 만나 피곤한 용병의 기력을 회복시켰다."
    },
    {
      "ID": "te_merc_group",
      "Name": "다른 용병단과 조우",
      "Type": "encounter",
      "EffectType": "reputation",
      "Magnitude": 10.0,
      "MinTier": 1,
      "MaxTier": 3,
      "Description": "다른 용병단과 우호적인 만남을 가졌다."
    },
    {
      "ID": "te_noble_encounter",
      "Name": "귀족 호위대 조우",
      "Type": "encounter",
      "EffectType": "reputation",
      "Magnitude": 15.0,
      "MinTier": 3,
      "MaxTier": 5,
      "Description": "귀족의 호위대와 만나 용병단의 이름을 알렸다."
    }
  ]
}
```

- [ ] **Step 2: Create Facility.json**

Create in both `Json/` and `band_of_mercenaries/assets/json/`:

```json
{
  "Facilities": [
    {
      "ID": "training",
      "Name": "훈련소",
      "EffectType": "xp_bonus",
      "MaxLevel": 5,
      "Costs": [500, 1000, 2000, 4000, 8000],
      "Values": [0.1, 0.2, 0.3, 0.4, 0.5]
    },
    {
      "ID": "infirmary",
      "Name": "의무실",
      "EffectType": "recovery_reduction",
      "MaxLevel": 5,
      "Costs": [300, 600, 1200, 2400, 4800],
      "Values": [0.1, 0.2, 0.3, 0.4, 0.5]
    },
    {
      "ID": "barracks",
      "Name": "주둔지",
      "EffectType": "max_mercenaries",
      "MaxLevel": 5,
      "Costs": [400, 800, 1600, 3200, 6400],
      "Values": [2.0, 4.0, 6.0, 8.0, 10.0]
    },
    {
      "ID": "intelligence",
      "Name": "정보망",
      "EffectType": "quest_count",
      "MaxLevel": 3,
      "Costs": [1000, 3000, 9000],
      "Values": [1.0, 2.0, 3.0]
    }
  ]
}
```

- [ ] **Step 3: Create Rank.json**

Create in both `Json/` and `band_of_mercenaries/assets/json/`:

```json
{
  "Ranks": [
    {
      "Grade": "F",
      "Name": "무명",
      "RequiredReputation": 0,
      "UnlockTier": 1
    },
    {
      "Grade": "E",
      "Name": "신출내기",
      "RequiredReputation": 500,
      "UnlockTier": 2
    },
    {
      "Grade": "D",
      "Name": "일반",
      "RequiredReputation": 2000,
      "UnlockTier": 3
    },
    {
      "Grade": "C",
      "Name": "숙련",
      "RequiredReputation": 8000,
      "UnlockTier": 4
    },
    {
      "Grade": "B",
      "Name": "정예",
      "RequiredReputation": 25000,
      "UnlockTier": 5
    },
    {
      "Grade": "A",
      "Name": "전설",
      "RequiredReputation": 80000,
      "UnlockTier": 5
    }
  ]
}
```

- [ ] **Step 4: Create MercenaryWage.json**

Create in both `Json/` and `band_of_mercenaries/assets/json/`:

```json
{
  "MercenaryWages": [
    { "Tier": 1, "Wage": 10 },
    { "Tier": 2, "Wage": 25 },
    { "Tier": 3, "Wage": 50 },
    { "Tier": 4, "Wage": 100 },
    { "Tier": 5, "Wage": 200 }
  ]
}
```

- [ ] **Step 5: Add dispatch_cost to Difficulty.json**

Update both `Json/Difficulty.json` and `band_of_mercenaries/assets/json/Difficulty.json`. Add `"DispatchCost"` field to each entry:

```json
{
  "Difficultys": [
    { "Level": 1, "EnemyPower": 10, "RewardMultiplier": 1.0, "SuccessPenalty": 0.0, "InjuryRate": 0.1, "DeathRate": 0.05, "DispatchCost": 20 },
    { "Level": 2, "EnemyPower": 20, "RewardMultiplier": 1.5, "SuccessPenalty": 0.1, "InjuryRate": 0.2, "DeathRate": 0.1, "DispatchCost": 50 },
    { "Level": 3, "EnemyPower": 35, "RewardMultiplier": 2.2, "SuccessPenalty": 0.2, "InjuryRate": 0.3, "DeathRate": 0.15, "DispatchCost": 100 },
    { "Level": 4, "EnemyPower": 55, "RewardMultiplier": 3.2, "SuccessPenalty": 0.3, "InjuryRate": 0.45, "DeathRate": 0.22, "DispatchCost": 200 },
    { "Level": 5, "EnemyPower": 80, "RewardMultiplier": 4.5, "SuccessPenalty": 0.4, "InjuryRate": 0.6, "DeathRate": 0.3, "DispatchCost": 400 }
  ]
}
```

- [ ] **Step 6: Update Difficulty model to include DispatchCost**

Modify `band_of_mercenaries/lib/core/models/difficulty.dart` — add the field:

```dart
@freezed
class Difficulty with _$Difficulty {
  const factory Difficulty({
    @JsonKey(name: 'Level') required int level,
    @JsonKey(name: 'EnemyPower') required int enemyPower,
    @JsonKey(name: 'RewardMultiplier') required double rewardMultiplier,
    @JsonKey(name: 'SuccessPenalty') required double successPenalty,
    @JsonKey(name: 'InjuryRate') required double injuryRate,
    @JsonKey(name: 'DeathRate') required double deathRate,
    @JsonKey(name: 'DispatchCost') required int dispatchCost,
  }) = _Difficulty;

  factory Difficulty.fromJson(Map<String, dynamic> json) =>
      _$DifficultyFromJson(json);
}
```

- [ ] **Step 7: Run build_runner**

Run: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`
Expected: Successful generation including updated Difficulty model.

- [ ] **Step 8: Commit**

```bash
git add Json/ band_of_mercenaries/assets/json/ band_of_mercenaries/lib/core/models/difficulty.dart \
  band_of_mercenaries/lib/core/models/difficulty.freezed.dart \
  band_of_mercenaries/lib/core/models/difficulty.g.dart
git commit -m "feat: add JSON data files for travel events, facilities, ranks, wages and add dispatch cost to difficulty"
```

---

## Task 3: Update JsonLoader and StaticDataProvider

Wire the new models into the data loading pipeline.

**Files:**
- Modify: `band_of_mercenaries/lib/core/data/json_loader.dart`
- Modify: `band_of_mercenaries/lib/core/providers/static_data_provider.dart`
- Modify: `band_of_mercenaries/test/core/data/json_loader_test.dart`

- [ ] **Step 1: Write failing tests for new parse methods**

Add to `band_of_mercenaries/test/core/data/json_loader_test.dart`:

```dart
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';

// Add these test groups inside the existing main():

group('parseTravelEvents', () {
  test('should parse travel events from JSON string', () async {
    final jsonString = await File('assets/json/TravelEvent.json').readAsString();
    final events = JsonLoader.parseTravelEvents(jsonString);
    expect(events, isNotEmpty);
    expect(events.first.id, isNotEmpty);
    expect(events.first.type, isNotEmpty);
    expect(events.first.effectType, isNotEmpty);
  });
});

group('parseFacilities', () {
  test('should parse facilities from JSON string', () async {
    final jsonString = await File('assets/json/Facility.json').readAsString();
    final facilities = JsonLoader.parseFacilities(jsonString);
    expect(facilities.length, 4);
    expect(facilities.first.id, 'training');
    expect(facilities.first.costs.length, facilities.first.maxLevel);
    expect(facilities.first.values.length, facilities.first.maxLevel);
  });
});

group('parseRanks', () {
  test('should parse ranks from JSON string', () async {
    final jsonString = await File('assets/json/Rank.json').readAsString();
    final ranks = JsonLoader.parseRanks(jsonString);
    expect(ranks.length, 6);
    expect(ranks.first.grade, 'F');
    expect(ranks.last.grade, 'A');
  });
});

group('parseMercenaryWages', () {
  test('should parse mercenary wages from JSON string', () async {
    final jsonString = await File('assets/json/MercenaryWage.json').readAsString();
    final wages = JsonLoader.parseMercenaryWages(jsonString);
    expect(wages.length, 5);
    expect(wages.first.tier, 1);
    expect(wages.first.wage, 10);
    expect(wages.last.wage, 200);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd band_of_mercenaries && flutter test test/core/data/json_loader_test.dart`
Expected: FAIL — `parseTravelEvents`, `parseFacilities`, `parseRanks`, `parseMercenaryWages` not defined.

- [ ] **Step 3: Add parse methods to JsonLoader**

Add to `band_of_mercenaries/lib/core/data/json_loader.dart`:

```dart
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';

// Add these static methods to the JsonLoader class:

static List<TravelEvent> parseTravelEvents(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return TravelEventList.fromJson(json).items;
}

static List<Facility> parseFacilities(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return FacilityList.fromJson(json).items;
}

static List<Rank> parseRanks(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return RankList.fromJson(json).items;
}

static List<MercenaryWage> parseMercenaryWages(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return MercenaryWageList.fromJson(json).items;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd band_of_mercenaries && flutter test test/core/data/json_loader_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Update StaticDataProvider**

Modify `band_of_mercenaries/lib/core/providers/static_data_provider.dart`:

Add fields to `StaticGameData`:
```dart
class StaticGameData {
  final List<Difficulty> difficulties;
  final List<Job> jobs;
  final List<TraitData> traits;
  final List<Region> regions;
  final List<QuestType> questTypes;
  final List<QuestPool> questPools;
  final List<PersonName> personNames;
  final List<TravelEvent> travelEvents;
  final List<Facility> facilities;
  final List<Rank> ranks;
  final List<MercenaryWage> mercenaryWages;

  const StaticGameData({
    required this.difficulties,
    required this.jobs,
    required this.traits,
    required this.regions,
    required this.questTypes,
    required this.questPools,
    required this.personNames,
    required this.travelEvents,
    required this.facilities,
    required this.ranks,
    required this.mercenaryWages,
  });
}
```

Update `staticDataProvider` to load the 4 new JSON files:
```dart
final staticDataProvider = FutureProvider<StaticGameData>((ref) async {
  final results = await Future.wait([
    rootBundle.loadString('assets/json/Difficulty.json'),
    rootBundle.loadString('assets/json/Job.json'),
    rootBundle.loadString('assets/json/Trait.json'),
    rootBundle.loadString('assets/json/Region.json'),
    rootBundle.loadString('assets/json/QuestType.json'),
    rootBundle.loadString('assets/json/QuestPool.json'),
    rootBundle.loadString('assets/json/PersonName.json'),
    rootBundle.loadString('assets/json/TravelEvent.json'),
    rootBundle.loadString('assets/json/Facility.json'),
    rootBundle.loadString('assets/json/Rank.json'),
    rootBundle.loadString('assets/json/MercenaryWage.json'),
  ]);

  return StaticGameData(
    difficulties: JsonLoader.parseDifficulties(results[0]),
    jobs: JsonLoader.parseJobs(results[1]),
    traits: JsonLoader.parseTraits(results[2]),
    regions: JsonLoader.parseRegions(results[3]),
    questTypes: JsonLoader.parseQuestTypes(results[4]),
    questPools: JsonLoader.parseQuestPools(results[5]),
    personNames: JsonLoader.parsePersonNames(results[6]),
    travelEvents: JsonLoader.parseTravelEvents(results[7]),
    facilities: JsonLoader.parseFacilities(results[8]),
    ranks: JsonLoader.parseRanks(results[9]),
    mercenaryWages: JsonLoader.parseMercenaryWages(results[10]),
  );
});
```

- [ ] **Step 6: Verify existing tests still pass**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS

- [ ] **Step 7: Commit**

```bash
git add band_of_mercenaries/lib/core/data/json_loader.dart \
  band_of_mercenaries/lib/core/providers/static_data_provider.dart \
  band_of_mercenaries/test/core/data/json_loader_test.dart
git commit -m "feat: wire new static data models into JsonLoader and StaticDataProvider"
```

---

## Task 4: Update Mercenary Model with XP/Level

Add experience and level fields to the Mercenary Hive model with level-based stat bonuses.

**Files:**
- Modify: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart`
- Modify: `band_of_mercenaries/test/features/mercenary/domain/mercenary_model_test.dart`

- [ ] **Step 1: Write failing tests for level bonuses**

Add tests to `band_of_mercenaries/test/features/mercenary/domain/mercenary_model_test.dart`:

```dart
group('level stat bonuses', () {
  test('level 1 mercenary has no bonus', () {
    final merc = Mercenary(
      id: 'test', name: 'Test', jobId: 'j1', traitId: 't1',
      atk: 100, def: 50, hp: 200, speed: 1.0,
      xp: 0, level: 1,
    );
    expect(merc.effectiveAtk, 100);
    expect(merc.effectiveDef, 50);
    expect(merc.effectiveHp, 200);
  });

  test('level 3 mercenary gets +20% bonus', () {
    final merc = Mercenary(
      id: 'test', name: 'Test', jobId: 'j1', traitId: 't1',
      atk: 100, def: 50, hp: 200, speed: 1.0,
      xp: 350, level: 3,
    );
    expect(merc.effectiveAtk, 120);
    expect(merc.effectiveDef, 60);
    expect(merc.effectiveHp, 240);
  });

  test('level 5 mercenary gets +40% bonus', () {
    final merc = Mercenary(
      id: 'test', name: 'Test', jobId: 'j1', traitId: 't1',
      atk: 100, def: 50, hp: 200, speed: 1.0,
      xp: 1850, level: 5,
    );
    expect(merc.effectiveAtk, 140);
    expect(merc.effectiveDef, 70);
    expect(merc.effectiveHp, 280);
  });

  test('tired + level 3 stacks multiplicatively', () {
    final merc = Mercenary(
      id: 'test', name: 'Test', jobId: 'j1', traitId: 't1',
      atk: 100, def: 50, hp: 200, speed: 1.0,
      xp: 350, level: 3,
      status: MercenaryStatus.tired,
    );
    // level bonus +20% on base: 120, then tired 80%: 96
    expect(merc.effectiveAtk, 96);
    expect(merc.effectiveDef, 48);
    expect(merc.effectiveHp, 192);
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd band_of_mercenaries && flutter test test/features/mercenary/domain/mercenary_model_test.dart`
Expected: FAIL — `xp` and `level` parameters not recognized.

- [ ] **Step 3: Update Mercenary model**

Modify `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart`:

Add two new HiveFields to the Mercenary class:

```dart
@HiveField(12)
int xp;

@HiveField(13)
int level;
```

Update the constructor to include defaults:
```dart
Mercenary({
  required this.id,
  required this.name,
  required this.jobId,
  required this.traitId,
  required this.atk,
  required this.def,
  required this.hp,
  required this.speed,
  this.status = MercenaryStatus.normal,
  this.tiredEndTime,
  this.injuryEndTime,
  this.isDispatched = false,
  this.xp = 0,
  this.level = 1,
});
```

Add level bonus getter:
```dart
double get _levelBonus => (level - 1) * 0.1;
```

Update effective stat getters to include level bonus:
```dart
int get effectiveAtk {
  final withLevel = (atk * (1.0 + _levelBonus)).round();
  return status == MercenaryStatus.tired ? (withLevel * 0.8).round() : withLevel;
}

int get effectiveDef {
  final withLevel = (def * (1.0 + _levelBonus)).round();
  return status == MercenaryStatus.tired ? (withLevel * 0.8).round() : withLevel;
}

int get effectiveHp {
  final withLevel = (hp * (1.0 + _levelBonus)).round();
  return status == MercenaryStatus.tired ? (withLevel * 0.8).round() : withLevel;
}
```

- [ ] **Step 4: Run build_runner**

Run: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`
Expected: Mercenary adapter regenerated with new fields.

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd band_of_mercenaries && flutter test test/features/mercenary/domain/mercenary_model_test.dart`
Expected: ALL PASS

- [ ] **Step 6: Run all tests to check for regressions**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS. Existing tests create Mercenary without `xp`/`level` but they have defaults, so no breakage.

- [ ] **Step 7: Commit**

```bash
git add band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart \
  band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.g.dart \
  band_of_mercenaries/test/features/mercenary/domain/mercenary_model_test.dart
git commit -m "feat: add xp and level fields to Mercenary model with level-based stat bonuses"
```

---

## Task 5: Update UserData Model with Reputation and Facilities

Extend UserData to track reputation and facility levels.

**Files:**
- Modify: `band_of_mercenaries/lib/features/movement/domain/movement_model.dart`

- [ ] **Step 1: Add new HiveFields to UserData**

Add to the UserData class in `movement_model.dart`:

```dart
@HiveField(10)
int reputation;

@HiveField(11)
Map<String, int> facilities;
```

Update the constructor:
```dart
UserData({
  required this.gold,
  this.continent = 1,
  required this.region,
  required this.sector,
  this.isMoving = false,
  this.moveTargetRegion,
  this.moveTargetSector,
  this.moveEndTime,
  required this.lastFreeRecruit,
  required this.createdAt,
  this.reputation = 0,
  Map<String, int>? facilities,
}) : facilities = facilities ?? {};
```

- [ ] **Step 2: Run build_runner**

Run: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`
Expected: UserData adapter regenerated.

- [ ] **Step 3: Run all tests**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS. Existing code creates UserData without `reputation`/`facilities` — defaults handle this.

- [ ] **Step 4: Commit**

```bash
git add band_of_mercenaries/lib/features/movement/domain/movement_model.dart \
  band_of_mercenaries/lib/features/movement/domain/movement_model.g.dart
git commit -m "feat: add reputation and facilities fields to UserData model"
```

---

## Task 6: Travel Event Service

Pure logic for determining travel events and calculating their effects.

**Files:**
- Create: `band_of_mercenaries/lib/features/movement/domain/travel_event_service.dart`
- Create: `band_of_mercenaries/test/features/movement/domain/travel_event_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `band_of_mercenaries/test/features/movement/domain/travel_event_service_test.dart`:

```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/features/movement/domain/travel_event_service.dart';

void main() {
  final testEvents = [
    const TravelEvent(
      id: 'te_gold', name: 'Gold Find', type: 'discovery',
      effectType: 'gold', magnitude: 50.0,
      minTier: 1, maxTier: 5, description: 'Found gold.',
    ),
    const TravelEvent(
      id: 'te_raid', name: 'Raid', type: 'raid',
      effectType: 'gold', magnitude: -30.0,
      minTier: 3, maxTier: 5, description: 'Raided.',
    ),
    const TravelEvent(
      id: 'te_storm', name: 'Storm', type: 'weather',
      effectType: 'delay', magnitude: 0.3,
      minTier: 1, maxTier: 5, description: 'Storm.',
    ),
    const TravelEvent(
      id: 'te_rep', name: 'Encounter', type: 'encounter',
      effectType: 'reputation', magnitude: 10.0,
      minTier: 1, maxTier: 2, description: 'Met a group.',
    ),
  ];

  group('shouldEventOccur', () {
    test('distance 1 has 15% chance', () {
      expect(TravelEventService.eventProbability(1), 0.15);
    });

    test('distance 5 has 75% chance', () {
      expect(TravelEventService.eventProbability(5), 0.75);
    });

    test('distance 10 is capped at 80%', () {
      expect(TravelEventService.eventProbability(10), 0.80);
    });

    test('distance 0 has 0% chance', () {
      expect(TravelEventService.eventProbability(0), 0.0);
    });
  });

  group('filterEventsByTier', () {
    test('tier 1 excludes tier 3+ events', () {
      final filtered = TravelEventService.filterByTier(testEvents, 1);
      expect(filtered.any((e) => e.id == 'te_gold'), true);
      expect(filtered.any((e) => e.id == 'te_raid'), false);
      expect(filtered.any((e) => e.id == 'te_rep'), true);
    });

    test('tier 4 includes all matching events', () {
      final filtered = TravelEventService.filterByTier(testEvents, 4);
      expect(filtered.any((e) => e.id == 'te_gold'), true);
      expect(filtered.any((e) => e.id == 'te_raid'), true);
      expect(filtered.any((e) => e.id == 'te_rep'), false);
    });
  });

  group('rollEvent', () {
    test('returns null when roll exceeds probability', () {
      // random returns 0.99, probability for distance 1 is 0.15
      final random = _FixedRandom([0.99, 0.0]);
      final result = TravelEventService.rollEvent(
        distance: 1, regionTier: 1, events: testEvents, random: random,
      );
      expect(result, isNull);
    });

    test('returns an event when roll is under probability', () {
      // random returns 0.01 (triggers event), then 0.0 (picks first filtered event)
      final random = _FixedRandom([0.01, 0.0]);
      final result = TravelEventService.rollEvent(
        distance: 5, regionTier: 1, events: testEvents, random: random,
      );
      expect(result, isNotNull);
    });
  });

  group('calculateDelayMultiplier', () {
    test('weather event with 0.3 magnitude returns 1.3', () {
      final event = testEvents.firstWhere((e) => e.effectType == 'delay');
      expect(TravelEventService.delayMultiplier(event), 1.3);
    });

    test('non-delay event returns 1.0', () {
      final event = testEvents.firstWhere((e) => e.effectType == 'gold');
      expect(TravelEventService.delayMultiplier(event), 1.0);
    });
  });
}

class _FixedRandom implements Random {
  final List<double> _values;
  int _index = 0;

  _FixedRandom(this._values);

  @override
  double nextDouble() => _values[_index++];

  @override
  int nextInt(int max) => (_values[_index++] * max).floor();

  @override
  bool nextBool() => _values[_index++] < 0.5;
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd band_of_mercenaries && flutter test test/features/movement/domain/travel_event_service_test.dart`
Expected: FAIL — `TravelEventService` not found.

- [ ] **Step 3: Implement TravelEventService**

Create `band_of_mercenaries/lib/features/movement/domain/travel_event_service.dart`:

```dart
import 'dart:math';
import 'package:band_of_mercenaries/core/models/travel_event.dart';

class TravelEventService {
  static double eventProbability(int distance) {
    if (distance <= 0) return 0.0;
    return (distance * 0.15).clamp(0.0, 0.80);
  }

  static List<TravelEvent> filterByTier(List<TravelEvent> events, int tier) {
    return events
        .where((e) => tier >= e.minTier && tier <= e.maxTier)
        .toList();
  }

  static TravelEvent? rollEvent({
    required int distance,
    required int regionTier,
    required List<TravelEvent> events,
    required Random random,
  }) {
    final probability = eventProbability(distance);
    if (random.nextDouble() >= probability) return null;

    final filtered = filterByTier(events, regionTier);
    if (filtered.isEmpty) return null;

    return filtered[random.nextInt(filtered.length)];
  }

  static double delayMultiplier(TravelEvent event) {
    if (event.effectType == 'delay') return 1.0 + event.magnitude;
    return 1.0;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd band_of_mercenaries && flutter test test/features/movement/domain/travel_event_service_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/movement/domain/travel_event_service.dart \
  band_of_mercenaries/test/features/movement/domain/travel_event_service_test.dart
git commit -m "feat: add TravelEventService with event probability, filtering, and delay logic"
```

---

## Task 7: Integrate Travel Events into Movement

Wire TravelEventService into the movement provider so events trigger on movement start/completion.

**Files:**
- Modify: `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart`
- Modify: `band_of_mercenaries/lib/core/providers/game_state_provider.dart`

- [ ] **Step 1: Add reputation management to UserDataNotifier**

Add to `UserDataNotifier` in `game_state_provider.dart`:

```dart
Future<void> addReputation(int amount) async {
  if (state == null) return;
  state!.reputation += amount;
  await state!.save();
  state = state;
}
```

- [ ] **Step 2: Update MovementNotifier.startMovement for weather delay**

Modify `startMovement` in `movement_provider.dart` to roll for events at departure and apply weather delay:

```dart
import 'dart:math';
import 'package:band_of_mercenaries/features/movement/domain/travel_event_service.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

// Add a provider to hold the last travel event result
final lastTravelEventProvider = StateProvider<TravelEvent?>((ref) => null);
```

Update `startMovement`:

```dart
Future<void> startMovement(int targetRegion, int targetSector) async {
  final user = state;
  if (user == null || user.isMoving) return;

  final staticData = ref.read(staticDataProvider).value;
  if (staticData == null) return;

  final distance = UserData.calculateDistance(
    user.region, user.sector, targetRegion, targetSector,
  );
  final speedMult = ref.read(speedMultiplierProvider);
  var duration = UserData.calculateMoveTime(distance, speedMultiplier: speedMult);

  // Roll for travel event
  final region = staticData.regions.firstWhere(
    (r) => r.region == user.region,
    orElse: () => staticData.regions.first,
  );
  final random = Random();
  final event = TravelEventService.rollEvent(
    distance: distance,
    regionTier: region.regionTier,
    events: staticData.travelEvents,
    random: random,
  );

  // Apply weather delay at departure
  if (event != null) {
    final multiplier = TravelEventService.delayMultiplier(event);
    if (multiplier > 1.0) {
      final delayedSeconds = (duration.inSeconds * multiplier).round();
      duration = Duration(seconds: delayedSeconds);
    }
  }

  // Store the event for completion processing
  ref.read(lastTravelEventProvider.notifier).state = event;

  final endTime = DateTime.now().add(duration);
  await _repo.startMovement(targetRegion, targetSector, endTime);
  _load();
  ref.read(userDataProvider.notifier).addGold(0);
}
```

- [ ] **Step 3: Update _completeMovement to apply event effects**

Update `_completeMovement` in `movement_provider.dart`:

```dart
Future<void> _completeMovement() async {
  final event = ref.read(lastTravelEventProvider);

  await _repo.completeMovement();
  _load();

  // Apply non-delay event effects
  if (event != null && event.effectType != 'delay') {
    await _applyEventEffect(event);
  }

  ref.read(userDataProvider.notifier).addGold(0);
  await ref.read(questListProvider.notifier).generateQuests();
}

Future<void> _applyEventEffect(TravelEvent event) async {
  switch (event.effectType) {
    case 'gold':
      final amount = event.magnitude.round();
      if (amount > 0) {
        await ref.read(userDataProvider.notifier).addGold(amount);
      } else {
        await ref.read(userDataProvider.notifier).spendGold(amount.abs());
      }
      break;
    case 'injury':
      final mercs = ref.read(mercenaryListProvider)
          .where((m) => m.isAvailable)
          .toList();
      if (mercs.isNotEmpty) {
        final target = mercs[Random().nextInt(mercs.length)];
        final speedMult = ref.read(speedMultiplierProvider);
        final recoverySeconds = (10 * 60 / speedMult).round();
        final endTime = DateTime.now().add(Duration(seconds: recoverySeconds));
        await ref.read(mercenaryRepositoryProvider)
            .updateStatus(target.id, MercenaryStatus.injured, endTime: endTime);
        ref.read(mercenaryListProvider.notifier).refresh();
      }
      break;
    case 'heal_tired':
      final tiredMercs = ref.read(mercenaryListProvider)
          .where((m) => m.status == MercenaryStatus.tired)
          .toList();
      if (tiredMercs.isNotEmpty) {
        final target = tiredMercs.first;
        await ref.read(mercenaryRepositoryProvider)
            .updateStatus(target.id, MercenaryStatus.normal);
        ref.read(mercenaryListProvider.notifier).refresh();
      }
      break;
    case 'reputation':
      await ref.read(userDataProvider.notifier)
          .addReputation(event.magnitude.round());
      break;
  }
}
```

- [ ] **Step 4: Run all tests to check no regressions**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/movement/domain/movement_provider.dart \
  band_of_mercenaries/lib/core/providers/game_state_provider.dart
git commit -m "feat: integrate travel events into movement system with effect processing"
```

---

## Task 8: Dispatch Cost and Wage Calculator

Add wage and dispatch cost calculations to QuestCalculator.

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart`
- Modify: `band_of_mercenaries/test/features/quest/domain/quest_calculator_test.dart`

- [ ] **Step 1: Write failing tests for wage and cost calculations**

Add to `band_of_mercenaries/test/features/quest/domain/quest_calculator_test.dart`:

```dart
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';

// Add inside the existing main():

group('calculateTotalWage', () {
  final wages = [
    const MercenaryWage(tier: 1, wage: 10),
    const MercenaryWage(tier: 2, wage: 25),
    const MercenaryWage(tier: 3, wage: 50),
    const MercenaryWage(tier: 4, wage: 100),
    const MercenaryWage(tier: 5, wage: 200),
  ];

  test('single tier 1 mercenary costs 10G', () {
    expect(QuestCalculator.calculateTotalWage([1], wages), 10);
  });

  test('mixed party calculates total wage', () {
    expect(QuestCalculator.calculateTotalWage([1, 3, 5], wages), 260);
  });

  test('empty party has zero wage', () {
    expect(QuestCalculator.calculateTotalWage([], wages), 0);
  });
});

group('calculateNetProfit', () {
  test('positive profit when reward exceeds costs', () {
    expect(
      QuestCalculator.calculateNetProfit(
        totalReward: 300, totalWage: 100, dispatchCost: 50,
      ),
      150,
    );
  });

  test('negative profit when costs exceed reward', () {
    expect(
      QuestCalculator.calculateNetProfit(
        totalReward: 100, totalWage: 150, dispatchCost: 50,
      ),
      -100,
    );
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd band_of_mercenaries && flutter test test/features/quest/domain/quest_calculator_test.dart`
Expected: FAIL — `calculateTotalWage` and `calculateNetProfit` not defined.

- [ ] **Step 3: Add wage/cost methods to QuestCalculator**

Add to `quest_calculator.dart`:

```dart
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';

// Add these static methods to the QuestCalculator class:

static int calculateTotalWage(List<int> mercTiers, List<MercenaryWage> wages) {
  int total = 0;
  for (final tier in mercTiers) {
    final wage = wages.firstWhere(
      (w) => w.tier == tier,
      orElse: () => const MercenaryWage(tier: 1, wage: 10),
    );
    total += wage.wage;
  }
  return total;
}

static int calculateNetProfit({
  required int totalReward,
  required int totalWage,
  required int dispatchCost,
}) {
  return totalReward - totalWage - dispatchCost;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd band_of_mercenaries && flutter test test/features/quest/domain/quest_calculator_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart \
  band_of_mercenaries/test/features/quest/domain/quest_calculator_test.dart
git commit -m "feat: add wage and dispatch cost calculations to QuestCalculator"
```

---

## Task 9: Integrate Dispatch Costs into Quest System

Wire dispatch costs and wage deduction into the quest provider and update the dispatch screen UI.

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart`
- Modify: `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart`

- [ ] **Step 1: Add dispatch cost check and deduction to quest provider**

Update the `dispatch` method in `quest_provider.dart`:

```dart
Future<bool> dispatch(String questId, List<String> mercIds) async {
  final staticData = ref.read(staticDataProvider).value;
  final speedMult = ref.read(speedMultiplierProvider);
  final userData = ref.read(userDataProvider);
  if (staticData == null || userData == null) return false;

  final quest = state.firstWhere((q) => q.id == questId);
  final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);
  final difficulty = staticData.difficulties.firstWhere(
    (d) => d.level == quest.difficulty.clamp(1, 5),
    orElse: () => staticData.difficulties.first,
  );

  // Check and deduct dispatch cost
  if (userData.gold < difficulty.dispatchCost) return false;
  await ref.read(userDataProvider.notifier).spendGold(difficulty.dispatchCost);

  final duration = QuestCalculator.calculateDispatchDuration(
    baseDuration: questType.baseDuration,
    difficulty: quest.difficulty,
    speedMultiplier: speedMult,
  );

  final endTime = DateTime.now().add(duration);
  await _repo.startQuest(questId, mercIds, endTime);

  final mercNotifier = ref.read(mercenaryListProvider.notifier);
  for (final mercId in mercIds) {
    await ref.read(mercenaryRepositoryProvider).setDispatched(mercId, true);
  }
  mercNotifier.refresh();
  _load();
  return true;
}
```

- [ ] **Step 2: Update reward calculation in _completeQuest to deduct wages**

In the `_completeQuest` method of `quest_provider.dart`, update the reward section:

```dart
// Process rewards (replace the existing reward block)
if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
  final grossReward = QuestCalculator.calculateReward(
    baseReward: questType.baseReward,
    rewardMultiplier: difficulty.rewardMultiplier,
    isGreatSuccess: resultType == QuestResultType.greatSuccess,
  );

  // Calculate and deduct wages
  final mercs = ref.read(mercenaryListProvider)
      .where((m) => quest.dispatchedMercIds.contains(m.id))
      .toList();
  final mercTiers = mercs.map((m) {
    final job = staticData.jobs.firstWhere((j) => j.id == m.jobId,
        orElse: () => staticData.jobs.first);
    return job.tier;
  }).toList();
  final totalWage = QuestCalculator.calculateTotalWage(
      mercTiers, staticData.mercenaryWages);

  final netReward = (grossReward - totalWage).clamp(0, grossReward);
  await ref.read(userDataProvider.notifier).addGold(netReward);
}
```

- [ ] **Step 3: Update dispatch screen to show cost breakdown**

In `dispatch_screen.dart`, add a cost breakdown widget in the dispatch confirmation area. Find the section that shows success rate and add below it:

```dart
// Add a helper method to the screen widget/state:
Widget _buildCostBreakdown(ActiveQuest quest, List<Mercenary> selectedMercs, StaticGameData staticData) {
  final difficulty = staticData.difficulties.firstWhere(
    (d) => d.level == quest.difficulty.clamp(1, 5),
    orElse: () => staticData.difficulties.first,
  );
  final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);

  final grossReward = QuestCalculator.calculateReward(
    baseReward: questType.baseReward,
    rewardMultiplier: difficulty.rewardMultiplier,
  );

  final mercTiers = selectedMercs.map((m) {
    final job = staticData.jobs.firstWhere((j) => j.id == m.jobId,
        orElse: () => staticData.jobs.first);
    return job.tier;
  }).toList();
  final totalWage = QuestCalculator.calculateTotalWage(
      mercTiers, staticData.mercenaryWages);

  final netProfit = QuestCalculator.calculateNetProfit(
    totalReward: grossReward,
    totalWage: totalWage,
    dispatchCost: difficulty.dispatchCost,
  );

  final profitColor = netProfit >= 0 ? Colors.green : Colors.red;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('예상 보상: ${grossReward}G', style: const TextStyle(fontSize: 14)),
      Text('인건비: -${totalWage}G', style: const TextStyle(fontSize: 14, color: Colors.orange)),
      Text('파견비용: -${difficulty.dispatchCost}G', style: const TextStyle(fontSize: 14, color: Colors.orange)),
      const Divider(),
      Text('예상 순수익: ${netProfit}G',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: profitColor)),
    ],
  );
}
```

Display the cost breakdown in the dispatch screen and disable the dispatch button when gold is insufficient.

- [ ] **Step 4: Run all tests**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS. The `dispatch` method signature changed from `void` to `Future<bool>`, so check for any callers.

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/quest/domain/quest_provider.dart \
  band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart
git commit -m "feat: integrate dispatch cost and wage deduction into quest system with UI breakdown"
```

---

## Task 10: Experience Service

Pure logic for XP calculation and level-up determination.

**Files:**
- Create: `band_of_mercenaries/lib/features/quest/domain/experience_service.dart`
- Create: `band_of_mercenaries/test/features/quest/domain/experience_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `band_of_mercenaries/test/features/quest/domain/experience_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/experience_service.dart';

void main() {
  group('calculateXpGain', () {
    test('success on difficulty 3 gives 60 XP', () {
      expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 1.0, facilityBonus: 0.0), 60);
    });

    test('great success doubles XP', () {
      expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 2.0, facilityBonus: 0.0), 120);
    });

    test('failure gives half XP', () {
      expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 0.5, facilityBonus: 0.0), 30);
    });

    test('critical failure gives 0 XP', () {
      expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 0.0, facilityBonus: 0.0), 0);
    });

    test('training facility bonus adds percentage', () {
      // difficulty 3 * 20 * 1.0 = 60, + 30% bonus = 78
      expect(ExperienceService.calculateXpGain(difficulty: 3, resultMultiplier: 1.0, facilityBonus: 0.3), 78);
    });
  });

  group('checkLevelUp', () {
    test('no level up when XP insufficient', () {
      final result = ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 50);
      expect(result, 1);
    });

    test('level up from 1 to 2 at 100 XP', () {
      final result = ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 100);
      expect(result, 2);
    });

    test('level up from 1 to 3 when XP exceeds level 3 threshold', () {
      final result = ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 400);
      expect(result, 3);
    });

    test('cannot exceed max level 5', () {
      final result = ExperienceService.checkLevelUp(currentLevel: 5, currentXp: 9999);
      expect(result, 5);
    });

    test('level thresholds are correct', () {
      expect(ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 99), 1);
      expect(ExperienceService.checkLevelUp(currentLevel: 1, currentXp: 100), 2);
      expect(ExperienceService.checkLevelUp(currentLevel: 2, currentXp: 349), 2);
      expect(ExperienceService.checkLevelUp(currentLevel: 2, currentXp: 350), 3);
      expect(ExperienceService.checkLevelUp(currentLevel: 3, currentXp: 849), 3);
      expect(ExperienceService.checkLevelUp(currentLevel: 3, currentXp: 850), 4);
      expect(ExperienceService.checkLevelUp(currentLevel: 4, currentXp: 1849), 4);
      expect(ExperienceService.checkLevelUp(currentLevel: 4, currentXp: 1850), 5);
    });
  });

  group('resultMultiplier', () {
    test('maps quest results to correct multipliers', () {
      expect(ExperienceService.resultMultiplier('greatSuccess'), 2.0);
      expect(ExperienceService.resultMultiplier('success'), 1.0);
      expect(ExperienceService.resultMultiplier('failure'), 0.5);
      expect(ExperienceService.resultMultiplier('criticalFailure'), 0.0);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd band_of_mercenaries && flutter test test/features/quest/domain/experience_service_test.dart`
Expected: FAIL — `ExperienceService` not found.

- [ ] **Step 3: Implement ExperienceService**

Create `band_of_mercenaries/lib/features/quest/domain/experience_service.dart`:

```dart
class ExperienceService {
  static const int baseXp = 20;
  static const int maxLevel = 5;

  static const List<int> _levelThresholds = [0, 100, 350, 850, 1850];

  static int calculateXpGain({
    required int difficulty,
    required double resultMultiplier,
    required double facilityBonus,
  }) {
    final base = difficulty * baseXp * resultMultiplier;
    return (base * (1.0 + facilityBonus)).round();
  }

  static int checkLevelUp({
    required int currentLevel,
    required int currentXp,
  }) {
    if (currentLevel >= maxLevel) return maxLevel;

    int newLevel = currentLevel;
    for (int lvl = currentLevel; lvl < maxLevel; lvl++) {
      if (currentXp >= _levelThresholds[lvl]) {
        newLevel = lvl + 1;
      } else {
        break;
      }
    }
    return newLevel;
  }

  static double resultMultiplier(String resultName) {
    return switch (resultName) {
      'greatSuccess' => 2.0,
      'success' => 1.0,
      'failure' => 0.5,
      'criticalFailure' => 0.0,
      _ => 0.0,
    };
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd band_of_mercenaries && flutter test test/features/quest/domain/experience_service_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/quest/domain/experience_service.dart \
  band_of_mercenaries/test/features/quest/domain/experience_service_test.dart
git commit -m "feat: add ExperienceService with XP calculation and level-up logic"
```

---

## Task 11: Facility Service

Pure logic for facility upgrade validation and effect retrieval.

**Files:**
- Create: `band_of_mercenaries/lib/features/mercenary/domain/facility_service.dart`
- Create: `band_of_mercenaries/test/features/mercenary/domain/facility_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `band_of_mercenaries/test/features/mercenary/domain/facility_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';

void main() {
  final testFacility = const Facility(
    id: 'training',
    name: '훈련소',
    effectType: 'xp_bonus',
    maxLevel: 5,
    costs: [500, 1000, 2000, 4000, 8000],
    values: [0.1, 0.2, 0.3, 0.4, 0.5],
  );

  group('getUpgradeCost', () {
    test('level 0 to 1 costs 500', () {
      expect(FacilityService.getUpgradeCost(testFacility, 0), 500);
    });

    test('level 2 to 3 costs 2000', () {
      expect(FacilityService.getUpgradeCost(testFacility, 2), 2000);
    });

    test('returns null when already at max level', () {
      expect(FacilityService.getUpgradeCost(testFacility, 5), null);
    });
  });

  group('canUpgrade', () {
    test('can upgrade when gold sufficient and not max', () {
      expect(FacilityService.canUpgrade(testFacility, 0, 500), true);
    });

    test('cannot upgrade when gold insufficient', () {
      expect(FacilityService.canUpgrade(testFacility, 0, 499), false);
    });

    test('cannot upgrade at max level', () {
      expect(FacilityService.canUpgrade(testFacility, 5, 99999), false);
    });
  });

  group('getEffectValue', () {
    test('level 0 returns 0', () {
      expect(FacilityService.getEffectValue(testFacility, 0), 0.0);
    });

    test('level 1 returns first value', () {
      expect(FacilityService.getEffectValue(testFacility, 1), 0.1);
    });

    test('level 3 returns third value', () {
      expect(FacilityService.getEffectValue(testFacility, 3), 0.3);
    });
  });

  group('getMaxMercenaries', () {
    final barracks = const Facility(
      id: 'barracks', name: '주둔지', effectType: 'max_mercenaries',
      maxLevel: 5, costs: [400, 800, 1600, 3200, 6400],
      values: [2.0, 4.0, 6.0, 8.0, 10.0],
    );

    test('base max is 10 with level 0 barracks', () {
      expect(FacilityService.getMaxMercenaries(barracks, 0), 10);
    });

    test('level 3 barracks gives 16 max', () {
      expect(FacilityService.getMaxMercenaries(barracks, 3), 16);
    });
  });

  group('getExtraQuestCount', () {
    final intelligence = const Facility(
      id: 'intelligence', name: '정보망', effectType: 'quest_count',
      maxLevel: 3, costs: [1000, 3000, 9000],
      values: [1.0, 2.0, 3.0],
    );

    test('level 0 gives 0 extra quests', () {
      expect(FacilityService.getExtraQuestCount(intelligence, 0), 0);
    });

    test('level 2 gives 2 extra quests', () {
      expect(FacilityService.getExtraQuestCount(intelligence, 2), 2);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd band_of_mercenaries && flutter test test/features/mercenary/domain/facility_service_test.dart`
Expected: FAIL — `FacilityService` not found.

- [ ] **Step 3: Implement FacilityService**

Create `band_of_mercenaries/lib/features/mercenary/domain/facility_service.dart`:

```dart
import 'package:band_of_mercenaries/core/models/facility.dart';

class FacilityService {
  static const int baseMercenaryMax = 10;
  static const int baseQuestCount = 5;

  static int? getUpgradeCost(Facility facility, int currentLevel) {
    if (currentLevel >= facility.maxLevel) return null;
    return facility.costs[currentLevel];
  }

  static bool canUpgrade(Facility facility, int currentLevel, int gold) {
    final cost = getUpgradeCost(facility, currentLevel);
    if (cost == null) return false;
    return gold >= cost;
  }

  static double getEffectValue(Facility facility, int level) {
    if (level <= 0) return 0.0;
    return facility.values[level - 1];
  }

  static int getMaxMercenaries(Facility barracks, int level) {
    return baseMercenaryMax + getEffectValue(barracks, level).round();
  }

  static int getExtraQuestCount(Facility intelligence, int level) {
    return getEffectValue(intelligence, level).round();
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd band_of_mercenaries && flutter test test/features/mercenary/domain/facility_service_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/mercenary/domain/facility_service.dart \
  band_of_mercenaries/test/features/mercenary/domain/facility_service_test.dart
git commit -m "feat: add FacilityService with upgrade validation and effect calculations"
```

---

## Task 12: Reputation Service

Pure logic for reputation gain and rank determination.

**Files:**
- Create: `band_of_mercenaries/lib/features/home/domain/reputation_service.dart`
- Create: `band_of_mercenaries/test/features/home/domain/reputation_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `band_of_mercenaries/test/features/home/domain/reputation_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';

void main() {
  final ranks = [
    const Rank(grade: 'F', name: '무명', requiredReputation: 0, unlockTier: 1),
    const Rank(grade: 'E', name: '신출내기', requiredReputation: 500, unlockTier: 2),
    const Rank(grade: 'D', name: '일반', requiredReputation: 2000, unlockTier: 3),
    const Rank(grade: 'C', name: '숙련', requiredReputation: 8000, unlockTier: 4),
    const Rank(grade: 'B', name: '정예', requiredReputation: 25000, unlockTier: 5),
    const Rank(grade: 'A', name: '전설', requiredReputation: 80000, unlockTier: 5),
  ];

  group('getCurrentRank', () {
    test('0 reputation is rank F', () {
      final rank = ReputationService.getCurrentRank(0, ranks);
      expect(rank.grade, 'F');
    });

    test('500 reputation is rank E', () {
      final rank = ReputationService.getCurrentRank(500, ranks);
      expect(rank.grade, 'E');
    });

    test('7999 reputation is still rank D', () {
      final rank = ReputationService.getCurrentRank(7999, ranks);
      expect(rank.grade, 'D');
    });

    test('80000 reputation is rank A', () {
      final rank = ReputationService.getCurrentRank(80000, ranks);
      expect(rank.grade, 'A');
    });
  });

  group('getMaxUnlockedTier', () {
    test('rank F unlocks tier 1', () {
      expect(ReputationService.getMaxUnlockedTier(0, ranks), 1);
    });

    test('rank D unlocks up to tier 3', () {
      expect(ReputationService.getMaxUnlockedTier(2000, ranks), 3);
    });

    test('rank B unlocks up to tier 5', () {
      expect(ReputationService.getMaxUnlockedTier(25000, ranks), 5);
    });
  });

  group('isRegionAccessible', () {
    test('tier 1 region accessible at rank F', () {
      expect(ReputationService.isRegionAccessible(1, 0, ranks), true);
    });

    test('tier 3 region not accessible at rank E', () {
      expect(ReputationService.isRegionAccessible(3, 500, ranks), false);
    });

    test('tier 3 region accessible at rank D', () {
      expect(ReputationService.isRegionAccessible(3, 2000, ranks), true);
    });
  });

  group('calculateQuestReputation', () {
    test('success on difficulty 3 gives 30', () {
      expect(ReputationService.calculateQuestReputation(difficulty: 3, isGreatSuccess: false), 30);
    });

    test('great success on difficulty 3 gives 60', () {
      expect(ReputationService.calculateQuestReputation(difficulty: 3, isGreatSuccess: true), 60);
    });
  });

  group('getNextRank', () {
    test('returns next rank when not at max', () {
      final next = ReputationService.getNextRank(0, ranks);
      expect(next?.grade, 'E');
    });

    test('returns null at max rank', () {
      final next = ReputationService.getNextRank(80000, ranks);
      expect(next, null);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd band_of_mercenaries && flutter test test/features/home/domain/reputation_service_test.dart`
Expected: FAIL — `ReputationService` not found.

- [ ] **Step 3: Implement ReputationService**

Create `band_of_mercenaries/lib/features/home/domain/reputation_service.dart`:

```dart
import 'package:band_of_mercenaries/core/models/rank.dart';

class ReputationService {
  static Rank getCurrentRank(int reputation, List<Rank> ranks) {
    Rank current = ranks.first;
    for (final rank in ranks) {
      if (reputation >= rank.requiredReputation) {
        current = rank;
      }
    }
    return current;
  }

  static int getMaxUnlockedTier(int reputation, List<Rank> ranks) {
    return getCurrentRank(reputation, ranks).unlockTier;
  }

  static bool isRegionAccessible(int regionTier, int reputation, List<Rank> ranks) {
    return regionTier <= getMaxUnlockedTier(reputation, ranks);
  }

  static int calculateQuestReputation({
    required int difficulty,
    required bool isGreatSuccess,
  }) {
    final multiplier = isGreatSuccess ? 20 : 10;
    return difficulty * multiplier;
  }

  static Rank? getNextRank(int reputation, List<Rank> ranks) {
    final current = getCurrentRank(reputation, ranks);
    final currentIndex = ranks.indexOf(current);
    if (currentIndex >= ranks.length - 1) return null;
    return ranks[currentIndex + 1];
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd band_of_mercenaries && flutter test test/features/home/domain/reputation_service_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/home/domain/reputation_service.dart \
  band_of_mercenaries/test/features/home/domain/reputation_service_test.dart
git commit -m "feat: add ReputationService with rank determination and region accessibility"
```

---

## Task 13: Integrate Growth into Quest Completion

Wire XP gain, level-up, reputation, and facility effects into the quest completion flow.

**Files:**
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart`
- Modify: `band_of_mercenaries/lib/features/quest/domain/quest_generator.dart`
- Modify: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_repository.dart`

- [ ] **Step 1: Add XP update method to MercenaryRepository**

Add to `mercenary_repository.dart`:

```dart
Future<void> addXpAndCheckLevel(String mercId, int xpGain) async {
  final merc = _box.values.firstWhere((m) => m.id == mercId);
  merc.xp += xpGain;
  final newLevel = ExperienceService.checkLevelUp(
    currentLevel: merc.level,
    currentXp: merc.xp,
  );
  merc.level = newLevel;
  await merc.save();
}
```

Add import at top:
```dart
import 'package:band_of_mercenaries/features/quest/domain/experience_service.dart';
```

- [ ] **Step 2: Integrate XP and reputation into _completeQuest**

In `quest_provider.dart`, after the reward processing block, add XP distribution and reputation gain:

```dart
import 'package:band_of_mercenaries/features/quest/domain/experience_service.dart';
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';

// Inside _completeQuest, after processing damage/tired status and before the final refresh:

// XP distribution
final resultName = switch (resultType) {
  QuestResultType.greatSuccess => 'greatSuccess',
  QuestResultType.success => 'success',
  QuestResultType.failure => 'failure',
  QuestResultType.criticalFailure => 'criticalFailure',
};
final xpMultiplier = ExperienceService.resultMultiplier(resultName);

// Get training facility bonus
double trainingBonus = 0.0;
if (userData != null) {
  final trainingLevel = userData.facilities['training'] ?? 0;
  if (trainingLevel > 0) {
    final trainingFacility = staticData.facilities.firstWhere(
      (f) => f.id == 'training',
      orElse: () => staticData.facilities.first,
    );
    trainingBonus = FacilityService.getEffectValue(trainingFacility, trainingLevel);
  }
}

final xpGain = ExperienceService.calculateXpGain(
  difficulty: quest.difficulty.clamp(1, 5),
  resultMultiplier: xpMultiplier,
  facilityBonus: trainingBonus,
);

// Distribute XP to all alive dispatched mercenaries
for (final merc in mercs) {
  if (merc.status != MercenaryStatus.dead) {
    await mercRepo.addXpAndCheckLevel(merc.id, xpGain);
  }
}

// Reputation gain on success
if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
  final repGain = ReputationService.calculateQuestReputation(
    difficulty: quest.difficulty.clamp(1, 5),
    isGreatSuccess: resultType == QuestResultType.greatSuccess,
  );
  await ref.read(userDataProvider.notifier).addReputation(repGain);
}
```

- [ ] **Step 3: Update quest generator to use intelligence facility bonus**

Modify `generateQuests` in `quest_provider.dart` to pass dynamic count:

```dart
Future<void> generateQuests() async {
  final staticData = ref.read(staticDataProvider).value;
  final userData = ref.read(userDataProvider);
  if (staticData == null || userData == null) return;

  final region = staticData.regions.firstWhere((r) => r.region == userData.region);

  // Calculate quest count with intelligence facility bonus
  int extraQuests = 0;
  final intelLevel = userData.facilities['intelligence'] ?? 0;
  if (intelLevel > 0) {
    final intelFacility = staticData.facilities.firstWhere(
      (f) => f.id == 'intelligence',
      orElse: () => staticData.facilities.first,
    );
    extraQuests = FacilityService.getExtraQuestCount(intelFacility, intelLevel);
  }
  final questCount = FacilityService.baseQuestCount + extraQuests;

  await _repo.clearPending();
  final quests = QuestGenerator.generateQuests(
    regionTier: region.regionTier,
    regionId: userData.region,
    questPools: staticData.questPools,
    questTypes: staticData.questTypes,
    count: questCount,
    random: Random(),
  );
  await _repo.addQuests(quests);
  _load();
}
```

- [ ] **Step 4: Update infirmary effect on injury recovery**

In the damage processing section of `_completeQuest`, update injury time to use infirmary bonus:

```dart
} else if (damageResult == DamageResult.injured) {
  // Apply infirmary facility reduction
  double recoveryReduction = 0.0;
  if (userData != null) {
    final infirmaryLevel = userData.facilities['infirmary'] ?? 0;
    if (infirmaryLevel > 0) {
      final infirmaryFacility = staticData.facilities.firstWhere(
        (f) => f.id == 'infirmary',
        orElse: () => staticData.facilities.first,
      );
      recoveryReduction = FacilityService.getEffectValue(infirmaryFacility, infirmaryLevel);
    }
  }
  final baseRecoverySeconds = (difficulty.level * 10 * 60 / speedMult).round();
  final recoverySeconds = (baseRecoverySeconds * (1.0 - recoveryReduction)).round();
  final recoveryTime = DateTime.now().add(Duration(seconds: recoverySeconds));
  await mercRepo.updateStatus(merc.id, MercenaryStatus.injured, endTime: recoveryTime);
}
```

- [ ] **Step 5: Run all tests**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add band_of_mercenaries/lib/features/quest/domain/quest_provider.dart \
  band_of_mercenaries/lib/features/mercenary/domain/mercenary_repository.dart
git commit -m "feat: integrate XP, reputation, and facility effects into quest completion flow"
```

---

## Task 14: Integrate Reputation into Movement (Region Lock)

Add region tier check to movement based on current rank.

**Files:**
- Modify: `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart`
- Modify: `band_of_mercenaries/lib/features/movement/view/movement_screen.dart`

- [ ] **Step 1: Add region access check to startMovement**

In `movement_provider.dart`, add a check at the beginning of `startMovement`:

```dart
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';

// At the top of startMovement, after getting user and staticData:
final targetRegionData = staticData.regions.firstWhere(
  (r) => r.region == targetRegion,
  orElse: () => staticData.regions.first,
);
if (!ReputationService.isRegionAccessible(
  targetRegionData.regionTier, user.reputation, staticData.ranks,
)) {
  return; // Region locked
}
```

- [ ] **Step 2: Update movement screen to show locked regions**

In `movement_screen.dart`, when displaying region information, check accessibility and show lock indicator:

```dart
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';

// In the region display section, add a lock check:
// For each region option shown, get its data and check:
final isAccessible = ReputationService.isRegionAccessible(
  regionData.regionTier, userData.reputation, staticData.ranks,
);

// If not accessible, show a lock icon and disable the move button:
if (!isAccessible) {
  // Show: "🔒 등급 부족 (필요: D등급)" text and disable the confirm button
  Text(
    '잠김 — ${ReputationService.getCurrentRank(userData.reputation, staticData.ranks).name} 등급으로는 이동 불가',
    style: TextStyle(color: Colors.grey),
  ),
}
```

- [ ] **Step 3: Run all tests**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add band_of_mercenaries/lib/features/movement/domain/movement_provider.dart \
  band_of_mercenaries/lib/features/movement/view/movement_screen.dart
git commit -m "feat: add region tier lock based on reputation rank"
```

---

## Task 15: Facility Management UI

Create a facility management screen and wire it into the settings tab.

**Files:**
- Create: `band_of_mercenaries/lib/features/settings/view/facility_screen.dart`
- Modify: `band_of_mercenaries/lib/features/settings/view/settings_screen.dart`
- Modify: `band_of_mercenaries/lib/core/providers/game_state_provider.dart`

- [ ] **Step 1: Add facility upgrade method to UserDataNotifier**

Add to `game_state_provider.dart`:

```dart
Future<bool> upgradeFacility(String facilityId, int cost) async {
  if (state == null || state!.gold < cost) return false;
  state!.gold -= cost;
  state!.facilities[facilityId] = (state!.facilities[facilityId] ?? 0) + 1;
  await state!.save();
  state = state;
  return true;
}
```

- [ ] **Step 2: Create FacilityScreen**

Create `band_of_mercenaries/lib/features/settings/view/facility_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';

class FacilityScreen extends ConsumerWidget {
  const FacilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).value;
    final userData = ref.watch(userDataProvider);
    if (staticData == null || userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('보유 골드: ${userData.gold}G',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...staticData.facilities.map((facility) {
          final currentLevel = userData.facilities[facility.id] ?? 0;
          final cost = FacilityService.getUpgradeCost(facility, currentLevel);
          final canUpgrade = cost != null && userData.gold >= cost;
          final currentValue = FacilityService.getEffectValue(facility, currentLevel);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(facility.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Lv.$currentLevel / ${facility.maxLevel}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_effectDescription(facility, currentLevel),
                      style: const TextStyle(fontSize: 14)),
                  if (currentLevel < facility.maxLevel) ...[
                    const SizedBox(height: 8),
                    Text('다음 단계: ${_effectDescription(facility, currentLevel + 1)}',
                        style: TextStyle(fontSize: 13, color: Colors.blue[200])),
                  ],
                  const SizedBox(height: 12),
                  if (cost != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canUpgrade
                            ? () => _upgrade(context, ref, facility.id, cost)
                            : null,
                        child: Text('업그레이드 (${cost}G)'),
                      ),
                    )
                  else
                    const Text('최대 레벨 도달',
                        style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _effectDescription(Facility facility, int level) {
    final value = FacilityService.getEffectValue(facility, level);
    return switch (facility.effectType) {
      'xp_bonus' => '경험치 +${(value * 100).round()}%',
      'recovery_reduction' => '부상 회복시간 -${(value * 100).round()}%',
      'max_mercenaries' => '최대 용병 수 ${FacilityService.baseMercenaryMax + value.round()}명',
      'quest_count' => '퀘스트 생성 ${FacilityService.baseQuestCount + value.round()}개',
      _ => '효과: $value',
    };
  }

  Future<void> _upgrade(BuildContext context, WidgetRef ref, String facilityId, int cost) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('시설 업그레이드'),
        content: Text('${cost}G를 사용하여 업그레이드하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(userDataProvider.notifier).upgradeFacility(facilityId, cost);
    }
  }
}
```

- [ ] **Step 3: Update settings screen to include facility management**

Replace the content of `settings_screen.dart` to include both speed controls and a navigation to facilities:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/settings/view/facility_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(speedMultiplierProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '시설 관리'),
              Tab(text: '설정'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const FacilityScreen(),
                // Existing speed controls
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('게임 속도', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (final s in [1.0, 10.0, 100.0])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                onPressed: () => ref.read(speedMultiplierProvider.notifier).state = s,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: speed == s ? Colors.blue : null,
                                ),
                                child: Text('${s.round()}x'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run all tests**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/settings/view/facility_screen.dart \
  band_of_mercenaries/lib/features/settings/view/settings_screen.dart \
  band_of_mercenaries/lib/core/providers/game_state_provider.dart
git commit -m "feat: add facility management screen with upgrade UI"
```

---

## Task 16: UI Updates — Mercenary Card, Home Screen, Movement Event Dialog

Update remaining UI components to display new system data.

**Files:**
- Modify: `band_of_mercenaries/lib/features/mercenary/view/mercenary_card.dart`
- Modify: `band_of_mercenaries/lib/features/home/view/home_screen.dart`
- Modify: `band_of_mercenaries/lib/features/movement/domain/movement_provider.dart`

- [ ] **Step 1: Add level badge and XP bar to mercenary card**

In `mercenary_card.dart`, add level and XP display. After the mercenary name, add:

```dart
import 'package:band_of_mercenaries/features/quest/domain/experience_service.dart';

// Inside the card widget, add after name display:
Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('Lv.${merc.level}',
          style: const TextStyle(fontSize: 12, color: Colors.amber)),
    ),
    const SizedBox(width: 8),
    if (merc.level < ExperienceService.maxLevel)
      Expanded(
        child: LinearProgressIndicator(
          value: _xpProgress(merc),
          backgroundColor: Colors.grey[800],
          valueColor: const AlwaysStoppedAnimation(Colors.amber),
        ),
      ),
  ],
),
```

Add helper method:
```dart
double _xpProgress(Mercenary merc) {
  const thresholds = [0, 100, 350, 850, 1850];
  if (merc.level >= ExperienceService.maxLevel) return 1.0;
  final currentThreshold = thresholds[merc.level - 1];
  final nextThreshold = thresholds[merc.level];
  final progress = (merc.xp - currentThreshold) / (nextThreshold - currentThreshold);
  return progress.clamp(0.0, 1.0);
}
```

- [ ] **Step 2: Add rank badge and reputation bar to home screen**

In `home_screen.dart`, add rank and reputation display at the top:

```dart
import 'package:band_of_mercenaries/features/home/domain/reputation_service.dart';

// In the build method, after the gold display, add:
if (staticData != null && userData != null) ...[
  Builder(builder: (context) {
    final rank = ReputationService.getCurrentRank(
        userData.reputation, staticData.ranks);
    final nextRank = ReputationService.getNextRank(
        userData.reputation, staticData.ranks);
    final progress = nextRank != null
        ? (userData.reputation - rank.requiredReputation) /
            (nextRank.requiredReputation - rank.requiredReputation)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${rank.grade}등급',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(width: 8),
            Text(rank.name, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[800],
          valueColor: const AlwaysStoppedAnimation(Colors.amber),
        ),
        const SizedBox(height: 2),
        Text(
          nextRank != null
              ? '명성: ${userData.reputation} / ${nextRank.requiredReputation}'
              : '명성: ${userData.reputation} (최고 등급)',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }),
],
```

- [ ] **Step 3: Add travel event result display to movement completion**

In `movement_provider.dart`, update `_completeMovement` to show event result. After applying the event effect, we need a way for the UI to know about it. The `lastTravelEventProvider` already stores the event. The home screen can watch this and display a dialog.

In `home_screen.dart`, add a listener for travel event completion:

```dart
// Add a ref.listen for movement completion with event display:
ref.listen(movementProvider, (prev, next) {
  if (prev?.isMoving == true && next?.isMoving == false) {
    final event = ref.read(lastTravelEventProvider);
    if (event != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('이동 완료'),
          content: Text(event.description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      // Clear the event
      ref.read(lastTravelEventProvider.notifier).state = null;
    }
  }
});
```

- [ ] **Step 4: Run all tests**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add band_of_mercenaries/lib/features/mercenary/view/mercenary_card.dart \
  band_of_mercenaries/lib/features/home/view/home_screen.dart \
  band_of_mercenaries/lib/features/movement/domain/movement_provider.dart
git commit -m "feat: add level/XP display on mercenary card, rank badge on home screen, and travel event dialog"
```

---

## Task 17: Barracks Max Mercenary Limit

Wire the barracks facility effect into recruitment to limit max mercenary count.

**Files:**
- Modify: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart`
- Modify: `band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart`

- [ ] **Step 1: Add max mercenary check to recruit method**

Update `recruit` in `mercenary_provider.dart`:

```dart
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';

// Update the recruit method:
Future<Mercenary?> recruit() async {
  final staticData = ref.read(staticDataProvider).value;
  final userData = ref.read(userDataProvider);
  if (staticData == null || userData == null) return null;

  // Check barracks capacity
  final barracksLevel = userData.facilities['barracks'] ?? 0;
  final barracks = staticData.facilities.firstWhere(
    (f) => f.id == 'barracks',
    orElse: () => staticData.facilities.first,
  );
  final maxMercs = FacilityService.getMaxMercenaries(barracks, barracksLevel);
  final aliveMercs = _repo.getAlive();
  if (aliveMercs.length >= maxMercs) return null;

  final merc = await _repo.recruit(
    jobs: staticData.jobs,
    traits: staticData.traits,
    names: staticData.personNames,
  );
  _load();
  return merc;
}
```

- [ ] **Step 2: Show capacity on recruit screen**

In `recruit_screen.dart`, display current/max mercenary count:

```dart
import 'package:band_of_mercenaries/features/mercenary/domain/facility_service.dart';

// Add capacity display near the recruit button:
final barracksLevel = userData.facilities['barracks'] ?? 0;
final barracks = staticData.facilities.firstWhere(
  (f) => f.id == 'barracks',
  orElse: () => staticData.facilities.first,
);
final maxMercs = FacilityService.getMaxMercenaries(barracks, barracksLevel);
final currentMercs = mercs.where((m) => m.status != MercenaryStatus.dead).length;
final isFull = currentMercs >= maxMercs;

Text('용병: $currentMercs / $maxMercs',
    style: TextStyle(color: isFull ? Colors.red : Colors.grey)),
// Disable recruit button when isFull
```

- [ ] **Step 3: Run all tests**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart \
  band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart
git commit -m "feat: enforce barracks capacity limit on mercenary recruitment"
```

---

## Task 18: Final Integration Test and Cleanup

Verify all systems work together and run full test suite.

**Files:**
- All modified files

- [ ] **Step 1: Run full test suite**

Run: `cd band_of_mercenaries && flutter test`
Expected: ALL PASS

- [ ] **Step 2: Run static analysis**

Run: `cd band_of_mercenaries && flutter analyze`
Expected: No errors

- [ ] **Step 3: Run build_runner one final time to ensure all generated files are up to date**

Run: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`
Expected: Clean build with no changes needed

- [ ] **Step 4: Final commit if any generated files changed**

```bash
git status
# If generated files changed:
git add -A band_of_mercenaries/lib/
git commit -m "chore: regenerate build_runner output for final consistency"
```
