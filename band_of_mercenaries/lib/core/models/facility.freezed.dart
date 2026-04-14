// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'facility.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Facility _$FacilityFromJson(Map<String, dynamic> json) {
  return _Facility.fromJson(json);
}

/// @nodoc
mixin _$Facility {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_type')
  String get effectType => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_level')
  int get maxLevel => throw _privateConstructorUsedError;
  List<int> get costs => throw _privateConstructorUsedError;
  List<double> get values => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_cost')
  int? get baseCost => throw _privateConstructorUsedError;
  @JsonKey(name: 'cost_multiplier')
  double? get costMultiplier => throw _privateConstructorUsedError;
  @JsonKey(name: 'lv1_cost')
  int? get lv1Cost => throw _privateConstructorUsedError;
  @JsonKey(name: 'lv2_cost')
  int? get lv2Cost => throw _privateConstructorUsedError;
  @JsonKey(name: 'base_time')
  int? get baseTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'time_multiplier')
  double? get timeMultiplier => throw _privateConstructorUsedError;
  @JsonKey(name: 'lv1_time')
  int? get lv1Time => throw _privateConstructorUsedError;
  @JsonKey(name: 'lv2_time')
  int? get lv2Time => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_effect')
  double? get maxEffect => throw _privateConstructorUsedError;
  double? get alpha => throw _privateConstructorUsedError;
  List<Map<String, dynamic>>? get milestones =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FacilityCopyWith<Facility> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FacilityCopyWith<$Res> {
  factory $FacilityCopyWith(Facility value, $Res Function(Facility) then) =
      _$FacilityCopyWithImpl<$Res, Facility>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'effect_type') String effectType,
      @JsonKey(name: 'max_level') int maxLevel,
      List<int> costs,
      List<double> values,
      String? description,
      String? category,
      @JsonKey(name: 'base_cost') int? baseCost,
      @JsonKey(name: 'cost_multiplier') double? costMultiplier,
      @JsonKey(name: 'lv1_cost') int? lv1Cost,
      @JsonKey(name: 'lv2_cost') int? lv2Cost,
      @JsonKey(name: 'base_time') int? baseTime,
      @JsonKey(name: 'time_multiplier') double? timeMultiplier,
      @JsonKey(name: 'lv1_time') int? lv1Time,
      @JsonKey(name: 'lv2_time') int? lv2Time,
      @JsonKey(name: 'max_effect') double? maxEffect,
      double? alpha,
      List<Map<String, dynamic>>? milestones});
}

/// @nodoc
class _$FacilityCopyWithImpl<$Res, $Val extends Facility>
    implements $FacilityCopyWith<$Res> {
  _$FacilityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? effectType = null,
    Object? maxLevel = null,
    Object? costs = null,
    Object? values = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? baseCost = freezed,
    Object? costMultiplier = freezed,
    Object? lv1Cost = freezed,
    Object? lv2Cost = freezed,
    Object? baseTime = freezed,
    Object? timeMultiplier = freezed,
    Object? lv1Time = freezed,
    Object? lv2Time = freezed,
    Object? maxEffect = freezed,
    Object? alpha = freezed,
    Object? milestones = freezed,
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
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as String,
      maxLevel: null == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int,
      costs: null == costs
          ? _value.costs
          : costs // ignore: cast_nullable_to_non_nullable
              as List<int>,
      values: null == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as List<double>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      baseCost: freezed == baseCost
          ? _value.baseCost
          : baseCost // ignore: cast_nullable_to_non_nullable
              as int?,
      costMultiplier: freezed == costMultiplier
          ? _value.costMultiplier
          : costMultiplier // ignore: cast_nullable_to_non_nullable
              as double?,
      lv1Cost: freezed == lv1Cost
          ? _value.lv1Cost
          : lv1Cost // ignore: cast_nullable_to_non_nullable
              as int?,
      lv2Cost: freezed == lv2Cost
          ? _value.lv2Cost
          : lv2Cost // ignore: cast_nullable_to_non_nullable
              as int?,
      baseTime: freezed == baseTime
          ? _value.baseTime
          : baseTime // ignore: cast_nullable_to_non_nullable
              as int?,
      timeMultiplier: freezed == timeMultiplier
          ? _value.timeMultiplier
          : timeMultiplier // ignore: cast_nullable_to_non_nullable
              as double?,
      lv1Time: freezed == lv1Time
          ? _value.lv1Time
          : lv1Time // ignore: cast_nullable_to_non_nullable
              as int?,
      lv2Time: freezed == lv2Time
          ? _value.lv2Time
          : lv2Time // ignore: cast_nullable_to_non_nullable
              as int?,
      maxEffect: freezed == maxEffect
          ? _value.maxEffect
          : maxEffect // ignore: cast_nullable_to_non_nullable
              as double?,
      alpha: freezed == alpha
          ? _value.alpha
          : alpha // ignore: cast_nullable_to_non_nullable
              as double?,
      milestones: freezed == milestones
          ? _value.milestones
          : milestones // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FacilityImplCopyWith<$Res>
    implements $FacilityCopyWith<$Res> {
  factory _$$FacilityImplCopyWith(
          _$FacilityImpl value, $Res Function(_$FacilityImpl) then) =
      __$$FacilityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'effect_type') String effectType,
      @JsonKey(name: 'max_level') int maxLevel,
      List<int> costs,
      List<double> values,
      String? description,
      String? category,
      @JsonKey(name: 'base_cost') int? baseCost,
      @JsonKey(name: 'cost_multiplier') double? costMultiplier,
      @JsonKey(name: 'lv1_cost') int? lv1Cost,
      @JsonKey(name: 'lv2_cost') int? lv2Cost,
      @JsonKey(name: 'base_time') int? baseTime,
      @JsonKey(name: 'time_multiplier') double? timeMultiplier,
      @JsonKey(name: 'lv1_time') int? lv1Time,
      @JsonKey(name: 'lv2_time') int? lv2Time,
      @JsonKey(name: 'max_effect') double? maxEffect,
      double? alpha,
      List<Map<String, dynamic>>? milestones});
}

/// @nodoc
class __$$FacilityImplCopyWithImpl<$Res>
    extends _$FacilityCopyWithImpl<$Res, _$FacilityImpl>
    implements _$$FacilityImplCopyWith<$Res> {
  __$$FacilityImplCopyWithImpl(
      _$FacilityImpl _value, $Res Function(_$FacilityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? effectType = null,
    Object? maxLevel = null,
    Object? costs = null,
    Object? values = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? baseCost = freezed,
    Object? costMultiplier = freezed,
    Object? lv1Cost = freezed,
    Object? lv2Cost = freezed,
    Object? baseTime = freezed,
    Object? timeMultiplier = freezed,
    Object? lv1Time = freezed,
    Object? lv2Time = freezed,
    Object? maxEffect = freezed,
    Object? alpha = freezed,
    Object? milestones = freezed,
  }) {
    return _then(_$FacilityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as String,
      maxLevel: null == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int,
      costs: null == costs
          ? _value._costs
          : costs // ignore: cast_nullable_to_non_nullable
              as List<int>,
      values: null == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as List<double>,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      baseCost: freezed == baseCost
          ? _value.baseCost
          : baseCost // ignore: cast_nullable_to_non_nullable
              as int?,
      costMultiplier: freezed == costMultiplier
          ? _value.costMultiplier
          : costMultiplier // ignore: cast_nullable_to_non_nullable
              as double?,
      lv1Cost: freezed == lv1Cost
          ? _value.lv1Cost
          : lv1Cost // ignore: cast_nullable_to_non_nullable
              as int?,
      lv2Cost: freezed == lv2Cost
          ? _value.lv2Cost
          : lv2Cost // ignore: cast_nullable_to_non_nullable
              as int?,
      baseTime: freezed == baseTime
          ? _value.baseTime
          : baseTime // ignore: cast_nullable_to_non_nullable
              as int?,
      timeMultiplier: freezed == timeMultiplier
          ? _value.timeMultiplier
          : timeMultiplier // ignore: cast_nullable_to_non_nullable
              as double?,
      lv1Time: freezed == lv1Time
          ? _value.lv1Time
          : lv1Time // ignore: cast_nullable_to_non_nullable
              as int?,
      lv2Time: freezed == lv2Time
          ? _value.lv2Time
          : lv2Time // ignore: cast_nullable_to_non_nullable
              as int?,
      maxEffect: freezed == maxEffect
          ? _value.maxEffect
          : maxEffect // ignore: cast_nullable_to_non_nullable
              as double?,
      alpha: freezed == alpha
          ? _value.alpha
          : alpha // ignore: cast_nullable_to_non_nullable
              as double?,
      milestones: freezed == milestones
          ? _value._milestones
          : milestones // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FacilityImpl implements _Facility {
  const _$FacilityImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'effect_type') required this.effectType,
      @JsonKey(name: 'max_level') required this.maxLevel,
      required final List<int> costs,
      required final List<double> values,
      this.description,
      this.category,
      @JsonKey(name: 'base_cost') this.baseCost,
      @JsonKey(name: 'cost_multiplier') this.costMultiplier,
      @JsonKey(name: 'lv1_cost') this.lv1Cost,
      @JsonKey(name: 'lv2_cost') this.lv2Cost,
      @JsonKey(name: 'base_time') this.baseTime,
      @JsonKey(name: 'time_multiplier') this.timeMultiplier,
      @JsonKey(name: 'lv1_time') this.lv1Time,
      @JsonKey(name: 'lv2_time') this.lv2Time,
      @JsonKey(name: 'max_effect') this.maxEffect,
      this.alpha,
      final List<Map<String, dynamic>>? milestones})
      : _costs = costs,
        _values = values,
        _milestones = milestones;

  factory _$FacilityImpl.fromJson(Map<String, dynamic> json) =>
      _$$FacilityImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'effect_type')
  final String effectType;
  @override
  @JsonKey(name: 'max_level')
  final int maxLevel;
  final List<int> _costs;
  @override
  List<int> get costs {
    if (_costs is EqualUnmodifiableListView) return _costs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_costs);
  }

  final List<double> _values;
  @override
  List<double> get values {
    if (_values is EqualUnmodifiableListView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_values);
  }

  @override
  final String? description;
  @override
  final String? category;
  @override
  @JsonKey(name: 'base_cost')
  final int? baseCost;
  @override
  @JsonKey(name: 'cost_multiplier')
  final double? costMultiplier;
  @override
  @JsonKey(name: 'lv1_cost')
  final int? lv1Cost;
  @override
  @JsonKey(name: 'lv2_cost')
  final int? lv2Cost;
  @override
  @JsonKey(name: 'base_time')
  final int? baseTime;
  @override
  @JsonKey(name: 'time_multiplier')
  final double? timeMultiplier;
  @override
  @JsonKey(name: 'lv1_time')
  final int? lv1Time;
  @override
  @JsonKey(name: 'lv2_time')
  final int? lv2Time;
  @override
  @JsonKey(name: 'max_effect')
  final double? maxEffect;
  @override
  final double? alpha;
  final List<Map<String, dynamic>>? _milestones;
  @override
  List<Map<String, dynamic>>? get milestones {
    final value = _milestones;
    if (value == null) return null;
    if (_milestones is EqualUnmodifiableListView) return _milestones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Facility(id: $id, name: $name, effectType: $effectType, maxLevel: $maxLevel, costs: $costs, values: $values, description: $description, category: $category, baseCost: $baseCost, costMultiplier: $costMultiplier, lv1Cost: $lv1Cost, lv2Cost: $lv2Cost, baseTime: $baseTime, timeMultiplier: $timeMultiplier, lv1Time: $lv1Time, lv2Time: $lv2Time, maxEffect: $maxEffect, alpha: $alpha, milestones: $milestones)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FacilityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.effectType, effectType) ||
                other.effectType == effectType) &&
            (identical(other.maxLevel, maxLevel) ||
                other.maxLevel == maxLevel) &&
            const DeepCollectionEquality().equals(other._costs, _costs) &&
            const DeepCollectionEquality().equals(other._values, _values) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.baseCost, baseCost) ||
                other.baseCost == baseCost) &&
            (identical(other.costMultiplier, costMultiplier) ||
                other.costMultiplier == costMultiplier) &&
            (identical(other.lv1Cost, lv1Cost) || other.lv1Cost == lv1Cost) &&
            (identical(other.lv2Cost, lv2Cost) || other.lv2Cost == lv2Cost) &&
            (identical(other.baseTime, baseTime) ||
                other.baseTime == baseTime) &&
            (identical(other.timeMultiplier, timeMultiplier) ||
                other.timeMultiplier == timeMultiplier) &&
            (identical(other.lv1Time, lv1Time) || other.lv1Time == lv1Time) &&
            (identical(other.lv2Time, lv2Time) || other.lv2Time == lv2Time) &&
            (identical(other.maxEffect, maxEffect) ||
                other.maxEffect == maxEffect) &&
            (identical(other.alpha, alpha) || other.alpha == alpha) &&
            const DeepCollectionEquality()
                .equals(other._milestones, _milestones));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        effectType,
        maxLevel,
        const DeepCollectionEquality().hash(_costs),
        const DeepCollectionEquality().hash(_values),
        description,
        category,
        baseCost,
        costMultiplier,
        lv1Cost,
        lv2Cost,
        baseTime,
        timeMultiplier,
        lv1Time,
        lv2Time,
        maxEffect,
        alpha,
        const DeepCollectionEquality().hash(_milestones)
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FacilityImplCopyWith<_$FacilityImpl> get copyWith =>
      __$$FacilityImplCopyWithImpl<_$FacilityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FacilityImplToJson(
      this,
    );
  }
}

abstract class _Facility implements Facility {
  const factory _Facility(
      {required final String id,
      required final String name,
      @JsonKey(name: 'effect_type') required final String effectType,
      @JsonKey(name: 'max_level') required final int maxLevel,
      required final List<int> costs,
      required final List<double> values,
      final String? description,
      final String? category,
      @JsonKey(name: 'base_cost') final int? baseCost,
      @JsonKey(name: 'cost_multiplier') final double? costMultiplier,
      @JsonKey(name: 'lv1_cost') final int? lv1Cost,
      @JsonKey(name: 'lv2_cost') final int? lv2Cost,
      @JsonKey(name: 'base_time') final int? baseTime,
      @JsonKey(name: 'time_multiplier') final double? timeMultiplier,
      @JsonKey(name: 'lv1_time') final int? lv1Time,
      @JsonKey(name: 'lv2_time') final int? lv2Time,
      @JsonKey(name: 'max_effect') final double? maxEffect,
      final double? alpha,
      final List<Map<String, dynamic>>? milestones}) = _$FacilityImpl;

  factory _Facility.fromJson(Map<String, dynamic> json) =
      _$FacilityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'effect_type')
  String get effectType;
  @override
  @JsonKey(name: 'max_level')
  int get maxLevel;
  @override
  List<int> get costs;
  @override
  List<double> get values;
  @override
  String? get description;
  @override
  String? get category;
  @override
  @JsonKey(name: 'base_cost')
  int? get baseCost;
  @override
  @JsonKey(name: 'cost_multiplier')
  double? get costMultiplier;
  @override
  @JsonKey(name: 'lv1_cost')
  int? get lv1Cost;
  @override
  @JsonKey(name: 'lv2_cost')
  int? get lv2Cost;
  @override
  @JsonKey(name: 'base_time')
  int? get baseTime;
  @override
  @JsonKey(name: 'time_multiplier')
  double? get timeMultiplier;
  @override
  @JsonKey(name: 'lv1_time')
  int? get lv1Time;
  @override
  @JsonKey(name: 'lv2_time')
  int? get lv2Time;
  @override
  @JsonKey(name: 'max_effect')
  double? get maxEffect;
  @override
  double? get alpha;
  @override
  List<Map<String, dynamic>>? get milestones;
  @override
  @JsonKey(ignore: true)
  _$$FacilityImplCopyWith<_$FacilityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
