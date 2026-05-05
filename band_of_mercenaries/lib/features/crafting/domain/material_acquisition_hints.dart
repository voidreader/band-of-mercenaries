/// 재료 12종 출처 힌트 (인벤토리 펼침 + 부족 재료 펼침에서 표시).
/// 텍스트 출처: design-content-dustvile-craft-ui.md §1-6
const Map<String, String> materialAcquisitionHints = {
  'mat_ore_rusty_scrap':               // 녹슨 쇳조각
      '폐광 labor 의뢰에서 주로 얻습니다. 폐광 일반 조사(지식 25)에서도 발견됩니다.',
  'mat_hide_dry_strap':                // 마른 가죽끈
      '마른 초원 hunt·도적 의뢰의 주요 보상입니다.',
  'mat_herb_dry':                      // 마른 약초
      '마른 초원 채집 의뢰에서 얻습니다.',
  'mat_herb_mountain_mushroom':        // 산기슭 버섯
      '마른 초원 채집 의뢰에서 얻습니다. 야간 순찰 중에도 발견됩니다.',
  'mat_herb_dust_resin':               // 접착 수액 (더스트빌 한정)
      '약초상 채집 의뢰(신뢰도 2단계 이후)에서 얻습니다. 더스트빌 한정.',
  'mat_hide_faded_cloth':              // 빛바랜 천 조각
      '신뢰도 2단계 진입 보상으로 1회 입수합니다. 광장 허드렛일에서 드물게 재입수 가능.',
  'mat_relic_pyegwang_pickaxe_head':   // 녹슨 곡괭이 머리 (더스트빌 한정)
      '폐광 입구 정찰 사건(step 1) 보상입니다. 더스트빌 한정.',
  'mat_relic_pyegwang_shard':          // 폐광의 유물 파편 (더스트빌 한정)
      '폐광 숨겨진 발견(지식 50) 또는 사건 단계 보상에서 얻습니다. 더스트빌 한정.',
  'mat_monster_giant_bat_fang':        // 거대 박쥐 송곳니
      '폐광 박쥐 둥지의 거대 박쥐(엘리트) 처치만이 입수 경로입니다.',
  'mat_relic_ancient_seal_piece':      // 고대 인장 조각 (더스트빌 한정)
      '폐광 재개방식 클라이맥스(step 6) 보상으로만 얻습니다. 더스트빌 한정.',
  'mat_hide_rough_bundle':             // 거친 가죽끈 묶음 (중간재)
      '낡은 대장간에서 마른 가죽끈 3개를 정제하여 제작합니다.',
  'mat_ore_polished_scrap':            // 연마된 쇳조각 (중간재)
      '낡은 대장간에서 녹슨 쇳조각 4개를 연마하여 제작합니다.',
};

/// slot 5종 출처 가이드 (빈 인벤토리에서 표시).
/// 텍스트 출처: design-content-dustvile-craft-ui.md §5-1
const Map<String, String> materialSlotGuides = {
  'material_ore':
      '폐광 labor 의뢰·폐광 일반 조사에서 얻습니다.',
  'material_hide':
      '마른 초원 hunt 의뢰·도적 의뢰에서 얻습니다.',
  'material_herb':
      '마른 초원 채집 의뢰·약초상 채집 의뢰(신뢰도 2 이후)에서 얻습니다.',
  'material_relic_fragment':
      '폐광 숨겨진 발견·폐광 사건 단계 보상에서 얻습니다.',
  'material_monster_part':
      '거대 박쥐 등 엘리트 처치 보상에서 얻습니다.',
};
