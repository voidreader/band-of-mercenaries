# M4 마을 신뢰도 4단계 + 고정 사건 라인 1개 컨텐츠 기획서

> 작성일: 2026-05-03
> 유형: 신규 컨텐츠 (M4 마일스톤 — 페이즈 1 산출물 4/5)
> 선행 문서:
> - `Docs/Archive/20260503_m4-region-sectors/design_starting-settlement.md` — 거점 잠금 정책·인사말 변주 17개·NPC 5명
> - `Docs/Archive/20260503_m4-region-migration/design_content.md` — 더스트플레인 region_id 3
> - `Docs/Archive/20260503_m4-region-sectors/design_sector-system.md` — 4섹터 구성(폐광 = sector_index 2 dungeon)
> - `Docs/roadmap/master_roadmap.md` (669~695행) — `#신뢰도 기반 고정 의뢰`, `#마을 신뢰도 4단계`
> 후속:
> - 페이즈 1 #5 "초반 2시간 플레이 흐름" — 본 문서의 6단계 사건 라인을 분 단위 흐름에 배치
> - 페이즈 2 #1 "마을 신뢰도 누적 임계값 + 단계별 보상 수치" — 본 문서의 단계 구분을 입력으로 받아 임계값·보상 정량화
> - 페이즈 2 #4 "고정 사건 의뢰 난이도·보상" — 본 문서의 6단계 의뢰를 입력으로 받아 난이도·보상 곡선 확정
> - 페이즈 4 #3 "quest_pools 컬럼 확장 + 고정 의뢰 노출 로직" — 본 문서의 4개 컬럼 정의 + 노출 규칙을 명세 입력
> - 페이즈 4 #5 "마을 신뢰도 시스템 + 고정 사건 진행 상태" — 본 문서의 저장소 결정을 명세 입력

---

## 개요

본 문서는 M4 시작 거점의 두 가지 핵심 시스템을 동시에 정의한다.

1. **마을 신뢰도 4단계**: 1(의심) → 2(인지) → 3(친근) → 4(소속). 단계 진입은 누적 신뢰도 임계값 도달 + 거점 해금/상태 변화/보상을 동반한다.
2. **고정 사건 라인 1개**: "폐광길 재개방" — 6단계 사건. 단계별 trust_threshold로 점진 노출되며, 최종 단계 완료가 신뢰도 4단계 진입 트리거다.

또한 본 문서는 두 가지 저장소 결정을 권장안으로 확정한다.
- **마을 신뢰도 저장소**: `regionStates` 확장 (M4 MVP 단순성 우선)
- **고정 사건 진행 저장소**: `chainQuestProgress` 재사용 (chain_id 네이밍 컨벤션으로 구분, 14일 dormant 비활성화)

수치(임계값·단계별 보상·의뢰 난이도 곡선)는 페이즈 2에 위임한다.

---

## 레퍼런스 분석

| 레퍼런스 | 차용 메커니즘 | 적용 방식 |
|---------|-------------|----------|
| Stardew Valley — Heart Level 시스템 | NPC별 0~10 hearts 누적, 특정 heart에서 컷씬·이벤트 해금 | 마을 단위 4단계 신뢰도. 단계 진입 = 거점 해금 + 인사말 변주 (heart에서 컷씬 해금과 동일 메커니즘) |
| Kingdom of Loathing — Council of Loathing 단계 진행 | "다음 목표 안내" 1명 NPC가 단계별로 다른 임무 부여, 단계 완료 시 자동 다음 임무 노출 | 촌장 파슨이 단일 허브로 사건 라인 진행. step 완료 시 자동 step+1 노출 |
| Hades — Heat 시스템 (재시도 가능) | 실패해도 풀에서 사라지지 않고 다음 시도 가능, 누적 진행도가 보존 | quest_pools.is_fixed = true 의뢰는 실패 후 재등장. 신뢰도 단계가 유지되는 한 노출 유지 |
| Disco Elysium — White Check 시스템 | 단순 성공/실패 외에 "성공 시 사건 진행, 실패 시 다른 분기" 흐름 | M4 MVP는 분기 없이 선형 6단계. M5+ 확장 시 분기 가능성 (본 문서 4.6절) |
| World of Warcraft — Reputation 시스템 (Hated → Exalted) | 6단계 + 단계별 명확한 시각 표시(색상·아이콘) + 단계별 보상 매핑 | 4단계 압축 + 거점 인사말·UI 색상 시각으로 단계 표현. 1=Hated 등가 / 4=Exalted 등가 |

**기존 게임과의 차별 포인트**: M3까지의 시스템(명성 F~A · 세력 평판 ±100 · 체인 퀘스트)은 모두 글로벌 단위였다. M4는 **거점 단위 신뢰도**를 처음으로 도입한다. M7 다중 거점 확장 시 동일 패턴 복제 가능한 형태로 설계한다.

---

## 상세 설계

### 1. 마을 신뢰도 4단계 컨셉

#### 1.1 단계 정의

| 단계 | 이름 | 핵심 톤 | 정량적 신호 | 거점 잠금 정책 (페이즈 1 #3 정합) |
|------|------|---------|-------------|----------------------------------|
| **1** | 의심 (Suspicion) | 외지인에 대한 경계 | 모든 NPC가 "쓸 만한지부터 보자" 톤 | 촌장 집: 모든 버튼 활성. 낡은 대장간: **모든 버튼 비활성**. 약초상: 즉시 회복 비용 +50% |
| **2** | 인지 (Acknowledgment) | "쓸만한 외지인" | NPC가 "허드렛일 정도는 맡길 수 있겠다" 톤 | 촌장 집: 버튼 활성. 낡은 대장간: 제작 목표 보기·재료 힌트 활성. 약초상: 비용 정상화 + 채집 의뢰 노출 |
| **3** | 친근 (Familiarity) | 마을의 친근한 외부인 | NPC가 "자네 이야기를 한다" 톤 | 촌장 집·대장간 모든 버튼 활성. 약초상 쿨다운 24h → 12h |
| **4** | 소속 (Belonging) | "이제 우리 마을 사람" | NPC가 "우리 마을의 일원" 톤 | 모든 거점 버튼 활성 + 보상 +20%. 광장 풍문 변화 |

각 단계 진입 시 다음이 발생한다.
- **거점 해금/상태 변화**: 페이즈 1 #3에 정의된 단계별 인사말 + 버튼 활성 정책 적용.
- **보상 지급**: 단계 진입 시 일회성 보상(골드/XP/명성 등). 수치는 페이즈 2 #1.
- **활동 로그 기록**: `ActivityLogType.settlementTrustUp`(신규 enum) 또는 `ActivityLogType.regionTransform`(기존) 재사용. 페이즈 4 #5에서 결정.

#### 1.2 누적 신뢰도 점수 컨셉

신뢰도는 **누적 점수**로 추적되며, 단계 진입 임계값에 도달하면 자동 승급한다 (M4 시점에서 강등 없음 — 페이즈 2 #1에서 강등 정책 검토).

신뢰도 점수 획득 경로:
1. **고정 사건 의뢰 완료** — 메인 점수원 (단계 진입의 핵심 트리거)
2. **세력 태그 = 마을 또는 무태그 일반 의뢰 완료** — 보조 점수원 (낮은 점수)
3. **세력 태그 = 외부 세력 의뢰 완료** — 무영향 (세력 평판으로만 적용)
4. **이동 선택지 결과 일부** — 페이즈 2 #1에서 정의 가능 (예: 마른 초원에서 약초 채집 성공)

수치 곡선은 페이즈 2 #1에 위임. 본 문서는 **단계 구분 + 트리거 종류**만 확정.

**페이즈 2 #1 입력 가이드**:
- 첫 2시간 안 신뢰도 1단계 → 2단계 도달 보장 (페이즈 1 #5의 분 단위 흐름과 정합)
- 첫 2시간 안 2단계 → 3단계 도달 가능 (선택적, 적극 플레이 시)
- 4단계 도달은 첫 2시간 외부 (M4 종료 조건의 일부)

#### 1.3 단계 시각 정책 (UI 가이드)

| 단계 | 권장 UI 색상 | 인사말 톤 | 진행 바 표시 |
|------|------------|----------|------------|
| 1 | `surface` 회색 | 차가움·짧음 | 0% — 25% (예시) |
| 2 | `secondary` 베이지 | 중립·실용 | 25% — 50% |
| 3 | `tertiary` 따뜻한 brown | 친근 | 50% — 75% |
| 4 | `primary` amber | 환영·자랑 | 75% — 100% (또는 "달성") |

**구현 권장**: `AppTheme`에 `settlementTrustL1~L4` 신규 색상 4개 추가, 또는 기존 surface/secondary/tertiary/primary 재사용. 페이즈 4 #5에서 결정.

### 2. 고정 사건 라인: "폐광길 재개방"

#### 2.1 사건 라인 선택 사유

세 후보(폐광길 재개방 / 실종된 광부 수색 / 야간 습격 방어) 중 **폐광길 재개방**을 채택한다.

| 후보 | 채택 평가 |
|------|----------|
| **폐광길 재개방** | ✅ 페이즈 1 #3의 4섹터(특히 폐광)와 직접 연결. 마을의 정체성("Dust" = 광산이 닫혀 먼지만 남은) 회복 서사. 6단계 흐름에 사건성·재미·진행감 균형 |
| 실종된 광부 수색 | ❌ 폐광 안 단발 임무 위주가 되어 4섹터 다양성 활용 불가. 6단계로 분해 시 반복적 |
| 야간 습격 방어 | ❌ 마을 외부 위협 중심이라 "마을 인정"의 서사보다 "외부 적 격퇴"에 가까움. 시작 거점 컨셉(변방 인정)에 부적합 |

**서사 한 줄 요약**: 닫힌 폐광을 다시 열어 마을의 생계를 되찾는 6단계 사건. 외지 용병이 마을의 가장 두려운 곳에 들어가서 마을을 일으키는 흐름.

#### 2.2 6단계 구성

| step | step 이름 | 무대 | quest_type | 의뢰 컨셉 | trust_threshold | 완료 시 효과 |
|------|----------|------|-----------|----------|----------------|-------------|
| 1 | 폐광 입구 정찰 | 폐광 (sector 2) | explore | 무너진 입구를 살펴보고 진입 가능 여부 보고. 박쥐 떼와 대치 | **1** | 신뢰도 +α (페이즈 2 #1), step 2 노출 |
| 2 | 도굴꾼 흔적 추적 | 마른 초원 (sector 3) | hunt | 폐광에서 들고 나온 듯한 흔적을 따라 외곽까지 추적 | **1** | 신뢰도 +α, step 3 노출 + **신뢰도 2단계 진입 트리거** (점수 충족 시) |
| 3 | 박쥐 둥지 소탕 | 폐광 (sector 2) | raid | 폐광 내부에 자리 잡은 거대 박쥐 둥지 소탕. 첫 위험 의뢰 | **2** | 신뢰도 +α, step 4 노출. **첫 엘리트 후보** (거대 박쥐 — M4 시점에 elite_monsters에 추가 검토) |
| 4 | 광부의 도구 회수 | 폐광 (sector 2) | escort | 마을 노인이 잃어버린 도구를 찾기 위해 폐광에 동행 (호위) | **2** | 신뢰도 +α, step 5 노출 + **신뢰도 3단계 진입 트리거** (점수 충족 시) |
| 5 | 갱도 안전 확보 | 폐광 (sector 2) | raid | 무너진 갱도를 보강하고 잔여 위협 제거 | **3** | 신뢰도 +α, step 6 노출 |
| 6 | 폐광 재개방식 | 더스트빌 (sector 1) | survey | 마을 광장에서 열리는 재개방식 안전 관리. 클라이맥스 | **3** | 신뢰도 +α (큰 보상) + **신뢰도 4단계 진입 트리거** + 사건 완료 직후 마을 반응 24h 노출 |

**4섹터 다양성 활용**:
- 폐광(sector 2) × 4회 (step 1, 3, 4, 5) — 핵심 무대
- 마른 초원(sector 3) × 1회 (step 2) — 추적 의뢰
- 더스트빌(sector 1) × 1회 (step 6) — 클라이맥스
- 먼지로 덮인 길(sector 4) × 0회 — 본 사건과 무관 (M5+ 다른 사건 라인의 주무대로 보존)

**quest_type 다양성**: explore × 1, hunt × 1, raid × 2, escort × 1, survey × 1 — 4종 quest_type 모두 활용.

#### 2.3 단계별 trust_threshold 매핑 정책

`trust_threshold` = "이 step이 노출되기 시작하는 신뢰도 단계 임계값". 따라서:

| step | trust_threshold | 노출 조건 |
|------|----------------|----------|
| 1 | **1** | 게임 시작 즉시 (신뢰도 1단계가 기본값) |
| 2 | **1** | 신뢰도 1단계 + step 1 완료 |
| 3 | **2** | 신뢰도 2단계 + step 2 완료 |
| 4 | **2** | 신뢰도 2단계 + step 3 완료 |
| 5 | **3** | 신뢰도 3단계 + step 4 완료 |
| 6 | **3** | 신뢰도 3단계 + step 5 완료 |

**중요 정합성**: step 2 완료 시 신뢰도 2단계 진입 트리거. 트리거 즉시 step 3가 trust_threshold 조건 충족. 따라서 사건 라인은 **신뢰도 점수가 충분하면 자연스럽게 다음 step 노출**이 보장된다.

만약 신뢰도 점수가 부족해서 step 2 완료해도 신뢰도 1단계에 머문다면? → step 3 노출 차단. 플레이어는 일반 의뢰로 신뢰도 점수를 더 쌓은 뒤 신뢰도 2단계 진입 시 step 3 자동 노출. **이 흐름이 페이즈 2 #1 임계값 설계의 입력**.

**최종 step 6 → 신뢰도 4단계 진입 룰**:
- step 6 완료 시 큰 신뢰도 보상 지급 (페이즈 2 #1).
- 보상 지급 후 누적 점수가 4단계 임계값 도달 → 신뢰도 4단계 자동 진입.
- 즉, **step 6 보상이 4단계 임계값을 정확히 채우도록** 페이즈 2 #1에서 임계값 역산 가능.

#### 2.4 실패·재등장 정책

`quest_pools.is_fixed = true`인 의뢰는 다음 규칙을 따른다.

1. **실패해도 풀에서 사라지지 않는다.** 일반 의뢰는 자동 갱신 주기(1시간)에 새 의뢰로 교체되지만, 고정 의뢰는 재시도 가능 상태로 유지.
2. **노출은 신뢰도 단계 + 이전 step 완료 두 조건이 모두 충족될 때만**.
3. **단계 완료 시 다음 step 자동 노출** — 신뢰도 단계 충족 조건 한정.
4. **6단계 모두 완료 시 사건 라인 종료** — `chainQuestProgress.status = completed` 전이.
5. **체인 큐 알림**: 페이즈 1 #3에서 정의한 촌장 집 [상황 듣기] 버튼이 항상 현재 step의 브리핑을 보여준다 (UI 통합).

#### 2.5 분기 정책 (M4 MVP는 선형)

본 6단계 사건은 **선형**이다. 분기/실패 분기/조건부 분기는 M4 MVP에서 도입하지 않는다. M5+ 확장 시 다음을 검토 가능 (본 문서는 컨셉만 명시).

- step 3 박쥐 소탕 vs 도굴꾼 협상 (선택)
- step 4 광부 동행 시 광부 사망/생존 분기

M4에서는 이러한 분기가 없으며, 모든 step은 1개 quest_pool 행으로만 정의된다.

#### 2.6 사건 완료 후 후속

페이즈 1 #3에 정의된 "사건 완료 직후 반응" 1개 문구가 24시간(게임 시간) 동안 모든 거점에 노출된다.

> "마을이 며칠간 시끄럽게 떠들썩했다. 광장에서 작은 잔치가 열렸고, 사람들은 당신에게 고개를 숙였다."

이후 일반 신뢰도 4단계 인사말로 복귀.

**M4 시점에서는 다른 사건 라인을 추가하지 않는다** — "폐광길 재개방" 1개로 첫 2시간 + α 분량 충분. M5+ 다른 사건 라인 추가 시 동일 quest_pools 패턴 사용 (본 문서의 정책 그대로 복제).

### 3. quest_pools 4개 컬럼 확장

#### 3.1 컬럼 정의

| 컬럼 | 타입 | 제약 | 의미 |
|------|------|------|------|
| `is_fixed` | BOOL | NOT NULL DEFAULT false | 고정 의뢰 여부. true이면 자동 갱신 주기에서 제외 |
| `fixed_chain_id` | TEXT | nullable, FK 권장 안 함 (M4 텍스트 단순) | 고정 사건 라인 ID. 예: `dustvile_pyegwang_reopen` |
| `fixed_step` | INT | nullable, CHECK (fixed_step BETWEEN 1 AND 20) | 사건 라인 내 단계. 1-based |
| `trust_threshold` | INT | nullable, CHECK (trust_threshold BETWEEN 1 AND 4) | 노출 시작 신뢰도 단계 |

**유니크 제약 권장**: `(fixed_chain_id, fixed_step)` UNIQUE — 동일 chain의 동일 step 중복 방지. is_fixed=false 행은 fixed_chain_id가 null이므로 제약 적용 안 됨.

#### 3.2 `dustvile_pyegwang_reopen` 사건의 quest_pools 6행

페이즈 3 또는 페이즈 4 인라인에서 입력할 데이터.

| id | quest_type | difficulty | sector_type | is_fixed | fixed_chain_id | fixed_step | trust_threshold | 비고 |
|----|-----------|-----------|------------|----------|---------------|-----------|----------------|------|
| `qp_pyegwang_step1` | explore | 1 | dungeon | true | `dustvile_pyegwang_reopen` | 1 | 1 | 폐광 입구 정찰 |
| `qp_pyegwang_step2` | hunt | 1 | field | true | `dustvile_pyegwang_reopen` | 2 | 1 | 도굴꾼 흔적 추적 |
| `qp_pyegwang_step3` | raid | 2 | dungeon | true | `dustvile_pyegwang_reopen` | 3 | 2 | 박쥐 둥지 소탕 (엘리트 후보) |
| `qp_pyegwang_step4` | escort | 2 | dungeon | true | `dustvile_pyegwang_reopen` | 4 | 2 | 광부의 도구 회수 |
| `qp_pyegwang_step5` | raid | 3 | dungeon | true | `dustvile_pyegwang_reopen` | 5 | 3 | 갱도 안전 확보 |
| `qp_pyegwang_step6` | survey | 3 | village | true | `dustvile_pyegwang_reopen` | 6 | 3 | 폐광 재개방식 |

기타 컬럼(`name`, `description`, `enemy_name`, `recommend_power`, `reward_gold`, `reward_xp` 등)은 페이즈 2 #4 (보상 곡선) + 페이즈 3 또는 페이즈 4 텍스트 입력에서 확정.

#### 3.3 노출 로직 (페이즈 4 #3 명세 입력)

`QuestGenerator` (또는 `DispatchScreen` 정렬 단계)에서 다음 분기를 추가:

```
일반 갱신 주기:
  pool := SELECT FROM quest_pools WHERE is_fixed = false [기존 조건]
  → ActiveQuest 생성 (기존 흐름)

고정 의뢰 노출:
  trust := getCurrentSettlementTrust(regionId)
  progress := getChainQuestProgress("dustvile_pyegwang_reopen")
  currentStep := progress?.currentStep ?? 1

  pool := SELECT FROM quest_pools
          WHERE is_fixed = true
            AND fixed_chain_id = "dustvile_pyegwang_reopen"
            AND fixed_step = currentStep
            AND trust_threshold <= trust

  IF pool 존재 AND ActiveQuest로 미발행:
    → ActiveQuest 생성 (isFixed=true 또는 isChainStep=true 분기 — 4.4절 참조)
    → 파견 화면 최상단 또는 5계층 정렬 Tier 0~1에 노출
```

**중요**: 일반 갱신 주기는 `is_fixed = true` 행을 **제외**한다. 고정 의뢰는 별도 흐름으로만 노출.

#### 3.4 정렬 우선순위

페이즈 1 #3·#2의 5계층 정렬(체인 → 세력 전용 → 엘리트 → 변형 섹터 → 일반)에 고정 의뢰를 어느 계층에 둘 것인가?

**권장**: **Tier 0 (체인 active)에 통합** — 4.4절 저장소 결정과 연동. 단, ChainTopSection의 1~3장 슬롯을 체인 + 고정 의뢰가 공유하지 않도록 분리 정책 권장:
- ChainTopSection 슬롯: 체인 퀘스트(`isChainStep` && `chain_id`가 settlement_ prefix 없음) 우선.
- 고정 의뢰는 일반 목록 최상단(Tier 0 일반 카드 형태)에 노출.

세부 UI 정책은 페이즈 4 #3·#4에서 결정. 본 문서는 **데이터 노출 규칙**만 확정.

### 4. 저장소 결정

본 절은 두 가지 저장소 결정을 권장안 + 사유와 함께 제시한다. 페이즈 4 #5 명세 작성 시 본 권장안을 그대로 채택하거나 조정한다.

#### 4.1 마을 신뢰도 저장소 권장: `regionStates` 확장

**옵션 비교**

| 옵션 | 설명 | 장점 | 단점 |
|------|------|------|------|
| A. **`regionStates` 확장** | RegionState 모델에 `settlementTrust` (int, 누적 점수) + `settlementTrustLevel` (int 1~4) 두 필드 추가 | M4는 1지역 1마을이므로 1:1 매핑이 자연스러움. 마이그레이션 단순 (HiveField 추가). 신규 박스/모델 불필요 | M7 다중 거점 확장 시 거점 ≠ 리전 매핑 문제 (한 리전에 여러 거점 가능?) |
| B. `settlementStates` Hive 박스 신설 | typeId 16 또는 17. SettlementState(settlementId, regionId, trust, trustLevel) 신규 모델 | M7 다중 거점 대비 인터페이스 명확. 거점이 마을 단위라는 의미 표현 | M4 시점에서 over-engineering. 신규 박스/모델/Repository 추가 부담 |

**권장: 옵션 A**. 이유:
1. M4 MVP는 1지역 1마을이라 1:1 매핑이 정확하다.
2. RegionState는 이미 sectorChanges, knowledge, triggeredDiscoveries 등 리전 단위 상태를 보유하므로 settlementTrust도 자연스러운 확장.
3. M7 다중 거점 확장 시 마이그레이션 path: RegionState.settlementTrust → SettlementState로 옮기는 1회 마이그레이션 (페이즈 4 #5 명세에 미래 마이그레이션 가이드 포함).
4. 코드 변경 최소: HiveField 4·5 추가 + RegionStateRepository 메서드 1~2개 추가.

**RegionState 확장 권장 필드**:

```dart
@HiveType(typeId: 8)
class RegionState extends HiveObject {
  // 기존 0~3 유지
  // ...

  @HiveField(4)
  int? settlementTrust; // 누적 점수, null = 미초기화 (하위호환)

  @HiveField(5)
  int? settlementTrustLevel; // 1~4 단계 캐시, null = 1단계 (하위호환)

  int get currentTrust => settlementTrust ?? 0;
  int get currentTrustLevel => settlementTrustLevel ?? 1;
}
```

**Repository 추가 메서드**:
- `addSettlementTrust(int regionId, int amount, String source)` — 누적 점수 증가 + 단계 승급 검증 + ActivityLog 기록.
- `getSettlementTrust(int regionId) → (trust: int, level: int)`
- `setSettlementTrust(int regionId, int trust, int level)` — 운영 도구·디버그용

**Provider 추가 권장**:
- `settlementTrustProvider(int regionId) → Provider<int>` — 현재 신뢰도 단계 동기 제공
- `settlementTrustLevelUpProvider → StateProvider<TrustLevelUpEvent?>` — 단계 승급 이벤트 채널 (rankUpProvider와 동일 패턴)

#### 4.2 고정 사건 진행 저장소 권장: `chainQuestProgress` 재사용

**옵션 비교**

| 옵션 | 설명 | 장점 | 단점 |
|------|------|------|------|
| A. **`chainQuestProgress` 재사용** | chain_id 네이밍 컨벤션으로 구분. 고정 사건 = `settlement_*` prefix (예: `settlement_3_pyegwang_reopen`) | 모델 거의 동일 (chainId / currentStep / status / startedAt / completedAt 모두 사용). Repository·Service·UI 통합. 신규 Hive 타입 불필요 | "체인 퀘스트"와 "고정 사건"의 의미 혼란 가능. 14일 dormant 정책이 마을 사건에 부적합 (분기 처리 필요) |
| B. `settlement_event_progress` 신규 박스 | typeId 16. 거점 단위 모델 신규 | 의미 명확. 14일 dormant 정책 적용 안 함 | 모델 거의 동일한 데이터를 두 박스에 분산. UI·Repository 중복 |

**권장: 옵션 A**. 이유:
1. ChainQuestProgress 모델은 이미 모든 필요 필드를 가지고 있다 (chainId, currentStep, status, startedAt, completedAt, currentStepAvailableAt, stepFailureCount, lastActivityAt). protagonistMercId만 무시하면 그대로 활용 가능.
2. Repository·Service·UI(ChainTopSection·ChainCompletedDialog) 그대로 재사용.
3. chain_id prefix로 구분: `chain_*` (기존 region_discovery 트리거 체인) vs `settlement_*` (신규 trust_threshold 트리거 사건).
4. 14일 dormant 비활성화는 Service 레이어에서 prefix 검사로 처리 (`if (chainId.startsWith("settlement_")) skip dormancyCheck`).

**chain_id 네이밍 컨벤션**:
- 기존 체인: `chain_<chain_name>` (예: `chain_roadside_shrine`) — 24개 chain_quests 행과 일치
- 신규 고정 사건: `settlement_<region_id>_<event_name>` (예: `settlement_3_pyegwang_reopen`)
- 정규식 분기: `^settlement_\d+_.+$` 매칭 시 거점 사건으로 처리

**ChainQuestProgress 재사용 시 분기 정책**:
- `protagonistMercId`: 거점 사건은 항상 null (마을 사건이므로 주인공 용병 미사용).
- `currentStepAvailableAt`: 거점 사건은 null (완료 후 즉시 다음 step 노출, 시간 대기 없음). 만약 페이즈 2 #4에서 시간 간격 도입 결정 시 활용 가능.
- `stepFailureCount`: 그대로 사용 (실패 시 +1, 재시도 시 검증).
- `lastActivityAt`: 갱신은 하되 dormancy 검사에는 사용 안 함 (분기).
- `status`: active / completed만 사용. dormant는 거점 사건에 미적용.

**ChainQuestService 분기 추가**:
- `tryActivate(ChainQuestData)`: 기존 region_discovery 트리거 — 변경 없음.
- `tryActivateSettlement(int regionId, String eventName)`: 신규 — 신뢰도 1단계 도달 시 자동 호출. 페이즈 4 #5에서 정의.
- `advanceStep(String chainId)`: 기존 — 변경 없음 (settlement_ prefix도 동일 흐름).
- `dormancyCheck()`: 분기 추가 — settlement_ prefix는 skip.

#### 4.3 활동 로그 통합

신규 ActivityLogType enum 추가 (HiveField 충돌 회피):
- `settlementTrustUp` (HiveField 22) — 신뢰도 단계 상승. 메시지 예: "마을 신뢰도가 2단계(인지)에 도달했다"
- `settlementEventStep` (HiveField 23) — 고정 사건 step 완료. 메시지 예: "사건 진행: 폐광 입구 정찰 완료 (1/6)"
- `settlementEventCompleted` (HiveField 24) — 고정 사건 라인 완주. 메시지 예: "폐광길 재개방 완료! 마을이 잔치를 벌인다"

기존 `ActivityLogType.chainProgressed`(18) / `chainCompleted`(20)와 분리하는 이유: 활동 로그 필터링 시 거점 사건과 일반 체인을 구분 가능. 색상·아이콘도 차별화 가능.

대안 (단순화 옵션): 기존 `chainProgressed`/`chainCompleted` 재사용 — 메시지 텍스트로만 구분. 페이즈 4 #5에서 결정.

#### 4.4 ActiveQuest 모델 영향

기존 ActiveQuest는 `isChainStep` (HiveField 21) + `chainId` (HiveField 22) + `chainStep` (HiveField 23)를 보유. 거점 사건도 동일 필드 재사용 가능.

**판별 로직**:
- `chainId?.startsWith("settlement_") == true` → 거점 사건 step
- `chainId?.startsWith("chain_") == true` → 일반 체인 step
- 둘 다 아닌 경우 → 일반 의뢰

**UI 차별화**:
- ChainTopSection: 일반 체인만 (settlement_ prefix 제외) — 페이즈 4 #3에서 정렬 정책 확정
- 거점 사건 카드: 일반 목록 최상단 + 별도 배지 ("📜 마을 사건" 또는 "🏘️ 사건")

### 5. data-generator 적용 여부

본 문서의 산출물 분류:

| 항목 | 수량 | data-generator 적용 권장 |
|------|------|------------------------|
| quest_pools 6행 (`dustvile_pyegwang_reopen` step 1~6) | 6 | △ — 기존 quest-pool 타입 변형 또는 인라인. 페이즈 3 진입 시 결정 |
| 6단계 의뢰 텍스트 (name·description·enemy_name) | 6 | △ — 본 문서 2.2절에 컨셉 명시, 페이즈 3 또는 페이즈 4에서 텍스트 작성 |
| quest_pools 신규 컬럼 4개 | — | ❌ — 페이즈 4 #3 마이그레이션 SQL |
| RegionState HiveField 추가 | — | ❌ — 페이즈 4 #5 코드 |
| ChainQuestService 분기 | — | ❌ — 페이즈 4 #5 코드 |

**6단계 의뢰 텍스트는 양이 적어 신규 타입 스펙(`types/fixed-quest.md`) 작성 부담이 크다.** 페이즈 4 #3·#5 명세에 인라인 처리 권장.

### 6. 페이즈 2·페이즈 4 입력 요약

#### 6.1 페이즈 2 #1 (마을 신뢰도 누적 임계값 + 단계별 보상 수치) 입력
- 단계 4개 (1·2·3·4) — 본 문서 1.1절
- 점수 획득 경로 4종 (고정 사건 / 일반 의뢰 / 외부 세력 의뢰=무영향 / 이동 선택지) — 본 문서 1.2절
- 첫 2시간 안 1단계 → 2단계 도달 보장 + 2단계 → 3단계 가능 — 본 문서 1.2절 가이드
- step 6 보상이 4단계 임계값을 정확히 채우도록 역산 — 본 문서 2.3절

**페이즈 2 #1 산출물 권장 내용**:
- 단계별 누적 임계값 (예: 0 / 30 / 80 / 200)
- step별 신뢰도 점수 보상 (예: step1=10 / step2=15 / step3=20 / step4=25 / step5=30 / step6=100)
- 일반 의뢰 1건당 신뢰도 점수 (난이도별 0~3 권장)
- 단계 진입 시 일회성 보상 (골드/XP)

#### 6.2 페이즈 2 #4 (고정 사건 의뢰 난이도·보상) 입력
- step별 quest_type / difficulty / sector_type — 본 문서 2.2절
- 최종 의뢰 60~80% 성공률 보장 (페이즈 1 #4 권장 — 페이즈 2 #4 확정)
- 6단계 의뢰의 reward_gold / reward_xp 곡선 — 페이즈 2 #4 산출물

#### 6.3 페이즈 4 #3 (quest_pools 컬럼 확장 + 고정 의뢰 노출 로직) 입력
- 4개 컬럼 정의 — 본 문서 3.1절
- `dustvile_pyegwang_reopen` 6행 — 본 문서 3.2절
- 노출 로직 — 본 문서 3.3절
- 정렬 우선순위 — 본 문서 3.4절

#### 6.4 페이즈 4 #5 (마을 신뢰도 시스템 + 고정 사건 진행 상태) 입력
- RegionState HiveField 4·5 추가 — 본 문서 4.1절
- chainQuestProgress 재사용 + chain_id 컨벤션 — 본 문서 4.2절
- ActivityLogType 3종 추가 — 본 문서 4.3절
- ChainQuestService 분기 — 본 문서 4.2절

---

## 현재 시스템과의 연관

### 영향받는 시스템

| 영역 | 영향 | 마이그레이션 범위 |
|------|------|------------------|
| `quest_pools` 테이블 | 4개 컬럼 추가(`is_fixed`/`fixed_chain_id`/`fixed_step`/`trust_threshold`) + 6행 INSERT | 페이즈 4 #3 |
| `RegionState` 모델 (typeId 8) | HiveField 4·5 추가 (settlementTrust / settlementTrustLevel) | 페이즈 4 #5 |
| `ChainQuestProgress` 모델 (typeId 13) | **변경 없음** — chain_id 네이밍 컨벤션으로 거점 사건 구분 | — |
| `ChainQuestService` | tryActivateSettlement / dormancyCheck 분기 추가 | 페이즈 4 #5 |
| `RegionStateRepository` | addSettlementTrust / getSettlementTrust / setSettlementTrust 추가 | 페이즈 4 #5 |
| `ActivityLogType` enum | settlementTrustUp(22) / settlementEventStep(23) / settlementEventCompleted(24) 추가 | 페이즈 4 #5 |
| `QuestGenerator` | is_fixed=true 행 일반 갱신 주기 제외 + 별도 노출 흐름 | 페이즈 4 #3 |
| `QuestSortService` | 거점 사건 카드를 일반 목록 최상단에 배치 (Tier 0 일반 또는 신규 Tier) | 페이즈 4 #3 |
| `ChainTopSection` | settlement_ prefix 제외 (일반 체인만 표시) | 페이즈 4 #3 |
| `ActiveQuest.chainId` | settlement_ prefix 분기 분류 — 변경 없음 (필드 재사용) | — |
| 촌장 집 [상황 듣기] 버튼 | 현재 `chainQuestProgress`에서 `settlement_3_pyegwang_reopen` 조회 → 현재 step 브리핑 표시 | 페이즈 4 #4·#5 |
| `settlementTrustProvider` (신규) | RegionStateRepository 기반 동기 Provider | 페이즈 4 #5 |
| `settlementTrustLevelUpProvider` (신규) | 단계 승급 이벤트 채널 + dialogQueue 통합 (medium priority 권장) | 페이즈 4 #5 |
| `dialogQueue` | 신뢰도 단계 승급 다이얼로그 추가 (medium 또는 high) | 페이즈 4 #5 |

### 호환성 검토

- **기존 사용자 세이브**: RegionState HiveField 4·5는 nullable이므로 기존 세이브와 호환. null = 1단계 / 점수 0 fallback.
- **chainQuestProgress 박스**: chain_id 네이밍 컨벤션만 추가. 기존 `chain_*` ID는 변경 없음. settlement_ prefix는 신규 ID만 사용.
- **일반 의뢰 자동 갱신 주기**: is_fixed=true 행 제외 분기 추가 외 동작 변경 없음.
- **5계층 정렬**: 거점 사건 카드의 노출 위치 결정은 페이즈 4 #3에서 확정. 본 문서는 "Tier 0 일반 또는 신규 Tier" 권장만.
- **운영 도구(operation-bom)**: quest_pools 편집 폼에 4개 컬럼 추가 (간단). 신규 거점 사건 추가 시 chain_id 네이밍 컨벤션 검증 권장.

### Tier 6~10 비영향 확인

본 시스템은 시작 거점(region_id 3, T1)에 한정된다. T6~T10 리전(M9 이연)의 기존 chainQuestProgress와 충돌 없음.

---

## 구현 우선순위 제안

| 항목 | 우선순위 | 근거 |
|------|---------|------|
| 마을 신뢰도 4단계 컨셉 (1.1·1.2·1.3절) | **높음** | 페이즈 2 #1·페이즈 4 #5의 입력 |
| 고정 사건 라인 "폐광길 재개방" 6단계 (2.2절) | **높음** | 페이즈 1 #5 분 단위 흐름 + 페이즈 2 #4 + 페이즈 4 #3의 입력 |
| trust_threshold 매핑 (2.3절) | **높음** | 페이즈 4 #3 노출 로직 직접 입력 |
| quest_pools 4개 컬럼 정의 (3.1·3.2·3.3·3.4절) | **높음** | 페이즈 4 #3 마이그레이션 + Generator 분기 입력 |
| 마을 신뢰도 저장소 결정 (4.1절) | **높음** | 페이즈 4 #5 명세 직접 입력. 본 문서로 권장 확정 |
| 고정 사건 진행 저장소 결정 (4.2절) | **높음** | 페이즈 4 #5 명세 직접 입력. 본 문서로 권장 확정 |
| 활동 로그 통합 (4.3절) | **중간** | 페이즈 4 #5에서 단순/통합 옵션 결정 |
| ActiveQuest UI 차별화 (4.4절) | **중간** | 페이즈 4 #3·#4에서 결정 |
| 분기 정책 (2.5절) | **낮음** | M4 MVP 미적용. M5+ 컨셉 메모 |

---

## 후속 작업

페이즈 1 #5 "초반 2시간 플레이 흐름"이 본 문서의 6단계 사건 라인을 분 단위 흐름에 배치한다. 권장 흐름 가이드:
- 0~10분: 첫 모집 + step 1 (폐광 입구 정찰) — 신뢰도 1단계 유지
- 10~30분: 일반 허드렛일 1~2건 + step 2 (도굴꾼 흔적 추적) → 신뢰도 2단계 진입
- 30~60분: 시설 건설 시작 + step 3 (박쥐 둥지 소탕, 첫 위험 의뢰) + step 4 (광부의 도구 회수)
- 60~120분: step 5·6 진행 → 신뢰도 3단계 도달, step 6는 첫 2시간 외부 마무리

페이즈 2 #1 "마을 신뢰도 누적 임계값"이 본 문서의 1.2절 점수 곡선과 2.3절 step 보상 매핑을 입력으로 받아 4단계 임계값을 확정한다.

페이즈 2 #4 "고정 사건 의뢰 난이도·보상"이 본 문서 2.2절 6단계 quest_type/difficulty 분포를 입력으로 받아 reward_gold·reward_xp·recommend_power 곡선을 확정한다 (최종 의뢰 60~80% 성공률 보장).

페이즈 4 #3·#5 "quest_pools 컬럼 확장 + 마을 신뢰도 시스템"이 본 문서 3·4절을 입력으로 받아 마이그레이션·코드 명세를 작성한다.

---

## data-generator 지시사항

본 문서의 6행 quest_pools는 신규 타입 스펙 작성 부담 대비 데이터량이 적어 페이즈 4 #3·#5 명세 인라인 처리를 권장한다. 만약 별도 처리 필요 시 다음 가이드를 따른다.

- **대상 타입**: `fixed-quest` (신규 작성 필요 — 단순 6행이므로 권장 안 함)
- **대상 테이블**: `quest_pools` (is_fixed=true 행)
- **생성 수량**: 6행 (`dustvile_pyegwang_reopen` step 1~6)
- **톤/세계관 가이드**: 폐광·먼지·산악 키워드. 변방 마을의 위협을 외지인이 풀어가는 톤. 영웅적 과장 지양, 실용적 묘사 우선
- **구조적 제약**:
  - quest_type 분포: explore × 1, hunt × 1, raid × 2, escort × 1, survey × 1
  - sector_type 분포: dungeon × 4, field × 1, village × 1
  - difficulty 분포: 1 × 2 (step 1·2), 2 × 2 (step 3·4), 3 × 2 (step 5·6)
  - is_fixed = true (전 행), fixed_chain_id = "dustvile_pyegwang_reopen" (전 행), fixed_step = 1~6 (UNIQUE)
  - trust_threshold = 1 × 2, 2 × 2, 3 × 2
- **수치 출처**: 페이즈 2 #4 (보상 곡선)
- **특수 요구**:
  - step 3 박쥐 둥지 소탕은 enemy_name = "거대 박쥐 둥지" 또는 elite_id 부여 검토 (M4 시점에 elite_monsters 추가 가능 여부는 페이즈 2 #4에서 결정)
  - step 6 폐광 재개방식은 sector_type=village로 설정 (마을 광장 무대) — 일반 quest_pools.sector_type='village' 12개 풀과 분리 (is_fixed=true)
- **검증**:
  - `(fixed_chain_id, fixed_step)` UNIQUE 제약 만족
  - trust_threshold 1~3 범위 (4 미사용 — 사건 완료 시 4단계 진입)
  - is_fixed=true 행은 일반 갱신 주기 노출 풀에서 제외되는지 SyncService 검증
