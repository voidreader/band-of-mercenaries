  페이즈 2: 밸런스 확정 — 다음 액션

  현재 액션: 3/4

  주제: 파견 상성 보정 수치 매트릭스

  참고 입력:
  - Docs/content-design/[content]20260417_dispatch_synergy.md (페이즈 1 항목 3 — 6 role × 4 quest_type 구조, 성공률 독립 레이어, 트레잇 시너지)
  - Docs/balance-design/20260417_faction_passive_values.md (성공률 공유 상한 +20%p 기준선)
  - Supabase jobs 85개 / quest_types 4개 / QuestCalculator 성공률 공식

  검토 포인트:
  - role × quest_type 매트릭스의 +%p 수치 확정 (±0 ~ ±10 범위 권장)
  - 기존 _questModifiers (explore +5, escort +3, raid 0, hunt -5) 와의 충돌/흡수 결정
  - 세력 패시브(+3~8%p) + 명성 A(+5%p) + 상성(+?%p) 누적 시 공유 상한 +20%p 도달 가능성
  - 트레잇 시너지 기존 effect_json 확장: quest_type_bonus 필드 스케일 (2~5%p 권장?)
  - 성공률 분포 시뮬레이션: 매칭 role 3명 파티 vs 불일치 파티의 실제 성공률 격차 (의미 있는 전략 차이가 생기는가)
  - jobs 85개 전수에 role 1개씩 할당 가능한 분류 기준 (경계 직업의 애매함 해결)

  실행할 명령어:
  /balance-designer 파견 상성 보정 수치 매트릭스 - M1 페이즈 2. 6 role × 4 quest_type 성공률 +%p 매트릭스, 기존 _questModifiers와의 통합,
  세력·명성과 합산한 공유 상한 +20%p 도달 시나리오, 트레잇 시너지 quest_type_bonus 스케일, 85개 job 전수의 role 분류 기준을 확정한다. 참고:
  Docs/content-design/[content]20260417_dispatch_synergy.md, Docs/balance-design/20260417_faction_passive_values.md

  예상 산출물 경로: Docs/balance-design/20260417_dispatch_synergy_values.md


  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