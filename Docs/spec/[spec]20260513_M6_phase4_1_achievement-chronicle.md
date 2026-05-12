# M6 페이즈 4 #1 — 위업·연대기 시스템 명세서

> 기획 문서:
> - `Docs/content-design/[content]20260512_achievement-chronicle-system.md` — 1차 입력 (3개념 분리 / 6 카테고리 / 데이터 모델 / UI 정책)
> - `Docs/balance-design/[balance]20260513_exposure-pacing.md` — 발급 페이스 + 모니터링 지표 6종 + 페이즈 3 스킵 권장
>
> 작성일: 2026-05-13
> 마일스톤: M6 페이즈 4 #1 — 위업·연대기 시스템 (1차)
> 선행: M3 ChainQuestService 완료 / M4 거점 신뢰도 / M5 제작 시스템
> 후속: M6 페이즈 4 #2 (칭호·간판 용병) / #3 (지명 의뢰) — MercenarySnapshot 6번째 필드(titleIds) 확장 의존
>
> Visual Companion: 미적용 (UI 와이어프레임은 §2.3에 텍스트 명세, 기획 문서 §6 다이어그램 참조)
> 페이즈 3 스킵: 칭호·지명 의뢰는 페이즈 4 #2·#3에서 인라인. **본 명세는 위업 템플릿 28행 SQL INSERT를 §6에 인라인 포함.**

---

## 1. 개요

위업·연대기 시스템은 M6 "이름을 얻는 용병단" 마일스톤의 토대 시스템이다. 후속 칭호(#2)·지명 의뢰(#3)는 본 시스템의 발급 이벤트와 mercSnapshot 영구 보존 정책을 hook 입력으로 활용한다.

핵심 기능:
- **bandAchievements** Hive 신규 박스(typeId 16+) 영속 + 6 카테고리 위업 발급 + 사망/방출 memorial 보존
- **AchievementService** 4 메서드(`grant` / `recordMemorial` / `hasAchievement` / `getAll`) + 6 hook(체인·거점사건·거점소속·명성·엘리트·제작) 통합
- **Supabase `band_achievement_templates`** 신규 테이블(30번째) + 28행 시드 SQL 인라인
- **AchievementUnlockedDialog** + **ChronicleScreen** + 홈 "연대기" 카드 + 정보 탭 진입점
- **RankUpDialog** 본체 1줄 인라인 통합(명성 카테고리는 별도 dialog 미발급)

---

## 2. 요구사항

### 2.1 기능 요구사항

#### (a) AchievementService 도메인

- **[FR-1] `AchievementService.grant(templateId, mercSnapshot?, regionId?, payload?)`**
  - 입력: `String templateId` (필수, 예: `chain_completed:chain_roadside_shrine`), `MercenarySnapshot? mercSnapshot`, `int? regionId`, `Map<String, dynamic> payload = const {}`
  - 동작: 사전에 `hasAchievement(templateId)` 호출하여 중복 차단(true 반환 시 즉시 return). 멱등성 보장.
  - 사이드이펙트 3종 순차 실행 (try/catch fail-soft):
    1. `bandAchievementsBox.add(BandAchievement(type: achievement, templateId, mercSnapshot, regionId, payload, achievedAt: DateTime.now(), id: uuid()))` — 영구 저장
    2. `activityLogProvider.notifier.addLog('★ 위업: {name} {— 주인공 mercName}', ActivityLogType.achievementUnlocked)` — 휘발 미러 1행 (이름은 templateId → name 조회 후 렌더)
    3. **카테고리 `reputation_rank` 제외**, `dialogQueueProvider.notifier.enqueue(achievementUnlockedRequest)` — high priority dialog
  - 카테고리 분류: templateId의 `:` 앞 부분(`chain_completed`, `settlement_event_completed`, `settlement_trust_belonging`, `reputation_rank`, `elite_unique_first_kill`, `craft_first_rare`)
  - `reputation_rank` 분기: bandAchievements + ActivityLog만 실행하고 dialog 큐 enqueue 생략 (RankUpDialog 본체 인라인이 대체)
  - 반환: `Future<BandAchievement?>` — 신규 발급 시 인스턴스, 중복 시 null
  - 위치: `band_of_mercenaries/lib/features/achievement/domain/achievement_service.dart` (신규)

- **[FR-2] `AchievementService.recordMemorial(cause, mercSnapshot, payload?)`**
  - 입력: `MemorialCause cause` (`diedQuest` / `diedEvent` / `released` — enum 3종), `MercenarySnapshot mercSnapshot` (필수), `Map<String, dynamic> payload = const {}`
  - 동작: `templateId = 'memorial:${cause.name}'` (예: `memorial:died_quest`) 구성 후 `bandAchievementsBox.add(BandAchievement(type: memorial, templateId, mercSnapshot, payload, achievedAt: now(), id: uuid()))`. **ActivityLog 미러 X, dialog enqueue X.**
  - 멱등성: `(mercSnapshot.id, cause)` 조합으로 사전 중복 검사 (한 용병에 대해 동일 cause로 두 번 발급되지 않음).
  - fail-soft: 저장 실패 시 ActivityLog에 에러 기록 후 정상 흐름 유지.

- **[FR-3] `AchievementService.hasAchievement(templateId) -> bool`**
  - 동작: `bandAchievementsBox.values.any((a) => a.type == achievement && a.templateId == templateId)` — 동기 호출 가능 (인메모리 Hive 박스).
  - 용도: 6 hook 멱등성 보장.

- **[FR-4] `AchievementService.getAll() -> List<BandAchievement>`**
  - 동작: `bandAchievementsBox.values.toList()..sort((a, b) => b.achievedAt.compareTo(a.achievedAt))` — 시간순 desc.
  - Provider 경유: `bandAchievementsProvider` (StateNotifier) — 박스 변경 시 자동 emit.

#### (b) 6 Hook 통합

- **[FR-5] 체인 완주 hook — 카테고리 1·2 통합**
  - 통합 지점: `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` `completeChain()` 메서드 (라인 126~159 구간)
  - 위치: `publishCompleted(event)` 호출 직후 (라인 158 부근)
  - 분기 로직:
    ```
    if (chainId.startsWith('chain_')):  // 일반 체인 7종
      templateId = 'chain_completed:$chainId'
      mercSnapshot = _buildSnapshotFromMercId(progress.protagonistMercId)
    else if (chainId.startsWith('settlement_')):  // 거점 사건
      templateId = 'settlement_event_completed:$chainId'
      mercSnapshot = _buildSnapshotFromMercId(_pickFinalStepTopContributor(finalStep.partyIds, finalStep.partyPowers))
    achievementService.grant(templateId, mercSnapshot, regionId: finalStep.regionId, payload: {'chainId': chainId})
    ```
  - **콜백 DI 패턴**: `ChainQuestService.completeChain()` 시그니처에 `Future<void> Function(String templateId, MercenarySnapshot?, int? regionId, Map<String, dynamic>) grantAchievement` 콜백 추가. 호출측(`chainQuestServiceProvider`)에서 `achievementService.grant`로 바인딩.
  - `_buildSnapshotFromMercId(String? mercId)`: mercId가 null이거나 mercenaries 박스에 없으면 null 반환. 있으면 5필드 MercenarySnapshot 구성.
  - `_pickFinalStepTopContributor(List<String> partyIds, Map<String, int>? partyPowers)`: partyPowers 1위 mercId. partyPowers 미제공 시 partyIds 첫 번째.

- **[FR-6] 거점 신뢰도 4단계 진입 hook — 카테고리 3**
  - 통합 지점: `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` `addSettlementTrust()` 메서드 (라인 143~247 구간)
  - 위치: `newLevel > oldLevel && newLevel == 4` 분기 (4단계 "소속" 진입 시점)
  - 호출: `achievementService.grant('settlement_trust_belonging:region_$regionId', mercSnapshot: null, regionId: regionId, payload: {'oldLevel': oldLevel, 'newLevel': newLevel})`
  - **콜백 DI**: `RegionStateRepository`는 이미 Riverpod ref 의존성을 가지고 있으므로 `ref.read(achievementServiceProvider).grant(...)` 직접 호출 가능. fail-soft try/catch 필수.

- **[FR-7] 명성 등급 진입 hook — 카테고리 4 (인라인 통합)**
  - 통합 지점: `band_of_mercenaries/lib/core/domain/reputation_service.dart` 또는 `userDataProvider`의 명성 갱신 분기 (rankUpProvider publish 위치)
  - 위치: 랭크 변경 후 `rankUpProvider.notifier.state = RankUpEvent(...)` publish 직후
  - 호출: `achievementService.grant('reputation_rank:$toGrade', mercSnapshot: null, regionId: null, payload: {'fromGrade': fromGrade, 'toGrade': toGrade})`
  - 분기: `toGrade in {E, D, C, B, A}`. F는 시작 등급이라 제외.
  - **dialog enqueue 생략**: AchievementService 내부에서 카테고리 `reputation_rank` 감지 시 자동 생략 ([FR-1] 분기). RankUpDialog 본체 1줄 인라인이 대체.

- **[FR-8] 엘리트 유니크 첫 처치 hook — 카테고리 5**
  - 통합 지점: `band_of_mercenaries/lib/features/quest/domain/elite_loot_service.dart` `rollDrops()` 호출 직후 또는 `quest_provider.dart`의 `_applyCompletionResult()` 내 엘리트 처치 처리부
  - 사전 조건: `eliteMonster.isUnique == true`
  - 멱등성 추적: `UserData.firstKilledEliteIds` 신규 HiveField (`Set<String>` 또는 `List<String>`)
    - **본 명세는 `UserData` 확장 회피** — `AchievementService.hasAchievement('elite_unique_first_kill:$eliteId')`로 멱등 보장. 이미 발급 시 추가 추적 불필요. (기획 §2.2 표 "firstKilledEliteIds" 표현은 개념적 의미, 실제 구현은 hasAchievement 체크로 통일)
  - 호출: `mercSnapshot = _buildSnapshotFromMercId(_pickTopContributor(quest.dispatchedMercIds, quest.contributionMap))` 후 `achievementService.grant('elite_unique_first_kill:$eliteId', mercSnapshot, regionId: quest.region, payload: {'eliteId': eliteId, 'questId': quest.id})`

- **[FR-9] 희귀(T3+) 첫 제작 hook — 카테고리 6**
  - 통합 지점: `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` `craft()` 메서드 (라인 94~120 구간)
  - 위치: `inventoryRepository.addItem(...)` 호출 직후 (제작 성공 후)
  - 사전 조건: 결과 itemData의 tier 조회 → `tier >= 3` (StaticGameData.items에서 itemId → tier 매핑)
  - 멱등성: `AchievementService.hasAchievement('craft_first_rare:$recipeId')` 체크 (FR-8과 동일 정책 — UserData 미확장)
  - 호출: `achievementService.grant('craft_first_rare:$recipeId', mercSnapshot: null, regionId: null, payload: {'recipeId': recipeId, 'itemId': resultItemId, 'tier': itemTier})`

- **[FR-10] 사망 처리 memorial hook**
  - 통합 지점:
    - `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` Mercenary 사망 처리 (파견 결과 처리 직후)
    - `band_of_mercenaries/lib/features/movement/...` 이동 중 사망 (TravelEventService) — 사망 분기 존재 시
  - 분기:
    - 퀘스트 사망 → `cause = MemorialCause.diedQuest`, `payload = {'questId': quest.id, 'regionId': quest.region}`
    - 여행 이벤트 사망 → `cause = MemorialCause.diedEvent`, `payload = {'eventId': event.id, 'regionId': currentRegionId}`
  - 호출: `mercSnapshot = MercenarySnapshot.fromMercenary(merc)` 후 `achievementService.recordMemorial(cause, mercSnapshot, payload)` — **사망 처리(박스 삭제 or 상태 변경) 직전에 snapshot 구성**해야 정보 손실 없음.

- **[FR-11] 방출 처리 memorial hook**
  - 통합 지점: `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` `dismiss(mercId, severancePay)` 메서드 (라인 161~184 구간)
  - 위치: 용병 status 변경 또는 박스 제거 **직전**에 snapshot 구성
  - 호출: `mercSnapshot = MercenarySnapshot.fromMercenary(merc)` 후 `achievementService.recordMemorial(MemorialCause.released, mercSnapshot, payload: {'severancePay': severancePay})`
  - fail-soft: memorial 발급 실패해도 방출 흐름 정상 종료.

#### (c) 다이얼로그 큐 통합

- **[FR-12] AchievementUnlockedDialog 위젯 + 큐 등록**
  - 신규 위젯: `band_of_mercenaries/lib/features/achievement/view/achievement_unlocked_dialog.dart`
  - DialogPriority.high (chainCompleted 동급)
  - `barrierDismissible: false` (큐 처리 측 app.dart 라인 356에서 `priority != critical` 분기로 자동 처리됨 → 명시적으로 dialog 자체 dismissible 정책에서 [확인] 버튼만 닫기 가능하도록 builder 내부 처리)
  - 위젯 구조:
    ```
    AlertDialog(
      title: Row([Icon(★ chainGold), Text('새로운 위업')])
      content: Column(min)([
        Text(template.name),  // 위업 이름
        SizedBox(8),
        if (mercSnapshot != null) Text('주인공: ${mercSnapshot.name} (T${tier} ${jobName})'),
        SizedBox(12),
        Text(renderedDescription, italic),  // TemplateEngine 렌더 결과
      ])
      actions: [ElevatedButton(onDismiss, '확인')]
    )
    ```
  - 색상: `AppTheme.chainGold` (기존 0xFFD4AF37 재사용)
  - 영속 복원 메시지(DialogQueueNotifier `_restoredMessage` 신규 case): "용병단의 새 위업이 기록되었습니다."

- **[FR-13] DialogTypeRegistry 확장**
  - `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` 라인 25~26 사이 추가:
    ```dart
    static const String achievementUnlocked = 'achievementUnlocked';
    ```
  - 라인 28~38 `keys` getter set에 `achievementUnlocked` 추가
  - 라인 148~187 `_restoredMessage` switch에 신규 case 추가:
    ```dart
    case DialogTypeRegistry.achievementUnlocked:
      final name = map['name'];
      return name == null
          ? '용병단의 새 위업이 기록되었습니다.'
          : '용병단의 새 위업이 기록되었습니다: $name';
    ```

- **[FR-14] RankUpDialog 본체 인라인 통합**
  - 통합 지점: `band_of_mercenaries/lib/features/home/view/rank_up_overlay.dart` Column children (라인 34~78 구간)
  - 기존 content 마지막에 신규 3 위젯 추가:
    ```dart
    const SizedBox(height: 12),
    const Divider(),
    const Text(
      '✨ 이 순간은 연대기에 새겨졌다',
      style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.chainGold),
    ),
    ```
  - 동작 변경: RankUpDialog 표시 흐름 자체는 변경 없음. 단순 시각적 추가 1줄. 위업 기록은 [FR-7]에서 별도 grant 호출로 영속화됨.

#### (d) 데이터 박스·정적 데이터

- **[FR-15] bandAchievements Hive 박스 + 어댑터 등록**
  - 박스명: `bandAchievements`
  - HiveInitializer 변경 (`band_of_mercenaries/lib/core/data/hive_initializer.dart`):
    - 라인 12 import 추가: BandAchievement, BandAchievementType, MercenarySnapshot, MemorialCause
    - 라인 23 직후 `static const String bandAchievementBoxName = 'bandAchievements';`
    - 라인 42 직후 어댑터 등록 4종 (typeId 순서):
      ```dart
      Hive.registerAdapter(BandAchievementTypeAdapter());  // typeId 17
      Hive.registerAdapter(MemorialCauseAdapter());          // typeId 19
      Hive.registerAdapter(MercenarySnapshotAdapter());      // typeId 18
      Hive.registerAdapter(BandAchievementAdapter());        // typeId 16
      ```
    - 라인 61 직후 박스 열기 추가:
      ```dart
      await Hive.openBox<BandAchievement>(bandAchievementBoxName);
      ```

- **[FR-16] band_achievement_templates Supabase 테이블 + 동기화 등록**
  - SyncService allTables 리스트 추가(`band_of_mercenaries/lib/core/data/sync_service.dart` 라인 47 직후):
    ```
    'band_achievement_templates', // 30. 위업 템플릿 (M6 페이즈 4 #1 추가)
    ```
  - DataLoader 캐시 키 자동 적용 (테이블명 그대로 사용).
  - StaticGameData (`band_of_mercenaries/lib/core/providers/static_data_provider.dart` 라인 63~64 다음):
    - 필드 추가: `final List<BandAchievementTemplate> bandAchievementTemplates;`
    - 생성자 파라미터 추가: `required this.bandAchievementTemplates`
    - JSON 로드: `dataLoader.loadFromCache<BandAchievementTemplate>('band_achievement_templates', BandAchievementTemplate.fromJson)` (또는 동일 패턴)

- **[FR-17] ActivityLogType 확장**
  - `band_of_mercenaries/lib/core/domain/activity_log_model.dart` 라인 63~64 (inventoryStackCapped 다음):
    ```dart
    @HiveField(29)
    achievementUnlocked,
    ```
  - **memorial은 신규 enum 추가 없음** — 기존 `mercenaryStatus`(HiveField 1)·`mercenaryDismiss`(HiveField 4)가 사망/방출 알림 처리.

### 2.2 데이터 요구사항

#### (a) Hive 신규 모델 3종 (typeId 16·17·18·19)

**BandAchievement (typeId 16)** — `band_of_mercenaries/lib/features/achievement/domain/band_achievement_model.dart` 신규
```dart
@HiveType(typeId: 16)
class BandAchievement extends HiveObject {
  @HiveField(0) final String id;                       // uuid v4
  @HiveField(1) final BandAchievementType type;        // achievement | memorial
  @HiveField(2) final DateTime achievedAt;
  @HiveField(3) final String templateId;               // 'chain_completed:chain_roadside_shrine' | 'memorial:died_quest'
  @HiveField(4) final MercenarySnapshot? mercSnapshot; // null = 주인공 없음
  @HiveField(5) final int? regionId;
  @HiveField(6) final Map<String, dynamic> payload;    // 카테고리별 자유 메타

  BandAchievement({
    required this.id,
    required this.type,
    required this.achievedAt,
    required this.templateId,
    this.mercSnapshot,
    this.regionId,
    this.payload = const {},
  });
}
```
- 다음 HiveField: 7

**BandAchievementType (typeId 17, enum)** — 동일 파일 또는 별도
```dart
@HiveType(typeId: 17)
enum BandAchievementType {
  @HiveField(0) achievement,
  @HiveField(1) memorial,
}
```

**MercenarySnapshot (typeId 18)** — `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.dart` 신규
```dart
@HiveType(typeId: 18)
class MercenarySnapshot {
  @HiveField(0) final String id;       // 본체 삭제 후에도 참조 가능
  @HiveField(1) final String name;
  @HiveField(2) final String jobId;
  @HiveField(3) final String jobName;  // 발급 시점 한국어 직업명 (영속 보존)
  @HiveField(4) final int tier;        // 1~5

  const MercenarySnapshot({
    required this.id,
    required this.name,
    required this.jobId,
    required this.jobName,
    required this.tier,
  });

  factory MercenarySnapshot.fromMercenary(Mercenary m, {required String jobName}) =>
      MercenarySnapshot(id: m.id, name: m.name, jobId: m.jobId, jobName: jobName, tier: m.tier);
}
```
- 다음 HiveField: **5** (페이즈 4 #2에서 `titleIds` HiveField 5 추가 예정 — 본 명세에서는 5필드 한정. 페이즈 4 #2가 마이그레이션 호환 처리 필요)
- jobName 영속 보존 이유: 발급 시점의 job 데이터가 미래에 변경되거나 삭제되어도 연대기 표시 안정. `Mercenary.jobId`는 보존되지만 jobs 테이블 변동 가능성 회피.

**MemorialCause (typeId 19, enum)** — `band_of_mercenaries/lib/features/achievement/domain/memorial_cause.dart` 신규
```dart
@HiveType(typeId: 19)
enum MemorialCause {
  @HiveField(0) diedQuest,   // 'died_quest'  → templateId 'memorial:died_quest'
  @HiveField(1) diedEvent,   // 'died_event'  → templateId 'memorial:died_event'
  @HiveField(2) released,    // 'released'    → templateId 'memorial:released'
}
```
- 기획 §4.1 §Q-1: 3종 분리(`died_old`는 향후 노화 시스템 도입 시 추가).

**CLAUDE.md typeId 표 갱신 후**:
| 모델 | typeId | 다음 HiveField |
|------|--------|---------------|
| BandAchievement | **16** | **7** |
| BandAchievementType (enum) | **17** | **2** |
| MercenarySnapshot | **18** | **5** (페이즈 4 #2에서 6) |
| MemorialCause (enum) | **19** | **3** |
- 다음 가용 typeId: **20+**. typeId **12는 여전히 미사용** (보존).

#### (b) Supabase `band_achievement_templates` (30번째 테이블)

DDL (마이그레이션 인라인):
```sql
CREATE TABLE band_achievement_templates (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  description_template TEXT NOT NULL,
  icon_key TEXT NOT NULL DEFAULT 'default',
  chronicle_variants JSONB DEFAULT '[]'::jsonb,
  default_priority TEXT NOT NULL DEFAULT 'high',
  narrative_hint TEXT,
  CONSTRAINT category_check CHECK (category IN (
    'chain_completed',
    'settlement_event_completed',
    'settlement_trust_belonging',
    'reputation_rank',
    'elite_unique_first_kill',
    'craft_first_rare',
    'memorial'
  )),
  CONSTRAINT priority_check CHECK (default_priority IN (
    'critical_inline', 'high', 'medium'
  ))
);

INSERT INTO data_versions (table_name, version) VALUES ('band_achievement_templates', 1);
```

운영 도구(operation-bom) `table-config.ts` 등록은 별도 작업으로 위임. M6 시점 시드 데이터는 §6 SQL INSERT 참조.

#### (c) Freezed 정적 데이터 모델

**BandAchievementTemplate** — `band_of_mercenaries/lib/core/models/band_achievement_template.dart` 신규
```dart
@freezed
class BandAchievementTemplate with _$BandAchievementTemplate {
  const factory BandAchievementTemplate({
    required String id,
    required String category,
    required String name,
    @JsonKey(name: 'description_template') required String descriptionTemplate,
    @JsonKey(name: 'icon_key') @Default('default') String iconKey,
    @JsonKey(name: 'chronicle_variants') @Default([]) List<String> chronicleVariants,
    @JsonKey(name: 'default_priority') @Default('high') String defaultPriority,
    @JsonKey(name: 'narrative_hint') String? narrativeHint,
  }) = _BandAchievementTemplate;

  factory BandAchievementTemplate.fromJson(Map<String, dynamic> json) =>
      _$BandAchievementTemplateFromJson(json);
}
```

#### (d) UserData 확장 — 없음

기획 §2.1 표는 `firstKilledEliteIds` / `firstCraftedItemIds` 추적을 언급하나, 본 명세는 **AchievementService.hasAchievement** 단일 체크로 멱등 보장하여 UserData 확장 회피. [FR-8]·[FR-9] 참조.

#### (e) 밸런스 수치

- 발급 빈도: 페이즈 2 #2 §6.1 페이스 표 — 명세 검증 acceptance criteria로 §4.4 구현 힌트에 인용
- 시간당 발급 1~3개 무게감 정책 — 다이얼로그 큐 critical/high 우선도로 폭주 방지

### 2.3 UI 요구사항

#### (a) AchievementUnlockedDialog ([FR-12] 위젯 명세)

- 화면 진입 조건: AchievementService.grant() 호출 후 카테고리가 `reputation_rank`가 아닐 때 dialog 큐 enqueue → app.dart ref.listen이 큐 head 노출
- 위젯 계층: `AlertDialog > Column > [Title Row(Icon + Text), Content Column(min), Actions]`
- 상태 변수: 없음 (StatelessWidget). payload는 `DialogRequest.payload`에서 직접 추출
- 화면 전환: showDialog (큐 자동 처리)
- 연출: 페이드 인 기본. chainGold 강조. ★ 아이콘.
- 참조 패턴: `band_of_mercenaries/lib/features/chain_quest/view/chain_completed_dialog.dart` (라인 54~87 구조 차용)

#### (b) ChronicleScreen 신규 화면

- 파일: `band_of_mercenaries/lib/features/achievement/view/chronicle_screen.dart`
- 화면 진입 조건: 두 경로 — (1) 정보 탭 "용병단 연대기" 카드 탭, (2) 홈 "연대기" 카드 [전체 보기] 탭
- 위젯 계층:
  ```
  Scaffold(
    appBar: AppBar(title: Text('용병단 연대기')),
    body: Column([
      _CategoryChipRow,            // ChoiceChip 7종 (체인/거점사건/거점소속/명성/엘리트/제작/추모)
      Expanded(
        ListView.builder(
          itemBuilder: _AchievementCard or _MemorialCard,
        )
      ),
    ])
  )
  ```
- 상태 변수:
  - `Set<String> _selectedCategories` (다중 선택, 빈 set = 전체)
  - `int _displayLimit = 50` (페이징, lazy load — 위업 누적이 100개 미만이면 한 번에 모두 로드)
- 화면 전환: **상태 기반 렌더링 회피** — Navigator.push (Material 페이지 push). 정보 탭과 홈에서 진입 자연.
- 정렬: `achievedAt` desc
- 빈 상태: 위업 0개 → Center(Text('용병단의 여정이 곧 시작됩니다.\n첫 위업을 기다립니다.'))
- 카드 탭 → AchievementUnlockedDialog 재사용(읽기 모드, builder만 호출)

#### (c) HomeScreen "연대기" 카드 추가

- 통합 지점: `band_of_mercenaries/lib/features/home/view/home_screen.dart` (build 메서드 Column children 내, 야영지 이미지와 활동 로그 사이)
- 위젯 계층:
  ```
  Card(
    InkWell(onTap: () => Navigator.push(ChronicleScreen)),
    Column([
      Row([Icon(★ chainGold), Text('연대기'), Spacer(), if (hasNew) Badge('NEW')]),
      _RecentAchievementRow,         // 최근 1개 위업 or memorial 1행 표시
      Align(Text('전체 연대기 보기 →')),
    ])
  )
  ```
- 상태 변수: 없음 (ConsumerWidget으로 `bandAchievementsProvider` watch)
- NEW 배지 조건: 가장 최근 위업의 `achievedAt`이 `DateTime.now().subtract(Duration(hours: 24))` 이후 (기획 §Q-2 권장 — 자연 갱신 + 24h NEW 배지)
- 빈 상태: 위업 0개 → "용병단의 첫 위업을 기다립니다" + 작은 힌트(첫 제작/명성 E)
- 위치 정책: 야영지 이미지 아래 + 활동 로그 위 (기획 §6.1)

#### (d) InfoScreen 진입점 추가

- 통합 지점: `band_of_mercenaries/lib/features/info/view/info_screen.dart` (ListView children, 기존 명성 정보·세력 도감 카드와 동급)
- 신규 카드:
  ```
  Card(
    ListTile(
      leading: Icon(★ chainGold),
      title: Text('용병단 연대기'),
      subtitle: Text('우리 용병단의 영구 기록'),
      trailing: Icon(Icons.chevron_right),
      onTap: () => Navigator.push(ChronicleScreen),
    )
  )
  ```

#### (e) AppTheme 색상 추가

- `band_of_mercenaries/lib/core/theme/app_theme.dart` 라인 59 (chainGold) 직후:
  ```dart
  static const Color memorialGray = Color(0xFF6E6E6E);
  ```
- chainGold는 기존(`0xFFD4AF37`) 재사용 (위업 강조)
- memorialGray: 추모 카드 카테고리 칩·아이콘·텍스트 강조용

#### (f) RankUpDialog 본체 1줄 추가 ([FR-14])

이미 위 [FR-14]에 명세. 시각적 1줄 추가만, 기능 변경 없음.

#### (g) 아이콘 매핑 (Material Icons 폴백)

기획 §Q-6 권장: M6 MVP는 Material Icons 폴백 사용:
- chain_completed → `Icons.link` 또는 ★ (chainGold)
- settlement_event_completed → `Icons.home_work`
- settlement_trust_belonging → `Icons.handshake`
- reputation_rank → `Icons.military_tech`
- elite_unique_first_kill → `Icons.local_fire_department`
- craft_first_rare → `Icons.construction`
- memorial → `Icons.flag` (회색, memorialGray 색조)

신규 아이콘 자산 추가 없음.

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | 박스 상수 `bandAchievementBoxName` + 어댑터 4개 등록 + 박스 열기 1줄 | bandAchievements 신규 박스 (11번째) |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | allTables 리스트 30번째 `band_achievement_templates` 추가 (라인 47 직후) | Supabase 신규 테이블 동기화 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | `bandAchievementTemplates` 필드 + 생성자 파라미터 + JSON 로드 추가 | StaticGameData 확장 |
| `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` | DialogTypeRegistry에 `achievementUnlocked` 키 추가 + keys getter set + `_restoredMessage` switch case 추가 | 다이얼로그 큐 10번째 키 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | ActivityLogType enum에 `@HiveField(29) achievementUnlocked` 추가 (라인 63 직후) | 활동 로그 미러 |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | `memorialGray` 상수 1줄 추가 (라인 59 직후) | 추모 카드 색상 |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` | `completeChain()` 시그니처에 `grantAchievement` 콜백 추가 + publishCompleted 직후 호출 | [FR-5] 체인·거점사건 hook |
| `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` 호출측 (provider) | `achievementService.grant`를 콜백으로 바인딩 | 위 콜백 DI |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | `addSettlementTrust()` newLevel == 4 분기에서 `achievementService.grant('settlement_trust_belonging:region_$regionId', ...)` 호출 | [FR-6] |
| `band_of_mercenaries/lib/core/domain/reputation_service.dart` 또는 명성 갱신 분기 | 랭크 진입 시 `achievementService.grant('reputation_rank:$toGrade', ...)` 호출 | [FR-7] |
| `band_of_mercenaries/lib/features/quest/domain/elite_loot_service.dart` 또는 quest_provider.dart | 유니크 엘리트 처치 후 첫 발생 시 grant 호출 (hasAchievement 멱등 체크) | [FR-8] |
| `band_of_mercenaries/lib/features/crafting/domain/crafting_service.dart` | `craft()` 성공 후 tier>=3 + hasAchievement 체크 후 grant 호출 | [FR-9] |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | Mercenary 사망 분기에서 `recordMemorial(diedQuest, snapshot, payload)` 호출 (제거 직전 snapshot 구성) | [FR-10] |
| TravelEventService 또는 movement 도메인 (사망 분기 있을 경우) | `recordMemorial(diedEvent, snapshot, ...)` 호출 | [FR-10] |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | `dismiss()` 직전에 snapshot 구성 후 `recordMemorial(released, snapshot, ...)` 호출 (라인 161~184 구간) | [FR-11] |
| `band_of_mercenaries/lib/features/home/view/rank_up_overlay.dart` | Column children 마지막에 SizedBox+Divider+Text 3 위젯 추가 (라인 34~78 구간) | [FR-14] 인라인 통합 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | 야영지 이미지 + 활동 로그 사이에 _ChronicleHomeCard 위젯 삽입 | UI §(c) |
| `band_of_mercenaries/lib/features/info/view/info_screen.dart` | ListView children에 "용병단 연대기" 카드 추가 | UI §(d) |
| `band_of_mercenaries/lib/app.dart` | dialog 큐 builder 매핑 dictionary에 `achievementUnlocked` → AchievementUnlockedDialog 빌더 추가 (ref.listen 핸들러 내부) | 큐 builder 매핑 (기존 9종과 동일 패턴) |
| `CLAUDE.md` | typeId 표 갱신(16·17·18·19 추가) + 박스 11개 표기 + 테이블 29→30개 갱신 + 핵심 시스템 로직 섹션 위업 추가 | 문서 동기화 |

### 3.2 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/achievement/domain/band_achievement_model.dart` | BandAchievement + BandAchievementType (typeId 16·17) |
| `band_of_mercenaries/lib/features/achievement/domain/mercenary_snapshot_model.dart` | MercenarySnapshot (typeId 18, 5필드) |
| `band_of_mercenaries/lib/features/achievement/domain/memorial_cause.dart` | MemorialCause enum (typeId 19) |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_service.dart` | AchievementService 4 메서드 + 카테고리 분류 헬퍼 + mercSnapshot 빌더 |
| `band_of_mercenaries/lib/features/achievement/domain/achievement_provider.dart` | `achievementServiceProvider` + `bandAchievementsProvider` (StateNotifierProvider) + `renderedAchievementProvider` (family) |
| `band_of_mercenaries/lib/core/models/band_achievement_template.dart` | Freezed 정적 데이터 모델 |
| `band_of_mercenaries/lib/features/achievement/view/achievement_unlocked_dialog.dart` | AchievementUnlockedDialog 위젯 |
| `band_of_mercenaries/lib/features/achievement/view/chronicle_screen.dart` | ChronicleScreen — 정렬·필터 칩 7종·페이징 |
| `band_of_mercenaries/lib/features/achievement/view/_chronicle_home_card.dart` | 홈 화면 "연대기" 카드 (정보 탭 카드와 분리 — 홈 컨텍스트 최근 1행 표시 전용) |
| `supabase/migrations/{timestamp}_create_band_achievement_templates.sql` | DDL + 28행 시드 INSERT |

### 3.3 코드 생성 필요 파일 (build_runner)

| 파일 | 이유 |
|------|------|
| `band_achievement_model.g.dart` | Hive typeId 16·17 어댑터 |
| `mercenary_snapshot_model.g.dart` | Hive typeId 18 어댑터 |
| `memorial_cause.g.dart` | Hive typeId 19 enum 어댑터 |
| `band_achievement_template.freezed.dart` + `band_achievement_template.g.dart` | Freezed + JSON |
| `achievement_provider.g.dart` | (riverpod_generator 사용 시) |

build 명령: `cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`

### 3.4 관련 시스템

- **ChainQuestService**: 체인·거점사건 완주 hook 진입점 (`completeChain()`)
- **RegionStateRepository**: 거점 신뢰도 4단계 진입 hook
- **ReputationService / UserDataNotifier**: 명성 등급 진입 hook
- **EliteLootService / QuestCompletionService**: 유니크 엘리트 첫 처치 hook
- **CraftingService**: T3+ 첫 제작 hook
- **QuestCompletionService / TravelEventService**: 사망 hook
- **MercenaryService**: 방출 hook
- **DialogQueueProvider**: 신규 dialogType 등록
- **ActivityLogProvider**: 미러 1행 기록
- **HomeScreen / InfoScreen**: 진입점 UI
- **StaticGameData / SyncService / DataLoader**: 신규 테이블 동기화
- **CLAUDE.md**: 문서 동기화 (typeId 표·박스 수·테이블 수·핵심 시스템)

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- **High priority dialog**: `band_of_mercenaries/lib/features/chain_quest/view/chain_completed_dialog.dart` (라인 54~87) — AlertDialog + Column min + onDismiss 콜백 패턴 차용. ChronicleScreen에서 카드 탭 시에도 동일 dialog 재사용.
- **Hive 모델 추가**: `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` (RegionState typeId 8, HiveField 0~7) — `@HiveType + @HiveField + 기본값 생성자` 패턴.
- **Freezed 정적 모델 + Supabase 동기화**: `band_of_mercenaries/lib/core/models/crafting_recipe_data.dart` (M5 추가) — `@freezed + @JsonKey + fromJson` + SyncService allTables 등록.
- **체인 콜백 DI**: `chain_quest_service.dart` `completeChain()` 시그니처 — 콜백 다수 인자로 받아 외부 의존성 분리. 위업 hook도 동일 패턴 적용.
- **다이얼로그 큐 신규 키 추가**: M3 chainCompleted / M3 regionTransform / M4 settlementTrustUp 시 DialogTypeRegistry 키 추가 + keys getter + _restoredMessage case 패턴.
- **TemplateEngine 사용**: `band_of_mercenaries/lib/core/domain/template_engine.dart` `render(template, context)`. ChainCompletedDialog (라인 42~51)에서 `engine.render(event.finalDescription, TemplateContext(...))` 사용 예시 참조.
- **상태 기반 렌더링**: 정보 탭 내부 화면 전환은 InfoScreen이 자체 화면 전환 처리. **ChronicleScreen은 별도 예외 — Navigator.push 사용 권장** (정보 탭 + 홈 카드 양쪽에서 진입하므로 화면 스택 사용이 자연).

### 4.2 주의사항

- **fail-soft 필수**: 6 hook 모두 try/catch로 grant 호출 감싸기. grant 실패 시 본 흐름(체인 완주·거점 신뢰도 업·랭크업·엘리트 드랍·제작 성공·사망·방출) 정상 동작 보장. 실패 메시지는 debugPrint로만.
- **memorial snapshot 타이밍**: 사망/방출 처리 **직전**에 MercenarySnapshot 구성. 박스 제거 후 시점에는 mercenary 본체 정보 손실 위험.
- **TemplateEngine binding**:
  - `{merc.name}` / `{merc.jobName}` / `{merc.tier}` — mercSnapshot에서 추출
  - `{region.name}` — StaticGameData.regions에서 regionId → name 조회 후 binding
  - `[pick A|B|C]` — chronicle_variants가 있는 경우 description_template + 랜덤 variant 선택 후 함께 렌더 (variants는 별도 표시용)
  - **mercSnapshot null인 카테고리(3·4·6)**: `{merc.name}` 사용 시 빈 문자열 또는 "용병단"으로 폴백
- **renderedAchievementProvider 캐싱**: 동일 위업 매번 렌더 비용 회피. family<String achievementId> 키 사용 + 일회 캐싱.
- **uuid 생성**: `package:uuid/uuid.dart`의 `Uuid().v4()`. 기존 코드베이스에서 다른 uuid 사용 패턴이 있다면 일관성 유지.
- **CLAUDE.md typeId 표**: 작업 완료 후 16·17·18·19 추가 + 박스 10→11 + 테이블 29→30 갱신.
- **operation-bom 별도**: `band_achievement_templates` CRUD 메뉴는 별도 작업으로 위임. 본 명세 외 작업.

### 4.3 엣지 케이스

- **EC-1 동시 발생 dialog 폭주**: 한 퀘스트 완료로 체인 완주 + 위업 + 랭크업 동시 발생 시 큐 우선도(critical → high → high) 순차 표시. RankUpDialog 본체 인라인이 1개 dialog로 통합되어 자연 처리. 페이즈 2 #2 §2.5 검증 완료.
- **EC-2 grant 호출 중 mercSnapshot 빌드 실패**: mercId가 mercenaries 박스에 없거나(이미 제거됨) jobs 정적 데이터에 jobId 없음 → mercSnapshot null로 fallback, grant는 정상 수행 (description은 `{merc.name}` 빈 문자열 렌더).
- **EC-3 멱등성 race condition**: hasAchievement 체크 후 grant 사이에 두 번째 호출 발생 시 두 번째도 hasAchievement 통과할 수 있음. Hive 박스는 단일 isolate 동기 액세스 → 실제로는 발생 불가. 필요 시 grant 내부에서 `bandAchievementsBox.values.any` 이중 체크.
- **EC-4 영속 복원 시 builder 손실**: 앱 재시작 후 dialog 큐 복원되면 AchievementUnlockedDialog builder는 fallback dialog로 변환(라인 131~136 패턴). `_restoredMessage` case에서 한국어 fallback 메시지 표시.
- **EC-5 templateId 누락**: Supabase에서 신규 위업 발급되는데 client 캐시 동기화 전이면 BandAchievementTemplate not found → AchievementUnlockedDialog가 templateId만 표시 + name="알 수 없는 위업" 폴백. 다음 SyncService 호출 시 자연 복원.
- **EC-6 24~25행 시드 vs 7체인 매칭**: chain_quests 테이블에 24행이 있고 chain_* prefix는 7개. 본 명세 §6 시드는 7개 chain_completed + 1개 settlement_event_completed + 1개 settlement_trust_belonging + 5개 reputation_rank + 8개 elite_unique_first_kill + 3개 craft_first_rare + 3개 memorial = **28행**. 기획 §2.1 표 "24~25"는 craft·settlement 가변 범위 — §6에서 28행으로 명시값 확정 (memorial 3행 포함이 기획 §2.1 표에서 명시적으로 제외되었던 점도 §6 인라인에서 포함하여 차이 발생).
- **EC-7 memorial 중복**: 한 용병이 사망 후 또 사망할 일 없음(natural impossibility). 방출 후 사망 불가. 단 동일 cause 두 번 호출 시(코드 버그) `(mercSnapshot.id, cause)` 사전 중복 검사로 차단.
- **EC-8 NEW 배지 시계 변경**: 사용자가 기기 시계를 변경하면 24h 윈도우 깨질 수 있음. `DateTime.now()` 직접 비교로 충분. 시계 변경은 게임 전반 영향 (퀘스트 만료 등) — 위업에 특별 처리 없음.

### 4.4 구현 힌트

- **진입점**:
  - `AchievementService` 신규 도메인 서비스가 모든 hook의 진입점
  - 6 hook은 각 도메인 서비스(ChainQuestService / RegionStateRepository / ReputationService / EliteLootService / CraftingService / QuestCompletionService / MercenaryService)의 기존 흐름 trailing side effect로 호출
  - UI 진입: HomeScreen "연대기" 카드 / InfoScreen "용병단 연대기" 카드 → ChronicleScreen
- **데이터 흐름**:
  - 발급: `domain hook → AchievementService.grant() → bandAchievementsBox.add() + activityLog.addLog() + dialogQueue.enqueue()` → `bandAchievementsProvider emit → HomeCard rebuild / ChronicleScreen rebuild`
  - 표시: `bandAchievementsProvider.watch → ChronicleScreen ListView → renderedAchievementProvider(template+snapshot) → TemplateEngine.render`
  - dialog: `dialogQueueProvider → app.dart ref.listen → showDialog(AchievementUnlockedDialog)`
- **참조 구현**:
  - `band_of_mercenaries/lib/features/chain_quest/view/chain_completed_dialog.dart` — high dialog 위젯 구조
  - `band_of_mercenaries/lib/features/chain_quest/domain/chain_quest_service.dart` — 콜백 DI 패턴 (`completeChain` 시그니처)
  - `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` `addSettlementTrust` — Ref 의존성 트레일링 side effect
  - `band_of_mercenaries/lib/features/info/view/faction_codex_screen.dart` (또는 유사 InfoScreen 자식 화면) — Navigator.push 패턴 + 카테고리 칩 UI
  - `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` 라인 148~187 `_restoredMessage` switch — 신규 case 추가 패턴
- **확장 지점**:
  - 페이즈 4 #2 (칭호) — `AchievementService.grant` 직후 칭호 자동 발급 hook (TitleService) 추가 예정. 본 명세에선 미적용.
  - 페이즈 4 #3 (지명 의뢰) — 위업 보유 여부가 지명 의뢰 등장 조건. `AchievementService.hasAchievement` 외부 호출 인터페이스로 활용.
  - 페이즈 4 #2 — MercenarySnapshot에 `@HiveField(5) titleIds` 추가 (마이그레이션 호환: 기본값 빈 리스트로 backward compatible).
- **acceptance criteria (페이즈 2 #2 §6.4 모니터링 지표 기반)**:
  - 평균 페이스 유저 1h 시점에 첫 위업 발급 ✓ (craft 깃발 또는 명성 E)
  - 평균 페이스 유저 5h 시점에 위업 5~6개 보유 + 메모리얼 0~1개 ✓
  - 적극 페이스 유저 5h 시점 위업 ≤ 8 (제한 없음 — 단순 모니터링)
  - 시간당 신규 발급 1~3개 ✓ (페이스 보존)
  - dialog 큐 폭주 없음 (1 이벤트에 ≤ 3 dialog 자연 순차) ✓

---

## 5. 기획 확인 사항

| ID | 기획 Q | 결정 |
|----|-------|------|
| Q-1 | memorial 카테고리 세분화 (3종 vs 4종) | **3종 채택**: `diedQuest` / `diedEvent` / `released`. MemorialCause enum typeId 19로 분리. `diedOld`(노화)는 향후 시스템 도입 시 HiveField 3 추가 |
| Q-2 | 홈 카드 갱신 트리거 (애니메이션 vs 자연 갱신) | **자연 갱신 + NEW 배지 24h** 채택. Riverpod provider watch로 자동 rebuild. NEW 배지는 `achievedAt > DateTime.now().subtract(Duration(hours: 24))` 조건 |
| Q-3 | 동시 발생 dialog 폭주 | **큐 자연 순차 표시**. 페이즈 2 #2 §2.5 검증 완료 — critical → high 우선도 순차 자연 |
| Q-4 | 위업 발급 빈도 페이스 | **페이즈 2 #2 §6.1 페이스 표 채택**. 본 명세 §4.4 acceptance criteria 인용 |
| Q-5 | memorial 토글 위치 | **카테고리 칩 안 7번째 칩으로 포함**. ChronicleScreen 단일 인터페이스 |
| Q-6 | icon_key 매핑 시점 | **Material Icons 폴백** 채택. UI §(g) 참조. 신규 아이콘 자산 추가 없음 |
| Q-7 | 다회차/세이브 리셋 | **M6 단일 회차 영구**. 다회차 보존은 M9+ 검토 |
| Q-8 | UserData 확장 (firstKilledEliteIds / firstCraftedItemIds) | **확장 회피**. `AchievementService.hasAchievement` 단일 체크로 멱등 보장 ([FR-8]·[FR-9]) |
| Q-9 | MercenarySnapshot.jobName 영속 보존 | **포함 결정** (5필드). 발급 시점 한국어 직업명 동결 — 정적 데이터 변동 회피 |
| Q-10 | ChronicleScreen 화면 전환 | **Navigator.push** 채택. 정보 탭 + 홈 카드 양쪽 진입점이 있어 화면 스택 사용 자연 |

---

## 6. Supabase 시드 데이터 (페이즈 3 인라인)

페이즈 2 #2 §스킵 검토 권장 채택. 본 명세 페이즈 4 #1에서 28행 SQL INSERT 인라인 처리. `band_achievement_templates` 테이블 시드:

```sql
-- band_achievement_templates 초기 시드 (M6 페이즈 4 #1)
-- 7 chain_completed + 1 settlement_event_completed + 1 settlement_trust_belonging
-- + 5 reputation_rank + 8 elite_unique_first_kill + 3 craft_first_rare + 3 memorial = 28행

INSERT INTO band_achievement_templates (id, category, name, description_template, icon_key, chronicle_variants, default_priority, narrative_hint) VALUES

-- (1) chain_completed × 7 — M3 산출물 chain_quests 24행 중 chain_* prefix 7개와 1:1 매칭
('chain_completed:chain_roadside_shrine', 'chain_completed', '길가의 폐사당을 열어주다',
 '{merc.name}이(가) 옛 수호자의 투구를 건네받았다.', 'chain_shrine',
 '["{merc.name}이(가) 잊혀진 길가에 빛을 되돌렸다.", "{merc.name}은 폐사당의 마지막 증인이 되었다."]', 'high',
 '체인 1단계 완주. 차분하고 의식적 톤'),

('chain_completed:chain_bandit_road', 'chain_completed', '도적의 길을 끊다',
 '{merc.name}이(가) 산길을 따라 흐르던 약탈의 흔적을 지웠다.', 'chain_bandit',
 '["{merc.name}이(가) 도적의 깃발을 마지막으로 거두었다."]', 'high',
 '도적 토벌 체인 완주'),

('chain_completed:chain_silent_grove', 'chain_completed', '침묵의 숲을 깨우다',
 '{merc.name}이(가) [pick 안개|어둠|침묵]을 헤치고 숲의 비밀을 마주했다.', 'chain_grove',
 '["{merc.name}의 발걸음이 숲의 잠을 깨웠다.", "오랜 침묵이 {merc.name} 앞에서 풀어졌다."]', 'high',
 '신비 톤. 변주 중요'),

('chain_completed:chain_iron_oath', 'chain_completed', '철의 서약에 응하다',
 '{merc.name}이(가) 옛 전우의 서약을 자신의 이름으로 마무리했다.', 'chain_oath',
 '["{merc.name}은 약속을 어기지 않았다."]', 'high',
 '서약·맹세 모티프'),

('chain_completed:chain_drowned_lighthouse', 'chain_completed', '물에 잠긴 등대를 다시 켜다',
 '{merc.name}의 손에서 등대의 불이 다시 타올랐다.', 'chain_lighthouse',
 '["{merc.name}이(가) 바다에 빛을 돌려놓았다."]', 'high',
 '해안 체인. 시각적 톤'),

('chain_completed:chain_witchs_circle', 'chain_completed', '마녀의 원을 끊다',
 '{merc.name}이(가) [pick 주문|결계|봉인]을 정면으로 마주하고 살아 돌아왔다.', 'chain_circle',
 '["마녀의 원 안에 {merc.name}의 이름이 새겨졌다."]', 'high',
 '주술·결계 모티프'),

('chain_completed:chain_soul_severance', 'chain_completed', '혼을 끊은 자',
 '{merc.name}이(가) 멸혼결을 완주하여 용병단의 전설이 되었다.', 'chain_severance',
 '["용병단의 가장 깊은 어둠을 {merc.name}이(가) 통과했다.", "{merc.name}의 이름은 더 이상 한 사람의 것이 아니었다."]', 'high',
 '엔드 체인. 무게감 최상'),

-- (2) settlement_event_completed × 1 — M4 더스트빌 폐광길 재개방
('settlement_event_completed:settlement_3_pyegwang_reopen', 'settlement_event_completed',
 '더스트빌 폐광길을 다시 열다',
 '더스트빌의 [pick 광장|마을길|광부 길드]에서 작은 잔치가 열렸다. 마을 사람들은 {merc.name}에게 고개를 숙였다.',
 'settlement_pyegwang',
 '["{merc.name}의 손으로 더스트빌의 빗장이 열렸다.", "광부들이 {merc.name}의 이름을 처음으로 부르기 시작했다."]', 'high',
 '거점 사건 완주. 마무리 step 파티 최고 기여자가 주인공'),

-- (3) settlement_trust_belonging × 1 — M5 더스트빌 4단계 소속
('settlement_trust_belonging:region_3', 'settlement_trust_belonging',
 '더스트빌의 한 식구',
 '용병단은 더스트빌 사람들에게 [pick 손님|동료|식구]로 받아들여졌다.',
 'settlement_belong',
 '["더스트빌의 문은 이제 용병단에게 닫히지 않는다."]', 'high',
 '거점 소속 진입. mercSnapshot 없음'),

-- (4) reputation_rank × 5 — E·D·C·B·A 각 1행 (F 제외)
('reputation_rank:E', 'reputation_rank', '이름을 새기다',
 '용병단의 [pick 첫 이름|첫 인장|첫 깃대]이(가) 명부에 올랐다.',
 'rep_rank_E',
 NULL, 'critical_inline',
 'E 신출내기 진입. RankUpDialog 본체 인라인'),

('reputation_rank:D', 'reputation_rank', '평범한 이름을 얻다',
 '용병단이 [pick 일반|평범한|이름 있는] 급으로 인정받았다.',
 'rep_rank_D',
 NULL, 'critical_inline',
 'D 일반 진입'),

('reputation_rank:C', 'reputation_rank', '능숙한 손길로 알려지다',
 '용병단의 손이 [pick 능숙하다|믿을 만하다|날카롭다]는 평을 듣는다.',
 'rep_rank_C',
 NULL, 'critical_inline',
 'C 능숙 진입'),

('reputation_rank:B', 'reputation_rank', '실력으로 부름 받다',
 '거점들마다 용병단의 이름이 [pick 먼저|먼저|이미] 들린다.',
 'rep_rank_B',
 NULL, 'critical_inline',
 'B 실력 진입'),

('reputation_rank:A', 'reputation_rank', '전설로 회자되다',
 '용병단의 이름이 [pick 노래|소문|이야기]에 실려 떠다닌다.',
 'rep_rank_A',
 NULL, 'critical_inline',
 'A 전설 진입'),

-- (5) elite_unique_first_kill × 8 — 유니크 엘리트 8종 1:1
-- (실제 elite_monsters.is_unique=true 8종 ID는 페이즈 2 #1 시점 미확정. 임시 placeholder ID로 정의 — 페이즈 4 #1 구현 시점에 elite_monsters 테이블 실제 ID로 교체 필요)
('elite_unique_first_kill:elite_giant_bat', 'elite_unique_first_kill', '거대 박쥐를 처음 사냥하다',
 '{merc.name}이(가) [pick 어둠|박쥐의 비명|폐광의 메아리] 사이에서 칼을 휘둘렀다.',
 'elite_bat',
 '["{merc.name}의 [pick 활시위|검|창]이 박쥐의 날개를 갈랐다."]', 'high',
 '거대 박쥐. M5 시점 등장. is_unique 여부는 페이즈 4 #1 구현 시 확인'),

('elite_unique_first_kill:elite_t1_unique_a', 'elite_unique_first_kill', '들개왕을 처음 쓰러뜨리다',
 '{merc.name}이(가) 들개 무리의 우두머리를 [pick 한 합|단번|짧은 호흡]에 베어 넘겼다.',
 'elite_unique',
 NULL, 'high',
 'T1 유니크 placeholder. 실제 elite_monsters ID로 교체'),

('elite_unique_first_kill:elite_t1_unique_b', 'elite_unique_first_kill', '독사의 여왕을 끊다',
 '{merc.name}의 검 끝이 [pick 독|비늘|뱀의 노래]을 갈랐다.',
 'elite_unique',
 NULL, 'high',
 'T1 유니크 placeholder'),

('elite_unique_first_kill:elite_t2_unique_a', 'elite_unique_first_kill', '강가의 거인을 처음 쓰러뜨리다',
 '{merc.name}이(가) 강가의 [pick 그림자|발자국|메아리] 앞에서 멈추지 않았다.',
 'elite_unique',
 NULL, 'high',
 'T2 유니크 placeholder'),

('elite_unique_first_kill:elite_t2_unique_b', 'elite_unique_first_kill', '회색 늑대 무리장을 베다',
 '{merc.name}의 칼날에서 [pick 늑대의 호흡|이빨의 빛|밤의 침묵]이 잠시 멈췄다.',
 'elite_unique',
 NULL, 'high',
 'T2 유니크 placeholder'),

('elite_unique_first_kill:elite_t3_unique_a', 'elite_unique_first_kill', '폐허의 골렘을 무너뜨리다',
 '{merc.name}이(가) [pick 돌|먼지|시간]의 무게를 잠시 짊어졌다.',
 'elite_unique',
 NULL, 'high',
 'T3 유니크 placeholder'),

('elite_unique_first_kill:elite_t3_unique_b', 'elite_unique_first_kill', '심해의 그림자를 끊다',
 '{merc.name}의 발자국이 [pick 바다|어둠|차가운 물결] 위에 남았다.',
 'elite_unique',
 NULL, 'high',
 'T3 유니크 placeholder'),

('elite_unique_first_kill:elite_t4_unique_a', 'elite_unique_first_kill', '잊혀진 군주를 쓰러뜨리다',
 '{merc.name}이(가) 옛 왕좌의 [pick 무게|침묵|먼지] 앞에 섰다.',
 'elite_unique',
 NULL, 'high',
 'T4 유니크 placeholder'),

-- (6) craft_first_rare × 3 — M5 시점 T3+ 레시피 (실제 crafting_recipes ID에 맞춰 교체 필요)
('craft_first_rare:recipe_dustvile_pyegwang_relic_fragment', 'craft_first_rare',
 '폐광의 유물을 처음 빚어내다',
 '낡은 대장간의 [pick 모루|불|망치]가 잊혀진 [pick 손길|숨결|울림]을 되찾았다.',
 'craft_relic',
 '["용병단의 첫 희귀품이 모루 위에서 식어갔다."]', 'high',
 'M5 폐광 유물 조각 T3 첫 제작'),

('craft_first_rare:recipe_dustvile_banner_restoration', 'craft_first_rare',
 '깃대를 처음 다시 세우다',
 '용병단의 [pick 첫 깃발|첫 표식|첫 이름]이 [pick 다시 펄럭였다|다시 떠올랐다|되살아났다].',
 'craft_banner',
 '["{merc.name}의 손은 거기에 없었지만, 깃발은 그날 처음 펼쳐졌다."]', 'high',
 '깃발 복원 T3 첫 제작. M5 페이즈 1 #3 시점 확정 여부에 따라 ID 조정'),

('craft_first_rare:recipe_t3_placeholder', 'craft_first_rare',
 '희귀한 손길로 빚다',
 '용병단이 [pick 첫번째|새로운|손에 익지 않은] 희귀품을 만들어냈다.',
 'craft_rare',
 NULL, 'high',
 'M5 T3 placeholder. 실제 recipe ID로 교체'),

-- (7) memorial × 3 — cause별 1개씩
('memorial:died_quest', 'memorial', '의뢰에서 잠들다',
 '{merc.name}이(가) [pick 마지막 의뢰|이름 없는 길|돌아오지 못한 길]에서 [pick 잠들었다|쓰러졌다|발을 멈췄다].',
 'memorial',
 '["용병단은 {merc.name}의 자리를 한참 비워두었다.", "{merc.name}의 이야기는 마지막 의뢰의 한 줄로 남았다."]', 'high',
 '파견 중 사망. memorial 톤. dialog enqueue X (recordMemorial)'),

('memorial:died_event', 'memorial', '길 위에서 잠들다',
 '{merc.name}이(가) [pick 이동 중|여행 중|길 위]에서 [pick 마지막 숨|마지막 인사|마지막 발걸음]을 남겼다.',
 'memorial',
 '["{merc.name}의 자취가 길 위에서 멈췄다."]', 'high',
 '여행 이벤트 사망'),

('memorial:released', 'memorial', '용병단을 떠나다',
 '{merc.name}이(가) [pick 짐을 챙기고|용병증을 돌려주고|마지막 의뢰를 마치고] 용병단을 떠났다.',
 'memorial',
 '["{merc.name}의 자리는 비어 있지만, 이름은 명부에 남았다."]', 'high',
 '자발/용량 방출. dialog enqueue X');

-- 총 28행
```

**시드 데이터 주의사항**:
- (5) elite_unique_first_kill 8행은 **placeholder ID 7개 + 거대 박쥐 1개**로 작성됨. 구현 시점에 `SELECT id FROM elite_monsters WHERE is_unique = true ORDER BY tier, id LIMIT 8`로 실제 ID 매핑 후 시드 갱신.
- (6) craft_first_rare 3행도 M5 페이즈 1 #3 T2~T3 결정 결과에 따라 ID 교체.
- chronicle_variants는 NULL 허용 (예: reputation_rank). TemplateEngine 렌더 시 variant 없으면 description_template만 사용.

---

## 7. 후속 작업

### 7.1 본 명세 완료 후 즉시

- `/implement-agent @Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle.md` 구현 진입 (§5단계 구현 규모 분석 결과 참조)
- 구현 후 `flutter analyze` + `flutter test` 통과 확인
- CLAUDE.md 갱신 (typeId 표·박스 수·테이블 수·핵심 시스템 섹션)

### 7.2 후속 페이즈 4 명세

- **페이즈 4 #2 (칭호·간판 용병)**: MercenarySnapshot HiveField 5 `titleIds` 추가. Mercenary HiveField 24·25 + UserData HiveField 24. Supabase `titles` 테이블(31번째).
- **페이즈 4 #3 (지명 의뢰)**: quest_pools 4 컬럼 확장 + UserData HiveField 25 + ActiveQuest HiveField 26 + QuestSortService NamedTier 슬롯 7번째.

### 7.3 운영 도구

- `operation-bom` 웹앱에 `band_achievement_templates` CRUD 메뉴 추가 (별도 작업)
- 시드 §6 28행 + 구현 시점 elite·craft ID 교체

---

## 명세서 생성 완료

파일: `Docs/spec/[spec]20260513_M6_phase4_1_achievement-chronicle.md`

### 구현 규모 분석

| 기준 | 내용 | 판정 |
|------|------|------|
| 수정/생성 파일 | 수정 18개 + 신규 10개 = 28개 | 대규모 |
| 영향 시스템 | ChainQuestService / RegionStateRepository / ReputationService / EliteLootService / CraftingService / QuestCompletionService / MercenaryService / DialogQueueProvider / ActivityLog / HomeScreen / InfoScreen / SyncService / StaticGameData (13개) | 대규모 |
| 신규 클래스 | BandAchievement / BandAchievementType / MercenarySnapshot / MemorialCause / BandAchievementTemplate / AchievementService / AchievementUnlockedDialog / ChronicleScreen + Home 카드 위젯 (9개) | 대규모 |
| 데이터 모델 | Hive 박스 1개 신규 + Hive 모델 3 + enum 2 + Supabase 신규 테이블 1개 | 대규모 |
| UI 작업 | 신규 화면 1(ChronicleScreen) + 신규 카드 위젯 2 + RankUpDialog 1줄 추가 + HomeScreen·InfoScreen 카드 추가 | 대규모 |
| 기존 시스템 변경 | 6 hook 통합 + 다이얼로그 큐 신규 키 + ActivityLog enum 확장 + SyncService allTables 추가 | 대규모 |

**추천: implement-agent** (6/6점)
- 대규모 다중 시스템 통합. spec → plan → coder → verifier 파이프라인 권장.
