import 'package:band_of_mercenaries/features/mercenary/domain/trait_evolution_service.dart';

/// 트레잇 진화 다이얼로그에서 플레이어가 선택한 진화 경로.
/// view(`TraitEvolutionDialog`)가 생성하고 domain(`MercenaryListNotifier.applyEvolution`)이 소비한다.
class EvolutionChoice {
  final bool isSingle;
  final SingleEvolutionCandidate? single;
  final ComboEvolutionCandidate? combo;

  EvolutionChoice.fromSingle(SingleEvolutionCandidate c)
      : isSingle = true,
        single = c,
        combo = null;

  EvolutionChoice.fromCombo(ComboEvolutionCandidate c)
      : isSingle = false,
        single = null,
        combo = c;
}
