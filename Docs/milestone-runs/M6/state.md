# M6 실행 상태

> 시작: 2026-05-05T11:40:25Z
> 마지막 업데이트: 2026-05-05T11:40:25Z
> 현재 페이즈: 1
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

**상태**: in_progress

계획된 산출물:
- [ ] 1. 위업·연대기 시스템 설계 (`achievement_chronicle_system`)
  - 참고 문서: `Docs/content-design/[content]20260423_chain_quests.md`, `[content]20260503_settlement-trust-and-fixed-events.md`, ActivityLog 시스템(`band_of_mercenaries/lib/core/domain/`)
  - 산출물: (미생성)
- [ ] 2. 칭호·간판 용병 설계 (`title_and_flagship`)
  - 참고 문서: roadmap M6 칭호 예시 4개, 트레잇 데이터(`Docs/content-design/20260412_trait_system_design.md`), 거점 신뢰도(`[content]20260503_settlement-trust-and-fixed-events.md`)
  - 의존: 1
  - 산출물: (미생성)
- [ ] 3. 지명 의뢰 설계 (`named_quest_design`)
  - 참고 문서: 페이즈 1 #1·#2, QuestGenerator(`band_of_mercenaries/lib/features/quest/domain/quest_generator.dart`)
  - 의존: 1, 2
  - 산출물: (미생성)

## 페이즈 2: 밸런스 확정

**상태**: pending

계획된 산출물:
- [ ] 1. 칭호 효과 수치 밸런스 (`title_effect_values`)
  - 입력: 페이즈 1 #2
  - 참고 문서: `Docs/balance-design/20260417_dispatch_synergy_values.md`, `20260417_faction_passive_values.md`
  - 산출물: (미생성)
- [ ] 2. 노출 빈도·획득 페이스 밸런스 (`exposure_pacing`)
  - 입력: 페이즈 1 #1·#3
  - 참고 문서: `Docs/balance-design/[balance]20260424_chain_quest_rewards.md`, `[balance]20260503_settlement-trust-tuning.md`
  - 산출물: (미생성)

## 페이즈 3: 데이터 생성

**상태**: pending (페이즈 4 완료 후 재결정)

계획된 산출물 (선택적):
- [ ] 1. `types/title.md` 타입 스펙 + 칭호 8~12개 데이터
  - 입력: 페이즈 4 #2 명세 (스키마 확정 후)
  - 산출물: (미생성)
- [ ] 2. `types/named_quest.md` 타입 스펙 + 지명 의뢰 5~8개 데이터
  - 입력: 페이즈 4 #3 명세
  - 산출물: (미생성)
- [ ] 3. `types/chronicle_template.md` 타입 스펙 + 연대기 문구 30~50개 (자동화 가치 가장 큼)
  - 입력: 페이즈 4 #1 명세
  - 산출물: (미생성)

> 페이즈 4 종료 후 사용자가 진행 여부를 결정한다. 명세에서 데이터 스키마가 확정되면 타입 스펙 작성 부담이 감소한다.

## 페이즈 4: 개발 명세

**상태**: pending

계획된 산출물:
- [ ] 1. 위업·연대기 시스템 명세 (`achievement_chronicle_spec`)
  - 입력: 페이즈 1 #1 + 페이즈 2 #2
  - 핵심: BandAchievement 모델 + chronicle 신규 Hive 박스(typeId 16+) + AchievementService 5 hook + 홈 카드 + 다이얼로그 큐 통합 + 사망 보존
  - 산출물: (미생성)
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
