# CHANGELOG

## 2026-04-26

### M3 공존 정책 — 파견 화면 정렬 + 도착 팝업 큐 통합

- 전역 다이얼로그 큐 도입 (`DialogQueueNotifier`): priority(critical/high/medium/low) + FIFO + id dedup. Hive `dialogQueue` 박스로 24h 영속화, 만료/실패 시 ActivityLog "알림 일부 유실됨" 기록
- 5개 독립 팝업 채널(건설·조사·랭크업·체인 완주·지역 변형) + 이동 도착 팝업 2종(자동 이벤트·선택지 회상) 모두 단일 큐로 통합. critical은 `barrierDismissible: false`
- 파견 화면 5계층 정렬 (`QuestSortService.sort`): Tier 0 체인 → Tier 1 세력 전용 → Tier 2 엘리트(유니크 우선) → Tier 3 변형 섹터 → Tier 4 일반. 같은 tier는 추정 보상↓ → 난이도↑ → id 사전순
- 체인 다음 단계 카드를 `ChainTopSection`(최대 3장, 활성/비활성 분기, 비활성은 "이동 화면으로" 버튼)으로 분리. 인라인 `ChainStepCard` 호출 제거
- `LayerSidebar`(8단계 우선순위 fold) + `QuestCardBadges`(체인/엘리트/섹터/세력 4종 배지) 공유 위젯 도입. 퀘스트 카드 시각 통합
- 이동 화면 체인 하이라이트: 체인 대상 리전 모든 섹터에 금색 2px 테두리 + "체인" 마이크로 배지
- ActivityLog 4종 신규 아이콘 매핑: 🗺️ regionTransform / ⛓️ chainProgressed / ⛓️(굵음) chainCompleted / 🛤️ travelChoiceCompleted
- AppTheme `chainGold`(`#D4AF37`) 신규, `transformVillage/Ruins/Hidden` + `eliteAccent/UniqueAccent` 명세 색상으로 갱신
- 신규 Hive 박스 `dialogQueue`(typeId 15) — 빌드 후 첫 실행 시 자동 생성

### M3 공존 정책 후속 정리 — 트레잇 진화 domain 이전 / 정렬 메모이제이션 / 다이얼로그 dismiss 일관성

- 트레잇 진화 적용 로직(Repository 호출/트레잇 이름 lookup/ActivityLog 기록/refresh)을 view에서 `MercenaryListNotifier.applyEvolution()`으로 이전. dispatch_screen은 위젯 위임 한 줄로 단순화
- `EvolutionChoice` 데이터 클래스를 view → domain 레이어로 이동 (`features/mercenary/domain/evolution_choice.dart`)
- 파견 화면 정렬을 `sortedPendingQuestsProvider`(derived Provider)로 메모이제이션. 1초 주기 `gameTickProvider`로 매 tick 정렬 재계산되던 비용 제거. 세력 가입/탈퇴(`factionRefreshProvider`) + 지역 변형(`currentRegionSectorChangesProvider`) 시 자동 무효화
- 다이얼로그 큐 5개 채널(건설·조사·랭크업·체인 완주·지역 변형) dismiss 책임 일원화: `enqueue` 직후 즉시 `state = null` 호출, builder/onDismiss 콜백은 `dismiss` 단순 참조만 수행
- `InvestigationResultDialog`의 누락된 state 리셋 보완 (재발화 위험 제거)
- 동작 변경 없음 (사용자 시각 동일성 보장 — 정렬 결과·진화 메시지·다이얼로그 표시 시퀀스 모두 동일)

### 퀘스트 서사 통합 (M3 페이즈 4-4)

- 퀘스트 완료 시 `quest_narratives` 88행에서 서사 템플릿을 weight 기반 가중 랜덤 선택 후 TemplateEngine으로 렌더링
- 렌더된 서사를 `ActiveQuest.renderedNarrative`에 저장, `QuestResultDialog` 완료 팝업에 이탤릭 텍스트로 표시
- 활동 로그 메시지에 서사 포함 (`'퀘스트 "이름" 결과! — 서사'` 포맷)
- `{quest.enemy}` 변수 지원 — 일반 퀘스트: `quest_pools.enemy_name` 필드, 엘리트: 몬스터 이름, null 시 `"적"` fallback
- 엘리트 퀘스트 전용 서사 8행 분리 적용 (`is_elite` 매트릭스)
- `AppTheme.elite*` 색상 상수 6개 추가 — `dispatch_screen`, `dispatch_detail_page`, `quest_result_dialog` 색상 리터럴 통일
- `QuestResultDialog` `_build*` 헬퍼 메서드 → `_EliteLootSection`, `_MercStatusRow`, `_RewardRow` StatelessWidget 추출

### 이동 선택지 시스템 (M3 페이즈 4-5)

- 이동 완료 시 확률 기반으로 선택지 이벤트 발생 — `P = min(base + coeff × distance, 0.30)`, 리전 티어별 coeff 조정
- `TravelChoiceRecallDialog` 2단계 팝업: 상황 서사 + 선택지 → 결과 서사 + 효과 요약
- 선택지 3종 risk_level (safe/risky/hidden) + `visibility_expr` TemplateEngine 평가로 숨겨진 선택지 조건부 노출
- 결과 8종 효과: gold_gain/gold_loss/xp_gain/reputation_gain/reputation_loss/trait_learning_boost/item_drop/trait_innate
- `UserData.choiceEventId` HiveField(21) — 앱 재시작 시에도 미표시 선택지 이벤트 보존
- `travel_choice_events` / `travel_choice_options` / `travel_choice_results` 정적 테이블 3개 Supabase 동기화 추가
- `TravelChoiceService` 순수 서비스 (5개 static 메서드) + 단위 테스트 19개

### M3 체인 퀘스트 섹터 단위 하이라이트 — chain_quests.target_sector_id 추가

- Supabase `chain_quests` 테이블에 `target_sector_id INTEGER NULL` 컬럼 추가 (1-based 1..10). `data_versions.chain_quests` version 1→2 갱신
- `ChainQuestData` freezed 모델에 `targetSectorId` 필드 추가, build_runner 재생성
- MovementScreen이 `chainTargetRegionIds`(Set) → `chainTargetSectors`(`Map<int, Set<int?>>`)로 자료구조 확장. `null in set` 시 region 전체 fallback, `sector in set` 시 해당 섹터 타일만 금색 테두리/배지 표시
- 기존 24개 chain_quest 단계는 모두 `targetSectorId == null` 상태이므로 region 단위 하이라이트로 동작 동일 (시각적 변경 없음)
- CSV(`Docs/content-data/[chain-quest]20260424_m3-chains.csv`) 헤더에 `target_sector_id` 컬럼 추가, 24행은 빈 값 유지 (콘텐츠 입력은 후속 sprint)

---

## 2026-04-25

### 연계 퀘스트 시스템 (M3)

- 지역 조사 완료 시 숨겨진 퀘스트 발견으로 체인 퀘스트 활성화 (7체인 24단계)
- 파견 화면 최상단에 현재 연계 단계 카드 고정 표시 (이동/대기/휴면 상태 오버레이)
- 주인공 용병 선정 및 체인 내 추적 — 주인공 사망률 50% 감소
- 단계 완료 시 다음 단계 지연 후 활성화, 14일 비활동 시 휴면 전환
- 체인 완주 시 명성 보너스 지급 + 완주 팝업 (서사 텍스트 템플릿 치환)
- 템플릿 엔진 구현: 변수 치환/조건 분기/랜덤 변주를 이동 이벤트·퀘스트 서사에 적용

### 지역 변형 시스템 (M3)

- 지역 조사 완료 시 섹터가 village/ruins/hidden 3종 중 하나로 영구 변형 — 변형 팝업(TemplateEngine 렌더)
- 변형 섹터에서 전용 퀘스트 34개 생성 (`quest_pools.sector_type` 필터 기반)
- 특수 플래그 6종: 트레잇 학습 부스트 / 길드 장비 드랍(희귀·초희귀) / 정수 드랍 / 장비 드랍 / 평판 패널티
- 이동 화면에서 변형 섹터 시각 구분 (아이콘 🏘️/🏛️/✨ + 색상 테두리)

---

## 2026-04-23

### 코드 품질 전수 점검 (flutter-reviewer)

HIGH 6 / MEDIUM 6 / LOW 2 이슈 수정. 테스트 372개 전부 통과.

- **Riverpod 반응성 버그 수정**
  - `DispatchScreen`의 `ref.listen<List<ActiveQuest>>`가 3개 early return 이후에 배치되어 `userData == null` 또는 이동 중에 퀘스트 완료 이벤트가 유실되던 문제 수정 — `build()` 최상단으로 이동
  - `RecruitScreen`/`FacilityTabScreen`이 세력 가입/탈퇴 후 모집·건설 비용 배수를 갱신하지 못하던 문제 수정 — `ref.watch(factionRefreshProvider)` 구독 추가
  - `HomeScreen`의 여행 이벤트 다이얼로그 표시 로직을 `build()` 내부 `_wasMoving && !isMovingNow` 패턴 → `ref.listen<MovementState?>`로 전환
- **레이어 경계 정리**
  - `view/` → `data/` 직접 import 6곳 제거. `factionStateRepositoryProvider`/`regionStateRepositoryProvider`를 domain 레이어(`faction_codex_providers.dart`/`investigation_notifier.dart`)에서 `export ... show`로 재노출
  - `PassiveBonusFormatter` 중복 파일(`core/domain` + `features/info/domain`) 통합 — `core/domain` 버전에 `describe`/`describeEffect` 메서드 추가하여 API 일원화, `features/info/domain/passive_bonus_formatter.dart` 삭제
- **위젯 재빌드 최적화**
  - `DispatchScreen._buildQuestCard` → `class _QuestCard extends ConsumerWidget` (리스트 순회 element 재사용)
  - `HomeScreen._buildActivityLog` → `class _ActivityLog extends ConsumerWidget` (로그 추가 시 전체 홈 화면 재빌드 → 해당 서브트리만)
  - `MercenaryDetailOverlay._buildStatChip`/`_buildXpBar`/`_buildSynergySection` → `const` 위젯 클래스 (element 재사용)
- **UI/UX 개선**
  - `DispatchDetailPage` 뒤로가기: `GestureDetector`+`Padding`+`Icon` → `IconButton` (터치 타겟 48×48 확보)
  - `QuestResultDialog` 정적 데이터 로드 실패 시 `barrierDismissible: false` 상태에서 닫을 수 없던 문제 수정 — error 브랜치에 닫기 버튼 추가
- **정리 및 방어 코드**
  - `main.dart`에 `FlutterError.onError` + `PlatformDispatcher.instance.onError` 전역 에러 핸들러 설치 (Crashlytics/Sentry 연동 플레이스홀더)
  - `MercenaryDetailOverlay` 티어 색상 리터럴 4개 → `AppTheme.tierN` 상수
  - `_parseFactionColor` 중복(`dispatch_screen`/`dispatch_detail_page`) → `FactionData.parseColor` static 메서드로 통합
  - `essence_service.dart` `debugPrint` 5건 제거
  - `dispatch_screen.dart`의 `ref.read(speedMultiplierProvider)` → `ref.watch` 의미론 교정

### M2b: 엘리트 몬스터 시스템

- 리전 `environment_tags` JSONB 컬럼 추가 — 지형/환경 태그로 퀘스트 풀 필터링 지원
- `EliteMonsterData` / `EliteLootTableData` 정적 데이터 모델 추가 (Supabase 동기화 대상 2개 테이블 신규)
- `EliteSpawnService`: 퀘스트 생성 시 리전 티어·환경 태그·난이도 조건으로 엘리트 몬스터 확률 배정
- `EliteLootService`: 드랍 테이블 가중 확률 롤 → 보너스 골드 + 아이템 드랍 계산
- `QuestGenerator` / `QuestCompletionService` 연동 — 엘리트 스폰·완료 처리 통합
- 파견 카드 엘리트 UI: 좌측 색상 사이드바·배지·이름 강조 (보통 🔥 오렌지 / 유니크 ★ 퍼플 2계층)
- 파견 상세 페이지: 엘리트 서사 카드(이름·설명/로어, 그라디언트 배경) 조건부 삽입
- 퀘스트 완료 팝업: 엘리트 드랍 섹션(보너스 골드·아이템 목록) 조건부 표시

---

## 2026-04-18

### 세력 태그 + 전용 퀘스트 시스템

- 가입 세력 단서를 보유한 리전에서 일반 퀘스트에 세력 태그가 자동 부여되어 완료 시 세력 평판을 획득한다 (가입 세력 100%, 비가입 거점 근접도 기반 5~30%).
- `quest_pools`에 세력 전용 퀘스트 98행(14세력 × 기본 3 + 고급 4) 추가. 가입 세력 + 평판(기본 11 / 고급 61) 조건 충족 시 파견 목록에 노출되며 완료 시 평판 5~10을 지급한다.
- 전용 퀘스트는 세력당 `min(가입수×2, 슬롯수×0.5)` 상한으로 노출되고 완료 후 6시간 쿨다운이 적용된다.
- 보상 공식이 패시브/랭크 보너스 + 트랙 보너스(기본 +0.30 / 고급 +0.40)의 가산 상한 +0.80으로 일원화되어 중복 가산이 제거되었다.
- 파견 화면 퀘스트 카드에 세력명 배지와 전용 퀘스트 강조 표시(좌측 세로 막대 + 테두리)가 추가되었고, 파견 상세 페이지는 세력명과 트랙 구분을 상단에 노출한다.

### 파견 상성 시스템 + 성공률 분해 UI

- 6개 role(전사/순찰자/마법사/도적/지원/전문가) × 4개 퀘스트 유형(약탈/토벌/호위/탐험) 상성 매트릭스가 도입되어, 파티 평균 보정값(-10 ~ +10%p 독립 상한)이 성공률에 가산된다. 85개 직업이 role로 전수 분류됐고, 트레잇 시너지도 독립 상한 ±10%p로 묶여 엔드게임에서도 전술 선택의 가치가 유지된다.
- 파견 화면에 추천 role 배지 2개(퀘스트 카드), +5 이상 상성 용병 하이라이트(카드 배경 tint + 보정값 배지), 성공률 옆 `?` 아이콘 → 분해 시트(기본값/파티력/유형/상성/트레잇/세력 패시브/거리 패널티 레이어별 표시)가 추가되었다.
- 용병 상세 오버레이 하단에 "퀘스트 유형별 상성" 섹션이 추가되어 각 용병의 role 보정값과 트레잇 시너지를 한눈에 확인할 수 있다.

### 명성 랭크 보너스 + 랭크업 연출 + 명성 정보 화면

- 명성이 증가하여 등급(F→E→D→C→B→A)이 상승하면 전체화면 축하 오버레이가 표시되고, 신규 등급의 보너스 목록이 한국어로 함께 안내된다. 활동 로그에도 `명성 상승: E → D` 기록이 추가된다 (🎖 아이콘).
- 홈 화면의 등급 카드를 탭하면 **보너스 요약 시트**가 열려 현재 활성화된 누적 보너스(세력 패시브 + 랭크 보너스 모두)와 다음 등급까지의 진행도를 확인할 수 있다. 최고 등급(A) 도달 시 "최고 등급 도달" 메시지로 전환된다.
- 정보 탭에 **"명성"** 진입점이 추가되어 F~A 전체 타임라인(도달/미도달 배지)과 등급별 보너스 프리뷰를 볼 수 있다. 타임라인에서 등급을 탭하면 해당 등급의 보너스 상세가 하단에 표시된다.
- 내부적으로 `ReputationService.getRankChain`/`getRankLevel`, `PassiveBonusContext` 공통 수집 헬퍼, `PassiveBonusFormatter`(17개 효과 타입 → 한국어 변환)가 추가되었다. 명성 하향 로직은 M2a 대비 stub으로 준비되었다.

---

## 2026-04-15

### 세력 발견 시스템 (World Expansion Phase 6)

- 지역 조사 완료 시 세력 단서(`faction_clue`) 발견 흐름 추가 — clue_level 1~3 단계별 정보 공개
- 하단 탭 6번째를 설정에서 정보 탭으로 교체, 설정은 홈 화면 상단 아이콘 버튼으로 이전
- 세력 도감 화면 신설 — 발견된 세력 목록(별 진행도), 세력 상세(description/philosophy/tierRange 단계별 공개)
- 조사 완료 팝업에 단서 인라인 표시 및 "도감에서 확인" 버튼 추가 (자동 스크롤 연동)
- `factionStates` Hive 박스 신설 (FactionState typeId:9, FactionClueRecord typeId:10)
- Supabase `factions` 테이블 동기화 대상 추가 (18번째 테이블)

### 세계 확장 Phase 1 — 지역 조사 시스템

- 용병 1명을 현재 리전에 파견과 독립된 "지역 조사" 슬롯에 배치하여 지식 포인트(0~100) 누적
- 지식 임계값 도달 시 `region_discoveries` 테이블 기반 발견 자동 트리거 (정보/엘리트/숨겨진 퀘스트)
- 조사 진행 중 이동 불가, 이동 중 조사 불가 (양방향 상호 배제)
- 조사 중인 용병은 퀘스트 파견 목록에서 자동 제외
- 시간 가속 설정 변경 시 조사 타이머도 비례 재계산
- Supabase `region_discoveries` 테이블 추가 (RLS anon read 정책 포함)

### 시설 ↔ 트레잇 연계 (Phase B)

- 시설 혜택 행동 지표 3종 추가 (training_benefit_count, infirmary_recovery_count, field_hospital_benefit_count)
- 퀘스트 완료 시 훈련소/의무실/야전병원 사용 여부에 따라 용병별 지표 자동 누적
- 시설 조건 기반 검증용 트레잇 3개 추가 (단련된 전사, 생존 본능, 철벽 수호)

---

## 2026-04-14

### 시설 시스템 고도화

- 시설 12종으로 확장 (기존 4종 + 신규 8종: 대장간/주점/연구소/방어시설/금고/게시판/이동수단/야전병원)
- 최대 레벨 25, OGame 스타일 건설 시간 + 기하급수 골드 비용 도입
- 건설 큐 1개 제한 (한 번에 하나만 건설, 취소 시 전액 환불)
- 하단 네비게이션 6탭 확장 (시설 전용 탭 추가)
- 시설 화면 전면 재설계 (건설 큐 상태 바, 시설 카드, 이정표 타임라인)
- 홈 화면 건설 미니 위젯 추가
- 로그 스케일 효과 공식 + 기능 해금 이정표 stub UI
- 시설 효과 적용: 주점(모집 확률), 방어시설(피해 감소), 금고(방치 보상 상한), 이동수단(이동 시간 단축), 야전병원(부상 확률 감소)

### 스탯 체계 재설계 — STR/INT/VIT/AGI 4스탯 전환

- 용병 스탯을 ATK/DEF/HP/speed에서 STR/INTELLIGENCE/VIT/AGI로 전환
- partyPower 계산을 퀘스트 유형별 가중치 공식으로 변경 (raid/hunt/escort/explore 각 가중치 차별화)
- AGI가 파견 소요 시간에 반영됨 (파티 평균 AGI 기반 속도 보정, 기준값 50)
- 기존 DEF·HP 유령 스탯 문제 해결 — VIT/INT로 퀘스트 전략 다양화
- Supabase jobs 테이블 컬럼 변환 및 85개 직업 INT 수치 직업 아키타입 기반 재설계
- operation-bom 웹앱 jobs 테이블 UI/타입 정의 갱신

---

## 2026-04-13

### Phase 6: operation-bom 트레잇 웹앱 확장

- operation-bom에 트레잇 시스템 6개 테이블 CRUD 관리 기능 추가 (trait_categories, traits, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies)
- FieldType에 "json" 타입 추가 — JSONB 컬럼의 입력(Textarea + JSON 검증), 목록 축약 표시 지원
- 복합 PK 테이블(trait_conflicts) 지원 — 추가/삭제만 허용, 편집 링크 숨김
- 사이드바에 "트레잇" 카테고리 신설 (6개 테이블 + 시각화 페이지)
- 트레잇 관계 시각화 페이지 (/traits/visualization) — 충돌/단일 진화/조합 진화/시너지 4개 섹션, 카테고리 필터

### Phase A: 트레잇 라이프사이클 완성

- 후천 트레잇 삭제 시스템 추가 (acquired 200G / evolved 500G, 의무실 레벨 해금)
- 용병 상세 오버레이에서 TraitDetailDialog 연결 (트레잇 탭 → 상세 다이얼로그)
- 트레잇 히스토리에 삭제 구분 표시 (`(삭제)` 라벨)
- 여행 이벤트로 빈 선천 슬롯에 트레잇 부여 (3종 신규 이벤트: 혹독한 지형/노련한 여행자/재능의 발현)
- TravelEvent 모델에 targetCategory 필드 추가
- trait_innate 이벤트 재롤링 로직 (최대 3회)

---

## 2026-04-12

### Refactors (코드 리뷰 Phase 1~3)

**Phase 1 — 안정성 확보**
- 퀘스트/이동 틱 레이스 컨디션 수정 (중복 처리 방지 가드 추가)
- `_completeQuest()` 185줄 God 메서드를 `QuestCompletionService`로 분리 (순수 계산 + 부수효과 분리)
- `ExperienceService.resultMultiplier` String → `QuestResult` enum 타입으로 변경
- `QuestCalculator.calculateSuccessRate` enemyPower <= 0 방어 코드 추가
- `mocktail` dev dependency 추가, `QuestCompletionService` 테스트 9개 신규

**Phase 2 — 아키텍처 정리**
- `UserData` 모델을 `features/movement/domain/` → `core/models/`로 이동
- `ActivityLog`, `ExperienceService`, `ReputationService`를 `core/domain/`으로 승격 (feature 간 그물망 의존성 해소)
- `QuestResultType` 삭제, `QuestResult`로 enum 통일 (이중 정의 + 수동 매핑 제거)
- `SettingsKeys` 상수 클래스 도입 (매직 스트링 중앙화)
- `addGold(0)` 해킹을 `UserDataNotifier.refresh()`로 교체
- `MovementNotifier` state를 `UserData?` → `MovementState?`로 분리 (SSOT 복원)
- 미사용 `XxxList` 래퍼 클래스 11개 삭제 (-2,000줄)

**Phase 3 — 품질 강화**
- `GameConstants` 상수 클래스 신규 (매직 넘버 10개 중앙화)
- timer 재계산 로직을 `recalculateEndTime()` 유틸리티로 통일 (3개 Notifier)
- `QuestCalculator.calculateSuccessRatePreview()` 추가 (랜덤 편차 없는 결정적 미리보기)
- View 레이어 비즈니스 로직 도메인으로 이동 (RecruitmentService 쿨다운, IdleRewardService, UserDataNotifier.recordFreeRecruit)
- `SyncService._fullDownload()` 부분 실패 시 캐시 롤백 처리
- `avoid_print` 린트 룰 추가
- 테스트 23개 신규 (총 138개)

### Bug Fixes
- Android 릴리스 빌드 시 네트워크 연결 실패 수정 (`AndroidManifest.xml`에 INTERNET 퍼미션 추가)

### Docs
- 코드베이스 종합 리뷰 리포트 및 Phase 1~3 구현 결과 문서 추가
- CLAUDE.md 아키텍처 섹션 업데이트 (core/domain, core/constants, SettingsKeys 반영)

### 트레잇 시스템 고도화 (Phase 1-2)

- Supabase에 트레잇 시스템 6개 테이블 생성 (trait_categories, traits, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies)
- 106개 트레잇 + 관계 데이터 (충돌 16쌍, 단일진화 16개, 조합진화 15개, 시너지 39개) 입력
- Flutter 모델 교체 (TraitData 구조 변경 + 5개 신규 모델 추가)
- SyncService 16개 테이블 동기화 대응
- 트레잇 카테고리 기반 색상 시스템 적용

### 트레잇 시스템 핵심 엔진 (Phase 3)

- 행동 지표 추적 시스템: 23개 지표(파견/생존/퀘스트유형/경제/연속기록) 퀘스트 완료 시 자동 갱신
- 용병 모집 변경: 선천 트레잇 1~3개 랜덤 부여 (Physical/Background/Talent 카테고리별 선택)
- 트레잇 획득 엔진: 행동 지표 → acquisition_condition 비교 → 시너지 감소 → 충돌 검증 → 자동 획득
- 데이터 드리븐 트레잇 효과: effect_json 기반 성공률/사망률/부상률 보정 (밸런스 수치는 향후 입력)
- quest type ID 변경: loot → raid (약탈)
- UI: 용병 카드에 복수 트레잇 뱃지 표시

### 트레잇 진화 시스템 (Phase 4)

- 단일 진화 엔진: acquired 트레잇 + 행동 지표 조건 충족 → 같은 카테고리 evolved 트레잇으로 교체
- 조합 진화 엔진: 서로 다른 카테고리의 acquired 2개 보유 시 → 원본 소멸 + evolved 트레잇 획득 + 슬롯 해방
- 트레잇 히스토리: 소멸된 트레잇 기록 (HiveField 16) → 재획득 방지 활성화
- 퀘스트 완료 시 자동 진화 체크 (단일 우선, 조합 후순위, 1회/턴 제한)

---

## 2026-04-11

### Features
- Supabase 기반 버전별 델타 동기화 시스템 구축 (1217d8b → 50437ee)
  - `SupabaseInitializer`: dotenv(.env) 기반 Supabase 연결 초기화 (2318607)
  - `DataLoader`: 캐시 파일 I/O 및 Supabase 응답 파싱 (9b5a9fb)
  - `SyncService`: `data_versions` 테이블 비교 → 변경 테이블만 다운로드하는 델타 동기화 (15c3270)
  - 앱 생명주기(시작 + 포그라운드 복귀)에 SyncService 통합 (ed6a6ab)

### Refactors
- 번들 JSON 파일 및 `JsonLoader` 제거 → Supabase 동기화로 대체 (e735d94)
- 전체 정적 데이터 모델 `@JsonKey` 어노테이션을 snake_case로 변환 (Supabase 컬럼명 일치) (5a896e5, 321c3b5)
- 캐시 저장소를 `path_provider` → Hive `staticDataCache` 박스로 교체 (웹 호환성) (3744a76)

### Docs
- Supabase 데이터 동기화 설계 스펙 및 구현 계획 추가 (6d285db, 3e3a92c)
- CLAUDE.md Supabase 데이터 동기화 아키텍처 반영 업데이트 (86dd3d6)

---

## 2026-04-10

- `update` (e3d7a6e)

---

## 2026-04-09

### Features
- 방치형 오프라인 보상 추가 (분당 1G, 최대 480G) (e3ddfed)
- 용병 방출 기능 추가 (퇴직금: 인건비 × 레벨) (0529a2e)
- 파견 중 이동 불가 제한 추가 (33983cf)
- 홈 화면에 용병 대시보드, 활동 로그, 퀘스트 완료 알림 추가 (37a04c8)
- Hive 기반 활동 로그 시스템 추가 (f52bc2e → f52bc2e)
- 파티 선택 UI를 드래그 가능한 바텀 시트로 교체 (f52bc2e)
- 활성 퀘스트가 최대치 미만일 때 퀘스트 채우기 버튼 추가 (6643e93)
- 대기 중 퀘스트 1시간마다 자동 갱신 + 카운트다운 타이머 (fc4ed52 → e2e2ced)
- 첫 실행 시 퀘스트 자동 생성 및 `createdAt` 필드 추가 (75995d8 → fc4ed52)
- 난이도별 min~max 범위 내 파견 비용 시간 비례 계산 (23c5201 → 75995d8)

### Bug Fixes
- `_showResult` 반환 타입을 `Future<void>`로 수정 (23c5201)
- 퀘스트 결과 다이얼로그 깜빡임 및 버튼 무반응 수정 (4ae9770)
- 시간 가속 시 모든 활성 타이머 endTime 재계산 수정 (d4cf610)

### Docs
- 20260409 요구사항 구현 계획 및 설계 문서 추가 (44f8902, 6f8c915)
- 구현 현황 업데이트 (3086895)
- Android 빌드 설정 가이드 추가 (aa27f2d)

---

## 2026-04-08

### Features
- 파견 비용/수익 분석 UI 추가 및 스탯 표시 수정 (9691d4a)
- 용병 모집 시 주둔지 용량 제한 적용 (ddafea8 → 731ed72)
- 레벨/XP 표시, 랭크 배지, 이동 이벤트 다이얼로그, 리전 잠금 UI 추가 (ddafea8)
- 시설 관리 화면 및 업그레이드 UI 추가 (0127bdf)
- 명성 랭크 기반 리전 티어 잠금 추가 (3fcb8fe)
- 퀘스트 완료 흐름에 XP, 명성, 시설 효과 통합 (3a780a8)
- 퀘스트 시스템에 파견 비용 및 인건비 차감 통합 (92c68ba)
- 이동 시스템에 이동 이벤트 통합 (af86de2)
- `ReputationService`: 랭크 결정 및 리전 접근 가능 여부 계산 (3f25caf)
- `FacilityService`: 업그레이드 검증 및 효과 계산 (3ec0554)
- `ExperienceService`: XP 계산 및 레벨업 로직 (61a19d8)
- `QuestCalculator`에 인건비 및 파견 비용 계산 추가 (3ec83aa)
- `TravelEventService`: 이벤트 확률, 필터링, 지연 처리 (f83ad6f)
- `UserData` 모델에 명성 및 시설 필드 추가 (de09320 → d0bc294)
- `Mercenary` 모델에 XP/레벨 필드 및 레벨 기반 스탯 보너스 추가 (d1fe218 → de09320)
- 새 정적 데이터 모델 `JsonLoader` 및 `StaticDataProvider`에 연결 (d1fe218)
- JSON 데이터 파일 추가 및 `Difficulty`에 파견 비용 필드 추가 (93d15bd)
- 이동 이벤트, 시설, 랭크, 인건비 정적 데이터 모델 추가 (97fd136 → 174be2f)

### Docs
- 게임 깊이 및 목표 시스템 구현 계획 추가 (97fd136)
- 브레인스토밍 미래 아이디어 문서화 (f9a2e3e)
- 게임 깊이/목표 설계 스펙 및 미래 아이디어 문서 추가 (d0df72f)

### Chore
- Android 플랫폼 추가 및 테스트 오류 수정 (ab4f9ff)

---

## 2026-04-07

### Features
- `main.dart` 추가: Hive 초기화 및 앱 부트스트랩 (2edd4ae)
- 모집 화면, 용병 카드, 설정 화면 추가 (e0f1a89)
- 파견 화면 및 퀘스트 결과 다이얼로그 추가 (6014878)
- 이동 화면: 리전/섹터 선택 UI (6dd0bbb)
- 하단 네비게이션, 홈 화면(야영지 페인터), 앱 셸 추가 (c809a5e)
- 용병/퀘스트/이동 Provider 및 게임 로직 통합 (642992b)
- 용병/퀘스트/이동 Repository 추가 (3de9691)
- 정적 데이터, 타이머, 게임 상태 핵심 Provider 추가 (4a1e3aa)
- 앱 테마, `StatusBadge`, `TimerDisplay` 위젯 추가 (5228482)
- `RecruitmentService` 및 `QuestGenerator` 추가 (전체 테스트 포함) (086d478)
- `QuestCalculator` 추가: 성공률, 결과, 피해, 소요시간 로직 (5e01cbe)
- Hive 어댑터 및 `HiveInitializer`가 포함된 런타임 데이터 모델 추가 (32b096a)
- 모든 정적 데이터 파싱 메서드 포함 `JsonLoader` 추가 (b2e283c)
- freezed + json_serializable 정적 데이터 모델 추가 (f6c4f42)
- Flutter 프로젝트 초기화: 의존성 및 디렉토리 구조 (8f0f8dd)

### Docs
- 프로토타입 구현 계획 추가 (3c222f2)
- 프로토타입 설계 스펙 추가 (de75b52)

### Chore
- Claude Code 설정 파일 추가 (9ee3f86)
- `.gitignore` 추가 (2ad86de)
- 나머지 미추적 파일 추가 (Docs, Json, iOS 빌드 아티팩트) (4ae0349)
