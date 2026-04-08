// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mercenary_wage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MercenaryWageImpl _$$MercenaryWageImplFromJson(Map<String, dynamic> json) =>
    _$MercenaryWageImpl(
      tier: (json['Tier'] as num).toInt(),
      wage: (json['Wage'] as num).toInt(),
    );

Map<String, dynamic> _$$MercenaryWageImplToJson(_$MercenaryWageImpl instance) =>
    <String, dynamic>{
      'Tier': instance.tier,
      'Wage': instance.wage,
    };

_$MercenaryWageListImpl _$$MercenaryWageListImplFromJson(
        Map<String, dynamic> json) =>
    _$MercenaryWageListImpl(
      items: (json['MercenaryWages'] as List<dynamic>)
          .map((e) => MercenaryWage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MercenaryWageListImplToJson(
        _$MercenaryWageListImpl instance) =>
    <String, dynamic>{
      'MercenaryWages': instance.items,
    };
