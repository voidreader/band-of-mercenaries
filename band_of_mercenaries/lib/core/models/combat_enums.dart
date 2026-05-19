// M8b 페이즈 4 #2 — 정적 카탈로그용 전투 enum 7종 (Hive typeId 미할당)
import 'package:json_annotation/json_annotation.dart';

enum ApplyMethod {
  @JsonValue('multiplicative') multiplicative,
  @JsonValue('additive') additive,
  @JsonValue('proportional') proportional,
  @JsonValue('absolute') absolute,
  @JsonValue('none') none,
}

enum StackPolicy {
  @JsonValue('refresh') refresh,
  @JsonValue('stack') stack,
  @JsonValue('ignore') ignore,
}

enum ActionCost {
  @JsonValue('action') action,
  @JsonValue('extraAction') extraAction, // CSV 값 camelCase 보존
  @JsonValue('passive') passive,
}

enum TriggerKind {
  @JsonValue('passive') passive,
  @JsonValue('active') active,
  @JsonValue('triggered') triggered,
  @JsonValue('on_hit') onHit,
  @JsonValue('on_kill') onKill,
}

enum TargetingKind {
  @JsonValue('self') self,
  @JsonValue('single_enemy') singleEnemy,
  @JsonValue('single_ally') singleAlly,
  @JsonValue('aoe_enemy') aoeEnemy,
  @JsonValue('aoe_ally') aoeAlly,
  @JsonValue('party') party,
}

enum DispelKind {
  @JsonValue('debuff') debuff,
  @JsonValue('buff') buff,
  @JsonValue('dot') dot,
  @JsonValue('debuff+dot') debuffPlusDot,
}

enum EnemyKind {
  @JsonValue('normal') normal,
  @JsonValue('elite') elite,
  @JsonValue('unique') unique,
}
