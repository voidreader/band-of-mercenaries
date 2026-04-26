import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/models/dialog_request.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_data.dart';

/// 퀘스트 카드 좌측 사이드바 색상을 8단계 우선순위로 결정하는 Resolver.
class LayerSidebarResolver {
  /// 퀘스트 계층 정보로 사이드바 색상을 결정한다.
  /// null 반환 시 사이드바 생략.
  static Color? resolveColor(QuestLayerInfo info) {
    // 1. 체인 다음 단계 (금색)
    if (info.chain != null) return AppTheme.chainGold;
    // 2. 엘리트 유니크 (진보라)
    if (info.isElite && info.isUnique) return AppTheme.eliteUniqueBorder;
    // 3. 엘리트 보통 (주황)
    if (info.isElite) return AppTheme.eliteBorder;
    // 4~6. 변형 섹터 유형
    switch (info.sectorType) {
      case 'hidden':
        return AppTheme.transformHidden;
      case 'ruins':
        return AppTheme.transformRuins;
      case 'village':
        return AppTheme.transformVillage;
    }
    // 7. 세력 전용
    if (info.isFactionExclusive && info.faction != null) {
      return FactionData.parseColor(info.faction!.color);
    }
    // 8. 일반 — 사이드바 생략
    return null;
  }
}

/// 퀘스트 카드 좌측 3px 사이드바 위젯.
class LayerSidebar extends StatelessWidget {
  final QuestLayerInfo info;
  final double height;
  final BorderRadius? borderRadius;

  const LayerSidebar({
    super.key,
    required this.info,
    this.height = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final color = LayerSidebarResolver.resolveColor(info);
    if (color == null) return const SizedBox.shrink();
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
    );
  }
}
