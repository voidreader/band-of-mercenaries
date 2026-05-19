// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'template_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TemplateContext {
  Mercenary? get merc => throw _privateConstructorUsedError;
  ActiveQuest? get quest => throw _privateConstructorUsedError;
  Region? get region => throw _privateConstructorUsedError;
  UserData get user => throw _privateConstructorUsedError;
  List<FactionState> get factionStates => throw _privateConstructorUsedError;
  Map<int, String>? get sectorChanges => throw _privateConstructorUsedError;
  int? get currentSectorIndex => throw _privateConstructorUsedError;
  List<Mercenary> get rosterForTeam => throw _privateConstructorUsedError;
  String? get eliteId => throw _privateConstructorUsedError;
  String? get allyName => throw _privateConstructorUsedError;
  String? get enemyName => throw _privateConstructorUsedError;
  int? get seed => throw _privateConstructorUsedError;
  EvaluationScope get evaluationScope => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TemplateContextCopyWith<TemplateContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TemplateContextCopyWith<$Res> {
  factory $TemplateContextCopyWith(
          TemplateContext value, $Res Function(TemplateContext) then) =
      _$TemplateContextCopyWithImpl<$Res, TemplateContext>;
  @useResult
  $Res call(
      {Mercenary? merc,
      ActiveQuest? quest,
      Region? region,
      UserData user,
      List<FactionState> factionStates,
      Map<int, String>? sectorChanges,
      int? currentSectorIndex,
      List<Mercenary> rosterForTeam,
      String? eliteId,
      String? allyName,
      String? enemyName,
      int? seed,
      EvaluationScope evaluationScope});

  $RegionCopyWith<$Res>? get region;
}

/// @nodoc
class _$TemplateContextCopyWithImpl<$Res, $Val extends TemplateContext>
    implements $TemplateContextCopyWith<$Res> {
  _$TemplateContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merc = freezed,
    Object? quest = freezed,
    Object? region = freezed,
    Object? user = null,
    Object? factionStates = null,
    Object? sectorChanges = freezed,
    Object? currentSectorIndex = freezed,
    Object? rosterForTeam = null,
    Object? eliteId = freezed,
    Object? allyName = freezed,
    Object? enemyName = freezed,
    Object? seed = freezed,
    Object? evaluationScope = null,
  }) {
    return _then(_value.copyWith(
      merc: freezed == merc
          ? _value.merc
          : merc // ignore: cast_nullable_to_non_nullable
              as Mercenary?,
      quest: freezed == quest
          ? _value.quest
          : quest // ignore: cast_nullable_to_non_nullable
              as ActiveQuest?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as Region?,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserData,
      factionStates: null == factionStates
          ? _value.factionStates
          : factionStates // ignore: cast_nullable_to_non_nullable
              as List<FactionState>,
      sectorChanges: freezed == sectorChanges
          ? _value.sectorChanges
          : sectorChanges // ignore: cast_nullable_to_non_nullable
              as Map<int, String>?,
      currentSectorIndex: freezed == currentSectorIndex
          ? _value.currentSectorIndex
          : currentSectorIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      rosterForTeam: null == rosterForTeam
          ? _value.rosterForTeam
          : rosterForTeam // ignore: cast_nullable_to_non_nullable
              as List<Mercenary>,
      eliteId: freezed == eliteId
          ? _value.eliteId
          : eliteId // ignore: cast_nullable_to_non_nullable
              as String?,
      allyName: freezed == allyName
          ? _value.allyName
          : allyName // ignore: cast_nullable_to_non_nullable
              as String?,
      enemyName: freezed == enemyName
          ? _value.enemyName
          : enemyName // ignore: cast_nullable_to_non_nullable
              as String?,
      seed: freezed == seed
          ? _value.seed
          : seed // ignore: cast_nullable_to_non_nullable
              as int?,
      evaluationScope: null == evaluationScope
          ? _value.evaluationScope
          : evaluationScope // ignore: cast_nullable_to_non_nullable
              as EvaluationScope,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RegionCopyWith<$Res>? get region {
    if (_value.region == null) {
      return null;
    }

    return $RegionCopyWith<$Res>(_value.region!, (value) {
      return _then(_value.copyWith(region: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TemplateContextImplCopyWith<$Res>
    implements $TemplateContextCopyWith<$Res> {
  factory _$$TemplateContextImplCopyWith(_$TemplateContextImpl value,
          $Res Function(_$TemplateContextImpl) then) =
      __$$TemplateContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Mercenary? merc,
      ActiveQuest? quest,
      Region? region,
      UserData user,
      List<FactionState> factionStates,
      Map<int, String>? sectorChanges,
      int? currentSectorIndex,
      List<Mercenary> rosterForTeam,
      String? eliteId,
      String? allyName,
      String? enemyName,
      int? seed,
      EvaluationScope evaluationScope});

  @override
  $RegionCopyWith<$Res>? get region;
}

/// @nodoc
class __$$TemplateContextImplCopyWithImpl<$Res>
    extends _$TemplateContextCopyWithImpl<$Res, _$TemplateContextImpl>
    implements _$$TemplateContextImplCopyWith<$Res> {
  __$$TemplateContextImplCopyWithImpl(
      _$TemplateContextImpl _value, $Res Function(_$TemplateContextImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merc = freezed,
    Object? quest = freezed,
    Object? region = freezed,
    Object? user = null,
    Object? factionStates = null,
    Object? sectorChanges = freezed,
    Object? currentSectorIndex = freezed,
    Object? rosterForTeam = null,
    Object? eliteId = freezed,
    Object? allyName = freezed,
    Object? enemyName = freezed,
    Object? seed = freezed,
    Object? evaluationScope = null,
  }) {
    return _then(_$TemplateContextImpl(
      merc: freezed == merc
          ? _value.merc
          : merc // ignore: cast_nullable_to_non_nullable
              as Mercenary?,
      quest: freezed == quest
          ? _value.quest
          : quest // ignore: cast_nullable_to_non_nullable
              as ActiveQuest?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as Region?,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserData,
      factionStates: null == factionStates
          ? _value._factionStates
          : factionStates // ignore: cast_nullable_to_non_nullable
              as List<FactionState>,
      sectorChanges: freezed == sectorChanges
          ? _value._sectorChanges
          : sectorChanges // ignore: cast_nullable_to_non_nullable
              as Map<int, String>?,
      currentSectorIndex: freezed == currentSectorIndex
          ? _value.currentSectorIndex
          : currentSectorIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      rosterForTeam: null == rosterForTeam
          ? _value._rosterForTeam
          : rosterForTeam // ignore: cast_nullable_to_non_nullable
              as List<Mercenary>,
      eliteId: freezed == eliteId
          ? _value.eliteId
          : eliteId // ignore: cast_nullable_to_non_nullable
              as String?,
      allyName: freezed == allyName
          ? _value.allyName
          : allyName // ignore: cast_nullable_to_non_nullable
              as String?,
      enemyName: freezed == enemyName
          ? _value.enemyName
          : enemyName // ignore: cast_nullable_to_non_nullable
              as String?,
      seed: freezed == seed
          ? _value.seed
          : seed // ignore: cast_nullable_to_non_nullable
              as int?,
      evaluationScope: null == evaluationScope
          ? _value.evaluationScope
          : evaluationScope // ignore: cast_nullable_to_non_nullable
              as EvaluationScope,
    ));
  }
}

/// @nodoc

class _$TemplateContextImpl implements _TemplateContext {
  const _$TemplateContextImpl(
      {this.merc,
      this.quest,
      this.region,
      required this.user,
      final List<FactionState> factionStates = const <FactionState>[],
      final Map<int, String>? sectorChanges,
      this.currentSectorIndex,
      final List<Mercenary> rosterForTeam = const <Mercenary>[],
      this.eliteId,
      this.allyName,
      this.enemyName,
      this.seed,
      this.evaluationScope = EvaluationScope.mercenary})
      : _factionStates = factionStates,
        _sectorChanges = sectorChanges,
        _rosterForTeam = rosterForTeam;

  @override
  final Mercenary? merc;
  @override
  final ActiveQuest? quest;
  @override
  final Region? region;
  @override
  final UserData user;
  final List<FactionState> _factionStates;
  @override
  @JsonKey()
  List<FactionState> get factionStates {
    if (_factionStates is EqualUnmodifiableListView) return _factionStates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_factionStates);
  }

  final Map<int, String>? _sectorChanges;
  @override
  Map<int, String>? get sectorChanges {
    final value = _sectorChanges;
    if (value == null) return null;
    if (_sectorChanges is EqualUnmodifiableMapView) return _sectorChanges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final int? currentSectorIndex;
  final List<Mercenary> _rosterForTeam;
  @override
  @JsonKey()
  List<Mercenary> get rosterForTeam {
    if (_rosterForTeam is EqualUnmodifiableListView) return _rosterForTeam;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rosterForTeam);
  }

  @override
  final String? eliteId;
  @override
  final String? allyName;
  @override
  final String? enemyName;
  @override
  final int? seed;
  @override
  @JsonKey()
  final EvaluationScope evaluationScope;

  @override
  String toString() {
    return 'TemplateContext(merc: $merc, quest: $quest, region: $region, user: $user, factionStates: $factionStates, sectorChanges: $sectorChanges, currentSectorIndex: $currentSectorIndex, rosterForTeam: $rosterForTeam, eliteId: $eliteId, allyName: $allyName, enemyName: $enemyName, seed: $seed, evaluationScope: $evaluationScope)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TemplateContextImpl &&
            (identical(other.merc, merc) || other.merc == merc) &&
            (identical(other.quest, quest) || other.quest == quest) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.user, user) || other.user == user) &&
            const DeepCollectionEquality()
                .equals(other._factionStates, _factionStates) &&
            const DeepCollectionEquality()
                .equals(other._sectorChanges, _sectorChanges) &&
            (identical(other.currentSectorIndex, currentSectorIndex) ||
                other.currentSectorIndex == currentSectorIndex) &&
            const DeepCollectionEquality()
                .equals(other._rosterForTeam, _rosterForTeam) &&
            (identical(other.eliteId, eliteId) || other.eliteId == eliteId) &&
            (identical(other.allyName, allyName) ||
                other.allyName == allyName) &&
            (identical(other.enemyName, enemyName) ||
                other.enemyName == enemyName) &&
            (identical(other.seed, seed) || other.seed == seed) &&
            (identical(other.evaluationScope, evaluationScope) ||
                other.evaluationScope == evaluationScope));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      merc,
      quest,
      region,
      user,
      const DeepCollectionEquality().hash(_factionStates),
      const DeepCollectionEquality().hash(_sectorChanges),
      currentSectorIndex,
      const DeepCollectionEquality().hash(_rosterForTeam),
      eliteId,
      allyName,
      enemyName,
      seed,
      evaluationScope);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TemplateContextImplCopyWith<_$TemplateContextImpl> get copyWith =>
      __$$TemplateContextImplCopyWithImpl<_$TemplateContextImpl>(
          this, _$identity);
}

abstract class _TemplateContext implements TemplateContext {
  const factory _TemplateContext(
      {final Mercenary? merc,
      final ActiveQuest? quest,
      final Region? region,
      required final UserData user,
      final List<FactionState> factionStates,
      final Map<int, String>? sectorChanges,
      final int? currentSectorIndex,
      final List<Mercenary> rosterForTeam,
      final String? eliteId,
      final String? allyName,
      final String? enemyName,
      final int? seed,
      final EvaluationScope evaluationScope}) = _$TemplateContextImpl;

  @override
  Mercenary? get merc;
  @override
  ActiveQuest? get quest;
  @override
  Region? get region;
  @override
  UserData get user;
  @override
  List<FactionState> get factionStates;
  @override
  Map<int, String>? get sectorChanges;
  @override
  int? get currentSectorIndex;
  @override
  List<Mercenary> get rosterForTeam;
  @override
  String? get eliteId;
  @override
  String? get allyName;
  @override
  String? get enemyName;
  @override
  int? get seed;
  @override
  EvaluationScope get evaluationScope;
  @override
  @JsonKey(ignore: true)
  _$$TemplateContextImplCopyWith<_$TemplateContextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
