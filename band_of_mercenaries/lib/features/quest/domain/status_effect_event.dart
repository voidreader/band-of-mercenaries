// M8b 페이즈 4 #2 — 상태 효과 이벤트 영속 모델 (typeId 25)
import 'package:hive/hive.dart';

part 'status_effect_event.g.dart';

@HiveType(typeId: 25)
class StatusEffectEvent extends HiveObject {
  /// 'apply'/'end'/'stack_increase'/'dispel'
  @HiveField(0)
  String eventType;

  @HiveField(1)
  int roundIndex;

  @HiveField(2)
  String targetId;

  @HiveField(3)
  String effectId;

  /// CombatStatusEffect.displayLabel 캐싱
  @HiveField(4)
  String labelKey;

  /// 'natural'/'dispel'/'death'/'combat_end' (eventType == 'end'만)
  @HiveField(5)
  String? endCause;

  /// apply/dispel 시 시전자
  @HiveField(6)
  String? casterId;

  /// apply 시 적용 강도
  @HiveField(7)
  double? intensity;

  /// apply 시 부여 지속 턴수
  @HiveField(8)
  int? durationTurns;

  /// stack_increase 시 결과 스택
  @HiveField(9)
  int? stackResult;

  StatusEffectEvent({
    required this.eventType,
    required this.roundIndex,
    required this.targetId,
    required this.effectId,
    required this.labelKey,
    this.endCause,
    this.casterId,
    this.intensity,
    this.durationTurns,
    this.stackResult,
  });
}
