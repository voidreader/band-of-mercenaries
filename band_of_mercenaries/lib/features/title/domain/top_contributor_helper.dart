import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

/// "최근 24h 윈도우" 단순화 구현 (페이즈 4 #2 §5 Q-2):
/// activity log 휘발성 100개 + 별도 윈도우 추적 인프라 부재로,
/// 누적 success_count + great_success_count 1위 mercenary로 대체.
/// tie-break: recruitedAt 빠른 순.
String? compute24hTopContributor(Ref ref) {
  final mercList = ref.read(mercenaryListProvider);
  final aliveMercs =
      mercList.where((m) => m.status != MercenaryStatus.dead).toList();
  if (aliveMercs.isEmpty) return null;

  Mercenary? best;
  int bestScore = -1;
  DateTime bestRecruited = DateTime(9999);
  for (final m in aliveMercs) {
    final success = m.stats['success_count'] ?? 0;
    final greatSuccess = m.stats['great_success_count'] ?? 0;
    final score = success + greatSuccess;
    final recruited = m.recruitedAt ?? DateTime(2000);
    if (score > bestScore ||
        (score == bestScore && recruited.isBefore(bestRecruited))) {
      best = m;
      bestScore = score;
      bestRecruited = recruited;
    }
  }
  return best?.id;
}
