# M4 실행 상태

> 시작: 2026-05-03
> 마지막 업데이트: 2026-05-04 (M4 마일스톤 완료 — Supabase 일괄 적용 종결)
> 현재 페이즈: 4 (완료)
> 상태: completed

## 로드맵 요구사항 요약

M4는 M3까지 만든 시스템을 시작 거점 1개에 다시 묶어 신규 유저가 첫 2시간 안에 "용병단이 마을에서 인정받기 시작했다"는 변화를 체감하게 만든다. 199→40 리전 축소(Tier 1~10 분포 유지, 작업 집중 1~5), 섹터 4개 기본화 + `region_sectors` 정규화 테이블, sector_type 5종(village/ruins/hidden + 신규 dungeon/field), 시작 거점 더스트플레인(mountain) → 더스트빌(village) 고정, `quest_pools` 4개 컬럼 확장(`is_fixed`/`fixed_chain_id`/`fixed_step`/`trust_threshold`), 마을 신뢰도 4단계, 마을 방문 거점 3종(촌장 집/낡은 대장간/약초상), 약초상 1회성 회복 vs 의무실 자동 회복 분리, 허드렛일 = 난이도 1 의뢰 + 고정 사건 라인 1개.

선행: M3 완료. 살아남는 40개 리전의 region_id 그대로 유지. Tier 6~10 종속 시스템(jobs/wages/ranks/elite/theme/recruit) 확장은 M9로 이연. 테스트 세이브 초기화 권고.

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 40 리전 재편안 + 199→40 매핑표
  - 참고 문서: `Docs/roadmap/master_roadmap.md` M4 #지역 축소 정책, 기존 `regions` 테이블 (Supabase)
  - 산출물: `Docs/Archive/20260503_m4-region-migration/design_content.md`
  - 완료: 2026-05-03
  - 핵심 결정: 더스트플레인=region_id 3 재태깅(plains→mountain) / T9=region_id 200 신규 / 살아남는 40개 region_id 추천 리스트 / chain_quests 100% 보존 / `target_sector_id` 변환은 페이즈 1 #2로 위임 / 삭제 159개는 옵션 B 단일 dump JSON 보관
- [x] 2. 섹터 시스템 재설계 (sector_count 정책 + region_sectors 스펙 + sector_type 5종)
  - 참고 문서: `Docs/roadmap/master_roadmap.md` M4 #섹터 축소 정책 + 섹터 이름 시스템, `regions`/`region_discoveries`/`quest_pools` 기존 sector 참조
  - 산출물: `Docs/Archive/20260503_m4-region-sectors/design_sector-system.md`
  - 완료: 2026-05-03
  - 핵심 결정: sector_count 4 기본 + 4개 리전(1, 23, 127, 146) 5섹터 승격 = 164행 / region_sectors 1-based + RegionState.sectorChanges 0-based 유지(어댑터 변환) / sector_type 5종 시각 (dungeon ⛏️ 0xFFB71C1C, field 🌾 0xFF558B2F 신규) / chain_quests target_sector_id 변환 불필요(실측 모두 null) / region_discoveries 3행 재매핑(r18 5→1, r23 7→4, r146 6→4) / dungeon·field quest_pools 신규 풀 12~16개 권장
- [x] 3. 시작 거점 더스트플레인·더스트빌 컨셉 (4섹터 구성 + NPC 4~6명 + 방문 거점 3개 MVP 기능)
  - 참고 문서: `Docs/roadmap/master_roadmap.md` M4 #설계 방향, #마을 섹터 방문 UI, #마을 거점별 MVP 기능
  - 산출물: `Docs/Archive/20260503_m4-region-sectors/design_starting-settlement.md`
  - 완료: 2026-05-03
  - 핵심 결정: 4섹터 구성 확정(1=더스트빌 village / 2=폐광 dungeon / 3=마른 초원 field / 4=먼지로 덮인 길 field) / 거점 3종 MVP 기능 명세(촌장 집·낡은 대장간·약초상 각 3개 버튼) / 약초상 vs 의무실 역할 분리 정책(즉시·골드·쿨다운 vs 자동·시간 단축·시설 레벨, 동시 작동) / NPC 5명(파슨·하겐·네리스 거점 3명 + 도라 할멈·레미 거리 2명) / 상태 변화 문구 17개(거점 3종 × 4단계 12개 + 광장 풍문 4개 + 사건 완료 직후 1개) / 거점 잠금 정책 단계별 활성화(신뢰도 1단계는 진입 가능하나 일부 버튼 비활성) / 시간 미소모 원칙 + 의뢰소 별도 거점 미생성
- [x] 4. 마을 신뢰도 4단계 + 고정 사건 라인 1개 (저장소 결정 + trust_threshold 매핑)
  - 참고 문서: `Docs/roadmap/master_roadmap.md` M4 #마을 신뢰도 4단계, #신뢰도 기반 고정 의뢰
  - 산출물: `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md`
  - 완료: 2026-05-03
  - 핵심 결정: 신뢰도 4단계 컨셉(1=의심/2=인지/3=친근/4=소속) / 고정 사건 라인 = "폐광길 재개방" 6단계 채택(폐광×4·마른초원×1·더스트빌×1, quest_type 4종 모두 활용) / step별 trust_threshold 매핑(1·2=trust1 / 3·4=trust2 / 5·6=trust3, step6 보상이 4단계 진입 트리거) / quest_pools 4개 컬럼 정의(is_fixed/fixed_chain_id/fixed_step/trust_threshold) + 노출 로직(일반 갱신 주기 제외 + 실패 후 재등장 + 단계 완료 시 자동 다음 step 노출) / **저장소 결정 1**: 마을 신뢰도 = regionStates 확장(HiveField 4·5 settlementTrust/settlementTrustLevel, M7 마이그레이션 path 명시) / **저장소 결정 2**: 고정 사건 진행 = chainQuestProgress 재사용(chain_id `settlement_*` prefix 컨벤션, 14일 dormant 비활성화 분기) / ActivityLogType 3종 추가(settlementTrustUp/settlementEventStep/settlementEventCompleted) / quest_pools 6행 인라인 처리 권장(별도 타입 스펙 작성 부담 대비 데이터량 적음)
- [x] 5. 초반 2시간 플레이 흐름 (분 단위)
  - 참고 문서: `Docs/roadmap/master_roadmap.md` M4 #누적 플레이 기준, 산출물 1~4 결과
  - 산출물: `Docs/content-design/[content]20260503_first-2h-playflow.md`
  - 완료: 2026-05-03
  - 핵심 결정: 4구간 분할 분 단위 매트릭스(A 0~10분 / B 10~30분 / C 30~60분 / D 60~120분, 5종 매핑 = 플레이어 액션·step 진행·신뢰도 점수·시설 큐·의뢰 갱신) / 신뢰도 임계값 권장 역산(1→2=30점·2→3=80점·3→4=200점) / step별 보상 권장(10/15/20/25/30/100) / 시설 4개 첫 60분 완성(의무실·주둔지·정보망·훈련소 Lv1) / 일반 의뢰 갱신 주기 60분 유지(1차 갱신 60:00·2차 120:00) / M4 종료 조건 4가지 모두 첫 60분 안에 충족 / 본 흐름은 "이상적 시나리오" — 이탈/실패 분기는 페이즈 2 #1·#3 시뮬레이션에 위임 / 페이즈 2 #1·#3·#4 직접 입력 제공

## 페이즈 2: 밸런스 확정

**상태**: in_progress

계획된 산출물:
- [x] 1. 마을 신뢰도 누적 임계값 + 단계별 보상 수치 (첫 2h 안 2회 상승 보장)
  - 입력: 페이즈 1 #4 + #5
  - 산출물: `Docs/Archive/20260503_m4-settlement-trust/design-balance.md`
  - 완료: 2026-05-03
  - 핵심 결정: 임계값 30/80/200 확정(시뮬레이션 검증 완료) / step별 보상 10·15·20·25·30·100 확정 / 일반 의뢰 보상 2·3·5점(난이도 1·2·3, 페이즈 1 권장 1점→2점 상향: 30분 임계값 도달 보장) / 단계 진입 일회성 보상 100G+50XP·200G+100XP·500G+200XP+100명성(2/3/4단계) / 결과 보정 대성공·성공 ×1.0·실패·대실패 ×0 / 강등 정책 M4 미적용(페이즈 4 #5 stub만) / 비관 시나리오 검증(step 3·5 1회 실패 시 4단계 진입 130:00, "외부" 종료 조건 정합) / 점수 획득 비율 고정사건 77%·일반의뢰 13%·이동선택지 3%·외부세력 0% / 페이즈 2 #3·#4 + 페이즈 4 #3·#5 직접 입력
- [x] 2. 약초상 vs 의무실 수치 분리 (비용·쿨다운·시간 단축 곡선)
  - 입력: 페이즈 1 #3 + 페이즈 2 #1
  - 산출물: `Docs/balance-design/[balance]20260503_herbalist-vs-infirmary.md`
  - 완료: 2026-05-03
  - 핵심 결정: 약초상 비용 곡선 75/50/45/40G(단계 1·2·3·4, 정상가 50G ×1.5/1.0/0.9/0.8) / 약초상 쿨다운 45/30/15/10m(페이즈 1 권장 24h/12h/8h 부정 — 게임 시간 = 실시간이라 미정합, 실측 부상 발생 빈도 step 3→step 5 38분 간격 정합 위해 30m 권장) / 의무실 facilities 행 변경 없음(max_effect 0.7·alpha 0.3·lv1 100G/8.58% 단축 유지) / 두 시스템 자연 분기(약초상=즉시·골드/의무실=영구·시간단축, 의무실 Lv10 시점 교차) / 채집 의뢰 골드 배수 ×1.0/×1.1/×1.2(2/3/4단계, 신뢰도 보상 2점 고정) / M5 채집 재료 시스템 의존성 명시(M4는 텍스트 힌트만) / 첫 2시간 약초상 누적 비용 ~140G(단계 진입 보상 800G의 17.5%) / 페이즈 4 #4 HerbalistService + UserData.herbalistCooldownEndTime HiveField 명세 입력
- [x] 3. 허드렛일(난이도 1) 보상 곡선 + 첫 30분 골드 흐름 시뮬레이션
  - 입력: 페이즈 1 #5 + 기존 `QuestCalculator` 보상 공식
  - 산출물: `Docs/Archive/20260503_m4-fixed-quest-system/design_chore-quest-economy.md`
  - 완료: 2026-05-03
  - 핵심 결정: 시작 골드 500G→200G 하향 권고(페이즈 1 #5 학습 모멘트 정합, 모든 시나리오 검증 완료) / 더스트빌 허드렛일 풀 10건 신규 추가(labor 6 + escort 1 + explore 2 + hunt 1, prompt 권장 11건에서 survey 1건 제외 — quest_pools 미해당) / Supabase 현황 검증 — 난이도 1 풀 labor 0건 발견(페이즈 4 #3 인라인 추가 필수) / 시작 의뢰 풀 6개 분포 조정 prompt 권장 4+2 → 5+1(난이도 2 1건만 노출, 학습 곡선 안정) / 난이도 1 순수익 곡선 35/65/75/85/105G(labor/explore/escort/raid/hunt T1 1명) / 첫 30분 시뮬레이션 3종(이상 405G / 비관 300G / 최악 285G) 모두 의무실 Lv1 100G 건설 가능 / 갱신 주기 60분 유지 + 단계 진입 시 신규 풀 강제 노출 트리거 추가 권고(페이즈 4 #3·#5 입력) / XP 공식 변경 없음(baseXp 20·levelThresholds [0,100,350,850,1850]) — 난이도 1 평균 25 XP/건 페이즈 1 #5 권장값 정합 / 페이즈 2 #4 step별 골드 보상 가이드 80/120/200/185/270/500G 합산 1,355G / 페이즈 2 #1 시뮬레이션 3 100분 잔고 ~260G 추정 보정 — 시설 4개 실제 비용 400G(가설 1,200G 과대), 실제 잔고 ~1,595G로 외부 진입 충분 / freeRecruitCooldown 2h·paidRecruitCost 100G 변경 없음
- [x] 4. 고정 사건 의뢰 난이도·보상 (최종 의뢰 60~80% 성공률)
  - 입력: 페이즈 1 #4
  - 산출물: `Docs/Archive/20260503_m4-fixed-quest-system/design_fixed-quest-curve.md`
  - 완료: 2026-05-03
  - 핵심 결정: step별 적전투력·추천 파티·성공률 곡선 확정(step 1·2 T1 1명 95% / step 3 T1 2명 72.5% T1 3명 95% / step 4 T1 2명 95% / step 5 T1 4명 82.5% T1 3명+T2 95% / step 6 T1 3명 60.5% T1 4명 80.5%) / **survey 핵심 발견** — `_questModifiers`·`_statWeights`·`RoleSynergyMatrix._matrix` 모두 미정의로 questMod·roleSynergy 0 fallback이 step 6 60~80% 통제에 정확 기여(변경 권장 안 함, 의도된 설계) / quest_pools 4개 신규 컬럼 추가 권장(`reward_gold_override`/`reward_xp_bonus_override`/`duration_override_seconds`/`trust_reward_override`) — survey base_reward 0 우회 + 페이즈 1 #5 ~5/6/10분 흐름 정합 + step 6 +50 XP 클라이맥스 + 페이즈 2 #1 결정값 직접 적용 / step별 매트릭스: 골드 80/120/200/185/270/500G·duration 300/300/360/300/600/600s·신뢰도 10/15/20/25/30/100·dispatch min 단일 5/5/10/10/20/20G(70G 합계, max 적용 시 380G 폭증 회피) / dispatch_cost min 단일 적용 분기 권장 / 비관 시나리오 검증 — step 5 1회 실패 시 4단계 진입 95분(첫 2시간 안), step 5·6 모두 실패(14.8% 확률) 시 4단계 진입 140분(첫 2시간 외부, 페이즈 1 #5 종료 조건 정합) / ChainQuestService.tryActivateSettlement(3, "pyegwang_reopen") 신규 + dormancyCheck settlement_ prefix skip 분기 / success_penalty 컬럼 적용 위치 미확인(deprecated 가능) — 페이즈 4 #5 검증 필요 / 부상·사망률 변경 없음 / 페이즈 4 #3·#5 명세 직접 입력

## 페이즈 3: 데이터 생성

**상태**: skipped (2026-05-03 페이즈 2 종료 체크포인트에서 결정)

스킵 사유:
- 4가지 신규 타입 스펙(region-sector, fixed-quest, dustvile-chore, npc-line) 모두 단일 거점 한정 데이터 + 반복 사용 빈도 낮음 → data-generator 호출 시 비용 대비 산출 효율 낮음
- 가장 큰 region_sectors도 ~164행 — SQL INSERT 인라인 처리 가능 범위
- 페이즈 4 명세에 데이터 + 코드 변경 통합 시 단일 PR 일관성 확보

인라인 처리 항목 (페이즈 4 명세 내):
- region_sectors ~164행 → 페이즈 4 #2 명세 내 SQL INSERT
- 고정 사건 의뢰 6행 (`dustvile_pyegwang_reopen` step 1~6) → 페이즈 4 #3 명세 내 SQL INSERT (페이즈 1 #4 + 페이즈 2 #4 매트릭스 통합)
- 더스트빌 허드렛일 10행 (`dustvile_chore_NN`) → 페이즈 4 #3 명세 내 SQL INSERT (페이즈 2 #3 컨셉)
- 더스트빌 NPC 5명 + 거점 상태 문구 17개 → 페이즈 4 #4 명세 내 인라인 (페이즈 1 #3 컨셉)
- 199→40 매핑표 → 페이즈 4 #1 명세 내 SQL UPDATE/DELETE (페이즈 1 #1 매핑)

## 페이즈 4: 개발 명세

**상태**: in_progress

계획된 산출물:
- [x] 1. 데이터 마이그레이션 + 시작 거점 고정
  - 입력: 페이즈 1 #1
  - 범위: 199→40 매핑 적용, 종속 데이터(`region_discoveries`/`quest_pools`/`chain_quests`/`elite_loot_tables`/`factions`) 일괄 변환, 테스트 세이브 초기화 게이트, `GameConstants.startingRegionId/startingSector` 추가, `initializeNewGame()` random 제거, `GameConstants.sectorCount` 폐기
  - 산출물: `Docs/Archive/20260503_m4-region-migration/spec.md` + `Docs/Archive/20260503_m4-region-migration/plan.md` (implement-agent 구현 계획 동반 산출)
  - 완료: 2026-05-03
  - 핵심 결정 (구현 단계):
    - 명세서 산수 정정 — "삭제 159개" 표기는 오기, 실제 기존 199 중 보존 39 + 삭제 160 + 신규 1(region 200) = 40 보존 / 160 삭제
    - UserData 모델에 `moveStartTime` 필드 부재 — 명세서 골격 코드에서 제외, 실제 4개 필드(`isMoving`/`moveTargetRegion`/`moveTargetSector`/`moveEndTime`)만 클리어
    - 호출 시점 옵션 A 채택 — `_PostSyncApp`을 ConsumerStatefulWidget으로 변경, `_ensureMigrationStarted(StaticGameData)` + `FutureBuilder`로 마이그레이션 1회 실행 후 `userDataProvider` watch
    - flutter-reviewer 2회 BLOCK → APPROVE 통과 (addPostFrameCallback 가드 / `_migrationFuture` 캡슐화 / `mounted` 체크 / raw exception UI 제거 + `_buildStaticDataErrorScreen` 추가 / 절대 경로 import)
    - dump JSON 추출 완료 (160개 region + 15개 region_discoveries) — `Docs/content-data/postponed_regions_dump.json`
    - 매핑 CSV 생성 완료 — `Docs/content-data/region_migration_199_to_40.csv` (200줄)
    - **Supabase 적용 보류** (옵션 B 선택) — 페이즈 4 #2~#5 모두 완료 후 단일 시점 일괄 적용. 현재 Supabase는 199 region 그대로 유지. data_versions 미증분이라 클라이언트 sync에서 변경분 안 내려옴 → RegionMigrationService 멱등 플래그도 미설정 상태로 안전 대기
  - 커밋: `94d9ccc feat(M4): 페이즈 4 #1 데이터 마이그레이션 + 시작 거점 고정 ...`
- [x] 2. region_sectors 신규 테이블 + 섹터 데이터 기반 렌더링
  - 입력: 페이즈 1 #2 + #3
  - 범위: Supabase 마이그레이션, `RegionSector` Freezed 모델, `regions.sector_count` 컬럼, `StaticGameData`/`SyncService` 통합, `MovementScreen` 동적 렌더링, sector_type 5종 + LayerSidebar/QuestCardBadges 아이콘
  - 산출물: `Docs/Archive/20260503_m4-region-sectors/spec.md` + `Docs/Archive/20260503_m4-region-sectors/plan.md` (implement-agent 구현 계획 동반 산출)
  - 완료: 2026-05-03
  - 핵심 결정 (구현 단계):
    - 시드 정책 — Q1=D 채택. region_sectors 시드 0행, 더스트플레인(region 3) 4섹터(더스트빌·폐광·마른 초원·먼지로 덮인 길)만 `RegionSectorFallback` const 상수로 인라인. 약 164행 시드는 후속 페이즈 위임
    - 키 정리 정책 — Q2=C 채택. UserData.sector clamp는 페이즈 4 #1로 충분. regionStates.sectorChanges 키 정리는 별도 멱등성 플래그(`region_sector_count_v1`)로 1회. RegionMigrationService §1 가드를 nested if로 변환(조기 return 제거)하여 §2 도달 가능
    - GameConstants 정리 — Q3=A 채택. `@Deprecated sectorCount = 10` stub 두 줄 완전 제거. movement_screen.dart 잔여 hardcoded 10을 `region.sectorCount`로 동적 변환
    - 레이아웃 — Q4=A 채택. MovementScreen 단일 Wrap 레이아웃 유지. `List.generate(targetRegion.sectorCount, ...)` 동적 그리드 + `effectiveSelectedSector` 로컬 clamp(build State 변이 회피) + ◀/▶ region 변경 onTap에 setState 내부 sector clamp 보정
    - quest_pools dungeon/field 풀 — Q5=B 채택. dungeon/field 풀 추가는 페이즈 4 #3으로 위임
    - sector_type 표현 — Q6 String 유지(enum 미도입). DB CHECK IN ('village','ruins','hidden','dungeon','field')로 검증
    - fallback 우선순위 — Q7. region 3 외 region 진입 시 lookup → null → 번호만 표시. `RegionSectorFallback.lookupSector(regionId, sectorIndex, regionSectors)`가 staticData → fallback(region 3 한정) → null 우선순위
    - 인덱싱 정책 — Q8. 0-based↔1-based 변환 헬퍼 미도입. 클래스 docstring + region_state_model.dart:17 + quest_provider.dart 3곳에 주석 명문화로만 처리
    - 신규 컬럼 — `regions.sector_count INT NOT NULL DEFAULT 4 CHECK 1..6`. 4개 거점급 region(1·23·127·146) UPDATE sector_count=5
    - 신규 테이블 — `region_sectors` (id TEXT PK 'r{region_id}_s{sector_index}', region_id INT FK→regions ON DELETE CASCADE, sector_index INT CHECK 1..6, name TEXT, sector_type TEXT CHECK 5종, environment_tags JSONB DEFAULT '[]', description TEXT, UNIQUE(region_id, sector_index)) + idx_region_sectors_region 인덱스
    - 모델/Provider 통합 — `RegionSector` freezed 모델(7필드, snake_case @JsonKey, 1-based 정책 docstring) + `StaticGameData.regionSectors` 필드 + `SyncService.allTables`에 'region_sectors' 추가(총 25개 테이블 / 27개 동기화 대상)
    - 시각 — `_SectorTile` switch에 dungeon ⛏️ + field 🌾 분기 추가. AppTheme `sectorDungeon = Color(0xFFB71C1C)` + `sectorField = Color(0xFF558B2F)` 색상 추가. dungeon/field는 MovementScreen 그리드 한정(LayerSidebar/QuestCardBadges는 기존 변형 3종 village/ruins/hidden 정책 보존)
    - region_discoveries 재매핑 — region 18 sector_index ≥4 → 1, region 23·146 ≥4 → 4 (총 3행)
    - 빌드 게이트 — 테스트 파일 4개(inventory/quest 도메인)에 `regionSectors: const []` 추가로 StaticGameData 생성자 시그니처 변경 흡수
    - **Supabase 적용 보류** (옵션 B 유지) — 페이즈 4 #3~#5 모두 완료 후 단일 시점 일괄 적용. 본 PR은 SQL 마이그레이션 파일만 작성. 현재 Supabase는 페이즈 4 #1·#2 변경 모두 미적용 상태. data_versions 미증분이라 클라이언트 sync에서 변경분 안 내려옴
  - 커밋: `2189adf feat(M4): 페이즈 4 #2 region_sectors 신규 테이블 + 섹터 데이터 기반 렌더링 ...`
- [x] 3. quest_pools 컬럼 확장 + 고정 의뢰 노출 로직
  - 입력: 페이즈 1 #2 + 페이즈 1 #4 + 페이즈 2 #3 + 페이즈 2 #4
  - 범위: quest_pools 9개 컬럼 마이그레이션(`is_fixed`/`fixed_chain_id`/`fixed_step`/`trust_threshold` + 보상/시간 override 4개 + `min_trust_level`), Partial UNIQUE 인덱스, `QuestPool` 모델 확장, `QuestGenerator` 분기 — 일반 갱신 풀 제외 + `trust_threshold` 도달 시 노출 + 실패 후 재등장 + 단계 완료 시 다음 step 자동 노출, dustvile_pyegwang_reopen 6단계 + dustvile_chore_NN 10건 INSERT, settlementTier 정렬 분기, 거점 사건 카드 배지
  - 산출물: `Docs/Archive/20260503_m4-fixed-quest-system/spec.md` + `Docs/Archive/20260503_m4-fixed-quest-system/plan.md` (implement-agent 구현 계획 동반 산출)
  - 완료: 2026-05-03
  - 핵심 결정 (구현 단계):
    - Q1=B 채택 — `AppTheme.settlementAccent = Color(0xFFFFA000)` 신규 상수 추가. 변형 섹터 `transformVillage`(0xFF2E7D32 초록)와 의미 충돌 회피
    - Q2=인라인 한정 채택 — settlementTier 카드 배지("📜 마을 사건")를 `dispatch_screen.dart` 인라인 Container로 추가. `QuestCardBadges` 통합은 페이즈 4 #4로 위임
    - Q3=Notifier 비공개 stub 채택 — `QuestListNotifier._getCurrentTrustLevel() return 0;` stub. `RegionStateRepository`는 페이즈 4 #5 본격 구현 영역, 미수정
    - dungeon/field 풀 추가 옵션 B 분리 — 페이즈 1 #2에서 위임된 12~16개 신규 풀은 본 명세에서 제외(M5 또는 페이즈 4 #6 위임). 본 페이즈 16행은 dustvile_chore_NN으로 sector_type=dungeon/field 일부 커버
    - quest_pools 9개 컬럼 단일 트랜잭션 마이그레이션 + Partial UNIQUE 인덱스 `(fixed_chain_id, fixed_step) WHERE is_fixed=true`
    - dustvile_pyegwang_reopen 6단계 SQL INSERT 매트릭스 (페이즈 2 #4 정합) — explore→hunt→raid→escort→raid→survey, trust_threshold 1·1·2·2·3·3, duration 300·300·360·300·600·600s, trust_reward 10·15·20·25·30·100, gold override step3+ 200·185·270·500G, step6 +50 XP 보너스
    - dustvile_chore_NN 허드렛일 10건 SQL INSERT (페이즈 2 #3 정합) — labor 6 + escort 1 + explore 2 + hunt 1, dustvile_chore_03 채집 의뢰만 min_trust_level=2
    - QuestListNotifier 6개 변경 통합 — chain_quest import / `_getCurrentTrustLevel` stub / `_injectFixedSettlementQuest` (settlement_3_pyegwang_reopen 진행 조회 + ActiveQuest isChainStep=true 생성) / `refreshAvailableQuests` (페이즈 4 #5 호출 연결용 시그니처) / `_checkQuestRefresh` settlement_ prefix 만료 제외 / `_refreshExpiredQuests` 동일 분기
    - ActiveQuest.isSettlementStep getter 추가 (chainId? startsWith settlement_)
    - QuestSortService.QuestSortResult에 settlementTier 신규 필드 + chainTier0 분류에서 settlement_ prefix 제외 + `sortedRest = [...settlementTier, ...tier1~4]` 순서 (일반 목록 최상단)
    - **Supabase 적용 보류 유지** (옵션 B 연장) — 페이즈 4 #4~#5 모두 완료 후 단일 시점 일괄 적용. 본 PR은 SQL 마이그레이션 파일만 작성. data_versions 미증분이라 클라이언트 sync에서 변경분 안 내려옴
    - **stub 정합성** — `_getCurrentTrustLevel() = 0` fallback이라 trust_threshold ≥ 1 조건 실패 → 고정 의뢰 미노출 안전 stub. 페이즈 4 #5에서 `RegionStateRepository.getSettlementTrust(regionId).level` 한 줄 교체로 활성화
    - 후속 처리 권고 (plan.md 4절 8개 항목) — ChainTopSection settlement_ filter 누락(페이즈 4 #5 명세) / `_injectFixedSettlementQuest` state vs Hive 중복 방어 (stub 해제 전 수정) / filteredExpired 이중 필터 정리 / IntrinsicHeight·Builder ref.watch (UI 사이클) / emoji 접근성 / hardcoded chainId 일반화 / settlementAccent 라이트 테마 대비비
  - 커밋: `0f39267 feat(M4): 페이즈 4 #3 quest_pools 컬럼 확장 + 고정 의뢰 노출 로직 ...`
- [x] 5. 마을 신뢰도 시스템 + 고정 사건 진행 상태 + 페이즈 4 #3 stub 해제
  - 입력: 페이즈 1 #4 + 페이즈 2 #1
  - 범위: RegionState HiveField 4·5(settlementTrust/settlementTrustLevel) 확장, RegionStateRepository 신뢰도 메서드 3종(addSettlementTrust/getSettlementTrust/setSettlementTrust) + 단계 임계값/일회성 보상/단계명 상수 맵 + 살아있는 용병 균등 XP 분배 헬퍼, TrustLevelUpEvent + settlementTrustLevelUpProvider StateProvider + settlementTrustProvider Provider.family 신규, ChainQuestService.tryActivateSettlement + checkDormant settlement_ skip + onStepCompleted protagonist skip 분기, QuestCalculator/ExperienceService 시그니처 4종 override(rewardGoldOverride/durationOverrideSeconds/isFixedWithDurationOverride/rewardXpBonusOverride), QuestCompletionService settlementTrustGain 필드 + pool 조회 + override 적용, QuestListNotifier 6개 변경(stub 해제 + dispatch override + 중복 방어 + 가독성 개선 + settlement_ + 일반 의뢰 분기), ActivityLogType HiveField 22~24 + home_screen _logIcon 매핑, DialogTypeRegistry settlementTrustUp 키(8종) + app.dart listen + dialogQueue high priority enqueue, SettlementTrustUpDialog 위젯 신규, ChainTopSection settlement_ filter, region 3 자동 활성화 hook 2종(initializeNewGame + _completeMovement)
  - 산출물: `Docs/Archive/20260503_m4-settlement-trust/spec.md` + `Docs/Archive/20260503_m4-settlement-trust/plan.md` (implement-agent 구현 계획 동반 산출)
  - 완료: 2026-05-04
  - 핵심 결정 (구현 단계):
    - 명세서 사전 확정 결정 D-1~D-7 모두 적용 — priority=high / AppTheme 신규 색상 미추가 / XP 살아있는 용병 균등 분배(정수 나눗셈, 잔여 0번째 가산) / region 3 한정 일반 의뢰 신뢰도 점수 / Future<void>+await / 결과 보정 ×1.0 유지(override는 base 값만 대체)
    - 명세서 5절 Q&A 권장 답변 모두 적용 — Q-1: Repository 직접 Ref 주입(addReputation 패턴 모방, SettlementTrustService 미분리) / Q-2: settlement_ chainId protagonist 무시 / Q-6: setSettlementTrust 일회성 보상 우회(무한 루프 회피)
    - 17 TASK 9단계 실행 — 1단계(병렬 7) → 2단계(build_runner) → 3단계(병렬 2) → 4~6단계(직렬) → 7단계(QuestListNotifier 통합 6개 변경) → 8단계(app.dart listen) → 9단계(병렬 2 hook)
    - flutter-reviewer HIGH 이슈 1건 수정 완료 — `RegionStateRepository.saveState`(line 42~49)가 기존 객체 존재 시 신규 인자(`settlementTrust:0` 포함)를 버리고 `existing.save()`만 호출하므로, MovementNotifier._completeMovement의 기존 세이브 호환 분기에서 `else if (regionState.settlementTrust == null)` 케이스를 saveState 우회 + 직접 객체 수정 패턴(`regionState.settlementTrust = 0; regionState.settlementTrustLevel ??= 1; await regionState.save();`)으로 변경
    - flutter-reviewer MEDIUM 5건은 수정 미수행 — 명세 결정사항(Q-1 Ref 주입) / 즉시 영향 없음(settlementTrustProvider 미사용·Map 삽입 순서·메서드 길이) / 후속 페이즈 위임(페이즈 4 #4 마을 방문 UI에서 settlementTrustProvider 사용 예정)
    - 빌드 게이트 1건 자동 수정 — home_screen.dart `_logIcon` switch가 신규 enum 3종 미처리 → dart-build-resolver가 `chainCompleted`(chainGold/bold) / `chainProgressed`(primary) 패턴 그대로 매핑 (settlementTrustUp=chainGold·🏘️·bold / settlementEventStep=primary·📜 / settlementEventCompleted=chainGold·📜·bold)
    - 페이즈 4 #3 stub 해제 — `_getCurrentTrustLevel() return 0;` → `getSettlementTrust(userData.region).level`로 한 줄 교체. 페이즈 4 #3 후속 권고 #1·#2·#3 통합 처리(ChainTopSection settlement_ filter / `_injectFixedSettlementQuest` `_load()` 선행 중복 방어 / `_refreshExpiredQuests` 이중 필터 제거)
    - 검증 결과 — verifier PASS(REQ-01~33 전부 + D-1~D-7 + Q&A 준수 + 호환성 OK) / flutter-reviewer APPROVE / flutter analyze "No issues found" / flutter test 499/499 PASS
    - **Supabase 적용 보류 유지** (옵션 B 연장) — 본 명세는 SQL 변경 없음(코드 영역만). 페이즈 4 #1·#2·#3 SQL 마이그레이션 4종 + data_versions 증분은 페이즈 4 #4 완료 후 단일 시점 일괄 적용
  - 커밋: `332df75 feat(M4): 페이즈 4 #5 마을 신뢰도 시스템 + 거점 사건 활성화 + 페이즈 4 #3 stub 해제 ...`
- [x] 4. 마을 방문 UI + 거점 3종 + 약초상/의무실 분리
  - 입력: 페이즈 1 #3 + 페이즈 2 #2
  - 범위: 이동 화면 village 섹터 하단 영역, 촌장 집·낡은 대장간·약초상 화면, `HerbalistService`(1회성 회복+쿨다운) 신규, 기존 `FacilityService` 의무실 효과 유지. **선행 의존**: 페이즈 4 #5 settlementTrustProvider 활성화 완료 — 거점 잠금 정책(단계별 활성화) + NPC 인사말 단계 변주 입력으로 활용
  - 산출물: `Docs/Archive/20260504_m4-settlement-visit-ui/spec.md` + `Docs/Archive/20260504_m4-settlement-visit-ui/plan.md` (implement-agent 구현 계획 동반 산출)
  - 완료: 2026-05-04
  - 핵심 결정 (구현 단계):
    - 명세서 5절 권장안 12개(Q-1~Q-12) 그대로 적용 — NPC/문구 const 인라인(`settlement_npc_data.dart`, RegionSectorFallback 패턴) / 채집 의뢰 식별 `quest_pools.id == 'dustvile_chore_03'` 단일 행 하드코딩 / `features/settlement/` 신규 feature 디렉토리 / `_selectedFacility` enum 상태 기반 렌더링 (Navigator.push 미사용) / HiveField 22·23(UserData) + 6(RegionState) + 25·26(ActivityLogType) / 사건 완료 24h 윈도우는 `RegionState.lastEventCompletedAt` 신규 필드 / 수리 의뢰 quest_pools 행 추가 없이 거점 화면 인라인 stub / [채집 정보]·[재료 힌트] M4 정적 텍스트 (M5 인벤토리 도입 시 동적 보유량) / 비활성 버튼은 회색 disabled 노출 / 거점 사건 step 진행도 "n/6" + chain_quests.description 직접 사용 / `MercenaryRepository.healInstant` 단일 책임 메서드 분리 / 단계 진입 보상 자동 지급([보상 받기] 버튼 disabled+안내)
    - 19 TASK 6단계 실행 — Stage 1(병렬 6: TASK 1·2·3·5·6·12) → Stage 2(build_runner, 8 outputs) → Stage 3(병렬 4: TASK 7·8·9·18) → Stage 4(직렬 묶음 TASK 10+11 quest 시그니처 + step==6 setEventCompleted 1줄) → Stage 5(병렬 4: TASK 13·14·15·19) → Stage 6(직렬 2: TASK 16·17 VillageVisitSection → MovementScreen 통합)
    - 빌드 게이트 1건 자동 수정 — `home_screen.dart:525` `_logIcon` switch가 신규 enum 2종 미처리 → herbalistHeal(🌿·d·false) / smithyRepairCompleted(⚒️·d·false) 매핑 추가
    - flutter-reviewer BLOCKER 1건 + WARNING 1건 수정 — `chief_house_screen.dart`가 view에서 data 레이어(`chainQuestRepositoryProvider`) 직접 접근 → 도메인 Provider `chainQuestProgressProvider`(StreamProvider)로 교체 + import 정리. `settlement_npc_data.dart` 상대경로 import → 절대경로(`package:band_of_mercenaries/...`).
    - flutter-reviewer WARNING 2건 보류 — `gameTickProvider` 1초 watch / build 내 `ref.listen`. 프로젝트 전반(건설·조사 쿨다운 / `home_screen.dart`) 동일 패턴이라 별도 리팩토링 PR로 일관 처리 권장. plan.md 6절 명시.
    - `regionStateRepositoryProvider` view 직접 접근 1건 잔존 — `chief_house_screen.dart`의 `eventCompletedRecently` 판정에 사용. 프로젝트 전반(`investigation_widget.dart` / `dispatch_screen.dart` / `quest_provider.dart`)이 동일 패턴이라 본 PR에서 보류. `regionStateProvider`(Provider.family) 신설 시 일괄 정리 권장.
    - 검증 결과 — verifier PASS(REQ-1~16 + 시그니처 + HiveField 충돌 + 호출자 추적 + 상태 기반 렌더링 + region 변경 시 selectedFacility 리셋 + settlementTrustProvider watch 모두 통과) / flutter-reviewer 재작업 후 APPROVE / `flutter analyze` "No issues found" / `flutter test test/features/settlement/` 13/13 PASS (HerbalistService 10 + healInstant 흐름 3)
    - **Supabase 적용 보류 종결** — 본 명세는 SQL 변경 없음(코드 영역만). 페이즈 4 #1·#2·#3 SQL 마이그레이션 4종 + data_versions 증분은 페이즈 4 종료 체크포인트 시점에 단일 일괄 적용으로 결정 (옵션 B 종결 시점)
  - 커밋: `c5716da feat(M4): 페이즈 4 #4 마을 방문 UI + 거점 3종 + 약초상/의무실 분리 ...`

## 실행 이력

- 2026-05-03: 마일스톤 시작 — 신규 모드 (이전 작업 폐기 후 재시작)
- 2026-05-03: 페이즈 1~4 산출물 계획 승인 (페이즈 1: 5건 / 페이즈 2: 4건 / 페이즈 3: 조건부 / 페이즈 4: 5건)
- 2026-05-03: 페이즈 1 #1 완료 (Docs/Archive/20260503_m4-region-migration/design_content.md)
- 2026-05-03: 페이즈 1 #2 완료 (Docs/Archive/20260503_m4-region-sectors/design_sector-system.md)
- 2026-05-03: 페이즈 1 #3 완료 (Docs/Archive/20260503_m4-region-sectors/design_starting-settlement.md)
- 2026-05-03: 페이즈 1 #4 완료 (Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md)
- 2026-05-03: 페이즈 1 #5 완료 (Docs/content-design/[content]20260503_first-2h-playflow.md)
- 2026-05-03: 페이즈 1 종료 — 페이즈 2 진행 결정 대기 (체크포인트)
- 2026-05-03: 페이즈 2 시작 승인 — 밸런스 확정 단계 진입
- 2026-05-03: 페이즈 2 #1 완료 (Docs/Archive/20260503_m4-settlement-trust/design-balance.md)
- 2026-05-03: 페이즈 2 #2 완료 (Docs/balance-design/[balance]20260503_herbalist-vs-infirmary.md)
- 2026-05-03: 페이즈 2 #3 완료 (Docs/Archive/20260503_m4-fixed-quest-system/design_chore-quest-economy.md)
- 2026-05-03: 페이즈 2 #4 완료 (Docs/Archive/20260503_m4-fixed-quest-system/design_fixed-quest-curve.md)
- 2026-05-03: 페이즈 2 종료 — 페이즈 3 진행 결정 대기 (체크포인트)
- 2026-05-03: 페이즈 3 스킵 결정 — 4가지 신규 타입 스펙 작성 부담 + 데이터량 적음 + 페이즈 4 명세 통합으로 단일 PR 일관성. 인라인 처리: region_sectors(페이즈 4 #2) / quest_pools 16행(페이즈 4 #3) / NPC 텍스트(페이즈 4 #4) / 199→40 매핑(페이즈 4 #1)
- 2026-05-03: 페이즈 4 시작 — 개발 명세 단계 진입
- 2026-05-03: 페이즈 4 #1 명세 작성 완료 (Docs/Archive/20260503_m4-region-migration/spec.md, spec-pipeline 1회 PASS)
- 2026-05-03: 페이즈 4 #1 implement-agent 완료 (9 TASK / 풀 검증 verifier PASS + flutter-reviewer 3차 APPROVE / 커밋 94d9ccc)
- 2026-05-03: 페이즈 4 #1 Supabase 적용 보류 결정 — 페이즈 4 #2~#5 모두 완료 후 단일 시점 일괄 적용 (옵션 B)
- 2026-05-03: 페이즈 4 #2 명세 작성 완료 (Docs/Archive/20260503_m4-region-sectors/spec.md, spec-pipeline 통과)
- 2026-05-03: 페이즈 4 #2 implement-agent 완료 (13 TASK 4단계 실행 / 신규 3파일 + 수정 10파일 + 테스트 4파일 / 커밋 2189adf)
- 2026-05-03: 페이즈 4 #2 Supabase 적용 보류 유지 — 페이즈 4 #3~#5 통합 후 일괄 적용 (옵션 B 연장)
- 2026-05-03: 페이즈 4 #3 명세 작성 완료 (Docs/Archive/20260503_m4-fixed-quest-system/spec.md, spec-pipeline 1회 PASS)
- 2026-05-03: 페이즈 4 #3 implement-agent 완료 (13 TASK 7단계 실행 / 신규 1파일(SQL) + 수정 8파일 + 자동 생성 2파일 / verifier PASS + flutter-reviewer APPROVE / 후속 권고 8건 plan.md 기록)
- 2026-05-03: 페이즈 4 #3 Supabase 적용 보류 유지 — 페이즈 4 #4~#5 통합 후 일괄 적용 (옵션 B 연장)
- 2026-05-03: 페이즈 4 #3 finalize-feature commit (`0f39267`) — Archive 4개 design + spec + plan, CLAUDE.md 갱신 (quest_pools 9컬럼/isSettlementStep getter/settlementTier 정렬), CHANGELOG fragment 생성
- 2026-05-03: 페이즈 4 진행 순서 변경 결정 — #4(마을 방문 UI) 이전에 #5(마을 신뢰도 시스템) 우선 진행. 사유: ① #3 stub 해제로 누적된 안전 fallback 활성화 검증 / ② #4 마을 방문 UI는 신뢰도 단계 인사말·거점 잠금이 핵심 입력이라 #5 완성도 의존 / ③ Visual Companion 목업이 #5 데이터 기반 위에서 정확
- 2026-05-03: 페이즈 4 #5 명세 작성 완료 (Docs/Archive/20260503_m4-settlement-trust/spec.md, spec-pipeline 1회 PASS)
- 2026-05-04: 페이즈 4 #5 implement-agent 완료 (17 TASK 9단계 실행 / 신규 3파일 + 수정 14파일 + 자동 생성 2파일 / verifier PASS + flutter-reviewer APPROVE(HIGH 1건 수정 후) / 페이즈 4 #3 후속 권고 #1·#2·#3 통합 처리)
- 2026-05-04: 페이즈 4 #5 Supabase 적용 보류 유지 — 본 명세는 SQL 변경 없음. 페이즈 4 #1·#2·#3 SQL 마이그레이션 4종은 페이즈 4 #4 완료 후 단일 시점 일괄 적용 (옵션 B 종결 시점)
- 2026-05-04: 페이즈 4 #5 finalize-feature commit (`332df75`) — Archive 4개 (design-content + design-balance + spec + plan), CLAUDE.md 갱신 (RegionState HiveField 4·5 / ActivityLogType 22~24 / settlementTrustLevelUpProvider + settlementTrustProvider / DialogTypeRegistry 8종 / 마을 신뢰도 시스템 게임 시스템 항목), CHANGELOG fragment 생성
- 2026-05-04: 페이즈 4 #4 명세 작성 완료 (Docs/Archive/20260504_m4-settlement-visit-ui/spec.md, spec-pipeline 1회 PASS — Q-1~Q-12 결정 권장안 모두 채택)
- 2026-05-04: 페이즈 4 #4 implement-agent 완료 (19 TASK 6단계 실행 / 신규 10파일(domain 3 + view 5 + test 2) + 수정 11파일 + 자동 생성 3파일 / verifier PASS + flutter-reviewer BLOCKER 1+WARNING 1 수정 후 APPROVE / flutter test 13/13 PASS)
- 2026-05-04: 페이즈 4 #4 finalize-feature commit (`c5716da`) — Archive 4개 (design-content + design-balance + spec + plan), CLAUDE.md 갱신 (UserData HiveField 22·23 / RegionState HiveField 6 + eventCompletedRecently / ActivityLogType 25·26 / 마을 방문 게임 시스템 항목), CHANGELOG fragment 생성
- 2026-05-04: 페이즈 4 5건 전부 완료 — 페이즈 4 종료 체크포인트 대기 (마일스톤 종료 직전)
- 2026-05-04: Supabase 일괄 적용 종결 (옵션 B 종결 시점) — 페이즈 4 #1·#2·#3 SQL 마이그레이션 3종 모두 적용 (project: wqeypiuywhtyznisoxla)
  - 페이즈 4 #1: regions 199→40, region 3 더스트플레인(mountain) 재태깅, region 200(망각의 수면 T9) INSERT, region_discoveries 47→32 (15행 정리), data_versions(regions/region_discoveries) +1
  - 페이즈 4 #2: regions.sector_count 컬럼 추가(default 4), region_sectors 테이블 신설(시드 0행), 4개 region(1·23·127·146) sector_count=5 승격, region_discoveries sector_index 재매핑(region 18 ≥4→1 / region 23·146 ≥4→4), data_versions(regions/region_discoveries +1, region_sectors version=1 신규)
  - 페이즈 4 #2 spec 보정: regions.region 컬럼에 UNIQUE 제약 추가(spec 누락) — region_sectors FK 참조용
  - 페이즈 4 #3: quest_pools 9개 컬럼 추가(is_fixed/fixed_chain_id/fixed_step/trust_threshold/reward_gold_override/reward_xp_bonus_override/duration_override_seconds/trust_reward_override/min_trust_level), Partial UNIQUE 인덱스(idx_quest_pools_fixed_chain_step), dustvile_pyegwang_reopen 6행 + dustvile_chore_NN 10행 INSERT (총 332→348행), data_versions(quest_pools) +1
  - 페이즈 4 #3 spec 보정: description 컬럼 INSERT 제거(quest_pools 테이블에 description 컬럼 부재 — spec의 SQL 결함, QuestPool 모델에도 미사용)
  - 검증: 모든 ASSERT PASS / data_versions 최종(regions=5, region_discoveries=5, region_sectors=1, quest_pools=5, chain_quests=2)
- 2026-05-04: M4 마일스톤 완료
