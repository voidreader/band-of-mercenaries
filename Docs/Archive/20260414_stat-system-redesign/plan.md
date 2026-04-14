# 스탯 체계 재설계 구현 계획서

Skill used : implement-agent

> 명세서: Docs/20260414_stat-system-redesign_radiogaga.md
> 작성일: 2026-04-14
> 담당자: radiogaga

---

## 1. 구현 개요

용병 스탯 체계를 ATK/DEF/HP/speed(4종)에서 STR/INTELLIGENCE/VIT/AGI(4종)로 전환하였다.
기존 DEF·HP가 게임 로직에 기여하지 않는 유령 스탯 문제를 해결하고, 퀘스트 유형별 가중치 기반 partyPower 공식으로 직업 아이덴티티를 분화하였다.

---

## 2. 실행 순서 및 완료 사항

### Wave 1 — 핵심 모델 변경 (병렬)
| 태스크 | 파일 | 내용 |
|--------|------|------|
| TASK-1 | `lib/core/models/job.dart` | baseStr/Intelligence/Vit/Agi 필드 교체, speed(double)→baseAgi(int) |
| TASK-2 | `lib/features/mercenary/domain/mercenary_model.dart` | HiveField 4~7 변경, effectiveStr/Intelligence/Vit/Agi getter 신설 |
| TASK-3 | `lib/features/mercenary/domain/recruitment_service.dart` | 신규 스탯으로 용병 생성 |

### TASK-16 — build_runner
- `job.freezed.dart`, `job.g.dart`, `mercenary_model.g.dart` 재생성 완료 (5 outputs)

### Wave 2 — 서비스/도메인 + UI 독립 파일 (병렬)
| 태스크 | 파일 | 내용 |
|--------|------|------|
| TASK-4 | `lib/core/data/hive_initializer.dart` | stat_migration_v2 플래그 기반 일회성 마이그레이션 |
| TASK-5 | `lib/features/quest/domain/quest_calculator.dart` | _statWeights 추가, calculatePartyPower 헬퍼, AGI dispatch 보정 |
| TASK-9 | `lib/features/mercenary/view/mercenary_card.dart` | STR·INT·VIT·AGI 표시 |
| TASK-10 | `lib/features/mercenary/view/mercenary_detail_overlay.dart` | 4스탯 칩으로 교체 |
| TASK-11 | `lib/features/home/view/home_screen.dart` | totalPower: effectiveStr 합산 |

### Wave 3 — partyPower 연동 (병렬)
| 태스크 | 파일 | 내용 |
|--------|------|------|
| TASK-6 | `lib/features/quest/domain/quest_completion_service.dart` | QuestCalculator.calculatePartyPower 호출 |
| TASK-7/8 | `lib/features/quest/view/dispatch_detail_page.dart` | partyPower + 개별 전투력 표시 |

### Wave 4 — 테스트 파일 (병렬)
| 태스크 | 파일 | 내용 |
|--------|------|------|
| TASK-12 | `test/features/mercenary/domain/mercenary_model_test.dart` | 스탯 파라미터/getter 교체 |
| TASK-13 | `test/features/mercenary/domain/recruitment_service_test.dart` | Job/Mercenary 생성자 교체 |
| TASK-14 | `test/features/quest/domain/quest_completion_service_test.dart` | Mercenary+Job 파라미터 교체 |
| TASK-15 | `test/core/data/data_loader_test.dart` | JSON 키 및 필드 교체 |

---

## 3. 변경 파일 목록

| 파일 경로 | 변경 유형 | 내용 |
|-----------|----------|------|
| `lib/core/models/job.dart` | 수정 | baseAtk/Def/Hp/speed → baseStr/Intelligence/Vit/Agi |
| `lib/core/models/job.freezed.dart` | 자동생성 | build_runner 재생성 |
| `lib/core/models/job.g.dart` | 자동생성 | build_runner 재생성 |
| `lib/features/mercenary/domain/mercenary_model.dart` | 수정 | HiveField 4~7 변경, getter 교체 |
| `lib/features/mercenary/domain/mercenary_model.g.dart` | 자동생성 | build_runner 재생성 |
| `lib/core/data/hive_initializer.dart` | 수정 | stat_migration_v2 일회성 마이그레이션 추가 |
| `lib/features/mercenary/domain/recruitment_service.dart` | 수정 | 신규 스탯으로 용병 생성 |
| `lib/features/quest/domain/quest_calculator.dart` | 수정 | _statWeights, calculatePartyPower, AGI dispatch 보정 |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | calculateDispatchDuration에 partyAverageAgi 전달 |
| `lib/features/quest/domain/quest_completion_service.dart` | 수정 | partyPower fold → QuestCalculator.calculatePartyPower |
| `lib/features/quest/view/dispatch_detail_page.dart` | 수정 | partyPower + 개별 전투력 표시 변경 |
| `lib/features/mercenary/view/mercenary_card.dart` | 수정 | STR·INT·VIT·AGI 표시 |
| `lib/features/mercenary/view/mercenary_detail_overlay.dart` | 수정 | 4스탯 칩 교체, speed 제거 |
| `lib/features/home/view/home_screen.dart` | 수정 | effectiveAtk → effectiveStr |
| `test/features/mercenary/domain/mercenary_model_test.dart` | 수정 | 스탯 파라미터/getter/설명 교체 |
| `test/features/mercenary/domain/recruitment_service_test.dart` | 수정 | Job 생성자 파라미터 교체 |
| `test/features/quest/domain/quest_completion_service_test.dart` | 수정 | Job+Mercenary 파라미터 교체, enemyPower 조정 |
| `test/core/data/data_loader_test.dart` | 수정 | JSON 키 및 Dart 필드명 교체 |

---

## 4. verifier 검증 결과

- **판정: PASS**
- flutter analyze: 에러 0 (기존 info 4건은 이번 작업과 무관)
- flutter test: 176/176 통과

### 수정된 이슈 목록

| 이슈 | 심각도 | 처리 방법 |
|------|--------|---------|
| quest_completion_service_test.dart의 Job 생성자 미수정 | major | 직접 수정 (baseAtk→baseStr 등) |
| 거리 패널티 테스트 enemyPower 미조정 | major | enemyPower: 10 → 30 (신규 가중치 공식으로 partyPower 상승 반영) |
| quest_provider.dart에 partyAverageAgi 미전달 | minor | dispatch 메서드에 평균 AGI 계산 및 전달 추가 |
| mercenary_model_test.dart 테스트 설명 문자열 미갱신 | minor | effectiveAtk/atk → effectiveStr/str 교체 |

---

## 5. build_runner 재실행 안내

이 구현으로 인해 다음 파일들이 자동 재생성되었다:
- `lib/core/models/job.freezed.dart`
- `lib/core/models/job.g.dart`
- `lib/features/mercenary/domain/mercenary_model.g.dart`

추후 모델 수정 시에도 `dart run build_runner build --delete-conflicting-outputs`를 실행해야 한다.

---

## 6. 후속 작업 안내

- **operation-bom 선행 작업 필수**: Supabase `jobs` 테이블 컬럼 변경 (`base_atk/def/hp/speed` → `base_str/intelligence/vit/agi`) 및 85개 직업 데이터 재입력 완료 후 정상 동작 가능
- 커밋 및 문서 아카이브: `finalize-feature` 스킬 실행
