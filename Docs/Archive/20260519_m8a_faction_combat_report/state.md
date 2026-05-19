# M8a 실행 상태

> 시작: 2026-05-18T12:42:03+09:00
> 마지막 업데이트: 2026-05-19T07:40:00+09:00
> 현재 페이즈: 4 (개발 명세 진행 중)
> 상태: in_progress

## 로드맵 요구사항 요약

M8a "세력의 귀환"은 M7 이후 첫 후속 마일스톤이다. 14세력 전체를 한 번에 확장하지 않고, 시작 생활권과 자연스럽게 연결되는 대표 세력 2~3개만 깊게 구현한다.

핵심 목표는 세력 기능의 수직 절편을 닫고, 세력·지명·엘리트·연계 의뢰 결과에 전투 보고서 MVP를 적용하여 결과가 "성공" 한 줄이 아니라 읽을 수 있는 사건으로 남도록 만드는 것이다.

전투 보고서 MVP는 실제 턴 기반 전투 엔진을 결과의 원천으로 사용하지 않는다. 기존 성공/실패/대성공/대실패 결과를 바탕으로 파티 구성, 직업군, 트레잇, 엘리트 여부, 세력 맥락을 해석하여 요약과 상세 로그를 생성하고 저장한다. 실제 턴 기반 전투 시뮬레이터는 M8b에서 구현한다.

선행 의존성은 M1~M7 완료이다. M7 상태 파일 기준 지역 생활권 확장, 지역 상태, 이동 UI, 마을 인프라 시스템은 구현 반영 완료 상태로 본다. `Docs/content_status.md`는 M3 기준 보관본이므로 보조 참고로만 사용한다.

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 대표 세력 2~3개 선정 + 생활권 접촉점 설계
  - 참고 문서: `Docs/roadmap/master_roadmap.md`, `Docs/milestone-runs/M7/state.md`, M1 세력 관련 산출물, M7 생활권 산출물
  - 산출물: `Docs/content-design/[content]20260518_m8a_faction_contacts.md`
  - 완료: 2026-05-18T12:46:08+09:00
- [x] 2. 세력 지명 의뢰·상점·전용 보상 수직 절편 설계
  - 참고 문서: 페이즈 1 산출물 1, 기존 `factions`, `quest_pools`, `items`, `crafting_recipes` 데이터
  - 산출물: `Docs/content-design/[content]20260518_m8a_faction_vertical_slice.md`
  - 완료: 2026-05-18T12:46:08+09:00
- [x] 3. 세력 갈등·후원·평판 흐름 설계
  - 참고 문서: 페이즈 1 산출물 1, `FactionJoinService`, 위업·칭호·지역 상태 시스템
  - 산출물: `Docs/content-design/[content]20260518_m8a_faction_patronage_flow.md`
  - 완료: 2026-05-18T12:46:08+09:00
- [x] 4. 전투 보고서 MVP 톤·길이·노출 규칙 설계
  - 참고 문서: `QuestNarrativeService`, `TemplateEngine`, `QuestResultDialog`, 엘리트·지명·연계 의뢰 결과 흐름
  - 산출물: `Docs/content-design/[content]20260518_m8a_combat_report_mvp.md`
  - 완료: 2026-05-18T12:46:08+09:00

## 페이즈 2: 밸런스 확정

**상태**: completed

계획된 산출물:
- [x] 1. 세력 상점 상품 가격·해금 조건 확정
  - 입력 의존: 페이즈 1 산출물 1, 2
  - 산출물: `Docs/balance-design/[balance]20260518_m8a_faction_shop_unlocks.md`
  - 완료: 2026-05-18T12:56:55+09:00
- [x] 2. 세력 의뢰 보상·평판·재료 수급 곡선 확정
  - 입력 의존: 페이즈 1 산출물 1, 2, 3
  - 산출물: `Docs/balance-design/[balance]20260518_m8a_faction_quest_rewards.md`
  - 완료: 2026-05-18T12:56:55+09:00
- [x] 3. 전투 보고서 노출 빈도·저장 범위·UI 피로도 기준 확정
  - 입력 의존: 페이즈 1 산출물 4
  - 산출물: `Docs/balance-design/[balance]20260518_m8a_combat_report_exposure.md`
  - 완료: 2026-05-18T12:56:55+09:00

## 페이즈 3: 데이터 생성

**상태**: completed

계획된 산출물:
- [x] 1. 대표 세력 접촉점·반응 텍스트 30~50개
  - 입력 의존: 페이즈 1 산출물 1, 3
  - 대상 테이블: `factions` 확장 후보 또는 신규 접촉점 테이블, 세력 반응 텍스트 테이블 후보
  - 산출물:
    - `Docs/content-data/[faction-contact]20260518_m8a-faction-contacts.csv`
    - `Docs/content-data/[faction-contact]20260518_m8a-faction-contacts.md`
  - 완료: 2026-05-18T13:12:18+09:00
- [x] 2. 세력 지명 의뢰 10~15개
  - 입력 의존: 페이즈 1 산출물 1, 2, 3 + 페이즈 2 산출물 2
  - 대상 테이블: `quest_pools`
  - 산출물:
    - `Docs/content-data/[faction-quest]20260518_m8a-faction-named-quests.csv`
    - `Docs/content-data/[faction-quest]20260518_m8a-faction-named-quests.md`
  - 완료: 2026-05-18T13:12:18+09:00
- [x] 3. 세력 상점 상품 15~24개
  - 입력 의존: 페이즈 1 산출물 2 + 페이즈 2 산출물 1
  - 대상 테이블: 신규 세력 상점 테이블 후보, `items`
  - 산출물:
    - `Docs/content-data/[faction-shop]20260518_m8a-faction-shop-items.csv`
    - `Docs/content-data/[faction-shop]20260518_m8a-faction-shop-items.md`
  - 완료: 2026-05-18T13:12:18+09:00
- [x] 4. 세력 레시피 또는 아티팩트 3~6개
  - 입력 의존: 페이즈 1 산출물 2, 3 + 페이즈 2 산출물 1, 2
  - 대상 테이블: `items`, `crafting_recipes`, `titles` 또는 위업 보상 데이터 후보
  - 산출물:
    - `Docs/content-data/[item]20260518_m8a-faction-rewards.csv`
    - `Docs/content-data/[faction-reward]20260518_m8a-faction-rewards.csv`
    - `Docs/content-data/[faction-reward]20260518_m8a-faction-rewards.md`
  - 완료: 2026-05-18T13:12:18+09:00
- [x] 5. 전투 보고서 템플릿 80~120개 + 전장/적/결정적 장면 키워드 30~50개
  - 입력 의존: 페이즈 1 산출물 4 + 페이즈 2 산출물 3
  - 대상 테이블: 신규 전투 보고서 템플릿 테이블 후보
  - 산출물:
    - `Docs/content-data/[combat-report-template]20260518_m8a-combat-report-templates.csv`
    - `Docs/content-data/[combat-report-keyword]20260518_m8a-combat-report-keywords.csv`
    - `Docs/content-data/[combat-report-template]20260518_m8a-combat-report-templates.md`
  - 완료: 2026-05-18T13:12:18+09:00

## 페이즈 4: 개발 명세

**상태**: in_progress

계획된 산출물:
- [x] 1. 세력 접촉점·상점·지명 의뢰 시스템 명세
  - 입력 의존: 페이즈 1 산출물 1, 2, 3 + 페이즈 2 산출물 1, 2 + 페이즈 3 산출물 1~4
  - 산출물: `Docs/spec/[spec]20260518_m8a-faction-system.md`
  - 완료: 2026-05-18T13:36:00+09:00 (spec-pipeline PASS, 사용자 수동 보완 포함)
- [x] 2. 전투 보고서 저장 모델·서비스·UI 명세
  - 입력 의존: 페이즈 1 산출물 4 + 페이즈 2 산출물 3 + 페이즈 3 산출물 5
  - 산출물:
    - `Docs/spec/[spec]20260518_m8a-combat-report-system.md`
    - `Docs/spec/[spec]20260518_m8a-combat-report-system_plan.md` (implement-agent 실행 결과)
  - 완료: 2026-05-19T00:00:00+09:00 (명세 작성 + implement-agent 12 TASK 순차 격리 모드 PASS + Supabase 마이그레이션 적용)
- [x] 3. 정적 데이터 스키마·동기화·operation-bom 편집 지원 명세
  - 입력 의존: 페이즈 3 전체 + 페이즈 4 산출물 1, 2
  - 산출물: `Docs/spec/[spec]20260519_m8a-static-data-sync-and-ops.md`
  - 완료: 2026-05-19T07:40:00+09:00 (spec-pipeline PASS, revision 0회. 코드 변경 없는 정책·운영 문서)
- [ ] 4. 통합 구현 명세 및 검증 계획
  - 입력 의존: 페이즈 4 산출물 1~3
  - 산출물: (미생성)

## 페이즈 간 의존

- 페이즈 2 전체는 페이즈 1 산출물 1~4를 입력으로 사용한다.
- 페이즈 3 항목 1~4는 페이즈 1 항목 1~3과 페이즈 2 항목 1~2를 입력으로 사용한다.
- 페이즈 3 항목 5는 페이즈 1 항목 4와 페이즈 2 항목 3을 입력으로 사용한다.
- 페이즈 4 항목 1은 페이즈 1 항목 1~3, 페이즈 2 항목 1~2, 페이즈 3 항목 1~4를 입력으로 사용한다.
- 페이즈 4 항목 2는 페이즈 1 항목 4, 페이즈 2 항목 3, 페이즈 3 항목 5를 입력으로 사용한다.
- 페이즈 4 항목 3은 페이즈 3 전체와 페이즈 4 항목 1, 2를 입력으로 사용한다.
- 페이즈 4 항목 4는 페이즈 4 항목 1~3을 통합한다.

## 완료 기준

- [ ] 대표 세력 2~3개가 생활권 사건과 연결되어 등장한다.
- [ ] 세력 지명 의뢰가 위업, 신뢰도, 칭호, 지역 상태 조건으로 노출된다.
- [ ] 세력 상점 상품이 제작 재료 또는 레시피와 연결된다.
- [ ] 세력 보상이 용병단 위상 또는 지역 상태에 영향을 준다.
- [ ] 세력·지명·엘리트·연계 의뢰 결과에 전투 보고서가 저장된다.
- [ ] 전투 보고서는 요약과 상세 로그를 구분하여 표시된다.
- [ ] 전투 보고서는 완료 후 재접속해도 동일하게 유지된다.
- [ ] 14세력 전체 확장을 전제로 하지 않아도 MVP가 완결된다.
- [ ] M1~M7 기능 회귀 이상 없음.

## 실행 이력

- 2026-05-18T12:42:03+09:00: 기존 M8a planned 상태 파일을 사용자 승인에 따라 덮어쓰고 마일스톤을 신규 시작한다.
- 2026-05-18T12:42:03+09:00: 4페이즈 계획 승인 (페이즈 1: 4개 / 페이즈 2: 3개 / 페이즈 3: 5개 / 페이즈 4: 4개).
- 2026-05-18T12:42:03+09:00: 페이즈 1 시작. 첫 산출물은 "대표 세력 2~3개 선정 + 생활권 접촉점 설계"이다.
- 2026-05-18T12:46:08+09:00: 페이즈 1 산출물 1 "대표 세력 2~3개 선정 + 생활권 접촉점 설계" 완료 (`Docs/content-design/[content]20260518_m8a_faction_contacts.md`). 대표 세력은 모험가 길드, 상인 연합, 전사 길드로 확정한다.
- 2026-05-18T12:46:08+09:00: 페이즈 1 산출물 2 "세력 지명 의뢰·상점·전용 보상 수직 절편 설계" 완료 (`Docs/content-design/[content]20260518_m8a_faction_vertical_slice.md`). 세력당 지명 의뢰 4개, 상점 6개, 전용 보상 2개로 제한한다.
- 2026-05-18T12:46:08+09:00: 페이즈 1 산출물 3 "세력 갈등·후원·평판 흐름 설계" 완료 (`Docs/content-design/[content]20260518_m8a_faction_patronage_flow.md`). 가입 전 후원 상태와 상인 연합 vs 전사 길드 약한 갈등을 채택한다.
- 2026-05-18T12:46:08+09:00: 페이즈 1 산출물 4 "전투 보고서 MVP 톤·길이·노출 규칙 설계" 완료 (`Docs/content-design/[content]20260518_m8a_combat_report_mvp.md`). 일반 의뢰 제외, 세력·지명·엘리트·연계 의뢰 우선 적용으로 범위를 제한한다.
- 2026-05-18T12:46:08+09:00: 페이즈 1 종료 — 4/4 산출물 모두 완료. 상태 paused로 갱신하고 페이즈 2 승인 대기.
- 2026-05-18T12:56:55+09:00: 페이즈 2 산출물 1 "세력 상점 상품 가격·해금 조건 확정" 완료 (`Docs/balance-design/[balance]20260518_m8a_faction_shop_unlocks.md`). 가격 80~750G, 해금 평판 1/11/31/61, 제한 재고 24시간 정책을 채택한다.
- 2026-05-18T12:56:55+09:00: 페이즈 2 산출물 2 "세력 의뢰 보상·평판·재료 수급 곡선 확정" 완료 (`Docs/balance-design/[balance]20260518_m8a_faction_quest_rewards.md`). 세력 지명 의뢰 배수 1.15~1.50, 평판 보상 +2~+8, 전사 d3~d5 / 모험가·상인 d2~d4 분포를 채택한다.
- 2026-05-18T12:56:55+09:00: 페이즈 2 산출물 3 "전투 보고서 노출 빈도·저장 범위·UI 피로도 기준 확정" 완료 (`Docs/balance-design/[balance]20260518_m8a_combat_report_exposure.md`). 일반 의뢰 제외, 장기 평균 보고서 생성률 15~25%, 템플릿 96개 + 키워드 40개 기준을 채택한다.
- 2026-05-18T12:56:55+09:00: 페이즈 2 종료 — 3/3 산출물 모두 완료. 상태 paused로 갱신하고 페이즈 3 승인 대기.
- 2026-05-18T13:12:18+09:00: 페이즈 3 산출물 1 "대표 세력 접촉점·반응 텍스트" 완료 (`Docs/content-data/[faction-contact]20260518_m8a-faction-contacts.csv`). 접촉점 3개와 반응 텍스트 33개를 생성한다.
- 2026-05-18T13:12:18+09:00: 페이즈 3 산출물 2 "세력 지명 의뢰" 완료 (`Docs/content-data/[faction-quest]20260518_m8a-faction-named-quests.csv`). 대표 3세력 12개 지명 의뢰와 보상·평판·보고서 메타를 생성한다.
- 2026-05-18T13:12:18+09:00: 페이즈 3 산출물 3 "세력 상점 상품" 완료 (`Docs/content-data/[faction-shop]20260518_m8a-faction-shop-items.csv`). 세력당 6개, 총 18개 상품과 가격·재고·해금 조건을 생성한다.
- 2026-05-18T13:12:18+09:00: 페이즈 3 산출물 4 "세력 레시피 또는 아티팩트" 완료 (`Docs/content-data/[faction-reward]20260518_m8a-faction-rewards.csv`). 전용 보상 6개와 신규 아이템 후보 4개를 생성한다.
- 2026-05-18T13:12:18+09:00: 페이즈 3 산출물 5 "전투 보고서 템플릿·키워드" 완료 (`Docs/content-data/[combat-report-template]20260518_m8a-combat-report-templates.csv`). 템플릿 96개와 키워드 40개를 생성한다.
- 2026-05-18T13:12:18+09:00: 페이즈 3 종료 — 5/5 산출물 모두 완료. CSV 구조 검증을 통과했으며 Supabase에는 아직 쓰지 않았다. 상태 paused로 갱신하고 페이즈 4 승인 대기.
- 2026-05-18T13:24:00+09:00: 페이즈 4 시작 승인. 4개 명세 계획대로 진행. 첫 산출물은 "세력 접촉점·상점·지명 의뢰 시스템 명세"이다.
- 2026-05-18T13:36:00+09:00: 페이즈 4 산출물 1 "세력 접촉점·상점·지명 의뢰 시스템 명세" 완료 (`Docs/spec/[spec]20260518_m8a-faction-system.md`). spec-pipeline 1회 수정 후 PASS, 사용자가 FR-A6 dedup 기준·FR-B5 factionTag 보존·FR-C4 hook 호출 위치 분리·FR-D1 itemId seed 정합 검증·FR-F1 CraftingService DI·Q-2 칭호 grant 대상 등을 추가 보완. 사용자가 implement-agent 실행 요청.
- 2026-05-18T17:45:00+09:00: 페이즈 4 산출물 1 구현 완료 (implement-agent 파이프라인). 21 TASK / 순차 격리 모드 / 35 파일 변경(신규 16 + 수정 14 + 빌드 게이트 외과적 5). flutter analyze 0 issues, 전체 테스트 568개 PASS, build_runner 재생성 완료. 실행 결과 plan 문서: `Docs/spec/[spec]20260518_m8a-faction-system_plan.md`.
- 2026-05-18T18:58:00+09:00: 페이즈 4 산출물 2 명세서 작성 완료 (`Docs/spec/[spec]20260518_m8a-combat-report-system.md`). 전투 보고서 저장 모델(`CombatReport` typeId 21, ActiveQuest.combatReport HiveField 27) + `CombatReportService` 14단계 정적 helper + TemplateEngine `ally`·`enemy` namespace + `QuestResultDialog` 인라인 상세 전환을 다룬다. FR 10개 + Q&A 11개 결정 포함.
- 2026-05-18T21:54:00+09:00: 페이즈 4 산출물 2 구현 완료 (implement-agent 파이프라인). 12 TASK / 순차 격리 모드 / 신규 5 파일 + 수정 9 파일 + 빌드 게이트 trailing 6 파일. flutter analyze 0 issues, 전체 테스트 576/576 통과, build_runner 5쌍 재생성. 실행 결과 plan 문서: `Docs/spec/[spec]20260518_m8a-combat-report-system_plan.md`.
- 2026-05-19T00:00:00+09:00: Supabase 마이그레이션 적용. `combat_report_templates`(96행) + `combat_report_keywords`(40행) 테이블 생성·시드, RLS 정책 + 4 인덱스 + `data_versions` 행 추가. 다음 SyncService.sync()에서 자동 다운로드 → 캐시.
- 2026-05-19T00:00:00+09:00: 페이즈 4 산출물 2 매칭 승인. 페이즈 4 산출물 3 "정적 데이터 스키마·동기화·operation-bom 편집 지원 명세" 진행 대기.
- 2026-05-19T07:40:00+09:00: 페이즈 4 산출물 3 작성 완료 (`Docs/spec/[spec]20260519_m8a-static-data-sync-and-ops.md`). spec-pipeline PASS(revision 0회). 코드 변경 없는 정책·운영 문서로 (a) M8a 신규 5 테이블 SyncService 등록 정합성, (b) optionalTables 운영 정책 9개 FR, (c) data_versions 수동 발행 규약, (d) 5 캐시 시나리오(A~E), (e) 후속 마일스톤 신규 테이블 추가 워크플로 8단계를 명세. operation-bom table-config 일괄 등록은 별도 PR 백로그(Q-2)로 분리. CLAUDE.md "32개 테이블 → 37개" 갱신은 finalize-feature 단계로 위임.
