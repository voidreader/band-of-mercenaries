# M7 실행 상태

> 시작: 2026-05-16T00:00:00+09:00
> 마지막 업데이트: 2026-05-18T00:00:00+09:00
> 현재 페이즈: 4 (spec 작성 완료 + 통합 구현 반영)
> 상태: completed (M7 마일스톤 spec 및 Flutter 구현 반영 완료. 후속 감사 항목은 별도 안정화 태스크로 관리)

## 로드맵 요구사항 요약

M7 "지역 생활권 확장" — M4의 시작 거점 패턴을 주변 5~10개 리전으로 확장. 전 대륙을 얕게 채우지 않고, 시작 거점 주변에 재료·사건·위험·이동 목적이 있는 생활권을 만든다.

핵심 시스템 5종: 생활권 리전 묶음 / 지역 특산품 / 지역 상태 변화(위험도·안정도·해금) / 마을 인프라 성장 / 이동 목적 강화. 스키마 확장: `regionStates` 또는 신규 지역 상태 모델. 데이터 채우기: 리전 5~10 / 특산 재료 10~20 / 고정 발견 20~40 / 상태별 퀘스트 풀 30~50. 누적 플레이 5~8시간 안에 주요 사건 2+, 제작 목표 2+, 지역 상태 변화 2+ 체험.

선행 의존성: M1~M6 모두 완료.

## 후속 마일스톤 연결

2026년 5월 18일 `Docs/roadmap/master_roadmap.md` v3.2 개정으로 M8 이후 로드맵이 세분화되었다. M7 완료 이후에는 기존 단일 M8 "세력 재도입"으로 바로 진입하지 않고, 다음 순서로 진행한다.

- M8a "세력의 귀환": 대표 세력 2~3개 최소 절편과 세력·지명·엘리트·연계 의뢰 전투 보고서 MVP를 구현한다.
- M8b "진짜 전투의 시작": 특별 의뢰부터 턴 기반 전투 시뮬레이터 v1을 적용한다.
- M8.5 "재미 가시화와 폴리싱": 생활권 완성도 대시보드, 간판 용병 솔로/소수정예 루프, 전투 감정 반응, 히든 스탯, UI 폴리싱, 주간 기여도 랭킹 MVP를 구현한다.
- M9 "완성과 균형": 일반 의뢰 전투화, 데이터 확장, stub 시설 연동, 전체 밸런싱을 수행한다.

신규 상태 문서는 `Docs/milestone-runs/M8a/state.md`, `Docs/milestone-runs/M8b/state.md`, `Docs/milestone-runs/M8.5/state.md`, `Docs/milestone-runs/M9/state.md`를 기준으로 관리한다.

## 구현 반영 상태

2026년 5월 18일 1차 프로젝트 감사 기준으로 M7 페이즈 4 시스템은 Flutter 코드에 반영되어 있다. 이 문서의 이전 상태값은 "spec 작성 단계 완료, implement-agent 별도"였으나, 실제 코드에는 지역 상태, QuestGenerator 가중치, 이동 UI, 마을 인프라 성장 시스템이 이미 연결되어 있었다.

구현 확인 항목은 다음과 같다.

- `RegionState`에 위험도 점수, 위험도 단계, 해금 플래그, 의뢰 풀 누적 완료 횟수, 인프라 단계가 반영되어 있다.
- `QuestGenerator.computeFinalWeight`가 위험도 단계, 해금 플래그, cumulative cap, 지명 의뢰 가중치를 통합 계산한다.
- `region_adjacency` 정적 데이터 모델과 `MovementDistanceCalculator`가 이동 거리 계산에 연결되어 있다.
- `SettlementInfrastructureConfig`, 외래 좌판, 생활권 정보, 인프라 승급 다이얼로그가 반영되어 있다.
- `flutter analyze`와 전체 `flutter test`는 2026년 5월 18일 감사 시점에 통과했다.

후속 안정화 항목은 다음과 같다.

- 정적 데이터 필수 테이블 검증 강화
- danger decay 마지막 체크 시각 영속화
- `content_status.md` 최신화 또는 보관본 명시
- 활성 문서와 `Docs/Archive/` 중복 정리

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 시작 생활권 리전 5~10개 선정 + 역할 매핑
  - 참고 문서: `Docs/proto_design.md`, M4 산출물(`Docs/milestone-runs/M4/`), 현재 `regions`/`region_sectors`, M5 제작 재료 출처
  - 산출물: `Docs/content-design/[content]20260516_m7_livingsphere_regions.md`
  - 완료: 2026-05-16T22:30:00+09:00
- [x] 2. 지역 상태 변화 규칙 설계 (위험도·안정도·해금 모델)
  - 참고 문서: M3 region-transform 시스템, M5 firstAcquiredItem 영속 추적
  - 산출물: `Docs/content-design/[content]20260516_m7_region_state_rules.md`
  - 완료: 2026-05-16T22:40:00+09:00
- [x] 3. 마을 인프라 성장 설계 (방문 거점·대장간·시장 단계별 개선)
  - 참고 문서: M4 신뢰도 4단계, M5 낡은 대장간, M4 VillageVisitSection
  - 산출물: `Docs/content-design/[content]20260517_m7_settlement_infrastructure_growth.md`
  - 완료: 2026-05-17T07:55:00+09:00
- [x] 4. 이동 목적 강화 + 생활권 진행 곡선 (중간 목표 2 / 최종 목표 1)
  - 참고 문서: M4 이동 시스템, M6 위업·체인 컨텐츠 흐름
  - 산출물: `Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md`
  - 완료: 2026-05-17T08:05:00+09:00

## 페이즈 2: 밸런스 확정

**상태**: completed

계획된 산출물:
- [x] 1. 지역 특산 재료 경제 곡선
  - 입력 의존: 페이즈 1 산출물 1, 2
  - 산출물: `Docs/balance-design/[balance]20260517_m7_material_economy_curve.md`
  - 완료: 2026-05-17T08:15:00+09:00
- [x] 2. 지역 상태 변화 임계값 확정
  - 입력 의존: 페이즈 1 산출물 2
  - 산출물: `Docs/balance-design/[balance]20260517_m7_region_state_thresholds.md`
  - 완료: 2026-05-17T08:20:00+09:00
- [x] 3. 마을 인프라 성장 비용·요구 사건 수 확정
  - 입력 의존: 페이즈 1 산출물 3
  - 산출물: `Docs/balance-design/[balance]20260517_m7_infrastructure_growth_curve.md`
  - 완료: 2026-05-17T08:30:00+09:00

## 페이즈 3: 데이터 생성

**상태**: completed

계획된 산출물:
- [x] 1. 생활권 리전 정의 5~10개 (regions/region_sectors UPDATE + region_adjacency 신설)
  - 입력 의존: 페이즈 1 산출물 1, 페이즈 1 산출물 4
  - 대상 테이블: `regions` (UPDATE 6행), `region_adjacency` (신규 + INSERT 22행)
  - 비고: 인라인 SQL 마이그레이션 스크립트 (M4 region_migration 패턴 답습). data-generator 타입 스펙 부재로 main agent 직접 작성
  - 산출물: `Docs/content-data/m7_region_metadata.sql` + `Docs/content-data/m7_region_metadata.md`
  - 완료: 2026-05-17T08:40:00+09:00
- [x] 2. 지역 특산 재료 10~20개
  - 입력 의존: 페이즈 1 산출물 1 + 페이즈 2 산출물 1
  - 대상 테이블: `items` (8행 INSERT 완료, Supabase 반영)
  - 타입: `types/item.md` 재사용 (material 카테고리 — 기존 12행 패턴 답습)
  - 산출물: `Docs/content-data/[item]20260517_m7-region-exclusive.csv` + `.md`
  - 완료: 2026-05-17T08:50:00+09:00 — Supabase items 50→58, material 12→20, region_exclusive 4→12
  - 범위 외 (별도 산출물): quest_pool_material_drops +34행 → 페이즈 3 #4 / elite_loot_tables +5~8행 → 신규 elite 별도 / travel_choice_results +8행 → 별도 / chain_quests.reward_items +4~6행 → 페이즈 3 #5
- [x] 3. 지역 상태별 고정 발견 15행 신규
  - 입력 의존: 페이즈 1 산출물 1·2 + 페이즈 2 산출물 1
  - 대상 테이블: `region_discoveries` (15행 INSERT 완료, Supabase 35→50)
  - 처리 방식: data-generator 타입 부재 (region-discovery 미지원) — main agent 직접 작성 (M2b `[region-discovery]20260423` 패턴 답습)
  - 산출물: `Docs/content-data/[region-discovery]20260517_m7-discoveries.csv` + `.md`
  - 완료: 2026-05-17T09:00:00+09:00 — discovery_type 분포 normal 11 / info 3 / hidden_quest 1, 신규 8종 region_exclusive 재료 모두 매핑
- [x] 4. 지역 상태별 퀘스트 풀 36행 + 신규 3 컬럼 DDL
  - 입력 의존: 페이즈 1 산출물 2 + 페이즈 2 산출물 2
  - 대상 테이블: `quest_pools` (ALTER + 36행 INSERT)
  - 처리 방식: 옵션 B — SQL 마이그레이션 스크립트, 페이즈 4 #2 spec 단계에서 일괄 적용 (즉시 미적용)
  - 산출물: `Docs/content-data/m7_quest_pools_state.sql` + `Docs/content-data/m7_quest_pools_state.md`
  - 완료: 2026-05-17T15:25:00+09:00 — region 분배 r3:2/r31:6/r127:5/r9:6/r10:5/r146:6/r38:6, 풀 분포 cumulative 7/oneshot 6/상태조건 11/일반 12
- [x] 5. 인프라 narrative + chain_m7_mist_clearing + M5 신규 6 레시피 통합
  - 입력 의존: 페이즈 1 산출물 3·4 + 페이즈 2 산출물 3 + 페이즈 3 산출물 3
  - 대상 테이블: `items` (+6), `crafting_recipes` (+6), `chain_quests` (+2) — 페이즈 4 #4 spec 적용 위임
  - 처리 방식: SQL 마이그레이션 + narrative 메타 통합 (data-generator chain-quest/crafting-recipe 타입 부재)
  - 산출물: `Docs/content-data/m7_phase3_5_recipes_chain.sql` + `Docs/content-data/m7_phase3_5_narrative.md`
  - 완료: 2026-05-17T15:35:00+09:00 — items 6 + crafting_recipes 6 (M5 unlock_condition 확장 regionFlag/all/infrastructureTier) + chain_m7_mist_clearing 2단계, narrative 17행

## 페이즈 4: 개발 명세

**상태**: in_progress

계획된 산출물:
- [x] 1. RegionState 모델 확장 + 지역 상태 시스템 (spec 작성 완료, 구현은 4 spec 통합 implement-agent로 위임)
  - 입력 의존: 페이즈 1 산출물 2 + 페이즈 2 산출물 2 + 페이즈 3 산출물 3·5
  - 산출물: `Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_1_region_state.md` (verify-spec PASS, 5/5 항목)
  - 완료: 2026-05-17T16:00:00+09:00 — spec-pipeline (spec-writer Sonnet + verify-spec Opus) PASS. implement-agent TASK-1 시도 후 사용자 요청으로 옵션 C-1 (변경 되돌리기) 채택. 페이즈 4 #2/#3/#4 spec 작성 후 4 spec 통합 implement로 진행 예정.
- [x] 2. `QuestGenerator` 지역 상태 가중치 분기 (spec 작성 완료, 구현은 4 spec 통합 implement-agent로 위임)
  - 입력 의존: 페이즈 1 산출물 2 + 페이즈 2 산출물 2 + 페이즈 3 산출물 4 + 페이즈 4 산출물 1
  - 산출물: `Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_2_questgenerator.md` (verify-spec PASS, 5/5 항목)
  - 완료: 2026-05-17T17:30:00+09:00 — spec-pipeline (spec-writer Sonnet + verify-spec Opus) PASS. 12 FR, RegionStateEffect 신규 sealed union, RegionStateWeightConfig 4×4 매트릭스+14 flag, QuestGenerator.computeFinalWeight, RegionStateRepository.applyDangerScoreFromQuest 본체(페이즈 4 #1 FR-4a 활성화), RegionState HiveField 11 questPoolCompletionCounts, quest_pools SQL 마이그레이션 통합. 4 spec 통합 implement-agent 정책.
- [x] 3. 이동 화면 + 거점 상세 UI — 생활권 표시 (spec 작성 완료, 구현은 4 spec 통합 implement-agent로 위임)
  - 입력 의존: 페이즈 1 산출물 4 + 페이즈 1 산출물 1 + 페이즈 3 산출물 1 + 페이즈 4 산출물 1
  - 산출물: `Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_3_movement_ui.md` (verify-spec PASS, 5/5 항목)
  - 완료: 2026-05-17T18:30:00+09:00 — spec-pipeline (spec-writer Sonnet + verify-spec Opus) PASS. 12 FR, RegionAdjacency 신규 freezed + StaticGameData.regionAdjacencyMap, MovementDistanceCalculator 헬퍼(UserData.calculateDistance fallback 보존), LivingsphereJumpBar 7리전 빠른 점프 칩, RegionStatusBadgeRow dangerLevel+unlockedFlags 미니 배지, AppTheme.dangerLevelColor/Label 헬퍼, VillageVisitSection 인프라 배지 진입점(페이즈 4 #4 graceful degradation), 광장 이정표 -10% 곱셈 합산, region_adjacency 마이그레이션 통합. 좌우 화살표 패턴 보존 + 칩 추가 절충안. Visual Companion 미사용(텍스트 명세 충분).
- [x] 4. 마을 인프라 성장 시스템 + 진입점 통합 (spec 작성 완료, 구현은 4 spec 통합 implement-agent로 위임)
  - 입력 의존: 페이즈 1 산출물 3 + 페이즈 2 산출물 3 + 페이즈 3 산출물 5 + 페이즈 4 산출물 1·3
  - 산출물: `Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_4_infrastructure.md` (verify-spec PASS, 5/5 항목)
  - 완료: 2026-05-17T19:30:00+09:00 — spec-pipeline (spec-writer Sonnet + verify-spec Opus) PASS. 16 FR, RegionState HiveField 12(infrastructureTier) / UserData HiveField 27(foreignStallVisitCount) / ActivityLogType HiveField 34(settlementInfrastructureUpgraded), SettlementInfrastructureConfig 정적 상수(임계 2/4/6 + 보상 100·200·500 + 외래좌판 가격 8종 + Tier 4 -20% + 광장 이정표 -10%), settlementInfrastructureTierProvider family 실 정의(페이즈 4 #3 stub 활성화), _evaluateInfrastructureTransition 본체(페이즈 4 #1 FR-4e 위임 활성), VillageFacility.foreignStall + ForeignStallScreen + 외래 상인 케일 NPC + ChiefHouseScreen 생활권 정보 버튼(Tier 2+), HerbalistService 곱셈 합산 multiplier 3종, CraftingService _isUnlockedM7 4 type(regionFlag/infrastructureTier/all/any), SettlementInfrastructureUpgradedDialog medium priority, items 6행 + crafting_recipes 6행 + chain_m7_mist_clearing 2단계 + band_achievement_templates 1행("변방의 영주") 마이그레이션 통합.

## 페이즈 간 의존

- 페이즈 2 전체 ← 페이즈 1 산출물 1, 2, 3
- 페이즈 3 항목 1 ← 페이즈 1 항목 1
- 페이즈 3 항목 2 ← 페이즈 1 항목 1 + 페이즈 2 항목 1
- 페이즈 3 항목 3, 4 ← 페이즈 1 항목 2 + 페이즈 2 항목 2
- 페이즈 3 항목 5 ← 페이즈 1 항목 3 + 페이즈 2 항목 3
- 페이즈 4 항목 1 ← 페이즈 1 항목 2 + 페이즈 2 항목 2
- 페이즈 4 항목 2 ← 페이즈 1 항목 2 + 페이즈 3 항목 4
- 페이즈 4 항목 3 ← 페이즈 1 항목 4
- 페이즈 4 항목 4 ← 페이즈 1 항목 3 + 페이즈 2 항목 3 + 페이즈 3 항목 5

## 실행 이력

- 2026-05-16T00:00:00+09:00: 마일스톤 시작
- 2026-05-16T00:00:00+09:00: 4페이즈 계획 승인 (페이즈 1: 4개 / 페이즈 2: 3개 / 페이즈 3: 5개 / 페이즈 4: 4개)
- 2026-05-16T22:30:00+09:00: 페이즈 1 산출물 1 "시작 생활권 리전 7개 선정 + 역할 매핑" 완료 (`Docs/content-design/[content]20260516_m7_livingsphere_regions.md`)
- 2026-05-16T22:40:00+09:00: 페이즈 1 산출물 2 "지역 상태 변화 규칙 설계" 완료 (`Docs/content-design/[content]20260516_m7_region_state_rules.md`)
- 2026-05-17T07:55:00+09:00: 페이즈 1 산출물 3 "마을 인프라 성장 설계" 완료 (`Docs/content-design/[content]20260517_m7_settlement_infrastructure_growth.md`)
- 2026-05-17T08:05:00+09:00: 페이즈 1 산출물 4 "이동 목적 강화 + 생활권 진행 곡선" 완료 (`Docs/content-design/[content]20260517_m7_livingsphere_progression_curve.md`)
- 2026-05-17T08:05:00+09:00: 페이즈 1 종료 — 4/4 산출물 모두 완료
- 2026-05-17T08:10:00+09:00: 페이즈 2 시작 승인 — 산출물 3개 (재료 경제 곡선 / 상태 임계값 / 인프라 비용)
- 2026-05-17T08:15:00+09:00: 페이즈 2 산출물 1 "지역 특산 재료 경제 곡선" 완료 (`Docs/balance-design/[balance]20260517_m7_material_economy_curve.md`)
- 2026-05-17T08:20:00+09:00: 페이즈 2 산출물 2 "지역 상태 변화 임계값 확정" 완료 (`Docs/balance-design/[balance]20260517_m7_region_state_thresholds.md`)
- 2026-05-17T08:30:00+09:00: 페이즈 2 산출물 3 "마을 인프라 성장 비용·요구 사건 수 확정" 완료 (`Docs/balance-design/[balance]20260517_m7_infrastructure_growth_curve.md`)
- 2026-05-17T08:30:00+09:00: 페이즈 2 종료 — 3/3 산출물 모두 완료
- 2026-05-17T08:35:00+09:00: 페이즈 3 시작 승인 — 산출물 5개 (regions/region_adjacency / items / region_discoveries / quest_pools / narrative+체인)
- 2026-05-17T08:40:00+09:00: 페이즈 3 산출물 1 "regions/region_adjacency" 완료 (`Docs/content-data/m7_region_metadata.sql`)
- 2026-05-17T08:50:00+09:00: 페이즈 3 산출물 2 "지역 특산 재료 8종" 완료 + Supabase items INSERT 8행 (`Docs/content-data/[item]20260517_m7-region-exclusive.csv`)
- 2026-05-17T09:00:00+09:00: 페이즈 3 산출물 3 "지역 상태별 고정 발견 15행" 완료 + Supabase region_discoveries INSERT 15행 (`Docs/content-data/[region-discovery]20260517_m7-discoveries.csv`)
- 2026-05-17T15:25:00+09:00: 페이즈 3 산출물 4 "지역 상태별 퀘스트 풀 36행 + 신규 3 컬럼 DDL" 완료 (`Docs/content-data/m7_quest_pools_state.sql` — 페이즈 4 #2 spec 단계 적용 위임)
- 2026-05-17T15:35:00+09:00: 페이즈 3 산출물 5 "인프라 narrative + 체인 + 신규 6 레시피" 완료 (`Docs/content-data/m7_phase3_5_recipes_chain.sql` + `_narrative.md` — 페이즈 4 #4 spec 단계 적용 위임)
- 2026-05-17T15:35:00+09:00: 페이즈 3 종료 — 5/5 산출물 모두 완료
- 2026-05-17T15:40:00+09:00: 페이즈 4 시작 승인 — 산출물 4개 (RegionState / QuestGenerator / MovementUI / 인프라 시스템)
- 2026-05-17T16:00:00+09:00: 페이즈 4 산출물 1 spec 작성 완료 (`Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_1_region_state.md`, verify-spec PASS). implement-agent 1차 시도 후 옵션 C-1로 4 spec 통합 implement 채택. TASK-1 변경 git checkout으로 되돌림.
- 2026-05-17T17:30:00+09:00: 페이즈 4 산출물 2 spec 작성 완료 (`Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_2_questgenerator.md`, verify-spec PASS 5/5). 페이즈 4 #1과의 HiveField 분담(8·9·10 vs 11) 명시, applyDangerScoreFromQuest 본체 활성화, quest_pools SQL 마이그레이션 통합. 4 spec 통합 implement 정책 유지 — 페이즈 4 #3·#4 spec 작성 후 한 번에 implement-agent 진행.
- 2026-05-17T18:30:00+09:00: 페이즈 4 산출물 3 spec 작성 완료 (`Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_3_movement_ui.md`, verify-spec PASS 5/5). MovementScreen 좌우 화살표 보존 + LivingsphereJumpBar 칩 추가 절충, RegionAdjacency 신규 freezed + MovementDistanceCalculator, AppTheme.dangerLevelColor 4종, VillageVisitSection 인프라 단계 graceful degradation, region_adjacency 마이그레이션 통합. 페이즈 4 #4 spec 작성 후 통합 implement-agent 진행.
- 2026-05-17T19:30:00+09:00: 페이즈 4 산출물 4 spec 작성 완료 (`Docs/Archive/20260517_m7_phase4_livingsphere/spec_p4_4_infrastructure.md`, verify-spec PASS 5/5). 16 FR + Q-1~Q-13 의사결정 + HiveField 12/27/34 분담 + 페이즈 4 #1 FR-4e 위임 활성화 + 페이즈 4 #3 stub graceful degradation 활성화 + items 6/recipes 6/chain 2단계/위업 1행 마이그레이션 통합. **페이즈 4 마지막 spec 완료** — 4 spec 통합 implement-agent 진행 단계 진입 가능.
- 2026-05-17T19:30:00+09:00: 페이즈 4 종료 — 4/4 spec 작성 완료 (verify-spec 4종 모두 5/5 PASS). 상태 paused로 갱신 — 사용자가 통합 implement-agent 호출 대기. M7 마일스톤 spec 단계 완료. 다음 단계: 4 spec 통합 implement (페이즈 4 #1 → #2 → #4 → #3 순서 권장, build_runner 1회 통합 실행).
- 2026-05-17T19:45:00+09:00: M7 마일스톤 spec 작성 완료 보고 — milestone-runner 7단계 종료. 상태 paused → completed. 총 16 산출물(컨텐츠 4 + 밸런스 3 + 데이터 5 + 명세 4) 생성. SQL 마이그레이션 3종(quest_pools/region_metadata/recipes_chain) + Supabase 적용 완료 2종(items 8 / region_discoveries 15) 보유. 통합 implement-agent는 사용자가 별도 호출.
- 2026-05-18T00:00:00+09:00: 프로젝트 1차 감사에서 M7 페이즈 4 구현이 코드에 이미 반영된 상태임을 확인. 문서 상태를 "spec 완료"에서 "spec + 구현 반영 완료"로 정정. 후속 안정화 항목은 감사 리포트와 별도 태스크로 분리.
