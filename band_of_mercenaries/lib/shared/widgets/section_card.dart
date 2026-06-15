import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

/// 섹션 카드 — 헤더 + 본문 슬롯 구조.
/// AppTheme.surfaceAlt 배경 + AppTheme.borderLight 보더 + radius 8 기준.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.padding,
    this.margin,
    this.color,
  });

  final String? title;       // 섹션 헤더 타이틀 텍스트 (null이면 헤더 미표시)
  final Widget? trailing;    // 헤더 trailing 위젯
  final Widget child;        // 본문
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(title!, style: AppTheme.sectionTitle),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}
