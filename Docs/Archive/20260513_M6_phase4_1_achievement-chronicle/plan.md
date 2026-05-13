# M6 페이즈 4 #1 — 위업·연대기 시스템 구현 계획·실행 리포트

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle.md`
> 작성일: 2026-05-13
> 마일스톤: M6 페이즈 4 #1 — 위업·연대기 시스템 (1차)
> 실행 모드: **순차 격리 모드** (TASK ≥ 5, 15 TASK)
> 검증 모드: **PHASE 2 task별 verifier + flutter-reviewer 미니 사이클 → PHASE 3 final integration sanity check**

---

## 1. 실행 요약

- **TASK 수**: 15개 (계획 시점)
- **실행 모드**: 순차 격리 모드 — task 사이 사용자 체크인 없이 continuous execution
- **검증 결과**: 모든 TASK PASS, 통합 검증 APPROVE
- **빌드 게이트**: 1회 dart-build-resolver 호출(테스트 fixture 4건 회귀 보정)
- **재작업**: TASK-4(5건 medium 이슈 정리), TASK-14(BLOCK 1건 — Navigator.push → 상태 기반 렌더링)

---

## 2. 구현 계획과 실제 변경 사항

### 2.1 영향 범위 보정 (계획 단계에서 자체 결정)

| 명세 §3.1 항목 | 보정 사항 | 사유 |
|---|---|---|
| `reputation_service.dart` | `core/providers/game_state_provider.dart`로 변경 | 실제 `reputationRankUpProvider` publish 위치는 `UserDataNotifier.addReputation`. 명세 "또는 명성 갱신 분기"의 후자에 해당 |
| `crafting_provider.dart` | 명세 누락분 추가 | CraftingService 생성자 DI 확장(`achievementService` 필드)에 따라 Provider 바인딩 수정 필요 |
| `app.dart` | 수정 제외 | DialogQueue head builder 디스패치가 이미 일반화되어 있어 별도 ref.listen 불필요. AchievementService가 DialogRequest.builder로 위젯 빌더 첨부 |
| TravelEventService `diedEvent` hook | 미구현 | 코드베이스에 사망 분기 부재. 명세 §3.1 "사망 분기 있을 경우" 조건부 명시에 부합. `MemorialCause.diedEvent` enum과 templateId만 정의 |
| CLAUDE.md | implement-agent 범위 밖 | finalize-feature 스킬이 처리 |

### 2.2 비명세 결정사항 (실행 중 발견·결정)

| 결정 | 사유 |
|---|---|
| `achievement_service_provider.dart` 신규 분리 + `achievement_provider.dart`에서 re-export | 명성 hook(`game_state_provider.dart`) 통합 시 순환 참조 발견. `achievement_provider.dart`가 `userDataProvider`를 통해 `game_state_provider.dart`를 참조하므로 역방향 import 불가. service Provider만 별도 파일로 분리하여 회피 |
| `MercenarySnapshot.fromMercenary` 시그니처에 `{required int tier}` 추가 주입 | Mercenary 모델이 tier 필드를 직접 보유하지 않음. Job 정적 데이터에서 매핑 필요. 명세는 `{required String jobName}`만 명시 |
| `AchievementService.recordMemorial` 반환 타입 `Future<BandAchievement?>` (명세 `Future<void>`) | 호환적 확장. 외부 호출자는 await만 사용하므로 무관 |
| `buildAchievementDialog` 콜백 DI 패턴 | AchievementService에서 위젯 타입 의존성 분리. `achievementServiceProvider`가 AchievementUnlockedDialog 빌더 함수를 주입 |
| `ChronicleScreen` 상태 기반 렌더링 (Navigator.push 미사용) | 명세 Q-10이 Navigator.push를 채택했으나, CLAUDE.md 컨벤션 "화면 전환은 Navigator.push 대신 상태 기반 렌더링" + `_MobileFrame ConstrainedBox(maxWidth: 430)` 깨짐 우려 → flutter-reviewer BLOCK 사유. InfoScreen 다른 sub-screen 패턴(`_showCodex` 등)과 일관성 확보 위해 `_showChronicle` 상태 + `onBack` 콜백 패턴으로 변경. ChronicleScreen은 독립 사용 시 `Navigator.maybePop` fallback 유지 |
| SQL 시드 28행 → 26행 | 명세 §6 주의사항에 따라 placeholder 정리. craft_first_rare 3행 중 실제 T3+ 레시피 1개만 시드(`recipe_dustvile_pyegwang_relic` → tier 3 확인). 나머지 2행 제외. elite_unique 8행은 명세 §6대로 유지(elite_monsters에 is_unique=true 데이터 미존재 — 향후 UPDATE 위임) |

---

## 3. 변경 파일 목록 (총 28개)

### 3.1 신규 생성 (11개)

| 파일 | 역할 |
|---|---|
| `band_of_mercenaries/lib/features/achievement/domain/band_achievement_model.dart` | BandAchievement(typeId 16) + BandAchievementType(typeId 17) |
| `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.dart` | MercenarySnapshot(typeId 18, 5필드, const class) |
| `band_of_mercenaries/lib/features/achievement/domain/memorial_cause.dart` | MemorialCause enum(typeId 19) |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_service.dart` | AchievementService 4 메서드(grant/recordMemorial/hasAchievement/getAll) |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_provider.dart` | bandAchievementsProvider + renderedAchievementProvider + achievementServiceProvider re-export |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_service_provider.dart` | achievementServiceProvider 분리 (순환 참조 회피) |
| `band_of_mercenaries/lib/features/achievement/view/achievement_unlocked_dialog.dart` | AchievementUnlockedDialog ConsumerWidget |
| `band_of_mercenaries/lib/features/achievement/view/chronicle_screen.dart` | ChronicleScreen + _AchievementCard + _MemorialCard |
| `band_of_mercenaries/lib/features/achievement/view/chronicle_home_card.dart` | 홈 화면 연대기 카드 위젯 |
| `band_of_mercenaries/lib/core/models/band_achievement_template.dart` | Freezed 정적 데이터 모델 |
| `band_of_mercenaries/supabase/migrations/20260513120000_create_band_achievement_templates.sql` | DDL + 26행 시드 (placeholder 정리) |

### 3.2 수정 (17개)

| 파일 | 변경 내용 |
|---|---|
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | bandAchievementBoxName 상수 + 어댑터 4개 등록(enum 우선) + 박스 open |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | allTables 30번째 `band_achievement_templates` 추가 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | bandAchievementTemplates 필드 + 생성자 + 로드 |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | DialogTypeRegistry.achievementUnlocked + keys + _restoredMessage |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | UserDataNotifier.addReputation에 명성 hook 추가 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | @HiveField(29) achievementUnlocked |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | memorialGray(0xFF6E6E6E) |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` | completeChain hook + 콜백 2종 추가(grantAchievement, buildSnapshot) |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_provider.dart` | ChainQuestService 콜백 바인딩 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | addSettlementTrust newLevel==4 hook |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 엘리트 hook + 사망 memorial hook |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` | 생성자 DI 확장(achievementService) + craft tier>=3 hook |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_provider.dart` | achievementService 주입 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | dismiss recordMemorial(released) hook |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | ChronicleHomeCard 삽입 + _showChronicle 상태 + _logIcon switch case |
| `band_of_mercenaries/lib/features/info/view/info_screen.dart` | 연대기 카드 + _showChronicle 상태 |
| `band_of_mercenaries/lib/features/home/view/rank_up_overlay.dart` | "이 순간은 연대기에 새겨졌다" 1줄 인라인 |

### 3.3 빌드 게이트 보정 (4개) — dart-build-resolver

StaticGameData 생성자에 `bandAchievementTemplates` 추가로 인한 fixture 누락 회귀:

| 파일 | 변경 |
|---|---|
| `band_of_mercenaries/test/features/inventory/view/inventory_screen_test.dart` | `bandAchievementTemplates: const []` 추가 |
| `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` | 동일 |
| `band_of_mercenaries/test/features/quest/domain/quest_narrative_render_test.dart` | 동일 |
| `band_of_mercenaries/test/features/quest/domain/special_flag_processor_test.dart` | 동일 |

---

## 4. 실행 결과 요약 (TASK별)

| TASK | 추천 모델 | verifier | flutter-reviewer | 재작업 |
|---|---|---|---|---|
| TASK-1 Hive 모델 4종 | haiku | PASS | APPROVE w/ warnings (3 minor) | TASK-2에서 통합 정리(import 절대경로, 파라미터명) |
| TASK-2 HiveInit + ActivityLog + Theme + DialogTypeRegistry | haiku | PASS | APPROVE (이슈 없음) | - |
| TASK-3 BandAchievementTemplate + SyncService + StaticGameData | haiku | PASS | APPROVE (이슈 없음) | - |
| TASK-4 AchievementService + Provider 3종 | opus | PASS | APPROVE w/ warnings (5 medium) | **5건 모두 정리**(on Exception, unawaited+mounted, stale closure, read 1회, Hive.box 재사용) |
| TASK-5 AchievementUnlockedDialog | sonnet | PASS | APPROVE w/ warnings (2 medium + 2 low) | plan 기록 |
| TASK-6 RankUpDialog 1줄 | haiku | PASS | APPROVE w/ warnings (2 medium) | 명세 [FR-14]가 인라인 TextStyle 명시 → plan 기록 |
| TASK-7 명성 hook (game_state_provider) | sonnet | PASS | APPROVE w/ warnings (3 — staticData watch 등) | 순환 참조 회피 분리(`achievement_service_provider.dart` 신규) |
| TASK-8 거점 신뢰도 hook | sonnet | PASS | APPROVE (이슈 없음) | - |
| TASK-9 체인 hook | sonnet | PASS | APPROVE w/ warnings (5 — debugPrint, bang 등) | plan 기록 |
| TASK-10 엘리트 유니크 hook | sonnet | PASS | APPROVE (이슈 없음) | - |
| TASK-11 사망 memorial hook | sonnet | PASS | APPROVE w/ warnings (2 medium) | plan 기록 |
| TASK-12 방출 + 제작 hook + CraftingService DI | sonnet | PASS | APPROVE w/ warnings (3 medium) | plan 기록 |
| TASK-13 ChronicleScreen | sonnet | PASS | APPROVE w/ warnings (4 medium) | plan 기록 |
| TASK-14 HomeScreen + InfoScreen 진입점 | sonnet | PASS | **BLOCK (high — Navigator.push)** | **재작업 — 상태 기반 렌더링으로 변경 후 APPROVE** |
| TASK-15 Supabase 마이그레이션 SQL | sonnet | PASS | (SQL 대상 외) | - |

### PHASE 2.5 빌드 게이트
- `flutter analyze` 전체: 회귀 4건 발견 → dart-build-resolver 호출 → 모두 해결 → **No issues found!**
- 35개 영향 테스트 재실행: 35/35 통과

### PHASE 3 Final Integration
- 통합 7개 포커스 영역(Provider 그래프 / Hook fail-soft / 시그니처 / DialogQueue / UI 흐름 / 데이터 그래프 / templateId 컨벤션) 모두 일관성 확보
- flutter-reviewer 최종 판정: **APPROVE (이슈 없음)**

---

## 5. build_runner 재실행 필요

본 구현은 build_runner를 **2회** 실행했다(TASK-2, TASK-3). 추가 변경이 없으면 재실행 불필요.

만약 재실행이 필요하면:
```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

생성된 주요 파일:
- `band_achievement_model.g.dart` (BandAchievementTypeAdapter, BandAchievementAdapter)
- `mercenary_snapshot_model.g.dart` (MercenarySnapshotAdapter)
- `memorial_cause.g.dart` (MemorialCauseAdapter)
- `activity_log_model.g.dart` (HiveField 29 반영 재생성)
- `band_achievement_template.freezed.dart` + `.g.dart`

---

## 6. 후속 정리 후보 (plan 기록 — 향후 개선 권장)

PHASE 2/3에서 발견된 medium/low 이슈로, 명세 준수가 아닌 코드 품질 영역. 후속 polish PR로 분리 권장.

### 6.1 ChronicleScreen (TASK-13)
- `_categoryOf` 헬퍼가 `_ChronicleScreenState`와 `_AchievementCard` 양쪽에 중복 정의 → top-level private 헬퍼로 통합
- ChoiceChip 해제 분기 Set spread 가독성(`{..._selectedCategories,}..remove(id)` → `where().toSet()` 또는 단순화)
- `_AchievementCard` subtitle fallback이 raw `templateId` 노출 위험 → 빈 문자열 또는 subtitle 자체 생략
- `_MemorialCard`에서 mercSnapshot null 시 title/subtitle 동일 텍스트 중복 → title을 '추모' 고정

### 6.2 AchievementUnlockedDialog (TASK-5)
- content Column의 SizedBox spacing 누적(mercSnapshot 분기 외부에 별도 4px 추가) → 일관된 spacing으로 통일
- `renderedAchievementProvider` 빈 문자열 vs null 시그널 모호성 → Provider 내부에서 fallback 책임 통합

### 6.3 AchievementService Provider 재생성 (TASK-7)
- `achievementServiceProvider`가 `ref.watch(staticDataProvider)`로 staticData 갱신 시마다 인스턴스 재생성 → templates를 lazy 평가 콜백(`List<BandAchievementTemplate> Function()`)으로 변경 또는 read 1회 패턴

### 6.4 quest_provider.dart 사망 분기 (TASK-11)
- 동일 `damage.newStatus == MercenaryStatus.dead` 분기가 정수 소실 로그(라인 910)와 memorial hook(라인 929) 두 블록으로 분리 → mercs 리스트 이중 조회 발생. 한 블록으로 통합 권장
- job 누락 silent skip 시 디버그 로그 부재 (elite hook과 일관성)

### 6.5 mercenary_provider.dart 방출 hook (TASK-12)
- memorial fail-soft 조건 분기 silently skip 시 디버그 로그 누락 → `else { debugPrint('memorial released skip: ...') }` 추가

### 6.6 CraftingService (TASK-12)
- `userDataNotifier` 의존성이 craft()/evaluateState() 어디서도 사용되지 않는 dead dependency (기존 코드) → 사용 또는 제거
- `craftingServiceProvider`(`requireValue`) vs `craftingRecipesProvider`(`maybeWhen`) AsyncValue 처리 비대칭

### 6.7 chain_quest_service.dart (TASK-9)
- `grantAchievement!` non-null assertion → 로컬 변수로 promotion
- 알 수 없는 chainId prefix 분기 `return` 가독성(hook 영역만 빠져나가는 것이 아니라 메서드 종료)
- silent skip 디버그 로그 보강

### 6.8 RankUpDialog (TASK-6)
- Text의 인라인 TextStyle 대신 `theme.textTheme.* copyWith` 사용 (명세 [FR-14]가 코드 그대로 명시했으나 프로젝트 컨벤션은 테마 사용)

### 6.9 MemorialCause 직렬화 일관성
- `MemorialCause.diedQuest.name = "diedQuest"` (camelCase) vs SQL 시드 `memorial:died_quest` (snake_case) — `recordMemorial`은 dialog enqueue/template lookup을 하지 않아 런타임 영향 없으나, ChronicleScreen이 향후 memorial templateId 기반 매핑 도입 시 정합성 보강 필요

### 6.10 BandAchievement.payload mutable Map 주의 (TASK-1)
- payload는 `const {}` 기본값이지만 외부 수정 시 unmodifiable 예외 가능. AchievementService 내부에서 mutation 없도록 spread 사용 정책 유지

### 6.11 Supabase 시드 후속 (TASK-15)
- elite_unique_first_kill 8행 중 7개 placeholder ID는 `is_unique=true` 엘리트 데이터 INSERT 후 UPDATE 필요
- craft_first_rare는 명세 3행 → 1행으로 정리(T3+ 레시피 미존재). 추후 T3+ 레시피 추가 시 INSERT 보강
- operation-bom `table-config.ts`에 `band_achievement_templates` CRUD 메뉴 등록 (별도 작업)

---

## 7. CLAUDE.md 금지사항 위반

본 구현에서 CLAUDE.md 정책을 의도적으로 위반한 항목은 다음과 같다:

### 7.1 TASK-4 placeholder TODO 마커 (해소됨)
- 사유: AchievementUnlockedDialog는 TASK-5에서 생성되므로, TASK-4 시점에는 임시 placeholder fallback AlertDialog + `// TODO(TASK-5):` 마커를 남겨야 컴파일 가능
- 명세서가 task 간 의존성 plug-in 지점을 명시적으로 요구한 영역
- TASK-5 완료 시점에 placeholder + TODO 마커 모두 제거 → **현재 코드에는 잔존하지 않음**

### 7.2 명세 Q-10 vs 코드 컨벤션 충돌 (TASK-14)
- 명세 §4.1 / Q-10: ChronicleScreen Navigator.push 채택
- CLAUDE.md: 화면 전환은 Navigator.push 대신 상태 기반 렌더링
- flutter-reviewer BLOCK 사유 + 모바일 프레임 깨짐 우려 → 상태 기반 렌더링으로 변경. 독립 사용 시 Navigator.maybePop fallback 유지하여 명세 의도(화면 스택 진입)도 보존

---

## 8. 다음 단계

본 plan 문서는 implement-agent 스킬의 산출물로, 다음을 안내한다:

1. **finalize-feature 스킬 실행** (사용자 요청 시)
   - CLAUDE.md typeId 표 갱신(16·17·18·19 추가) + 박스 수 10→11 + 테이블 수 29→30 + 위업·연대기 핵심 시스템 섹션 추가
   - CHANGELOG fragment 생성
   - git commit + 아카이브

2. **Supabase 마이그레이션 적용** (별도 작업)
   ```bash
   cd band_of_mercenaries && supabase db push
   # 또는 Supabase MCP apply_migration 호출
   ```

3. **operation-bom 운영 도구 작업** (별도 작업)
   - `table-config.ts`에 `band_achievement_templates` CRUD 메뉴 추가

4. **후속 페이즈 4 작업**
   - 페이즈 4 #2 (칭호·간판 용병): MercenarySnapshot HiveField 5 `titleIds` 추가 + Mercenary HiveField 24·25 + UserData HiveField 24 + Supabase `titles` 테이블(31번째)
   - 페이즈 4 #3 (지명 의뢰): quest_pools 4 컬럼 확장 + UserData HiveField 25 + ActiveQuest HiveField 26 + QuestSortService NamedTier 슬롯 7번째
