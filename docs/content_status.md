# 컨텐츠 개발 현황

> 마지막 업데이트: 2026-04-14 (시설 시스템 고도화 반영)

---

## 1. 핵심 게임 루프

```
용병 모집 → 위치 이동 (여행 이벤트) → 퀘스트 생성 → 파견 (비용 차감) → 시간 대기 → 결과 (보상/XP/명성) → 반복
```

**상태: 완성** - 전체 루프가 동작하며, 1초 게임 틱으로 퀘스트 완료/이동 도착/상태 회복을 자동 처리.

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

### 용병 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 모집 | ✅ | 무료(2시간 쿨타임) + 골드 모집 |
| 티어 확률 | ✅ | T1:45% / T2:30% / T3:15% / T4:8% / T5:2% |
| 직업 | ✅ | 85개 (5티어), 기본 ATK/DEF/HP/Speed |
| 선천 트레잇 | ✅ | 모집 시 Physical/Background/Talent 카테고리에서 랜덤 1~3개 부여 (각 60% 확률, 최소 1개) |
| 트레잇 시스템 | ✅ | 106개 트레잇 (8개 카테고리), 선천 최대 3개 + 후천 최대 4개 슬롯 |
| 상태 관리 | ✅ | 정상 → 피곤함(80%, 5분) → 부상(난이도×10분) → 사망 |
| 레벨/XP | ✅ | 최대 5레벨, 임계값 [0, 100, 350, 850, 1850] |
| 주둔지 용량 | ✅ | 기본 + 주둔지 레벨별 추가 슬롯 |
| 이름 | ✅ | 약 270개 한국어 이름 풀 |
| 방출 | ✅ | 파견 중이 아닌 용병을 퇴직금(인건비×레벨) 지급 후 영구 방출, 재모집 불가 |
| 행동 지표 | ✅ | 23개 지표 자동 추적 (total_dispatch_count, success_count, raid_count 등) |
| 용병 상세 화면 | ✅ | 어디서든 용병 카드 탭 → 전체화면 오버레이 (트레잇 슬롯, 행동 지표, 트레잇 히스토리) |
| 트레잇 삭제 | ✅ | 후천 트레잇 삭제 (선천 불가). acquired 200G / evolved 500G. 의무실 Lv2(acquired)/Lv4(evolved) 해금. 삭제 기록 → 재획득 방지 |
| 여행 이벤트 선천 트레잇 | ✅ | 이동 중 빈 선천 슬롯 보유 용병에게 선천 트레잇 부여. 신규 이벤트 3종(혹독한 지형/노련한 여행자/재능의 발현). 최대 3회 재롤링 |

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

**건설 큐**: `UserData.constructionFacilityId` + `constructionStartTime` + `constructionEndTime` (HiveField 12~14). 완료 시 `gameTickProvider`에서 자동 감지 → 전역 팝업 + 활동 로그 기록.

### 명성/랭크 시스템

| 등급 | 이름 | 필요 명성 | 해금 티어 |
|------|------|-----------|-----------|
| F | 무명 | 0 | 1 |
| E | 신출내기 | 500 | 2 |
| D | 일반 | 2,000 | 3 |
| C | 숙련 | 8,000 | 4 |
| B | 정예 | 25,000 | 5 |
| A | 전설 | 80,000 | 5 |

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
| 로그 유형 | ✅ | 퀘스트 결과, 용병 상태 변화, 이동 완료, 모집, 방출, 레벨업 |
| 저장 | ✅ | Hive `activityLogs` 박스, 최대 100개 유지 |
| 표시 | ✅ | 타임스탬프 역순 정렬 |

---

## 3. 정적 데이터 현황

Supabase에서 관리되며, `data_versions` 기반으로 Flutter 앱에 동기화 (16개 테이블).

| 테이블 | 건수 | 비고 |
|--------|------|------|
| regions | 199 | 1개 대륙, 5단계 티어 |
| jobs | 85 | 5티어 직업군 |
| trait_categories | 8 | Physical / Background / Talent / CombatStyle / Survival / Behavior / Mental / Experience |
| traits | 106 | 선천 35개 + 후천 acquired 40개 + 후천 evolved 31개. acquisition_condition / effect_json JSONB 컬럼 포함 |
| trait_conflicts | 32 | 충돌 관계 16쌍 × 양방향 |
| trait_transitions | 16 | 단일 진화 경로 (condition_json으로 복합 조건) |
| trait_combo_evolutions | 15 | 조합 진화 레시피 |
| trait_synergies | 39 | 선천-후천 시너지 (획득 조건 완화 비율) |
| difficulties | 5 | 난이도 1~5 (min_dispatch_cost / max_dispatch_cost) |
| quest_types | 4 | 약탈(raid) / 탐험 / 토벌 / 호위 |
| quest_pools | 200 | 퀘스트 템플릿 |
| person_names | 약 500 | 한국어 이름 풀 |
| travel_events | 12 | 여행 이벤트 |
| facilities | 4 | 시설 종류 |
| ranks | 6 | 명성 등급 |
| mercenary_wages | 5 | 티어별 인건비 |

---

## 4. UI 화면 현황

| 탭 | 화면 | 상태 | 주요 기능 |
|----|------|------|-----------|
| 홈 | HomeScreen | ✅ | 골드, 위치, 진행중 퀘스트, 용병 수, 야영지 이미지, 활동 로그, 건설 미니 위젯 |
| 이동 | MovementScreen | ✅ | 리전/섹터 선택, 거리/시간 표시 (이동수단 효과 반영), 티어 잠금 표시, 이동 제한 안내 |
| 파견 | DispatchScreen | ✅ | 퀘스트 목록, 용병 선택, 비용 분석, 결과 다이얼로그, 트레잇 획득/진화 팝업 체이닝 |
| 모집 | RecruitScreen | ✅ | 무료/유료 모집, 용병 카드(레벨/XP/스탯/트레잇/상태), 방출 기능 |
| 시설 | FacilityTabScreen | ✅ | 건설 큐 상태 바(남은 시간/취소), 시설 카드 12종(레벨/비용/건설시간/효과), 이정표 타임라인(stub) |
| 설정 | SettingsScreen | ✅ | 시간 가속 (개발용), 건설 타이머 재계산 |
| (오버레이) | MercenaryDetailOverlay | ✅ | 어디서든 용병 카드 탭 → 전체화면 상세. 선천/후천 트레잇 슬롯 그리드, 행동 지표(접기/펼치기), 트레잇 히스토리 |
| (다이얼로그) | TraitDetailDialog | ✅ | 트레잇 설명, 효과, 진화 경로 진행도 바, 시너지, 충돌 관계 |
| (다이얼로그) | TraitAcquisitionDialog | ✅ | 퀘스트 완료 후 획득 트레잇 알림 |
| (다이얼로그) | TraitEvolutionDialog | ✅ | 카드 비교형 진화 선택 UI (단일/조합 진화 후보 선택, 보류 가능) |

---

## 5. 영속성 (Hive 박스)

| 박스 | 내용 |
|------|------|
| `user` | 골드, 위치, 이동상태, 명성, 시설레벨(Map), 무료모집 쿨타임, HiveField(12) constructionFacilityId, HiveField(13) constructionStartTime, HiveField(14) constructionEndTime |
| `mercenaries` | 용병 목록 (스탯, 상태, XP, 레벨, stats 행동 지표 Map, traitIds 트레잇 목록, traitHistory 소멸 트레잇 기록) |
| `quests` | 퀘스트 목록 (대기/진행/완료), 보상 데이터 포함 |
| `activityLogs` | 활동 로그 (최대 100개). 로그 유형에 `facilityUpgrade` 추가 (HiveField(9)) |
| `settings` | 일반 key-value (lastActiveTime, dismissedMercIds 등) |

---

## 6. 미구현 / 향후 계획

| 항목 | 우선순위 | 비고 |
|------|----------|------|
| 밸런스 튜닝 | 높음 | 트레잇 획득 임계값, 진화 조건, 경제 수치 / 시설 비용·효과 수치 조정 필요 |
| operation-bom 트레잇 관리 UI | 중 | Phase 6: table-config.ts에 6개 트레잇 테이블 추가 |
| 시설 stub 기능 구현 | 중 | 대장간(장비 강화), 연구소(특수 트레잇), 게시판(특수 의뢰) — 의존 시스템 미구현 |
| 건설 시간 단축 (용병 투입) | 중 | 시설 건설에 용병을 투입해 건설 시간 단축하는 기능 |
| 시설 이정표 기능 구현 | 낮음 | Lv5/10/15/20/25 해금 기능 실제 연동 (현재 stub UI) |
| 장비 시스템 | - | 기획 문서에 언급 없음 |
| 스킬 시스템 | - | 기획 문서에 언급 없음 |
| PVP / 레이드 | - | 기획 문서에 향후 범위로 명시 |
| 동맹/길드 | - | 기획 문서에 향후 범위로 명시 |
| 국제화 (i18n) | - | 현재 한국어 하드코딩 |

---

## 7. 아키텍처 요약

```
lib/
├── core/models/        16개 정적 데이터 모델 (Freezed) — TraitData, TraitCategory, TraitConflict, TraitTransition, TraitComboEvolution, TraitSynergy 포함. Facility 모델 13개 신규 필드(formula 파라미터 및 milestones) 추가
├── core/providers/     5개 전역 Provider (game_state, static_data, timer, mercenary_detail, navigation)
│                       navigation_provider.dart 신규 — currentTabProvider (순환 의존성 방지 분리)
├── core/data/          Hive 초기화, JSON 로더, SyncService (16개 테이블)
├── features/
│   ├── home/           ReputationService, ActivityLog 시스템
│   ├── movement/       TravelEventService, MovementProvider, Repository
│   ├── quest/          ExperienceService, QuestCalculator, QuestGenerator, QuestProvider, QuestCompletionService, Repository
│   ├── mercenary/
│   │   ├── domain/     FacilityService (ConstructionService 위임 래퍼), RecruitmentService, MercenaryStatService,
│   │   │               TraitEffectService, TraitAcquisitionService, TraitEvolutionService,
│   │   │               TraitDeletionService, MercenaryProvider, Repository
│   │   └── view/       MercenaryCard, MercenaryDetailOverlay, TraitSlotGrid,
│   │                   BehaviorStatsSection, TraitHistorySection,
│   │                   TraitDetailDialog, TraitAcquisitionDialog, TraitEvolutionDialog
│   ├── facility/       (신규)
│   │   ├── domain/     ConstructionService (비용/시간/효과 공식), construction_completion_provider
│   │   └── view/       FacilityTabScreen, FacilityCard, ConstructionQueueBar, MilestoneTimeline
│   └── settings/       SettingsScreen (시설 관리 UI 제거, 개발 도구만 유지)
└── shared/widgets/     BottomNavBar (6탭), TimerDisplay, StatusBadge
```

서비스 12개: ReputationService, TravelEventService, ExperienceService, QuestCalculator, RecruitmentService, FacilityService, **ConstructionService**, MercenaryStatService, TraitEffectService, TraitAcquisitionService, TraitEvolutionService, TraitDeletionService
