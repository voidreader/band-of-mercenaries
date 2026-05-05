import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/timer_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_provider.dart';
import 'package:band_of_mercenaries/features/crafting/domain/crafting_service.dart';
import 'package:band_of_mercenaries/features/crafting/domain/recipe_filter_provider.dart';
import 'package:band_of_mercenaries/features/crafting/view/recipe_card.dart';

/// 레시피 목록 전체를 4계층 정렬·그룹 헤더·자동 필터 칩과 함께 렌더링한다.
class RecipeListSection extends ConsumerWidget {
  const RecipeListSection({
    super.key,
    required this.onClose,
  });

  /// RecipeCard의 [인벤토리에서 보기] → 대장간 닫기 콜백
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameTickProvider); // 1초마다 정렬 재평가 — recipeStateProvider stale 해소
    final recipes = ref.watch(craftingRecipesProvider);
    final filterMaterialId = ref.watch(recipeFilterMaterialIdProvider);
    final staticData = ref.watch(staticDataProvider).requireValue;
    final items = staticData.items;

    // 자동 필터: filterMaterialId가 설정된 경우 해당 재료를 사용하는 레시피만 노출
    final filteredRecipes = filterMaterialId == null
        ? recipes
        : recipes
            .where((r) => r.inputs.any((i) => i.itemId == filterMaterialId))
            .toList();

    // 결과물 ItemData 룩업 helper
    ItemData itemFor(String itemId) => items.firstWhere(
          (i) => i.id == itemId,
          orElse: () => throw ArgumentError('알 수 없는 itemId: $itemId'),
        );

    // 4계층 정렬 (ref.read로 정렬 시점 1회만 평가 — watch 금지)
    // 1. 상태 우선순위: ready < insufficient < locked
    // 2. 동 상태 내 slot 그룹 순서
    // 3. 동 그룹 내 결과물 tier 내림차순
    // 4. 동 tier 내 recipe.id 오름차순
    final sortedRecipes = [...filteredRecipes];
    sortedRecipes.sort((a, b) {
      final aState = ref.read(recipeStateProvider(a.id));
      final bState = ref.read(recipeStateProvider(b.id));
      final aStatePriority = _statePriority(aState);
      final bStatePriority = _statePriority(bState);
      if (aStatePriority != bStatePriority) return aStatePriority - bStatePriority;

      final aSlotOrder = _slotOrder(itemFor(a.resultItemId).slot);
      final bSlotOrder = _slotOrder(itemFor(b.resultItemId).slot);
      if (aSlotOrder != bSlotOrder) return aSlotOrder - bSlotOrder;

      final aTier = itemFor(a.resultItemId).tier;
      final bTier = itemFor(b.resultItemId).tier;
      if (aTier != bTier) return bTier - aTier; // tier desc

      return a.id.compareTo(b.id);
    });

    // 자동 필터 칩 (filterMaterialId 활성 시)
    Widget? filterChip;
    if (filterMaterialId != null) {
      final materialName = itemFor(filterMaterialId).name;
      filterChip = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Chip(label: Text('필터: $materialName 사용')),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () =>
                  ref.read(recipeFilterMaterialIdProvider.notifier).state = null,
              child: const Text('필터 해제'),
            ),
          ],
        ),
      );
    }

    // 그룹 헤더 삽입 — banner/artifact 슬롯만 헤더 표시, 그 외 없음
    final widgets = <Widget>[];
    if (filterChip != null) widgets.add(filterChip);

    String? prevSlot;
    for (final recipe in sortedRecipes) {
      final slot = itemFor(recipe.resultItemId).slot;
      if (slot != prevSlot) {
        if (slot == 'banner') {
          widgets.add(
            const RecipeGroupHeader(text: '용병단 깃발 (banner 1슬롯 — 양자택일)'),
          );
        } else if (slot == 'artifact') {
          widgets.add(
            const RecipeGroupHeader(
              text: '용병단 아티팩트 (artifact 2슬롯 — 동시 장착 가능)',
            ),
          );
        }
        prevSlot = slot;
      }
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RecipeCard(recipe: recipe, onClose: onClose),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 상태별 정렬 우선순위 — 낮을수록 상단 노출
  static int _statePriority(RecipeState state) {
    switch (state) {
      case RecipeState.ready:
        return 0;
      case RecipeState.insufficient:
        return 1;
      case RecipeState.locked:
        return 2;
    }
  }

  /// slot 문자열을 정렬 순서 정수로 변환 — material 등 미정의 슬롯은 후순위(99)
  static int _slotOrder(String slot) {
    const order = {
      'banner': 0,
      'weapon': 1,
      'armor': 2,
      'accessory': 3,
      'artifact': 4,
    };
    return order[slot] ?? 99;
  }
}

/// 슬롯 그룹 구분 헤더 — banner/artifact 슬롯 전환 시점에만 삽입된다.
class RecipeGroupHeader extends StatelessWidget {
  const RecipeGroupHeader({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.settlementAccent,
        ),
      ),
    );
  }
}
