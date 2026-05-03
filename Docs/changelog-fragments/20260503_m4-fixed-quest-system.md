### M4 페이즈 4 #3: 고정 의뢰 시스템 + 더스트빌 허드렛일 풀 (페이즈 4 #5 stub 상태)

- `quest_pools` 테이블에 9개 컬럼 추가 — `is_fixed`/`fixed_chain_id`/`fixed_step`/`trust_threshold` (페이즈 1 #4) + `reward_gold_override`/`reward_xp_bonus_override`/`duration_override_seconds`/`trust_reward_override` (페이즈 2 #4 보상·시간 override) + `min_trust_level` (페이즈 2 #3 단계별 노출 제어). Partial UNIQUE 인덱스 `(fixed_chain_id, fixed_step) WHERE is_fixed = true`.
- "폐광길 재개방" 6단계 거점 사건 라인 데이터 추가 (`settlement_3_pyegwang_reopen`). explore → hunt → raid → escort → raid → survey 순, `trust_threshold` 1·1·2·2·3·3, `duration_override_seconds` 300·300·360·300·600·600, `trust_reward_override` 10·15·20·25·30·100, `reward_gold_override` step3 이후 200·185·270·500G, step6 `reward_xp_bonus_override` +50.
- 더스트빌 허드렛일 10건 (`dustvile_chore_NN`) 추가 — labor 6 + escort 1 + explore 2 + hunt 1, 모두 난이도 1, `min_region_diff=1`/`max_region_diff=1` (T1 한정). `dustvile_chore_03` 약초 채집 의뢰만 `min_trust_level=2`.
- `QuestPool` Freezed 모델 9개 필드 확장 + build_runner 재생성.
- `QuestGenerator.generateQuests`에 `currentTrustLevel` 파라미터 + `!isFixed` / `minTrustLevel <= currentTrustLevel` 필터 2개 추가.
- `QuestListNotifier`에 `_getCurrentTrustLevel` stub (페이즈 4 #5 연결용 0 fallback) + `_injectFixedSettlementQuest` (settlement_3_pyegwang_reopen 진행 조회 후 ActiveQuest 생성) + `refreshAvailableQuests` 공개 메서드 추가. `_checkQuestRefresh` / `_refreshExpiredQuests`에 `settlement_` prefix 만료 제외 분기.
- `ActiveQuest.isSettlementStep` getter 추가 (chainId? startsWith settlement_).
- `QuestSortService.QuestSortResult`에 `settlementTier` 신규 필드 + `chainTier0` 분류에서 settlement_ prefix 분리 + `sortedRest`는 `[...settlementTier, ...tier1~4]` 순서로 일반 목록 최상단 배치.
- `AppTheme.settlementAccent`(0xFFFFA000) 신규 색상 상수 — 변형 섹터 `transformVillage` 0xFF2E7D32 와 의미 충돌 회피.
- 파견 화면 `_QuestCard`에 "📜 마을 사건" 인라인 배지 추가 (`AppTheme.settlementAccent` 알파 0.15 배경 + 1px 테두리).
- Supabase 마이그레이션 SQL은 페이즈 4 #1·#2와 동일하게 보류 (옵션 B 연장, 페이즈 4 #4·#5 완료 후 일괄 적용). `_getCurrentTrustLevel() = 0` stub이라 `trust_threshold ≥ 1` 조건 실패 → 고정 의뢰 미노출 안전 fallback. 페이즈 4 #5에서 `RegionStateRepository.getSettlementTrust(regionId).level` 한 줄 교체로 활성화.
