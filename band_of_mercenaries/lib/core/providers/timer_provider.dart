import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final speedMultiplierProvider = StateProvider<double>((ref) => 1.0);

final gameTickProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});
