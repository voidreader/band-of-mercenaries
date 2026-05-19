# M8a 전투 보고서 템플릿·키워드 데이터

> 작성일: 2026-05-18
> 데이터 파일:
> - `Docs/content-data/[combat-report-template]20260518_m8a-combat-report-templates.csv`
> - `Docs/content-data/[combat-report-keyword]20260518_m8a-combat-report-keywords.csv`
> 입력 문서:
> - `Docs/content-design/[content]20260518_m8a_combat_report_mvp.md`
> - `Docs/balance-design/[balance]20260518_m8a_combat_report_exposure.md`

## 생성 범위

- 전투 보고서 템플릿 96개
- 전투 보고서 키워드 40개
- 일반 의뢰 전체 적용이 아니라 세력 지명, 기존 지명, 엘리트, 연계 핵심 단계에 붙이는 MVP 기준이다.

## 템플릿 분포

| 그룹 | 수량 | 설명 |
|------|------|------|
| `common` | 24 | quest_type별 결과 공통 문장 |
| `faction` | 24 | 대표 3세력별 결과 톤 문장 |
| `elite` | 16 | 일반 엘리트와 유니크 엘리트 상세 라인 |
| `chain` | 12 | 연계 퀘스트 중간·최종·거점 사건 라인 |
| `decisive` | 20 | 주인공 활약, 보조, 방패, 후퇴, 추격, 부상 장면 |

## 키워드 분포

| 카테고리 | 수량 |
|----------|------|
| `battlefield` | 12 |
| `enemy` | 10 |
| `decisive` | 12 |
| `injury` | 6 |

## 테이블 후보

페이즈 4에서 신규 정적 데이터 테이블 2개를 권장한다.

| 후보 테이블 | 역할 |
|-------------|------|
| `combat_report_templates` | 결과·세력·의뢰 유형·중요도별 템플릿 |
| `combat_report_keywords` | 전장, 적, 결정적 장면, 부상 키워드 |

## 구현 메모

- `template`은 `TemplateEngine` 확장 namespace를 전제로 `{merc.name}`, `{ally.name}`, `{region.name}`, `{quest.name}`, `{enemy.name}` 플레이스홀더를 사용한다.
- `line_type=summary`는 결과 다이얼로그 요약 후보, `line_type=detail`은 상세 보고서 라인 후보로 사용한다.
- `importance`는 `normal`, `high`, `very_high` 3단계로 두고 UI 길이와 자동 강조 여부를 결정한다.
- `tags_json`은 M8.5 히든 스탯·감정 반응 연결 후보로 남긴다.

## 자체 검증

- 템플릿 수는 80~120개 목표 범위 안인 96개다.
- 키워드 수는 30~50개 목표 범위 안인 40개다.
- 실패·대실패 문장은 조롱하지 않고 건조한 기록 톤으로 작성했다.
- Supabase에는 아직 쓰지 않았다.
