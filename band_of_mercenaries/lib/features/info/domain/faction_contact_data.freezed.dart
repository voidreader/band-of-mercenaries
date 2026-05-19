// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faction_contact_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FactionContact _$FactionContactFromJson(Map<String, dynamic> json) {
  return _FactionContact.fromJson(json);
}

/// @nodoc
mixin _$FactionContact {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'faction_id')
  String get factionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'region_id')
  int get regionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'npc_name')
  String get npcName => throw _privateConstructorUsedError;
  @JsonKey(name: 'trigger_type')
  String get triggerType => throw _privateConstructorUsedError;
  @JsonKey(name: 'trigger_value')
  String get triggerValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_reaction_text')
  String get firstReactionText => throw _privateConstructorUsedError;
  @JsonKey(name: 'tags_json')
  Map<String, dynamic> get tagsJson => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FactionContactCopyWith<FactionContact> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FactionContactCopyWith<$Res> {
  factory $FactionContactCopyWith(
          FactionContact value, $Res Function(FactionContact) then) =
      _$FactionContactCopyWithImpl<$Res, FactionContact>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'faction_id') String factionId,
      @JsonKey(name: 'region_id') int regionId,
      @JsonKey(name: 'npc_name') String npcName,
      @JsonKey(name: 'trigger_type') String triggerType,
      @JsonKey(name: 'trigger_value') String triggerValue,
      @JsonKey(name: 'first_reaction_text') String firstReactionText,
      @JsonKey(name: 'tags_json') Map<String, dynamic> tagsJson});
}

/// @nodoc
class _$FactionContactCopyWithImpl<$Res, $Val extends FactionContact>
    implements $FactionContactCopyWith<$Res> {
  _$FactionContactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? factionId = null,
    Object? regionId = null,
    Object? npcName = null,
    Object? triggerType = null,
    Object? triggerValue = null,
    Object? firstReactionText = null,
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
      regionId: null == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int,
      npcName: null == npcName
          ? _value.npcName
          : npcName // ignore: cast_nullable_to_non_nullable
              as String,
      triggerType: null == triggerType
          ? _value.triggerType
          : triggerType // ignore: cast_nullable_to_non_nullable
              as String,
      triggerValue: null == triggerValue
          ? _value.triggerValue
          : triggerValue // ignore: cast_nullable_to_non_nullable
              as String,
      firstReactionText: null == firstReactionText
          ? _value.firstReactionText
          : firstReactionText // ignore: cast_nullable_to_non_nullable
              as String,
      tagsJson: null == tagsJson
          ? _value.tagsJson
          : tagsJson // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FactionContactImplCopyWith<$Res>
    implements $FactionContactCopyWith<$Res> {
  factory _$$FactionContactImplCopyWith(_$FactionContactImpl value,
          $Res Function(_$FactionContactImpl) then) =
      __$$FactionContactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'faction_id') String factionId,
      @JsonKey(name: 'region_id') int regionId,
      @JsonKey(name: 'npc_name') String npcName,
      @JsonKey(name: 'trigger_type') String triggerType,
      @JsonKey(name: 'trigger_value') String triggerValue,
      @JsonKey(name: 'first_reaction_text') String firstReactionText,
      @JsonKey(name: 'tags_json') Map<String, dynamic> tagsJson});
}

/// @nodoc
class __$$FactionContactImplCopyWithImpl<$Res>
    extends _$FactionContactCopyWithImpl<$Res, _$FactionContactImpl>
    implements _$$FactionContactImplCopyWith<$Res> {
  __$$FactionContactImplCopyWithImpl(
      _$FactionContactImpl _value, $Res Function(_$FactionContactImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? factionId = null,
    Object? regionId = null,
    Object? npcName = null,
    Object? triggerType = null,
    Object? triggerValue = null,
    Object? firstReactionText = null,
    Object? tagsJson = null,
  }) {
    return _then(_$FactionContactImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      factionId: null == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String,
      regionId: null == regionId
          ? _value.regionId
          : regionId // ignore: cast_nullable_to_non_nullable
              as int,
      npcName: null == npcName
          ? _value.npcName
          : npcName // ignore: cast_nullable_to_non_nullable
              as String,
      triggerType: null == triggerType
          ? _value.triggerType
          : triggerType // ignore: cast_nullable_to_non_nullable
              as String,
      triggerValue: null == triggerValue
          ? _value.triggerValue
          : triggerValue // ignore: cast_nullable_to_non_nullable
              as String,
      firstReactionText: null == firstReactionText
          ? _value.firstReactionText
          : firstReactionText // ignore: cast_nullable_to_non_nullable
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
class _$FactionContactImpl implements _FactionContact {
  const _$FactionContactImpl(
      {required this.id,
      @JsonKey(name: 'faction_id') required this.factionId,
      @JsonKey(name: 'region_id') required this.regionId,
      @JsonKey(name: 'npc_name') required this.npcName,
      @JsonKey(name: 'trigger_type') required this.triggerType,
      @JsonKey(name: 'trigger_value') required this.triggerValue,
      @JsonKey(name: 'first_reaction_text') required this.firstReactionText,
      @JsonKey(name: 'tags_json')
      final Map<String, dynamic> tagsJson = const <String, dynamic>{}})
      : _tagsJson = tagsJson;

  factory _$FactionContactImpl.fromJson(Map<String, dynamic> json) =>
      _$$FactionContactImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'faction_id')
  final String factionId;
  @override
  @JsonKey(name: 'region_id')
  final int regionId;
  @override
  @JsonKey(name: 'npc_name')
  final String npcName;
  @override
  @JsonKey(name: 'trigger_type')
  final String triggerType;
  @override
  @JsonKey(name: 'trigger_value')
  final String triggerValue;
  @override
  @JsonKey(name: 'first_reaction_text')
  final String firstReactionText;
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
    return 'FactionContact(id: $id, factionId: $factionId, regionId: $regionId, npcName: $npcName, triggerType: $triggerType, triggerValue: $triggerValue, firstReactionText: $firstReactionText, tagsJson: $tagsJson)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FactionContactImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.factionId, factionId) ||
                other.factionId == factionId) &&
            (identical(other.regionId, regionId) ||
                other.regionId == regionId) &&
            (identical(other.npcName, npcName) || other.npcName == npcName) &&
            (identical(other.triggerType, triggerType) ||
                other.triggerType == triggerType) &&
            (identical(other.triggerValue, triggerValue) ||
                other.triggerValue == triggerValue) &&
            (identical(other.firstReactionText, firstReactionText) ||
                other.firstReactionText == firstReactionText) &&
            const DeepCollectionEquality().equals(other._tagsJson, _tagsJson));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      factionId,
      regionId,
      npcName,
      triggerType,
      triggerValue,
      firstReactionText,
      const DeepCollectionEquality().hash(_tagsJson));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FactionContactImplCopyWith<_$FactionContactImpl> get copyWith =>
      __$$FactionContactImplCopyWithImpl<_$FactionContactImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FactionContactImplToJson(
      this,
    );
  }
}

abstract class _FactionContact implements FactionContact {
  const factory _FactionContact(
          {required final String id,
          @JsonKey(name: 'faction_id') required final String factionId,
          @JsonKey(name: 'region_id') required final int regionId,
          @JsonKey(name: 'npc_name') required final String npcName,
          @JsonKey(name: 'trigger_type') required final String triggerType,
          @JsonKey(name: 'trigger_value') required final String triggerValue,
          @JsonKey(name: 'first_reaction_text')
          required final String firstReactionText,
          @JsonKey(name: 'tags_json') final Map<String, dynamic> tagsJson}) =
      _$FactionContactImpl;

  factory _FactionContact.fromJson(Map<String, dynamic> json) =
      _$FactionContactImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'faction_id')
  String get factionId;
  @override
  @JsonKey(name: 'region_id')
  int get regionId;
  @override
  @JsonKey(name: 'npc_name')
  String get npcName;
  @override
  @JsonKey(name: 'trigger_type')
  String get triggerType;
  @override
  @JsonKey(name: 'trigger_value')
  String get triggerValue;
  @override
  @JsonKey(name: 'first_reaction_text')
  String get firstReactionText;
  @override
  @JsonKey(name: 'tags_json')
  Map<String, dynamic> get tagsJson;
  @override
  @JsonKey(ignore: true)
  _$$FactionContactImplCopyWith<_$FactionContactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
