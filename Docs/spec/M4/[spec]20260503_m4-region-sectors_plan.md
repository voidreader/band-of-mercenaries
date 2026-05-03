# M4 페이즈 4 #2 region_sectors 신규 테이블 + 섹터 데이터 기반 렌더링 구현 계획·결과

Skill used : implement-agent

> 명세서: `Docs/spec/M4/[spec]20260503_m4-region-sectors.md`
> 기획 문서:
> - `Docs/content-design/[content]20260503_sector-system-redesign.md` (페이즈 1 #2)
> - `Docs/content-design/[content]20260503_starting-settlement.md` (페이즈 1 #3)
> 작성일: 2026-05-03
> 선행 페이즈: 페이즈 4 #1 `[spec]20260503_m4-region-migration.md`

---

## 1. 구현 계획 요약

### 사용자 결정사항 (재확정)

- **Q1=D**: region_sectors 데이터 시드 0건. 더스트플레인(region 3) 4섹터만 코드 fallback 상수로 인라인. 약 164행 시드는 후속 페이즈 위임.
- **Q2=C**: UserData.sector clamp는 페이즈 4 #1로 충분. 단 regionStates.sectorChanges 키 정리는 별도 멱등성 플래그(`region_sector_count_v1`)로 1회.
- **Q3=A**: GameConstants.sectorCount 완전 제거 + movement_screen.dart hardcoded 10 동적 변환.
- **Q4=A**: MovementScreen 단일 Wrap 레이아웃 유지.
- **Q5=B**: dungeon/field quest_pools 풀 추가는 페이즈 4 #3 위임.
- **Q6**: sectorType String 유지(enum 미도입).
- **Q7**: 시드 미배포 + region 3 외 region 진입 시 lookup → null → 번호만 표시.
- **Q8**: 0-based↔1-based 변환 헬퍼 미도입. 주석 명문화로만 처리.

### 13개 TASK 4단계 실행 순서

| 단계 | 병렬/직렬 | TASK 수 | 비고 |
|------|----------|---------|------|
| 1 | 병렬 | 8개 (1·2·3·4·5·6·12·13) | 의존성 없는 인프라 |
| build_runner 1차 | — | — | freezed/json 생성 |
| 2 | 병렬 | 3개 (7·8·9) | 1단계 의존 |
| 3 | 직렬(독립 파일이라 사실상 병렬) | 2개 (10·11) | 2단계 의존 |
| 4 (검증) | 병렬 | verifier + flutter-reviewer | PHASE 3 풀 검증 |

---

## 2. 변경 파일 목록

### 2.1 신규 생성 (3개)

| 파일 경로 | 역할 | TASK |
|-----------|------|------|
| `band_of_mercenaries/lib/core/models/region_sector.dart` | RegionSector freezed 모델 (7필드, snake_case @JsonKey, 1-based sector_index 정책 docstring) | TASK-2 |
| `band_of_mercenaries/lib/core/data/region_sector_fallback.dart` | 더스트플레인 4섹터 fallback 상수 + `lookupSector(regionId, sectorIndex, regionSectors)` 정적 헬퍼. staticData → fallback(region 3 한정) → null 우선순위 | TASK-9 |
| `band_of_mercenaries/supabase/migrations/20260503_m4_phase4_2_region_sectors.sql` | 단일 BEGIN/COMMIT 트랜잭션. 5섹션: §1 ASSERT chain_quests / §2 ALTER regions + CREATE region_sectors + INDEX / §3 UPDATE regions sector_count=5 4행 / §4 region_discoveries 재매핑 / §5 data_versions UPDATE 2 + INSERT 1 | TASK-6 |

### 2.2 수정 (10개)

| 파일 경로 | 변경 내용 | TASK |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/region.dart` | `@JsonKey('sector_count') @Default(4) int sectorCount` 필드 추가 | TASK-1 |
| `band_of_mercenaries/lib/core/providers/static_data_provider.dart` | RegionSector import + `regionSectors` 클래스 필드 + 생성자 파라미터 + builder 한 라인 (총 4곳 갱신) | TASK-7 |
| `band_of_mercenaries/lib/core/data/sync_service.dart` | `allTables`에 `'region_sectors'` 추가 (regions 다음, M4 페이즈 4 #2 코멘트) | TASK-8 |
| `band_of_mercenaries/lib/core/constants/game_constants.dart` | `@Deprecated sectorCount = 10` 두 줄 완전 삭제 | TASK-4 |
| `band_of_mercenaries/lib/features/movement/view/movement_screen.dart` | (1) RegionSectorFallback import / (2) `effectiveSelectedSector` 로컬 clamp 변수 도입 (build State 변이 회피) / (3) `List.generate(targetRegion.sectorCount, ...)` 동적 그리드 / (4) `sectorChanges[sectorKey] ?? RegionSectorFallback.lookupSector(...)?.sectorType` 우선순위 결정 / (5) `_SectorTile._transformColor`/`_transformIcon` switch에 dungeon·field 분기 추가 / (6) ◀/▶ region 변경 onTap 핸들러 setState 내부에 sector clamp | TASK-11 + 후속 수정 |
| `band_of_mercenaries/lib/core/theme/app_theme.dart` | `sectorDungeon = Color(0xFFB71C1C)`, `sectorField = Color(0xFF558B2F)` + 섹션 헤더 코멘트 | TASK-3 |
| `band_of_mercenaries/lib/core/data/region_migration_service.dart` | (1) `_sectorCountFlagKey` 상수 / (2) §1 본문을 nested if(`if (settings.get(_flagKey) != true) { ... }`)로 wrap 변환 — 기존 조기 return 제거 / (3) §2 sectorChanges 키 정리 가드 블록 추가 — sectorCount 초과 키(0-based) 제거 + 별도 멱등성 플래그 | TASK-10 + 후속 수정 |
| `band_of_mercenaries/lib/core/data/settings_keys.dart` | `regionSectorCountV1 = 'region_sector_count_v1'` 상수 추가 | TASK-5 |
| `band_of_mercenaries/lib/features/investigation/domain/region_state_model.dart` | 라인 17 주석 보강 — 0-based key vs 1-based region_sectors.sector_index 변환 룰 명문화 | TASK-12 |
| `band_of_mercenaries/lib/features/quest/domain/quest_provider.dart` | 라인 173·263·397 3곳에 인덱싱 변환(user.sector 1-based → 0-based) 정책 주석 추가 | TASK-13 |

### 2.3 빌드 게이트 외과적 수정 (테스트 4개)

| 파일 경로 | 변경 내용 |
|-----------|----------|
| `band_of_mercenaries/test/features/inventory/view/inventory_screen_test.dart` | StaticGameData 생성자에 `regionSectors: const [],` 한 줄 추가 |
| `band_of_mercenaries/test/features/quest/domain/quest_completion_service_test.dart` | 동일 |
| `band_of_mercenaries/test/features/quest/domain/quest_narrative_render_test.dart` | 동일 |
| `band_of_mercenaries/test/features/quest/domain/special_flag_processor_test.dart` | 동일 |

dart-build-resolver가 외과적으로 수정. 추가 import 없이 `const []`로 타입 추론.

### 2.4 자동 생성 파일 (build_runner)

| 파일 경로 | 비고 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/region.freezed.dart` | sectorCount 필드 추가 반영 |
| `band_of_mercenaries/lib/core/models/region.g.dart` | 동일 |
| `band_of_mercenaries/lib/core/models/region_sector.freezed.dart` | 신규 모델 생성 |
| `band_of_mercenaries/lib/core/models/region_sector.g.dart` | 동일 |

---

## 3. PHASE 별 검증 결과

### PHASE 1 — planner 통합 계획 수립

- 1회 수행. 사용자 확인 필요 항목 없음. 13개 TASK + 4단계 실행 순서 + REQ-1~14 매핑 완료.
- 사용자 승인 후 PHASE 2 진입.

### PHASE 2 — coder 구현 (13개 TASK)

- 1단계 8개 TASK 병렬 호출 → 모두 완료 보고.
- build_runner 1차 실행 — 12 outputs / 9.0s — 성공.
- 2단계 3개 TASK 병렬 호출 → 모두 완료 보고.
- 3단계 2개 TASK 병렬 호출(서로 다른 파일이라 안전) → 모두 완료 보고.
- TASK-10 결함 발견(coder가 직접 보고): 기존 §1 가드의 조기 `return`이 §2 블록 도달을 차단함. FR-13 "페이즈 4 #1 적용 사용자도 본 단계는 새로 실행되어야 함"과 충돌.
- TASK-10 후속 수정: 기존 `if (settings.get(_flagKey) == true) return;` 조기 return 제거 + §1 본문 전체를 `if (settings.get(_flagKey) != true) { ... }` nested if로 wrap. 시나리오 3종 추적 검증 완료(처음 실행 / 페이즈 4 #1 후 #2 첫 실행 / 모두 적용 후 재실행).

### PHASE 2.5 — 빌드 게이트

- 1차 `flutter analyze`: 4개 테스트 파일에서 missing_required_argument(`regionSectors`) 에러.
- dart-build-resolver 호출: 외과적 수정 4개 파일. 신규 import 0건. SUCCESS.
- 2차 `flutter analyze`: PASS — No issues found.

### PHASE 3 — 풀 검증 (verifier + flutter-reviewer 병렬)

- TASK 13개 ≥ 3 → 풀 검증 모드.
- **verifier 결과**: PASS — 모든 REQ-1~14 PASS, 시그니처 준수 PASS, 호환성 PASS, flutter analyze PASS, 테스트 499/499 PASS, 이슈 없음.
- **flutter-reviewer 1차 결과**: BLOCK — HIGH 1건 + MEDIUM 2건 + LOW 1건.
  - **HIGH-1**: build() 내 `_selectedSector = 1` State 직접 변이 (Flutter 라이프사이클 위반).
  - **MEDIUM-1**: SyncService.allTables의 region_sectors 주석 번호 불일치 (`// 27.` vs 배열 위치 3번째).
  - **MEDIUM-2**: lookupSector 이중 순차 검색 — 시드 배포 후 build당 6×164 = 984회 순회 가능성.
  - **LOW-1**: `_SectorTile` 터치 타겟 40×44px (Material 가이드라인 48×48px 미달).
- **통합 1차 판정**: FAIL (verifier PASS + flutter-reviewer BLOCK).
- **수정 1회 (HIGH-1)**:
  - build() 진입 라인의 직접 변이 제거.
  - `final effectiveSelectedSector = _selectedSector.clamp(1, targetRegion.sectorCount);` 로컬 변수 도입.
  - build() 내 `_selectedSector` 읽기 참조 3곳(calculateDistance / isSelected 비교 / startMovement)을 `effectiveSelectedSector`로 교체.
  - 지역 변경 ◀/▶ onTap 핸들러 두 곳 setState 내부에 newRegion.sectorCount 비교 + `_selectedSector = 1` clamp 추가.
- MEDIUM 2건 + LOW 1건은 후속 트래킹 권장으로 명시 — 본 PR 차단 사유 아님(flutter-reviewer 명시).
- **flutter-reviewer 2차 결과**: APPROVE — HIGH 이슈 해소됨, 새 이슈 없음, 라이프사이클 규칙 부합.
- **최종 판정**: PASS (verifier PASS + flutter-reviewer APPROVE).

---

## 4. 후속 트래킹 (본 PR 차단 사유 아님)

flutter-reviewer가 1차 리뷰에서 제기한 MEDIUM/LOW 이슈는 본 PR 병합과 무관하나 후속 페이즈에서 처리 권장:

1. **MEDIUM-1**: `SyncService.allTables`의 region_sectors 항목 주석 번호 정합성 — 모든 항목 번호 재정렬 또는 단순 마일스톤 코멘트로 통일 (페이즈 4 후속 또는 별도 챠우 작업).
2. **MEDIUM-2**: `lookupSector` 성능 — 시드 ~164행 배포 시점에 `Map<int, Map<int, RegionSector>> regionSectorIndex` 사전 계산하여 O(1) 조회 (페이즈 3 데이터 시드 작업 또는 페이즈 4 #4와 함께).
3. **LOW-1**: `_SectorTile` 터치 타겟 — 페이즈 4 #4 마을 방문 UI 작업과 함께 그리드 시각·접근성 개선 시 처리.

---

## 5. Supabase 적용 절차 (본 PR 미적용 — 보류)

본 PR은 SQL 파일을 작성·저장만 한다. 실제 Supabase 적용은 페이즈 4 #2~#5 통합 후 일괄 처리 정책에 따라 보류. 적용 시점에 다음 절차:

1. 페이즈 4 #1 SQL(`20260503_m4_phase4_1_region_migration.sql`) 선행 적용 확인.
2. 페이즈 4 #2 SQL(`20260503_m4_phase4_2_region_sectors.sql`) 적용. 단일 트랜잭션이므로 실패 시 자동 롤백.
3. 적용 후 검증 쿼리:
   - `SELECT COUNT(*) FROM regions WHERE sector_count IS NULL` → 0
   - `SELECT region, sector_count FROM regions WHERE sector_count = 5 ORDER BY region` → (1, 23, 127, 146)
   - `SELECT COUNT(*) FROM region_sectors` → 0 (시드 미배포 상태)
   - `SELECT version FROM data_versions WHERE table_name IN ('regions', 'region_discoveries', 'region_sectors')` → 각 +1 / +1 / 1
4. Flutter 앱 재실행 시 `RegionMigrationService.migrate(staticData)`의 §2 블록이 1회 실행되어 sectorChanges 키 정리.

---

## 6. FR / TASK 트레이스 매트릭스

| FR / REQ | TASK | 상태 |
|---------|------|------|
| FR-1 regions.sector_count | TASK-1 + TASK-6 (§2) | PASS |
| FR-2 region_sectors 테이블 | TASK-6 (§2) | PASS |
| FR-3 RegionSector 모델 + StaticGameData + SyncService | TASK-2 + TASK-7 + TASK-8 | PASS |
| FR-4 GameConstants.sectorCount 제거 + 동적 변환 | TASK-4 + TASK-11 | PASS |
| FR-5 MovementScreen 동적 그리드 + clamp | TASK-11 + 후속 수정 | PASS |
| FR-6 더스트플레인 4섹터 fallback | TASK-9 | PASS |
| FR-7 lookupSector 우선순위 | TASK-9 + TASK-11 | PASS |
| FR-8 AppTheme + _SectorTile 색상 분기 | TASK-3 + TASK-11 | PASS |
| FR-9 _SectorTile 아이콘 분기 | TASK-11 | PASS |
| FR-10 인덱싱 정책 주석 명문화 | TASK-2 + TASK-12 + TASK-13 | PASS |
| FR-11 chain_quests target_sector_id ASSERT | TASK-6 (§1) | PASS |
| FR-12 region_discoveries 재매핑 | TASK-6 (§4) | PASS |
| FR-13 RegionMigrationService 확장 | TASK-5 + TASK-10 + 후속 수정 | PASS |
| FR-14 operation-bom 영향 — 본 페이즈 제외 | (변경 0건) | PASS |

---

## 7. CLAUDE.md 금지사항 위반 여부

본 PR에서 CLAUDE.md 금지사항 위반 없음. 모든 코더가 보고에서 "위반 없음" 명시.

다만 다음은 본 PR이 의도적으로 도입한 패턴으로 위반은 아니나 명시적 기록 가치가 있음:

- **build() 내 로컬 clamp 변수 패턴**: `effectiveSelectedSector` 로컬 변수는 일반적 Riverpod/Flutter 패턴이며 `_selectedSector` State는 setState 사이클에서만 변경. 라이프사이클 규칙 부합.
- **fallback 상수 패턴**: 본 프로젝트 첫 도입. 시드 미배포 시점의 게임 첫 실행 보장 목적. 시드 배포 후 자동 비활성화.
- **RegionMigrationService nested if 패턴**: 기존 단일 가드(early return)에서 단계별 가드(`if (...) { ... }`) 패턴으로 변환. 페이즈 추가 시 §3·§4 가드 블록을 같은 패턴으로 추가하면 됨.

---

## 8. build_runner 재실행 필요 여부

- **PHASE 2.5에서 1회 실행 완료** (12 outputs / 9.0s).
- 후속 작업에서 본 PR 코드 base에 추가 변경 시 build_runner 재실행 필요한 freezed 모델: Region, RegionSector.

명령어:
```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```

---

## 9. 다음 단계 안내

본 PR은 implement-agent 파이프라인이 완료된 상태. 다음 단계:

1. **finalize-feature 호출** — git commit + Archive 처리.
   - 사용자 메모리 기준: 원본 spec/기획 문서는 archive 시 git rm 금지(복사만 수행).
2. **milestone-runner M4 --resume** — 페이즈 4 #1·#2 완료 마킹 + 페이즈 4 #3 액션 안내.
3. **Supabase 일괄 적용** — 페이즈 4 #2~#5 SQL이 모두 작성된 후 사용자 결정에 따라 일괄 적용 (현재 SQL 2개 누적: phase4_1, phase4_2).
