import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/features/investigation/domain/investigation_result.dart';

final investigationCompletedProvider = StateProvider<InvestigationResult?>((ref) => null);
