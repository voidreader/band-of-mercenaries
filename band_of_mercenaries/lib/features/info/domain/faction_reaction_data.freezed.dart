// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faction_reaction_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FactionReaction _$FactionReactionFromJson(Map<String, dynamic> json) {
  return _FactionReaction.fromJson(json);
}

/// @nodoc
mixin _$FactionReaction {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'faction_id')
  String get factionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'contact_id')
  String get contactId => throw _privateConstructorUsedError;
  @JsonKey(name: 'trigger_type')
  String get triggerType => throw _privateConstructorUsedError;
  @JsonKey(name: 'trigger_value')
  String get triggerValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'relation_stage')
  String get relationStage => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  @JsonKey(name: 'tags_json')
  Map<String, dynamic> get tagsJson => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FactionReactionCopyWith<FactionReaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FactionReactionCopyWith<$Res> {
  factory $FactionReactionCopyWith(
          FactionReaction value, $Res Function(FactionReaction) then) =
      _$FactionReactionCopyWithImpl<$Res, FactionReaction>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'faction_id') String factionId,
      @JsonKey(name: 'contact_id') String contactId,
      @JsonKey(name: 'trigger_type') String triggerType,
      @JsonKey(name: 'trigger_value') String triggerValue,
      @JsonKey(name: 'relation_stage') String relationStage,
      int weight,
      String text,
      @JsonKey(name: 'tags_json') Map<String, dynamic> tagsJson});
}

/// @nodoc
class _$FactionReactionCopyWithImpl<$Res, $Val extends FactionReaction>
    implements $FactionReactionCopyWith<$Res> {
  _$FactionReactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? factionId = null,
    Object? contactId = null,
    Object? triggerType = null,
    Object? triggerValue = null,
    Object? relationStage = null,
    Object? weight = null,
    Object? text = null,
    Object? tagsJson = null,
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
      contactId: null == contactId
          ? _value.contactId
          : contactId // ignore: cast_nullable_to_non_nullable
              as String,
      triggerType: null == triggerType
          ? _value.triggerType
          : triggerType // ignore: cast_nullable_to_non_nullable
              as String,
      triggerValue: null == triggerValue
          ? _value.triggerValue
          : triggerValue // ignore: cast_nullable_to_non_nullable
              as String,
      relationStage: null == relationStage
          ? _value.relationStage
          : relationStage // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      tagsJson: null == tagsJson
          ? _value.tagsJson
          : tagsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FactionReactionImplCopyWith<$Res>
    implements $FactionReactionCopyWith<$Res> {
  factory _$$FactionReactionImplCopyWith(_$FactionReactionImpl value,
          $Res Function(_$FactionReactionImpl) then) =
      __$$FactionReactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'faction_id') String factionId,
      @JsonKey(name: 'contact_id') String contactId,
      @JsonKey(name: 'trigger_type') String triggerType,
      @JsonKey(name: 'trigger_value') String triggerValue,
      @JsonKey(name: 'relation_stage') String relationStage,
      int weight,
      String text,
      @JsonKey(name: 'tags_json') Map<String, dynamic> tagsJson});
}

/// @nodoc
class __$$FactionReactionImplCopyWithImpl<$Res>
    extends _$FactionReactionCopyWithImpl<$Res, _$FactionReactionImpl>
    implements _$$FactionReactionImplCopyWith<$Res> {
  __$$FactionReactionImplCopyWithImpl(
      _$FactionReactionImpl _value, $Res Function(_$FactionReactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? factionId = null,
    Object? contactId = null,
    Object? triggerType = null,
    Object? triggerValue = null,
    Object? relationStage = null,
    Object? weight = null,
    Object? text = null,
    Object? tagsJson = null,
  }) {
    return _then(_$FactionReactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      factionId: null == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String,
      contactId: null == contactId
          ? _value.contactId
          : contactId // ignore: cast_nullable_to_non_nullable
              as String,
      triggerType: null == triggerType
          ? _value.triggerType
          : triggerType // ignore: cast_nullable_to_non_nullable
              as String,
      triggerValue: null == triggerValue
          ? _value.triggerValue
          : triggerValue // ignore: cast_nullable_to_non_nullable
              as String,
      relationStage: null == relationStage
          ? _value.relationStage
          : relationStage // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      tagsJson: null == tagsJson
          ? _value._tagsJson
          : tagsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FactionReactionImpl implements _FactionReaction {
  const _$FactionReactionImpl(
      {required this.id,
      @JsonKey(name: 'faction_id') required this.factionId,
      @JsonKey(name: 'contact_id') required this.contactId,
      @JsonKey(name: 'trigger_type') required this.triggerType,
      @JsonKey(name: 'trigger_value') required this.triggerValue,
      @JsonKey(name: 'relation_stage') required this.relationStage,
      this.weight = 50,
      required this.text,
      @JsonKey(name: 'tags_json')
      final Map<String, dynamic> tagsJson = const <String, dynamic>{}})
      : _tagsJson = tagsJson;

  factory _$FactionReactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$FactionReactionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'faction_id')
  final String factionId;
  @override
  @JsonKey(name: 'contact_id')
  final String contactId;
  @override
  @JsonKey(name: 'trigger_type')
  final String triggerType;
  @override
  @JsonKey(name: 'trigger_value')
  final String triggerValue;
  @override
  @JsonKey(name: 'relation_stage')
  final String relationStage;
  @override
  @JsonKey()
  final int weight;
  @override
  final String text;
  final Map<String, dynamic> _tagsJson;
  @override
  @JsonKey(name: 'tags_json')
  Map<String, dynamic> get tagsJson {
    if (_tagsJson is EqualUnmodifiableMapView) return _tagsJson;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_tagsJson);
  }

  @override
  String toString() {
    return 'FactionReaction(id: $id, factionId: $factionId, contactId: $contactId, triggerType: $triggerType, triggerValue: $triggerValue, relationStage: $relationStage, weight: $weight, text: $text, tagsJson: $tagsJson)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FactionReactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.factionId, factionId) ||
                other.factionId == factionId) &&
            (identical(other.contactId, contactId) ||
                other.contactId == contactId) &&
            (identical(other.triggerType, triggerType) ||
                other.triggerType == triggerType) &&
            (identical(other.triggerValue, triggerValue) ||
                other.triggerValue == triggerValue) &&
            (identical(other.relationStage, relationStage) ||
                other.relationStage == relationStage) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._tagsJson, _tagsJson));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      factionId,
      contactId,
      triggerType,
      triggerValue,
      relationStage,
      weight,
      text,
      const DeepCollectionEquality().hash(_tagsJson));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FactionReactionImplCopyWith<_$FactionReactionImpl> get copyWith =>
      __$$FactionReactionImplCopyWithImpl<_$FactionReactionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FactionReactionImplToJson(
      this,
    );
  }
}

abstract class _FactionReaction implements FactionReaction {
  const factory _FactionReaction(
          {required final String id,
          @JsonKey(name: 'faction_id') required final String factionId,
          @JsonKey(name: 'contact_id') required final String contactId,
          @JsonKey(name: 'trigger_type') required final String triggerType,
          @JsonKey(name: 'trigger_value') required final String triggerValue,
          @JsonKey(name: 'relation_stage') required final String relationStage,
          final int weight,
          required final String text,
          @JsonKey(name: 'tags_json') final Map<String, dynamic> tagsJson}) =
      _$FactionReactionImpl;

  factory _FactionReaction.fromJson(Map<String, dynamic> json) =
      _$FactionReactionImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'faction_id')
  String get factionId;
  @override
  @JsonKey(name: 'contact_id')
  String get contactId;
  @override
  @JsonKey(name: 'trigger_type')
  String get triggerType;
  @override
  @JsonKey(name: 'trigger_value')
  String get triggerValue;
  @override
  @JsonKey(name: 'relation_stage')
  String get relationStage;
  @override
  int get weight;
  @override
  String get text;
  @override
  @JsonKey(name: 'tags_json')
  Map<String, dynamic> get tagsJson;
  @override
  @JsonKey(ignore: true)
  _$$FactionReactionImplCopyWith<_$FactionReactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
