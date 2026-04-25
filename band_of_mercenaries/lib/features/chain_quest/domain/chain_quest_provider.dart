import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/chain_quest/data/chain_quest_repository.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_progress.dart';
import 'package:band_of_mercenaries/features/chain_quest/domain/chain_quest_service.dart';

final chainQuestServiceProvider = Provider<ChainQuestService>((ref) {
  return ChainQuestService(ref.watch(chainQuestRepositoryProvider));
});

final chainQuestProgressProvider = StreamProvider<List<ChainQuestProgress>>((ref) {
  return ref.watch(chainQuestRepositoryProvider).watchAll();
});

final activeChainProvider = Provider<ChainQuestProgress?>((ref) {
  final progresses = ref.watch(chainQuestProgressProvider).valueOrNull ?? [];
  final active = progresses.where((p) => p.status == ChainQuestStatus.active).toList();
  if (active.isEmpty) return null;
  final sorted = [...active]
    ..sort((a, b) {
      final aTime = a.currentStepAvailableAt;
      final bTime = b.currentStepAvailableAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return -1;
      if (bTime == null) return 1;
      return aTime.compareTo(bTime);
    });
  return sorted.first;
});

final chainCompletedProvider = StateProvider<ChainCompletedEvent?>((ref) => null);
