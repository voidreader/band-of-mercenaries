# region-environment-tag 생성 메타 — M2b 리전 환경 태그

> 생성일: 2026-04-23
> 타입: region-environment-tag
> 대상 테이블: `regions` (UPDATE 199행)
> CSV: `[region-environment-tag]20260423_m2b-regions.csv`

## 생성 근거

- 밸런스 분석: `Docs/balance-design/[balance]20260423_region-naming-reform.md`
- 이름 개편 기반: 해안(18개)·늪(11개) 신규 추가 + 폐허 1개 → 숲 전환
- 타입 스펙: `.claude/skills/data-generator/types/region-environment-tag.md`

## 매핑 기준

결정론적 1:1 매핑 (창의적 생성 없음). region_name → environment_tags 직접 대응.

| region_name | 수 | 태그 | 비고 |
|------------|---|------|------|
| 초원 | 22 | `["plains"]` | T1 내륙 초지 |
| 해안 | 18 | `["coast"]` | T1 해안가 지형 (신규) |
| 숲 | 25 | `["forest"]` | T2 원시림 |
| 늪 | 11 | `["swamp"]` | T2 습지 (신규) |
| 폐허 | 29 | `["ruins"]` | T3 고대 잔해 |
| 산악 | 25 | `["mountain"]` | T4 험준한 산지 |
| 전쟁터 | 20 | `["plains"]` | T5 활성 전장 (ruins 미부여) |
| 고대유적 (id 17~94, 9개) | 9 | `["ruins","underground"]` | T6 지상+지하 유적 |
| 고대유적 (id 102~197, 9개) | 9 | `["underground"]` | T6 지하 미로형 고대 도시 |
| 황무지 | 15 | `["desert"]` | T7 황야 |
| 마계경계 | 10 | `["mountain"]` | T8 산악 방벽 (underground 미부여) |
| 심연 | 6 | `["underground"]` | T10 심층 지하 |

## 검증 결과

### 태그 분포

| 태그 | 기여 리전 | 합계 | 목표 범위 | 결과 |
|------|---------|------|---------|------|
| plains | 초원22 + 전쟁터20 | **42** | 35~65 | ✓ |
| coast | 해안18 | **18** | 18~33 | ✓ |
| forest | 숲25 | **25** | 25~45 | ✓ |
| swamp | 늪11 | **11** | 11~20 | ✓ |
| ruins | 폐허29 + 고대유적첫9 | **38** | 21~39 | ✓ |
| mountain | 산악25 + 마계경계10 | **35** | 21~39 | ✓ |
| desert | 황무지15 | **15** | 14~26 | ✓ |
| underground | 고대유적18 + 심연6 | **24** | 14~26 | ✓ |
| **총계** | | **208** | 평균 1.05/리전 | |

### 자체 검증 체크리스트

- [x] 출력 행 수 = 199 (전 리전 커버)
- [x] 모든 region_id 유일, 1~199 전부 포함
- [x] 모든 태그가 8종 허용 태그 내
- [x] 모든 리전 태그 수 1~2개 (3개 없음)
- [x] 금지 조합 없음 (desert+swamp, desert+coast 해당 없음)
- [x] 8개 태그 전부 목표 범위 내
- [x] T5 전쟁터 → plains (고티어 plains 단독 허용 예외: 전장 특성)
- [x] T1에 mountain/ruins/underground 단독 없음

## DB 반영 안내

`environment_tags` 컬럼이 현재 `regions` 테이블에 존재하지 않음.

**반영 선행 조건**: 페이즈 4-1 마이그레이션에서 아래 DDL 실행 후 CSV를 적용할 것.

```sql
ALTER TABLE regions ADD COLUMN environment_tags JSONB DEFAULT '[]'::jsonb;
```

이후 CSV의 각 행을 아래 형식으로 UPDATE:
```sql
UPDATE regions SET environment_tags = '[...]'::jsonb WHERE id = N;
```
