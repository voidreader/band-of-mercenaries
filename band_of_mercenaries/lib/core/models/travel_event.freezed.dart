// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'travel_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TravelEvent _$TravelEventFromJson(Map<String, dynamic> json) {
  return _TravelEvent.fromJson(json);
}

/// @nodoc
mixin _$TravelEvent {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'effect_type')
  String get effectType => throw _privateConstructorUsedError;
  double get magnitude => throw _privateConstructorUsedError;
  @JsonKey(name: 'min_tier')
  int get minTier => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_tier')
  int get maxTier => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TravelEventCopyWith<TravelEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TravelEventCopyWith<$Res> {
  factory $TravelEventCopyWith(
          TravelEvent value, $Res Function(TravelEvent) then) =
      _$TravelEventCopyWithImpl<$Res, TravelEvent>;
  @useResult
  $Res call(
      {String id,
      String name,
      String type,
      @JsonKey(name: 'effect_type') String effectType,
      double magnitude,
      @JsonKey(name: 'min_tier') int minTier,
      @JsonKey(name: 'max_tier') int maxTier,
      String description});
}

/// @nodoc
class _$TravelEventCopyWithImpl<$Res, $Val extends TravelEvent>
    implements $TravelEventCopyWith<$Res> {
  _$TravelEventCopyWithImpl(this._value, this._then);

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
    Object? effectType = null,
    Object? magnitude = null,
    Object? minTier = null,
    Object? maxTier = null,
    Object? description = null,
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
              as String,
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as String,
      magnitude: null == magnitude
          ? _value.magnitude
          : magnitude // ignore: cast_nullable_to_non_nullable
              as double,
      minTier: null == minTier
          ? _value.minTier
          : minTier // ignore: cast_nullable_to_non_nullable
              as int,
      maxTier: null == maxTier
          ? _value.maxTier
          : maxTier // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TravelEventImplCopyWith<$Res>
    implements $TravelEventCopyWith<$Res> {
  factory _$$TravelEventImplCopyWith(
          _$TravelEventImpl value, $Res Function(_$TravelEventImpl) then) =
      __$$TravelEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String type,
      @JsonKey(name: 'effect_type') String effectType,
      double magnitude,
      @JsonKey(name: 'min_tier') int minTier,
      @JsonKey(name: 'max_tier') int maxTier,
      String description});
}

/// @nodoc
class __$$TravelEventImplCopyWithImpl<$Res>
    extends _$TravelEventCopyWithImpl<$Res, _$TravelEventImpl>
    implements _$$TravelEventImplCopyWith<$Res> {
  __$$TravelEventImplCopyWithImpl(
      _$TravelEventImpl _value, $Res Function(_$TravelEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? effectType = null,
    Object? magnitude = null,
    Object? minTier = null,
    Object? maxTier = null,
    Object? description = null,
  }) {
    return _then(_$TravelEventImpl(
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
              as String,
      effectType: null == effectType
          ? _value.effectType
          : effectType // ignore: cast_nullable_to_non_nullable
              as String,
      magnitude: null == magnitude
          ? _value.magnitude
          : magnitude // ignore: cast_nullable_to_non_nullable
              as double,
      minTier: null == minTier
          ? _value.minTier
          : minTier // ignore: cast_nullable_to_non_nullable
              as int,
      maxTier: null == maxTier
          ? _value.maxTier
          : maxTier // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TravelEventImpl implements _TravelEvent {
  const _$TravelEventImpl(
      {required this.id,
      required this.name,
      required this.type,
      @JsonKey(name: 'effect_type') required this.effectType,
      required this.magnitude,
      @JsonKey(name: 'min_tier') required this.minTier,
      @JsonKey(name: 'max_tier') required this.maxTier,
      required this.description});

  factory _$TravelEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$TravelEventImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String type;
  @override
  @JsonKey(name: 'effect_type')
  final String effectType;
  @override
  final double magnitude;
  @override
  @JsonKey(name: 'min_tier')
  final int minTier;
  @override
  @JsonKey(name: 'max_tier')
  final int maxTier;
  @override
  final String description;

  @override
  String toString() {
    return 'TravelEvent(id: $id, name: $name, type: $type, effectType: $effectType, magnitude: $magnitude, minTier: $minTier, maxTier: $maxTier, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TravelEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.effectType, effectType) ||
                other.effectType == effectType) &&
            (identical(other.magnitude, magnitude) ||
                other.magnitude == magnitude) &&
            (identical(other.minTier, minTier) || other.minTier == minTier) &&
            (identical(other.maxTier, maxTier) || other.maxTier == maxTier) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, type, effectType,
      magnitude, minTier, maxTier, description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TravelEventImplCopyWith<_$TravelEventImpl> get copyWith =>
      __$$TravelEventImplCopyWithImpl<_$TravelEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TravelEventImplToJson(
      this,
    );
  }
}

abstract class _TravelEvent implements TravelEvent {
  const factory _TravelEvent(
      {required final String id,
      required final String name,
      required final String type,
      @JsonKey(name: 'effect_type') required final String effectType,
      required final double magnitude,
      @JsonKey(name: 'min_tier') required final int minTier,
      @JsonKey(name: 'max_tier') required final int maxTier,
      required final String description}) = _$TravelEventImpl;

  factory _TravelEvent.fromJson(Map<String, dynamic> json) =
      _$TravelEventImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get type;
  @override
  @JsonKey(name: 'effect_type')
  String get effectType;
  @override
  double get magnitude;
  @override
  @JsonKey(name: 'min_tier')
  int get minTier;
  @override
  @JsonKey(name: 'max_tier')
  int get maxTier;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$TravelEventImplCopyWith<_$TravelEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TravelEventList _$TravelEventListFromJson(Map<String, dynamic> json) {
  return _TravelEventList.fromJson(json);
}

/// @nodoc
mixin _$TravelEventList {
  @JsonKey(name: 'TravelEvents')
  List<TravelEvent> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TravelEventListCopyWith<TravelEventList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TravelEventListCopyWith<$Res> {
  factory $TravelEventListCopyWith(
          TravelEventList value, $Res Function(TravelEventList) then) =
      _$TravelEventListCopyWithImpl<$Res, TravelEventList>;
  @useResult
  $Res call({@JsonKey(name: 'TravelEvents') List<TravelEvent> items});
}

/// @nodoc
class _$TravelEventListCopyWithImpl<$Res, $Val extends TravelEventList>
    implements $TravelEventListCopyWith<$Res> {
  _$TravelEventListCopyWithImpl(this._value, this._then);

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
              as List<TravelEvent>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TravelEventListImplCopyWith<$Res>
    implements $TravelEventListCopyWith<$Res> {
  factory _$$TravelEventListImplCopyWith(_$TravelEventListImpl value,
          $Res Function(_$TravelEventListImpl) then) =
      __$$TravelEventListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'TravelEvents') List<TravelEvent> items});
}

/// @nodoc
class __$$TravelEventListImplCopyWithImpl<$Res>
    extends _$TravelEventListCopyWithImpl<$Res, _$TravelEventListImpl>
    implements _$$TravelEventListImplCopyWith<$Res> {
  __$$TravelEventListImplCopyWithImpl(
      _$TravelEventListImpl _value, $Res Function(_$TravelEventListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$TravelEventListImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<TravelEvent>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TravelEventListImpl implements _TravelEventList {
  const _$TravelEventListImpl(
      {@JsonKey(name: 'TravelEvents') required final List<TravelEvent> items})
      : _items = items;

  factory _$TravelEventListImpl.fromJson(Map<String, dynamic> json) =>
      _$$TravelEventListImplFromJson(json);

  final List<TravelEvent> _items;
  @override
  @JsonKey(name: 'TravelEvents')
  List<TravelEvent> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'TravelEventList(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TravelEventListImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TravelEventListImplCopyWith<_$TravelEventListImpl> get copyWith =>
      __$$TravelEventListImplCopyWithImpl<_$TravelEventListImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TravelEventListImplToJson(
      this,
    );
  }
}

abstract class _TravelEventList implements TravelEventList {
  const factory _TravelEventList(
      {@JsonKey(name: 'TravelEvents')
      required final List<TravelEvent> items}) = _$TravelEventListImpl;

  factory _TravelEventList.fromJson(Map<String, dynamic> json) =
      _$TravelEventListImpl.fromJson;

  @override
  @JsonKey(name: 'TravelEvents')
  List<TravelEvent> get items;
  @override
  @JsonKey(ignore: true)
  _$$TravelEventListImplCopyWith<_$TravelEventListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
