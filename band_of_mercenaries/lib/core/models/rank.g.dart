// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RankImpl _$$RankImplFromJson(Map<String, dynamic> json) => _$RankImpl(
      grade: json['grade'] as String,
      name: json['name'] as String,
      requiredReputation: (json['required_reputation'] as num).toInt(),
      unlockTier: (json['unlock_tier'] as num).toInt(),
    );

Map<String, dynamic> _$$RankImplToJson(_$RankImpl instance) =>
    <String, dynamic>{
      'grade': instance.grade,
      'name': instance.name,
      'required_reputation': instance.requiredReputation,
      'unlock_tier': instance.unlockTier,
    };

_$RankListImpl _$$RankListImplFromJson(Map<String, dynamic> json) =>
    _$RankListImpl(
      items: (json['Ranks'] as List<dynamic>)
          .map((e) => Rank.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$RankListImplToJson(_$RankListImpl instance) =>
    <String, dynamic>{
      'Ranks': instance.items,
    };
