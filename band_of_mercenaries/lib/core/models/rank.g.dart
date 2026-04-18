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
      bonusJson: json['bonus_json'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$RankImplToJson(_$RankImpl instance) =>
    <String, dynamic>{
      'grade': instance.grade,
      'name': instance.name,
      'required_reputation': instance.requiredReputation,
      'unlock_tier': instance.unlockTier,
      'bonus_json': instance.bonusJson,
    };
