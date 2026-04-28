# M4 실행 상태

> 시작: 2026-04-28
> 마지막 업데이트: 2026-04-28
> 현재 페이즈: 1
> 상태: in_progress

## 로드맵 요구사항 요약

- **목표**: 세력을 단순 소속 표시 → 완결된 진행 시스템(전용 시설·거점·상점·전용 트레잇)으로 변모. 가입 세력 선택이 용병단의 장기 전략을 결정짓는 마일스톤.
- **포함 시스템**: 세력 전용 시설 14종 (탈퇴 시 잠금/레벨 보존) / 세력 거점 + 상점 (평판 구간별 상품 해금, 세력당 8~15개) / 세력 전용 트레잇 (세력당 2~3종, 가입+거점 방문+평판+행동 지표 AND 조건).
- **선행 의존성**: M1 세력 패시브/퀘스트 태그 / M2a 아이템 인프라.
- **사전 작업 필수**: `traits.faction_id` 필드 + acquisition_condition 평가기 확장 → M4 본 구현 진입 전 명세 선행.
- **스키마 확장**: `faction_facilities` / `faction_shop_items` 신규 테이블 / `factions.stronghold_region_id` / `traits.faction_id`.
- **종료 조건**: 가입 세력 1개에 대해 거점 방문 → 상점 구매 → 전용 시설 Lv3 → 전용 트레잇 1개 획득의 10~15시간 플레이 가능.

## 페이즈 1: 컨텐츠 설계

**상태**: in_progress

계획된 산출물:
- [ ] 1. 세력 전용 시설 14종 컨셉
  - 참고 문서: `Docs/roadmap/master_roadmap.md` (M4 섹션) / `Docs/content-design/[content]20260416_faction_system.md` / `Docs/content-design/[content]20260417_faction_passive_mapping.md`
  - 산출물: (미생성)
- [ ] 2. 세력 거점 지정 + 방문 UX
  - 참고 문서: `Docs/content-design/[content]20260416_faction_system.md` / `Docs/proto_design.md`
  - 산출물: (미생성)
- [ ] 3. 세력 상점 컨셉
  - 참고 문서: `Docs/content-design/[content]20260418_initial_item_set.md` / `Docs/content-design/[content]20260418_item_taxonomy.md`
  - 산출물: (미생성)
- [ ] 4. 세력 전용 트레잇 컨셉
  - 참고 문서: `Docs/content-design/20260412_trait_system_design.md` / `Docs/content-design/20260413_phase_a_trait_lifecycle.md`
  - 산출물: (미생성)
- [ ] 5. 세력 트레잇 데이터 모델 사전 확정 (필수 선행)
  - 참고 문서: `Docs/roadmap/master_roadmap.md` (M4 섹션 "세력 전용 트레잇 데이터 모델 사전 확정")
  - 산출물: (미생성)

## 페이즈 2: 밸런스 확정

**상태**: pending

계획된 산출물:
- [ ] 1. 세력 전용 시설 비용/효과 공식
  - 입력 기획서: 페이즈 1 #1
  - 산출물: (미생성)
- [ ] 2. 세력 상점 가격표
  - 입력 기획서: 페이즈 1 #3 + `Docs/balance-design/[balance]20260420_elite_drop_simulation.md` / `Docs/balance-design/20260418_essence_inflation.md`
  - 산출물: (미생성)
- [ ] 3. 세력 전용 트레잇 강도 밸런스
  - 입력 기획서: 페이즈 1 #4 + #5
  - 산출물: (미생성)

## 페이즈 3: 데이터 생성

**상태**: pending

> ⚠ 페이즈 3 진입 전 data-generator 타입 스펙 작성 필수: `faction-facility` / `faction-shop` 신규 추가, `trait` 타입 스펙 `faction_id` 컬럼 확장.

계획된 산출물:
- [ ] 1. faction-facility × 14종 (레벨 25 펼침) — data-generator 호출
  - 입력 기획서: 페이즈 1 #1 + 페이즈 2 #1
  - 대상 테이블: `faction_facilities` (신규)
  - 산출물: (미생성)
- [ ] 2. faction-shop-item × 112~210행 — data-generator 호출
  - 입력 기획서: 페이즈 1 #3 + 페이즈 2 #2 + 기존 `[item]20260420_m2a-equipment.csv`
  - 대상 테이블: `faction_shop_items` (신규) + 필요 시 `items` 추가
  - 산출물: (미생성)
- [ ] 3. faction-trait × 28~42개 — data-generator 호출
  - 입력 기획서: 페이즈 1 #4 + #5 + 페이즈 2 #3
  - 대상 테이블: `traits` (faction_id 추가) + `trait_synergies` / `trait_conflicts`
  - 산출물: (미생성)

## 페이즈 4: 개발 명세

**상태**: pending

계획된 산출물:
- [ ] 1. 세력 트레잇 데이터 모델 확장 명세 (다른 M4 명세의 선행 의존)
  - 입력 기획서: 페이즈 1 #5
  - 산출물: (미생성)
- [ ] 2. 세력 전용 시설 시스템 명세
  - 입력 기획서: 페이즈 1 #1 + 페이즈 2 #1 + 페이즈 4 #1
  - 산출물: (미생성)
- [ ] 3. 세력 거점 + 상점 시스템 명세
  - 입력 기획서: 페이즈 1 #2 + 페이즈 1 #3 + 페이즈 2 #2
  - 산출물: (미생성)
- [ ] 4. 세력 전용 트레잇 시스템 명세
  - 입력 기획서: 페이즈 1 #4 + 페이즈 2 #3 + 페이즈 4 #1
  - 산출물: (미생성)

## 실행 이력

- 2026-04-28: 마일스톤 시작
- 2026-04-28: 4개 페이즈 산출물 계획 승인 (페이즈 1: 5개 / 페이즈 2: 3개 / 페이즈 3: 3개 / 페이즈 4: 4개)
- 2026-04-28: 페이즈 1 시작
