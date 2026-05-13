import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/achievement/domain/mercenary_snapshot_model.dart';

part 'band_achievement_model.g.dart';

@HiveType(typeId: 17)
enum BandAchievementType {
  @HiveField(0)
  achievement,

  @HiveField(1)
  memorial,
}

@HiveType(typeId: 16)
class BandAchievement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final BandAchievementType type;

  @HiveField(2)
  final DateTime achievedAt;

  @HiveField(3)
  final String templateId;

  @HiveField(4)
  final MercenarySnapshot? mercSnapshot;

  @HiveField(5)
  final int? regionId;

  @HiveField(6)
  final Map<String, dynamic> payload;

  BandAchievement({
    required this.id,
    required this.type,
    required this.achievedAt,
    required this.templateId,
    this.mercSnapshot,
    this.regionId,
    this.payload = const {},
  });
}
