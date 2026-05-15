# M6 실행 상태

> 시작: 2026-05-05T11:40:25Z
> 마지막 업데이트: 2026-05-13 (페이즈 4 #1 명세·구현·커밋 완료, 페이즈 4 #2 진입 대기)
> 현재 페이즈: 4
> 상태: in_progress

## 로드맵 요구사항 요약

- **테마**: "이름을 얻는 용병단" — 강한 용병과 성장한 용병단이 세계에서 다르게 취급받는 체감을 만든다.
- **5개 시스템**: 위업 기록 / 용병 칭호 / 간판 용병 / 지명 의뢰 / 용병단 연대기
- **종료 조건**: 신규 유저가 3~5시간 안에 최소 1명의 용병 이름·칭호를 기억하고, 시작 거점 사건 해결 용병의 지명 의뢰가 1회 이상 등장한다. 사망/방출 용병의 기록도 연대기에 유지된다.
- **규모**: 중 (Supabase 1~2개 신규 테이블, Hive mercenaries 칭호 필드 확장 + chronicle 신규 박스 typeId 16+, Flutter 서비스 2~3개)
- **선행 의존성**: M1 명성 시스템 / M3 체인 퀘스트 / M4 거점 신뢰도 / M5 제작 시스템 — 위업·칭호 발행 hook이 모두 이전 마일스톤 시스템 위에 쌓인다.

## 핵심 설계 의문 (페이즈 1·2에서 해소)

1. 위업과 ActivityLog의 관계 (휘발성 100개 vs 영구)
2. 위업과 다이얼로그 큐 우선도 (rankUp/chain 사이 어디)
3. 칭호 발급 조건과 트레잇 23개 행동 지표 hook 공유 여부
4. 간판 용병 자동 선정 알고리즘 (가중합 정의)
5. 칭호 효과 강도 (트레잇·시너지 대비)
6. 지명 의뢰 노출 빈도·쿨다운 정책
7. 사망/방출 용병의 칭호·연대기 처리

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 위업·연대기 시스템 설계 (`achievement_chronicle_system`)
  - 참고 문서: `Docs/content-design/[content]20260423_chain_quests.md`, `[content]20260503_settlement-trust-and-fixed-events.md`, ActivityLog 시스템(`band_of_mercenaries/lib/core/domain/`)
  - 산출물: `Docs/content-design/[content]20260512_achievement-chronicle-system.md`
  - 완료: 2026-05-12
  - 핵심 결정: 3개념 분리(위업=영구 신규 Hive 박스 / 연대기=뷰 / ActivityLog 100개 휘발성 유지 + 미러 1행) / 트리거 6 카테고리(체인 7 + 거점사건 1+ + 거점소속 1+ + 명성 5 + 엘리트 유니크 8 + 희귀 제작 2~3 = M5 시점 24~25개) / 다이얼로그 큐 단일 high + 명성은 RankUpDialog 본체 1줄 인라인 통합 / mercSnapshot {id, name, jobId, jobName, tier} 50~80B / Hive typeId 16(BandAchievement) + 17(enum) + 18(MercenarySnapshot) / Supabase `band_achievement_templates` 신규(27→28 테이블) / ActivityLogType HiveField 29 `achievementUnlocked` 추가 / type 필드(achievement/memorial)로 사망/방출 영구 보존 + enqueue 생략 / UI 홈 야영지 이미지 아래 "연대기" 카드(최근 1) + 정보 탭 신규 "용병단 연대기" 카드 / DialogTypeRegistry 9→10종(`achievementUnlocked` 추가) / data-generator `band-achievement-template` 신규 타입 24~25행 + 변주 1~3개
- [x] 2. 칭호·간판 용병 설계 (`title_and_flagship`)
  - 참고 문서: roadmap M6 칭호 예시 4개, 트레잇 데이터(`Docs/content-design/20260412_trait_system_design.md`), 거점 신뢰도(`[content]20260503_settlement-trust-and-fixed-events.md`), #1 산출물 6 위업 카테고리
  - 의존: 1
  - 산출물: `Docs/content-design/[content]20260512_titles-and-flagship.md`
  - 완료: 2026-05-12
  - 핵심 결정: 저장 위치(Mercenary.titleIds HiveField 24 + recruitedAt 25 + UserData.flagshipMercId 24 + MercenarySnapshot.titleIds HiveField 5) / Supabase `titles` 신규 28→29번째 테이블 / 발급 hook 3종(a 위업/b 행동지표/c 상태) — (a)는 #1 AchievementUnlockedDialog 본체 1줄 인라인 통합, (b)·(c)는 신규 TitleUnlockedDialog(high) / DialogTypeRegistry 10→11종 / 초반 칭호 11종(roadmap 예시 4 + 추가 7 — 마을의 은인/폐광의 생존자/첫 깃발을 든 자/도적길 추적자/백전노장/정찰의 눈/호위의 노련함/더스트빌의 친우/괴물 사냥꾼/이름을 알린 자/혼을 끊은 자) / 효과 = PassiveEffect 17종 sealed 재사용 0종 추가, 2~5% 광역 + 좁은 hook 조합 / 자동 선정 5단계 정렬(칭호 수 → 위업 주인공 → 레벨 → partyPower → recruitedAt 빠른) / 수동 override 가능 + 사망/방출 시 자동 리셋 + 알고리즘 재적용 / MercenarySnapshot.titleIds 동결로 사망 후 보존 / ActivityLogType HiveField 30 `titleUnlocked` 추가 / TitleService + FlagshipMercenaryService 신규 서비스 / PassiveBonusService `_collectFromTitles` 1줄 통합 / data-generator `title` 신규 타입 11행
- [x] 3. 지명 의뢰 설계 (`named_quest_design`)
  - 참고 문서: 페이즈 1 #1·#2, QuestGenerator(`band_of_mercenaries/lib/features/quest/domain/quest_generator.dart`), QuestSortService, M4 fixed_quests 패턴
  - 의존: 1, 2
  - 산출물: `Docs/content-design/[content]20260512_named-quests.md`
  - 완료: 2026-05-13 (사용자 무중단 진행 모드 — 7개 결정 모두 Recommended 채택)
  - 핵심 결정: 데이터 모델 = quest_pools 4 컬럼 확장(M4 fixed_quests 패턴 재사용: `is_named`/`named_hook_type`/`named_hook_value`/`named_cooldown_hours`) — 신규 테이블 0 / hook 3종 단일 조건(a title 3개 / b achievement_count 2개 / c flagship 2개) M6 MVP / 노출 정책 = 일반 갱신 풀에 섞여 매칭 시 가중치 +α=3 + 24h 쿨다운 / 정렬 위치 = 신규 NamedTier(settlementTier 다음, Tier 1 위) QuestSortService 6→7 슬롯 / 의뢰 7개(마을의 은인/도적길 추적자/괴물 사냥꾼/이름 있는 용병단/전설을 들은 의뢰인/깃대를 보고 온 편지/깃대의 전설) / 보상 보너스 골드 +30~50% + 명성 +30~50%(칭호 효과는 PassiveBonusService 자동 가산) / isDispatched 잠금 + "지명 용병 복귀 대기" 표시 / 간판 변경 시 진행 의뢰 유지(ActiveQuest.namedTargetMercId HiveField 26 동결) 사망/방출 시 자동 종료 / UserData.namedQuestCooldowns HiveField 25 신설(#2의 flagshipMercId HiveField 24 다음) / ActiveQuest.namedTargetMercId HiveField 26 신설(ActiveQuest 다음 27) / 페이즈 3 스킵 권장(7행 페이즈 4 #3 인라인 처리)

## 페이즈 2: 밸런스 확정

**상태**: completed

계획된 산출물:
- [x] 1. 칭호 효과 수치 밸런스 (`title_effect_values`)
  - 입력: 페이즈 1 #2
  - 참고 문서: `Docs/balance-design/20260417_dispatch_synergy_values.md`, `20260417_faction_passive_values.md`, Supabase factions/traits/quest_types 실데이터
  - 산출물: `Docs/balance-design/[balance]20260513_title-effect-values.md`
  - 완료: 2026-05-13
  - 핵심 결정: effect_json 11종 중 2종만 미세 하향(#1 광역 questSuccessRateBonus 0.03→0.025, #8 광역 questRewardMultiplier 0.03→0.02) 나머지 9종 그대로 / 행동 지표 hook 임계 4종 모두 하향(raid 30→20, dispatch 100→80, explore 20→15, escort 15→12) — 5~10h 자연 도달 / 풀스택 시너지 검증 ✓ (PassiveBonusService 곱셈 클램프 0.10 통과·가산 상한 정합) / 칭호 단독 빌드 +8%p vs 트레잇 풀스택 +14%p — "필수 최적해" 위험 없음 / #11 혼을 끊은 자 복합(rep+0.05 + XP+0.10) 엔드 격 그대로 채택 / Supabase 실데이터(세력 14·트레잇 109) 강도 비교 = 칭호는 세력 1/4~동급 / 풀스택 raid 의뢰 성공률 시뮬레이션 66.5% / 부상 회복 풀스택 클램프 0.10 정상 동작 / 트레잇 effect_json(정수%) vs 칭호 effect_json(double) 시스템 분리 확인 / 4개 오픈 질문 페이즈 4 #2 위임(questRewardMultiplier·mercenaryXpBonus 상한 명시 권장)
- [x] 2. 노출 빈도·획득 페이스 밸런스 (`exposure_pacing`)
  - 입력: 페이즈 1 #1·#3 + 페이즈 2 #1
  - 참고 문서: `Docs/balance-design/[balance]20260424_chain_quest_rewards.md`, `[balance]20260503_settlement-trust-tuning.md`, Supabase quest_pools/difficulties 실데이터, GameConstants.baseQuestCount
  - 산출물: `Docs/balance-design/[balance]20260513_exposure-pacing.md`
  - 완료: 2026-05-13
  - 핵심 결정: 시간당 평균 8 파견 가정 검증 ✓(GameConstants.baseQuestCount 6 + 의뢰 평균 20min) / 3종 페이스 모드 도입(보수 4/h, 평균 8/h, 적극 12/h) / 통합 페이스 표 — 평균 페이스 3h 시점 위업 4 / 칭호 2~3 / 지명 의뢰 2~3, 5h 시점 위업 5~6 / 칭호 3~4 / 지명 의뢰 3~6 → **roadmap 종료 조건 모든 페이스 모드 충족 ✓** / 지명 의뢰 α=3 정량 검증(매 갱신 64.2% 등장, 시간당 0.9회, 1.1h마다 1회 자연) / 24h 쿨다운 회전 검증(7개 풀 자연 분산, 25h에 첫 재등장) / 무게감 보존(시간당 발급 1~3개, dialog 큐 우선도로 폭주 방지) / **페이즈 3 스킵 권장** — 칭호 11 + 지명 의뢰 7 = 18행 페이즈 4 SQL 인라인 / 페이즈 4 모니터링 지표 6종 명시(첫 위업 시점·3h 칭호·5h 위업·적극 5h 위업·시간당 지명 등장·24h 다양성) / 일반 의뢰 풀 203행 + faction 98 + fixed 6 + transform 56 + named 7 실측 / 5개 오픈 질문 페이즈 4 위임

## 페이즈 3: 데이터 생성

**상태**: skipped (2026-05-13 페이즈 2 종료 체크포인트 시점에 사용자 `skip` 결정)

스킵 사유 (페이즈 2 #2 §스킵 검토 권장 + 사용자 채택):
- 칭호 11행 + 지명 의뢰 7행 = 18행 → 페이즈 4 SQL 인라인 처리 가능 (M5 동일 패턴)
- 연대기 문구 30~50개는 페이즈 4 #1 명세 작성 시 부분 자동화 검토
- 신규 타입 스펙 3종(title/named_quest/chronicle_template) 작성 부담이 자동화 가치 능가

원래 계획된 산출물 (참고 — 모두 미진행):
- ~~1. `types/title.md` 타입 스펙 + 칭호 11개 데이터~~
- ~~2. `types/named_quest.md` 타입 스펙 + 지명 의뢰 7개 데이터~~
- ~~3. `types/chronicle_template.md` 타입 스펙 + 연대기 문구 30~50개~~

인라인 처리 후보 (페이즈 4 명세 내):
- 칭호 11행 → 페이즈 4 #2 명세 내 SQL INSERT
- 지명 의뢰 7행 (quest_pools 4 컬럼 확장 패턴) → 페이즈 4 #3 명세 내 SQL UPDATE/INSERT
- 위업 템플릿 24~25행 + chronicle_variants 30~50개 → 페이즈 4 #1 명세 내 SQL INSERT 또는 data-generator 부분 호출 검토

## 페이즈 4: 개발 명세

**상태**: in_progress

계획된 산출물:
- [x] 1. 위업·연대기 시스템 명세 (`achievement_chronicle_spec`)
  - 입력: 페이즈 1 #1 + 페이즈 2 #2
  - 핵심: BandAchievement 모델 + chronicle 신규 Hive 박스(typeId 16+) + AchievementService 5 hook + 홈 카드 + 다이얼로그 큐 통합 + 사망 보존
  - 산출물: `Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle.md` (54.9KB)
  - 완료: 2026-05-13 (spec-writer 산출 + verify-spec PASS + implement-agent 15 TASK 순차 격리 모드 구현 완료 + finalize-feature commit `3f14c34`)
  - 핵심 결정: AchievementService 4 메서드(grant/recordMemorial/hasAchievement/getAll) 콜백 DI / 6 hook fail-soft trailing(체인·거점신뢰도·명성·엘리트유니크·T3+제작·사망/방출) / Hive 박스 11번째 `bandAchievements` typeId 16~19(BandAchievement·BandAchievementType·MercenarySnapshot·MemorialCause) / Supabase 30번째 테이블 `band_achievement_templates` 26행 시드(placeholder 7개 elite is_unique=true 후속 UPDATE 위임 + craft_first_rare 2행 T3+ 레시피 미존재로 제외) / AchievementUnlockedDialog high priority + reputation_rank 카테고리는 RankUpDialog 본체 인라인 / ChronicleScreen 상태 기반 렌더링(`_showChronicle`+`onBack`) HomeScreen·InfoScreen 양쪽 진입 / MercenarySnapshot 5필드 영속 보존(페이즈 4 #2 titleIds HiveField 5 호환) / 순환 참조 회피로 `achievement_service_provider.dart` 분리·re-export / TravelEventService `diedEvent` hook 미구현(사망 분기 부재, MemorialCause enum만 정의) / 구현 계획서: `Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle_plan.md`
- [ ] 2. 칭호·간판 용병 시스템 명세 (`title_flagship_spec`)
  - 입력: 페이즈 1 #2 + 페이즈 2 #1
  - 핵심: Mercenary.titleIds + flagshipFlag + Supabase titles 테이블 + TitleService + FlagshipMercenaryService + 용병 상세/홈 UI
  - 산출물: (미생성)
- [ ] 3. 지명 의뢰 시스템 명세 (`named_quest_spec`)
  - 입력: 페이즈 1 #2·#3 + 페이즈 2 #2 + 페이즈 4 #2 (Mercenary.titleIds 의존)
  - 핵심: Supabase named_quests 테이블 + NamedQuestService + QuestGenerator 통합 + 의뢰 카드 차별화 UI
  - 산출물: (미생성)

## 실행 이력

- 2026-05-05T11:40:25Z: 마일스톤 시작 (Opus 4.7 기반 재계획)
- 2026-05-05T11:40:25Z: 페이즈 1·2·3·4 산출물 계획 승인 (총 11개 산출물 + 페이즈 3 선택적)
- 2026-05-12: `--resume` 호출. 직전 약 7일 갭. `Docs/content-design/` 스캔 결과 신규 산출물 0건, 계획 그대로 페이즈 1 #1부터 재개
- 2026-05-12: 페이즈 1 #1 "위업·연대기 시스템 설계" 완료 (`[content]20260512_achievement-chronicle-system.md`, 42.8KB) — 3개념 분리 / 6 카테고리 / 단일 high 큐 + 명성 인라인 / mercSnapshot 50~80B / Hive typeId 16·17·18 / Supabase 28번째 테이블 / type 필드로 memorial 영구 보존 / 홈 카드 + 정보 탭 진입점 / 4개 핵심 의문 모두 해소(휘발 vs 영구 / 큐 우선도 / 사망 보존 / 데이터 모델)
- 2026-05-12: `--resume` 재호출. 페이즈 1 #1 매칭·체크 완료 → #2 "칭호·간판 용병 설계" 진입 대기
- 2026-05-12: 페이즈 1 #2 "칭호·간판 용병 설계" 완료 (`[content]20260512_titles-and-flagship.md`, 43.0KB) — 11종 칭호 / 3종 hook / Mercenary HiveField 24·25 + UserData 24 + MercenarySnapshot 5 / Supabase titles 29번째 / DialogTypeRegistry 10→11종 / ActivityLogType 30 / PassiveEffect 재사용 0 추가 / 자동 선정 5단계 정렬 / 수동 override / 사망 후 titleIds 동결 보존 / TitleService + FlagshipMercenaryService 신규 / 핵심 의문 4개(3·4·5·7) 모두 해소
- 2026-05-12: `--resume` 재호출. 페이즈 1 #2 매칭·체크 완료 → #3 "지명 의뢰 설계" 진입 대기
- 2026-05-13: 페이즈 1 #3 "지명 의뢰 설계" 완료 (`[content]20260512_named-quests.md`, 32.6KB) — 사용자 "질문 없이 진행" 모드, 7개 결정 모두 Recommended 채택 / quest_pools 4 컬럼 확장(M4 패턴) / hook 3종 단일 조건 / 의뢰 7개 / NamedTier 신규 정렬 / 가중치 α=3 + 쿨다운 24h / UserData HiveField 25 + ActiveQuest HiveField 26 / **페이즈 1 전체 완료**
- 2026-05-13: `--resume` 재호출. 페이즈 1 #3 매칭·체크 완료, 페이즈 1 상태 in_progress → completed. 종료 체크포인트 대기
- 2026-05-13: 페이즈 1 종료 체크포인트 사용자 승인 (y) → 페이즈 2 진입. 페이즈 2 #1 "칭호 효과 수치 밸런스" 진행 대기
- 2026-05-13: 페이즈 2 #1 "칭호 효과 수치 밸런스" 완료 (`[balance]20260513_title-effect-values.md`, 28.3KB) — Supabase 실데이터 6쿼리 / 풀스택 시너지 검증 ✓ / effect_json 11종 중 2종 미세 하향 / 행동 지표 임계 4종 모두 하향 / "필수 최적해" 위험 없음 정량 확인 / 4개 오픈 질문 페이즈 4 #2 위임
- 2026-05-13: `--resume` 재호출. 페이즈 2 #1 매칭·체크 완료 → #2 "노출 빈도·획득 페이스 밸런스" 진입 대기
- 2026-05-13: 페이즈 2 #2 "노출 빈도·획득 페이스 밸런스" 완료 (`[balance]20260513_exposure-pacing.md`, 28.4KB) — 시간당 8 파견 가정 ✓ / 3종 페이스 모드(보수/평균/적극) / 통합 페이스 표 확정 / α=3 정량 검증(매 갱신 64% 등장) / 24h 쿨다운 회전 ✓ / 무게감 보존 ✓ / 페이즈 3 스킵 권장 / 페이즈 4 모니터링 지표 6종 / 5개 오픈 질문 / **페이즈 2 전체 완료**
- 2026-05-13: `--resume` 재호출. 페이즈 2 #2 매칭·체크 완료, 페이즈 2 상태 in_progress → completed. 종료 체크포인트 대기
- 2026-05-13: 페이즈 2 종료 체크포인트 사용자 `skip` 결정 → 페이즈 3 skipped + 페이즈 4 진입. 페이즈 4 #1 "위업·연대기 시스템 명세" 진행 대기
- 2026-05-13: 페이즈 4 #1 "위업·연대기 시스템 명세" 완료 (`[spec]20260513_M6_phase4_1_achievement-chronicle.md`, 54.9KB) — spec-writer + verify-spec PASS / implement-agent 15 TASK 순차 격리 모드(planner → coder×15 + verifier×15 + flutter-reviewer×15 → 빌드 게이트 → final integration sanity check) / 28개 파일 변경 + dart-build-resolver 1회(테스트 fixture 4건) + TASK-4 5건 medium 정리 + TASK-14 BLOCK 1건 재작업(Navigator.push → 상태 기반 렌더링) / finalize-feature commit `3f14c34` + CLAUDE.md 갱신(typeId 16~19 + 박스 11 + 테이블 28) + Archive 4 사본 + CHANGELOG fragment + plan 문서
- 2026-05-13: `--resume` 재호출. 페이즈 4 #1 매칭·체크 완료 → #2 "칭호·간판 용병 시스템 명세" 진입 대기
