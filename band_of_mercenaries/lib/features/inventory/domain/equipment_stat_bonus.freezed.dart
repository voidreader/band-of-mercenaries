// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'equipment_stat_bonus.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EquipmentStatBonus {
  int get str => throw _privateConstructorUsedError;
  int get intelligence => throw _privateConstructorUsedError;
  int get vit => throw _privateConstructorUsedError;
  int get agi => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EquipmentStatBonusCopyWith<EquipmentStatBonus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EquipmentStatBonusCopyWith<$Res> {
  factory $EquipmentStatBonusCopyWith(
          EquipmentStatBonus value, $Res Function(EquipmentStatBonus) then) =
      _$EquipmentStatBonusCopyWithImpl<$Res, EquipmentStatBonus>;
  @useResult
  $Res call({int str, int intelligence, int vit, int agi});
}

/// @nodoc
class _$EquipmentStatBonusCopyWithImpl<$Res, $Val extends EquipmentStatBonus>
    implements $EquipmentStatBonusCopyWith<$Res> {
  _$EquipmentStatBonusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? str = null,
    Object? intelligence = null,
    Object? vit = null,
    Object? agi = null,
  }) {
    return _then(_value.copyWith(
      str: null == str
          ? _value.str
          : str // ignore: cast_nullable_to_non_nullable
              as int,
      intelligence: null == intelligence
          ? _value.intelligence
          : intelligence // ignore: cast_nullable_to_non_nullable
              as int,
      vit: null == vit
          ? _value.vit
          : vit // ignore: cast_nullable_to_non_nullable
              as int,
      agi: null == agi
          ? _value.agi
          : agi // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EquipmentStatBonusImplCopyWith<$Res>
    implements $EquipmentStatBonusCopyWith<$Res> {
  factory _$$EquipmentStatBonusImplCopyWith(_$EquipmentStatBonusImpl value,
          $Res Function(_$EquipmentStatBonusImpl) then) =
      __$$EquipmentStatBonusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int str, int intelligence, int vit, int agi});
}

/// @nodoc
class __$$EquipmentStatBonusImplCopyWithImpl<$Res>
    extends _$EquipmentStatBonusCopyWithImpl<$Res, _$EquipmentStatBonusImpl>
    implements _$$EquipmentStatBonusImplCopyWith<$Res> {
  __$$EquipmentStatBonusImplCopyWithImpl(_$EquipmentStatBonusImpl _value,
      $Res Function(_$EquipmentStatBonusImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? str = null,
    Object? intelligence = null,
    Object? vit = null,
    Object? agi = null,
  }) {
    return _then(_$EquipmentStatBonusImpl(
      str: null == str
          ? _value.str
          : str // ignore: cast_nullable_to_non_nullable
              as int,
      intelligence: null == intelligence
          ? _value.intelligence
          : intelligence // ignore: cast_nullable_to_non_nullable
              as int,
      vit: null == vit
          ? _value.vit
          : vit // ignore: cast_nullable_to_non_nullable
              as int,
      agi: null == agi
          ? _value.agi
          : agi // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$EquipmentStatBonusImpl implements _EquipmentStatBonus {
  const _$EquipmentStatBonusImpl(
      {this.str = 0, this.intelligence = 0, this.vit = 0, this.agi = 0});

  @override
  @JsonKey()
  final int str;
  @override
  @JsonKey()
  final int intelligence;
  @override
  @JsonKey()
  final int vit;
  @override
  @JsonKey()
  final int agi;

  @override
  String toString() {
    return 'EquipmentStatBonus(str: $str, intelligence: $intelligence, vit: $vit, agi: $agi)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EquipmentStatBonusImpl &&
            (identical(other.str, str) || other.str == str) &&
            (identical(other.intelligence, intelligence) ||
                other.intelligence == intelligence) &&
            (identical(other.vit, vit) || other.vit == vit) &&
            (identical(other.agi, agi) || other.agi == agi));
  }

  @override
  int get hashCode => Object.hash(runtimeType, str, intelligence, vit, agi);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EquipmentStatBonusImplCopyWith<_$EquipmentStatBonusImpl> get copyWith =>
      __$$EquipmentStatBonusImplCopyWithImpl<_$EquipmentStatBonusImpl>(
          this, _$identity);
}

abstract class _EquipmentStatBonus implements EquipmentStatBonus {
  const factory _EquipmentStatBonus(
      {final int str,
      final int intelligence,
      final int vit,
      final int agi}) = _$EquipmentStatBonusImpl;

  @override
  int get str;
  @override
  int get intelligence;
  @override
  int get vit;
  @override
  int get agi;
  @override
  @JsonKey(ignore: true)
  _$$EquipmentStatBonusImplCopyWith<_$EquipmentStatBonusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
