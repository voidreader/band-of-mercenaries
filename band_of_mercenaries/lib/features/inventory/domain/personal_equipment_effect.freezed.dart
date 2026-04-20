// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_equipment_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PersonalEquipmentEffect {
  EquipmentStatBonus get statBonus => throw _privateConstructorUsedError;
  LegendaryEffect? get legendary => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PersonalEquipmentEffectCopyWith<PersonalEquipmentEffect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalEquipmentEffectCopyWith<$Res> {
  factory $PersonalEquipmentEffectCopyWith(PersonalEquipmentEffect value,
          $Res Function(PersonalEquipmentEffect) then) =
      _$PersonalEquipmentEffectCopyWithImpl<$Res, PersonalEquipmentEffect>;
  @useResult
  $Res call({EquipmentStatBonus statBonus, LegendaryEffect? legendary});

  $EquipmentStatBonusCopyWith<$Res> get statBonus;
  $LegendaryEffectCopyWith<$Res>? get legendary;
}

/// @nodoc
class _$PersonalEquipmentEffectCopyWithImpl<$Res,
        $Val extends PersonalEquipmentEffect>
    implements $PersonalEquipmentEffectCopyWith<$Res> {
  _$PersonalEquipmentEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statBonus = null,
    Object? legendary = freezed,
  }) {
    return _then(_value.copyWith(
      statBonus: null == statBonus
          ? _value.statBonus
          : statBonus // ignore: cast_nullable_to_non_nullable
              as EquipmentStatBonus,
      legendary: freezed == legendary
          ? _value.legendary
          : legendary // ignore: cast_nullable_to_non_nullable
              as LegendaryEffect?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $EquipmentStatBonusCopyWith<$Res> get statBonus {
    return $EquipmentStatBonusCopyWith<$Res>(_value.statBonus, (value) {
      return _then(_value.copyWith(statBonus: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $LegendaryEffectCopyWith<$Res>? get legendary {
    if (_value.legendary == null) {
      return null;
    }

    return $LegendaryEffectCopyWith<$Res>(_value.legendary!, (value) {
      return _then(_value.copyWith(legendary: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PersonalEquipmentEffectImplCopyWith<$Res>
    implements $PersonalEquipmentEffectCopyWith<$Res> {
  factory _$$PersonalEquipmentEffectImplCopyWith(
          _$PersonalEquipmentEffectImpl value,
          $Res Function(_$PersonalEquipmentEffectImpl) then) =
      __$$PersonalEquipmentEffectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({EquipmentStatBonus statBonus, LegendaryEffect? legendary});

  @override
  $EquipmentStatBonusCopyWith<$Res> get statBonus;
  @override
  $LegendaryEffectCopyWith<$Res>? get legendary;
}

/// @nodoc
class __$$PersonalEquipmentEffectImplCopyWithImpl<$Res>
    extends _$PersonalEquipmentEffectCopyWithImpl<$Res,
        _$PersonalEquipmentEffectImpl>
    implements _$$PersonalEquipmentEffectImplCopyWith<$Res> {
  __$$PersonalEquipmentEffectImplCopyWithImpl(
      _$PersonalEquipmentEffectImpl _value,
      $Res Function(_$PersonalEquipmentEffectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statBonus = null,
    Object? legendary = freezed,
  }) {
    return _then(_$PersonalEquipmentEffectImpl(
      statBonus: null == statBonus
          ? _value.statBonus
          : statBonus // ignore: cast_nullable_to_non_nullable
              as EquipmentStatBonus,
      legendary: freezed == legendary
          ? _value.legendary
          : legendary // ignore: cast_nullable_to_non_nullable
              as LegendaryEffect?,
    ));
  }
}

/// @nodoc

class _$PersonalEquipmentEffectImpl implements _PersonalEquipmentEffect {
  const _$PersonalEquipmentEffectImpl(
      {required this.statBonus, this.legendary});

  @override
  final EquipmentStatBonus statBonus;
  @override
  final LegendaryEffect? legendary;

  @override
  String toString() {
    return 'PersonalEquipmentEffect(statBonus: $statBonus, legendary: $legendary)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalEquipmentEffectImpl &&
            (identical(other.statBonus, statBonus) ||
                other.statBonus == statBonus) &&
            (identical(other.legendary, legendary) ||
                other.legendary == legendary));
  }

  @override
  int get hashCode => Object.hash(runtimeType, statBonus, legendary);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalEquipmentEffectImplCopyWith<_$PersonalEquipmentEffectImpl>
      get copyWith => __$$PersonalEquipmentEffectImplCopyWithImpl<
          _$PersonalEquipmentEffectImpl>(this, _$identity);
}

abstract class _PersonalEquipmentEffect implements PersonalEquipmentEffect {
  const factory _PersonalEquipmentEffect(
      {required final EquipmentStatBonus statBonus,
      final LegendaryEffect? legendary}) = _$PersonalEquipmentEffectImpl;

  @override
  EquipmentStatBonus get statBonus;
  @override
  LegendaryEffect? get legendary;
  @override
  @JsonKey(ignore: true)
  _$$PersonalEquipmentEffectImplCopyWith<_$PersonalEquipmentEffectImpl>
      get copyWith => throw _privateConstructorUsedError;
}
