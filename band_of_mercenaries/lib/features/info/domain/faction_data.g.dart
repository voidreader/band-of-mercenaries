// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faction_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FactionDataImpl _$$FactionDataImplFromJson(Map<String, dynamic> json) =>
    _$FactionDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      philosophy: json['philosophy'] as String,
      tierRange: (json['tier_range'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      color: json['color'] as String,
      visibilityType: json['visibility_type'] as String? ?? 'public',
      joinRankMin: json['join_rank_min'] as String?,
      joinNeedsClue: json['join_needs_clue'] as bool? ?? false,
      passiveBonusJson: json['passive_bonus_json'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      conflictFactionIds: (json['conflict_faction_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$FactionDataImplToJson(_$FactionDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'philosophy': instance.philosophy,
      'tier_range': instance.tierRange,
      'color': instance.color,
      'visibility_type': instance.visibilityType,
      'join_rank_min': instance.joinRankMin,
      'join_needs_clue': instance.joinNeedsClue,
      'passive_bonus_json': instance.passiveBonusJson,
      'conflict_faction_ids': instance.conflictFactionIds,
    };
