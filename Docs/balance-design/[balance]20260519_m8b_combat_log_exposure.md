# M8b 전투 로그 길이·수치 노출 기준 확정 밸런스 리포트

> 작성일: 2026-05-19
> 유형: 밸런스 분석 / 데이터 매트릭스 확정
> 분석 대상: M8b 보고서 라인 길이·노출 매트릭스 (M8a `combat_report_templates` 호환 확장)
> 선행 문서:
> - `Docs/content-design/[content]20260519_m8b_combat_turn_structure.md` (페이즈 1 #1) — §M8a 호환 §라운드 압축 정책
> - `Docs/content-design/[content]20260519_m8b_initiative_and_action_order.md` (페이즈 1 #2) — 결정적 장면 키워드
> - `Docs/content-design/[content]20260519_m8b_combat_formulas.md` (페이즈 1 #3) — §11 보고서 노출 정책
> - `Docs/content-design/[content]20260519_m8b_status_effects.md` (페이즈 1 #4) — §11 상태 효과 노출 정책 + 라벨
> - `Docs/balance-design/[balance]20260519_m8b_class_skills.md` (페이즈 2 #1) — §9 스킬별 라인 후보
> - `Docs/balance-design/[balance]20260519_m8b_enemy_types.md` (페이즈 2 #2) — §11·§13 적별 라인 후보
> - `Docs/balance-design/[balance]20260519_m8b_status_effect_values.md` (페이즈 2 #3) — §9 노출 매트릭스 11종
> - Supabase `combat_report_templates` (96행 — scope 7종 × line_type 2종) + `combat_report_keywords` (40행)
>
> 후속:
> - 페이즈 3 #4 전투 로그 템플릿 데이터 생성 (60~80 신규 행 → M8a 기존 96과 합쳐 156~176행, 권장 120~180 범위 안)
> - 페이즈 4 #4 전투 보고서 UI 확장 명세 (§7 노출/비노출 매트릭스 + §8 다중 결합 라인 우선순위)
> - 페이즈 4 #1 `CombatSimulator` 명세 (§9 보고서 라인 압축 알고리즘 입력)

## 개요

본 산출물은 페이즈 1·2의 노출 정책 단편들을 **단일 통합 매트릭스**로 결합하고, M8a `combat_report_templates` 96행 + `combat_report_keywords` 40행 호환 위에서 M8b 시뮬레이션 결과를 보고서로 압축하는 정책·우선순위·길이 매트릭스를 확정한다.

페이즈 2 #4는 M8b 페이즈 2의 마지막 산출물이다. 본 결정은 페이즈 3 #4 전투 로그 템플릿 데이터 생성과 페이즈 4 #4 UI 확장 명세의 입력이 된다. 페이즈 1·2의 모든 결정·산식·카탈로그 구조는 변경하지 않는다.

## 현재 상태 — M8a `combat_report_templates` 96행 분포 분석

### 1.1 M8a 테이블 스키마 (11 컬럼)

| 컬럼 | 타입 | 의미 |
|------|------|------|
| `id` | TEXT PK | 템플릿 ID |
| `group` | TEXT | 묶음 분류 |
| `scope` | TEXT | 7종 (chain_final/chain_step/elite/faction_named/quest_type/scene/settlement_event/unique_elite) |
| `faction_id` | TEXT | 세력 매칭 (faction_named scope만) |
| `quest_type` | TEXT | 의뢰 유형 매칭 |
| `result_type` | TEXT | 4종 (great_success/success/failure/critical_failure) |
| `line_type` | TEXT | 2종 (summary/detail) |
| `importance` | TEXT | 3종 (normal/high/veryHigh) |
| `weight` | INT | 가중 random (기본 100, 보조 85~95) |
| `template` | TEXT | 본문 (variables: `{merc.name}` / `{ally.name}` / `{enemy.name}` / `{region.name}`) |
| `tags_json` | JSONB | 보조 분류 메타 |

### 1.2 scope × line_type 96행 분포

| scope | summary | detail | 합계 | importance |
|-------|---------|--------|------|------------|
| `chain_final` | 4 | 0 | 4 | high (체인 최종 단계) |
| `chain_step` | 0 | 4 | 4 | high |
| `elite` | 0 | 8 | 8 | high |
| `faction_named` | 12 | 12 | 24 | normal·high (rep≥31 또는 isAdvancedTrack 시) |
| `quest_type` | 16 | 8 | 24 | normal |
| `scene` | 0 | 20 | 20 | (보충풀 — importance 미사용) |
| `settlement_event` | 0 | 4 | 4 | high |
| `unique_elite` | 4 | 4 | 8 | veryHigh |
| **합계** | **36** | **60** | **96** | — |

### 1.3 `combat_report_keywords` 40행 분포

| category | count | 활용 |
|----------|-------|------|
| `battlefield` | 12 | 진입(1줄) — 환경·진형 묘사 |
| `enemy` | 10 | 진입(1줄) — 적 첫 등장 묘사 |
| `decisive` | 12 | 위기(4~5줄)·해소(6~7줄) — 결정적 장면 |
| `injury` | 6 | 위기(4~5줄) — 부상 묘사 |

## 2. 라운드 수 → 보고서 길이 매핑 매트릭스

페이즈 1 #1 §라운드 권장 범위(3~6) + 페이즈 1 #1 §M8a 호환 라인 길이 매트릭스를 결합한다.

### 2.1 라운드 수 ↔ 보고서 길이 매핑

| 실제 라운드 수 | 요약 (summary) 문장 수 | 상세 (detail) 줄 수 | 분포 |
|--------------|--------------------|-----------------|------|
| 1 (즉결 — 선제 라운드만) | 2 | 4 | 매우 드묾 (페이즈 1 #1 §종료조건 (b)/(c) R0 발동) |
| 2~3 (단축) | 2 | 4 | 약 15% |
| 4 (평균 단축) | 3 | 5 | 약 25% |
| 5 (평균) | 3 | 6 | 약 30% |
| 6 (평균 상한) | 3 | 6 | 약 20% |
| 7 (장기) | 4 | 7 | 약 8% |
| 8 (상한 도달) | 4 | 8 | 약 2% (페이즈 1 #1 §종료 조건 (d)) |

### 2.2 길이 결정 트리

```text
function resolveSummaryCount(rounds, importance):
  base = (rounds <= 3) ? 2 : (rounds <= 6) ? 3 : 4
  // importance veryHigh는 +0 (요약은 톤만 — 길이 가산 없음)
  // importance high는 +0 (요약 길이는 라운드 수가 결정)
  return base   // 항상 2~4

function resolveDetailCount(rounds, importance):
  base = (rounds <= 3) ? 4 : (rounds <= 5) ? min(rounds + 1, 6) : min(rounds, 8)
  // importance veryHigh: +1 (8 상한 도달 시 미가산)
  // importance high: +0
  // importance normal: -0 (4 하한 유지)
  if (importance == 'veryHigh' && base < 8): base = base + 1
  return clamp(base, 4, 8)
```

### 2.3 scope 7종 × 길이 매트릭스

페이즈 1 #1 §M8a 호환·페이즈 2 #1 §1.2 자동 보유 정책 정합:

| scope | importance | summary | detail (라운드 4 / 5 / 6 / 7+) | 평균 detail | 비고 |
|-------|------------|---------|--------------------------|------------|------|
| `unique_elite` | veryHigh | 2~4 | 5 / 6 / 7 / 8 | **7줄** | 8줄 우선. 유니크 첫 처치는 결정적 장면 우선 |
| `chain_final` | veryHigh | 2~4 | 5 / 6 / 7 / 8 | **7줄** | unique_elite와 동급 importance |
| `chain_step` | high | 2~3 | 5 / 6 / 6 / 7 | **6줄** | |
| `settlement_event` | high | 2~3 | 5 / 6 / 6 / 7 | **6줄** | |
| `elite` | high | 2~3 | 5 / 6 / 6 / 7 | **6줄** | |
| `faction_named` (rep≥31 / advancedTrack) | high | 2~3 | 5 / 6 / 6 / 7 | **6줄** | M8a §평판 31 이상 정합 |
| `faction_named` (rep 11~30 일반) | normal | 2~3 | 4 / 5 / 6 / 6 | **5줄** | |
| `quest_type` (일반 의뢰 fallback) | normal | 2 | 4 / 5 / 6 / 6 | **5줄** | M8b 시뮬레이션 비대상 (`combatReportEligible`만) |

### 2.4 길이 분포 검증

본 매트릭스가 만드는 평균 보고서 길이 분포 (페이즈 1 #1 §라운드 권장 범위 정합):

- **요약**: 2~4 문장 (M8a §summary 길이 매트릭스 정합)
- **상세**: 4~8 줄 (M8a §detail 길이 매트릭스 정합)
- **평균 6 라운드 unique_elite 의뢰** → 요약 3 + 상세 7 = **총 10줄**
- **평균 5 라운드 elite 의뢰** → 요약 2~3 + 상세 6 = **총 8~9줄**
- **평균 4 라운드 faction_named 일반** → 요약 2 + 상세 5 = **총 7줄**

페이즈 1 #4 §11.3 비노출 정책 + 페이즈 1 #3 §11 결과만 노출 정책과 결합해 가독성·압축률 균형 보장.

## 3. 결정적 장면 5 위치 분류 매트릭스

페이즈 1 #1 §라운드 압축 정책에서 상세 라인 8줄을 5 위치(진입/전개/위기/해소/후일담)로 분류한다. M8a `combat_report_templates` 호환을 위해 5 위치를 `tags_json.position` 메타로 표현 (line_type 자체는 `detail` 그대로 유지).

### 3.1 5 위치 정의 + 라인 후보 출처

| 위치 | 위치 키 (tags_json.position) | 라인 후보 출처 | 권장 라인 수 |
|------|--------------------------|------------|-----------|
| 진입 | `entry` | 진형·사기·선제권·환경 (페이즈 1 #2 §2·§6·§7 / `combat_report_keywords` battlefield 12 + enemy 10) | 1 |
| 전개 | `development` | 일반 공격·광역·buff·debuff·정조준 (페이즈 2 #1 §9 + 페이즈 2 #2 §13) | 2~3 |
| 위기 | `crisis` | 부상·적 결정타·armor_break·taunt_roar·stunned (페이즈 2 #3 §9 + `injury` 6) | 1~2 |
| 해소 | `resolution` | 반격·방패·결정타·도주·사망 (페이즈 2 #1 §9 + `decisive` 12) | 1~2 |
| 후일담 | `aftermath` | 사기 평가·dispel·DoT 해제 (페이즈 1 #4 §11) | 0~1 |

### 3.2 보고서 길이별 5 위치 분포

| 보고서 길이 | 진입 | 전개 | 위기 | 해소 | 후일담 | 합계 |
|-----------|-----|-----|-----|-----|------|------|
| 4줄 (짧음) | 1 | 1 | 1 | 1 | 0 | 4 |
| 5줄 | 1 | 2 | 1 | 1 | 0 | 5 |
| 6줄 (평균) | 1 | 2 | 1 | 1 | 1 | 6 |
| 7줄 | 1 | 2 | 2 | 1 | 1 | 7 |
| 8줄 (최대) | 1 | 3 | 2 | 1 | 1 | 8 |

### 3.3 5 위치 결합 우선순위

| 우선순위 | 위치 | 근거 |
|---------|-----|------|
| 1 | 진입 1줄 (항상) | M8a §보고서 시작 톤 보장 |
| 2 | 해소 1줄 (항상) | 종료 조건 결과 텍스트 보장 |
| 3 | 위기 1줄 (4줄+ 보장) | 결정적 장면 톤 |
| 4 | 전개 1줄 (4줄+ 보장) | 일반 행동 톤 |
| 5 | 전개 2~3줄 (5줄+ 추가) | 라운드 수 비례 |
| 6 | 위기 2줄 (7줄+ 추가) | 부상자·결정타 |
| 7 | 후일담 1줄 (6줄+ 추가) | 사기·DoT 해제 |

페이즈 4 #1 `CombatSimulator` 명세의 보고서 압축 알고리즘 입력.

## 4. 노출/비노출 매트릭스 통합

페이즈 1 #3 §11 + 페이즈 1 #4 §11 + 페이즈 2 #3 §9 통합. 단일 진실의 원천.

### 4.1 노출 항목 (보고서에 정수/텍스트로 표시)

| 항목 | 형식 | 출처 |
|------|------|------|
| 단발 피해량 | 정수 (`"47의 피해"`) | 페이즈 1 #3 §11 |
| 치명타 발동 | 텍스트 + 정수 (`"치명타! 89"`) | 페이즈 1 #3 §11 |
| 회피 | 텍스트 (`"도적이 회피했다"`) | 페이즈 1 #3 §11 |
| 방패 막기 | 텍스트 + 감소율 % (`"방패로 막아 30% 감소"`) | 페이즈 1 #3 §11 |
| 반격 | 텍스트 + 피해 정수 (`"반격으로 15의 피해"`) | 페이즈 1 #3 §11 |
| 광역 대상 수 + 합계 피해 | 정수 (`"3명에게 총 65의 피해"`) | 페이즈 1 #3 §11 |
| 연속 횟수 + 합계 피해 | 정수 (`"3연타로 47"`) | 페이즈 1 #3 §11 |
| 상태 효과 부여 | 라벨 + 지속 턴 (`"출혈 3턴 부여"`) | 페이즈 1 #4 §11 |
| 상태 효과 자연 해제 | 라벨만 (`"독이 사라졌다"`) | 페이즈 1 #4 §11 |
| dispel 해제 | 시전자+대상+라벨 (`"신관이 도적의 강화를 풀었다"`) | 페이즈 1 #4 §11 |
| DoT 피해 적용 | 라벨 + 피해 정수 (`"출혈로 12 피해"`) | 페이즈 1 #4 §11 |
| DoT stack 증가 | 라벨 + stack 수 (`"출혈 2 스택"`) | 페이즈 1 #4 §11 |
| stunned 행동 스킵 | 텍스트 (`"기절해 행동하지 못했다"`) | 페이즈 1 #4 §11 |
| HP 비율 텍스트 | 간접 표현 (`"빈사"`, `"절반 이하"`, `"쓰러졌다"`) | 페이즈 1 #3 §11.1 |
| 부상자 발생 | 텍스트 (`"{merc.name}이 부상"`) | 페이즈 1 #3 §11 |
| 사망 발생 | 텍스트 (`"{merc.name}이 쓰러졌다"`) | 페이즈 1 #3 §11 |
| 진형 변화 (간접) | 텍스트 (`"적 전열이 갈라졌다"`) | 페이즈 1 #2 §7 |

### 4.2 비노출 항목 (보고서에 절대 표시 금지)

| 항목 | 비노출 근거 |
|------|-----------|
| 명중률 % | 페이즈 1 #3 §11.3 — 확률 노출 피로 방지 |
| 회피율 % | 페이즈 1 #3 §11.3 |
| 치명타율 % | 페이즈 1 #3 §11.3 |
| 사망 저항 % | 페이즈 1 #3 §11.3 |
| 반격 확률 % | 페이즈 1 #3 §11.3 |
| 방패 막기 발동 확률 % | 페이즈 1 #3 §11.3 |
| 상태 효과 intensity 수치 | 페이즈 1 #4 §11.3 (예: `+0.20` 비노출 → "공격력 강화" 텍스트만) |
| applyChance 발동 결과 | 페이즈 1 #4 §11.3 — 결과(부여 성공/실패)만 텍스트로 |
| stack 도달 확률 | 페이즈 1 #4 §11.3 |
| HP 절대값 | 페이즈 1 #3 §11.1 — 비율 텍스트만 |
| 진형 직접 명시 | 페이즈 1 #2 §7 — `entry` 위치 텍스트로만 간접 표현 |
| 행동 점수 (`actionScore`) | 페이즈 1 #2 §3 — 결정적 장면 라인에 간접 표현 |
| 선제 점수 (`sideInitiativeScore`) | 페이즈 1 #2 §2 |
| 시드 값 | 페이즈 1 #1 §결정성 — 디버그 빌드에서만 노출 |
| 산식 (HP=vit×coef 등) | 페이즈 1 #3 §11.3 |

### 4.3 노출/비노출 결정 트리

```text
function shouldExpose(metric):
  if (metric == 'damage' || metric == 'critDamage'): return true
  if (metric == 'evasion' || metric == 'shieldBlock' || metric == 'riposte'): return true  // 텍스트만
  if (metric == 'aoeTargets' || metric == 'multiHitCount'): return true
  if (metric == 'statusEffectLabel' || metric == 'statusEffectDuration'): return true
  if (metric == 'dotDamage' || metric == 'dotStack'): return true
  if (metric == 'injuryEvent' || metric == 'deathEvent'): return true
  if (metric.endsWith('Chance')): return false  // 명중·회피·치명타·반격·방패 확률
  if (metric.endsWith('Intensity')): return false  // 상태 효과 강도
  if (metric == 'hpAbsolute' || metric == 'actionScore' || metric == 'seed'): return false
  if (metric == 'formationSlot'): return false  // 간접 표현만
  return false  // 보수적 폴백
```

## 5. 페이즈 2 #1·#2·#3 라인 후보 종합

페이즈 2 #1 §9 + 페이즈 2 #2 §13 + 페이즈 2 #3 §9 + `combat_report_keywords` 40행을 통합 매트릭스화한다.

### 5.1 페이즈 2 #1 §9 스킬별 라인 후보 (50개)

10 스킬 × 5 위치 = 50 라인 후보. 페이즈 2 #1 §9.1 표에서 매트릭스화:

| 스킬 | entry | development | crisis | resolution | aftermath |
|------|-------|------------|--------|------------|-----------|
| `skill_warrior_shield_bulwark` | — | — | "{m}이 방패로 받아냈다. 피해 {N}% 감소" | — | — |
| `skill_warrior_battle_fury` | — | "{m}이 분노에 휩싸였다" | "{m}이 {enemy}에게 {N}의 피해 (강화)" | — | "{m}의 분노가 가라앉았다" |
| `skill_rogue_mass_blind` | — | "{m}이 적 전열에 연막. {N}명 약화" | — | — | — |
| `skill_ranger_marksman_focus` | — | "{m}이 호흡을 멈추고 조준했다" | — | "{m}의 치명타! {N}의 피해" | — |
| `skill_ranger_volley_shot` | — | "{m}의 3연사로 {N}의 피해" | — | "{m}의 마지막 사격이 {enemy}를 쓰러뜨렸다" | — |
| `skill_mage_arcane_blast` | — | "{m}의 마법이 {N}명을 휩쓸었다. 총 {합계}" | — | — | — |
| `skill_mage_stun_bolt` | — | — | "{m}의 마법이 {enemy}를 기절시켰다" | — | "기절한 {enemy}가 무기력하게 쓰러졌다" |
| `skill_support_aegis_aura` | "{m}의 오라가 아군을 감쌌다" | — | — | — | — |
| `skill_support_cleansing_word` | — | "{m}의 외침이 아군의 {효과}를 풀었다" | — | — | — |
| `skill_specialist_adaptive_footwork` | — | "{m}이 발밑을 고쳐 잡았다" | "{m}이 공격을 아슬아슬하게 피해냈다" | — | — |

총 50개 라인 후보 중 표에 명시된 18개 + 5 위치 × 직업군 × 결과 4종으로 확장한 나머지가 페이즈 3 #4에서 채워진다.

### 5.2 페이즈 2 #2 §11·§13 적별 라인 후보 (15개)

페이즈 2 #2 §13 표 8개 + §11.3 신규 키워드 5개 + `combat_report_keywords` enemy 10 통합 후 중복 제거 = 약 **15개 라인 후보** (적 전용).

추가로 페이즈 2 #2 §5 적 전용 6 스킬 × 5 위치 = 약 30 라인 후보. 합계 약 **45 라인 후보** (적 측).

### 5.3 페이즈 2 #3 §9 상태 효과 노출 텍스트 (11종 × 위치)

11종 노출 텍스트(buff 4 부여·해제·DoT 부여·DoT stack·DoT 피해·mez 부여·mez 행동 스킵·dispel 해제) 각각 2~3개 변형 = 약 **30 라인 후보**.

### 5.4 `combat_report_keywords` 40행 활용

| category | 활용 위치 | 사용 패턴 |
|----------|---------|---------|
| `battlefield` (12) | entry | `{region.name}` + `{key.display_text}` 결합 ("먼지 낀 광장에서 {enemy.name}이 모습을 드러냈다") |
| `enemy` (10) | entry | `{key.display_text}` 직접 사용 ("도굴꾼 대장이 다시 열린 폐광 입구에 등장했다") |
| `decisive` (12) | crisis / resolution | 라인 끝에 톤 가산 ("{decisive.key.display_text}") |
| `injury` (6) | crisis | "{merc.name}이 {key.display_text}" |

### 5.5 총 라인 풀 분포 권고 (페이즈 3 #4 입력)

| 출처 | 분량 | 합계 |
|------|------|------|
| 페이즈 2 #1 §9 파티 측 스킬 라인 (10 스킬 × 5 위치) | 50 | |
| 페이즈 2 #2 §13 적 측 일반 라인 + §5 적 전용 스킬 6개 × 5 위치 | 45 | |
| 페이즈 2 #3 §9 상태 효과 11 노출 텍스트 × 변형 2~3개 | 30 | |
| 5 위치 환경·진입 라인 (region × 의뢰 유형 매트릭스) | 20 | |
| 후일담 사기·승리·패배 라인 | 10 | |
| **신규 총합** | | **155** |
| M8a 기존 96행 보존 | | 96 |
| **페이즈 3 #4 최종 풀** | | **약 246** (권장 120~180 상한 초과 — §10 분할 정책) |

**중요**: 총합 246은 권장 상한 180을 초과한다. §10에서 분할 정책을 명시한다.

## 6. 가독성 검증

### 6.1 라운드 6~30 액션 → 4~8줄 압축 검증

평균 6 라운드 전투 시 발생하는 액션 개수:

| 라운드 구성 | 액션 수 |
|-----------|--------|
| 파티 5명 × 6 라운드 | 30 |
| 적 4명 × 6 라운드 | 24 |
| `extraAction` 가산 (battle_fury 등) | +1~3 |
| 반격 가산 | +0~5 |
| 합계 | 55~62 |

55~62 액션을 6줄 상세에 압축 → 라운드당 평균 9~10 액션 중 1~1.5 라인만 표시. **압축률 90%**.

압축 정책:
- 동일 라운드 내 1순위 행동(가장 큰 피해 / 결정적 장면)만 표시
- 일반 공격 N회는 누적 피해 1줄로 압축 ("R3에서 적 3명을 합 47의 피해로 압박했다")
- 회피·방패·반격은 발동 시점에만 표시
- 상태 효과 부여는 첫 부여만 표시 (refresh는 비표시)
- DoT 피해는 stack 변화 또는 결정적 라운드만 표시

### 6.2 중복 라인 회피 정책

한 보고서 안에서:
- 동일 `combat_report_templates.id` 1회만 사용
- 동일 `combat_report_keywords.id` 1회만 사용
- 동일 변수 패턴 (예: `{merc.name}이 치명타`) 라운드 2회 이상 시 두 번째부터 변형 라인 또는 `combat_report_keywords.decisive` 톤 가산만 사용
- protagonist 1명에 라인 3개 이상 배정 (모든 라인을 1명이 가져가지 않도록 후속 우선순위)

### 6.3 protagonist/featured 라인 우선순위

페이즈 1 #1 §featured/protagonist 일관성 정합:

| 우선순위 | 라인 후보 |
|---------|---------|
| 1 (필수) | 진입 1줄 — `{region.name}` + `{enemy.name}` 첫 등장 (protagonist 미언급 가능) |
| 2 (필수) | 해소 1줄 — protagonist의 결정타 또는 종료 조건 매핑 ("김철수가 도적 대장을 쓰러뜨렸다") |
| 3 | 위기 1줄 — 부상자 또는 protagonist의 위기 ("박영희가 부상") |
| 4 | 전개 1~2줄 — protagonist의 첫 결정적 행동 + 1순위 featured 1명 |
| 5 | 위기·해소 추가 — featured 2~3명의 결정적 장면 |
| 6 | 후일담 1줄 — protagonist의 후일담 또는 사기 평가 |

protagonist는 보고서에 평균 **2~3 라인** 등장. featured 1순위는 **1~2 라인**. featured 2~3순위는 **0~1 라인**.

### 6.4 톤 키워드 분포 (`combat_report_keywords` decisive 12 + tags_json mood)

`combat_report_keywords` decisive 12행은 위기·해소 위치에 라인 끝 톤 가산으로 사용한다.

| decisive key | 매핑 결정적 장면 | 활용 빈도 |
|------------|-------------|---------|
| `shield_opens_path` | 방패 막기 결정타 | warrior 위주 |
| `backline_cut` | 후열 침투 | rogue 위주 |
| `protagonist_last_step` | 빈사 protagonist 생존 | 부상 위기 |
| `cart_saved` | 호위 의뢰 결정 | escort 매칭 |
| `map_corrected` | 탐험 의뢰 결정 | explore 매칭 |
| `seal_recovered` | 회수 의뢰 결정 | escort 매칭 |
| `duel_mark_pressed` | 결투 결정 | faction_named 매칭 |
| `retreat_controlled` | 도주 매칭 (종료 조건 e) | failure 결과 |
| `second_ambush_failed` | 매복 후속 차단 | ambush 의뢰 |
| `enemy_weakness_seen` | 적 약점 노출 | elite 매칭 |
| `signal_late` | 후퇴 신호 늦음 | failure/critical |
| `formation_split` | 전열 와해 | critical_failure |

각 보고서당 1~2 decisive 키워드만 사용 (`weight` 가중 random).

## 7. scope 7종 × 길이·강도 차등 매트릭스

페이즈 2 #1 §1.3 / 페이즈 2 #2 §10·§11 / 페이즈 1 #1 §M8a 호환 §라인 매트릭스 정합.

### 7.1 scope별 차등 정책

| scope | importance | summary | detail | decisive 키워드 사용 | injury 키워드 사용 |
|-------|-----------|---------|--------|------------------|----------------|
| `unique_elite` | veryHigh | 3~4 | 7~8 | 2~3 | 1~2 |
| `chain_final` | veryHigh | 3~4 | 7~8 | 2 | 1 |
| `chain_step` | high | 2~3 | 6~7 | 1~2 | 1 |
| `settlement_event` | high | 2~3 | 6 | 1~2 | 0~1 |
| `elite` | high | 2~3 | 6~7 | 1~2 | 1 |
| `faction_named` (advanced) | high | 2~3 | 6 | 1~2 | 1 |
| `faction_named` (basic) | normal | 2 | 4~5 | 1 | 0~1 |
| `quest_type` (fallback) | normal | 2 | 4~5 | 0~1 | 0 |

### 7.2 결정성 강조 정책 (페이즈 1 #1 §결정성)

scope `unique_elite` / `chain_final`은 결정적 장면 라인을 최대화한다.
- `unique_elite` 8줄 상세 → 1+3+2+1+1 분포 (entry 1 / development 3 / crisis 2 / resolution 1 / aftermath 1)
- `chain_final` 8줄 상세 → 동일 분포
- 두 scope 모두 detail 끝줄에 `decisive` 키워드 또는 후일담 사기 평가 추가 권장

### 7.3 scope `scene` 보충풀 활용

M8a `scene` scope 20행은 모든 scope의 detail 라인 후보로 fallback 보충풀. 매핑 우선순위:
- scope 우선 라인 풀이 부족할 때만 `scene`에서 추출
- M8b 시뮬레이션 결과 `featured` 미발견 시 scene에서 사용
- 페이즈 2 #1 §6 콤보 패턴 미실행 시 scene 보충

## 8. 다중 결합 라인 우선순위

한 라운드에 결정적 장면 2개 이상 발생 시 라인 1개로 압축하는 정책.

### 8.1 다중 결합 케이스

| 동시 결정적 장면 | 라인 압축 정책 |
|---------------|--------------|
| 치명타 + 적 사망 (R3 일격 결정타) | "{m}의 치명타가 {enemy}를 쓰러뜨렸다" (1줄로 압축) |
| 광역 + 광역 결과 부상 | "{m}의 광역이 {N}명을 휩쓸어 {ally}가 부상" (1줄로 압축) |
| 방패 + 반격 | "{m}이 방패로 막고 {N}의 반격" (1줄로 압축) |
| 회피 + 반격 | "{m}이 회피하며 {N}의 반격" (1줄로 압축) |
| DoT stack + DoT 피해 | "{m}의 출혈이 2 스택. {N}의 피해" (1줄로 압축) |
| stunned 발동 + 적 행동 스킵 | "{m}의 마법으로 {enemy}이 기절해 행동 불가" (1줄로 압축) |
| dispel + 상태 효과 해제 | "{m}이 아군의 {효과}를 풀었다" (1줄로 압축) |

### 8.2 페이즈 2 #1 §6 콤보 패턴 4종 압축

| 콤보 | 압축 라인 |
|------|--------|
| ranger 정조준 → 연속 사격 (R1+R2) | "{m}이 호흡 조준 후 3연사로 {N}의 피해" (1줄 압축, 2 라운드 묶음) |
| rogue mass_blind → warrior 반격 (R1+R2) | "연막 속에서 {warrior}의 반격이 적을 흩뜨렸다" (1줄 압축) |
| mage arcane_blast → stun_bolt (R1+R2) | "{mage}의 마법이 {N}명을 휩쓸고 {boss}를 기절시켰다" (1줄 압축) |
| support aegis_aura → mage arcane_blast (R1+R2) | "오라 아래 {mage}의 마법이 안전하게 펼쳐졌다" (1줄 압축) |

### 8.3 다중 결합 라인 우선순위 결정 트리

```text
function selectLineForRound(actions, position):
  // 우선순위 1: 사망 이벤트 (필수)
  if (actions.any(a => a.type == 'kill')):
    return formatKillLine(actions)
  
  // 우선순위 2: 부상 이벤트 (필수)
  if (actions.any(a => a.type == 'injure')):
    return formatInjuryLine(actions)
  
  // 우선순위 3: 광역 액션 (대상 N명)
  if (actions.any(a => a.aoeTargets >= 2)):
    return formatAoeLine(actions, mergeDamageTotal=true)
  
  // 우선순위 4: 결정적 장면 (치명타·반격·방패·연속)
  if (actions.any(a => a.isDecisive)):
    return formatDecisiveLine(actions, addToneKeyword=true)
  
  // 우선순위 5: 상태 효과 부여 (mez·dot·armor_break 등)
  if (actions.any(a => a.appliesStatusEffect)):
    return formatStatusLine(actions)
  
  // 폴백: 가장 큰 피해 액션
  return formatDamageLine(actions.maxBy(a => a.damage))
```

## 9. 페이즈 3 #4 입력 매트릭스

페이즈 3 #4 전투 로그 템플릿 데이터 생성의 분포 권고.

### 9.1 신규 라인 풀 60~80행 권장 (M8a 기존 96 + 신규 = 156~176, 권장 120~180 안)

§5.5에서 분량 합계 155를 산출했으나 권장 상한 180을 보존하기 위해 다음 정책을 채택:

| 출처 | 권장 분량 | 누락 처리 |
|------|----------|----------|
| 페이즈 2 #1 §9 파티 측 스킬 라인 | **30** (50→30으로 축약) | 스킬 5종 × 5 위치 + 콤보 압축 5개. 나머지는 `scene` 보충풀 활용 |
| 페이즈 2 #2 §13 적 측 일반 + §5 적 전용 스킬 | **20** (45→20) | 적 6 신규 스킬 중 MVP 핵심 5종 우선 + scope `elite`/`unique_elite` 확장 |
| 페이즈 2 #3 §9 상태 효과 텍스트 | **15** (30→15) | 11 노출 텍스트 + DoT 강조 4 |
| 5 위치 환경·진입 라인 | **10** (20→10) | M7 7리전 × 2 변형 |
| 후일담 사기 라인 | **5** (10→5) | result_type 4 × 변형 |
| **신규 합계** | **80** | M8a 기존 96 + 80 = **176행** (권장 180 안) |

### 9.2 scope별 신규 행 분포

| scope | M8a 기존 | M8b 신규 | 합계 | 권장 분포 |
|-------|---------|---------|------|---------|
| `chain_final` | 4 (summary) | 4 (detail) | 8 | 8 |
| `chain_step` | 4 (detail) | 4 (summary) | 8 | 8 |
| `elite` | 8 (detail) | 8 (summary 4 + detail 4) | 16 | 16 |
| `faction_named` | 24 | 8 (advanced 4 + basic 4) | 32 | 32 |
| `quest_type` | 24 | 4 (detail 추가) | 28 | 28 |
| `scene` | 20 | 20 (M8b 5 위치 보충풀 확장) | 40 | 40 |
| `settlement_event` | 4 (detail) | 4 (summary 추가) | 8 | 8 |
| `unique_elite` | 8 | 8 (detail 8 추가) | 16 | 16 |
| `combat_skill` (신규 scope) | 0 | 20 (페이즈 2 #1 스킬 라인) | 20 | 20 |
| **합계** | **96** | **80** | **176** | — |

**중요**: 신규 scope `combat_skill` 도입. M8a `combat_report_templates.scope` CHECK 제약 확장 (페이즈 4 #2 데이터 모델에서 확정).

### 9.3 신규 컬럼 후보 (M8a 호환)

M8a `combat_report_templates` 11 컬럼 보존. M8b 추가 메타는 `tags_json`에 영속화:

```json
{
  "position": "entry|development|crisis|resolution|aftermath",  // M8b §3 5 위치
  "skill_id": "skill_warrior_battle_fury",                       // 페이즈 2 #1 스킬 매칭
  "status_effect_id": "buff_attack_up",                          // 페이즈 1 #4 상태 효과 매칭
  "behavior_pattern": "berserker",                               // 페이즈 2 #2 §8 behaviorPattern 매칭
  "decisive_keyword_key": "shield_opens_path",                   // combat_report_keywords decisive 매칭
  "is_combo_compression": true                                    // §8.2 콤보 압축 라인 여부
}
```

기존 M8a 96행은 `tags_json`에 이 필드가 부재해도 fallback 작동 (페이즈 4 #1 시뮬레이터 명세에서 보장).

### 9.4 페이즈 3 #4 data-generator 가이드

- **대상 타입**: `combat-log-template` (신규 타입 스펙 작성 필요 — `types/combat-log-template.md`)
- **대상 테이블**: `combat_report_templates` (M8a 기존, M8b 80행 INSERT)
- **생성 수량**: 80행
- **외래 키 제약**:
  - `scope` ∈ {chain_final, chain_step, elite, faction_named, quest_type, scene, settlement_event, unique_elite, **combat_skill**} (M8b 신규 scope 추가)
  - `result_type` ∈ {great_success, success, failure, critical_failure}
  - `line_type` ∈ {summary, detail}
  - `importance` ∈ {normal, high, veryHigh}
  - `tags_json.skill_id` REFERENCES combat_skills(id) (페이즈 3 #2 의존)
  - `tags_json.status_effect_id` REFERENCES combat_status_effects(id) (페이즈 3 #3 의존)
  - `tags_json.decisive_keyword_key` REFERENCES combat_report_keywords(key) WHERE category='decisive'
- **수치 범위**: weight 80~100 (기본 100, 보조 90, 변형 85)
- **balance 근거**: §2.3 scope별 길이 매트릭스 + §6 가독성 검증 + §7 scope 차등 정책

## 10. 라인 풀 분할 정책 (§5.5 246 → §9.1 176 축약)

§5.5 산출 총합 246이 권장 상한 180을 초과하므로 분할 정책을 채택한다.

### 10.1 M8b 페이즈 3 #4 MVP: 80 신규 행

§9.1 정책에 따라 80행만 페이즈 3 #4 시드. 핵심 매트릭스 커버.

### 10.2 후속 확장 후보: 70 추가 행

| 후속 마일스톤 | 라인 풀 확장 후보 | 권장 시점 |
|------------|----------------|---------|
| M8.5 (전투 보고서 영상화) | 추가 50행 — 콤보 압축 변형·protagonist 다양성 | M8b 출시 후 |
| M9 (대규모 컨텐츠) | 추가 70행 — 신규 적 풀 + 신규 세력 매칭 + DoT 강조 | M8b 검증 후 |

후속 확장은 본 산출물 외 범위. 페이즈 3 #4 MVP는 80행으로 시작.

### 10.3 라인 풀 활용 우선순위

| 보고서 생성 단계 | 우선순위 |
|---------------|--------|
| 1 | scope 직접 매칭 라인 (예: unique_elite scope 16행 중 result_type 매칭) |
| 2 | scope 보충풀 (`scene` 40행) |
| 3 | importance 매칭 fallback (예: unique_elite veryHigh fail → chain_final veryHigh) |
| 4 | result_type 일반 fallback (예: critical_failure → failure 라인) |

페이즈 4 #1 `CombatSimulator` 명세의 보고서 라인 선택 알고리즘 입력.

## 11. 보고서 라인 예시 종합

### 11.1 6 라운드 unique_elite 의뢰 (검은 마녀 모르간)

**요약 (3문장)**:
> 검은 마녀의 마법이 두 번 폭발했지만 김철수의 방패가 길을 열었다.
> 박영희의 정조준 사격이 마지막을 결정지었다.
> 강적의 약점이 드러났다.

**상세 (7줄)**:
1. **[entry]** 부서진 요새 성벽에서 검은 마녀가 모습을 드러냈다.
2. **[development]** 김철수가 분노에 휩싸였다. 공격력 강화 3턴.
3. **[development]** 검은 마녀의 마법이 3명을 휩쓸었다. 총 89의 피해.
4. **[development]** 박영희가 호흡을 멈추고 조준했다. 명중·치명타 강화.
5. **[crisis]** 검은 마녀가 박영희를 기절시켰다. 행동 불가 1턴.
6. **[resolution]** 박영희의 치명타! 132의 피해. 검은 마녀가 쓰러졌다.
7. **[aftermath]** 강적의 약점이 드러났다.

### 11.2 4 라운드 faction_named (basic) 의뢰 (상인 연합 매복 호위)

**요약 (2문장)**:
> 수레는 제시간보다 먼저 도착했고 봉인은 끝까지 뜯기지 않았다.
> 봉인이 온전하게 회수됐다.

**상세 (5줄)**:
1. **[entry]** 바퀴 자국 남은 도적길에서 도적 잔당이 매복했다.
2. **[development]** 김철수가 도적 두목에게 47의 피해.
3. **[crisis]** 도적 암살자가 박영희에게 더러운 칼날. 출혈 부여.
4. **[resolution]** 김철수가 방패로 막아 30% 감소. 반격으로 15의 피해.
5. **[aftermath]** 박영희의 출혈이 사라졌다.

### 11.3 8 라운드 chain_final 의뢰 (R8 라운드 한계 도달, critical_failure)

**요약 (4문장)**:
> 마지막 표식은 닫히지 않았고 후일담 대신 손실 명단이 남았다.
> 후퇴 신호가 늦었다.
> 늪지 사령관의 포효 앞에서 전열이 무너졌다.
> 신호가 늦게 닿았다.

**상세 (8줄)**:
1. **[entry]** 회색 늪지 안개 속에서 늪지 사령관이 모습을 드러냈다.
2. **[development]** 늪지 사령관의 포효에 파티 3명이 위축됐다. 공격력 약화 2턴.
3. **[development]** 박영희의 마법이 광역으로 65의 피해.
4. **[development]** 김철수가 거대 망치로 갑옷이 깨졌다. 방어력 약화 3턴.
5. **[crisis]** 박영희가 출혈로 8 피해. 무릎이 꺾였다.
6. **[crisis]** 김철수가 부상.
7. **[resolution]** 후퇴가 질서를 유지하지 못했다.
8. **[aftermath]** 전열이 갈라졌다.

## 12. 페이즈 4 #4 UI 확장 명세 입력

페이즈 4 #4가 활용할 UI 정책:

### 12.1 노출 매트릭스 정합

페이즈 4 #4 `QuestResultDialog` 확장 시 §4 노출/비노출 매트릭스를 그대로 적용. 추가 노출 항목 없음.

### 12.2 보고서 라인 표시 정책

- 요약 라인: result_type 색상 헤더 (great=초록 / success=파랑 / failure=주황 / critical=빨강)
- 상세 라인: 위치별 색상 구분 (entry=회색 / development=흰색 / crisis=노랑 / resolution=금색 / aftermath=회색)
- decisive 키워드 배지: 라인 끝 우측 배지 형태 (선택)
- protagonist 라인: bold 또는 좌측 보더 강조
- featured 라인: 동일 mercenary 라인 그룹화 옵션

### 12.3 인라인 전환 호환

M8a 페이즈 4 #2 `QuestResultDialog` 인라인 상세 전환(150ms `AnimatedSwitcher`) 보존. M8b는 동일 인터랙션 위에서 확장된 detail 라인을 표시.

## 13. 현재 시스템과의 연관

| 시스템 | 영향 | 처리 방식 |
|--------|------|----------|
| M8a `combat_report_templates` (96행) | M8b 80행 신규 INSERT (총 176행) | 기존 96행 보존, scope CHECK 확장 |
| M8a `combat_report_keywords` (40행) | 위치별 활용 매트릭스 | 변경 없음 |
| 페이즈 1 #1·#3·#4 노출 정책 | §4 통합 매트릭스로 단일화 | 정책 자체 변경 없음 |
| 페이즈 2 #1 §9 / 페이즈 2 #2 §13 / 페이즈 2 #3 §9 | §5 라인 후보 종합 | 출처 분량 그대로 |
| 페이즈 1 #2 §7 진형 | §4 진형 직접 명시 비노출 정책 | 변경 없음 |
| `CombatReportService.generate` (M8a) | 페이즈 4 #1 `CombatSimulator` 결과를 입력으로 받음 | M8a 호환 + simulationResult 비null 분기 |
| 페이즈 4 #1 `CombatSimulator` 명세 | §3.3 5 위치 결합 우선순위 + §8 다중 결합 라인 우선순위 | 페이즈 4 #1 입력 |
| 페이즈 4 #4 UI 확장 명세 | §4 노출 매트릭스 + §12 표시 정책 | 페이즈 4 #4 입력 |

## 14. 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|----------|------|------|
| 높음 | §2 라운드 수 ↔ 보고서 길이 매트릭스 | 페이즈 4 #1 보고서 생성의 핵심 입력 |
| 높음 | §3 5 위치 분류 + `tags_json.position` 메타 | 라인 풀 구조의 기반 |
| 높음 | §4 노출/비노출 매트릭스 통합 | 페이즈 1 #3·#4 정책 단일화 |
| 높음 | §7 scope 7종 차등 길이·강도 | unique_elite·chain_final 8줄 우선 |
| 높음 | §8 다중 결합 라인 압축 정책 | 라운드 6~30 액션 → 4~8줄 압축 |
| 중간 | §6.3 protagonist/featured 라인 우선순위 | 가독성·보고서 호흡 |
| 중간 | §9 신규 80행 분포 + scope `combat_skill` 추가 | 페이즈 3 #4 데이터 생성 입력 |
| 중간 | §6.4 톤 키워드 분포 (decisive 12 + tags_json) | M8a 호환 |
| 낮음 | §10 후속 확장 70행 (M8.5/M9 위임) | MVP 후순위 |
| 낮음 | §12 UI 표시 색상·배지 정책 | 페이즈 4 #4 UI 명세 시 정합 |

## 15. data-generator 수치 가이드

페이즈 3 #4에서 `combat_report_templates`에 본 산출물 80행을 추가 INSERT한다.

- **대상 타입**: `combat-log-template` (신규 타입 스펙 작성 필요)
- **대상 테이블**: `combat_report_templates` (M8a 기존 96행 + M8b 80행 = 176행)
- **수치 범위**:
  - `scope` ∈ {chain_final, chain_step, elite, faction_named, quest_type, scene, settlement_event, unique_elite, combat_skill} — combat_skill 신규
  - `result_type` ∈ {great_success, success, failure, critical_failure}
  - `line_type` ∈ {summary, detail}
  - `importance` ∈ {normal, high, veryHigh}
  - `weight` ∈ [80, 100]
- **외래 키 제약**:
  - `tags_json.skill_id` REFERENCES combat_skills(id) (페이즈 3 #2 의존)
  - `tags_json.status_effect_id` REFERENCES combat_status_effects(id) (페이즈 3 #3 의존)
  - `tags_json.decisive_keyword_key` REFERENCES combat_report_keywords(key) WHERE category='decisive'
  - `tags_json.position` ∈ {entry, development, crisis, resolution, aftermath}
- **분포 권고**: §9.2 scope별 신규 행 분포 표 + §9.1 출처별 권장 분량
- **balance 근거**: §2 라운드 수 ↔ 길이 + §6 가독성 검증 + §7 scope 차등 + §8 다중 결합 우선순위

페이즈 3 시작 시점에 (a) `types/combat-log-template.md` 타입 스펙 우선 작성 또는 (b) 본 산출물을 입력으로 SQL/수동 INSERT 80행 병행을 결정한다.

## 16. 페이즈 3·4 입력 요약

| 후속 산출물 | 본 산출물의 입력 기여 |
|-----------|---------------------|
| 페이즈 3 #4 전투 로그 템플릿 80행 | §9 신규 행 분포 + §9.3 tags_json 메타 + §9.4 data-generator 가이드 |
| 페이즈 4 #1 `CombatSimulator` 명세 | §3.3 5 위치 결합 우선순위 + §8 다중 결합 라인 우선순위 + §6.3 protagonist 우선순위 |
| 페이즈 4 #2 `CombatReport` 모델 확장 | tags_json 메타 5 필드 + scope `combat_skill` 추가 |
| 페이즈 4 #4 UI 확장 명세 | §4 노출 매트릭스 + §12 표시 정책 + §11 라인 예시 |
| 페이즈 4 #5 검증 명세 | §2 라운드 수 분포 검증 + §6 가독성 검증 + §10 라인 풀 활용 분석 |

## 17. 다음 단계 — 페이즈 2 완료

본 산출물로 페이즈 2(직업군 스킬·적 유형 설계) 4개 산출물이 모두 완료된다.

**페이즈 2 종료 체크포인트로 이동**:
- 페이즈 2 #1 직업군 대표 스킬 10종 (`[balance]20260519_m8b_class_skills.md`)
- 페이즈 2 #2 적 유형 26종 + 적 전용 6 신규 스킬 (`[balance]20260519_m8b_enemy_types.md`)
- 페이즈 2 #3 상태 효과 default 수치 10행 (`[balance]20260519_m8b_status_effect_values.md`)
- 페이즈 2 #4 전투 로그 길이·노출 매트릭스 (본 산출물)

**다음 페이즈 (페이즈 3 데이터 생성)** 미리보기:
- 페이즈 3 #1 enemies 26행 (`Docs/content-data/`)
- 페이즈 3 #2 combat_skills 16행 (파티 10 + 적 전용 6)
- 페이즈 3 #3 combat_status_effects 10행
- 페이즈 3 #4 combat_report_templates 80행 추가 INSERT

페이즈 3 시작 시점에 타입 스펙 4종(`types/enemy.md`/`types/combat-skill.md`/`types/status-effect.md`/`types/combat-log-template.md`) 부재 여부 확인 → 우선 작성 또는 SQL/수동 데이터 생성 병행 결정.

페이즈 4(개발 명세) 미리보기:
- 페이즈 4 #1 `CombatSimulator` 순수 서비스 명세 (본 산출물 §3·§8 입력)
- 페이즈 4 #2 신규 모델 5종 명세 (`CombatantSnapshot`/`CombatTurn`/`CombatAction`/`CombatStatusEffect`/`CombatReport` 확장)
- 페이즈 4 #3 `QuestCompletionService` 통합 명세 (페이즈 1 #1 §combatSimulationEligible 분기)
- 페이즈 4 #4 전투 보고서 UI 확장 명세 (본 산출물 §4·§12 입력)
- 페이즈 4 #5 검증 및 밸런스 명세 (본 산출물 §6·§10 입력)
