# faction-quest 벌크 생성 메타 — M1 세력 전용 퀘스트

> 작성일: 2026-04-17
> 타입: faction-quest
> 대상 테이블: `quest_pools` (스키마 확장 필요)
> 총 생성: **98행** (14세력 × 7개)
> CSV: `[faction-quest]20260417_m1-faction-exclusive.csv`

---

## 생성 근거

### 입력 문서
- **컨텐츠 기획서**: `Docs/content-design/[content]20260417_faction_quests.md`
  - 섹션 6: 14개 세력별 톤·키워드·대상·트랙 컨셉 가이드
  - 섹션 4: 세력별 유형 배분 표
- **밸런스 리포트**: `Docs/balance-design/20260417_faction_quests_balance.md`
  - 분석 5: tier_range 기반 난이도 배정표 (기본 하위 3 / 고급 상위 3)
  - P2 조정: 고급 트랙 보상 보너스 +0.50 → +0.40 (본 CSV는 수치 참조만, 실제 적용은 `QuestCalculator` 런타임 계산)
  - P4 조정: 뿌리의 맹세단 tier_range [1,3]→[1,4] Supabase 실측 반영

### 타입 스펙
- `.claude/skills/data-generator/types/faction-quest.md`
- 확장 컬럼(`is_faction_exclusive`, `min_reputation`)은 기획서 섹션 9 및 balance 리포트 후속 안내의 "페이즈 3 사전 작업"에 명시된 스키마 확장 예정 컬럼을 선제 포함

---

## 생성 규칙 요약

| 항목 | 규칙 |
|------|------|
| id 형식 | `fq_{faction_key}_{slug}` — `faction_key`는 `factions.id`에서 `faction_` 제거 |
| 트랙 분배 | 세력당 기본 3 + 고급 4 = 7개 |
| `min_reputation` | 기본 트랙 3개 → 11, 고급 트랙 4개 → 61 |
| `is_faction_exclusive` | 모두 `true` |
| 난이도 | tier_range 하위 3(기본) / 상위 3(고급), clamp[1,5] |
| `min_region_diff`/`max_region_diff` | tier_range 기반 거리 범위 |
| 유형(type) | 1=raid / 2=hunt / 3=escort / 4=explore. 세력별 배분은 기획서 섹션 4 표 |
| `sector_type` | 모두 빈 값 (M3에서 채움) |

---

## 세력별 배정 결과

| 세력 | tier_range | 기본 난이도 | 고급 난이도 | region_diff | 유형 배분 (R/H/E/X) |
|------|:----------:|:-----------:|:-----------:|:-----------:|:------------------:|
| 모험가 길드 | [1,3] | 2, 2, 3 | 3, 3, 4, 4 | 0~3 | 1/2/1/3 |
| 상인 연합 | [1,4] | 2, 3, 3 | 4, 4, 5, 5 | 0~4 | 0/1/4/2 |
| 전사 길드 | [2,4] | 3, 3, 4 | 4, 4, 5, 5 | 1~5 | 3/3/1/0 |
| 도둑 길드 | [2,4] | 3, 3, 4 | 4, 4, 5, 5 | 1~5 | 2/1/1/3 |
| 마탑 연합 | [3,5] | 4, 4, 5 | 5, 5, 5, 5 | 2~8 | 0/1/1/5 |
| 태양 교단 | [2,4] | 3, 3, 4 | 4, 4, 5, 5 | 1~5 | 1/2/3/1 |
| 균형 감시자 | [2,5] | 3, 4, 4 | 5, 5, 5, 5 | 1~6 | 1/2/2/2 |
| 금지된 서고 | [3,5] | 4, 4, 5 | 5, 5, 5, 5 | 2~8 | 1/1/1/4 |
| 뿌리의 맹세단 | [1,4] | 2, 3, 3 | 4, 4, 5, 5 | 0~4 | 2/2/2/1 |
| 황혼 공학회 | [3,5] | 4, 4, 5 | 5, 5, 5, 5 | 2~8 | 1/1/2/3 |
| 심층 망치단 | [3,5] | 4, 4, 5 | 5, 5, 5, 5 | 2~8 | 1/2/2/2 |
| 화산 심장단 | [3,5] | 4, 4, 5 | 5, 5, 5, 5 | 2~8 | 4/2/0/1 |
| 혈계 귀족회 | [4,5] | 4, 5, 5 | 5, 5, 5, 5 | 3~8 | 1/2/3/1 |
| 송곳니 결사 | [2,4] | 3, 3, 4 | 4, 4, 5, 5 | 1~5 | 2/3/1/1 |

---

## 검증 결과

### 카운트 검증

| 항목 | 기대치 | 실측치 | 결과 |
|------|:------:|:------:|:----:|
| 총 행 수 | 98 | 98 | ✓ |
| 세력당 행 수 | 7 | 7 (14개 모두) | ✓ |
| 유일 ID 수 | 98 | 98 | ✓ |
| type=1 (raid) | 20 | 20 | ✓ |
| type=2 (hunt) | 25 | 25 | ✓ |
| type=3 (escort) | 24 | 24 | ✓ |
| type=4 (explore) | 29 | 29 | ✓ |

### 체크리스트 (타입 스펙 기준)

- [x] 모든 `id`가 `fq_{faction_key}_{slug}` 형식
- [x] 모든 `id`가 유일 (98/98)
- [x] 모든 `name`이 기존 `quest_pools`와 중복 없음 (기존은 `{대상} {유형} Lv{n}` 패턴 → 전용은 Lv 없는 명사구/명령형으로 명확히 구분)
- [x] 모든 `faction_tag`가 `factions.id`에 실존 (14개 모두 Supabase 조회로 확인)
- [x] `type` 값 1~4 범위 내
- [x] `difficulty` 값 1~5이고 기획서 tier_range 범위 내
- [x] `min_region_diff <= max_region_diff`
- [x] 유형 배분이 기획서 섹션 4 표와 일치
- [x] `min_reputation` 기본 3개=11, 고급 4개=61
- [x] `is_faction_exclusive` 모두 true
- [x] `sector_type` 모두 빈 값

### 세력명 직접 노출 검증

타입 스펙 "세력명 직접 노출 금지" 규칙 준수 확인:
- 내부 충돌 세력 상호 지칭: 심층 망치단의 "숙적 화염 거점 타격" / 화산 심장단의 "숙적 광산 공격" — **간접 표현**(숙적, 화염, 광산)으로 직접 세력명 회피
- 송곳니 결사 "귀족 영지 습격" / 혈계 귀족회 "경쟁 부족장 제거" — 간접 표현
- 뿌리의 맹세단 "기계 문명 거점 습격" / 황혼 공학회 지칭 — 간접 표현
- 어떤 퀘스트 이름에도 `모험가`, `상인`, `전사`, `도둑`, `마탑`, `태양`, `균형`, `서고`, `뿌리`, `황혼`, `심층`, `화산`, `혈계`, `송곳니` 등 세력명 고유 키워드 포함되지 않음 ✓

---

## ⚠️ 스키마 미확장 이슈 (DB 쓰기 보류)

현재 `quest_pools` 테이블 실제 스키마:
```
id (text), name (text), type (real), difficulty (real),
min_region_diff (real), max_region_diff (real)
```

본 CSV에 포함된 **4개 추가 컬럼이 현재 테이블에 없음**:
- `faction_tag` (text, nullable) — 신규
- `is_faction_exclusive` (boolean, default false) — 신규
- `min_reputation` (int, default 0) — 신규
- `sector_type` (text, nullable) — 신규

또한 `type` 컬럼이 현재 `real` 타입이나 의미적으로는 `quest_types.id`(text)를 참조해야 함. 페이즈 4 스키마 확장 시 결정:
- 옵션 A: `type`을 text로 변경하고 CSV의 1~4 숫자를 `raid/hunt/escort/explore`로 매핑 변환
- 옵션 B: `type_id` 신규 컬럼 추가하고 기존 `type`(real)은 deprecated 처리

**현재 조치:** CSV만 생성. **DB INSERT는 페이즈 4 개발 명세(`/spec-writer`)의 스키마 마이그레이션 완료 이후**로 연기.

페이즈 4 마이그레이션 스크립트 초안:
```sql
ALTER TABLE quest_pools ADD COLUMN faction_tag TEXT NULL REFERENCES factions(id);
ALTER TABLE quest_pools ADD COLUMN is_faction_exclusive BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE quest_pools ADD COLUMN min_reputation INT NOT NULL DEFAULT 0;
ALTER TABLE quest_pools ADD COLUMN sector_type TEXT NULL;
-- type 컬럼 처리는 페이즈 4에서 결정
```

---

## 생성 결과

- **CSV 경로**: `Docs/content-data/[faction-quest]20260417_m1-faction-exclusive.csv`
- **총 행 수**: 98
- **파일 크기**: ~12KB (UTF-8, BOM 없음)
- **헤더**: `id,name,type,difficulty,min_region_diff,max_region_diff,faction_tag,is_faction_exclusive,min_reputation,sector_type`

---

## 후속 단계

### 즉시
- ✅ CSV 생성 완료
- ✅ 메타 리포트 작성 완료
- ⏸️ **Supabase INSERT 보류** (스키마 확장 미완)

### 페이즈 4 (`/spec-writer` 산출물)
1. `quest_pools` 스키마 4필드 추가 마이그레이션 작성
2. `QuestPool` Freezed 모델에 신규 필드 반영
3. `SyncService` quest_pools 버전 갱신
4. 본 CSV를 기반으로 `INSERT` 스크립트 작성 (`operation-bom` 벌크 업로드 또는 SQL 직접 실행)

### M3 이후
- `sector_type` 필드 채우기 (섹터 변형 시스템 도입 시)

### 재노출 권장
- 스키마 확장 후 다시 `/data-generator faction-quest --brief @... --write`로 호출하여 DB INSERT 수행. CSV는 재생성 없이 기존 파일 import 가능.
