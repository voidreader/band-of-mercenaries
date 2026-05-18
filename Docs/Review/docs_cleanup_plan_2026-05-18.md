# Docs 2차 정리 계획서

> 작성일: 2026년 5월 18일
> 기준 감사: `Docs/Review/project_audit_2026-05-18.md`
> 범위: `Docs/` 하위 마크다운 문서의 최신성, 중복, 보존 위치 정리

## 결론

2차 정리는 문서 삭제 작업이 아니라 기준 문서와 완료 산출물을 분리하는 작업이다. 현재 `Docs/`에는 290개 마크다운 문서와 약 11.7만 줄의 문서가 있으며, 해시 기준 동일 문서 그룹 65개, 관련 파일 134개가 확인된다. 즉시 삭제보다 `current/reference/archive` 성격을 명확히 나누고, 완료 산출물은 `Docs/Archive/`에만 보존하는 방식이 안전하다.

이번 계획은 실제 파일 이동·삭제 전 승인용 기준 문서로 사용한다. 실행 단계에서는 한 번에 전체를 정리하지 않고, Phase별로 변경량을 제한한다.

## 현재 현황

문서 현황은 2026년 5월 18일 기준 스캔 결과이다.

- 전체 마크다운: 290개
- 전체 라인 수: 117,277줄
- 동일 해시 중복 그룹: 65개
- 동일 해시 중복 관련 파일: 134개
- 최대 문서군: `Docs/Archive` 111개, `Docs/spec` 56개, `Docs/content-design` 37개, `Docs/balance-design` 23개

대형 문서는 대부분 완료된 `Docs/superpowers/plans/`에 집중되어 있다. 이 파일들은 개발 이력으로서 가치는 있지만 현재 작업 기준 문서로 계속 노출될 필요는 낮다.

## 정리 원칙

문서 정리는 다음 원칙을 적용한다.

- 현재 개발 기준 문서는 적게 유지한다.
- 완료된 spec, plan, design 산출물은 `Docs/Archive/`에 보존한다.
- 활성 폴더에는 “진행 중이거나 자주 참조하는 문서”만 둔다.
- byte-for-byte 동일한 문서가 있으면 아카이브 사본을 보존하고 활성 사본을 제거 후보로 둔다.
- 동일하지 않지만 내용상 중복인 문서는 즉시 삭제하지 않고 대표 문서와 보조 문서를 지정한다.
- `Docs/`와 `docs/`의 대소문자 표기는 별도 파일시스템 위험이 있으므로 이번 정리에서 이름 변경을 시도하지 않는다.
- `Docs/Archive/` 내부 문서는 원칙적으로 삭제하지 않는다. 단, 동일 아카이브 폴더 안에서 중복된 사본은 별도 승인 후 정리한다.

## 기준 문서 세트

정리 후에도 다음 문서는 현재 기준 문서로 남긴다.

- `AGENTS.md`
- `CLAUDE.md`
- `Docs/roadmap/master_roadmap.md`
- `Docs/game_overview.md`
- `Docs/flutter-ui-refactor.md`
- `Docs/flutter_commands.md`
- `Docs/CHANGELOG.md`
- `Docs/milestone-runs/M7/state.md`
- `Docs/Review/project_audit_2026-05-18.md`
- `Docs/Review/docs_cleanup_plan_2026-05-18.md`

다음 문서는 보관본 또는 참고 문서로 남기되, 최신 기준 문서가 아님을 명시한다.

- `Docs/content_status.md`
- `Docs/milestone_next_action.md`
- `Docs/Review/code_review_2026-04-12*.md`

## Phase 1: 활성 spec 중복 제거

Phase 1은 가장 안전한 정리 단계이다. `Docs/spec/`에 남아 있지만 `Docs/Archive/`에 동일 사본이 있는 완료 산출물을 활성 검색면에서 제거한다.

대상 후보는 다음과 같다.

- `Docs/spec/M3/`
- `Docs/spec/M4/`
- `Docs/spec/archive/`
- `Docs/spec/discard/`
- `Docs/spec/[spec]20260505_M5_phase4_2_crafting-service-and-inventory-ui.md`
- `Docs/spec/[spec]20260505_M5_phase4_2_crafting-service-and-inventory-ui_plan.md`
- `Docs/spec/[spec]20260505_M5_phase4_3_drop-hooks-and-progression-triggers.md`
- `Docs/spec/[spec]20260505_M5_phase4_3_drop-hooks-and-progression-triggers_plan.md`
- `Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle.md`
- `Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle_plan.md`
- `Docs/spec/[spec]20260515_M6_phase4_2_titles-flagship.md`
- `Docs/spec/[spec]20260515_M6_phase4_2_titles-flagship_plan.md`
- `Docs/spec/[spec]20260515_M6_phase4_3_named-quests.md`
- `Docs/spec/m7_p4_1_region_state_system.md`
- `Docs/spec/m7_p4_2_questgenerator_weights.md`
- `Docs/spec/m7_p4_3_movement_ui.md`
- `Docs/spec/m7_p4_4_infrastructure_system.md`
- `Docs/spec/m7_p4_implementation_plan.md`

실행 방식은 두 가지 중 하나를 선택한다.

1. 보수안: 활성 파일을 삭제하지 않고 `Docs/spec/README.md`를 만들어 완료 산출물은 `Docs/Archive/`를 참조하라고 안내한다.
2. 정리안: 동일 사본이 확인된 활성 spec 파일을 `git rm`으로 제거하고 아카이브 사본만 보존한다.

권장안은 정리안이다. 단, 실행 직전 해시 동일성을 다시 확인해야 한다.

### Phase 1 실행 결과

2026년 5월 18일에 Phase 1을 실행했다. 실행 직전 `Docs/spec/`와 `Docs/Archive/`의 해시를 재검증하고, byte-for-byte 동일한 아카이브 사본이 있는 활성 spec만 `git rm`으로 제거했다.

- 제거한 활성 spec 파일: 40개
- 실행 후 전체 마크다운: 247개
- 보존 위치: 동일 사본은 `Docs/Archive/` 하위 마일스톤별 폴더에 유지한다.
- 유지한 예외: `Docs/spec/M3/[spec]20260424_template-engine.md`와 plan은 동일 아카이브 사본이 없어 유지한다.
- 유지한 예외: `Docs/spec/archive/`와 `Docs/spec/discard/` 파일은 이번 해시 기준 동일 아카이브 사본이 없어 유지한다.
- 참조 보정: `Docs/milestone-runs/`의 M3·M4·M6·M7 상태 문서, `Docs/superpowers/plans/2026-05-15-named-quests.md`, `Docs/content-data/postponed_regions_dump.json`의 활성 경로 참조를 아카이브 경로로 갱신한다.

Phase 1 완료 후 다음 정리 후보는 Phase 3이다. `Docs/superpowers/plans/`는 완료된 구현 계획 대형 문서가 많아 검색면과 컨텍스트 소비를 크게 줄일 수 있다.

## Phase 2: content-design과 balance-design 중복 정리

Phase 2는 설계·밸런스 문서의 활성면을 줄이는 단계이다. 이 문서군은 기획 의사결정 가치가 있으므로 삭제보다 대표 문서 지정이 우선이다.

활성 유지 후보는 다음과 같다.

- M7 생활권 관련 최신 4개 content 문서
- M7 밸런스 관련 최신 3개 balance 문서
- M6 칭호·위업·지명 의뢰 핵심 설계 문서
- M5 제작 경제와 드랍 훅 핵심 설계 문서

아카이브 후보는 다음과 같다.

- `Docs/content-design/[content]20260423_region_transform.md`
- `Docs/content-design/[content]20260424_quest_narratives.md`
- `Docs/content-design/[content]20260424_travel_choices.md`
- `Docs/content-design/[content]20260503_starting-settlement.md`
- `Docs/content-design/[content]20260503_sector-system-redesign.md`
- `Docs/content-design/[content]20260503_region-40-redesign.md`
- `Docs/content-design/[content]20260512_named-quests.md`
- `Docs/content-design/[content]20260512_titles-and-flagship.md`
- `Docs/content-design/[content]20260512_achievement-chronicle-system.md`
- `Docs/balance-design/[balance]20260503_fixed-quest-curve.md`
- `Docs/balance-design/[balance]20260503_chore-quest-economy.md`
- `Docs/balance-design/[balance]20260503_settlement-trust-tuning.md`
- `Docs/balance-design/[balance]20260513_title-effect-values.md`
- `Docs/balance-design/[balance]20260513_exposure-pacing.md`

실행 방식은 대표 문서를 남긴 뒤, 동일 사본이 이미 `Docs/Archive/`에 있는 파일만 제거한다. 동일하지 않은 문서는 `Docs/Archive/`로 이동한다.

### Phase 2 실행 결과

2026년 5월 18일에 Phase 2를 실행했다. 실행 직전 해시를 확인하고, `Docs/Archive/`에 byte-for-byte 동일 사본이 있는 content-design 9개와 balance-design 5개를 활성 위치에서 제거했다.

- 제거한 활성 설계·밸런스 문서: 14개
- 실행 후 `Docs/content-design/` 마크다운: 28개
- 실행 후 `Docs/balance-design/` 마크다운: 18개
- 보존 위치: 동일 사본은 각 마일스톤별 `Docs/Archive/` 폴더에 유지한다.
- 참조 보정: 활성 문서의 제거 대상 경로를 `Docs/Archive/` 경로로 갱신한다.

Phase 2는 최신 M7 설계·밸런스 문서와 아직 아카이브 사본이 확인되지 않은 구기획 문서를 유지한다. 남은 문서는 Phase 4 이후 별도 대표 문서 지정 또는 `Docs/Archive/misc/` 이동으로 재평가한다.

## Phase 3: superpowers 산출물 보관

Phase 3은 `Docs/superpowers/`의 완료 plan과 design을 보관 위치로 옮기는 단계이다. 이 문서들은 긴 실행 기록이므로 보존하되, 일반 작업 검색면에서는 제외하는 편이 좋다.

대상 후보는 다음과 같다.

- `Docs/superpowers/plans/2026-04-07-band-of-mercenaries-prototype.md`
- `Docs/superpowers/plans/2026-04-08-game-depth-and-goals.md`
- `Docs/superpowers/plans/2026-04-09-requirements-update.md`
- `Docs/superpowers/plans/2026-04-11-supabase-data-sync.md`
- `Docs/superpowers/plans/2026-04-11-ui-fixes-dispatch-popup-activity.md`
- `Docs/superpowers/plans/2026-04-13-trait-system-phase5-ui.md`
- `Docs/superpowers/plans/2026-04-16-faction-core-system.md`
- `Docs/superpowers/plans/2026-05-15-named-quests.md`
- `Docs/superpowers/specs/*.md`

권장 이동 위치는 `Docs/Archive/superpowers/`이다. 이미 특정 마일스톤 아카이브에 동일 사본이 있는 문서는 활성 사본만 제거한다.

### Phase 3 실행 결과

2026년 5월 18일에 Phase 3을 실행했다. 완료된 superpowers plan 8개와 design 7개를 `Docs/Archive/superpowers/`로 이동했다.

- 이동한 superpowers plan: 8개
- 이동한 superpowers design: 7개
- 실행 후 `Docs/superpowers/` 마크다운: 0개
- 보존 위치: `Docs/Archive/superpowers/plans/`, `Docs/Archive/superpowers/specs/`
- 참조 보정: 활성 문서의 `Docs/superpowers/plans/2026-05-15-named-quests.md` 참조를 `Docs/Archive/superpowers/plans/2026-05-15-named-quests.md`로 갱신한다.

Phase 3 완료 후 `Docs/superpowers/`는 일반 검색면에서 제거된다. 향후 새 superpowers 산출물이 생성되면 진행 중 문서만 활성 위치에 두고, 완료 시 같은 보관 위치로 이동한다.

## Phase 4: 루트 문서 정리

Phase 4는 `Docs/` 루트의 낮은 최신성 문서를 정리하는 단계이다. 루트 문서는 검색과 사람이 보는 진입점에 직접 영향을 주므로, 삭제보다 상태 표시와 링크 정리가 우선이다.

대상 후보는 다음과 같다.

- `Docs/content_status.md`: 이미 M3 기준 보관본으로 표시했다.
- `Docs/milestone_next_action.md`: 이미 오래된 임시 액션 기록으로 표시했다.
- `Docs/roadmap-by-gemeni.md`: `Docs/roadmap/master_roadmap.md`와 중복 가능성이 높다.
- `Docs/ecc_token_efficiency_analysis.md`: 현재 개발 기준 문서 여부를 확인한다.
- `Docs/ecc_integration_review.md`: 현재 개발 기준 문서 여부를 확인한다.
- `Docs/future_ideas.md`: 유지하되 M8 이후 후보 아이디어로 분류한다.
- `Docs/idea_note.md`: `future_ideas.md`와 통합 후보이다.

권장안은 `roadmap-by-gemeni.md`, `ecc_*`, `idea_note.md`를 바로 삭제하지 않고 `Docs/Archive/misc/`로 이동하는 것이다. 이후 1~2주 동안 참조 문제가 없으면 삭제 후보로 재평가한다.

### Phase 4 실행 결과

2026년 5월 18일에 Phase 4를 실행했다. 낮은 최신성의 루트 문서는 삭제하지 않고 `Docs/Archive/misc/`로 보존 이동했으며, 활성 문서의 참조 경로를 갱신했다.

- 이동한 루트 문서: 4개
- 이동 위치: `Docs/Archive/misc/`
- 이동 파일: `roadmap-by-gemeni.md`, `ecc_integration_review.md`, `ecc_token_efficiency_analysis.md`, `idea_note.md`
- 유지 파일: `Docs/content_status.md`, `Docs/milestone_next_action.md`, `Docs/future_ideas.md`
- 상태 표시: `Docs/future_ideas.md`를 M8 이후 후보 아이디어 보관소로 표시한다.
- 참조 보정: 활성 문서의 `Docs/idea_note.md` 참조를 `Docs/Archive/misc/idea_note.md`로 갱신하고, `content_status.md`가 최신 구현 문서처럼 보이는 안내 문장을 보정한다.

Phase 4 완료 후 `Docs/` 루트에는 현재 기준 문서와 보관 표시가 명확한 문서만 남긴다.

## Phase 5: changelog fragment 정리

Phase 5는 이번 정리 범위에서 제외한다. 변경 로그 조각의 병합 여부는 릴리스 정리 또는 `merge-changelog` 작업 시 별도로 확인한다.

대상 후보는 다음과 같다.

- `Docs/changelog-fragments/20260513_M6_phase4_1_achievement-chronicle.md`
- `Docs/changelog-fragments/20260515_M6_phase4_2_titles-flagship.md`
- `Docs/changelog-fragments/20260515_M6_phase4_3_named-quests.md`
- `Docs/changelog-fragments/20260517_m7-phase4-livingsphere.md`

이번 작업에서는 `Docs/CHANGELOG.md`와 fragment 파일을 수정하지 않는다.

## 실행 전 검증

각 Phase 실행 전에는 다음 검증을 수행한다.

```bash
find Docs -type f -name '*.md' -print0 | xargs -0 md5 -r | sort
rg -n "Docs/spec|Docs/content-design|Docs/balance-design|Docs/superpowers" Docs AGENTS.md CLAUDE.md
git status --short
```

동일 해시가 아닌 문서는 삭제하지 않는다. 문서 이동 후에는 링크가 깨지는지 `rg`로 참조를 확인한다.

## 실행 후 검증

문서 정리 후에는 다음 검증을 수행한다.

```bash
rg -n "Docs/spec/M3|Docs/spec/M4|Docs/superpowers/plans" Docs AGENTS.md CLAUDE.md
rg -n "gh[p]_|github_[p]at_" Docs AGENTS.md CLAUDE.md
git status --short
```

코드 변경이 없는 문서 이동만 수행한 경우 `flutter test`는 필수는 아니다. 단, `AGENTS.md`, `CLAUDE.md`, 코드 생성 문서, 명령 문서를 수정한 경우 `flutter analyze`를 실행한다.

## 위험과 대응

문서 정리의 주요 위험은 참조 경로 손상과 기획 맥락 손실이다.

- 참조 경로 손상: 이동 전후 `rg`로 경로 참조를 확인한다.
- 기획 맥락 손실: 삭제보다 `Docs/Archive/` 이동을 우선한다.
- 대소문자 경로 혼선: 이번 작업에서는 `Docs`와 `docs` 경로명을 정규화하지 않는다.
- 대량 변경 리뷰 어려움: Phase별로 커밋을 나누거나 최소한 Phase별 diff를 분리한다.

## 권장 실행 순서

다음 순서로 실행한다.

1. Phase 1을 실행하여 완료 spec 중복을 제거한다.
2. `rg`로 깨진 참조를 수정한다.
3. Phase 3을 실행하여 `Docs/superpowers/` 완료 산출물을 보관한다.
4. Phase 2를 실행하여 content/balance 설계 문서 대표본을 정리한다.
5. Phase 4를 실행하여 루트 문서의 상태 표시와 보관 이동을 마무리한다.
6. Phase 5는 changelog 병합 여부를 확인한 뒤 별도 처리한다.

## 다음 단계

Phase 1~4는 완료되었다. Phase 5는 이번 정리 범위에서 제외한다. 이후 문서 정리는 릴리스 시점의 changelog 병합 확인 또는 새 마일스톤 시작 전 기준 문서 점검으로 분리해 진행한다.
