import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/title_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_provider.dart';

/// 정적 데이터 캐시에서 11종 칭호 데이터를 동기 접근.
/// staticDataProvider 로딩 완료 후 fallback 빈 리스트.
final titlesProvider = Provider<List<TitleData>>((ref) {
  return ref.watch(staticDataProvider).value?.titles ?? const [];
});

/// 특정 mercenary의 titleIds → TitleData 리스트 변환.
/// 미발견 ID는 silent skip (Supabase에서 삭제된 칭호 등).
final mercenaryTitlesProvider =
    Provider.family<List<TitleData>, String>((ref, mercId) {
  final mercList = ref.watch(mercenaryListProvider);
  final titles = ref.watch(titlesProvider);
  final merc = mercList.firstWhereOrNull((m) => m.id == mercId);
  if (merc == null) return const [];
  return merc.titleIds
      .map((id) => titles.firstWhereOrNull((t) => t.id == id))
      .whereType<TitleData>()
      .toList();
});
