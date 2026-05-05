import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 인벤토리 → 대장간 점프 시 자동 필터 컨텍스트.
/// 재료 itemId가 들어가면 RecipeListSection이 해당 재료 사용 레시피만 노출.
final recipeFilterMaterialIdProvider = StateProvider<String?>((ref) => null);
