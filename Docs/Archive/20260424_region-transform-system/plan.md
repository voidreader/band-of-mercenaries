# 구현 계획서

Skill used : implement-agent

---

## 명세서

`Docs/spec/M3/[spec]20260424_region-transform-system.md`

---

## 요구사항 분해

| 코드 | 내용 | 구현 상태 |
|------|------|----------|
| FR-1 | RegionState.sectorChanges HiveField(3) Map<String,String> 추가 | PASS |
| FR-2 | InvestigationNotifier._completeInvestigation()에 transform 분기 추가 | PASS |
| FR-3 | RegionTransformDialog ConsumerWidget + app.dart 리스너 통합 | PASS |
| FR-4 | QuestGenerator: sectorType 분기 + sectorChanges 파라미터 | PASS |
| FR-5 | QuestPool 모델: sectorType + specialFlags 필드 추가 | PASS |
| FR-6 | ActiveQuest.specialFlags HiveField(24) 런타임 필드 + exclusive 분기 포함 복사 | PASS |
| FR-7 | SpecialFlagProcessor: 6종 플래그 처리 (personal_equipment + tier_range 필터 포함) | PASS |
| FR-8 | Mercenary.traitLearningBoostUntil HiveField(23) + MercenaryStatService 부스트 | PASS |
| FR-9 | MovementScreen: currentRegionSectorChangesProvider watch, 변형 섹터 시각 구분 | PASS |
| FR-10 | RegionStateRepository.applyTransform(): 리전당 1섹터 제약 + 중복 방어 | PASS |
| FR-11 | ActivityLogType.regionTransform HiveField(18) | PASS |
| FR-12 | 변형 시 기존 대기 퀘스트 보존, 다음 갱신부터 sectorChanges 적용 | PASS |

---

## 변경 파일 목록

### 신규 생성

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/features/investigation/domain/region_transformed_provider.dart` | 신규 | RegionTransformedEvent value class, regionTransformedProvider(StateProvider<RegionTransformedEvent?>), currentRegionSectorChangesProvider(Provider<Map<String,String>>) |
| `lib/features/investigation/view/region_transform_dialog.dart` | 신규 | RegionTransformDialog ConsumerWidget — 유형 배지(village/ruins/hidden), "확인"/"이동 화면으로" 버튼 |
| `lib/features/quest/domain/special_flag_result.dart` | 신규 | SpecialFlagResult value class (extraItemIds, extraReputation, boostedMercIds, reputationPenaltyApplied) |
| `lib/features/quest/domain/special_flag_processor.dart` | 신규 | SpecialFlagProcessor 순수 static 서비스 — 6종 플래그 처리, _tryGuildDrop 헬퍼 |
| `test/features/investigation/domain/region_transform_trigger_test.dart` | 신규 | 변형 트리거 10개 테스트 |
| `test/features/quest/domain/special_flag_processor_test.dart` | 신규 | SpecialFlagProcessor 13개 테스트 |
| `test/features/quest/domain/quest_generator_sector_branch_test.dart` | 신규 | QuestGenerator sectorType 분기 7개 테스트 |

### 수정

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `lib/features/investigation/domain/region_state_model.dart` | 수정 | HiveField(3) `Map<String, String> sectorChanges` 추가 (기본값 `{}`) |
| `lib/features/investigation/data/region_state_repository.dart` | 수정 | `applyTransform()` Future<bool> 추가, `updateKnowledge()` await 패턴 수정 |
| `lib/features/investigation/domain/investigation_notifier.dart` | 수정 | transform discovery_type 분기, RegionTransformedEvent 발행 + TemplateEngine 렌더 |
| `lib/features/mercenary/domain/mercenary_model.dart` | 수정 | HiveField(23) `DateTime? traitLearningBoostUntil` 추가 |
| `lib/features/mercenary/domain/mercenary_stat_service.dart` | 수정 | `traitLearningBoost bool` 파라미터 추가, 15개 트레잇 관련 통계 부스트 적용. solo/team_dispatch_count는 절대 카운터로 부스트 미적용 |
| `lib/features/mercenary/data/mercenary_repository.dart` | 수정 | `setTraitLearningBoost(String mercId, DateTime? until)` 추가 |
| `lib/core/models/quest_pool.dart` | 수정 | `sectorType String?` + `specialFlags Map<String,dynamic>` 필드 추가 |
| `lib/features/quest/domain/quest_model.dart` | 수정 | HiveField(24) `Map<String, dynamic>? specialFlags` 추가 |
| `lib/features/quest/domain/quest_generator.dart` | 수정 | `currentSectorIndex`, `sectorChanges` 파라미터 추가; sectorType 분기; specialFlags 복사 (exclusive 분기 포함) |
| `lib/features/quest/domain/quest_provider.dart` | 수정 | generateQuests 3개 호출 사이트 업데이트, SpecialFlagProcessor 통합, traitLearningBoost 전달 |
| `lib/features/movement/view/movement_screen.dart` | 수정 | `currentRegionSectorChangesProvider` watch, 변형 섹터 아이콘(🏘️/🏛️/✨) + 색상 테두리 시각화, AppTheme 상수 사용 |
| `lib/app.dart` | 수정 | `regionTransformedProvider` ref.listen + RegionTransformDialog showDialog |
| `lib/core/theme/app_theme.dart` | 수정 | `transformVillage` / `transformRuins` / `transformHidden` / `transformFallback` 색상 상수 추가 |
| `lib/core/domain/activity_log_model.dart` | 수정 | `ActivityLogType.regionTransform` HiveField(18) 추가 |

---

## 설계 결정

### sectorChanges 키 타입: String
- Hive `Map<String, String>` 어댑터 안정성을 위해 `int` 대신 `String` 키 사용
- API 레이어는 int 섹터 인덱스를 노출하고, 저장 시 `sectorIndex.toString()` 변환

### currentRegionSectorChangesProvider
- view 레이어가 data 레이어(regionStateRepositoryProvider)를 직접 접근하지 않도록 domain 레이어 Provider 추가
- `userDataProvider` + `regionTransformedProvider`를 watch하여 리전 이동 및 변형 이벤트 시 자동 갱신

### SpecialFlagResult.extraGold 미포함
- 명세 FR-7의 6종 플래그에 extraGold 가산 항목이 없으므로 제거 (dead field 방지)

### 부스트 배수 단순화 (FR-8)
- 명세 `(amount * 1.5).round()` → 구현 `traitLearningBoost ? 2 : 1`
- 현재 모든 호출처가 amount=1 고정이므로 결과 동일 (round(1.5)=2)
- 정수 stat 특성상 단순화 적용, 향후 amount>1 도입 시 재검토

---

## 검증 모드

**풀 검증** (TASK 수 ≥ 3): verifier + flutter-reviewer 병렬 실행

| 라운드 | verifier | flutter-reviewer | 결과 |
|--------|----------|-----------------|------|
| Round 1 | FAIL | BLOCK | 7건 수정 |
| Round 2 | FAIL | APPROVE | 5건 수정 |
| Round 3 | PASS | — | 빌드 PASS, 테스트 455/455 |

### 수정된 이슈

**Round 1** (HIGH 3 + MEDIUM 4):
- [HIGH-1] MovementScreen repo 직접 접근 → currentRegionSectorChangesProvider watch로 교체
- [HIGH-2] RegionTransformDialog + MovementScreen 색상 리터럴 → AppTheme 상수 교체
- [HIGH-3] solo/team_dispatch_count에 boost 적용 오류 → +1 고정으로 수정
- [MEDIUM-1] ref.watch(regionTransformedProvider) 리빌드 트리거 제거 (currentRegionSectorChangesProvider가 반응적으로 대체)
- [MEDIUM-2] updateKnowledge() await 패턴 수정
- [MEDIUM-3] RegionTransformDialog badgeColor 로컬 변수 캐시
- [MEDIUM-4] guild_drop_rare/ultra_rare → _tryGuildDrop 헬퍼로 중복 제거

**Round 2** (verifier warning 2 + minor 2 + flutter-reviewer MEDIUM/LOW):
- [ISSUE-1] equipment_drop_bonus: guild_equipment → personal_equipment + tier_range 필터 수정
- [ISSUE-2] SpecialFlagResult.extraGold 데드필드 제거
- [ISSUE-3] 부스트 배수 단순화 근거 주석 추가
- [ISSUE-4] exclusive 퀘스트 분기에 specialFlags 복사 누락 추가
- [flutter-reviewer MEDIUM] currentRegionSectorChangesProvider: ref.read → ref.watch
- [flutter-reviewer LOW] Colors.grey fallback → AppTheme.transformFallback 상수 추가

---

## build_runner 재실행 필요

- `lib/features/investigation/domain/region_state_model.dart` (hive_generator — HiveField 추가)
- `lib/features/mercenary/domain/mercenary_model.dart` (hive_generator — HiveField 추가)
- `lib/features/quest/domain/quest_model.dart` (hive_generator — HiveField 추가)
- `lib/core/models/quest_pool.dart` (json_serializable — 필드 추가)

명령어:
```bash
cd band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs
```
