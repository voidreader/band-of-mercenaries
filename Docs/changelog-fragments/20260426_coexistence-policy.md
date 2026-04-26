### M3 공존 정책 — 파견 화면 정렬 + 도착 팝업 큐 통합

- 전역 다이얼로그 큐 도입 (`DialogQueueNotifier`): priority(critical/high/medium/low) + FIFO + id dedup. Hive `dialogQueue` 박스로 24h 영속화, 만료/실패 시 ActivityLog "알림 일부 유실됨" 기록
- 5개 독립 팝업 채널(건설·조사·랭크업·체인 완주·지역 변형) + 이동 도착 팝업 2종(자동 이벤트·선택지 회상) 모두 단일 큐로 통합. critical은 `barrierDismissible: false`
- 파견 화면 5계층 정렬 (`QuestSortService.sort`): Tier 0 체인 → Tier 1 세력 전용 → Tier 2 엘리트(유니크 우선) → Tier 3 변형 섹터 → Tier 4 일반. 같은 tier는 추정 보상↓ → 난이도↑ → id 사전순
- 체인 다음 단계 카드를 `ChainTopSection`(최대 3장, 활성/비활성 분기, 비활성은 "이동 화면으로" 버튼)으로 분리. 인라인 `ChainStepCard` 호출 제거
- `LayerSidebar`(8단계 우선순위 fold) + `QuestCardBadges`(체인/엘리트/섹터/세력 4종 배지) 공유 위젯 도입. 퀘스트 카드 시각 통합
- 이동 화면 체인 하이라이트: 체인 대상 리전 모든 섹터에 금색 2px 테두리 + "체인" 마이크로 배지
- ActivityLog 4종 신규 아이콘 매핑: 🗺️ regionTransform / ⛓️ chainProgressed / ⛓️(굵음) chainCompleted / 🛤️ travelChoiceCompleted
- AppTheme `chainGold`(`#D4AF37`) 신규, `transformVillage/Ruins/Hidden` + `eliteAccent/UniqueAccent` 명세 색상으로 갱신
- 신규 Hive 박스 `dialogQueue`(typeId 15) — 빌드 후 첫 실행 시 자동 생성
