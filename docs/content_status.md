# 컨텐츠 개발 현황

> 마지막 업데이트: 2026-04-18 (M1 세력의 영향력 완료 반영)

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
| 세력 태그 배정 | ✅ | `FactionTagResolver.resolve()` 런타임 배정. 가입 세력 단서 보유 리전 100%, 비가입 세력 거점 근접도(tier 1: 30% / 2: 20% / 3: 10% / 4: 5%). 적대 세력(평판 -100) 제외 |
| 세력 전용 퀘스트 | ✅ | `is_faction_exclusive=true` 전용 풀. 기본 트랙(평판 11, 보상 +0.30) / 고급 트랙(평판 61, 보상 +0.40). 완료 시 평판 5~7 / 8~10 지급. 6h 쿨다운. 노출 상한 `min(joinedCount×2, activeSlotCount×0.5)` |
| 세력 평판 획득 | ✅ | 태그 퀘스트 완료 시 평판 +1 or +2(근접도). 전용 퀘스트 완료 시 +5~10. `QuestCompletionService` → `FactionStateRepository.addReputation()` 자동 호출 |

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
| 로그 유형 | ✅ | 퀘스트 결과, 용병 상태 변화, 이동 완료, 모집, 방출, 레벨업, 세력 단서/발견 |
| 저장 | ✅ | Hive `activityLogs` 박스, 최대 100개 유지 |
| 표시 | ✅ | 타임스탬프 역순 정렬 |

### 지역 조사 시스템

| 항목 | 상태 | 내용 |
|------|------|------|
| 조사 시작/취소 | ✅ | 용병 1명을 현재 리전에 배치, 파견·이동과 독립된 별도 슬롯 |
| 성공률 | ✅ | `(85 + (AGI+VIT)/200).clamp(5,95)%` |
| 소요 시간 | ✅ | 리전 티어별 (T1=5분 ~ T5=20분). 시간 가속 적용 |
| 지식 포인트 | ✅ | `RegionState.knowledge` (0~100). 성공 시 티어별 획득량 가산 |
| 발견 트리거 | ✅ | 지식 임계값 도달 시 `region_discoveries` 자동 트리거 (faction_clue, 일반 발견) |
| 이동 제한 연동 | ✅ | 조사 중 이동 불가, 이동 중 조사 불가 (양방향 상호 배제) |
| 완료 처리 | ✅ | `InvestigationNotifier` → `investigationCompletedProvider(InvestigationResult?)` |
| Hive 저장 | ✅ | `regionStates` 박스: RegionState (knowledge, triggeredDiscoveries) |

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

---

## 3. 정적 데이터 현황

Supabase에서 관리되며, `data_versions` 기반으로 Flutter 앱에 동기화 (18개 테이블).

| 테이블 | 건수 | 비고 |
|--------|------|------|
| regions | 199 | 1개 대륙, 5단계 티어 |
| jobs | 85 | 5티어 직업군 |
| trait_categories | 8 | Physical / Background / Talent / CombatStyle / Survival / Behavior / Mental / Experience |
| traits | 109 | 선천 35개 + 후천 acquired 43개 + 후천 evolved 31개. acquisition_condition / effect_json JSONB 컬럼 포함. 시설 기반 트레잇 3종 추가 (training/infirmary/field_hospital) |
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
| region_discoveries | 가변 | 리전별 발견 데이터 (id TEXT PK, region_id, knowledge_threshold, discovery_type, discovery_data JSONB, description) |
| factions | 14 | 세력 마스터 데이터. 공개 6 / 비밀 4 / 지역 4. visibility_type / join_rank_min / join_needs_clue / passive_bonus_json / conflict_faction_ids 포함 |

---

## 4. UI 화면 현황

| 탭 | 화면 | 상태 | 주요 기능 |
|----|------|------|-----------|
| 홈 | HomeScreen | ✅ | 골드, 위치, 진행중 퀘스트, 용병 수, 야영지 이미지, 활동 로그, 건설 미니 위젯, 설정 버튼 |
| 이동 | MovementScreen | ✅ | 리전/섹터 선택, 거리/시간 표시 (이동수단 효과 반영), 티어 잠금 표시, 이동 제한 안내 |
| 파견 | DispatchScreen | ✅ | 퀘스트 목록, 용병 선택, 비용 분석, 결과 다이얼로그, 트레잇 획득/진화 팝업 체이닝 |
| 모집 | RecruitScreen | ✅ | 무료/유료 모집, 용병 카드(레벨/XP/스탯/트레잇/상태), 방출 기능 |
| 시설 | FacilityTabScreen | ✅ | 건설 큐 상태 바(남은 시간/취소), 시설 카드 12종(레벨/비용/건설시간/효과), 이정표 타임라인(stub) |
| 정보 | InfoScreen → FactionCodexScreen → FactionDetailScreen | ✅ | 세력 도감 (정렬/별/가입 배지), 세력 상세 (평판 바/가입 조건/패시브/가입·탈퇴 버튼) |
| (오버레이) | MercenaryDetailOverlay | ✅ | 어디서든 용병 카드 탭 → 전체화면 상세. 선천/후천 트레잇 슬롯 그리드, 행동 지표(접기/펼치기), 트레잇 히스토리 |
| (오버레이) | InvestigationWidget | ✅ | 이동 화면 내 지역 조사 위젯. 조사 시작/취소, 진행률 표시, 완료 팝업(발견 목록 + 세력 단서 인라인) |
| (설정) | SettingsScreen | ✅ | 홈 탭 → 설정 아이콘. 시간 가속 (개발용), 건설 타이머 재계산 |
| (다이얼로그) | TraitDetailDialog | ✅ | 트레잇 설명, 효과, 진화 경로 진행도 바, 시너지, 충돌 관계 |
| (다이얼로그) | TraitAcquisitionDialog | ✅ | 퀘스트 완료 후 획득 트레잇 알림 |
| (다이얼로그) | TraitEvolutionDialog | ✅ | 카드 비교형 진화 선택 UI (단일/조합 진화 후보 선택, 보류 가능) |

---

## 5. 영속성 (Hive 박스)

| 박스 | 내용 |
|------|------|
| `user` | 골드, 위치, 이동상태, 명성, 시설레벨(Map), 무료모집 쿨타임, HiveField(12~14) 건설 큐, HiveField(15~17) 지역 조사 (investigatingMercId, investigationEndTime, investigationRegionId) |
| `mercenaries` | 용병 목록 (스탯, 상태, XP, 레벨, stats 행동 지표 Map, traitIds 트레잇 목록, traitHistory 소멸 트레잇 기록) |
| `quests` | 퀘스트 목록 (대기/진행/완료), 보상 데이터 포함 |
| `activityLogs` | 활동 로그 (최대 100개). 로그 유형에 `facilityUpgrade`, `investigationSuccess`, `investigationFailed`, `discoveryFound` 포함 |
| `settings` | 일반 key-value (lastActiveTime, dismissedMercIds 등) |
| `regionStates` | RegionState 모델 (typeId:8) — regionId(int), knowledge(int 0~100), triggeredDiscoveries(List<String>). regionId 키로 저장 |
| `factionStates` | FactionState 모델 (typeId:9) — factionId(String), clueRecords(List<FactionClueRecord>), reputation(int?), joined(bool?), joinedAt(DateTime?), facilityLevels(Map<String,int>?). FactionClueRecord(typeId:10) — factionId, regionId, discoveryId, foundAt |

---

## 6. 미구현 / 향후 계획

| 항목 | 마일스톤 | 비고 |
|------|----------|------|
| 아이템/장비 인프라 (정수·장비) | M2a | 아이템 모델, 인벤토리 Hive 박스, 장비 장착/해제, 정수 영구 스탯 강화 |
| 엘리트 몬스터 + 드랍 테이블 | M2b | M2a 아이템 인프라 선행 필요 |
| 숨겨진 연계 퀘스트 | M3 | 아이템 보상 필요 (M2a 후) |
| 특수 임무 시스템 | M3 | 연계 퀘스트와 통합 |
| 지역 변형 | M3 | 지역 조사 최종 보상 |
| 퀘스트 서사 텍스트 | M3 | 선택지·템플릿 엔진 공유 |
| 이동 이벤트 선택지 | M3 | 서사 텍스트와 동일 파이프라인 |
| 세력 전용 시설 14종 | M4 | M1 패시브 + M2a 아이템 필요 |
| 세력 거점 + 상점 + 전용 트레잇 | M4 | 아이템 상점 상품, 트레잇 데이터 모델 사전 확정 필요 |
| 용병 간 상호작용 | M5 | 독립적, 파견 전략 깊이 |
| 용병 티어 업그레이드 | M6 | 경제 재설계 필요 |
| 밸런스 튜닝 + 전체 데이터 채우기 | M6 | 트레잇 임계값·진화 조건·경제 수치·시설 비용 수치 |
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
├── core/models/        19개 정적 데이터 모델 (Freezed) — TraitData, TraitCategory, TraitConflict, TraitTransition, TraitComboEvolution, TraitSynergy, RegionDiscovery, FactionData, PassiveEffect(sealed, 17종) 포함
├── core/providers/     6개 전역 Provider (game_state, static_data, timer, mercenary_detail, navigation, reputation_rank_up)
│                       navigation_provider.dart — currentTabProvider
│                       reputation_rank_up_provider.dart — reputationRankUpProvider StateProvider<RankUpEvent?>
├── core/domain/        PassiveBonusService (패시브 누적/스태킹), PassiveBonusFormatter (17종 한국어 변환),
│                       PassiveBonusContext (Ref/WidgetRef 일괄 수집 헬퍼), ReputationService, ActivityLog 시스템
├── core/data/          Hive 초기화, JSON 로더, SyncService (18개 테이블)
├── features/
│   ├── home/           홈 화면, RankUpOverlay (랭크업 축하 다이얼로그), RankBonusSummarySheet (홈 등급 카드 보너스 시트)
│   ├── movement/       TravelEventService, MovementProvider, Repository
│   ├── quest/          ExperienceService, QuestCalculator (partyRoles·PassiveEffect 통합),
│   │                   QuestGenerator, FactionTagResolver (세력 태그 런타임 배정),
│   │                   RoleSynergyMatrix (6 role × 4 quest_type 상성 상수),
│   │                   RoleUtils, SuccessRateBreakdown (8레이어 분해 값 객체),
│   │                   QuestProvider, QuestCompletionService (평판 자동 지급), Repository
│   ├── mercenary/
│   │   ├── domain/     FacilityService (ConstructionService 위임 래퍼), RecruitmentService, MercenaryStatService,
│   │   │               TraitEffectService, TraitAcquisitionService, TraitEvolutionService,
│   │   │               TraitDeletionService, MercenaryProvider, Repository
│   │   └── view/       MercenaryCard (상성 tint·배지), MercenaryDetailOverlay, TraitSlotGrid,
│   │                   BehaviorStatsSection, TraitHistorySection,
│   │                   TraitDetailDialog, TraitAcquisitionDialog, TraitEvolutionDialog
│   ├── facility/
│   │   ├── domain/     ConstructionService (비용/시간/효과 공식), construction_completion_provider
│   │   └── view/       FacilityTabScreen, FacilityCard, ConstructionQueueBar, MilestoneTimeline
│   ├── investigation/
│   │   ├── domain/     InvestigationNotifier, InvestigationService, investigation_completion_provider
│   │   └── data/       RegionStateRepository
│   ├── info/
│   │   ├── domain/     FactionJoinService (순수 정적 서비스), faction_codex_providers (factionListProvider, factionCodexScrollTargetProvider, factionRefreshProvider)
│   │   ├── data/       FactionStateRepository (join/leave/addReputation/applyConflictPenalty)
│   │   └── view/       InfoScreen, FactionCodexScreen, FactionDetailScreen, RankInfoScreen (F~A 타임라인)
│   └── settings/       SettingsScreen (개발 도구만 유지, 홈 탭으로 이동)
└── shared/widgets/     BottomNavBar (6탭), TimerDisplay, StatusBadge
```

서비스 16개: **PassiveBonusService**, ReputationService, TravelEventService, ExperienceService, QuestCalculator, **FactionTagResolver**, RecruitmentService, FacilityService, **ConstructionService**, MercenaryStatService, TraitEffectService, TraitAcquisitionService, TraitEvolutionService, TraitDeletionService, **InvestigationService**, **FactionJoinService**
