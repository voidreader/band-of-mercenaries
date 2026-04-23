Skill used : implement-spec

# M2b 4-1 구현 계획 및 실행 결과

## 구현 계획 요약

1. Supabase DDL — `regions.environment_tags JSONB NOT NULL DEFAULT '[]'` 추가
2. Supabase UPDATE — 199개 리전 환경 태그 일괄 적용 (VALUES 조인 단일 쿼리)
3. Supabase UPDATE — `data_versions.regions` 버전 2 → 3
4. Flutter `region.dart` — `environmentTags` 필드 추가 (`@Default(<String>[])`)
5. build_runner 재실행 — `region.freezed.dart` / `region.g.dart` 재생성
6. 마이그레이션 SQL 파일 저장

## 변경 파일 목록

| 파일 경로 | 변경 유형 | 설명 |
|-----------|----------|------|
| `band_of_mercenaries/lib/core/models/region.dart` | 수정 | `environmentTags` 필드 추가 |
| `band_of_mercenaries/supabase/migrations/20260423_m2b_4_1_region_environment_tags.sql` | 신규 | DDL + 199행 UPDATE + data_versions 갱신 SQL |
| `band_of_mercenaries/lib/core/models/region.freezed.dart` | 재생성 | build_runner |
| `band_of_mercenaries/lib/core/models/region.g.dart` | 재생성 | build_runner |

## 실제 개발 사항

### Supabase 실행 결과

- `regions` 테이블 스키마 확인: `id`(serial PK) + `region`(int) 두 컬럼 모두 존재, 값 일치 확인 후 `id`를 WHERE 조건으로 사용
- DDL 실행: `ALTER TABLE regions ADD COLUMN IF NOT EXISTS environment_tags JSONB NOT NULL DEFAULT '[]'` → 성공
- 199행 UPDATE 실행 → 성공
- 검증 샘플: id=1→`["plains"]`, id=17→`["ruins","underground"]`, id=99→`["coast"]`, id=147→`["swamp"]`, id=199→`["underground"]` 모두 정확
- `data_versions.regions` 버전 3으로 갱신 완료

### Flutter 모델 수정

`region.dart`에 추가된 필드:
```dart
@JsonKey(name: 'environment_tags')
@Default(<String>[])
List<String> environmentTags,
```

`@Default(<String>[])` 사용으로 기존 캐시 backward compatibility 보장.

### build_runner 결과

```
Succeeded after 8.3s with 16 outputs (118 actions)
```

### flutter analyze 결과

```
No issues found! (ran in 1.6s)
```

## CLAUDE.md 금지사항 위반

없음.

## 다음 단계

M2b 4-2: `EliteMonsterData` / `EliteLootEntry` Freezed 모델 + `elite_monsters` / `elite_loot_tables` 신규 테이블 DDL + SyncService 확장
