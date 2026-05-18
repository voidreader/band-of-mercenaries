# M8a 세력 접촉점·반응 텍스트 데이터

> 작성일: 2026-05-18
> 데이터 파일: `Docs/content-data/[faction-contact]20260518_m8a-faction-contacts.csv`
> 입력 문서:
> - `Docs/content-design/[content]20260518_m8a_faction_contacts.md`
> - `Docs/content-design/[content]20260518_m8a_faction_patronage_flow.md`

## 생성 범위

- 접촉점 3개: 모험가 길드, 상인 연합, 전사 길드 각 1개
- 반응 텍스트 33개: 세력당 11개
- 총 레코드 36개

## 테이블 후보

페이즈 4에서 다음 2개 테이블을 검토한다.

| 후보 테이블 | 역할 |
|-------------|------|
| `faction_contacts` | 세력별 생활권 접촉점, NPC, 최초 노출 조건 |
| `faction_reaction_texts` | 접촉점 상태·조건별 반응 텍스트 |

CSV는 두 테이블 후보를 한 파일로 묶기 위해 `record_type` 컬럼을 둔다. `record_type=contact` 행은 접촉점 정의, `record_type=reaction` 행은 반응 텍스트다.

## 구현 메모

- `trigger_type` 값은 페이즈 4에서 `infrastructureTier`, `region_flag`, `achievement`, `faction_reputation`, `faction_joined`, `conflict_hint`, `combat_report`로 정규화한다.
- `relation_stage`는 계산형 상태 후보이며 `noticed`, `patronage`, `joined`, `trusted`, `core`, `conflict`, `hostile`, `any`를 사용한다.
- `tags_json`은 UI 톤, 필터, 보고서 연동을 위한 후보 메타데이터다.
- 본 데이터는 Supabase 쓰기 전 승인용 산출물이며 아직 실제 테이블에 삽입하지 않았다.

## 자체 검증

- 대표 세력 3개 모두 접촉점이 있다.
- 반응 텍스트는 30~50개 목표 범위 안이다.
- 지역 상태 플래그 5종 이상을 조건으로 사용한다.
- 가입 전 후원 상태와 상인 연합 vs 전사 길드 갈등을 반영한다.
