# 위업·연대기 시스템 컨텐츠 기획서

> 작성일: 2026-05-12
> 유형: 신규 컨텐츠 (M6 마일스톤 페이즈 1 #1)
> 선행 문서:
> - `Docs/roadmap/master_roadmap.md` 라인 1026~1110 (M6 섹션)
> - `Docs/content-design/[content]20260423_chain_quests.md` — 체인 완주 hook
> - `Docs/content-design/[content]20260503_settlement-trust-and-fixed-events.md` — 거점 사건 완주 hook
> - `band_of_mercenaries/lib/core/domain/activity_log_model.dart` — 휘발 100개 정책
> - `band_of_mercenaries/lib/core/providers/dialog_queue_provider.dart` — 큐 우선도 체계
> 후속:
> - M6 페이즈 1 #2 "칭호·간판 용병 설계" — 칭호 발급 hook이 본 문서의 6종 카테고리에 매핑
> - M6 페이즈 1 #3 "지명 의뢰 설계" — 위업 보유 여부가 지명 의뢰 등장 조건
> - M6 페이즈 2 #2 "노출 빈도·획득 페이스 밸런스" — 발급 빈도 곡선
> - M6 페이즈 4 #1 "위업·연대기 시스템 명세" — 본 문서의 데이터 모델·UI 정책을 구현 명세로 변환

---

## 개요

본 문서는 M6 "이름을 얻는 용병단" 마일스톤의 **첫 번째 토대 시스템**인 위업·연대기를 정의한다. 후속 칭호(#2)·지명 의뢰(#3) 시스템이 모두 본 시스템의 발급 이벤트를 기반으로 작동한다.

핵심 결정 사항:
1. **데이터 분리**: 위업은 영구 보관(신규 Hive 박스), 연대기는 위업 박스의 읽기 뷰, ActivityLog 100개 휘발성은 그대로 유지하되 위업 발급 시 미러 1행 추가.
2. **트리거 6종 카테고리**: 체인 완주 / 거점 사건 완주 / 거점 소속 도달 / 명성 등급 진입 / 엘리트 유니크 첫 처치 / 희귀(T3+) 제작 첫 완성. M5 시점 24~25개 템플릿, M7+ 자연 확장.
3. **다이얼로그 큐 통합**: 단일 등급 high(`chainCompleted` 동급). 단, 명성 등급 진입 위업은 별도 dialog 미발급 — 기존 `rankUp` critical dialog에 인라인 1줄("이 순간은 연대기에 새겨졌다") 추가.
4. **사망/방출 보존**: bandAchievements 박스의 `type` 필드(`achievement` / `memorial`)로 분리. mercSnapshot {id, name, jobId, jobName, tier}만 저장(~50~80B/엔트리). 사망/방출 시 memorial 엔트리 자동 추가, enqueue는 생략.
5. **데이터 모델**: Hive typeId 16(BandAchievement) + 17(enum) + 18(MercenarySnapshot). Supabase 신규 테이블 `band_achievement_templates`(27→28번째 테이블).
6. **UI**: 홈 야영지 이미지 아래 "연대기" 카드(최근 1개 + [전체 보기]) + 정보 탭 세력 도감 동급 "용병단 연대기" 신규 카드.

종료 조건 매핑(roadmap 라인 1091~1102):
| roadmap 종료 조건 | 본 문서 충족 |
|---|---|
| 3~5시간 안에 1명 이상 용병 이름·칭호 기억 | 5~7개 위업 보유, 그 중 주인공 보유 위업이 2~4개 — 자연스러운 이름 노출 |
| 시작 거점 사건 해결 용병이 연대기에 남는다 | "거점 사건 완주" 카테고리 + mercSnapshot 영구 보관 |
| 사망/방출 용병의 기록이 연대기에 남는다 | `memorial` type 엔트리 + 위업 mercSnapshot 보존 |

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 본 시스템 적용 |
|---------|-------------|---------------|
| **Dwarf Fortress — Legends Mode** | 모든 NPC와 장소의 역사를 영구 기록하여 사후에도 조회 가능 ("dorf의 일대기") | bandAchievements 박스는 영구 보관. 사망한 용병의 위업도 mercSnapshot 보존으로 "고(故) 김철수가 폐사당을 열었다" 식 회상 가능 |
| **Crusader Kings III — Dynasty Chronicle** | 가문 단위 사건의 연대기. 인물이 죽어도 가문 기록은 이어진다 | 용병 = 인물, 용병단 = 가문. 용병이 사망해도 용병단 연대기에 흔적 남음 |
| **Stardew Valley — Achievement & Item Collection Log** | 일회성 마일스톤은 영구, 일상 기록(daily log)은 휘발 | bandAchievements(영구) vs ActivityLog(휘발 100개) 분리 정책 일치 |
| **Hades — Codex & Encounter Log** | 처음 만난 적, 처음 만든 아이템에 "처음 한 번"의 특별한 알림 | "첫 엘리트 유니크 처치" / "첫 희귀 제작" — 두 번째부터는 일반 알림으로 다운그레이드 |
| **Disco Elysium — Thought Cabinet** | 영구적인 깨달음이 캐릭터의 일부가 됨 (스킬 트레잇과 분리) | 위업이 칭호(#2)와 분리되어 영구 기록만 보유 — "이력서"와 "능력치"가 다름 |
| **Kingdom of Loathing — Beach Trophies** | 게임 진행에 따라 영구히 쌓이는 "트로피" 박스 — 다회차 보전 | M6는 단일 회차 영구. 다회차는 M9+ 검토 |

**핵심 설계 원칙**: "**영구 vs 휘발의 의미 분리**" — ActivityLog는 "지금 무슨 일이 있었지?"를 빠르게 답하는 임시 알림판이고, bandAchievements는 "우리 용병단이 누군가에게 자랑할 만한 순간들"을 영구 보관하는 명예의 장이다. 두 시스템은 서로의 의미를 침범하지 않는다.

---

## 상세 설계

### 1. 3개념 데이터 분리 정책

세 개념의 책임을 다음과 같이 분리한다.

| 개념 | 저장소 | 수명 | 책임 |
|------|-------|------|------|
| **위업** | `bandAchievements` Hive 박스 (신규, typeId 16) | 영구 (앱 데이터 초기화 외 삭제 없음) | "이 순간이 우리 용병단의 일부가 되었다"는 1행짜리 영구 기록. 발급 시점에 mercSnapshot으로 당시 용병 정보를 굳혀 보관 |
| **연대기** | (저장소 없음) `bandAchievements`의 읽기 뷰 | — | 위업 박스를 시간순 정렬해 화면에 표시. 홈 카드(최근 1개)와 정보 탭 전체 화면 두 진입점 |
| **활동 로그** | `activityLogs` Hive 박스 (typeId 7, 기존) | 휘발 (`maxLogs = 100`, 초과 시 가장 오래된 행 자동 삭제) | "지금 무슨 일이 있었지?" 빠른 알림판. 위업 발급 시 ActivityLog에 미러 1행 추가하여 일반 알림 흐름과 연계 |

#### 1.1 위업 발급 시 흐름

```
AchievementService.grant(templateId, mercSnapshot?, payload):
  ├─ bandAchievements.add(BandAchievement(...))     [영구]
  ├─ activityLog.addLog(message, achievementUnlocked) [휘발 미러]
  └─ dialogQueue.enqueue(AchievementUnlockedDialog)   [팝업, 단 명성 카테고리는 생략]
```

**미러 1행의 의미**: ActivityLog에서 위업 발급을 보고 싶은 유저는 활동 로그 탭에서 색상 강조된 1줄("★ 위업: 마을의 은인 — 김철수")로 확인 가능. 100개 초과로 회전되어도 bandAchievements에는 영구 보존이므로 정보 손실 없음.

#### 1.2 연대기 화면 데이터 소스

연대기 화면은 `bandAchievements.values.toList()..sort((a,b) => b.achievedAt.compareTo(a.achievedAt))`만 보여준다. 별도 데이터 모델 없음.

**필터(M6 MVP)**: 시간순 정렬 + 카테고리 칩 6종(체인/거점사건/거점소속/명성/엘리트/제작) + memorial 토글. 용병별 필터는 #2 칭호 설계 후 결정 (M6 페이즈 1 #2에서 검토).

#### 1.3 ActivityLog 신규 enum 추가

`ActivityLogType` (`typeId 6`) 다음 가용 번호 = **29**. 신규 추가:

| HiveField | 이름 | 용도 |
|---|---|---|
| 29 | `achievementUnlocked` | 위업 발급 시 활동 로그 미러 1행. 메시지: "★ 위업: {name} — 주인공 {mercName}" 또는 "★ 위업: {name}"(주인공 없는 카테고리) |

memorial 엔트리는 별도 ActivityLog enum 없음 — 이미 `mercenaryStatus`(HiveField 1)·`mercenaryDismiss`(HiveField 4) 기존 enum이 사망/방출 알림을 처리한다. memorial은 bandAchievements에만 영구 1행 추가.

### 2. 위업 트리거 6종 카테고리

#### 2.1 카테고리 표

| # | 카테고리 ID | 발급 hook | M5 시점 인스턴스 | 주인공 | 다이얼로그 큐 |
|---|------------|----------|----------------|-------|--------------|
| 1 | `chain_completed` | `ChainQuestService.completeChain()` (chain_* prefix만) | 7 | ✓ (protagonistMercId) | high |
| 2 | `settlement_event_completed` | `ChainQuestService.completeChain()` (settlement_* prefix만) | 1 (M5 dustvile_pyegwang_reopen) | △ 마지막 step 파티 최고 기여자 | high |
| 3 | `settlement_trust_belonging` | `RegionStateRepository.addSettlementTrust()` (4단계 진입 시) | 1 (M5 region 3) | ✗ | high |
| 4 | `reputation_rank` | `ReputationService` 랭크 진입 (E/D/C/B/A) | 5 | ✗ | **인라인 통합** (별도 dialog 없음) |
| 5 | `elite_unique_first_kill` | `EliteLootService.rollDrops()` 엘리트 유니크 처치 + `firstKilledEliteIds`에 미포함 시 | 8 | ✓ 파티 최고 기여자 | high |
| 6 | `craft_first_rare` | `CraftingService.craft()` T3+ 결과물 + `firstCraftedItemIds`에 미포함 시 | 2~3 (M5: 폐광 유물 조각 T3 1종, M5 페이즈 1 #3에서 추가 T2~T3 결정 위임) | ✗ | high |
| **소계** | | | **24~25** | | |

**M7+ 자연 확장**:
- 거점 N개 → settlement_event_completed가 N개, settlement_trust_belonging이 N개
- 체인 추가 → chain_completed 자연 증가
- 엘리트 유니크 추가 → elite_unique_first_kill 자연 증가
- T4~T5 제작 추가 → craft_first_rare 자연 증가

roadmap "위업 템플릿 20~30개"는 M5~M9 전체 누적 기준으로 보면 50~100개까지 가능. M6 시작 시점 한정 24~25개로 진입.

#### 2.2 카테고리별 templateId 컨벤션

`{category_id}:{instance_id}` 형식. 예시:

| templateId | 카테고리 | 인스턴스 |
|-----------|---------|---------|
| `chain_completed:chain_roadside_shrine` | 1 | 7체인 첫 번째 |
| `chain_completed:chain_soul_severance` | 1 | 엔드게임 체인 (멸혼결) |
| `settlement_event_completed:settlement_3_pyegwang_reopen` | 2 | 더스트빌 폐광길 재개방 |
| `settlement_trust_belonging:region_3` | 3 | 더스트빌 소속 도달 |
| `reputation_rank:E` | 4 | 신출내기 진입 |
| `reputation_rank:D` | 4 | 일반 진입 |
| `reputation_rank:A` | 4 | 전설 진입 |
| `elite_unique_first_kill:elite_giant_bat` | 5 | 거대 박쥐 (M5 신설) |
| `craft_first_rare:recipe_dustvile_pyegwang_relic_fragment` | 6 | 폐광 유물 조각 T3 첫 제작 |

**유니크 제약**: `(templateId)`는 본 유저의 bandAchievements 박스 안에서 1회만 발급(중복 방지). `AchievementService.grant()`에서 사전 조회로 중복 차단.

#### 2.3 카테고리 간 결과 차이

**주인공 있음 (1·2·5)**: mercSnapshot 필수. 연대기 표시에 "주인공: 김철수 (T2 검사)" 부각.
**주인공 없음 (3·4·6)**: mercSnapshot null. 연대기 표시에 용병 이름 표기 없음.

**주인공 선정 규칙**:
- 카테고리 1 (chain_completed): `ChainQuestProgress.protagonistMercId`에서 그대로. 이미 결정된 주인공.
- 카테고리 2 (settlement_event_completed): chainQuestProgress.protagonistMercId가 null(settlement_ chain은 미설정) → **사건 마지막 step(완료 시점) 파티 최고 기여자**로 결정. step 6 폐광 재개방식 파티에서 partyPower 비중 1위 용병.
- 카테고리 5 (elite_unique_first_kill): 해당 퀘스트 파티 최고 기여자.

**주인공 사망/방출 시점에 위업 발급되면?**: 발급되는 시점에 살아있는 용병만 주인공 후보. 모든 후보가 사망한 사례(주인공이 직전 step에서 죽고 다른 용병이 마무리)는 마무리 용병이 주인공.

#### 2.4 카테고리별 발생 빈도 예측 (페이즈 2 #2에 입력)

신규 유저 누적 플레이 시간 기준 예상 위업 보유 수:

| 누적 플레이 | 예상 위업 수 | 보유 가능 카테고리 |
|---|---|---|
| 30분 | 0~1개 | 카테고리 4(명성 E) 또는 6(첫 제작 — 깃발 복원) |
| 1시간 | 1~3개 | 4 + 6 + 2 일부 진행 |
| 2시간 | 3~5개 | 4(D 진입) + 6 + 2(거점 사건 완주) + 3(거점 소속) 가능 |
| 5시간 | 5~8개 | 1(체인 1~2 완주) + 5(엘리트 유니크 1~2종) + 위 누적 |
| 10시간 | 10~14개 | 체인 3~4 + 엘리트 4~5 + 위 누적 |

roadmap 종료 조건 "3~5시간 안 1명 이상 용병 이름·칭호 기억"에 정합. 페이즈 2 #2에서 실제 발급 페이스 시뮬레이션 확정.

### 3. 다이얼로그 큐 통합

#### 3.1 신규 dialogType

`DialogTypeRegistry.achievementUnlocked` (신규 키). 추가 후 등록 키 10종(현재 9종 → 10종).

```dart
// dialog_queue_provider.dart
class DialogTypeRegistry {
  // ... 기존 9종 ...
  static const String achievementUnlocked = 'achievementUnlocked';

  static Set<String> get keys => {
    constructionComplete, investigationResult, rankUp, autoTravelEvent,
    travelChoiceRecall, chainCompleted, regionTransform, settlementTrustUp,
    idleReward,
    achievementUnlocked,  // 신규
  };
}
```

복원 메시지(앱 종료 후 재시작 시 fallback): "용병단의 새 위업이 기록되었습니다."

#### 3.2 우선도 = high (chain 동급)

**단일 등급**으로 단순화. chain·transform·settlementTrustUp과 동급. 그 위에는 critical(rankUp) 1종만 있다.

`barrierDismissible: false` — 위업 dialog는 사용자가 명시적으로 확인 버튼을 눌러야 닫힌다. "기억해야 할 순간"을 흘려보내지 않도록.

#### 3.3 명성 등급 진입 인라인 통합 (카테고리 4 예외)

명성 등급 진입은 이미 `rankUpProvider` critical로 RankUpDialog를 띄운다. 그 위에 위업 dialog까지 high로 띄우면 한 이벤트에 풀스크린 dialog 2개 연달다.

해결: 카테고리 4 위업은 `bandAchievements.add()` + `activityLog` 미러만 실행하고 **`dialogQueue.enqueue()`는 생략**한다. RankUpDialog 본체를 다음과 같이 변경:

```dart
// 기존 RankUpDialog 내부 1줄 추가
RankUpDialog(
  ...
  child: Column([
    Text('명성 등급 ${toGrade} 진입!'),
    Text('${rankBonus.description}'),
    // 신규 1줄
    const SizedBox(height: 12),
    const Divider(),
    Text(
      '✨ 이 순간은 연대기에 새겨졌다',
      style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.chainGold),
    ),
  ]),
);
```

**왜 이 방식인가**:
- 명성 5회 진입 모두에 대해 "rankUp + 위업"이 함께 발생. 자연 결합.
- bandAchievements에는 영구 저장되어 연대기 화면에서 확인 가능.
- 사용자 입장에서 RankUpDialog 하나로 두 의미("등급 올랐다" + "이 순간이 영구히 새겨졌다")를 한 번에 인지.

#### 3.4 dialog payload 정의

`DialogRequest.payload` (`Map<String, dynamic>`) 표준 키:

```json
{
  "achievementId": "uuid-...",
  "templateId": "chain_completed:chain_roadside_shrine",
  "name": "길가의 폐사당을 열어주다",
  "description": "{merc.name}이(가) 옛 수호자의 투구를 건네받았다.",
  "iconKey": "chain_shrine",
  "mercSnapshot": {              // null 가능 (주인공 없는 카테고리)
    "id": "merc_42",
    "name": "김철수",
    "jobName": "검사",
    "tier": 2
  },
  "regionId": 5,                  // 발급 발생 지역 (선택)
  "category": "chain_completed"
}
```

builder 클로저는 직렬화 불가하므로, 영속 복원 시 fallback dialog로 변환된다 (기존 dialog_queue 패턴 따름).

### 4. 사망/방출 보존 규칙

#### 4.1 `type` 필드로 두 종류 분리

`BandAchievement.type` enum:
- `achievement` — 위업 (카테고리 6종 발급분)
- `memorial` — 추모 (사망/방출 시 자동 추가)

#### 4.2 사망 시 자동 흐름

```
Mercenary 사망 시 (QuestCompletionService 또는 MercenaryService):
  1. 기존 흐름: mercenaries 박스에서 용병 제거 (또는 isDeceased=true 분기 — #2 칭호 산출물에서 결정)
  2. 신규: AchievementService.recordMemorial(
       cause: 'died_quest' | 'died_event' | 'died_old',
       mercSnapshot: {id, name, jobId, jobName, tier},
       payload: { questId?, eventId?, regionId? }
     )
       └─ bandAchievements.add(BandAchievement(
           id: uuid,
           type: memorial,
           achievedAt: now(),
           templateId: 'memorial:died_quest',  // 또는 'memorial:released'
           mercSnapshot: snapshot,
           regionId: regionId,
           payload: payload,
         ))
       └─ ActivityLog 미러 X (기존 mercenaryStatus enum이 이미 처리)
       └─ dialogQueue.enqueue() X (memorial은 팝업 X)
```

#### 4.3 방출 시 자동 흐름

```
Mercenary 방출 시 (MercenaryService.release):
  1. 기존 흐름: 퇴직금 지급 + mercenaries 박스에서 제거
  2. 신규: AchievementService.recordMemorial(
       cause: 'released',
       mercSnapshot: snapshot,
       payload: { reason?: 'voluntary' | 'capacity' }
     )
```

#### 4.4 mercSnapshot 보존 깊이 (확정)

```dart
@HiveType(typeId: 18)
class MercenarySnapshot {
  @HiveField(0) String id;          // 용병 고유 ID (참조용, 본체 삭제되어도 보존)
  @HiveField(1) String name;        // "김철수"
  @HiveField(2) String jobId;       // "job_t2_swordsman"
  @HiveField(3) String jobName;     // "검사"
  @HiveField(4) int tier;           // 2 (1~5)
}
```

크기: 50~80 bytes/엔트리. 24~25개 위업 + 일부 memorial = 평균 2~5KB/유저. Hive 부담 미미.

**왜 trait/stats/level/xp 미포함**: M6 MVP는 "이름을 기억한다"가 목적. "어떤 능력의 용병이었는가"는 트레잇·레벨이 아닌 직업·티어로 충분히 압축된다. T5 영주(legendary job)와 T1 보병이 같은 위업을 달성했을 때 보유 정보 차이가 충분히 변별. 더 깊은 스냅샷은 M9+ 검토.

#### 4.5 memorial 엔트리 UI

연대기 화면에서 memorial은 위업과 같은 시간순 흐름에 섞이되 아이콘·색상으로 구분:
- 위업: ★ (금색, `AppTheme.chainGold` 0xFFD4AF37)
- 추모: ✝ (회색, `AppTheme.surface` 또는 신규 `AppTheme.memorialGray`)

홈 카드 "최근 1개" 표시 정책: memorial이 최신이라도 표시됨(상실감 자연 노출). 단, 너무 자주 사망 발생 시 홈이 우울해질 수 있어 **카테고리 토글**로 사용자가 memorial 노출 끌 수 있게 함(M6 페이즈 4 #1 spec에서 결정).

#### 4.6 사망 자체를 위업으로 만들지 않는 이유

- 위업 = 명예. 사망은 명예 아님.
- 모든 사망을 위업으로 만들면 24~25개 위업 외에 사망 N개가 섞여 무게감 희석.
- "영웅적 사망"은 후속 마일스톤(M9 완성도)에서 별도 칭호("Fallen Hero" 등)로 처리 가능.
- roadmap "사망한 용병의 칭호와 위업은 유지" = "사망 직전에 가지고 있던 위업이 영구 보존"이지 "사망 자체가 위업"이 아니다.

### 5. 데이터 모델

#### 5.1 Hive 신규 모델 (typeId 16·17·18)

```dart
@HiveType(typeId: 16)
class BandAchievement extends HiveObject {
  @HiveField(0)
  final String id;                    // uuid

  @HiveField(1)
  final BandAchievementType type;     // achievement | memorial

  @HiveField(2)
  final DateTime achievedAt;

  @HiveField(3)
  final String templateId;            // 'chain_completed:chain_roadside_shrine' or 'memorial:died_quest'

  @HiveField(4)
  final MercenarySnapshot? mercSnapshot;

  @HiveField(5)
  final int? regionId;

  @HiveField(6)
  final Map<String, dynamic> payload; // 카테고리별 자유 메타

  BandAchievement({...});
}

@HiveType(typeId: 17)
enum BandAchievementType {
  @HiveField(0) achievement,
  @HiveField(1) memorial,
}

@HiveType(typeId: 18)
class MercenarySnapshot {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String jobId;
  @HiveField(3) final String jobName;
  @HiveField(4) final int tier;

  MercenarySnapshot({...});
}
```

**Hive 박스 추가**:
- 박스명: `bandAchievements`
- HiveInitializer 초기화 11번째 박스(기존 10 → 11). `core/data/hive_initializer.dart` 등록 필요.

**typeId 점유 갱신 (CLAUDE.md 표 업데이트)**:
| 모델 | typeId | 다음 HiveField |
|------|--------|---------------|
| BandAchievement | **16** | **7** |
| BandAchievementType (enum) | **17** | **2** |
| MercenarySnapshot | **18** | **5** |

다음 가용 typeId: **19+**. typeId **12는 여전히 미사용** (CLAUDE.md 표 보완 권장).

#### 5.2 Supabase 신규 테이블 — `band_achievement_templates`

| 컬럼 | 타입 | 제약 | 의미 |
|------|------|------|------|
| `id` | TEXT | PRIMARY KEY | templateId. 예: `chain_completed:chain_roadside_shrine` |
| `category` | TEXT | NOT NULL CHECK | 카테고리 6종 + memorial. CHECK 제약 |
| `name` | TEXT | NOT NULL | 위업 이름. 예: "길가의 폐사당을 열어주다" |
| `description_template` | TEXT | NOT NULL | TemplateEngine 문법 허용. 예: "{merc.name}이(가) 옛 수호자의 투구를 건네받았다." |
| `icon_key` | TEXT | NOT NULL DEFAULT 'default' | UI 아이콘 식별자. 예: 'chain_shrine', 'rep_rank_D', 'elite_bat' |
| `chronicle_variants` | JSONB | NULL | 연대기 표시 변주 1~3개 배열. 매 표시 시 랜덤 선택 가능 |
| `default_priority` | TEXT | NOT NULL DEFAULT 'high' CHECK | 'critical_inline' / 'high' / 'medium'. M6는 사실상 high / critical_inline 둘만 사용 |
| `narrative_hint` | TEXT | NULL | 운영자용 문구 작성 가이드. 본 산출물에서 page1과 동일한 톤 가이드 |

**CHECK 제약**:
```sql
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
```

**SyncService 등록**: 27 → 28번째 테이블. `data_versions` 엔트리 + DataLoader 캐시 파일 + StaticGameData 확장.

**Freezed 모델 신규**:
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
}
```

#### 5.3 신규 Provider 권장 목록

```
AchievementService (도메인 서비스)
  - grant(templateId, mercSnapshot?, regionId?, payload)
  - recordMemorial(cause, mercSnapshot, payload)
  - hasAchievement(templateId) -> bool   // 중복 발급 방지
  - getAll() -> List<BandAchievement>    // 시간순 정렬

bandAchievementsProvider (StateNotifierProvider)
  - 전체 위업 목록 watch. 새 발급 시 자동 업데이트
  - 카테고리/시간 필터 메서드

achievementTemplatesProvider (FutureProvider<List<BandAchievementTemplate>>)
  - SyncService 동기화된 정적 데이터 캐시

renderedAchievementProvider (family<BandAchievement, String>)
  - templateId + mercSnapshot으로 TemplateEngine 렌더된 description 반환
```

#### 5.4 TemplateEngine 통합

`description_template`에 TemplateEngine 문법 사용 가능:
- `{merc.name}` / `{merc.job}` / `{merc.tier}` — mercSnapshot 바인딩
- `{region.name}` — regionId 바인딩 (필요 시 StaticGameData에서 조회)
- `[pick A|B|C]` — 변주
- `[if has_trait:brave]...[/if]` — mercSnapshot은 트레잇 미보유이므로 mercSnapshot 기반 조건은 미지원. payload에서 별도 키 사용

**예시**:
```
"chain_completed:chain_roadside_shrine":
  description_template:
    "{merc.name}이(가) 옛 수호자의 투구를 건네받았다."

"settlement_event_completed:settlement_3_pyegwang_reopen":
  description_template:
    "더스트빌의 [pick 광장|마을길|광부 길드]에서 작은 잔치가 열렸다. 마을 사람들은 {merc.name}에게 고개를 숙였다."

"reputation_rank:D":
  description_template:
    "용병단이 [pick 일반|평범한|이름 있는] 급으로 인정받았다."
```

#### 5.5 운영 도구(operation-bom) 영향

- 신규 메뉴: `band_achievement_templates` CRUD (table-config.ts 등록)
- 24~25개 행 편집 가능 (한국어 텍스트 변경 즉시 반영)
- `chronicle_variants` JSONB 편집기 (배열 형식 검증)

### 6. UI 노출 정책

#### 6.1 홈 화면 신규 카드

야영지 이미지 아래 + 활동 로그 위에 "연대기" 카드 1개 추가.

```
홈 화면 (위→아래):
  1. 골드·위치·진행중·용병 수
  2. 야영지 이미지
  3. ★ 연대기 카드 (NEW)
       - 최근 1개 위업/추모 1행
       - 24h 이내 발급된 위업이 있으면 NEW 배지
       - [전체 연대기 보기 →] 버튼 → 연대기 화면 진입
       - 빈 상태(위업 0개): "용병단의 첫 위업을 기다립니다" + 힌트
  4. 활동 로그 (기존)
  5. 건설 미니 위젯 (기존)
  6. 설정 버튼 (기존)
```

#### 6.2 정보 탭 신규 진입점

`InfoScreen` 카드 구성:
```
정보 탭 (기존):
  · 명성 정보 카드
  · 세력 도감 카드 → FactionCodexScreen

정보 탭 (M6 추가):
  · ★ 용병단 연대기 카드 → ChronicleScreen
```

#### 6.3 ChronicleScreen 구조 (M6 MVP)

```
┌─ ChronicleScreen ──────────────────┐
│ ← 정보 (헤더)                       │
│                                     │
│ ┌─ 카테고리 칩 ────────────────────┐│
│ │ [전체] [체인] [거점] [명성]      ││
│ │ [엘리트] [제작] [추모]           ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─ 위업/추모 카드 (시간순 desc) ─┐  │
│ │ ★ 2026-05-12 14:23             │  │
│ │   체인 완주 · 길가의 폐사당     │  │
│ │   주인공: 김철수 (T2 검사)      │  │
│ │   "옛 수호자의 투구를 ..."     │  │
│ │                                 │  │
│ │ ✝ 2026-05-10 09:15             │  │
│ │   추모 · 故 박영희 (T1 보병)    │  │
│ │   '폐광 입구 정찰'에서 사망     │  │
│ │                                 │  │
│ │ ★ 2026-05-09 18:42             │  │
│ │   명성 등급 · D 진입            │  │
│ │   "일반 급으로 인정받았다"      │  │
│ │ ...                             │  │
│ └─────────────────────────────────┘ │
│                                     │
│ [더 보기]  (페이징 또는 lazy load)  │
└─────────────────────────────────────┘
```

**M6 MVP UX 정책**:
- 무한 스크롤 (lazy load) 또는 50개씩 페이징. 위업 누적이 100개 미만이면 한 번에 모두 로드.
- 카테고리 칩 다중 선택 가능 (Material 3 Chip ChoiceChip).
- 카드 탭 시 상세 다이얼로그 — 발급 시점 다이얼로그와 동일 위젯 재사용.
- 빈 상태 (위업 0개): "용병단의 여정이 곧 시작됩니다" + 게임 진행 안내.
- 빈 상태 (memorial만 0개): 토글로 추모 숨김 가능 시 자연 안내 없음.

#### 6.4 AchievementUnlockedDialog 위젯

```
┌─ AchievementUnlockedDialog ─────┐
│                                  │
│   ★ 새로운 위업                  │
│                                  │
│   길가의 폐사당을 열어주다       │
│                                  │
│   주인공: 김철수 (T2 검사)       │
│                                  │
│   "{merc.name}이(가) 옛 수호자의 │
│    투구를 건네받았다."           │
│                                  │
│                  [확인]          │
└──────────────────────────────────┘
```

- 배경: 반투명 검정 + 중앙 모달
- 강조 색: `AppTheme.chainGold` (0xFFD4AF37)
- 아이콘: templateId → iconKey → 위젯 매핑 (M6 페이즈 4 #1 spec에서 ic_chain/ic_rep/ic_elite 등 매핑 결정)
- barrierDismissible: false (확인 버튼만으로 닫힘)

#### 6.5 색상·아이콘 가이드

`AppTheme` 신규 색상 또는 기존 재사용:
- 위업 강조: `AppTheme.chainGold` (0xFFD4AF37) — 기존 chain 강조 색 재사용. M3의 ChainCompletedDialog와 시각 언어 통일.
- 추모: 신규 `AppTheme.memorialGray` (예: 0xFF6E6E6E) 또는 surface 회색 재사용.
- 카테고리별 아이콘 키 (M6 페이즈 4 #1에서 실제 아이콘 위젯 매핑):
  - chain_completed → `ic_chain`
  - settlement_event_completed → `ic_settlement`
  - settlement_trust_belonging → `ic_belong`
  - reputation_rank → `ic_rank_{grade}` (rep_rank_E, rep_rank_D, ...)
  - elite_unique_first_kill → `ic_elite_unique`
  - craft_first_rare → `ic_craft_rare`
  - memorial → `ic_memorial`

#### 6.6 정렬·필터 정책

**기본 정렬**: `achievedAt` desc (가장 최근이 위).

**필터(M6 MVP)**:
- 카테고리 칩 6+1종 (위업 6 + memorial)
- 다중 선택 시 OR 조건

**용병별 필터**: M6 페이즈 1 #2 칭호 설계에서 결정. mercSnapshot이 있는 카테고리(1·2·5)만 대상.

---

## 현재 시스템과의 연관

### 영향받는 시스템

| 시스템 | 영향 내용 | 마이그레이션 |
|--------|----------|-------------|
| Hive 박스 | `bandAchievements` 신규 박스 (11번째). HiveInitializer 등록 | 페이즈 4 #1 |
| Hive 모델 | BandAchievement(typeId 16) + enum(17) + MercenarySnapshot(18) 3종 신규 | 페이즈 4 #1 |
| `ActivityLogType` enum | HiveField 29 `achievementUnlocked` 추가 (typeId 6 유지) | 페이즈 4 #1 |
| Supabase 테이블 | `band_achievement_templates` 신규 (28번째 테이블) | 페이즈 4 #1 |
| StaticGameData | `bandAchievementTemplates` 필드 추가 | 페이즈 4 #1 |
| SyncService | 28번째 테이블 등록 + data_versions 엔트리 + DataLoader 캐시 | 페이즈 4 #1 |
| `DialogTypeRegistry` | `achievementUnlocked` 키 + restored 메시지 추가 (9 → 10종) | 페이즈 4 #1 |
| `AchievementService` 신규 도메인 | grant / recordMemorial / hasAchievement / getAll 4 메서드 | 페이즈 4 #1 |
| `ChainQuestService.completeChain()` | hook 추가 — chain_* prefix는 카테고리 1, settlement_* prefix는 카테고리 2로 grant 호출 | 페이즈 4 #1 |
| `RegionStateRepository.addSettlementTrust()` | hook 추가 — newLevel == 4 시 카테고리 3 grant 호출 | 페이즈 4 #1 |
| `ReputationService` 랭크 진입 처리 | hook 추가 — E/D/C/B/A 진입 시 카테고리 4 grant + rankUp dialog 본체 1줄 추가 | 페이즈 4 #1 |
| `EliteLootService.rollDrops()` | hook 추가 — 유니크 엘리트 처치 + 첫 발생 시 카테고리 5 grant | 페이즈 4 #1 |
| `CraftingService.craft()` | hook 추가 — 결과물 tier >= 3 + 첫 발생 시 카테고리 6 grant | 페이즈 4 #1 |
| Mercenary 사망 처리 (`QuestCompletionService`/`MercenaryStatService`) | hook 추가 — 사망 직후 recordMemorial(cause='died_*') | 페이즈 4 #1 |
| `MercenaryService.release()` (방출) | hook 추가 — 방출 직후 recordMemorial(cause='released') | 페이즈 4 #1 |
| `app.dart` ref.listen | `bandAchievementsProvider` ↔ `dialogQueueProvider` 통합 | 페이즈 4 #1 |
| `HomeScreen` | "연대기" 카드 위젯 추가 (야영지 이미지 ↔ 활동 로그 사이) | 페이즈 4 #1 |
| `InfoScreen` | "용병단 연대기" 카드 추가 (세력 도감/명성 정보 동급) | 페이즈 4 #1 |
| `ChronicleScreen` 신규 위젯 | 정보 탭 진입 + 홈 카드 탭 진입 양쪽 지원 | 페이즈 4 #1 |
| `AchievementUnlockedDialog` 신규 위젯 | high 우선도 다이얼로그 | 페이즈 4 #1 |
| `RankUpDialog` | 본체 1줄 추가 ("이 순간은 연대기에 새겨졌다") | 페이즈 4 #1 |
| `AppTheme` | `memorialGray` 신규 색상 1개 추가 | 페이즈 4 #1 |
| operation-bom | `band_achievement_templates` CRUD 메뉴 추가 | 별도 작업 |

### 호환성 검토

- **기존 사용자 세이브**: bandAchievements 신규 박스는 빈 상태로 초기화 (HiveInitializer가 자동 처리). 기존 ActivityLog 100개와 충돌 없음.
- **DialogQueueRegistry 변경**: 신규 키 1개 추가는 후방 호환. 기존 9종 영향 없음.
- **RankUpDialog 본체 1줄 추가**: 시각적 변경. 기능 영향 없음.
- **운영 도구 영향**: 신규 테이블 1개. 기존 27개 테이블 영향 없음.
- **체인/거점/명성/엘리트/제작 서비스**: hook 1줄 추가만으로 통합. 기존 흐름 변경 없음 (위업 발급 실패해도 본 흐름 정상 작동, fail-soft).

### 호환성 리스크

- **낮음**: AchievementService.grant()는 멱등성 보장 (`hasAchievement(templateId)` 사전 체크). 중복 hook 호출(예: 체인 완주 시 onComplete 두 번 호출)에도 안전.
- **낮음**: memorial 발급도 멱등성 보장 (mercSnapshot.id 기준 중복 차단). 단, 한 용병이 사망 후 또 사망할 일은 없으므로 사실상 자연 멱등.
- **중간**: RankUpDialog 1줄 추가 — UI 터치이지만 위젯 트리 변경 없음 (Column children에 SizedBox+Divider+Text 3개 추가). 기존 테스트 영향 없음 (이 부분 테스트가 별도 위젯 테스트로 존재하면 1줄 수정).
- **중간**: AchievementService hook 6개 추가 — 각 도메인 서비스의 trailing side effect로 grant 호출. fail-soft 처리(try/catch + 활동 로그 기록) 필수.

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| Hive 모델 3종 + 박스 1개 (5.1절) | **높음** | 페이즈 4 #1 명세 작성의 직접 입력. 다른 모든 hook의 토대 |
| Supabase 테이블 + 24~25개 행 시드 (5.2절) | **높음** | data-generator 출력 입력. UI 표시 데이터의 원천 |
| AchievementService 4 메서드 (5.3절) | **높음** | hook 통합 지점. fail-soft 필수 |
| 6 hook 통합 (현재 시스템과의 연관 표) | **높음** | 위업 발급의 실제 흐름. M6 페이즈 4 #1 명세에서 6개 hook 모두 spec |
| AchievementUnlockedDialog + 큐 통합 (3절) | **높음** | 발급 UX. RankUpDialog 1줄 추가 동반 |
| 홈 카드 + 정보 탭 진입점 (6.1·6.2절) | **높음** | M6 가시성 충족 |
| ChronicleScreen (6.3절) | **높음** | M6 종료 조건의 직접 충족점 |
| 사망/방출 memorial hook (4.2·4.3절) | **높음** | roadmap 완료 점검표 직접 충족 ("사망/방출 기록이 연대기에 남는다") |
| TemplateEngine 통합 (5.4절) | **중간** | 모든 카테고리에 변주 가능. 초기엔 단순 텍스트만으로도 동작 |
| memorialGray 색상 + 아이콘 매핑 (6.5절) | **중간** | 시각 차별화. M6 페이즈 4 #1 spec에서 결정 |
| 다중 선택 카테고리 칩 (6.6절) | **중간** | UX. 단일 선택만으로도 동작 |
| 용병별 필터 (6.6절) | **낮음** | M6 페이즈 1 #2(칭호) 설계 후 결정 |

---

## data-generator 지시사항

본 문서는 페이즈 4 #1 명세에서 데이터 시드와 함께 작성될 수 있으나, **24~25개 템플릿 + 변주 1~3개 = 총 30~50개 텍스트 셀**이 발생하므로 data-generator 활용이 자연스럽다.

- **대상 타입**: `band-achievement-template` (신규 — 타입 스펙 작성 필요. 페이즈 3 또는 페이즈 4 #1 명세에 인라인 처리 검토)
- **대상 테이블**: `band_achievement_templates` (신규 Supabase 테이블)
- **생성 수량**: **24~25행** (카테고리 6종 × 인스턴스 — M5 시점)
- **톤/세계관 가이드**:
  - 한국어 판타지 톤. 본 문서 §2.2 templateId 예시 + 본 문서 §5.4 description_template 예시를 작명 가이드로 사용
  - 위업 이름은 "{동사} {목적어}" 형식 권장. 예: "길가의 폐사당을 열어주다", "도적길을 끊다", "철의 서약에 응하다"
  - description_template은 1~2문장. TemplateEngine 문법 (`{merc.name}` / `{merc.job}` / `{region.name}` / `[pick A|B|C]`) 적극 활용
  - chronicle_variants 배열은 1~3개. 같은 위업의 다른 표현 변주
  - memorial 카테고리는 별도 메시지 ("폐광 입구 정찰에서 잠들었다" / "마지막 의뢰를 마치고 떠났다" 등)
  - 고유명사 저작권 금칙 (한국 웹소설 고유명사 미사용)
- **구조적 제약**:
  - id 형식: `{category}:{instance_id}` — 본 문서 §2.2 표 기반 24~25개 ID 고정
  - category 7종: `chain_completed`(7), `settlement_event_completed`(1+), `settlement_trust_belonging`(1+), `reputation_rank`(5: E/D/C/B/A), `elite_unique_first_kill`(8), `craft_first_rare`(2~3), `memorial`(공통 1~3개 템플릿)
  - icon_key는 §6.5절 가이드 키 사용
  - default_priority: `reputation_rank`는 `critical_inline` / 나머지는 `high` / `memorial`은 본 컬럼 미사용 (CHECK에 포함하지 않거나 'high' 디폴트)
- **수치 출처**:
  - chronicle_variants 개수는 운영 텍스트 변주 차원, 밸런스 무관
- **특수 요구**:
  - 체인 카테고리 7개는 본 문서 후속 chain_quests 24행 chain_id와 1:1 매칭 (M3 산출물 §2 표 참조). 명칭은 별개 작명.
  - 거점 사건 카테고리는 `settlement_3_pyegwang_reopen` 1개로 시작. M7+ 확장 시 신규 거점별 1행씩 추가.
  - reputation_rank 5개는 E/D/C/B/A 5등급에 1:1. F는 게임 시작 등급이라 제외.
  - elite_unique_first_kill 8개는 `elite_monsters.is_unique=true` 8종에 1:1 매칭. 현재 거대 박쥐(M5)는 유니크 아님이므로 일반 카테고리 미해당. 페이즈 2에서 8종 유니크 ID 확정 후 매핑.
  - craft_first_rare는 M5 시점 폐광의 유물 조각(T3) 1종. M5 페이즈 1 #3의 T2~T3 결정에 따라 2~3개로 조정.
  - memorial은 cause별 1개씩 — `memorial:died_quest`, `memorial:died_event`, `memorial:released` 3종. 변주는 각 1~3개.

---

## 오픈 질문

- **Q-1 (memorial 카테고리 세분화)**: 사망 원인을 `died_quest`(파견 중 사망) / `died_event`(여행 이벤트 사망) / `died_old`(노화 — 게임 내 미구현) / `released`(자발 방출)로 4종 분리할지, 더 단순화할지. **권장**: 3종(`died_quest` / `died_event` / `released`) — `died_old`는 향후 시스템 도입 시 추가
- **Q-2 (홈 카드 갱신 트리거)**: 새 위업 발급 시 홈 카드를 즉시 갱신할지(animation), 다음 빌드 사이클에 자연 갱신할지. **권장**: 자연 갱신 + NEW 배지로 24h 강조 (애니메이션 부담 줄이고 비주얼 강조는 배지로)
- **Q-3 (체인 완주 + 명성 등급 진입 동시 발생)**: 한 퀘스트 완료로 두 위업이 동시 발생하면 dialog 2개 큐잉. critical(rankUp + 인라인) → high(chain) 순서로 자연 정렬되지만, 사용자가 "한 번에 보는" 부담 검토. **권장**: 순차 표시 그대로 — 다이얼로그 큐가 한 번에 1개씩 처리하므로 자연
- **Q-4 (위업 발급 빈도 페이스)**: 페이즈 2 #2에서 결정. 본 문서 §2.4 예측이 실제 플레이와 일치하는지 검증 필요
- **Q-5 (memorial 토글 위치)**: ChronicleScreen 카테고리 칩 안에 포함 vs 별도 토글. **권장**: 카테고리 칩 안에 포함 (단일 인터페이스)
- **Q-6 (icon_key 매핑 시점)**: 본 문서는 키 명만 정의. 실제 아이콘 위젯 매핑은 페이즈 4 #1 spec에서 결정. **권장**: M6 MVP는 Material Icons 활용 (★ / ✝ / 🏘️ / 등 이모지 폴백)
- **Q-7 (다회차/세이브 리셋)**: 앱 데이터 초기화 시 bandAchievements도 초기화됨. "이전 회차 위업" 보존 시스템은 M9+ 검토. **권장**: M6에선 단일 회차 영구만

---

## 후속 작업

### 동일 페이즈(1) 후속 산출물

- **페이즈 1 #2 칭호·간판 용병 설계** — 본 문서의 6 카테고리가 칭호 발급 hook의 토대.
  - "마을의 은인" 칭호 → `settlement_event_completed:settlement_3_pyegwang_reopen` 위업 보유자
  - "폐광의 생존자" 칭호 → `settlement_event_completed` + 사건 진행 중 부상 경험 (mercenaryStatus 보조 hook 필요)
  - "첫 깃발을 든 자" 칭호 → `craft_first_rare:recipe_dustvile_banner_restoration` 위업 발급 시 참여 용병 (제작은 단일 행위이므로 "참여"가 어떻게 정의되는지 #2에서 결정)
  - "도적길 추적자" 칭호 → 위업과 직결 안 됨. 누적 hunt/raid 지표(`Mercenary.stats`)와 별도 hook
  - **#2 작성 시 권장 호출**: `/content-designer 칭호·간판 용병 설계: 본 문서(achievement_chronicle_system) 6 카테고리를 칭호 발급 hook의 상위 집합으로 활용. 칭호 8~12개 설계 + 발급 조건 + Mercenary.titleIds 모델 + 간판 용병 자동 선정 알고리즘`

- **페이즈 1 #3 지명 의뢰 설계** — 본 문서의 위업 보유 여부가 지명 의뢰 등장 조건.
  - "{regionName}의 영주가 {위업} 보유 용병단을 찾는다" 형식
  - 위업이 0개일 때 지명 의뢰 미등장 / 5개 이상일 때 자연 등장

### 후속 페이즈 입력

- **페이즈 2 #2 노출 빈도·획득 페이스 밸런스**: 본 문서 §2.4 예측을 시뮬레이션으로 검증. 위업 발급 페이스가 너무 빠르면 무게감 희석, 너무 느리면 종료 조건 미충족.
- **페이즈 3 #3 chronicle_template 타입 스펙 + 연대기 문구 30~50개**: data-generator 활용. 본 문서의 templateId 24~25개 × 변주 1~3개. 페이즈 4 #1 명세에 인라인 처리 또는 별도 페이즈 3 작업.
- **페이즈 4 #1 위업·연대기 시스템 명세**: 본 문서를 입력으로 spec-writer 호출. 데이터 모델·6 hook·UI 위젯·SyncService 통합 모두 spec화.

### 밸런스 검토 필요

**예**. 페이즈 2 #2에서 검토할 수치:
- 첫 위업 발생 시점 (15~30분 권장 — 첫 제작 깃발 복원 또는 명성 E 진입)
- 누적 5시간 시 보유 위업 수 (5~8개 권장 — roadmap 종료 조건 충족)
- memorial 발생 빈도 — 사망 페이스가 너무 높으면 추모가 우울감 유발

호출: `/balance-designer 위업 발급 페이스 및 카테고리별 빈도 시뮬레이션` (페이즈 2 #2)

### 벌크 데이터 생성 필요

**예, 단 타입 스펙 선행 필요**. 페이즈 3 #3 또는 페이즈 4 #1 명세 인라인.

호출 후보: `/data-generator band-achievement-template --brief @Docs/content-design/[content]20260512_achievement-chronicle-system.md`

### 구현 명세서 생성

페이즈 4 #1에서:
- 호출: `/spec-writer @Docs/content-design/[content]20260512_achievement-chronicle-system.md` (M6 페이즈 2 #2 결과 + 페이즈 1 #2·#3 결과 + #1 본 문서 모두 입력)
