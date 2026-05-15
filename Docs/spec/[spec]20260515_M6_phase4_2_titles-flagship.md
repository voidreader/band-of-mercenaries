# M6 페이즈 4 #2 — 칭호·간판 용병 시스템 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260512_titles-and-flagship.md` — 1차 입력 (3종 hook / 11종 칭호 / 자동 선정 5단계 / 사망 후 동결)
> - `Docs/balance-design/[balance]20260513_title-effect-values.md` — 수치 (effect_json 11종 / 행동 지표 임계 4종 하향 / 가산 상한 위임)
> - `Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle.md` — 페이즈 4 #1 직전 명세 (MercenarySnapshot HiveField 5 예약 / AchievementService 4 메서드 / 6 hook)
>
> 작성일: 2026-05-15
> 마일스톤: M6 페이즈 4 #2 — 칭호·간판 용병 시스템
> 선행: M6 페이즈 4 #1 (위업·연대기) — AchievementService / MercenarySnapshot / dialogQueue 기반
> 후속: M6 페이즈 4 #3 (지명 의뢰) — Mercenary.titleIds·UserData.flagshipMercId·MercenarySnapshot.titleIds 시그니처 안정 의존
>
> Visual Companion 적용: `.superpowers/brainstorm/86694-1778834258/content/` 3종 (홈 간판 카드 / 용병 상세 칭호 섹션 / TitleUnlockedDialog)
> 페이즈 3 스킵: 칭호 11종 SQL INSERT를 §7에 인라인 포함

---

## 1. 개요

칭호·간판 용병 시스템은 M6 "이름을 얻는 용병단" 마일스톤의 두 번째 토대다. 페이즈 4 #1의 위업 발급 이벤트와 mercSnapshot 영구 보존 정책을 hook으로 활용하여, 용병별 칭호를 자동/수동 발급하고 한 명의 "간판" 용병을 자동 5단계 정렬로 노출한다.

핵심 기능:
- **Mercenary** 모델 확장 (HiveField 24 `titleIds: List<String>` + HiveField 25 `recruitedAt: DateTime?`)
- **UserData** 모델 확장 (HiveField 24 `flagshipMercId: String?` — null = 자동, non-null = 수동)
- **MercenarySnapshot** 모델 확장 (HiveField 5 `titleIds: List<String>` — 발급 시점 동결, 페이즈 4 #1에서 예약)
- **Supabase `titles`** 신규 테이블 (31번째) + 11행 시드 SQL 인라인
- **TitleService** 신규 4 메서드 + **FlagshipMercenaryService** 신규 4 메서드
- **PassiveBonusService.collect()** `titleEffects` 인자 추가 + `questRewardMultiplier`·`mercenaryXpBonus` 가산 상한 +0.30 명시
- **TitleUnlockedDialog** (high) 신규 + **AchievementUnlockedDialog** 본체 1줄 인라인 통합
- **HomeScreen** 간판 용병 카드 + **MercenaryDetailOverlay** 칭호 섹션 + 4상태 간판 토글
- **DialogTypeRegistry** 11번째 (`titleUnlocked`) + **ActivityLogType** HiveField 30 (`titleUnlocked`)
- **행동 지표 임계 하향** (페이즈 2 #1 결정): raid 30→20, dispatch 100→80, explore 20→15, escort 15→12 (titles 테이블 시드 데이터에 직접 반영)

---

## 2. 요구사항

### 2.1 기능 요구사항

#### (a) 데이터 모델 확장

- **[FR-1] Mercenary 모델 HiveField 24·25 추가**
  - 위치: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` (typeId 1, 현재 HiveField 0~23)
  - 추가 필드:
    ```dart
    @HiveField(24)
    List<String> titleIds;     // default: <String>[]
    @HiveField(25)
    DateTime? recruitedAt;     // nullable, 기존 세이브 호환
    ```
  - 생성자 시그니처 확장: `Mercenary({..., this.titleIds = const [], this.recruitedAt})` — `titleIds` 항상 mutable List 변환 (`titleIds ?? <String>[]` 패턴, 기존 traitIds 패턴 준용)
  - **CLAUDE.md 표 갱신**: Mercenary 다음 HiveField 24 → **26**
  - **build_runner**: `mercenary_model.g.dart` 재생성

- **[FR-2] UserData 모델 HiveField 24 추가**
  - 위치: `band_of_mercenaries/lib/core/models/user_data.dart` (typeId 5, 현재 HiveField 0~23)
  - 추가 필드:
    ```dart
    @HiveField(24)
    String? flagshipMercId;    // null = 자동, non-null = 수동 ID
    ```
  - 생성자 시그니처: `UserData({..., this.flagshipMercId})` — nullable, 기존 세이브 자동 호환 (null 초기화)
  - copyWith가 있다면 `flagshipMercId` 파라미터 추가
  - **CLAUDE.md 표 갱신**: UserData 다음 HiveField 24 → **25**
  - **build_runner**: `user_data.g.dart` 재생성

- **[FR-3] MercenarySnapshot 모델 HiveField 5 추가**
  - 위치: `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.dart` (typeId 18, 현재 HiveField 0~4)
  - 추가 필드:
    ```dart
    @HiveField(5)
    final List<String> titleIds;   // default: const []
    ```
  - 생성자 시그니처 확장: `MercenarySnapshot({required this.id, ..., this.titleIds = const []})`
  - `fromMercenary` 팩토리 확장:
    ```dart
    factory MercenarySnapshot.fromMercenary(
      Mercenary mercenary, {
      required String jobName,
      required int tier,
      List<String>? titleIds,  // 미주입 시 mercenary.titleIds 사본 사용
    }) => MercenarySnapshot(
      id: mercenary.id,
      name: mercenary.name,
      jobId: mercenary.jobId,
      jobName: jobName,
      tier: tier,
      titleIds: List<String>.from(titleIds ?? mercenary.titleIds),  // 동결 사본
    );
    ```
  - **CLAUDE.md 표 갱신**: MercenarySnapshot 다음 HiveField 5 → **6**
  - **build_runner**: `mercenary_snapshot_model.g.dart` 재생성

- **[FR-4] TitleData 정적 데이터 모델 신규 (freezed + json_serializable)**
  - 위치: `band_of_mercenaries/lib/core/models/title_data.dart` (신규)
  - 시그니처:
    ```dart
    @freezed
    class TitleData with _$TitleData {
      const factory TitleData({
        required String id,
        required String name,
        required String description,
        @JsonKey(name: 'hook_type') required String hookType,
        @JsonKey(name: 'hook_condition') @Default({}) Map<String, dynamic> hookCondition,
        @JsonKey(name: 'effect_json') @Default({}) Map<String, dynamic> effectJson,
        @JsonKey(name: 'icon_key') @Default('default') String iconKey,
        @JsonKey(name: 'narrative_hint') String? narrativeHint,
      }) = _TitleData;

      factory TitleData.fromJson(Map<String, dynamic> json) => _$TitleDataFromJson(json);
    }
    ```
  - **build_runner**: `title_data.freezed.dart` + `title_data.g.dart` 생성

#### (b) Supabase 테이블 + 동기화

- **[FR-5] Supabase `titles` 테이블 생성 (31번째 테이블)**
  - 페이즈 4 #1에서 30번째 테이블 `band_achievement_templates`까지 등록됨. 본 명세는 31번째.
  - 스키마: §7.1 SQL 인라인 참조 (PRIMARY KEY `id` TEXT, `hook_type` TEXT CHECK in (achievement/action_stat/status), `hook_condition` JSONB, `effect_json` JSONB, `icon_key` TEXT, `narrative_hint` TEXT NULL)
  - 11행 시드 INSERT: §7.2 SQL 인라인 참조
  - `data_versions`에 `('titles', 1, NOW())` INSERT
  - operation-bom CRUD UI는 별도 작업 (본 명세 범위 외)

- **[FR-6] SyncService 31번째 테이블 등록**
  - 위치: `band_of_mercenaries/lib/core/data/sync_service.dart` `allTables` 정적 리스트
  - 추가: 리스트 마지막에 `'titles', // M6 페이즈 4 #2 추가 (31번)` 항목 추가
  - DataLoader는 테이블명을 캐시 키로 사용하므로 별도 수정 불요 (자동 동작)

- **[FR-7] StaticGameData `titles` 필드 추가**
  - 위치: `band_of_mercenaries/lib/core/providers/static_data_provider.dart`
  - 추가 필드: `final List<TitleData> titles; // M6 페이즈 4 #2 추가`
  - 생성자 `required this.titles` 추가
  - FutureProvider 내 로드 분기 추가:
    ```dart
    final titlesJson = await DataLoader.loadFromCache('titles');
    final titles = titlesJson.map(TitleData.fromJson).toList();
    ```
  - StaticGameData 인스턴스 생성 시 `titles: titles` 전달

- **[FR-8] titlesProvider 신규**
  - 위치: `band_of_mercenaries/lib/features/title/domain/title_provider.dart` (신규)
  - 시그니처: `final titlesProvider = Provider<List<TitleData>>((ref) => ref.watch(staticDataProvider).value?.titles ?? const []);`
  - 동기 접근 가능 — `staticDataProvider` 로딩 완료 후 fallback 빈 리스트

#### (c) TitleService 신규 도메인

- **[FR-9] TitleService 클래스 (콜백 DI 패턴, AchievementService 유사)**
  - 위치: `band_of_mercenaries/lib/features/title/domain/title_service.dart` (신규)
  - 생성자 시그니처:
    ```dart
    TitleService({
      required this.titles,                          // List<TitleData>
      required this.getMercenary,                    // Mercenary? Function(String mercId)
      required this.updateMercenaryTitles,           // Future<void> Function(String mercId, List<String> titleIds)
      required this.addLog,                          // void Function(String, ActivityLogType)
      required this.enqueueDialog,                   // void Function(DialogRequest)
      required this.hasAchievement,                  // bool Function(String templateId)
      required this.bandAchievements,                // List<BandAchievement> getter (간판 알고리즘 보조)
      required this.staticData,                      // StaticGameData (job·region·questType 조회)
      required this.buildTitleDialog,               // Widget Function({title, mercSnapshot, reasonText})
    });
    ```
  - **콜백 DI**: 직접 Provider 의존성을 가지지 않고 외부 주입. `titleServiceProvider`가 의존성 바인딩.

- **[FR-10] `TitleService.evaluateAchievementHook(achievement, hookContext)`**
  - 시그니처: `List<TitleData> evaluateAchievementHook(BandAchievement achievement, AchievementHookContext context)`
  - `AchievementHookContext` 신규 데이터 클래스 (record 또는 freezed):
    ```dart
    class AchievementHookContext {
      final BandAchievement achievement;
      final MercenarySnapshot? protagonist;          // achievement.mercSnapshot 그대로
      final List<String> aliveDispatchableMercIds;   // hook_target 보조
      final Map<String, int> regionDispatchCounts;   // mercId → region 3 누적 dispatch (hook_target=most_dispatched_to_region_3 보조)
      final String? lastDispatchTopMercId;           // hook_target=last_dispatch_protagonist 보조
      final String? top24hContributorMercId;          // hook_target=top_contributor_24h 보조
    }
    ```
  - 동작:
    1. `achievement.type == achievement` 인 경우만 평가 (memorial 분기 시 즉시 빈 리스트 반환)
    2. `titles` 중 `hookType == 'achievement'` 항목 순회
    3. `hook_condition.achievement_template_id` 또는 `achievement_template_id_prefix` 매칭 + `hook_condition.first_only == true` 시 `hasAchievement` 글로벌 체크 (titles 발급 시 동일 prefix 추가 발급 차단)
    4. `hook_target` 분기 (5종):
       - `require_protagonist: true` → `context.protagonist?.id` 사용. null이면 skip.
       - `hook_target: 'last_dispatch_protagonist'` → `context.lastDispatchTopMercId` 사용. null이면 skip.
       - `hook_target: 'most_dispatched_to_region_3'` → `context.regionDispatchCounts` 1위 mercId 사용. 빈 Map이면 skip.
       - `hook_target: 'top_contributor_24h'` → `context.top24hContributorMercId` 사용. null이면 skip.
       - `hook_target: 'first_only'` (자체 분기, achievement_template_id_prefix와 함께만 사용) → `context.protagonist?.id` 사용.
    5. 결정된 `targetMercId`로 `getMercenary` 호출. mercenary 미존재 또는 사망 시 skip.
    6. `mercenary.titleIds.contains(title.id)` 시 중복 차단.
    7. `_grantTitle(mercenary, title)` 내부 호출.
    8. 반환: 발급된 `List<TitleData>` (0~N개)
  - **fail-soft**: hook_target 분기에서 정보 부족(예: lastDispatchTopMercId == null) 시 silent skip — 다이얼로그 미발급.
  - **AchievementUnlockedDialog 본체 인라인 통합**: 반환된 List는 AchievementService.grant 측에서 payload에 `grantedTitles` 키로 첨부 (§FR-22 참조)

- **[FR-11] `TitleService.evaluateActionStatHook(mercId)`**
  - 시그니처: `void evaluateActionStatHook(String mercId)`
  - 동작:
    1. `getMercenary(mercId)` — mercenary 미존재·사망 시 skip
    2. `titles` 중 `hookType == 'action_stat'` 항목 순회
    3. `mercenary.titleIds.contains(title.id)` 시 중복 차단
    4. `hook_condition`: `{stat_key: String, threshold: int, operator: '>='}` 매칭. `mercenary.stats[statKey] ?? 0 >= threshold` 조건 평가.
    5. 매칭 시 `_grantTitle(mercenary, title)` + `enqueueDialog(TitleUnlockedDialog 빌더)` (high priority)
  - 호출 시점: §FR-29 (QuestCompletionService 파견 결과 처리 직후)

- **[FR-12] `TitleService.evaluateStatusHook(mercId, newStatus, context)`**
  - 시그니처: `void evaluateStatusHook(String mercId, MercenaryStatus newStatus, Map<String, dynamic> context)`
  - 동작:
    1. `getMercenary(mercId)` — mercenary 미존재·사망 시 skip
    2. `titles` 중 `hookType == 'status'` 항목 순회
    3. `mercenary.titleIds.contains(title.id)` 시 중복 차단
    4. `hook_condition`: `{trigger_status: String, context: {chain_id?: String, require_chain_completion?: bool, ...}}` 매칭
       - `trigger_status == newStatus.name` 비교
       - `hook_condition.context.chain_id` 존재 시: `context['chainProgressMap']` (Map<String, ChainQuestStatus>) 확인. `require_chain_completion == true`면 해당 chain 완료 상태여야 함.
    5. 매칭 시 `_grantTitle(mercenary, title)` + `enqueueDialog(TitleUnlockedDialog 빌더)` (high priority)
  - 호출 시점: §FR-30 (퀘스트 부상 처리 직후 — `MercenaryStatus.injured` 진입 시 + chain progress 확인)

- **[FR-13] `TitleService._grantTitle(mercenary, title)` (private)**
  - 시그니처: `Future<void> _grantTitle(Mercenary mercenary, TitleData title)`
  - 동작 (4단계 fail-soft trailing):
    1. `final newIds = [...mercenary.titleIds, title.id]`
    2. `updateMercenaryTitles(mercenary.id, newIds)` — Repository를 통한 Hive 영속화
    3. `addLog('┝ ${mercenary.name}이(가) "${title.name}" 칭호를 얻었다', ActivityLogType.titleUnlocked)`
    4. 호출측 dialog enqueue는 외부 책임 (evaluateActionStatHook / evaluateStatusHook 에서 enqueue, evaluateAchievementHook는 AchievementService payload 통합)

- **[FR-14] `titleServiceProvider` Riverpod Provider**
  - 위치: `band_of_mercenaries/lib/features/title/domain/title_service_provider.dart` (신규)
  - 시그니처: `final titleServiceProvider = Provider<TitleService>((ref) { ... });`
  - 의존성 주입:
    - `titles`: `ref.watch(titlesProvider)`
    - `getMercenary`: `(id) => ref.read(mercenaryListProvider).where((m) => m.id == id).firstOrNull`
    - `updateMercenaryTitles`: `ref.read(mercenaryListProvider.notifier).updateTitleIds`
    - `addLog`: `ref.read(activityLogProvider.notifier).addLog`
    - `enqueueDialog`: `ref.read(dialogQueueProvider.notifier).enqueue`
    - `hasAchievement`: `ref.read(achievementServiceProvider).hasAchievement`
    - `bandAchievements`: `() => ref.read(bandAchievementsProvider)`
    - `staticData`: `ref.watch(staticDataProvider).requireValue`
    - `buildTitleDialog`: `({title, mercSnapshot, reasonText}) => TitleUnlockedDialog(title: title, mercSnapshot: mercSnapshot, reasonText: reasonText)`
  - **순환 참조 회피**: AchievementService 패턴 따라 `title_service_provider.dart`로 분리

#### (d) MercenaryListNotifier 확장

- **[FR-15] MercenaryListNotifier.updateTitleIds(mercId, titleIds) 신규**
  - 위치: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart`
  - 시그니처: `Future<void> updateTitleIds(String mercId, List<String> titleIds)`
  - 동작: Hive box에서 mercId 조회 → `merc.titleIds = List<String>.from(titleIds)` → `await merc.save()` → `_load()`
  - **Path 일관성**: MercenaryRepository에 동일 메서드 위임 또는 직접 box.put 처리 (기존 `_repo.dismiss` 패턴 따름)

#### (e) FlagshipMercenaryService 신규 도메인

- **[FR-16] FlagshipMercenaryService 클래스 (콜백 DI)**
  - 위치: `band_of_mercenaries/lib/features/title/domain/flagship_mercenary_service.dart` (신규)
  - 생성자 시그니처:
    ```dart
    FlagshipMercenaryService({
      required this.getMercenaries,         // List<Mercenary> Function()
      required this.getBandAchievements,    // List<BandAchievement> Function()
      required this.staticData,             // StaticGameData (partyPower 계산용 job·trait·rank 조회)
      required this.getReputation,          // int Function()
      required this.getJoinedFactions,      // List<FactionData> Function()
    });
    ```

- **[FR-17] `FlagshipMercenaryService.selectAuto()`**
  - 시그니처: `Mercenary? selectAuto()`
  - 동작:
    1. `getMercenaries().where((m) => m.status != MercenaryStatus.dead).toList()` — dead 제외
    2. `isEmpty` 시 `null` 반환
    3. `candidates.sort(_compareFlagship)` — 5단계 정렬
    4. `candidates.first` 반환
  - 5단계 정렬 비교자 `_compareFlagship(a, b)`:
    ```
    1순위: titleIds.length DESC
    2순위: 위업 주인공 횟수 DESC (getBandAchievements 필터: type==achievement && mercSnapshot.id==merc.id)
    3순위: level DESC
    4순위: partyPower DESC (가중 평균 — STR×0.3 + INT×0.3 + VIT×0.2 + AGI×0.2의 effectiveXxx getter 사용, MercenaryStatService 보너스 적용)
    5순위: recruitedAt ASC (이른 가입 우선; null = DateTime(2000) fallback)
    ```
  - 4순위 `partyPower`: `(merc.effectiveStr * 0.3 + merc.effectiveIntelligence * 0.3 + merc.effectiveVit * 0.2 + merc.effectiveAgi * 0.2)` — 단순 평균. quest_type 가중치 미적용 (간판 알고리즘 단순화).

- **[FR-18] `FlagshipMercenaryService.handleMercDeathOrRelease(deadMercId)`**
  - 시그니처: `String? handleMercDeathOrRelease(String deadMercId, {required String? currentFlagshipMercId})`
  - 동작:
    - `currentFlagshipMercId == deadMercId` 시 반환 `null` (수동 간판 사망/방출 시 자동 복귀)
    - 외 → `currentFlagshipMercId` 그대로 반환 (변경 없음)
  - 호출처: §FR-31 (mercenary_provider.dismiss + quest_provider 사망 분기)

- **[FR-19] `flagshipMercenaryProvider` Riverpod Provider**
  - 위치: `band_of_mercenaries/lib/features/title/domain/flagship_provider.dart` (신규)
  - 시그니처: `final flagshipMercenaryProvider = Provider<Mercenary?>((ref) { ... });`
  - 동작 (Riverpod auto-recompute):
    1. `userData.flagshipMercId` watch
    2. `mercenaryListProvider` watch
    3. `bandAchievementsProvider` watch (정렬 2순위 영향)
    4. `flagshipMercId != null` 시 mercenaryList에서 매칭 검색 — 발견 시 반환, 미발견 시 자동 알고리즘 호출
    5. `flagshipMercId == null` 시 `FlagshipMercenaryService.selectAuto()` 호출 → 반환
  - 의존 Provider 변경 시 자동 재계산. 별도 갱신 호출 불요.

- **[FR-20] `flagshipMercenaryServiceProvider`**
  - 위치: `band_of_mercenaries/lib/features/title/domain/flagship_provider.dart` (동일)
  - 시그니처: `final flagshipMercenaryServiceProvider = Provider<FlagshipMercenaryService>((ref) { ... });`
  - 의존성 주입 (FR-16 시그니처 기반)

#### (f) PassiveBonusService 통합

- **[FR-21] PassiveBonusService.collect() 시그니처 확장 + 가산 상한 명시**
  - 위치: `band_of_mercenaries/lib/core/domain/passive_bonus_service.dart`
  - 시그니처 확장 (인자 1개 추가):
    ```dart
    static CollectedEffects collect({
      required int reputation,
      required List<Rank> allRanks,
      required List<FactionData> joinedFactions,
      List<PassiveEffect> personalEquipmentLegendaries = const [],
      List<PassiveEffect> guildEquipments = const [],
      List<PassiveEffect> titleEffects = const [],  // 신규
    })
    ```
  - 본체 동작: buffer에 `titleEffects` 추가 (`buffer.addAll(titleEffects)`)
  - **가산 상한 명시 — `getQuestRewardMultiplier`**:
    - 기존: `return 1.0 + sum;` (상한 없음)
    - 변경: `final clamped = sum.clamp(0.0, 0.30); return 1.0 + clamped;` — **상한 +0.30**
  - **가산 상한 명시 — `getMercenaryXpBonus`**:
    - 기존: 합산 후 반환 (상한 없음)
    - 변경: `return (sum).clamp(0.0, 0.30);` — **상한 +0.30**
  - 호출처 6개 (app.dart / passive_bonus_context.dart×2 / facility_tab_screen.dart / investigation_notifier.dart / movement_provider.dart / quest_completion_service.dart / mercenary_provider.dart)는 기존 호출 시그니처 유지 — `titleEffects` 미주입 시 default 빈 리스트.
  - 칭호 효과 전달이 필요한 호출처는 별도 helper(§FR-22) 사용.

- **[FR-22] `MercenaryTitleEffects.collectForMercenary(mercenary, titles)` helper**
  - 위치: `band_of_mercenaries/lib/features/title/domain/mercenary_title_effects.dart` (신규)
  - 시그니처:
    ```dart
    class MercenaryTitleEffects {
      static List<PassiveEffect> collectFor(Mercenary mercenary, List<TitleData> titles) {
        final result = <PassiveEffect>[];
        for (final id in mercenary.titleIds) {
          final title = titles.firstWhereOrNull((t) => t.id == id);
          if (title == null) continue;
          result.addAll(PassiveEffect.parseEffects(title.effectJson));
        }
        return result;
      }
    }
    ```
  - 용병 1명 단위 호출처에서 `titleEffects: MercenaryTitleEffects.collectFor(mercenary, ref.read(titlesProvider))` 형태로 사용.
  - **적용 대상 호출처 4개**:
    - `quest_completion_service.dart` 라인 ~134 (`PassiveBonusService.collect` 호출 시 mercenary 단위 합산이 가능한 케이스만 — 파티 대표 1인 또는 파티별 합산)
    - `investigation_notifier.dart` 라인 107 — investigation 1명 단위
    - `app.dart` idle reward 라인 104 — **미적용** (용병단 단위라 칭호 미합산)
    - `movement_provider.dart` / `facility_tab_screen.dart` / `mercenary_provider.recruit` — **미적용** (용병단 단위 효과)
  - **적용 정책 명시**: 칭호는 mercenary 1명 단위 효과이므로 파티/조사 시 해당 mercenary의 titleEffects만 합산. 파티 다수 mercenary가 있는 경우(파견 파티) — 각 mercenary별 합산 후 평균 또는 단순 합산은 호출 시점 결정. **본 명세는 "퀘스트 시 파티 첫 번째 mercenary 단독" 정책**으로 단순화 (페이즈 4 #1 ChainQuestService.protagonist 패턴 준용). 향후 페이즈 5에서 파티 전원 합산 결정 검토 (§5 기획 확인 Q-1).

#### (g) AchievementService 통합 (페이즈 4 #1 확장)

- **[FR-23] AchievementService.grant() payload에 grantedTitles 통합**
  - 위치: `band_of_mercenaries/lib/features/achievement/domain/achievement_service.dart`
  - 변경: grant 메서드 본체 fail-soft trailing 4단계에서 dialog enqueue 직전에 TitleService 호출:
    ```dart
    Future<BandAchievement?> grant(String templateId, {MercenarySnapshot? mercSnapshot, int? regionId, Map<String, dynamic> payload = const {}}) async {
      if (hasAchievement(templateId)) return null;
      final newAchievement = BandAchievement(...);  // 기존
      await box.add(newAchievement);                  // (1) 영속 저장
      addLog(...);                                    // (2) activityLog 미러

      // 신규 — (2.5) 칭호 hook 평가
      List<TitleData>? grantedTitles;
      try {
        if (evaluateAchievementHook != null) {  // 콜백 nullable
          final ctx = buildHookContext(newAchievement);  // §FR-25
          grantedTitles = evaluateAchievementHook!(newAchievement, ctx);
        }
      } on Exception catch (e) {
        debugPrint('[BOM][Title] hook 평가 실패: $e');
      }

      // (3) dialog enqueue — reputation_rank 제외
      if (_categoryOf(templateId) != 'reputation_rank') {
        enqueueDialog(buildAchievementDialog(newAchievement, grantedTitles ?? const []));
      }
      return newAchievement;
    }
    ```
  - 생성자에 신규 콜백 추가:
    - `List<TitleData> Function(BandAchievement, AchievementHookContext)? evaluateAchievementHook` (nullable — 페이즈 4 #1 호환)
    - `AchievementHookContext Function(BandAchievement)? buildHookContext` (nullable)
  - `buildAchievementDialog` 시그니처도 `(BandAchievement, List<TitleData> grantedTitles)`로 확장 (페이즈 4 #1: 1개 인자, 본 명세: 2개 인자)

- **[FR-24] AchievementServiceProvider 의존성 확장**
  - 위치: `band_of_mercenaries/lib/features/achievement/domain/achievement_service_provider.dart`
  - 추가 의존성 주입:
    - `evaluateAchievementHook`: `(ach, ctx) => ref.read(titleServiceProvider).evaluateAchievementHook(ach, ctx)`
    - `buildHookContext`: `(ach) => _buildContextFromProviders(ref, ach)` (helper 함수, §FR-25)
  - `buildAchievementDialog` 변경: `(ach, titles) => AchievementUnlockedDialog(achievement: ach, grantedTitles: titles)`

- **[FR-25] AchievementHookContext 빌더 헬퍼**
  - 위치: `band_of_mercenaries/lib/features/title/domain/achievement_hook_context_builder.dart` (신규)
  - 시그니처: `AchievementHookContext buildAchievementHookContext(Ref ref, BandAchievement achievement)`
  - 동작:
    1. `protagonist`: `achievement.mercSnapshot` 그대로
    2. `aliveDispatchableMercIds`: `ref.read(mercenaryListProvider).where((m) => m.status != MercenaryStatus.dead).map((m) => m.id).toList()`
    3. `regionDispatchCounts`: `_collectRegionDispatchCounts(ref, regionId: 3)` — Mercenary.stats[`region_3_dispatch_count`] 집계 (§FR-26)
    4. `lastDispatchTopMercId`: `userData.lastDispatchProtagonistMercId` — 신규 캐시 (§FR-27)
    5. `top24hContributorMercId`: `_compute24hTopContributor(ref)` — bandAchievements + activity 기반 (§FR-28)

#### (h) hook_target 5종 보조 인프라

- **[FR-26] Mercenary.stats `region_{N}_dispatch_count` 신규 카운터**
  - 위치: `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart`
  - 호출 위치: 파견 결과 처리 직후 (stats 갱신 분기, 기존 stats 23개와 함께 증가)
  - 동작: `mercenary.stats['region_${regionId}_dispatch_count'] = (current ?? 0) + 1` — 파견 파티 전원 +1 (region별)
  - **추가 키 수량**: regions 40개 = 최대 40개 신규 stats 키. 기존 stats 23개 → 최대 63개. Map<String, int>이라 점진적 추가 무관.

- **[FR-27] UserData.lastDispatchProtagonistMercId 신규 HiveField 25**
  - **CLAUDE.md 표 갱신**: UserData 다음 HiveField는 §FR-2의 24(`flagshipMercId`) + 본 25 → **26**
  - 시그니처:
    ```dart
    @HiveField(25)
    String? lastDispatchProtagonistMercId;  // 가장 최근 성공 파견의 최고 기여 mercId 캐시
    ```
  - 갱신 시점: QuestCompletionService 파견 결과 `result == success || greatSuccess` 시 `partyPowers` 1위 mercId로 set. UserDataNotifier 신규 메서드 `updateLastDispatchProtagonist(mercId)`.
  - 호출 시점: §FR-29 (QuestCompletionService 파견 결과 처리)
  - **build_runner**: `user_data.g.dart` 재생성 (FR-2와 함께)

- **[FR-28] top_contributor_24h 추적 — bandAchievements + dispatch 기반 합산**
  - 위치: `band_of_mercenaries/lib/features/title/domain/top_contributor_helper.dart` (신규 helper)
  - 시그니처: `String? compute24hTopContributor(Ref ref)`
  - 동작 (단순 구현):
    1. `now = DateTime.now()`, `cutoff = now.subtract(Duration(hours: 24))`
    2. `mercenaryList` 순회. 각 mercenary에 대해:
       - 최근 24h 내 stats 증가량 계산 불가 (스냅샷 없음). 대안: `mercenary.stats['success_count']` + `mercenary.stats['great_success_count']` 합계가 최대인 mercenary로 단순화.
    3. tie-break: `recruitedAt` 빠른 순.
  - **단순화 사유**: 실시간 24h 윈도우 추적은 별도 인프라 (activityLog 100개 휘발성 미달). 본 명세는 "전체 누적 성공 1위" fallback으로 단순화. roadmap 종료 조건 충족 (간판 노출 + 칭호 발급 1건 이상). 페이즈 5+에서 정교화 검토 (§5 기획 확인 Q-2).

#### (i) 6 hook 통합 (페이즈 4 #1과 연계)

- **[FR-29] QuestCompletionService — 행동 지표 hook + lastDispatchProtagonist 갱신**
  - 위치: `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` 또는 `quest_provider.dart` `_applyCompletionResult` 영역
  - 추가 동작:
    1. 파견 완료 stats 갱신 후 (기존 코드): 각 파견 mercenary에 대해 `ref.read(titleServiceProvider).evaluateActionStatHook(mercId)` 호출 — fail-soft try/catch
    2. 파견 결과 `result == success || greatSuccess` 분기:
       - `topMercId = _pickTopContributor(quest.dispatchedMercIds, quest.contributionMap)` (페이즈 4 #1 helper 재사용)
       - `await ref.read(userDataProvider.notifier).updateLastDispatchProtagonist(topMercId)` (§FR-27)
    3. 파견 시 region 카운터: 각 파견 mercenary의 `stats['region_${regionId}_dispatch_count']` +1 (§FR-26)
  - **추가 순서**: 기존 stats 갱신 → evaluateActionStatHook → updateLastDispatchProtagonist → activityLog 순서. fail-soft 트레일링 패턴.

- **[FR-30] 부상 처리 — 상태 hook 평가**
  - 위치: `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` 라인 309~321 (DamageResult.injured 분기)
  - 추가 동작: `merc.status = MercenaryStatus.injured` 직후:
    ```dart
    try {
      final chainProgress = await ref.read(chainQuestProgressProvider.future);
      ref.read(titleServiceProvider).evaluateStatusHook(
        merc.id,
        MercenaryStatus.injured,
        {'chainProgressMap': chainProgress, 'questId': quest.id, 'regionId': quest.region},
      );
    } on Exception catch (e) {
      debugPrint('[BOM][Title] status hook 실패: $e');
    }
    ```

- **[FR-31] mercenary_provider.dismiss + 사망 분기 — MercenarySnapshot.titleIds 동결**
  - 위치 1: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` 라인 182 (dismiss → MercenarySnapshot.fromMercenary 호출 직전)
  - 위치 2: `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` 라인 ~940 (사망 처리 → recordMemorial 호출 직전)
  - 변경: `MercenarySnapshot.fromMercenary(merc, jobName: job.name, tier: job.tier)` 호출 — 기존 시그니처는 그대로 동작 (titleIds 미주입 시 merc.titleIds 사본 자동 동결, §FR-3)
  - **추가 동작**: dismiss/사망 처리 후 `userData.flagshipMercId == merc.id` 시 `ref.read(userDataProvider.notifier).clearFlagship()` 호출 (수동 간판 자동 복귀)

- **[FR-32] UserDataNotifier — 신규 메서드 3개**
  - 위치: `band_of_mercenaries/lib/core/providers/game_state_provider.dart` (UserDataNotifier 정의 위치)
  - 추가 메서드:
    ```dart
    Future<void> setFlagshipMercId(String? mercId);     // §FR-2 영속화
    Future<void> clearFlagship() => setFlagshipMercId(null);
    Future<void> updateLastDispatchProtagonist(String? mercId);  // §FR-27 영속화
    ```
  - 각 메서드: 현재 userData 객체 복사 → 필드 변경 → Hive save → state emit (`_load()` 또는 `state = newUserData`).

#### (j) Dialog 시스템 통합

- **[FR-33] DialogTypeRegistry `titleUnlocked` 11번째 추가**
  - 위치: `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart`
  - 변경:
    ```dart
    static const String titleUnlocked = 'titleUnlocked';
    static final Set<String> keys = {..., titleUnlocked};
    ```
  - **CLAUDE.md 표 갱신**: DialogTypeRegistry 10 → **11종**

- **[FR-34] TitleUnlockedDialog 신규 위젯**
  - 위치: `band_of_mercenaries/lib/features/title/view/title_unlocked_dialog.dart` (신규)
  - 시그니처:
    ```dart
    class TitleUnlockedDialog extends StatelessWidget {
      final TitleData title;
      final MercenarySnapshot mercSnapshot;
      final String reasonText;  // hook별 차등 문구
      const TitleUnlockedDialog({...});
    }
    ```
  - 동작: AlertDialog + barrierDismissible: false + "확인" 버튼만 dismiss
  - UI: §2.3 wireframe 03 참조 (chainGold border + Title name + mercSnapshot + reasonText + effect 한 줄 + 확인 버튼)
  - reasonText 빌드 규칙:
    - hookType=`action_stat`: `'${threshold}회의 ${questTypeName} 활동'` (e.g. "20회의 도적 소탕")
    - hookType=`status`: title.narrativeHint 그대로 (e.g. "폐광에서 살아 돌아온 자")
    - hookType=`achievement`: 본 다이얼로그 미사용

- **[FR-35] AchievementUnlockedDialog grantedTitles 1줄 인라인 통합**
  - 위치: `band_of_mercenaries/lib/features/achievement/view/achievement_unlocked_dialog.dart` (페이즈 4 #1 신규 파일, 본 명세에서 확장)
  - 시그니처 확장:
    ```dart
    class AchievementUnlockedDialog extends StatelessWidget {
      final BandAchievement achievement;
      final List<TitleData> grantedTitles;  // 신규 (페이즈 4 #1: 미존재)
      const AchievementUnlockedDialog({..., this.grantedTitles = const []});
    }
    ```
  - UI 변경: description 다음에 grantedTitles 1줄 추가:
    - 0개: 라인 미표시
    - 1~2개: `Text('┝ 칭호 획득: ${grantedTitles.map((t) => t.name).join(", ")}')`
    - 3개+: `Text('┝ 칭호 획득: ${grantedTitles.first.name} 외 ${grantedTitles.length - 1}종')`
  - 스타일: chainGold 색상 + 12px font

- **[FR-36] app.dart dialog builder 매핑 등록**
  - 위치: `band_of_mercenaries/lib/app.dart` (dialog builder 매핑 영역)
  - 추가: `titleUnlocked` 키 → `TitleUnlockedDialog` 빌더 매핑 (PersistedDialogEntry 복원 시 사용)

#### (k) ActivityLogType 확장

- **[FR-37] ActivityLogType.titleUnlocked HiveField 30 추가**
  - 위치: `band_of_mercenaries/lib/core/domain/activity_log_model.dart`
  - 추가: `@HiveField(30) titleUnlocked,` (현재 29: `achievementUnlocked`)
  - 메시지 패턴: `'┝ ${mercName}이(가) "${titleName}" 칭호를 얻었다'`
  - **CLAUDE.md 표 갱신**: ActivityLogType (enum) HiveField 30 → **31**
  - **build_runner**: `activity_log_model.g.dart` 재생성

#### (l) UI — 홈 + 용병 상세

- **[FR-38] HomeScreen 간판 용병 카드 신규 위젯 추가**
  - 위치 1: `band_of_mercenaries/lib/features/title/view/flagship_home_card.dart` (신규 위젯 파일)
  - 위치 2: `band_of_mercenaries/lib/features/home/view/home_screen.dart` (위젯 배치)
  - 배치: 야영지 이미지 다음, ChronicleHomeCard 직전
  - 시그니처:
    ```dart
    class FlagshipHomeCard extends ConsumerWidget {
      const FlagshipHomeCard({super.key});
      @override Widget build(BuildContext context, WidgetRef ref) {
        final merc = ref.watch(flagshipMercenaryProvider);
        final isManual = ref.watch(userDataProvider)?.flagshipMercId != null;
        // ...
      }
    }
    ```
  - UI: §2.3 wireframe 01 참조 (chainGold border + tierBadge + name+job + recruitDays + title chips Wrap + dispatchBadge)
  - 탭 동작: 카드 전체 GestureDetector → `selectedMercenaryIdProvider.state = merc.id` (앱 레벨 오버레이 트리거)
  - 빈 상태 (merc == null): "용병단의 새 간판을 기다립니다 — 새 용병을 모집해 보세요" 텍스트 1줄 카드

- **[FR-39] MercenaryDetailOverlay 칭호 섹션 + 4상태 간판 토글**
  - 위치 1: `band_of_mercenaries/lib/features/title/view/titles_section.dart` (신규 위젯)
  - 위치 2: `band_of_mercenaries/lib/features/title/view/flagship_toggle_button.dart` (신규 위젯)
  - 위치 3: `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` (배치)
  - 배치: trait_slot_grid 다음, behavior_stats_section 직전
  - TitlesSection 시그니처: `TitlesSection({required Mercenary mercenary})` — `mercenaryTitlesProvider(mercId)` watch로 TitleData 리스트 조회
  - UI: §2.3 wireframe 02 참조 (chainGold border + 각 칭호 카드: icon + name + reasonText + effect line + flagshipToggleButton 하단)
  - 빈 상태 (titleIds.isEmpty): "아직 칭호가 없습니다 — 위업으로 이름을 남겨 보세요" 텍스트 1줄
  - **4상태 간판 토글 분기 (FlagshipToggleButton)**:
    1. 자동 + 이 용병이 현재 간판: 라벨 "현재 자동 간판" (Text only) + [수동 고정] 버튼 활성
    2. 자동 + 다른 용병이 간판: [★ 간판으로 지정 (수동)] 버튼 활성
    3. 수동 + 이 용병이 간판: [간판 해제 → 자동 복귀] 버튼 활성
    4. 수동 + 다른 용병이 간판: [★ 이 용병으로 변경] 버튼 활성
  - 버튼 탭 동작:
    - 수동 고정/변경: `userDataNotifier.setFlagshipMercId(merc.id)` + activityLog "간판 용병이 ${name}으로 지정되었다"
    - 해제: `userDataNotifier.clearFlagship()` + activityLog "간판 용병 자동 선정으로 돌아왔다"

- **[FR-40] mercenaryTitlesProvider family Provider 신규**
  - 위치: `band_of_mercenaries/lib/features/title/domain/title_provider.dart` (동일 파일)
  - 시그니처:
    ```dart
    final mercenaryTitlesProvider = Provider.family<List<TitleData>, String>((ref, mercId) {
      final mercList = ref.watch(mercenaryListProvider);
      final titles = ref.watch(titlesProvider);
      final merc = mercList.where((m) => m.id == mercId).firstOrNull;
      if (merc == null) return const [];
      return merc.titleIds
        .map((id) => titles.firstWhereOrNull((t) => t.id == id))
        .whereNotNull()
        .toList();
    });
    ```

#### (m) RecruitmentService — recruitedAt 설정

- **[FR-41] generateMercenary 시점에 recruitedAt 설정**
  - 위치: `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart` 라인 129 (Mercenary 생성자 호출)
  - 변경: `Mercenary(...) ` → `Mercenary(..., recruitedAt: DateTime.now(), titleIds: const [])` 추가
  - **starting mercenaries (라인 155)**: 동일하게 적용 (시작 용병도 recruitedAt 설정)
  - **호환성**: 기존 세이브의 mercenary는 recruitedAt == null. 5단계 정렬에서 `DateTime(2000)` fallback (§FR-17).

#### (n) 행동 지표 임계 하향 — Supabase 시드 직접 반영

- **[FR-42] 행동 지표 임계 4종 하향 (페이즈 2 #1 결정)**
  - 동작: §7.2 titles 시드 SQL INSERT의 `hook_condition.threshold` 값에 직접 반영
    - `title_road_hunter`: threshold **20** (기존 권장 30)
    - `title_veteran`: threshold **80** (기존 권장 100)
    - `title_scout_eye`: threshold **15** (기존 권장 20)
    - `title_escort_master`: threshold **12** (기존 권장 15)
  - 코드 변경 없음 (titles 테이블 데이터에서만 반영)

### 2.2 데이터 요구사항

#### Hive 박스 변경
- **`mercenaries` 박스**: Mercenary 모델 HiveField 24·25 추가 (titleIds·recruitedAt). typeId 1 유지.
- **`user` 박스**: UserData 모델 HiveField 24·25 추가 (flagshipMercId·lastDispatchProtagonistMercId). typeId 5 유지.
- **`bandAchievements` 박스**: MercenarySnapshot HiveField 5 추가 (titleIds). typeId 18 유지.
- **`activityLogs` 박스**: ActivityLogType HiveField 30 추가 (titleUnlocked). typeId 6 유지.
- **신규 박스**: 없음.

#### 정적 데이터 모델 변경
- **신규 `TitleData`** freezed + json_serializable 모델 (typeId 불요 — 정적 데이터)
- **`StaticGameData.titles: List<TitleData>`** 필드 추가
- **Supabase `titles`** 31번째 테이블 신규 — §7.1 스키마

#### 신규 enum / 클래스
- **`AchievementHookContext`** 데이터 클래스 (record 또는 plain class) — §FR-10 시그니처
- 신규 sealed/enum 없음 (기존 PassiveEffect·MercenaryStatus 그대로 재사용)

#### 밸런스 수치
- §7.2 SQL INSERT 11행 — effect_json·hook_condition·icon_key·narrative_hint 모두 페이즈 2 #1 §5.1·§5.2 결정값 반영

#### typeId 점유 갱신
- 신규 typeId 점유 없음. 다음 가용 typeId 20 그대로.

#### HiveField 점유 갱신 (CLAUDE.md 표 갱신 필요)

| 모델 | typeId | 본 명세 적용 후 HiveField | 다음 가용 |
|------|--------|------------------------|----------|
| Mercenary | 1 | 0~25 (24·25 본 명세 추가) | **26** |
| UserData | 5 | 0~25 (24·25 본 명세 추가) | **26** |
| MercenarySnapshot | 18 | 0~5 (5 본 명세 추가) | **6** |
| ActivityLogType (enum) | 6 | 0~30 (30 본 명세 추가) | **31** |

### 2.3 UI 요구사항

**Visual Companion 적용** — `.superpowers/brainstorm/86694-1778834258/content/` 에 3개 wireframe HTML 작성 완료:

- **`01_home_flagship_card.html`** — 홈 야영지 간판 용병 카드 (FR-38)
  - 진입 조건: HomeScreen 최초 렌더 + flagshipMercenaryProvider watch
  - 위젯 계층: `HomeScreen > Scaffold > ListView > FlagshipHomeCard > ConstrainedBox(maxWidth: 430) > Container(chainGold border) > Row[TierBadge | Column(name+job, recruitDays, TitleChips Wrap) | DispatchBadge?]`
  - 상태/Provider: `flagshipMercenaryProvider`, `mercenaryTitlesProvider`, `userDataProvider` (flagshipMercId 모드 표시)
  - 화면 전환: 카드 탭 → `selectedMercenaryIdProvider.state = merc.id` (상태 기반, Navigator.push 금지)

- **`02_mercenary_detail_titles_section.html`** — 용병 상세 칭호 섹션 + 4상태 간판 토글 (FR-39)
  - 진입 조건: selectedMercenaryIdProvider 발화
  - 위젯 계층: `MercenaryDetailOverlay > SingleChildScrollView > Column[profile_header, trait_slot_grid, TitlesSection (신규), behavior_stats_section, trait_history_section]`
  - TitlesSection 내부: `Container > Column[HeaderRow, TitleCard×N, FlagshipToggleButton]`
  - 상태/Provider: `mercenaryTitlesProvider(mercId)` family, `flagshipMercenaryProvider` watch, `userDataProvider`
  - 4상태 토글 버튼: FR-39 분기 참조

- **`03_title_unlocked_dialog.html`** — TitleUnlockedDialog (b)·(c) hook 전용 (FR-34)
  - 진입 조건: dialogQueue → titleUnlockedRequest dequeue
  - 위젯 계층: `TitleUnlockedDialog > AlertDialog > Column[DecorationHeader, TitleName, Container(MercSnapshot+Reason), EffectRow, ConfirmButton]`
  - 다이얼로그 큐: `DialogTypeRegistry.titleUnlocked` 신규 키, priority high, barrierDismissible: false
  - app.dart builder 매핑 등록 (FR-36)

#### 연출/애니메이션
- 별도 애니메이션 없음 (페이즈 4 #1 패턴 따름)
- TitleUnlockedDialog AlertDialog 기본 fade 전환

#### 색상 / Theme
- 신규 색상 없음 — 기존 `AppTheme.chainGold` (0xFFD4AF37) 재사용
- TitleCard / FlagshipHomeCard / TitleUnlockedDialog 강조 border + accent color

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` | HiveField 24·25 추가 (titleIds, recruitedAt) | FR-1 |
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField 24·25 추가 (flagshipMercId, lastDispatchProtagonistMercId) | FR-2·FR-27 |
| `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.dart` | HiveField 5 추가 (titleIds) + fromMercenary 시그니처 확장 | FR-3 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | allTables에 `'titles'` 31번째 등록 | FR-6 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `titles` 필드 추가 + FutureProvider 로드 분기 | FR-7 |
| `band_of_mercenaries/lib/core/domain/passive_bonus_service.dart` | collect 시그니처 + getQuestRewardMultiplier/getMercenaryXpBonus 가산 상한 | FR-21 |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_service.dart` | grant 본체 fail-soft 4단계에 evaluateAchievementHook 통합 + 시그니처 확장 | FR-23 |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_service_provider.dart` | TitleService 콜백 의존성 주입 + buildAchievementDialog 시그니처 변경 | FR-24 |
| `band_of_mercenaries/lib/features/achievement/view/achievement_unlocked_dialog.dart` | grantedTitles 인자 추가 + 1줄 인라인 UI | FR-35 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | evaluateActionStatHook + updateLastDispatchProtagonist + region_N_dispatch_count 갱신 + evaluateStatusHook (부상 분기) | FR-29·FR-30 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 사망 분기 MercenarySnapshot.fromMercenary 호출 시 titleIds 동결 + flagship 해제 분기 | FR-31 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | dismiss 호출 시 flagship 해제 + updateTitleIds 메서드 추가 | FR-15·FR-31 |
| `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` | updateTitleIds 위임 추가 (선택, 일관성) | FR-15 |
| `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart` | generateMercenary 시점 recruitedAt = DateTime.now() 설정 | FR-41 |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | UserDataNotifier에 setFlagshipMercId/clearFlagship/updateLastDispatchProtagonist 메서드 추가 | FR-32 |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | DialogTypeRegistry.titleUnlocked 키 추가 | FR-33 |
| `band_of_mercenaries/lib/app.dart` | dialog builder 매핑에 titleUnlocked → TitleUnlockedDialog 등록 | FR-36 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | ActivityLogType.titleUnlocked HiveField 30 추가 | FR-37 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | FlagshipHomeCard 위젯 배치 (야영지 이미지 다음, ChronicleHomeCard 직전) | FR-38 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` | TitlesSection 위젯 배치 (trait_slot_grid 다음) | FR-39 |
| `CLAUDE.md` | HiveField 점유 표 갱신 + DialogTypeRegistry 10→11 + Supabase 테이블 30→31 + bandAchievement·title·flagship 영역 동기 | 본 명세 적용 후 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/title_data.dart` | TitleData freezed 모델 (FR-4) |
| `band_of_mercenaries/lib/features/title/domain/title_service.dart` | TitleService 4 메서드 + AchievementHookContext (FR-9~FR-13) |
| `band_of_mercenaries/lib/features/title/domain/title_service_provider.dart` | titleServiceProvider (FR-14) |
| `band_of_mercenaries/lib/features/title/domain/title_provider.dart` | titlesProvider + mercenaryTitlesProvider(family) (FR-8·FR-40) |
| `band_of_mercenaries/lib/features/title/domain/flagship_mercenary_service.dart` | FlagshipMercenaryService 4 메서드 (FR-16~FR-18) |
| `band_of_mercenaries/lib/features/title/domain/flagship_provider.dart` | flagshipMercenaryProvider + flagshipMercenaryServiceProvider (FR-19·FR-20) |
| `band_of_mercenaries/lib/features/title/domain/mercenary_title_effects.dart` | collectFor static helper (FR-22) |
| `band_of_mercenaries/lib/features/title/domain/achievement_hook_context_builder.dart` | buildAchievementHookContext helper (FR-25) |
| `band_of_mercenaries/lib/features/title/domain/top_contributor_helper.dart` | compute24hTopContributor helper (FR-28) |
| `band_of_mercenaries/lib/features/title/view/flagship_home_card.dart` | FlagshipHomeCard 위젯 (FR-38) |
| `band_of_mercenaries/lib/features/title/view/titles_section.dart` | TitlesSection 위젯 (FR-39) |
| `band_of_mercenaries/lib/features/title/view/flagship_toggle_button.dart` | FlagshipToggleButton 4상태 위젯 (FR-39) |
| `band_of_mercenaries/lib/features/title/view/title_unlocked_dialog.dart` | TitleUnlockedDialog 신규 (FR-34) |
| Supabase migration | `titles` 테이블 CREATE + 11행 INSERT + data_versions INSERT (§7) |
| `Docs/changelog-fragments/{date}_m6-phase4-2-titles-flagship.md` | CHANGELOG fragment |

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.g.dart` | Mercenary HiveField 24·25 추가 (FR-1) |
| `band_of_mercenaries/lib/core/models/user_data.g.dart` | UserData HiveField 24·25 추가 (FR-2·FR-27) |
| `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.g.dart` | MercenarySnapshot HiveField 5 추가 (FR-3) |
| `band_of_mercenaries/lib/core/models/title_data.freezed.dart` | TitleData freezed 생성 (FR-4) |
| `band_of_mercenaries/lib/core/models/title_data.g.dart` | TitleData fromJson/toJson 생성 (FR-4) |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | ActivityLogType.titleUnlocked HiveField 30 추가 (FR-37) |

빌드 명령: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`

### 3.4 관련 시스템

- **Mercenary 시스템**: titleIds·recruitedAt 영속화 + dismiss 분기 + 사망 분기 +recruit 시점 recruitedAt 설정
- **AchievementService 시스템 (페이즈 4 #1)**: grant 본체 fail-soft 4단계에 evaluateAchievementHook 통합 + grantedTitles payload 부착
- **PassiveBonusService 시스템**: titleEffects 인자 추가 + 가산 상한 +0.30 명시 + mercenary 단위 호출처 4곳 확장
- **DialogQueue 시스템**: titleUnlocked 11번째 + barrierDismissible: false high priority
- **ActivityLog 시스템**: HiveField 30 추가
- **Home/MercenaryDetail UI 시스템**: 신규 카드/섹션 위젯 배치 + 상태 기반 렌더링 패턴
- **QuestCompletion 시스템**: 파견 결과 처리 직후 4가지 hook 호출 (action_stat + status + last_dispatch_protagonist + region_N_dispatch_count)
- **RecruitmentService 시스템**: generateMercenary 시점 recruitedAt 일괄 설정

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **콜백 DI 패턴 (Provider 순환 참조 회피)**:
  - `band_of_mercenaries/lib/features/achievement/domain/achievement_service.dart` (페이즈 4 #1) — Service 클래스가 Provider 없이 콜백 받음. TitleService도 동일 패턴.
  - `band_of_mercenaries/lib/features/achievement/domain/achievement_service_provider.dart` — re-export 패턴. TitleService도 동일.
- **fail-soft trailing 사이드이펙트**:
  - `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` `completeChain()` — try/catch + debugPrint
  - 본 명세 모든 hook 호출 (FR-23·FR-29·FR-30·FR-31) 동일 패턴
- **Hive 박스 + freezed 모델 결합**:
  - `band_of_mercenaries/lib/features/achievement/domain/band_achievement_model.dart` (typeId 16, HiveField 0~6)
  - `band_of_mercenaries/lib/core/models/passive_effect.dart` — sealed PassiveEffect (Map 직렬화)
- **StateNotifier + box.watch 구독**:
  - `band_of_mercenaries/lib/features/achievement/domain/achievement_provider.dart` `bandAchievementsProvider` — 본 명세는 `flagshipMercenaryProvider`가 동일 패턴 (mercenaryListProvider + bandAchievementsProvider watch)
- **family Provider 캐시**:
  - `band_of_mercenaries/lib/features/achievement/domain/achievement_provider.dart` `renderedAchievementProvider` — `mercenaryTitlesProvider(mercId)` 동일 패턴
- **AlertDialog + high priority dialog**:
  - `band_of_mercenaries/lib/features/achievement/view/achievement_unlocked_dialog.dart`
  - `band_of_mercenaries/lib/features/quest/view/region_transformed_dialog.dart`
- **사망/방출 직전 MercenarySnapshot 동결**:
  - `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` 라인 178~195 — recordMemorial 호출 직전 snapshot 구성. titleIds도 동일 시점 동결 (FR-3 fromMercenary 자동 처리).
- **PassiveBonusService 호출 패턴**:
  - `band_of_mercenaries/lib/core/domain/passive_bonus_context.dart` — CollectedEffects 래퍼 + helper 메서드 (getXxx)
  - 본 명세는 `titleEffects` 인자만 추가, 기존 패턴 유지

### 4.2 주의사항

- **CLAUDE.md 규칙 준수**:
  - 화면 전환은 `Navigator.push` 대신 상태 기반 렌더링 — FlagshipHomeCard 탭 → `selectedMercenaryIdProvider.state = merc.id` (오버레이 트리거)
  - 한국어 응답·코드 주석 유지
  - 공통 위젯은 같은 패턴 3개 파일 이상 반복 시 `shared/widgets/` 이동 — 본 명세 신규 위젯 6개는 features/title/view/ 하위로 모듈화
- **freezed 호환**:
  - TitleData `@JsonKey(name: 'hook_type')` 형식 — Supabase snake_case 호환
  - `@Default({})` Map / `@Default('default')` String 명시
- **typeId 점유 보존**:
  - 신규 모델 typeId 추가 없음
  - 다음 가용 typeId 20 그대로 유지
- **build_runner 재실행 순서**:
  - `mercenary_model.g.dart` / `user_data.g.dart` / `mercenary_snapshot_model.g.dart` / `activity_log_model.g.dart` / `title_data.freezed.dart` / `title_data.g.dart` 동시 생성
  - 명령: `dart run build_runner build --delete-conflicting-outputs`
- **`titleIds` 빈 리스트 처리**:
  - Hive 자동 mapping 시 `null` 또는 `<dynamic>` 변환 가능 → 생성자에서 `List<String>.from(titleIds ?? const [])` 또는 default 빈 리스트 사용. 기존 `traitIds` 패턴 따름.
- **MercenarySnapshot.fromMercenary 호환성**:
  - 페이즈 4 #1 호출처 (chainQuestService, region_state_repository, quest_provider, mercenary_provider, crafting_service)는 모두 `titleIds` 미주입 → mercenary.titleIds 자동 사본 동결
  - 별도 호출처 수정 불요 (시그니처 backward compatible)
- **CLAUDE.md 다이얼로그 큐 정책**:
  - high priority: chain·transform·trustUp·**achievementUnlocked**·**titleUnlocked** (본 명세 추가)
  - barrierDismissible: false (확인 버튼만 dismiss)
- **순환 참조 회피**:
  - TitleService → AchievementService.hasAchievement 콜백 (역방향: AchievementService → TitleService.evaluateAchievementHook 콜백) — 콜백 nullable 처리로 안전 분리
  - `title_service_provider.dart` 분리 + `title_provider.dart`에서 re-export 패턴

### 4.3 엣지 케이스

- **사망 mercenary가 dialog 큐에 enqueue된 채 dequeue 시점**: TitleUnlockedDialog의 mercSnapshot은 발급 시점 영구 동결되므로 사망 후 표시 가능 (Snapshot 5필드 + titleIds 모두 보존).
- **flagshipMercId가 dead mercenary를 가리키는 경우**: FlagshipMercenaryProvider FR-19 분기 (`flagshipMercId != null && mercList에서 발견`) 시 dead mercenary 반환 가능 — FlagshipHomeCard UI에서 dead 표시 또는 빈 상태로 전환. FR-31에서 dismiss/사망 시 clearFlagship 호출하므로 정상 흐름에서는 발생 안 함. 데이터 파손 fallback: `merc.status == dead` 시 자동 알고리즘으로 fallback.
- **선천 + 후천 칭호 동시 발급**: 한 위업에 매칭되는 칭호 0~N개. evaluateAchievementHook이 List 반환 → AchievementUnlockedDialog 1줄 인라인 표시 (3개+는 "외 N종").
- **모집 시 칭호 0개 보장**: RecruitmentService.generateMercenary는 `titleIds: const []` 명시 (FR-41). 트레잇 발급 hook과 분리.
- **사망 → 부상 강등 (legendary 특수효과)**: quest_completion_service.dart 라인 286~307 — `MercenaryStatus.dead`가 부상으로 다운그레이드되는 경우 evaluateStatusHook이 평가 (FR-30) — `injured` 상태로 변경되므로 폐광의 생존자 칭호 hook 발급 정상 동작.
- **flagshipMercenaryProvider에서 candidates.isEmpty 시**: null 반환. UI 빈 상태 분기.
- **lastDispatchProtagonistMercId가 dead mercenary**: AchievementHookContext.lastDispatchTopMercId가 dead mercenary id를 가리킬 수 있음. TitleService.evaluateAchievementHook 내부에서 `getMercenary(id)?.status != dead` 검증 → dead면 skip.
- **`titleIds` 자체 발견 불가 ID 보유**: titles 캐시 미존재 ID (예: 운영자가 Supabase에서 삭제한 칭호). mercenaryTitlesProvider에서 `firstWhereOrNull`로 null skip — 표시·효과 자동 제거 (Hive 박스에는 ID만 잔존).
- **hook_target=most_dispatched_to_region_3 시 region_3 dispatch 카운터 미존재**: 기존 mercenary들의 stats에 키 없음. FR-26 갱신 시점 이후만 추적. fallback: 빈 Map → silent skip.
- **PassiveBonusService 호출 시 titleEffects 미주입**: default 빈 리스트 → 기존 효과만 합산 (backward compatible).
- **questRewardMultiplier 상한 +0.30 도달**: 칭호 + 세력 합산 초과 시 자동 clamp. lossAmount 추적 미적용 (현재 코드 패턴 따름).

### 4.4 구현 힌트

- **진입점**:
  - 칭호 발급: `TitleService` 3 메서드 (evaluateAchievementHook/evaluateActionStatHook/evaluateStatusHook)
  - 간판 노출: `flagshipMercenaryProvider` Riverpod auto-recompute
  - UI 진입: HomeScreen (FlagshipHomeCard) + MercenaryDetailOverlay (TitlesSection) + dialogQueue (TitleUnlockedDialog/AchievementUnlockedDialog)

- **데이터 흐름** (칭호 발급 흐름):
  ```
  파견 완료 (quest_completion_service)
    → mercenary.stats[raid_count] += 1
    → titleService.evaluateActionStatHook(mercId)
       → titles.where(hookType==action_stat) 순회
       → mercenary.stats[stat_key] >= threshold
       → _grantTitle: titleIds.add → save → log
       → enqueueDialog(TitleUnlockedDialog) [high priority]

  체인 완주 (chain_quest_service)
    → AchievementService.grant(chain_completed:...)
       → evaluateAchievementHook(achievement, ctx)
          → titles.where(hookType==achievement) 순회
          → hook_target 분기로 targetMercId 결정
          → _grantTitle (mercenary.titleIds.add)
          → return List<TitleData>
       → enqueueDialog(AchievementUnlockedDialog, grantedTitles)  // 1줄 인라인
  ```

- **데이터 흐름** (간판 자동 선정 흐름):
  ```
  사용자 동작 (모집/사망/방출/위업 발급/레벨업)
    → mercenaryList 변경 또는 bandAchievements 변경 또는 userData 변경
    → flagshipMercenaryProvider 자동 재계산 (Riverpod watch)
       → userData.flagshipMercId != null: 매칭 mercenary 반환 (수동)
       → null: FlagshipMercenaryService.selectAuto()
         → 5단계 정렬 → 1위 반환 (자동)
    → FlagshipHomeCard 자동 리빌드
  ```

- **참조 구현**:
  - `band_of_mercenaries/lib/features/achievement/domain/achievement_service.dart` — TitleService 거울 패턴
  - `band_of_mercenaries/lib/features/achievement/domain/achievement_service_provider.dart` — titleServiceProvider 거울 패턴
  - `band_of_mercenaries/lib/features/achievement/domain/achievement_provider.dart` — mercenaryTitlesProvider family·flagshipMercenaryProvider 거울 패턴
  - `band_of_mercenaries/lib/features/achievement/view/achievement_unlocked_dialog.dart` — TitleUnlockedDialog 거울 패턴
  - `band_of_mercenaries/lib/features/achievement/view/chronicle_home_card.dart` — FlagshipHomeCard 거울 패턴
  - `band_of_mercenaries/lib/features/quest/domain/chain_quest_service.dart` `completeChain()` — fail-soft trailing 패턴
  - `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` 라인 830~870 (elite hook) — hasAchievement + grant 패턴

- **확장 지점**:
  - 페이즈 4 #3 (지명 의뢰): `Mercenary.titleIds` + `UserData.flagshipMercId` + `MercenarySnapshot.titleIds` 시그니처 의존
  - 페이즈 5+ 칭호 시너지: TitlesData.effectJson에 추가 필드 가능 (sealed 변경 없음)
  - operation-bom titles CRUD UI 별도 작업

---

## 5. 기획 확인 사항

- [Q-1] **PassiveBonusService.collectFor의 파티 다수 mercenary 합산 정책** → 본 명세는 "퀘스트 시 파티 첫 번째 mercenary 단독" 정책으로 단순화. 페이즈 5+에서 파티 전원 합산 결정 검토. 사용자 확정.
- [Q-2] **top_contributor_24h 단순화** → 24h 윈도우 추적 인프라 부재로 "전체 누적 success_count + great_success_count 1위 mercenary"로 단순화. roadmap 종료 조건 충족. 페이즈 5+에서 정교화 검토. 사용자 확정.
- [Q-3] **questRewardMultiplier 가산 상한 +0.30** → 페이즈 2 #1 Q-1 결정 채택. reputationGainModifier (+0.30)와 동일 정책. PassiveBonusService 코드에 clamp 적용.
- [Q-4] **mercenaryXpBonus 가산 상한 +0.30** → 페이즈 2 #1 Q-2 결정 채택. 동일 상한 정책.
- [Q-5] **hook_target 11종 모두 구현** → 사용자 결정. last_dispatch_protagonist는 lastDispatchProtagonistMercId UserData HiveField 25 캐시 (FR-27). most_dispatched_to_region_3는 Mercenary.stats region_N_dispatch_count 카운터 (FR-26). top_contributor_24h는 §FR-28 단순화 fallback.
- [Q-6] **칭호 발급 시 다이얼로그 dismiss 정책** → barrierDismissible: false + 확인 버튼만 dismiss. (페이즈 4 #1 AchievementUnlockedDialog와 동일)
- [Q-7] **사용자 수동 칭호 제거 기능** → 미도입. M6 MVP는 자동 부여·자동 누적·자동 보존만. 페이즈 5+에서 검토.
- [Q-8] **기존 세이브 recruitedAt 마이그레이션** → null fallback `DateTime(2000)`만 적용. 1회성 마이그레이션 미적용 (사용자 체감 무영향). 신규 모집부터 자동 설정.
- [Q-9] **flagshipMercId == null 시 자동 알고리즘 결과 캐싱** → 미적용. flagshipMercenaryProvider가 매번 5단계 정렬 (mercenary 7명 정도라 비용 무시 가능).
- [Q-10] **칭호 효과 합산 평가 시점** → quest_completion_service / investigation_notifier 두 위치에서만 mercenary 단위 합산 적용 (FR-22). 다른 호출처 (idle reward, recruitment cost, facility cost, travel event)는 용병단 단위라 칭호 합산 미적용. 페이즈 5+에서 정교화 검토.

---

## 6. TASK 분할 가이드 (implement-agent용)

페이즈 4 #1 패턴 따라 약 15~18 TASK 순차 격리 모드 권장.

- **TASK 1**: Mercenary 모델 HiveField 24·25 + UserData HiveField 24·25 + MercenarySnapshot HiveField 5 + ActivityLogType HiveField 30 — 4개 모델 동시 확장 (FR-1·FR-2·FR-3·FR-27·FR-37) → build_runner 실행
- **TASK 2**: TitleData freezed 모델 신규 (FR-4) → build_runner 실행
- **TASK 3**: Supabase `titles` 테이블 CREATE + 11행 INSERT + data_versions INSERT (§7) — Supabase MCP 호출
- **TASK 4**: SyncService 31번째 등록 + StaticGameData.titles 필드 + titlesProvider Provider (FR-6·FR-7·FR-8)
- **TASK 5**: TitleService 도메인 클래스 + AchievementHookContext + titleServiceProvider (FR-9~FR-14)
- **TASK 6**: hook_target 보조 인프라 — region_N_dispatch_count 카운터 + UserDataNotifier.updateLastDispatchProtagonist + top_contributor_24h helper (FR-26·FR-27·FR-28·FR-32)
- **TASK 7**: MercenaryListNotifier.updateTitleIds + MercenaryRepository 위임 (FR-15)
- **TASK 8**: FlagshipMercenaryService + flagshipMercenaryProvider + flagshipMercenaryServiceProvider (FR-16~FR-20)
- **TASK 9**: PassiveBonusService.collect titleEffects 인자 + 가산 상한 명시 + MercenaryTitleEffects helper (FR-21·FR-22)
- **TASK 10**: AchievementService.grant 본체 fail-soft 확장 + AchievementHookContext 빌더 (FR-23·FR-24·FR-25)
- **TASK 11**: QuestCompletionService 4 hook 통합 (action_stat + lastDispatch + region 카운터 + status injured) (FR-29·FR-30)
- **TASK 12**: mercenary_provider.dismiss + quest_provider 사망 분기 — flagship 해제 + snapshot titleIds 동결 (FR-31)
- **TASK 13**: RecruitmentService.generateMercenary recruitedAt 설정 (FR-41)
- **TASK 14**: DialogTypeRegistry titleUnlocked + TitleUnlockedDialog 위젯 + AchievementUnlockedDialog 인라인 통합 + app.dart builder 매핑 (FR-33~FR-36)
- **TASK 15**: FlagshipHomeCard 위젯 + HomeScreen 배치 (FR-38)
- **TASK 16**: TitlesSection 위젯 + FlagshipToggleButton 4상태 + MercenaryDetailOverlay 배치 + mercenaryTitlesProvider family (FR-39·FR-40)
- **TASK 17**: 통합 빌드 게이트 — `flutter analyze` + `flutter test` 통과 + 데모 시나리오 (위업 발급 → 칭호 인라인 + dialog 큐 + 홈 카드 갱신 + 사망 후 titleIds 동결 표시)
- **TASK 18**: CLAUDE.md 표 갱신 + CHANGELOG fragment 작성 (HiveField 점유 / DialogTypeRegistry 11종 / Supabase 31번째)

각 TASK는 verifier(명세 준수) + flutter-reviewer(품질) 2단 리뷰 + dart-build-resolver 대기.

---

## 7. Supabase `titles` 테이블 + 11행 시드 SQL (인라인)

### 7.1 테이블 스키마

```sql
CREATE TABLE IF NOT EXISTS public.titles (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  description     TEXT NOT NULL,
  hook_type       TEXT NOT NULL CHECK (hook_type IN ('achievement', 'action_stat', 'status')),
  hook_condition  JSONB NOT NULL DEFAULT '{}'::jsonb,
  effect_json     JSONB NOT NULL DEFAULT '{}'::jsonb,
  icon_key        TEXT NOT NULL DEFAULT 'default',
  narrative_hint  TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_titles_hook_type ON public.titles (hook_type);

-- data_versions에 신규 테이블 등록
INSERT INTO public.data_versions (table_name, version, updated_at)
VALUES ('titles', 1, NOW())
ON CONFLICT (table_name) DO UPDATE SET version = EXCLUDED.version, updated_at = EXCLUDED.updated_at;
```

### 7.2 11행 시드 INSERT

```sql
-- 1. 마을의 은인 (a) - 거점 사건 완주 위업 hook
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_village_savior',
 '마을의 은인',
 '더스트빌의 사건을 해결하고 작은 잔치의 주역이 된 용병.',
 'achievement',
 '{"achievement_template_id": "settlement_event_completed:settlement_3_pyegwang_reopen", "hook_target": "require_protagonist"}'::jsonb,
 '{"effects": [{"type": "quest_success_rate_bonus", "quest_type": "all", "value": 0.025}]}'::jsonb,
 'ic_village_savior',
 '거점 사건 주인공에게 부여. 광역 +2.5%p (페이즈 2 #1 미세 하향).');

-- 2. 폐광의 생존자 (c) - 상태 hook (부상에서 회복)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_pyegwang_survivor',
 '폐광의 생존자',
 '폐광의 어둠 속에서 부상을 입고도 다시 일어선 자.',
 'status',
 '{"trigger_status": "injured", "context": {"chain_id": "settlement_3_pyegwang_reopen", "require_chain_completion": true}}'::jsonb,
 '{"effects": [{"type": "recovery_time_reduction", "status": "injured", "value": -0.10}]}'::jsonb,
 'ic_survivor',
 '폐광 체인 완주 중 부상 진입 시 부여. 회복 -10%.');

-- 3. 첫 깃발을 든 자 (a) - 제작 첫 희귀 위업 hook (last_dispatch_protagonist)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_first_banner',
 '첫 깃발을 든 자',
 '용병단의 깃발을 처음 휘날린 자.',
 'achievement',
 '{"achievement_template_id": "craft_first_rare:recipe_dustvile_banner_restoration", "hook_target": "last_dispatch_protagonist"}'::jsonb,
 '{"effects": [{"type": "reputation_gain_modifier", "value": 0.02}]}'::jsonb,
 'ic_banner',
 '깃발 복원 위업 발급 시 최근 파견 1위 mercenary에게 부여. 명성 +2%.');

-- 4. 도적길 추적자 (b) - 행동 지표 hook (raid_count >= 20, 페이즈 2 #1 하향)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_road_hunter',
 '도적길 추적자',
 '도적을 쫓아 거리를 누빈 자.',
 'action_stat',
 '{"stat_key": "raid_count", "threshold": 20, "operator": ">="}'::jsonb,
 '{"effects": [{"type": "quest_success_rate_bonus", "quest_type": "raid", "value": 0.05}]}'::jsonb,
 'ic_road_hunter',
 '20회 약탈 의뢰 누적 시 부여. raid 한정 +5%p.');

-- 5. 백전노장 (b) - 행동 지표 hook (total_dispatch_count >= 80, 페이즈 2 #1 하향)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_veteran',
 '백전노장',
 '수많은 의뢰를 견디며 단단해진 노련한 용병.',
 'action_stat',
 '{"stat_key": "total_dispatch_count", "threshold": 80, "operator": ">="}'::jsonb,
 '{"effects": [{"type": "injury_rate_modifier", "value": -0.03}]}'::jsonb,
 'ic_veteran',
 '80회 누적 파견 시 부여. 부상률 -3%.');

-- 6. 정찰의 눈 (b) - 행동 지표 hook (explore_count >= 15, 페이즈 2 #1 하향)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_scout_eye',
 '정찰의 눈',
 '예리한 시선으로 미답의 길을 밝힌 자.',
 'action_stat',
 '{"stat_key": "explore_count", "threshold": 15, "operator": ">="}'::jsonb,
 '{"effects": [{"type": "investigation_success_rate_bonus", "value": 0.05}]}'::jsonb,
 'ic_scout_eye',
 '15회 정찰/조사 누적 시 부여. 조사 +5%p.');

-- 7. 호위의 노련함 (b) - 행동 지표 hook (escort_count >= 12, 페이즈 2 #1 하향)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_escort_master',
 '호위의 노련함',
 '의뢰인을 끝까지 지켜낸 침착한 호위자.',
 'action_stat',
 '{"stat_key": "escort_count", "threshold": 12, "operator": ">="}'::jsonb,
 '{"effects": [{"type": "quest_success_rate_bonus", "quest_type": "escort", "value": 0.05}]}'::jsonb,
 'ic_escort_master',
 '12회 호위 의뢰 누적 시 부여. escort 한정 +5%p.');

-- 8. 더스트빌의 친우 (a) - 거점 소속 위업 hook (most_dispatched_to_region_3)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_dustvile_friend',
 '더스트빌의 친우',
 '더스트빌 사람들이 이름을 부르는 가까운 동무.',
 'achievement',
 '{"achievement_template_id": "settlement_trust_belonging:region_3", "hook_target": "most_dispatched_to_region_3"}'::jsonb,
 '{"effects": [{"type": "quest_reward_multiplier", "quest_type": "all", "value": 0.02}]}'::jsonb,
 'ic_dustvile_friend',
 '거점 소속 위업 발급 시 region 3 최다 파견 mercenary에게 부여. 보상 +2% (페이즈 2 #1 미세 하향).');

-- 9. 괴물 사냥꾼 (a) - 엘리트 유니크 첫 처치 hook (first_only)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_monster_hunter',
 '괴물 사냥꾼',
 '평범하지 않은 짐승을 처음 마주하고 끝낸 자.',
 'achievement',
 '{"achievement_template_id_prefix": "elite_unique_first_kill:", "first_only": true, "hook_target": "require_protagonist"}'::jsonb,
 '{"effects": [{"type": "quest_success_rate_bonus", "quest_type": "hunt", "value": 0.05}]}'::jsonb,
 'ic_monster_hunter',
 '8 유니크 엘리트 첫 처치 위업 중 첫 1회만 부여. hunt 한정 +5%p.');

-- 10. 이름을 알린 자 (a) - 명성 D 진입 hook (top_contributor_24h)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_renowned',
 '이름을 알린 자',
 '용병단의 명성을 처음 세상에 알린 자.',
 'achievement',
 '{"achievement_template_id": "reputation_rank:D", "hook_target": "top_contributor_24h"}'::jsonb,
 '{"effects": [{"type": "reputation_gain_modifier", "value": 0.03}]}'::jsonb,
 'ic_renowned',
 '명성 D 등급 진입 시 24h 누적 기여 1위 mercenary에게 부여. 명성 +3%.');

-- 11. 혼을 끊은 자 (a) - 엔드 칭호, 체인 완주 hook (require_protagonist)
INSERT INTO public.titles (id, name, description, hook_type, hook_condition, effect_json, icon_key, narrative_hint) VALUES
('title_soul_severer',
 '혼을 끊은 자',
 '저주의 매듭을 끊고 망령의 굴레에서 자유롭게 한 자.',
 'achievement',
 '{"achievement_template_id": "chain_completed:chain_soul_severance", "hook_target": "require_protagonist"}'::jsonb,
 '{"effects": [{"type": "reputation_gain_modifier", "value": 0.05}, {"type": "mercenary_xp_bonus", "value": 0.10}]}'::jsonb,
 'ic_soul_severer',
 '저주 단절 체인 완주 protagonist에게 부여. 복합 효과: 명성 +5% + XP +10%.');
```

### 7.3 데이터 일관성 검증 SQL (사후 점검)

```sql
-- 11행 INSERT 검증
SELECT COUNT(*) FROM public.titles;  -- 기대: 11

-- hook_type 분포 검증
SELECT hook_type, COUNT(*) FROM public.titles GROUP BY hook_type;
-- 기대: achievement=6, action_stat=4, status=1

-- chain_id 참조 무결성 (settlement_3_pyegwang_reopen)
SELECT t.id, c.id FROM public.titles t
LEFT JOIN public.chain_quests c ON c.id = t.hook_condition->'context'->>'chain_id'
WHERE t.id = 'title_pyegwang_survivor';

-- elite_unique_first_kill prefix 매칭 위업 카테고리 확인
SELECT * FROM public.band_achievement_templates
WHERE id LIKE 'elite_unique_first_kill:%';  -- 페이즈 4 #1 7행 placeholder 확인
```
