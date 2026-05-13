import 'package:hive/hive.dart';

part 'memorial_cause.g.dart';

@HiveType(typeId: 19)
enum MemorialCause {
  @HiveField(0)
  diedQuest,

  @HiveField(1)
  diedEvent,

  @HiveField(2)
  released,
}
