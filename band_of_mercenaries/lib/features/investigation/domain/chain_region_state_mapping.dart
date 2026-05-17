class ChainRegionStateEntry {
  final int regionId;
  final int delta;
  final String flag;

  const ChainRegionStateEntry({
    required this.regionId,
    required this.delta,
    required this.flag,
  });
}

const Map<String, ChainRegionStateEntry> chainRegionStateMapping = {
  'chain_roadside_shrine': ChainRegionStateEntry(
    regionId: 31,
    delta: -20,
    flag: 'region_31_shrine_quest_completed',
  ),
  'chain_windrunner_trail': ChainRegionStateEntry(
    regionId: 10,
    delta: -30,
    flag: 'region_10_windrunner_chain_completed',
  ),
  'chain_ironbound_pact': ChainRegionStateEntry(
    regionId: 38,
    delta: -40,
    flag: 'region_38_ironbound_pact_completed',
  ),
  'chain_m7_mist_clearing': ChainRegionStateEntry(
    regionId: 146,
    delta: -50,
    flag: 'region_146_mist_cleared',
  ),
  'settlement_3_pyegwang_reopen': ChainRegionStateEntry(
    regionId: 3,
    delta: -30,
    flag: 'region_3_pyegwang_reopen_completed',
  ),
};
