# M6 페이즈 4 #2 — 칭호·간판 용병 시스템 구현 계획·결과 리포트

> Skill used: implement-agent
> 명세서: `Docs/spec/[spec]20260515_M6_phase4_2_titles-flagship.md` (70.5KB / 1080 lines)
> 작성일: 2026-05-15
> 실행 모드: **순차 격리 모드** (TASK 16개)
> 검증 모드: 순차 격리 모드 final integration sanity check
> 최종 결과: 전체 542/542 테스트 PASS + flutter analyze 0 issues + build_runner success

---

## 1. 실행 요약

페이즈 4 #1(위업·연대기) 미러 패턴으로 16 TASK 순차 격리 모드 진행. 각 TASK는 coder → main 미니 검증 가이드 → verifier(spec) → flutter-reviewer(quality) 미니 사이클을 거쳤다. 2 TASK(TASK-7, TASK-8)는 flutter-reviewer의 BLOCK/medium 이슈 재작업 1회 후 통과. TASK-14는 high 1건(Future await 누락)을 fix 1회 후 통과. 나머지 12 TASK는 1차 통과.

핵심 통합 결과:
- **Hive 박스 11개** 유지(typeId 20 추가 없음). HiveField 점유 갱신: Mercenary 26 / UserData 26 / MercenarySnapshot 6 / ActivityLogType 31.
- **Supabase 31번째 테이블** `titles` 신규 + 11행 시드 (migration 파일 작성, 실제 적용은 별도 작업 — 페이즈 4 #1 동일 패턴).
- **신규 도메인 서비스 2종** + **신규 Provider 5종** + **신규 위젯 4종** + **신규 helper 3종**.
- **콜백 DI 패턴 + 순환 참조 회피**: AchievementService ↔ TitleService 양방향 콜백을 Hive box 직접 조회(title_service_provider)로 해소.
- **합리적 단순화 결정 2건** (verifier 인지):
  - FR-16 FlagshipMercenaryService 콜백 5→2 (over-spec dead code 제거, 페이즈 5+ 위임 코멘트)
  - FR-28 top_contributor_24h: 24h 윈도우 추적 인프라 부재로 누적 success+great_success 1위 fallback

---

## 2. TASK별 실행 결과

| # | TASK | 추천 모델 | 실제 모델 | 1차 결과 | 재작업 | 최종 |
|---|------|----------|----------|---------|--------|------|
| 1 | Hive 4 모델 확장 (Mercenary·UserData·MercenarySnapshot·ActivityLogType) | haiku | haiku | PASS + APPROVE | - | PASS |
| 2 | TitleData freezed 모델 신규 | haiku | haiku | PASS + APPROVE | - | PASS |
| 3 | Supabase titles 테이블 + 11행 SQL 시드 (migration 파일) | haiku | haiku | PASS (verifier only) | - | PASS |
| 4 | SyncService 31번째 + StaticGameData.titles + titlesProvider | sonnet | sonnet | PASS + APPROVE | - | PASS |
| 5 | TitleService 도메인 + AchievementHookContext + Provider | opus | opus | PASS + APPROVE(w/warnings, medium 3) | - | PASS |
| 6 | hook_target 5종 보조 인프라 (UserDataNotifier 3 + 2 helper) | sonnet | sonnet | PASS + APPROVE | - | PASS |
| 7 | MercenaryListNotifier.updateTitleIds + Repository 위임 | haiku | haiku | PASS(w/warnings) + APPROVE(w/warnings) | 1회 (medium 1 + low 1) | PASS |
| 8 | FlagshipMercenaryService + 5단계 정렬 + Provider | sonnet | sonnet | PASS + BLOCK (high 2) | 1회 (콜백 5→2 단순화 + 단위 테스트 12) | PASS |
| 9 | PassiveBonusService 시그니처 + 가산 상한 + MercenaryTitleEffects | sonnet | sonnet | PASS + APPROVE | - | PASS |
| 10 | AchievementService.grant 확장 + 콜백 주입 (페이즈 4 #1 호환) | opus | opus | PASS + APPROVE | - | PASS |
| 11 | QuestCompletionService 4 hook 통합 | opus | opus | PASS + APPROVE(w/warnings, medium 5) | - | PASS |
| 12 | 사망/방출 + flagship 해제 + snapshot titleIds 동결 | sonnet | sonnet | PASS + APPROVE | - | PASS |
| 13 | RecruitmentService.generateMercenary recruitedAt 설정 | haiku | haiku | PASS (verifier-only) | - | PASS |
| 14 | DialogTypeRegistry + TitleUnlockedDialog + AchievementUnlockedDialog 인라인 + app.dart + home_screen switch | sonnet | sonnet | PASS + BLOCK (high 1 await + medium 6) | 1회 (high + 핵심 medium 3건 fix) | PASS |
| 15 | FlagshipHomeCard + HomeScreen 배치 | sonnet | sonnet | PASS + APPROVE(w/warnings, medium 4) | 1회 (medium 4건 fix: AppTheme/const/gameTickProvider/Widget 추출) | PASS |
| 16 | TitlesSection + FlagshipToggleButton + MercenaryDetailOverlay 배치 + mercenaryTitlesProvider family | sonnet | sonnet | PASS + APPROVE(w/warnings, medium 4 + low 1) | - | PASS |

총 재작업 횟수: 4회 (TASK-7 / TASK-8 / TASK-14 / TASK-15). 2회 미만 임계 내 모두 해결.

---

## 3. 변경 파일 목록 (35개 + Supabase migration)

### 신규 생성 (16개)

| 파일 | 역할 |
|------|------|
| `band_of_mercenaries/lib/core/models/title_data.dart` | TitleData freezed 정적 데이터 모델 (FR-4) |
| `band_of_mercenaries/lib/core/models/title_data.freezed.dart` | freezed 생성 |
| `band_of_mercenaries/lib/core/models/title_data.g.dart` | json_serializable 생성 |
| `band_of_mercenaries/lib/features/title/domain/title_service.dart` | TitleService 4 메서드 + AchievementHookContext (FR-9~FR-13) |
| `band_of_mercenaries/lib/features/title/domain/title_service_provider.dart` | titleServiceProvider 콜백 DI (FR-14, 순환 참조 회피로 분리) |
| `band_of_mercenaries/lib/features/title/domain/title_provider.dart` | titlesProvider + mercenaryTitlesProvider(family) (FR-8·FR-40) |
| `band_of_mercenaries/lib/features/title/domain/flagship_mercenary_service.dart` | FlagshipMercenaryService 5단계 정렬 (FR-16~FR-18) |
| `band_of_mercenaries/lib/features/title/domain/flagship_provider.dart` | flagshipMercenaryProvider + flagshipMercenaryServiceProvider (FR-19·FR-20) |
| `band_of_mercenaries/lib/features/title/domain/mercenary_title_effects.dart` | collectFor static helper (FR-22) |
| `band_of_mercenaries/lib/features/title/domain/achievement_hook_context_builder.dart` | buildAchievementHookContext helper (FR-25) |
| `band_of_mercenaries/lib/features/title/domain/top_contributor_helper.dart` | compute24hTopContributor 단순화 fallback (FR-28) |
| `band_of_mercenaries/lib/features/title/view/flagship_home_card.dart` | FlagshipHomeCard 홈 위젯 (FR-38) |
| `band_of_mercenaries/lib/features/title/view/titles_section.dart` | TitlesSection 용병 상세 섹션 (FR-39) |
| `band_of_mercenaries/lib/features/title/view/flagship_toggle_button.dart` | FlagshipToggleButton 4상태 토글 (FR-39) |
| `band_of_mercenaries/lib/features/title/view/title_unlocked_dialog.dart` | TitleUnlockedDialog (FR-34) |
| `band_of_mercenaries/supabase/migrations/20260515120000_create_titles.sql` | Supabase 31번째 테이블 + 11행 시드 (§7) |
| `band_of_mercenaries/test/features/title/domain/flagship_mercenary_service_test.dart` | FlagshipMercenaryService 단위 테스트 12 케이스 |

### 수정 (20개)

| 파일 | 변경 내용 |
|------|----------|
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` | HiveField 24·25 추가 (titleIds, recruitedAt) — FR-1 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.g.dart` | build_runner 재생성 |
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField 24·25 추가 (flagshipMercId, lastDispatchProtagonistMercId) — FR-2·FR-27 |
| `band_of_mercenaries/lib/core/models/user_data.g.dart` | build_runner 재생성 |
| `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.dart` | HiveField 5 추가 (titleIds) + fromMercenary 시그니처 backward compatible 확장 — FR-3 |
| `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.g.dart` | build_runner 재생성 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | ActivityLogType.titleUnlocked HiveField 30 — FR-37 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | build_runner 재생성 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | allTables 31번째 `'titles'` — FR-6 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | titles 필드 + 로드 분기 — FR-7 |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | DialogTypeRegistry.titleUnlocked 11번째 + _restoredMessage case — FR-33 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | UserDataNotifier 3 메서드 (setFlagshipMercId/clearFlagship/updateLastDispatchProtagonist) — FR-32 |
| `band_of_mercenaries/lib/core/domain/passive_bonus_service.dart` | collect titleEffects 인자 + getQuestRewardMultiplier·getMercenaryXpBonus +0.30 clamp — FR-21 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | updateTitleIds 메서드 + dismiss에 flagship 해제 분기 — FR-15·FR-31 |
| `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` | updateTitleIds 위임 — FR-15 |
| `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart` | generateMercenary에 recruitedAt 설정 — FR-41 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 4 hook 통합 (region 카운터 + action_stat + lastDispatch + status injured) + 사망 분기 flagship 해제 — FR-29·FR-30·FR-31 |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_service.dart` | grant 본체 fail-soft 2.5단계 + 콜백 2개 + buildAchievementDialog 3-arg — FR-23 |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_service_provider.dart` | TitleService 콜백 의존성 주입 — FR-24 |
| `band_of_mercenaries/lib/features/achievement/view/achievement_unlocked_dialog.dart` | grantedTitles 1줄 인라인 UI — FR-35 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | FlagshipHomeCard 배치 + ActivityLogType.titleUnlocked switch case — FR-38 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` | TitlesSection 배치 — FR-39 |

### 테스트 fixture 갱신 (4개, StaticGameData required 필드 추가 영향)

- `test/features/quest/domain/quest_narrative_render_test.dart`
- `test/features/inventory/view/inventory_screen_test.dart`
- `test/features/quest/domain/special_flag_processor_test.dart`
- `test/features/quest/domain/quest_completion_service_test.dart`

---

## 4. build_runner 재실행 파일

다음 4개 `.g.dart` 파일이 build_runner build로 재생성됨:
- `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.g.dart`
- `band_of_mercenaries/lib/core/models/user_data.g.dart`
- `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.g.dart`
- `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart`

신규 생성:
- `band_of_mercenaries/lib/core/models/title_data.freezed.dart`
- `band_of_mercenaries/lib/core/models/title_data.g.dart`

빌드 명령: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`

---

## 5. CLAUDE.md 금지사항 위반 / 합리적 일탈 사항

### 합리적 일탈 (verifier 인지·승인)

1. **FR-16 FlagshipMercenaryService 콜백 5→2 단순화**:
   - 명세는 5개 콜백(getMercenaries / getBandAchievements / staticData / getReputation / getJoinedFactions) 정의.
   - selectAuto 5단계 정렬은 mercenary 객체 effectiveXxx getter + getBandAchievements만 사용 → 3개 콜백은 dead code.
   - 페이즈 5+ reputation/faction 가중치 도입 시 콜백 재추가 가능 (코드 주석으로 의도 명시).
   - flutter-reviewer 1차 BLOCK 후 단순화 결정. verifier가 합리적 단순화로 인정.

2. **FR-28 top_contributor_24h 단순화 fallback**:
   - 24h 윈도우 추적 인프라 부재 (activity log 100개 휘발성 미달).
   - 누적 `success_count + great_success_count` 1위 mercenary로 대체. tie-break: recruitedAt 빠른 순.
   - 명세 §5 Q-2 결정 채택.

3. **title_service_provider 사이클 해소**:
   - TASK-10에서 AchievementService → TitleService 콜백 주입 시 import 사이클 발생 (achievement_service_provider ↔ title_service_provider 양방향).
   - title_service_provider의 hasAchievement / bandAchievements 콜백을 Hive box 직접 조회로 변경 (achievementServiceProvider/bandAchievementsProvider 의존 회피).
   - 시그니처 동일, 구현만 단순화. fail-soft 보장 유지.

4. **TASK-11 PassiveBonusService.collect titleEffects 미사용 경로**:
   - quest_provider에서 `MercenaryTitleEffects.collectFor(mercs.first, titles)` 결과를 CollectedEffects 리스트에 spread (PassiveBonusService.collect의 titleEffects 인자 미사용).
   - 동작 등가성 보장 (buffer.addAll(titleEffects)와 결과 동일).
   - Q-10 결정("파티 첫 번째 mercenary 단독") 적용.

### 금지사항 위반 없음

- Navigator.push 미사용 (상태 기반 렌더링 유지)
- 신규 의존성 추가 없음
- 한국어 응답·코드 주석 유지
- ConstrainedBox(maxWidth: 430) 적용
- AppTheme 색상 토큰 사용 (TASK-15 fix 후 모두 통과)

---

## 6. 검증 결과 요약

### verifier (명세 준수)

- 16 TASK 중 16/16 PASS
- TASK-8 / TASK-9 / TASK-11 등 코더 합리적 단순화 결정에 대해 "PASS (with warnings — 명세 시그니처 단순화 인지)" 형태로 통과

### flutter-reviewer (코드 품질)

- 16 TASK 중 13/16 APPROVE (1차 또는 재작업 후)
- BLOCK 3건: TASK-7(medium 1 + low 1 — Repository 위임 패턴 정합성) / TASK-8(high 2 — 미사용 필드 + 단위 테스트 부재) / TASK-14(high 1 — Future await 누락)
- 모든 BLOCK은 1회 재작업으로 해소
- APPROVE(with warnings) 6건: TASK-5 / TASK-7 / TASK-11 / TASK-14 / TASK-15 / TASK-16 (medium 이슈 누적은 통합 빌드 게이트에서 재확인, 동작 영향 없음 확인)

### 통합 빌드 게이트 (PHASE 2.5)

- `flutter analyze` 전체: No issues found
- `dart run build_runner build --delete-conflicting-outputs`: Succeeded with 1 outputs

### Final integration sanity check (PHASE 3-C)

- 전체 테스트 542/542 PASS
- 시그니처 충돌·누락 wiring 없음
- AchievementService ↔ TitleService 양방향 콜백 + 사이클 해소 완료
- titleServiceProvider stub 2종 모두 해소 (TASK-7 + TASK-14)
- DialogTypeRegistry 11종 등록 + TitleUnlockedDialog builder 매핑 + home_screen activityLog switch case 완비

---

## 7. 잔여 minor 이슈 (페이즈 5+ 위임)

페이즈 5+ 또는 후속 리팩토링에서 검토 가능한 quality 개선 항목 (동작 영향 없음):

1. **TASK-5 `_grantTitle` Future**: TASK-14에서 high로 격상되어 fix 완료 (await 추가)
2. **TASK-11 quest_provider 사망 분기 중복** (ISSUE-1 medium): 동일 조건 `damage.newStatus == MercenaryStatus.dead` 두 번 평가 — 통합 가능
3. **TASK-11 region_N_dispatch_count stat key prefix** (ISSUE-2 medium): Mercenary.stats Map에 region_N 키 추가 — 명세 의도이지만 별도 카운터 box로 분리 검토 가능
4. **TASK-11 mercRepo.getAll() 3회 호출** (ISSUE-3 medium): 단일 snapshot으로 통일 가능
5. **TASK-14 `_buildEffectLine` 비즈니스 로직** (ISSUE-3 medium): TitleUnlockedDialog 위젯 내부 → domain layer 분리 가능. titles_section.dart의 동일 패턴도 함께 통합
6. **TASK-14 ASCII glyph 접근성** (ISSUE-5 medium): `┝` 박스 드로잉 → Semantics 또는 Icon 위젯 대체
7. **TASK-14 ChainQuestProgress.status dynamic 캐스팅** (ISSUE-6 medium): enum 정확 비교로 교체 가능
8. **TASK-16 FlagshipToggleButton 4상태 분기** (ISSUE-1·2 medium): _buildContent → 4 state widget 추출 + ButtonStyle 중복 제거 (DRY)

---

## 8. CLAUDE.md 갱신 필요 항목 (finalize-feature 위임)

다음 항목은 본 스킬 범위 외이며 `finalize-feature` 스킬에서 처리:

- **HiveField 점유 표**: Mercenary 26 / UserData 26 / MercenarySnapshot 6 / ActivityLogType 31
- **DialogTypeRegistry 10 → 11종**: titleUnlocked 추가
- **Supabase 테이블 30 → 31**: titles 신규
- **AppTheme 토큰**: 본 명세는 신규 색상 토큰 추가 없음 (기존 chainGold / textPrimary / textSecondary / textHint / eliteAccent / eliteBg 재사용)
- **typeId 점유**: 신규 typeId 추가 없음 (다음 가용 20 유지)
- **신규 기능 영역**: 칭호 시스템 / 간판 용병 시스템 (M6 페이즈 4 #2)
- **Phase 4 #3 (지명 의뢰) 의존성**: Mercenary.titleIds·UserData.flagshipMercId·MercenarySnapshot.titleIds 시그니처 안정성 보장

---

## 9. 다음 단계

- **Supabase migration 적용**: `band_of_mercenaries/supabase/migrations/20260515120000_create_titles.sql`을 실제 Supabase 프로젝트에 적용 (페이즈 4 #1 동일 패턴, finalize-feature 또는 운영 작업)
- **finalize-feature 스킬 실행**: CLAUDE.md 업데이트 + CHANGELOG fragment 생성 + git commit + 아카이브
- **M6 페이즈 4 #3 진입**: 지명 의뢰 시스템 명세 작성 (페이즈 4 #2의 Mercenary.titleIds·UserData.flagshipMercId·MercenarySnapshot.titleIds 시그니처 의존)

---

> 본 plan 문서는 implement-agent 스킬에서 자동 생성되었습니다.
> 모든 결정은 명세서(`Docs/spec/[spec]20260515_M6_phase4_2_titles-flagship.md`)와 일관되며,
> verifier·flutter-reviewer 두 검증자의 PASS·APPROVE 판정으로 통과 처리되었습니다.
