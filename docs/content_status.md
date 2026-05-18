# 컨텐츠 개발 현황 (M3 기준 보관본)

> 마지막 업데이트: 2026-05-18
> 상태: 보관본. 본문은 2026년 4월 26일 M3 완료 기준 내용을 유지한다.

이 문서는 M3 완료 시점의 시스템 현황을 보관한다. M4~M7에서 추가된 거점 신뢰도, 제작, 위업·연대기, 칭호·간판 용병, 지명 의뢰, 지역 상태 변화, 생활권 이동 UI, 마을 인프라 시스템은 본문 전체에 아직 통합 반영되어 있지 않다.

현재 프로젝트 상태를 확인할 때는 다음 문서를 우선 참조한다.

- `AGENTS.md`
- `Docs/roadmap/master_roadmap.md`
- `Docs/milestone-runs/M7/state.md`
- `Docs/Review/project_audit_2026-05-18.md`

---

## 1. 핵심 게임 루프

```
용병 모집 → 위치 이동 (여행 이벤트 + 선택지 회상) → 퀘스트 생성 → 파견 (비용 차감) → 시간 대기 → 결과 (보상/XP/명성/서사) → 반복
```

**상태: 완성** - 전체 루프가 동작하며, 1초 게임 틱으로 퀘스트 완료/이동 도착/상태 회복을 자동 처리. M3에서 서사 텍스트·연계 퀘스트·지역 변형·이동 선택지가 추가되어 루프에 서사 계층이 부여되었다.

---

## 2. 시스템별 구현 현황

### 이동 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 리전 이동 | ✅ | 199개 리전, 리전당 10개 섹터 |
| 거리/시간 계산 | ✅ | 거리 × 30초 |
| 여행 이벤트 | ✅ | 12종, 거리 비례 확률 (최대 80%) |
| 리전 티어 잠금 | ✅ | 명성 랭크에 따른 상위 티어 접근 제한 |
| 이동 제한 | ✅ | 파견 중인 용병이 있으면 이동 불가 |

### 퀘스트 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 퀘스트 생성 | ✅ | 리전 기반 5~8개 자동 생성, 정보망 시설 보너스 |
| 퀘스트 유형 | ✅ | 4종 (약탈 100G / 토벌 120G / 호위 90G / 탐험 80G) |
| 난이도 5단계 | ✅ | 적전투력 10~80, 보상배수 1.0~4.5 |
| 파견 | ✅ | 다중 용병 선택, 성공률 실시간 표시 |
| 비용 구조 | ✅ | 파견비용(소요시간 비례) + 인건비 선차감, 순수익 표시 |
| 결과 판정 | ✅ | 대성공(2배) / 성공 / 실패(부상) / 대실패(사망률↑) |
| XP 분배 | ✅ | 난이도 × 기본XP(20) × 결과배수 + 훈련소 보너스 |
| 명성 획득 | ✅ | 퀘스트 완료 시 명성 획득 |
| 퀘스트 자동 갱신 | ✅ | 대기 중 퀘스트 1시간(게임 시간)마다 자동 교체 |
| 세력 태그 배정 | ✅ | `FactionTagResolver.resolve()` 런타임 배정. 가입 세력 단서 보유 리전 100%, 비가입 세력 거점 근접도(tier 1: 30% / 2: 20% / 3: 10% / 4: 5%). 적대 세력(평판 -100) 제외 |
| 세력 전용 퀘스트 | ✅ | `is_faction_exclusive=true` 전용 풀. 기본 트랙(평판 11, 보상 +0.30) / 고급 트랙(평판 61, 보상 +0.40). 완료 시 평판 5~7 / 8~10 지급. 6h 쿨다운. 노출 상한 `min(joinedCount×2, activeSlotCount×0.5)` |
| 세력 평판 획득 | ✅ | 태그 퀘스트 완료 시 평판 +1 or +2(근접도). 전용 퀘스트 완료 시 +5~10. `QuestCompletionService` → `FactionStateRepository.addReputation()` 자동 호출 |
| 섹터 변형 전용 퀘스트 | ✅ | `quest_pools.sector_type` 기반 분기. QuestGenerator가 변형 섹터 타입에 맞는 풀에서 생성. village/ruins/hidden 총 34개 풀 |
| 퀘스트 서사 | ✅ | `QuestNarrativeService.renderNarrative()`. quest_type × result_type × is_elite 3중 필터 + weight 가중 랜덤 선택 → TemplateEngine 렌더. `ActiveQuest.renderedNarrative` HiveField(25) 저장 |
| 파견 화면 5계층 정렬 | ✅ | `QuestSortService.sort()`: 체인 active > 세력 전용 > 엘리트(유니크 우선) > 변형 섹터 > 일반. `sortedPendingQuestsProvider` 메모이제이션 |

### 엘리트 몬스터 시스템 (M2b)

| 항목 | 상태 | 내용 |
|------|------|------|
| 엘리트 몬스터 데이터 | ✅ | 39종 (보통 31 + 유니크 8). `elite_monsters` 테이블. tier/environment_tags/combat_power/is_unique |
| 드랍 테이블 | ✅ | `elite_loot_tables` 209행. bonus_gold/item_id/drop_weight/min_difficulty |
| 스폰 로직 | ✅ | `EliteSpawnService.trySpawn()`. 리전 tier 범위 + environment_tags 교집합 + 최소 난이도 조건 확인 후 확률 배정 |
| 드랍 로직 | ✅ | `EliteLootService.roll()`. 완료 시 드랍 테이블에서 보너스 골드/아이템 weight 추출 → `EliteLootResult` 반환 |
| 결과 팝업 | ✅ | `QuestResultDialog`에 보통(🔥 엘리트 드랍) / 유니크(★ 유니크 드랍) 조건부 섹션 표시 |
| 파견 화면 UI | ✅ | 엘리트 퀘스트 카드 좌측 색상 강조(보통: `#e65100` / 유니크: `#7b1fa2`) + 배지(🔥/★) + 이름 색상. `DispatchDetailPage`에 엘리트 서사 카드 삽입 |

### 용병 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 모집 | ✅ | 무료(2시간 쿨타임) + 골드 모집 |
| 티어 확률 | ✅ | T1:45% / T2:30% / T3:15% / T4:8% / T5:2% |
| 직업 | ✅ | 85개 (5티어), 기본 STR/INT/VIT/AGI |
| 스탯 시스템 | ✅ | STR(기본 공격력) / INT(스킬 공격력) / VIT(체력+방어) / AGI(이동속도+회피). 퀘스트 유형별 partyPower 가중치: raid(STR 0.70) / hunt(STR 0.50, AGI 0.30) / escort(VIT 0.60) / explore(INT 0.45, AGI 0.30). AGI 기반 파견 시간 보정 |
| 선천 트레잇 | ✅ | 모집 시 Physical/Background/Talent 카테고리에서 랜덤 1~3개 부여 (각 60% 확률, 최소 1개) |
| 트레잇 시스템 | ✅ | 109개 트레잇 (8개 카테고리), 선천 최대 3개 + 후천 최대 4개 슬롯 |
| 상태 관리 | ✅ | 정상 → 피곤함(80%, 5분) → 부상(난이도×10분) → 사망 |
| 레벨/XP | ✅ | 최대 5레벨, 임계값 [0, 100, 350, 850, 1850] |
| 주둔지 용량 | ✅ | 기본 + 주둔지 레벨별 추가 슬롯 |
| 이름 | ✅ | 약 270개 한국어 이름 풀 |
| 방출 | ✅ | 파견 중이 아닌 용병을 퇴직금(인건비×레벨) 지급 후 영구 방출, 재모집 불가 |
| 행동 지표 | ✅ | 26개 지표 자동 추적 (total_dispatch_count, success_count, raid_count 등 + 시설 혜택 지표 3종) |
| 시설 혜택 지표 | ✅ | 훈련소/의무실/야전병원 사용 시 전용 지표 누적 → 시설 기반 트레잇 자동 획득 조건 (training_benefit_count, infirmary_recovery_count, field_hospital_benefit_count) |
| 용병 상세 화면 | ✅ | 어디서든 용병 카드 탭 → 전체화면 오버레이 (트레잇 슬롯, 행동 지표, 트레잇 히스토리) |
| 트레잇 삭제 | ✅ | 후천 트레잇 삭제 (선천 불가). acquired 200G / evolved 500G. 의무실 Lv2(acquired)/Lv4(evolved) 해금. 삭제 기록 → 재획득 방지 |
| 여행 이벤트 선천 트레잇 | ✅ | 이동 중 빈 선천 슬롯 보유 용병에게 선천 트레잇 부여. 신규 이벤트 3종(혹독한 지형/노련한 여행자/재능의 발현). 최대 3회 재롤링 |
| 트레잇 학습 부스트 | ✅ | `Mercenary.traitLearningBoostUntil` HiveField(23). 지역 변형 숨겨진 섹터 퀘스트 완료 시 활성화. 활성 중 행동 지표 2배 누적 |

### 시설 시스템

OGame 스타일 건설 시간 + 기하급수 골드 비용. 건설 큐 1개 제한 (취소 시 전액 환불). 최대 레벨 25.

**공식:**
- 건설 비용: `baseCost × costMultiplier^(level-1)` (단, Lv1=lv1Cost, Lv2=lv2Cost 고정)
- 건설 시간: `baseTime × timeMultiplier^(level-1)` (단, Lv1=lv1Time, Lv2=lv2Time 고정)
- 효과 스케일: `maxEffect × ln(1 + level × α) / ln(1 + 25 × α)` (로그 스케일)

| 시설 | 최대레벨 | 효과 | 상태 |
|------|----------|------|------|
| 훈련소 | 25 | XP 보너스 (최대 +100%) | ✅ |
| 의무실 | 25 | 회복시간 감소 (최대 -70%) + 트레잇 삭제 해금 (Lv2/Lv4) | ✅ |
| 주둔지 | 25 | 용병 상한 추가 (최대 +20명) | ✅ |
| 정보망 | 25 | 퀘스트 추가생성 (최대 +5개) | ✅ |
| 대장간 | 25 | 장비 강화 효과 (stub — 장비 시스템 미구현) | ✅ |
| 주점 | 25 | 고급 용병 모집 확률 상승 (최대 +15%) | ✅ |
| 연구소 | 25 | 특수 트레잇 해금 (stub — 미구현) | ✅ |
| 방어시설 | 25 | 여행 이벤트 피해 감소 (최대 -50%) | ✅ |
| 금고 | 25 | 방치 보상 상한 상승 (최대 +480G → 최대 960G) | ✅ |
| 게시판 | 25 | 특수 의뢰 알림 (stub — 미구현) | ✅ |
| 이동수단 | 25 | 이동 시간 단축 (최대 -40%) | ✅ |
| 야전병원 | 25 | 부상 확률 감소 (최대 -50%) | ✅ |

**건설 큐**: `UserData.constructionFacilityId` + `constructionStartTime` + `constructionEndTime` (HiveField 12~14). 완료 시 `gameTickProvider`에서 자동 감지 → 다이얼로그 큐(medium priority) 경유 팝업 + 활동 로그 기록.

### 파견 상성 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 상성 매트릭스 | ✅ | `RoleSynergyMatrix`: 6개 role × 4개 quest_type 정적 상수 (−2 ~ +8) |
| 파티 보정 적용 | ✅ | `QuestCalculator.calculateSuccessRate`에 `partyRoles` 파라미터 추가. 파티 평균 보정값 계산 후 ±10%p 독립 상한 클램프 |
| 트레잇 상한 분리 | ✅ | 트레잇 보정 `traitBonus.clamp(-10.0, 10.0)` 별도 독립 상한 (파티 상성과 풀 분리) |
| 성공률 분해 표시 | ✅ | `SuccessRateBreakdown` 값 객체: 기본값/파티력/유형/상성/트레잇/세력패시브/공유상한손실/거리패널티 8개 레이어 분해. `?` 버튼 → `SuccessRateBreakdownSheet` |
| UI 힌트 | ✅ | 퀘스트 카드 추천 role Chip×2(`RoleSynergyMatrix.topRolesForQuest`). 용병 카드 `singleBonus≥5.0`일 때 tint + `+X.X` 배지 |

### 명성/랭크 시스템

| 등급 | 이름 | 필요 명성 | 해금 티어 |
|------|------|-----------|-----------|
| F | 무명 | 0 | 1 |
| E | 신출내기 | 500 | 2 |
| D | 일반 | 2,000 | 3 |
| C | 숙련 | 8,000 | 4 |
| B | 정예 | 25,000 | 5 |
| A | 전설 | 80,000 | 5 |

**랭크 보너스 (M1 구현):** `ranks` 테이블 `bonus_json` 필드. `PassiveBonusService.collect()`가 F~현재 도달 랭크까지 누적 수집. 17개 `PassiveEffect` 타입 지원. `PassiveBonusFormatter.format()`이 한국어 표시 문자열 변환. 홈 등급 카드 탭 → `RankBonusSummarySheet`로 활성 보너스 전체 표시. `RankInfoScreen`에서 F~A 타임라인으로 등급별 보너스 프리뷰.

### 경제 시스템

| 항목 | 내용 |
|------|------|
| 초기 골드 | 500G |
| 파견비용 | 난이도 및 소요시간 비례 (MinCost~MaxCost 구간 보간) |
| 인건비 | 티어별 10/25/50/100/200G (퀘스트당) |
| 수익 공식 | 순수익 = 기본보상 × 난이도배수 - 인건비 - 파견비용 |
| 여행 이벤트 | 골드 획득(+20~120G) 또는 손실(-30~60G) |
| 방치형 보상 | 앱 미접속 시 분당 1G, 최대 480G(8시간) 자동 지급 |

### 활동 로그 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 로그 유형 | ✅ | 퀘스트 결과 + 서사, 용병 상태 변화, 이동 완료, 모집, 방출, 레벨업, 시설 건설, 지역 조사, 세력 단서/발견, 랭크업/다운, 연계 퀘스트 진행/완주, 지역 변형, 이동 선택지 완료 |
| 저장 | ✅ | Hive `activityLogs` 박스, 최대 100개 유지 |
| 표시 | ✅ | 타임스탬프 역순 정렬 |

### 지역 조사 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 조사 시작/취소 | ✅ | 용병 1명을 현재 리전에 배치, 파견·이동과 독립된 별도 슬롯 |
| 성공률 | ✅ | `(85 + (AGI+VIT)/200).clamp(5,95)%` |
| 소요 시간 | ✅ | 리전 티어별 (T1=5분 ~ T5=20분). 시간 가속 적용 |
| 지식 포인트 | ✅ | `RegionState.knowledge` (0~100). 성공 시 티어별 획득량 가산 |
| 발견 트리거 | ✅ | 지식 임계값 도달 시 `region_discoveries` 자동 트리거 (faction_clue / hidden_quest / transform) |
| 이동 제한 연동 | ✅ | 조사 중 이동 불가, 이동 중 조사 불가 (양방향 상호 배제) |
| 완료 처리 | ✅ | `InvestigationNotifier` → `investigationCompletedProvider(InvestigationResult?)` |
| Hive 저장 | ✅ | `regionStates` 박스: RegionState (knowledge, triggeredDiscoveries, sectorChanges) |

### 세력 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 세력 데이터 | ✅ | 14개 세력 (공개 6 / 비밀 4 / 지역 4). Supabase `factions` 테이블 |
| 세력 발견 | ✅ | 지역 조사 → `faction_clue` 발견 → clue_level 1/2/3 단계별 정보 노출 |
| 세력 도감 | ✅ | `FactionCodexScreen`: 공개 → 발견(clueLevel 내림차순) → 미발견 순 정렬. 가입 배지/별 표시 |
| 세력 상세 | ✅ | `FactionDetailScreen`: 평판 바, 가입 조건, 패시브 혜택, 가입/탈퇴 버튼, 충돌 경고 다이얼로그 |
| 가입 조건 판정 | ✅ | `FactionJoinService.canJoin()`: 평판>0 / clueLevel 조건 / 랭크 조건 / 실효 가입 수<3 |
| 평판 관리 | ✅ | 미가입 최대 10 / 가입 최대 100 / 최소 -100. `clampReputation()` |
| 충돌 세력 | ✅ | 가입 시 충돌 세력 자동 탈퇴 + 평판 -20. 실효 가입 수 계산에서 제외 |
| 패시브 혜택 | ✅ | `PassiveBonusService.collect()`로 가입 세력 패시브 + 도달 랭크 보너스 누적 수집. 17개 `PassiveEffect` 타입. `QuestCalculator` / `RecruitmentService` / 회복 로직 등 6개 도메인 서비스에 보정값 주입. `PassiveBonusContext` 헬퍼로 `Ref/WidgetRef`에서 일괄 수집 |
| Hive 저장 | ✅ | `factionStates` 박스: FactionState (clueRecords, reputation?, joined?, joinedAt?, facilityLevels?) |

### 연계 퀘스트(체인 퀘스트) 시스템 (M3)

| 항목 | 상태 | 내용 |
|------|------|------|
| 체인 데이터 | ✅ | `chain_quests` 테이블 24행. 7체인 × 2~5단계. chain_id/step/region_id/target_region_id/target_sector_id/name/description/combat_power/duration_seconds/reward_gold/reward_items/final_reward/next_step_delay_seconds/faction_tag_id |
| 발동 트리거 | ✅ | `region_discoveries.discovery_type = 'hidden_quest'` → `ChainQuestService.tryActivate()`. 완료 체인 재발동 방지 |
| ChainQuestProgress Hive | ✅ | `chainQuestProgress` 박스 (typeId:13). chainId/currentStep/status(active/completed/dormant)/startedAt/completedAt/protagonistMercId/currentStepAvailableAt/stepFailureCount/lastActivityAt |
| 파견 화면 고정 | ✅ | 활성 체인 단계 최상단 `ChainTopSection` 고정. 이동 필요 오버레이, 비활성 단계 opacity 0.6 |
| 체인 단계 주입 | ✅ | `QuestListNotifier.injectChainStep(ChainQuestData, userRegion)`. 대기열에 삽입 |
| 주인공 용병 | ✅ | 1단계 최초 성공 시 partyPower 기여 1위 용병이 protagonistMercId 고정. 사망 시 폴백 재지정 |
| 체인 사망률 감소 | ✅ | 체인 단계 퀘스트 파견 시 주인공 용병 사망 확률 × 0.5 |
| 완주 보상 | ✅ | `ChainQuestService.completeChain()`. 명성 보너스(`단계수 × 150 × tier_weight`) + completedChains 기록 + `chainCompletedProvider` publish → 큐 경유 `ChainCompletedDialog` 팝업 |
| 14일 휴면 | ✅ | 마지막 활동 후 14일 경과 시 dormant 전환. 탭으로 재활성화 |
| SyncService 동기화 | ✅ | `chain_quests` 테이블 포함. data_versions 기반 증분 업데이트 |
| target_sector_id | ✅ | 1-based(1..10) sector 인덱스. null이면 region 전체 하이라이트 fallback. MovementScreen `Map<int, Set<int?>>` 자료구조로 region+sector 매칭 |

### 지역 변형 시스템 (M3)

| 항목 | 상태 | 내용 |
|------|------|------|
| sectorChanges 필드 | ✅ | `RegionState.sectorChanges` HiveField(3): `Map<String, String>` (key=섹터인덱스 "0"~"9" / value="village"\|"ruins"\|"hidden"). 리전당 최대 1섹터 (MVP 제약) |
| transform 트리거 | ✅ | `region_discoveries.discovery_type = 'transform'` 발견 시 `RegionStateRepository.applyTransform()`. discovery_data에서 transform_type/sector_index/transformed_name/narrative_template 추출 |
| 변형 팝업 | ✅ | `regionTransformedProvider` publish → `app.dart` ref.listen → `RegionTransformDialog` (barrierDismissible: false). TemplateEngine 서사 렌더 |
| QuestGenerator 분기 | ✅ | `QuestGenerator.sectorType` 분기. 변형 섹터 타입(`sector_type`) 일치 퀘스트 34개 생성 |
| SpecialFlagProcessor | ✅ | `ActiveQuest.specialFlags` HiveField(24) → 완료 시 6종 처리: trait_learning_boost / guild_drop_rare / guild_drop_ultra_rare / essence_drop_bonus / equipment_drop_bonus / reputation_penalty |
| 이동 화면 시각 구분 | ✅ | 변형 섹터 아이콘(🏘️/🏛️/✨) + 색상 테두리. `currentRegionSectorChangesProvider` watch |
| 활동 로그 | ✅ | `ActivityLogType.regionTransform` HiveField(18) |

### 퀘스트 서사 시스템 (M3)

| 항목 | 상태 | 내용 |
|------|------|------|
| 서사 데이터 | ✅ | `quest_narratives` 테이블 88행. quest_type/result_type/is_elite/template/weight/description |
| 서비스 | ✅ | `QuestNarrativeService.pickTemplate()` weight 가중 랜덤 선택. `.pickProtagonist()` partyPower 기여 1위 용병 선정. `.renderNarrative()` TemplateEngine 치환 |
| ActiveQuest 저장 | ✅ | `ActiveQuest.renderedNarrative` HiveField(25). 완료 시점 1회 렌더, 이후 재렌더 금지 |
| `{quest.enemy}` 해결 | ✅ | QuestPool.enemyName → EliteMonster.name → "적" 순서 fallback. `TemplateContext.enemyName`으로 사전 해결 |
| 결과 팝업 표시 | ✅ | `QuestResultDialog` 이탤릭 서사 Container. 활동 로그 포맷: `'퀘스트 "이름" 결과! — 서사'` |
| SyncService 동기화 | ✅ | `quest_narratives` 테이블 포함. `quest_pools.enemy_name TEXT NULL` 컬럼 추가 |

### 이동 선택지(회상 팝업) 시스템 (M3)

| 항목 | 상태 | 내용 |
|------|------|------|
| 선택지 데이터 | ✅ | `travel_choice_events`(12행) / `travel_choice_options`(30행) / `travel_choice_results`(72행) 3 테이블 |
| 발동 로직 | ✅ | `TravelChoiceService.rollChoiceEvent()`. `P = min(base + coeff × distance, 0.30)`. tier별 coeff(1-2: 0.08 / 3-4: 0.10 / 5: 0.12). 전원 파견 시 미발동 |
| 도착 후 회상 | ✅ | `MovementNotifier._triggerChoiceRecall()` → `pendingTravelChoiceProvider` publish → `home_screen.dart` ref.listen → 다이얼로그 큐 medium priority 등록 |
| 회상 팝업 UI | ✅ | `TravelChoiceRecallDialog`. 1단계: 상황 서사 + 선택지(safe/risky/hidden). 2단계: 결과 서사 + 효과 요약 |
| 숨겨진 선택지 | ✅ | `visibility_expr` 조건식 평가. `TravelChoiceService.filterVisibleOptions()`. 특정 트레잇 보유 시만 표시 |
| 효과 적용 | ✅ | 효과 8종(gold_gain/gold_loss/xp_gain/reputation_gain/reputation_loss/trait_learning_boost/item_drop/trait_innate). `MovementNotifier.applyTravelChoiceEffect()` 위임 |
| 영속화 | ✅ | `UserData.choiceEventId` HiveField(21). 앱 재시작 시 recall 복원 |
| 활동 로그 | ✅ | `ActivityLogType.travelChoiceCompleted` HiveField(21) |
| SyncService 동기화 | ✅ | 3 테이블 포함. data_versions 엔트리 추가 |

### 템플릿 엔진 (M3)

| 항목 | 상태 | 내용 |
|------|------|------|
| TemplateEngine | ✅ | `core/domain/template_engine/`. 변수 치환 `{namespace.field}`, 조건 분기 `[if]...[/if]`, 랜덤 변주 `[pick A\|B\|C]` |
| TemplateContext | ✅ | freezed 모델. user/merc/region/factionStates 등 컨텍스트 필드. `TemplateContext.enemyName`으로 `{quest.enemy}` 사전 해결 |
| evaluationScope | ✅ | mercenary(단일) / team(팀 전체) 두 가지 평가 범위. `has_trait` 등 team-wide 조건 지원 |
| fail-safe | ✅ | 예외 발생 시 원문 그대로 반환 |
| Provider | ✅ | `templateEngineProvider`: const 스테이트리스 `Provider<TemplateEngine>` |
| 적용 지점 | ✅ | 퀘스트 서사 렌더 / 이동 선택지 가시성 평가 / 체인 완주 설명 / 지역 변형 서사 / 여행 이벤트 설명 |

### 다이얼로그 큐 (M3)

| 항목 | 상태 | 내용 |
|------|------|------|
| dialogQueueProvider | ✅ | `StateNotifierProvider<DialogQueueNotifier, List<DialogRequest>>`. `DialogPriority`(critical/high/medium/low) desc + FIFO + id dedup |
| 7종 dialogType | ✅ | `DialogTypeRegistry`: constructionComplete / investigationResult / rankUp / autoTravelEvent / travelChoiceRecall / chainCompleted / regionTransform |
| Hive 영속화 | ✅ | `dialogQueue` 박스. `PersistedDialogEntry` (typeId:15). 24h 만료, 등록된 dialogType만 복원 |
| app.dart 통합 | ✅ | 단일 `ref.listen`. `_isShowingDialog` 플래그 + mounted 가드 + `addPostFrameCallback`으로 head 표시 |
| dismiss 일관성 | ✅ | 모든 채널: `enqueue(...)` 직후 즉시 `xxxProvider.notifier.state = null`. builder/onDismiss는 `dismiss` 단순 참조 |

---

## 3. 정적 데이터 현황

Supabase에서 관리되며, `data_versions` 기반으로 Flutter 앱에 동기화 (24개 테이블).

| 테이블 | 건수 | 비고 |
|--------|------|------|
| regions | 199 | 1개 대륙, 5단계 티어. `environment_tags` JSONB 컬럼 (엘리트 스폰 환경 필터) |
| jobs | 85 | 5티어 직업군. `role` 컬럼(warrior/specialist/mage/support/ranger/rogue) |
| trait_categories | 8 | Physical / Background / Talent / CombatStyle / Survival / Behavior / Mental / Experience |
| traits | 109 | 선천 35개 + 후천 acquired 43개 + 후천 evolved 31개. acquisition_condition / effect_json JSONB 포함. 시설 기반 트레잇 3종 (training/infirmary/field_hospital) |
| trait_conflicts | 32 | 충돌 관계 16쌍 × 양방향 |
| trait_transitions | 16 | 단일 진화 경로 (condition_json으로 복합 조건) |
| trait_combo_evolutions | 15 | 조합 진화 레시피 |
| trait_synergies | 39 | 선천-후천 시너지 (획득 조건 완화 비율) |
| difficulties | 5 | 난이도 1~5 (min_dispatch_cost / max_dispatch_cost) |
| quest_types | 4 | 약탈(raid) / 탐험(explore) / 토벌(hunt) / 호위(escort) |
| quest_pools | 332 | 일반 200 + 세력 전용 98(M1) + 섹터 변형 34(M3). `sector_type` / `enemy_name` / `is_faction_exclusive` / `special_flags JSONB` 컬럼 포함 |
| person_names | 약 500 | 한국어 이름 풀 |
| travel_events | 12 | 여행 이벤트 |
| facilities | 12 | 시설 종류 |
| ranks | 6 | 명성 등급 |
| mercenary_wages | 5 | 티어별 인건비 |
| region_discoveries | 47 | 리전별 발견 데이터. discovery_type: faction_clue / hidden_quest / transform. M3에서 25행 추가(transform 18 + hidden_quest 7) |
| factions | 14 | 세력 마스터 데이터. 공개 6 / 비밀 4 / 지역 4. visibility_type / join_rank_min / join_needs_clue / passive_bonus_json / conflict_faction_ids 포함 |
| elite_monsters | 39 | 보통 31종 + 유니크 8종. tier/environment_tags/combat_power/is_unique/title/lore/min_region_tier/max_region_tier |
| elite_loot_tables | 209 | 엘리트 드랍 테이블. bonus_gold/item_id/drop_weight/min_difficulty |
| chain_quests | 24 | 7체인 × 2~5단계. chain_id/step/region_id/target_region_id/target_sector_id/combat_power/duration_seconds/reward_items/next_step_delay_seconds/faction_tag_id 포함 |
| quest_narratives | 88 | 서사 템플릿. raid/hunt/escort/explore × 4결과 × 4변형(64) + labor/survey × 4결과 × 2변형(16) + 엘리트 raid/hunt × 4결과 × 1(8) |
| travel_choice_events | 12 | 이동 선택지 이벤트. category(encounter/dilemma/discovery/hazard)/min_tier/max_tier/weight/preferred_traits |
| travel_choice_options | 30 | 선택지 옵션. choice_index/label/visibility_expr/description/risk_level(safe/risky/hidden) |
| travel_choice_results | 72 | 선택지 결과. probability/conditional_expr/narrative/effect_type/effect_magnitude/effect_target |

---

## 4. UI 화면 현황

| 탭 | 화면 | 상태 | 주요 기능 |
|----|------|------|-----------|
| 홈 | HomeScreen | ✅ | 골드, 위치, 진행중 퀘스트, 용병 수, 야영지 이미지, 활동 로그, 건설 미니 위젯, 설정 버튼 |
| 이동 | MovementScreen | ✅ | 리전/섹터 선택, 거리/시간 표시 (이동수단 효과 반영), 티어 잠금, 변형 섹터 아이콘/테두리, 체인 대상 섹터 금색 테두리 + "체인" 배지, 이동 제한 안내 |
| 파견 | DispatchScreen | ✅ | 퀘스트 목록 5계층 정렬, 체인 최상단 고정(ChainTopSection), 용병 선택, 비용 분석, 결과 다이얼로그 + 서사, 트레잇 획득/진화 팝업 체이닝, 엘리트 드랍 표시 |
| 모집 | RecruitScreen | ✅ | 무료/유료 모집, 용병 카드(레벨/XP/스탯/트레잇/상태), 방출 기능 |
| 시설 | FacilityTabScreen | ✅ | 건설 큐 상태 바(남은 시간/취소), 시설 카드 12종(레벨/비용/건설시간/효과), 이정표 타임라인(stub) |
| 정보 | InfoScreen → FactionCodexScreen → FactionDetailScreen | ✅ | 세력 도감 (정렬/별/가입 배지), 세력 상세 (평판 바/가입 조건/패시브/가입·탈퇴 버튼) |
| (오버레이) | MercenaryDetailOverlay | ✅ | 어디서든 용병 카드 탭 → 전체화면 상세. 선천/후천 트레잇 슬롯 그리드, 행동 지표(접기/펼치기), 트레잇 히스토리 |
| (오버레이) | InvestigationWidget | ✅ | 이동 화면 내 지역 조사 위젯. 조사 시작/취소, 진행률 표시, 완료 팝업(발견 목록 + 세력 단서 인라인) |
| (설정) | SettingsScreen | ✅ | 홈 탭 → 설정 아이콘. 시간 가속 (개발용), 건설 타이머 재계산 |
| (다이얼로그) | TraitDetailDialog | ✅ | 트레잇 설명, 효과, 진화 경로 진행도 바, 시너지, 충돌 관계 |
| (다이얼로그) | TraitAcquisitionDialog | ✅ | 퀘스트 완료 후 획득 트레잇 알림 |
| (다이얼로그) | TraitEvolutionDialog | ✅ | 카드 비교형 진화 선택 UI (단일/조합 진화 후보 선택, 보류 가능) |
| (다이얼로그) | TravelChoiceRecallDialog | ✅ | 이동 완료 후 회상 팝업. 상황 서사 + 선택지(safe/risky/hidden). 결과 서사 + 효과 요약 |
| (다이얼로그) | ChainCompletedDialog | ✅ | 체인 퀘스트 완주 축하 팝업. TemplateEngine 서사 렌더링. barrierDismissible: false |
| (다이얼로그) | RegionTransformDialog | ✅ | 지역 변형 발생 팝업. 변형 유형 + 서사 + 새 퀘스트 안내. barrierDismissible: false |

---

## 5. 영속성 (Hive 박스)

| 박스 | 내용 |
|------|------|
| `user` | 골드, 위치, 이동상태, 명성, 시설레벨(Map), 무료모집 쿨타임. HiveField(12~14) 건설 큐. HiveField(15~17) 지역 조사. HiveField(20) completedChains(List<String>). HiveField(21) choiceEventId(String?, 이동 선택지 recall 복원용) |
| `mercenaries` | 용병 목록. HiveField(4~7) 스탯. HiveField(14) stats 행동 지표 Map. HiveField(15) traitIds. HiveField(16) traitHistory. HiveField(17) deletedTraitIds. HiveField(23) traitLearningBoostUntil(DateTime?) |
| `quests` | 퀘스트 목록 (대기/진행/완료). HiveField(17) factionTag. HiveField(18) reputationReward. HiveField(19) isAdvancedTrack. HiveField(20) eliteId. HiveField(21) isChainStep. HiveField(22) chainId. HiveField(23) chainStep. HiveField(24) specialFlags. HiveField(25) renderedNarrative |
| `activityLogs` | 활동 로그 (최대 100개). `ActivityLogType` enum: @HiveField(13) reputationRankUp / @HiveField(14) reputationRankDown / @HiveField(15) regionTransform / @HiveField(16~17) (사용 중, M2a) / @HiveField(18) chainProgressed / @HiveField(19) chainCompleted / @HiveField(20) travelChoiceCompleted |
| `settings` | 일반 key-value (SettingsKeys 참조). `factionQuestCooldowns` 키: 전용 퀘스트 6시간 쿨다운 맵 |
| `regionStates` | RegionState (typeId:8). regionId/knowledge/triggeredDiscoveries/sectorChanges(Map<String,String>). regionId 키로 저장 |
| `factionStates` | FactionState (typeId:9). factionId/clueRecords/reputation?/joined?/joinedAt?/facilityLevels?. FactionClueRecord(typeId:10) |
| `chainQuestProgress` | ChainQuestProgress (typeId:13). chainId/currentStep/status(ChainQuestStatus typeId:14)/startedAt/completedAt?/protagonistMercId?/currentStepAvailableAt?/stepFailureCount/lastActivityAt? |
| `dialogQueue` | PersistedDialogEntry (typeId:15). id/priority/dialogType/payloadJson/enqueuedAt. 24h 만료. `DialogQueuePersistence`로 CRUD + 복원 실패 시 ActivityLog 기록 |

---

## 6. 미구현 / 향후 계획

| 항목 | 마일스톤 | 비고 |
|------|----------|------|
| 세력 전용 시설 14종 | M4 | M1 패시브 + M2a 아이템 필요 |
| 세력 거점 + 상점 + 전용 트레잇 | M4 | 아이템 상점 상품, 트레잇 데이터 모델 사전 확정 필요 |
| 용병 간 상호작용 | M5 | 독립적, 파견 전략 깊이 |
| 용병 티어 업그레이드 | M6 | 경제 재설계 필요 |
| 밸런스 튜닝 + 전체 데이터 채우기 | M6 | 트레잇 임계값·진화 조건·경제 수치·시설 비용 수치. quest_pools.difficulty 1~10 스케일 이슈 해결 포함 |
| operation-bom 트레잇 관리 UI | 중 | table-config.ts에 6개 트레잇 테이블 추가 |
| 시설 stub 기능 구현 | 중 | 대장간(장비 강화 M2a 후), 연구소(특수 트레잇), 게시판(특수 의뢰) |
| 건설 시간 단축 (용병 투입) | 중 | 시설 건설에 용병을 투입해 건설 시간 단축 |
| 시설 이정표 기능 구현 | 낮음 | Lv5/10/15/20/25 해금 기능 실제 연동 (현재 stub UI) |
| PVP / 레이드 | - | 장기 로드맵 |
| 동맹/길드 | - | 장기 로드맵 |
| 국제화 (i18n) | - | 현재 한국어 하드코딩 |

---

## 7. 아키텍처 요약

```
lib/
├── core/models/        정적 데이터 모델 (Freezed) — TraitData, RegionDiscovery, FactionData, EliteMonsterData, EliteLootTableData,
│                       ChainQuestData, QuestNarrativeData, TravelChoiceEventData/OptionData/ResultData, PassiveEffect(sealed, 17종) 포함
├── core/providers/     전역 Provider — game_state, static_data, timer, mercenary_detail, navigation, reputation_rank_up,
│                       dialog_queue_provider(dialogQueueProvider), template_engine_provider(templateEngineProvider)
├── core/domain/        PassiveBonusService, PassiveBonusFormatter, PassiveBonusContext, ReputationService, ActivityLog 시스템
│                       template_engine/ — TemplateEngine(renderer/resolver/lexer/expression/validator/escapes), TemplateContext
├── core/data/          Hive 초기화, JSON 로더, SyncService (24개 테이블)
├── features/
│   ├── home/           홈 화면, RankUpOverlay, RankBonusSummarySheet
│   ├── movement/       TravelEventService, MovementProvider, Repository
│   │                   domain/travel_choice_service.dart (TravelChoiceService — 5개 static 메서드)
│   │                   domain/travel_choice_recall_provider.dart (pendingTravelChoiceProvider)
│   ├── quest/          ExperienceService, QuestCalculator, QuestGenerator, FactionTagResolver,
│   │                   RoleSynergyMatrix, SuccessRateBreakdown, QuestSortService(sortedPendingQuestsProvider),
│   │                   QuestNarrativeService, EliteSpawnService, EliteLootService,
│   │                   QuestProvider, QuestCompletionService, Repository
│   ├── mercenary/
│   │   ├── domain/     FacilityService, RecruitmentService, MercenaryStatService,
│   │   │               TraitEffectService, TraitAcquisitionService, TraitEvolutionService,
│   │   │               TraitDeletionService, MercenaryProvider, Repository
│   │   └── view/       MercenaryCard, MercenaryDetailOverlay, TraitSlotGrid,
│   │                   BehaviorStatsSection, TraitHistorySection,
│   │                   TraitDetailDialog, TraitAcquisitionDialog, TraitEvolutionDialog
│   ├── facility/
│   │   ├── domain/     ConstructionService, construction_completion_provider
│   │   └── view/       FacilityTabScreen, FacilityCard, ConstructionQueueBar, MilestoneTimeline
│   ├── investigation/
│   │   ├── domain/     InvestigationNotifier, InvestigationService, investigation_completion_provider,
│   │   │               region_transformed_provider(regionTransformedProvider, currentRegionSectorChangesProvider)
│   │   └── data/       RegionStateRepository
│   ├── chain_quest/
│   │   ├── domain/     ChainQuestService, chain_quest_provider(chainQuestServiceProvider,
│   │   │               chainQuestProgressProvider, activeChainProvider, chainCompletedProvider)
│   │   ├── data/       ChainQuestRepository
│   │   └── view/       ChainTopSection, ChainStepCard, ChainCompletedDialog
│   ├── info/
│   │   ├── domain/     FactionJoinService, faction_codex_providers
│   │   ├── data/       FactionStateRepository
│   │   └── view/       InfoScreen, FactionCodexScreen, FactionDetailScreen, RankInfoScreen
│   └── settings/       SettingsScreen
└── shared/widgets/     BottomNavBar (6탭), TimerDisplay, StatusBadge, TierBadge, CardContainer, EmptyStateWidget
```

서비스 21개: **PassiveBonusService**, ReputationService, TravelEventService, **TravelChoiceService**, ExperienceService, QuestCalculator, **FactionTagResolver**, **QuestNarrativeService**, **EliteSpawnService**, **EliteLootService**, RecruitmentService, FacilityService, **ConstructionService**, MercenaryStatService, TraitEffectService, TraitAcquisitionService, TraitEvolutionService, TraitDeletionService, **InvestigationService**, **FactionJoinService**, **ChainQuestService**
