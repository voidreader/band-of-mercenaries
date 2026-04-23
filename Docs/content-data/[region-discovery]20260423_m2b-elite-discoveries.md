# region-discovery 생성 메타 — M2b 유니크 엘리트 발견 단서 16행

> 생성일: 2026-04-23
> 타입: region-discovery (elite 서브타입)
> 대상 테이블: `region_discoveries` (INSERT 16행)
> CSV: `[region-discovery]20260423_m2b-elite-discoveries.csv`

## 생성 근거

- 컨텐츠 기획: `Docs/content-design/[content]20260420_elite_monster_catalog.md` §6.4
- 엘리트 몬스터 목록: `Docs/content-data/[elite-monster]20260423_m2b-elite-monsters.csv`
- 리전 환경 태그: `Docs/content-data/[region-environment-tag]20260423_m2b-regions.csv`
- regions 테이블 tier 조회: Supabase MCP

## 생성 요약

| 유니크 | elite tier | region_id × 2 | region_tier (name) | threshold |
|--------|-----------|--------------|-------------------|-----------|
| elite_wolf_ulbur | T2 | 23, 74 | T2 숲 | 30 |
| elite_golem_steel | T3 | 36, 62 | T6 고대유적 | 50 |
| elite_hydra_swamp | T3 | 147, 178 | T2 늪 | 50 |
| elite_skeleton_general | T3 | 49, 116 | T3 폐허 | 50 |
| elite_guardian_desert | T4 | 44, 115 | T7 황무지 | 70 |
| elite_witch_morgan | T4 | 5, 52 | T3 숲·T3 폐허 | 70 |
| elite_kraken_abyss | T4 | 129, 190 | T1 해안 | 70 |
| elite_lich_primordial | T5 | 17, 84 | T6 고대유적 | 85 |
| **합계** | | **16행** | | |

## 선정 기준

### knowledge_threshold 매핑 (기획서 §6.4)
- T2 유니크: 30
- T3 유니크: 50
- T4 유니크: 70
- T5 유니크: 85

### 리전 선정 원칙
1. `fixed_region_environments`에 명시된 환경 태그 보유 리전 중 선택
2. 유니크 서사(lore)와 일치하는 리전 환경 우선
3. 같은 유니크 내 두 리전은 numerically 분산 선택

### 특이 케이스
- **golem_steel / lich_primordial**: 둘 다 ruins+underground → T6 고대유적. region_id 겹침 없이 분리 (golem: 36·62, lich: 17·84)
- **hydra_swamp**: T3 엘리트지만 swamp 전체가 T2 늪. T2 리전에서 T3 엘리트 발견 — 히드라가 잠든 구역은 외견상 평범한 늪으로 인식됨
- **kraken_abyss**: T4 엘리트지만 coast 전체가 T1 해안. 잠든 해수를 연안 조사로 발견하는 서사 일관성 유지
- **witch_morgan**: forest(region 5, T3) + ruins(region 52, T3) 각각 1개씩 배치 — 마녀의 영향력이 숲과 폐허 양쪽에 미침

## discovery_data 스키마

```json
{
  "elite_id": "elite_{id}",
  "reveal_text": "조사 완료 시 표시되는 1~2문장 플레이어 팝업 텍스트"
}
```

## 자체 검증 결과

- [x] 총 행 수 = 16 (유니크 8종 × 2)
- [x] 모든 id 유일 (`rd_{region_id:03d}_elite_{elite_suffix}` 형식)
- [x] 모든 region_id 유일 (중복 없음): 23·74·36·62·147·178·49·116·44·115·5·52·129·190·17·84
- [x] discovery_type = 'elite' 전 16행
- [x] knowledge_threshold T2=30 / T3=50 / T4=70 / T5=85 준수
- [x] discovery_data JSON 형식 올바름 (elite_id + reveal_text 키)
- [x] 기존 `region_discoveries` 6행 ID와 충돌 없음 (기존 elite 행 rd_001_elite_50은 region_id=1)
- [x] 각 유니크의 fixed_region_environments와 선정 리전 환경 태그 일치
- [x] description 1~2문장, 세계관 톤 일관성

## DB 반영 안내

`region_discoveries` 테이블 기존 존재 확인 (현재 6행).

이 16행은 기존 구조와 동일한 스키마로 INSERT 가능.

> **단, `discovery_data` 형식 주의**: 기존 `rd_001_elite_50`은 `{"power":120,"enemy_type":"veteran_guard"}` 형식이나, 본 행들은 `{"elite_id":"...","reveal_text":"..."}` 형식으로 다름. Phase 4-3 Flutter 구현 시 `discovery_type='elite'` 파싱 로직이 이 형식을 처리해야 한다.

## 다음 단계

Phase 3 완료 → Phase 4 체크포인트 진입 가능

Phase 4 산출물 목록:
- 4-1: `regions.environment_tags` 컬럼 추가 마이그레이션 + `Region` Freezed 모델 확장
- 4-2: `EliteMonsterData`, `EliteLootEntry` Freezed 모델 + SyncService 확장
- 4-3: 엘리트 퀘스트 생성 + 드랍 판정 (EliteLootService)
- 4-4: 엘리트 UI
