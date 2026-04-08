// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RankImpl _$$RankImplFromJson(Map<String, dynamic> json) => _$RankImpl(
      grade: json['Grade'] as String,
      name: json['Name'] as String,
      requiredReputation: (json['RequiredReputation'] as num).toInt(),
      unlockTier: (json['UnlockTier'] as num).toInt(),
    );

Map<String, dynamic> _$$RankImplToJson(_$RankImpl instance) =>
    <String, dynamic>{
      'Grade': instance.grade,
      'Name': instance.name,
      'RequiredReputation': instance.requiredReputation,
      'UnlockTier': instance.unlockTier,
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
