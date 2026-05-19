// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat_report_keyword.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CombatReportKeyword _$CombatReportKeywordFromJson(Map<String, dynamic> json) {
  return _CombatReportKeyword.fromJson(json);
}

/// @nodoc
mixin _$CombatReportKeyword {
  String get id => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get key => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_text')
  String get displayText => throw _privateConstructorUsedError;
  @JsonKey(name: 'tags_json')
  Object? get tagsJson => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CombatReportKeywordCopyWith<CombatReportKeyword> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CombatReportKeywordCopyWith<$Res> {
  factory $CombatReportKeywordCopyWith(
          CombatReportKeyword value, $Res Function(CombatReportKeyword) then) =
      _$CombatReportKeywordCopyWithImpl<$Res, CombatReportKeyword>;
  @useResult
  $Res call(
      {String id,
      String category,
      String key,
      @JsonKey(name: 'display_text') String displayText,
      @JsonKey(name: 'tags_json') Object? tagsJson,
      int weight});
}

/// @nodoc
class _$CombatReportKeywordCopyWithImpl<$Res, $Val extends CombatReportKeyword>
    implements $CombatReportKeywordCopyWith<$Res> {
  _$CombatReportKeywordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? category = null,
    Object? key = null,
    Object? displayText = null,
    Object? tagsJson = freezed,
    Object? weight = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      displayText: null == displayText
          ? _value.displayText
          : displayText // ignore: cast_nullable_to_non_nullable
              as String,
      tagsJson: freezed == tagsJson ? _value.tagsJson : tagsJson,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CombatReportKeywordImplCopyWith<$Res>
    implements $CombatReportKeywordCopyWith<$Res> {
  factory _$$CombatReportKeywordImplCopyWith(_$CombatReportKeywordImpl value,
          $Res Function(_$CombatReportKeywordImpl) then) =
      __$$CombatReportKeywordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String category,
      String key,
      @JsonKey(name: 'display_text') String displayText,
      @JsonKey(name: 'tags_json') Object? tagsJson,
      int weight});
}

/// @nodoc
class __$$CombatReportKeywordImplCopyWithImpl<$Res>
    extends _$CombatReportKeywordCopyWithImpl<$Res, _$CombatReportKeywordImpl>
    implements _$$CombatReportKeywordImplCopyWith<$Res> {
  __$$CombatReportKeywordImplCopyWithImpl(_$CombatReportKeywordImpl _value,
      $Res Function(_$CombatReportKeywordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? category = null,
    Object? key = null,
    Object? displayText = null,
    Object? tagsJson = freezed,
    Object? weight = null,
  }) {
    return _then(_$CombatReportKeywordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      displayText: null == displayText
          ? _value.displayText
          : displayText // ignore: cast_nullable_to_non_nullable
              as String,
      tagsJson: freezed == tagsJson ? _value.tagsJson : tagsJson,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CombatReportKeywordImpl implements _CombatReportKeyword {
  const _$CombatReportKeywordImpl(
      {required this.id,
      required this.category,
      required this.key,
      @JsonKey(name: 'display_text') required this.displayText,
      @JsonKey(name: 'tags_json') this.tagsJson,
      this.weight = 1});

  factory _$CombatReportKeywordImpl.fromJson(Map<String, dynamic> json) =>
      _$$CombatReportKeywordImplFromJson(json);

  @override
  final String id;
  @override
  final String category;
  @override
  final String key;
  @override
  @JsonKey(name: 'display_text')
  final String displayText;
  @override
  @JsonKey(name: 'tags_json')
  final Object? tagsJson;
  @override
  @JsonKey()
  final int weight;

  @override
  String toString() {
    return 'CombatReportKeyword(id: $id, category: $category, key: $key, displayText: $displayText, tagsJson: $tagsJson, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CombatReportKeywordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.displayText, displayText) ||
                other.displayText == displayText) &&
            const DeepCollectionEquality().equals(other.tagsJson, tagsJson) &&
            (identical(other.weight, weight) || other.weight == weight));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, category, key, displayText,
      const DeepCollectionEquality().hash(tagsJson), weight);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CombatReportKeywordImplCopyWith<_$CombatReportKeywordImpl> get copyWith =>
      __$$CombatReportKeywordImplCopyWithImpl<_$CombatReportKeywordImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CombatReportKeywordImplToJson(
      this,
    );
  }
}

abstract class _CombatReportKeyword implements CombatReportKeyword {
  const factory _CombatReportKeyword(
      {required final String id,
      required final String category,
      required final String key,
      @JsonKey(name: 'display_text') required final String displayText,
      @JsonKey(name: 'tags_json') final Object? tagsJson,
      final int weight}) = _$CombatReportKeywordImpl;

  factory _CombatReportKeyword.fromJson(Map<String, dynamic> json) =
      _$CombatReportKeywordImpl.fromJson;

  @override
  String get id;
  @override
  String get category;
  @override
  String get key;
  @override
  @JsonKey(name: 'display_text')
  String get displayText;
  @override
  @JsonKey(name: 'tags_json')
  Object? get tagsJson;
  @override
  int get weight;
  @override
  @JsonKey(ignore: true)
  _$$CombatReportKeywordImplCopyWith<_$CombatReportKeywordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
