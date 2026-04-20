# M2a 정수 사용 + 인벤토리 UI 구현 계획 및 결과

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md`
> 작성일: 2026-04-19
> 파이프라인: planner → coder(×16) → verifier (풀 검증)

---

## 1. 구현 요약

M2a 마일스톤 페이즈 4 산출물 3/3. 선행 산출물(인프라, 장비 효과) 위에 **정수(Essence) 영구 스탯 강화** 파이프라인과 **인벤토리 UI**를 구축했다.

- `Mercenary` 모델에 `permanentStr` / `permanentIntelligence` / `permanentVit` / `permanentAgi` (HiveField 19~22) 신설.
- `effective*` / `effective*With` 공식을 `(base + permanent + equipment) × (1 + levelBonus) × fatigueMod`로 통일.
- `EssenceService` 신설 — 정수 1개 소비 → 상한 판정(잔량 부족 시 일부 적용·손실) → `permanent*` 갱신 + 수량 차감 + 활동 로그.
- 인벤토리 화면(`InventoryScreen`) — 정보 탭 4번째 ListTile 진입, 카테고리 필터(전체/개인장비/용병단장비/소모품) + 아이템 카드 + 상세 팝업.
- 정수 사용 UX 양방향 — 경로 A(용병 상세 → `EssenceSelectSheet`) / 경로 B(인벤토리 → `EssenceTargetSheet`) + 공통 `EssenceApplyPreviewDialog`.
- 프리뷰 팝업 3단계 경고(normal / approaching / overflow) + 각인 펄스 연출(200ms `AnimatedScale`) / SnackBar(1.5s).
- 방출 다이얼로그 정수 소멸 경고 + 버튼 라벨 조건부 전환.
- 사망/방출 시 활동 로그 3종 신규(`essenceApplied` / `essenceLostOnDeath` / `essenceLostOnRelease`).

---

## 2. 변경 파일 목록

### 수정 (8개)

| 파일 경로 | 변경 요약 |
|---|---|
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` | HiveField 19~22 4종 추가, `effective*` getter 4종 + `effective*With` 4종 공식에 `+ permanent*` 삽입 |
| `band_of_mercenaries/lib/core/domain/activity_log_model.dart` | `ActivityLogType` HiveField 15~17 (`essenceApplied`·`essenceLostOnDeath`·`essenceLostOnRelease`) 추가 |
| `band_of_mercenaries/lib/features/info/view/info_screen.dart` | `_showInventory` 상태 + 분기 + `인벤토리` ListTile 4번째 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` | ConsumerWidget → ConsumerStatefulWidget 전환, 헤더바 `IconButton(Icons.auto_awesome)`, `_buildStatRow` permanent 괄호 표기 + `AnimatedScale` 펄스 |
| `band_of_mercenaries/lib/features/mercenary/view/recruit_screen.dart` | 방출 다이얼로그에 `totalPermanent > 0` 시 붉은 경고 박스 + 버튼 라벨 `[손실 감수하고 방출]` |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_provider.dart` | `dismiss` 메서드에서 `totalPermanent > 0`이면 `essenceLostOnRelease` 로그로 분기 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 사망 처리 루프(`for damage in result.mercDamages`)에서 `updateStatus` 호출 이전에 `essenceLostOnDeath` 로그 삽입 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | `_logIcon` switch에 신규 ActivityLogType 3종 case 추가 (계획 범위 외지만 enum 확장 부작용 차단용 필수 수정) |

### 신규 (7개 + 테스트 2개)

| 파일 경로 | 역할 |
|---|---|
| `band_of_mercenaries/lib/features/inventory/domain/essence_service.dart` | 정수 소비 정적 서비스 + freezed 값 객체 3종(`EssenceDescriptor`/`EssencePreview`/`EssenceApplyResult`) + enum `EssencePreviewLevel` |
| `band_of_mercenaries/lib/features/inventory/view/inventory_screen.dart` | 인벤토리 본 화면 (카테고리 필터 4종 + 리스트 + 빈 상태) |
| `band_of_mercenaries/lib/features/inventory/view/inventory_item_card.dart` | 72px 아이템 카드 (티어 색상 원형 + 이름 + 수량/장착 상태) |
| `band_of_mercenaries/lib/features/inventory/view/item_detail_sheet.dart` | 아이템 상세 바텀 시트 (카테고리별 효과 요약 + 액션 버튼) |
| `band_of_mercenaries/lib/features/inventory/view/essence_select_sheet.dart` | 경로 A 정수 선택 시트 (용병 상세 → 정수 선택) |
| `band_of_mercenaries/lib/features/inventory/view/essence_target_sheet.dart` | 경로 B 용병 선택 시트 (인벤토리 → 용병 선택) |
| `band_of_mercenaries/lib/features/inventory/view/essence_apply_preview_dialog.dart` | 정수 사용 프리뷰 다이얼로그 (3단계 경고 + apply 호출 + 중복 클릭 방지) |
| `band_of_mercenaries/test/features/inventory/domain/essence_service_test.dart` | `resolve` 5케이스 + `preview` 8케이스 (13 테스트) |
| `band_of_mercenaries/test/features/inventory/view/inventory_screen_test.dart` | 위젯 스모크 2 + 필터 로직 단위 7 (9 테스트) |

---

## 3. 계획 대비 구현 차이점

### 의도적 변경 사항

1. **FR-4 사망 로그 삽입 위치**: 명세서는 `quest_completion_service.dart` 명시했으나, 실제 사망 처리(상태 변경 + 용병 삭제)는 `quest_provider.dart`의 `_checkCompletions` 루프에서 일어남. `QuestCompletionService.calculate`는 순수 계산만 담당하므로 **순수성 유지를 위해 로그 삽입 위치를 `quest_provider.dart`로 조정**. 타이밍("용병 삭제 이전")은 충족.
2. **TASK-16 인벤토리 위젯 테스트**: `MercenaryListNotifier` 생성자가 `gameTickProvider`(Stream.periodic)를 listen하므로 FakeAsync 환경에서 pending 상태로 `pumpAndSettle` 무한 대기 발생. **아이템 목록 렌더링 위젯 테스트 대신 `_filteredRows` 동일 로직을 단위 테스트로 추출**하여 카테고리 필터·정렬 규칙을 9케이스로 커버.
3. **TASK-11 `_buildStatChip` 리팩토링**: `AnimatedScale` 래핑 시 `Expanded`가 자식 위젯 내부에 있으면 레이아웃 오류 발생. `_buildStatChip`에서 `Expanded` 제거 후 `_buildStatRow`의 Row 직계 자식에서 `Expanded(AnimatedScale(_buildStatChip))` 구조로 재배치.
4. **`home_screen.dart` 수정**: 계획 범위 외였으나 `ActivityLogType` enum 확장으로 `_logIcon` switch가 non-exhaustive가 되어 컴파일 에러 발생. 신규 3종 case 추가 (아이콘 `✧`/`💀`/`👋`).
5. **프리뷰 다이얼로그 헤드 숫자 수정 (PHASE 3 피드백)**: verifier ISSUE-1 반영. "현재 STR" 헤드를 `${base + currentPermanent}`로, "사용 후 STR" 헤드를 `${base + newPermanent}`로 변경하여 사용 전/후 값 변화가 헤드에서도 시각화되게 함.

### 명세 준수 사항

- HiveField 18(`legendaryDeathPreventionCooldownUntil`, 산출물 2에서 점유) 건너뛰지 않고 19~22 순차 할당.
- 티어별 효과 `{1:1, 2:2, 3:4, 4:7, 5:11}`, 상한 `{1:10, 2:20, 3:40, 4:70, 5:120}` balance-design 확정값 적용.
- 한국어 UI/주석 유지, `avoid_print` 린트 준수 (debugPrint 사용), `ConstrainedBox(maxWidth: 430)` 제약 위배 없음(기존 `_MobileFrame` 내부 상태 기반 전환만 사용).

---

## 4. 검증 결과 (PHASE 3)

### 검증 모드: 풀 검증 (verifier 서브에이전트)

TASK 수 16개(≥3)이므로 verifier 호출.

**판정: PASS (with warnings)**

#### 정적 분석
- `flutter analyze`: **PASS** (0 issues)

#### 자동 분석에서 감지된 초기 이슈 및 해결

| 이슈 | 심각도 | 해결 방식 |
|---|---|---|
| `home_screen.dart:555` switch non-exhaustive | Critical | 신규 `ActivityLogType` 3종 case 추가 |
| `unnecessary_underscores` × 3 (essence_select_sheet, essence_target_sheet, inventory_screen) | Minor | `(_, __)` → `(_, _)`로 교체 |
| `dangling_library_doc_comments` (inventory_screen_test.dart) | Minor | `///` 라이브러리 doc comment → `//` 일반 주석으로 변환 |

#### verifier 분석 minor 이슈 (3건)

| 이슈 | 처리 |
|---|---|
| [ISSUE-1] 프리뷰 팝업 헤드 숫자가 사용 전/후 동일 | **수정 반영** — `essence_apply_preview_dialog.dart:121-128` 헤드 값을 `base + permanent` 합계로 표시 |
| [ISSUE-2] 사망 로그 위치가 `quest_completion_service`가 아닌 `quest_provider`에 | **유지 (기능 충족)** — QuestCompletionService 순수성 유지 의도, removeDead 이전 타이밍 충족 |
| [ISSUE-3] `EssenceService.apply` 단위 테스트 없음 | **향후 과제로 이관** — Hive/Repository 의존성으로 통합 테스트 영역. 명세서 엣지 케이스 및 프리뷰 로직은 13 단위 테스트로 충분 커버 |

#### 테스트
- **363/363 통과** (신규 22 + 기존 341).

---

## 5. 코드 생성 실행 내역

`dart run build_runner build --delete-conflicting-outputs` 2회 실행:

1. **1차** (TASK-1, TASK-2 완료 후): `mercenary_model.g.dart`, `activity_log_model.g.dart` 재생성.
2. **2차** (TASK-3 완료 후): `essence_service.freezed.dart` 신규 생성.

코드 생성 대상 파일:
- `lib/features/mercenary/domain/mercenary_model.dart` (hive_generator, HiveField 19~22 추가)
- `lib/core/domain/activity_log_model.dart` (hive_generator, enum HiveField 15~17 추가)
- `lib/features/inventory/domain/essence_service.dart` (freezed, sealed 값 객체 3종)

---

## 6. CLAUDE.md 준수 사항

- **HiveField 순차 할당**: 18(기존) → 19~22(신규) 순차, 건너뛰지 않음.
- **Navigator.push 금지**: 인벤토리 화면·프리뷰 팝업 모두 `showModalBottomSheet`/`showDialog` 또는 `InfoScreen._showInventory` 상태 기반 전환으로 구현. `Navigator.push` 사용 없음.
- **`ConstrainedBox(maxWidth: 430)` 존중**: 기존 `_MobileFrame` 내부에서 렌더. 제약 밖으로 나가지 않음.
- **한국어 우선**: UI 텍스트·주석·로그 메시지 모두 한국어.
- **`avoid_print` 린트**: `EssenceService.resolve` 스키마 경고 등은 `debugPrint` 사용.
- **불필요한 파일 생성 지양**: 기획에 없는 새 문서/임시 파일 생성 없음.

**CLAUDE.md 금지사항 위반 없음.**

---

## 7. 후속 작업 안내

### 즉시 후속 (페이즈 3, data-generator)

- 정수 20종(4축 × 5티어) `items` 테이블 벌크 생성. 본 구현이 `category == 'consumable'` + `effect_json.permanent_stat_gain.{stat}` 스키마를 전제로 파싱.
- `.claude/skills/data-generator/types/essence.md` 타입 스펙 작성 선행 필요.

### 향후 과제

- **`EssenceService.apply` 통합 테스트**: Hive 임시 박스 + FakeActivityLogNotifier로 정상/`full_cap`/`schema` 3케이스 커버 (verifier ISSUE-3).
- **다중 소비 UI** (M2b 이후): `EssenceService.applyBatch(List<InventoryItem>)`.
- **M6 승급 재료 재사용**: `EssenceService.consumeForPromotion(...)` — permanent 유지 + tier cap 확장.
- **인벤토리 UI 위젯 통합 테스트**: `gameTickProvider` override 또는 `MercenaryListNotifier` 리팩토링 후.

### 마무리

커밋과 변경로그 아카이브가 필요하시면 `finalize-feature` 스킬을 실행하세요.

- 변경 파일 총 8 수정 + 7 신규 + 2 테스트 = **17개** (계획 범위 내 16 + 범위 외 home_screen.dart 1 — enum 확장 파생 수정).
- build_runner 재실행은 완료 상태. 추가 실행 불필요.
