import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_event_data.dart';
import 'package:band_of_mercenaries/core/models/travel_choice_option_data.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

class TravelChoiceRecallData {
  final TravelChoiceEventData event;
  final List<TravelChoiceOptionData> visibleOptions;
  final List<TravelChoiceOptionData> hiddenOptions;
  final Mercenary protagonist;
  final String renderedSituation;

  const TravelChoiceRecallData({
    required this.event,
    required this.visibleOptions,
    required this.hiddenOptions,
    required this.protagonist,
    required this.renderedSituation,
  });
}

final pendingTravelChoiceProvider =
    StateProvider<TravelChoiceRecallData?>((_) => null);
