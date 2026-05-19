// M8b 페이즈 4 #2 — 전투 단일 행동 영속 모델 (typeId 24)
import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/quest/domain/combat_enums_hive.dart';

part 'combat_action.g.dart';

@HiveType(typeId: 24)
class CombatAction extends HiveObject {
  @HiveField(0)
  String actorId;

  @HiveField(1)
  List<String> targetIds;

  /// 'basic_attack'/'skill'/'dot_tick'/'skipped_stunned'/'extra_action'/'riposte'
  @HiveField(2)
  String actionKind;

  /// CombatSkill.id (nullable)
  @HiveField(3)
  String? skillId;

  /// CombatStatusEffect.id (nullable)
  @HiveField(4)
  String? statusEffectId;

  /// 액터가 적이면 enum, 파티이면 null
  @HiveField(5)
  BehaviorPattern? behaviorPattern;

  /// combat_report_keywords.category == 'decisive' 매칭 키
  @HiveField(6)
  String? decisiveKeywordKey;

  /// 페이즈 4 #1 [FR-18] §4 압축 라인 여부
  @HiveField(7)
  bool isComboCompression;

  /// 'entry'/'development'/'crisis'/'resolution'/'aftermath'
  @HiveField(8)
  String position;

  /// 단발 피해 (다단/광역은 합계)
  @HiveField(9)
  int damage;

  @HiveField(10)
  bool isCrit;

  @HiveField(11)
  bool isHit;

  @HiveField(12)
  bool isEvaded;

  @HiveField(13)
  bool isShielded;

  @HiveField(14)
  bool isKill;

  /// 0.0~0.6 적용된 감소율
  @HiveField(15)
  double shieldMitigation;

  /// JSON for AoE detail/multi-hit/extension
  @HiveField(16)
  Map<String, dynamic>? extraMeta;

  CombatAction({
    required this.actorId,
    required this.targetIds,
    required this.actionKind,
    this.skillId,
    this.statusEffectId,
    this.behaviorPattern,
    this.decisiveKeywordKey,
    this.isComboCompression = false,
    required this.position,
    this.damage = 0,
    this.isCrit = false,
    this.isHit = true,
    this.isEvaded = false,
    this.isShielded = false,
    this.isKill = false,
    this.shieldMitigation = 0.0,
    this.extraMeta,
  });
}
