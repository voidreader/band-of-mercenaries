import 'package:flutter/material.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final double fontSize;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(fontSize: fontSize, color: AppTheme.textHint),
      ),
    );
  }
}
