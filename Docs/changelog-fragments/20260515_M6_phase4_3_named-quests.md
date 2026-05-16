### M6 페이즈 4 #3 — 지명 의뢰 시스템 (M6 마일스톤 완료)

- 지명 의뢰 시스템 추가 — 칭호/위업 누적/간판 용병 정체성을 의뢰인이 알아보고 의뢰를 보내는 7종 지명 의뢰. hook 3종(title 3 / achievement_count 2 / flagship 2) + 24h 쿨다운 + 가중치 +α=3로 노출 빈도 자연 분산.
- 의뢰 카드 차별화 — 신규 `namedAccent` 분홍 마젠타 색상으로 사이드바·이름·테두리·배지 일관 강조. ✩ 지명 배지에 hook별 설명("칭호 — {name}" / "위업 N개 이상" / "간판 용병 지명").
- 잠금 UI — title hook은 보유 용병 전원 파견 중일 때, flagship hook은 동결 용병 파견 중일 때 카드 dim + 토스트 "지명 용병 {name}이(가) 복귀해야 수행할 수 있습니다".
- 보상 보너스 — 골드 +30~50% + 명성 +30~50% 자동 적용 (`special_flags.named_reward_multiplier` / `named_reputation_multiplier`).
- 자동 종료 — 사망/방출 시 진행 중인 flagship 의뢰 자동 정리 + ActivityLog "지명 의뢰 '{name}'가 지명 용병의 부재로 종료되었다" 발급.
- 파견 화면 정렬 6슬롯 → 7슬롯 — 신규 `NamedTier`가 거점 사건 다음, 세력 전용 위에 배치.
- `quest_pools` 4 컬럼 확장(M4 `is_fixed` 패턴 재사용) + CHECK 2종 + 부분 INDEX + 7행 데이터 시드.
- M6 마일스톤 전체 완료 — roadmap 종료 조건 4건 모두 충족 (3~5h 내 용병 이름·칭호 기억 / 시작 거점 사건 해결 용병 지명 의뢰 1회 이상 / 사망 용병 연대기 영구 보존 / 간판 용병 시스템).
