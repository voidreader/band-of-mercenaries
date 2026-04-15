// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faction_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FactionData _$FactionDataFromJson(Map<String, dynamic> json) {
  return _FactionData.fromJson(json);
}

/// @nodoc
mixin _$FactionData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get philosophy => throw _privateConstructorUsedError;
  @JsonKey(name: 'tier_range')
  List<int> get tierRange => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FactionDataCopyWith<FactionData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FactionDataCopyWith<$Res> {
  factory $FactionDataCopyWith(
          FactionData value, $Res Function(FactionData) then) =
      _$FactionDataCopyWithImpl<$Res, FactionData>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String philosophy,
      @JsonKey(name: 'tier_range') List<int> tierRange,
      String color});
}

/// @nodoc
class _$FactionDataCopyWithImpl<$Res, $Val extends FactionData>
    implements $FactionDataCopyWith<$Res> {
  _$FactionDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? philosophy = null,
    Object? tierRange = null,
    Object? color = null,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      philosophy: null == philosophy
          ? _value.philosophy
          : philosophy // ignore: cast_nullable_to_non_nullable
              as String,
      tierRange: null == tierRange
          ? _value.tierRange
          : tierRange // ignore: cast_nullable_to_non_nullable
              as List<int>,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FactionDataImplCopyWith<$Res>
    implements $FactionDataCopyWith<$Res> {
  factory _$$FactionDataImplCopyWith(
          _$FactionDataImpl value, $Res Function(_$FactionDataImpl) then) =
      __$$FactionDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String philosophy,
      @JsonKey(name: 'tier_range') List<int> tierRange,
      String color});
}

/// @nodoc
class __$$FactionDataImplCopyWithImpl<$Res>
    extends _$FactionDataCopyWithImpl<$Res, _$FactionDataImpl>
    implements _$$FactionDataImplCopyWith<$Res> {
  __$$FactionDataImplCopyWithImpl(
      _$FactionDataImpl _value, $Res Function(_$FactionDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? philosophy = null,
    Object? tierRange = null,
    Object? color = null,
  }) {
    return _then(_$FactionDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      philosophy: null == philosophy
          ? _value.philosophy
          : philosophy // ignore: cast_nullable_to_non_nullable
              as String,
      tierRange: null == tierRange
          ? _value._tierRange
          : tierRange // ignore: cast_nullable_to_non_nullable
              as List<int>,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FactionDataImpl implements _FactionData {
  const _$FactionDataImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.philosophy,
      @JsonKey(name: 'tier_range') required final List<int> tierRange,
      required this.color})
      : _tierRange = tierRange;

  factory _$FactionDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FactionDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String philosophy;
  final List<int> _tierRange;
  @override
  @JsonKey(name: 'tier_range')
  List<int> get tierRange {
    if (_tierRange is EqualUnmodifiableListView) return _tierRange;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tierRange);
  }

  @override
  final String color;

  @override
  String toString() {
    return 'FactionData(id: $id, name: $name, description: $description, philosophy: $philosophy, tierRange: $tierRange, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FactionDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.philosophy, philosophy) ||
                other.philosophy == philosophy) &&
            const DeepCollectionEquality()
                .equals(other._tierRange, _tierRange) &&
            (identical(other.color, color) || other.color == color));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description,
      philosophy, const DeepCollectionEquality().hash(_tierRange), color);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FactionDataImplCopyWith<_$FactionDataImpl> get copyWith =>
      __$$FactionDataImplCopyWithImpl<_$FactionDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FactionDataImplToJson(
      this,
    );
  }
}

abstract class _FactionData implements FactionData {
  const factory _FactionData(
      {required final String id,
      required final String name,
      required final String description,
      required final String philosophy,
      @JsonKey(name: 'tier_range') required final List<int> tierRange,
      required final String color}) = _$FactionDataImpl;

  factory _FactionData.fromJson(Map<String, dynamic> json) =
      _$FactionDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get philosophy;
  @override
  @JsonKey(name: 'tier_range')
  List<int> get tierRange;
  @override
  String get color;
  @override
  @JsonKey(ignore: true)
  _$$FactionDataImplCopyWith<_$FactionDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
