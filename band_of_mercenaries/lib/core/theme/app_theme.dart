import 'package:flutter/material.dart';

class AppTheme {
  // Base colors
  static const Color primary = Color(0xFF1A1A1A);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAFAFA);
  static const Color border = Color(0xFFDDDDDD);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF444444);
  static const Color textTertiary = Color(0xFF555555);
  static const Color textHint = Color(0xFF666666);

  // Tier colors
  static const Color tier1 = Color(0xFF666666);
  static const Color tier2 = Color(0xFF2E7D32);
  static const Color tier3 = Color(0xFF1565C0);
  static const Color tier4 = Color(0xFF6A1B9A);
  static const Color tier5 = Color(0xFFC62828);

  static const Color tier1Bg = Color(0xFFF0F0F0);
  static const Color tier2Bg = Color(0xFFE8F5E9);
  static const Color tier3Bg = Color(0xFFE3F2FD);
  static const Color tier4Bg = Color(0xFFF3E5F5);
  static const Color tier5Bg = Color(0xFFFFEBEE);

  // Trait category colors
  static const Map<String, Color> traitCategoryColors = {
    'Physical': Color(0xFF2E7D32),     // 초록
    'Background': Color(0xFF795548),   // 갈색
    'Talent': Color(0xFFFF8F00),       // 금색
    'CombatStyle': Color(0xFFC62828),  // 빨강
    'Survival': Color(0xFF1565C0),     // 파랑
    'Behavior': Color(0xFF6A1B9A),     // 보라
    'Mental': Color(0xFF00838F),       // 청록
    'Experience': Color(0xFFEF6C00),   // 주황
  };

  // 지역 변형 타입 색상
  static const Color transformVillage = Color(0xFF2E7D32);    // 마을 (초록)
  static const Color transformRuins = Color(0xFF6A1B9A);      // 유적지 (보라)
  static const Color transformHidden = Color(0xFFB8860B);     // 숨겨진 섹터 (어두운 금)
  static const Color transformFallback = Color(0xFF9E9E9E);   // 알 수 없는 변형 (회색)

  // M4 섹터 타입 색상 (MovementScreen 그리드 한정 — LayerSidebar/QuestCardBadges에는 미반영)
  static const Color sectorDungeon = Color(0xFFB71C1C); // dungeon (위험 적갈색)
  static const Color sectorField = Color(0xFF558B2F);   // field (평온 녹색)

  // Chain quest colors
  static const Color chainGold = Color(0xFFD4AF37);           // 연계 퀘스트 금색

  // Elite monster colors
  static const Color eliteAccent = Color(0xFFFB923C);         // 엘리트 보통 이름색 (주황)
  static const Color eliteUniqueAccent = Color(0xFFC084FC);   // 엘리트 유니크 이름색 (보라)
  static const Color eliteBg = Color(0xFF1a0d00);
  static const Color eliteUniqueBg = Color(0xFF1a0028);
  static const Color eliteBorder = Color(0xFFe65100);
  static const Color eliteUniqueBorder = Color(0xFF7b1fa2);

  // Quest result colors
  static const Color greatSuccess = Color(0xFF1565C0);
  static const Color success = Color(0xFF2E7D32);
  static const Color failure = Color(0xFFE65100);
  static const Color criticalFailure = Color(0xFFC62828);

  static const Color greatSuccessBg = Color(0xFFE3F2FD);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color failureBg = Color(0xFFFFF3E0);
  static const Color criticalFailureBg = Color(0xFFFFEBEE);

  // Timer accent
  static const Color timerBlue = Color(0xFF1565C0);

  static Color tierColor(int tier) {
    switch (tier) {
      case 1: return tier1;
      case 2: return tier2;
      case 3: return tier3;
      case 4: return tier4;
      case 5: return tier5;
      default: return tier1;
    }
  }

  static Color tierBgColor(int tier) {
    switch (tier) {
      case 1: return tier1Bg;
      case 2: return tier2Bg;
      case 3: return tier3Bg;
      case 4: return tier4Bg;
      case 5: return tier5Bg;
      default: return tier1Bg;
    }
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceAlt,
      selectedItemColor: primary,
      unselectedItemColor: textHint,
      selectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: borderLight),
      ),
    ),
  );
}
