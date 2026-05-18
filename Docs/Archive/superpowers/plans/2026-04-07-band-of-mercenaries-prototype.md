# Band of Mercenaries Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter mobile prototype of a text-based mercenary band strategy game with quest dispatching, movement, recruitment, and time-based mechanics.

**Architecture:** Hybrid feature+layer Flutter architecture using Riverpod for state management and Hive for local persistence. Static game data loaded from bundled JSON assets. Timer-based game loop with dev acceleration mode.

**Tech Stack:** Flutter, Riverpod, Hive, freezed, json_serializable, uuid

**Spec:** `docs/superpowers/specs/2026-04-07-band-of-mercenaries-prototype-design.md`

---

## File Structure

```
band_of_mercenaries/
├── assets/json/                          # Static JSON (copied from Json/)
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── data/json_loader.dart
│   │   ├── data/hive_initializer.dart
│   │   ├── models/difficulty.dart        # + .freezed.dart + .g.dart
│   │   ├── models/job.dart
│   │   ├── models/trait_data.dart
│   │   ├── models/region.dart
│   │   ├── models/quest_type.dart
│   │   ├── models/quest_pool.dart
│   │   ├── models/person_name.dart
│   │   ├── providers/static_data_provider.dart
│   │   ├── providers/timer_provider.dart
│   │   ├── providers/game_state_provider.dart
│   │   └── theme/app_theme.dart
│   ├── features/
│   │   ├── mercenary/
│   │   │   ├── data/mercenary_repository.dart
│   │   │   ├── domain/mercenary_model.dart   # Hive model
│   │   │   ├── domain/mercenary_provider.dart
│   │   │   ├── domain/recruitment_service.dart
│   │   │   ├── view/recruit_screen.dart
│   │   │   └── view/mercenary_card.dart
│   │   ├── quest/
│   │   │   ├── data/quest_repository.dart
│   │   │   ├── domain/quest_model.dart       # Hive model
│   │   │   ├── domain/quest_provider.dart
│   │   │   ├── domain/quest_calculator.dart
│   │   │   ├── domain/quest_generator.dart
│   │   │   ├── view/dispatch_screen.dart
│   │   │   └── view/quest_result_dialog.dart
│   │   ├── movement/
│   │   │   ├── data/movement_repository.dart
│   │   │   ├── domain/movement_model.dart
│   │   │   ├── domain/movement_provider.dart
│   │   │   └── view/movement_screen.dart
│   │   ├── home/
│   │   │   └── view/home_screen.dart
│   │   │   └── view/campsite_painter.dart
│   │   └── settings/
│   │       └── view/settings_screen.dart
│   └── shared/widgets/
│       ├── bottom_nav_bar.dart
│       ├── timer_display.dart
│       └── status_badge.dart
├── test/
│   ├── core/data/json_loader_test.dart
│   ├── features/quest/domain/quest_calculator_test.dart
│   ├── features/quest/domain/quest_generator_test.dart
│   ├── features/mercenary/domain/recruitment_service_test.dart
│   ├── features/movement/domain/movement_model_test.dart
│   └── features/mercenary/domain/mercenary_model_test.dart
└── pubspec.yaml
```

---

### Task 1: Flutter 프로젝트 생성 및 의존성 설정

**Files:**
- Create: `band_of_mercenaries/pubspec.yaml` (via flutter create, then modify)
- Create: `band_of_mercenaries/assets/json/*.json` (copy from `Json/`)
- Modify: `band_of_mercenaries/analysis_options.yaml`

- [ ] **Step 1: Flutter 프로젝트 생성**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
flutter create band_of_mercenaries --org com.bandofmercenaries --platforms android,ios
```

Expected: Flutter project created successfully.

- [ ] **Step 2: JSON 에셋 복사**

```bash
mkdir -p band_of_mercenaries/assets/json
cp Json/*.json band_of_mercenaries/assets/json/
```

- [ ] **Step 3: pubspec.yaml 의존성 추가**

`band_of_mercenaries/pubspec.yaml`의 dependencies와 dev_dependencies, assets 섹션을 다음으로 교체:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  uuid: ^4.4.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.12
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  hive_generator: ^2.0.1
  riverpod_generator: ^2.4.3

flutter:
  uses-material-design: true
  assets:
    - assets/json/
```

- [ ] **Step 4: 의존성 설치**

```bash
cd band_of_mercenaries
flutter pub get
```

Expected: No errors.

- [ ] **Step 5: 디렉토리 구조 생성**

```bash
cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries
mkdir -p lib/core/{data,models,providers,theme}
mkdir -p lib/features/mercenary/{data,domain,view}
mkdir -p lib/features/quest/{data,domain,view}
mkdir -p lib/features/movement/{data,domain,view}
mkdir -p lib/features/home/view
mkdir -p lib/features/settings/view
mkdir -p lib/shared/widgets
mkdir -p test/core/data
mkdir -p test/features/quest/domain
mkdir -p test/features/mercenary/domain
mkdir -p test/features/movement/domain
```

- [ ] **Step 6: 커밋**

```bash
git add band_of_mercenaries/
git commit -m "feat: initialize Flutter project with dependencies and directory structure"
```

---

### Task 2: Static 데이터 모델 (freezed + json_serializable)

**Files:**
- Create: `lib/core/models/difficulty.dart`
- Create: `lib/core/models/job.dart`
- Create: `lib/core/models/trait_data.dart`
- Create: `lib/core/models/region.dart`
- Create: `lib/core/models/quest_type.dart`
- Create: `lib/core/models/quest_pool.dart`
- Create: `lib/core/models/person_name.dart`

- [ ] **Step 1: Difficulty 모델 작성**

`lib/core/models/difficulty.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'difficulty.freezed.dart';
part 'difficulty.g.dart';

@freezed
class Difficulty with _$Difficulty {
  const factory Difficulty({
    @JsonKey(name: 'Level') required int level,
    @JsonKey(name: 'EnemyPower') required int enemyPower,
    @JsonKey(name: 'RewardMultiplier') required double rewardMultiplier,
    @JsonKey(name: 'SuccessPenalty') required double successPenalty,
    @JsonKey(name: 'InjuryRate') required double injuryRate,
    @JsonKey(name: 'DeathRate') required double deathRate,
  }) = _Difficulty;

  factory Difficulty.fromJson(Map<String, dynamic> json) =>
      _$DifficultyFromJson(json);
}

@freezed
class DifficultyList with _$DifficultyList {
  const factory DifficultyList({
    @JsonKey(name: 'Difficultys') required List<Difficulty> items,
  }) = _DifficultyList;

  factory DifficultyList.fromJson(Map<String, dynamic> json) =>
      _$DifficultyListFromJson(json);
}
```

- [ ] **Step 2: Job 모델 작성**

`lib/core/models/job.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Tier') required int tier,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'BaseAtk') required int baseAtk,
    @JsonKey(name: 'BaseDef') required int baseDef,
    @JsonKey(name: 'BaseHp') required int baseHp,
    @JsonKey(name: 'Speed') required double speed,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

@freezed
class JobList with _$JobList {
  const factory JobList({
    @JsonKey(name: 'Jobs') required List<Job> items,
  }) = _JobList;

  factory JobList.fromJson(Map<String, dynamic> json) =>
      _$JobListFromJson(json);
}
```

- [ ] **Step 3: TraitData 모델 작성**

`lib/core/models/trait_data.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trait_data.freezed.dart';
part 'trait_data.g.dart';

@freezed
class TraitData with _$TraitData {
  const factory TraitData({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'EffectType') required String effectType,
    @JsonKey(name: 'Value') required double value,
  }) = _TraitData;

  factory TraitData.fromJson(Map<String, dynamic> json) =>
      _$TraitDataFromJson(json);
}

@freezed
class TraitDataList with _$TraitDataList {
  const factory TraitDataList({
    @JsonKey(name: 'Traits') required List<TraitData> items,
  }) = _TraitDataList;

  factory TraitDataList.fromJson(Map<String, dynamic> json) =>
      _$TraitDataListFromJson(json);
}
```

- [ ] **Step 4: Region 모델 작성**

`lib/core/models/region.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'region.freezed.dart';
part 'region.g.dart';

@freezed
class Region with _$Region {
  const factory Region({
    @JsonKey(name: 'Continent') required int continent,
    @JsonKey(name: 'Region') required int region,
    @JsonKey(name: 'RegionName') required String regionName,
    @JsonKey(name: 'RegionTier') required int regionTier,
    @JsonKey(name: 'RecommendPower') required int recommendPower,
    @JsonKey(name: 'Desc') required String desc,
  }) = _Region;

  factory Region.fromJson(Map<String, dynamic> json) =>
      _$RegionFromJson(json);
}

@freezed
class RegionList with _$RegionList {
  const factory RegionList({
    @JsonKey(name: 'Regions') required List<Region> items,
  }) = _RegionList;

  factory RegionList.fromJson(Map<String, dynamic> json) =>
      _$RegionListFromJson(json);
}
```

- [ ] **Step 5: QuestType 모델 작성**

`lib/core/models/quest_type.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_type.freezed.dart';
part 'quest_type.g.dart';

@freezed
class QuestType with _$QuestType {
  const factory QuestType({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'BaseReward') required int baseReward,
    @JsonKey(name: 'BaseDuration') required int baseDuration,
    @JsonKey(name: 'RiskFactor') required double riskFactor,
  }) = _QuestType;

  factory QuestType.fromJson(Map<String, dynamic> json) =>
      _$QuestTypeFromJson(json);
}

@freezed
class QuestTypeList with _$QuestTypeList {
  const factory QuestTypeList({
    @JsonKey(name: 'QuestTypes') required List<QuestType> items,
  }) = _QuestTypeList;

  factory QuestTypeList.fromJson(Map<String, dynamic> json) =>
      _$QuestTypeListFromJson(json);
}
```

- [ ] **Step 6: QuestPool 모델 작성**

`lib/core/models/quest_pool.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_pool.freezed.dart';
part 'quest_pool.g.dart';

@freezed
class QuestPool with _$QuestPool {
  const factory QuestPool({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'Type') required double type,
    @JsonKey(name: 'Difficulty') required double difficulty,
    @JsonKey(name: 'MinRegionDiff') required double minRegionDiff,
    @JsonKey(name: 'MaxRegionDiff') required double maxRegionDiff,
  }) = _QuestPool;

  factory QuestPool.fromJson(Map<String, dynamic> json) =>
      _$QuestPoolFromJson(json);
}

@freezed
class QuestPoolList with _$QuestPoolList {
  const factory QuestPoolList({
    @JsonKey(name: 'QuestPools') required List<QuestPool> items,
  }) = _QuestPoolList;

  factory QuestPoolList.fromJson(Map<String, dynamic> json) =>
      _$QuestPoolListFromJson(json);
}
```

- [ ] **Step 7: PersonName 모델 작성**

`lib/core/models/person_name.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_name.freezed.dart';
part 'person_name.g.dart';

@freezed
class PersonName with _$PersonName {
  const factory PersonName({
    @JsonKey(name: 'ID') required int id,
    @JsonKey(name: 'Korean') required String korean,
  }) = _PersonName;

  factory PersonName.fromJson(Map<String, dynamic> json) =>
      _$PersonNameFromJson(json);
}

@freezed
class PersonNameList with _$PersonNameList {
  const factory PersonNameList({
    @JsonKey(name: 'PersonNames') required List<PersonName> items,
  }) = _PersonNameList;

  factory PersonNameList.fromJson(Map<String, dynamic> json) =>
      _$PersonNameListFromJson(json);
}
```

- [ ] **Step 8: 코드 생성 실행**

```bash
cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries
dart run build_runner build --delete-conflicting-outputs
```

Expected: Generated `.freezed.dart` and `.g.dart` files for all 7 models with no errors.

- [ ] **Step 9: 빌드 확인**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 10: 커밋**

```bash
git add .
git commit -m "feat: add static data models with freezed and json_serializable"
```

---

### Task 3: JSON Loader 및 테스트

**Files:**
- Create: `lib/core/data/json_loader.dart`
- Create: `test/core/data/json_loader_test.dart`

- [ ] **Step 1: 테스트 작성**

`test/core/data/json_loader_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/data/json_loader.dart';

void main() {
  group('JsonLoader', () {
    test('parseDifficulties parses JSON correctly', () {
      const jsonString = '''
      {
        "Difficultys": [
          {"Level": 1, "EnemyPower": 10, "RewardMultiplier": 1.0, "SuccessPenalty": 0.0, "InjuryRate": 0.1, "DeathRate": 0.05}
        ]
      }
      ''';
      final result = JsonLoader.parseDifficulties(jsonString);
      expect(result.length, 1);
      expect(result[0].level, 1);
      expect(result[0].enemyPower, 10);
      expect(result[0].deathRate, 0.05);
    });

    test('parseJobs parses JSON correctly', () {
      const jsonString = '''
      {
        "Jobs": [
          {"ID": "farmer", "Tier": 1, "Name": "농부", "BaseAtk": 4, "BaseDef": 3, "BaseHp": 24, "Speed": 0.96}
        ]
      }
      ''';
      final result = JsonLoader.parseJobs(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'farmer');
      expect(result[0].tier, 1);
      expect(result[0].name, '농부');
    });

    test('parseTraits parses JSON correctly', () {
      const jsonString = '''
      {
        "Traits": [
          {"ID": "strong", "Name": "강인함", "EffectType": "hp_bonus", "Value": 0.2}
        ]
      }
      ''';
      final result = JsonLoader.parseTraits(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'strong');
      expect(result[0].effectType, 'hp_bonus');
    });

    test('parseRegions parses JSON correctly', () {
      const jsonString = '''
      {
        "Regions": [
          {"Continent": 1, "Region": 3, "RegionName": "초원", "RegionTier": 1, "RecommendPower": 10, "Desc": "초원 지역"}
        ]
      }
      ''';
      final result = JsonLoader.parseRegions(jsonString);
      expect(result.length, 1);
      expect(result[0].region, 3);
      expect(result[0].regionTier, 1);
    });

    test('parseQuestTypes parses JSON correctly', () {
      const jsonString = '''
      {
        "QuestTypes": [
          {"ID": "loot", "Name": "약탈", "BaseReward": 100, "BaseDuration": 60, "RiskFactor": 0.3}
        ]
      }
      ''';
      final result = JsonLoader.parseQuestTypes(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'loot');
      expect(result[0].baseReward, 100);
    });

    test('parseQuestPools parses JSON correctly', () {
      const jsonString = '''
      {
        "QuestPools": [
          {"ID": "q001", "Name": "귀족 마차 호위 Lv8", "Type": 0.0, "Difficulty": 8.0, "MinRegionDiff": 6.0, "MaxRegionDiff": 10.0}
        ]
      }
      ''';
      final result = JsonLoader.parseQuestPools(jsonString);
      expect(result.length, 1);
      expect(result[0].id, 'q001');
      expect(result[0].difficulty, 8.0);
    });

    test('parsePersonNames parses JSON correctly', () {
      const jsonString = '''
      {
        "PersonNames": [
          {"ID": 0, "Korean": "에이드리안"},
          {"ID": 1, "Korean": "알라릭"}
        ]
      }
      ''';
      final result = JsonLoader.parsePersonNames(jsonString);
      expect(result.length, 2);
      expect(result[0].korean, '에이드리안');
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries
flutter test test/core/data/json_loader_test.dart
```

Expected: FAIL — `json_loader.dart` not found.

- [ ] **Step 3: JsonLoader 구현**

`lib/core/data/json_loader.dart`:
```dart
import 'dart:convert';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';

class JsonLoader {
  static List<Difficulty> parseDifficulties(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return DifficultyList.fromJson(json).items;
  }

  static List<Job> parseJobs(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return JobList.fromJson(json).items;
  }

  static List<TraitData> parseTraits(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return TraitDataList.fromJson(json).items;
  }

  static List<Region> parseRegions(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return RegionList.fromJson(json).items;
  }

  static List<QuestType> parseQuestTypes(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return QuestTypeList.fromJson(json).items;
  }

  static List<QuestPool> parseQuestPools(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return QuestPoolList.fromJson(json).items;
  }

  static List<PersonName> parsePersonNames(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return PersonNameList.fromJson(json).items;
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/core/data/json_loader_test.dart
```

Expected: All 7 tests pass.

- [ ] **Step 5: 커밋**

```bash
git add .
git commit -m "feat: add JSON loader with parse methods for all static data"
```

---

### Task 4: Runtime 데이터 모델 (Hive)

**Files:**
- Create: `lib/features/mercenary/domain/mercenary_model.dart`
- Create: `lib/features/quest/domain/quest_model.dart`
- Create: `lib/features/movement/domain/movement_model.dart`
- Create: `lib/core/data/hive_initializer.dart`
- Test: `test/features/mercenary/domain/mercenary_model_test.dart`

- [ ] **Step 1: MercenaryStatus 및 Mercenary 모델 작성**

`lib/features/mercenary/domain/mercenary_model.dart`:
```dart
import 'package:hive/hive.dart';

part 'mercenary_model.g.dart';

@HiveType(typeId: 0)
enum MercenaryStatus {
  @HiveField(0)
  normal,
  @HiveField(1)
  tired,
  @HiveField(2)
  injured,
  @HiveField(3)
  dead,
}

@HiveType(typeId: 1)
class Mercenary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String jobId;

  @HiveField(3)
  final String traitId;

  @HiveField(4)
  int atk;

  @HiveField(5)
  int def;

  @HiveField(6)
  int hp;

  @HiveField(7)
  double speed;

  @HiveField(8)
  MercenaryStatus status;

  @HiveField(9)
  DateTime? tiredEndTime;

  @HiveField(10)
  DateTime? injuryEndTime;

  @HiveField(11)
  bool isDispatched;

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
  });

  int get effectiveAtk =>
      status == MercenaryStatus.tired ? (atk * 0.8).round() : atk;

  int get effectiveDef =>
      status == MercenaryStatus.tired ? (def * 0.8).round() : def;

  int get effectiveHp =>
      status == MercenaryStatus.tired ? (hp * 0.8).round() : hp;

  bool get isAvailable =>
      status != MercenaryStatus.dead &&
      status != MercenaryStatus.injured &&
      !isDispatched;
}
```

- [ ] **Step 2: QuestStatus 및 ActiveQuest 모델 작성**

`lib/features/quest/domain/quest_model.dart`:
```dart
import 'package:hive/hive.dart';

part 'quest_model.g.dart';

@HiveType(typeId: 2)
enum QuestStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
}

@HiveType(typeId: 3)
enum QuestResult {
  @HiveField(0)
  greatSuccess,
  @HiveField(1)
  success,
  @HiveField(2)
  failure,
  @HiveField(3)
  criticalFailure,
}

@HiveType(typeId: 4)
class ActiveQuest extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String questPoolId;

  @HiveField(2)
  final String questTypeId;

  @HiveField(3)
  final int difficulty;

  @HiveField(4)
  final int region;

  @HiveField(5)
  List<String> dispatchedMercIds;

  @HiveField(6)
  DateTime? startTime;

  @HiveField(7)
  DateTime? endTime;

  @HiveField(8)
  QuestStatus status;

  @HiveField(9)
  QuestResult? result;

  @HiveField(10)
  final String questName;

  ActiveQuest({
    required this.id,
    required this.questPoolId,
    required this.questTypeId,
    required this.difficulty,
    required this.region,
    required this.questName,
    this.dispatchedMercIds = const [],
    this.startTime,
    this.endTime,
    this.status = QuestStatus.pending,
    this.result,
  });
}
```

- [ ] **Step 3: UserData 모델 작성**

`lib/features/movement/domain/movement_model.dart`:
```dart
import 'package:hive/hive.dart';

part 'movement_model.g.dart';

@HiveType(typeId: 5)
class UserData extends HiveObject {
  @HiveField(0)
  int gold;

  @HiveField(1)
  final int continent;

  @HiveField(2)
  int region;

  @HiveField(3)
  int sector;

  @HiveField(4)
  bool isMoving;

  @HiveField(5)
  int? moveTargetRegion;

  @HiveField(6)
  int? moveTargetSector;

  @HiveField(7)
  DateTime? moveEndTime;

  @HiveField(8)
  DateTime lastFreeRecruit;

  @HiveField(9)
  final DateTime createdAt;

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
  });

  static int calculateDistance(
      int fromRegion, int fromSector, int toRegion, int toSector) {
    return (fromRegion - toRegion).abs() + (fromSector - toSector).abs();
  }

  static Duration calculateMoveTime(int distance, {double speedMultiplier = 1.0}) {
    final seconds = (distance * 30 / speedMultiplier).round();
    return Duration(seconds: seconds);
  }
}
```

- [ ] **Step 4: Mercenary 모델 테스트 작성**

`test/features/mercenary/domain/mercenary_model_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

void main() {
  group('Mercenary', () {
    test('effectiveAtk returns 80% when tired', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        atk: 10,
        def: 10,
        hp: 100,
        speed: 1.0,
        status: MercenaryStatus.tired,
      );
      expect(merc.effectiveAtk, 8);
      expect(merc.effectiveDef, 8);
      expect(merc.effectiveHp, 80);
    });

    test('effectiveAtk returns full value when normal', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        atk: 10,
        def: 10,
        hp: 100,
        speed: 1.0,
      );
      expect(merc.effectiveAtk, 10);
    });

    test('isAvailable returns false when dead', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        atk: 10,
        def: 10,
        hp: 100,
        speed: 1.0,
        status: MercenaryStatus.dead,
      );
      expect(merc.isAvailable, false);
    });

    test('isAvailable returns false when dispatched', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        atk: 10,
        def: 10,
        hp: 100,
        speed: 1.0,
        isDispatched: true,
      );
      expect(merc.isAvailable, false);
    });

    test('isAvailable returns true when normal and not dispatched', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        atk: 10,
        def: 10,
        hp: 100,
        speed: 1.0,
      );
      expect(merc.isAvailable, true);
    });

    test('isAvailable returns true when tired and not dispatched', () {
      final merc = Mercenary(
        id: 'test',
        name: 'Test',
        jobId: 'farmer',
        traitId: 'strong',
        atk: 10,
        def: 10,
        hp: 100,
        speed: 1.0,
        status: MercenaryStatus.tired,
      );
      expect(merc.isAvailable, true);
    });
  });
}
```

- [ ] **Step 5: Movement 모델 테스트 작성**

`test/features/movement/domain/movement_model_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';

void main() {
  group('UserData', () {
    test('calculateDistance returns correct value for same region', () {
      expect(UserData.calculateDistance(42, 3, 42, 7), 4);
    });

    test('calculateDistance returns correct value for different regions', () {
      expect(UserData.calculateDistance(42, 3, 50, 5), 10);
    });

    test('calculateMoveTime returns 30s per distance unit', () {
      final duration = UserData.calculateMoveTime(5);
      expect(duration.inSeconds, 150);
    });

    test('calculateMoveTime applies speed multiplier', () {
      final duration = UserData.calculateMoveTime(10, speedMultiplier: 10.0);
      expect(duration.inSeconds, 30);
    });
  });
}
```

- [ ] **Step 6: 코드 생성 실행**

```bash
cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries
dart run build_runner build --delete-conflicting-outputs
```

Expected: Generated `.g.dart` files for all Hive models.

- [ ] **Step 7: 테스트 실행**

```bash
flutter test test/features/mercenary/domain/mercenary_model_test.dart test/features/movement/domain/movement_model_test.dart
```

Expected: All tests pass.

- [ ] **Step 8: HiveInitializer 작성**

`lib/core/data/hive_initializer.dart`:
```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';

class HiveInitializer {
  static const String userBoxName = 'user';
  static const String mercenaryBoxName = 'mercenaries';
  static const String questBoxName = 'quests';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(MercenaryStatusAdapter());
    Hive.registerAdapter(MercenaryAdapter());
    Hive.registerAdapter(QuestStatusAdapter());
    Hive.registerAdapter(QuestResultAdapter());
    Hive.registerAdapter(ActiveQuestAdapter());
    Hive.registerAdapter(UserDataAdapter());

    await Hive.openBox<UserData>(userBoxName);
    await Hive.openBox<Mercenary>(mercenaryBoxName);
    await Hive.openBox<ActiveQuest>(questBoxName);
  }
}
```

- [ ] **Step 9: 커밋**

```bash
git add .
git commit -m "feat: add runtime data models with Hive adapters and HiveInitializer"
```

---

### Task 5: 게임 로직 — QuestCalculator

**Files:**
- Create: `lib/features/quest/domain/quest_calculator.dart`
- Create: `test/features/quest/domain/quest_calculator_test.dart`

- [ ] **Step 1: 테스트 작성**

`test/features/quest/domain/quest_calculator_test.dart`:
```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';

void main() {
  group('QuestCalculator', () {
    group('calculateSuccessRate', () {
      test('returns 50% when power ratio is 1.0 with no modifiers', () {
        final rate = QuestCalculator.calculateSuccessRate(
          partyPower: 10,
          enemyPower: 10,
          traitBonuses: [],
          questTypeId: 'loot',
          distancePenalty: 0,
          random: Random(42),
        );
        // 50% + 0 + 0(loot) - 0 + random variance
        expect(rate, greaterThanOrEqualTo(5));
        expect(rate, lessThanOrEqualTo(95));
      });

      test('higher power ratio increases success rate', () {
        final rate = QuestCalculator.calculateSuccessRate(
          partyPower: 20,
          enemyPower: 10,
          traitBonuses: [],
          questTypeId: 'loot',
          distancePenalty: 0,
          random: Random(42),
        );
        // 50% + (2.0 - 1) * 50 = 100%, clamped to 95 + variance
        expect(rate, greaterThan(80));
      });

      test('explore quest type gives +5% bonus', () {
        final rng = Random(42);
        final explorRate = QuestCalculator.calculateSuccessRate(
          partyPower: 10,
          enemyPower: 10,
          traitBonuses: [],
          questTypeId: 'explore',
          distancePenalty: 0,
          random: rng,
        );
        final rng2 = Random(42);
        final lootRate = QuestCalculator.calculateSuccessRate(
          partyPower: 10,
          enemyPower: 10,
          traitBonuses: [],
          questTypeId: 'loot',
          distancePenalty: 0,
          random: rng2,
        );
        expect(explorRate - lootRate, 5);
      });

      test('clamps to 5-95 range', () {
        final rate = QuestCalculator.calculateSuccessRate(
          partyPower: 1,
          enemyPower: 100,
          traitBonuses: [],
          questTypeId: 'hunt',
          distancePenalty: 50,
          random: Random(42),
        );
        expect(rate, greaterThanOrEqualTo(5));

        final highRate = QuestCalculator.calculateSuccessRate(
          partyPower: 1000,
          enemyPower: 1,
          traitBonuses: [],
          questTypeId: 'explore',
          distancePenalty: 0,
          random: Random(42),
        );
        expect(highRate, lessThanOrEqualTo(95));
      });
    });

    group('determineResult', () {
      test('roll in great success range returns greatSuccess', () {
        // success_rate = 80, great_success threshold = 80 * 0.3 = 24
        // roll = 10 <= 24 → great success
        final result = QuestCalculator.determineResult(
          successRate: 80,
          roll: 10,
        );
        expect(result, QuestResultType.greatSuccess);
      });

      test('roll in success range returns success', () {
        // success_rate = 80, great threshold = 24, success threshold = 80
        // roll = 50 → success
        final result = QuestCalculator.determineResult(
          successRate: 80,
          roll: 50,
        );
        expect(result, QuestResultType.success);
      });

      test('roll in failure range returns failure', () {
        // success_rate = 80, failure threshold = 80 + (100-80)*0.7 = 94
        // roll = 85 → failure
        final result = QuestCalculator.determineResult(
          successRate: 80,
          roll: 85,
        );
        expect(result, QuestResultType.failure);
      });

      test('roll in critical failure range returns criticalFailure', () {
        // success_rate = 80, failure threshold = 94
        // roll = 98 → critical failure
        final result = QuestCalculator.determineResult(
          successRate: 80,
          roll: 98,
        );
        expect(result, QuestResultType.criticalFailure);
      });
    });

    group('calculateReward', () {
      test('calculates reward correctly', () {
        final reward = QuestCalculator.calculateReward(
          baseReward: 100,
          rewardMultiplier: 1.5,
        );
        expect(reward, 150);
      });

      test('great success doubles reward', () {
        final reward = QuestCalculator.calculateReward(
          baseReward: 100,
          rewardMultiplier: 1.5,
          isGreatSuccess: true,
        );
        expect(reward, 300);
      });
    });

    group('calculateDamage', () {
      test('roll below deathRate returns dead', () {
        final result = QuestCalculator.calculateDamage(
          roll: 0.03,
          deathRate: 0.05,
          injuryRate: 0.1,
          traitId: '',
        );
        expect(result, DamageResult.dead);
      });

      test('roll below injuryRate returns injured', () {
        final result = QuestCalculator.calculateDamage(
          roll: 0.07,
          deathRate: 0.05,
          injuryRate: 0.1,
          traitId: '',
        );
        expect(result, DamageResult.injured);
      });

      test('roll above injuryRate returns survived', () {
        final result = QuestCalculator.calculateDamage(
          roll: 0.5,
          deathRate: 0.05,
          injuryRate: 0.1,
          traitId: '',
        );
        expect(result, DamageResult.survived);
      });

      test('coward trait reduces deathRate by 30%', () {
        // deathRate 0.1 * 0.7 = 0.07. Roll 0.08 should survive death check.
        final result = QuestCalculator.calculateDamage(
          roll: 0.08,
          deathRate: 0.1,
          injuryRate: 0.2,
          traitId: 'coward',
        );
        expect(result, DamageResult.injured);
      });

      test('strong trait reduces injuryRate by 20%', () {
        // injuryRate 0.2 * 0.8 = 0.16. Roll 0.17 should survive.
        final result = QuestCalculator.calculateDamage(
          roll: 0.17,
          deathRate: 0.05,
          injuryRate: 0.2,
          traitId: 'strong',
        );
        expect(result, DamageResult.survived);
      });
    });

    group('calculateDispatchDuration', () {
      test('difficulty 1 returns base duration', () {
        final duration = QuestCalculator.calculateDispatchDuration(
          baseDuration: 60,
          difficulty: 1,
          speedMultiplier: 1.0,
        );
        expect(duration.inSeconds, 60);
      });

      test('difficulty 5 applies 1.8x multiplier', () {
        final duration = QuestCalculator.calculateDispatchDuration(
          baseDuration: 60,
          difficulty: 5,
          speedMultiplier: 1.0,
        );
        expect(duration.inSeconds, 108); // 60 * 1.8
      });

      test('speed multiplier reduces duration', () {
        final duration = QuestCalculator.calculateDispatchDuration(
          baseDuration: 60,
          difficulty: 1,
          speedMultiplier: 10.0,
        );
        expect(duration.inSeconds, 6);
      });
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
flutter test test/features/quest/domain/quest_calculator_test.dart
```

Expected: FAIL — `quest_calculator.dart` not found.

- [ ] **Step 3: QuestCalculator 구현**

`lib/features/quest/domain/quest_calculator.dart`:
```dart
import 'dart:math';

enum QuestResultType {
  greatSuccess,
  success,
  failure,
  criticalFailure,
}

enum DamageResult {
  dead,
  injured,
  survived,
}

class QuestCalculator {
  static const Map<String, double> _questModifiers = {
    'explore': 5.0,
    'escort': 3.0,
    'loot': 0.0,
    'hunt': -5.0,
  };

  static double calculateSuccessRate({
    required int partyPower,
    required int enemyPower,
    required List<String> traitBonuses,
    required String questTypeId,
    required int distancePenalty,
    required Random random,
  }) {
    final powerRatio = partyPower / enemyPower;
    final questMod = _questModifiers[questTypeId] ?? 0.0;
    final traitBonus = traitBonuses.contains('veteran') ? 10.0 : 0.0;
    final randomVariance = (random.nextDouble() * 10.0) - 5.0;

    final rate = 50.0 +
        (powerRatio - 1.0) * 50.0 +
        traitBonus +
        questMod -
        distancePenalty.toDouble() +
        randomVariance;

    return rate.clamp(5.0, 95.0);
  }

  static QuestResultType determineResult({
    required double successRate,
    required double roll,
  }) {
    final greatSuccessThreshold = successRate * 0.3;
    final successThreshold = successRate;
    final failureThreshold = successRate + (100 - successRate) * 0.7;

    if (roll <= greatSuccessThreshold) {
      return QuestResultType.greatSuccess;
    } else if (roll <= successThreshold) {
      return QuestResultType.success;
    } else if (roll <= failureThreshold) {
      return QuestResultType.failure;
    } else {
      return QuestResultType.criticalFailure;
    }
  }

  static int calculateReward({
    required int baseReward,
    required double rewardMultiplier,
    bool isGreatSuccess = false,
  }) {
    final reward = (baseReward * rewardMultiplier).round();
    return isGreatSuccess ? reward * 2 : reward;
  }

  static DamageResult calculateDamage({
    required double roll,
    required double deathRate,
    required double injuryRate,
    required String traitId,
  }) {
    double effectiveDeathRate = deathRate;
    double effectiveInjuryRate = injuryRate;

    if (traitId == 'coward') {
      effectiveDeathRate *= 0.7;
    }
    if (traitId == 'strong') {
      effectiveInjuryRate *= 0.8;
    }

    if (roll < effectiveDeathRate) {
      return DamageResult.dead;
    } else if (roll < effectiveInjuryRate) {
      return DamageResult.injured;
    } else {
      return DamageResult.survived;
    }
  }

  static Duration calculateDispatchDuration({
    required int baseDuration,
    required int difficulty,
    required double speedMultiplier,
  }) {
    final multiplier = 1.0 + (difficulty - 1) * 0.2;
    final seconds = (baseDuration * multiplier / speedMultiplier).round();
    return Duration(seconds: seconds);
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/features/quest/domain/quest_calculator_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: 커밋**

```bash
git add .
git commit -m "feat: add QuestCalculator with success rate, result, damage, and duration logic"
```

---

### Task 6: 게임 로직 — RecruitmentService & QuestGenerator

**Files:**
- Create: `lib/features/mercenary/domain/recruitment_service.dart`
- Create: `lib/features/quest/domain/quest_generator.dart`
- Create: `test/features/mercenary/domain/recruitment_service_test.dart`
- Create: `test/features/quest/domain/quest_generator_test.dart`

- [ ] **Step 1: RecruitmentService 테스트 작성**

`test/features/mercenary/domain/recruitment_service_test.dart`:
```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';

void main() {
  final jobs = [
    const Job(id: 'farmer', tier: 1, name: '농부', baseAtk: 4, baseDef: 3, baseHp: 24, speed: 0.96),
    const Job(id: 'militia', tier: 2, name: '민병대', baseAtk: 15, baseDef: 15, baseHp: 75, speed: 0.83),
    const Job(id: 'knight', tier: 3, name: '기사', baseAtk: 20, baseDef: 21, baseHp: 97, speed: 0.81),
  ];

  final traits = [
    const TraitData(id: 'strong', name: '강인함', effectType: 'hp_bonus', value: 0.2),
    const TraitData(id: 'veteran', name: '노련함', effectType: 'success_rate', value: 0.1),
  ];

  final names = [
    const PersonName(id: 0, korean: '알라릭'),
    const PersonName(id: 1, korean: '세드릭'),
  ];

  group('RecruitmentService', () {
    test('selectTier returns a valid tier between 1-5', () {
      final tier = RecruitmentService.selectTier(Random(42));
      expect(tier, greaterThanOrEqualTo(1));
      expect(tier, lessThanOrEqualTo(5));
    });

    test('tier distribution favors lower tiers', () {
      final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (var i = 0; i < 10000; i++) {
        final tier = RecruitmentService.selectTier(Random(i));
        counts[tier] = counts[tier]! + 1;
      }
      expect(counts[1]!, greaterThan(counts[2]!));
      expect(counts[2]!, greaterThan(counts[3]!));
      expect(counts[3]!, greaterThan(counts[4]!));
      expect(counts[4]!, greaterThan(counts[5]!));
    });

    test('generateMercenary creates a valid mercenary', () {
      final merc = RecruitmentService.generateMercenary(
        jobs: jobs,
        traits: traits,
        names: names,
        random: Random(42),
      );
      expect(merc.name, isNotEmpty);
      expect(merc.jobId, isNotEmpty);
      expect(merc.traitId, isNotEmpty);
      expect(merc.atk, greaterThan(0));
      expect(merc.id, isNotEmpty);
    });

    test('generateMercenary applies hp_bonus trait correctly', () {
      // Force tier 1 by using specific seed and check hp_bonus
      final merc = RecruitmentService.generateMercenary(
        jobs: jobs,
        traits: [const TraitData(id: 'strong', name: '강인함', effectType: 'hp_bonus', value: 0.2)],
        names: names,
        random: Random(42),
      );
      // Trait is always 'strong' (only option), so hp should be boosted
      expect(merc.traitId, 'strong');
      // The hp should be base * 1.2
      final job = jobs.firstWhere((j) => j.id == merc.jobId);
      expect(merc.hp, (job.baseHp * 1.2).round());
    });

    test('generateStartingMercenaries creates 4 mercs from tier 1-2', () {
      final mercs = RecruitmentService.generateStartingMercenaries(
        jobs: jobs,
        traits: traits,
        names: names,
        count: 4,
        random: Random(42),
      );
      expect(mercs.length, 4);
      for (final merc in mercs) {
        final job = jobs.firstWhere((j) => j.id == merc.jobId);
        expect(job.tier, lessThanOrEqualTo(2));
      }
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
flutter test test/features/mercenary/domain/recruitment_service_test.dart
```

Expected: FAIL.

- [ ] **Step 3: RecruitmentService 구현**

`lib/features/mercenary/domain/recruitment_service.dart`:
```dart
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

class RecruitmentService {
  static const _tierProbabilities = <int, double>{
    1: 0.45,
    2: 0.30,
    3: 0.15,
    4: 0.08,
    5: 0.02,
  };

  static const _uuid = Uuid();

  static int selectTier(Random random) {
    final roll = random.nextDouble();
    double cumulative = 0;
    for (final entry in _tierProbabilities.entries) {
      cumulative += entry.value;
      if (roll < cumulative) return entry.key;
    }
    return 1;
  }

  static Mercenary generateMercenary({
    required List<Job> jobs,
    required List<TraitData> traits,
    required List<PersonName> names,
    required Random random,
    int? forceTier,
  }) {
    final tier = forceTier ?? selectTier(random);
    final tierJobs = jobs.where((j) => j.tier == tier).toList();
    final job = tierJobs[random.nextInt(tierJobs.length)];
    final trait = traits[random.nextInt(traits.length)];
    final name = names[random.nextInt(names.length)];

    int atk = job.baseAtk;
    int def = job.baseDef;
    int hp = job.baseHp;

    switch (trait.effectType) {
      case 'hp_bonus':
        hp = (hp * (1 + trait.value)).round();
        break;
      case 'atk_bonus':
        atk = (atk * (1 + trait.value)).round();
        break;
      case 'success_rate':
      case 'survival_rate':
        // These are applied during quest calculation, not stat modification
        break;
    }

    return Mercenary(
      id: _uuid.v4(),
      name: name.korean,
      jobId: job.id,
      traitId: trait.id,
      atk: atk,
      def: def,
      hp: hp,
      speed: job.speed,
    );
  }

  static List<Mercenary> generateStartingMercenaries({
    required List<Job> jobs,
    required List<TraitData> traits,
    required List<PersonName> names,
    required int count,
    required Random random,
  }) {
    return List.generate(
      count,
      (_) => generateMercenary(
        jobs: jobs,
        traits: traits,
        names: names,
        random: random,
        forceTier: random.nextBool() ? 1 : 2,
      ),
    );
  }
}
```

- [ ] **Step 4: RecruitmentService 테스트 통과 확인**

```bash
flutter test test/features/mercenary/domain/recruitment_service_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: QuestGenerator 테스트 작성**

`test/features/quest/domain/quest_generator_test.dart`:
```dart
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';

void main() {
  final questPools = [
    const QuestPool(id: 'q001', name: '오크 사냥 Lv1', type: 0, difficulty: 1, minRegionDiff: 0, maxRegionDiff: 3),
    const QuestPool(id: 'q002', name: '늑대 토벌 Lv5', type: 0, difficulty: 5, minRegionDiff: 3, maxRegionDiff: 7),
    const QuestPool(id: 'q003', name: '동굴 조사 Lv10', type: 0, difficulty: 10, minRegionDiff: 8, maxRegionDiff: 12),
    const QuestPool(id: 'q004', name: '보물 침입 Lv2', type: 0, difficulty: 2, minRegionDiff: 0, maxRegionDiff: 4),
    const QuestPool(id: 'q005', name: '마법 유적 Lv3', type: 0, difficulty: 3, minRegionDiff: 1, maxRegionDiff: 5),
    const QuestPool(id: 'q006', name: '상단 호위 Lv4', type: 0, difficulty: 4, minRegionDiff: 2, maxRegionDiff: 6),
  ];

  final questTypes = [
    const QuestType(id: 'loot', name: '약탈', baseReward: 100, baseDuration: 60, riskFactor: 0.3),
    const QuestType(id: 'explore', name: '탐험', baseReward: 80, baseDuration: 70, riskFactor: 0.2),
    const QuestType(id: 'hunt', name: '토벌', baseReward: 120, baseDuration: 80, riskFactor: 0.5),
    const QuestType(id: 'escort', name: '호위', baseReward: 90, baseDuration: 75, riskFactor: 0.25),
  ];

  group('QuestGenerator', () {
    test('generates correct number of quests', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 3,
        questPools: questPools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
      );
      // Should return min(5, available quests matching tier 1)
      expect(quests.length, lessThanOrEqualTo(5));
      expect(quests.length, greaterThan(0));
    });

    test('filters quests by region tier correctly', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 3,
        questPools: questPools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
      );
      // Tier 1 should only match quests where minRegionDiff <= 1 <= maxRegionDiff
      for (final quest in quests) {
        final pool = questPools.firstWhere((p) => p.id == quest.questPoolId);
        expect(pool.minRegionDiff, lessThanOrEqualTo(1));
        expect(pool.maxRegionDiff, greaterThanOrEqualTo(1));
      }
    });

    test('assigns quest types from available types', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 1,
        regionId: 3,
        questPools: questPools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
      );
      final validTypeIds = questTypes.map((t) => t.id).toSet();
      for (final quest in quests) {
        expect(validTypeIds.contains(quest.questTypeId), true);
      }
    });

    test('returns empty list when no quests match region tier', () {
      final quests = QuestGenerator.generateQuests(
        regionTier: 99,
        regionId: 1,
        questPools: questPools,
        questTypes: questTypes,
        count: 5,
        random: Random(42),
      );
      expect(quests, isEmpty);
    });
  });
}
```

- [ ] **Step 6: 테스트 실패 확인**

```bash
flutter test test/features/quest/domain/quest_generator_test.dart
```

Expected: FAIL.

- [ ] **Step 7: QuestGenerator 구현**

`lib/features/quest/domain/quest_generator.dart`:
```dart
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

class QuestGenerator {
  static const _uuid = Uuid();

  static List<ActiveQuest> generateQuests({
    required int regionTier,
    required int regionId,
    required List<QuestPool> questPools,
    required List<QuestType> questTypes,
    required int count,
    required Random random,
  }) {
    final filtered = questPools
        .where((q) =>
            q.minRegionDiff <= regionTier && q.maxRegionDiff >= regionTier)
        .toList();

    if (filtered.isEmpty) return [];

    filtered.shuffle(random);
    final selected = filtered.take(count).toList();

    return selected.map((pool) {
      final questType = questTypes[random.nextInt(questTypes.length)];
      return ActiveQuest(
        id: _uuid.v4(),
        questPoolId: pool.id,
        questTypeId: questType.id,
        difficulty: pool.difficulty.round(),
        region: regionId,
        questName: pool.name,
      );
    }).toList();
  }
}
```

- [ ] **Step 8: QuestGenerator 테스트 통과 확인**

```bash
flutter test test/features/quest/domain/quest_generator_test.dart
```

Expected: All tests pass.

- [ ] **Step 9: 커밋**

```bash
git add .
git commit -m "feat: add RecruitmentService and QuestGenerator with full test coverage"
```

---

### Task 7: 앱 테마 및 공유 위젯

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/shared/widgets/status_badge.dart`
- Create: `lib/shared/widgets/timer_display.dart`

- [ ] **Step 1: AppTheme 작성**

`lib/core/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';

class AppTheme {
  // Base colors
  static const Color primary = Color(0xFF1A1A1A);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAFAFA);
  static const Color border = Color(0xFFDDDDDD);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF444444);
  static const Color textTertiary = Color(0xFF555555);
  static const Color textHint = Color(0xFF666666);

  // Tier colors
  static const Color tier1 = Color(0xFF666666);
  static const Color tier2 = Color(0xFF2E7D32);
  static const Color tier3 = Color(0xFF1565C0);
  static const Color tier4 = Color(0xFF6A1B9A);
  static const Color tier5 = Color(0xFFC62828);

  static const Color tier1Bg = Color(0xFFF0F0F0);
  static const Color tier2Bg = Color(0xFFE8F5E9);
  static const Color tier3Bg = Color(0xFFE3F2FD);
  static const Color tier4Bg = Color(0xFFF3E5F5);
  static const Color tier5Bg = Color(0xFFFFEBEE);

  // Trait colors
  static const Map<String, Color> traitColors = {
    'strong': Color(0xFF2E7D32),
    'veteran': Color(0xFF1565C0),
    'coward': Color(0xFF6A1B9A),
    'berserker': Color(0xFFC62828),
  };

  // Quest result colors
  static const Color greatSuccess = Color(0xFF1565C0);
  static const Color success = Color(0xFF2E7D32);
  static const Color failure = Color(0xFFE65100);
  static const Color criticalFailure = Color(0xFFC62828);

  static const Color greatSuccessBg = Color(0xFFE3F2FD);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color failureBg = Color(0xFFFFF3E0);
  static const Color criticalFailureBg = Color(0xFFFFEBEE);

  // Timer accent
  static const Color timerBlue = Color(0xFF1565C0);

  static Color tierColor(int tier) {
    switch (tier) {
      case 1: return tier1;
      case 2: return tier2;
      case 3: return tier3;
      case 4: return tier4;
      case 5: return tier5;
      default: return tier1;
    }
  }

  static Color tierBgColor(int tier) {
    switch (tier) {
      case 1: return tier1Bg;
      case 2: return tier2Bg;
      case 3: return tier3Bg;
      case 4: return tier4Bg;
      case 5: return tier5Bg;
      default: return tier1Bg;
    }
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceAlt,
      selectedItemColor: primary,
      unselectedItemColor: textHint,
      selectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: borderLight),
      ),
    ),
  );
}
```

- [ ] **Step 2: StatusBadge 위젯 작성**

`lib/shared/widgets/status_badge.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final MercenaryStatus status;
  final String? timerText;

  const StatusBadge({super.key, required this.status, this.timerText});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      MercenaryStatus.normal => ('정상', AppTheme.textSecondary, AppTheme.tier1Bg),
      MercenaryStatus.tired => ('피곤', AppTheme.failure, AppTheme.failureBg),
      MercenaryStatus.injured => ('부상${timerText != null ? ' $timerText' : ''}', AppTheme.criticalFailure, AppTheme.criticalFailureBg),
      MercenaryStatus.dead => ('사망', AppTheme.criticalFailure, AppTheme.criticalFailureBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
```

- [ ] **Step 3: TimerDisplay 위젯 작성**

`lib/shared/widgets/timer_display.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class TimerDisplay extends StatelessWidget {
  final Duration remaining;
  final String label;

  const TimerDisplay({super.key, required this.remaining, required this.label});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        Text(
          '${_formatDuration(remaining)} 남음',
          style: const TextStyle(fontSize: 14, color: AppTheme.timerBlue, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 빌드 확인**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 5: 커밋**

```bash
git add .
git commit -m "feat: add app theme, StatusBadge, and TimerDisplay widgets"
```

---

### Task 8: Core Providers (StaticData, Timer, GameState)

**Files:**
- Create: `lib/core/providers/static_data_provider.dart`
- Create: `lib/core/providers/timer_provider.dart`
- Create: `lib/core/providers/game_state_provider.dart`

- [ ] **Step 1: StaticDataProvider 작성**

`lib/core/providers/static_data_provider.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/data/json_loader.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';

class StaticGameData {
  final List<Difficulty> difficulties;
  final List<Job> jobs;
  final List<TraitData> traits;
  final List<Region> regions;
  final List<QuestType> questTypes;
  final List<QuestPool> questPools;
  final List<PersonName> personNames;

  const StaticGameData({
    required this.difficulties,
    required this.jobs,
    required this.traits,
    required this.regions,
    required this.questTypes,
    required this.questPools,
    required this.personNames,
  });
}

final staticDataProvider = FutureProvider<StaticGameData>((ref) async {
  final results = await Future.wait([
    rootBundle.loadString('assets/json/Difficulty.json'),
    rootBundle.loadString('assets/json/Job.json'),
    rootBundle.loadString('assets/json/Trait.json'),
    rootBundle.loadString('assets/json/Region.json'),
    rootBundle.loadString('assets/json/QuestType.json'),
    rootBundle.loadString('assets/json/QuestPool.json'),
    rootBundle.loadString('assets/json/PersonName.json'),
  ]);

  return StaticGameData(
    difficulties: JsonLoader.parseDifficulties(results[0]),
    jobs: JsonLoader.parseJobs(results[1]),
    traits: JsonLoader.parseTraits(results[2]),
    regions: JsonLoader.parseRegions(results[3]),
    questTypes: JsonLoader.parseQuestTypes(results[4]),
    questPools: JsonLoader.parseQuestPools(results[5]),
    personNames: JsonLoader.parsePersonNames(results[6]),
  );
});
```

- [ ] **Step 2: TimerProvider 작성**

`lib/core/providers/timer_provider.dart`:
```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final speedMultiplierProvider = StateProvider<double>((ref) => 1.0);

final gameTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});
```

- [ ] **Step 3: GameStateProvider 작성**

`lib/core/providers/game_state_provider.dart`:
```dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';

final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData?>((ref) {
  return UserDataNotifier(ref);
});

class UserDataNotifier extends StateNotifier<UserData?> {
  final Ref ref;

  UserDataNotifier(this.ref) : super(null) {
    _load();
  }

  void _load() {
    final box = Hive.box<UserData>(HiveInitializer.userBoxName);
    if (box.isNotEmpty) {
      state = box.getAt(0);
    }
  }

  Future<void> initializeNewGame() async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final random = Random();
    final tier1Regions = staticData.regions.where((r) => r.regionTier == 1).toList();
    final startRegion = tier1Regions[random.nextInt(tier1Regions.length)];
    final startSector = random.nextInt(10) + 1;

    final userData = UserData(
      gold: 500,
      region: startRegion.region,
      sector: startSector,
      lastFreeRecruit: DateTime.now().subtract(const Duration(hours: 3)),
      createdAt: DateTime.now(),
    );

    final box = Hive.box<UserData>(HiveInitializer.userBoxName);
    await box.clear();
    await box.add(userData);
    state = userData;

    // Generate starting mercenaries
    final mercBox = Hive.box<Mercenary>(HiveInitializer.mercenaryBoxName);
    await mercBox.clear();
    final startingMercs = RecruitmentService.generateStartingMercenaries(
      jobs: staticData.jobs,
      traits: staticData.traits,
      names: staticData.personNames,
      count: 4,
      random: random,
    );
    for (final merc in startingMercs) {
      await mercBox.add(merc);
    }
  }

  Future<void> addGold(int amount) async {
    if (state == null) return;
    state!.gold += amount;
    await state!.save();
    state = state;
  }

  Future<void> spendGold(int amount) async {
    if (state == null || state!.gold < amount) return;
    state!.gold -= amount;
    await state!.save();
    state = state;
  }
}
```

- [ ] **Step 4: 빌드 확인**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 5: 커밋**

```bash
git add .
git commit -m "feat: add core providers for static data, timer, and game state"
```

---

### Task 9: Feature Repositories (Mercenary, Quest, Movement)

**Files:**
- Create: `lib/features/mercenary/data/mercenary_repository.dart`
- Create: `lib/features/quest/data/quest_repository.dart`
- Create: `lib/features/movement/data/movement_repository.dart`

- [ ] **Step 1: MercenaryRepository 작성**

`lib/features/mercenary/data/mercenary_repository.dart`:
```dart
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';

class MercenaryRepository {
  Box<Mercenary> get _box => Hive.box<Mercenary>(HiveInitializer.mercenaryBoxName);

  List<Mercenary> getAll() => _box.values.toList();

  List<Mercenary> getAlive() =>
      _box.values.where((m) => m.status != MercenaryStatus.dead).toList();

  List<Mercenary> getAvailable() =>
      _box.values.where((m) => m.isAvailable).toList();

  Future<Mercenary> recruit({
    required List<Job> jobs,
    required List<TraitData> traits,
    required List<PersonName> names,
  }) async {
    final merc = RecruitmentService.generateMercenary(
      jobs: jobs,
      traits: traits,
      names: names,
      random: Random(),
    );
    await _box.add(merc);
    return merc;
  }

  Future<void> updateStatus(String mercId, MercenaryStatus status, {DateTime? endTime}) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    merc.status = status;
    if (status == MercenaryStatus.injured) {
      merc.injuryEndTime = endTime;
    } else if (status == MercenaryStatus.tired) {
      merc.tiredEndTime = endTime;
    }
    await merc.save();
  }

  Future<void> setDispatched(String mercId, bool dispatched) async {
    final merc = _box.values.firstWhere((m) => m.id == mercId);
    merc.isDispatched = dispatched;
    await merc.save();
  }

  Future<void> removeDead(String mercId) async {
    final index = _box.values.toList().indexWhere((m) => m.id == mercId);
    if (index >= 0) await _box.deleteAt(index);
  }
}
```

- [ ] **Step 2: QuestRepository 작성**

`lib/features/quest/data/quest_repository.dart`:
```dart
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

class QuestRepository {
  Box<ActiveQuest> get _box => Hive.box<ActiveQuest>(HiveInitializer.questBoxName);

  List<ActiveQuest> getAll() => _box.values.toList();

  List<ActiveQuest> getPending() =>
      _box.values.where((q) => q.status == QuestStatus.pending).toList();

  List<ActiveQuest> getInProgress() =>
      _box.values.where((q) => q.status == QuestStatus.inProgress).toList();

  Future<void> addQuests(List<ActiveQuest> quests) async {
    for (final quest in quests) {
      await _box.add(quest);
    }
  }

  Future<void> startQuest(String questId, List<String> mercIds, DateTime endTime) async {
    final quest = _box.values.firstWhere((q) => q.id == questId);
    quest.dispatchedMercIds = mercIds;
    quest.startTime = DateTime.now();
    quest.endTime = endTime;
    quest.status = QuestStatus.inProgress;
    await quest.save();
  }

  Future<void> completeQuest(String questId, QuestResult result) async {
    final quest = _box.values.firstWhere((q) => q.id == questId);
    quest.status = QuestStatus.completed;
    quest.result = result;
    await quest.save();
  }

  Future<void> clearPending() async {
    final pending = _box.values.where((q) => q.status == QuestStatus.pending).toList();
    for (final quest in pending) {
      await quest.delete();
    }
  }

  Future<void> clearCompleted() async {
    final completed = _box.values.where((q) => q.status == QuestStatus.completed).toList();
    for (final quest in completed) {
      await quest.delete();
    }
  }
}
```

- [ ] **Step 3: MovementRepository 작성**

`lib/features/movement/data/movement_repository.dart`:
```dart
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';

class MovementRepository {
  Box<UserData> get _box => Hive.box<UserData>(HiveInitializer.userBoxName);

  UserData? get userData => _box.isNotEmpty ? _box.getAt(0) : null;

  Future<void> startMovement(int targetRegion, int targetSector, DateTime endTime) async {
    final user = userData;
    if (user == null) return;
    user.isMoving = true;
    user.moveTargetRegion = targetRegion;
    user.moveTargetSector = targetSector;
    user.moveEndTime = endTime;
    await user.save();
  }

  Future<void> completeMovement() async {
    final user = userData;
    if (user == null) return;
    user.region = user.moveTargetRegion!;
    user.sector = user.moveTargetSector!;
    user.isMoving = false;
    user.moveTargetRegion = null;
    user.moveTargetSector = null;
    user.moveEndTime = null;
    await user.save();
  }
}
```

- [ ] **Step 4: 빌드 확인**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 5: 커밋**

```bash
git add .
git commit -m "feat: add Mercenary, Quest, and Movement repositories"
```

---

### Task 10: Feature Providers (Mercenary, Quest, Movement)

**Files:**
- Create: `lib/features/mercenary/domain/mercenary_provider.dart`
- Create: `lib/features/quest/domain/quest_provider.dart`
- Create: `lib/features/movement/domain/movement_provider.dart`

- [ ] **Step 1: MercenaryProvider 작성**

`lib/features/mercenary/domain/mercenary_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/mercenary/data/mercenary_repository.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';

final mercenaryRepositoryProvider = Provider((ref) => MercenaryRepository());

final mercenaryListProvider = StateNotifierProvider<MercenaryListNotifier, List<Mercenary>>((ref) {
  return MercenaryListNotifier(ref);
});

class MercenaryListNotifier extends StateNotifier<List<Mercenary>> {
  final Ref ref;
  late final MercenaryRepository _repo;

  MercenaryListNotifier(this.ref) : super([]) {
    _repo = ref.read(mercenaryRepositoryProvider);
    _load();
    ref.listen(gameTickProvider, (_, __) => _checkTimers());
  }

  void _load() {
    state = _repo.getAll();
  }

  void refresh() => _load();

  void _checkTimers() {
    final now = DateTime.now();
    bool changed = false;
    for (final merc in state) {
      if (merc.status == MercenaryStatus.tired && merc.tiredEndTime != null) {
        if (now.isAfter(merc.tiredEndTime!)) {
          merc.status = MercenaryStatus.normal;
          merc.tiredEndTime = null;
          merc.save();
          changed = true;
        }
      }
      if (merc.status == MercenaryStatus.injured && merc.injuryEndTime != null) {
        if (now.isAfter(merc.injuryEndTime!)) {
          merc.status = MercenaryStatus.normal;
          merc.injuryEndTime = null;
          merc.save();
          changed = true;
        }
      }
    }
    if (changed) _load();
  }

  Future<Mercenary?> recruit() async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return null;
    final merc = await _repo.recruit(
      jobs: staticData.jobs,
      traits: staticData.traits,
      names: staticData.personNames,
    );
    _load();
    return merc;
  }
}
```

- [ ] **Step 2: QuestProvider 작성**

`lib/features/quest/domain/quest_provider.dart`:
```dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/quest/data/quest_repository.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_generator.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';

final questRepositoryProvider = Provider((ref) => QuestRepository());

final questListProvider = StateNotifierProvider<QuestListNotifier, List<ActiveQuest>>((ref) {
  return QuestListNotifier(ref);
});

class QuestListNotifier extends StateNotifier<List<ActiveQuest>> {
  final Ref ref;
  late final QuestRepository _repo;

  QuestListNotifier(this.ref) : super([]) {
    _repo = ref.read(questRepositoryProvider);
    _load();
    ref.listen(gameTickProvider, (_, __) => _checkCompletions());
  }

  void _load() {
    state = _repo.getAll();
  }

  void refresh() => _load();

  Future<void> generateQuests() async {
    final staticData = ref.read(staticDataProvider).value;
    final userData = ref.read(userDataProvider);
    if (staticData == null || userData == null) return;

    final region = staticData.regions.firstWhere((r) => r.region == userData.region);

    await _repo.clearPending();
    final quests = QuestGenerator.generateQuests(
      regionTier: region.regionTier,
      regionId: userData.region,
      questPools: staticData.questPools,
      questTypes: staticData.questTypes,
      count: 5,
      random: Random(),
    );
    await _repo.addQuests(quests);
    _load();
  }

  Future<void> dispatch(String questId, List<String> mercIds) async {
    final staticData = ref.read(staticDataProvider).value;
    final speedMult = ref.read(speedMultiplierProvider);
    if (staticData == null) return;

    final quest = state.firstWhere((q) => q.id == questId);
    final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);

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
  }

  void _checkCompletions() {
    final now = DateTime.now();
    for (final quest in state) {
      if (quest.status == QuestStatus.inProgress && quest.endTime != null) {
        if (now.isAfter(quest.endTime!)) {
          _completeQuest(quest);
        }
      }
    }
  }

  Future<void> _completeQuest(ActiveQuest quest) async {
    final staticData = ref.read(staticDataProvider).value;
    if (staticData == null) return;

    final random = Random();
    final mercs = ref.read(mercenaryListProvider)
        .where((m) => quest.dispatchedMercIds.contains(m.id))
        .toList();

    final partyPower = mercs.fold<int>(0, (sum, m) => sum + m.effectiveAtk);
    final difficulty = staticData.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => staticData.difficulties.first,
    );
    final questType = staticData.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final userData = ref.read(userDataProvider);

    final distancePenalty = userData != null ? (quest.region - userData.region).abs() : 0;

    final successRate = QuestCalculator.calculateSuccessRate(
      partyPower: partyPower,
      enemyPower: difficulty.enemyPower,
      traitBonuses: mercs.map((m) => m.traitId).toList(),
      questTypeId: quest.questTypeId,
      distancePenalty: distancePenalty,
      random: random,
    );

    final roll = random.nextDouble() * 100;
    final resultType = QuestCalculator.determineResult(successRate: successRate, roll: roll);

    final questResult = switch (resultType) {
      QuestResultType.greatSuccess => QuestResult.greatSuccess,
      QuestResultType.success => QuestResult.success,
      QuestResultType.failure => QuestResult.failure,
      QuestResultType.criticalFailure => QuestResult.criticalFailure,
    };

    await _repo.completeQuest(quest.id, questResult);

    // Process rewards
    if (resultType == QuestResultType.greatSuccess || resultType == QuestResultType.success) {
      final reward = QuestCalculator.calculateReward(
        baseReward: questType.baseReward,
        rewardMultiplier: difficulty.rewardMultiplier,
        isGreatSuccess: resultType == QuestResultType.greatSuccess,
      );
      await ref.read(userDataProvider.notifier).addGold(reward);
    }

    // Process damage
    final mercRepo = ref.read(mercenaryRepositoryProvider);
    final speedMult = ref.read(speedMultiplierProvider);

    for (final merc in mercs) {
      await mercRepo.setDispatched(merc.id, false);

      if (resultType == QuestResultType.failure || resultType == QuestResultType.criticalFailure) {
        final damageRoll = random.nextDouble();
        final damageResult = QuestCalculator.calculateDamage(
          roll: damageRoll,
          deathRate: difficulty.deathRate,
          injuryRate: difficulty.injuryRate,
          traitId: merc.traitId,
        );

        if (damageResult == DamageResult.dead) {
          await mercRepo.updateStatus(merc.id, MercenaryStatus.dead);
        } else if (damageResult == DamageResult.injured) {
          final recoverySeconds = (difficulty.level * 10 * 60 / speedMult).round();
          final recoveryTime = DateTime.now().add(Duration(seconds: recoverySeconds));
          await mercRepo.updateStatus(merc.id, MercenaryStatus.injured, endTime: recoveryTime);
        }
      } else {
        // Success: set tired
        final tiredSeconds = (5 * 60 / speedMult).round();
        final tiredEnd = DateTime.now().add(Duration(seconds: tiredSeconds));
        await mercRepo.updateStatus(merc.id, MercenaryStatus.tired, endTime: tiredEnd);
      }
    }

    ref.read(mercenaryListProvider.notifier).refresh();
    _load();
  }
}
```

- [ ] **Step 3: MovementProvider 작성**

`lib/features/movement/domain/movement_provider.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/movement/data/movement_repository.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';

final movementRepositoryProvider = Provider((ref) => MovementRepository());

final movementProvider = StateNotifierProvider<MovementNotifier, UserData?>((ref) {
  return MovementNotifier(ref);
});

class MovementNotifier extends StateNotifier<UserData?> {
  final Ref ref;
  late final MovementRepository _repo;

  MovementNotifier(this.ref) : super(null) {
    _repo = ref.read(movementRepositoryProvider);
    _load();
    ref.listen(gameTickProvider, (_, __) => _checkArrival());
  }

  void _load() {
    state = _repo.userData;
  }

  Future<void> startMovement(int targetRegion, int targetSector) async {
    final user = state;
    if (user == null || user.isMoving) return;

    final distance = UserData.calculateDistance(
      user.region, user.sector, targetRegion, targetSector,
    );
    final speedMult = ref.read(speedMultiplierProvider);
    final duration = UserData.calculateMoveTime(distance, speedMultiplier: speedMult);
    final endTime = DateTime.now().add(duration);

    await _repo.startMovement(targetRegion, targetSector, endTime);
    _load();
    // Also update the main user data provider
    ref.read(userDataProvider.notifier).addGold(0); // trigger rebuild
  }

  void _checkArrival() {
    final user = _repo.userData;
    if (user == null || !user.isMoving || user.moveEndTime == null) return;

    if (DateTime.now().isAfter(user.moveEndTime!)) {
      _completeMovement();
    }
  }

  Future<void> _completeMovement() async {
    await _repo.completeMovement();
    _load();
    ref.read(userDataProvider.notifier).addGold(0); // trigger rebuild
    // Generate new quests for the new region
    await ref.read(questListProvider.notifier).generateQuests();
  }
}
```

- [ ] **Step 4: 빌드 확인**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 5: 커밋**

```bash
git add .
git commit -m "feat: add Mercenary, Quest, and Movement providers with game logic integration"
```

---

### Task 11: UI — 하단 네비게이션 및 홈 화면

**Files:**
- Create: `lib/shared/widgets/bottom_nav_bar.dart`
- Create: `lib/features/home/view/home_screen.dart`
- Create: `lib/features/home/view/campsite_painter.dart`
- Create: `lib/app.dart`

- [ ] **Step 1: BottomNavBar 작성**

`lib/shared/widgets/bottom_nav_bar.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Text('🗺', style: TextStyle(fontSize: 22)), label: '이동'),
        BottomNavigationBarItem(icon: Text('⚔', style: TextStyle(fontSize: 22)), label: '파견'),
        BottomNavigationBarItem(icon: Text('🏕', style: TextStyle(fontSize: 22)), label: '홈'),
        BottomNavigationBarItem(icon: Text('👥', style: TextStyle(fontSize: 22)), label: '모집'),
        BottomNavigationBarItem(icon: Text('⚙', style: TextStyle(fontSize: 22)), label: '설정'),
      ],
    );
  }
}
```

- [ ] **Step 2: CampsitePainter 작성**

`lib/features/home/view/campsite_painter.dart`:
```dart
import 'package:flutter/material.dart';

class CampsitePainter extends CustomPainter {
  final int mercenaryCount;

  CampsitePainter({required this.mercenaryCount});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Ground
    final groundPaint = Paint()..color = const Color(0xFFE8E0D0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: size.width * 0.7, height: 40),
      groundPaint,
    );

    // Campfire logs
    final logPaint = Paint()..color = const Color(0xFF8B4513)..strokeWidth = 4;
    canvas.drawLine(Offset(cx - 12, cy + 8), Offset(cx + 12, cy + 8), logPaint);
    canvas.drawLine(Offset(cx - 8, cy + 12), Offset(cx + 8, cy + 4), logPaint);

    // Fire
    final firePaint = Paint()..color = const Color(0xFFFF6600);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 16, height: 24),
      firePaint,
    );
    final innerFire = Paint()..color = const Color(0xFFFFCC00);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 2), width: 8, height: 14),
      innerFire,
    );

    // Sparks
    final sparkPaint = Paint()..color = const Color(0xFFFFAA00)..strokeWidth = 2;
    canvas.drawCircle(Offset(cx - 4, cy - 20), 2, sparkPaint);
    canvas.drawCircle(Offset(cx + 6, cy - 24), 1.5, sparkPaint);

    // Mercenaries (simple dot figures)
    final bodyPaint = Paint()..color = const Color(0xFF444444);
    final headPaint = Paint()..color = const Color(0xFF666666);
    final positions = [
      Offset(cx - 50, cy + 5),
      Offset(cx + 50, cy + 5),
      Offset(cx - 30, cy + 15),
      Offset(cx + 30, cy + 15),
      Offset(cx - 60, cy + 18),
      Offset(cx + 60, cy + 18),
    ];

    for (var i = 0; i < mercenaryCount.clamp(0, positions.length); i++) {
      final pos = positions[i];
      // Body
      canvas.drawRect(Rect.fromCenter(center: pos, width: 8, height: 12), bodyPaint);
      // Head
      canvas.drawCircle(Offset(pos.dx, pos.dy - 10), 5, headPaint);
    }

    // Tent (left)
    final tentPaint = Paint()..color = const Color(0xFF9E8E7E);
    final tentPath = Path()
      ..moveTo(cx - 80, cy - 10)
      ..lineTo(cx - 60, cy - 35)
      ..lineTo(cx - 40, cy - 10)
      ..close();
    canvas.drawPath(tentPath, tentPaint);

    // Tent (right)
    final tentPath2 = Path()
      ..moveTo(cx + 40, cy - 10)
      ..lineTo(cx + 60, cy - 35)
      ..lineTo(cx + 80, cy - 10)
      ..close();
    canvas.drawPath(tentPath2, tentPaint);
  }

  @override
  bool shouldRepaint(CampsitePainter oldDelegate) =>
      mercenaryCount != oldDelegate.mercenaryCount;
}
```

- [ ] **Step 3: HomeScreen 작성**

`lib/features/home/view/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/home/view/campsite_painter.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_provider.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final quests = ref.watch(questListProvider);
    final movement = ref.watch(movementProvider);
    ref.watch(gameTickProvider);

    if (userData == null) return const Center(child: CircularProgressIndicator());

    final inProgressQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();
    final aliveMercs = mercs.where((m) => m.status != MercenaryStatus.dead).length;

    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('💰 ${userData.gold}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('대륙 ${userData.continent} : 지역 ${userData.region} : 섹터 ${userData.sector}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
            ],
          ),
        ),

        // Campsite
        Expanded(
          child: Container(
            color: AppTheme.surfaceAlt,
            child: Center(
              child: CustomPaint(
                size: const Size(300, 200),
                painter: CampsitePainter(mercenaryCount: aliveMercs),
              ),
            ),
          ),
        ),

        // Progress panel
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('진행 상황', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (userData.isMoving && userData.moveEndTime != null)
                TimerDisplay(
                  label: '🗺 이동 → 지역 ${userData.moveTargetRegion}',
                  remaining: userData.moveEndTime!.difference(DateTime.now()),
                ),
              for (final quest in inProgressQuests)
                if (quest.endTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TimerDisplay(
                      label: '⚔ ${quest.questName}',
                      remaining: quest.endTime!.difference(DateTime.now()),
                    ),
                  ),
              if (!userData.isMoving && inProgressQuests.isEmpty)
                const Text('진행 중인 활동이 없습니다',
                    style: TextStyle(fontSize: 14, color: AppTheme.textHint)),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: App 쉘 작성**

`lib/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/shared/widgets/bottom_nav_bar.dart';
import 'package:band_of_mercenaries/features/home/view/home_screen.dart';
import 'package:band_of_mercenaries/features/movement/view/movement_screen.dart';
import 'package:band_of_mercenaries/features/quest/view/dispatch_screen.dart';
import 'package:band_of_mercenaries/features/mercenary/view/recruit_screen.dart';
import 'package:band_of_mercenaries/features/settings/view/settings_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 2); // Home is default

class BandOfMercenariesApp extends StatelessWidget {
  const BandOfMercenariesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Band of Mercenaries',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    MovementScreen(),
    DispatchScreen(),
    HomeScreen(),
    RecruitScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: SafeArea(child: _screens[currentTab]),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentTab,
        onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
      ),
    );
  }
}
```

- [ ] **Step 5: 커밋**

```bash
git add .
git commit -m "feat: add bottom navigation, home screen with campsite painter, and app shell"
```

---

### Task 12: UI — 이동 화면

**Files:**
- Create: `lib/features/movement/view/movement_screen.dart`

- [ ] **Step 1: MovementScreen 작성**

`lib/features/movement/view/movement_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_model.dart';
import 'package:band_of_mercenaries/features/movement/domain/movement_provider.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';

class MovementScreen extends ConsumerStatefulWidget {
  const MovementScreen({super.key});

  @override
  ConsumerState<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends ConsumerState<MovementScreen> {
  int _selectedRegion = 1;
  int _selectedSector = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = ref.read(userDataProvider);
      if (userData != null) {
        setState(() {
          _selectedRegion = userData.region;
          _selectedSector = userData.sector;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final staticData = ref.watch(staticDataProvider);
    ref.watch(gameTickProvider);

    if (userData == null) return const Center(child: CircularProgressIndicator());

    return staticData.when(
      data: (data) {
        final currentRegion = data.regions.firstWhere((r) => r.region == userData.region);
        final targetRegion = data.regions.firstWhere(
          (r) => r.region == _selectedRegion,
          orElse: () => currentRegion,
        );
        final distance = UserData.calculateDistance(
          userData.region, userData.sector, _selectedRegion, _selectedSector,
        );
        final speedMult = ref.watch(speedMultiplierProvider);
        final moveTime = UserData.calculateMoveTime(distance, speedMultiplier: speedMult);

        return Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💰 ${userData.gold}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('대륙 ${userData.continent} : 지역 ${userData.region} : 섹터 ${userData.sector}',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // Moving indicator
                    if (userData.isMoving && userData.moveEndTime != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.tier3Bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TimerDisplay(
                          label: '🗺 이동 중 → 지역 ${userData.moveTargetRegion}',
                          remaining: userData.moveEndTime!.difference(DateTime.now()),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Current location
                    Text('현재 위치', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                    const SizedBox(height: 4),
                    Text('${currentRegion.regionName} (지역 ${userData.region} : 섹터 ${userData.sector})',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Tier ${currentRegion.regionTier} · 추천 전투력 ${currentRegion.recommendPower}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                    const SizedBox(height: 20),

                    // Region selector
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Text('지역 선택', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: userData.isMoving ? null : () {
                                  setState(() {
                                    if (_selectedRegion > 1) _selectedRegion--;
                                  });
                                },
                                icon: const Text('◀', style: TextStyle(fontSize: 16)),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.surface,
                                  side: const BorderSide(color: AppTheme.border),
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                width: 110,
                                child: Column(
                                  children: [
                                    Text('지역 $_selectedRegion',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                    Text('${targetRegion.regionName} · Tier ${targetRegion.regionTier}',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                onPressed: userData.isMoving ? null : () {
                                  setState(() {
                                    if (_selectedRegion < 199) _selectedRegion++;
                                  });
                                },
                                icon: const Text('▶', style: TextStyle(fontSize: 16)),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.surface,
                                  side: const BorderSide(color: AppTheme.border),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sector selector
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Text('섹터 선택', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: List.generate(10, (i) {
                              final sector = i + 1;
                              final isSelected = sector == _selectedSector;
                              return GestureDetector(
                                onTap: userData.isMoving ? null : () {
                                  setState(() => _selectedSector = sector);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primary : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: isSelected ? null : Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    '$sector',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Travel time & button
                    if (distance > 0)
                      Text(
                        '이동 소요시간: ',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary),
                      ),
                    if (distance > 0)
                      Text(
                        '약 ${moveTime.inSeconds}초',
                        style: const TextStyle(fontSize: 14, color: AppTheme.timerBlue, fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: userData.isMoving || distance == 0
                            ? null
                            : () {
                                ref.read(movementProvider.notifier)
                                    .startMovement(_selectedRegion, _selectedSector);
                              },
                        child: Text(userData.isMoving ? '이동 중...' : '이동 시작'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 3: 커밋**

```bash
git add .
git commit -m "feat: add movement screen with region/sector selection"
```

---

### Task 13: UI — 파견 화면 및 결과 다이얼로그

**Files:**
- Create: `lib/features/quest/view/dispatch_screen.dart`
- Create: `lib/features/quest/view/quest_result_dialog.dart`

- [ ] **Step 1: DispatchScreen 작성**

`lib/features/quest/view/dispatch_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_calculator.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/quest/view/quest_result_dialog.dart';
import 'package:band_of_mercenaries/shared/widgets/timer_display.dart';

class DispatchScreen extends ConsumerStatefulWidget {
  const DispatchScreen({super.key});

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  String? _selectedQuestId;
  final Set<String> _selectedMercIds = {};

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final quests = ref.watch(questListProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final staticData = ref.watch(staticDataProvider);
    ref.watch(gameTickProvider);

    if (userData == null) return const Center(child: CircularProgressIndicator());

    if (userData.isMoving) {
      return const Center(
        child: Text('이동 중에는 파견할 수 없습니다', style: TextStyle(fontSize: 16, color: AppTheme.textHint)),
      );
    }

    // Check for completed quests to show results
    final completed = quests.where((q) => q.status == QuestStatus.completed).toList();
    if (completed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResult(context, completed.first, ref);
      });
    }

    final pendingQuests = quests.where((q) => q.status == QuestStatus.pending).toList();
    final inProgressQuests = quests.where((q) => q.status == QuestStatus.inProgress).toList();

    return staticData.when(
      data: (data) {
        return Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('💰 ${userData.gold}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${data.regions.firstWhere((r) => r.region == userData.region).regionName} (지역 ${userData.region})',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // In-progress quests
                    for (final quest in inProgressQuests)
                      if (quest.endTime != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.tier3Bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TimerDisplay(
                              label: '⚔ ${quest.questName}',
                              remaining: quest.endTime!.difference(DateTime.now()),
                            ),
                          ),
                        ),

                    // Quest list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('가능한 퀘스트 (${pendingQuests.length}개)',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
                        if (pendingQuests.isEmpty)
                          TextButton(
                            onPressed: () => ref.read(questListProvider.notifier).generateQuests(),
                            child: const Text('퀘스트 생성'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    for (final quest in pendingQuests)
                      _buildQuestCard(quest, data),

                    // Dispatch panel
                    if (_selectedQuestId != null) ...[
                      const SizedBox(height: 12),
                      _buildDispatchPanel(mercs, data),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildQuestCard(ActiveQuest quest, StaticGameData data) {
    final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
    final isSelected = _selectedQuestId == quest.id;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedQuestId = isSelected ? null : quest.id;
        _selectedMercIds.clear();
      }),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(quest.questName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(questType.name, style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
              ],
            ),
            const SizedBox(height: 4),
            Text('난이도 ${quest.difficulty} · 보상 ${questType.baseReward}G · 소요 ${questType.baseDuration}초',
                style: const TextStyle(fontSize: 13, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchPanel(List<Mercenary> mercs, StaticGameData data) {
    final quest = ref.read(questListProvider).firstWhere((q) => q.id == _selectedQuestId);
    final difficulty = data.difficulties.firstWhere(
      (d) => d.level == quest.difficulty.clamp(1, 5),
      orElse: () => data.difficulties.first,
    );
    final selectedMercs = mercs.where((m) => _selectedMercIds.contains(m.id)).toList();
    final partyPower = selectedMercs.fold<int>(0, (sum, m) => sum + m.effectiveAtk);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('파견 인원 선택', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: mercs.map((merc) {
              final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
              final isSelected = _selectedMercIds.contains(merc.id);
              final canSelect = merc.isAvailable;

              return GestureDetector(
                onTap: canSelect
                    ? () => setState(() {
                          if (isSelected) {
                            _selectedMercIds.remove(merc.id);
                          } else {
                            _selectedMercIds.add(merc.id);
                          }
                        })
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : (canSelect ? AppTheme.surface : AppTheme.surface),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: canSelect ? AppTheme.border : AppTheme.borderLight),
                  ),
                  child: Text(
                    '${isSelected ? '✓ ' : ''}${merc.name} (${job.name})',
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : (canSelect ? AppTheme.textSecondary : const Color(0xFF999999)),
                      decoration: canSelect ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            '예상 성공률: ${_selectedMercIds.isEmpty ? "-" : "${(partyPower / difficulty.enemyPower * 50 + 50).clamp(5, 95).round()}%"} · 전투력: $partyPower/${difficulty.enemyPower}',
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedMercIds.isEmpty
                  ? null
                  : () {
                      ref.read(questListProvider.notifier)
                          .dispatch(_selectedQuestId!, _selectedMercIds.toList());
                      setState(() {
                        _selectedQuestId = null;
                        _selectedMercIds.clear();
                      });
                    },
              child: const Text('파견 출발'),
            ),
          ),
        ],
      ),
    );
  }

  void _showResult(BuildContext context, ActiveQuest quest, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuestResultDialog(quest: quest),
    ).then((_) {
      ref.read(questRepositoryProvider).clearCompleted();
      ref.read(questListProvider.notifier).refresh();
    });
  }
}
```

- [ ] **Step 2: QuestResultDialog 작성**

`lib/features/quest/view/quest_result_dialog.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

class QuestResultDialog extends ConsumerWidget {
  final ActiveQuest quest;

  const QuestResultDialog({super.key, required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider);
    final mercs = ref.watch(mercenaryListProvider);

    return staticData.when(
      data: (data) {
        final questType = data.questTypes.firstWhere((t) => t.id == quest.questTypeId);
        final (label, color, bgColor) = switch (quest.result) {
          QuestResult.greatSuccess => ('대성공!', AppTheme.greatSuccess, AppTheme.greatSuccessBg),
          QuestResult.success => ('성공!', AppTheme.success, AppTheme.successBg),
          QuestResult.failure => ('실패...', AppTheme.failure, AppTheme.failureBg),
          QuestResult.criticalFailure => ('대실패...', AppTheme.criticalFailure, AppTheme.criticalFailureBg),
          null => ('완료', AppTheme.textSecondary, AppTheme.tier1Bg),
        };

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('퀘스트 완료', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                const SizedBox(height: 4),
                Text(quest.questName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text('${questType.name} · 난이도 ${quest.difficulty}',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
                const SizedBox(height: 16),

                // Result banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                  ),
                ),
                const SizedBox(height: 16),

                // Mercenary status
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('용병 상태', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                for (final mercId in quest.dispatchedMercIds)
                  _buildMercStatus(mercId, mercs, data),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMercStatus(String mercId, List mercs, StaticGameData data) {
    final merc = mercs.cast().firstWhere((m) => m.id == mercId, orElse: () => null);
    if (merc == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('알 수 없는 용병', style: TextStyle(fontSize: 14)),
            Text('사망', style: TextStyle(fontSize: 14, color: AppTheme.criticalFailure, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
    final statusText = switch (merc.status) {
      MercenaryStatus.normal || MercenaryStatus.tired => '무사 귀환',
      MercenaryStatus.injured => '부상',
      MercenaryStatus.dead => '사망',
    };
    final statusColor = switch (merc.status) {
      MercenaryStatus.normal || MercenaryStatus.tired => AppTheme.textSecondary,
      MercenaryStatus.injured => AppTheme.failure,
      MercenaryStatus.dead => AppTheme.criticalFailure,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${merc.name} (${job.name})', style: const TextStyle(fontSize: 14)),
          Text(statusText, style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: 빌드 확인**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 4: 커밋**

```bash
git add .
git commit -m "feat: add dispatch screen and quest result dialog"
```

---

### Task 14: UI — 모집 화면 및 설정 화면

**Files:**
- Create: `lib/features/mercenary/view/recruit_screen.dart`
- Create: `lib/features/mercenary/view/mercenary_card.dart`
- Create: `lib/features/settings/view/settings_screen.dart`

- [ ] **Step 1: MercenaryCard 작성**

`lib/features/mercenary/view/mercenary_card.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/shared/widgets/status_badge.dart';

class MercenaryCard extends StatelessWidget {
  final Mercenary mercenary;
  final Job job;
  final TraitData trait;

  const MercenaryCard({
    super.key,
    required this.mercenary,
    required this.job,
    required this.trait,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTheme.tierColor(job.tier);
    final tierBg = AppTheme.tierBgColor(job.tier);
    final traitColor = AppTheme.traitColors[trait.id] ?? AppTheme.textHint;

    String? timerText;
    if (mercenary.status == MercenaryStatus.injured && mercenary.injuryEndTime != null) {
      final remaining = mercenary.injuryEndTime!.difference(DateTime.now());
      if (remaining.isNegative) {
        timerText = null;
      } else {
        final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
        final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
        timerText = '$m:$s';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(mercenary.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text(job.name, style: TextStyle(fontSize: 13, color: tierColor, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tierBg,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('T${job.tier}',
                        style: TextStyle(fontSize: 12, color: tierColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (mercenary.isDispatched)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tier1Bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('파견중', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                )
              else
                StatusBadge(status: mercenary.status, timerText: timerText),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ATK ${mercenary.atk} · DEF ${mercenary.def} · HP ${mercenary.hp} · ',
            style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          ),
          Text(trait.name, style: TextStyle(fontSize: 13, color: traitColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: RecruitScreen 작성**

`lib/features/mercenary/view/recruit_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/view/mercenary_card.dart';

class RecruitScreen extends ConsumerWidget {
  const RecruitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider);
    final mercs = ref.watch(mercenaryListProvider);
    final staticData = ref.watch(staticDataProvider);
    final speedMult = ref.watch(speedMultiplierProvider);
    ref.watch(gameTickProvider);

    if (userData == null) return const Center(child: CircularProgressIndicator());

    final aliveMercs = mercs.where((m) => m.status != MercenaryStatus.dead).toList();
    final freeRecruitCooldown = Duration(seconds: (2 * 3600 / speedMult).round());
    final nextFreeRecruit = userData.lastFreeRecruit.add(freeRecruitCooldown);
    final canFreeRecruit = DateTime.now().isAfter(nextFreeRecruit);
    final remaining = nextFreeRecruit.difference(DateTime.now());

    return staticData.when(
      data: (data) => Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('💰 ${userData.gold}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('용병단 ${aliveMercs.length}명', style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
              ],
            ),
          ),

          // Recruit buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: canFreeRecruit
                        ? () async {
                            await ref.read(mercenaryListProvider.notifier).recruit();
                            userData.lastFreeRecruit = DateTime.now();
                            await userData.save();
                          }
                        : null,
                    child: Column(
                      children: [
                        const Text('무료 모집'),
                        Text(
                          canFreeRecruit ? '가능!' : '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: canFreeRecruit ? Colors.white70 : Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: userData.gold >= 100
                        ? () async {
                            await ref.read(userDataProvider.notifier).spendGold(100);
                            await ref.read(mercenaryListProvider.notifier).recruit();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: const Column(
                      children: [
                        Text('골드 모집', style: TextStyle(color: AppTheme.textPrimary)),
                        Text('100G', style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mercenary list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('내 용병단', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: aliveMercs.length,
              itemBuilder: (_, i) {
                final merc = aliveMercs[i];
                final job = data.jobs.firstWhere((j) => j.id == merc.jobId);
                final trait = data.traits.firstWhere((t) => t.id == merc.traitId);
                return MercenaryCard(mercenary: merc, job: job, trait: trait);
              },
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
```

- [ ] **Step 3: SettingsScreen 작성**

`lib/features/settings/view/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speedMult = ref.watch(speedMultiplierProvider);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          const Text('시간 가속 모드', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('개발/테스트용 시간 가속 설정', style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final speed in [1.0, 10.0, 100.0])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: speed == speedMult
                        ? ElevatedButton(
                            onPressed: () {},
                            child: Text('x${speed.toInt()}'),
                          )
                        : OutlinedButton(
                            onPressed: () => ref.read(speedMultiplierProvider.notifier).state = speed,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: Text('x${speed.toInt()}', style: const TextStyle(color: AppTheme.textSecondary)),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('현재 배속: x${speedMult.toInt()}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 빌드 확인**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 5: 커밋**

```bash
git add .
git commit -m "feat: add recruit screen, mercenary card, and settings screen"
```

---

### Task 15: main.dart 및 앱 초기화

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: main.dart 작성**

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInitializer.initialize();
  runApp(const ProviderScope(child: AppBootstrap()));
}

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider);

    return staticData.when(
      data: (_) {
        final userData = ref.watch(userDataProvider);
        if (userData == null) {
          // First launch — initialize new game
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(userDataProvider.notifier).initializeNewGame();
          });
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return const BandOfMercenariesApp();
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('로딩 실패: $e'))),
      ),
    );
  }
}
```

- [ ] **Step 2: 전체 빌드 확인**

```bash
flutter analyze
```

Expected: No issues.

- [ ] **Step 3: 전체 테스트 실행**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 4: 커밋**

```bash
git add .
git commit -m "feat: add main.dart with Hive initialization and app bootstrap"
```

---

### Task 16: 최종 통합 테스트 및 실행 확인

- [ ] **Step 1: 앱 빌드 확인**

```bash
cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries
flutter build apk --debug
```

Expected: Build successful.

- [ ] **Step 2: 전체 테스트 실행**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: 최종 커밋**

```bash
git add .
git commit -m "chore: final integration — Band of Mercenaries prototype complete"
```
