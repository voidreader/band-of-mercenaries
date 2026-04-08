// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'difficulty.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Difficulty _$DifficultyFromJson(Map<String, dynamic> json) {
  return _Difficulty.fromJson(json);
}

/// @nodoc
mixin _$Difficulty {
  @JsonKey(name: 'Level')
  int get level => throw _privateConstructorUsedError;
  @JsonKey(name: 'EnemyPower')
  int get enemyPower => throw _privateConstructorUsedError;
  @JsonKey(name: 'RewardMultiplier')
  double get rewardMultiplier => throw _privateConstructorUsedError;
  @JsonKey(name: 'SuccessPenalty')
  double get successPenalty => throw _privateConstructorUsedError;
  @JsonKey(name: 'InjuryRate')
  double get injuryRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'DeathRate')
  double get deathRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'DispatchCost')
  int get dispatchCost => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DifficultyCopyWith<Difficulty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DifficultyCopyWith<$Res> {
  factory $DifficultyCopyWith(
          Difficulty value, $Res Function(Difficulty) then) =
      _$DifficultyCopyWithImpl<$Res, Difficulty>;
  @useResult
  $Res call(
      {@JsonKey(name: 'Level') int level,
      @JsonKey(name: 'EnemyPower') int enemyPower,
      @JsonKey(name: 'RewardMultiplier') double rewardMultiplier,
      @JsonKey(name: 'SuccessPenalty') double successPenalty,
      @JsonKey(name: 'InjuryRate') double injuryRate,
      @JsonKey(name: 'DeathRate') double deathRate,
      @JsonKey(name: 'DispatchCost') int dispatchCost});
}

/// @nodoc
class _$DifficultyCopyWithImpl<$Res, $Val extends Difficulty>
    implements $DifficultyCopyWith<$Res> {
  _$DifficultyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? enemyPower = null,
    Object? rewardMultiplier = null,
    Object? successPenalty = null,
    Object? injuryRate = null,
    Object? deathRate = null,
    Object? dispatchCost = null,
  }) {
    return _then(_value.copyWith(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      enemyPower: null == enemyPower
          ? _value.enemyPower
          : enemyPower // ignore: cast_nullable_to_non_nullable
              as int,
      rewardMultiplier: null == rewardMultiplier
          ? _value.rewardMultiplier
          : rewardMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      successPenalty: null == successPenalty
          ? _value.successPenalty
          : successPenalty // ignore: cast_nullable_to_non_nullable
              as double,
      injuryRate: null == injuryRate
          ? _value.injuryRate
          : injuryRate // ignore: cast_nullable_to_non_nullable
              as double,
      deathRate: null == deathRate
          ? _value.deathRate
          : deathRate // ignore: cast_nullable_to_non_nullable
              as double,
      dispatchCost: null == dispatchCost
          ? _value.dispatchCost
          : dispatchCost // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DifficultyImplCopyWith<$Res>
    implements $DifficultyCopyWith<$Res> {
  factory _$$DifficultyImplCopyWith(
          _$DifficultyImpl value, $Res Function(_$DifficultyImpl) then) =
      __$$DifficultyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'Level') int level,
      @JsonKey(name: 'EnemyPower') int enemyPower,
      @JsonKey(name: 'RewardMultiplier') double rewardMultiplier,
      @JsonKey(name: 'SuccessPenalty') double successPenalty,
      @JsonKey(name: 'InjuryRate') double injuryRate,
      @JsonKey(name: 'DeathRate') double deathRate,
      @JsonKey(name: 'DispatchCost') int dispatchCost});
}

/// @nodoc
class __$$DifficultyImplCopyWithImpl<$Res>
    extends _$DifficultyCopyWithImpl<$Res, _$DifficultyImpl>
    implements _$$DifficultyImplCopyWith<$Res> {
  __$$DifficultyImplCopyWithImpl(
      _$DifficultyImpl _value, $Res Function(_$DifficultyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? enemyPower = null,
    Object? rewardMultiplier = null,
    Object? successPenalty = null,
    Object? injuryRate = null,
    Object? deathRate = null,
    Object? dispatchCost = null,
  }) {
    return _then(_$DifficultyImpl(
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      enemyPower: null == enemyPower
          ? _value.enemyPower
          : enemyPower // ignore: cast_nullable_to_non_nullable
              as int,
      rewardMultiplier: null == rewardMultiplier
          ? _value.rewardMultiplier
          : rewardMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      successPenalty: null == successPenalty
          ? _value.successPenalty
          : successPenalty // ignore: cast_nullable_to_non_nullable
              as double,
      injuryRate: null == injuryRate
          ? _value.injuryRate
          : injuryRate // ignore: cast_nullable_to_non_nullable
              as double,
      deathRate: null == deathRate
          ? _value.deathRate
          : deathRate // ignore: cast_nullable_to_non_nullable
              as double,
      dispatchCost: null == dispatchCost
          ? _value.dispatchCost
          : dispatchCost // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DifficultyImpl implements _Difficulty {
  const _$DifficultyImpl(
      {@JsonKey(name: 'Level') required this.level,
      @JsonKey(name: 'EnemyPower') required this.enemyPower,
      @JsonKey(name: 'RewardMultiplier') required this.rewardMultiplier,
      @JsonKey(name: 'SuccessPenalty') required this.successPenalty,
      @JsonKey(name: 'InjuryRate') required this.injuryRate,
      @JsonKey(name: 'DeathRate') required this.deathRate,
      @JsonKey(name: 'DispatchCost') required this.dispatchCost});

  factory _$DifficultyImpl.fromJson(Map<String, dynamic> json) =>
      _$$DifficultyImplFromJson(json);

  @override
  @JsonKey(name: 'Level')
  final int level;
  @override
  @JsonKey(name: 'EnemyPower')
  final int enemyPower;
  @override
  @JsonKey(name: 'RewardMultiplier')
  final double rewardMultiplier;
  @override
  @JsonKey(name: 'SuccessPenalty')
  final double successPenalty;
  @override
  @JsonKey(name: 'InjuryRate')
  final double injuryRate;
  @override
  @JsonKey(name: 'DeathRate')
  final double deathRate;
  @override
  @JsonKey(name: 'DispatchCost')
  final int dispatchCost;

  @override
  String toString() {
    return 'Difficulty(level: $level, enemyPower: $enemyPower, rewardMultiplier: $rewardMultiplier, successPenalty: $successPenalty, injuryRate: $injuryRate, deathRate: $deathRate, dispatchCost: $dispatchCost)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DifficultyImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.enemyPower, enemyPower) ||
                other.enemyPower == enemyPower) &&
            (identical(other.rewardMultiplier, rewardMultiplier) ||
                other.rewardMultiplier == rewardMultiplier) &&
            (identical(other.successPenalty, successPenalty) ||
                other.successPenalty == successPenalty) &&
            (identical(other.injuryRate, injuryRate) ||
                other.injuryRate == injuryRate) &&
            (identical(other.deathRate, deathRate) ||
                other.deathRate == deathRate) &&
            (identical(other.dispatchCost, dispatchCost) ||
                other.dispatchCost == dispatchCost));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, level, enemyPower,
      rewardMultiplier, successPenalty, injuryRate, deathRate, dispatchCost);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DifficultyImplCopyWith<_$DifficultyImpl> get copyWith =>
      __$$DifficultyImplCopyWithImpl<_$DifficultyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DifficultyImplToJson(
      this,
    );
  }
}

abstract class _Difficulty implements Difficulty {
  const factory _Difficulty(
      {@JsonKey(name: 'Level') required final int level,
      @JsonKey(name: 'EnemyPower') required final int enemyPower,
      @JsonKey(name: 'RewardMultiplier') required final double rewardMultiplier,
      @JsonKey(name: 'SuccessPenalty') required final double successPenalty,
      @JsonKey(name: 'InjuryRate') required final double injuryRate,
      @JsonKey(name: 'DeathRate') required final double deathRate,
      @JsonKey(name: 'DispatchCost')
      required final int dispatchCost}) = _$DifficultyImpl;

  factory _Difficulty.fromJson(Map<String, dynamic> json) =
      _$DifficultyImpl.fromJson;

  @override
  @JsonKey(name: 'Level')
  int get level;
  @override
  @JsonKey(name: 'EnemyPower')
  int get enemyPower;
  @override
  @JsonKey(name: 'RewardMultiplier')
  double get rewardMultiplier;
  @override
  @JsonKey(name: 'SuccessPenalty')
  double get successPenalty;
  @override
  @JsonKey(name: 'InjuryRate')
  double get injuryRate;
  @override
  @JsonKey(name: 'DeathRate')
  double get deathRate;
  @override
  @JsonKey(name: 'DispatchCost')
  int get dispatchCost;
  @override
  @JsonKey(ignore: true)
  _$$DifficultyImplCopyWith<_$DifficultyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DifficultyList _$DifficultyListFromJson(Map<String, dynamic> json) {
  return _DifficultyList.fromJson(json);
}

/// @nodoc
mixin _$DifficultyList {
  @JsonKey(name: 'Difficultys')
  List<Difficulty> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DifficultyListCopyWith<DifficultyList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DifficultyListCopyWith<$Res> {
  factory $DifficultyListCopyWith(
          DifficultyList value, $Res Function(DifficultyList) then) =
      _$DifficultyListCopyWithImpl<$Res, DifficultyList>;
  @useResult
  $Res call({@JsonKey(name: 'Difficultys') List<Difficulty> items});
}

/// @nodoc
class _$DifficultyListCopyWithImpl<$Res, $Val extends DifficultyList>
    implements $DifficultyListCopyWith<$Res> {
  _$DifficultyListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Difficulty>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DifficultyListImplCopyWith<$Res>
    implements $DifficultyListCopyWith<$Res> {
  factory _$$DifficultyListImplCopyWith(_$DifficultyListImpl value,
          $Res Function(_$DifficultyListImpl) then) =
      __$$DifficultyListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'Difficultys') List<Difficulty> items});
}

/// @nodoc
class __$$DifficultyListImplCopyWithImpl<$Res>
    extends _$DifficultyListCopyWithImpl<$Res, _$DifficultyListImpl>
    implements _$$DifficultyListImplCopyWith<$Res> {
  __$$DifficultyListImplCopyWithImpl(
      _$DifficultyListImpl _value, $Res Function(_$DifficultyListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$DifficultyListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<Difficulty>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DifficultyListImpl implements _DifficultyList {
  const _$DifficultyListImpl(
      {@JsonKey(name: 'Difficultys') required final List<Difficulty> items})
      : _items = items;

  factory _$DifficultyListImpl.fromJson(Map<String, dynamic> json) =>
      _$$DifficultyListImplFromJson(json);

  final List<Difficulty> _items;
  @override
  @JsonKey(name: 'Difficultys')
  List<Difficulty> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'DifficultyList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DifficultyListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DifficultyListImplCopyWith<_$DifficultyListImpl> get copyWith =>
      __$$DifficultyListImplCopyWithImpl<_$DifficultyListImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DifficultyListImplToJson(
      this,
    );
  }
}

abstract class _DifficultyList implements DifficultyList {
  const factory _DifficultyList(
      {@JsonKey(name: 'Difficultys')
      required final List<Difficulty> items}) = _$DifficultyListImpl;

  factory _DifficultyList.fromJson(Map<String, dynamic> json) =
      _$DifficultyListImpl.fromJson;

  @override
  @JsonKey(name: 'Difficultys')
  List<Difficulty> get items;
  @override
  @JsonKey(ignore: true)
  _$$DifficultyListImplCopyWith<_$DifficultyListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
