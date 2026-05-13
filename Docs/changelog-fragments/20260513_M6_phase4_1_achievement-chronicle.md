### M6 페이즈 4 #1 — 위업·연대기 시스템

- 용병단의 영구 기록을 추적하는 위업·연대기 시스템 신규 도입. 7 카테고리(체인 완주 / 거점 사건 / 거점 신뢰도 4단계 / 명성 등급 / 엘리트 유니크 첫 처치 / 희귀 첫 제작 / 추모) 단일 인터페이스로 통합.
- 6 hook 자동 통합: 체인 완주(`ChainQuestService.completeChain`) · 거점 신뢰도 4단계(`RegionStateRepository.addSettlementTrust`) · 명성 등급 진입(`UserDataNotifier.addReputation`) · 엘리트 유니크 첫 처치(`quest_provider._applyCompletionResult`) · T3+ 첫 제작(`CraftingService.craft`) · 사망/방출 memorial(`quest_provider` dead 분기 + `MercenaryRepository.dismiss` 직전 snapshot 구성). 모두 fail-soft trailing side effect로 본 흐름과 격리.
- `AchievementUnlockedDialog` high priority 다이얼로그 신규 — 카테고리별 Material Icons + chainGold 강조 + TemplateEngine 렌더 description. `reputation_rank` 카테고리는 RankUpDialog 본체 인라인("✨ 이 순간은 연대기에 새겨졌다")으로 대체하여 dialog 폭주 방지.
- 신규 `ChronicleScreen` 영구 기록 화면 — ChoiceChip 7종 카테고리 필터(다중 선택) + 50개 페이징 + 카드 탭으로 dialog 재노출. HomeScreen 야영지 아래 연대기 카드(최근 1행 + 24시간 NEW 배지) + InfoScreen "용병단 연대기" 진입점 두 경로로 접근. 상태 기반 렌더링(`_showChronicle` + `onBack`) 적용.
- `MercenarySnapshot` 5필드(id/name/jobId/jobName/tier) 발급 시점 영속 보존 — 용병 사망·방출 이후에도 위업 카드/연대기 화면에 주인공 정보 유지. 페이즈 4 #2(칭호)에서 `titleIds` 필드 추가 호환 예정.
- Hive 신규 박스 `bandAchievements`(typeId 16~19 4종 어댑터) + Supabase 30번째 테이블 `band_achievement_templates`(26행 시드, 7 카테고리 CHECK + chronicle_variants JSONB + default_priority CHECK) + `ActivityLogType.achievementUnlocked` HiveField 29 + `AppTheme.memorialGray` 추가.
- 멱등성 보장: `AchievementService.hasAchievement(templateId)` 사전 체크로 6 hook 모두 일회성. memorial은 `(mercSnapshot.id, cause)` 조합으로 중복 차단.
