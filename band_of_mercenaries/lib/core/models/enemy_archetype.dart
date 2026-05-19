// M8b 페이즈 4 #2 — EnemyArchetype 정적 카탈로그 모델
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'combat_enums.dart';

part 'enemy_archetype.freezed.dart';
part 'enemy_archetype.g.dart';

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
