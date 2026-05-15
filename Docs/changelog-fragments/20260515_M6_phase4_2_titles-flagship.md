### M6 페이즈 4 #2 — 칭호·간판 용병 시스템

- 칭호 시스템 추가 — 위업/행동지표/상태 hook 3종으로 자동 발급되는 11종 칭호 (마을의 은인·도적길 추적자·백전노장·정찰의 눈·호위의 노련함 등). 사망/방출 후에도 mercSnapshot에 영구 보존.
- 간판 용병 시스템 추가 — 5단계 정렬(칭호 수→위업 주인공→레벨→partyPower→가입 빠른 순)로 자동 선정. 홈 야영지 카드 노출 + 용병 상세에서 수동 지정 토글 (자동/수동 4상태 전환).
- 위업 발급 시 칭호 1줄 인라인 — AchievementUnlockedDialog 본체에 "칭호 획득" 1줄 통합 표시. (b)/(c) hook은 신규 TitleUnlockedDialog (high priority).
- 칭호 효과 — PassiveBonusService 통합 (mercenary 단위 자동 가산). questRewardMultiplier·mercenaryXpBonus 가산 상한 +0.30 명시.
- Supabase `titles` 테이블 신규 (31번째) + 11행 시드. 행동 지표 임계 페이즈 2 #1 결정값 반영(raid 20·dispatch 80·explore 15·escort 12).
- 페이즈 4 #1 `band_achievement_templates` 테이블 (30번째) + 26행 시드도 함께 적용.
- ActivityLog "칭호 획득" 항목 노출 (홈 활동 로그 + 연대기 ✩ 아이콘).
