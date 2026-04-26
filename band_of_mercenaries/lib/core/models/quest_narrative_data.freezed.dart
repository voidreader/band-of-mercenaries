// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quest_narrative_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

QuestNarrativeData _$QuestNarrativeDataFromJson(Map<String, dynamic> json) {
  return _QuestNarrativeData.fromJson(json);
}

/// @nodoc
mixin _$QuestNarrativeData {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'quest_type')
  String get questType => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_type')
  String get resultType => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_elite')
  bool get isElite => throw _privateConstructorUsedError;
  String get template => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $QuestNarrativeDataCopyWith<QuestNarrativeData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestNarrativeDataCopyWith<$Res> {
  factory $QuestNarrativeDataCopyWith(
          QuestNarrativeData value, $Res Function(QuestNarrativeData) then) =
      _$QuestNarrativeDataCopyWithImpl<$Res, QuestNarrativeData>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'quest_type') String questType,
      @JsonKey(name: 'result_type') String resultType,
      @JsonKey(name: 'is_elite') bool isElite,
      String template,
      int weight,
      String? description});
}

/// @nodoc
class _$QuestNarrativeDataCopyWithImpl<$Res, $Val extends QuestNarrativeData>
    implements $QuestNarrativeDataCopyWith<$Res> {
  _$QuestNarrativeDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? questType = null,
    Object? resultType = null,
    Object? isElite = null,
    Object? template = null,
    Object? weight = null,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      questType: null == questType
          ? _value.questType
          : questType // ignore: cast_nullable_to_non_nullable
              as String,
      resultType: null == resultType
          ? _value.resultType
          : resultType // ignore: cast_nullable_to_non_nullable
              as String,
      isElite: null == isElite
          ? _value.isElite
          : isElite // ignore: cast_nullable_to_non_nullable
              as bool,
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$QuestNarrativeDataImplCopyWith<$Res>
    implements $QuestNarrativeDataCopyWith<$Res> {
  factory _$$QuestNarrativeDataImplCopyWith(_$QuestNarrativeDataImpl value,
          $Res Function(_$QuestNarrativeDataImpl) then) =
      __$$QuestNarrativeDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'quest_type') String questType,
      @JsonKey(name: 'result_type') String resultType,
      @JsonKey(name: 'is_elite') bool isElite,
      String template,
      int weight,
      String? description});
}

/// @nodoc
class __$$QuestNarrativeDataImplCopyWithImpl<$Res>
    extends _$QuestNarrativeDataCopyWithImpl<$Res, _$QuestNarrativeDataImpl>
    implements _$$QuestNarrativeDataImplCopyWith<$Res> {
  __$$QuestNarrativeDataImplCopyWithImpl(_$QuestNarrativeDataImpl _value,
      $Res Function(_$QuestNarrativeDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? questType = null,
    Object? resultType = null,
    Object? isElite = null,
    Object? template = null,
    Object? weight = null,
    Object? description = freezed,
  }) {
    return _then(_$QuestNarrativeDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      questType: null == questType
          ? _value.questType
          : questType // ignore: cast_nullable_to_non_nullable
              as String,
      resultType: null == resultType
          ? _value.resultType
          : resultType // ignore: cast_nullable_to_non_nullable
              as String,
      isElite: null == isElite
          ? _value.isElite
          : isElite // ignore: cast_nullable_to_non_nullable
              as bool,
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestNarrativeDataImpl implements _QuestNarrativeData {
  const _$QuestNarrativeDataImpl(
      {required this.id,
      @JsonKey(name: 'quest_type') required this.questType,
      @JsonKey(name: 'result_type') required this.resultType,
      @JsonKey(name: 'is_elite') this.isElite = false,
      required this.template,
      this.weight = 1,
      this.description});

  factory _$QuestNarrativeDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestNarrativeDataImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'quest_type')
  final String questType;
  @override
  @JsonKey(name: 'result_type')
  final String resultType;
  @override
  @JsonKey(name: 'is_elite')
  final bool isElite;
  @override
  final String template;
  @override
  @JsonKey()
  final int weight;
  @override
  final String? description;

  @override
  String toString() {
    return 'QuestNarrativeData(id: $id, questType: $questType, resultType: $resultType, isElite: $isElite, template: $template, weight: $weight, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestNarrativeDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.questType, questType) ||
                other.questType == questType) &&
            (identical(other.resultType, resultType) ||
                other.resultType == resultType) &&
            (identical(other.isElite, isElite) || other.isElite == isElite) &&
            (identical(other.template, template) ||
                other.template == template) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, questType, resultType,
      isElite, template, weight, description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestNarrativeDataImplCopyWith<_$QuestNarrativeDataImpl> get copyWith =>
      __$$QuestNarrativeDataImplCopyWithImpl<_$QuestNarrativeDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestNarrativeDataImplToJson(
      this,
    );
  }
}

abstract class _QuestNarrativeData implements QuestNarrativeData {
  const factory _QuestNarrativeData(
      {required final String id,
      @JsonKey(name: 'quest_type') required final String questType,
      @JsonKey(name: 'result_type') required final String resultType,
      @JsonKey(name: 'is_elite') final bool isElite,
      required final String template,
      final int weight,
      final String? description}) = _$QuestNarrativeDataImpl;

  factory _QuestNarrativeData.fromJson(Map<String, dynamic> json) =
      _$QuestNarrativeDataImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'quest_type')
  String get questType;
  @override
  @JsonKey(name: 'result_type')
  String get resultType;
  @override
  @JsonKey(name: 'is_elite')
  bool get isElite;
  @override
  String get template;
  @override
  int get weight;
  @override
  String? get description;
  @override
  @JsonKey(ignore: true)
  _$$QuestNarrativeDataImplCopyWith<_$QuestNarrativeDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
