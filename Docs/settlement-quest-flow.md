# 더스트빌 거점 사건 진행 흐름

> 작성일: 2026-05-04  
> 대상: 신규 팀원 온보딩 / 컨텐츠 리뷰

---

## 개요

더스트빌(region 3)의 고정 임무 라인 **"폐광길 재개방"** 이 신규 유저에게 어떤 조건과 순서로 노출되는지 설명한다.

관련 시스템: 마을 신뢰도(`RegionState`) · 거점 사건 체인(`ChainQuestProgress`) · 고정 의뢰(`quest_pools.is_fixed`)

---

## 1. 초기 활성화

새 게임 시작 시 `initializeNewGame()` 내부에서 자동으로 체인을 활성화한다.

```
tryActivateSettlement(regionId: 3, eventName: 'pyegwang_reopen')
  → ChainQuestProgress 생성
    chainId : settlement_3_pyegwang_reopen
    step    : 1
    status  : active
```

플레이어가 별도로 무언가를 트리거할 필요 없이, 게임 시작과 동시에 1단계 의뢰가 파견 탭에 나타날 준비가 된다.

---

## 2. 전체 진행 흐름

```
신뢰도 1단계 (0점, 의심) ─────────────────────────────────────────
  Step 1 │ 폐광 입구 정찰       │ explore │ D1 │ 완료 시 신뢰도 +10
  Step 2 │ 도굴꾼 흔적 추적     │ hunt    │ D1 │ 완료 시 신뢰도 +15
         │                                        누적 약 25점
         │  ← 허드렛일로 5점을 채워야 다음 단계 열림 ───────────────
신뢰도 2단계 (30점, 인지) ─────────────────────────────────────────
  Step 3 │ 박쥐 둥지 소탕       │ raid    │ D2 │ 완료 시 신뢰도 +20
  Step 4 │ 광부의 도구 회수     │ escort  │ D2 │ 완료 시 신뢰도 +25
         │                                        누적 약 70점
         │  ← 허드렛일로 10점을 채워야 다음 단계 열림 ──────────────
신뢰도 3단계 (80점, 친근) ─────────────────────────────────────────
  Step 5 │ 갱도 안전 확보       │ raid    │ D3 │ 완료 시 신뢰도 +30
  Step 6 │ 폐광 재개방식 안전   │ survey  │ D3 │ 완료 시 신뢰도 +100
         │                                        ─ 사건 종료 ─
신뢰도 4단계 (200점, 소속) 자동 진입 ────────────────────────────────
```

---

## 3. 단계별 노출 조건

각 단계는 아래 **4가지 조건을 모두 충족**해야 파견 탭에 나타난다.  
조건 체크는 `_injectFixedSettlementQuest()` 가 담당한다.

| # | 조건 | 설명 |
|---|------|------|
| 1 | 체인이 active 상태 | `ChainQuestProgress.status == active` |
| 2 | 현재 step 일치 | `quest_pools.fixed_step == currentStep` |
| 3 | **신뢰도 단계 충족** | `trust_threshold <= currentTrustLevel` ← **핵심 게이트** |
| 4 | 중복 방지 | 동일 step 의뢰가 이미 pending/inProgress 아닌 경우 |

### trust_threshold 매핑

| Step | 의뢰명 | trust_threshold | 필요 신뢰도 |
|------|--------|----------------|------------|
| 1 | 폐광 입구 정찰 | 1 | 0점 (즉시) |
| 2 | 도굴꾼 흔적 추적 | 1 | 0점 (즉시) |
| 3 | 박쥐 둥지 소탕 | 2 | 30점 이상 |
| 4 | 광부의 도구 회수 | 2 | 30점 이상 |
| 5 | 갱도 안전 확보 | 3 | 80점 이상 |
| 6 | 폐광 재개방식 안전 관리 | 3 | 80점 이상 |

---

## 4. 완료 후 다음 단계로 넘어가는 흐름

성공 또는 대성공 시에만 진행된다. 실패·대실패는 `stepFailureCount += 1`만 기록되고 의뢰가 그대로 남아 재파견 가능하다.

```
파견 완료 (성공/대성공)
  │
  ├─ ChainQuestService.onStepCompleted()
  │    ├─ settlement_ prefix → protagonist 지정 없음 (일반 체인과 다름)
  │    ├─ 마지막 step이 아니면 → progress.currentStep += 1
  │    └─ 마지막 step(6)이면   → completeChain() 호출
  │
  └─ addSettlementTrust(amount: trustRewardOverride)
       ├─ 신뢰도 레벨업 미발생 → 다음 generateQuests() 시 자동 주입
       └─ 신뢰도 레벨업 발생   → refreshAvailableQuests() 즉시 호출
                                  → 다음 step 파견 탭 즉시 등장
```

---

## 5. 사건 종료 (Step 6 완료)

Step 6 완료 시 다음이 순서대로 처리된다.

1. `setEventCompleted()` — 촌장 집에 🎉 완료 배너 표시
2. `completeChain()` — 연계 완료 팝업 표시 (`chainCompletedProvider`)
3. 명성 **+500** 지급 (`chain_quests.final_reputation_bonus`)
4. 신뢰도 **+100** — 4단계(소속) 자동 진입
5. 촌장 집 **상황 듣기** 텍스트가 완료 후 대사로 전환

---

## 6. 허드렛일의 역할

허드렛일(`is_fixed=false` 의뢰)은 신뢰도를 채우는 **버퍼** 역할을 한다.

| 구간 | 사건 step 보상 합계 | 필요 임계값 | 부족분 | 허드렛일 필요 |
|------|-------------------|------------|--------|-------------|
| 1단계 → 2단계 | step1(+10) + step2(+15) = **25점** | 30점 | **5점** | 약 1~2회 |
| 2단계 → 3단계 | step3(+20) + step4(+25) = **45점** | 80점 | **~10점** | 약 2~3회 |
| 3단계 → 4단계 | step5(+30) + step6(+100) = **130점** | 200점 | 충분 (step6이 큰 보상) | 불필요 |

허드렛일을 전혀 안 하면 신뢰도 임계값에 막혀 사건 step이 열리지 않는다. 초반 루프에서 반복 플레이를 유도하는 구조다.

---

## 7. 파견 탭 UI에서 보이는 방식

- 고정 사건 의뢰는 `isSettlementStep = true`
- 파견 탭 정렬 시 `settlementTier`로 **최상단 고정** 노출
- 자동 갱신(1시간 주기)에서 **제외** — 완료하기 전까지 사라지지 않음
- 퀘스트 카드에 체인 배지(⛓) 표시

---

## 8. 관련 파일

| 역할 | 파일 |
|------|------|
| 의뢰 주입 로직 | `features/quest/domain/quest_provider.dart` → `_injectFixedSettlementQuest()` |
| 체인 진행 로직 | `features/chain_quest/domain/chain_quest_service.dart` → `onStepCompleted()` |
| 촌장 집 UI | `features/settlement/view/chief_house_screen.dart` |
| NPC 대사 데이터 | `features/settlement/domain/settlement_npc_data.dart` |
| DB 의뢰 데이터 | Supabase `quest_pools` (is_fixed=true, fixed_chain_id='settlement_3_pyegwang_reopen') |
| DB 브리핑 텍스트 | Supabase `chain_quests` (chain_id='settlement_3_pyegwang_reopen') |
