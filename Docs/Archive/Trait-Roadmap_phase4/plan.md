Skill used : implement-spec

# Phase 4: 진화 시스템 — 구현 결과

## 참조 문서
- `Docs/Trait-Roadmap.md` (Phase 4 섹션)
- `Docs/content-design/20260412_trait_system_design.md` (전체 기획서)

---

## 구현 계획 및 실제 개발 사항

### Step 1: Mercenary 모델 확장
- HiveField(16) `List<String> traitHistory` 추가 (소멸된 트레잇 key 기록)
- 생성자: `traitHistory = traitHistory ?? []` (기존 데이터 호환)

### Step 2: ActivityLogType 확장
- `traitEvolved` HiveField(7) 추가 (단일/조합 진화 공용)
- home_screen.dart _logIcon에 `'⭐'` 아이콘 매핑 추가

### Step 3: TraitEvolutionService 신규 생성
- `checkSingleEvolutions()`: 보유 acquired 트레잇 + 지표 조건 → 진화 후보
  - `trait_transitions` 테이블의 `conditionJson`과 stats 비교
  - innate 트레잇은 진화 대상에서 제외
- `checkComboEvolutions()`: 보유 2개 acquired 트레잇 → 조합 진화 후보
  - 결과 카테고리 슬롯 검증 (원본 소멸로 해방되는 경우 허용)
- `_meetsCondition()`: stats vs conditionJson 비교 (`max_quest_type_count` 특수 조건 지원)

### Step 4: MercenaryRepository 확장
- `evolveTrait(mercId, fromKey, toKey)`: traitIds에서 원본 → 진화 교체, traitHistory에 원본 추가
- `comboEvolveTrait(mercId, key1, key2, resultKey)`: 2개 제거 + 결과 추가, traitHistory에 2개 추가

### Step 5: quest_provider 통합
- `_applyCompletionResult()`에서 진화 체크 추가
- 순서: 지표 갱신 → 트레잇 획득 → 단일 진화 체크 → 조합 진화 체크
- `traitHistory: const []` → `merc.traitHistory`로 교체 (Phase 3 재획득 방지 활성화)
- 한 퀘스트 완료당 최대 1회 진화 (단일 우선, 없으면 조합)

### Step 6: 테스트
- 신규 9개 테스트 (trait_evolution_service_test.dart)
- 전체 170개 테스트 통과

---

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/features/mercenary/domain/trait_evolution_service.dart` | 신규 | 단일/조합 진화 체크 서비스 |
| `lib/features/mercenary/domain/mercenary_model.dart` | 수정 | HiveField(16) traitHistory 추가 |
| `lib/features/mercenary/data/mercenary_repository.dart` | 수정 | evolveTrait, comboEvolveTrait 메서드 추가 |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | 진화 체크 통합 + traitHistory 전달 |
| `lib/core/domain/activity_log_model.dart` | 수정 | traitEvolved enum 추가 |
| `lib/features/home/view/home_screen.dart` | 수정 | traitEvolved 아이콘 매핑 |
| `test/.../trait_evolution_service_test.dart` | 신규 | 단일/조합 진화 9개 테스트 |

## build_runner 재실행 필요 파일
- `lib/features/mercenary/domain/mercenary_model.dart` (hive_generator)
- `lib/core/domain/activity_log_model.dart` (hive_generator)

## CLAUDE.md 금지사항 위반
- 없음
