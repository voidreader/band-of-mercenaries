# 세력 발견 시스템 구현 계획서

Skill used : implement-agent

> 명세서: Docs/spec/[spec]20260415_faction-discovery-phase6.md
> 작성일: 2026-04-15

---

## 1. 구현 개요

지역 조사 시스템(Phase 1)에 `faction_clue` discovery 타입을 추가하여 세력 발견 흐름을 구현했다. 단서는 Hive `factionStates` 박스에 저장되고, 신설된 **정보 탭**의 세력 도감에 표시된다. 설정 탭은 홈 화면 상단 톱니바퀴 버튼으로 이전되었다.

---

## 2. 변경 파일 목록

### 수정 파일

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/app.dart` | 수정 | `_screens[5]`: `SettingsScreen()` → `InfoScreen()`, import 교체 |
| `lib/shared/widgets/bottom_nav_bar.dart` | 수정 | 인덱스 5 탭: `⚙ 설정` → `📋 정보` |
| `lib/features/home/view/home_screen.dart` | 수정 | `_showSettings` 상태 변수 + 설정 아이콘 버튼 추가, 상태 기반 SettingsScreen 렌더링 |
| `lib/core/data/sync_service.dart` | 수정 | `allTables`에 `'factions'` 추가 |
| `lib/core/data/hive_initializer.dart` | 수정 | `FactionClueRecordAdapter`(typeId:10), `FactionStateAdapter`(typeId:9) 등록 + `factionStates` 박스 오픈 + `factionStateBoxName` 상수 |
| `lib/core/providers/static_data_provider.dart` | 수정 | `StaticGameData.factions: List<FactionData>` 필드 + DataLoader 호출 추가 |
| `lib/features/investigation/domain/investigation_result.dart` | 수정 | `factionClues: List<FactionClueResult>` 필드 추가 (기본값 `const []`) |
| `lib/features/investigation/domain/investigation_notifier.dart` | 수정 | `_completeInvestigation()` 내 `faction_clue` 분기 + 활동 로그 중복 방지 + 생성자 호출부 2곳 수정 |
| `lib/features/investigation/view/investigation_widget.dart` | 수정 | `InvestigationResultDialog` → ConsumerWidget 전환, "새로운 단서 발견!" 섹션 + "도감에서 확인" 버튼 추가 |
| `test/features/quest/domain/quest_completion_service_test.dart` | 수정 | `StaticGameData` 생성자에 `factions: const []` 인자 추가 |

### 신규 생성 파일

| 파일 경로 | 역할 |
|-----------|------|
| `lib/features/info/domain/faction_data.dart` | FactionData freezed + json_serializable 정적 데이터 모델 |
| `lib/features/info/domain/faction_data.freezed.dart` | 코드 생성 (build_runner) |
| `lib/features/info/domain/faction_data.g.dart` | 코드 생성 (build_runner) |
| `lib/features/info/domain/faction_state_model.dart` | FactionState(typeId:9) + FactionClueRecord(typeId:10) Hive 모델 |
| `lib/features/info/domain/faction_state_model.g.dart` | 코드 생성 (build_runner) |
| `lib/features/info/domain/faction_clue_result.dart` | FactionClueResult DTO (InvestigationResult → UI 전달용) |
| `lib/features/info/domain/faction_codex_providers.dart` | `factionCodexScrollTargetProvider`(StateProvider<String?>) + `factionListProvider`(Provider<List<FactionData>>) |
| `lib/features/info/data/faction_state_repository.dart` | FactionStateRepository — `getState`, `processClue`, `getAll` CRUD |
| `lib/features/info/view/info_screen.dart` | 정보 탭 루트 화면 (상태 기반 화면 전환 허브) |
| `lib/features/info/view/faction_codex_screen.dart` | 세력 도감 목록 화면 (별 진행도, 자동 스크롤) |
| `lib/features/info/view/faction_detail_screen.dart` | 세력 상세 화면 (maxClueLevel 기반 정보 공개 제어) |

---

## 3. 구현 계획 및 실제 개발 사항

### 단계별 실행 순서

| 단계 | 태스크 | 병렬 여부 |
|------|--------|----------|
| 1 | TASK-1(FactionData), TASK-2(FactionState모델), TASK-4(FactionClueResult), TASK-6(SyncService) | 병렬 |
| 2 | TASK-3(build_runner 1차) | 순차 |
| 3 | TASK-5(HiveInit), TASK-7(StaticData), TASK-8(InvestResult), TASK-9(Repository), TASK-10(Providers), TASK-16(HomeScreen), TASK-17(BottomNav) | 병렬 |
| 4 | TASK-11(InvestNotifier) | 순차 |
| 5 | TASK-13(FactionCodex), TASK-14(FactionDetail) | 병렬 |
| 6 | TASK-12(InfoScreen) | 순차 |
| 7 | TASK-15(InvestDialog) | 순차 |
| 8 | TASK-18(app.dart) | 순차 |
| 9 | TASK-19(build_runner 2차 + analyze) | 순차 |

### 주요 설계 결정사항

- **`discoveredInRegions`**: `clueRecords`에서 `regionId` getter로 동적 계산 (중복 저장 없음)
- **스크롤 null 초기화**: `addPostFrameCallback` 패턴 (Flutter 표준)
- **HomeScreen 설정 오버레이**: `_showSettings` 상태 변수로 조건 분기 (Navigator.push 미사용)
- **`factionListProvider`**: `Provider<List<FactionData>>` + `.value?.factions ?? const []` null 가드
- **`tier_range` 역직렬화**: `@JsonKey(name: 'tier_range') required List<int> tierRange` (json_serializable 자동 처리)
- **FactionClueRecord 어댑터 등록 순서**: typeId:10 먼저, typeId:9 나중 (List 내 하위 타입 직렬화 요건)

---

## 4. verifier 검증 결과

### 1차 검증: FAIL

| 이슈 | 심각도 | 상태 |
|------|--------|------|
| [ISSUE-1] `InfoScreen`이 `factionCodexScrollTargetProvider` 감지 후 자동 네비게이션하지 않음 | warning | 수정 완료 |

**수정 내용**: `info_screen.dart`의 `build()` 상단에 `ref.watch(factionCodexScrollTargetProvider)` 추가, non-null 시 `addPostFrameCallback`으로 `_showCodex = true` 자동 전환.

### 2차 검증: PASS

모든 FR 요구사항 충족, 이슈 없음.

---

## 5. 빌드/테스트 결과

- **build_runner**: 1차(5 outputs 생성), 2차(0 outputs — 변경 없음) 성공
- **flutter analyze**: dispatch_screen.dart의 기존 info 경고 4개 (이번 구현과 무관한 사전 존재 경고)
- **flutter test**: 176/176 통과

---

## 6. build_runner 재실행 필요 파일

이미 실행 완료. 생성된 파일:
- `lib/features/info/domain/faction_data.freezed.dart`
- `lib/features/info/domain/faction_data.g.dart`
- `lib/features/info/domain/faction_state_model.g.dart`

---

## 7. CLAUDE.md 금지사항 위반

없음.

---

## 8. Supabase 선행 작업 안내 (앱 외부)

구현 완료된 앱을 실제 동작시키려면 Supabase에 다음 작업이 선행되어야 한다:

1. `factions` 테이블 생성 (스키마: `id TEXT PK, name TEXT, description TEXT, philosophy TEXT, tier_range JSONB, color TEXT`)
2. `data_versions`에 `factions` 행 추가 (`version: 1`)
3. 세력 마스터 데이터 삽입
4. `region_discoveries`에 `discovery_type = 'faction_clue'`인 행 삽입 (discovery_data: `{"faction_id": "...", "clue_level": 1, "clue_text": "..."}`)
