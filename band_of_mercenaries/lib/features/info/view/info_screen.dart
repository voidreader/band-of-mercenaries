import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/info/data/faction_state_repository.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_codex_providers.dart';
import 'package:band_of_mercenaries/features/info/view/faction_codex_screen.dart';
import 'package:band_of_mercenaries/features/info/view/faction_detail_screen.dart';

class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  bool _showCodex = false;
  String? _selectedFactionId;

  @override
  Widget build(BuildContext context) {
    // factionCodexScrollTargetProvider가 non-null이면 자동으로 도감 화면으로 전환
    final scrollTarget = ref.watch(factionCodexScrollTargetProvider);
    if (scrollTarget != null && !_showCodex && _selectedFactionId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showCodex = true);
      });
    }

    if (_selectedFactionId != null) {
      return FactionDetailScreen(
        factionId: _selectedFactionId!,
        onBack: () => setState(() => _selectedFactionId = null),
      );
    }

    if (_showCodex) {
      return FactionCodexScreen(
        onBack: () => setState(() => _showCodex = false),
        onSelectFaction: (id) => setState(() => _selectedFactionId = id),
      );
    }

    final repo = ref.read(factionStateRepositoryProvider);
    final allStates = repo.getAll();
    final discoveredCount =
        allStates.where((s) => s.clueRecords.isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Text(
            '정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book, color: AppTheme.textPrimary),
                title: const Text(
                  '세력 도감',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '발견한 세력: $discoveredCount',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textHint,
                ),
                onTap: () => setState(() => _showCodex = true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
