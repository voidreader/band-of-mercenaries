import 'package:collection/collection.dart';
import 'package:band_of_mercenaries/core/models/passive_effect.dart';
import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

/// 한 mercenary의 titleIds로부터 PassiveEffect 리스트 합산.
/// 호출처: quest_completion_service / investigation_notifier 등 mercenary 단위 호출 (Q-10).
/// 용병단 단위 호출(app.dart idle / facility / movement / recruit)에는 미적용.
class MercenaryTitleEffects {
  static List<PassiveEffect> collectFor(Mercenary mercenary, List<TitleData> titles) {
    final result = <PassiveEffect>[];
    for (final id in mercenary.titleIds) {
      final title = titles.firstWhereOrNull((t) => t.id == id);
      if (title == null) continue;
      result.addAll(PassiveEffect.parseEffects(title.effectJson));
    }
    return result;
  }
}
