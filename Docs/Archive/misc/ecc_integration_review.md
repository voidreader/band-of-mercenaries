# everything-claude-code 도입 검토 리포트

**작성일**: 2026-04-22
**최근 업데이트**: 2026-04-22 (1단계 도입 완료)
**대상 저장소**: [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)
**목적**: 검증된 하네스 엔지니어링 프로젝트인 ecc에서 `band-of-mercenaries` 프로젝트에 기여할만한 agent/skill을 식별하고, 토큰 효율 및 AI 개발환경 개선 방향을 제시한다.

## 범례

- ✅ **적용 완료**
- 🟡 **부분 적용** (일부만 도입됨)
- ⬜ **미적용**

---

## 현황 요약

현재 프로젝트 `.claude/` 구성:

- **agents (5)**: `analyzer`, `architect`, `coder`, `planner`, `verifier`
- **skills (13)**: `balance-designer`, `content-designer`, `data-generator`, `docs-writer`, `finalize-feature`, `finalize-minor-task`, `implement-agent`, `implement-spec`, `merge-changelog`, `milestone-runner`, `spec-pipeline`, `spec-writer`, `verify-spec`

이미 spec-pipeline 기반 자체 워크플로우가 잘 갖춰져 있으므로, **대체가 아닌 보완 용도**로만 추가 도입을 권장한다.

ecc 저장소 규모:
- agents: 48개
- skills: 183개 (언어별 패턴/리뷰/테스트, AI 하네스, 토큰 관리, 도메인 전문 등)

---

## 최우선 권장: Flutter 직접 관련 (즉시 효과)

### ⬜ 1. `dart-flutter-patterns` (skill)
**출처**: `skills/dart-flutter-patterns/SKILL.md`

- 용도: Riverpod/Freezed/async/widget 패턴 copy-paste 카탈로그
- 커버 영역: null safety, immutable state(sealed/freezed), async composition, widget architecture(class 추출, const propagation), state management(BLoC/Riverpod), GoRouter, Dio, 에러 핸들링, 테스트
- **우리 프로젝트 효과**: `coder` 에이전트가 참조할 레퍼런스로 활용 → Flutter 관용구 실수 감소, 재작업 빈도↓

### ⬜ 2. `flutter-dart-code-review` (skill)
**출처**: `skills/flutter-dart-code-review/SKILL.md`

- 용도: 라이브러리-agnostic Flutter/Dart 리뷰 체크리스트
- 항목: 프로젝트 구조, Dart 언어 함정, 상태관리, 위젯 성능, 접근성, 보안, 아키텍처
- **우리 프로젝트 효과**: `verifier` 에이전트 프롬프트에 체크리스트로 주입 → 리뷰 일관성↑
- 참고: 3번 `flutter-reviewer` agent 도입 시 내부에 해당 체크리스트를 프로젝트 컨벤션에 맞춰 내장하였으므로, 별도 skill 도입은 선택 사항

### ✅ 3. `flutter-reviewer` (agent)
**출처**: `agents/flutter-reviewer.md`
**적용 위치**: `.claude/agents/flutter-reviewer.md`
**적용일**: 2026-04-22

- 용도: Flutter 전용 리뷰 에이전트 (widget rebuild, 상태관리 안티패턴)
- 툴: Read, Grep, Glob, Bash (read-only)
- **우리 프로젝트 효과**: 현 `verifier`(일반 Flutter/Dart 검증)보다 더 깊이 있는 Flutter 특화 리뷰. 역할 분리 가능
- **커스터마이즈 내용**:
  - verifier와 역할 분리 명시 (verifier = 명세 검증 / flutter-reviewer = 코드 품질)
  - Riverpod 전용 컨벤션 반영 (BLoC/GetX/MobX 항목 제거)
  - feature 모듈 3계층(view/domain/data) 경계 검증 추가
  - 모바일 프레임(`_MobileFrame`) 상태 기반 렌더링 컨벤션 반영
  - 한국어 출력 형식
- **파이프라인 편입**: `implement-agent` PHASE 3에서 verifier와 병렬 호출

### ✅ 4. `dart-build-resolver` (agent)
**출처**: `agents/dart-build-resolver.md`
**적용 위치**: `.claude/agents/dart-build-resolver.md`
**적용일**: 2026-04-22

- 용도: `dart analyze`, `flutter analyze`, `pubspec.yaml` 충돌, `build_runner` 실패를 최소 수정으로 해결
- 툴: Read, Write, Edit, Bash, Grep, Glob
- **우리 프로젝트 효과**: 현재 없음. 빌드 실패 시 수동 디버깅 루프 시간 대폭 단축 (freezed/hive_generator/riverpod_generator 4종 코드 생성 에러 빈발 환경에 적합)
- **커스터마이즈 내용**:
  - `band_of_mercenaries/` 서브디렉토리 prefix 명시
  - 4종 코드 생성기(freezed/json_serializable/hive_generator/riverpod_generator) 컨텍스트 반영
  - 프로젝트 특화 에러 패턴 추가 (Hive typeId 중복, `@JsonKey` snake_case 누락 등)
  - iOS/Android 플랫폼 섹션은 최소화 (현재 주로 웹 빌드 환경)
  - 한국어 출력 형식
- **파이프라인 편입**:
  - `implement-agent` PHASE 2.5 빌드 게이트에서 조건부 호출
  - `implement-spec` 9a 정적 분석 검증에서 복잡 에러 발생 시 위임

---

## 토큰 효율 / AI 개발환경 개선

### ⬜ 5. `context-budget` (skill)
**출처**: `skills/context-budget/SKILL.md`

- 용도: 로드된 agent/skill/rule/MCP의 토큰 소비 감사, 블로트 식별, 우선순위 기반 절감안 제시
- **우리 프로젝트 효과**: 현재 13 skill + 5 agent가 모두 필요한지 정기 감사 가능. 세션 초기 컨텍스트 예산 가시화

### ⬜ 6. `search-first` (skill)
**출처**: `skills/search-first/SKILL.md`

- 용도: 코드 작성 전 기존 패키지/유틸/MCP/스킬 병렬 탐색 → 채택/확장/커스텀 중 의사결정
- **우리 프로젝트 효과**: 재발명 방지 → 의존성 추가 전 검토 루틴 체계화

### ⬜ 7. `strategic-compact` (skill)
- 용도: 대화 길이 증가 시 compact 전략
- **우리 프로젝트 효과**: 장시간 구현 세션 토큰 소비 완화

### ⬜ 8. `ck` (checkpoint skill)
**출처**: `skills/ck/` (SessionStart 훅 포함)

- 용도: 세션 간 상태 체크포인트 저장/복구
- **우리 프로젝트 효과**: 마일스톤 단위 장기 작업에서 컨텍스트 재로딩 비용↓

### ⬜ 9. `agent-harness-construction` (skill)
- 용도: action space / observation format / recovery 설계 원리
- **우리 프로젝트 효과**: 자체 `planner/coder/verifier` 프롬프트 튜닝 시 바이블로 활용

### ⬜ 10. `harness-optimizer` (agent)
- 용도: 하네스 설정 자체를 `/harness-audit` 점수 기반으로 최적화, before/after 델타 측정
- **우리 프로젝트 효과**: 정기 감사 에이전트 — 하네스 품질 수치로 추적 가능

---

## 품질 보조 (선택적)

### ⬜ `silent-failure-hunter` (agent)
- 용도: 빈 `catch {}`, 로그 미흡, 위험한 fallback, 에러 전파 누락 탐지
- **우리 프로젝트 효과**: Flutter async/Future/Stream에서 특히 유용. M2a 장비/효과 시스템처럼 복잡해질수록 가치↑

### ⬜ `code-simplifier` / `refactor-cleaner` (agent)
- 용도: 리팩토링 전용
- **우리 프로젝트 효과**: 마일스톤 완료 후 기술부채 정리용

---

## 권장 도입 순서

| 단계 | 상태 | 도입 항목 | 기대 효과 |
|---|---|---|---|
| 1 | ✅ 완료 (2026-04-22) | `dart-build-resolver` + `flutter-reviewer` agent 복사 | 즉시 체감 — 빌드 에러 수렴 속도↑, Flutter 리뷰 품질↑ |
| 2 | ⬜ 보류 | `dart-flutter-patterns` + `flutter-dart-code-review` skill 복사 + `coder`/`verifier` 프롬프트에서 링크 | 관용구 준수율↑, 리뷰 일관성↑ |
| 3 | ⬜ 대기 | `context-budget` 실행 → 현재 세션 블로트 확인 → 불필요 skill 아카이브 | 세션 초기 컨텍스트 여유↑ |
| 4 | ⬜ 대기 | 필요 시 `ck` / `search-first` / `harness-optimizer` 도입 | 장기 세션 효율, 재발명 방지, 하네스 정기 감사 |

### 1단계 도입 상세 (2026-04-22)

**신규 파일:**
- `.claude/agents/dart-build-resolver.md`
- `.claude/agents/flutter-reviewer.md`

**수정 파일:**
- `.claude/skills/implement-agent/SKILL.md`
  - description 갱신: `planner → coder → dart-build-resolver → verifier + flutter-reviewer 병렬`
  - PHASE 2.5 빌드 게이트 신설 (조건부 `dart-build-resolver` 위임)
  - PHASE 3를 병렬 리뷰 단계로 확장 (verifier + flutter-reviewer 동시 호출, 결과 취합 규칙 명시)
- `.claude/skills/implement-spec/SKILL.md`
  - 9a 정적 분석 검증 단계에 빌드 게이트 편입 (단순 에러는 main 직접, 복잡 에러는 `dart-build-resolver` 위임)
- `Docs/skill_guide.md`
  - `implement-agent` 항목 파이프라인 설명 갱신

**비편입 결정:**
- `flutter-reviewer`는 `implement-spec`에는 편입하지 않음 (경량/소규모 포지셔닝 유지, 토큰 절약 목표 부합)

**드라이런 대상:**
- 다음 실전 `/implement-agent` 또는 `/implement-spec` 실행 시 새 파이프라인 동작 확인
- 관찰 지표: coder 재작업 감소율, verifier/flutter-reviewer 이슈 중복률, 병렬 호출 컨텍스트 비용 vs 순차 대비 이득

---

## 도입하지 않아도 되는 것 (중복/불필요)

- `planner`, `architect`, `code-architect`, `code-reviewer` (ecc) — 우리 커스텀 spec-pipeline과 중복
- 타 언어 스킬 전체 (kotlin/rust/go/swift/python/ts 등) — 현 프로젝트 무관
- 특정 도메인 스킬 (healthcare, finance, logistics 등) — 무관
- `tdd-workflow` — 현재 프로젝트 TDD 도입 미결정 상태, 필요 시 재검토

---

## 다음 액션 후보

1. ~~ecc에서 1단계 항목(`dart-build-resolver`, `flutter-reviewer`) 실제 복사 및 프로젝트 통합~~ ✅ 완료 (2026-04-22)
2. 1단계 드라이런 후 효과 측정 → 2단계(`dart-flutter-patterns`/`flutter-dart-code-review` skill) 도입 판단
3. `context-budget` 감사 실행 및 결과 별도 문서화
4. (선택) 자체 spec-pipeline 프롬프트를 `agent-harness-construction` 원리로 재검토
