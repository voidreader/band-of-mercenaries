import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_pool.freezed.dart';
part 'quest_pool.g.dart';

@freezed
class QuestPool with _$QuestPool {
  const factory QuestPool({
    required String id,
    required String name,
    // Deprecated: quest_types 외래 키는 type_id 사용 (Supabase quest_pools.type 컬럼 호환용으로 유지)
    required double type,
    required double difficulty,
    @JsonKey(name: 'min_region_diff') required double minRegionDiff,
    @JsonKey(name: 'max_region_diff') required double maxRegionDiff,
    @Default('raid') @JsonKey(name: 'type_id') String typeId,
    @JsonKey(name: 'faction_tag') String? factionTag,
    @Default(false) @JsonKey(name: 'is_faction_exclusive') bool isFactionExclusive,
    @Default(0) @JsonKey(name: 'min_reputation') int minReputation,
    @JsonKey(name: 'sector_type') String? sectorType,
    @JsonKey(name: 'special_flags') @Default(<String, dynamic>{}) Map<String, dynamic> specialFlags,
    @JsonKey(name: 'enemy_name') String? enemyName,

    // 고정 의뢰 컬럼 (페이즈 1 #4)
    @Default(false) @JsonKey(name: 'is_fixed') bool isFixed,
    @JsonKey(name: 'fixed_chain_id') String? fixedChainId,
    @JsonKey(name: 'fixed_step') int? fixedStep,
    @JsonKey(name: 'trust_threshold') int? trustThreshold,

    // 보상/시간 override 컬럼 (페이즈 2 #4)
    @JsonKey(name: 'reward_gold_override') int? rewardGoldOverride,
    @JsonKey(name: 'reward_xp_bonus_override') int? rewardXpBonusOverride,
    @JsonKey(name: 'duration_override_seconds') int? durationOverrideSeconds,
    @JsonKey(name: 'trust_reward_override') int? trustRewardOverride,

    // 단계별 노출 제어 컬럼 (페이즈 2 #3)
    @Default(0) @JsonKey(name: 'min_trust_level') int minTrustLevel,

    // 지명 의뢰 컬럼 (M6 페이즈 4 #3)
    @Default(false) @JsonKey(name: 'is_named') bool isNamed,
    @JsonKey(name: 'named_hook_type') String? namedHookType,
    @JsonKey(name: 'named_hook_value') String? namedHookValue,
    @Default(24) @JsonKey(name: 'named_cooldown_hours') int namedCooldownHours,
  }) = _QuestPool;

  factory QuestPool.fromJson(Map<String, dynamic> json) =>
      _$QuestPoolFromJson(json);
}