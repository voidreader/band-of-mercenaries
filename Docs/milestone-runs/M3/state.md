# M3 실행 상태

> 시작: 2026-04-23
> 마지막 업데이트: 2026-04-25 (페이즈 4 완료, 마일스톤 완료)
> 현재 페이즈: 4
> 상태: completed

## 로드맵 요구사항 요약

- 테마: "깊어지는 세계" — 지역 조사의 최종 보상을 완성하고, 세계에 서사 계층을 부여한다.
- 핵심 시스템 3종: 숨겨진 연계 퀘스트(2~5단계 체인, 확정 아이템), 지역 변형(마을/유적지/숨겨진 섹터), 퀘스트 서사 + 이동 선택지(TemplateEngine 공유)
- 검증 데이터: 연계 퀘스트 5~8체인(15~30단계), 변형 리전 15~25개, 서사 템플릿 48~80개, 이동 선택지 10~15종
- 스키마 확장: `chain_quests`, `quest_narratives`, `travel_choice_events` 3개 신규 테이블 + `RegionState.sectorChanges` 확장 + `quest_pools.sector_type` 활용
- 종료 조건: 연계 퀘스트 2개 이상 완주 + 지역 변형 1회 이상 경험 + 서사 템플릿이 모든 quest_type × result_type 조합에 최소 1개. 5~8시간 플레이.
- 선행 의존: M2a 아이템 인프라(완료), 지역 조사 + `region_discoveries` 인프라(완료)

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. TemplateEngine 공유 모듈 설계 — 변수 치환, 조건 분기, 트레잇 기반 숨겨진 옵션 평가
  - 참고 문서: `Docs/roadmap/master_roadmap.md` M3 섹션 "통합 근거", 기존 TravelEvent 구조
  - 산출물: `Docs/content-design/[content]20260423_template_engine.md`
  - 완료: 2026-04-23
  - 핵심 결정: 구문 2종 분리(`{치환}` + `[블록]`), 변수 카탈로그 4 네임스페이스 29 필드(merc/quest/region/world), 조건식 9개 연산자(수식 금지), if 2단계 중첩 상한, pick 2~10개, 3가지 적용 지점 통일(가시성/텍스트 변주/결과 변주), operation-bom TS가 진실의 원천 → Dart 카탈로그 빌드 타임 자동 생성(Option A), 런타임 fail-safe `[?var]` 표시. 오픈 질문 6건(Q-1 codegen 도구 / Q-2 대표 용병 선정 / Q-3 pick 시드 재현 / Q-4 선택지 결과 적용 시점 / Q-5 카탈로그 확장 정책 / Q-6 `quest.enemy` 필드 위치)
- [x] 2. 연계 퀘스트 시나리오 기획 — 5~8개 체인, 2~5단계, 리전 티어 분포, 단계별 지역/전투력/보상/서사, 실패 재도전, 최종 확정 보상 아이템 선정
  - 참고 문서: M3 섹션, M2a items 데이터(`Docs/content-data/[item]20260420_m2a-equipment.csv`), 페이즈 1-1 TemplateEngine
  - 산출물: `Docs/content-design/[content]20260423_chain_quests.md`
  - 완료: 2026-04-23
  - 핵심 결정: 7체인/24단계(2+3+3+3+4+4+5), 리전 티어 T1~T5 분산, 지역 이동 체인 5/7, M2a 장비 10종 중 7종 매핑(개인6+용병단1) — 나머지 3종(깃발/뿔피리/방패장식)은 엘리트·M4 경로로 분리. knowledge_threshold 60~95 분포. next_step_delay 실제 시간 기준(입문 10분~엔드 6시간). 체인 포기 불가 + 7일 휴면. **Q-2 확정: (e) 체인 시작 시점 protagonistMercId 고정 + 사망 폴백** (ChainQuestProgress 신규 필드). 체인 서사는 `chain_quests.description`에 직접 저장(quest_narratives와 독립). 오픈 질문 6건(Q-1 휴면 기간 / Q-2 인벤 가득 사전 차단 / Q-3 이동 중 delay 흐름 / Q-4 다중 체인 임계 차이 순차 / Q-5 실패 무보상 / Q-6 추상 세력→실제 faction id 매핑 1-4/3-1에서 확정)
- [x] 3. 지역 변형 기획 — 마을/유적지/숨겨진 섹터 3유형, 변형 대상 리전 15~25개 선정, 유형별 전용 퀘스트 풀 컨셉
  - 참고 문서: M3 섹션, 페이즈 1-2 (연계 퀘스트 최종 단계와의 연결)
  - 산출물: `Docs/content-design/[content]20260423_region_transform.md`
  - 완료: 2026-04-24
  - 핵심 결정: 3유형 포지셔닝 확정(village 안전/반복·ruins 고위험·역사·1회성 강화·hidden 희귀 발견), 18개 변형 대상 리전 선정(T1-1: 5개/T2-3: 5개/T3-5: 4개/T4: 3개/T5: 1개), sector_type 4값(village/ruins/hidden/standard). 트리거 임계값: village 90/ruins 80/hidden 95. 영속성(되돌릴 수 없음) 확정. 연계 퀘스트 최종 단계 → 변형 잠금 해제 상호작용 확정. 체인 퀘스트 6/7이 변형 완료 조건 포함.
- [x] 4. 퀘스트 서사 템플릿 기획 — quest_type(4) × result_type(4) 매트릭스, 유형×결과별 3~5개 변형 총 48~80개
  - 참고 문서: 페이즈 1-1 (TemplateEngine 문법)
  - 산출물: `Docs/content-design/[content]20260424_quest_narratives.md`
  - 완료: 2026-04-24
  - 핵심 결정: **매트릭스 옵션 β(88행) 확정** — quest_type 6유형(활성 raid/hunt/escort/explore 4 + 스키마만 존재 labor/survey 2). 활성 4×4×4변형=64 + labor/survey 4×2변형×2유형=16 + 엘리트 전용 hunt/raid×4 result×1변형=8. **엘리트·섹터 확장 D 확정**(엘리트 전용 8행 + 섹터는 `[if region.sector_type=="..."]` 인라인 분기). **대표 용병 (b) 파티 기여 1위 확정**(`QuestCalculator.statWeights` 기반, labor=균등/survey=INT·AGI 우선). **스키마**: `quest_narratives`(id/quest_type/result_type/is_elite/template/weight/description) + CHECK 제약 + lookup 인덱스. **`quest_pools.enemy_name TEXT NULL` 신규 컬럼** + `{quest.enemy|적}` fallback. **`region.sector_type` 변수 추가**(카탈로그 29→30, 페이즈 1-1 후속 반영 필요). pick 50% 적용, 후보 2~4, 행당 최대 2개. 길이 40~120자 1~2문장. 체인 퀘스트는 `chain_quests.description` 독립(본 풀 비적용). 변형 섹터 34행·세력 전용 98행은 본 풀 자동 커버. 오픈 질문 8건(labor/survey 가중치·지역조사 관계·세력 톤 분기 범위·pick 시드·enemy_name 미채움 UX·엘리트 fallback 품질·엘리트 행의 quest.enemy 사용·weight 초기 차등).
- [x] 5. 이동 선택지 이벤트 기획 — 10~15종 시나리오, 선택지 2~3개, 결과 확률, 트레잇 기반 숨겨진 선택지
  - 참고 문서: 페이즈 1-1 (TemplateEngine 문법), 기존 TravelEvent 12종
  - 산출물: `Docs/content-design/[content]20260424_travel_choices.md`
  - 완료: 2026-04-24
  - 핵심 결정: **스키마 3테이블 분리 확정**(`travel_choice_events` + `travel_choice_options` + `travel_choice_results`). **발동 타이밍 "도착 후 회상"**(이동 중 UI 변화 없음, 방치형 UX 유지). 4 카테고리(encounter/dilemma/discovery/hazard) × 3개 = **12종 시나리오**. 선택지 구조: 기본 2(safe+risky) + 숨겨진 0~1(hidden) 총 2~3개. 결과 분기 선택지당 2~3개, probability 합=1.0 + `conditional_expr` 탈락 시 런타임 정규화. **효과 타입 8종**: 기존 5종(gold/injury/heal_tired/reputation/trait_innate) + 신규 3종(trait_acquired/item/nothing). delay 효과 제외(회상 맥락 부적절). **대표 용병 선정: preferred_traits 매칭 + 최고 레벨 fallback**(team-wide visibility 평가와 구분). **EV 정책: hidden > safe ≥ risky**(수치는 페이즈 2-3 위임). **TemplateEngine `evaluationScope` 파라미터 확장 후속 반영 필요**(has_trait 등의 team-wide 평가 모드). rollEvent 통합: 자동 이벤트 + 선택지 이벤트 독립 roll (선택지는 `distance × 0.08~0.12`). 총 114행 추정(12+30+72). 오픈 질문 10건(발동 확률·hidden UI 표시·trait 키 실존·preferred vs visibility 일치·delay 재확장·trait_acquired 매커니즘 공유·item 풀·팝업 순서·전원 파견 fallback·로그 표시).
- [x] 6. 공존 정책 정의 — 파견 화면 [연계 진행 단계 최상단] > [가입 세력 전용(M1)] > [엘리트(M2b)] > [일반] 정렬·강조·UI 슬롯 규칙
  - 참고 문서: 페이즈 1-2, 1-3, 1-4, 1-5, M1 세력 전용 퀘스트 UI, M2b 엘리트 UI
  - 산출물: `Docs/content-design/[content]20260424_coexistence_policy.md`
  - 완료: 2026-04-24
  - 핵심 결정: **5계층 정렬 확정**(상단 고정 체인 > 세력 전용 > 엘리트 > 변형 섹터 > 일반). **카드 시각 3원칙**(사이드바 1개만/배지 복수 허용/테두리는 체인·세력 전용에만). **도착 팝업 8단계 순차**(퀘스트 결과 → 자동 이벤트 → 선택지 회상 → 건설 완료 → 조사 완료 → 랭크업 → 체인 진행 → 변형 발동). **Global Dialog Queue 도입** (critical/high/medium/low 4 priority + Hive persistence + 24h 만료). **`RankUpOverlay` 큐 경유로 전환**(즉시 표시 → 큐 경유). **"오늘의 기록" 요약 화면 M3 MVP 제외**(M4+ 검토). 활동 로그 4개 신규 타입(regionTransform/chainProgressed/chainCompleted/travelChoiceCompleted, HiveField 15~18). 페이즈 1-5 Q-8·페이즈 1-3 §5-4 해결. 오픈 질문 10건(체인 상단 3장 제한·세력명 축약·M4 중첩 대비·큐 만료 24h·조사 동시성·보라 색 유사·상단 고정 토글·필터 UI·배지 overflow·persistence 복원 실패).

## 페이즈 2: 밸런스 확정

**상태**: in_progress

계획된 산출물:
- [x] 1. 연계 퀘스트 확정 보상 강도 — 체인 최종 보상 vs M2b 엘리트 반복 파밍 시간 효율 비교
  - 참고 문서: 페이즈 1-2, M2b 드랍 시뮬레이션
  - 산출물: `Docs/balance-design/[balance]20260424_chain_quest_rewards.md`
  - 완료: 2026-04-24
  - 핵심 결정: **수치 변경 7건** — (1) 체인 1 단계 골드 120/300→150/400, (2) 완주 명성 보너스 공식 `단계수×150×tier_weight`(합 4,890), (3) 체인 단계 death_rate ×0.5 하드 감산(injury는 유지), (4) 휴면 전환 7일→14일, (5) 인벤 사전 차단(c) 확정, (6) 체인 7 단계 4→5 delay 6h→4h(총 15h→13h), (7) 체인 2~6 및 멸혼결 엘리트 경로 현 설계 유지. **active 시간 기준 체인이 엘리트 대비 14~173배 효율** 검증. 체인 7 주인공 생존율 18.7%→46.2% 시뮬. Q-1(휴면)·Q-2(인벤) 해결. 페이즈 4-2 spec 반영 사항 4건(명성 로직/death 감산/인벤 차단/휴면 14일) + 페이즈 3-1 data-generator 가이드 §7. 오픈 질문 5건(Q-A 일반퀘 명성 비교·Q-B death 감산 UI 배지·Q-C 멸혼결 M4 대안·Q-D 랭크 패시브 미반영·Q-E delay 누적 UX).
- [x] 2. 섹터 변형 전용 퀘스트 난이도/보상 — 유적지(고위험·고보상) vs 마을(안전 대안), 숨겨진 섹터 특수 보상 밸런스
  - 참고 문서: 페이즈 1-3
  - 산출물: `Docs/balance-design/[balance]20260424_sector_transform_quests.md`
  - 완료: 2026-04-24
  - 핵심 결정: **3유형 수치 확정** — (1) Village 유형 분포 `호4/탐3/노3/약1/토1`로 조정(labor 3개 신규 투입 → 시간당 수익 엘리트 T3의 91%→65%), D2~D3 고정; (2) Ruins 기존 유지(토5/탐4/약3, D4~D5 평균 4.4) + 드랍 플래그 4개 퀘 배정; (3) Hidden 10개 `3 trait_boost + 3 guild_drop + 4 일반`(깃발 T3 3%/뿔피리 T4 2%/수호자방패장식 T5 1%). **트레잇 학습 가속 수치 ×1.5 × 24h 확정**. **쿨다운 없음** 정책. **knowledge_threshold 98 유지**, 체인 5/6 보너스 +10/+15 유지. **`quest_pools.special_flags JSONB` 신규 필드 DDL** 선행 필요. **D1~D5 스케일 입력 강제**(기존 200행 1~10 스케일 이슈는 페이즈 3-6과 통합 권장). Q-1·Q-3·Q-4 해결. 페이즈 4-3 spec 7건 반영 사항. 오픈 질문 7건(labor 톤·Ruins death 감산·Hidden drop M4·flags DDL·체인 5/6 임계·scale 불일치·기획서 §4-2 labor 추가).
- [x] 3. 이동 선택지 기대값 시뮬레이션 — 선택지별 EV 계산, 위험/안전 합리성 검증
  - 참고 문서: 페이즈 1-5
  - 산출물: `Docs/balance-design/[balance]20260424_travel_choice_ev.md`
  - 완료: 2026-04-24
  - 핵심 결정: **1G 환산표 제정** (rep×10·injury×-400·heal_tired×±50·trait_innate+400·trait_acquired+300·item 하+40/중+150·nothing 0). **기획 §9-1 정책 위반 감지**(hidden 51G < risky 55G) → hidden r0 `herb_bundle→rare_herb`(150G)·r1 `rep+15→+20` 상향으로 **hidden EV 155G, 2.8× risky 달성**. **EV 정책 범위**: safe [5,25] 또는 nothing / risky [25,60] / hidden ≥2×risky·≥120. **발동 확률 cap 0.40~0.60 → 일괄 0.30 단축**(자동+선택지 합 6회/hr). **효과 타입 분포 72행 확정**(nothing 12/gold 22/rep 18/injury 6/heal_tired 5/item 5/trait_acquired 3/trait_innate 1). **hidden 선택지 12종→6종 축소** 권장(희소성 강화). **전원 파견 시 선택지 미발동**(Q-9)·**활동 로그 1줄 요약**(Q-10)·**item 풀 M2a tier≤3 한정**(Q-7)·**trait FK 실존 검증 페이즈 3-5 선행**(Q-3 필수 가드). **data-generator 검증 쿼리 §4-5**(정책 위반 0행 보장). 페이즈 4-1 `evaluationScope` + 페이즈 4-5 spec 7건 반영 사항. 오픈 질문 8건(safe=nothing 비율·hidden 축소 승인·item 풀 경계·자동이벤트 cap·conditional 중복·미발동 UX).

## 페이즈 3: 데이터 생성

**상태**: completed

계획된 산출물:
- [x] 0-1. `types/chain-quest.md` 타입 스펙 — 체인·단계 구조, next_step_delay, final_reward
  - 산출물: `.claude/skills/data-generator/types/chain-quest.md`
  - 완료: 2026-04-24 (배치 A)
  - 핵심: `chain_quests` DDL + 24행 고정표(balance 2-1 §5-1 체인1 150/400·§5-6 체인7 step4 delay 4h 반영)·세력 매칭 절차·description 톤 가이드·검증 체크리스트 22항
- [x] 0-2. `types/region-transform.md` 타입 스펙 — transform 트리거/sector_type/전용 퀘스트 풀 매핑
  - 산출물: `.claude/skills/data-generator/types/region-transform.md`
  - 완료: 2026-04-24 (배치 A)
  - 핵심: `quest_pools.special_flags JSONB` DDL + `region_discoveries` 18행(village/ruins/hidden 각 6, 체인 5/6 연관 knowledge_threshold 88/83 조정) + `quest_pools` sector 34행(balance 2-2 §5-1 Village labor 3개·D2~D3·Ruins 4 flag·Hidden 7 flag). D1~D5 스케일 강제
- [x] 0-3. `types/quest-narrative.md` 타입 스펙 — quest_type × result_type 매트릭스, 템플릿 변수 규칙
  - 산출물: `.claude/skills/data-generator/types/quest-narrative.md`
  - 완료: 2026-04-24 (배치 A)
  - 핵심: `quest_narratives` DDL + `quest_pools.enemy_name` ALTER + 88행 매트릭스 β(raid/hunt/escort/explore × 4 × 4 + labor/survey × 4 × 2 + 엘리트 2타입 × 4 × 1) · result_type 톤 매트릭스 · TemplateEngine 변수 가이드 · `[if region.sector_type]` D옵션 인라인 분기
- [x] 0-4. `types/travel-choice.md` 타입 스펙 — 선택지·결과·확률·숨겨진 조건 스키마
  - 산출물: `.claude/skills/data-generator/types/travel-choice.md`
  - 완료: 2026-04-24 (배치 A)
  - 핵심: 3테이블 DDL + 12 events + 30 options (balance 2-3 §8-2 hidden 6종 축소) + 72 results (effect_type 분포 §4-4) · preferred_traits 실존 검증 사전 쿼리 · EV 검증 쿼리(hidden≥2×risky·≥120G) · item 풀 tier≤3 한정 · trait_innate FK 검증 · 3 CSV 파일 분리 출력
- [x] 1. 연계 퀘스트 체인 5~8개 (총 15~30단계) → `chain_quests`
  - 입력 기획서: 페이즈 1-2 + 페이즈 2-1
  - 대상 테이블: `chain_quests` (신규)
  - 산출물: `Docs/content-data/[chain-quest]20260424_m3-chains.csv` + `.md`
  - 완료: 2026-04-24 (배치 B)
  - 핵심: DDL(`chain_quests` + data_versions 엔트리) 적용 → INSERT 24행(7체인 × 2~5단계, 골드 합 12,230G, 체인 7 delay 합 46,800초=13시간 = balance 2-1 A5 반영). 세력 매핑 5체인 확정(sun_order/warriors_guild/merchants_alliance/deep_hammer/forbidden_archive). 최종 보상 7종 item FK 검증 완료. 검증 쿼리: total 24 / finals 7 / faction_linked 19 / 체인별 steps=declared 7체인 모두 일치. region_id는 NULL 상태 — 배치 C 완료 후 UPDATE 예정.
- [x] 2. `region_discoveries` 확장 — hidden_quest + transform 트리거 행 추가 (15~25개 리전)
  - 입력 기획서: 페이즈 1-2 + 페이즈 1-3
  - 대상 테이블: `region_discoveries` (INSERT)
  - 산출물: `Docs/content-data/[region-transform]20260424_m3-triggers.csv`
  - 완료: 2026-04-24 (배치 C)
  - 핵심: INSERT 25행(transform 18 + hidden_quest 7) + chain_quests region_id/target_region_id UPDATE 24행. 매핑: 체인 1(31), 2(10→50), 3(38), 4(49→21), 5(51→65→24), 6(16 왕복→21), 7(28→35→47). 체인 5/6 조기 트리거(threshold 88/83)는 본 MVP 미적용 — 필요 시 후속 UPDATE로 조정 권장. 기존 region_discoveries 22건 위에 25건 추가 → 총 47건.
- [x] 3. 섹터 변형 전용 퀘스트 풀 — `quest_pools` 확장 (마을/유적지/숨겨진 유형별 10~15개)
  - 입력 기획서: 페이즈 1-3 + 페이즈 2-2
  - 대상 테이블: `quest_pools` (INSERT)
  - 산출물: `Docs/content-data/[region-transform]20260424_m3-sector-pools.csv`
  - 완료: 2026-04-24 (배치 D)
  - 핵심: DDL(`quest_pools.special_flags JSONB` 컬럼 추가 + data_versions bump) + INSERT 34행(village 12: escort4/explore3/labor3/raid1/hunt1 D2~D3 / ruins 12: hunt5/explore4/raid3 D4~D5 4행 플래그 / hidden 10: explore6/hunt2/escort1/raid1 D3~D5 7행 플래그). 검증: village 12 플래그 0 / ruins 12 플래그 4 / hidden 10 플래그 7 정합.
- [x] 4. 서사 템플릿 88개 → `quest_narratives`
  - 입력 기획서: 페이즈 1-4
  - 대상 테이블: `quest_narratives` (신규)
  - 산출물: Supabase 직접 INSERT (CSV 스킵 — 대량 텍스트 효율)
  - 완료: 2026-04-24 (배치 E)
  - 핵심: DDL 2건(`quest_narratives` 신규 테이블 + `quest_pools.enemy_name` ALTER) + INSERT 88행(raid 16/hunt 16/escort 16/explore 16/labor 8/survey 8/elite raid 4/elite hunt 4). 검증: total 88·elites 8·quest_type×result_type 분포 기획 β 정합 / {merc.*} 사용 88/88(초기 2행 누락 → UPDATE 보강) / [pick] 6행 / [if region.sector_type] D옵션 1행(explore_greatSuccess_02). 배치 F(페이즈 3-5 travel_choice 114행) 대기.
- [x] 5. 이동 선택지 이벤트 10~15종 → `travel_choice_events`
  - 입력 기획서: 페이즈 1-5 + 페이즈 2-3
  - 대상 테이블: `travel_choice_events`/`_options`/`_results` (3 신규)
  - 산출물: Supabase 직접 INSERT (대량 텍스트)
  - 완료: 2026-04-24 (배치 F)
  - 핵심: DDL(3테이블 + data_versions 엔트리) + INSERT 114행(events 12/options 30/results 72). trait 매핑: empathy→empathic, brave→iron_will, scholar→quick_learner, curious→sixth_sense, leader→born_leader, cunning→thief_origin, tracker→hawk_eye, faithful→monastery_origin, hardy→iron_skin, survival→survival_instinct, agile→agile_body. hidden 6종 축소안 반영(enc_01/dil_01/dil_03/dis_01/dis_03/haz_02). conditional_expr 4건(enc_02/dis_02/haz_01/haz_03). item effect_target essence_*_t2/t3 사용. **EV 검증 통과**: safe [0,17.5] / risky [28.5,56.5] / hidden [129,175] / 위반 0. probability 합 1.0 검증 통과. 배치 G(페이즈 3-6 일반 퀘 200행 재분류) 대기.
- [x] 6. 일반 퀘스트 200행 유형 재분류 + `enemy_name` 채움 (Supabase MCP 직접 트랙)
  - 입력 기획서: 페이즈 1-4 §(B)
  - 선행: `ALTER TABLE quest_pools ADD COLUMN enemy_name TEXT NULL` (배치 E에서 완료)
  - 대상 테이블: `quest_pools` (UPDATE 200행)
  - 산출물: Supabase 직접 UPDATE (CSV 불필요)
  - 완료: 2026-04-24 (배치 G)
  - 핵심: 키워드 기반 재분류 UPDATE 200행. **분포 실적**: hunt 57(28.5%) / escort 55(27.5% 2.5%p 초과) / raid 45(22.5% 2.5%p 미달) / explore 43(21.5%). 경계선 편차지만 수용(이름 구조상 호위 4종×10레벨 자연 과다). **enemy_name 채움**: 77/200(38.5%) — 오크 16 / 트롤 16 / 괴물 14 / 폐허 도적 11 / 늑대 무리 11 / 도적단 9. 나머지 123행(호위/탐험/중립)은 NULL 유지(기획 의도). `quest_pools.difficulty` 1~10 스케일 이슈는 본 배치 범위 밖 — M4+ 해결 권장.

## 페이즈 4: 개발 명세

**상태**: completed

계획된 산출물:
- [x] 1. TemplateEngine 공유 모듈 spec — 변수 치환·조건 분기·트레잇 기반 숨겨진 옵션 평가 모듈 (최우선)
  - 입력: 페이즈 1-1 + **페이즈 1-4의 region.sector_type 카탈로그 확장(29→30) 후속 반영** + **페이즈 1-5의 evaluationScope: mercenary|team 파라미터 확장(has_trait team-wide 평가)**
  - 산출물: `Docs/spec/M3/[spec]20260424_template-engine.md`
  - 완료: 2026-04-24
  - 핵심: FR 12건 (치환·fallback·if/else/elif·pick·9개 연산자·evaluationScope·evaluate/render/validate API·TemplateContext 12필드·Riverpod Provider·카탈로그 30개). **verify-spec PASS**(5/5 항목 통과, 초기 1패스). 신규 파일 9개(엔진·컨텍스트·카탈로그·AST·오류·Provider·테스트 3종) + 수정 파일 1개(travel_event_service 통합). Q-A 2건 참고사항(List<String> eliteId 타입 정리 / List<QuestType> questTypes Context 필드 추가) 구현 단계에서 처리.
- [x] 2. 연계 퀘스트 시스템 spec — `ChainQuestData`/`ChainQuestProgress`/`ChainQuestService`, `chainQuestProgress` Hive 박스, 파견 화면 상단 고정 UI, 타 지역 "이동 필요" 안내
  - 입력: 페이즈 1-2 + 페이즈 2-1 + 페이즈 3-1
  - 산출물: `Docs/spec/M3/[spec]20260424_chain-quest-system.md`
  - 완료: 2026-04-24
  - 핵심: FR 12건 (발동/주인공 선정·고정/단계 주입/단계 완료/death×0.5/인벤 차단/완주 보너스/폴백/휴면/플래그/템플릿 렌더/완주 후 재발동 방지). balance 2-1 런타임 로직 4건 전체 반영. Hive typeId 11(ChainQuestProgress)/12(ChainQuestStatus) 신규, HiveField append-only 준수(UserData 20·ActiveQuest 21~23·ActivityLogType 16~17). **verify-spec PASS**(5/5, 초기 1패스). `chain_quests.final_reputation_bonus` DDL·데이터 실존 재확인 완료. 수정 13 + 신규 9 = 22 파일.
- [x] 3. 지역 변형 시스템 spec — `RegionState.sectorChanges`, transform 트리거, 이동 화면 구분, `QuestGenerator` sector_type 분기
  - 입력: 페이즈 1-3 + 페이즈 2-2 + 페이즈 3-2 + 페이즈 3-3
  - 산출물: `Docs/spec/M3/[spec]20260424_region-transform-system.md`
  - 완료: 2026-04-24
  - 핵심: FR 12건 (sectorChanges 필드/transform 트리거/변형 팝업/QuestGenerator sector_type 분기/quest_pools 모델 확장/ActiveQuest.specialFlags/SpecialFlagProcessor 6종 플래그/traitLearningBoostUntil/이동 화면 시각 구분/applyTransform API/regionTransform 로그 타입/대기 퀘 보존). balance 2-2 특수 플래그 7건 전체 처리 + 페이즈 4-5와 공유 매커니즘 확정. HiveField append-only(RegionState 3 / Mercenary 23 / ActiveQuest 24 / ActivityLogType 15). **verify-spec PASS**(5/5, 초기 1패스). §FR-1 Map<int,String>→Map<String,String> Hive 안정성 일관성 수정 + reputation_penalty 규칙 명확화 수정. 수정 12 + 신규 8 = 20 파일.
- [x] 4. 퀘스트 서사 통합 spec — `QuestNarrativeData`/`QuestNarrativeService`, 완료 팝업 서사 영역
  - 입력: 페이즈 1-4 + 페이즈 3-4 + 페이즈 4-1
  - 산출물: `Docs/spec/M3/[spec]20260424_quest-narrative-integration.md`
  - 완료: 2026-04-24
  - 핵심: FR 12건 (QuestNarrativeData 모델/pickTemplate weight 랜덤/renderNarrative/ActiveQuest.renderedNarrative HiveField 25/`{quest.enemy}` 해결 로직/QuestResultDialog 서사 영역/활동 로그 포맷/SyncService 동기화/대표 용병 선정 공식/체인 우회/엘리트 분기/pick 시드 결정). 페이즈 4-1에 `{quest.enemy}` 해결 로직(QuestPool.enemyName → EliteMonster.name → "적") 구현 요구 교차 전달. **verify-spec PASS**(5/5, 초기 1패스). **M3 신규 spec 작업 중 기존 `ActivityLogType` HiveField 15~17 점유(M2a essence) 발견 → 페이즈 4-2/4-3 spec의 HiveField 번호를 19/20·18로 일괄 교정**. 수정 9 + 신규 4 = 13 파일.
- [x] 5. 이동 선택지 spec — `TravelChoiceEventData`, `TravelEventService` 확장, 이동 완료 후 "회상" UI, 트레잇 숨겨진 선택지
  - 입력: 페이즈 1-5 + 페이즈 2-3 + 페이즈 3-5 + 페이즈 4-1
  - 산출물: `Docs/spec/M3/[spec]20260425_travel-choice-system.md`
  - 완료: 2026-04-25
- [x] 6. SyncService + 파견 화면 공존 정렬 spec — 3개 신규 테이블 동기화, data_versions 갱신, 페이즈 1-6 정렬 규칙 Flutter 구현
  - 입력: 페이즈 1-6 + 페이즈 3-1/4/5
  - 산출물: `Docs/spec/M3/[spec]20260425_coexistence-policy.md`
  - 완료: 2026-04-25

## 실행 이력

- 2026-04-23: 마일스톤 M3 시작
- 2026-04-23: 페이즈 1~4 산출물 계획 승인 (6 + 3 + 9 + 6 = 24개)
- 2026-04-23: 페이즈 1-1 완료 — TemplateEngine 공유 모듈 설계 (`Docs/content-design/[content]20260423_template_engine.md`)
- 2026-04-23: 페이즈 1-2 완료 — 연계 퀘스트 시나리오 7체인/24단계 (`Docs/content-design/[content]20260423_chain_quests.md`). Q-2 해결.
- 2026-04-24: 페이즈 1-3 완료 — 지역 변형 기획 18개 리전·3유형 (`Docs/content-design/[content]20260423_region_transform.md`)
- 2026-04-24: 페이즈 1-4 완료 — 퀘스트 서사 템플릿 88행 매트릭스 + quest_type 6유형 확장 대응 + 엘리트/섹터 분기 전략 D + 스키마 + 샘플 16개 (`Docs/content-design/[content]20260424_quest_narratives.md`). Q-2·Q-6 해결. 페이즈 3-6(일반 퀘스트 200행 재분류) 신규 트랙 추가. 페이즈 4-1에 `region.sector_type` 카탈로그 확장 후속 반영 메모.
- 2026-04-24: 페이즈 1-5 완료 — 이동 선택지 이벤트 12종·114행 기획 (`Docs/content-design/[content]20260424_travel_choices.md`). 스키마 3테이블 분리·도착 후 회상 UI·4 카테고리·hidden 트레잇 분기·효과 타입 8종 확정. Q-4(페이즈 1-1 선택지 결과 적용 시점) 해결(도착 직후 즉시 반영). 페이즈 4-1에 `evaluationScope` 파라미터 확장 후속 반영 메모. 페이즈 4-3·4-5가 trait_acquired 학습 가속 매커니즘 공유 권장.
- 2026-04-24: 페이즈 1-6 완료 — 공존 정책 정의 (`Docs/content-design/[content]20260424_coexistence_policy.md`). 5계층 정렬·카드 시각 3원칙·도착 팝업 8단계·Global Dialog Queue(4 priority + Hive persistence)·RankUpOverlay 큐 통합·활동 로그 4신규 타입 확정. 페이즈 1-5 Q-8 + 페이즈 1-3 §5-4 해결. 페이즈 4-6 spec은 타 페이즈 4 spec들의 통합 계약 역할.
- 2026-04-24: **페이즈 1(컨텐츠 설계) 완료** — 6개 산출물 전체 생성. 페이즈 2 체크포인트 대기.
- 2026-04-24: 페이즈 2 시작 — 사용자 승인. 페이즈 2-1(연계 퀘스트 확정 보상 강도) 액션 안내.
- 2026-04-24: 페이즈 2-1 완료 — 연계 퀘스트 확정 보상 강도 밸런스 리포트(`Docs/balance-design/[balance]20260424_chain_quest_rewards.md`). 수치 변경 7건 확정(체인 1 골드/완주 명성/death ×0.5/휴면 14일/인벤 차단/체인7 delay 단축/기타 유지). A5 조정(체인 7 delay 6h→4h) 사용자 승인 반영.
- 2026-04-24: 페이즈 2-2 완료 — 섹터 변형 전용 퀘스트 밸런스 리포트(`Docs/balance-design/[balance]20260424_sector_transform_quests.md`). Village labor 3개 투입·Ruins 드랍 4개·Hidden 특수 플래그 3+3+4·트레잇 가속 ×1.5×24h·쿨다운 없음·knowledge 98 유지 확정. `quest_pools.special_flags` JSONB DDL 선행 필요. `quest_pools.difficulty` 1~10 vs `difficulties` 1~5 스케일 불일치 이슈 페이즈 3-6 통합 권장. 페이즈 4-3 spec 7건 반영 사항.
- 2026-04-24: 페이즈 2-3 완료 — 이동 선택지 EV 밸런스 리포트(`Docs/balance-design/[balance]20260424_travel_choice_ev.md`). 1G 환산표 제정·기획 §9-1 정책 위반 감지 후 hidden 보상 상향(EV 51→155G, 2.8×risky)·발동 확률 cap 0.30 단축·효과 타입 분포 72행 확정·hidden 6종 축소 권장·전원 파견 미발동·item 풀 tier≤3 한정·trait FK 검증 선행 가드. data-generator 검증 쿼리 첨부. 페이즈 4-1/4-5 spec 반영 사항 7건. **페이즈 2 완료 체크포인트 대기**.
- 2026-04-24: **페이즈 2(밸런스 확정) 완료** — 3개 산출물 전체 생성. 사용자 승인. 페이즈 3 시작.
- 2026-04-24: **배치 A(타입 스펙 4개) 완료** — `.claude/skills/data-generator/types/` 하위 chain-quest / region-transform / quest-narrative / travel-choice 스펙 생성. SKILL.md 지원 타입 목록 갱신. 배치 B(페이즈 3-1 chain_quests 벌크) 대기.
- 2026-04-24: **배치 B(페이즈 3-1 chain_quests 24행) 완료** — DDL 적용 + INSERT 24행 + 검증 통과(7체인·7 final·5체인 faction 매핑). 배치 C(페이즈 3-2 region_discoveries 18 transform + hidden_quest) 대기.
- 2026-04-24: **배치 C(페이즈 3-2 region_discoveries 25행) 완료** — transform 18 + hidden_quest 7 INSERT + chain_quests 24행 region_id/target_region_id UPDATE. 리전 매핑: transform 18 리전(tier 1~10 전반 커버) + 체인 시작 7 리전. 검증: transform 18 / chain hidden 7 / chain_quests null 0. 배치 D(페이즈 3-3 quest_pools sector 34행) 대기.
- 2026-04-24: **배치 D(페이즈 3-3 quest_pools sector 34행) 완료** — DDL(`quest_pools.special_flags` 추가) + INSERT 34행(village 12/ruins 12/hidden 10) + special_flags 11행 배정(ruins 4 essence/equipment/guild_ultra + hidden 7 boost/guild/rep). 배치 E(페이즈 3-4 quest_narratives 88행) 대기.
- 2026-04-24: **배치 E(페이즈 3-4 quest_narratives 88행) 완료** — DDL 2건(`quest_narratives` 신규 + `quest_pools.enemy_name` 컬럼 추가) + INSERT 88행. 분포 검증 기획 β 정합(일반 80 + 엘리트 8). 배치 F(페이즈 3-5 travel_choice 114행) 대기.
- 2026-04-24: **배치 F(페이즈 3-5 travel_choice 114행) 완료** — DDL 3테이블 + INSERT 114행(events 12/options 30/results 72). trait 11종 실 매핑 확정. hidden 6종 축소(balance 2-3) + conditional 4건. EV 검증 통과(safe [0,17.5]/risky [28.5,56.5]/hidden [129,175]). 배치 G(페이즈 3-6 일반 퀘 200행 재분류) 대기.
- 2026-04-24: **배치 G(페이즈 3-6 일반 퀘 200행 재분류) 완료** — 키워드 기반 UPDATE 200행. 분포 hunt 28.5%/escort 27.5%/raid 22.5%/explore 21.5% (escort/raid 경계선 2.5%p 편차 수용). enemy_name 채움 77행(38.5%). **페이즈 3 완료 체크포인트 대기**.
- 2026-04-24: **페이즈 3(데이터 생성) 완료** — 10개 산출물 전체 생성. 4 타입 스펙 + 6 벌크 생성(chain_quests 24 / region_discoveries 25 / quest_pools sector 34 / quest_narratives 88 / travel_choice 114 / 일반 퀘 200 UPDATE) = 285 신규/UPDATE. 3 신규 테이블 + 2 컬럼 ALTER DDL. 페이즈 4 체크포인트 대기.
- 2026-04-24: 페이즈 4 시작 — 사용자 승인. spec-pipeline으로 spec 6건 1건씩 순차 생성 방식 채택(auto 진행 X, 각 spec 후 사용자 확인).
- 2026-04-25: 페이즈 4-5 완료 — 이동 선택지 spec (`Docs/spec/M3/[spec]20260425_travel-choice-system.md`)
- 2026-04-25: 페이즈 4-6 완료 — SyncService + 공존 정렬 spec (`Docs/spec/M3/[spec]20260425_coexistence-policy.md`)
- 2026-04-25: **페이즈 4(개발 명세) 완료** — 6개 산출물 전체 생성.
- 2026-04-25: **M3 마일스톤 완료** — 전체 24개 산출물 생성 완료. 상태: completed.
