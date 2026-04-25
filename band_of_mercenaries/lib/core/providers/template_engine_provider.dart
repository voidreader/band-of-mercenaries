import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:band_of_mercenaries/core/domain/template_engine.dart';

final templateEngineProvider = Provider<TemplateEngine>((ref) => const TemplateEngine());
