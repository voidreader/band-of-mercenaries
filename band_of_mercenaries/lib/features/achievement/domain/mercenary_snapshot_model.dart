import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

part 'mercenary_snapshot_model.g.dart';

@HiveType(typeId: 18)
class MercenarySnapshot {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String jobId;

  @HiveField(3)
  final String jobName;

  @HiveField(4)
  final int tier;

  /// 직함 ID 목록 (발급 시점 동결)
  @HiveField(5)
  final List<String> titleIds;

  const MercenarySnapshot({
    required this.id,
    required this.name,
    required this.jobId,
    required this.jobName,
    required this.tier,
    this.titleIds = const [],
  });

  /// Mercenary 객체에서 snapshot 생성. jobName과 tier는 외부에서 주입.
  /// 발급 시점의 job 정보를 영속 보존하기 위함.
  factory MercenarySnapshot.fromMercenary(
    Mercenary mercenary, {
    required String jobName,
    required int tier,
    List<String>? titleIds,
  }) =>
      MercenarySnapshot(
        id: mercenary.id,
        name: mercenary.name,
        jobId: mercenary.jobId,
        jobName: jobName,
        tier: tier,
        titleIds: List<String>.from(titleIds ?? mercenary.titleIds),
      );
}
