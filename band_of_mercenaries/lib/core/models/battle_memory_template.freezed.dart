// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'battle_memory_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BattleMemoryTemplate _$BattleMemoryTemplateFromJson(Map<String, dynamic> json) {
  return _BattleMemoryTemplate.fromJson(json);
}

/// @nodoc
mixin _$BattleMemoryTemplate {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'entry_type')
  String get entryType => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_event_match')
  String? get sourceEventMatch => throw _privateConstructorUsedError;
  String get template => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BattleMemoryTemplateCopyWith<BattleMemoryTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BattleMemoryTemplateCopyWith<$Res> {
  factory $BattleMemoryTemplateCopyWith(BattleMemoryTemplate value,
          $Res Function(BattleMemoryTemplate) then) =
      _$BattleMemoryTemplateCopyWithImpl<$Res, BattleMemoryTemplate>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'entry_type') String entryType,
      @JsonKey(name: 'source_event_match') String? sourceEventMatch,
      String template,
      int weight});
}

/// @nodoc
class _$BattleMemoryTemplateCopyWithImpl<$Res,
        $Val extends BattleMemoryTemplate>
    implements $BattleMemoryTemplateCopyWith<$Res> {
  _$BattleMemoryTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? entryType = null,
    Object? sourceEventMatch = freezed,
    Object? template = null,
    Object? weight = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      entryType: null == entryType
          ? _value.entryType
          : entryType // ignore: cast_nullable_to_non_nullable
              as String,
      sourceEventMatch: freezed == sourceEventMatch
          ? _value.sourceEventMatch
          : sourceEventMatch // ignore: cast_nullable_to_non_nullable
              as String?,
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BattleMemoryTemplateImplCopyWith<$Res>
    implements $BattleMemoryTemplateCopyWith<$Res> {
  factory _$$BattleMemoryTemplateImplCopyWith(_$BattleMemoryTemplateImpl value,
          $Res Function(_$BattleMemoryTemplateImpl) then) =
      __$$BattleMemoryTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'entry_type') String entryType,
      @JsonKey(name: 'source_event_match') String? sourceEventMatch,
      String template,
      int weight});
}

/// @nodoc
class __$$BattleMemoryTemplateImplCopyWithImpl<$Res>
    extends _$BattleMemoryTemplateCopyWithImpl<$Res, _$BattleMemoryTemplateImpl>
    implements _$$BattleMemoryTemplateImplCopyWith<$Res> {
  __$$BattleMemoryTemplateImplCopyWithImpl(_$BattleMemoryTemplateImpl _value,
      $Res Function(_$BattleMemoryTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? entryType = null,
    Object? sourceEventMatch = freezed,
    Object? template = null,
    Object? weight = null,
  }) {
    return _then(_$BattleMemoryTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      entryType: null == entryType
          ? _value.entryType
          : entryType // ignore: cast_nullable_to_non_nullable
              as String,
      sourceEventMatch: freezed == sourceEventMatch
          ? _value.sourceEventMatch
          : sourceEventMatch // ignore: cast_nullable_to_non_nullable
              as String?,
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BattleMemoryTemplateImpl implements _BattleMemoryTemplate {
  const _$BattleMemoryTemplateImpl(
      {required this.id,
      @JsonKey(name: 'entry_type') required this.entryType,
      @JsonKey(name: 'source_event_match') this.sourceEventMatch,
      required this.template,
      this.weight = 1});

  factory _$BattleMemoryTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$BattleMemoryTemplateImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'entry_type')
  final String entryType;
  @override
  @JsonKey(name: 'source_event_match')
  final String? sourceEventMatch;
  @override
  final String template;
  @override
  @JsonKey()
  final int weight;

  @override
  String toString() {
    return 'BattleMemoryTemplate(id: $id, entryType: $entryType, sourceEventMatch: $sourceEventMatch, template: $template, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BattleMemoryTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.entryType, entryType) ||
                other.entryType == entryType) &&
            (identical(other.sourceEventMatch, sourceEventMatch) ||
                other.sourceEventMatch == sourceEventMatch) &&
            (identical(other.template, template) ||
                other.template == template) &&
            (identical(other.weight, weight) || other.weight == weight));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, entryType, sourceEventMatch, template, weight);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BattleMemoryTemplateImplCopyWith<_$BattleMemoryTemplateImpl>
      get copyWith =>
          __$$BattleMemoryTemplateImplCopyWithImpl<_$BattleMemoryTemplateImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BattleMemoryTemplateImplToJson(
      this,
    );
  }
}

abstract class _BattleMemoryTemplate implements BattleMemoryTemplate {
  const factory _BattleMemoryTemplate(
      {required final String id,
      @JsonKey(name: 'entry_type') required final String entryType,
      @JsonKey(name: 'source_event_match') final String? sourceEventMatch,
      required final String template,
      final int weight}) = _$BattleMemoryTemplateImpl;

  factory _BattleMemoryTemplate.fromJson(Map<String, dynamic> json) =
      _$BattleMemoryTemplateImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'entry_type')
  String get entryType;
  @override
  @JsonKey(name: 'source_event_match')
  String? get sourceEventMatch;
  @override
  String get template;
  @override
  int get weight;
  @override
  @JsonKey(ignore: true)
  _$$BattleMemoryTemplateImplCopyWith<_$BattleMemoryTemplateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
