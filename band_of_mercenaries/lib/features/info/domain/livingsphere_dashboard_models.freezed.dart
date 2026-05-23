// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'livingsphere_dashboard_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GoalJumpTarget {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? regionId) movement,
    required TResult Function(String? questPoolId) dispatch,
    required TResult Function(VillageFacility facility, int regionId)
        settlementFacility,
    required TResult Function(String? itemId) inventory,
    required TResult Function() smithy,
    required TResult Function(String? factionId) faction,
    required TResult Function() chronicle,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? regionId)? movement,
    TResult? Function(String? questPoolId)? dispatch,
    TResult? Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult? Function(String? itemId)? inventory,
    TResult? Function()? smithy,
    TResult? Function(String? factionId)? faction,
    TResult? Function()? chronicle,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? regionId)? movement,
    TResult Function(String? questPoolId)? dispatch,
    TResult Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult Function(String? itemId)? inventory,
    TResult Function()? smithy,
    TResult Function(String? factionId)? faction,
    TResult Function()? chronicle,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GoalJumpTargetMovement value) movement,
    required TResult Function(GoalJumpTargetDispatch value) dispatch,
    required TResult Function(GoalJumpTargetSettlementFacility value)
        settlementFacility,
    required TResult Function(GoalJumpTargetInventory value) inventory,
    required TResult Function(GoalJumpTargetSmithy value) smithy,
    required TResult Function(GoalJumpTargetFaction value) faction,
    required TResult Function(GoalJumpTargetChronicle value) chronicle,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GoalJumpTargetMovement value)? movement,
    TResult? Function(GoalJumpTargetDispatch value)? dispatch,
    TResult? Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult? Function(GoalJumpTargetInventory value)? inventory,
    TResult? Function(GoalJumpTargetSmithy value)? smithy,
    TResult? Function(GoalJumpTargetFaction value)? faction,
    TResult? Function(GoalJumpTargetChronicle value)? chronicle,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GoalJumpTargetMovement value)? movement,
    TResult Function(GoalJumpTargetDispatch value)? dispatch,
    TResult Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult Function(GoalJumpTargetInventory value)? inventory,
    TResult Function(GoalJumpTargetSmithy value)? smithy,
    TResult Function(GoalJumpTargetFaction value)? faction,
    TResult Function(GoalJumpTargetChronicle value)? chronicle,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalJumpTargetCopyWith<$Res> {
  factory $GoalJumpTargetCopyWith(
          GoalJumpTarget value, $Res Function(GoalJumpTarget) then) =
      _$GoalJumpTargetCopyWithImpl<$Res, GoalJumpTarget>;
}

/// @nodoc
class _$GoalJumpTargetCopyWithImpl<$Res, $Val extends GoalJumpTarget>
    implements $GoalJumpTargetCopyWith<$Res> {
  _$GoalJumpTargetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$GoalJumpTargetMovementImplCopyWith<$Res> {
  factory _$$GoalJumpTargetMovementImplCopyWith(
          _$GoalJumpTargetMovementImpl value,
          $Res Function(_$GoalJumpTargetMovementImpl) then) =
      __$$GoalJumpTargetMovementImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int? regionId});
}

/// @nodoc
class __$$GoalJumpTargetMovementImplCopyWithImpl<$Res>
    extends _$GoalJumpTargetCopyWithImpl<$Res, _$GoalJumpTargetMovementImpl>
    implements _$$GoalJumpTargetMovementImplCopyWith<$Res> {
  __$$GoalJumpTargetMovementImplCopyWithImpl(
      _$GoalJumpTargetMovementImpl _value,
      $Res Function(_$GoalJumpTargetMovementImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? regionId = freezed,
  }) {
    return _then(_$GoalJumpTargetMovementImpl(
      regionId: freezed == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$GoalJumpTargetMovementImpl implements GoalJumpTargetMovement {
  const _$GoalJumpTargetMovementImpl({this.regionId});

  @override
  final int? regionId;

  @override
  String toString() {
    return 'GoalJumpTarget.movement(regionId: $regionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalJumpTargetMovementImpl &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, regionId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalJumpTargetMovementImplCopyWith<_$GoalJumpTargetMovementImpl>
      get copyWith => __$$GoalJumpTargetMovementImplCopyWithImpl<
          _$GoalJumpTargetMovementImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? regionId) movement,
    required TResult Function(String? questPoolId) dispatch,
    required TResult Function(VillageFacility facility, int regionId)
        settlementFacility,
    required TResult Function(String? itemId) inventory,
    required TResult Function() smithy,
    required TResult Function(String? factionId) faction,
    required TResult Function() chronicle,
  }) {
    return movement(regionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? regionId)? movement,
    TResult? Function(String? questPoolId)? dispatch,
    TResult? Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult? Function(String? itemId)? inventory,
    TResult? Function()? smithy,
    TResult? Function(String? factionId)? faction,
    TResult? Function()? chronicle,
  }) {
    return movement?.call(regionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? regionId)? movement,
    TResult Function(String? questPoolId)? dispatch,
    TResult Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult Function(String? itemId)? inventory,
    TResult Function()? smithy,
    TResult Function(String? factionId)? faction,
    TResult Function()? chronicle,
    required TResult orElse(),
  }) {
    if (movement != null) {
      return movement(regionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GoalJumpTargetMovement value) movement,
    required TResult Function(GoalJumpTargetDispatch value) dispatch,
    required TResult Function(GoalJumpTargetSettlementFacility value)
        settlementFacility,
    required TResult Function(GoalJumpTargetInventory value) inventory,
    required TResult Function(GoalJumpTargetSmithy value) smithy,
    required TResult Function(GoalJumpTargetFaction value) faction,
    required TResult Function(GoalJumpTargetChronicle value) chronicle,
  }) {
    return movement(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GoalJumpTargetMovement value)? movement,
    TResult? Function(GoalJumpTargetDispatch value)? dispatch,
    TResult? Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult? Function(GoalJumpTargetInventory value)? inventory,
    TResult? Function(GoalJumpTargetSmithy value)? smithy,
    TResult? Function(GoalJumpTargetFaction value)? faction,
    TResult? Function(GoalJumpTargetChronicle value)? chronicle,
  }) {
    return movement?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GoalJumpTargetMovement value)? movement,
    TResult Function(GoalJumpTargetDispatch value)? dispatch,
    TResult Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult Function(GoalJumpTargetInventory value)? inventory,
    TResult Function(GoalJumpTargetSmithy value)? smithy,
    TResult Function(GoalJumpTargetFaction value)? faction,
    TResult Function(GoalJumpTargetChronicle value)? chronicle,
    required TResult orElse(),
  }) {
    if (movement != null) {
      return movement(this);
    }
    return orElse();
  }
}

abstract class GoalJumpTargetMovement implements GoalJumpTarget {
  const factory GoalJumpTargetMovement({final int? regionId}) =
      _$GoalJumpTargetMovementImpl;

  int? get regionId;
  @JsonKey(ignore: true)
  _$$GoalJumpTargetMovementImplCopyWith<_$GoalJumpTargetMovementImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GoalJumpTargetDispatchImplCopyWith<$Res> {
  factory _$$GoalJumpTargetDispatchImplCopyWith(
          _$GoalJumpTargetDispatchImpl value,
          $Res Function(_$GoalJumpTargetDispatchImpl) then) =
      __$$GoalJumpTargetDispatchImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? questPoolId});
}

/// @nodoc
class __$$GoalJumpTargetDispatchImplCopyWithImpl<$Res>
    extends _$GoalJumpTargetCopyWithImpl<$Res, _$GoalJumpTargetDispatchImpl>
    implements _$$GoalJumpTargetDispatchImplCopyWith<$Res> {
  __$$GoalJumpTargetDispatchImplCopyWithImpl(
      _$GoalJumpTargetDispatchImpl _value,
      $Res Function(_$GoalJumpTargetDispatchImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questPoolId = freezed,
  }) {
    return _then(_$GoalJumpTargetDispatchImpl(
      questPoolId: freezed == questPoolId
          ? _value.questPoolId
          : questPoolId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$GoalJumpTargetDispatchImpl implements GoalJumpTargetDispatch {
  const _$GoalJumpTargetDispatchImpl({this.questPoolId});

  @override
  final String? questPoolId;

  @override
  String toString() {
    return 'GoalJumpTarget.dispatch(questPoolId: $questPoolId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalJumpTargetDispatchImpl &&
            (identical(other.questPoolId, questPoolId) ||
                other.questPoolId == questPoolId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, questPoolId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalJumpTargetDispatchImplCopyWith<_$GoalJumpTargetDispatchImpl>
      get copyWith => __$$GoalJumpTargetDispatchImplCopyWithImpl<
          _$GoalJumpTargetDispatchImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? regionId) movement,
    required TResult Function(String? questPoolId) dispatch,
    required TResult Function(VillageFacility facility, int regionId)
        settlementFacility,
    required TResult Function(String? itemId) inventory,
    required TResult Function() smithy,
    required TResult Function(String? factionId) faction,
    required TResult Function() chronicle,
  }) {
    return dispatch(questPoolId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? regionId)? movement,
    TResult? Function(String? questPoolId)? dispatch,
    TResult? Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult? Function(String? itemId)? inventory,
    TResult? Function()? smithy,
    TResult? Function(String? factionId)? faction,
    TResult? Function()? chronicle,
  }) {
    return dispatch?.call(questPoolId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? regionId)? movement,
    TResult Function(String? questPoolId)? dispatch,
    TResult Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult Function(String? itemId)? inventory,
    TResult Function()? smithy,
    TResult Function(String? factionId)? faction,
    TResult Function()? chronicle,
    required TResult orElse(),
  }) {
    if (dispatch != null) {
      return dispatch(questPoolId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GoalJumpTargetMovement value) movement,
    required TResult Function(GoalJumpTargetDispatch value) dispatch,
    required TResult Function(GoalJumpTargetSettlementFacility value)
        settlementFacility,
    required TResult Function(GoalJumpTargetInventory value) inventory,
    required TResult Function(GoalJumpTargetSmithy value) smithy,
    required TResult Function(GoalJumpTargetFaction value) faction,
    required TResult Function(GoalJumpTargetChronicle value) chronicle,
  }) {
    return dispatch(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GoalJumpTargetMovement value)? movement,
    TResult? Function(GoalJumpTargetDispatch value)? dispatch,
    TResult? Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult? Function(GoalJumpTargetInventory value)? inventory,
    TResult? Function(GoalJumpTargetSmithy value)? smithy,
    TResult? Function(GoalJumpTargetFaction value)? faction,
    TResult? Function(GoalJumpTargetChronicle value)? chronicle,
  }) {
    return dispatch?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GoalJumpTargetMovement value)? movement,
    TResult Function(GoalJumpTargetDispatch value)? dispatch,
    TResult Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult Function(GoalJumpTargetInventory value)? inventory,
    TResult Function(GoalJumpTargetSmithy value)? smithy,
    TResult Function(GoalJumpTargetFaction value)? faction,
    TResult Function(GoalJumpTargetChronicle value)? chronicle,
    required TResult orElse(),
  }) {
    if (dispatch != null) {
      return dispatch(this);
    }
    return orElse();
  }
}

abstract class GoalJumpTargetDispatch implements GoalJumpTarget {
  const factory GoalJumpTargetDispatch({final String? questPoolId}) =
      _$GoalJumpTargetDispatchImpl;

  String? get questPoolId;
  @JsonKey(ignore: true)
  _$$GoalJumpTargetDispatchImplCopyWith<_$GoalJumpTargetDispatchImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GoalJumpTargetSettlementFacilityImplCopyWith<$Res> {
  factory _$$GoalJumpTargetSettlementFacilityImplCopyWith(
          _$GoalJumpTargetSettlementFacilityImpl value,
          $Res Function(_$GoalJumpTargetSettlementFacilityImpl) then) =
      __$$GoalJumpTargetSettlementFacilityImplCopyWithImpl<$Res>;
  @useResult
  $Res call({VillageFacility facility, int regionId});
}

/// @nodoc
class __$$GoalJumpTargetSettlementFacilityImplCopyWithImpl<$Res>
    extends _$GoalJumpTargetCopyWithImpl<$Res,
        _$GoalJumpTargetSettlementFacilityImpl>
    implements _$$GoalJumpTargetSettlementFacilityImplCopyWith<$Res> {
  __$$GoalJumpTargetSettlementFacilityImplCopyWithImpl(
      _$GoalJumpTargetSettlementFacilityImpl _value,
      $Res Function(_$GoalJumpTargetSettlementFacilityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? facility = null,
    Object? regionId = null,
  }) {
    return _then(_$GoalJumpTargetSettlementFacilityImpl(
      facility: null == facility
          ? _value.facility
          : facility // ignore: cast_nullable_to_non_nullable
              as VillageFacility,
      regionId: null == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$GoalJumpTargetSettlementFacilityImpl
    implements GoalJumpTargetSettlementFacility {
  const _$GoalJumpTargetSettlementFacilityImpl(
      {required this.facility, required this.regionId});

  @override
  final VillageFacility facility;
  @override
  final int regionId;

  @override
  String toString() {
    return 'GoalJumpTarget.settlementFacility(facility: $facility, regionId: $regionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalJumpTargetSettlementFacilityImpl &&
            (identical(other.facility, facility) ||
                other.facility == facility) &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, facility, regionId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalJumpTargetSettlementFacilityImplCopyWith<
          _$GoalJumpTargetSettlementFacilityImpl>
      get copyWith => __$$GoalJumpTargetSettlementFacilityImplCopyWithImpl<
          _$GoalJumpTargetSettlementFacilityImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? regionId) movement,
    required TResult Function(String? questPoolId) dispatch,
    required TResult Function(VillageFacility facility, int regionId)
        settlementFacility,
    required TResult Function(String? itemId) inventory,
    required TResult Function() smithy,
    required TResult Function(String? factionId) faction,
    required TResult Function() chronicle,
  }) {
    return settlementFacility(facility, regionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? regionId)? movement,
    TResult? Function(String? questPoolId)? dispatch,
    TResult? Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult? Function(String? itemId)? inventory,
    TResult? Function()? smithy,
    TResult? Function(String? factionId)? faction,
    TResult? Function()? chronicle,
  }) {
    return settlementFacility?.call(facility, regionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? regionId)? movement,
    TResult Function(String? questPoolId)? dispatch,
    TResult Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult Function(String? itemId)? inventory,
    TResult Function()? smithy,
    TResult Function(String? factionId)? faction,
    TResult Function()? chronicle,
    required TResult orElse(),
  }) {
    if (settlementFacility != null) {
      return settlementFacility(facility, regionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GoalJumpTargetMovement value) movement,
    required TResult Function(GoalJumpTargetDispatch value) dispatch,
    required TResult Function(GoalJumpTargetSettlementFacility value)
        settlementFacility,
    required TResult Function(GoalJumpTargetInventory value) inventory,
    required TResult Function(GoalJumpTargetSmithy value) smithy,
    required TResult Function(GoalJumpTargetFaction value) faction,
    required TResult Function(GoalJumpTargetChronicle value) chronicle,
  }) {
    return settlementFacility(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GoalJumpTargetMovement value)? movement,
    TResult? Function(GoalJumpTargetDispatch value)? dispatch,
    TResult? Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult? Function(GoalJumpTargetInventory value)? inventory,
    TResult? Function(GoalJumpTargetSmithy value)? smithy,
    TResult? Function(GoalJumpTargetFaction value)? faction,
    TResult? Function(GoalJumpTargetChronicle value)? chronicle,
  }) {
    return settlementFacility?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GoalJumpTargetMovement value)? movement,
    TResult Function(GoalJumpTargetDispatch value)? dispatch,
    TResult Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult Function(GoalJumpTargetInventory value)? inventory,
    TResult Function(GoalJumpTargetSmithy value)? smithy,
    TResult Function(GoalJumpTargetFaction value)? faction,
    TResult Function(GoalJumpTargetChronicle value)? chronicle,
    required TResult orElse(),
  }) {
    if (settlementFacility != null) {
      return settlementFacility(this);
    }
    return orElse();
  }
}

abstract class GoalJumpTargetSettlementFacility implements GoalJumpTarget {
  const factory GoalJumpTargetSettlementFacility(
      {required final VillageFacility facility,
      required final int regionId}) = _$GoalJumpTargetSettlementFacilityImpl;

  VillageFacility get facility;
  int get regionId;
  @JsonKey(ignore: true)
  _$$GoalJumpTargetSettlementFacilityImplCopyWith<
          _$GoalJumpTargetSettlementFacilityImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GoalJumpTargetInventoryImplCopyWith<$Res> {
  factory _$$GoalJumpTargetInventoryImplCopyWith(
          _$GoalJumpTargetInventoryImpl value,
          $Res Function(_$GoalJumpTargetInventoryImpl) then) =
      __$$GoalJumpTargetInventoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? itemId});
}

/// @nodoc
class __$$GoalJumpTargetInventoryImplCopyWithImpl<$Res>
    extends _$GoalJumpTargetCopyWithImpl<$Res, _$GoalJumpTargetInventoryImpl>
    implements _$$GoalJumpTargetInventoryImplCopyWith<$Res> {
  __$$GoalJumpTargetInventoryImplCopyWithImpl(
      _$GoalJumpTargetInventoryImpl _value,
      $Res Function(_$GoalJumpTargetInventoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = freezed,
  }) {
    return _then(_$GoalJumpTargetInventoryImpl(
      itemId: freezed == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$GoalJumpTargetInventoryImpl implements GoalJumpTargetInventory {
  const _$GoalJumpTargetInventoryImpl({this.itemId});

  @override
  final String? itemId;

  @override
  String toString() {
    return 'GoalJumpTarget.inventory(itemId: $itemId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalJumpTargetInventoryImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, itemId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalJumpTargetInventoryImplCopyWith<_$GoalJumpTargetInventoryImpl>
      get copyWith => __$$GoalJumpTargetInventoryImplCopyWithImpl<
          _$GoalJumpTargetInventoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? regionId) movement,
    required TResult Function(String? questPoolId) dispatch,
    required TResult Function(VillageFacility facility, int regionId)
        settlementFacility,
    required TResult Function(String? itemId) inventory,
    required TResult Function() smithy,
    required TResult Function(String? factionId) faction,
    required TResult Function() chronicle,
  }) {
    return inventory(itemId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? regionId)? movement,
    TResult? Function(String? questPoolId)? dispatch,
    TResult? Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult? Function(String? itemId)? inventory,
    TResult? Function()? smithy,
    TResult? Function(String? factionId)? faction,
    TResult? Function()? chronicle,
  }) {
    return inventory?.call(itemId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? regionId)? movement,
    TResult Function(String? questPoolId)? dispatch,
    TResult Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult Function(String? itemId)? inventory,
    TResult Function()? smithy,
    TResult Function(String? factionId)? faction,
    TResult Function()? chronicle,
    required TResult orElse(),
  }) {
    if (inventory != null) {
      return inventory(itemId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GoalJumpTargetMovement value) movement,
    required TResult Function(GoalJumpTargetDispatch value) dispatch,
    required TResult Function(GoalJumpTargetSettlementFacility value)
        settlementFacility,
    required TResult Function(GoalJumpTargetInventory value) inventory,
    required TResult Function(GoalJumpTargetSmithy value) smithy,
    required TResult Function(GoalJumpTargetFaction value) faction,
    required TResult Function(GoalJumpTargetChronicle value) chronicle,
  }) {
    return inventory(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GoalJumpTargetMovement value)? movement,
    TResult? Function(GoalJumpTargetDispatch value)? dispatch,
    TResult? Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult? Function(GoalJumpTargetInventory value)? inventory,
    TResult? Function(GoalJumpTargetSmithy value)? smithy,
    TResult? Function(GoalJumpTargetFaction value)? faction,
    TResult? Function(GoalJumpTargetChronicle value)? chronicle,
  }) {
    return inventory?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GoalJumpTargetMovement value)? movement,
    TResult Function(GoalJumpTargetDispatch value)? dispatch,
    TResult Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult Function(GoalJumpTargetInventory value)? inventory,
    TResult Function(GoalJumpTargetSmithy value)? smithy,
    TResult Function(GoalJumpTargetFaction value)? faction,
    TResult Function(GoalJumpTargetChronicle value)? chronicle,
    required TResult orElse(),
  }) {
    if (inventory != null) {
      return inventory(this);
    }
    return orElse();
  }
}

abstract class GoalJumpTargetInventory implements GoalJumpTarget {
  const factory GoalJumpTargetInventory({final String? itemId}) =
      _$GoalJumpTargetInventoryImpl;

  String? get itemId;
  @JsonKey(ignore: true)
  _$$GoalJumpTargetInventoryImplCopyWith<_$GoalJumpTargetInventoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GoalJumpTargetSmithyImplCopyWith<$Res> {
  factory _$$GoalJumpTargetSmithyImplCopyWith(_$GoalJumpTargetSmithyImpl value,
          $Res Function(_$GoalJumpTargetSmithyImpl) then) =
      __$$GoalJumpTargetSmithyImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GoalJumpTargetSmithyImplCopyWithImpl<$Res>
    extends _$GoalJumpTargetCopyWithImpl<$Res, _$GoalJumpTargetSmithyImpl>
    implements _$$GoalJumpTargetSmithyImplCopyWith<$Res> {
  __$$GoalJumpTargetSmithyImplCopyWithImpl(_$GoalJumpTargetSmithyImpl _value,
      $Res Function(_$GoalJumpTargetSmithyImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$GoalJumpTargetSmithyImpl implements GoalJumpTargetSmithy {
  const _$GoalJumpTargetSmithyImpl();

  @override
  String toString() {
    return 'GoalJumpTarget.smithy()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalJumpTargetSmithyImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? regionId) movement,
    required TResult Function(String? questPoolId) dispatch,
    required TResult Function(VillageFacility facility, int regionId)
        settlementFacility,
    required TResult Function(String? itemId) inventory,
    required TResult Function() smithy,
    required TResult Function(String? factionId) faction,
    required TResult Function() chronicle,
  }) {
    return smithy();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? regionId)? movement,
    TResult? Function(String? questPoolId)? dispatch,
    TResult? Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult? Function(String? itemId)? inventory,
    TResult? Function()? smithy,
    TResult? Function(String? factionId)? faction,
    TResult? Function()? chronicle,
  }) {
    return smithy?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? regionId)? movement,
    TResult Function(String? questPoolId)? dispatch,
    TResult Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult Function(String? itemId)? inventory,
    TResult Function()? smithy,
    TResult Function(String? factionId)? faction,
    TResult Function()? chronicle,
    required TResult orElse(),
  }) {
    if (smithy != null) {
      return smithy();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GoalJumpTargetMovement value) movement,
    required TResult Function(GoalJumpTargetDispatch value) dispatch,
    required TResult Function(GoalJumpTargetSettlementFacility value)
        settlementFacility,
    required TResult Function(GoalJumpTargetInventory value) inventory,
    required TResult Function(GoalJumpTargetSmithy value) smithy,
    required TResult Function(GoalJumpTargetFaction value) faction,
    required TResult Function(GoalJumpTargetChronicle value) chronicle,
  }) {
    return smithy(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GoalJumpTargetMovement value)? movement,
    TResult? Function(GoalJumpTargetDispatch value)? dispatch,
    TResult? Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult? Function(GoalJumpTargetInventory value)? inventory,
    TResult? Function(GoalJumpTargetSmithy value)? smithy,
    TResult? Function(GoalJumpTargetFaction value)? faction,
    TResult? Function(GoalJumpTargetChronicle value)? chronicle,
  }) {
    return smithy?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GoalJumpTargetMovement value)? movement,
    TResult Function(GoalJumpTargetDispatch value)? dispatch,
    TResult Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult Function(GoalJumpTargetInventory value)? inventory,
    TResult Function(GoalJumpTargetSmithy value)? smithy,
    TResult Function(GoalJumpTargetFaction value)? faction,
    TResult Function(GoalJumpTargetChronicle value)? chronicle,
    required TResult orElse(),
  }) {
    if (smithy != null) {
      return smithy(this);
    }
    return orElse();
  }
}

abstract class GoalJumpTargetSmithy implements GoalJumpTarget {
  const factory GoalJumpTargetSmithy() = _$GoalJumpTargetSmithyImpl;
}

/// @nodoc
abstract class _$$GoalJumpTargetFactionImplCopyWith<$Res> {
  factory _$$GoalJumpTargetFactionImplCopyWith(
          _$GoalJumpTargetFactionImpl value,
          $Res Function(_$GoalJumpTargetFactionImpl) then) =
      __$$GoalJumpTargetFactionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? factionId});
}

/// @nodoc
class __$$GoalJumpTargetFactionImplCopyWithImpl<$Res>
    extends _$GoalJumpTargetCopyWithImpl<$Res, _$GoalJumpTargetFactionImpl>
    implements _$$GoalJumpTargetFactionImplCopyWith<$Res> {
  __$$GoalJumpTargetFactionImplCopyWithImpl(_$GoalJumpTargetFactionImpl _value,
      $Res Function(_$GoalJumpTargetFactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? factionId = freezed,
  }) {
    return _then(_$GoalJumpTargetFactionImpl(
      factionId: freezed == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$GoalJumpTargetFactionImpl implements GoalJumpTargetFaction {
  const _$GoalJumpTargetFactionImpl({this.factionId});

  @override
  final String? factionId;

  @override
  String toString() {
    return 'GoalJumpTarget.faction(factionId: $factionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalJumpTargetFactionImpl &&
            (identical(other.factionId, factionId) ||
                other.factionId == factionId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, factionId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalJumpTargetFactionImplCopyWith<_$GoalJumpTargetFactionImpl>
      get copyWith => __$$GoalJumpTargetFactionImplCopyWithImpl<
          _$GoalJumpTargetFactionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? regionId) movement,
    required TResult Function(String? questPoolId) dispatch,
    required TResult Function(VillageFacility facility, int regionId)
        settlementFacility,
    required TResult Function(String? itemId) inventory,
    required TResult Function() smithy,
    required TResult Function(String? factionId) faction,
    required TResult Function() chronicle,
  }) {
    return faction(factionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? regionId)? movement,
    TResult? Function(String? questPoolId)? dispatch,
    TResult? Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult? Function(String? itemId)? inventory,
    TResult? Function()? smithy,
    TResult? Function(String? factionId)? faction,
    TResult? Function()? chronicle,
  }) {
    return faction?.call(factionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? regionId)? movement,
    TResult Function(String? questPoolId)? dispatch,
    TResult Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult Function(String? itemId)? inventory,
    TResult Function()? smithy,
    TResult Function(String? factionId)? faction,
    TResult Function()? chronicle,
    required TResult orElse(),
  }) {
    if (faction != null) {
      return faction(factionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GoalJumpTargetMovement value) movement,
    required TResult Function(GoalJumpTargetDispatch value) dispatch,
    required TResult Function(GoalJumpTargetSettlementFacility value)
        settlementFacility,
    required TResult Function(GoalJumpTargetInventory value) inventory,
    required TResult Function(GoalJumpTargetSmithy value) smithy,
    required TResult Function(GoalJumpTargetFaction value) faction,
    required TResult Function(GoalJumpTargetChronicle value) chronicle,
  }) {
    return faction(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GoalJumpTargetMovement value)? movement,
    TResult? Function(GoalJumpTargetDispatch value)? dispatch,
    TResult? Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult? Function(GoalJumpTargetInventory value)? inventory,
    TResult? Function(GoalJumpTargetSmithy value)? smithy,
    TResult? Function(GoalJumpTargetFaction value)? faction,
    TResult? Function(GoalJumpTargetChronicle value)? chronicle,
  }) {
    return faction?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GoalJumpTargetMovement value)? movement,
    TResult Function(GoalJumpTargetDispatch value)? dispatch,
    TResult Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult Function(GoalJumpTargetInventory value)? inventory,
    TResult Function(GoalJumpTargetSmithy value)? smithy,
    TResult Function(GoalJumpTargetFaction value)? faction,
    TResult Function(GoalJumpTargetChronicle value)? chronicle,
    required TResult orElse(),
  }) {
    if (faction != null) {
      return faction(this);
    }
    return orElse();
  }
}

abstract class GoalJumpTargetFaction implements GoalJumpTarget {
  const factory GoalJumpTargetFaction({final String? factionId}) =
      _$GoalJumpTargetFactionImpl;

  String? get factionId;
  @JsonKey(ignore: true)
  _$$GoalJumpTargetFactionImplCopyWith<_$GoalJumpTargetFactionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GoalJumpTargetChronicleImplCopyWith<$Res> {
  factory _$$GoalJumpTargetChronicleImplCopyWith(
          _$GoalJumpTargetChronicleImpl value,
          $Res Function(_$GoalJumpTargetChronicleImpl) then) =
      __$$GoalJumpTargetChronicleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GoalJumpTargetChronicleImplCopyWithImpl<$Res>
    extends _$GoalJumpTargetCopyWithImpl<$Res, _$GoalJumpTargetChronicleImpl>
    implements _$$GoalJumpTargetChronicleImplCopyWith<$Res> {
  __$$GoalJumpTargetChronicleImplCopyWithImpl(
      _$GoalJumpTargetChronicleImpl _value,
      $Res Function(_$GoalJumpTargetChronicleImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$GoalJumpTargetChronicleImpl implements GoalJumpTargetChronicle {
  const _$GoalJumpTargetChronicleImpl();

  @override
  String toString() {
    return 'GoalJumpTarget.chronicle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalJumpTargetChronicleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? regionId) movement,
    required TResult Function(String? questPoolId) dispatch,
    required TResult Function(VillageFacility facility, int regionId)
        settlementFacility,
    required TResult Function(String? itemId) inventory,
    required TResult Function() smithy,
    required TResult Function(String? factionId) faction,
    required TResult Function() chronicle,
  }) {
    return chronicle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? regionId)? movement,
    TResult? Function(String? questPoolId)? dispatch,
    TResult? Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult? Function(String? itemId)? inventory,
    TResult? Function()? smithy,
    TResult? Function(String? factionId)? faction,
    TResult? Function()? chronicle,
  }) {
    return chronicle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? regionId)? movement,
    TResult Function(String? questPoolId)? dispatch,
    TResult Function(VillageFacility facility, int regionId)?
        settlementFacility,
    TResult Function(String? itemId)? inventory,
    TResult Function()? smithy,
    TResult Function(String? factionId)? faction,
    TResult Function()? chronicle,
    required TResult orElse(),
  }) {
    if (chronicle != null) {
      return chronicle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GoalJumpTargetMovement value) movement,
    required TResult Function(GoalJumpTargetDispatch value) dispatch,
    required TResult Function(GoalJumpTargetSettlementFacility value)
        settlementFacility,
    required TResult Function(GoalJumpTargetInventory value) inventory,
    required TResult Function(GoalJumpTargetSmithy value) smithy,
    required TResult Function(GoalJumpTargetFaction value) faction,
    required TResult Function(GoalJumpTargetChronicle value) chronicle,
  }) {
    return chronicle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GoalJumpTargetMovement value)? movement,
    TResult? Function(GoalJumpTargetDispatch value)? dispatch,
    TResult? Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult? Function(GoalJumpTargetInventory value)? inventory,
    TResult? Function(GoalJumpTargetSmithy value)? smithy,
    TResult? Function(GoalJumpTargetFaction value)? faction,
    TResult? Function(GoalJumpTargetChronicle value)? chronicle,
  }) {
    return chronicle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GoalJumpTargetMovement value)? movement,
    TResult Function(GoalJumpTargetDispatch value)? dispatch,
    TResult Function(GoalJumpTargetSettlementFacility value)?
        settlementFacility,
    TResult Function(GoalJumpTargetInventory value)? inventory,
    TResult Function(GoalJumpTargetSmithy value)? smithy,
    TResult Function(GoalJumpTargetFaction value)? faction,
    TResult Function(GoalJumpTargetChronicle value)? chronicle,
    required TResult orElse(),
  }) {
    if (chronicle != null) {
      return chronicle(this);
    }
    return orElse();
  }
}

abstract class GoalJumpTargetChronicle implements GoalJumpTarget {
  const factory GoalJumpTargetChronicle() = _$GoalJumpTargetChronicleImpl;
}

/// @nodoc
mixin _$MetricValue {
  /// 0~100 백분율
  double get percent => throw _privateConstructorUsedError;

  /// 표시 모드 (percent/tierLevel/countOverTotal/averageStage)
  MetricDisplayMode get displayMode => throw _privateConstructorUsedError;

  /// 현재값 (예: Tier 3 → 3, n/m → n)
  num? get currentValue => throw _privateConstructorUsedError;

  /// 전체값 (예: n/m → m)
  num? get totalValue => throw _privateConstructorUsedError;

  /// 라벨 텍스트 (예: "평온", "Tier 3", "안정 단계")
  String? get label => throw _privateConstructorUsedError;

  /// 펼침 본문에서 UI가 추가로 조합할 요약 텍스트
  String? get expandedSummary => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MetricValueCopyWith<MetricValue> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MetricValueCopyWith<$Res> {
  factory $MetricValueCopyWith(
          MetricValue value, $Res Function(MetricValue) then) =
      _$MetricValueCopyWithImpl<$Res, MetricValue>;
  @useResult
  $Res call(
      {double percent,
      MetricDisplayMode displayMode,
      num? currentValue,
      num? totalValue,
      String? label,
      String? expandedSummary});
}

/// @nodoc
class _$MetricValueCopyWithImpl<$Res, $Val extends MetricValue>
    implements $MetricValueCopyWith<$Res> {
  _$MetricValueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? percent = null,
    Object? displayMode = null,
    Object? currentValue = freezed,
    Object? totalValue = freezed,
    Object? label = freezed,
    Object? expandedSummary = freezed,
  }) {
    return _then(_value.copyWith(
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
      displayMode: null == displayMode
          ? _value.displayMode
          : displayMode // ignore: cast_nullable_to_non_nullable
              as MetricDisplayMode,
      currentValue: freezed == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as num?,
      totalValue: freezed == totalValue
          ? _value.totalValue
          : totalValue // ignore: cast_nullable_to_non_nullable
              as num?,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      expandedSummary: freezed == expandedSummary
          ? _value.expandedSummary
          : expandedSummary // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MetricValueImplCopyWith<$Res>
    implements $MetricValueCopyWith<$Res> {
  factory _$$MetricValueImplCopyWith(
          _$MetricValueImpl value, $Res Function(_$MetricValueImpl) then) =
      __$$MetricValueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double percent,
      MetricDisplayMode displayMode,
      num? currentValue,
      num? totalValue,
      String? label,
      String? expandedSummary});
}

/// @nodoc
class __$$MetricValueImplCopyWithImpl<$Res>
    extends _$MetricValueCopyWithImpl<$Res, _$MetricValueImpl>
    implements _$$MetricValueImplCopyWith<$Res> {
  __$$MetricValueImplCopyWithImpl(
      _$MetricValueImpl _value, $Res Function(_$MetricValueImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? percent = null,
    Object? displayMode = null,
    Object? currentValue = freezed,
    Object? totalValue = freezed,
    Object? label = freezed,
    Object? expandedSummary = freezed,
  }) {
    return _then(_$MetricValueImpl(
      percent: null == percent
          ? _value.percent
          : percent // ignore: cast_nullable_to_non_nullable
              as double,
      displayMode: null == displayMode
          ? _value.displayMode
          : displayMode // ignore: cast_nullable_to_non_nullable
              as MetricDisplayMode,
      currentValue: freezed == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as num?,
      totalValue: freezed == totalValue
          ? _value.totalValue
          : totalValue // ignore: cast_nullable_to_non_nullable
              as num?,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      expandedSummary: freezed == expandedSummary
          ? _value.expandedSummary
          : expandedSummary // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MetricValueImpl implements _MetricValue {
  const _$MetricValueImpl(
      {required this.percent,
      required this.displayMode,
      this.currentValue,
      this.totalValue,
      this.label,
      this.expandedSummary});

  /// 0~100 백분율
  @override
  final double percent;

  /// 표시 모드 (percent/tierLevel/countOverTotal/averageStage)
  @override
  final MetricDisplayMode displayMode;

  /// 현재값 (예: Tier 3 → 3, n/m → n)
  @override
  final num? currentValue;

  /// 전체값 (예: n/m → m)
  @override
  final num? totalValue;

  /// 라벨 텍스트 (예: "평온", "Tier 3", "안정 단계")
  @override
  final String? label;

  /// 펼침 본문에서 UI가 추가로 조합할 요약 텍스트
  @override
  final String? expandedSummary;

  @override
  String toString() {
    return 'MetricValue(percent: $percent, displayMode: $displayMode, currentValue: $currentValue, totalValue: $totalValue, label: $label, expandedSummary: $expandedSummary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MetricValueImpl &&
            (identical(other.percent, percent) || other.percent == percent) &&
            (identical(other.displayMode, displayMode) ||
                other.displayMode == displayMode) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.totalValue, totalValue) ||
                other.totalValue == totalValue) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.expandedSummary, expandedSummary) ||
                other.expandedSummary == expandedSummary));
  }

  @override
  int get hashCode => Object.hash(runtimeType, percent, displayMode,
      currentValue, totalValue, label, expandedSummary);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MetricValueImplCopyWith<_$MetricValueImpl> get copyWith =>
      __$$MetricValueImplCopyWithImpl<_$MetricValueImpl>(this, _$identity);
}

abstract class _MetricValue implements MetricValue {
  const factory _MetricValue(
      {required final double percent,
      required final MetricDisplayMode displayMode,
      final num? currentValue,
      final num? totalValue,
      final String? label,
      final String? expandedSummary}) = _$MetricValueImpl;

  @override

  /// 0~100 백분율
  double get percent;
  @override

  /// 표시 모드 (percent/tierLevel/countOverTotal/averageStage)
  MetricDisplayMode get displayMode;
  @override

  /// 현재값 (예: Tier 3 → 3, n/m → n)
  num? get currentValue;
  @override

  /// 전체값 (예: n/m → m)
  num? get totalValue;
  @override

  /// 라벨 텍스트 (예: "평온", "Tier 3", "안정 단계")
  String? get label;
  @override

  /// 펼침 본문에서 UI가 추가로 조합할 요약 텍스트
  String? get expandedSummary;
  @override
  @JsonKey(ignore: true)
  _$$MetricValueImplCopyWith<_$MetricValueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$LivingsphereDashboardSnapshot {
  /// 대시보드 대상 region ID (MVP는 항상 3)
  int get regionId => throw _privateConstructorUsedError;

  /// 6 지표의 계산 결과 (MetricKey → MetricValue)
  Map<MetricKey, MetricValue> get metrics => throw _privateConstructorUsedError;

  /// 통합 완성도 (0~100)
  double get totalCompletionPct => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $LivingsphereDashboardSnapshotCopyWith<LivingsphereDashboardSnapshot>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LivingsphereDashboardSnapshotCopyWith<$Res> {
  factory $LivingsphereDashboardSnapshotCopyWith(
          LivingsphereDashboardSnapshot value,
          $Res Function(LivingsphereDashboardSnapshot) then) =
      _$LivingsphereDashboardSnapshotCopyWithImpl<$Res,
          LivingsphereDashboardSnapshot>;
  @useResult
  $Res call(
      {int regionId,
      Map<MetricKey, MetricValue> metrics,
      double totalCompletionPct});
}

/// @nodoc
class _$LivingsphereDashboardSnapshotCopyWithImpl<$Res,
        $Val extends LivingsphereDashboardSnapshot>
    implements $LivingsphereDashboardSnapshotCopyWith<$Res> {
  _$LivingsphereDashboardSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? regionId = null,
    Object? metrics = null,
    Object? totalCompletionPct = null,
  }) {
    return _then(_value.copyWith(
      regionId: null == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int,
      metrics: null == metrics
          ? _value.metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as Map<MetricKey, MetricValue>,
      totalCompletionPct: null == totalCompletionPct
          ? _value.totalCompletionPct
          : totalCompletionPct // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LivingsphereDashboardSnapshotImplCopyWith<$Res>
    implements $LivingsphereDashboardSnapshotCopyWith<$Res> {
  factory _$$LivingsphereDashboardSnapshotImplCopyWith(
          _$LivingsphereDashboardSnapshotImpl value,
          $Res Function(_$LivingsphereDashboardSnapshotImpl) then) =
      __$$LivingsphereDashboardSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int regionId,
      Map<MetricKey, MetricValue> metrics,
      double totalCompletionPct});
}

/// @nodoc
class __$$LivingsphereDashboardSnapshotImplCopyWithImpl<$Res>
    extends _$LivingsphereDashboardSnapshotCopyWithImpl<$Res,
        _$LivingsphereDashboardSnapshotImpl>
    implements _$$LivingsphereDashboardSnapshotImplCopyWith<$Res> {
  __$$LivingsphereDashboardSnapshotImplCopyWithImpl(
      _$LivingsphereDashboardSnapshotImpl _value,
      $Res Function(_$LivingsphereDashboardSnapshotImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? regionId = null,
    Object? metrics = null,
    Object? totalCompletionPct = null,
  }) {
    return _then(_$LivingsphereDashboardSnapshotImpl(
      regionId: null == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int,
      metrics: null == metrics
          ? _value._metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as Map<MetricKey, MetricValue>,
      totalCompletionPct: null == totalCompletionPct
          ? _value.totalCompletionPct
          : totalCompletionPct // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$LivingsphereDashboardSnapshotImpl
    implements _LivingsphereDashboardSnapshot {
  const _$LivingsphereDashboardSnapshotImpl(
      {required this.regionId,
      required final Map<MetricKey, MetricValue> metrics,
      required this.totalCompletionPct})
      : _metrics = metrics;

  /// 대시보드 대상 region ID (MVP는 항상 3)
  @override
  final int regionId;

  /// 6 지표의 계산 결과 (MetricKey → MetricValue)
  final Map<MetricKey, MetricValue> _metrics;

  /// 6 지표의 계산 결과 (MetricKey → MetricValue)
  @override
  Map<MetricKey, MetricValue> get metrics {
    if (_metrics is EqualUnmodifiableMapView) return _metrics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metrics);
  }

  /// 통합 완성도 (0~100)
  @override
  final double totalCompletionPct;

  @override
  String toString() {
    return 'LivingsphereDashboardSnapshot(regionId: $regionId, metrics: $metrics, totalCompletionPct: $totalCompletionPct)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LivingsphereDashboardSnapshotImpl &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            const DeepCollectionEquality().equals(other._metrics, _metrics) &&
            (identical(other.totalCompletionPct, totalCompletionPct) ||
                other.totalCompletionPct == totalCompletionPct));
  }

  @override
  int get hashCode => Object.hash(runtimeType, regionId,
      const DeepCollectionEquality().hash(_metrics), totalCompletionPct);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LivingsphereDashboardSnapshotImplCopyWith<
          _$LivingsphereDashboardSnapshotImpl>
      get copyWith => __$$LivingsphereDashboardSnapshotImplCopyWithImpl<
          _$LivingsphereDashboardSnapshotImpl>(this, _$identity);
}

abstract class _LivingsphereDashboardSnapshot
    implements LivingsphereDashboardSnapshot {
  const factory _LivingsphereDashboardSnapshot(
          {required final int regionId,
          required final Map<MetricKey, MetricValue> metrics,
          required final double totalCompletionPct}) =
      _$LivingsphereDashboardSnapshotImpl;

  @override

  /// 대시보드 대상 region ID (MVP는 항상 3)
  int get regionId;
  @override

  /// 6 지표의 계산 결과 (MetricKey → MetricValue)
  Map<MetricKey, MetricValue> get metrics;
  @override

  /// 통합 완성도 (0~100)
  double get totalCompletionPct;
  @override
  @JsonKey(ignore: true)
  _$$LivingsphereDashboardSnapshotImplCopyWith<
          _$LivingsphereDashboardSnapshotImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GoalCandidate {
  /// 목표 ID (pinId 포맷: 'quest:{id}', 'chain:{id}' 등)
  String get id => throw _privateConstructorUsedError;

  /// 목표 슬롯 (30분 vs 8시간)
  GoalSlot get slot => throw _privateConstructorUsedError;

  /// UI에 표시할 라벨 (예: "동굴 박쥐 소탕", "대장간 개방")
  String get label => throw _privateConstructorUsedError;

  /// 목표의 종류
  GoalCandidateKind get kind => throw _privateConstructorUsedError;

  /// 기본 가중치 (50~100)
  double get baseWeight => throw _privateConstructorUsedError;

  /// 진행 인자 (0.0~1.0, progress_factor = 1 - remaining/max)
  double get progressFactor => throw _privateConstructorUsedError;

  /// 가치 인자 (0~50, 난이도·중요도 등의 정규화)
  double get valueFactor => throw _privateConstructorUsedError;

  /// 최종 점수 = baseWeight × clamp(progressFactor) + clamp(valueFactor)
  double get score => throw _privateConstructorUsedError;

  /// 점프 대상 (null이면 텍스트만 노출)
  GoalJumpTarget? get jumpTarget => throw _privateConstructorUsedError;

  /// 핀 무효화 판정용 플래그 (의뢰 완료, 체인 완주 등으로 false 가능)
  bool get isValid => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GoalCandidateCopyWith<GoalCandidate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalCandidateCopyWith<$Res> {
  factory $GoalCandidateCopyWith(
          GoalCandidate value, $Res Function(GoalCandidate) then) =
      _$GoalCandidateCopyWithImpl<$Res, GoalCandidate>;
  @useResult
  $Res call(
      {String id,
      GoalSlot slot,
      String label,
      GoalCandidateKind kind,
      double baseWeight,
      double progressFactor,
      double valueFactor,
      double score,
      GoalJumpTarget? jumpTarget,
      bool isValid});

  $GoalJumpTargetCopyWith<$Res>? get jumpTarget;
}

/// @nodoc
class _$GoalCandidateCopyWithImpl<$Res, $Val extends GoalCandidate>
    implements $GoalCandidateCopyWith<$Res> {
  _$GoalCandidateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slot = null,
    Object? label = null,
    Object? kind = null,
    Object? baseWeight = null,
    Object? progressFactor = null,
    Object? valueFactor = null,
    Object? score = null,
    Object? jumpTarget = freezed,
    Object? isValid = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as GoalSlot,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as GoalCandidateKind,
      baseWeight: null == baseWeight
          ? _value.baseWeight
          : baseWeight // ignore: cast_nullable_to_non_nullable
              as double,
      progressFactor: null == progressFactor
          ? _value.progressFactor
          : progressFactor // ignore: cast_nullable_to_non_nullable
              as double,
      valueFactor: null == valueFactor
          ? _value.valueFactor
          : valueFactor // ignore: cast_nullable_to_non_nullable
              as double,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      jumpTarget: freezed == jumpTarget
          ? _value.jumpTarget
          : jumpTarget // ignore: cast_nullable_to_non_nullable
              as GoalJumpTarget?,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $GoalJumpTargetCopyWith<$Res>? get jumpTarget {
    if (_value.jumpTarget == null) {
      return null;
    }

    return $GoalJumpTargetCopyWith<$Res>(_value.jumpTarget!, (value) {
      return _then(_value.copyWith(jumpTarget: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GoalCandidateImplCopyWith<$Res>
    implements $GoalCandidateCopyWith<$Res> {
  factory _$$GoalCandidateImplCopyWith(
          _$GoalCandidateImpl value, $Res Function(_$GoalCandidateImpl) then) =
      __$$GoalCandidateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      GoalSlot slot,
      String label,
      GoalCandidateKind kind,
      double baseWeight,
      double progressFactor,
      double valueFactor,
      double score,
      GoalJumpTarget? jumpTarget,
      bool isValid});

  @override
  $GoalJumpTargetCopyWith<$Res>? get jumpTarget;
}

/// @nodoc
class __$$GoalCandidateImplCopyWithImpl<$Res>
    extends _$GoalCandidateCopyWithImpl<$Res, _$GoalCandidateImpl>
    implements _$$GoalCandidateImplCopyWith<$Res> {
  __$$GoalCandidateImplCopyWithImpl(
      _$GoalCandidateImpl _value, $Res Function(_$GoalCandidateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slot = null,
    Object? label = null,
    Object? kind = null,
    Object? baseWeight = null,
    Object? progressFactor = null,
    Object? valueFactor = null,
    Object? score = null,
    Object? jumpTarget = freezed,
    Object? isValid = null,
  }) {
    return _then(_$GoalCandidateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as GoalSlot,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as GoalCandidateKind,
      baseWeight: null == baseWeight
          ? _value.baseWeight
          : baseWeight // ignore: cast_nullable_to_non_nullable
              as double,
      progressFactor: null == progressFactor
          ? _value.progressFactor
          : progressFactor // ignore: cast_nullable_to_non_nullable
              as double,
      valueFactor: null == valueFactor
          ? _value.valueFactor
          : valueFactor // ignore: cast_nullable_to_non_nullable
              as double,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      jumpTarget: freezed == jumpTarget
          ? _value.jumpTarget
          : jumpTarget // ignore: cast_nullable_to_non_nullable
              as GoalJumpTarget?,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$GoalCandidateImpl implements _GoalCandidate {
  const _$GoalCandidateImpl(
      {required this.id,
      required this.slot,
      required this.label,
      required this.kind,
      required this.baseWeight,
      required this.progressFactor,
      required this.valueFactor,
      required this.score,
      this.jumpTarget,
      this.isValid = true});

  /// 목표 ID (pinId 포맷: 'quest:{id}', 'chain:{id}' 등)
  @override
  final String id;

  /// 목표 슬롯 (30분 vs 8시간)
  @override
  final GoalSlot slot;

  /// UI에 표시할 라벨 (예: "동굴 박쥐 소탕", "대장간 개방")
  @override
  final String label;

  /// 목표의 종류
  @override
  final GoalCandidateKind kind;

  /// 기본 가중치 (50~100)
  @override
  final double baseWeight;

  /// 진행 인자 (0.0~1.0, progress_factor = 1 - remaining/max)
  @override
  final double progressFactor;

  /// 가치 인자 (0~50, 난이도·중요도 등의 정규화)
  @override
  final double valueFactor;

  /// 최종 점수 = baseWeight × clamp(progressFactor) + clamp(valueFactor)
  @override
  final double score;

  /// 점프 대상 (null이면 텍스트만 노출)
  @override
  final GoalJumpTarget? jumpTarget;

  /// 핀 무효화 판정용 플래그 (의뢰 완료, 체인 완주 등으로 false 가능)
  @override
  @JsonKey()
  final bool isValid;

  @override
  String toString() {
    return 'GoalCandidate(id: $id, slot: $slot, label: $label, kind: $kind, baseWeight: $baseWeight, progressFactor: $progressFactor, valueFactor: $valueFactor, score: $score, jumpTarget: $jumpTarget, isValid: $isValid)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalCandidateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.slot, slot) || other.slot == slot) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.baseWeight, baseWeight) ||
                other.baseWeight == baseWeight) &&
            (identical(other.progressFactor, progressFactor) ||
                other.progressFactor == progressFactor) &&
            (identical(other.valueFactor, valueFactor) ||
                other.valueFactor == valueFactor) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.jumpTarget, jumpTarget) ||
                other.jumpTarget == jumpTarget) &&
            (identical(other.isValid, isValid) || other.isValid == isValid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, slot, label, kind,
      baseWeight, progressFactor, valueFactor, score, jumpTarget, isValid);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalCandidateImplCopyWith<_$GoalCandidateImpl> get copyWith =>
      __$$GoalCandidateImplCopyWithImpl<_$GoalCandidateImpl>(this, _$identity);
}

abstract class _GoalCandidate implements GoalCandidate {
  const factory _GoalCandidate(
      {required final String id,
      required final GoalSlot slot,
      required final String label,
      required final GoalCandidateKind kind,
      required final double baseWeight,
      required final double progressFactor,
      required final double valueFactor,
      required final double score,
      final GoalJumpTarget? jumpTarget,
      final bool isValid}) = _$GoalCandidateImpl;

  @override

  /// 목표 ID (pinId 포맷: 'quest:{id}', 'chain:{id}' 등)
  String get id;
  @override

  /// 목표 슬롯 (30분 vs 8시간)
  GoalSlot get slot;
  @override

  /// UI에 표시할 라벨 (예: "동굴 박쥐 소탕", "대장간 개방")
  String get label;
  @override

  /// 목표의 종류
  GoalCandidateKind get kind;
  @override

  /// 기본 가중치 (50~100)
  double get baseWeight;
  @override

  /// 진행 인자 (0.0~1.0, progress_factor = 1 - remaining/max)
  double get progressFactor;
  @override

  /// 가치 인자 (0~50, 난이도·중요도 등의 정규화)
  double get valueFactor;
  @override

  /// 최종 점수 = baseWeight × clamp(progressFactor) + clamp(valueFactor)
  double get score;
  @override

  /// 점프 대상 (null이면 텍스트만 노출)
  GoalJumpTarget? get jumpTarget;
  @override

  /// 핀 무효화 판정용 플래그 (의뢰 완료, 체인 완주 등으로 false 가능)
  bool get isValid;
  @override
  @JsonKey(ignore: true)
  _$$GoalCandidateImplCopyWith<_$GoalCandidateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GoalRecommendation {
  /// 목표 슬롯
  GoalSlot get slot => throw _privateConstructorUsedError;

  /// 자동 추천 또는 핀된 후보 (null이면 fallback 상태)
  GoalCandidate? get primary => throw _privateConstructorUsedError;

  /// 핀 활성 여부 (primary가 pinned candidate)
  bool get pinned => throw _privateConstructorUsedError;

  /// 기타 대안 후보 (최대 3개, score > 0만)
  List<GoalCandidate> get alternatives => throw _privateConstructorUsedError;

  /// fallback 상태 (후보 없음 또는 모두 score <= 0)
  bool get isFallback => throw _privateConstructorUsedError;

  /// 무효화된 pinId (감지되면 UI의 post-frame cleanup에서 제거)
  String? get invalidatedPinId => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GoalRecommendationCopyWith<GoalRecommendation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalRecommendationCopyWith<$Res> {
  factory $GoalRecommendationCopyWith(
          GoalRecommendation value, $Res Function(GoalRecommendation) then) =
      _$GoalRecommendationCopyWithImpl<$Res, GoalRecommendation>;
  @useResult
  $Res call(
      {GoalSlot slot,
      GoalCandidate? primary,
      bool pinned,
      List<GoalCandidate> alternatives,
      bool isFallback,
      String? invalidatedPinId});

  $GoalCandidateCopyWith<$Res>? get primary;
}

/// @nodoc
class _$GoalRecommendationCopyWithImpl<$Res, $Val extends GoalRecommendation>
    implements $GoalRecommendationCopyWith<$Res> {
  _$GoalRecommendationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? primary = freezed,
    Object? pinned = null,
    Object? alternatives = null,
    Object? isFallback = null,
    Object? invalidatedPinId = freezed,
  }) {
    return _then(_value.copyWith(
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as GoalSlot,
      primary: freezed == primary
          ? _value.primary
          : primary // ignore: cast_nullable_to_non_nullable
              as GoalCandidate?,
      pinned: null == pinned
          ? _value.pinned
          : pinned // ignore: cast_nullable_to_non_nullable
              as bool,
      alternatives: null == alternatives
          ? _value.alternatives
          : alternatives // ignore: cast_nullable_to_non_nullable
              as List<GoalCandidate>,
      isFallback: null == isFallback
          ? _value.isFallback
          : isFallback // ignore: cast_nullable_to_non_nullable
              as bool,
      invalidatedPinId: freezed == invalidatedPinId
          ? _value.invalidatedPinId
          : invalidatedPinId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $GoalCandidateCopyWith<$Res>? get primary {
    if (_value.primary == null) {
      return null;
    }

    return $GoalCandidateCopyWith<$Res>(_value.primary!, (value) {
      return _then(_value.copyWith(primary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GoalRecommendationImplCopyWith<$Res>
    implements $GoalRecommendationCopyWith<$Res> {
  factory _$$GoalRecommendationImplCopyWith(_$GoalRecommendationImpl value,
          $Res Function(_$GoalRecommendationImpl) then) =
      __$$GoalRecommendationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {GoalSlot slot,
      GoalCandidate? primary,
      bool pinned,
      List<GoalCandidate> alternatives,
      bool isFallback,
      String? invalidatedPinId});

  @override
  $GoalCandidateCopyWith<$Res>? get primary;
}

/// @nodoc
class __$$GoalRecommendationImplCopyWithImpl<$Res>
    extends _$GoalRecommendationCopyWithImpl<$Res, _$GoalRecommendationImpl>
    implements _$$GoalRecommendationImplCopyWith<$Res> {
  __$$GoalRecommendationImplCopyWithImpl(_$GoalRecommendationImpl _value,
      $Res Function(_$GoalRecommendationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slot = null,
    Object? primary = freezed,
    Object? pinned = null,
    Object? alternatives = null,
    Object? isFallback = null,
    Object? invalidatedPinId = freezed,
  }) {
    return _then(_$GoalRecommendationImpl(
      slot: null == slot
          ? _value.slot
          : slot // ignore: cast_nullable_to_non_nullable
              as GoalSlot,
      primary: freezed == primary
          ? _value.primary
          : primary // ignore: cast_nullable_to_non_nullable
              as GoalCandidate?,
      pinned: null == pinned
          ? _value.pinned
          : pinned // ignore: cast_nullable_to_non_nullable
              as bool,
      alternatives: null == alternatives
          ? _value._alternatives
          : alternatives // ignore: cast_nullable_to_non_nullable
              as List<GoalCandidate>,
      isFallback: null == isFallback
          ? _value.isFallback
          : isFallback // ignore: cast_nullable_to_non_nullable
              as bool,
      invalidatedPinId: freezed == invalidatedPinId
          ? _value.invalidatedPinId
          : invalidatedPinId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$GoalRecommendationImpl implements _GoalRecommendation {
  const _$GoalRecommendationImpl(
      {required this.slot,
      this.primary,
      this.pinned = false,
      final List<GoalCandidate> alternatives = const [],
      this.isFallback = false,
      this.invalidatedPinId})
      : _alternatives = alternatives;

  /// 목표 슬롯
  @override
  final GoalSlot slot;

  /// 자동 추천 또는 핀된 후보 (null이면 fallback 상태)
  @override
  final GoalCandidate? primary;

  /// 핀 활성 여부 (primary가 pinned candidate)
  @override
  @JsonKey()
  final bool pinned;

  /// 기타 대안 후보 (최대 3개, score > 0만)
  final List<GoalCandidate> _alternatives;

  /// 기타 대안 후보 (최대 3개, score > 0만)
  @override
  @JsonKey()
  List<GoalCandidate> get alternatives {
    if (_alternatives is EqualUnmodifiableListView) return _alternatives;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_alternatives);
  }

  /// fallback 상태 (후보 없음 또는 모두 score <= 0)
  @override
  @JsonKey()
  final bool isFallback;

  /// 무효화된 pinId (감지되면 UI의 post-frame cleanup에서 제거)
  @override
  final String? invalidatedPinId;

  @override
  String toString() {
    return 'GoalRecommendation(slot: $slot, primary: $primary, pinned: $pinned, alternatives: $alternatives, isFallback: $isFallback, invalidatedPinId: $invalidatedPinId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalRecommendationImpl &&
            (identical(other.slot, slot) || other.slot == slot) &&
            (identical(other.primary, primary) || other.primary == primary) &&
            (identical(other.pinned, pinned) || other.pinned == pinned) &&
            const DeepCollectionEquality()
                .equals(other._alternatives, _alternatives) &&
            (identical(other.isFallback, isFallback) ||
                other.isFallback == isFallback) &&
            (identical(other.invalidatedPinId, invalidatedPinId) ||
                other.invalidatedPinId == invalidatedPinId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      slot,
      primary,
      pinned,
      const DeepCollectionEquality().hash(_alternatives),
      isFallback,
      invalidatedPinId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalRecommendationImplCopyWith<_$GoalRecommendationImpl> get copyWith =>
      __$$GoalRecommendationImplCopyWithImpl<_$GoalRecommendationImpl>(
          this, _$identity);
}

abstract class _GoalRecommendation implements GoalRecommendation {
  const factory _GoalRecommendation(
      {required final GoalSlot slot,
      final GoalCandidate? primary,
      final bool pinned,
      final List<GoalCandidate> alternatives,
      final bool isFallback,
      final String? invalidatedPinId}) = _$GoalRecommendationImpl;

  @override

  /// 목표 슬롯
  GoalSlot get slot;
  @override

  /// 자동 추천 또는 핀된 후보 (null이면 fallback 상태)
  GoalCandidate? get primary;
  @override

  /// 핀 활성 여부 (primary가 pinned candidate)
  bool get pinned;
  @override

  /// 기타 대안 후보 (최대 3개, score > 0만)
  List<GoalCandidate> get alternatives;
  @override

  /// fallback 상태 (후보 없음 또는 모두 score <= 0)
  bool get isFallback;
  @override

  /// 무효화된 pinId (감지되면 UI의 post-frame cleanup에서 제거)
  String? get invalidatedPinId;
  @override
  @JsonKey(ignore: true)
  _$$GoalRecommendationImplCopyWith<_$GoalRecommendationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
