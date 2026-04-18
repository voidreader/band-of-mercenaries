# M1 실행 상태

> 시작: 2026-04-17T08:19:03Z
> 마지막 업데이트: 2026-04-18T01:25:00Z
> 현재 페이즈: 4
> 상태: completed

## 로드맵 요구사항 요약

- 테마: 세력 가입이 퀘스트 보상·성공률·경제 수치에 실제 영향을 미친다.
- 핵심 시스템: 패시브 효과 연동 / 세력 태그+전용 퀘스트 / 파견 상성 / 명성 등급 보너스
- 스키마 확장: `faction_passive_bonuses`(신규), `quest_synergy_matrix`(신규), `quest_pools`에 `faction_tag`+`sector_type` 일괄 추가, `ranks` 보너스 필드
- 종료 조건: F랭크 신규 유저가 단서 발견→가입→전용 퀘스트→평판→랭크 업까지 30~60분 연속 플레이 가능
- 선행: 세력 Phase A/B, 트레잇·시설·조사 완료

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 세력 패시브 효과 매핑 기획
  - 참고 문서: `Docs/content-design/[content]20260416_faction_system.md`, `Docs/roadmap/master_roadmap.md#M1`
  - 설명: 14개 세력의 `passive_bonus_json` → 효과 타입(reward_multiplier, success_rate_bonus, recovery_time_reduction, recruitment_discount 등) 매핑
  - 산출물: `Docs/content-design/[content]20260417_faction_passive_mapping.md`
  - 완료: 2026-04-17T08:32:00Z
- [x] 2. 세력 태그 퀘스트 & 전용 퀘스트 컨셉
  - 참고 문서: `Docs/content-design/[content]20260416_faction_system.md`
  - 설명: 14개 세력별 태그 퀘스트 톤, 세력당 7개 전용 퀘스트(기본 3 + 고급 4), 총 98개 컨셉 가이드라인
  - 산출물: `Docs/content-design/[content]20260417_faction_quests.md`
  - 완료: 2026-04-17T08:50:00Z
- [x] 3. 파견 상성 시스템 컨셉
  - 참고 문서: `Docs/roadmap/master_roadmap.md#M1`
  - 설명: role(6개) × 퀘스트 유형 상성 매트릭스, 성공률 +%p 독립 레이어, 트레잇 시너지 확장, UI 힌트
  - 산출물: `Docs/content-design/[content]20260417_dispatch_synergy.md`
  - 완료: 2026-04-17T09:00:00Z
- [x] 4. 명성 등급별 보너스 컨셉
  - 참고 문서: `Docs/roadmap/master_roadmap.md#M1`
  - 설명: F~A 6등급 누적 보너스, 세력 패시브와 효과 타입 공유 + `dispatch_slot_bonus`/`recruitment_cost_reduction` 추가
  - 산출물: `Docs/content-design/[content]20260417_rank_bonuses.md`
  - 완료: 2026-04-17T09:55:00Z

## 페이즈 2: 밸런스 확정

**상태**: completed

계획된 산출물:
- [x] 1. 패시브 보너스 수치 확정
  - 입력: 페이즈 1 산출물 1
  - 설명: 효과 타입별 수치 범위, 경제 인플레이션 시뮬레이션. P1 치명적 결함(회복 가산 스태킹 음수) 발견 → 곱셈 전환 권고 + 페이즈 1 기획서 역반영
  - 산출물: `Docs/balance-design/20260417_faction_passive_values.md`
  - 완료: 2026-04-17T10:25:00Z
- [x] 2. 태그 확률 + 전용 퀘스트 밸런스
  - 입력: 페이즈 1 산출물 2
  - 설명: 거점 거리별 태그 확률, 전용 퀘스트 난이도/보상/평판 수치. 가입 세력 태그 100% 고정 도입, 고급 트랙 ×1.5→×1.4 하향, 전용 노출 상한 + 6시간 쿨다운 규칙 신설, 페이즈 1 기획서 역반영 4건 도출
  - 산출물: `Docs/balance-design/20260417_faction_quests_balance.md`
  - 완료: 2026-04-17T13:55:00Z
- [x] 3. 상성 보정 수치 매트릭스
  - 입력: 페이즈 1 산출물 3
  - 설명: 6 role × 4 quest_type 매트릭스 확정(−2~+8), role synergy 공유 상한 분리(독립 +10%p), 트레잇 시너지 키 규약 재사용({quest_type}_success_rate), 85개 job role 전수 분류 완료. P1(공유 상한 흡수)·P2(T5 ranger 부재) 이슈 도출, 페이즈 1 기획서 역반영 필요 사항 없음
  - 산출물: `Docs/balance-design/20260417_dispatch_synergy_values.md`
  - 완료: 2026-04-17T14:29:00Z
- [x] 4. 명성 등급별 보너스 수치
  - 입력: 페이즈 1 산출물 4
  - 설명: F~A 누적 보너스 수치 확정 — E 임계값 500→300 하향(C1), D/B 보상 누적 +15%→+10% 하향(C2), dispatch_slot_bonus 가산 상한 +10 명시(C3), B등급에 성공률 +0.02 추가(M1, 곡선 연속성). 공유 상한 +20%p는 세력과 공유 유지(상성 리포트와 정합). 16개 효과 타입 카탈로그 최종 확정
  - 산출물: `Docs/balance-design/20260417_rank_bonuses_values.md`
  - 완료: 2026-04-17T14:42:00Z

## 페이즈 3: 데이터 생성

**상태**: completed

계획된 산출물:
- [x] 1. 세력 전용 퀘스트 풀 대량 생성 (faction-quest × 98)
  - 입력: 페이즈 1 산출물 2 + 페이즈 2 산출물 2
  - 대상 테이블: `quest_pools` (faction_tag/is_faction_exclusive/min_reputation/sector_type 4개 컬럼 필요)
  - 설명: 14세력 × 7개(기본 3 + 고급 4) = 98개. 유형 분포 raid 20 / hunt 25 / escort 24 / explore 29 기획서 정확 일치. 세력명 직접 노출 금지 규칙 준수. 기존 quest_pools 200개와 이름 중복 없음
  - 산출물: `Docs/content-data/[faction-quest]20260417_m1-faction-exclusive.csv` + 메타 `.md`
  - 완료: 2026-04-17T14:55:00Z
  - **⚠️ DB INSERT 보류 상태**: 현재 quest_pools 스키마에 4개 신규 컬럼 미추가. type 컬럼도 real→text 매핑 결정 필요. **페이즈 4 개발 명세에서 스키마 마이그레이션과 함께 INSERT 수행 필수**

참고: 패시브 보너스 14행·상성 매트릭스·랭크 보너스는 수량이 적어 페이즈 2 산출물의 수치표로 operation-bom에 직접 입력 권장 (벌크 생성 불필요).

## 페이즈 4: 개발 명세

**상태**: completed

계획된 산출물:
- [x] 1. PassiveBonusService 도입 + 기존 서비스 연동 명세
  - 입력: 페이즈 1 산출물 1 + 페이즈 2 산출물 1 + 페이즈 2 산출물 4(명성)
  - 스키마: `factions.passive_bonus_json` JSONB 유지(정규화 테이블 미신설), `ranks.bonus_json` JSONB 컬럼 추가, E 임계값 500→300 UPDATE, Freezed sealed class PassiveEffect(16 variant), PassiveBonusFormatter 신규
  - 설명: 16개 효과 타입 카탈로그, 가산/곱셈/공유 상한 +20%p 스태킹 규칙, 6개 도메인 서비스(QuestCalculator/Recruitment/Construction/TraitAcquisition·Evolution/IdleReward/TravelEvent) + ExperienceService 시그니처 확장, P1 회복 곱셈 반영. 마이그레이션 SQL 초안 포함
  - 산출물: `Docs/spec/[spec]20260418_passive-bonus-service.md`
  - 완료: 2026-04-18T00:15:00Z
  - 구현 규모: implement-agent 추천 (5/6점, 21개 파일, 7개 시스템)
- [x] 2. QuestGenerator / QuestCompletionService 확장 명세 (세력 태그 + 전용 퀘스트)
  - 입력: 페이즈 1 산출물 2 + 페이즈 2 산출물 2 + **페이즈 3 산출물 1 (98행 CSV)** + 페이즈 4 산출물 1(PassiveBonusService)
  - 스키마: `quest_pools` 5필드 확장(`type_id` 신규 + `faction_tag`/`is_faction_exclusive`/`min_reputation`/`sector_type`). 기존 `type` real 유지(deprecated)
  - 설명: FactionTagResolver 신설(가입 100% / 비가입 거점 확률), QuestGenerator 전용/일반 분리 + 노출 상한 min(가입수×2, 슬롯×0.5) + 6h 쿨다운(settings 단일 JSON 키), QuestCompletionService 세력 평판 지급 분기, QuestCalculator 보상 가산 총합 +0.80 클램프, ActiveQuest HiveField 17~19(factionTag/reputationReward/isAdvancedTrack). ⚠️ CSV 98행 DB INSERT 마이그레이션 SQL 포함
  - 산출물: `Docs/spec/[spec]20260418_faction-quest-system.md`
  - 완료: 2026-04-18T00:35:00Z
  - 구현 규모: implement-agent 추천 (5/6점, 15개 파일, 4개 시스템)
- [x] 3. QuestCalculator 상성 보정 명세 + 파견 UI 힌트
  - 입력: 페이즈 1 산출물 3 + 페이즈 2 산출물 3 + P4-1/P4-2 선행 명세
  - 스키마: `jobs.role` 컬럼 추가(text NOT NULL DEFAULT 'specialist') + 85개 전수 UPDATE (warrior 26 / specialist 16 / mage 16 / support 10 / ranger 9 / rogue 8) + 15개 트레잇 effect_json UPDATE. 매트릭스는 정적 Dart 상수 `RoleSynergyMatrix`로 관리 (테이블 미신설)
  - 설명: QuestCalculator 시그니처 최종 통합(P1+P2+P3 병합, `partyRoles` 파라미터 + `roleSynergyBonus` 독립 상한 +10%p 클램프 + `traitBonus` 독립 상한 ±10%p 클램프), TraitEffectService 코드 변경 없음(기존 키 재사용), SuccessRateBreakdown 값 객체 + 분해 툴팁 신규 위젯, 퀘스트 카드 role 배지, 용병 카드 +5 이상 하이라이트, 용병 상세 상성 섹션. P2 이슈(T5 ranger 0개) 주석 기록
  - 산출물: `Docs/spec/[spec]20260418_dispatch-synergy.md`
  - 완료: 2026-04-18T01:00:00Z
  - 구현 규모: implement-agent 강력 추천 (6/6점, 14개 파일, 4개 시스템)
- [x] 4. ReputationService 랭크 보너스 명세
  - 입력: 페이즈 1 산출물 4 + 페이즈 2 산출물 4 + P4-1 선행 명세(ranks.bonus_json 이미 포함됨)
  - 스키마: P1 명세의 마이그레이션 SQL에 이미 포함됨(중복 작업 없음). 본 명세는 로직 연결만
  - 설명: ReputationService.getRankChain/getRankLevel/sumRankSuccessRateBonus 신규, UserDataNotifier.addReputation 랭크업 감지, reputationRankUpProvider 신설, RankUpOverlay(app.dart ref.listen 패턴), 홈 화면 등급 카드 탭→RankBonusSummarySheet, 정보 탭 "명성" ListTile + RankInfoScreen(F~A 타임라인 + 등급별 보너스 프리뷰), ActivityLogType에 reputationRankUp/Down 2개 값 추가, 랭크 하향 stub(M2a 이후)
  - 산출물: `Docs/spec/[spec]20260418_rank-bonus-service.md`
  - 완료: 2026-04-18T01:20:00Z
  - 구현 규모: implement-agent 추천 (5/6점, 13개 파일, 6개 시스템)

## 실행 이력

- 2026-04-17T08:19:03Z: 마일스톤 시작
- 2026-04-17T08:19:03Z: 페이즈 1~4 계획 승인
- 2026-04-17T08:19:03Z: 페이즈 1 시작
- 2026-04-17T08:32:00Z: 페이즈 1 항목 1 완료 — 세력 패시브 매핑 기획 (`Docs/content-design/[content]20260417_faction_passive_mapping.md`)
- 2026-04-17T08:50:00Z: 페이즈 1 항목 2 완료 — 세력 태그·전용 퀘스트 컨셉 (`Docs/content-design/[content]20260417_faction_quests.md`)
- 2026-04-17T09:00:00Z: 페이즈 1 항목 3 완료 — 파견 상성 시스템 컨셉 (`Docs/content-design/[content]20260417_dispatch_synergy.md`)
- 2026-04-17T09:55:00Z: 페이즈 1 항목 4 완료 — 명성 등급별 보너스 컨셉 (`Docs/content-design/[content]20260417_rank_bonuses.md`)
- 2026-04-17T09:55:00Z: 페이즈 1 전체 완료 (4/4)
- 2026-04-17T09:56:00Z: 페이즈 2 시작 — 밸런스 확정
- 2026-04-17T10:25:00Z: 페이즈 2 항목 1 완료 — 세력 패시브 수치 밸런스 (`Docs/balance-design/20260417_faction_passive_values.md`). P1~P4 권고 도출
- 2026-04-17T10:30:00Z: 페이즈 1 기획서 역반영 — `[content]20260417_faction_passive_mapping.md` 섹션 3 스태킹 규칙 및 섹션 5 수치 5건 업데이트 (P1 곱셈 스태킹, P2 보상 하향, P3 혈계 하향, P4 뿌리 회복 하향)
- 2026-04-17T13:55:00Z: 페이즈 2 항목 2 완료 — 세력 태그 + 전용 퀘스트 밸런스 (`Docs/balance-design/20260417_faction_quests_balance.md`). 가입 세력 태그 100% 고정, 고급 트랙 보상 +0.40 하향, 전용 노출 상한·쿨다운 규칙 신설
- 2026-04-17T13:58:00Z: 페이즈 1 기획서 역반영 완료 — `[content]20260417_faction_quests.md` 4건 수정 (뿌리 tier_range [1,3]→[1,4], 보상 배수 +0.30/+0.40 가산, 태그 100% 규칙, 노출 상한·6h 쿨다운)
- 2026-04-17T14:29:00Z: 페이즈 2 항목 3 완료 — 파견 상성 보정 수치 매트릭스 (`Docs/balance-design/20260417_dispatch_synergy_values.md`). role synergy 공유 상한에서 분리(독립 +10%p), 기존 `_questModifiers` 유지, 트레잇은 기존 `{quest_type}_success_rate` 키 재사용(신규 필드 불요), 85개 job role 전수 분류 테이블 확정
- 2026-04-17T14:42:00Z: 페이즈 2 항목 4 완료 — 명성 등급별 보너스 수치 (`Docs/balance-design/20260417_rank_bonuses_values.md`). E 임계값 500→300(C1), D/B 보상 누적 +15%→+10%(C2), dispatch_slot_bonus 가산 상한 +10(C3), B등급 성공률 +0.02 신규(M1). 16개 효과 타입 카탈로그 최종 확정
- 2026-04-17T14:45:00Z: 페이즈 2 전체 완료 (4/4) — 세력 패시브/퀘스트/상성/명성 4개 리포트 교차 검증 완료
- 2026-04-17T14:50:00Z: 페이즈 3 시작 — 데이터 생성. faction-quest 타입 스펙 존재 확인 완료(`.claude/skills/data-generator/types/faction-quest.md`)
- 2026-04-17T14:55:00Z: 페이즈 3 항목 1 완료 — 세력 전용 퀘스트 98개 CSV 생성(`Docs/content-data/[faction-quest]20260417_m1-faction-exclusive.csv`). 유형 분포 raid 20 / hunt 25 / escort 24 / explore 29 기획서 정확 일치. DB INSERT는 스키마 확장 미완으로 보류 → 페이즈 4에서 반드시 수행
- 2026-04-17T15:00:00Z: 페이즈 3 전체 완료 (1/1). 페이즈 4 명세서에 **CSV 98행 DB INSERT 작업 필수 포함** 방침 확정
- 2026-04-18T00:05:00Z: 페이즈 4 시작 — 개발 명세 작성. 4개 독립 명세 순차 진행 예정
- 2026-04-18T00:15:00Z: 페이즈 4 항목 1 완료 — PassiveBonusService 명세 (`Docs/spec/[spec]20260418_passive-bonus-service.md`). implement-agent 추천(5/6점), 마이그레이션 SQL 초안 포함
- 2026-04-18T00:35:00Z: 페이즈 4 항목 2 완료 — 세력 태그 + 전용 퀘스트 시스템 명세 (`Docs/spec/[spec]20260418_faction-quest-system.md`). CSV 98행 INSERT 마이그레이션 SQL 포함, FactionTagResolver + 쿨다운 + 보상 +0.80 클램프. implement-agent 추천(5/6점)
- 2026-04-18T01:00:00Z: 페이즈 4 항목 3 완료 — QuestCalculator 상성 보정 + 파견 UI 명세 (`Docs/spec/[spec]20260418_dispatch-synergy.md`). jobs.role 85개 UPDATE + RoleSynergyMatrix 정적 상수 + QuestCalculator 시그니처 최종 통합 + SuccessRateBreakdown + 분해 툴팁. implement-agent 강력 추천(6/6점)
- 2026-04-18T01:20:00Z: 페이즈 4 항목 4 완료 — ReputationService 랭크 보너스 + 명성 UI 명세 (`Docs/spec/[spec]20260418_rank-bonus-service.md`). getRankChain + 랭크업 감지 + RankUpOverlay + 홈 배지 팝업 + RankInfoScreen + ActivityLog 연동. implement-agent 추천(5/6점)
- 2026-04-18T01:25:00Z: 페이즈 4 전체 완료 (4/4) — 4개 개발 명세서 교차 통합 완료. M1 마일스톤 전 페이즈 완료
