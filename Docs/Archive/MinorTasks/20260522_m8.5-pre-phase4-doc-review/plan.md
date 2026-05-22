# m8.5-pre-phase4-doc-review 수정 내역

Skill used : finalize-minor-task

## 변경 파일 목록

| 파일 | 변경 유형 | 설명 |
| --- | --- | --- |
| `Docs/milestone-runs/M8.5/state.md` | 수정 | M8.5 페이즈 1~3 실행 상태와 페이즈 4 입력 의존성을 최신화 |
| `Docs/content-design/[content]20260520_m8.5_livingsphere_dashboard.md` | 신규 | 생활권 완성도 대시보드 컨셉 문서 추가 |
| `Docs/content-design/[content]20260521_m8.5_flagship_solo_quests.md` | 신규 | 간판 용병 솔로/소수정예 의뢰 컨셉 문서 추가 |
| `Docs/content-design/[content]20260521_m8.5_combat_emotional_reactions.md` | 신규 | 전투 감정 반응 컨셉 문서 추가 |
| `Docs/content-design/[content]20260521_m8.5_hidden_stats.md` | 신규 | 히든 스탯 해금 컨셉 문서 추가 |
| `Docs/content-design/[content]20260521_m8.5_battle_memory.md` | 신규 | 용병 전투 기억 컨셉 문서 추가 |
| `Docs/content-design/[content]20260521_m8.5_weekly_contribution_ranking.md` | 신규 | 주간 기여도 랭킹 컨셉 문서 추가 |
| `Docs/balance-design/[balance]20260521_m8.5_livingsphere_metrics.md` | 신규 | 생활권 완성도 지표 수치화 문서 추가 |
| `Docs/balance-design/[balance]20260521_m8.5_flagship_solo_quest_balance.md` | 신규 | 간판 용병 의뢰 보상·난이도 밸런스 문서 추가 |
| `Docs/balance-design/[balance]20260521_m8.5_emotional_reaction_values.md` | 신규 | 감정 반응 상태 수치 문서 추가 |
| `Docs/balance-design/[balance]20260522_m8.5_hidden_stat_values.md` | 신규 | 히든 스탯 효과 수치와 해금 임계값 문서 추가 |
| `Docs/balance-design/[balance]20260522_m8.5_weekly_contribution_values.md` | 신규 | 주간 기여도 점수 산식 수치 문서 추가 |
| `Docs/content-data/[data]20260522_m8.5_weekly_contributions_sql.md` | 신규 | 주간 기여도 Supabase 마이그레이션 SQL 문서 추가 |
| `Docs/Archive/MinorTasks/20260522_m8.5-pre-phase4-doc-review/plan.md` | 신규 | 이번 문서 보완 및 커밋 기록 추가 |
| `Docs/changelog-fragments/20260522_m8.5-pre-phase4-doc-review.md` | 신규 | 변경 로그 fragment 추가 |

## 수정 내용

- M8.5 페이즈 1~3 컨텐츠 설계, 밸런스 확정, 데이터 생성 산출물을 문서로 추가한다.
- 페이즈 4 진입 전 리뷰에서 발견한 `UserData` HiveField 충돌을 문서상에서 해소한다.
  - 생활권 목표 핀은 HiveField 28~29를 사용한다.
  - 주간 기여도 점수 버퍼는 HiveField 30~33을 사용한다.
- `CombatSimulationResult.weeklyContributionDelta`를 HiveField 15로 예약하고, HiveField 13~14가 히든 스탯·전투 기억에 사용됨을 명시한다.
- `battle_memory_templates` 30행 시드를 페이즈 4 #3 입력에 포함하도록 상태 문서를 보완한다.
- 이미지 에셋 메타데이터는 페이즈 3 산출물이 아니라 페이즈 4 #5 UI 스펙에 통합 위임하도록 문서를 정정한다.

## 수정 사유

- 페이즈 4 개발 명세 작성 전에 M8.5 기획·밸런스·데이터 산출물의 의존성과 영속 필드 번호를 정리해야 한다.
- HiveField 번호가 중복된 상태로 spec-writer 또는 implement 단계에 진입하면 저장 데이터 호환성 문제가 발생할 수 있다.
- 전투 기억 템플릿과 주간 기여도 delta의 입력 경로가 누락되면 페이즈 4 명세가 불완전해진다.

## 특이사항

- 코드 변경은 없다.
- Flutter/Dart 모델을 수정하지 않았으므로 `build_runner` 재실행은 필요하지 않다.
- 검증은 문서 diff 기준으로 수행한다.
