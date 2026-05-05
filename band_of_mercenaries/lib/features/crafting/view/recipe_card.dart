import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/crafting_recipe_data.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/providers/navigation_provider.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_service.dart';
import 'package:band_of_mercenaries/features/crafting/domain/material_acquisition_hints.dart';
import 'package:band_of_mercenaries/features/crafting/domain/material_jump_provider.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';

/// 레시피 1건 카드 — locked / insufficient / ready 4상태를 시각적으로 분기한다.
class RecipeCard extends ConsumerStatefulWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onClose,
  });

  final CraftingRecipeData recipe;
  final VoidCallback onClose;

  @override
  ConsumerState<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends ConsumerState<RecipeCard> {
  bool _isCrafting = false;
  bool _isExpanded = false;

  String _formatUnlockCondition(RecipeUnlockCondition? cond) {
    if (cond == null) return '';
    if (cond.trustLevel != null) return '마을 신뢰도 ${cond.trustLevel}단계 도달 시';
    if (cond.chainStep != null) return '폐광 재개방 사건 step ${cond.chainStep!.step} 완료';
    if (cond.firstAcquiredItem != null) return '첫 입수 후 해금';
    return '';
  }

  Future<void> _onCraftPressed() async {
    if (_isCrafting) return;
    setState(() => _isCrafting = true);

    final service = ref.read(craftingServiceProvider);
    final result = await service.craft(widget.recipe.id);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (result is CraftingSuccess) {
      final staticData = ref.read(staticDataProvider).requireValue;
      final resultItem = staticData.items.firstWhere(
        (i) => i.id == widget.recipe.resultItemId,
        orElse: () => throw ArgumentError('알 수 없는 resultItemId: ${widget.recipe.resultItemId}'),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('${resultItem.name} 제작 완료 ✨'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } else if (result is CraftingFailure) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('재료 부족'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    setState(() => _isCrafting = false);
  }

  void _onJumpToInventory(String materialItemId) {
    ref.read(materialJumpTargetItemIdProvider.notifier).state = materialItemId;
    // 현재 탭에 관계없이 InfoScreen이 build되도록 인벤토리 탭(5)으로 전환
    ref.read(currentTabProvider.notifier).state = 5;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipeStateProvider(widget.recipe.id));
    final repo = ref.watch(inventoryRepositoryProvider);
    final staticData = ref.watch(staticDataProvider).requireValue;
    final itemMap = {for (final i in staticData.items) i.id: i};

    return _buildCard(state, repo, itemMap);
  }

  Widget _buildCard(RecipeState state, InventoryRepository repo, Map<String, ItemData> itemMap) {
    if (state == RecipeState.locked) {
      return Opacity(
        opacity: 0.5,
        child: _LockedCardContent(recipe: widget.recipe, formatter: _formatUnlockCondition),
      );
    }

    if (state == RecipeState.insufficient) {
      return Opacity(
        opacity: 0.6,
        child: _buildInsufficientCard(repo, itemMap),
      );
    }

    return _buildReadyCard(repo, itemMap);
  }

  Widget _buildInsufficientCard(InventoryRepository repo, Map<String, ItemData> itemMap) {
    return Card(
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecipeHeader(recipe: widget.recipe),
              const SizedBox(height: 8),
              ..._buildInputRows(repo, itemMap),
              if (_isExpanded) ...[
                const Divider(height: 16),
                _buildShortfallHints(repo, itemMap),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  child: const Text('제작'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyCard(InventoryRepository repo, Map<String, ItemData> itemMap) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.tier2Bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '제작 가능',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tier2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _RecipeHeader(recipe: widget.recipe),
            const SizedBox(height: 8),
            ..._buildInputRows(repo, itemMap),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tier2,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isCrafting ? null : _onCraftPressed,
                child: _isCrafting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('제작'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInputRows(InventoryRepository repo, Map<String, ItemData> itemMap) {
    return widget.recipe.inputs.map((input) {
      final held = repo.getQuantityForItemId(input.itemId);
      final isSufficient = held >= input.quantity;
      final color = isSufficient ? AppTheme.tier2 : AppTheme.dangerRed;
      final icon = isSufficient ? Icons.check : Icons.close;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                itemMap[input.itemId]?.name ?? input.itemId,
                style: TextStyle(fontSize: 12, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$held/${input.quantity}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildShortfallHints(InventoryRepository repo, Map<String, ItemData> itemMap) {
    final shortfallInputs = widget.recipe.inputs.where((input) {
      final held = repo.getQuantityForItemId(input.itemId);
      return held < input.quantity;
    }).toList();

    if (shortfallInputs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shortfallInputs.map((input) {
        final hint = materialAcquisitionHints[input.itemId];
        final itemName = itemMap[input.itemId]?.name ?? input.itemId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  hint ?? '$itemName — 출처 정보 없음',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _onJumpToInventory(input.itemId),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppTheme.tier3,
                ),
                child: const Text(
                  '인벤토리에서 보기',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecipeHeader extends StatelessWidget {
  const _RecipeHeader({required this.recipe});

  final CraftingRecipeData recipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        if (recipe.description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            recipe.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _LockedCardContent extends StatelessWidget {
  const _LockedCardContent({
    required this.recipe,
    required this.formatter,
  });

  final CraftingRecipeData recipe;
  final String Function(RecipeUnlockCondition?) formatter;

  @override
  Widget build(BuildContext context) {
    final conditionText = formatter(recipe.unlockCondition);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '???',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.lock, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    conditionText.isNotEmpty ? conditionText : '해금 조건 미충족',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
