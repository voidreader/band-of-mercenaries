# 스탯 체계 재설계 개발 명세서

> 기획 문서: Docs/balance-design/20260414_stat-system-redesign.md
> 작성일: 2026-04-14
> 담당자: radiogaga

---

## 1. 개요

용병 스탯 체계를 ATK/DEF/HP/speed(4종)에서 STR/INTELLIGENCE/VIT/AGI(4종)로 재설계한다.
현재 DEF·HP는 게임 로직에 기여하지 않는 유령 스탯이며, partyPower가 ATK 합산만으로 계산되는 문제를 해결한다.
신규 4스탯은 퀘스트 유형별 가중치 기반 partyPower 공식으로 역할을 분화한다.

---

## 2. 요구사항

### 2.1 기능 요구사항

- **[FR-1] 4스탯 체계 전환**
  - 기존 스탯 (ATK/DEF/HP/speed)를 신규 스탯 (STR/INTELLIGENCE/VIT/AGI)으로 교체
  - 각 스탯의 역할:
    - `str`: 기본 공격력 — 직업 무관 전 용병의 근간 스탯
    - `intelligence`: 스킬 공격력 + 스킬 사용 횟수 (현재는 성공률 가중치에만 반영, 스킬 시스템은 추후 도입)
    - `vit`: 체력 + 방어력 통합 — 부상률/사망률 관련 기여
    - `agi`: 이동속도 + 회피 + 스킬 쿨타임 감소 (현재는 이동 시간 + 성공률 가중치에만 반영)
  - 각 직업의 주력 스탯: STR형(전사/검사), INT형(마법사/사제/드루이드/바드), VIT형(기사/방패병), AGI형(암살자/정찰병/궁수)

- **[FR-2] 퀘스트 유형별 partyPower 가중치 공식**
  - 기존: `partyPower = Σ(effectiveAtk)`
  - 신규: `partyPower = Σ(str×w_str + intelligence×w_int + vit×w_vit + agi×w_agi)`
  - 퀘스트 유형별 가중치:

  | questTypeId | STR | INTELLIGENCE | VIT | AGI |
  |-------------|-----|-------------|-----|-----|
  | `raid`      | 0.70 | 0.10 | 0.10 | 0.10 |
  | `hunt`      | 0.50 | 0.10 | 0.10 | 0.30 |
  | `escort`    | 0.20 | 0.10 | 0.60 | 0.10 |
  | `explore`   | 0.10 | 0.45 | 0.15 | 0.30 |

- **[FR-3] 기존 용병 데이터 일회성 마이그레이션**
  - 앱 초기화 시 `mercenaries` + `quests` Hive 박스를 비워 구 스탯 데이터와의 충돌 방지
  - HiveInitializer.initialize() 에서 박스 열기 전 삭제 후 재생성
  - **일회성 실행**: `settings` 박스에 `stat_migration_v2` 플래그를 확인하여, 플래그가 없을 때만 삭제 실행 후 플래그 기록. 이후 실행에서는 건너뜀

- **[FR-4] 신규 스탯 기반 용병 생성**
  - 모집 시 Job의 `baseStr/baseIntelligence/baseVit/baseAgi`에서 초기값 복사
  - 이동 시간 계산: 기존 `speed` 필드 → `agi` 기반 공식으로 변환
    - `speedMultiplier = agi / 50.0` (AGI 50 → 속도 1.0x 기준)

- **[FR-5] effective 스탯 getter**
  - 레벨 보너스 + 피로 디버프 패턴은 기존과 동일하게 유지
  - `effectiveStr`, `effectiveIntelligence`, `effectiveVit`, `effectiveAgi` 4개 getter 신설
  - 기존 `effectiveAtk`, `effectiveDef`, `effectiveHp` getter 제거

- **[FR-6] 홈 화면 총전투력 표시 업데이트**
  - `home_screen.dart:393` `totalPower`: `effectiveAtk` → `effectiveStr` 로 변경
  - 총전투력은 STR 합산으로 유지 (퀘스트 가중치 미적용, 단순 지표)

- **[FR-7] 용병 카드 및 상세 화면 스탯 표시 업데이트**
  - 용병 카드: `ATK·DEF·HP` → `STR·INT·VIT·AGI` 4종 표시로 변경
  - 용병 상세 오버레이: 4스탯 칩으로 교체, `speed` 칩 제거

### 2.2 데이터 요구사항

- **Supabase jobs 테이블 컬럼 변경**
  - 삭제: `base_atk`, `base_def`, `base_hp`, `speed`
  - 추가: `base_str` (int), `base_intelligence` (int), `base_vit` (int), `base_agi` (int)
  - 85개 직업 데이터 전체 재입력 필요 (operation-bom에서 수행)

- **Hive `mercenaries` 박스 — Mercenary 모델 필드 변경**

  | HiveField | 기존 | 신규 | 타입 변경 |
  |-----------|------|------|---------|
  | 4 | `int atk` | `int str` | 없음 |
  | 5 | `int def` | `int intelligence` | 없음 |
  | 6 | `int hp` | `int vit` | 없음 |
  | 7 | `double speed` | `int agi` | **double → int** |

  HiveField 번호 유지, 필드명·타입만 변경. 기존 저장 데이터는 초기화로 처리.

- **Job 모델 (freezed) 필드 변경**
  - 삭제: `baseAtk`, `baseDef`, `baseHp`, `speed`
  - 추가: `baseStr`, `baseIntelligence`, `baseVit`, `baseAgi`
  - JsonKey: `base_str`, `base_intelligence`, `base_vit`, `base_agi`

- **AGI → 이동속도 변환 수치**
  - 기준: AGI 50 = speed 1.0x
  - 공식: `speedMultiplier = agi / 50.0`
  - 기존 speed 0.76~1.39 범위 → AGI 38~70 범위

- **퀘스트 유형별 가중치 상수**
  - `quest_calculator.dart`에 `Map<String, Map<String, double>>` 상수로 추가

### 2.3 UI 요구사항

- 용병 카드 (`mercenary_card.dart:127`): 한 줄 요약 `STR X · INT X · VIT X · AGI X`
- 용병 상세 오버레이 (`mercenary_detail_overlay.dart:299-305`): 4개 칩으로 교체
  - 라벨: `STR`, `INT`, `VIT`, `AGI`
  - 값: 각 effective 스탯 값

---

## 3. 영향 범위

### 3.1 수정 대상 파일

| 파일 경로 | 수정 내용 | 사유 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/job.dart` | baseAtk/Def/Hp/speed → baseStr/Intelligence/Vit/Agi 필드 교체 | Job 정적 데이터 모델 변경 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` | HiveField 4~7 필드명/타입 변경, effectiveAtk/Def/Hp getter → effectiveStr/Intelligence/Vit/Agi로 교체 | 핵심 용병 모델 변경 |
| `band_of_mercenaries/lib/core/data/hive_initializer.dart` | mercenaries 박스 열기 전 deleteBoxFromDisk() 호출 추가 | 구 스탯 데이터 초기화 |
| `band_of_mercenaries/lib/features/mercenary/domain/recruitment_service.dart` | job.baseAtk/Def/Hp/speed → job.baseStr/Intelligence/Vit/Agi 초기화 코드 변경 | 신규 스탯으로 용병 생성 |
| `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart` | 퀘스트별 스탯 가중치 Map 상수 추가, partyPower 계산 헬퍼 메서드 추가 | 가중치 공식 중앙화 |
| `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart` | partyPower 계산 로직 변경 (effectiveAtk → 4스탯 가중합) | 핵심 성공률 계산 변경 |
| `band_of_mercenaries/lib/features/quest/view/dispatch_detail_page.dart` | partyPower 계산 로직 변경 (line 50) + 개별 용병 전투력 표시 변경 (line 161: `merc.effectiveAtk` → `merc.effectiveStr`) | 성공률 미리보기 + 용병 전투력 표시 일치 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_card.dart` | 스탯 표시 문자열 변경 (line 127) | UI 반영 |
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` | 스탯 칩 4개로 교체 (line 299-305) | UI 반영 |
| `band_of_mercenaries/lib/features/home/view/home_screen.dart` | totalPower 계산: effectiveAtk → effectiveStr (line 393) | UI 반영 |

### 3.2 신규 생성 파일

없음

### 3.3 코드 생성 필요 파일

| 파일 경로 | 이유 |
|-----------|------|
| `band_of_mercenaries/lib/core/models/job.dart` | freezed + json_serializable 필드 변경 → job.freezed.dart, job.g.dart 재생성 |
| `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart` | hive_generator 필드 타입 변경 → mercenary_model.g.dart 재생성 |

### 3.4 관련 시스템

- **퀘스트 파견 시스템**: partyPower 공식 변경으로 성공률 분포 전면 변동
- **용병 이동 시스템**: `features/movement/` 하위에서 `mercenary.speed` 직접 참조 **0건 확인됨** — 영향 없음
- **방치형 보상 시스템**: speed 참조 없으므로 영향 없음

---

## 4. 기술 참고사항

### 4.1 기존 패턴 참조

- `band_of_mercenaries/lib/features/mercenary/domain/mercenary_model.dart:104-119` — effectiveAtk/Def/Hp getter 패턴을 그대로 복제하여 effectiveStr/Intelligence/Vit/Agi 작성
- `band_of_mercenaries/lib/features/quest/domain/quest_completion_service.dart:72` — partyPower 한 줄 fold 패턴 참조
- `band_of_mercenaries/lib/features/quest/domain/quest_calculator.dart:10-12` — 기존 `_questModifiers` Map 상수 선언 패턴 참조

### 4.2 주의사항

- **`int` 예약어**: `intelligence` 필드명 사용. 줄여서 `intel`로 쓰지 않는다.
- **Hive 어댑터 재생성**: `mercenary_model.dart` 변경 후 반드시 `dart run build_runner build` 실행. `.g.dart` 미재생성 시 런타임 오류 발생.
- **이동 시스템 speed 참조**: `features/movement/` 하위에서 `mercenary.speed` 직접 참조 0건 확인됨. 추가 교체 불필요.
- **데이터 초기화 순서**: `HiveInitializer.initialize()`에서 어댑터 등록 → `settings` 박스 열기 → `stat_migration_v2` 플래그 확인 → (없으면) `deleteBoxFromDisk('mercenaries')` + `deleteBoxFromDisk('quests')` → 플래그 기록 → `openBox()` 순서. 어댑터 등록 전 삭제해도 무방(박스 파일만 삭제).
- **operation-bom 선행 작업**: Flutter 구현 전 Supabase jobs 테이블 컬럼 변경 및 85개 직업 데이터 재입력이 완료되어야 정상 동작. 개발 중에는 더미 데이터로 테스트 가능.

### 4.3 엣지 케이스

- **파견 중인 용병의 데이터 초기화**: mercenaries 박스 삭제 시 파견 중 퀘스트(`quests` 박스)와 mercenaryId 참조가 끊김. quests 박스도 함께 초기화 필요. 일회성 마이그레이션 플래그(`stat_migration_v2`)로 반복 삭제 방지.
- **AGI=0 예외**: `speedMultiplier = agi / 50.0`에서 agi=0이면 속도 0 → 이동 시간 무한대. 최솟값 clamp 처리 필요 (`agi.clamp(1, 999)`).
- **가중치 합이 1.0**: 4개 가중치 합이 1.0이 되어야 기존 enemyPower 수치와 스케일이 맞음. 현재 제안된 가중치는 모두 합산 1.0.

### 4.4 구현 힌트

- **진입점**:
  - 스탯 계산: `mercenary_model.dart` — effectiveStr/Intelligence/Vit/Agi getter
  - partyPower: `quest_completion_service.dart:72`, `dispatch_detail_page.dart:50`
  - 개별 용병 전투력 표시: `dispatch_detail_page.dart:161`
  - 용병 생성: `recruitment_service.dart:103-114`
  - 데이터 초기화: `hive_initializer.dart:15` `initialize()` 메서드

- **데이터 흐름**:
  ```
  Supabase jobs 테이블 (base_str/int/vit/agi)
    → SyncService → 로컬 JSON 캐시
    → DataLoader → StaticGameData.jobs
    → Job 모델 (baseStr/Intelligence/Vit/Agi)
    → RecruitmentService → Mercenary(str/intelligence/vit/agi)
    → Hive mercenaries 박스 저장
    → mercenaryListProvider
    → effectiveStr/Intelligence/Vit/Agi getter
    → QuestCompletionService (partyPower 가중합)
    → QuestCalculator.calculateSuccessRate(partyPower, enemyPower, ...)
  ```

- **partyPower 계산 패턴 (신규)**:
  ```dart
  // quest_calculator.dart에 추가
  static const Map<String, Map<String, double>> _statWeights = {
    'raid':    {'str': 0.70, 'intelligence': 0.10, 'vit': 0.10, 'agi': 0.10},
    'hunt':    {'str': 0.50, 'intelligence': 0.10, 'vit': 0.10, 'agi': 0.30},
    'escort':  {'str': 0.20, 'intelligence': 0.10, 'vit': 0.60, 'agi': 0.10},
    'explore': {'str': 0.10, 'intelligence': 0.45, 'vit': 0.15, 'agi': 0.30},
  };

  static int calculatePartyPower(List<Mercenary> mercs, String questTypeId) {
    final w = _statWeights[questTypeId] ?? _statWeights['raid']!;
    return mercs.fold<int>(0, (sum, m) =>
      sum + (m.effectiveStr * w['str']! +
             m.effectiveIntelligence * w['intelligence']! +
             m.effectiveVit * w['vit']! +
             m.effectiveAgi * w['agi']!).round());
  }
  ```

- **Hive 데이터 일회성 마이그레이션 패턴**:
  ```dart
  // hive_initializer.dart — initialize() 내부
  // settings 박스는 먼저 열어야 플래그 확인 가능
  await Hive.openBox(settingsBoxName);
  final settingsBox = Hive.box(settingsBoxName);
  if (settingsBox.get('stat_migration_v2') == null) {
    await Hive.deleteBoxFromDisk(mercenaryBoxName);
    await Hive.deleteBoxFromDisk(questBoxName);
    await settingsBox.put('stat_migration_v2', true);
  }
  await Hive.openBox<Mercenary>(mercenaryBoxName);
  await Hive.openBox<ActiveQuest>(questBoxName);
  ```

- **참조 구현**:
  - `mercenary_model.dart:104-119` — effective getter 패턴 (레벨보너스 + 피로 디버프)
  - `quest_calculator.dart:10-12` — `_questModifiers` Map 상수 선언 형태 참고

- **확장 지점**:
  - `quest_calculator.dart` 상단 `_statWeights` Map에 신규 퀘스트 타입 추가 시 가중치만 추가하면 됨
  - 미래 전투 시스템 도입 시 `effectiveStr/Int/Vit/Agi`를 그대로 재활용

---

## 5. 기획 확인 사항

- **[Q-1]** 기존 저장된 용병 데이터 처리 방식 → **초기화** (mercenaries + quests 박스 삭제)
- **[Q-2]** intelligence/intel/magic 중 필드명 → **`intelligence`** 사용
- **[Q-3]** 홈 화면 총전투력(totalPower)은 어떤 스탯으로 표시할지 → 단순 지표이므로 `effectiveStr` 합산으로 유지. 퀘스트 가중치 미적용.
