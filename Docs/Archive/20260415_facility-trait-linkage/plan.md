# Phase B: 시설 ↔ 트레잇 연계 — 구현 결과

Skill used : implement-spec

> 명세서: `Docs/spec/[spec] 20260415_facility-trait-linkage.md`
> 구현일: 2026-04-15

## 구현 계획

### 목표

시설(훈련소/의무실/야전병원) 사용 시 용병 개인의 행동 지표를 누적하여, 기존 트레잇 획득 파이프라인이 시설 조건 기반 트레잇도 자동 획득하도록 연결.

### 접근 방식

- `MercenaryStatService`에 `updateStatsForFacilityBenefit()` 정적 메서드 추가
- `quest_provider.dart`의 `_applyCompletionResult()`에서 기존 `updateStatsAfterQuest()` 직후에 호출 삽입
- `newStats` → `finalStats` 체이닝으로 시설 지표 포함한 최종 stats를 Hive 저장 및 트레잇 체크에 전달

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/features/mercenary/domain/mercenary_stat_service.dart` | 수정 | `updateStatsForFacilityBenefit()` 정적 메서드 추가 (line 106-130) |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | 시설 지표 갱신 호출 삽입 (line 338-345), `newStats` → `finalStats` 변수명 체이닝 (line 346, 351) |

## 추가된 지표 키

| 키 | 카운트 조건 |
|----|-----------|
| `training_benefit_count` | 훈련소 Lv > 0일 때 퀘스트 완료 |
| `infirmary_recovery_count` | 의무실 Lv > 0일 때 부상 상태 전환 |
| `field_hospital_benefit_count` | 야전병원 Lv > 0일 때 실패 퀘스트에서 부상 없이 생존 |

## build_runner 재실행

불요 (freezed/json_serializable 모델 변경 없음)

## 정적 분석 결과

- error: 0개
- warning: 0개
- info: 4개 (기존 `dispatch_screen.dart`의 `use_build_context_synchronously`, 이번 변경과 무관)

## 후속 작업

- Supabase `traits` 테이블에 시설 조건 기반 검증용 트레잇 3개 INSERT (operation-bom 또는 직접 SQL)
- `behavior_stats_section.dart`의 `_labelMap`에 신규 3개 지표 한글 라벨 추가 (선택적 — UI 표시용)
