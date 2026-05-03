// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quest_pool.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuestPool _$QuestPoolFromJson(Map<String, dynamic> json) {
  return _QuestPool.fromJson(json);
}

/// @nodoc
mixin _$QuestPool {
  String get id => throw _privateConstructorUsedError;
  String get name =>
      throw _privateConstructorUsedError; // Deprecated: quest_types 외래 키는 type_id 사용 (Supabase quest_pools.type 컬럼 호환용으로 유지)
  double get type => throw _privateConstructorUsedError;
  double get difficulty => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_region_diff')
  double get minRegionDiff => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_region_diff')
  double get maxRegionDiff => throw _privateConstructorUsedError;
  @JsonKey(name: 'type_id')
  String get typeId => throw _privateConstructorUsedError;
  @JsonKey(name: 'faction_tag')
  String? get factionTag => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_faction_exclusive')
  bool get isFactionExclusive => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_reputation')
  int get minReputation => throw _privateConstructorUsedError;
  @JsonKey(name: 'sector_type')
  String? get sectorType => throw _privateConstructorUsedError;
  @JsonKey(name: 'special_flags')
  Map<String, dynamic> get specialFlags => throw _privateConstructorUsedError;
  @JsonKey(name: 'enemy_name')
  String? get enemyName =>
      throw _privateConstructorUsedError; // 고정 의뢰 컬럼 (페이즈 1 #4)
  @JsonKey(name: 'is_fixed')
  bool get isFixed => throw _privateConstructorUsedError;
  @JsonKey(name: 'fixed_chain_id')
  String? get fixedChainId => throw _privateConstructorUsedError;
  @JsonKey(name: 'fixed_step')
  int? get fixedStep => throw _privateConstructorUsedError;
  @JsonKey(name: 'trust_threshold')
  int? get trustThreshold =>
      throw _privateConstructorUsedError; // 보상/시간 override 컬럼 (페이즈 2 #4)
  @JsonKey(name: 'reward_gold_override')
  int? get rewardGoldOverride => throw _privateConstructorUsedError;
  @JsonKey(name: 'reward_xp_bonus_override')
  int? get rewardXpBonusOverride => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_override_seconds')
  int? get durationOverrideSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'trust_reward_override')
  int? get trustRewardOverride =>
      throw _privateConstructorUsedError; // 단계별 노출 제어 컬럼 (페이즈 2 #3)
  @JsonKey(name: 'min_trust_level')
  int get minTrustLevel => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestPoolCopyWith<QuestPool> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestPoolCopyWith<$Res> {
  factory $QuestPoolCopyWith(QuestPool value, $Res Function(QuestPool) then) =
      _$QuestPoolCopyWithImpl<$Res, QuestPool>;
  @useResult
  $Res call(
      {String id,
      String name,
      double type,
      double difficulty,
      @JsonKey(name: 'min_region_diff') double minRegionDiff,
      @JsonKey(name: 'max_region_diff') double maxRegionDiff,
      @JsonKey(name: 'type_id') String typeId,
      @JsonKey(name: 'faction_tag') String? factionTag,
      @JsonKey(name: 'is_faction_exclusive') bool isFactionExclusive,
      @JsonKey(name: 'min_reputation') int minReputation,
      @JsonKey(name: 'sector_type') String? sectorType,
      @JsonKey(name: 'special_flags') Map<String, dynamic> specialFlags,
      @JsonKey(name: 'enemy_name') String? enemyName,
      @JsonKey(name: 'is_fixed') bool isFixed,
      @JsonKey(name: 'fixed_chain_id') String? fixedChainId,
      @JsonKey(name: 'fixed_step') int? fixedStep,
      @JsonKey(name: 'trust_threshold') int? trustThreshold,
      @JsonKey(name: 'reward_gold_override') int? rewardGoldOverride,
      @JsonKey(name: 'reward_xp_bonus_override') int? rewardXpBonusOverride,
      @JsonKey(name: 'duration_override_seconds') int? durationOverrideSeconds,
      @JsonKey(name: 'trust_reward_override') int? trustRewardOverride,
      @JsonKey(name: 'min_trust_level') int minTrustLevel});
}

/// @nodoc
class _$QuestPoolCopyWithImpl<$Res, $Val extends QuestPool>
    implements $QuestPoolCopyWith<$Res> {
  _$QuestPoolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? difficulty = null,
    Object? minRegionDiff = null,
    Object? maxRegionDiff = null,
    Object? typeId = null,
    Object? factionTag = freezed,
    Object? isFactionExclusive = null,
    Object? minReputation = null,
    Object? sectorType = freezed,
    Object? specialFlags = null,
    Object? enemyName = freezed,
    Object? isFixed = null,
    Object? fixedChainId = freezed,
    Object? fixedStep = freezed,
    Object? trustThreshold = freezed,
    Object? rewardGoldOverride = freezed,
    Object? rewardXpBonusOverride = freezed,
    Object? durationOverrideSeconds = freezed,
    Object? trustRewardOverride = freezed,
    Object? minTrustLevel = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as double,
      minRegionDiff: null == minRegionDiff
          ? _value.minRegionDiff
          : minRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
      maxRegionDiff: null == maxRegionDiff
          ? _value.maxRegionDiff
          : maxRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
      typeId: null == typeId
          ? _value.typeId
          : typeId // ignore: cast_nullable_to_non_nullable
              as String,
      factionTag: freezed == factionTag
          ? _value.factionTag
          : factionTag // ignore: cast_nullable_to_non_nullable
              as String?,
      isFactionExclusive: null == isFactionExclusive
          ? _value.isFactionExclusive
          : isFactionExclusive // ignore: cast_nullable_to_non_nullable
              as bool,
      minReputation: null == minReputation
          ? _value.minReputation
          : minReputation // ignore: cast_nullable_to_non_nullable
              as int,
      sectorType: freezed == sectorType
          ? _value.sectorType
          : sectorType // ignore: cast_nullable_to_non_nullable
              as String?,
      specialFlags: null == specialFlags
          ? _value.specialFlags
          : specialFlags // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      enemyName: freezed == enemyName
          ? _value.enemyName
          : enemyName // ignore: cast_nullable_to_non_nullable
              as String?,
      isFixed: null == isFixed
          ? _value.isFixed
          : isFixed // ignore: cast_nullable_to_non_nullable
              as bool,
      fixedChainId: freezed == fixedChainId
          ? _value.fixedChainId
          : fixedChainId // ignore: cast_nullable_to_non_nullable
              as String?,
      fixedStep: freezed == fixedStep
          ? _value.fixedStep
          : fixedStep // ignore: cast_nullable_to_non_nullable
              as int?,
      trustThreshold: freezed == trustThreshold
          ? _value.trustThreshold
          : trustThreshold // ignore: cast_nullable_to_non_nullable
              as int?,
      rewardGoldOverride: freezed == rewardGoldOverride
          ? _value.rewardGoldOverride
          : rewardGoldOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      rewardXpBonusOverride: freezed == rewardXpBonusOverride
          ? _value.rewardXpBonusOverride
          : rewardXpBonusOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      durationOverrideSeconds: freezed == durationOverrideSeconds
          ? _value.durationOverrideSeconds
          : durationOverrideSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      trustRewardOverride: freezed == trustRewardOverride
          ? _value.trustRewardOverride
          : trustRewardOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      minTrustLevel: null == minTrustLevel
          ? _value.minTrustLevel
          : minTrustLevel // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestPoolImplCopyWith<$Res>
    implements $QuestPoolCopyWith<$Res> {
  factory _$$QuestPoolImplCopyWith(
          _$QuestPoolImpl value, $Res Function(_$QuestPoolImpl) then) =
      __$$QuestPoolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      double type,
      double difficulty,
      @JsonKey(name: 'min_region_diff') double minRegionDiff,
      @JsonKey(name: 'max_region_diff') double maxRegionDiff,
      @JsonKey(name: 'type_id') String typeId,
      @JsonKey(name: 'faction_tag') String? factionTag,
      @JsonKey(name: 'is_faction_exclusive') bool isFactionExclusive,
      @JsonKey(name: 'min_reputation') int minReputation,
      @JsonKey(name: 'sector_type') String? sectorType,
      @JsonKey(name: 'special_flags') Map<String, dynamic> specialFlags,
      @JsonKey(name: 'enemy_name') String? enemyName,
      @JsonKey(name: 'is_fixed') bool isFixed,
      @JsonKey(name: 'fixed_chain_id') String? fixedChainId,
      @JsonKey(name: 'fixed_step') int? fixedStep,
      @JsonKey(name: 'trust_threshold') int? trustThreshold,
      @JsonKey(name: 'reward_gold_override') int? rewardGoldOverride,
      @JsonKey(name: 'reward_xp_bonus_override') int? rewardXpBonusOverride,
      @JsonKey(name: 'duration_override_seconds') int? durationOverrideSeconds,
      @JsonKey(name: 'trust_reward_override') int? trustRewardOverride,
      @JsonKey(name: 'min_trust_level') int minTrustLevel});
}

/// @nodoc
class __$$QuestPoolImplCopyWithImpl<$Res>
    extends _$QuestPoolCopyWithImpl<$Res, _$QuestPoolImpl>
    implements _$$QuestPoolImplCopyWith<$Res> {
  __$$QuestPoolImplCopyWithImpl(
      _$QuestPoolImpl _value, $Res Function(_$QuestPoolImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? difficulty = null,
    Object? minRegionDiff = null,
    Object? maxRegionDiff = null,
    Object? typeId = null,
    Object? factionTag = freezed,
    Object? isFactionExclusive = null,
    Object? minReputation = null,
    Object? sectorType = freezed,
    Object? specialFlags = null,
    Object? enemyName = freezed,
    Object? isFixed = null,
    Object? fixedChainId = freezed,
    Object? fixedStep = freezed,
    Object? trustThreshold = freezed,
    Object? rewardGoldOverride = freezed,
    Object? rewardXpBonusOverride = freezed,
    Object? durationOverrideSeconds = freezed,
    Object? trustRewardOverride = freezed,
    Object? minTrustLevel = null,
  }) {
    return _then(_$QuestPoolImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as double,
      minRegionDiff: null == minRegionDiff
          ? _value.minRegionDiff
          : minRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
      maxRegionDiff: null == maxRegionDiff
          ? _value.maxRegionDiff
          : maxRegionDiff // ignore: cast_nullable_to_non_nullable
              as double,
      typeId: null == typeId
          ? _value.typeId
          : typeId // ignore: cast_nullable_to_non_nullable
              as String,
      factionTag: freezed == factionTag
          ? _value.factionTag
          : factionTag // ignore: cast_nullable_to_non_nullable
              as String?,
      isFactionExclusive: null == isFactionExclusive
          ? _value.isFactionExclusive
          : isFactionExclusive // ignore: cast_nullable_to_non_nullable
              as bool,
      minReputation: null == minReputation
          ? _value.minReputation
          : minReputation // ignore: cast_nullable_to_non_nullable
              as int,
      sectorType: freezed == sectorType
          ? _value.sectorType
          : sectorType // ignore: cast_nullable_to_non_nullable
              as String?,
      specialFlags: null == specialFlags
          ? _value._specialFlags
          : specialFlags // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      enemyName: freezed == enemyName
          ? _value.enemyName
          : enemyName // ignore: cast_nullable_to_non_nullable
              as String?,
      isFixed: null == isFixed
          ? _value.isFixed
          : isFixed // ignore: cast_nullable_to_non_nullable
              as bool,
      fixedChainId: freezed == fixedChainId
          ? _value.fixedChainId
          : fixedChainId // ignore: cast_nullable_to_non_nullable
              as String?,
      fixedStep: freezed == fixedStep
          ? _value.fixedStep
          : fixedStep // ignore: cast_nullable_to_non_nullable
              as int?,
      trustThreshold: freezed == trustThreshold
          ? _value.trustThreshold
          : trustThreshold // ignore: cast_nullable_to_non_nullable
              as int?,
      rewardGoldOverride: freezed == rewardGoldOverride
          ? _value.rewardGoldOverride
          : rewardGoldOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      rewardXpBonusOverride: freezed == rewardXpBonusOverride
          ? _value.rewardXpBonusOverride
          : rewardXpBonusOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      durationOverrideSeconds: freezed == durationOverrideSeconds
          ? _value.durationOverrideSeconds
          : durationOverrideSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      trustRewardOverride: freezed == trustRewardOverride
          ? _value.trustRewardOverride
          : trustRewardOverride // ignore: cast_nullable_to_non_nullable
              as int?,
      minTrustLevel: null == minTrustLevel
          ? _value.minTrustLevel
          : minTrustLevel // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestPoolImpl implements _QuestPool {
  const _$QuestPoolImpl(
      {required this.id,
      required this.name,
      required this.type,
      required this.difficulty,
      @JsonKey(name: 'min_region_diff') required this.minRegionDiff,
      @JsonKey(name: 'max_region_diff') required this.maxRegionDiff,
      @JsonKey(name: 'type_id') this.typeId = 'raid',
      @JsonKey(name: 'faction_tag') this.factionTag,
      @JsonKey(name: 'is_faction_exclusive') this.isFactionExclusive = false,
      @JsonKey(name: 'min_reputation') this.minReputation = 0,
      @JsonKey(name: 'sector_type') this.sectorType,
      @JsonKey(name: 'special_flags')
      final Map<String, dynamic> specialFlags = const <String, dynamic>{},
      @JsonKey(name: 'enemy_name') this.enemyName,
      @JsonKey(name: 'is_fixed') this.isFixed = false,
      @JsonKey(name: 'fixed_chain_id') this.fixedChainId,
      @JsonKey(name: 'fixed_step') this.fixedStep,
      @JsonKey(name: 'trust_threshold') this.trustThreshold,
      @JsonKey(name: 'reward_gold_override') this.rewardGoldOverride,
      @JsonKey(name: 'reward_xp_bonus_override') this.rewardXpBonusOverride,
      @JsonKey(name: 'duration_override_seconds') this.durationOverrideSeconds,
      @JsonKey(name: 'trust_reward_override') this.trustRewardOverride,
      @JsonKey(name: 'min_trust_level') this.minTrustLevel = 0})
      : _specialFlags = specialFlags;

  factory _$QuestPoolImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestPoolImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
// Deprecated: quest_types 외래 키는 type_id 사용 (Supabase quest_pools.type 컬럼 호환용으로 유지)
  @override
  final double type;
  @override
  final double difficulty;
  @override
  @JsonKey(name: 'min_region_diff')
  final double minRegionDiff;
  @override
  @JsonKey(name: 'max_region_diff')
  final double maxRegionDiff;
  @override
  @JsonKey(name: 'type_id')
  final String typeId;
  @override
  @JsonKey(name: 'faction_tag')
  final String? factionTag;
  @override
  @JsonKey(name: 'is_faction_exclusive')
  final bool isFactionExclusive;
  @override
  @JsonKey(name: 'min_reputation')
  final int minReputation;
  @override
  @JsonKey(name: 'sector_type')
  final String? sectorType;
  final Map<String, dynamic> _specialFlags;
  @override
  @JsonKey(name: 'special_flags')
  Map<String, dynamic> get specialFlags {
    if (_specialFlags is EqualUnmodifiableMapView) return _specialFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_specialFlags);
  }

  @override
  @JsonKey(name: 'enemy_name')
  final String? enemyName;
// 고정 의뢰 컬럼 (페이즈 1 #4)
  @override
  @JsonKey(name: 'is_fixed')
  final bool isFixed;
  @override
  @JsonKey(name: 'fixed_chain_id')
  final String? fixedChainId;
  @override
  @JsonKey(name: 'fixed_step')
  final int? fixedStep;
  @override
  @JsonKey(name: 'trust_threshold')
  final int? trustThreshold;
// 보상/시간 override 컬럼 (페이즈 2 #4)
  @override
  @JsonKey(name: 'reward_gold_override')
  final int? rewardGoldOverride;
  @override
  @JsonKey(name: 'reward_xp_bonus_override')
  final int? rewardXpBonusOverride;
  @override
  @JsonKey(name: 'duration_override_seconds')
  final int? durationOverrideSeconds;
  @override
  @JsonKey(name: 'trust_reward_override')
  final int? trustRewardOverride;
// 단계별 노출 제어 컬럼 (페이즈 2 #3)
  @override
  @JsonKey(name: 'min_trust_level')
  final int minTrustLevel;

  @override
  String toString() {
    return 'QuestPool(id: $id, name: $name, type: $type, difficulty: $difficulty, minRegionDiff: $minRegionDiff, maxRegionDiff: $maxRegionDiff, typeId: $typeId, factionTag: $factionTag, isFactionExclusive: $isFactionExclusive, minReputation: $minReputation, sectorType: $sectorType, specialFlags: $specialFlags, enemyName: $enemyName, isFixed: $isFixed, fixedChainId: $fixedChainId, fixedStep: $fixedStep, trustThreshold: $trustThreshold, rewardGoldOverride: $rewardGoldOverride, rewardXpBonusOverride: $rewardXpBonusOverride, durationOverrideSeconds: $durationOverrideSeconds, trustRewardOverride: $trustRewardOverride, minTrustLevel: $minTrustLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestPoolImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.minRegionDiff, minRegionDiff) ||
                other.minRegionDiff == minRegionDiff) &&
            (identical(other.maxRegionDiff, maxRegionDiff) ||
                other.maxRegionDiff == maxRegionDiff) &&
            (identical(other.typeId, typeId) || other.typeId == typeId) &&
            (identical(other.factionTag, factionTag) ||
                other.factionTag == factionTag) &&
            (identical(other.isFactionExclusive, isFactionExclusive) ||
                other.isFactionExclusive == isFactionExclusive) &&
            (identical(other.minReputation, minReputation) ||
                other.minReputation == minReputation) &&
            (identical(other.sectorType, sectorType) ||
                other.sectorType == sectorType) &&
            const DeepCollectionEquality()
                .equals(other._specialFlags, _specialFlags) &&
            (identical(other.enemyName, enemyName) ||
                other.enemyName == enemyName) &&
            (identical(other.isFixed, isFixed) || other.isFixed == isFixed) &&
            (identical(other.fixedChainId, fixedChainId) ||
                other.fixedChainId == fixedChainId) &&
            (identical(other.fixedStep, fixedStep) ||
                other.fixedStep == fixedStep) &&
            (identical(other.trustThreshold, trustThreshold) ||
                other.trustThreshold == trustThreshold) &&
            (identical(other.rewardGoldOverride, rewardGoldOverride) ||
                other.rewardGoldOverride == rewardGoldOverride) &&
            (identical(other.rewardXpBonusOverride, rewardXpBonusOverride) ||
                other.rewardXpBonusOverride == rewardXpBonusOverride) &&
            (identical(
                    other.durationOverrideSeconds, durationOverrideSeconds) ||
                other.durationOverrideSeconds == durationOverrideSeconds) &&
            (identical(other.trustRewardOverride, trustRewardOverride) ||
                other.trustRewardOverride == trustRewardOverride) &&
            (identical(other.minTrustLevel, minTrustLevel) ||
                other.minTrustLevel == minTrustLevel));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        type,
        difficulty,
        minRegionDiff,
        maxRegionDiff,
        typeId,
        factionTag,
        isFactionExclusive,
        minReputation,
        sectorType,
        const DeepCollectionEquality().hash(_specialFlags),
        enemyName,
        isFixed,
        fixedChainId,
        fixedStep,
        trustThreshold,
        rewardGoldOverride,
        rewardXpBonusOverride,
        durationOverrideSeconds,
        trustRewardOverride,
        minTrustLevel
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestPoolImplCopyWith<_$QuestPoolImpl> get copyWith =>
      __$$QuestPoolImplCopyWithImpl<_$QuestPoolImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestPoolImplToJson(
      this,
    );
  }
}

abstract class _QuestPool implements QuestPool {
  const factory _QuestPool(
      {required final String id,
      required final String name,
      required final double type,
      required final double difficulty,
      @JsonKey(name: 'min_region_diff') required final double minRegionDiff,
      @JsonKey(name: 'max_region_diff') required final double maxRegionDiff,
      @JsonKey(name: 'type_id') final String typeId,
      @JsonKey(name: 'faction_tag') final String? factionTag,
      @JsonKey(name: 'is_faction_exclusive') final bool isFactionExclusive,
      @JsonKey(name: 'min_reputation') final int minReputation,
      @JsonKey(name: 'sector_type') final String? sectorType,
      @JsonKey(name: 'special_flags') final Map<String, dynamic> specialFlags,
      @JsonKey(name: 'enemy_name') final String? enemyName,
      @JsonKey(name: 'is_fixed') final bool isFixed,
      @JsonKey(name: 'fixed_chain_id') final String? fixedChainId,
      @JsonKey(name: 'fixed_step') final int? fixedStep,
      @JsonKey(name: 'trust_threshold') final int? trustThreshold,
      @JsonKey(name: 'reward_gold_override') final int? rewardGoldOverride,
      @JsonKey(name: 'reward_xp_bonus_override')
      final int? rewardXpBonusOverride,
      @JsonKey(name: 'duration_override_seconds')
      final int? durationOverrideSeconds,
      @JsonKey(name: 'trust_reward_override') final int? trustRewardOverride,
      @JsonKey(name: 'min_trust_level')
      final int minTrustLevel}) = _$QuestPoolImpl;

  factory _QuestPool.fromJson(Map<String, dynamic> json) =
      _$QuestPoolImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override // Deprecated: quest_types 외래 키는 type_id 사용 (Supabase quest_pools.type 컬럼 호환용으로 유지)
  double get type;
  @override
  double get difficulty;
  @override
  @JsonKey(name: 'min_region_diff')
  double get minRegionDiff;
  @override
  @JsonKey(name: 'max_region_diff')
  double get maxRegionDiff;
  @override
  @JsonKey(name: 'type_id')
  String get typeId;
  @override
  @JsonKey(name: 'faction_tag')
  String? get factionTag;
  @override
  @JsonKey(name: 'is_faction_exclusive')
  bool get isFactionExclusive;
  @override
  @JsonKey(name: 'min_reputation')
  int get minReputation;
  @override
  @JsonKey(name: 'sector_type')
  String? get sectorType;
  @override
  @JsonKey(name: 'special_flags')
  Map<String, dynamic> get specialFlags;
  @override
  @JsonKey(name: 'enemy_name')
  String? get enemyName;
  @override // 고정 의뢰 컬럼 (페이즈 1 #4)
  @JsonKey(name: 'is_fixed')
  bool get isFixed;
  @override
  @JsonKey(name: 'fixed_chain_id')
  String? get fixedChainId;
  @override
  @JsonKey(name: 'fixed_step')
  int? get fixedStep;
  @override
  @JsonKey(name: 'trust_threshold')
  int? get trustThreshold;
  @override // 보상/시간 override 컬럼 (페이즈 2 #4)
  @JsonKey(name: 'reward_gold_override')
  int? get rewardGoldOverride;
  @override
  @JsonKey(name: 'reward_xp_bonus_override')
  int? get rewardXpBonusOverride;
  @override
  @JsonKey(name: 'duration_override_seconds')
  int? get durationOverrideSeconds;
  @override
  @JsonKey(name: 'trust_reward_override')
  int? get trustRewardOverride;
  @override // 단계별 노출 제어 컬럼 (페이즈 2 #3)
  @JsonKey(name: 'min_trust_level')
  int get minTrustLevel;
  @override
  @JsonKey(ignore: true)
  _$$QuestPoolImplCopyWith<_$QuestPoolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
