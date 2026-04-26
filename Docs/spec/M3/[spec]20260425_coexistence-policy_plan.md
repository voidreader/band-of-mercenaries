# 공존 정책 — 파견 화면 정렬 + 도착 팝업 큐 구현 리포트

Skill used : implement-agent
작성일: 2026-04-26
명세서: `Docs/spec/M3/[spec]20260425_coexistence-policy.md`

## 1. 개요

M3 Phase 4-6 "공존 정책" 구현 완료. 5계층 컨텐츠(체인·세력 전용·엘리트·변형 섹터·일반)가 파견 화면에서 시각적으로 구분되어 공존하고, 한 번의 이동 도착 시 발생하는 다중 팝업이 우선순위 큐를 통해 순차 처리된다. 기존 5개 독립 팝업 채널(건설·조사·랭크업·체인 완주·지역 변형)을 단일 `dialogQueueProvider` 큐로 통합했다.

## 2. 사용자 확정 결정사항

- **Q-1**: `PersistedDialogEntry` typeId = **15** (실제 코드 13/14 점유로 변경)
- **Q-2**: `chainQuestProgressProvider` (StreamProvider) + 클라이언트 active 필터 사용
- **Q-4**: 체인 하이라이트는 **region 단위만** 적용 (`target_sector_id` 컬럼 부재 — 후속 스프린트로 이전)
- **Q-5**: `ChainTopSection`이 인라인 `ChainStepCard` 완전 대체
- **Q-7**: `chainCompletedProvider` / `regionTransformedProvider`도 큐로 마이그레이션 (high priority)
- **Q-8**: 정렬 키 = `QuestType.baseReward × difficulty` (pending 퀘스트는 `rewardGold` null이므로 추정값 사용)

## 3. 구현 결과 (FR별)

| FR | 요약 | 구현 |
|----|------|------|
| FR-1 | DialogQueueNotifier (priority desc + FIFO + id dedup) | `dialog_queue_provider.dart` |
| FR-2 | DialogPriority 4단계 (critical/high/medium/low) | `dialog_request.dart` |
| FR-3 | 큐 persistence (24h 만료, 미등록 type 필터, 복원 실패 처리) | `dialog_queue_persistence.dart` + `persisted_dialog_entry.dart` (typeId 15) |
| FR-4 | app.dart 단일 listen + `_isShowingDialog` + mounted 가드 | `app.dart` |
| FR-5 | 5개 도메인 채널 마이그레이션 (construction=medium, investigation=medium, rankUp=critical, chainCompleted=high, regionTransform=high) | `app.dart` |
| FR-6 | 이동 완료 팝업 큐 통합 (자동 이벤트 → 선택지 회상 FIFO) | `home_screen.dart` |
| FR-7 | 5계층 정렬 함수 (Tier 0 체인 → Tier 1 세력 → Tier 2 엘리트 → Tier 3 변형 섹터 → Tier 4 일반) | `quest_sort_service.dart` |
| FR-8 | ChainTopSection (활성/비활성/0장, 최대 3장, 이동 탭 이동 버튼) | `chain_top_section.dart` |
| FR-9 | LayerSidebar 8단계 우선순위 fold | `layer_sidebar.dart` |
| FR-10 | QuestCardBadges 4종 배지 (체인·엘리트·섹터·세력) | `quest_card_badges.dart` |
| FR-11 | _QuestCard 시각 통합 (LayerSidebar+QuestCardBadges) | `dispatch_screen.dart` |
| FR-12 | MovementScreen 체인 하이라이트 (region 단위, _SectorTile 추출) | `movement_screen.dart` |
| FR-13 | ActivityLog 4종 아이콘 (🗺️/⛓️/⛓️굵게/🛤️) | `home_screen.dart` |

## 4. 변경 파일 목록

### 신규 생성 (9개)

| 파일 | 역할 |
|------|------|
| `lib/core/models/persisted_dialog_entry.dart` | Hive 모델 (typeId 15) |
| `lib/core/models/persisted_dialog_entry.g.dart` | hive_generator 생성 어댑터 |
| `lib/core/models/dialog_request.dart` | DialogRequest, DialogPriority, QuestLayerInfo, ChainQuestInfo |
| `lib/core/data/dialog_queue_persistence.dart` | Hive `dialogQueue` 박스 wrapper (24h 만료 + 복원 실패 처리) |
| `lib/core/providers/dialog_queue_provider.dart` | DialogQueueNotifier + DialogTypeRegistry + dialogQueueProvider |
| `lib/features/quest/domain/quest_sort_service.dart` | 5계층 정렬 순수 정적 서비스 |
| `lib/features/quest/view/chain_top_section.dart` | ChainTopSection + ChainQuestCard 위젯 |
| `lib/shared/widgets/layer_sidebar.dart` | 사이드바 색상 8단계 fold |
| `lib/shared/widgets/quest_card_badges.dart` | 4종 배지 렌더 |
| `test/features/quest/domain/quest_sort_service_test.dart` | 정렬 서비스 단위 테스트 (8 케이스) |

### 수정 (6개)

| 파일 | 변경 |
|------|------|
| `lib/core/data/hive_initializer.dart` | `dialogQueueBoxName` 상수 + `PersistedDialogEntryAdapter` 등록 + 박스 open |
| `lib/core/theme/app_theme.dart` | `transformVillage/Ruins/Hidden` 명세 색상으로 갱신, `eliteAccent/UniqueAccent` 명세 색상으로 갱신, `chainGold` 신규 추가 |
| `lib/app.dart` | 5개 listen → 단일 큐 listen + `_isShowingDialog` 플래그 + `mounted` 가드 |
| `lib/features/home/view/home_screen.dart` | 이동 팝업 enqueue + `_logIcon()` 4종 매핑 + `_showQuestResult` mounted 가드 |
| `lib/features/quest/view/dispatch_screen.dart` | `QuestSortService.sort()` 적용 + `ChainTopSection` 삽입 + `_QuestCard` LayerSidebar/QuestCardBadges 통합 + view→data import 제거 (domain 경유) + error 메시지 친화화 |
| `lib/features/movement/view/movement_screen.dart` | `_SectorTile` StatelessWidget 추출 + 체인 하이라이트 region 단위 + error 메시지 친화화 |

## 5. 검증 결과

### 빌드/테스트
- `flutter analyze`: **No issues found**
- `flutter test`: **497/497 passed** (`quest_sort_service_test.dart` 8 케이스 포함)
- `dart run build_runner build --delete-conflicting-outputs`: 성공 (`persisted_dialog_entry.g.dart` 생성)

### 검증 모드: 풀 검증 (verifier + flutter-reviewer 병렬)

#### 1차 검증
- verifier: PASS (4 minor warnings)
- flutter-reviewer: BLOCK (HIGH 5건 + MEDIUM 4건 + LOW 1건)

#### 1차 재작업 처리
- HIGH-1: `_ActiveChainCard` StatelessWidget → ConsumerWidget 전환
- HIGH-2: `app.dart` `showDialog().then()` mounted 가드 추가
- HIGH-3: `home_screen._showQuestResult` mounted 가드 추가
- HIGH-4: AppTheme 색상 통일 (transform/elite 색상 명세 일치 + chainGold 신규)
- HIGH-5: `dispatch_screen` view → data 직접 import 제거 (domain 경유 export 사용)
- MEDIUM(_chainGold 중복): 파일 최상단 `_kChainGold` 단일 선언 → AppTheme.chainGold 일괄 교체로 추후 흡수
- MEDIUM(raw exception): "데이터를 불러오는 중 오류가 발생했습니다"로 교체
- minor(opacity 0.65→0.6, 라벨 "진행 중인 체인"): 명세 문구로 교체
- LOW(_QuestCard super.key): private + 호출부 미전달 → `unused_element_parameter` warning 회피로 보류

#### 2차 검증
- verifier: PASS (4 minor — typeId 15 변경, 정렬 키 estimatedReward, DialogTypeRegistry 키 'chainCompleted', InvestigationResultDialog dismiss 자기책임 — 모두 spec drift이나 코드 변경 불필요)
- flutter-reviewer: BLOCK (HIGH 2건 + MEDIUM 2건)

#### 2차 재작업 처리
- HIGH(색상 리터럴 잔존 7곳): 본 spec 작업 부분(dispatch/home/movement/chain_top_section) 모두 AppTheme 상수로 교체
- MEDIUM(IntrinsicHeight): `chain_top_section.dart` 카드 구조를 `Border(left: width:4)` 패턴으로 단순화
- MEDIUM(_buildSectorTile private 메서드): `_SectorTile` StatelessWidget 클래스로 추출

#### 미해결 후속 항목 (본 spec 범위 외)

- **HIGH-2 (`dispatch_screen._showTraitEvents`의 `mercenaryRepositoryProvider` 직접 호출)**: 본 spec 작업과 무관한 기존 코드. 트레잇 진화 적용 로직을 `MercenaryListNotifier.applyEvolution()` 등 domain Notifier 메서드로 이전 권장 — **별도 리팩터링 스프린트로 이전**
- **MEDIUM (`QuestSortService.sort()` 매 build 재호출)**: 데이터 규모(최대 5~10개 퀘스트)가 작아 즉시 차단 사유 아님. select Provider 분리 또는 `provider`-level 메모이제이션으로 최적화 가능 — **후속 성능 스프린트**
- **LOW (`_QuestCard` super.key)**: private + key 미사용으로 `unused_element_parameter` warning 발생 회피 — 보존
- **InvestigationResultDialog dismiss 자기책임 패턴**: 큐 통합 후 일관성 차원에서 후속 정리 권장 (verifier 1차 ISSUE-4 + 2차 ISSUE-4)
- **target_sector_id 스키마 추가**: 체인 하이라이트의 섹터 단위 정확도를 위해 `chain_quests` 테이블에 `target_sector_id` 컬럼 추가 후속 spec 필요

## 6. 명세서 갱신 권장 사항

코드 진실성을 반영하여 후속 spec 보완 권장:

1. **§2.2 HiveType 할당 표**: `PersistedDialogEntry` typeId를 13 → **15**로 갱신 (실제 13/14는 ChainQuest 점유)
2. **§2.1 FR-7 정렬 키**: "rewardGold 내림차순" → "pending 퀘스트의 rewardGold가 null이므로 `questType.baseReward × difficulty` 추정값 사용" 단서 추가
3. **§2.2 DialogTypeRegistry 예시**: `chainProgress` → `chainCompleted` (실제 의미상 더 정확)

## 7. CLAUDE.md 정책 준수 사항

- view → domain → data 레이어 분리 준수 (HIGH-5 처리)
- 한국어 주석 + 비자명한 부분만 작성
- 의존성 최소화 (각 파일 신규 import는 명세 요구 모듈만)
- 새 화면 전환 없음 (상태 기반 렌더링 유지)
- 색상 단일 출처 (AppTheme 중앙 관리)

## 8. build_runner 재실행 필요 파일

- `lib/core/models/persisted_dialog_entry.dart` → `persisted_dialog_entry.g.dart` 생성됨

다른 freezed/json_serializable 파일 변경 없음.

## 9. 후속 작업 안내

본 구현 완료 후 다음 작업이 필요하면 별도 스프린트로 분리 권장:

- 트레잇 진화 적용 로직의 domain 이전 (HIGH-2)
- QuestSortService 메모이제이션 (성능)
- `target_sector_id` 스키마 추가 후 체인 섹터 단위 하이라이트
- InvestigationResultDialog dismiss 일관성 정리
- AppTheme 색상 변경(transform/elite)이 다른 사용처에 미친 시각적 영향 회귀 점검 (운영 QA)
