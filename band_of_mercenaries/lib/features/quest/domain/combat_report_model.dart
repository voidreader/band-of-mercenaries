import 'package:hive/hive.dart';

part 'combat_report_model.g.dart';

@HiveType(typeId: 21)
class CombatReport extends HiveObject {
  @HiveField(0)
  String summary;

  @HiveField(1)
  List<String> details;

  @HiveField(2)
  int seed;

  @HiveField(3)
  String? protagonistMercId;

  @HiveField(4)
  List<String> featuredMercIds;

  @HiveField(5)
  List<String> toneTags;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  List<String> templateIds;

  CombatReport({
    required this.summary,
    required this.details,
    required this.seed,
    this.protagonistMercId,
    required this.featuredMercIds,
    required this.toneTags,
    required this.createdAt,
    required this.templateIds,
  });
}
