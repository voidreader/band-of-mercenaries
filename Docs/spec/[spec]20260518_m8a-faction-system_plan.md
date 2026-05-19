# M8a 세력 접촉점·상점·지명 의뢰 시스템 구현 계획 및 결과

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260518_m8a-faction-system.md`
> 실행 일자: 2026-05-18
> 실행 모드: PHASE 2 순차 격리 (21 TASK ≥ 5)
> 검증 모드: PHASE 3 순차 격리 final integration sanity check

## 실행 요약

- 명세서 영향 범위(수정 14 + 신규 16 = 30 파일)에 PHASE 2.5 dart-build-resolver의 외과적 수정 5 파일을 더해 총 **35 파일** 변경.
- planner 계획 21 TASK 모두 verifier+flutter-reviewer two-stage review 통과 (with warnings 2건 보정 적용).
- 빌드 게이트 dart-build-resolver 1회 호출로 13 error → 0 error.
- 전체 테스트 568개 PASS, `flutter analyze` 0 issues, `build_runner build` 정상 완료.

## 변경 파일 목록 (35 파일)

### 신규 16 파일

| 경로 | 역할 |
|------|------|
| `band_of_mercenaries/lib/features/info/domain/faction_contact_data.dart` | FactionContact freezed 모델 (FR-A1) |
| `band_of_mercenaries/lib/features/info/domain/faction_reaction_data.dart` | FactionReaction freezed 모델 (FR-A2) |
| `band_of_mercenaries/lib/features/info/domain/faction_shop_item_data.dart` | FactionShopItem freezed 모델 (FR-D1) |
| `band_of_mercenaries/lib/features/info/domain/faction_shop_daily_entry.dart` | Hive 모델 typeId 20 (FR-D4) |
| `band_of_mercenaries/lib/features/info/domain/faction_contact_service.dart` | 접촉점 활성 평가 헬퍼 (FR-A3) — `isActive(WidgetRef)` + `isActiveFromProviderRef(Ref)` 오버로드 |
| `band_of_mercenaries/lib/features/info/domain/faction_relation_stage.dart` | enum 7종 + resolve (FR-A4) |
| `band_of_mercenaries/lib/features/info/domain/faction_reaction_picker.dart` | 가중 random + 범위 파서 (FR-A5) |
| `band_of_mercenaries/lib/features/info/domain/faction_shop_unlock_result.dart` | sealed 3 case (FR-D2) |
| `band_of_mercenaries/lib/features/info/domain/faction_shop_service.dart` | evaluateUnlock 6단계 + purchase 5단계 (FR-D2/D3) |
| `band_of_mercenaries/lib/features/info/domain/faction_reward_service.dart` | 정적 상수 Map 2 entry + grant trailing (FR-E5) |
| `band_of_mercenaries/lib/features/info/domain/faction_contact_arrived_event.dart` | freezed event + StateProvider (FR-A6) |
| `band_of_mercenaries/lib/features/info/view/faction_contact_section.dart` | 접촉점 카드 섹션 (FR-G1) |
| `band_of_mercenaries/lib/features/info/view/faction_named_quest_section.dart` | 세력 지명 의뢰 섹션 (FR-G1) |
| `band_of_mercenaries/lib/features/info/view/faction_shop_section.dart` | 상점 섹션 + _ShopItemRow (FR-G1) |
| `band_of_mercenaries/lib/features/info/view/faction_contact_arrived_dialog.dart` | 접촉점 도착 다이얼로그 (FR-G2) |
| `band_of_mercenaries/lib/features/quest/domain/named_hook_context_builder.dart` | NamedHookContextBuilder.build(WidgetRef) (FR-B2) |

### 수정 14 파일

| 경로 | 핵심 변경 |
|------|----------|
| `lib/core/data/sync_service.dart` | allTables 32→35 (faction_contacts/_reactions/_shop_items) |
| `lib/core/providers/static_data_provider.dart` | 필드 3 + 생성자 required 3 + loadFromCache 3 |
| `lib/features/info/domain/faction_state_model.dart` | HiveField 6/7/8/9 nullable + effective getter 4종 |
| `lib/features/info/data/faction_state_repository.dart` | recordShopPurchase / markRewardGranted / hasGrantedReward / markContactUnlocked / hasContactUnlocked 5 메서드 |
| `lib/core/data/hive_initializer.dart` | FactionShopDailyEntryAdapter 등록 |
| `lib/core/domain/activity_log_model.dart` | enum HiveField 35~38 (4 case) |
| `lib/features/quest/domain/named_hook_evaluator.dart` | NamedHookContext 신규 3 필드 + switch 3 case (region_flag/faction_contact/faction_reputation) |
| `lib/features/quest/domain/quest_generator.dart` | generateQuests 시그니처 +2 optional 인자 + NamedHookContext 채움 + factionTag 보존 |
| `lib/features/quest/domain/quest_provider.dart` | `_buildHookFieldsForGenerator` inline 헬퍼 + 3 호출점 unlockedRegionFlags/activeContactIds 전달 + `_applyCompletionResult` trailing hook (oldRep/newRep + 3 fail-soft hook) |
| `lib/features/quest/domain/quest_completion_service.dart` | factionRepGain 분기 교체 (faction_named 우선) + combatReportEligible 필드 |
| `lib/features/crafting/domain/crafting_service.dart` | 생성자 DI 2 + _isUnlockedM7 switch case 2 (factionReputation/factionContact) |
| `lib/features/crafting/domain/crafting_provider.dart` | craftingServiceProvider 신규 2 인자 주입 |
| `lib/features/title/domain/title_service.dart` | evaluateFactionReputationHook 신규 메서드 |
| `lib/features/info/view/faction_detail_screen.dart` | 3 섹션 import + 활동 티어 다음 삽입 |
| `lib/features/info/view/faction_codex_screen.dart` | _FactionCard ConsumerWidget + 분홍 dot + staticData/bandAchievements watch |
| `lib/core/providers/dialog_queue_provider.dart` | DialogTypeRegistry.factionContactArrived 키 + keys Set + _restoredMessage |
| `lib/app.dart` | factionContactArrivedProvider ref.listen + initState/resumed hook |

### dart-build-resolver 외과적 수정 5 파일 (PHASE 2.5)

| 경로 | 수정 |
|------|------|
| `lib/features/home/view/home_screen.dart` | ActivityLogType switch에 신규 4 case 추가 (icon 매핑) |
| `test/features/inventory/view/inventory_screen_test.dart` | StaticGameData 생성자에 factionContacts/Reactions/ShopItems = const [] 3 인자 |
| `test/features/quest/domain/quest_completion_service_test.dart` | 동일 3 인자 |
| `test/features/quest/domain/quest_narrative_render_test.dart` | 동일 3 인자 |
| `test/features/quest/domain/special_flag_processor_test.dart` | 동일 3 인자 |

## TASK 진행 및 검증 결과

| TASK | 복잡도 | 모델 | verifier | flutter-reviewer | 비고 |
|------|--------|------|----------|----------------|------|
| TASK-1 ActivityLogType enum | mechanical | haiku | PASS | APPROVE | — |
| TASK-2 FactionShopDailyEntry | mechanical | haiku | PASS | APPROVE | typeId 20 신규 |
| TASK-3 FactionState 확장 | integration | sonnet | PASS | APPROVE | HiveField 6/7/8/9 |
| TASK-4 hive_initializer 어댑터 | mechanical | haiku | PASS | APPROVE | — |
| TASK-5 정적 데이터 3종 + 동기화 | integration | sonnet | PASS | APPROVE | — |
| TASK-6 Repository 5 메서드 | integration | sonnet | PASS | APPROVE | — |
| TASK-7 도메인 헬퍼 4종 | integration | sonnet | PASS | APPROVE | — |
| TASK-8 FactionShopService | integration | sonnet | PASS | BLOCK→APPROVE | 6 이슈 중 4(WidgetRef/StateError/reason 문자열/테스트)는 명세 의도라 미반영, ISSUE-4(bang)/ISSUE-6(format) 보정 |
| TASK-9 FactionRewardService | integration | sonnet | PASS | APPROVE | Q-2 default 정적 Map 하드코딩 |
| TASK-10 NamedHookEvaluator 확장 | integration | sonnet | PASS | APPROVE | 3 hook + 3 신규 필드 |
| TASK-11 NamedHookContextBuilder | integration | sonnet | PASS | APPROVE | — |
| TASK-12 QuestGenerator 확장 | integration | sonnet | PASS | APPROVE | factionTag 보존 + 신규 3 필드 |
| TASK-13 quest_provider 통합 | architecture | opus | PASS | APPROVE(with warnings) | medium ISSUE-1(한국어 명칭) 보정. ISSUE-2/3(테스트/dead code)는 미반영 |
| TASK-14 QuestCompletionService 분기 | integration | sonnet | PASS | APPROVE | — |
| TASK-15 TitleService faction hook | integration | sonnet | PASS | APPROVE | 12 기존 테스트 모두 통과 |
| TASK-16 CraftingService DI + case | integration | sonnet | PASS | APPROVE | FactionContactService.isActiveFromProviderRef 오버로드 추가 |
| TASK-17 Event + DialogTypeRegistry | integration | sonnet | PASS | APPROVE | — |
| TASK-18 FactionContactArrivedDialog | mechanical | haiku | PASS | APPROVE | — |
| TASK-19 app.dart 통합 | integration | sonnet | PASS | APPROVE | — |
| TASK-20 FactionDetail 3 섹션 | integration | sonnet | PASS | APPROVE(with warnings) | medium ISSUE-1(Random 정적 필드) 보정 |
| TASK-21 FactionCodex 분홍 dot | mechanical | haiku | PASS | APPROVE(with warnings) | medium ISSUE-1(부모 watch 추가) 보정 |

## 명세 의도 명시 보존 (반영하지 않은 reviewer 이슈)

다음 이슈들은 명세서 또는 planner Q-default가 명시적으로 지시한 설계 결정이므로 반영하지 않고 보존했다. 후속 명세에서 재검토 가능.

- **TASK-8 ISSUE-1 (WidgetRef 도메인 의존)**: 명세서 FR-A3/A4/A5/D2/D3/E5가 `WidgetRef ref` 매개변수를 명시적으로 사용. 모든 신규 도메인 헬퍼가 이 패턴을 일관 사용한다.
- **TASK-8 ISSUE-2 (StateError 흐름 제어)**: 명세서 FR-D3 "evaluateUnlock Ready 확인. 아니면 StateError. 골드 부족 시 StateError('insufficient_gold')" 명시.
- **TASK-8 ISSUE-3 (reason 문자열 매직 스트링)**: 명세서 FR-D2가 `'not_joined'`, `'reputation:{n}'`, `'contact:{value}'`, `'region_flag:{flag}'` 형식을 정확히 명시.
- **TASK-8 ISSUE-5 / TASK-13 ISSUE-2 (도메인 서비스 unit test 미동반)**: planner Q-3 default 결정에서 "수정만 진행, 신규 테스트 추가는 별도 작업"으로 사용자 승인.
- **TASK-13 ISSUE-3 (factionRewardServiceProvider Helper 미사용)**: low 이슈. 향후 UI 직접 호출용으로 유지. 명세 외 정리는 별도 작업.

## PHASE 2.5 빌드 게이트 결과

| 명령 | 결과 |
|------|------|
| `dart run build_runner build --delete-conflicting-outputs` | PASS (146 actions, 0 outputs after final caching) |
| `flutter analyze` (전체) | 초기 13 errors → dart-build-resolver 호출 → **0 issues** |
| `flutter test` (전체) | 568 tests PASS |

build_runner 재생성 대상: faction_contact_data / faction_reaction_data / faction_shop_item_data / faction_shop_daily_entry / faction_state_model / activity_log_model / faction_contact_arrived_event (각 `.freezed.dart` / `.g.dart`).

## CLAUDE.md 금지사항 위반

위반 없음. 모든 변경이 다음 정책을 준수:
- Navigator.push 사용 금지 — 상태 기반 렌더링 (FactionContactArrivedDialog는 dialogQueue + scrollTarget)
- HiveField 번호 시프트 금지 — FactionState 0~5 보존, 신규 6/7/8/9만 추가
- typeId 충돌 금지 — 20 신규 점유 (12 보존 유지)
- 한국어 스타일 유지 — 모든 코멘트/ActivityLog 메시지 한국어
- 코멘트 정책 — WHY 코멘트 위주, 신규 FR 번호 명시

## 다음 단계

본 명세는 페이즈 4 #1 단독. 다음 산출물은 별도 명세:

- **페이즈 4 #2** 전투 보고서 저장 모델/서비스/UI 명세 — 본 명세의 `combatReportEligible` 메타가 입력
- **페이즈 4 #3** 정적 데이터 스키마 SQL/operation-bom 편집 — `faction_contacts`/`faction_reactions`/`faction_shop_items` 3 테이블 신설 + `quest_pools` 12행 + `items` 4행 + `crafting_recipes` 2행 + `titles` 2행 + `titles.hook_type` CHECK 확장
- **페이즈 4 #4** 통합 구현 명세 + 검증 계획

## 워크플로우 안내

본 스킬은 git commit과 문서 아카이브를 수행하지 않는다. 커밋과 아카이브가 필요하면 `finalize-feature` 스킬을 실행하라.

- 변경 35 파일 (위 표 참고)
- build_runner 재실행: **이미 수행 완료** (PHASE 2.5)
- 산출물 문서: `Docs/spec/[spec]20260518_m8a-faction-system_plan.md` (본 파일)
