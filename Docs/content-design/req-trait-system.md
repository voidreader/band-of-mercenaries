# PD에 의해 작성된 트레잇 강화 아이디어

PD가 제안한 트레잇 시스템 개선 아이디어

# 📌 Trait 시스템 기획 요약 (컨텐츠 기획자용)

## 🎯 목표
용병을 단순한 “스탯 유닛”이 아니라  
👉 **플레이에 따라 성격과 역할이 변하는 캐릭터**로 만든다

---

## 🔥 핵심 컨셉

### Trait은 옵션이 아니다
- 기존: Trait = 랜덤 스탯 보너스
- 변경: Trait = **플레이 결과로 형성되는 정체성**

👉 “용병을 키운다” → ❌  
👉 “용병의 성격을 만든다” → ✅

---

## 🧠 시스템 구조

### 1. Trait 분류

- **선천 Trait (innate)**: 생성 시 고정
- **획득 Trait (acquired)**: 플레이 중 획득
- **진화 Trait (evolved)**: 특정 조건에서 상위 변형

---

### 2. 카테고리 시스템

| 카테고리 | 설명 |
|----------|------|
| CombatStyle | 전투 방식 |
| Survival | 생존 성향 |
| Behavior | 행동 스타일 |
| Mental | 정신 상태 |
| Experience | 경험 |

👉 룰:
- 같은 카테고리 Trait은 1개만 보유 가능

---

### 3. 슬롯 제한

- 최대 Trait: **3~4개**
- 선천 Trait: 1개 고정

👉 핵심:
**Trait은 쌓는 것이 아니라 선택하는 것**

---

## 🔁 성장 구조

### 기본 흐름
행동 → 태그 → 조건 충족 → Trait 후보 생성 → 선택 → Trait 획득

---

### 예시

- 혼자 임무 수행 많음 → "고독한 늑대"
- 실패 반복 → "트라우마"
- 성공 반복 → "자신감"

---

## 🔥 핵심 시스템 1: explicit conflict

Trait 간 충돌을 명시적으로 정의

### 예시
- 광전사 ↔ 신중함
- 고독한 늑대 ↔ 협동가
- 자신감 ↔ 트라우마

👉 룰:
- 충돌 Trait은 동시에 가질 수 없음

---

## 🔥 핵심 시스템 2: Trait 진화 (그래프 구조)

Trait은 트리가 아니라 **그래프 구조**

### 예시
겁쟁이
→ 생존 전문가
→ 신중함
→ 트라우마
👉 같은 시작이라도 다른 결과 발생

---

## 🔥 핵심 시스템 3: 조합 진화

Trait 조합으로 상위 Trait 생성

### 예시

- 고독한 늑대 + 생존 전문가 → 그림자 사냥꾼
- 광전사 + 자신감 → 학살자

👉 핵심:
**현재 보유 Trait “집합” 기반으로 판단**

---

## ⚙️ 데이터 구조 (첨부 참고)

첨부된 파일:

- CSV: Trait 데이터
- DDL: 테이블 구조

---

### 주요 테이블

- trait_category
- trait
- trait_effect
- trait_conflict
- trait_transition
- trait_combo_evolution
- mercenary_trait
- mercenary_stat

---

## 🎮 기획자가 해야 할 작업

### 1. Trait 설계 (핵심)

- Trait 30~50개 확장
- 각 Trait의 “성격” 명확히 정의
- 수치보다 **서사/느낌 중심**

---

### 2. 충돌 관계 설계

- 서로 상반되는 Trait 정의
- 선택 시 포기 구조 만들기

---

### 3. 진화 설계

- 단일 진화 (조건 기반)
- 조합 진화 (2개 이상 Trait)

---

### 4. 획득 조건 설계

예:
- solo_mission_count
- success_count
- failure_count
- near_death_count

👉 핵심:
**플레이 행동 기반이어야 함**

---

### 5. 플레이 스타일 분기 설계

예:

| 플레이 스타일 | 결과 |
|--------------|------|
| 솔로 위주 | 고독한 늑대 |
| 안정 플레이 | 신중함 |
| 위험 감수 | 광전사 |
| 실패 반복 | 트라우마 |

---

## ⚠️ 반드시 지킬 것

❌ Trait 랜덤 지급 금지  
❌ Trait 무한 증가 금지  
❌ 효과 중복 금지  

---

## 💡 핵심 설계 철학

### 1. 선택 = 포기
모든 Trait을 가질 수 없어야 한다

---

### 2. 실패도 성장이다
실패가 새로운 Trait을 만든다

---

### 3. 플레이 기록이 캐릭터를 만든다

---

## 🚀 기대 효과

- 용병 개성 강화
- 감정적 애착 증가
- 다양한 플레이 스타일 생성
- 리텐션 상승

---

## 🎯 한 줄 요약

👉 **Trait은 스탯 시스템이 아니라 “캐릭터 생성 시스템”이다**


---

### 테이블 구조 예시 
```
-- Trait Category
CREATE TABLE trait_category (
    id SERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL
);

-- Trait
CREATE TABLE trait (
    id SERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    category_id INT REFERENCES trait_category(id),
    type TEXT NOT NULL, -- innate / acquired / evolved
    description TEXT
);

-- Trait Effect
CREATE TABLE trait_effect (
    id SERIAL PRIMARY KEY,
    trait_id INT REFERENCES trait(id),
    stat_key TEXT NOT NULL,
    value NUMERIC NOT NULL
);

-- Trait Conflict (explicit conflict)
CREATE TABLE trait_conflict (
    trait_id INT REFERENCES trait(id),
    conflict_trait_id INT REFERENCES trait(id),
    PRIMARY KEY (trait_id, conflict_trait_id)
);

-- Trait Transition (그래프 구조)
CREATE TABLE trait_transition (
    id SERIAL PRIMARY KEY,
    from_trait_id INT REFERENCES trait(id),
    to_trait_id INT REFERENCES trait(id),
    condition_type TEXT,
    condition_value NUMERIC,
    weight NUMERIC DEFAULT 1.0
);

-- Trait Combo Evolution
CREATE TABLE trait_combo_evolution (
    id SERIAL PRIMARY KEY,
    required_trait_1 INT REFERENCES trait(id),
    required_trait_2 INT REFERENCES trait(id),
    result_trait_id INT REFERENCES trait(id)
);

-- Mercenary Trait
CREATE TABLE mercenary_trait (
    id SERIAL PRIMARY KEY,
    mercenary_id BIGINT NOT NULL,
    trait_id INT REFERENCES trait(id),
    acquired_at TIMESTAMP DEFAULT NOW(),
    is_locked BOOLEAN DEFAULT FALSE
);

-- Mercenary Stat (조건 계산용)
CREATE TABLE mercenary_stat (
    mercenary_id BIGINT PRIMARY KEY,
    solo_mission_count INT DEFAULT 0,
    success_count INT DEFAULT 0,
    failure_count INT DEFAULT 0,
    near_death_count INT DEFAULT 0
);
``` 
