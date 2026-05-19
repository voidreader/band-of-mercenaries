// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faction_shop_item_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FactionShopItem _$FactionShopItemFromJson(Map<String, dynamic> json) {
  return _FactionShopItem.fromJson(json);
}

/// @nodoc
mixin _$FactionShopItem {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'faction_id')
  String get factionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_id')
  String get itemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'shop_category')
  String get shopCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_gold')
  int get priceGold => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_reputation')
  int get minReputation => throw _privateConstructorUsedError;
  @JsonKey(name: 'requires_joined')
  bool get requiresJoined => throw _privateConstructorUsedError;
  @JsonKey(name: 'unlock_type')
  String? get unlockType => throw _privateConstructorUsedError;
  @JsonKey(name: 'unlock_value')
  String? get unlockValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'stock_policy')
  String get stockPolicy => throw _privateConstructorUsedError;
  @JsonKey(name: 'stock_limit')
  int get stockLimit => throw _privateConstructorUsedError;
  @JsonKey(name: 'restock_hours')
  int? get restockHours => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'grant_type')
  String get grantType => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FactionShopItemCopyWith<FactionShopItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FactionShopItemCopyWith<$Res> {
  factory $FactionShopItemCopyWith(
          FactionShopItem value, $Res Function(FactionShopItem) then) =
      _$FactionShopItemCopyWithImpl<$Res, FactionShopItem>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'faction_id') String factionId,
      @JsonKey(name: 'item_id') String itemId,
      @JsonKey(name: 'shop_category') String shopCategory,
      @JsonKey(name: 'price_gold') int priceGold,
      @JsonKey(name: 'min_reputation') int minReputation,
      @JsonKey(name: 'requires_joined') bool requiresJoined,
      @JsonKey(name: 'unlock_type') String? unlockType,
      @JsonKey(name: 'unlock_value') String? unlockValue,
      @JsonKey(name: 'stock_policy') String stockPolicy,
      @JsonKey(name: 'stock_limit') int stockLimit,
      @JsonKey(name: 'restock_hours') int? restockHours,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'grant_type') String grantType,
      String notes});
}

/// @nodoc
class _$FactionShopItemCopyWithImpl<$Res, $Val extends FactionShopItem>
    implements $FactionShopItemCopyWith<$Res> {
  _$FactionShopItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? factionId = null,
    Object? itemId = null,
    Object? shopCategory = null,
    Object? priceGold = null,
    Object? minReputation = null,
    Object? requiresJoined = null,
    Object? unlockType = freezed,
    Object? unlockValue = freezed,
    Object? stockPolicy = null,
    Object? stockLimit = null,
    Object? restockHours = freezed,
    Object? sortOrder = null,
    Object? grantType = null,
    Object? notes = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      factionId: null == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      shopCategory: null == shopCategory
          ? _value.shopCategory
          : shopCategory // ignore: cast_nullable_to_non_nullable
              as String,
      priceGold: null == priceGold
          ? _value.priceGold
          : priceGold // ignore: cast_nullable_to_non_nullable
              as int,
      minReputation: null == minReputation
          ? _value.minReputation
          : minReputation // ignore: cast_nullable_to_non_nullable
              as int,
      requiresJoined: null == requiresJoined
          ? _value.requiresJoined
          : requiresJoined // ignore: cast_nullable_to_non_nullable
              as bool,
      unlockType: freezed == unlockType
          ? _value.unlockType
          : unlockType // ignore: cast_nullable_to_non_nullable
              as String?,
      unlockValue: freezed == unlockValue
          ? _value.unlockValue
          : unlockValue // ignore: cast_nullable_to_non_nullable
              as String?,
      stockPolicy: null == stockPolicy
          ? _value.stockPolicy
          : stockPolicy // ignore: cast_nullable_to_non_nullable
              as String,
      stockLimit: null == stockLimit
          ? _value.stockLimit
          : stockLimit // ignore: cast_nullable_to_non_nullable
              as int,
      restockHours: freezed == restockHours
          ? _value.restockHours
          : restockHours // ignore: cast_nullable_to_non_nullable
              as int?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      grantType: null == grantType
          ? _value.grantType
          : grantType // ignore: cast_nullable_to_non_nullable
              as String,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FactionShopItemImplCopyWith<$Res>
    implements $FactionShopItemCopyWith<$Res> {
  factory _$$FactionShopItemImplCopyWith(_$FactionShopItemImpl value,
          $Res Function(_$FactionShopItemImpl) then) =
      __$$FactionShopItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'faction_id') String factionId,
      @JsonKey(name: 'item_id') String itemId,
      @JsonKey(name: 'shop_category') String shopCategory,
      @JsonKey(name: 'price_gold') int priceGold,
      @JsonKey(name: 'min_reputation') int minReputation,
      @JsonKey(name: 'requires_joined') bool requiresJoined,
      @JsonKey(name: 'unlock_type') String? unlockType,
      @JsonKey(name: 'unlock_value') String? unlockValue,
      @JsonKey(name: 'stock_policy') String stockPolicy,
      @JsonKey(name: 'stock_limit') int stockLimit,
      @JsonKey(name: 'restock_hours') int? restockHours,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'grant_type') String grantType,
      String notes});
}

/// @nodoc
class __$$FactionShopItemImplCopyWithImpl<$Res>
    extends _$FactionShopItemCopyWithImpl<$Res, _$FactionShopItemImpl>
    implements _$$FactionShopItemImplCopyWith<$Res> {
  __$$FactionShopItemImplCopyWithImpl(
      _$FactionShopItemImpl _value, $Res Function(_$FactionShopItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? factionId = null,
    Object? itemId = null,
    Object? shopCategory = null,
    Object? priceGold = null,
    Object? minReputation = null,
    Object? requiresJoined = null,
    Object? unlockType = freezed,
    Object? unlockValue = freezed,
    Object? stockPolicy = null,
    Object? stockLimit = null,
    Object? restockHours = freezed,
    Object? sortOrder = null,
    Object? grantType = null,
    Object? notes = null,
  }) {
    return _then(_$FactionShopItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      factionId: null == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String,
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      shopCategory: null == shopCategory
          ? _value.shopCategory
          : shopCategory // ignore: cast_nullable_to_non_nullable
              as String,
      priceGold: null == priceGold
          ? _value.priceGold
          : priceGold // ignore: cast_nullable_to_non_nullable
              as int,
      minReputation: null == minReputation
          ? _value.minReputation
          : minReputation // ignore: cast_nullable_to_non_nullable
              as int,
      requiresJoined: null == requiresJoined
          ? _value.requiresJoined
          : requiresJoined // ignore: cast_nullable_to_non_nullable
              as bool,
      unlockType: freezed == unlockType
          ? _value.unlockType
          : unlockType // ignore: cast_nullable_to_non_nullable
              as String?,
      unlockValue: freezed == unlockValue
          ? _value.unlockValue
          : unlockValue // ignore: cast_nullable_to_non_nullable
              as String?,
      stockPolicy: null == stockPolicy
          ? _value.stockPolicy
          : stockPolicy // ignore: cast_nullable_to_non_nullable
              as String,
      stockLimit: null == stockLimit
          ? _value.stockLimit
          : stockLimit // ignore: cast_nullable_to_non_nullable
              as int,
      restockHours: freezed == restockHours
          ? _value.restockHours
          : restockHours // ignore: cast_nullable_to_non_nullable
              as int?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      grantType: null == grantType
          ? _value.grantType
          : grantType // ignore: cast_nullable_to_non_nullable
              as String,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FactionShopItemImpl implements _FactionShopItem {
  const _$FactionShopItemImpl(
      {required this.id,
      @JsonKey(name: 'faction_id') required this.factionId,
      @JsonKey(name: 'item_id') required this.itemId,
      @JsonKey(name: 'shop_category') required this.shopCategory,
      @JsonKey(name: 'price_gold') required this.priceGold,
      @JsonKey(name: 'min_reputation') required this.minReputation,
      @JsonKey(name: 'requires_joined') this.requiresJoined = false,
      @JsonKey(name: 'unlock_type') this.unlockType,
      @JsonKey(name: 'unlock_value') this.unlockValue,
      @JsonKey(name: 'stock_policy') this.stockPolicy = 'once',
      @JsonKey(name: 'stock_limit') this.stockLimit = 1,
      @JsonKey(name: 'restock_hours') this.restockHours,
      @JsonKey(name: 'sort_order') this.sortOrder = 0,
      @JsonKey(name: 'grant_type') this.grantType = 'item',
      this.notes = ''});

  factory _$FactionShopItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FactionShopItemImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'faction_id')
  final String factionId;
  @override
  @JsonKey(name: 'item_id')
  final String itemId;
  @override
  @JsonKey(name: 'shop_category')
  final String shopCategory;
  @override
  @JsonKey(name: 'price_gold')
  final int priceGold;
  @override
  @JsonKey(name: 'min_reputation')
  final int minReputation;
  @override
  @JsonKey(name: 'requires_joined')
  final bool requiresJoined;
  @override
  @JsonKey(name: 'unlock_type')
  final String? unlockType;
  @override
  @JsonKey(name: 'unlock_value')
  final String? unlockValue;
  @override
  @JsonKey(name: 'stock_policy')
  final String stockPolicy;
  @override
  @JsonKey(name: 'stock_limit')
  final int stockLimit;
  @override
  @JsonKey(name: 'restock_hours')
  final int? restockHours;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @override
  @JsonKey(name: 'grant_type')
  final String grantType;
  @override
  @JsonKey()
  final String notes;

  @override
  String toString() {
    return 'FactionShopItem(id: $id, factionId: $factionId, itemId: $itemId, shopCategory: $shopCategory, priceGold: $priceGold, minReputation: $minReputation, requiresJoined: $requiresJoined, unlockType: $unlockType, unlockValue: $unlockValue, stockPolicy: $stockPolicy, stockLimit: $stockLimit, restockHours: $restockHours, sortOrder: $sortOrder, grantType: $grantType, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FactionShopItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.factionId, factionId) ||
                other.factionId == factionId) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.shopCategory, shopCategory) ||
                other.shopCategory == shopCategory) &&
            (identical(other.priceGold, priceGold) ||
                other.priceGold == priceGold) &&
            (identical(other.minReputation, minReputation) ||
                other.minReputation == minReputation) &&
            (identical(other.requiresJoined, requiresJoined) ||
                other.requiresJoined == requiresJoined) &&
            (identical(other.unlockType, unlockType) ||
                other.unlockType == unlockType) &&
            (identical(other.unlockValue, unlockValue) ||
                other.unlockValue == unlockValue) &&
            (identical(other.stockPolicy, stockPolicy) ||
                other.stockPolicy == stockPolicy) &&
            (identical(other.stockLimit, stockLimit) ||
                other.stockLimit == stockLimit) &&
            (identical(other.restockHours, restockHours) ||
                other.restockHours == restockHours) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.grantType, grantType) ||
                other.grantType == grantType) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      factionId,
      itemId,
      shopCategory,
      priceGold,
      minReputation,
      requiresJoined,
      unlockType,
      unlockValue,
      stockPolicy,
      stockLimit,
      restockHours,
      sortOrder,
      grantType,
      notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FactionShopItemImplCopyWith<_$FactionShopItemImpl> get copyWith =>
      __$$FactionShopItemImplCopyWithImpl<_$FactionShopItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FactionShopItemImplToJson(
      this,
    );
  }
}

abstract class _FactionShopItem implements FactionShopItem {
  const factory _FactionShopItem(
      {required final String id,
      @JsonKey(name: 'faction_id') required final String factionId,
      @JsonKey(name: 'item_id') required final String itemId,
      @JsonKey(name: 'shop_category') required final String shopCategory,
      @JsonKey(name: 'price_gold') required final int priceGold,
      @JsonKey(name: 'min_reputation') required final int minReputation,
      @JsonKey(name: 'requires_joined') final bool requiresJoined,
      @JsonKey(name: 'unlock_type') final String? unlockType,
      @JsonKey(name: 'unlock_value') final String? unlockValue,
      @JsonKey(name: 'stock_policy') final String stockPolicy,
      @JsonKey(name: 'stock_limit') final int stockLimit,
      @JsonKey(name: 'restock_hours') final int? restockHours,
      @JsonKey(name: 'sort_order') final int sortOrder,
      @JsonKey(name: 'grant_type') final String grantType,
      final String notes}) = _$FactionShopItemImpl;

  factory _FactionShopItem.fromJson(Map<String, dynamic> json) =
      _$FactionShopItemImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'faction_id')
  String get factionId;
  @override
  @JsonKey(name: 'item_id')
  String get itemId;
  @override
  @JsonKey(name: 'shop_category')
  String get shopCategory;
  @override
  @JsonKey(name: 'price_gold')
  int get priceGold;
  @override
  @JsonKey(name: 'min_reputation')
  int get minReputation;
  @override
  @JsonKey(name: 'requires_joined')
  bool get requiresJoined;
  @override
  @JsonKey(name: 'unlock_type')
  String? get unlockType;
  @override
  @JsonKey(name: 'unlock_value')
  String? get unlockValue;
  @override
  @JsonKey(name: 'stock_policy')
  String get stockPolicy;
  @override
  @JsonKey(name: 'stock_limit')
  int get stockLimit;
  @override
  @JsonKey(name: 'restock_hours')
  int? get restockHours;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'grant_type')
  String get grantType;
  @override
  String get notes;
  @override
  @JsonKey(ignore: true)
  _$$FactionShopItemImplCopyWith<_$FactionShopItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
