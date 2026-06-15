// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ImageAsset _$ImageAssetFromJson(Map<String, dynamic> json) {
  return _ImageAsset.fromJson(json);
}

/// @nodoc
mixin _$ImageAsset {
  @JsonKey(name: 'asset_key')
  String get assetKey => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'entity_id')
  String? get entityId => throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;
  @JsonKey(name: 'fallback_emoji')
  String? get fallbackEmoji => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ImageAssetCopyWith<ImageAsset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImageAssetCopyWith<$Res> {
  factory $ImageAssetCopyWith(
          ImageAsset value, $Res Function(ImageAsset) then) =
      _$ImageAssetCopyWithImpl<$Res, ImageAsset>;
  @useResult
  $Res call(
      {@JsonKey(name: 'asset_key') String assetKey,
      String category,
      @JsonKey(name: 'entity_id') String? entityId,
      String? url,
      int? width,
      int? height,
      @JsonKey(name: 'fallback_emoji') String? fallbackEmoji,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class _$ImageAssetCopyWithImpl<$Res, $Val extends ImageAsset>
    implements $ImageAssetCopyWith<$Res> {
  _$ImageAssetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assetKey = null,
    Object? category = null,
    Object? entityId = freezed,
    Object? url = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? fallbackEmoji = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      assetKey: null == assetKey
          ? _value.assetKey
          : assetKey // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      fallbackEmoji: freezed == fallbackEmoji
          ? _value.fallbackEmoji
          : fallbackEmoji // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImageAssetImplCopyWith<$Res>
    implements $ImageAssetCopyWith<$Res> {
  factory _$$ImageAssetImplCopyWith(
          _$ImageAssetImpl value, $Res Function(_$ImageAssetImpl) then) =
      __$$ImageAssetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'asset_key') String assetKey,
      String category,
      @JsonKey(name: 'entity_id') String? entityId,
      String? url,
      int? width,
      int? height,
      @JsonKey(name: 'fallback_emoji') String? fallbackEmoji,
      @JsonKey(name: 'updated_at') String? updatedAt});
}

/// @nodoc
class __$$ImageAssetImplCopyWithImpl<$Res>
    extends _$ImageAssetCopyWithImpl<$Res, _$ImageAssetImpl>
    implements _$$ImageAssetImplCopyWith<$Res> {
  __$$ImageAssetImplCopyWithImpl(
      _$ImageAssetImpl _value, $Res Function(_$ImageAssetImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? assetKey = null,
    Object? category = null,
    Object? entityId = freezed,
    Object? url = freezed,
    Object? width = freezed,
    Object? height = freezed,
    Object? fallbackEmoji = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ImageAssetImpl(
      assetKey: null == assetKey
          ? _value.assetKey
          : assetKey // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      entityId: freezed == entityId
          ? _value.entityId
          : entityId // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      fallbackEmoji: freezed == fallbackEmoji
          ? _value.fallbackEmoji
          : fallbackEmoji // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImageAssetImpl implements _ImageAsset {
  const _$ImageAssetImpl(
      {@JsonKey(name: 'asset_key') required this.assetKey,
      required this.category,
      @JsonKey(name: 'entity_id') this.entityId,
      this.url,
      this.width,
      this.height,
      @JsonKey(name: 'fallback_emoji') this.fallbackEmoji,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$ImageAssetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImageAssetImplFromJson(json);

  @override
  @JsonKey(name: 'asset_key')
  final String assetKey;
  @override
  final String category;
  @override
  @JsonKey(name: 'entity_id')
  final String? entityId;
  @override
  final String? url;
  @override
  final int? width;
  @override
  final int? height;
  @override
  @JsonKey(name: 'fallback_emoji')
  final String? fallbackEmoji;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @override
  String toString() {
    return 'ImageAsset(assetKey: $assetKey, category: $category, entityId: $entityId, url: $url, width: $width, height: $height, fallbackEmoji: $fallbackEmoji, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageAssetImpl &&
            (identical(other.assetKey, assetKey) ||
                other.assetKey == assetKey) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.entityId, entityId) ||
                other.entityId == entityId) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.fallbackEmoji, fallbackEmoji) ||
                other.fallbackEmoji == fallbackEmoji) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, assetKey, category, entityId,
      url, width, height, fallbackEmoji, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageAssetImplCopyWith<_$ImageAssetImpl> get copyWith =>
      __$$ImageAssetImplCopyWithImpl<_$ImageAssetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImageAssetImplToJson(
      this,
    );
  }
}

abstract class _ImageAsset implements ImageAsset {
  const factory _ImageAsset(
      {@JsonKey(name: 'asset_key') required final String assetKey,
      required final String category,
      @JsonKey(name: 'entity_id') final String? entityId,
      final String? url,
      final int? width,
      final int? height,
      @JsonKey(name: 'fallback_emoji') final String? fallbackEmoji,
      @JsonKey(name: 'updated_at') final String? updatedAt}) = _$ImageAssetImpl;

  factory _ImageAsset.fromJson(Map<String, dynamic> json) =
      _$ImageAssetImpl.fromJson;

  @override
  @JsonKey(name: 'asset_key')
  String get assetKey;
  @override
  String get category;
  @override
  @JsonKey(name: 'entity_id')
  String? get entityId;
  @override
  String? get url;
  @override
  int? get width;
  @override
  int? get height;
  @override
  @JsonKey(name: 'fallback_emoji')
  String? get fallbackEmoji;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ImageAssetImplCopyWith<_$ImageAssetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
