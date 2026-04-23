// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'elite_loot_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EliteLootEntry _$EliteLootEntryFromJson(Map<String, dynamic> json) {
  return _EliteLootEntry.fromJson(json);
}

/// @nodoc
mixin _$EliteLootEntry {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'elite_id')
  String get eliteId => throw _privateConstructorUsedError;
  @JsonKey(name: 'drop_type')
  String get dropType => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_id')
  String? get itemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'gold_min')
  int? get goldMin => throw _privateConstructorUsedError;
  @JsonKey(name: 'gold_max')
  int? get goldMax => throw _privateConstructorUsedError;
  @JsonKey(name: 'drop_rate')
  double get dropRate => throw _privateConstructorUsedError;
  @JsonKey(name: 'rarity_grade')
  String get rarityGrade => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EliteLootEntryCopyWith<EliteLootEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EliteLootEntryCopyWith<$Res> {
  factory $EliteLootEntryCopyWith(
          EliteLootEntry value, $Res Function(EliteLootEntry) then) =
      _$EliteLootEntryCopyWithImpl<$Res, EliteLootEntry>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'elite_id') String eliteId,
      @JsonKey(name: 'drop_type') String dropType,
      @JsonKey(name: 'item_id') String? itemId,
      @JsonKey(name: 'gold_min') int? goldMin,
      @JsonKey(name: 'gold_max') int? goldMax,
      @JsonKey(name: 'drop_rate') double dropRate,
      @JsonKey(name: 'rarity_grade') String rarityGrade,
      int quantity});
}

/// @nodoc
class _$EliteLootEntryCopyWithImpl<$Res, $Val extends EliteLootEntry>
    implements $EliteLootEntryCopyWith<$Res> {
  _$EliteLootEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eliteId = null,
    Object? dropType = null,
    Object? itemId = freezed,
    Object? goldMin = freezed,
    Object? goldMax = freezed,
    Object? dropRate = null,
    Object? rarityGrade = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eliteId: null == eliteId
          ? _value.eliteId
          : eliteId // ignore: cast_nullable_to_non_nullable
              as String,
      dropType: null == dropType
          ? _value.dropType
          : dropType // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: freezed == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String?,
      goldMin: freezed == goldMin
          ? _value.goldMin
          : goldMin // ignore: cast_nullable_to_non_nullable
              as int?,
      goldMax: freezed == goldMax
          ? _value.goldMax
          : goldMax // ignore: cast_nullable_to_non_nullable
              as int?,
      dropRate: null == dropRate
          ? _value.dropRate
          : dropRate // ignore: cast_nullable_to_non_nullable
              as double,
      rarityGrade: null == rarityGrade
          ? _value.rarityGrade
          : rarityGrade // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EliteLootEntryImplCopyWith<$Res>
    implements $EliteLootEntryCopyWith<$Res> {
  factory _$$EliteLootEntryImplCopyWith(_$EliteLootEntryImpl value,
          $Res Function(_$EliteLootEntryImpl) then) =
      __$$EliteLootEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'elite_id') String eliteId,
      @JsonKey(name: 'drop_type') String dropType,
      @JsonKey(name: 'item_id') String? itemId,
      @JsonKey(name: 'gold_min') int? goldMin,
      @JsonKey(name: 'gold_max') int? goldMax,
      @JsonKey(name: 'drop_rate') double dropRate,
      @JsonKey(name: 'rarity_grade') String rarityGrade,
      int quantity});
}

/// @nodoc
class __$$EliteLootEntryImplCopyWithImpl<$Res>
    extends _$EliteLootEntryCopyWithImpl<$Res, _$EliteLootEntryImpl>
    implements _$$EliteLootEntryImplCopyWith<$Res> {
  __$$EliteLootEntryImplCopyWithImpl(
      _$EliteLootEntryImpl _value, $Res Function(_$EliteLootEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? eliteId = null,
    Object? dropType = null,
    Object? itemId = freezed,
    Object? goldMin = freezed,
    Object? goldMax = freezed,
    Object? dropRate = null,
    Object? rarityGrade = null,
    Object? quantity = null,
  }) {
    return _then(_$EliteLootEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      eliteId: null == eliteId
          ? _value.eliteId
          : eliteId // ignore: cast_nullable_to_non_nullable
              as String,
      dropType: null == dropType
          ? _value.dropType
          : dropType // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: freezed == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String?,
      goldMin: freezed == goldMin
          ? _value.goldMin
          : goldMin // ignore: cast_nullable_to_non_nullable
              as int?,
      goldMax: freezed == goldMax
          ? _value.goldMax
          : goldMax // ignore: cast_nullable_to_non_nullable
              as int?,
      dropRate: null == dropRate
          ? _value.dropRate
          : dropRate // ignore: cast_nullable_to_non_nullable
              as double,
      rarityGrade: null == rarityGrade
          ? _value.rarityGrade
          : rarityGrade // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EliteLootEntryImpl implements _EliteLootEntry {
  const _$EliteLootEntryImpl(
      {required this.id,
      @JsonKey(name: 'elite_id') required this.eliteId,
      @JsonKey(name: 'drop_type') required this.dropType,
      @JsonKey(name: 'item_id') this.itemId,
      @JsonKey(name: 'gold_min') this.goldMin,
      @JsonKey(name: 'gold_max') this.goldMax,
      @JsonKey(name: 'drop_rate') required this.dropRate,
      @JsonKey(name: 'rarity_grade') required this.rarityGrade,
      this.quantity = 1});

  factory _$EliteLootEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$EliteLootEntryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'elite_id')
  final String eliteId;
  @override
  @JsonKey(name: 'drop_type')
  final String dropType;
  @override
  @JsonKey(name: 'item_id')
  final String? itemId;
  @override
  @JsonKey(name: 'gold_min')
  final int? goldMin;
  @override
  @JsonKey(name: 'gold_max')
  final int? goldMax;
  @override
  @JsonKey(name: 'drop_rate')
  final double dropRate;
  @override
  @JsonKey(name: 'rarity_grade')
  final String rarityGrade;
  @override
  @JsonKey()
  final int quantity;

  @override
  String toString() {
    return 'EliteLootEntry(id: $id, eliteId: $eliteId, dropType: $dropType, itemId: $itemId, goldMin: $goldMin, goldMax: $goldMax, dropRate: $dropRate, rarityGrade: $rarityGrade, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EliteLootEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.eliteId, eliteId) || other.eliteId == eliteId) &&
            (identical(other.dropType, dropType) ||
                other.dropType == dropType) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.goldMin, goldMin) || other.goldMin == goldMin) &&
            (identical(other.goldMax, goldMax) || other.goldMax == goldMax) &&
            (identical(other.dropRate, dropRate) ||
                other.dropRate == dropRate) &&
            (identical(other.rarityGrade, rarityGrade) ||
                other.rarityGrade == rarityGrade) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, eliteId, dropType, itemId,
      goldMin, goldMax, dropRate, rarityGrade, quantity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EliteLootEntryImplCopyWith<_$EliteLootEntryImpl> get copyWith =>
      __$$EliteLootEntryImplCopyWithImpl<_$EliteLootEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EliteLootEntryImplToJson(
      this,
    );
  }
}

abstract class _EliteLootEntry implements EliteLootEntry {
  const factory _EliteLootEntry(
      {required final String id,
      @JsonKey(name: 'elite_id') required final String eliteId,
      @JsonKey(name: 'drop_type') required final String dropType,
      @JsonKey(name: 'item_id') final String? itemId,
      @JsonKey(name: 'gold_min') final int? goldMin,
      @JsonKey(name: 'gold_max') final int? goldMax,
      @JsonKey(name: 'drop_rate') required final double dropRate,
      @JsonKey(name: 'rarity_grade') required final String rarityGrade,
      final int quantity}) = _$EliteLootEntryImpl;

  factory _EliteLootEntry.fromJson(Map<String, dynamic> json) =
      _$EliteLootEntryImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'elite_id')
  String get eliteId;
  @override
  @JsonKey(name: 'drop_type')
  String get dropType;
  @override
  @JsonKey(name: 'item_id')
  String? get itemId;
  @override
  @JsonKey(name: 'gold_min')
  int? get goldMin;
  @override
  @JsonKey(name: 'gold_max')
  int? get goldMax;
  @override
  @JsonKey(name: 'drop_rate')
  double get dropRate;
  @override
  @JsonKey(name: 'rarity_grade')
  String get rarityGrade;
  @override
  int get quantity;
  @override
  @JsonKey(ignore: true)
  _$$EliteLootEntryImplCopyWith<_$EliteLootEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
