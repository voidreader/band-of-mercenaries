import 'package:band_of_mercenaries/core/models/region_sector.dart';

/// region_sectors 시드 데이터 부재 시 사용되는 fallback 정적 클래스.
///
/// 시드가 후속 페이즈에서 일괄 배포되기 전까지 게임 첫 실행을 보장하기 위해
/// 더스트플레인(region 3) 4섹터를 코드 상수로 보유한다. staticData가 시드를
/// 보유한 후에는 자동으로 비활성화(staticData 우선).
class RegionSectorFallback {
  /// 더스트플레인(region 3) 4섹터 fallback.
  /// 기획 문서 [content]20260503_starting-settlement.md 1.2~1.3절 데이터를 그대로 인라인.
  static const List<RegionSector> dustplainSectors = [
    RegionSector(
      id: 'r3_s1',
      regionId: 3,
      sectorIndex: 1,
      name: '더스트빌',
      sectorType: 'village',
      environmentTags: ['mountain', 'village'],
      description: '산기슭의 작은 마을. 흙벽 집들이 광장을 둘러싸고 있고, 촌장 집·낡은 대장간·약초상이 한 자리에 모여 있다. 마을 사람들은 외지인을 의심스럽게 본다.',
    ),
    RegionSector(
      id: 'r3_s2',
      regionId: 3,
      sectorIndex: 2,
      name: '폐광',
      sectorType: 'dungeon',
      environmentTags: ['mountain', 'dungeon'],
      description: '한때 마을의 생계였던 광산. 지금은 입구가 무너져 있고 박쥐와 도굴꾼이 자리 잡았다. 마을 사람들이 가장 두려워하는 곳이지만, 가장 중요한 사건이 시작되는 곳이기도 하다.',
    ),
    RegionSector(
      id: 'r3_s3',
      regionId: 3,
      sectorIndex: 3,
      name: '마른 초원',
      sectorType: 'field',
      environmentTags: ['mountain', 'plains'],
      description: '마을 외곽의 거친 풀밭. 약초 무리와 들개 흔적이 섞여 있다. 신참 용병이 처음 가는 곳이며, 야간이면 마을 경계가 약해져 순찰 의뢰가 자주 나온다.',
    ),
    RegionSector(
      id: 'r3_s4',
      regionId: 3,
      sectorIndex: 4,
      name: '먼지로 덮인 길',
      sectorType: 'field',
      environmentTags: ['mountain', 'road'],
      description: '외부와 더스트플레인을 잇는 유일한 산길. 흙먼지가 발자국을 덮어버리는 곳이다. 호위가 필요한 행상이나 외지에서 온 여행자가 자주 마주친다.',
    ),
  ];

  /// staticData → fallback(region 3 한정) → null 우선순위로 RegionSector 조회.
  ///
  /// 시드 데이터가 우선되며, region 3에 한해 더스트플레인 fallback이 보조한다.
  /// 그 외 region은 시드 부재 시 null 반환 — 호출자가 sector_type 표시를 생략한다.
  static RegionSector? lookupSector(
    int regionId,
    int sectorIndex,
    List<RegionSector> regionSectors,
  ) {
    final fromData = regionSectors
        .where((s) => s.regionId == regionId && s.sectorIndex == sectorIndex)
        .firstOrNull;
    if (fromData != null) return fromData;
    if (regionId == 3) {
      return dustplainSectors
          .where((s) => s.sectorIndex == sectorIndex)
          .firstOrNull;
    }
    return null;
  }
}
