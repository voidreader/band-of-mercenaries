# UI 폴리싱 1차 + 이미지 에셋 적용 개발 명세서

> 기획 문서: `Docs/content-design/[content]20260614_m8.5_ui_polish_image_assets.md`
> 작성일: 2026-06-14
> 마일스톤: M8.5 페이즈 4 #5

---

## 1. 개요

현재 코드베이스에 `Image.network` / `Image.asset` / `NetworkImage` / `AssetImage` / `CachedNetworkImage` 사용처가 **전무**하다. 모든 시각 요소가 이모지와 `campsite_painter`(`CustomPainter`)에 의존한다. 본 명세는 두 가지 작업을 동시에 완료한다.

1. **이미지 인프라 신설** — `image_assets` 테이블(정적 데이터 43번째 테이블), freezed 모델 `ImageAsset`, `StaticGameData.imageAssets` 필드, `SyncService`/`DataLoader` 편입, 재사용 위젯 `GameImage`(fallback-first 설계).
2. **UI 폴리싱 1차** — 홈/파견/이동/제작·인벤토리/정보 4+1 화면에 이미지 슬롯 4종 배치 + 카드 위계 3단계 통일(`SectionCard` 신규) + 홈 스크롤 영역 의미 그룹 재정렬 + AppTheme 토큰 추가 + 문서 테마 표기 정정.

**M8.5 시점 전 URL NULL 정책**: `image_assets`의 모든 행이 `url = NULL`이므로, 코드 실행 시 100% fallback 경로(이모지+색상 박스)로 동작한다. M9 디자인 작업 시 DB의 `url`만 UPDATE하면 코드·앱 배포 없이 이미지가 노출된다.

**`cached_network_image` 패키지 도입 보류 결정**: 전 URL NULL인 현 상태에서 네트워크 캐싱 레이어는 불필요하다. 기본 `Image.network` + `errorBuilder`로 시작하고, M9 실제 이미지 도입 시 재검토한다. `pubspec.yaml` 수정 없음.

---

## 2. 요구사항

### 2.1 기능 요구사항 (FR)

#### FR-A1: `image_assets` 테이블 정의 및 SQL 블록

`image_assets` 테이블을 신설한다. 실제 Supabase 적용은 별도 승인 후 진행한다.

```sql
-- =============================================
-- image_assets 테이블 신설 (M8.5 페이즈 4 #5)
-- Supabase 적용은 별도 승인 대기
-- =============================================
CREATE TABLE image_assets (
  asset_key        TEXT PRIMARY KEY,
  category         TEXT NOT NULL CHECK (category IN (
                     'region_thumbnail',
                     'faction_emblem',
                     'item_icon',
                     'dashboard_metric_icon',
                     'livingsphere_background'
                   )),
  entity_id        TEXT NULL,
  url              TEXT NULL,
  width            INT NULL,
  height           INT NULL,
  fallback_emoji   TEXT NULL,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- data_versions 등록 (M9 URL UPDATE 시 version 증가 필수)
INSERT INTO data_versions (table_name, version) VALUES ('image_assets', 1)
  ON CONFLICT (table_name) DO NOTHING;

-- =============================================
-- 최소 placeholder INSERT (M8.5 — 전 url NULL)
-- =============================================

-- 6지표 아이콘 (dashboard_metric_icon) — 6행
INSERT INTO image_assets (asset_key, category, entity_id, url, width, height, fallback_emoji) VALUES
  ('dashboard_metric_stability',      'dashboard_metric_icon', 'stability',      NULL, 96, 96, '🛡'),
  ('dashboard_metric_infrastructure', 'dashboard_metric_icon', 'infrastructure', NULL, 96, 96, '🏘'),
  ('dashboard_metric_event',          'dashboard_metric_icon', 'eventCompletion',NULL, 96, 96, '📜'),
  ('dashboard_metric_resource',       'dashboard_metric_icon', 'resourceCraft',  NULL, 96, 96, '📦'),
  ('dashboard_metric_influence',      'dashboard_metric_icon', 'influence',      NULL, 96, 96, '🔱'),
  ('dashboard_metric_achievement',    'dashboard_metric_icon', 'achievement',    NULL, 96, 96, '★');

-- 생활권 배경 (livingsphere_background) — 1행
INSERT INTO image_assets (asset_key, category, entity_id, url, width, height, fallback_emoji) VALUES
  ('livingsphere_bg_dustplain', 'livingsphere_background', NULL, NULL, 1024, 512, '🏕');

-- M7 핵심 7리전 지역 썸네일 (region_thumbnail) — 7행
-- entity_id는 region INTEGER를 TEXT로 저장
INSERT INTO image_assets (asset_key, category, entity_id, url, width, height, fallback_emoji) VALUES
  ('region_thumb_3',   'region_thumbnail', '3',   NULL, 512, 288, '🗺'),
  ('region_thumb_31',  'region_thumbnail', '31',  NULL, 512, 288, '🗺'),
  ('region_thumb_127', 'region_thumbnail', '127', NULL, 512, 288, '🗺'),
  ('region_thumb_9',   'region_thumbnail', '9',   NULL, 512, 288, '🗺'),
  ('region_thumb_10',  'region_thumbnail', '10',  NULL, 512, 288, '🗺'),
  ('region_thumb_146', 'region_thumbnail', '146', NULL, 512, 288, '🗺'),
  ('region_thumb_38',  'region_thumbnail', '38',  NULL, 512, 288, '🗺');

-- 대표 3세력 엠블럼 (faction_emblem) — 3행
-- entity_id는 faction.id (TEXT)
INSERT INTO image_assets (asset_key, category, entity_id, url, width, height, fallback_emoji) VALUES
  ('faction_emblem_adventurer_guild', 'faction_emblem', 'adventurer_guild', NULL, 128, 128, '🔱'),
  ('faction_emblem_merchant_league',  'faction_emblem', 'merchant_league',  NULL, 128, 128, '🔱'),
  ('faction_emblem_warrior_order',    'faction_emblem', 'warrior_order',    NULL, 128, 128, '🔱');

-- item_icon: 카테고리 fallback으로 충분하므로 0행 시작 (M9에서 추가)
```

> 합계 17행. 실제 faction id는 Supabase `factions` 테이블의 실제 키로 확인 후 조정 필요 (Q-1 참조).

---

#### FR-A2: `ImageAsset` freezed 모델 신설

**파일**: `band_of_mercenaries/lib/core/models/image_asset.dart` (신규)

```dart
// M8.5 페이즈 4 #5 — ImageAsset 정적 카탈로그 모델
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_asset.freezed.dart';
part 'image_asset.g.dart';

@freezed
class ImageAsset with _$ImageAsset {
  const factory ImageAsset({
    @JsonKey(name: 'asset_key') required String assetKey,
    required String category,
    @JsonKey(name: 'entity_id') String? entityId,
    String? url,
    int? width,
    int? height,
    @JsonKey(name: 'fallback_emoji') String? fallbackEmoji,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _ImageAsset;

  factory ImageAsset.fromJson(Map<String, dynamic> json) =>
      _$ImageAssetFromJson(json);
}
```

`build_runner build` 실행 후 `image_asset.freezed.dart` / `image_asset.g.dart` 자동 생성.

---

#### FR-A3: `StaticGameData` + `staticDataProvider` 편입

패턴 참조: 기존 `hidden_stats` / `battle_memory_templates` 편입 방식과 완전히 동일하다.

**수정 파일**: `band_of_mercenaries/lib/core/providers/static_data_provider.dart`

1. import 추가:
   ```dart
   import 'package:band_of_mercenaries/core/models/image_asset.dart'; // M8.5 페이즈 4 #5 추가
   ```

2. `StaticGameData` 클래스에 필드 추가:
   ```dart
   final List<ImageAsset> imageAssets; // M8.5 페이즈 4 #5 추가
   ```

3. 생성자 파라미터 추가:
   ```dart
   required this.imageAssets, // M8.5 페이즈 4 #5 추가
   ```

4. `staticDataProvider` FutureProvider 내부 `StaticGameData(...)` 호출에 추가:
   ```dart
   imageAssets: dataLoader.loadFromCache('image_assets', ImageAsset.fromJson), // M8.5 페이즈 4 #5 추가
   ```

5. 편의 조회 메서드 추가 (`StaticGameData` 클래스 내부):
   ```dart
   /// asset_key로 ImageAsset 조회. 없으면 null.
   ImageAsset? findImageAsset(String assetKey) {
     return imageAssets.where((a) => a.assetKey == assetKey).firstOrNull;
   }

   /// category + entityId 조합으로 ImageAsset 조회. 없으면 null.
   ImageAsset? findImageAssetByEntity(String category, String entityId) {
     return imageAssets.where(
       (a) => a.category == category && a.entityId == entityId,
     ).firstOrNull;
   }
   ```

---

#### FR-A4: `SyncService` 편입

**수정 파일**: `band_of_mercenaries/lib/core/data/sync_service.dart`

1. `allTables` 리스트에 추가:
   ```dart
   'image_assets', // 43. 이미지 에셋 (M8.5 페이즈 4 #5 추가)
   ```

2. `optionalTables` Set에 추가:
   ```dart
   'image_assets',
   ```
   > 이미지 에셋은 optional 처리한다. 테이블이 없거나 비어 있어도 앱이 fallback으로 동작해야 하기 때문이다.

3. 추가 위치: `battle_memory_templates` 항목 바로 다음.

---

#### FR-A5: `ImageAssetCategory` 열거 상수 + `GameImage` 위젯 신설

**파일**: `band_of_mercenaries/lib/shared/widgets/game_image.dart` (신규)

`GameImage` 위젯의 렌더 결정 순서:
1. `assetKey`가 null이거나 `staticData.imageAssets`에 없으면 즉시 fallback.
2. `ImageAsset.url`이 non-null이면 `Image.network` 렌더(loadingBuilder: 색상 박스 shimmer, errorBuilder: fallback).
3. `url`이 null이거나 에러이면 fallback: 둥근 사각 색상 박스 위 이모지 중앙 배치(행 `fallback_emoji` > 파라미터 `fallbackEmoji` > 카테고리 기본 이모지).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';

/// 이미지 에셋 카테고리 — fallback 이모지/색상 매핑 기준
enum ImageAssetCategory {
  regionThumbnail,
  factionEmblem,
  itemIcon,
  dashboardMetricIcon,
  livingsphereBackground,
}

/// 재사용 가능한 이미지 위젯. url이 null이거나 로드 실패 시 이모지+색상박스로 fallback.
/// M8.5 시점: 전 url NULL이므로 100% fallback 경로로 동작 (시각 회귀 없음).
class GameImage extends ConsumerWidget {
  const GameImage({
    super.key,
    required this.assetKey,
    required this.category,
    this.fallbackEmoji,
    this.fallbackBg,
    this.width,
    this.height,
    this.borderRadius,
  });

  /// image_assets 조회 키. null이면 즉시 fallback.
  final String? assetKey;

  /// fallback 이모지/색상 기본값 결정용 카테고리.
  final ImageAssetCategory category;

  /// 호출부 오버라이드 fallback 이모지 (행 emoji > 이 값 > 카테고리 기본 순).
  final String? fallbackEmoji;

  /// fallback 색상 박스 배경색 (null이면 카테고리 기본색 사용).
  final Color? fallbackBg;

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider).valueOrNull;
    final asset = (staticData != null && assetKey != null)
        ? staticData.findImageAsset(assetKey!)
        : null;

    final url = asset?.url;
    final resolvedEmoji = asset?.fallbackEmoji ?? fallbackEmoji ?? _defaultEmoji(category);
    final resolvedBg = fallbackBg ?? _defaultBg(category);
    final br = borderRadius ?? BorderRadius.circular(8);

    if (url != null) {
      return ClipRRect(
        borderRadius: br,
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return _FallbackBox(
              width: width,
              height: height,
              bg: resolvedBg,
              emoji: resolvedEmoji,
              br: br,
            );
          },
          errorBuilder: (ctx, error, stack) => _FallbackBox(
            width: width,
            height: height,
            bg: resolvedBg,
            emoji: resolvedEmoji,
            br: br,
          ),
        ),
      );
    }

    return _FallbackBox(
      width: width,
      height: height,
      bg: resolvedBg,
      emoji: resolvedEmoji,
      br: br,
    );
  }

  static String _defaultEmoji(ImageAssetCategory cat) => switch (cat) {
    ImageAssetCategory.regionThumbnail       => '🗺',
    ImageAssetCategory.factionEmblem         => '🔱',
    ImageAssetCategory.itemIcon              => '⚔',
    ImageAssetCategory.dashboardMetricIcon   => '★',
    ImageAssetCategory.livingsphereBackground => '🏕',
  };

  static Color _defaultBg(ImageAssetCategory cat) => switch (cat) {
    ImageAssetCategory.regionThumbnail       => AppTheme.borderLight,
    ImageAssetCategory.factionEmblem         => AppTheme.surfaceAlt,
    ImageAssetCategory.itemIcon              => AppTheme.surfaceAlt,
    ImageAssetCategory.dashboardMetricIcon   => AppTheme.surfaceAlt,
    ImageAssetCategory.livingsphereBackground => AppTheme.surfaceAlt,
  };
}

class _FallbackBox extends StatelessWidget {
  const _FallbackBox({
    required this.width,
    required this.height,
    required this.bg,
    required this.emoji,
    required this.br,
  });

  final double? width;
  final double? height;
  final Color bg;
  final String emoji;
  final BorderRadius br;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: bg, borderRadius: br),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
```

> `GameImage`가 `ConsumerWidget`인 이유: `staticDataProvider`를 watch해야 하기 때문이다. 단, `staticDataProvider.valueOrNull`로 non-blocking 접근(로딩 중이면 즉시 fallback).

---

#### FR-B1: 지역 썸네일 슬롯 — 이동 화면

**수정 파일**: `band_of_mercenaries/lib/features/movement/view/movement_screen.dart`

지역 선택 영역(`CardContainer` 내부 지역 선택 Row, 564줄 기준)의 현재 위치:
- 현재: `_selectedRegion` 숫자 + regionName 텍스트만 표시.
- 변경: 지역 선택 카드 상단(또는 leading)에 `GameImage` 추가.

구현 위치: `_MovementScreenState.build` → `staticData.when(data: ...)` 내부, 지역 선택 `CardContainer` 안의 `Column`에 지역 썸네일 추가.

```dart
// 지역 선택 CardContainer 안, '지역 선택' Text 아래에 삽입
GameImage(
  assetKey: 'region_thumb_$_selectedRegion',
  category: ImageAssetCategory.regionThumbnail,
  fallbackBg: AppTheme.dangerLevelColor(
    targetRegion.dangerLevel ?? 1, // Region 모델의 실제 필드 확인 후 적용
  ).withValues(alpha: 0.15),
  width: double.infinity,
  height: 80,
  borderRadius: BorderRadius.circular(6),
),
```

> Region 모델에 `dangerLevel` 필드가 없을 수 있다. `RegionState`의 dangerLevel은 Hive에 있으므로, fallbackBg는 `AppTheme.borderLight`로 단순화하거나, `regionStateRepositoryProvider`로 실시간 조회한다 (Q-2 참조).

---

#### FR-B2: 지역 썸네일 슬롯 — 생활권 대시보드 헤더

**수정 파일**: `band_of_mercenaries/lib/features/home/view/livingsphere_summary_section.dart`

현재 헤더: `'🏘️ 더스트플레인 생활권'` 텍스트 Row만 존재.
변경: 헤더 상단에 `GameImage`(region_thumb_3, 16:9 가로 배너) 선택적 추가.

```dart
// 헤더 Text Row 위에 삽입
GameImage(
  assetKey: 'region_thumb_3',
  category: ImageAssetCategory.regionThumbnail,
  width: double.infinity,
  height: 60,
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(8),
    topRight: Radius.circular(8),
  ),
),
const SizedBox(height: 8),
```

> `LivingsphereSummarySection`은 `ConsumerWidget`이므로 `GameImage`(ConsumerWidget) 내장 가능. `staticDataProvider`는 이미 watch 중.

---

#### FR-B3: 6지표 아이콘 슬롯 — 생활권 대시보드

**수정 파일**: `band_of_mercenaries/lib/features/home/view/livingsphere_summary_section.dart`

현재 `_MetricMiniRow`에는 label 텍스트만 있다.
변경: 각 지표 행의 label 텍스트 앞에 24×24 `GameImage` 아이콘 추가.

`_MetricMiniRow.build` Row에 leading으로 `GameImage` 추가:
```dart
GameImage(
  assetKey: 'dashboard_metric_${_metricKeyId(key)}',  // 예: 'dashboard_metric_stability'
  category: ImageAssetCategory.dashboardMetricIcon,
  fallbackEmoji: _metricEmoji(key),
  width: 24,
  height: 24,
  borderRadius: BorderRadius.circular(4),
),
const SizedBox(width: 6),
```

`_metricKeyId` 매핑 (private static String):
| MetricKey | assetKey suffix |
|-----------|----------------|
| stability | stability |
| infrastructure | infrastructure |
| eventCompletion | event |
| resourceCraft | resource |
| influence | influence |
| achievement | achievement |

`_metricEmoji` 매핑: stability→🛡, infrastructure→🏘, eventCompletion→📜, resourceCraft→📦, influence→🔱, achievement→★

> `_MetricMiniRow`는 현재 `StatelessWidget`이다. `GameImage`가 `ConsumerWidget`이므로, `_MetricMiniRow`를 `ConsumerWidget`으로 변경하거나, `LivingsphereSummarySection.build` 에서 staticData를 read해 `_MetricMiniRow`에 `ImageAsset?` 파라미터로 전달하는 방식 중 선택한다. **권장: `_MetricMiniRow`를 ConsumerWidget으로 변경** (의존성 명시적).

---

#### FR-B4: 세력 엠블럼 슬롯 — FactionCodexScreen

**수정 파일**: `band_of_mercenaries/lib/features/info/view/faction_codex_screen.dart`

현재 `_FactionCard.build` Row:
```dart
// 현재: 4px 세로 컬러 바 + SizedBox(width:12) + Expanded(Column)
Container(width: 4, height: 44, decoration: ...) // 세력 색 바
```

변경: 4px 컬러 바 대신(또는 함께) 44×44 `GameImage` 엠블럼 leading 추가.

```dart
// 기존 4px 바 유지 + 엠블럼 추가
Container(width: 4, height: 44, decoration: BoxDecoration(color: factionColor, ...)),
const SizedBox(width: 8),
GameImage(
  assetKey: 'faction_emblem_${faction.id}',
  category: ImageAssetCategory.factionEmblem,
  fallbackBg: factionColor.withValues(alpha: 0.1),
  width: 44,
  height: 44,
  borderRadius: BorderRadius.circular(6),
),
const SizedBox(width: 8),
// 기존 Expanded(Column(...))
```

> `_FactionCard`는 이미 `ConsumerWidget`이므로 `GameImage` 내장 가능.

---

#### FR-B5: 세력 엠블럼 슬롯 — FactionDetailScreen

**수정 파일**: `band_of_mercenaries/lib/features/info/view/faction_top_bar.dart` (또는 `faction_detail_screen.dart`의 헤더 영역)

현재 `FactionTopBar`: displayName 텍스트 + 뒤로가기 버튼만 있다 (`faction_top_bar.dart` 확인 필요).
변경: TopBar 또는 헤더 바로 아래에 엠블럼 영역 추가.

`FactionDetailScreen`의 `_FactionBody` 위젯 상단(또는 TopBar 내 leading) 구현:
```dart
GameImage(
  assetKey: 'faction_emblem_${faction.id}',
  category: ImageAssetCategory.factionEmblem,
  fallbackBg: FactionData.parseColor(faction.color).withValues(alpha: 0.1),
  width: 64,
  height: 64,
  borderRadius: BorderRadius.circular(8),
),
```

---

#### FR-B6: 아이템 아이콘 슬롯 — InventoryItemCard

**수정 파일**: `band_of_mercenaries/lib/features/inventory/view/inventory_item_card.dart`

현재 leading: 36×36 원형 `Container`(tierBgColor 배경 + 카테고리 이모지).
변경: `GameImage`로 교체. fallback이면 기존과 동일한 이모지+색상 박스로 렌더된다.

`build` 메서드의 leading Container를 `GameImage`로 교체:
```dart
// 기존 Container 제거하고 아래로 교체
GameImage(
  assetKey: 'item_icon_${itemData.id}',
  category: ImageAssetCategory.itemIcon,
  fallbackEmoji: _categoryIcon(itemData.category),
  fallbackBg: AppTheme.tierBgColor(itemData.tier),
  width: 36,
  height: 36,
  borderRadius: BorderRadius.circular(18), // 원형
),
```

> `InventoryItemCard`는 현재 `StatelessWidget`이다. `GameImage`가 ConsumerWidget이므로 `InventoryItemCard`를 `ConsumerWidget`으로 변경해야 한다.

---

#### FR-B7: 아이템 아이콘 슬롯 — RecipeCard

**수정 파일**: `band_of_mercenaries/lib/features/crafting/view/recipe_card.dart`

`_RecipeHeader` 위젯(private, 파일 내부)이 recipe 이름을 표시한다. 이 헤더에 결과물 아이템 아이콘 추가.

`_buildReadyCard` / `_buildInsufficientCard` 내부의 `_RecipeHeader` 앞에 아이콘:
```dart
// _RecipeHeader Row의 leading에 추가
GameImage(
  assetKey: 'item_icon_${widget.recipe.resultItemId}',
  category: ImageAssetCategory.itemIcon,
  fallbackEmoji: '⚒',
  fallbackBg: AppTheme.surfaceAlt,
  width: 32,
  height: 32,
  borderRadius: BorderRadius.circular(6),
),
const SizedBox(width: 8),
```

> `RecipeCard`는 이미 `ConsumerStatefulWidget`이므로 `GameImage` 내장 가능.

---

#### FR-B8: 아이템 아이콘 슬롯 — MaterialItemCard

**수정 파일**: `band_of_mercenaries/lib/features/crafting/view/material_item_card.dart`

현재 카드 leading 구조를 확인 후 `GameImage` 삽입 (실제 파일 확인 필요 — FR-B6와 동일 패턴).

---

#### FR-B9: 파견 화면 퀘스트 카드 지역 썸네일 미니

**수정 파일**: `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart`

`_QuestCard.build` — 현재 카드 Row 구조: LayerSidebar + Expanded(Padding(Column)).
변경: Expanded Padding의 Column 내 퀘스트 이름 Row에 40×40 지역 썸네일 trailing 추가.

```dart
// 퀘스트 이름 Row trailing에 추가 (기존 questType.name Text 앞)
GameImage(
  assetKey: 'region_thumb_${quest.regionId}',  // ActiveQuest.regionId 필드 확인 필요 (Q-3 참조)
  category: ImageAssetCategory.regionThumbnail,
  width: 32,
  height: 32,
  borderRadius: BorderRadius.circular(4),
),
const SizedBox(width: 6),
```

> `_QuestCard`는 이미 `ConsumerWidget`이므로 `GameImage` 내장 가능.

---

#### FR-C1: `SectionCard` 공용 위젯 신설

**파일**: `band_of_mercenaries/lib/shared/widgets/section_card.dart` (신규)

기존 `CardContainer`(`shared/widgets/card_container.dart`)는 border+색상 박스다. `SectionCard`는 헤더 슬롯을 포함하는 확장형이다. 기존 accent 보더 카드(FlagshipHomeCard, ChronicleHomeCard, LivingsphereSummarySection)는 보존하고, 새로 카드화가 필요한 영역(진행 상황 패널 등)에 사용한다.

```dart
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
                if (trailing != null) trailing!,
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
```

---

#### FR-C2: 홈 스크롤 영역 의미 그룹 재정렬

**수정 파일**: `band_of_mercenaries/lib/features/home/view/home_screen.dart`

현재 스크롤 영역 순서: 진행상황 패널 → FlagshipHomeCard → ChronicleHomeCard → LivingsphereSummarySection → _ActivityLog

변경 후 순서: 진행상황 패널(SectionCard 카드화) → FlagshipHomeCard → **LivingsphereSummarySection** → **ChronicleHomeCard** → _ActivityLog

구현: `SingleChildScrollView` 내 `Column` children 순서 변경. 기존 `Container`(진행상황 패널)를 `SectionCard`로 교체.

```dart
// 기존 Container(진행상황) → SectionCard로 교체
SectionCard(
  title: '진행 상황',
  margin: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 기존 내부 콘텐츠 유지 (이동/건설/임무 타이머)
      ...
    ],
  ),
),
```

> accent 보더 카드(FlagshipHomeCard, ChronicleHomeCard, LivingsphereSummarySection)는 내부 스타일 보존. 순서만 변경.

---

#### FR-D1: AppTheme 토큰 확장

**수정 파일**: `band_of_mercenaries/lib/core/theme/app_theme.dart`

추가할 정적 상수/메서드:

```dart
// === M8.5 페이즈 4 #5 추가 ===

// 섹션 헤더 TextStyle 토큰
// 현재 화면마다 fontSize: 13~15, w600~700 산재 → 통일
static const TextStyle sectionTitle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: textPrimary,
);

static const TextStyle sectionSubtitle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: textSecondary,
);

// 이미지 fallback 박스 표준 배경색 (별도 정의 불필요 — surfaceAlt 재사용)
// 신규 색상 추가 없음.
```

---

#### FR-D2: 문서 표기 정정 (코드 변경 없음, 문서만)

**수정 파일 1**: `/Users/radiogaga/git/band-of-mercenaries/CLAUDE.md`
- 변경: `"Material 3 다크 테마"` → `"Material 3 라이트 테마"` (UI 섹션)

**수정 파일 2**: `/Users/radiogaga/git/band-of-mercenaries/Docs/game_overview.md`
- 변경: 동일 표기 정정

> `AppTheme.theme`의 `ThemeData.colorScheme.light(...)` 호출이 확인되었으므로, 라이트 테마가 정식 채택임을 문서에 반영한다. 다크 테마 전환은 별도 마일스톤.

---

### 2.2 데이터 요구사항

| 항목 | 타입 | 비고 |
|------|------|------|
| `ImageAsset.assetKey` | `String` (PK) | snake_case, 예: `region_thumb_3` |
| `ImageAsset.category` | `String` | CHECK 5종 |
| `ImageAsset.entityId` | `String?` | region은 INT→TEXT, faction은 id(String) |
| `ImageAsset.url` | `String?` | M8.5 전 NULL |
| `ImageAsset.width` | `int?` | 권장 표시 폭(px) |
| `ImageAsset.height` | `int?` | 권장 표시 높이(px) |
| `ImageAsset.fallbackEmoji` | `String?` | 미지정 시 카테고리 기본 이모지 사용 |
| `ImageAsset.updatedAt` | `String?` | TIMESTAMPTZ, Dart는 String으로 수신 |

`StaticGameData.imageAssets`: `List<ImageAsset>`, 앱 기동 시 JSON 캐시에서 로드. 빈 리스트이면 전체 GameImage가 fallback으로 동작.

Hive 영속성: 해당 없음. image_assets는 `staticDataCacheBox`(Box\<String\>) JSON 캐시로 관리. 신규 typeId 불필요.

---

### 2.3 UI 요구사항

| 슬롯 | 사양 | fallback | 배치 위치 |
|------|------|----------|----------|
| 지역 썸네일 (이동 화면) | 가로 전체 × 80px | 🗺 + borderLight | 지역 선택 CardContainer 내 |
| 지역 썸네일 (생활권 헤더) | 가로 전체 × 60px | 🗺 + borderLight | LivingsphereSummarySection 헤더 상단 |
| 지역 썸네일 (파견 카드) | 32×32 | 🗺 + borderLight | _QuestCard 퀘스트 이름 Row trailing |
| 세력 엠블럼 (도감 목록) | 44×44 | 🔱 + 세력색 0.1α | _FactionCard leading (컬러 바 옆) |
| 세력 엠블럼 (세력 상세) | 64×64 | 🔱 + 세력색 0.1α | FactionTopBar 또는 헤더 영역 |
| 아이템 아이콘 (인벤토리) | 36×36 원형 | 카테고리 이모지 + tier배경 | InventoryItemCard leading |
| 아이템 아이콘 (RecipeCard) | 32×32 | ⚒ + surfaceAlt | _RecipeHeader leading |
| 아이템 아이콘 (MaterialItemCard) | 32×32 | slot 이모지 + surfaceAlt | 카드 leading |
| 6지표 아이콘 | 24×24 | 지표별 이모지 | _MetricMiniRow leading |

**카드 위계 3단계**:
1. 섹션 카드 (`SectionCard`): surfaceAlt 배경 + borderLight 보더 + radius 8
2. 강조 카드: chainGold/namedAccent 등 accent 보더 (기존 유지)
3. 인라인 행: 배경 없음

**홈 스크롤 영역 순서** (변경 후):
1. 진행상황 패널 (`SectionCard`)
2. 간판 용병 (`FlagshipHomeCard` — accent 보더 유지)
3. 생활권 대시보드 (`LivingsphereSummarySection` — Card 위젯 유지)
4. 연대기 (`ChronicleHomeCard` — accent 보더 유지)
5. 최근 활동 (`_ActivityLog` — surfaceAlt 컨테이너 유지)

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 | 수정 내용 | FR |
|------|----------|-----|
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | import 추가, StaticGameData 필드/생성자/로딩 추가, 편의 메서드 2개 추가 | FR-A3 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | allTables + optionalTables에 'image_assets' 추가 | FR-A4 |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | sectionTitle/sectionSubtitle TextStyle 상수 추가 | FR-D1 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | 스크롤 영역 순서 재정렬(생활권↔연대기 교환), 진행상황 패널 SectionCard 교체 | FR-C2 |
| `band_of_mercenaries/lib/features/home/view/livingsphere_summary_section.dart` | 헤더 썸네일 GameImage 추가, _MetricMiniRow ConsumerWidget 변경 + 아이콘 추가 | FR-B2, FR-B3 |
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | 지역 선택 CardContainer에 GameImage 지역 썸네일 추가 | FR-B1 |
| `band_of_mercenaries/lib/features/info/view/faction_codex_screen.dart` | _FactionCard Row에 GameImage 엠블럼 추가 | FR-B4 |
| `band_of_mercenaries/lib/features/info/view/faction_detail_screen.dart` | 헤더 영역에 GameImage 엠블럼 추가 | FR-B5 |
| `band_of_mercenaries/lib/features/info/view/faction_top_bar.dart` | (FR-B5 구현 방식 따라 수정 여부 결정) | FR-B5 |
| `band_of_mercenaries/lib/features/inventory/view/inventory_item_card.dart` | StatelessWidget → ConsumerWidget 변경, leading GameImage 교체 | FR-B6 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_screen.dart` | _QuestCard Row에 GameImage 지역 썸네일 미니 추가 | FR-B9 |
| `band_of_mercenaries/lib/features/crafting/view/recipe_card.dart` | _RecipeHeader에 GameImage 아이콘 추가 | FR-B7 |
| `band_of_mercenaries/lib/features/crafting/view/material_item_card.dart` | leading에 GameImage 아이콘 추가 | FR-B8 |
| `/Users/radiogaga/git/band-of-mercenaries/CLAUDE.md` | "다크 테마" → "라이트 테마" 표기 정정 | FR-D2 |
| `/Users/radiogaga/git/band-of-mercenaries/Docs/game_overview.md` | 동일 정정 | FR-D2 |

### 3.2 신규 생성 파일

| 파일 | 내용 |
|------|------|
| `band_of_mercenaries/lib/core/models/image_asset.dart` | ImageAsset freezed 모델 |
| `band_of_mercenaries/lib/shared/widgets/game_image.dart` | GameImage 위젯 + ImageAssetCategory enum |
| `band_of_mercenaries/lib/shared/widgets/section_card.dart` | SectionCard 공용 위젯 |

### 3.3 코드 생성 필요 파일 (build_runner)

| 생성 파일 | 원본 |
|----------|------|
| `band_of_mercenaries/lib/core/models/image_asset.freezed.dart` | `image_asset.dart` |
| `band_of_mercenaries/lib/core/models/image_asset.g.dart` | `image_asset.dart` |

### 3.4 관련 시스템

- **정적 데이터 파이프라인**: SyncService → DataLoader → StaticGameData → staticDataProvider. image_assets가 optional 테이블로 편입됨.
- **Hive**: 신규 박스 없음. staticDataCacheBox(Box\<String\>) 재사용.
- **다이얼로그 큐**: 영향 없음.
- **테스트**: `image_assets` optional이므로 빈 캐시 상태에서도 테스트 통과. `GameImage` 위젯 테스트는 `staticDataProvider`를 override해 빈 imageAssets 반환하면 fallback 경로만 테스트 (URL null이므로 네트워크 mock 불필요).

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

**정적 데이터 편입 패턴** (hidden_stats를 예시로):
1. `sync_service.dart` `allTables` / `optionalTables`에 테이블명 추가
2. `core/models/` 에 freezed 모델 신설 (파일명 snake_case, part 2개)
3. `static_data_provider.dart` import → `StaticGameData` 필드 → 생성자 파라미터 → `staticDataProvider` 내 `loadFromCache` 호출 (이 순서로 4곳 수정)
4. `build_runner build` 실행

`image_assets`는 optional 테이블(`hidden_stats`, `battle_memory_templates` 등과 동일)이므로 `validateRequiredCaches` 체크 대상이 아니다. 빈 리스트이면 `GameImage`가 모두 fallback으로 동작.

**ConsumerWidget 변환 패턴**:
`InventoryItemCard`처럼 StatelessWidget → ConsumerWidget 변환 시:
```dart
// 변경 전
class InventoryItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) { ... }
}

// 변경 후
class InventoryItemCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

**GameImage 호출 패턴**:
- `assetKey`가 `staticData.imageAssets`에 없으면 fallback (에러 없음)
- `staticDataProvider.valueOrNull` 사용으로 로딩 중에도 fallback으로 동작
- M8.5 시점: 전 url NULL → `_FallbackBox` 경로 100% → 기존 이모지와 시각적으로 동등하거나 더 정돈된 색상 박스

### 4.2 주의사항

1. **typeId 불필요**: `image_assets`는 정적 데이터(JSON 캐시). Hive 모델 어노테이션(`@HiveType`, `@HiveField`) 사용하지 않는다. freezed + json_serializable만 사용.

2. **ConsumerWidget 연쇄**: `GameImage`가 ConsumerWidget이므로, 이를 포함하는 StatelessWidget은 ConsumerWidget으로 변환해야 한다. 영향 파일: `InventoryItemCard` (StatelessWidget → ConsumerWidget). `_MetricMiniRow`도 ConsumerWidget으로 변환 또는 staticData를 파라미터로 받는 방식 선택.

3. **`Image.network` 위젯 테스트**: `flutter test` 환경에서 `Image.network`는 실제 네트워크를 호출하지 않아도 `HttpOverrides` 없이 에러가 발생할 수 있다. 단, M8.5 전 URL NULL이므로 `Image.network` 브랜치에 진입하지 않아 테스트 영향 없음. 향후 URL이 실제 값으로 채워질 때 위젯 테스트에서 `HttpOverrides.global = _AlwaysFailHttpOverrides()` 설정 필요.

4. **`faction.id` 값 확인**: `faction_emblem_${faction.id}` 형태의 assetKey가 SQL INSERT의 entity_id와 일치해야 한다. 실제 factions 테이블의 id 값을 Supabase에서 확인 후 SQL INSERT 조정 필요 (Q-1).

5. **`quest.regionId` 필드 존재 확인**: FR-B9에서 `ActiveQuest.regionId`를 사용한다고 가정했으나, `ActiveQuest` 모델에 해당 필드가 있는지 확인 필요 (Q-3).

6. **순서 변경 회귀 위험**: `home_screen.dart` 스크롤 영역 순서 변경(FR-C2)은 기능 비파괴이나, 기존 테스트가 순서에 의존한다면 조정 필요. 현재 테스트 파일 확인 권장.

7. **`_MetricMiniRow`의 SizedBox(width: 60) 조정**: 아이콘 24px 추가 시 label SizedBox 폭을 60 → 36으로 줄이거나, 전체 Row 레이아웃 재검토 필요.

### 4.3 엣지 케이스

| 케이스 | 처리 방식 |
|--------|----------|
| `staticDataProvider` 로딩 중 | `valueOrNull` → null → 즉시 fallback |
| `image_assets` 캐시 없음 (optional 테이블) | `loadFromCache` → `[]` → 모든 GameImage fallback |
| `assetKey`에 해당하는 행 없음 | `findImageAsset` → null → fallback |
| URL non-null이지만 CDN 오류 | `Image.network` `errorBuilder` → fallback |
| `fallbackEmoji` 미지정 + 행 없음 | 카테고리 기본 이모지 사용 |
| `InventoryItemCard` StatelessWidget → ConsumerWidget | 기존 사용처 변경 없음(Widget 타입 무관) |
| region ID가 핵심 7리전 외인 경우 | asset 없음 → fallback → 기존 이모지와 동일 |
| faction.id가 SQL INSERT에 없는 경우 | 행 없음 → fallback → 기존 컬러 바만 표시 |

### 4.4 구현 힌트

**진입점 / 데이터 흐름**:
```
Supabase [image_assets 테이블]
  ↓ SyncService._downloadTable('image_assets')
  ↓ DataLoader.saveToCache('image_assets', ...)
  ↓ [staticDataCacheBox JSON 캐시]
  ↓ DataLoader.loadFromCache('image_assets', ImageAsset.fromJson)
  ↓ StaticGameData.imageAssets (List<ImageAsset>)
  ↓ staticDataProvider (FutureProvider<StaticGameData>)
  ↓ GameImage.build → ref.watch(staticDataProvider).valueOrNull → findImageAsset(assetKey)
  ↓ url null → _FallbackBox(emoji, bg)
     url non-null → Image.network(url, errorBuilder: _FallbackBox)
```

**참조 구현**:
- freezed 모델 패턴: `band_of_mercenaries/lib/core/models/battle_memory_template.dart` (가장 최근 추가, 구조 동일)
- staticDataProvider 편입 패턴: `static_data_provider.dart` 289~295행 (`hiddenStats`, `battleMemoryTemplates` 추가 부분)
- SyncService optional 패턴: `sync_service.dart` 68~80행 (`optionalTables` Set)
- ConsumerWidget 변환: `features/info/view/faction_codex_screen.dart` (`_FactionCard extends ConsumerWidget`)
- 기존 SectionCard 유사 패턴: `_ActivityLog` widget의 Container 스타일 (surfaceAlt + borderLight + radius 8)

**확장 지점**:
- M9: `image_assets.url` UPDATE + `data_versions.version` 증가 → SyncService 자동 갱신 → GameImage URL 분기 활성화
- M9 이후 캐싱 필요 시: `GameImage`의 `Image.network` → `CachedNetworkImage`로 교체(위젯 외부 인터페이스 변경 없음)
- 추가 슬롯: `asset_key` 규약(`{category_prefix}_{entity_id}`)을 따라 DB 행 추가 → 코드 변경 없음

**구현 순서 권장** (implement-agent 순차 격리 모드):
1. TASK-1: FR-A2(모델) + FR-A4(SyncService) + FR-A3(StaticGameData) + build_runner
2. TASK-2: FR-A5(GameImage + SectionCard + AppTheme 토큰)
3. TASK-3: FR-B1(이동 썸네일) + FR-B2(생활권 헤더) + FR-B3(6지표 아이콘)
4. TASK-4: FR-B4(도감 엠블럼) + FR-B5(상세 엠블럼) + FR-B9(파견 썸네일)
5. TASK-5: FR-B6(인벤토리 아이콘) + FR-B7(RecipeCard) + FR-B8(MaterialItemCard)
6. TASK-6: FR-C2(홈 재정렬) + FR-D2(문서 정정)

---

## 5. 기획 확인 사항

**Q-1. `factions` 테이블의 실제 id 값 확인**
- 내용: SQL INSERT에 사용한 faction entity_id(`adventurer_guild`, `merchant_league`, `warrior_order`)가 실제 Supabase `factions.id` 컬럼 값과 일치해야 한다.
- 조치: 구현 전 Supabase 콘솔 또는 `staticData.factions.map((f) => f.id)` 출력으로 확인 후 SQL 조정.
- 기획 문서: 세력 id 명시 없음 → 확인 후 조정 필요.

**Q-2. 이동 화면 지역 썸네일 fallbackBg 색상 소스**
- 내용: FR-B1에서 `targetRegion.dangerLevel`을 사용하려 했으나, `Region` 정적 모델에 dangerLevel이 없다(실시간 상태는 `RegionState` Hive). fallbackBg 단순화(`AppTheme.borderLight`)로 충분한가, 아니면 `regionStateRepositoryProvider`를 참조해 실시간 dangerLevel 색상을 적용해야 하는가.
- 확인 결과: 기획 문서는 "dangerLevel 색 박스" 명시. 단, M8.5 전 URL NULL이므로 차이가 눈에 보이지 않는다. `AppTheme.borderLight` 단순화로 시작하고, M9에서 실시간 색상 적용 검토를 권장한다.

**Q-3. `ActiveQuest.regionId` 필드 존재 여부**
- 내용: FR-B9(파견 카드 썸네일)에서 `quest.regionId`를 사용한다. `ActiveQuest` 모델(`features/quest/domain/quest_model.dart`)에 해당 필드가 있는지 확인 필요.
- 조치: 없을 경우 `quest.questPoolId`로 QuestPool을 조회해 `pool.regionId`를 사용하거나, 또는 파견 카드에 썸네일 미니를 생략하고 fallback 텍스트만 유지한다.

**Q-4. `_MetricMiniRow` 아이콘 추가 후 레이아웃 폭 조정**
- 내용: 현재 `_MetricMiniRow`의 label `SizedBox(width: 60)`에 24px 아이콘이 추가되면 전체 Row가 좁아질 수 있다. label width를 36으로 줄이거나 아이콘 크기를 20px로 조정할지.
- 확인 결과: 기획 문서 미명시. 구현 시 실제 화면에서 확인 후 조정. 권장: 아이콘 20×20, label SizedBox(width: 48).

**Q-5. `FactionTopBar` 구조 확인**
- 내용: `faction_top_bar.dart` 파일을 직접 Read하지 않았다. FR-B5 구현 위치가 TopBar 내부인지 `_FactionBody` 상단인지 실제 파일 확인 후 결정 필요.
- 조치: 구현 에이전트가 파일 Read 후 적절한 위치에 엠블럼 삽입.

**Q-6. 기존 `material_item_card.dart` 구조**
- 내용: FR-B8의 `material_item_card.dart` 구조를 직접 Read하지 않았다. leading 패턴이 `InventoryItemCard`와 유사하다고 가정했으나 확인 필요.
- 조치: 구현 에이전트가 파일 Read 후 `GameImage` 삽입 위치 결정.
