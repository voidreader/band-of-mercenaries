### M8a 세력 수직 절편 — 접촉점·지명 의뢰·상점·전용 보상

- 모험가 길드·상인 연합·전사 길드 3 세력의 "접촉점 → 후원 → 가입 → 신뢰" 수직 절편 구현. 14세력 전체 확장 대신 대표 3 세력만 깊게 풀어냈다.
- 세력 상세 화면(`FactionDetailScreen`)에 접촉점·지명 의뢰·상점 3 신규 섹션 추가. 세력 도감 카드는 활성 접촉점 보유 시 분홍 dot으로 강조.
- `FactionRelationStage` 7단계(미접촉/주목/후원/가입/신뢰/핵심/적대) 동기 평가. `FactionContactArrivedDialog`(medium priority)로 신규 접촉점 발견 시 자동 알림.
- 세력 지명 의뢰 12개 추가 — `NamedHookEvaluator` 3 hook 확장(`region_flag` / `faction_contact` / `faction_reputation`)으로 위업·지역 상태·세력 평판 조건에 따라 발급.
- 세력 상점 18개 상품 — 평판 1/11/31/61 해금 + once/daily(24h 슬라이딩) 재고 정책 + material_bundle/recipe_key/consumable/equipment 4 카테고리.
- 세력 평판 31 도달 시 칭호 자동 발급(`길드 장부에 오른 자`·`결투 표식을 받은 자`). 평판 61 + region flag 시 아이템 보상 자동 1회 지급(`상단 보증서`·`붉은 창의 손목끈`).
- 세력 전용 레시피 2종 추가(`기록원의 나침반`·`교역 인장 장식`) — 제작 unlock 조건이 `factionReputation` + `regionFlag` 조합.
- `quest_pools` +12행 · `items` +17행(신규 4 + placeholder 13) · `crafting_recipes` +2 · `titles` +2 · `faction_contacts` 3 + `faction_reactions` 33 + `faction_shop_items` 18 신규 테이블.
- Hive 신규: `FactionShopDailyEntry` typeId 20, `FactionState` HiveField 6~9, `ActivityLogType` HiveField 35~38.
