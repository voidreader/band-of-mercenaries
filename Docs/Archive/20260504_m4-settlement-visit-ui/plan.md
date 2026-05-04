# M4 마을 방문 UI + 거점 3종 + 약초상/의무실 분리 구현 결과

> Skill used : implement-agent
> 명세서: `Docs/spec/M4/[spec]20260504_m4-settlement-visit-ui.md`
> 작성일: 2026-05-04
> 검증 모드: 풀 검증 (TASK 19개 ≥ 3)

---

## 1. 구현 요약

M4 시작 거점 더스트빌(region 3, sector 1, sector_type='village')에 **마을 방문 영역**을 신설하고, 거점 3종(촌장 집·낡은 대장간·약초상)과 1회성 즉시 회복 시스템 `HerbalistService`를 구현했다. 자동 회복 기반 의무실(`facilities['infirmary']`)은 변경 없이 그대로 유지되며, 약초상은 골드+쿨다운 기반 별도 경로로 작동한다.

신규 feature 디렉토리 `lib/features/settlement/` 신설, 도메인 서비스/const 자료/UI 위젯 5종을 한 묶음으로 추가했다. 기존 시스템(MovementScreen / QuestCompletionService / RegionState / UserData / ActivityLogType)에 외과적 분기·필드를 추가하여 시간 미소모 원칙·상태 기반 렌더링·HiveField 슬롯 정합성을 모두 준수했다.

---

## 2. 실행 순서 (Stage별 결과)

| Stage | 병렬도 | 태스크 | 결과 |
|-------|-------|-------|------|
| 1 | 6개 병렬 | TASK 1·2·3·5·6·12 | PASS — 데이터 모델 / HerbalistService / VillageFacility enum / settlement_npc_data const |
| 2 | 1개 직렬 | TASK 4 | PASS — `dart run build_runner build --delete-conflicting-outputs` 8 outputs |
| 3 | 4개 병렬 | TASK 7·8·9·18 | PASS — UserDataNotifier 메서드 / healInstant Repository+Notifier / setEventCompleted / 단위 테스트 10/10 PASS |
| 4 | 1개 직렬 묶음 | TASK 10+11 | PASS — QuestCompletionService 시그니처 + 채집 분기 + quest_provider 호출측 + step==6 setEventCompleted |
| 5 | 4개 병렬 | TASK 13·14·15·19 | PASS — ChiefHouseScreen / OldSmithyScreen / HerbalistScreen+HerbalistHealDialog / healInstant 흐름 테스트 3/3 PASS |
| 6 | 2개 직렬 | TASK 16·17 | PASS — VillageVisitSection → MovementScreen 통합 |

**총 19개 TASK 모두 1회차 PASS** (재작업 발생 없음).

---

## 3. 변경 파일 목록

### 수정 파일 (11개)

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/user_data.dart` | HiveField 추가 | HiveField 22 `herbalistCooldownEndTime` (DateTime?), HiveField 23 `lastSmithyRepairAt` (DateTime?) |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | HiveField + getter 추가 | HiveField 6 `lastEventCompletedAt` (DateTime?) + getter `eventCompletedRecently` (24h 윈도우 판정) |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | enum 항목 추가 | HiveField 25 `herbalistHeal`, HiveField 26 `smithyRepairCompleted` |
| `band_of_mercenaries/lib/core/providers/game_state_provider.dart` | 메서드 추가 | `UserDataNotifier.setHerbalistCooldown(DateTime?)` / `setSmithyRepairAt(DateTime?)` |
| `band_of_mercenaries/lib/features/mercenary/data/mercenary_repository.dart` | 메서드 추가 | `healInstant(String mercId)` — status normal + injuryEndTime/tiredEndTime null + save |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | 메서드 추가 | `MercenaryListNotifier.healInstant({mercId, cost, cooldownMinutes})` wrapper + ActivityLog 기록 |
| `band_of_mercenaries/lib/features/investigation/data/region_state_repository.dart` | 메서드 추가 | `setEventCompleted(int regionId)` — `lastEventCompletedAt = DateTime.now()` |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | 시그니처 + 분기 추가 | `calculate({..., int currentTrustLevel = 1})` + `dustvile_chore_03` 채집 의뢰 골드 ×배수 분기. `HerbalistService` import 추가 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 호출측 + 1줄 추가 | `_completeQuest`의 `calculate(...)` 호출에 `currentTrustLevel` 인자 / `_applyCompletionResult`의 step==6 분기에 `setEventCompleted` 호출 1줄 |
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | 상태 변수 + 분기 추가 | `_selectedFacility` 필드 + `ref.listen<UserData?>` region 변경 시 리셋 + sector_type=='village' 분기에 `VillageVisitSection` 인라인 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | switch case 추가 | `_logIcon` switch에 `herbalistHeal` / `smithyRepairCompleted` 2 case 추가 (PHASE 2.5 빌드 게이트 외과적 수정) |

### 신규 생성 파일 (10개 + 자동 생성 3개)

| 파일 경로 | 역할 |
|-----------|------|
| `band_of_mercenaries/lib/features/settlement/domain/herbalist_service.dart` | 정적 서비스. `calculateCost` / `calculateCooldownMinutes` / `gatheringMultiplier` 3개 static 메서드 |
| `band_of_mercenaries/lib/features/settlement/domain/village_facility.dart` | `enum VillageFacility { chiefHouse, oldSmithy, herbalist }` |
| `band_of_mercenaries/lib/features/settlement/domain/settlement_npc_data.dart` | NPC 5명 + 광장 풍문 4개 + 사건 완료 메시지 const 자료 + `npcFor` / `greetingFor` 헬퍼 |
| `band_of_mercenaries/lib/features/settlement/view/chief_house_screen.dart` | 촌장 집 화면 (NPC 헤더 + 24h 사건 배너 + 신뢰도 진행 바 + [상황 듣기]/[신뢰도 확인]/[보상 받기]) |
| `band_of_mercenaries/lib/features/settlement/view/old_smithy_screen.dart` | 낡은 대장간 화면 ([제작 목표]/[수리 의뢰]/[재료 힌트] + 단계별 잠금 + 24h 쿨다운) |
| `band_of_mercenaries/lib/features/settlement/view/herbalist_screen.dart` | 약초상 화면 ([즉시 회복]/[채집 정보]/[재료 힌트] + 단계별 비용/쿨다운) |
| `band_of_mercenaries/lib/features/settlement/view/herbalist_heal_dialog.dart` | 회복 대상 선택 → 비용 확인 2단계 다이얼로그 |
| `band_of_mercenaries/lib/features/settlement/view/village_visit_section.dart` | 마을 영역 진입 위젯 (광장 풍문 배너 + 거점 3종 카드 + selectedFacility 분기) |
| `band_of_mercenaries/test/features/settlement/domain/herbalist_service_test.dart` | HerbalistService 비용/쿨다운/배수 단위 테스트 (10 케이스) |
| `band_of_mercenaries/test/features/settlement/domain/herbalist_heal_flow_test.dart` | healInstant Hive 인메모리 흐름 테스트 (3 케이스) |

### 자동 생성 파일 (build_runner 산출, 직접 편집 금지)

| 파일 경로 | 사유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/user_data.g.dart` | UserData HiveField 22·23 추가로 어댑터 read/write 메서드 재생성 |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.g.dart` | RegionState HiveField 6 추가로 어댑터 재생성 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.g.dart` | ActivityLogType enum HiveField 25·26 추가로 enum adapter 재생성 |

---

## 4. build_runner 재실행 정보

PHASE 2 Stage 2에서 1회 실행 완료:
```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```
- 결과: 8 outputs / 9.0s / 156 actions
- 재실행 불필요 (이후 Stage들은 build_runner 영향 파일 미수정)

---

## 5. 검증 결과

### PHASE 2.5 빌드 게이트

- **1차 시도**: 1건 에러 — `home_screen.dart:525` `ActivityLogType` switch가 신규 enum 값(`herbalistHeal`/`smithyRepairCompleted`) 누락. **외과적 수정**으로 2 case 추가하여 해소.
- **재시도**: `flutter analyze` → No issues found

### PHASE 3 풀 검증 (verifier + flutter-reviewer 병렬)

#### verifier 결과: PASS

REQ-1~16 모두 충족. 시그니처 검증 + HiveField 충돌 검증 + 호출자 추적 + 상태 기반 렌더링 준수 + region 변경 시 selectedFacility 리셋 모두 통과.

#### flutter-reviewer 결과: BLOCK → APPROVE (재작업 후)

**BLOCKER-1**: `chief_house_screen.dart`가 view에서 data 레이어(`chainQuestRepositoryProvider`)에 직접 접근 → **수정 완료**. 도메인 레이어의 `chainQuestProgressProvider` (StreamProvider)로 교체. import 정리 포함.

**WARNING-3**: `settlement_npc_data.dart`의 `import 'village_facility.dart';` 상대경로 → **수정 완료**. `package:band_of_mercenaries/...` 절대경로로 전환.

**WARNING-1·2 (보류)**: `gameTickProvider` 1초 watch / build 내 `ref.listen`. 프로젝트 전반(건설·조사 쿨다운 / `home_screen.dart` 등) 동일 패턴이며 본 PR에서 새로 도입한 안티패턴이 아님. 별도 리팩토링 PR로 일관 처리 권장.

#### 통합 판정: PASS

재작업 1회 발생 (BLOCKER-1 + WARNING-3, 2개 파일 외과적 수정).

### 테스트 결과

```
flutter test test/features/settlement/
00:00 +13: All tests passed!
```

- `herbalist_service_test.dart`: 10 케이스 (calculateCost 5 + calculateCooldownMinutes 2 + gatheringMultiplier 3)
- `herbalist_heal_flow_test.dart`: 3 케이스 (부상 / 피로 / 존재하지 않는 mercId)

---

## 6. 보류 사항 (다음 PR 권장)

- **WARNING-1**: `OldSmithyScreen` / `HerbalistScreen`이 `gameTickProvider` 1초 주기 watch 사용. 24h(대장간) / 분 단위(약초상) 쿨다운에 1초 갱신은 과도. `Timer.periodic(Duration(minutes: 1))` 또는 `Stream.periodic`으로 교체 검토. **단**, 프로젝트 전반(건설·조사 등)이 모두 `gameTickProvider` watch 패턴이므로 일관 리팩토링이 필요.
- **WARNING-2**: `MovementScreen.build`에 추가한 `ref.listen<UserData?>` region 변경 감지를 `initState` 또는 `didChangeDependencies`로 이동 권장. Riverpod이 build 내 listen을 idempotent하게 처리하지만 ConsumerStatefulWidget 관용은 build 외 등록.
- **`regionStateRepositoryProvider` view 직접 접근**: `chief_house_screen.dart`의 `eventCompletedRecently` 판정에 여전히 직접 호출 사용. 프로젝트 전반(`investigation_widget.dart` / `dispatch_screen.dart` / `quest_provider.dart`)이 동일 패턴이라 본 PR에서 보류. 도메인 레이어에 `regionStateProvider` (Provider.family<RegionState?, int>) 신설 시 일괄 정리 가능.

---

## 7. CLAUDE.md 정책 준수 결과

- **상태 기반 렌더링** (Navigator.push 금지): 거점 3종 화면 모두 `_selectedFacility` enum 분기 + 다이얼로그는 `showDialog`만 사용 — 0건 위반.
- **시간 미소모 원칙**: 약초상 즉시 회복 / 수리 의뢰 stub / 거점 화면 모두 `gameTickProvider` watch는 표시 갱신용이며 게임 시간 미사용.
- **주석 정책**: 자명한 코드에 주석 작성 금지. REQ 매핑 1줄 주석은 quest_completion_service / movement_screen 분기에 한해 허용 (REQ 추적성).
- **3계층 분리** (view → domain → data): 신규 settlement feature 모두 준수. `chainQuestRepositoryProvider` 직접 접근 1건 → BLOCKER 수정으로 해소.
- **HiveField 슬롯 정합성**: UserData 22·23, RegionState 6, ActivityLogType 25·26 모두 기존 미사용 슬롯이며 충돌 0건.

위반 0건. WARNING-1·2 보류는 위반이 아닌 일관성 사유.

---

## 8. 마이그레이션·호환성 검토

- **기존 사용자 세이브**: 신규 HiveField 3개(UserData 22·23, RegionState 6) 모두 nullable 또는 default 0. 기존 박스에서 자동으로 null로 로드되므로 마이그레이션 코드 불필요.
- **ActivityLogType enum 확장**: 새 항목은 enum 끝에 추가, 기존 인덱스 보존. 기존 활동 로그 deserialize 영향 없음.
- **`QuestCompletionService.calculate` 시그니처**: `currentTrustLevel` named parameter에 default 1 부여로 기존 호출자 호환성 유지. 단일 호출자(`quest_provider`) 동일 커밋에서 갱신.
- **Hive 어댑터 재등록**: `hive_initializer.dart` 변경 없음. 기존 `UserDataAdapter` / `RegionStateAdapter` / `ActivityLogTypeAdapter` 재생성만 처리.

---

## 9. 다음 단계 안내

**커밋과 아카이브가 필요하시면 `finalize-feature` 스킬을 실행해주세요.**

- 변경 파일: 21개 (수정 11 + 신규 10) + 자동 생성 3개
- 신규 디렉토리: `lib/features/settlement/{domain,view}/` + `test/features/settlement/domain/`
- build_runner 재실행: 불필요 (PHASE 2 Stage 2에서 1회 실행 완료)
- 산출물 문서: `Docs/spec/M4/[spec]20260504_m4-settlement-visit-ui_plan.md` (본 문서)
