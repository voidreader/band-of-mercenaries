Skill used : implement-spec

# Phase 2: Flutter 모델/싱크 업데이트 — 구현 결과

> 작성일: 2026-04-12

## 구현 계획 요약

트레잇 시스템 고도화 Phase 1에서 Supabase에 적용된 6개 테이블 구조에 맞게 Flutter 앱의 모델, 동기화, 데이터 로딩을 업데이트하였다.

## 변경 파일 목록

### 신규 파일 (5개)

| 파일 경로 | 설명 |
|----------|------|
| `lib/core/models/trait_category.dart` | TraitCategory 모델 (key, name, slotType) |
| `lib/core/models/trait_conflict.dart` | TraitConflict 모델 (traitKey, conflictTraitKey) |
| `lib/core/models/trait_transition.dart` | TraitTransition 모델 (id, fromTraitKey, toTraitKey, conditionJson) |
| `lib/core/models/trait_combo_evolution.dart` | TraitComboEvolution 모델 (id, requiredTrait1, requiredTrait2, resultTraitKey) |
| `lib/core/models/trait_synergy.dart` | TraitSynergy 모델 (id, innateTraitKey, targetTraitKey, reductionPercent) |

### 수정 파일 (11개)

| 파일 경로 | 변경 유형 | 설명 |
|----------|----------|------|
| `lib/core/models/trait_data.dart` | 교체 | id→key, effectType/value 제거, categoryKey/type/description/effectText 추가 |
| `lib/core/data/sync_service.dart` | 수정 | allTables에 5개 신규 테이블 추가 (trait_categories, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies) |
| `lib/core/providers/static_data_provider.dart` | 수정 | StaticGameData에 5개 필드 추가 + import 6개 추가 |
| `lib/core/theme/app_theme.dart` | 수정 | traitColors → traitCategoryColors (카테고리 기반 색상) |
| `lib/features/mercenary/domain/recruitment_service.dart` | 수정 | trait.id→trait.key, effectType/value switch 제거 |
| `lib/features/quest/domain/quest_calculator.dart` | 수정 | 하드코딩된 trait 효과 제거 (Phase 3에서 데이터 드리븐 구현 예정) |
| `lib/features/mercenary/view/mercenary_card.dart` | 수정 | trait nullable 처리, 카테고리 기반 색상 |
| `lib/features/mercenary/view/recruit_screen.dart` | 수정 | t.id→t.key, firstWhereOrNull null-safe 조회 |
| `test/features/mercenary/domain/recruitment_service_test.dart` | 수정 | 새 TraitData 모델에 맞게 테스트 데이터 갱신 |
| `test/features/quest/domain/quest_calculator_test.dart` | 수정 | 트레잇 효과 비활성화 반영 |
| `test/features/quest/domain/quest_calculator_preview_test.dart` | 수정 | 트레잇 보너스 0 반영 |
| `test/features/quest/domain/quest_completion_service_test.dart` | 수정 | StaticGameData 신규 필드 추가 |

### build_runner 재실행 필요 파일

| 파일 | 생성 파일 |
|------|----------|
| `lib/core/models/trait_data.dart` | `.freezed.dart`, `.g.dart` |
| `lib/core/models/trait_category.dart` | `.freezed.dart`, `.g.dart` |
| `lib/core/models/trait_conflict.dart` | `.freezed.dart`, `.g.dart` |
| `lib/core/models/trait_transition.dart` | `.freezed.dart`, `.g.dart` |
| `lib/core/models/trait_combo_evolution.dart` | `.freezed.dart`, `.g.dart` |
| `lib/core/models/trait_synergy.dart` | `.freezed.dart`, `.g.dart` |

## 검증 결과

- `dart run build_runner build` — 성공 (912 outputs)
- `flutter analyze` — error 0개 (기존 info 1개만 잔존)
- `flutter test` — **137개 전부 통과**

## 임시 비활성화된 기능 (Phase 3에서 복구 예정)

| 기능 | 이유 | 위치 |
|------|------|------|
| 모집 시 스탯 수정 (hp_bonus, atk_bonus) | effectType/value 필드 제거됨 | `recruitment_service.dart` |
| veteran 트레잇 성공률 +10% | 하드코딩 제거 | `quest_calculator.dart` |
| coward 트레잇 사망률 -30% | 하드코딩 제거 | `quest_calculator.dart` |
| strong 트레잇 부상률 -20% | 하드코딩 제거 | `quest_calculator.dart` |

## 호환성 처리

- 기존 용병(구 traitId: strong, veteran, coward, berserker)은 새 trait DB에서 조회 실패 가능
- `recruit_screen.dart`에서 `firstWhereOrNull` 사용, `mercenary_card.dart`에서 trait nullable 처리
- UI에 "알 수 없는 특성" 텍스트로 fallback 표시
- Phase 3에서 용병 데이터 마이그레이션 또는 기존 용병 리셋 처리 예정
