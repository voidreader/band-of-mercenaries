# M8b 페이즈 4 #2 — CombatSimulator 의존 freezed/Hive 모델 개발 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1 — §CombatSimulationResult 11 필드 / §파견 시작 시점 스냅샷 고정 정책)
> - `Docs/content-design/[content]20260519_m8b_status_effects.md` (페이즈 1 #4 — §2 CombatStatusEffect 5 필드 + §3 hook 매핑)
> - `Docs/balance-design/[balance]20260519_m8b_class_skills.md` (페이즈 2 #1 — §10 CombatSkill 22 컬럼)
> - `Docs/balance-design/[balance]20260519_m8b_enemy_types.md` (페이즈 2 #2 — §14 EnemyArchetype/EnemySnapshot 구조)
> - `Docs/balance-design/[balance]20260519_m8b_status_effect_values.md` (페이즈 2 #3 — §10.2 default 10행)
> - `Docs/spec/[spec]20260519_m8b_combat_simulator.md` (페이즈 4 #1 — §2.2 데이터 요구사항: 의존 모델 19종 + StaticGameData 3 컬렉션 + Hive typeId 결정 가이드)
> - 페이즈 3 CSV 시드:
>   - `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.csv` (16행, 23 컬럼)
>   - `Docs/content-data/[status-effect]20260519_m8b-combat-status-effects.csv` (10행, 9 컬럼)
>   - `Docs/content-data/[enemy]20260519_m8b-enemies.csv` (26행, 20 컬럼)
>   - `Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.csv` (85행 추가, 기존 96 + 85 = 181)
> 작성일: 2026-05-19
> 마일스톤: M8b 페이즈 4 #2 (CombatSimulator 의존 freezed/Hive 모델 + 정적 데이터 통합)

## 1. 개요

페이즈 4 #1 `CombatSimulator` 순수 서비스 명세가 컴파일·운영 가능하도록, 의존 모델 9종(freezed 정적 카탈로그 + 일반 Hive 영속 모델 분리)·enum 10종·`StaticGameData` 3 컬렉션 확장·DataLoader/SyncService 3 신규 테이블 통합을 정의한다. M8a `CombatReport`(typeId 21, HiveField 0~7) 본체에 시뮬레이션 결과를 HiveField 8+로 임베드해 기존 보고서 호환을 유지한다.

본 명세는 데이터 구조 정의와 정적 데이터 로딩 인프라에 집중하며, 시뮬레이터 알고리즘(페이즈 4 #1)·`QuestCompletionService` 통합(페이즈 4 #3)·UI 표시(페이즈 4 #4)·검증 테스트(페이즈 4 #5)는 별도 명세에서 다룬다.

## 2. 요구사항

### 2.1 기능 요구사항

#### 2.1.1 모델 분류 정책 (정적 카탈로그 vs 시뮬레이션 영속 결과)

- **[FR-1]** 모델을 두 그룹으로 분리한다:
  - **그룹 A (정적 카탈로그)**: Supabase 동기화 + DataLoader JSON 캐시에서 로딩. freezed + json_serializable만 사용. **Hive typeId 불필요**. enum은 String 직렬화.
    - `CombatSkill`, `CombatStatusEffect`, `EnemyArchetype` (3 모델)
    - 관련 enum 7종: `ApplyMethod`, `StackPolicy`, `ActionCost`, `TriggerKind`, `TargetingKind`, `DispelKind`, `EnemyKind`
  - **그룹 B (시뮬레이션 영속 결과)**: `ActiveQuest.combatReport`(typeId 21) 내부에 임베드되어 Hive 박스(`quests`)에 영속. 일반 Hive 클래스 + `hive_generator`를 사용하며 freezed를 사용하지 않는다.
    - `CombatSimulationResult`, `CombatTurn`, `CombatAction`, `StatusEffectEvent`, `CombatantSnapshot`, `EnemySnapshot` (6 모델)
    - 관련 Hive enum 3종: `CombatExitCondition`, `BehaviorPattern`, `PositionRow`
  - 분리 근거:
    1. 정적 카탈로그는 정적 데이터 캐시(`staticDataCache` 박스 + JSON 파싱)로 충분. Hive 직렬화 오버헤드 불필요.
    2. 시뮬레이션 결과는 사용자 데이터(`quests` 박스)에 영속되며 앱 재실행 후에도 보고서 표시에 필요. Hive 타입 어댑터 필요.
    3. `CombatSimulationResult`는 시뮬레이터 반환값이자 페이즈 4 #3 통합 입력으로도 사용되므로 동일 필드 구조를 유지하되, 영속은 `CombatReport` 확장 필드에 분해 저장한다.

#### 2.1.2 그룹 A — 정적 카탈로그 모델 3종 + enum 7종

- **[FR-2]** `CombatSkill` freezed 모델 (페이즈 2 #1 §10 + 페이즈 3 CSV 23 컬럼 정합):
  - 위치: `band_of_mercenaries/lib/core/models/combat_skill.dart`
  - freezed + json_serializable. snake_case `@JsonKey`.
  - 필드 22+1개:
    ```dart
    @freezed
    class CombatSkill with _$CombatSkill {
      const factory CombatSkill({
        required String id,
        required String role,                                  // {warrior/rogue/ranger/mage/support/specialist}
        @Default(false) @JsonKey(name: 'party_only') bool partyOnly,
        @JsonKey(name: 'trigger_kind') required TriggerKind triggerKind,
        @JsonKey(name: 'trigger_condition') String? triggerCondition,
        @JsonKey(name: 'action_cost') required ActionCost actionCost,
        @Default(0) @JsonKey(name: 'cooldown_rounds') int cooldownRounds,
        @JsonKey(name: 'max_uses_per_combat') int? maxUsesPerCombat,
        @JsonKey(name: 'targeting_kind') required TargetingKind targetingKind,
        @JsonKey(name: 'targeting_max_count') int? targetingMaxCount,
        @JsonKey(name: 'targeting_priority') String? targetingPriority,
        @JsonKey(name: 'multi_hit_count') int? multiHitCount,
        @JsonKey(name: 'skill_damage_multiplier') double? skillDamageMultiplier,
        @JsonKey(name: 'shield_block_bonus') double? shieldBlockBonus,
        @JsonKey(name: 'crit_rate_bonus') double? critRateBonus,
        @JsonKey(name: 'status_effect_id') String? statusEffectId,
        @JsonKey(name: 'status_effect_apply_chance') double? statusEffectApplyChance,
        @JsonKey(name: 'status_effect_intensity') double? statusEffectIntensity,
        @JsonKey(name: 'status_effect_duration_turns') int? statusEffectDurationTurns,
        @JsonKey(name: 'dispel_kind') DispelKind? dispelKind,
        @JsonKey(name: 'dispel_max_count') int? dispelMaxCount,
        @JsonKey(name: 'display_label') required String displayLabel,
        required String description,
      }) = _CombatSkill;

      factory CombatSkill.fromJson(Map<String, dynamic> json) =>
          _$CombatSkillFromJson(json);
    }
    ```
  - 7 enum 모두 `JsonValue` 어노테이션으로 **CSV/DB 문자열 그대로** 매핑한다. 대부분 snake_case이나 `ActionCost.extraAction`은 기존 페이즈 2·3 산출물과 CSV가 `extraAction` camelCase 값을 사용한다.

- **[FR-3]** `CombatStatusEffect` freezed 모델 (페이즈 1 #4 §2 + 페이즈 2 #3 §10.2 + 페이즈 3 CSV 9 컬럼):
  - 위치: `band_of_mercenaries/lib/core/models/combat_status_effect.dart`
  - 필드:
    ```dart
    @freezed
    class CombatStatusEffect with _$CombatStatusEffect {
      const factory CombatStatusEffect({
        required String id,                                    // 예: 'buff_attack_up'
        required String kind,                                  // {buff/debuff/mez/dot} — String 보존(페이즈 4 #1이 String 비교 사용)
        @JsonKey(name: 'display_label') required String displayLabel,
        @JsonKey(name: 'default_duration_turns') required int defaultDurationTurns,
        @JsonKey(name: 'default_intensity') required double defaultIntensity,
        @JsonKey(name: 'stack_policy') required StackPolicy stackPolicy,
        @JsonKey(name: 'hook_target') required List<String> hookTarget,   // 예: ['attack']
        @JsonKey(name: 'apply_method') required ApplyMethod applyMethod,
        required String description,
      }) = _CombatStatusEffect;

      factory CombatStatusEffect.fromJson(Map<String, dynamic> json) =>
          _$CombatStatusEffectFromJson(json);
    }
    ```
  - **`kind` 필드는 enum이 아닌 String**(이유: 페이즈 4 #1 시뮬레이터가 `kind == 'debuff'` 같은 String 비교를 사용하며, 카탈로그 확장 시 enum 보일러플레이트 회피).
  - `clamp_max_intensity` / `clamp_max_stack` / `clamp_max_duration`은 페이즈 2 #3 §2에서 정의됐으나 **시드 CSV에 컬럼이 없음**. 정적 상수로 `combat_simulator_constants.dart`에 영속화(페이즈 4 #1 명세 §3.2 정합). 모델 필드에 포함하지 않는다.

- **[FR-4]** `EnemyArchetype` freezed 모델 (페이즈 2 #2 §14 + 페이즈 3 CSV 20 컬럼):
  - 위치: `band_of_mercenaries/lib/core/models/enemy_archetype.dart`
  - 필드:
    ```dart
    @freezed
    class EnemyArchetype with _$EnemyArchetype {
      const factory EnemyArchetype({
        required String id,
        required String name,
        @JsonKey(name: 'enemy_kind') required EnemyKind enemyKind,
        required String role,
        required int tier,
        @JsonKey(name: 'base_str') required int baseStr,
        @JsonKey(name: 'base_int') required int baseInt,
        @JsonKey(name: 'base_vit') required int baseVit,
        @JsonKey(name: 'base_agi') required int baseAgi,
        @JsonKey(name: 'base_hp') required int baseHp,
        @JsonKey(name: 'base_attack') required int baseAttack,
        @JsonKey(name: 'base_defense') required int baseDefense,
        @JsonKey(name: 'behavior_pattern') required BehaviorPattern behaviorPattern,
        @JsonKey(name: 'skill_ids') @Default([]) List<String> skillIds,
        @JsonKey(name: 'environment_tags') @Default([]) List<String> environmentTags,
        @JsonKey(name: 'faction_tags') @Default([]) List<String> factionTags,
        @JsonKey(name: 'ambush_compatible') @Default(false) bool ambushCompatible,
        @JsonKey(name: 'enemy_keyword_key') String? enemyKeywordKey,
        @JsonKey(name: 'elite_monster_id') String? eliteMonsterId,
        required String description,
      }) = _EnemyArchetype;

      factory EnemyArchetype.fromJson(Map<String, dynamic> json) =>
          _$EnemyArchetypeFromJson(json);
    }
    ```
  - `BehaviorPattern`은 정적 카탈로그에 들어가지만 시뮬레이션 영속(EnemySnapshot)에도 사용된다 → **enum이 두 곳에서 공유**. 해결책: `BehaviorPattern`을 Hive enum으로 정의하되 정적 카탈로그 JSON 매핑은 `@JsonValue` 어노테이션으로 snake_case String 매핑을 명시한다([FR-9.5] 참조).

- **[FR-5]** 정적 카탈로그용 enum 7종:
  - 위치: `band_of_mercenaries/lib/core/models/combat_enums.dart` (모든 enum 단일 파일)
  - **모두 `JsonValue` snake_case 매핑 명시**:
    ```dart
    enum ApplyMethod {
      @JsonValue('multiplicative') multiplicative,
      @JsonValue('additive') additive,
      @JsonValue('proportional') proportional,
      @JsonValue('absolute') absolute,
      @JsonValue('none') none,
    }
    enum StackPolicy {
      @JsonValue('refresh') refresh,
      @JsonValue('stack') stack,
      @JsonValue('ignore') ignore,
    }
    enum ActionCost {
      @JsonValue('action') action,
      @JsonValue('extraAction') extraAction,
      @JsonValue('passive') passive,
    }
    enum TriggerKind {
      @JsonValue('passive') passive,
      @JsonValue('active') active,
      @JsonValue('triggered') triggered,
      @JsonValue('on_hit') onHit,
      @JsonValue('on_kill') onKill,
    }
    enum TargetingKind {
      @JsonValue('self') self,
      @JsonValue('single_enemy') singleEnemy,
      @JsonValue('single_ally') singleAlly,
      @JsonValue('aoe_enemy') aoeEnemy,
      @JsonValue('aoe_ally') aoeAlly,
      @JsonValue('party') party,
    }
    enum DispelKind {
      @JsonValue('debuff') debuff,
      @JsonValue('buff') buff,
      @JsonValue('dot') dot,
      @JsonValue('debuff+dot') debuffPlusDot,
    }
    enum EnemyKind {
      @JsonValue('normal') normal,
      @JsonValue('elite') elite,
      @JsonValue('unique') unique,
    }
    ```
  - **Hive typeId 미할당**(정적 카탈로그 enum은 박스에 영속되지 않음).

#### 2.1.3 그룹 B — 시뮬레이션 영속 결과 모델 6종 + Hive enum 3종

- **[FR-6]** `CombatSimulationResult` 일반 Hive 모델 (페이즈 1 #1 §CombatSimulationResult 11 필드):
  - 위치: `band_of_mercenaries/lib/features/quest/domain/combat_simulation_result.dart`
  - typeId: **22**
  - freezed는 사용하지 않는다. `CombatReport`와 같은 일반 Hive 클래스 패턴(`extends HiveObject`, `@HiveType`, `@HiveField`)을 사용한다.
  - 필드:
    ```dart
    @HiveType(typeId: 22)
    class CombatSimulationResult extends HiveObject {
      @HiveField(0) QuestResult questResult;        // 기존 quest_model.dart QuestResult (HiveType typeId 3)
      @HiveField(1) List<CombatTurn> turns;
      @HiveField(2) String? protagonistMercId;
      @HiveField(3) List<String> featuredMercIds;
      @HiveField(4) List<String> injuredMercIds;
      @HiveField(5) List<String> deceasedMercIds;
      @HiveField(6) double objectiveProgress;
      @HiveField(7) CombatExitCondition exitCondition;
      @HiveField(8) List<StatusEffectEvent> statusEffectHistory;
      @HiveField(9) int seed;
      @HiveField(10) List<String> toneTags;

      CombatSimulationResult({
        required this.questResult,
        required this.turns,
        this.protagonistMercId,
        this.featuredMercIds = const [],
        this.injuredMercIds = const [],
        this.deceasedMercIds = const [],
        this.objectiveProgress = 0.0,
        required this.exitCondition,
        this.statusEffectHistory = const [],
        required this.seed,
        this.toneTags = const [],
      });
    }
    ```
  - **freezed + Hive 통합 패턴 회피**: `CombatReport`(`combat_report_model.dart`)는 freezed가 아닌 일반 Hive 클래스다. 본 명세도 동일 패턴으로 일반 Hive 클래스를 채택하는 것이 build_runner 충돌을 회피한다.
  - `CombatSimulationResult`는 페이즈 4 #3에서 `CombatReport` 확장 필드로 분해 저장한다. 단독 HiveField로 직접 저장하지 않지만, 시뮬레이터 결과 재사용·테스트·후속 직접 저장 가능성을 위해 typeId 22와 어댑터를 예약한다.
  - **[Q-1]** freezed vs 일반 Hive 클래스 선택 — 본 명세는 일반 Hive 클래스로 확정한다.

- **[FR-7]** `CombatTurn` Hive 모델:
  - 위치: `band_of_mercenaries/lib/features/quest/domain/combat_turn.dart`
  - typeId: **23**
  - 필드:
    ```dart
    @HiveType(typeId: 23)
    class CombatTurn extends HiveObject {
      @HiveField(0) int roundIndex;                            // 0=선제 라운드, 1+=일반 라운드
      @HiveField(1) String phase;                              // 'initiative'/'general'
      @HiveField(2) List<CombatAction> actions;
      @HiveField(3) List<String> exitConditionsTriggered;      // 라운드 종료 시 트리거된 enum names
      @HiveField(4) Map<String, int>? hpRemainingByCombatant;  // 라운드 종료 시점 HP 스냅샷 (디버그)
      
      CombatTurn({...});
    }
    ```

- **[FR-8]** `CombatAction` Hive 모델 (페이즈 4 #1 [FR-18.5] 메타데이터 6필드 포함):
  - 위치: `band_of_mercenaries/lib/features/quest/domain/combat_action.dart`
  - typeId: **24**
  - 필드:
    ```dart
    @HiveType(typeId: 24)
    class CombatAction extends HiveObject {
      @HiveField(0) String actorId;
      @HiveField(1) List<String> targetIds;
      @HiveField(2) String actionKind;                         // 'basic_attack'/'skill'/'dot_tick'/'skipped_stunned'/'extra_action'/'riposte'
      @HiveField(3) String? skillId;                           // CombatSkill.id (nullable)
      @HiveField(4) String? statusEffectId;                    // CombatStatusEffect.id (nullable)
      @HiveField(5) BehaviorPattern? behaviorPattern;          // 액터가 적이면 enum, 파티이면 null
      @HiveField(6) String? decisiveKeywordKey;                // combat_report_keywords.category == 'decisive' 매칭 키
      @HiveField(7) bool isComboCompression;                   // 페이즈 4 #1 [FR-18] §4 압축 라인 여부
      @HiveField(8) String position;                           // 'entry'/'development'/'crisis'/'resolution'/'aftermath'
      @HiveField(9) int damage;                                // 단발 피해(다단/광역은 합계)
      @HiveField(10) bool isCrit;
      @HiveField(11) bool isHit;
      @HiveField(12) bool isEvaded;
      @HiveField(13) bool isShielded;
      @HiveField(14) bool isKill;
      @HiveField(15) double shieldMitigation;                  // 0.0~0.6 적용된 감소율
      @HiveField(16) Map<String, dynamic>? extraMeta;          // JSON for AoE detail/multi-hit/extension
      
      CombatAction({...});
    }
    ```

- **[FR-9]** `StatusEffectEvent` Hive 모델 (페이즈 4 #1 [FR-17.5] endEvent 6 필드):
  - 위치: `band_of_mercenaries/lib/features/quest/domain/status_effect_event.dart`
  - typeId: **25**
  - 필드:
    ```dart
    @HiveType(typeId: 25)
    class StatusEffectEvent extends HiveObject {
      @HiveField(0) String eventType;                          // 'apply'/'end'/'stack_increase'/'dispel'
      @HiveField(1) int roundIndex;
      @HiveField(2) String targetId;
      @HiveField(3) String effectId;
      @HiveField(4) String labelKey;                           // CombatStatusEffect.displayLabel 캐싱
      @HiveField(5) String? endCause;                          // 'natural'/'dispel'/'death'/'combat_end' (event_type==end만)
      @HiveField(6) String? casterId;                          // apply/dispel 시 시전자
      @HiveField(7) double? intensity;                         // apply 시 적용 강도
      @HiveField(8) int? durationTurns;                        // apply 시 부여 지속
      @HiveField(9) int? stackResult;                          // stack_increase 시 결과 stack
      
      StatusEffectEvent({...});
    }
    ```

- **[FR-9.3]** `CombatantSnapshot` Hive 모델 (페이즈 1 #1 §파견 시작 시점 스냅샷 고정):
  - 위치: `band_of_mercenaries/lib/features/quest/domain/combatant_snapshot.dart`
  - typeId: **26**
  - 필드:
    ```dart
    @HiveType(typeId: 26)
    class CombatantSnapshot extends HiveObject {
      @HiveField(0) String mercId;
      @HiveField(1) String name;
      @HiveField(2) String jobId;
      @HiveField(3) int tier;
      @HiveField(4) int level;
      @HiveField(5) int effectiveStr;                          // EquipmentStatBonus 반영된 동결값
      @HiveField(6) int effectiveInt;
      @HiveField(7) int effectiveVit;
      @HiveField(8) int effectiveAgi;
      @HiveField(9) List<String> titleIds;
      @HiveField(10) List<String> traitIds;                    // 선천 + 후천 합산
      @HiveField(11) List<String> equippedItemIds;
      @HiveField(12) String role;                              // jobs.role
      @HiveField(13) PositionRow positionRow;                  // 진형 배치
      @HiveField(14) int positionIndex;                        // 동일 row 내 순서
      
      CombatantSnapshot({...});
    }
    ```

- **[FR-9.4]** `EnemySnapshot` Hive 모델 (페이즈 2 #2 §14.3):
  - 위치: `band_of_mercenaries/lib/features/quest/domain/enemy_snapshot.dart`
  - typeId: **27**
  - 필드:
    ```dart
    @HiveType(typeId: 27)
    class EnemySnapshot extends HiveObject {
      @HiveField(0) String archetypeId;                        // EnemyArchetype.id
      @HiveField(1) String instanceId;                         // 'archetypeId#instanceIndex' 형식
      @HiveField(2) String name;
      @HiveField(3) String role;
      @HiveField(4) int tier;
      @HiveField(5) int str;
      @HiveField(6) int int_;                                  // Dart 'int' 키워드 충돌 회피
      @HiveField(7) int vit;
      @HiveField(8) int agi;
      @HiveField(9) int hp;                                    // 시뮬레이션 도중 변동 (snapshot이지만 영속용 final hp = 종료 시점)
      @HiveField(10) int attack;
      @HiveField(11) int defense;
      @HiveField(12) List<String> skillIds;
      @HiveField(13) BehaviorPattern behaviorPattern;
      @HiveField(14) String? factionTag;
      @HiveField(15) PositionRow positionRow;
      @HiveField(16) int positionIndex;
      @HiveField(17) String formationGroupId;
      @HiveField(18) String? enemyKeywordKey;
      @HiveField(19) bool flagBattleFuryUsed;                  // 페이즈 4 #1 [FR-15] §3 1회성 플래그
      @HiveField(20) bool flagSummonUsed;
      
      EnemySnapshot({...});
    }
    ```

- **[FR-9.5]** Hive enum 3종:
  - 위치: `band_of_mercenaries/lib/features/quest/domain/combat_enums_hive.dart` (또는 각 모델 파일과 인접)
  - typeId: **28~30**
  - `BehaviorPattern`은 그룹 A `EnemyArchetype`과 그룹 B `EnemySnapshot` 양쪽에서 사용된다. 한 enum 정의를 양쪽에서 공유한다. JsonValue snake_case와 HiveType을 함께 적용:
    ```dart
    @HiveType(typeId: 28)
    enum CombatExitCondition {
      @HiveField(0) @JsonValue('a_party_wiped') aPartyWiped,
      @HiveField(1) @JsonValue('b_enemy_wiped') bEnemyWiped,
      @HiveField(2) @JsonValue('c_objective_achieved') cObjectiveAchieved,
      @HiveField(3) @JsonValue('d_round_limit') dRoundLimit,
      @HiveField(4) @JsonValue('e_flee') eFlee,
      @HiveField(5) @JsonValue('f_escort_dead') fEscortDead,
    }

    @HiveType(typeId: 29)
    enum BehaviorPattern {
      @HiveField(0) @JsonValue('aggressive') aggressive,
      @HiveField(1) @JsonValue('opportunist') opportunist,
      @HiveField(2) @JsonValue('caster') caster,
      @HiveField(3) @JsonValue('supporter') supporter,
      @HiveField(4) @JsonValue('defender') defender,
      @HiveField(5) @JsonValue('berserker') berserker,
    }

    @HiveType(typeId: 30)
    enum PositionRow {
      @HiveField(0) @JsonValue('front') front,
      @HiveField(1) @JsonValue('middle') middle,
      @HiveField(2) @JsonValue('back') back,
    }
    ```
  - **typeId 할당 결정**: 본 명세는 22~30(9개) 신규 할당. typeId 12는 보존(CLAUDE.md 정책). 31+는 후속 마일스톤용 예약.

- **[FR-9.6]** `CombatReport` 확장 (typeId 21, HiveField 8+):
  - 위치: `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart` (수정)
  - 기존 HiveField 0~7 유지. HiveField 8+에 신규 optional 필드 추가:
    ```dart
    @HiveType(typeId: 21)
    class CombatReport extends HiveObject {
      // 기존 0~7 보존
      @HiveField(0) String summary;
      @HiveField(1) List<String> details;
      // ... 2~7 (생략)
      
      // M8b 페이즈 4 #2 추가:
      @HiveField(8) int? schemaVersion;                        // 1=M8b 초기 (M8a 보고서는 null)
      @HiveField(9) List<CombatantSnapshot>? combatantSnapshots;
      @HiveField(10) List<CombatTurn>? turns;
      @HiveField(11) CombatExitCondition? exitCondition;
      @HiveField(12) double? objectiveProgress;
      @HiveField(13) List<EnemySnapshot>? enemySnapshots;       // 적 동결 보존(디버깅·재현)
      @HiveField(14) List<StatusEffectEvent>? statusEffectHistory;
      
      CombatReport({...});  // 신규 필드는 모두 optional, 기존 M8a 보고서 호환
    }
    ```
  - 기존 M8a 보고서(HiveField 0~7만 가진 행)는 신규 필드 null로 정상 디코딩. M8b 보고서는 신규 필드 모두 채움.
  - `schemaVersion`은 페이즈 4 #4 UI에서 분기 처리 입력(M8a MVP UI / M8b 시뮬레이션 UI).

#### 2.1.4 StaticGameData 3 컬렉션 확장

- **[FR-10]** `StaticGameData`에 3 컬렉션 추가 (`static_data_provider.dart` 수정):
  - 필드 추가:
    ```dart
    final List<CombatSkill> combatSkills;                      // M8b 페이즈 4 #2 추가
    final List<CombatStatusEffect> combatStatusEffects;        // M8b 페이즈 4 #2 추가
    final List<EnemyArchetype> enemyArchetypes;                // M8b 페이즈 4 #2 추가
    ```
  - 생성자 `required this.combatSkills` 등 3개 추가.
  - `staticDataProvider` Future 본체에 `dataLoader.loadFromCache('combat_skills', CombatSkill.fromJson)` 등 3개 항목 추가.
  - import 추가: `combat_skill.dart`/`combat_status_effect.dart`/`enemy_archetype.dart`.

#### 2.1.5 DataLoader / SyncService 3 신규 테이블 통합

- **[FR-11]** `SyncService.allTables` 리스트에 3 신규 테이블을 추가하고, `optionalTables`에도 동일하게 추가한다(`sync_service.dart` 수정):
  ```dart
  'combat_skills',           // 38. M8b 페이즈 4 #2 추가
  'combat_status_effects',   // 39. M8b 페이즈 4 #2 추가
  'enemies',                 // 40. M8b 페이즈 4 #2 추가
  // combat_report_templates(M8a)는 기존 항목, M8b는 행수만 증가(85행 추가)
  ```
  - 런타임 동기화 정책은 **optionalTables**이다. 정적 데이터 캐시 부재 시 시뮬레이션 미발동 → `QuestCalculator` 폴백으로 처리한다. 페이즈 4 #1 [FR-20] fallback 정책과 정합한다.
  - 출시 검증 기준에서는 3 테이블 모두 시드 완료가 필수이나, 스키마 적용 전 개발/테스트 환경의 앱 기동을 막지 않는다.
- **[FR-12]** `combat_report_templates` 행수 변화(M8a 96 → M8b 181):
  - **테이블 자체는 M8a에서 이미 정의**됨. 스키마 변경 없음.
  - 신규 scope `combat_skill` 23행 + 기존 8 scope 추가 보강 62행 = 총 +85행. Supabase apply_migration 1회 INSERT.
  - `scope` CHECK 제약 확장 필요: 기존 8종 + `combat_skill` 1종 = 9종.

#### 2.1.6 Hive 어댑터 등록 (HiveInitializer 수정)

- **[FR-13]** `HiveInitializer` 어댑터 등록 (`hive_initializer.dart` 수정):
  - 신규 9개 typeId(22~30)에 대한 어댑터 등록 호출 추가:
    ```dart
    Hive.registerAdapter(CombatSimulationResultAdapter());     // 22
    Hive.registerAdapter(CombatTurnAdapter());                 // 23
    Hive.registerAdapter(CombatActionAdapter());               // 24
    Hive.registerAdapter(StatusEffectEventAdapter());          // 25
    Hive.registerAdapter(CombatantSnapshotAdapter());          // 26
    Hive.registerAdapter(EnemySnapshotAdapter());              // 27
    Hive.registerAdapter(CombatExitConditionAdapter());        // 28
    Hive.registerAdapter(BehaviorPatternAdapter());            // 29
    Hive.registerAdapter(PositionRowAdapter());                // 30
    ```
  - 모든 어댑터는 `build_runner` 실행 후 자동 생성된다.

#### 2.1.7 Supabase 스키마 마이그레이션

- **[FR-14]** Supabase MCP `apply_migration` 4종:
  - **a) `combat_status_effects` 테이블 신설** + 10행 INSERT:
    ```sql
    CREATE TABLE combat_status_effects (
      id TEXT PRIMARY KEY,
      kind TEXT NOT NULL CHECK (kind IN ('buff','debuff','mez','dot')),
      display_label TEXT NOT NULL,
      default_duration_turns INT NOT NULL,
      default_intensity NUMERIC NOT NULL,
      stack_policy TEXT NOT NULL CHECK (stack_policy IN ('refresh','stack','ignore')),
      hook_target JSONB NOT NULL,
      apply_method TEXT NOT NULL CHECK (apply_method IN ('multiplicative','additive','proportional','absolute','none')),
      description TEXT NOT NULL
    );
    ```
    - 10행 INSERT는 페이즈 2 #3 §10.2 정밀 값 그대로.
  - **b) `combat_skills` 테이블 신설** + 페이즈 3 CSV 16행 INSERT:
    ```sql
    CREATE TABLE combat_skills (
      id TEXT PRIMARY KEY,
      role TEXT NOT NULL CHECK (role IN ('warrior','rogue','ranger','mage','support','specialist')),
      party_only BOOL NOT NULL DEFAULT false,
      trigger_kind TEXT NOT NULL CHECK (trigger_kind IN ('passive','active','triggered','on_hit','on_kill')),
      trigger_condition TEXT,
      action_cost TEXT NOT NULL CHECK (action_cost IN ('action','extraAction','passive')),
      cooldown_rounds INT NOT NULL DEFAULT 0,
      max_uses_per_combat INT,
      targeting_kind TEXT NOT NULL CHECK (targeting_kind IN ('self','single_enemy','single_ally','aoe_enemy','aoe_ally','party')),
      targeting_max_count INT,
      targeting_priority TEXT,
      multi_hit_count INT,
      skill_damage_multiplier NUMERIC,
      shield_block_bonus NUMERIC,
      crit_rate_bonus NUMERIC,
      status_effect_id TEXT REFERENCES combat_status_effects(id),
      status_effect_apply_chance NUMERIC,
      status_effect_intensity NUMERIC,
      status_effect_duration_turns INT,
      dispel_kind TEXT CHECK (dispel_kind IN ('debuff','buff','dot','debuff+dot')),
      dispel_max_count INT,
      display_label TEXT NOT NULL,
      description TEXT NOT NULL
    );
    ```
    - INSERT 16행은 `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.csv` 그대로 매핑한다(헤더 1행 + 데이터 16행). `combat_skills.status_effect_id`가 `combat_status_effects(id)`를 참조하므로 `combat_status_effects`를 먼저 생성·시드한다.
  - **c) `enemies` 테이블 신설** + 26행 INSERT:
    ```sql
    CREATE TABLE enemies (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      enemy_kind TEXT NOT NULL CHECK (enemy_kind IN ('normal','elite','unique')),
      role TEXT NOT NULL CHECK (role IN ('warrior','rogue','ranger','mage','support','specialist')),
      tier INT NOT NULL,
      base_str INT NOT NULL,
      base_int INT NOT NULL,
      base_vit INT NOT NULL,
      base_agi INT NOT NULL,
      base_hp INT NOT NULL,
      base_attack INT NOT NULL,
      base_defense INT NOT NULL,
      behavior_pattern TEXT NOT NULL CHECK (behavior_pattern IN ('aggressive','opportunist','caster','supporter','defender','berserker')),
      skill_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
      environment_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
      faction_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
      ambush_compatible BOOL NOT NULL DEFAULT false,
      enemy_keyword_key TEXT,
      elite_monster_id TEXT REFERENCES elite_monsters(id),
      description TEXT NOT NULL
    );
    ```
    - `enemy_keyword_key`는 M8a `combat_report_keywords.key` 값과 논리적으로 매칭한다. 기존 M8a 스키마에서 `key` 유니크 보장이 명시되지 않았으므로 FK를 걸지 않고, 시드 검증 SQL로 `category='enemy'` 매칭 여부를 확인한다.
  - **d) `combat_report_templates` 신규 85행 INSERT** + scope CHECK 확장:
    ```sql
    ALTER TABLE combat_report_templates DROP CONSTRAINT IF EXISTS combat_report_templates_scope_check;
    ALTER TABLE combat_report_templates ADD CONSTRAINT combat_report_templates_scope_check
      CHECK (scope IN ('chain_final','chain_step','elite','faction_named','quest_type','scene','settlement_event','unique_elite','combat_skill'));
    -- 85행 INSERT (페이즈 3 #4 CSV 정합)
    ```
  - **`data_versions` 테이블 갱신**: 4 테이블의 `version` 컬럼 +1 (`combat_skills`/`combat_status_effects`/`enemies`/`combat_report_templates`). SyncService가 변경 감지 후 자동 재동기화.

### 2.2 데이터 요구사항

#### 신규 정적 데이터 모델 (그룹 A)
- `CombatSkill` (`core/models/combat_skill.dart` 신규) — 22 컬럼 + display_label = 23필드
- `CombatStatusEffect` (`core/models/combat_status_effect.dart` 신규) — 9필드
- `EnemyArchetype` (`core/models/enemy_archetype.dart` 신규) — 20필드
- 7 enum (`core/models/combat_enums.dart` 신규) — `ApplyMethod`/`StackPolicy`/`ActionCost`/`TriggerKind`/`TargetingKind`/`DispelKind`/`EnemyKind`

#### 신규 시뮬레이션 영속 모델 (그룹 B, Hive typeId 22~30)
| typeId | 모델 | 위치 |
|--------|------|------|
| 22 | `CombatSimulationResult` | `features/quest/domain/combat_simulation_result.dart` |
| 23 | `CombatTurn` | `features/quest/domain/combat_turn.dart` |
| 24 | `CombatAction` | `features/quest/domain/combat_action.dart` |
| 25 | `StatusEffectEvent` | `features/quest/domain/status_effect_event.dart` |
| 26 | `CombatantSnapshot` | `features/quest/domain/combatant_snapshot.dart` |
| 27 | `EnemySnapshot` | `features/quest/domain/enemy_snapshot.dart` |
| 28 | `CombatExitCondition` (enum) | `features/quest/domain/combat_enums_hive.dart` |
| 29 | `BehaviorPattern` (enum) | `features/quest/domain/combat_enums_hive.dart` |
| 30 | `PositionRow` (enum) | `features/quest/domain/combat_enums_hive.dart` |

#### 기존 모델 확장
- `CombatReport` (typeId 21): HiveField 8~14 신규 7 필드 (`combat_report_model.dart` 수정)

#### Hive 박스 변경
- 신규 박스 없음. `quests` 박스에 영속되는 `ActiveQuest.combatReport`(HiveField 27, M8a)에 그룹 B 임베드.

#### Supabase 신규 테이블 3개
- `combat_skills` / `combat_status_effects` / `enemies` (38·39·40번째 테이블)
- `combat_report_templates`: 기존 36번째 테이블의 행수 확장 + scope CHECK 확장 (M8a에서 신설된 테이블).

#### 페이즈 3 CSV → Supabase MCP `apply_migration`
- `Docs/content-data/[combat-skill]20260519_m8b-combat-skills.csv` → `combat_skills` 시드
- `Docs/content-data/[status-effect]20260519_m8b-combat-status-effects.csv` → `combat_status_effects` 시드
- `Docs/content-data/[enemy]20260519_m8b-enemies.csv` → `enemies` 시드
- `Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.csv` → `combat_report_templates` INSERT (85행)

### 2.3 UI 요구사항

해당 없음. 본 명세는 모델·정적 데이터 인프라이며 UI 표시는 페이즈 4 #4 별도 명세에서 다룬다.

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart` | HiveField 8~14 신규 7 필드 추가 (`schemaVersion`/`combatantSnapshots`/`turns`/`exitCondition`/`objectiveProgress`/`enemySnapshots`/`statusEffectHistory`) | 시뮬레이션 결과를 보고서 본체에 임베드 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `combatSkills`/`combatStatusEffects`/`enemyArchetypes` 3 컬렉션 추가 + import 추가 + `staticDataProvider` 로딩 호출 추가 | StaticGameData 확장 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables`에 `combat_skills`/`combat_status_effects`/`enemies` 3 항목 추가. `optionalTables`에도 동일 3개 추가([Q-2] 정책) | Supabase 동기화 + fail-soft |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | 9개 어댑터 등록 (typeId 22~30) | Hive 어댑터 등록 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/combat_skill.dart` | `CombatSkill` freezed 모델 |
| `band_of_mercenaries/lib/core/models/combat_status_effect.dart` | `CombatStatusEffect` freezed 모델 |
| `band_of_mercenaries/lib/core/models/enemy_archetype.dart` | `EnemyArchetype` freezed 모델 |
| `band_of_mercenaries/lib/core/models/combat_enums.dart` | 7 정적 카탈로그 enum (`ApplyMethod`/`StackPolicy`/`ActionCost`/`TriggerKind`/`TargetingKind`/`DispelKind`/`EnemyKind`) |
| `band_of_mercenaries/lib/features/quest/domain/combat_simulation_result.dart` | typeId 22 |
| `band_of_mercenaries/lib/features/quest/domain/combat_turn.dart` | typeId 23 |
| `band_of_mercenaries/lib/features/quest/domain/combat_action.dart` | typeId 24 |
| `band_of_mercenaries/lib/features/quest/domain/status_effect_event.dart` | typeId 25 |
| `band_of_mercenaries/lib/features/quest/domain/combatant_snapshot.dart` | typeId 26 |
| `band_of_mercenaries/lib/features/quest/domain/enemy_snapshot.dart` | typeId 27 |
| `band_of_mercenaries/lib/features/quest/domain/combat_enums_hive.dart` | 3 Hive enum (typeId 28~30) — `CombatExitCondition`/`BehaviorPattern`/`PositionRow` |
| Supabase 마이그레이션 SQL 4개 | `combat_skills`/`combat_status_effects`/`enemies` 신설 + `combat_report_templates` 행추가·CHECK 확장 |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `combat_skill.freezed.dart` / `.g.dart` | freezed + json_serializable |
| `combat_status_effect.freezed.dart` / `.g.dart` | 동일 |
| `enemy_archetype.freezed.dart` / `.g.dart` | 동일 |
| `combat_enums.dart` | enum 전용 파일. 별도 생성 파일 없음. enum 매핑 코드는 이를 사용하는 모델의 `.g.dart`에 생성 |
| `combat_simulation_result.g.dart` | hive_generator 어댑터 |
| `combat_turn.g.dart` | 동일 |
| `combat_action.g.dart` | 동일 |
| `status_effect_event.g.dart` | 동일 |
| `combatant_snapshot.g.dart` | 동일 |
| `enemy_snapshot.g.dart` | 동일 |
| `combat_enums_hive.g.dart` | hive_generator enum 어댑터 |
| `combat_report_model.g.dart` | 기존 파일 재생성 (HiveField 8~14 추가 반영) |

전체 신규 + 재생성 → `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs` 1회 실행 필수.

### 3.4 관련 시스템

- **CombatSimulator (페이즈 4 #1)**: 본 명세의 모든 모델·enum을 의존. 본 명세 구현 완료 후 페이즈 4 #1 구현이 컴파일 가능.
- **QuestCompletionService / quest_provider (페이즈 4 #3)**: `CombatReport.turns`/`combatantSnapshots`/`exitCondition` 등 확장 필드 활용.
- **CombatReportService (페이즈 4 #3)**: `generate(..., simulationResult: CombatSimulationResult?)` 인자 추가. 본 명세는 시그니처 영향 없음(타입만 정의).
- **DataLoader / SyncService**: 3 신규 테이블 추가 + `combat_report_templates` 버전 갱신.
- **StaticGameData**: 3 컬렉션 확장 + 로딩 호출 추가.
- **HiveInitializer**: 어댑터 9개 등록.
- **페이즈 4 #4 UI**: `CombatReport.schemaVersion`으로 M8a/M8b 분기.
- **페이즈 4 #5 검증**: 본 명세 모델로 단위 테스트 작성 가능.

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `band_of_mercenaries/lib/core/models/combat_report_keyword.dart` — M8a freezed + json_serializable 패턴(snake_case `@JsonKey`).
- `band_of_mercenaries/lib/core/models/region_state_effect.dart` — sealed freezed union + JsonValue 매핑(enum-like).
- `band_of_mercenaries/lib/features/quest/domain/combat_report_model.dart` — 일반 Hive 클래스 패턴(extends HiveObject, HiveField).
- `band_of_mercenaries/lib/features/achievement/domain/band_achievement_model.dart` — Hive enum + Hive 클래스 결합(typeId 16, 17 동일 파일).
- `band_of_mercenaries/lib/features/achievement/domain/memorial_cause.dart` — Hive enum 단일 파일 패턴(typeId 19).
- `band_of_mercenaries/lib/features/info/domain/faction_state_model.dart` — Hive 모델 내부에 nested 객체(typeId 9 + 10).
- `band_of_mercenaries/lib/core/data/sync_service.dart` — `allTables` + `optionalTables` 분리 패턴.
- `band_of_mercenaries/lib/core/providers/static_data_provider.dart` — `dataLoader.loadFromCache('table', Model.fromJson)` 호출 패턴.

### 4.2 주의사항

- **freezed + Hive 통합 회피**: `CombatReport`는 일반 Hive 클래스다(freezed 미사용). 본 명세 그룹 B 모델도 **동일 패턴**으로 일반 Hive 클래스를 채택해 build_runner 충돌을 방지한다. freezed `@Freezed(hiveType: ...)`는 freezed 2.x + hive_generator 호환 이슈가 있어 회피한다.
- **enum의 이중 어노테이션**: `BehaviorPattern`은 그룹 A `EnemyArchetype`(JSON 캐시)과 그룹 B `EnemySnapshot`(Hive 박스) 양쪽에서 사용된다. `@HiveType` + `@JsonValue` 두 어노테이션을 동시 적용한다. json_serializable과 hive_generator 모두 인식한다.
- **`int_` 필드명 회피**: Dart 키워드 `int` 충돌. `EnemySnapshot`에서 `int_` 또는 `intelligence`로 명명. 본 명세는 `int_` 채택(다른 stat과 동일 3자 일관성).
- **typeId 22~30 점유 영속**: 본 명세 확정 후 다른 마일스톤에서 동일 typeId 재사용 절대 금지. CLAUDE.md typeId 표 갱신 필요(별도 finalize 단계).
- **Hive 박스 마이그레이션 미필요**: 기존 `quests` 박스의 `ActiveQuest` 행은 `CombatReport.HiveField 8+` null 디코딩 안전. Hive는 누락 필드를 default(nullable)로 자동 처리한다.
- **Supabase RLS**: 3 신규 테이블 모두 SELECT 권한만 anon role에 부여(M8a 패턴 동일). INSERT/UPDATE는 service_role 한정.

### 4.3 엣지 케이스

- **CSV 컬럼이 모델 필드와 불일치**: `combat_skills` CSV 23 컬럼 중 일부 NULL/빈 값이 nullable로 매핑되어야 함. freezed의 `@JsonKey` + nullable 처리 + json_serializable의 `defaultValue` 활용.
- **enum String 직렬화 실패**: 알 수 없는 enum 값(예: 미래 마일스톤의 새 trigger_kind) 수신 시 json_serializable이 throw — `@JsonEnum(unknownEnumValue: ...)` 또는 명시적 fromJson 분기로 fail-soft 처리하거나 throw 후 SyncService가 시드 데이터 오류로 보고. **본 명세 채택**: throw 후 CombatSimulator fail-soft fallback(페이즈 4 #1 [FR-20]).
- **Hive enum 신규 case 추가**: typeId 28~30 enum에 신규 HiveField 인덱스 추가는 안전(기존 인덱스 보존). enum case 삭제는 데이터 손상 위험 → 금지.
- **`elite_monster_id` FK 매칭 실패**: `EnemyArchetype.eliteMonsterId`가 NULL인 경우(일반 적 17행)는 정상. non-NULL인데 `elite_monsters`에 매칭 행 없으면 Supabase FK CHECK 실패. 시드 단계 검증.
- **데이터 versions 충돌**: 기존 `data_versions` 행에 3 신규 테이블 또는 `combat_report_templates` 버전 갱신이 누락되면 해당 캐시가 갱신되지 않는다. 마이그레이션 마지막 단계에서 4개(`combat_skills`/`combat_status_effects`/`enemies`/`combat_report_templates`) 버전을 함께 upsert한다.
- **`CombatReport.combatantSnapshots == null`**: M8a 보고서는 null. UI 분기에서 `schemaVersion == null` 또는 `combatantSnapshots == null`을 M8a MVP 경로로 처리.
- **`EnemySnapshot.hp` 영속값**: 시뮬레이션 도중 변동하나 영속 시점에는 전투 종료 시점 HP. 디버깅용 정보로 보존.

### 4.4 구현 힌트

- **진입점**: 본 명세는 데이터 모델 정의 중심. 진입점은 (a) 모델 파일 신규 작성 → (b) build_runner 실행 → (c) `static_data_provider.dart`/`sync_service.dart`/`hive_initializer.dart` 통합 → (d) Supabase 마이그레이션 적용 순.
- **데이터 흐름**:
  ```
  Supabase 3 테이블(combat_skills/combat_status_effects/enemies)
    → SyncService.allTables 추가 → DataLoader.saveToCache → JSON 캐시
    → staticDataProvider → StaticGameData.combatSkills/combatStatusEffects/enemyArchetypes
    → CombatSimulator(페이즈 4 #1)가 사용
  
  CombatSimulator(페이즈 4 #1)
    → CombatSimulationResult/CombatTurn/CombatAction/StatusEffectEvent/CombatantSnapshot/EnemySnapshot 생성
    → CombatReportService.generate(..., simulationResult)에 전달 (페이즈 4 #3)
    → CombatReport.HiveField 8+ 채움
    → ActiveQuest.combatReport(HiveField 27)에 저장 (M8a 기존 경로)
  ```
- **참조 구현**:
  - `combat_report_keyword.dart:1~21` — freezed + json_serializable + snake_case `@JsonKey` 표준 패턴
  - `combat_report_model.dart` — Hive 모델 패턴(extends HiveObject, HiveField 0~7)
  - `band_achievement_model.dart:6~17` — Hive enum + Hive 클래스 결합
  - `memorial_cause.dart` — Hive enum 단일 파일 + JsonValue 매핑 결합 패턴
  - `static_data_provider.dart:81~82, 240~260` — 신규 컬렉션 추가 위치
  - `sync_service.dart:18~70` — `allTables`/`optionalTables` 분리 패턴
- **확장 지점**:
  - 페이즈 4 #1 시뮬레이터: `staticData.combatSkills.firstWhere((s) => s.id == skillId)` 룩업.
  - 페이즈 4 #3 통합: `CombatReportService.generate(..., simulationResult: simResult)` 시그니처 인자 추가.
  - 페이즈 4 #4 UI: `CombatReport.schemaVersion == 1` 분기로 M8b 전용 표시 활성화.
- **build_runner 실행 명령**:
  ```bash
  cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
  ```
- **Supabase apply_migration 순서**:
  1. `combat_status_effects` 신설 + 10행 INSERT (FK 의존 없음 — 가장 먼저)
  2. `combat_skills` 신설 + 16행 INSERT (`status_effect_id` REFERENCES combat_status_effects)
  3. `enemies` 신설 + 26행 INSERT (`elite_monster_id` REFERENCES elite_monsters / `enemy_keyword_key`는 논리 매칭)
  4. `combat_report_templates` scope CHECK 확장 + 85행 INSERT
  5. `data_versions` 행 4개 추가 또는 갱신

## 5. 기획 확인 사항

- **[Q-1]** 그룹 B 모델(시뮬레이션 영속 결과)을 freezed로 정의할지 일반 Hive 클래스로 정의할지?
  → 처리 방향(본 명세 채택): **일반 Hive 클래스** (CombatReport 기존 패턴과 동일). freezed + Hive 통합은 hive_generator 호환 이슈가 있고, freezed `copyWith`/`==` 기능이 시뮬레이션 결과 모델에 필요하지 않다. 단순 데이터 컨테이너로 충분.

- **[Q-2]** 3 신규 테이블(`combat_skills`/`combat_status_effects`/`enemies`)을 `requiredTables` vs `optionalTables` 어디에 둘 것인가?
  → 처리 방향(본 명세 채택): **`optionalTables`**. CombatSimulator는 페이즈 4 #1 [FR-20] fail-soft 정책으로 정적 데이터 부재 시 null 반환 → QuestCalculator 폴백. optional로 두면 (a) M8b 출시 전 개발 빌드에서 시드 데이터 없이도 게임 동작, (b) 핫픽스로 시드만 누락된 상태에서도 게임 멈춤 방지. 단 출시 검증에서는 3 테이블의 시드 완료를 필수 조건으로 둔다.

- **[Q-3]** `CombatStatusEffect.kind`를 enum으로 만들지 String으로 유지할지?
  → 처리 방향(본 명세 채택): **String**. 페이즈 4 #1 시뮬레이터가 `kind == 'debuff'` 같은 String 비교를 광범위하게 사용하고, 카탈로그 확장(예: `mez_silenced`/`mez_taunted`) 시 enum case 추가 + JsonValue 매핑 보일러플레이트가 증가한다. `kind`는 4종({buff/debuff/mez/dot})으로 안정적이지만 String 유지가 단순.

- **[Q-4]** `BehaviorPattern` enum을 그룹 A(EnemyArchetype JSON) + 그룹 B(EnemySnapshot Hive)에서 공유할 때 typeId 28~30 중 어디에 할당할지?
  → 처리 방향(본 명세 채택): **typeId 29 (그룹 B와 함께)**. JSON 캐시 측은 typeId 무관(JsonValue String 매핑만 사용). Hive 측만 typeId 필요하므로 그룹 B 어댑터로 등록.

- **[Q-5]** `CombatReport`의 HiveField 8~14를 모두 nullable로 둘 때 페이즈 4 #4 UI가 분기 처리해야 하는 조건은?
  → 처리 방향(본 명세 채택): `schemaVersion == null` 또는 `combatantSnapshots == null`이면 M8a MVP 경로(요약·상세만). `schemaVersion == 1 && turns != null`이면 M8b 시뮬레이션 경로(요약·상세 + 라운드 로그 표시). 정확한 UI 분기는 페이즈 4 #4 명세에서 확정.

- **[Q-6]** Supabase 마이그레이션을 본 명세 구현 중에 적용할지, 별도 finalize 단계에서 적용할지?
  → 처리 방향(본 명세 채택): **본 명세 구현 단계에서 적용**. `combat_skills`/`combat_status_effects`/`enemies` 테이블은 런타임 optional로 로드하지만, M8b 검증 빌드에서는 시뮬레이터 입력 데이터로 필요하다. coder가 `apply_migration` MCP를 호출해 적용한다.

- **[Q-7]** `combat_report_templates`의 신규 scope `combat_skill` 23행 + 기존 8 scope 보강 62행 총 85행 INSERT는 본 명세 범위에 포함되는가, 페이즈 3 #4 데이터 시드로 분리할지?
  → 처리 방향(본 명세 채택): **본 명세 범위 포함**. 페이즈 3 산출물 CSV(`Docs/content-data/[combat-log-template]20260519_m8b-combat-report-templates.csv` 85행)는 이미 존재한다. Supabase apply_migration 1회로 INSERT + scope CHECK 확장을 동시 수행. 페이즈 3 #4 작업으로 따로 분리하면 본 명세 통합 빌드 게이트 의존성이 복잡해진다.

- **[Q-8]** 본 명세 구현 후 페이즈 4 #1(CombatSimulator 본체)이 자동으로 컴파일 가능해지는가?
  → 처리 방향: **예**. 본 명세에서 정의한 9 모델·10 enum·StaticGameData 3 컬렉션이 페이즈 4 #1 `[spec]20260519_m8b_combat_simulator.md` §2.2의 의존 항목과 1:1 매핑된다. 본 명세 → 페이즈 4 #1 implement-agent 흐름으로 자연스럽게 이어진다.

---

## 부록 A: 페이즈 1·2·3·4 산출물 ↔ 본 명세 매핑 표

| 페이즈 산출물 | 본 명세 반영 위치 |
|------------|---------------|
| 페이즈 1 #1 §CombatSimulationResult 11 필드 | [FR-6] |
| 페이즈 1 #1 §파견 시작 시점 스냅샷 고정 | [FR-9.3] CombatantSnapshot |
| 페이즈 1 #1 §라운드 시퀀스 영속화 | [FR-7] CombatTurn / [FR-8] CombatAction |
| 페이즈 1 #1 §상태 효과 이벤트 영속 | [FR-9] StatusEffectEvent |
| 페이즈 1 #1 §종료 조건 (a)~(f) | [FR-9.5] CombatExitCondition |
| 페이즈 1 #1 §CombatReport HiveField 8+ 확장 | [FR-9.6] |
| 페이즈 1 #4 §2 CombatStatusEffect 구조 | [FR-3] |
| 페이즈 1 #4 §3 hook 매핑 | [FR-5] ApplyMethod enum |
| 페이즈 1 #4 §7 stackPolicy | [FR-5] StackPolicy enum |
| 페이즈 1 #4 §8.2 dispel 분류 | [FR-5] DispelKind enum |
| 페이즈 2 #1 §10 CombatSkill 22 컬럼 | [FR-2] |
| 페이즈 2 #1 §10 enum 후보 | [FR-5] ActionCost/TriggerKind/TargetingKind |
| 페이즈 2 #2 §14 EnemyArchetype 구조 | [FR-4] |
| 페이즈 2 #2 §14.3 EnemySnapshot 구조 | [FR-9.4] |
| 페이즈 2 #2 §8.3 behaviorPattern | [FR-5]/[FR-9.5] BehaviorPattern |
| 페이즈 2 #3 §10.2 default 10행 | Supabase `combat_status_effects` 시드 |
| 페이즈 2 #3 §6 nullable 오버라이드 정책 | [FR-2] statusEffectIntensity/statusEffectDurationTurns nullable |
| 페이즈 3 #1 enemies 26행 CSV | [FR-14.c] apply_migration |
| 페이즈 3 #2 combat_skills 16행 CSV | [FR-14.b] apply_migration |
| 페이즈 3 #3 combat_status_effects 10행 CSV | [FR-14.a] apply_migration |
| 페이즈 3 #4 combat_report_templates 신규 85행 | [FR-14.d] apply_migration + scope CHECK 확장 |
| 페이즈 4 #1 §2.2 데이터 요구사항 19종 모델 | [FR-2]~[FR-9.6] 전체 |
| 페이즈 4 #1 §[FR-18.5] CombatAction 메타데이터 6필드 | [FR-8] HiveField 3~8 |
| 페이즈 4 #1 §[FR-15] flagBattleFuryUsed/flagSummonUsed | [FR-9.4] HiveField 19~20 |
| 페이즈 4 #1 §[FR-12] 10 PRNG 도메인 키 | (모델 무관 — 시뮬레이터 자체 책임) |
| 페이즈 4 #1 §[FR-7] 적 그룹 구성 fallback | [FR-4] factionTags/environmentTags 필드 활용 |

## 부록 B: typeId 점유 현황 갱신 (구현 후 CLAUDE.md 반영 필요)

| typeId | 모델 | 마일스톤 |
|--------|------|---------|
| 0~5 | MercenaryStatus/Mercenary/QuestStatus/QuestResult/ActiveQuest/UserData | M0~M1 |
| 6, 7 | ActivityLogType/ActivityLog | M0 |
| 8 | RegionState | M2b |
| 9, 10 | FactionState/FactionClueRecord | M3 |
| 11 | InventoryItem | M5 |
| 12 | (미사용 보존) | — |
| 13, 14 | ChainQuestProgress/ChainQuestStatus | M3 |
| 15 | PersistedDialogEntry | M5 |
| 16, 17 | BandAchievement/BandAchievementType | M6 |
| 18, 19 | MercenarySnapshot/MemorialCause | M6 |
| 20 | FactionShopDailyEntry | M8a |
| 21 | CombatReport (M8b에서 HiveField 8~14 확장) | M8a / M8b |
| **22** | **CombatSimulationResult** | **M8b** |
| **23** | **CombatTurn** | **M8b** |
| **24** | **CombatAction** | **M8b** |
| **25** | **StatusEffectEvent** | **M8b** |
| **26** | **CombatantSnapshot** | **M8b** |
| **27** | **EnemySnapshot** | **M8b** |
| **28** | **CombatExitCondition** | **M8b** |
| **29** | **BehaviorPattern** | **M8b** |
| **30** | **PositionRow** | **M8b** |
| 31+ | 예약 | — |
