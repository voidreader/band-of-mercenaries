import 'dart:math';

import 'faction_reaction_data.dart';
import 'faction_relation_stage.dart';

/// M8a 세력 반응 텍스트 선택 헬퍼 (FR-A5)
///
/// factionId + relationStage 일치 후보 중 weight 가중 random 1개 반환.
/// 후보 0개면 null.
class FactionReactionPicker {
  const FactionReactionPicker._();

  /// [reactions] 중 factionId / relationStage / triggerType / triggerValue를 모두 만족하는
  /// 후보를 weight 가중 랜덤으로 1개 선택해 반환한다.
  ///
  /// - relationStage는 `'any'`도 매칭.
  /// - triggerType / triggerValue가 null이면 해당 조건은 무시한다.
  /// - 후보가 없으면 null을 반환한다.
  static FactionReaction? pickFor({
    required String factionId,
    required FactionRelationStage relationStage,
    required List<FactionReaction> reactions,
    String? triggerType,
    String? triggerValue,
    required Random random,
  }) {
    final stageName = relationStage.name;
    final candidates = <FactionReaction>[];

    for (final r in reactions) {
      if (r.factionId != factionId) continue;
      if (r.relationStage != stageName && r.relationStage != 'any') continue;
      if (triggerType != null && r.triggerType != triggerType) continue;
      if (triggerValue != null &&
          !_matchTriggerValue(r.triggerValue, triggerValue)) {
        continue;
      }
      candidates.add(r);
    }

    if (candidates.isEmpty) return null;

    final totalWeight = candidates.fold<int>(0, (sum, r) => sum + r.weight);
    if (totalWeight <= 0) return candidates.first;

    var roll = random.nextInt(totalWeight);
    for (final r in candidates) {
      roll -= r.weight;
      if (roll < 0) return r;
    }
    return candidates.last;
  }

  /// reactionValue 표기와 target 값 매칭.
  ///
  /// 지원 표기: 단일 값 / `*` 또는 `any` / `<N` (미만) / `a..b` (범위 포함)
  static bool _matchTriggerValue(String reactionValue, String target) {
    if (reactionValue == target) return true;
    if (reactionValue == '*' || reactionValue == 'any') return true;

    if (reactionValue.startsWith('<')) {
      final n = int.tryParse(reactionValue.substring(1));
      final t = int.tryParse(target);
      if (n != null && t != null) return t < n;
    }

    if (reactionValue.contains('..')) {
      final parts = reactionValue.split('..');
      if (parts.length == 2) {
        final lo = int.tryParse(parts[0]);
        final hi = int.tryParse(parts[1]);
        final t = int.tryParse(target);
        if (lo != null && hi != null && t != null) return t >= lo && t <= hi;
      }
    }

    return false;
  }
}
