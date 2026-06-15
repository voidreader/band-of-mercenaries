# UI 폴리싱 1차 + 이미지 에셋 적용 구현 계획·개발 정리

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260614_m8.5_ui_polish_image_assets.md`
> 기획 문서: `Docs/content-design/[content]20260614_m8.5_ui_polish_image_assets.md`
> 구현일: 2026-06-14
> 마일스톤: M8.5 페이즈 4 #5

## 1. 구현 개요

이미지 인프라(fallback-first)를 신설하고, 홈/파견/이동/제작·인벤토리/정보 화면에 이미지 슬롯 4종을 배치했다. 실제 이미지 파일이 없는 현 상태(전 `url = NULL`)에서 100% fallback 경로(이모지+색상 박스)로 동작하며, M9 디자인 작업 시 DB의 `url`만 `UPDATE`하면 코드·앱 배포 없이 이미지가 노출된다.

## 2. 실행 모드 및 검증

- **실행 모드**: 순차 격리 모드 (TASK 6개). TASK-1·2는 개별 미니 사이클(coder → verifier → flutter-reviewer), 파일이 완전 격리된 TASK-3·4·5·6은 coder 병렬 실행 후 통합 검증(verifier + flutter-reviewer 병렬).
- **검증 결과 요약**:
  - TASK-1: verifier PASS / flutter-reviewer APPROVE (이슈 0)
  - TASK-2: verifier PASS / flutter-reviewer APPROVE (with warnings — semantics label 부재 low, 코드베이스 일관성상 향후 위임)
  - TASK-3~6 통합: verifier PASS (이슈 0) / flutter-reviewer APPROVE (with warnings — ref 미사용 ConsumerWidget low 2건)
  - **cleanup**: flutter-reviewer ISSUE-1·2 반영 — `_MetricMiniRow`/`InventoryItemCard`/`_RecipeHeader`를 StatelessWidget으로 환원, 미사용 import 제거
- **빌드 게이트**: `flutter analyze` error 0 (info 1건 `combat_report_service.dart:166` use_null_aware_elements는 pre-existing, 본 작업 무관) · `flutter test` 789/789 PASS.

## 3. 변경 파일 목록

### 신규 생성 (3)
| 파일 | 역할 |
|------|------|
| `band_of_mercenaries/lib/core/models/image_asset.dart` | `ImageAsset` freezed 모델 (8필드, snake_case @JsonKey) |
| `band_of_mercenaries/lib/shared/widgets/game_image.dart` | `GameImage`(ConsumerWidget) + `ImageAssetCategory` enum 5종 + `_FallbackBox` |
| `band_of_mercenaries/lib/shared/widgets/section_card.dart` | `SectionCard` 공용 위젯 (헤더+본문 슬롯) |

### 코드 생성 (build_runner, 2)
| 파일 | 원본 |
|------|------|
| `band_of_mercenaries/lib/core/models/image_asset.freezed.dart` | `image_asset.dart` |
| `band_of_mercenaries/lib/core/models/image_asset.g.dart` | `image_asset.dart` |

### 수정 (코드, 11)
| 파일 | 변경 | FR |
|------|------|-----|
| `lib/core/providers/static_data_provider.dart` | import + `imageAssets` 필드/생성자/loadFromCache + `findImageAsset`/`findImageAssetByEntity` | FR-A3 |
| `lib/core/data/sync_service.dart` | allTables(43번) + optionalTables에 `image_assets` | FR-A4 |
| `lib/core/theme/app_theme.dart` | `sectionTitle`/`sectionSubtitle` TextStyle 토큰 | FR-D1 |
| `lib/features/movement/view/movement_screen.dart` | 지역 선택 영역 지역 썸네일(80px) | FR-B1 |
| `lib/features/home/view/livingsphere_summary_section.dart` | 헤더 썸네일(60px) + `_MetricMiniRow` 6지표 아이콘(20px) | FR-B2·B3 |
| `lib/features/info/view/faction_codex_screen.dart` | `_FactionCard` 엠블럼(44px) | FR-B4 |
| `lib/features/info/view/faction_detail_screen.dart` | `_FactionBody` 엠블럼(64px) | FR-B5 |
| `lib/features/quest/view/dispatch_screen.dart` | `_QuestCard` 지역 썸네일 미니(32px, `quest.region`) | FR-B9 |
| `lib/features/inventory/view/inventory_item_card.dart` | leading 아이템 아이콘(36px 원형) | FR-B6 |
| `lib/features/crafting/view/recipe_card.dart` | `_RecipeHeader` 결과물 아이콘(32px) | FR-B7 |
| `lib/features/crafting/view/material_item_card.dart` | leading 아이템 아이콘(32px) + `_slotEmoji` 헬퍼 | FR-B8 |
| `lib/features/home/view/home_screen.dart` | 스크롤 순서 재정렬(Flagship→생활권→연대기) + 진행상황 SectionCard 교체 | FR-C2 |

### 수정 (문서·테스트)
| 파일 | 변경 | FR |
|------|------|-----|
| `CLAUDE.md` (228행) | "Material 3 다크 테마" → "라이트 테마" | FR-D2 |
| `Docs/game_overview.md` (460행) | 동일 정정 | FR-D2 |
| 테스트 18파일 | `StaticGameData` 생성처에 `imageAssets: const []`(또는 `base.imageAssets`) 추가 (required 필드) | FR-A3 부수 |

## 4. 주요 결정사항 (명세 Q항목 코드 검증 해소)

- **Q-1 (faction id)**: 실제 id가 명세 SQL과 불일치 → 보고에 정정 기록(`faction_adventurers_guild`/`faction_merchants_alliance`/`faction_warriors_guild`). 코드는 `faction.id` 사용이라 영향 없음. **SQL은 별도 승인 대기**.
- **Q-2**: 이동 썸네일 fallbackBg는 `AppTheme.borderLight` 단순화(Region 정적 모델에 dangerLevel 없음).
- **Q-3**: `ActiveQuest.regionId` 없음 → `quest.region`(int, HiveField 4) 사용.
- **Q-4**: 6지표 아이콘 20×20, `_MetricMiniRow` label SizedBox 60→48 축소.
- **Q-5**: `faction_top_bar.dart`(StatelessWidget) 미수정 → 엠블럼은 `faction_detail_screen.dart` 본문 배치.
- **Q-6**: `MaterialItemCard`(ConsumerStatefulWidget) — GameImage를 `Align(center)`로 감싸 IntrinsicHeight+stretch 대응.

## 5. build_runner 재실행

- `image_asset.dart` 작성 직후 1회 실행 완료 (`image_asset.freezed.dart`/`image_asset.g.dart` 생성). 추가 모델 변경 없음.

## 6. CLAUDE.md 금지사항 위반

- 없음. 정적 데이터 모델은 Hive typeId 미사용(freezed+json만), 스타일은 AppTheme 중앙 관리, Navigator.push 미사용(상태 기반 렌더링 유지), shared/styles 미생성.

## 7. 후속 대기 항목

- **SQL 적용**: 명세 FR-A1의 `image_assets` CREATE + INSERT(faction entity_id 정정본)는 실제 Supabase 적용 별도 승인 대기. 적용 시 `data_versions` 버전 증가 필수.
- **M9 이미지 작업**: 실제 이미지 제작 → CDN 업로드 → `image_assets.url` UPDATE로 노출. 코드 변경 불필요.
- **semantics label (low)**: `GameImage` 접근성 레이블은 실제 url 도입 마일스톤에서 일괄 대응 권고(현재 코드베이스 전반 미사용으로 일관성상 보류).
