import 'package:band_of_mercenaries/core/models/passive_effect.dart';

/// 히든 스탯 효과를 해석·계산하는 정적 helper.
/// 불굴/투지/운/공포저항/전장감각 5 스탯의 lv별 효과 산식 + 레벨 임계값을 정의한다.
/// 참조: Docs/balance-design/[balance]20260522_m8.5_hidden_stat_values.md §6.2
class HiddenStatBonusResolver {
  // 스탯 ID 컨벤션 (레벨 저장소 키)
  static const String fortitude = 'fortitude';
  static const String grit = 'grit';
  static const String luck = 'luck';
  static const String fearResistance = 'fear_resistance';
  static const String battleSense = 'battle_sense';

  // 카운터 키 컨벤션 ({statId}_event_count)
  static const String fortitudeCounter = 'fortitude_event_count';
  static const String gritCounter = 'grit_event_count';
  static const String luckCounter = 'luck_event_count';
  static const String fearResistanceCounter = 'fear_resistance_event_count';
  static const String battleSenseCounter = 'battle_sense_event_count';

  // M8b hook 가산 산식 (per lv)
  static double resolveHookBonus({
    required String hook,
    required Map<String, int> hiddenStats,  // mercId의 hiddenStats Map
  }) {
    final fort = hiddenStats[fortitude] ?? 0;
    final gri = hiddenStats[grit] ?? 0;
    final luc = hiddenStats[luck] ?? 0;
    final fear = hiddenStats[fearResistance] ?? 0;
    final battle = hiddenStats[battleSense] ?? 0;

    switch (hook) {
      case 'death_resistance':
        return fort * 0.02;
      case 'despair_immune_chance':
        return gri * 0.08;
      case 'critical_rate':
        return luc * 0.01;
      case 'evasion':
        return luc * 0.01;
      case 'mez_immune_chance':
        return fear * 0.05;
      case 'strong_attack_evasion':
        return fear * 0.015;
      case 'action_score':
        return battle * 0.5;
      case 'featured_score':
        return battle * 0.2;
      case 'hit_chance':
        return battle * 0.01;
      default:
        return 0.0;
    }
  }

  // PassiveBonusService 통합 (per lv)
  static List<PassiveEffect> collectPassiveBonuses(Map<String, int> hiddenStats) {
    final result = <PassiveEffect>[];
    final fort = hiddenStats[fortitude] ?? 0;
    final gri = hiddenStats[grit] ?? 0;

    if (fort > 0) {
      result.add(PassiveEffect.recoveryTimeReduction(
        status: 'injured',
        value: fort * 0.04,
      ));
    }
    if (gri > 0) {
      result.add(PassiveEffect.reputationGainModifier(
        value: gri * 0.015,
      ));
    }
    // luck/fear/battle은 PassiveEffect 미통합
    return result;
  }

  // QuestCompletionService 후처리 (per lv)
  static double itemDropBonus(Map<String, int> hiddenStats) {
    final luc = hiddenStats[luck] ?? 0;
    return (luc * 0.005).clamp(0.0, 0.025);
  }

  // lv 임계 평가
  static const List<int> thresholds = [1, 3, 7, 15, 30];

  static int computeLevel(int counter) {
    int lv = 0;
    for (final t in thresholds) {
      if (counter >= t) {
        lv++;
      } else {
        break;
      }
    }
    return lv;
  }
}
