// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'faction_contact_arrived_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FactionContactArrivedEvent {
  String get factionId => throw _privateConstructorUsedError;
  String get factionName => throw _privateConstructorUsedError;
  String get contactId => throw _privateConstructorUsedError;
  String get npcName => throw _privateConstructorUsedError;
  String get firstReactionText => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FactionContactArrivedEventCopyWith<FactionContactArrivedEvent>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FactionContactArrivedEventCopyWith<$Res> {
  factory $FactionContactArrivedEventCopyWith(FactionContactArrivedEvent value,
          $Res Function(FactionContactArrivedEvent) then) =
      _$FactionContactArrivedEventCopyWithImpl<$Res,
          FactionContactArrivedEvent>;
  @useResult
  $Res call(
      {String factionId,
      String factionName,
      String contactId,
      String npcName,
      String firstReactionText});
}

/// @nodoc
class _$FactionContactArrivedEventCopyWithImpl<$Res,
        $Val extends FactionContactArrivedEvent>
    implements $FactionContactArrivedEventCopyWith<$Res> {
  _$FactionContactArrivedEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? factionId = null,
    Object? factionName = null,
    Object? contactId = null,
    Object? npcName = null,
    Object? firstReactionText = null,
  }) {
    return _then(_value.copyWith(
      factionId: null == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String,
      factionName: null == factionName
          ? _value.factionName
          : factionName // ignore: cast_nullable_to_non_nullable
              as String,
      contactId: null == contactId
          ? _value.contactId
          : contactId // ignore: cast_nullable_to_non_nullable
              as String,
      npcName: null == npcName
          ? _value.npcName
          : npcName // ignore: cast_nullable_to_non_nullable
              as String,
      firstReactionText: null == firstReactionText
          ? _value.firstReactionText
          : firstReactionText // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FactionContactArrivedEventImplCopyWith<$Res>
    implements $FactionContactArrivedEventCopyWith<$Res> {
  factory _$$FactionContactArrivedEventImplCopyWith(
          _$FactionContactArrivedEventImpl value,
          $Res Function(_$FactionContactArrivedEventImpl) then) =
      __$$FactionContactArrivedEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String factionId,
      String factionName,
      String contactId,
      String npcName,
      String firstReactionText});
}

/// @nodoc
class __$$FactionContactArrivedEventImplCopyWithImpl<$Res>
    extends _$FactionContactArrivedEventCopyWithImpl<$Res,
        _$FactionContactArrivedEventImpl>
    implements _$$FactionContactArrivedEventImplCopyWith<$Res> {
  __$$FactionContactArrivedEventImplCopyWithImpl(
      _$FactionContactArrivedEventImpl _value,
      $Res Function(_$FactionContactArrivedEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? factionId = null,
    Object? factionName = null,
    Object? contactId = null,
    Object? npcName = null,
    Object? firstReactionText = null,
  }) {
    return _then(_$FactionContactArrivedEventImpl(
      factionId: null == factionId
          ? _value.factionId
          : factionId // ignore: cast_nullable_to_non_nullable
              as String,
      factionName: null == factionName
          ? _value.factionName
          : factionName // ignore: cast_nullable_to_non_nullable
              as String,
      contactId: null == contactId
          ? _value.contactId
          : contactId // ignore: cast_nullable_to_non_nullable
              as String,
      npcName: null == npcName
          ? _value.npcName
          : npcName // ignore: cast_nullable_to_non_nullable
              as String,
      firstReactionText: null == firstReactionText
          ? _value.firstReactionText
          : firstReactionText // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$FactionContactArrivedEventImpl implements _FactionContactArrivedEvent {
  const _$FactionContactArrivedEventImpl(
      {required this.factionId,
      required this.factionName,
      required this.contactId,
      required this.npcName,
      required this.firstReactionText});

  @override
  final String factionId;
  @override
  final String factionName;
  @override
  final String contactId;
  @override
  final String npcName;
  @override
  final String firstReactionText;

  @override
  String toString() {
    return 'FactionContactArrivedEvent(factionId: $factionId, factionName: $factionName, contactId: $contactId, npcName: $npcName, firstReactionText: $firstReactionText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FactionContactArrivedEventImpl &&
            (identical(other.factionId, factionId) ||
                other.factionId == factionId) &&
            (identical(other.factionName, factionName) ||
                other.factionName == factionName) &&
            (identical(other.contactId, contactId) ||
                other.contactId == contactId) &&
            (identical(other.npcName, npcName) || other.npcName == npcName) &&
            (identical(other.firstReactionText, firstReactionText) ||
                other.firstReactionText == firstReactionText));
  }

  @override
  int get hashCode => Object.hash(runtimeType, factionId, factionName,
      contactId, npcName, firstReactionText);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FactionContactArrivedEventImplCopyWith<_$FactionContactArrivedEventImpl>
      get copyWith => __$$FactionContactArrivedEventImplCopyWithImpl<
          _$FactionContactArrivedEventImpl>(this, _$identity);
}

abstract class _FactionContactArrivedEvent
    implements FactionContactArrivedEvent {
  const factory _FactionContactArrivedEvent(
          {required final String factionId,
          required final String factionName,
          required final String contactId,
          required final String npcName,
          required final String firstReactionText}) =
      _$FactionContactArrivedEventImpl;

  @override
  String get factionId;
  @override
  String get factionName;
  @override
  String get contactId;
  @override
  String get npcName;
  @override
  String get firstReactionText;
  @override
  @JsonKey(ignore: true)
  _$$FactionContactArrivedEventImplCopyWith<_$FactionContactArrivedEventImpl>
      get copyWith => throw _privateConstructorUsedError;
}
