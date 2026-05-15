# 칭호·간판 용병 컨텐츠 기획서

> 작성일: 2026-05-12
> 유형: 신규 컨텐츠 (M6 마일스톤 페이즈 1 #2)
> 선행 문서:
> - `Docs/content-design/[content]20260512_achievement-chronicle-system.md` (M6 페이즈 1 #1) — 6 위업 카테고리·mercSnapshot 모델·dialogQueue 정책
> - `Docs/roadmap/master_roadmap.md` 라인 1037~1054 + 라인 1087 (칭호 예시 4종 + "필수 최적해가 되지 않도록 제한")
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` — M4 폐광길 재개방 6단계 (마을의 은인·폐광의 생존자 hook)
> - `Docs/content-design/[content]20260423_chain_quests.md` — M3 체인 24단계 protagonistMercId
> - 코드: `Mercenary` 모델(HiveField 24 가용), `TraitData`/`PassiveEffect` sealed(17종), `PassiveBonusService`/`PassiveBonusContext`
> 후속:
> - M6 페이즈 1 #3 "지명 의뢰 설계" — 본 산출물의 11 칭호 + 간판 용병이 의뢰 등장 조건
> - M6 페이즈 2 #1 "칭호 효과 수치 밸런스" — 본 산출물의 effect_json 권장값을 시뮬레이션 검증
> - M6 페이즈 4 #2 "칭호·간판 용병 시스템 명세" — 데이터 모델·hook·UI를 구현 명세로

---

## 개요

본 문서는 M6 "이름을 얻는 용병단" 마일스톤의 두 번째 토대 시스템인 **칭호**와 **간판 용병**을 정의한다. 페이즈 1 #1(위업·연대기)의 6 카테고리를 칭호 발급 hook의 상위 집합으로 활용하며, 페이즈 1 #3(지명 의뢰)의 직접 입력이 된다.

핵심 결정 사항:
1. **저장 위치**: `Mercenary.titleIds` HiveField 24 + Supabase `titles` 신규 테이블(28→29번째). 트레잇 패턴 100% 재사용.
2. **발급 hook 3종**: (a) 위업 기반 / (b) 행동 지표 기반 / (c) 상태 기반. (a)는 #1 AchievementUnlockedDialog에 통합, (b)·(c)는 신규 `TitleUnlockedDialog` (high). DialogTypeRegistry 10→11종.
3. **초반 칭호 11종**: (a) 6 + (b) 4 + (c) 1. roadmap 예시 4종 모두 포함 + 추가 7종.
4. **효과 강도**: 기존 PassiveEffect 17종 sealed 그대로 재사용. 광역 작은 효과(2~5%) + 좁은 hook 조합. 신규 PassiveEffect 0종 추가. 페이즈 2 #1에서 미세 조정.
5. **간판 자동 선정**: 5단계 정렬 (칭호 수 → 위업 주인공 → 레벨 → partyPower → recruitedAt 빠른). `Mercenary.recruitedAt` HiveField 25 신설.
6. **수동 override**: `UserData.flagshipMercId` HiveField 24(UserData 다음 가용) 신설. 자동/수동 토글.
7. **사망/방출 보존**: `MercenarySnapshot` (typeId 18, #1 모델) HiveField 5 `titleIds: List<String>` 추가. 모든 mercSnapshot이 동일 정보 구조.

종료 조건 매핑:
| roadmap 종료 조건 | 본 문서 충족 |
|---|---|
| 3~5시간 안에 1명 이상 칭호 기억 | M5 시점 발급 가능 칭호 9종(11종 중 #11 엔드·#12 제거 후) + 자동 간판 카드로 1명 시각 노출 |
| 사망한 용병의 칭호 유지 | MercenarySnapshot.titleIds 동결 + memorial 엔트리 연대기 표시 |
| 간판 용병을 확인하거나 지정할 수 있다 | 자동 5단계 정렬 + 수동 [간판 지정] 버튼 |
| 칭호 효과가 필수 최적해가 되지 않게 | PassiveEffect 17종 재사용 + 2~5% 광역 효과 한정 + 페이즈 2 #1 검증 |

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 본 시스템 적용 |
|---------|-------------|---------------|
| **Crusader Kings III — Traits & Nicknames** | 인물별 특성과 별칭이 별도 분리. 별칭은 명예/일생 사건에서 자동 부여 | 트레잇(능력)과 칭호(이력) 분리 — 트레잇은 모집 시 또는 행동으로 획득하는 능력, 칭호는 사건의 결과로 부여되는 명예 |
| **Dwarf Fortress — Nicknames & Legendary Status** | 특정 사건 후 dwarf가 별칭을 얻고 legendary 등급 도달 시 영구 기억 | 칭호는 1회성 사건에 자동 부여. 사망 후에도 mercSnapshot에 보존 |
| **Stardew Valley — Achievement Titles** | 사건 후 자동 칭호 부여, 표시는 UI 카드. 효과는 없거나 미미 | 칭호 효과 강도 제한(2~5%). "필수 최적해 안 됨" 정책 |
| **Hades — Bond Companions** | 동료마다 특별한 관계 진행도. 메인 캐릭터가 떠나도 동료 기록 보존 | 간판 용병 = "메인 동료" 격. 사망/방출 후에도 연대기 보존 |
| **Kingdom of Loathing — Adventurer Titles** | 누적 행동 기반 칭호 (raid 30회 → 도적길 추적자) | 행동 지표 hook (b) 패턴 — Mercenary.stats 카운터 활용 |
| **Disco Elysium — Thought Cabinet** | 칭호는 "이 인물이 어떤 정체성을 갖는가"를 표시 | 칭호 = 용병 정체성, 트레잇 = 능력. M6 컨셉 "이름 기억" 정합 |

**핵심 설계 원칙**: "**칭호는 명예, 트레잇은 능력**" — 두 시스템의 책임 분리. 트레잇은 STR+1 같은 직접 능력치 변화, 칭호는 "이 용병이 어떤 사건의 주인공이었나"의 기록. 효과는 부차적이고 사건 자체가 보상이다.

---

## 상세 설계

### 1. 데이터 저장 위치

#### 1.1 Mercenary 모델 확장

```dart
@HiveType(typeId: 1)
class Mercenary extends HiveObject {
  // ... 기존 0~23 ...

  @HiveField(24)
  List<String> titleIds;       // 신규 — 활성 칭호 ID 리스트 (트레잇과 동일 패턴)

  @HiveField(25)
  DateTime? recruitedAt;       // 신규 — 모집 시점. 간판 자동 선정 동률 처리 + UI "N일째" 표시
}
```

**HiveField 점유 갱신** (CLAUDE.md 표):
| 모델 | typeId | 현재 HiveField | 신규 다음 |
|------|--------|--------------|-----------|
| Mercenary | 1 | 24 (다음) | **26** (24·25 사용) |
| UserData | — | 24 (다음) | **25** (24 사용 — §6) |
| MercenarySnapshot | 18 | 5 (다음, #1 결정) | **6** (5 사용 — §7) |

**기존 데이터 호환**: 두 신규 필드 모두 nullable 또는 default 빈 리스트. 마이그레이션 시 자동 초기화 (Hive 자동 처리).

**`recruitedAt` 신설 사유**: 5단계 자동 정렬의 마지막 동률 처리 키 + "우리 용병단에 가입한 지 N일째" UI 표시. 기존 모집 시점 추적 미존재 (모집은 RecruitmentService.recruit에서 즉시 mercenary 박스에 add만 함).

#### 1.2 Supabase 신규 테이블 — `titles`

| 컬럼 | 타입 | 제약 | 의미 |
|------|------|------|------|
| `id` | TEXT | PRIMARY KEY | 칭호 ID. 예: `title_village_savior` |
| `name` | TEXT | NOT NULL | 한국어 칭호명. 예: "마을의 은인" |
| `description` | TEXT | NOT NULL | 칭호 설명. 1~2문장 |
| `hook_type` | TEXT | NOT NULL CHECK | `achievement` / `action_stat` / `status` |
| `hook_condition` | JSONB | NOT NULL | hook별 조건 (§2.2 참조) |
| `effect_json` | JSONB | NOT NULL | PassiveEffect 17종 sealed 직렬화. 트레잇 동일 형식 |
| `icon_key` | TEXT | NOT NULL DEFAULT 'default' | UI 아이콘 식별자 |
| `narrative_hint` | TEXT | NULL | 운영자용 톤 가이드 |

**CHECK 제약**:
```sql
CONSTRAINT hook_type_check CHECK (hook_type IN ('achievement', 'action_stat', 'status'))
```

**SyncService 등록**: 28 → **29번째 테이블**. data_versions 엔트리 + DataLoader 캐시 파일 + StaticGameData.titles 필드.

**Freezed 모델 신규**:
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
}
```

### 2. 발급 hook 3종 매핑 정책

#### 2.1 Hook 유형별 평가 시점

| Hook | 평가 시점 | 평가 주체 | 알림 정책 |
|------|----------|---------|----------|
| **(a) achievement** | `AchievementService.grant()` 직후 | TitleService.evaluateAchievementHook(achievement, mercSnapshot) | #1 AchievementUnlockedDialog **본체 내 1줄 통합** ("┝ 칭호 획득: 마을의 은인") |
| **(b) action_stat** | Mercenary.stats 갱신 시 (QuestCompletionService) | TitleService.evaluateActionStatHook(mercId) | **신규 TitleUnlockedDialog** (high) |
| **(c) status** | MercenaryStatus 변화 시 (MercenaryStatService) | TitleService.evaluateStatusHook(mercId, newStatus, context) | **신규 TitleUnlockedDialog** (high) |

#### 2.2 hook_condition JSONB 구조

**(a) achievement**:
```json
{
  "achievement_template_id": "settlement_event_completed:settlement_3_pyegwang_reopen",
  "require_protagonist": true
}
```
- `require_protagonist: true` — mercSnapshot이 발급 주인공 본인일 때만 매칭
- 한 위업 발급 시 매칭되는 칭호 0~N개 (보통 0 또는 1)

**(b) action_stat**:
```json
{
  "stat_key": "raid_count",
  "threshold": 30,
  "operator": ">="
}
```
- `stat_key` — Mercenary.stats Map의 키
- 매 stats 갱신 시 평가 (이미 trait_acquisition_service에서 비슷한 hook 존재)

**(c) status**:
```json
{
  "trigger_status": "injured",
  "context": {
    "chain_id": "settlement_3_pyegwang_reopen",
    "require_chain_completion": true
  }
}
```
- `trigger_status` — 발급 트리거 상태 (예: `injured` 진입 또는 회복)
- `context` — 추가 조건 (특정 사건 진행 중, 특정 지역 등)
- M6 MVP는 `status` 칭호 1종(폐광의 생존자)만 있어 구조 단순

#### 2.3 자동 발급 정책

모든 hook은 **자동 발급** (사용자 수락 불요). 트레잇과 동일 패턴.

- Mercenary.titleIds 사전 보유 확인 (중복 차단)
- titleIds.add(titleId) 즉시
- 알림은 hook 유형별 차등 (위 표)

#### 2.4 발급 흐름 코드

```dart
// (a) 위업 hook
class AchievementService {
  Future<AchievementResult> grant(template, mercSnapshot, payload) async {
    final achievement = await bandAchievementsRepo.add(...);
    final grantedTitles = await titleService.evaluateAchievementHook(
      achievement, mercSnapshot
    );  // 매칭 칭호 즉시 grant + return
    activityLog.addLog(...);
    dialogQueue.enqueue(
      AchievementUnlockedDialog(
        achievement: achievement,
        grantedTitles: grantedTitles,  // dialog 본체 1줄에 표시
      )
    );
  }
}

// (b) 행동 지표 hook
class TitleService {
  void evaluateActionStatHook(String mercId) {
    final merc = mercRepo.get(mercId);
    for (final title in titlesData.where(t => t.hookType == 'action_stat')) {
      if (merc.titleIds.contains(title.id)) continue;  // 중복 차단
      if (_matchActionStat(merc, title.hookCondition)) {
        _grantTitle(merc, title);
        dialogQueue.enqueue(TitleUnlockedDialog(title: title, mercSnapshot: ...));
      }
    }
  }

  void _grantTitle(Mercenary merc, TitleData title) {
    merc.titleIds.add(title.id);
    merc.save();
    activityLog.addLog('┝ ${merc.name}이(가) "${title.name}" 칭호를 얻었다', ActivityLogType.titleUnlocked);
  }
}
```

#### 2.5 DialogTypeRegistry 신규 키

`DialogTypeRegistry.titleUnlocked` 추가 — 9 → 10종 (#1) → **11종**.

`TitleUnlockedDialog` 위젯:
```
┌─ TitleUnlockedDialog ──────────┐
│                                 │
│   ┝ 새로운 칭호                  │
│                                 │
│   도적길 추적자                  │
│                                 │
│   김철수 (T2 검사)               │
│   30회의 도적 소탕 활동           │
│                                 │
│   효과: 약탈 의뢰 성공률 +5%      │
│                                 │
│                  [확인]          │
└─────────────────────────────────┘
```
- barrierDismissible: false
- priority: high (chain·transform·achievement 동급)

#### 2.6 ActivityLog 신규 enum

`ActivityLogType.titleUnlocked` HiveField **30** 추가 (현재 다음 가용 29 = `achievementUnlocked` #1 결정).

| HiveField | 이름 | 용도 |
|---|---|---|
| 29 | `achievementUnlocked` | #1에서 결정 |
| **30** | **`titleUnlocked`** | (b)·(c) 칭호 발급 시. (a)는 같은 위업 로그에 인라인. 메시지 예: "┝ 김철수가 '도적길 추적자' 칭호를 얻었다" |

### 3. 초반 칭호 11종 명세

#### 3.1 표

| # | id | name | hook | hook_condition | effect_json (권장, 페이즈 2 #1 확정) | icon_key | M5 발급 |
|---|----|------|------|---------------|------------------------------------|---------|---------|
| 1 | `title_village_savior` | 마을의 은인 | (a) | achievement_template_id: `settlement_event_completed:settlement_3_pyegwang_reopen` | questSuccessRateBonus(quest_type:'all', value:+0.03) | `ic_village_savior` | ✓ |
| 2 | `title_pyegwang_survivor` | 폐광의 생존자 | (c) | trigger_status: `injured`, context: { chain_id: `settlement_3_pyegwang_reopen`, require_chain_completion: true } | recoveryTimeReduction(status:'injured', value:-0.10) | `ic_survivor` | ✓ |
| 3 | `title_first_banner` | 첫 깃발을 든 자 | (a) | achievement_template_id: `craft_first_rare:recipe_dustvile_banner_restoration`, hook_target: `last_dispatch_protagonist` | reputationGainModifier(value:+0.02) | `ic_banner` | ✓ |
| 4 | `title_road_hunter` | 도적길 추적자 | (b) | stat_key: `raid_count`, threshold: 30, operator: `>=` | questSuccessRateBonus(quest_type:'raid', value:+0.05) | `ic_road_hunter` | ✓ |
| 5 | `title_veteran` | 백전노장 | (b) | stat_key: `total_dispatch_count`, threshold: 100, operator: `>=` | injuryRateModifier(value:-0.03) | `ic_veteran` | ✓ (5~10h) |
| 6 | `title_scout_eye` | 정찰의 눈 | (b) | stat_key: `explore_count`, threshold: 20, operator: `>=` | investigationSuccessRateBonus(value:+0.05) | `ic_scout_eye` | ✓ |
| 7 | `title_escort_master` | 호위의 노련함 | (b) | stat_key: `escort_count`, threshold: 15, operator: `>=` | questSuccessRateBonus(quest_type:'escort', value:+0.05) | `ic_escort_master` | ✓ |
| 8 | `title_dustvile_friend` | 더스트빌의 친우 | (a) | achievement_template_id: `settlement_trust_belonging:region_3`, hook_target: `most_dispatched_to_region_3` | questRewardMultiplier(quest_type:'all', value:+0.03) | `ic_dustvile_friend` | ✓ |
| 9 | `title_monster_hunter` | 괴물 사냥꾼 | (a) | achievement_template_id_prefix: `elite_unique_first_kill:`, first_only: true | questSuccessRateBonus(quest_type:'hunt', value:+0.05) | `ic_monster_hunter` | ✓ (유니크 8종 정의 후) |
| 10 | `title_renowned` | 이름을 알린 자 | (a) | achievement_template_id: `reputation_rank:D`, hook_target: `top_contributor_24h` | reputationGainModifier(value:+0.03) | `ic_renowned` | ✓ |
| 11 | `title_soul_severer` | 혼을 끊은 자 | (a) | achievement_template_id: `chain_completed:chain_soul_severance`, require_protagonist: true | 복합: reputationGainModifier(value:+0.05) + mercenaryXpBonus(value:+0.10) | `ic_soul_severer` | △ M6 후반 |

**hook_target 분기 설명**:
- `require_protagonist` (true) — mercSnapshot이 그 위업의 직접 주인공일 때 (대부분)
- `last_dispatch_protagonist` — 제작 위업 발급 시점, 가장 최근 파견 성공 파티 최고 기여자에게 부여 (제작은 단일 행위라 "참여자" 미정의)
- `most_dispatched_to_region_3` — 거점 소속 위업은 용병 주인공 없음. region 3에 가장 많이 파견된 용병에게 부여 (Mercenary.stats에 `region_3_dispatch_count` 같은 신규 카운터 또는 quest 완료 로그 집계)
- `top_contributor_24h` — 명성 등급 진입 시점 직전 24h partyPower 기여 1위 (실시간 추적 필요)
- `first_only` — N개 위업 중 첫 1회만 발급. `elite_unique_first_kill:*` 8 위업 모두 hook 매칭이지만 첫 1회만 칭호 부여

#### 3.2 hook_target 구현 가이드 (페이즈 4 #2 입력)

- `require_protagonist`: 가장 단순. mercSnapshot.id == merc.id 확인.
- `last_dispatch_protagonist`: ActivityLog 또는 별도 lastDispatchProtagonistId UserData 캐시 필요. 또는 QuestCompletionService에서 partyPower 기여 1위 mercId 매번 캐시.
- `most_dispatched_to_region_3`: Mercenary.stats에 `region_{N}_dispatch_count` 23개 카운터 외 신규 키 추가. 또는 RegionState 단위 dispatch 누적 추적 후 매번 집계.
- `top_contributor_24h`: 별도 24h 윈도우 추적. 페이즈 4 #2에서 상세화.
- `first_only`: 칭호 자체에 "이미 발급됨" 플래그가 아닌, 글로벌 카운터로 추적. 또는 `(category_prefix, granted=true)` 글로벌 set 보유.

**M6 MVP 단순화 권장**: `require_protagonist`만 우선 구현하고, `last_dispatch_protagonist` 등 복잡 hook은 페이즈 4 #2에서 구체 정의. 11종 중 hook_target 단순한 5종(#1·#4·#5·#6·#7·#11)부터 활성화 가능.

#### 3.3 칭호 11종 발급 시뮬레이션 (페이즈 2 #1 입력)

신규 유저 누적 플레이 시간 기준 예상 칭호 보유 수 (M5 시점):

| 누적 플레이 | 예상 칭호 수 | 보유 가능 칭호 |
|---|---|---|
| 30분 | 0개 | (제작·명성 위업은 보유 가능하지만 칭호 hook 미발급 아직) |
| 1시간 | 0~1개 | #3 첫 깃발을 든 자 (깃발 복원 완료 시) |
| 2시간 | 1~3개 | #1 마을의 은인 + #3 + #10 이름을 알린 자(D 진입 시) 일부 |
| 5시간 | 3~6개 | + #2 폐광의 생존자 + #8 더스트빌의 친우 + #4 도적길 추적자 일부 |
| 10시간 | 5~8개 | + #5 백전노장 + #6 정찰의 눈 + #7 호위의 노련함 + #9 괴물 사냥꾼 |

roadmap "3~5시간 안 1명 이상 칭호 기억" 충족. 페이즈 2 #1에서 발급 페이스 검증.

### 4. 칭호 효과 강도 정책

#### 4.1 강도 비교 표 (페이즈 2 #1 입력)

| 시스템 | 강도 범위 | 적용 단위 | 충돌 가능성 |
|--------|----------|---------|------------|
| 트레잇 (109종) | STR+1~+3 / 부상률 -5% / XP +10% | 용병 1명 | 칭호와 동일 용병 단위 — **누적 가능** |
| 세력 패시브 (14개) | injuryRateModifier -0.07 / reputationGainModifier +0.04 | 용병단 전체 | 칭호와 별개 적용 — 누적 |
| 랭크 패시브 (6) | idleRewardBonus / recruitmentTierBoost 5~10% | 용병단 전체 | 별개 |
| **칭호 (11종, 신규)** | **2~5% 권장** | **용병 1명** | **트레잇·세력·랭크와 누적** |

**누적 정책 (기존 PassiveBonusService 동일)**:
- 가산 효과 (reputationGainModifier 등): Σ + clamp(상한)
- 곱셈 효과 (injuryRateModifier): (1 + Σ).clamp(0.10, 1.0)
- 칭호도 같은 PassiveBonusService 파이프라인에 흘러들어가므로 자동 처리

#### 4.2 "필수 최적해 안 됨" 보장

roadmap 라인 1087 정책 충족 방안:

1. **칭호 효과는 항상 트레잇 동급 또는 약함** (2~5%). 트레잇이 5~15%이므로 칭호 단독으로 빌드 결정 못 함.
2. **칭호는 1명 단위 효과**. 모든 용병 칭호 보유 어렵고, 파견 파티에서 칭호 효과는 "추가 보너스" 격.
3. **칭호 효과는 hook이 좁은 1회성 사건**. 행동 지표 칭호(b)는 누적이지만 30~100 카운터로 시간 비용 큼.
4. **페이즈 2 #1 시뮬레이션 검증**: 칭호 풀스택(11종 모두 한 용병에게 부여 가정) 시에도 트레잇 1개 평균치 못 넘는지 확인.

#### 4.3 PassiveBonusService 통합

기존 `PassiveBonusService.collect()`가 트레잇·세력·랭크 효과를 누적 수집한다. **신규 추가**:

```dart
class PassiveBonusService {
  List<PassiveEffect> collect(...) {
    final effects = <PassiveEffect>[];
    effects.addAll(_collectFromTraits(merc));
    effects.addAll(_collectFromFactions(...));
    effects.addAll(_collectFromRanks(...));
    effects.addAll(_collectFromTitles(merc, titlesData));  // 신규
    return effects;
  }

  List<PassiveEffect> _collectFromTitles(Mercenary merc, List<TitleData> titlesData) {
    return merc.titleIds
      .map((id) => titlesData.firstWhereOrNull((t) => t.id == id))
      .where((t) => t != null)
      .expand((t) => PassiveEffect.parseEffects(t!.effectJson))
      .toList();
  }
}
```

**호출 지점 확장**: 기존 QuestCalculator, RecruitmentService 등 6개 도메인 서비스가 PassiveBonusContext를 통해 collect를 호출. titleIds 효과가 자동으로 흘러들어감. **코드 변경 1곳**(_collectFromTitles 추가).

### 5. 간판 용병 자동 선정 알고리즘

#### 5.1 5단계 정렬

```dart
class FlagshipMercenaryService {
  Mercenary? selectAuto() {
    final candidates = mercRepo.getAll()
      .where((m) => m.status != MercenaryStatus.dead)
      .toList();
    if (candidates.isEmpty) return null;
    candidates.sort(_compareFlagship);
    return candidates.first;
  }

  static int _compareFlagship(Mercenary a, Mercenary b) {
    // 1순위: 칭호 보유 수 desc
    final cmpTitles = b.titleIds.length.compareTo(a.titleIds.length);
    if (cmpTitles != 0) return cmpTitles;

    // 2순위: 위업 주인공 횟수 desc
    final aAch = _countAchievements(a.id);
    final bAch = _countAchievements(b.id);
    final cmpAch = bAch.compareTo(aAch);
    if (cmpAch != 0) return cmpAch;

    // 3순위: 레벨 desc
    if (a.level != b.level) return b.level.compareTo(a.level);

    // 4순위: partyPower desc (대표 quest_type 가중 평균)
    final aPower = _calculatePartyPower(a);
    final bPower = _calculatePartyPower(b);
    if (aPower != bPower) return bPower.compareTo(aPower);

    // 5순위: recruitedAt 빠른 순 (오래된 용병 우선)
    final aRecruited = a.recruitedAt ?? DateTime(2000);
    final bRecruited = b.recruitedAt ?? DateTime(2000);
    return aRecruited.compareTo(bRecruited);
  }

  static int _countAchievements(String mercId) {
    return bandAchievementsRepo.getAll()
      .where((a) => a.mercSnapshot?.id == mercId && a.type == BandAchievementType.achievement)
      .length;
  }
}
```

#### 5.2 갱신 트리거

`flagshipMercenaryProvider`는 다음 시점에 재평가:
- 칭호 발급 (TitleService.grant 직후)
- 위업 발급 (AchievementService.grant 직후)
- 용병 사망 (수동 간판이면 자동 리셋 + 자동 알고리즘)
- 용병 방출 (수동 간판이면 자동 리셋)
- 용병 레벨업 (드물지만 적용)
- 신규 모집 (recruitedAt 갱신)

구현: Riverpod Provider가 `userDataProvider`, `mercenaryListProvider`, `bandAchievementsProvider`를 watch하여 자동 재계산. 별도 갱신 호출 불요.

#### 5.3 isDispatched 처리

자동 선정 시 `isDispatched`는 **필터링하지 않는다** — 파견 중 용병도 간판 가능. UI에서 "파견 중" 배지를 별도로 표시하여 사용자 인지.

이유: 파견 중인 용병이 간판 자격을 잃는 건 자연스럽지 않다. "이 용병이 현재 파견 중"이라는 정보는 시각 보조로 표현.

#### 5.4 후보 0명 처리 (전원 사망)

`candidates.isEmpty` 시 `null` 반환. 홈 간판 카드는 빈 상태:
- "용병단의 새 간판을 기다립니다 — 새 용병을 모집해 보세요"

### 6. 수동 지정 + UI

#### 6.1 UserData 모델 확장

```dart
// UserData Hive 모델 (typeId 미상, CLAUDE.md 표에서 다음 HiveField 24)
@HiveField(24)
String? flagshipMercId;  // null = 자동, non-null = 수동 고정
```

**호환성**: nullable. 기존 세이브에서 null로 초기화되어 자동 알고리즘 적용.

#### 6.2 자동/수동 토글 흐름

```
초기 상태: flagshipMercId = null → 자동 알고리즘 선정

[사용자 동작 1] 용병 상세 화면 → [★ 간판으로 지정] 버튼 탭
  → UserData.flagshipMercId = thisMercId
  → ActivityLog: '간판 용병이 {name}으로 지정되었다'
  → 홈 간판 카드 갱신 (이 용병으로)

[사용자 동작 2] 수동 상태에서 용병 상세 → [★ 간판 해제 (자동)] 버튼 탭
  → UserData.flagshipMercId = null
  → ActivityLog: '간판 용병 자동 선정으로 돌아왔다'
  → 홈 간판 카드 갱신 (자동 알고리즘 결과로)

[자동 트리거 1] 수동 간판 용병 사망 시
  → UserData.flagshipMercId = null
  → ActivityLog: '간판 용병 {name}의 이야기가 이어질 주인을 찾는다'
  → memorial 엔트리 자동 추가 (#1 mercSnapshot.titleIds 포함)
  → 자동 알고리즘 재적용

[자동 트리거 2] 수동 간판 용병 방출 시
  → 동일하게 null 리셋 + memorial(cause=released) + 자동 재적용
```

#### 6.3 홈 간판 카드 UI

홈 화면 야영지 이미지 아래, "연대기 카드"(#1) 위 또는 옆 배치. 카드 1개 추가:

```
홈 화면 (위→아래, M6 누적):
  1. 골드·위치·진행중·용병 수 (기존)
  2. 야영지 이미지 (기존)
  3. ★ 간판 용병 카드 (NEW, 본 문서)
       - 이름·직업·티어
       - 보유 칭호 1~3개 미니 표시 (3개 초과 시 +N)
       - "용병단에 N일째" (recruitedAt 기준)
       - 파견 중이면 "파견 중" 배지
       - [탭 → 용병 상세]
  4. ✩ 연대기 카드 (#1)
  5. 활동 로그 (기존)
  6. 건설 미니 위젯 (기존)
  7. 설정 버튼 (기존)
```

빈 상태 (전원 사망 또는 모집 0): "용병단의 새 간판을 기다립니다 — 새 용병을 모집해 보세요"

#### 6.4 용병 상세 화면 [간판] 섹션

용병 상세 (MercenaryDetailOverlay)에 신규 섹션 추가:

```
용병 상세 화면 (위→아래, M6 누적):
  - 프로필 헤더 (기존)
  - 트레잇 슬롯 그리드 (기존)
  - ★ 칭호 섹션 (NEW)
      - 보유 칭호 N개 카드 리스트
      - 각 카드: 칭호명·발급 일자·효과 텍스트
      - 빈 상태: "아직 칭호가 없습니다"
  - ★ 간판 토글 버튼 (NEW)
      - 자동 상태일 때: 이 용병이 자동 간판이면 "현재 자동 간판" 표시 (버튼 비활성)
                       다른 용병이 자동 간판이면 [★ 간판으로 지정] (활성)
      - 수동 상태일 때: 이 용병이 수동 간판이면 [간판 해제 (자동)] (활성)
                       다른 용병이 수동 간판이면 [★ 간판으로 지정] (활성, 누르면 override)
  - 행동 지표 (기존)
  - 트레잇 히스토리 (기존)
```

### 7. 사망/방출 시 칭호 보존

#### 7.1 MercenarySnapshot 확장

```dart
@HiveType(typeId: 18)  // #1에서 결정
class MercenarySnapshot {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String jobId;
  @HiveField(3) String jobName;
  @HiveField(4) int tier;
  @HiveField(5) List<String> titleIds;  // 신규 — 스냅샷 시점 칭호 동결
}
```

#### 7.2 스냅샷 시점

| 이벤트 | mercSnapshot.titleIds 동결 시점 |
|--------|------------------------------|
| 위업 발급 | 발급 시점의 mercenary.titleIds 사본 |
| memorial 추가 (사망) | 사망 직전 mercenary.titleIds 사본 |
| memorial 추가 (방출) | 방출 직전 mercenary.titleIds 사본 |

**일관성 보장**: 위업이 발급된 후 용병이 추가 칭호를 획득해도, 그 위업의 mercSnapshot.titleIds는 변경되지 않음. "이 위업 발급 당시 이 용병이 가지고 있던 칭호들"의 의미가 명확히 보존.

#### 7.3 연대기 표시 예시

```
연대기 화면:
  ★ 2026-05-12 14:23
    체인 완주 · 길가의 폐사당
    주인공: 김철수 (T2 검사)
    당시 칭호: 마을의 은인, 도적길 추적자

  ★ 2026-05-13 09:14
    엘리트 유니크 첫 처치
    주인공: 김철수 (T2 검사)
    당시 칭호: 마을의 은인, 도적길 추적자, 괴물 사냥꾼  ← 자연 누적

  ┝ 2026-05-15 18:42
    추모 · 故 김철수 (T2 검사)
    "국경의 검" 4단계에서 사망
    경력: 마을의 은인, 도적길 추적자, 괴물 사냥꾼, 백전노장
```

#### 7.4 칭호 보존 크기

- 평균 칭호 보유 수: 0~5개/용병
- titleIds 평균 크기: 5개 × 25 bytes/ID = ~125 bytes
- mercSnapshot 평균 크기: 50~80B (#1) → 70~200 bytes (titleIds 포함)
- 24~25 위업 + 일부 memorial = 3~5KB/유저. 미미.

#### 7.5 사망/방출 시 흐름 (#1 통합)

```
용병 사망 시:
  1. memorial mercSnapshot 생성:
     MercenarySnapshot(
       id: merc.id, name: merc.name,
       jobId: merc.jobId, jobName: merc.jobName,
       tier: merc.tier,
       titleIds: List.from(merc.titleIds)  // 신규 — 사망 시점 동결
     )
  2. AchievementService.recordMemorial(
       cause: 'died_quest',
       mercSnapshot: snapshot,
       payload: { questId, regionId, ... }
     )
  3. 수동 간판이면: UserData.flagshipMercId = null
  4. mercenary 박스에서 본체 제거
  5. 자동 간판 알고리즘 재적용 (Riverpod auto)
```

### 8. AchievementUnlockedDialog 본체 내 칭호 인라인 통합 (Hook a)

#1에서 AchievementUnlockedDialog는 위업 발급 시 high 우선도로 띄운다. 칭호 hook (a)가 함께 매칭되면 동일 dialog에 칭호 정보 1줄 통합.

#### 8.1 dialog payload 확장

```json
// #1 AchievementUnlockedDialog payload
{
  "achievementId": "uuid-...",
  "templateId": "settlement_event_completed:settlement_3_pyegwang_reopen",
  "name": "마을을 일으키다",
  "description": "더스트빌에서 작은 잔치가 열렸다.",
  "iconKey": "settlement_event",
  "mercSnapshot": { "id": "merc_42", "name": "김철수", "jobName": "검사", "tier": 2 },
  "regionId": 3,
  "category": "settlement_event_completed",
  "grantedTitles": [                          // 신규 (본 문서)
    { "id": "title_village_savior", "name": "마을의 은인" }
  ]
}
```

#### 8.2 UI 표현

```
┌─ AchievementUnlockedDialog ─────┐
│                                  │
│   ★ 새로운 위업                  │
│                                  │
│   마을을 일으키다                 │
│                                  │
│   더스트빌에서 작은 잔치가 열렸다.│
│                                  │
│   주인공: 김철수 (T2 검사)        │
│                                  │
│   ┝ 칭호 획득: 마을의 은인        │ ← 신규 1줄
│                                  │
│                  [확인]          │
└──────────────────────────────────┘
```

**0~N개 칭호 처리**:
- 0개: 신규 라인 미표시 (위업만)
- 1~2개: 각 1줄
- 3개 이상: 첫 1줄 + "외 N종"

---

## 현재 시스템과의 연관

### 영향받는 시스템

| 시스템 | 영향 내용 | 마이그레이션 |
|--------|----------|-------------|
| `Mercenary` 모델 (typeId 1) | HiveField 24 (`titleIds`), 25 (`recruitedAt`) 추가 — 다음 가용 26 | 페이즈 4 #2 |
| `UserData` 모델 | HiveField 24 (`flagshipMercId`) 추가 — 다음 가용 25 | 페이즈 4 #2 |
| `MercenarySnapshot` 모델 (typeId 18, #1) | HiveField 5 (`titleIds`) 추가 — 다음 가용 6 | 페이즈 4 #2 |
| Supabase 테이블 | `titles` 신규 (29번째) | 페이즈 4 #2 |
| StaticGameData | `titles: List<TitleData>` 필드 추가 | 페이즈 4 #2 |
| SyncService | 29번째 테이블 등록 + data_versions 엔트리 + DataLoader 캐시 | 페이즈 4 #2 |
| `DialogTypeRegistry` | `titleUnlocked` 키 추가 (10 → 11종) | 페이즈 4 #2 |
| `ActivityLogType` enum | HiveField 30 `titleUnlocked` 추가 | 페이즈 4 #2 |
| `TitleService` 신규 도메인 | evaluateAchievementHook / evaluateActionStatHook / evaluateStatusHook / _grantTitle 4 메서드 | 페이즈 4 #2 |
| `FlagshipMercenaryService` 신규 도메인 | selectAuto / selectManual / clearManual / getCurrentFlagship | 페이즈 4 #2 |
| `PassiveBonusService.collect()` | `_collectFromTitles(merc, titlesData)` 호출 1줄 추가 | 페이즈 4 #2 |
| `AchievementService.grant()` (#1) | `titleService.evaluateAchievementHook` 호출 + `grantedTitles` payload 전달 | 페이즈 4 #2 |
| `QuestCompletionService` | 퀘스트 완료 시 `titleService.evaluateActionStatHook(mercId)` 호출 (행동 지표 갱신 직후) | 페이즈 4 #2 |
| `MercenaryStatService` (또는 `QuestCompletionService` 부상 처리) | 상태 변화 시 `titleService.evaluateStatusHook(mercId, newStatus, context)` 호출 | 페이즈 4 #2 |
| `RecruitmentService.recruit()` | mercenary 생성 시 `recruitedAt = DateTime.now()` 설정 | 페이즈 4 #2 |
| `app.dart` ref.listen | `bandAchievementsProvider`·`mercenaryListProvider` → `flagshipMercenaryProvider` 자동 재계산 (Riverpod auto, 별도 listen 불요) | 페이즈 4 #2 |
| `AchievementUnlockedDialog` (#1) | `grantedTitles` 1줄 인라인 표시 | 페이즈 4 #2 |
| `TitleUnlockedDialog` 신규 위젯 | high 우선도 dialog | 페이즈 4 #2 |
| `HomeScreen` | "간판 용병" 카드 위젯 추가 (#1 연대기 카드 위 또는 동급) | 페이즈 4 #2 |
| `MercenaryDetailOverlay` | "칭호 섹션" + "[간판으로 지정/해제]" 버튼 추가 | 페이즈 4 #2 |
| `titlesProvider` 신규 | FutureProvider<List<TitleData>> — 정적 데이터 캐시 | 페이즈 4 #2 |
| `flagshipMercenaryProvider` 신규 | Provider<Mercenary?> — 자동/수동 통합 | 페이즈 4 #2 |
| `mercenaryTitlesProvider` 신규 | family<Mercenary, List<TitleData>> — 용병별 활성 칭호 변환 | 페이즈 4 #2 |
| operation-bom | `titles` CRUD 메뉴 추가 | 별도 작업 |

### 호환성 검토

- **기존 세이브**: Mercenary.titleIds·recruitedAt 모두 nullable/default 빈 리스트. UserData.flagshipMercId nullable. 기존 데이터 그대로 호환.
- **PassiveBonusService**: `_collectFromTitles` 추가는 후방 호환. 기존 트레잇·세력·랭크 효과 영향 없음.
- **DialogQueueRegistry**: 신규 키 1개 추가는 후방 호환.
- **trait_acquisition_service**: 기존 trait hook과 칭호 (b) action_stat hook이 동일 trigger(stats 갱신) 공유. **두 hook은 독립적**으로 평가 — 칭호와 트레잇이 같은 stat key를 다른 임계로 사용 가능. 평가 순서는 trait 우선(기존) → title (신규).

### 호환성 리스크

- **낮음**: TitleService 평가는 멱등성 보장 (mercenary.titleIds 사전 확인). 중복 hook 호출에도 안전.
- **중간**: `recruitedAt`이 기존 세이브에서 null인 경우 5단계 정렬 5순위에서 default 1970년 또는 2000년으로 fallback — 모든 기존 용병이 동일 timestamp 됨. 동률 발생 가능. 페이즈 4 #2에서 1회성 마이그레이션: 기존 mercenary에 `recruitedAt = DateTime.now()` 일괄 설정 (대략적 — 실제 모집 시점 미상이지만 동률 회피).
- **중간**: hook_target `most_dispatched_to_region_3`·`top_contributor_24h`는 별도 추적 인프라 필요. M6 MVP는 `require_protagonist`만 활성화하고 두 hook은 페이즈 4 #2에서 결정.
- **낮음**: `regionId 3` 한정 칭호가 광역 PassiveEffect로 표현되어 다른 지역 의뢰에도 적용 — 의미·효과 결합 약함. 페이즈 2 #1에서 효과 수치 조정으로 보완.

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| Mercenary HiveField 24·25 + UserData HiveField 24 + MercenarySnapshot HiveField 5 | **높음** | 페이즈 4 #2 명세 작성의 직접 입력. 다른 모든 hook의 토대 |
| Supabase titles 테이블 + 11개 행 시드 (§3.1) | **높음** | data-generator 출력 입력. 효과·hook 정의 |
| TitleService + 3 hook (§2.4) | **높음** | 모든 칭호 발급의 파이프라인 |
| FlagshipMercenaryService 자동 알고리즘 (§5) | **높음** | 홈 간판 카드의 데이터 소스 |
| PassiveBonusService _collectFromTitles 통합 (§4.3) | **높음** | 칭호 효과 자동 적용 |
| #1 AchievementUnlockedDialog grantedTitles 통합 (§8) | **높음** | (a) hook 칭호의 UX |
| TitleUnlockedDialog 신규 (§2.5) | **높음** | (b)·(c) hook 칭호의 UX |
| 홈 간판 카드 + 용병 상세 칭호 섹션 (§6.3·6.4) | **높음** | M6 종료 조건 충족 |
| MercenarySnapshot.titleIds 동결 (§7) | **높음** | 사망 후 보존, roadmap 종료 조건 |
| 수동 override 토글 (§6.2) | **중간** | 자동만으로도 동작. 사용자 개입은 UX 보강 |
| hook_target 복잡 분기 (`most_dispatched_to_region_3` 등) | **중간** | 5종 단순 hook은 우선, 4종 복잡 hook은 페이즈 4 #2에서 결정 |
| `recruitedAt` 1회성 마이그레이션 | **낮음** | 기존 세이브 동률 회피용. 일괄 now() 설정 |

---

## data-generator 지시사항

본 문서는 페이즈 4 #2 명세에서 데이터 시드와 함께 작성될 수 있으나, **11개 칭호 × 한국어 텍스트 3컬럼(name·description·narrative_hint)**이 발생하므로 data-generator 활용이 자연스럽다.

- **대상 타입**: `title` (신규 — 타입 스펙 작성 필요. 페이즈 3 또는 페이즈 4 #2 명세에 인라인 처리 검토)
- **대상 테이블**: `titles` (신규 Supabase 테이블)
- **생성 수량**: **11행** (§3.1 표 그대로 고정)
- **톤/세계관 가이드**:
  - 한국어 판타지 톤. roadmap "마을의 은인" / "폐광의 생존자" 작명 스타일 유지
  - 칭호 이름은 "{한정어}{의/을} {명사}" 또는 "{형용사} {명사}" 형식
  - description은 1~2문장. "이 용병은 ___" 또는 "{이름}이(가) ___" 톤
  - narrative_hint는 운영자용. 발급 hook의 의미와 가이드 텍스트
  - 고유명사 저작권 금칙 (한국 웹소설 고유명사 미사용)
- **구조적 제약**:
  - id 형식: `title_{slug}` — §3.1 표 11개 ID 그대로 고정
  - hook_type 3종: `achievement`(6) / `action_stat`(4) / `status`(1)
  - hook_condition JSONB: §2.2 + §3.1 표 그대로
  - effect_json JSONB: §3.1 표 권장값 (페이즈 2 #1 마이크로 조정 후 최종 확정)
  - icon_key: §3.1 표 그대로
- **수치 출처**: effect_json 권장값은 본 문서 §3.1, 페이즈 2 #1에서 시뮬레이션 검증 후 최종 확정
- **특수 요구**:
  - #2 폐광의 생존자: hook_condition의 chain_id가 M4 실제 데이터(`settlement_3_pyegwang_reopen`)와 일치 검증
  - #9 괴물 사냥꾼: M5 elite_unique_first_kill 위업 카테고리의 유니크 8종은 페이즈 1 #1 §3.1에 미정. 현재는 prefix 매칭 hook으로 일단 정의. 페이즈 1 #1 후속 결정 후 first_only 동작 확정
  - #11 혼을 끊은 자: 엔드게임 칭호. M5 시점 발급 사실상 0건이지만 데이터 시드 포함

---

## 오픈 질문

- **Q-1 (제작 칭호 hook_target)**: #3 첫 깃발을 든 자의 `last_dispatch_protagonist` 정의. "가장 최근 파견 성공 파티 최고 기여자"는 명확하지만, 파견 완료 후 며칠 지난 시점 제작 시 매핑 어색. 대안: "제작 직전 12h 내 가장 활동 많은 용병" 또는 "출입 가능 용병 중 levelIds.length 최다". **권장**: 페이즈 4 #2에서 단순 정의 선택 (예: 야영지에서 partyPower 1위)
- **Q-2 (거점 소속 칭호 hook_target)**: #8 더스트빌의 친우의 `most_dispatched_to_region_3`. Mercenary.stats에 region별 카운터 없음. **권장**: 페이즈 4 #2 명세에서 `Mercenary.stats['region_3_dispatch_count']` 신규 키 추가 + QuestCompletionService에서 increment hook. 또는 더 단순하게 "거점 소속 위업 발급 시점에 살아있는 용병 중 partyPower 1위"
- **Q-3 (명성 등급 진입 칭호 hook_target)**: #10 이름을 알린 자의 `top_contributor_24h`. 별도 24h 윈도우 추적 필요. **권장**: 페이즈 4 #2 단순화 — "랭크 D 진입 시점에 활성 용병 중 stats.success_count 최다" 또는 partyPower 1위
- **Q-4 (칭호 수동 해제)**: 사용자가 특정 칭호를 명시적으로 숨기거나 해제할 수 있는가? **권장**: M6 MVP 불가. 칭호는 자동 부여·자동 누적·자동 보존. 페이즈 4 #2에서 제거
- **Q-5 (칭호 효과 토글)**: 사용자가 특정 칭호 효과를 끄고 다른 칭호로 갈아끼울 수 있는가 (예: 한 용병이 5개 칭호 가지면 5개 효과 모두 항상 활성)? **권장**: 항상 모두 활성. 트레잇과 동일 정책. 칭호별 활성/비활성 토글은 over-engineering
- **Q-6 (칭호 시너지)**: 두 특정 칭호를 동시 보유 시 추가 보너스 부여? **권장**: M6 MVP 미도입. 트레잇 시너지(39개)와 별개로 칭호 시너지는 페이즈 4 #2 또는 M9에서 검토
- **Q-7 (간판 변경 알림)**: 자동 알고리즘이 간판을 자동 교체할 때(예: 신규 칭호 획득으로 다른 용병이 간판) 사용자에게 알림? **권장**: 활동 로그 1행만, 다이얼로그 없음 ("간판 용병이 ___으로 바뀌었다")
- **Q-8 (간판 카드 표시 우선도)**: 홈 카드 배치 — 간판 vs 연대기(#1) 중 어느 게 위? **권장**: 간판이 위 (용병 한 명에 집중하는 게 M6 핵심)

---

## 후속 작업

### 동일 페이즈(1) 후속 산출물

- **페이즈 1 #3 지명 의뢰 설계** — 본 문서의 11 칭호 + 간판 용병이 의뢰 등장 조건:
  - "마을의 은인" 보유 용병단을 찾는 의뢰
  - 간판 용병이 특정 칭호 보유 시 자연 노출되는 의뢰
  - 위업 보유 수 ≥ N일 때 의뢰 풀 확장
  - **#3 작성 시 권장 호출**: `/content-designer 지명 의뢰 설계: 본 문서(titles_and_flagship 11 칭호) + #1 위업 6 카테고리 + 간판 용병이 의뢰 등장 조건. 의뢰 5~8개 + 등장 빈도/쿨다운 + 의뢰 카드 차별화 UI`

### 후속 페이즈 입력

- **페이즈 2 #1 칭호 효과 수치 밸런스**: 본 문서 §3.1·§4 effect_json 11종을 시뮬레이션 검증. 풀스택 시너지(트레잇·세력·랭크·칭호 모두 누적) 시에도 "필수 최적해" 안 되는지 검증
- **페이즈 2 #2 노출 빈도·획득 페이스 밸런스** (#1 위업 페이스와 통합): 본 문서 §3.3 발급 시뮬레이션 검증
- **페이즈 3 #1 (선택)** `types/title.md` 타입 스펙 + 11개 데이터: data-generator 활용
- **페이즈 4 #2 칭호·간판 용병 시스템 명세**: 본 문서 + 페이즈 2 #1 검증 결과 + 페이즈 1 #3 결과를 입력으로 spec-writer 호출

### 밸런스 검토 필요

**예**. 페이즈 2 #1에서 검토할 수치:
- 11종 칭호 효과 수치 (#3.1 권장값) 미세 조정
- 행동 지표 hook (#4·#5·#6·#7) 임계 30/100/20/15가 적절한지 — 너무 느리면 (b) 칭호 미발급, 너무 빠르면 무게감 희석
- 풀스택 시너지 안전 검증 (PassiveBonusService 곱셈 누적이 하한 0.10 클램프 통과하는지)

호출: `/balance-designer 칭호 효과 수치 + 행동 지표 임계 시뮬레이션` (페이즈 2 #1)

### 벌크 데이터 생성 필요

**예, 단 타입 스펙 선행 필요**. 페이즈 3 #1 또는 페이즈 4 #2 명세 인라인.

호출 후보: `/data-generator title --brief @Docs/content-design/[content]20260512_titles-and-flagship.md`

### 구현 명세서 생성

페이즈 4 #2에서:
- 호출: `/spec-writer @Docs/content-design/[content]20260512_titles-and-flagship.md` (페이즈 1 #1·#3 + 페이즈 2 #1 모두 입력)
