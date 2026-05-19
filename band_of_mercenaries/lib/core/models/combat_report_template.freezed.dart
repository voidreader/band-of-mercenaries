// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat_report_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CombatReportTemplate _$CombatReportTemplateFromJson(Map<String, dynamic> json) {
  return _CombatReportTemplate.fromJson(json);
}

/// @nodoc
mixin _$CombatReportTemplate {
  String get id => throw _privateConstructorUsedError;
  String get group => throw _privateConstructorUsedError;
  String get scope => throw _privateConstructorUsedError;
  @JsonKey(name: 'faction_id')
  String? get factionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'quest_type')
  String? get questType => throw _privateConstructorUsedError;
  @JsonKey(name: 'result_type')
  String? get resultType => throw _privateConstructorUsedError;
  @JsonKey(name: 'line_type')
  String get lineType => throw _privateConstructorUsedError;
  String get importance => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;
  String get template => throw _privateConstructorUsedError;
  @JsonKey(name: 'tags_json')
  Object? get tagsJson => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CombatReportTemplateCopyWith<CombatReportTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CombatReportTemplateCopyWith<$Res> {
  factory $CombatReportTemplateCopyWith(CombatReportTemplate value,
          $Res Function(CombatReportTemplate) then) =
      _$CombatReportTemplateCopyWithImpl<$Res, CombatReportTemplate>;
  @useResult
  $Res call(
      {String id,
      String group,
      String scope,
      @JsonKey(name: 'faction_id') String? factionId,
      @JsonKey(name: 'quest_type') String? questType,
      @JsonKey(name: 'result_type') String? resultType,
      @JsonKey(name: 'line_type') String lineType,
      String importance,
      int weight,
      String template,
      @JsonKey(name: 'tags_json') Object? tagsJson});
}

/// @nodoc
class _$CombatReportTemplateCopyWithImpl<$Res,
        $Val extends CombatReportTemplate>
    implements $CombatReportTemplateCopyWith<$Res> {
  _$CombatReportTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? group = null,
    Object? scope = null,
    Object? factionId = freezed,
    Object? questType = freezed,
    Object? resultType = freezed,
    Object? lineType = null,
    Object? importance = null,
    Object? weight = null,
    Object? template = null,
    Object? tagsJson = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      group: null == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String,
      factionId: freezed == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String?,
      questType: freezed == questType
          ? _value.questType
          : questType // ignore: cast_nullable_to_non_nullable
              as String?,
      resultType: freezed == resultType
          ? _value.resultType
          : resultType // ignore: cast_nullable_to_non_nullable
              as String?,
      lineType: null == lineType
          ? _value.lineType
          : lineType // ignore: cast_nullable_to_non_nullable
              as String,
      importance: null == importance
          ? _value.importance
          : importance // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      tagsJson: freezed == tagsJson ? _value.tagsJson : tagsJson,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CombatReportTemplateImplCopyWith<$Res>
    implements $CombatReportTemplateCopyWith<$Res> {
  factory _$$CombatReportTemplateImplCopyWith(_$CombatReportTemplateImpl value,
          $Res Function(_$CombatReportTemplateImpl) then) =
      __$$CombatReportTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String group,
      String scope,
      @JsonKey(name: 'faction_id') String? factionId,
      @JsonKey(name: 'quest_type') String? questType,
      @JsonKey(name: 'result_type') String? resultType,
      @JsonKey(name: 'line_type') String lineType,
      String importance,
      int weight,
      String template,
      @JsonKey(name: 'tags_json') Object? tagsJson});
}

/// @nodoc
class __$$CombatReportTemplateImplCopyWithImpl<$Res>
    extends _$CombatReportTemplateCopyWithImpl<$Res, _$CombatReportTemplateImpl>
    implements _$$CombatReportTemplateImplCopyWith<$Res> {
  __$$CombatReportTemplateImplCopyWithImpl(_$CombatReportTemplateImpl _value,
      $Res Function(_$CombatReportTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? group = null,
    Object? scope = null,
    Object? factionId = freezed,
    Object? questType = freezed,
    Object? resultType = freezed,
    Object? lineType = null,
    Object? importance = null,
    Object? weight = null,
    Object? template = null,
    Object? tagsJson = freezed,
  }) {
    return _then(_$CombatReportTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      group: null == group
          ? _value.group
          : group // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as String,
      factionId: freezed == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String?,
      questType: freezed == questType
          ? _value.questType
          : questType // ignore: cast_nullable_to_non_nullable
              as String?,
      resultType: freezed == resultType
          ? _value.resultType
          : resultType // ignore: cast_nullable_to_non_nullable
              as String?,
      lineType: null == lineType
          ? _value.lineType
          : lineType // ignore: cast_nullable_to_non_nullable
              as String,
      importance: null == importance
          ? _value.importance
          : importance // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      tagsJson: freezed == tagsJson ? _value.tagsJson : tagsJson,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CombatReportTemplateImpl implements _CombatReportTemplate {
  const _$CombatReportTemplateImpl(
      {required this.id,
      required this.group,
      required this.scope,
      @JsonKey(name: 'faction_id') this.factionId,
      @JsonKey(name: 'quest_type') this.questType,
      @JsonKey(name: 'result_type') this.resultType,
      @JsonKey(name: 'line_type') required this.lineType,
      required this.importance,
      this.weight = 1,
      required this.template,
      @JsonKey(name: 'tags_json') this.tagsJson});

  factory _$CombatReportTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$CombatReportTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String group;
  @override
  final String scope;
  @override
  @JsonKey(name: 'faction_id')
  final String? factionId;
  @override
  @JsonKey(name: 'quest_type')
  final String? questType;
  @override
  @JsonKey(name: 'result_type')
  final String? resultType;
  @override
  @JsonKey(name: 'line_type')
  final String lineType;
  @override
  final String importance;
  @override
  @JsonKey()
  final int weight;
  @override
  final String template;
  @override
  @JsonKey(name: 'tags_json')
  final Object? tagsJson;

  @override
  String toString() {
    return 'CombatReportTemplate(id: $id, group: $group, scope: $scope, factionId: $factionId, questType: $questType, resultType: $resultType, lineType: $lineType, importance: $importance, weight: $weight, template: $template, tagsJson: $tagsJson)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CombatReportTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.group, group) || other.group == group) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.factionId, factionId) ||
                other.factionId == factionId) &&
            (identical(other.questType, questType) ||
                other.questType == questType) &&
            (identical(other.resultType, resultType) ||
                other.resultType == resultType) &&
            (identical(other.lineType, lineType) ||
                other.lineType == lineType) &&
            (identical(other.importance, importance) ||
                other.importance == importance) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.template, template) ||
                other.template == template) &&
            const DeepCollectionEquality().equals(other.tagsJson, tagsJson));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      group,
      scope,
      factionId,
      questType,
      resultType,
      lineType,
      importance,
      weight,
      template,
      const DeepCollectionEquality().hash(tagsJson));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CombatReportTemplateImplCopyWith<_$CombatReportTemplateImpl>
      get copyWith =>
          __$$CombatReportTemplateImplCopyWithImpl<_$CombatReportTemplateImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CombatReportTemplateImplToJson(
      this,
    );
  }
}

abstract class _CombatReportTemplate implements CombatReportTemplate {
  const factory _CombatReportTemplate(
          {required final String id,
          required final String group,
          required final String scope,
          @JsonKey(name: 'faction_id') final String? factionId,
          @JsonKey(name: 'quest_type') final String? questType,
          @JsonKey(name: 'result_type') final String? resultType,
          @JsonKey(name: 'line_type') required final String lineType,
          required final String importance,
          final int weight,
          required final String template,
          @JsonKey(name: 'tags_json') final Object? tagsJson}) =
      _$CombatReportTemplateImpl;

  factory _CombatReportTemplate.fromJson(Map<String, dynamic> json) =
      _$CombatReportTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get group;
  @override
  String get scope;
  @override
  @JsonKey(name: 'faction_id')
  String? get factionId;
  @override
  @JsonKey(name: 'quest_type')
  String? get questType;
  @override
  @JsonKey(name: 'result_type')
  String? get resultType;
  @override
  @JsonKey(name: 'line_type')
  String get lineType;
  @override
  String get importance;
  @override
  int get weight;
  @override
  String get template;
  @override
  @JsonKey(name: 'tags_json')
  Object? get tagsJson;
  @override
  @JsonKey(ignore: true)
  _$$CombatReportTemplateImplCopyWith<_$CombatReportTemplateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
