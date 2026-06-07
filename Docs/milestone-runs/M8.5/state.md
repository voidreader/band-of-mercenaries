# M8.5 실행 상태

> 시작: 2026-05-20T19:05:00+09:00
> 마지막 업데이트: 2026-06-07T00:00:00+09:00
> 현재 페이즈: 4
> 상태: in_progress

## 로드맵 요구사항 요약

M8.5 "재미 가시화와 폴리싱"은 M4~M8b에서 만든 기능을 플레이어가 재미로 인식하도록 가시화한다. 생활권, 세력, 전투, 제작, 위업, 간판 용병을 개별 화면에 흩어진 기능으로 두지 않고, "지금 무엇을 완성하고 있는가"와 "내 용병들이 어떤 이야기를 만들었는가"를 한눈에 보이게 한다.

핵심 6 시스템: 생활권 완성도 대시보드 · 간판 용병 솔로/소수정예 루프 · 전투 감정 반응 · 히든 스탯 해금 · UI 폴리싱 1차 + 이미지 에셋 · 주간 더스트플레인 생활권 기여도 랭킹 MVP.

선행 의존성: M8b 완료(2026-05-20). `CombatSimulator` 턴 전투 시뮬레이터, `CombatReport` schemaVersion=1, 라운드 로그·decisive 장면 시스템, `combat_skills` 16행 · `combat_status_effects` 10행 · `enemies` 26행 · `combat_report_templates` 181행 + 검증 명세 기반.

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 생활권 완성도 대시보드 컨셉
  - 참고 문서: `Docs/Archive/20260518_m7_*` (M7 거점화), `band_of_mercenaries/lib/features/achievement/view/chronicle_screen.dart`, `band_of_mercenaries/lib/features/info/view/faction_codex_screen.dart`, `band_of_mercenaries/lib/features/settlement/view/village_visit_section.dart`
  - 권장 내용: 지표 항목 (안정도·사건 완료율·특산품 수집률·제작 목표·세력 영향력) 정의, "다음 30분 목표"와 "다음 8시간 목표" 노출 규칙, 정보 위계, 진입 동선
  - 산출물: `Docs/content-design/[content]20260520_m8.5_livingsphere_dashboard.md`
  - 완료: 2026-05-21T09:45:00+09:00
- [x] 2. 간판 용병 솔로/소수정예 의뢰 컨셉
  - 참고 문서: M6 페이즈 4 #3 지명 의뢰 (`Docs/Archive/20260518_m6_*`), M6 페이즈 4 #2 칭호 시스템, M8b CombatSimulator (`Docs/spec/[spec]20260519_m8b_combat_simulator.md`)
  - 권장 내용: 1인 의뢰 vs 2~3인 의뢰 조건, 전용 칭호·개인 숙련도·장비 목표 컨셉, 위험도 차별화 정책, 발급 빈도
  - 산출물: `Docs/content-design/[content]20260521_m8.5_flagship_solo_quests.md`
  - 완료: 2026-05-21T12:05:00+09:00
- [x] 3. 전투 감정 반응 컨셉
  - 참고 문서: 페이즈 1 #2, M8b `CombatSimulator` 상태 효과 (`Docs/balance-design/[balance]20260519_m8b_status_effect_values.md`), M8a 전투 보고서 (`Docs/Archive/20260519_m8a_faction_combat_report/`)
  - 권장 내용: 분노·절망·슬픔·투지 4 감정 상태의 발생 조건 (동료 사망·중상·간판 위기·전멸 직전), 보고서 노출 정책, 전투 효과 컨셉
  - 산출물: `Docs/content-design/[content]20260521_m8.5_combat_emotional_reactions.md`
  - 완료: 2026-05-21T13:53:00+09:00
- [x] 4. 히든 스탯 해금 컨셉
  - 참고 문서: 페이즈 1 #3, M8b CombatSimulator, M6 트레잇 시스템 (`band_of_mercenaries/lib/features/mercenary/domain/trait_*`)
  - 권장 내용: 불굴·투지·운·공포 저항·전장 감각 5 히든 스탯 정의, 해금 트리거 (전투 사건 종류), 표시 정책, 트레잇과의 차이점
  - 산출물: `Docs/content-design/[content]20260521_m8.5_hidden_stats.md`
  - 완료: 2026-05-21T14:58:00+09:00
- [x] 5. 용병 전투 기억 컨셉
  - 참고 문서: 페이즈 1 #3·#4, M8a 전투 보고서, M6 위업/칭호 (`band_of_mercenaries/lib/features/achievement/`, `band_of_mercenaries/lib/features/title/`)
  - 권장 내용: 전투 기억 기록 구조, 표시 정책 (용병 상세 화면), 위업/칭호와의 관계, 보존 정책
  - 산출물: `Docs/content-design/[content]20260521_m8.5_battle_memory.md`
  - 완료: 2026-05-21T16:11:00+09:00
- [x] 6. 주간 기여도 랭킹 컨셉
  - 참고 문서: 게임 전반, M7 거점화 시스템, M4 세력 영향력
  - 권장 내용: 점수 항목 정의 (지역 안정화·세력 의뢰·전투 활약·제작·위업), 주간 사이클 정책, PvP 손실 없는 경쟁 UX, 노출 위치
  - 산출물: `Docs/content-design/[content]20260521_m8.5_weekly_contribution_ranking.md`
  - 완료: 2026-05-21T18:03:00+09:00

## 페이즈 2: 밸런스 확정

**상태**: completed

계획된 산출물:
- [x] 1. 생활권 완성도 지표 수치화
  - 입력 의존: 페이즈 1 #1
  - 권장 내용: 안정도(`dangerScore` 변환)·사건 완료율(체인·고정의뢰)·특산품 수집률(M5 재료)·제작 목표·세력 영향력 가중치, 0~100% 변환 산식
  - 산출물: `Docs/balance-design/[balance]20260521_m8.5_livingsphere_metrics.md`
  - 완료: 2026-05-21T18:23:00+09:00
- [x] 2. 간판 용병 의뢰 보상·난이도 수치
  - 입력 의존: 페이즈 1 #2
  - 권장 내용: 1인/2~3인 의뢰별 성공률 보정, 보상 배수, 위험도(사망 저항 보정), 발급 빈도 cap
  - 산출물: `Docs/balance-design/[balance]20260521_m8.5_flagship_solo_quest_balance.md`
  - 완료: 2026-05-21T18:56:00+09:00
- [x] 3. 감정 반응 상태 발동 확률·지속·수치
  - 입력 의존: 페이즈 1 #3 + 페이즈 1 #5
  - 권장 내용: 분노·절망·슬픔·투지 발동 확률, 지속 턴, intensity, M8b 상태 효과 시스템 연계
  - 산출물: `Docs/balance-design/[balance]20260521_m8.5_emotional_reaction_values.md`
  - 완료: 2026-05-22T10:52:00+09:00
- [x] 4. 히든 스탯 효과 수치 및 해금 임계값
  - 입력 의존: 페이즈 1 #4
  - 권장 내용: 5 히든 스탯 효과 산식 (전투 hook 적용 방식), 해금 사건 누적 임계값, M8b 산식과의 결합 방식
  - 산출물: `Docs/balance-design/[balance]20260522_m8.5_hidden_stat_values.md`
  - 완료: 2026-05-22T11:36:00+09:00
- [x] 5. 주간 기여도 점수 산식 수치
  - 입력 의존: 페이즈 1 #6
  - 권장 내용: 점수 항목별 가중치, 표준화 방식, 주간 사이클 timing, 랭킹 표시 cap
  - 산출물: `Docs/balance-design/[balance]20260522_m8.5_weekly_contribution_values.md`
  - 완료: 2026-05-22T11:58:00+09:00

## 페이즈 3: 데이터 생성

**상태**: completed (#5 진행 / #1·#2·#3·#4 페이즈 4 위임)

> 사용자 결정 (2026-05-22T12:35+09:00): 페이즈 3에서 **#5 주간 기여도 메타데이터**만 진행. #1 이미지 에셋은 실제 이미지 파일이 없는 상태에서 메타데이터만 작성하는 가치가 낮아 페이즈 4 #5 UI 스펙에 통합 위임. 나머지 #2·#3·#4는 데이터 분량이 적어 페이즈 4 spec 인라인 위임.

계획된 산출물:
- [~] 1. 이미지 에셋 메타데이터 — **페이즈 4 #5 UI 스펙 통합 위임**
  - 입력 의존: 페이즈 1 #1 + 페이즈 1 전체 (시스템별 이미지 슬롯 위치)
  - 대상 테이블: 신규 `image_assets` (또는 기존 테이블 확장)
  - 위임 사유: 이미지 파일 자체는 별도 디자인 작업이며 placeholder URL만으로 작성하는 가치가 낮음. 페이즈 4 #5 "UI 폴리싱 1차 + 이미지 에셋 적용 명세"에서 image_assets CREATE + 7행 INSERT + Image 위젯 + placeholder URL 관리 정책 통합. M9 디자인 작업 완료 시 URL 갱신.
- [~] 2. 감정 반응 상태 효과 시드 4행 추가 — **페이즈 4 #3 spec 인라인 위임**
  - 입력 의존: 페이즈 1 #3 + 페이즈 2 #3
  - 대상 테이블: M8b `combat_status_effects` ALTER + INSERT 4행 (분노·절망·슬픔·투지) + 신규 `battle_memory_templates` 30행
  - 위임 사유: 상태 효과 4행 + 전투 보고서/전투 기억 템플릿을 페이즈 4 #3에서 함께 인라인 처리 가능
- [~] 3. 히든 스탯 정의 시드 5행 — **페이즈 4 #3 spec 인라인 위임**
  - 입력 의존: 페이즈 1 #4 + 페이즈 2 #4
  - 대상 테이블: 신규 `hidden_stats` 테이블 CREATE + 5행 INSERT
  - 위임 사유: 페이즈 4 #3에서 감정 반응 hook과 함께 통합 spec 작성
- [~] 4. 간판 용병 솔로/소수정예 의뢰 풀 시드 — **페이즈 4 #2 spec 인라인 위임**
  - 입력 의존: 페이즈 1 #2 + 페이즈 2 #2
  - 대상 테이블: 기존 `quest_pools` 신규 컬럼(party_size_min/max) + 5행 + `titles` 4행 + `items` 2행
  - 위임 사유: 11행 인라인 가능 (소량)
- [x] 5. 주간 기여도 점수 메타데이터
  - 입력 의존: 페이즈 1 #6 + 페이즈 2 #5
  - 대상 테이블: 신규 `weekly_contributions` 테이블 + RLS 정책 + pg_cron + RPC 함수
  - 산출물: `Docs/content-data/[data]20260522_m8.5_weekly_contributions_sql.md`
  - 완료: 2026-05-22T14:05:00+09:00

## 페이즈 4: 개발 명세

**상태**: in_progress

계획된 산출물:
- [x] 1. 생활권 완성도 대시보드 + 홈 화면 위젯 확장 명세
  - 입력 의존: 페이즈 1 #1 + 페이즈 2 #1 + 페이즈 3 #1 위임 결정
  - 권장 내용: `HomeScreen` 확장, 신규 `LivingsphereDashboardSection`, 정보 위계, 진입 동선
  - 산출물: `Docs/spec/[spec]20260522_m8.5_livingsphere_dashboard.md`
  - 구현 계획서(implement-agent 부산물): `Docs/spec/[spec]20260522_m8.5_livingsphere_dashboard_plan.md`
  - 완료: 2026-05-22T16:44:00+09:00 (spec 작성) / 2026-05-22T20:25:00+09:00 (구현 완료)
- [x] 2. 간판 용병 솔로/소수정예 의뢰 QuestGenerator 확장 명세
  - 입력 의존: 페이즈 1 #2 + 페이즈 2 #2 + 페이즈 3 #4
  - 권장 내용: `QuestGenerator` 신규 hook 또는 별도 슬롯, `ActiveQuest` 확장, 보상 배수
  - 산출물: `Docs/spec/[spec]20260523_m8.5_flagship_solo_quests.md`
  - 구현 계획서(implement-agent 부산물): `Docs/spec/[spec]20260523_m8.5_flagship_solo_quests_plan.md`
  - 완료: 2026-05-23T14:18:00+09:00 (spec 작성) / 2026-05-23T18:51:00+09:00 (구현 완료, 커밋 `cd29b4a`)
- [x] 3. 전투 시뮬레이터 감정 반응·히든 스탯 hook 명세
  - 입력 의존: 페이즈 1 #3·#4·#5 + 페이즈 2 #3·#4 + 페이즈 3 #2·#3
  - 권장 내용: `CombatSimulator` 신규 hook, 4 감정 상태 적용, 5 히든 스탯 hook, `battle_memory_templates` 30행과 `CombatSimulationResult.battleMemoryEvents`
  - 산출물: `Docs/spec/[spec]20260531_m8.5_combat_emotion_hidden_stats.md`
  - 구현 계획서(implement-agent 부산물): `Docs/spec/[spec]20260531_m8.5_combat_emotion_hidden_stats_plan.md`
  - 데이터 산출물(SQL, 적용 별도 승인 대기): `Docs/content-data/[data]20260531_m8.5_combat_emotion_hidden_stats_sql.md`
  - 완료: 2026-05-31T20:42:00+09:00 (spec 작성) / 2026-05-31T23:20:00+09:00 (구현 완료, 커밋 `288fc71`)
- [ ] 4. 용병 상세 화면 전투 기억·히든 스탯·개인 숙련도 섹션 명세
  - 입력 의존: 페이즈 1 #5 + 페이즈 4 #2·#3
  - 권장 내용: `MercenaryDetailScreen` 확장, 신규 `BattleMemorySection`·`HiddenStatsSection`·`MasteryProgressSection`, 위업/칭호 섹션 연계
  - 산출물: `Docs/spec/[spec]20260607_m8.5_mercenary_detail_sections.md`
  - spec 작성 완료: 2026-06-07 (spec-pipeline — verify-spec PASS 1회 통과) / 구현 대기
- [ ] 5. UI 폴리싱 1차 + 이미지 에셋 적용 명세 (홈/파견/이동/제작)
  - 입력 의존: 페이즈 1 전체 + 페이즈 3 #1 위임 결정
  - 권장 내용: 정보 위계 재정렬, 이미지 슬롯, 카드 위계, 요약/상세 전환, `AppTheme` 확장
  - 산출물: (미생성)
- [ ] 6. 주간 기여도 랭킹 MVP 명세 (Supabase + UI)
  - 입력 의존: 페이즈 1 #6 + 페이즈 2 #5 + 페이즈 3 #5
  - 권장 내용: Supabase 함수/테이블 + RLS, 점수 산출 클라이언트, 랭킹 UI MVP, PvP 손실 없는 검증 정책
  - 산출물: (미생성)
- [ ] 7. 검증 및 회귀 명세
  - 입력 의존: 페이즈 4 #1~#6 통합
  - 권장 내용: M1~M8b 회귀 검증 절차, 새 기능별 검증 케이스, `flutter analyze`/`flutter test` 게이트, UI 검증 기준
  - 산출물: (미생성)

## 페이즈 간 의존

- 페이즈 2 항목 1~5 → 페이즈 1 대응 항목 입력
- 페이즈 3 항목 2~5 → 페이즈 1·2 대응 항목
- 페이즈 3 항목 1 → 페이즈 1 전체 (이미지 슬롯 위치 결정)
- 페이즈 4 항목 1~6 → 페이즈 1·2·3 대응 항목
- 페이즈 4 항목 7 → 페이즈 4 항목 1~6 통합

## 완료 기준

- [ ] 생활권 완성도 대시보드에서 지역 안정도, 남은 사건, 재료, 제작 목표, 위업을 확인할 수 있다.
- [ ] 간판 용병 1인/소수정예 의뢰가 1종 이상 동작한다.
- [ ] 전투 중 동료 사망 또는 중상 상황에서 감정 반응이 발생할 수 있다.
- [ ] 불굴, 투지, 운 등 히든 스탯이 전투 사건으로 해금된다.
- [ ] 용병 상세 화면에서 전투 기억과 히든 스탯을 확인할 수 있다.
- [ ] 홈/파견/용병 상세/이동/제작 화면의 1차 UI 폴리싱이 완료된다.
- [ ] 세력 엠블럼, 지역 썸네일, 아이템 아이콘 중 최소 2종 이상이 실제 화면에 반영된다.
- [ ] 주간 더스트플레인 생활권 기여도 랭킹 MVP가 동작한다.
- [ ] M1~M8b 기능 회귀 이상 없음 (`flutter analyze` 0 issues, `flutter test` 전체 PASS).

## 실행 이력

- 2026-05-18T00:00:00+09:00: M8.5 사전 골격 작성 (planned 상태, 시스템별 페이즈 4종 초안).
- 2026-05-20T19:05:00+09:00: milestone-runner 신규 시작. 사전 골격을 milestone-runner 표준 4페이즈 구조(컨텐츠 설계 · 밸런스 확정 · 데이터 생성 · 개발 명세)로 재구성하여 산출물 계획 승인 (페이즈 1: 6개 / 페이즈 2: 5개 / 페이즈 3: 5개 / 페이즈 4: 7개, 총 23개). 상태 in_progress로 전환.
- 2026-05-20T19:05:00+09:00: 페이즈 1 시작. 첫 산출물은 "생활권 완성도 대시보드 컨셉"이다.
- 2026-05-21T09:45:00+09:00: 페이즈 1 #1 "생활권 완성도 대시보드 컨셉" 완료 — `Docs/content-design/[content]20260520_m8.5_livingsphere_dashboard.md` (26803 bytes).
- 2026-05-21T12:05:00+09:00: 페이즈 1 #2 "간판 용병 솔로/소수정예 의뢰 컨셉" 완료 — `Docs/content-design/[content]20260521_m8.5_flagship_solo_quests.md` (35770 bytes). M6 지명 의뢰 확장 / 솔로 1인+소수정예 2~3인 2계층 / 사망 저항 cap 솔로 0.95·소수 0.90 / 4 신규 칭호+3 카운터 / 의뢰 5종(솔로 3+소수 2).
- 2026-05-21T13:00:00+09:00: 페이즈 1 #2 사용자 사후 수정 (38534 bytes) — partySizeMin/Max Freezed default 명시, 카운터 4종(solo_great_success_count 추가), NamedTier 재정렬 정책 변경, 보상 배수 `special_flags` 직접 저장 정책.
- 2026-05-21T13:53:00+09:00: 페이즈 1 #3 "전투 감정 반응 컨셉" 완료 — `Docs/content-design/[content]20260521_m8.5_combat_emotional_reactions.md` (34147 bytes). combat_status_effects kind='emotional' 4행 확장 / 4 감정마다 다른 텍스처(분노=폭주, 절망=무력화, 슬픔=위축, 투지=영웅적) / 사건별 매트릭스 트리거 + 트레잇 가중 / 우선순위 투지>분노>슬픔>절망 / CombatReport scope='emotional' ~20행 신규.
- 2026-05-21T14:02:00+09:00: 페이즈 1 #3 사용자 사후 수정 (36343 bytes) — hooks 신규 필드 제거 후 기존 hook_target 그대로 사용, apply_method='none'+effectId 분기로 슬픔 처리, StatusEffectEvent 이력 재활용.
- 2026-05-21T14:58:00+09:00: 페이즈 1 #4 "히든 스탯 해금 컨셉" 초안 완료 — `Docs/content-design/[content]20260521_m8.5_hidden_stats.md` (34841 bytes). 초안 값은 Mercenary.hiddenStats Map 신규 HiveField 27 / 신규 hidden_stats 31번째 테이블로 기록되었으나, 2026-05-21T15:23 정정으로 폐기됨.
- 2026-05-21T15:23:00+09:00: 페이즈 1 #4 사용자 사후 수정 (38074 bytes) — HiveField 27 → 26으로 정정 (titleIds=24/recruitedAt=25/hiddenStats=26), 효과 3계층(M8b hook + 기존 PassiveBonusService + QuestCompletionService 전용 후처리)으로 변경 — 신규 PassiveEffect 타입 가정 회피, hidden_stats 테이블 번호 41 → 41(원문 유지) 그러나 hidden_stats를 41번으로 명시 (영속 데이터 최소 확장 원칙 강화).
- 2026-05-21T16:11:00+09:00: 페이즈 1 #5 "용병 전투 기억 컨셉" 완료 — `Docs/content-design/[content]20260521_m8.5_battle_memory.md` (38927 bytes). BattleMemoryEntry 신규 typeId 31 (mercId/entryType/sourceEventId/timestamp/templateKey/templateData 6 필드) / Mercenary.battleMemories HiveField 27 + MercenarySnapshot.hiddenStats HiveField 6 (페이즈 1 #4 Q-4 결정) + MercenarySnapshot.battleMemories HiveField 7 / 30 cap FIFO / 6 entryType / sourceEventId 참조 + lookup / battle_memory_templates 30행.
- 2026-05-21T18:03:00+09:00: 페이즈 1 #6 "주간 기여도 랭킹 컨셉" 완료 — `Docs/content-design/[content]20260521_m8.5_weekly_contribution_ranking.md` (34784 bytes). 5항목 점수(지역 안정화/세력 의뢰/전투 활약/제작/위업) / UTC 월요일 0:00 사이클 / 5분 throttle 업로드 / 익명 ID 표시 + 보상 없음 MVP / 정보 탭 WeeklyRankingScreen + 홈 HomeCard 2위치 / Supabase weekly_contributions 테이블 + RLS + pg_cron + 익명 인증 부트스트랩 / CombatSimulator 순수성 유지 (weeklyContributionDelta 결과 반환).
- 2026-05-21T18:10:00+09:00: **페이즈 1 완료 — 6/6 산출물 모두 완료.** 페이즈 종료 체크포인트 진입.
- 2026-05-21T18:15:00+09:00: 사용자 승인으로 페이즈 2 "밸런스 확정" 시작. 첫 산출물은 "생활권 완성도 지표 수치화".
- 2026-05-21T18:23:00+09:00: 페이즈 2 #1 "생활권 완성도 지표 수치화" 완료 — `Docs/balance-design/[balance]20260521_m8.5_livingsphere_metrics.md` (23034 bytes). 사용자 사후 보완: 사건 분모 14→11 (위업 중복 제거), 자원·제작 allowlist 5종 명시, 영향력 untouched=0 처리(36% 과대표시 해소), 위업 분모 7→5 (현 코드 미발급 T2 제외), 30분/8시간 목표 임박도 산식 `1 - gap/threshold`로 통일. 통합 가중치 0.20/0.20/0.20/0.15/0.10/0.15.
- 2026-05-21T18:56:00+09:00: 페이즈 2 #2 "간판 용병 의뢰 보상·난이도 수치" 완료 — `Docs/balance-design/[balance]20260521_m8.5_flagship_solo_quest_balance.md` (21105 bytes). 5종 의뢰 최종 매트릭스: 솔로 #1 x2.0/1.7, #2 x1.8/1.8, #3 x2.2/2.0, 페어 #4 x1.5/1.4, 삼인행 #5 x1.4/1.3. cap 0.95/0.90, α=2, 쿨다운 48h/36h. 사용자 사후 보완: 시간/파견비 산식을 실제 `calculateDispatchDuration`/`calculateDispatchCost` 코드 기준으로 보정, 명성 보상 `difficulty×10` 코드 기준, 가중치 컬럼명 `named_weight_alpha`로 변경(`QuestGenerator.computeFinalWeight` 수정 필요), 솔로 #1을 부트스트랩에서 분리하고 #2/#3을 초반 노출로 재해석, 삼인행 hook을 `achievement_count=10`으로 통일.
- 2026-05-22T10:52:00+09:00: 페이즈 2 #3 "감정 반응 상태 발동 확률·지속·수치" 완료 — `Docs/balance-design/[balance]20260521_m8.5_emotional_reaction_values.md` (33129 bytes). 4 감정 default 확정 (분노 atk 0.30/def -0.20 multiplicative 3턴, 절망 hit -0.20/eva -0.15 additive 3턴, 슬픔 skip 0.50 none 2턴, 투지 death_resist +0.20/eva +0.15 additive 4턴). 발동 확률 60/50/80/100%. 트레잇 13키 실제 매칭 (vengeful/berserker_talent/madman/slayer + guardian/empathic/team_player/mentor + iron_will/unyielding/hardened/fearless/composed). 투지 cap 정책: 사망 저항 합산식에 가산 후 capForQuest로 재clamp, cap 통과 후 별도 가산 금지. 사용자 사후 보완: 부호 정책 명시 (default_intensity 음수 허용, signed additive), 전투 단위 latch(`despairTriggered`/`determinationTriggeredMercIds`) 추가, sorrow 행동 직전 평가 명시.
- 2026-05-22T11:36:00+09:00: 페이즈 2 #4 "히든 스탯 효과 수치 및 해금 임계값" 완료 — `Docs/balance-design/[balance]20260522_m8.5_hidden_stat_values.md` (30876 bytes). 5 스탯 lv별 최종 매트릭스 (불굴 death_resist +0.10/recovery ×0.80, 투지 despair 면제 +0.40/rep +0.075, 운 critical +0.05/eva +0.05/drop +0.025, 공포 저항 mez +0.25/강공격 회피 +0.075, 전장 감각 action +2.5/featured +1.0/hit +0.05). 임계값 1·3·7·15·30 유지. 사건 가중치 솔로 완수 +2/솔로 대성공 +3 유지. 풀스택 도달 ~3주. 사용자 사후 보완: PassiveEffect 18종+unknown fallback 명시, recovery_time_reduction 양수 저장 정책, 운 item_drop 파티 최고 lv 1명만 적용, 풀스택 시뮬레이션 단계별 분리 (base/투지/세력 포함).
- 2026-05-22T11:58:00+09:00: 페이즈 2 #5 "주간 기여도 점수 산식 수치" 완료 — `Docs/balance-design/[balance]20260522_m8.5_weekly_contribution_values.md` (20997 bytes). 5항목 최종 매트릭스 (안정화 50/200/500, 세력 difficulty×50, 전투 100/3/750, 제작 tier×30, 위업 100~500). 1주 누적 신규 3,275 / 중급 6,400 / 베테랑 9,125. 항목별 cap 도입 (combat 5500 등). settlement_trust_belonging 200점 추가. 동률 처리 정책 명시. 사용자 사후 보완: critical 5→3, 솔로 대성공 1000→750, combat cap 6000→5500.
- 2026-05-22T12:05:00+09:00: **페이즈 2 완료 — 5/5 산출물 모두 완료.** 페이즈 종료 체크포인트 진입.
- 2026-05-22T12:15:00+09:00: 사용자 결정으로 페이즈 3 부분 진행. #1 이미지 에셋 + #5 주간 기여도 메타데이터만 페이즈 3에서 진행. #2 감정 반응(→ 페이즈 4 #3) / #3 히든 스탯(→ 페이즈 4 #3) / #4 솔로 의뢰(→ 페이즈 4 #2)는 spec 인라인 위임. 첫 산출물은 "이미지 에셋 메타데이터".
- 2026-05-22T12:35:00+09:00: 사용자 질문으로 #1 이미지 에셋 산출물의 실제 가치 검토. 이미지 파일 없이 메타데이터만 작성하는 가치가 낮다고 판단하여 #1도 페이즈 4 #5 UI 스펙에 통합 위임 결정. 페이즈 3은 #5만 진행 (1개 산출물만 남음).
- 2026-05-22T14:05:00+09:00: 페이즈 3 #5 "주간 기여도 점수 메타데이터" 완료 — `Docs/content-data/[data]20260522_m8.5_weekly_contributions_sql.md` (14784 bytes). `weekly_contributions` 테이블 CREATE + 인덱스 + RLS 정책 4종 + pg_cron 정리(매주 수 0:00 UTC, 2주 보존) + RPC `upsert_weekly_score`(SECURITY DEFINER + 인증 가드 + 음수 거부) + RPC `get_my_weekly_rank`(동률 처리 정합). 적용 방법 3종(CLI/MCP/Studio) + 검증 쿼리 6종 + RLS 수동 테스트 10 케이스 + 롤백 SQL + 운영 노트. data-generator 타입 부재 + 텍스트 데이터 생성 불요 판단으로 Write 도구로 직접 작성.
- 2026-05-22T14:10:00+09:00: **페이즈 3 완료 — #5만 진행, 1/1 완료.** #1 이미지 에셋 / #2 감정 반응 / #3 히든 스탯 / #4 솔로 의뢰는 페이즈 4 spec 인라인 위임. 페이즈 종료 체크포인트 진입.
- 2026-05-22T14:33:00+09:00: 페이즈 4 진입 전 종합 리뷰 보완 반영. `UserData` HiveField 할당을 생활권 목표 핀 28~29 / 주간 기여도 30~33으로 분리하고, `CombatSimulationResult.weeklyContributionDelta` HiveField 15를 예약. 페이즈 4 #3 입력에 `battle_memory_templates` 30행과 페이즈 1 #5 전투 기억 문서를 명시. 이미지 에셋 메타데이터는 페이즈 4 #5 위임으로 문서 정정.
- 2026-05-22T16:44:00+09:00: 페이즈 4 #1 "생활권 완성도 대시보드 + 홈 화면 위젯 확장 명세" spec 작성 완료 — `Docs/spec/[spec]20260522_m8.5_livingsphere_dashboard.md` (57171 bytes). 6 지표(안정도/거점 발전/사건 완료율/자원·제작/세력 영향력/위업 달성률) 통합 완성도 + 30분·8시간 목표 추천 + 6 점프 동선 + 4 freezed 모델 + 9 신규 Provider + 2 신규 위젯 + `UserData` HiveField 28~29 영속.
- 2026-05-22T20:25:00+09:00: 페이즈 4 #1 implement-agent 구현 완료 — 14 TASK 순차 격리 모드 (29 FR을 14 TASK로 분할, 각 TASK verifier+flutter-reviewer 미니 사이클). 구현 계획서 `Docs/spec/[spec]20260522_m8.5_livingsphere_dashboard_plan.md` (16363 bytes). 회귀 테스트 698/698 PASS. 신규 도메인 서비스 2종, 9 Provider, 위젯 2종, 단위 테스트 29 신규.
- 2026-05-22T20:50:00+09:00: milestone-runner --resume — 페이즈 4 #1 매칭 확인 완료. 페이즈 4 상태 in_progress로 갱신. 다음 액션: 페이즈 4 #2 "간판 용병 솔로/소수정예 의뢰 QuestGenerator 확장 명세" spec-writer 호출 안내.
- 2026-05-23T14:18:00+09:00: 페이즈 4 #2 "간판 용병 솔로/소수정예 의뢰 QuestGenerator 확장 명세" spec 작성 완료 — `Docs/spec/[spec]20260523_m8.5_flagship_solo_quests.md` (48170 bytes). `QuestPool.partySizeMin/Max` 컬럼, `FlagshipSoloQuestConfig` 정적 상수(사망저항 cap 솔로 0.95/소수 0.90, 쿨다운 48h/36h, weight α 2.0), `CombatSimulator.simulate(deathResistanceCaps:)` 5계층 패스스루, `QuestSortService.namedTier` 3그룹, `DispatchDetailPage` 정확 인원 강제.
- 2026-05-23T18:51:00+09:00: 페이즈 4 #2 implement-agent 구현 완료 — 커밋 `cd29b4a`. QuestPool 파티 크기 필드 / CombatSimulator deathResistanceCaps 5계층 / quest_provider 5 trailing fail-soft / DispatchDetailPage 인원 강제 UI / ⭐ 솔로 배지. 구현 계획서 `Docs/spec/[spec]20260523_m8.5_flagship_solo_quests_plan.md` (15198 bytes).
- 2026-05-31T20:30:00+09:00: milestone-runner --resume — 페이즈 4 #2 매칭 확인 완료(state.md 동기화 누락분 소급 반영). 다음 액션: 페이즈 4 #3 "전투 시뮬레이터 감정 반응·히든 스탯 hook 명세" spec-writer 호출 안내.
- 2026-05-31T20:42:00+09:00: 페이즈 4 #3 "전투 시뮬레이터 감정 반응·히든 스탯 hook 명세" spec 작성 완료 — `Docs/spec/[spec]20260531_m8.5_combat_emotion_hidden_stats.md` (36761 bytes). 감정 반응 4종(combat_status_effects kind=emotional 4행)·히든 스탯 5종(hidden_stats 테이블 + HiddenStatBonusResolver 9 hook)·전투 기억 6 entryType(BattleMemoryEntry typeId 31)·HiveField(Mercenary 26 hiddenStats/27 battleMemories, CombatSimulationResult 13/14, MercenarySnapshot 6/7)·트리거 우선순위(투지>분노>슬픔>절망 결정적 flush)·효과 산식.
- 2026-05-31T23:20:00+09:00: 페이즈 4 #3 implement-agent 구현 완료 — 커밋 `288fc71`. 감정 반응 4종 trigger·우선순위 flush / 히든 스탯 5종 9 hook·3계층 효과·lv 임계 [1,3,7,15,30] / 전투 기억 6 entryType trailing / lv1 hiddenStatUnlockedProvider(medium) 다이얼로그 / SQL 산출물 4 블록(`Docs/content-data/[data]20260531_m8.5_combat_emotion_hidden_stats_sql.md`, 실제 Supabase 적용 별도 승인 대기) / 테스트 64 신규 762 PASS. 구현 계획서 `Docs/spec/[spec]20260531_m8.5_combat_emotion_hidden_stats_plan.md` (104 라인).
- 2026-06-07T00:00:00+09:00: 페이즈 4 #3 사후 검증 — verifier PASS(FR-1~19 전체 충족, 이슈 없음), `flutter analyze` error 0(info 1건 use_null_aware_elements), `flutter test` 762/762 PASS 재확인. state.md 동기화 누락분 소급 반영(#3 완료 처리). 다음 액션: 페이즈 4 #4 "용병 상세 화면 전투 기억·히든 스탯·개인 숙련도 섹션 명세" spec-writer 호출.
- 2026-06-07T00:05:00+09:00: milestone-runner --resume — 페이즈 4 산출물 스캔 결과 state.md와 파일시스템 일치(추가 누락분 없음). 사용자 결정: 페이즈 4 #4를 spec-pipeline으로 진행. 실행 명령어 `/spec-pipeline @Docs/content-design/[content]20260521_m8.5_battle_memory.md @Docs/spec/[spec]20260531_m8.5_combat_emotion_hidden_stats.md` 안내. 예상 산출물 `Docs/spec/[spec]20260607_m8.5_mercenary_detail_sections.md`. spec 생성 후 `--resume` 재진입 대기.
- 2026-06-07T00:30:00+09:00: 페이즈 4 #4 "용병 상세 화면 전투 기억·히든 스탯·개인 숙련도 섹션 명세" spec 작성 완료 — `Docs/spec/[spec]20260607_m8.5_mercenary_detail_sections.md`. UI 표시 계층 전용(데이터/도메인은 #3 완비, 읽기 전용). 8 FR: HiddenStatsSection(lv1+ 노출/진행도 바) / BattleMemorySection(desc 정렬/6 entryType 렌더/lookup fail-soft) / MasteryProgressSection(솔로 4 카운터 + 미획득 전용 칭호 진행도, 독립 섹션 — 사용자 결정) / MercenaryDetailOverlay 섹션 통합(TitlesSection→숙련도→히든스탯→전투기억→행동지표) / ChronicleScreen _MemorialCard 펼침(titleIds/hiddenStats/battleMemories). 신규 위젯 3 + 수정 2. verify-spec PASS 1회 통과(코드 대조 — 파일/라인/필드/Provider/색상 실측 일치, 수정 지시 없음). 사용자 결정: 개인 숙련도 독립 섹션 + 목업 없이 텍스트 명세. 구현 방식 추천 implement-agent(3/6). 구현 대기.
