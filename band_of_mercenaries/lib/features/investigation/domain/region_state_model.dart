import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/features/investigation/domain/danger_level.dart';

part 'region_state_model.g.dart';

@HiveType(typeId: 8)
class RegionState extends HiveObject {
  @HiveField(0)
  int regionId;

  @HiveField(1)
  int knowledge; // 0~100

  @HiveField(2)
  List<String> triggeredDiscoveries; // 트리거된 discovery ID 목록

  @HiveField(3)
  Map<String, String> sectorChanges; // 섹터 변환 상태 (key는 0-based('0'~'9'), region_sectors.sector_index는 1-based(1..6) — 변환 시 -1/+1. value: "village"|"ruins"|"hidden")

  @HiveField(4)
  int? settlementTrust; // 마을 신뢰도 누적 점수. null=0 fallback

  @HiveField(5)
  int? settlementTrustLevel; // 마을 신뢰도 단계(1~4) 캐시. null=1 fallback

  @HiveField(6)
  DateTime? lastEventCompletedAt;

  /// M5 페이즈 4 #3 - 재료 첫 입수 영속 추적
  @HiveField(7)
  List<String> firstAcquiredMaterialIds;

  /// M7 페이즈 4 #1 — 위험도 점수 (-100 ~ +100, clamp)
  @HiveField(8)
  int? dangerScore;

  /// M7 페이즈 4 #1 — 위험도 단계 캐시 (1=stable 2=peaceful 3=tension 4=threat)
  @HiveField(9)
  int? dangerLevel;

  /// M7 페이즈 4 #1 — 해금 상태 영속 플래그
  @HiveField(10)
  List<String> unlockedFlags;

  /// M7 페이즈 4 #2 — quest_pool별 region 내 누적 완료 횟수
  @HiveField(11)
  Map<String, int> questPoolCompletionCounts;

  /// M7 페이즈 4 #4 — 마을 인프라 단계 (1~4, region 3 한정)
  @HiveField(12)
  int? infrastructureTier;

  int get currentTrust => settlementTrust ?? 0;
  int get currentTrustLevel => settlementTrustLevel ?? 1;
  int get currentDangerScore => dangerScore ?? 0;
  int get currentDangerLevel => dangerLevel ?? DangerLevelResolver.resolveLevel(currentDangerScore).cacheInt;
  bool hasFlag(String flag) => unlockedFlags.contains(flag);
  int get currentInfrastructureTier => infrastructureTier ?? 1;

  bool get eventCompletedRecently =>
      lastEventCompletedAt != null &&
      DateTime.now().difference(lastEventCompletedAt!) <= const Duration(hours: 24);

  RegionState({
    required this.regionId,
    this.knowledge = 0,
    List<String>? triggeredDiscoveries,
    Map<String, String>? sectorChanges,
    this.settlementTrust,
    this.settlementTrustLevel,
    this.lastEventCompletedAt,
    List<String>? firstAcquiredMaterialIds,
    this.dangerScore,
    this.dangerLevel,
    List<String>? unlockedFlags,
    Map<String, int>? questPoolCompletionCounts,
    this.infrastructureTier,
  })  : triggeredDiscoveries = triggeredDiscoveries ?? [],
        sectorChanges = sectorChanges ?? {},
        firstAcquiredMaterialIds = firstAcquiredMaterialIds ?? [],
        unlockedFlags = unlockedFlags ?? [],
        questPoolCompletionCounts = questPoolCompletionCounts ?? {};
}
