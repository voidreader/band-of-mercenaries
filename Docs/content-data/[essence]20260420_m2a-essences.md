# 정수 20종 생성 리포트 (M2a)

> 생성일: 2026-04-20
> 타입: `essence`
> 대상 테이블: `items` (category=consumable)
> 산출: `Docs/content-data/[essence]20260420_m2a-essences.csv`

## 입력 근거

- `Docs/content-design/[content]20260418_essence_system.md` — 20종 체계, effect_json 구조, 저장/소비 UX
- `Docs/content-design/[content]20260418_initial_item_set.md` — 수식어 체계(기본/오래된/고대의/태고의/태초의), 톤
- `Docs/balance-design/20260418_essence_inflation.md` — 효과 곡선 +1/+2/+4/+7/+11 확정, 단일 축 정책, effect_json 스키마

## 생성 요약

- 총 20행 (스탯 4축 × 티어 5단계)
- 분포: STR 5 / INT 5 / VIT 5 / AGI 5
- 티어 분포: T1 4 / T2 4 / T3 4 / T4 4 / T5 4
- 수치 총합 참고: (1+2+4+7+11) × 4 = 100 포인트

## 네이밍 규약

DB 마이그레이션 007의 check constraint가 `slot ∈ {essence_str, essence_int, essence_vit, essence_agi}`(tier suffix 없음)만 허용 → balance-design 문서의 "slot + tier 조합" 방식을 DB가 채택한 상태. 이에 맞춰 **id는 유니크 키로 tier suffix 유지, slot은 tier 컬럼과 조합**으로 운용.

| 티어 | 수식어 | id (PK) | slot | tier 컬럼 |
|---|---|---|---|---|
| T1 | (없음) | `essence_{stat}_t1` | `essence_{stat}` | 1 |
| T2 | 오래된 | `essence_{stat}_t2` | `essence_{stat}` | 2 |
| T3 | 고대의 | `essence_{stat}_t3` | `essence_{stat}` | 3 |
| T4 | 태고의 | `essence_{stat}_t4` | `essence_{stat}` | 4 |
| T5 | 태초의 | `essence_{stat}_t5` | `essence_{stat}` | 5 |

`stat ∈ {str, int, vit, agi}` (id/slot) — 4축 모두 동일 수식어 적용. 단, `effect_json`의 stat 키는 Mercenary 모델 필드명과 일치하도록 `intelligence` 사용 (나머지 str/vit/agi는 동일).

**후속 조치 필요:** `.claude/skills/data-generator/types/essence.md`의 slot 형식 표기(`essence_{stat}_t{tier}`)를 DB 규약(`essence_{stat}`)과 일치시키는 수정 권고.

## effect_json 스키마 준수

모든 20행이 다음 형식:
```json
{ "permanent_stat_gain": { "<statKey>": <tierValue> } }
```
- `statKey` = slot의 stat 부분과 정확히 일치 (단일 축)
- `tierValue` = T1:1 / T2:2 / T3:4 / T4:7 / T5:11

## description 처리

DB 스키마에서 `description`이 NOT NULL이므로, 타입 스펙의 "간결한 한 줄" 운영 원칙에 따라 `"{STAT} +{n} 영구 강화"` 포맷으로 채움. 서사는 `flavor_text`가 전담.

## flavor_text 톤 설계

시간 계단(현재 → 수십 년 → 수백 년 → 태고 → 세계 형체 이전) × 축별 모티프:
- STR: 전장·함성·일격·전사
- INT: 지식·룬·사유·도서관
- VIT: 수호·성벽·거인·꺾이지 않음
- AGI: 발걸음·질주·전령·궤적

저작권 금칙 준수: 웹소설 레퍼런스(게임 속 바바리안으로 살아남기 / 메모라이즈 / 용마검전 / 특성 쌓는 김전사)의 고유명사·인물·세계관 미사용. 감성 톤만 추출.

## 자체 검증 체크리스트

- [x] 모든 `id`가 `essence_{stat}_t{tier}` 형식
- [x] 모든 `id`가 유일 (내부 중복 없음)
- [x] 4 × 5 = 20종 전체 생성
- [x] `category` 전부 `consumable`
- [x] `slot` = `id`
- [x] `tier`와 slot의 `_t{N}` 부분 일치
- [x] `effect_json.permanent_stat_gain`의 키가 slot의 stat 부분과 일치
- [x] 수치가 1/2/4/7/11 공식 엄수
- [x] 명칭 수식어 체계 정확 적용
- [x] `flavor_text` 모든 행 존재 (1문장 기준, 60자 내외)
- [x] 저작권 금칙 준수

## Supabase 상태 확인 (생성 전)

- `items` 테이블: 존재, 현재 0행 (충돌 없음)
- `items` 컬럼: id/name/description/flavor_text/category/slot/tier/effect_json/created_at 모두 NOT NULL
- `data_versions.items`: version=1 (2026-04-19 생성). INSERT 후 version=2로 bump 필요

## 후속 작업

1. 사용자 검토 → 승인 시 Supabase `items` 테이블에 INSERT (20행)
2. `data_versions.items` version=1 → 2 업데이트 (Flutter 앱 재동기화 트리거)
3. spec-writer 페이즈 4 진행:
   - `Mercenary` 모델 HiveField 18~21 (permanent_*) 확장
   - `EssenceService` (canApply/previewApply/apply)
   - 소비 UX: 용병 상세 "정수 사용" 버튼 + 인벤토리 양방향 진입 + 프리뷰 팝업
4. M6 선반영: 동일 아이템 풀이 승급 재료로 재사용됨 (재생성 금지)
