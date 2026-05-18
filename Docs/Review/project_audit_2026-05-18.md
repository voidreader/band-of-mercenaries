# 프로젝트 1차 감사 리포트

> 작성일: 2026년 5월 18일
> 범위: M7 진행 이후 코드 구조, 테스트 상태, `Docs/` 마크다운 정리 후보
> 원칙: 본 감사는 삭제·이동 없이 읽기 전용으로 수행한다.

## 결론

프로젝트는 M7 기준으로 기능 규모가 크게 커졌지만, 현재 빌드 기준선은 안정적이다. `flutter analyze`와 전체 `flutter test`는 모두 통과한다. 다만 문서 체계는 이미 활성 문서와 아카이브 문서가 중복 보관되는 단계에 들어섰고, 일부 상태 문서는 실제 코드 진행 상황을 반영하지 못한다. 코드 측면에서는 즉시 실패하는 결함보다 정적 데이터 동기화, 장기 타이머, 이벤트 채널, 문서-코드 상태 불일치가 다음 마일스톤의 주요 위험이다.

가장 먼저 처리할 항목은 보안 토큰으로 보이는 문자열이 추적 파일에 남아 있는 문제이다. 해당 값은 리포트에 재기재하지 않으며, 즉시 폐기와 삭제가 필요하다.

## 감사 요약

이번 감사에서는 저장소의 마크다운 파일, Flutter/Dart 소스, 테스트, M7 연결부를 우선 확인했다.

- `Docs/` 전체 마크다운: 289개
- `Docs/` 총 라인 수: 116,989줄
- Flutter/Dart 소스: 341개
- Flutter/Dart 테스트: 60개
- `flutter analyze`: 통과
- `flutter test`: 568개 테스트 통과
- 변경 감지: 기존 사용자 변경으로 보이는 `.claude/settings.local.json` 수정 1건 존재

## 후속 수정 반영

2026년 5월 18일 감사 직후 다음 항목을 바로 조치했다.

- C1: `Docs/milestone_next_action.md`의 노출 문자열을 제거했다. 토큰 revoke는 저장소 밖 계정 작업이므로 별도 수행이 필요하다.
- H1: `DataLoader.validateRequiredCaches`를 추가하고 `staticDataProvider` 로딩 전에 `SyncService.allTables` 필수 캐시 검증을 수행하도록 변경했다.
- H2: `RegionState.lastDangerDecayCheckedAt` HiveField 13을 추가하고 danger decay 마지막 체크 시각을 Hive에 영속화하도록 변경했다.
- M1: `Docs/milestone-runs/M7/state.md`를 spec 완료 상태에서 구현 반영 완료 상태로 정정했다.
- M2/M4: `Docs/content_status.md`와 `Docs/milestone_next_action.md`에 보관본/비최신 문서 표시를 추가했다.

남은 항목은 문서 중복 정리(M3/M5)와 후속 품질 강화 태스크이다.

## 주요 발견

### C1. 추적 문서에 GitHub 토큰으로 보이는 문자열이 남아 있다

심각도: Critical

`Docs/milestone_next_action.md` 28행에 GitHub personal access token 형식의 문자열이 포함되어 있었다. 파일은 `git ls-files` 기준 추적 대상이다. 토큰이 실제 사용 가능한 값이라면 이미 노출된 것으로 간주해야 한다.

수정 상태: 문자열은 제거했다. 토큰 revoke와 git history 정리 여부 판단은 별도 계정/저장소 운영 작업으로 남아 있다.

권장 조치:

- GitHub에서 해당 토큰을 즉시 revoke한다.
- `Docs/milestone_next_action.md` 28행을 삭제한다.
- 필요 시 git history 정리 여부를 별도 판단한다.
- 이후 `rg` 기반 secret scan 또는 pre-commit hook을 추가한다.

### H1. 정적 데이터 캐시 누락이 빈 리스트로 조용히 처리된다

심각도: High

`band_of_mercenaries/lib/core/data/data_loader.dart`의 `loadFromCache`는 캐시가 없으면 빈 리스트를 반환한다. M7 이후 `region_adjacency`, `quest_pools` 지역 상태 컬럼, `crafting_recipes`, `band_achievement_templates`, `titles`처럼 데이터 의존 시스템이 많아졌다. 신규 테이블이 서버 `data_versions` 또는 로컬 캐시에 빠지면 앱은 크래시 없이 켜질 수 있지만, 해당 기능은 조용히 비활성화된다.

수정 상태: `validateRequiredCaches`를 추가하고 `staticDataProvider`에서 필수 정적 테이블을 사전 검증하도록 변경했다.

관련 위치:

- `band_of_mercenaries/lib/core/data/data_loader.dart:30`
- `band_of_mercenaries/lib/core/data/sync_service.dart:18`
- `band_of_mercenaries/lib/core/providers/static_data_provider.dart:125`

권장 조치:

- 필수 테이블 목록과 선택 테이블 목록을 분리한다.
- 필수 테이블 누락 시 개발 모드에서 명확한 오류를 발생시킨다.
- `StaticGameData` 로딩 직후 최소 row count 검증을 추가한다.
- M7 핵심 테이블은 회귀 테스트에 포함한다.

### H2. 장기 decay 상태가 메모리 캐시에만 저장된다

심각도: High

M7 위험도 decay 체크 시각은 `RegionStateRepository._lastDecayCheckedAt` 정적 Map에만 저장된다. 앱 재시작 후에는 마지막 체크 시각이 초기화되므로, 음수 dangerScore를 가진 지역은 재시작 후 비교적 빠르게 decay 대상이 될 수 있다. 의도한 “12시간 경과”가 세션 경계에서 정확히 보존되지 않는다.

수정 상태: `RegionState.lastDangerDecayCheckedAt`을 HiveField 13으로 추가하고 `RegionStateRepository.updateLastDecayCheckedAt`이 Hive에 저장하도록 변경했다.

관련 위치:

- `band_of_mercenaries/lib/core/providers/timer_provider.dart:35`
- `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart`

권장 조치:

- `RegionState`에 `lastDangerDecayCheckedAt` 필드를 추가하거나 `settings` 박스에 region별 체크 시각을 저장한다.
- 세션 재시작, 긴 백그라운드 복귀, 시간 가속 조건을 포함한 단위 테스트를 추가한다.

### M1. M7 상태 문서가 실제 구현 상태와 맞지 않는다

심각도: Medium

`Docs/milestone-runs/M7/state.md`는 “spec 작성 단계 완료, implement-agent는 별도 단계”라고 기록한다. 반면 코드에는 M7 시스템 구현 흔적이 이미 반영되어 있다. 이 문서가 다음 작업의 기준으로 사용되면 중복 구현이나 잘못된 재작업을 유발할 수 있다.

수정 상태: M7 state 문서를 spec + 구현 반영 완료 상태로 정정하고, 구현 확인 항목과 후속 안정화 항목을 추가했다.

관련 위치:

- `Docs/milestone-runs/M7/state.md:6`
- `Docs/milestone-runs/M7/state.md:153`
- `Docs/changelog-fragments/20260517_m7-phase4-livingsphere.md`

권장 조치:

- M7 state를 “spec 완료”와 “구현 반영”으로 분리해 최신화한다.
- 구현 커밋/검증 결과/남은 후속 작업을 한 섹션에 정리한다.

### M2. `content_status.md`가 M3 기준에 머물러 있다

심각도: Medium

`Docs/content_status.md`의 마지막 업데이트는 2026년 4월 26일이며 M3 완료 기준이다. 현재 프로젝트 기준 문서처럼 보이지만 M4~M7의 제작, 위업, 칭호, 지명 의뢰, 지역 상태, 인프라 시스템을 반영하지 않는다.

수정 상태: 제목과 서두에 M3 기준 보관본임을 명시하고, 최신 기준 문서 링크를 추가했다.

관련 위치:

- `Docs/content_status.md:3`

권장 조치:

- `content_status.md`를 최신 종합 현황 문서로 갱신한다.
- 갱신 비용이 크면 `Docs/Archive/`로 이동하고 새 `project_status.md`를 만든다.

### M3. 활성 폴더와 아카이브 폴더에 동일 문서가 대량 중복되어 있다

심각도: Medium

`md5` 기준으로 활성 문서와 `Docs/Archive/` 문서가 동일한 쌍이 다수 존재한다. 예를 들어 M4~M7 spec, content-design, balance-design 문서가 현재 위치와 아카이브 위치에 동시에 있다. 이 구조는 검색 결과를 부풀리고, 어느 문서를 수정해야 하는지 모호하게 만든다.

대표 중복:

- `Docs/spec/m7_p4_1_region_state_system.md` ↔ `Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_1_region_state.md`
- `Docs/spec/m7_p4_2_questgenerator_weights.md` ↔ `Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_2_questgenerator.md`
- `Docs/spec/m7_p4_3_movement_ui.md` ↔ `Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_3_movement_ui.md`
- `Docs/spec/m7_p4_4_infrastructure_system.md` ↔ `Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_4_infrastructure.md`
- `Docs/spec/[spec]20260515_M6_phase4_3_named-quests.md` ↔ `Docs/Archive/20260515_M6_phase4_3_named-quests/spec.md`

권장 조치:

- 완료된 spec은 `Docs/Archive/` 사본만 보존하고 활성 `Docs/spec/`에서는 제거한다.
- 현재 구현 기준으로 계속 참조할 문서는 `Docs/current/` 또는 `Docs/reference/`로 승격한다.
- 아카이브된 문서에는 “보관본” 표시를 추가한다.

### M4. `milestone_next_action.md`가 오래된 임시 작업 파일로 남아 있다

심각도: Medium

`Docs/milestone_next_action.md`는 M1 페이즈 2의 다음 액션을 가리킨다. 현재 프로젝트는 M7까지 진행되었으므로, 이 파일은 최신 작업 안내 역할을 하지 않는다. 또한 C1의 보안 이슈를 포함한다.

권장 조치:

- 보안 문자열 제거 후 파일 자체를 아카이브하거나 삭제 후보로 지정한다.
- 앞으로는 “다음 액션”을 `Docs/milestone-runs/{Mx}/state.md` 또는 이슈 트래커 하나로 통일한다.

### M5. 오래된 대형 superpowers plan 문서가 활성 검색면에 남아 있다

심각도: Medium

`Docs/superpowers/plans/`에는 1,000줄 이상의 계획 문서가 다수 남아 있다. 일부는 `Docs/Archive/`에 동일 사본이 존재한다. 구현 완료 후에는 대부분 역사 기록 성격이므로 일반 검색에서 계속 노출될 필요가 낮다.

대표 파일:

- `Docs/superpowers/plans/2026-04-07-band-of-mercenaries-prototype.md`
- `Docs/superpowers/plans/2026-04-08-game-depth-and-goals.md`
- `Docs/superpowers/plans/2026-04-13-trait-system-phase5-ui.md`
- `Docs/superpowers/plans/2026-05-15-named-quests.md`

권장 조치:

- 완료된 plan은 `Docs/Archive/superpowers/`로 이동한다.
- 현재 실행 중 plan만 `Docs/superpowers/plans/`에 남긴다.

## 문서 정리 분류

### 유지 후보

다음 문서는 현재 프로젝트 운영 기준으로 남기는 편이 좋다.

- `AGENTS.md`
- `CLAUDE.md`
- `Docs/roadmap/master_roadmap.md`
- `Docs/game_overview.md`
- `Docs/flutter-ui-refactor.md`
- `Docs/flutter_commands.md`
- `Docs/CHANGELOG.md`
- `Docs/changelog-fragments/20260517_m7-phase4-livingsphere.md`
- `Docs/milestone-runs/M7/state.md` 단, 최신화 필요

### 갱신 후보

다음 문서는 현재 코드 기준과 맞추는 작업이 필요하다.

- `Docs/content_status.md`
- `Docs/milestone-runs/M7/state.md`
- `Docs/game_overview.md`
- `Docs/project_snapshot_for_ai.md`
- `Docs/skill_guide.md`

### 아카이브 후보

다음 계열은 완료 산출물이므로 활성 검색면에서 빼는 것이 좋다.

- `Docs/spec/M3/`
- `Docs/spec/M4/`
- `Docs/spec/archive/`
- `Docs/spec/discard/`
- 구현 완료된 M5/M6/M7 spec 중 `Docs/Archive/`에 동일 사본이 있는 파일
- `Docs/superpowers/plans/`의 완료 plan
- `Docs/superpowers/specs/`의 완료 design
- 오래된 `Docs/Review/code_review_2026-04-12*`

### 삭제 후보

삭제는 2차 정리에서 사용자 확인 후 수행한다.

- `Docs/milestone_next_action.md`: 보안 문자열 제거 후 삭제 또는 아카이브 후보
- 활성 위치와 아카이브 위치가 byte-for-byte 동일한 중복 문서 중 활성 사본
- `Docs/roadmap-by-gemeni.md`: 출처·최신성 불명, 현재 master roadmap과 중복 가능
- `Docs/ecc_token_efficiency_analysis.md`, `Docs/ecc_integration_review.md`: 현재 개발 기준 문서인지 확인 필요

## 코드 리뷰 메모

현재 기준으로 즉시 빌드를 깨는 문제는 발견하지 못했다. 다만 다음 위험은 M8 전에 정리하는 것이 좋다.

- `DataLoader`와 `SyncService`는 필수 테이블 누락을 더 강하게 검증해야 한다.
- `regionDangerDecayProvider`는 세션 재시작 후 정확한 12시간 간격을 보장하지 않는다.
- M7 지역 상태, 인프라 전이, 위업 발급, dialog queue는 통합 시나리오 테스트가 부족하다.
- 문서의 HiveField 점유표와 실제 모델 필드는 M8 시작 전 한 번 더 대조해야 한다.
- `QuestGenerator`의 `elite_giant_bat` 강제 spawn 하드코딩은 여전히 M9+ 제거 TODO로 남아 있다.

## 검증 결과

다음 명령을 실행했다.

```bash
flutter analyze
flutter test
```

결과는 다음과 같다.

- `flutter analyze`: No issues found
- `flutter test`: All tests passed, 568 tests

## 다음 단계

1. `Docs/milestone_next_action.md`의 보안 문자열을 제거하고 토큰을 폐기한다.
2. `Docs/milestone-runs/M7/state.md`와 `Docs/content_status.md`를 최신 구현 기준으로 갱신한다.
3. 중복 문서 목록을 기준으로 2차 정리 계획을 만든다.
4. 활성 문서 구조를 `current/reference/archive` 성격으로 재분류한다.
5. M8 착수 전 정적 데이터 필수 테이블 검증과 decay 영속화 리팩터링을 태스크로 분리한다.
