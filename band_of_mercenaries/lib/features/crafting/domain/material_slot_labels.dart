/// 재료 slot 5종 → 한국어 라벨 매핑.
const Map<String, String> materialSlotLabels = {
  'material_ore': '광석',
  'material_hide': '가죽',
  'material_herb': '약초',
  'material_relic_fragment': '유물 파편',
  'material_monster_part': '몬스터 부산물',
};

/// 알 수 없는 slot은 raw key 반환.
String materialSlotLabelOf(String slot) => materialSlotLabels[slot] ?? slot;
