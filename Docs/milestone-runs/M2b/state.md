# M2b 실행 상태

> 시작: 2026-04-20
> 마지막 업데이트: 2026-04-23 (페이즈 4-4 구현 완료)
> 현재 페이즈: 4
> 상태: completed

## 로드맵 요구사항 요약

- 테마: "엘리트의 시대" — M2a 아이템 인프라 위에 엘리트 몬스터를 올려 반복 파밍 플레이 패턴을 만든다.
- 핵심 시스템 1종: 엘리트 몬스터 (지식 임계값 해금, 반복 출현, 고난도 토벌, 드랍 판정 — 정수 40~60% / 장비 15~25% / 유물 3~8%)
- 검증 데이터: 엘리트 10~15종 (Tier 2~3 분포)
- 스키마 확장: `elite_monsters`, `elite_loot_tables` 2개 테이블
- 종료 조건: Tier 2~3 리전에서 엘리트 1~2종 해금, 반복 파밍으로 정수 5~10개 수집하여 용병 영구 스탯 의미 있게 상승시키는 3~5시간 플레이 가능
- 선행 의존: M2a 아이템 인프라(완료 `e5a76de`), 지역 조사 + `region_discoveries` 인프라(완료)

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 엘리트 몬스터 카탈로그 컨셉 — 리전 티어별 엘리트 종류/테마, 출현 리전 선정, 서사적 포지셔닝
  - 참고 문서: `Docs/roadmap/master_roadmap.md` M2b 섹션, `Docs/game_overview.md`
  - 산출물: `Docs/content-design/[content]20260420_elite_monster_catalog.md`
  - 완료: 2026-04-20 12:08
  - 핵심 결정: 2계층 구조(보통 31종 + 유니크 8종 = 39종), 환경 태그 8종 JSONB 다중 태그, `regions.environment_tags` 신설 (스코프 확장)
- [x] 2. 드랍 테이블 구조 기획 — 드랍 카테고리(정수/장비/유물), 엘리트별 드랍 구성 원칙, 반복 파밍 심리 설계
  - 참고 문서: 페이즈 1 산출물 1, M2a 아이템 데이터
  - 산출물: `Docs/content-design/[content]20260420_elite_drop_table.md`
  - 완료: 2026-04-20
  - 핵심 결정: 드랍 카테고리 4종(gold/essence/personal_equipment/guild_artifact), 희소성 4등급(common/rare/epic/legendary 시각 구분), 엘리트당 드랍 행 보통 4~6 / 유니크 7~9 (전체 평균 5~7), 독립 확률 판정 방식 확정(페이즈 1-1 §7 Q-1 해소), 타입 가족 → 정수 주/부/미드랍 축 매핑, 유니크 8종 signature drop(M2a 유물 4종 2:1 배치), `elite_loot_tables` 스키마 초안, data-generator 목표 200~270행

## 페이즈 2: 밸런스 확정

**상태**: in_progress

계획된 산출물:
- [x] 1. 엘리트 전투력 / 성공률 곡선 — 티어별 전투력 100~200, 소요시간 1.5~2배, 출현 확률 8~15% 확정
  - 참고 문서: 페이즈 1 산출물 1
  - 산출물: `Docs/balance-design/[balance]20260420_elite_combat_power.md`
  - 완료: 2026-04-20 13:00
  - 핵심 결정: 보통 31종 전투력 T2=85~110/T3=120~150/T4=170~200 (타입 가족 ±5~10 편차), 유니크 8종 120~245(T5 리치 의도적 범위 초과), 소요시간 1.5~2.0× 7구간, 출현 확률 보통 15/12/8% + 유니크 8/7/6/5%. 파티 시나리오 A~D × 엘리트 교차 매트릭스로 주 공략 성공률 50~85% 검증
- [x] 2. 드랍률 × 파밍 주기 시뮬레이션 — 드랍률 확정, M2a 정수 인플레이션에 엘리트 파밍 속도 대입
  - 참고 문서: 페이즈 1 산출물 2, 페이즈 2 산출물 1, M2a 시뮬레이션
  - 산출물: `Docs/balance-design/[balance]20260420_elite_drop_simulation.md`
  - 완료: 2026-04-20 13:33
  - 핵심 결정: 보통 essence 주축 30~50%/부축 15~30% · 유니크 essence 주축 50~70%/부축 epic 30~45%/상위 legendary 5~15%. 기대 행수 상향 보통 1.55~2.00 / 유니크 2.80~3.60. 시간당 정수 0.28~0.45개 (시나리오 A~D). 골드 드랍 재확정(보통 1.53~1.63× / 유니크 2.49~2.96×). signature drop T2 울부르 15% / T3~T4 10~15% / T5 리치 각 6%. **M2a 로드맵 "3~5시간에 5~10개" 과대 지적 → M2b 12~25시간 재설정 (Q-1)**. **M6 승급 옵션 B(140개) 약 180h 필요, 로드맵 "헤비 1주" 미달 → M6 기획 재검토 요청 (Q-2)**

## 페이즈 3: 데이터 생성

**상태**: completed

계획된 산출물:
- [x] 1. `types/elite-monster.md` 타입 스펙 작성 — data-generator에 elite_monsters + elite_loot_tables 생성 규칙 정의 (2계층 구조, 10 타입 가족 변주, 유니크 맹주 8종 네이밍·서사 고정)
  - 산출물: `.claude/skills/data-generator/types/elite-monster.md`
  - 완료: 2026-04-23
  - 핵심 내용: 보통 31종 + 유니크 8종 전체 고정 목록 (id/name/tier/power/spawn_rate/duration_multiplier/environment_tags/stat_weight), elite_loot_tables 스키마 + drop_rate 가이드 + 골드 min/max 확정표 + signature drop 매핑 + 타입 가족별 essence/장비 드랍 축 매핑 + 자체 검증 체크리스트
- [x] 2. `types/region-environment-tag.md` 타입 스펙 작성 — 199개 리전에 환경 태그 1~3개 부여 규칙 (description 기반 반자동 분류, 8개 태그 세트, 충돌 검증 규칙)
  - 산출물: `.claude/skills/data-generator/types/region-environment-tag.md`
  - 완료: 2026-04-23
  - 핵심 내용: 8개 태그 키워드 분류 기준, 티어별 태그 경향, desert+swamp 등 금지 조합, 분포 목표(±30%), CSV/SQL 출력 포맷, 자체 검증 체크리스트
- [x] 3. 리전 환경 태그 데이터 — 199개 리전에 `environment_tags` JSONB 부여
  - 입력 기획서: 페이즈 1 산출물 1 (§3.2, §3.7)
  - 대상 테이블: `regions` (UPDATE, 199행)
  - 산출물: `Docs/content-data/[region-environment-tag]20260423_m2b-regions.csv`
  - 메타: `Docs/content-data/[region-environment-tag]20260423_m2b-regions.md`
  - 완료: 2026-04-23
  - 핵심 내용: 8종 태그 전부 목표 범위 달성 (plains 42/coast 18/forest 25/swamp 11/ruins 38/mountain 35/desert 15/underground 24, 총 208태그). region_name 개편(해안 18개/늪 11개/숲 +1) + data_versions 버전 2 갱신 선행 완료. DB UPDATE는 페이즈 4-1 마이그레이션 후 적용 예정
- [x] 4. 엘리트 몬스터 39종 (보통 31 + 유니크 8) — elite-monster 타입 data-generator 호출
  - 입력 기획서: 페이즈 1 산출물 1 + 페이즈 2 산출물 1
  - 대상 테이블: `elite_monsters` (신규, 미존재 — Phase 4-1 마이그레이션 후 INSERT 예정)
  - 산출물: `Docs/content-data/[elite-monster]20260423_m2b-elite-monsters.csv`
  - 메타: `Docs/content-data/[elite-monster]20260423_m2b-elite-monsters.md`
  - 완료: 2026-04-23
  - 핵심 내용: 보통 31종(T2×7/T3×13/T4×11) + 유니크 8종(T2×1/T3×3/T4×3/T5×1). stat_weight 합계 1.0 전 행 검증, 유니크 8종 lore/title/fixed_region_environments 포함. elite_monsters 테이블 미존재로 Supabase INSERT는 Phase 4-1 DDL 후 예정
- [x] 5. 엘리트 드랍 테이블 200~270행 — 각 엘리트별 드랍 항목·확률. M2a items 외래키 참조
  - 입력 기획서: 페이즈 1 산출물 2 + 페이즈 2 산출물 2 + 페이즈 3 산출물 4
  - 대상 테이블: `elite_loot_tables` (신규, 미존재 — Phase 4-1 마이그레이션 후 INSERT 예정)
  - 산출물: `Docs/content-data/[elite-loot-table]20260423_m2b-elite-loot-tables.csv`
  - 메타: `Docs/content-data/[elite-loot-table]20260423_m2b-elite-loot-tables.md`
  - 완료: 2026-04-23
  - 핵심 내용: 39종 × 평균 5.4행 = 209행. 보통 Σ 1.68~1.82 / 유니크 Σ 2.80~2.88. undead/demon 에센스 int/agi 전용 준수. 모든 item_id Supabase items 테이블 실존 ID 검증. elite_loot_tables 테이블 미존재로 INSERT는 Phase 4-1 DDL 후 예정
- [x] 6. 유니크 엘리트 region_discovery 행 8~16개 — 유니크 8종의 발견 단서 배치 (`discovery_type = 'elite'`)
  - 입력 기획서: 페이즈 1 산출물 1 (§3.4, §6.4) + 페이즈 3 산출물 3, 4
  - 대상 테이블: `region_discoveries` (기존)
  - 산출물: `Docs/content-data/[region-discovery]20260423_m2b-elite-discoveries.csv`
  - 메타: `Docs/content-data/[region-discovery]20260423_m2b-elite-discoveries.md`
  - 완료: 2026-04-23
  - 핵심 내용: 16행 (유니크 8종 × 2 리전). threshold T2=30/T3=50/T4=70/T5=85. discovery_data `{elite_id, reveal_text}` 형식. 환경 태그-region_tier 교차 매칭으로 region_id 확정 (Supabase 실조회)

## 페이즈 4: 개발 명세

**상태**: in_progress

계획된 산출물:
- [x] 1. 리전 환경 태그 마이그레이션 + `Region` 모델 확장 — `regions.environment_tags` JSONB 컬럼 추가 마이그레이션, `Region` Freezed 모델 확장, SyncService 재동기화, data_versions 재퍼블리시
  - 입력 기획서: 페이즈 1 산출물 1 (§3.2)
  - 산출물: `Docs/spec/[spec]20260423_m2b-4-1-region-environment-tags.md`
  - 완료: 2026-04-23
  - 핵심 내용: Supabase DDL + 199행 UPDATE(id=1~199) + data_versions.regions 버전 3 갱신. Flutter Region 모델 environmentTags(@Default<String>[]) 추가. flutter analyze No issues.
- [x] 2. 엘리트 데이터 모델 + SyncService 확장 — `EliteMonsterData`, `EliteLootEntry` Freezed 모델, `elite_monsters` + `elite_loot_tables` 2개 테이블 신설·동기화, `region_discoveries` elite 타입 파싱
  - 입력 기획서: 페이즈 3 산출물 4, 5 + 페이즈 4 산출물 1 (의존)
  - 산출물: `Docs/spec/[spec]20260423_m2b-4-2-elite-data-models.md`
  - 완료: 2026-04-23
  - 핵심 내용: elite_monsters/elite_loot_tables DDL + EliteMonsterData(14 필드)/EliteLootEntry(9 필드) Freezed, SyncService allTables +2(20→21번), StaticGameData +2 필드, InvestigationNotifier elite 분기 + InvestigationResult.unlockedEliteIds 추가
- [x] 3. 엘리트 퀘스트 생성 + 드랍 판정 — 환경 태그 매칭 기반 보통 엘리트 확률 출현, `RegionState.triggeredDiscoveries` 기반 유니크 해금, `ActiveQuest.isElite` 플래그, `EliteLootService` 드랍 판정, M2a `InventoryRepository` 적재
  - 입력 기획서: 페이즈 1 산출물 1-2 + 페이즈 2 산출물 전체 + 페이즈 4 산출물 1, 2
  - 산출물: `Docs/spec/[spec]20260423_m2b-4-3-elite-quest-loot_plan.md`
  - 완료: 2026-04-23
  - 핵심 내용: ActiveQuest HiveField(20) eliteId + isElite getter. EliteLootService(rollDrops) + EliteLootResult 신규. QuestGenerator 엘리트 파라미터 3개 + 보통/유니크 생성 블록(최대 2개 추가 슬롯). QuestCompletionResult.eliteLoot 필드. QuestListNotifier 엘리트 드랍 처리(bonusGold addGold/itemDrops addItem). flutter analyze No issues. 127/127 테스트 통과. Supabase: elite_monsters 39행(v2)/elite_loot_tables 204행(v2)/region_discoveries elite 16행(v3)
- [x] 4. 엘리트 UI — 파견 화면 보통·유니크 2계층 구분(아이콘·강조 색상·서사 툴팁), 최소 파견 인원 권장, 퀘스트 완료 팝업 드랍 결과 리스트
  - 입력 기획서: 페이즈 4 산출물 3
  - 산출물: `Docs/spec/[spec]20260423_m2b-4-4-elite-ui.md`
  - 완료: 2026-04-23
  - 핵심 내용: pendingEliteLootProvider(Map<String,EliteLootResult>) 신규 추가. _buildQuestCard 보통/유니크 색상·배지·사이드바 분기. dispatch_detail_page 서사 카드(보통=description/유니크=title+lore). QuestResultDialog eliteLoot 파라미터 + _buildEliteLootSection. flutter analyze No issues. 372/372 테스트 통과

## 실행 이력

- 2026-04-20: 마일스톤 시작
- 2026-04-20: 페이즈 1~4 계획 승인 (총 10개 산출물, 페이즈 3은 타입 스펙 선행)
- 2026-04-20: 페이즈 1 진입
- 2026-04-20 12:08: 페이즈 1 항목 1 완료 — 엘리트 몬스터 카탈로그 컨셉 (39종 2계층 구조, 환경 태그 8종, `regions.environment_tags` 스코프 확장 결정)
- 2026-04-20 12:10: 페이즈 3 확장 (3→6 산출물: `region-environment-tag` 타입 스펙 + 리전 태그 199행 + 엘리트 수량 39종 + 드랍 200~270행 + region_discovery 행)
- 2026-04-20 12:10: 페이즈 4 확장 (3→4 산출물: 리전 환경 태그 마이그레이션 + Region 모델 확장 별도 분리)
- 2026-04-20: 페이즈 1 항목 2 완료 — 드랍 테이블 구조 기획 (카테고리 4종, 희소성 4등급, 독립 확률 판정, M2a 30종 아이템 매핑, 유니크 signature drop 매핑, 200~270행 생성 목표)
- 2026-04-20: 페이즈 1 완료, 페이즈 2 진입
- 2026-04-20 13:00: 페이즈 2 항목 1 완료 — 엘리트 전투력/성공률 곡선 (보통 31종 85~200, 유니크 8종 120~245, 소요시간 1.5~2.0× 7구간, 출현 확률 보통 15/12/8% + 유니크 8/7/6/5%, 파티 시나리오 A~D × 엘리트 교차 매트릭스 50~85% 검증)
- 2026-04-20 13:33: 페이즈 2 항목 2 완료 — 드랍률 × 파밍 주기 시뮬레이션 (drop_rate 구성 확정, 시간당 정수 0.28~0.45개, 골드 재조정, signature drop 15/12/10/6%, M2a 로드맵 과대 지적 + M6 승급 옵션 B 갭 경고)
- 2026-04-20 13:33: 페이즈 2 완료 → 페이즈 3 체크포인트 대기
- 2026-04-20 13:35: 페이즈 3 진입 승인 (첫 액션: `types/elite-monster.md` 타입 스펙 작성)
- 2026-04-23: 페이즈 3 항목 1 완료 — `types/elite-monster.md` 작성 (보통 31종 + 유니크 8종 고정 목록, elite_loot_tables 스키마·드랍률·골드·signature drop 매핑 통합)
- 2026-04-23: 페이즈 3 항목 2 완료 — `types/region-environment-tag.md` 작성 (8개 태그 분류 규칙, 충돌 검증, 분포 목표, CSV 출력 포맷)
- 2026-04-23: 리전 이름 개편 Supabase 실행 (초원→해안 18개, 숲→늪 11개, 폐허→숲 1개) + data_versions.regions 버전 1→2 갱신
- 2026-04-23: 페이즈 3 항목 3 완료 — 리전 환경 태그 199행 CSV 생성 (8종 태그 전부 목표 범위 달성, DB UPDATE는 페이즈 4-1 후 예정)
- 2026-04-23: 페이즈 3 항목 4 완료 — 엘리트 몬스터 39종 CSV 생성 (보통 31 + 유니크 8, elite_monsters 테이블 미존재로 INSERT 보류)
- 2026-04-23: 페이즈 3 항목 5 완료 — 엘리트 드랍 테이블 209행 CSV 생성 (보통 154행 + 유니크 66행, 전 행 drop_rate/essence Σ 검증, elite_loot_tables 테이블 미존재로 INSERT 보류)
- 2026-04-23: 페이즈 3 항목 6 완료 — 유니크 엘리트 region_discovery 16행 CSV 생성 (유니크 8종 × 2 리전, Supabase region tier 실조회로 region_id 확정, discovery_data {elite_id,reveal_text} 형식)
- 2026-04-23: 페이즈 3 완료 → 페이즈 4 체크포인트 대기
- 2026-04-23: 페이즈 4 진입 승인 (첫 액션: 리전 환경 태그 마이그레이션 + Region 모델 확장 명세)
- 2026-04-23: 페이즈 4 항목 1 완료 — regions.environment_tags 마이그레이션 (Supabase DDL+199행+data_versions v3) + Region 모델 environmentTags 필드 추가 + build_runner 성공 + flutter analyze No issues
- 2026-04-23: 페이즈 4 항목 2 명세 완료 — `Docs/spec/[spec]20260423_m2b-4-2-elite-data-models.md` 생성
- 2026-04-23: 페이즈 4 항목 2 구현 완료 — implement-agent 파이프라인 (8 TASK). EliteMonsterData/EliteLootEntry Freezed 모델 신규 + elite_monsters/elite_loot_tables DDL + SyncService 21개 + StaticGameData 확장 + InvestigationNotifier elite 분기. flutter analyze No issues. plan: `Docs/spec/[spec]20260423_m2b-4-2-elite-data-models_plan.md`
- 2026-04-23: 페이즈 4 항목 3 명세 완료 — `Docs/spec/[spec]20260423_m2b-4-3-elite-quest-loot.md` 생성
- 2026-04-23: 페이즈 4 항목 3 구현 완료 — implement-agent 파이프라인 (5 TASK). ActiveQuest HiveField(20) eliteId + EliteLootService + QuestGenerator 엘리트 블록 + QuestCompletionResult.eliteLoot + QuestProvider 엘리트 드랍 처리. 2차 검증 PASS. flutter analyze No issues. 127/127 + 9/9 테스트 통과. plan: `Docs/spec/[spec]20260423_m2b-4-3-elite-quest-loot_plan.md`
- 2026-04-23: 페이즈 4 항목 4 명세서 완료 — `Docs/spec/[spec]20260423_m2b-4-4-elite-ui.md` (verify-spec PASS)
- 2026-04-23: 페이즈 4 항목 4 구현 완료 — implement-spec. pendingEliteLootProvider 신규 + dispatch_screen 엘리트 분기 + dispatch_detail_page 서사 카드 + quest_result_dialog 드랍 섹션. flutter analyze No issues. 372/372 테스트 통과. plan: `Docs/spec/[spec]20260423_m2b-4-4-elite-ui_plan.md`
- 2026-04-23: M2b 마일스톤 완료 (페이즈 1~4 전체)
