# 스킬 및 에이전트 사용 가이드

> 마지막 업데이트: 2026-04-11

이 문서는 프로젝트에 등록된 Claude Code 스킬의 역할과 사용법을 정리한다.

---

## 기획 단계

기획 아이디어를 발전시키고 밸런스를 분석하는 스킬이다.

| 스킬 | 호출 | 역할 |
|------|------|------|
| `content-designer` | `/content-designer` | 컨텐츠 기획 (신규 컨텐츠, 고도화, 아이디어 제안) |
| `balance-designer` | `/balance-designer` | 밸런스 분석 (수식 검증, 경제 시뮬레이션, 수치 조정 제안) |

### content-designer

레퍼런스 게임(OGame, 아크메이지, Melvor Idle, Kingdom of Loathing)에 정통한 컨텐츠 기획자 역할을 수행한다. 대화형 컨설팅과 분석 리포트 두 가지 모드를 지원한다.

```bash
/content-designer                    # 대화 시작, 주제 질문
/content-designer 여행 이벤트 선택지 시스템을 추가하고 싶다   # 주제 직접 전달
```

- 산출물: `Docs/content-design/{날짜}_{주제}.md`
- 코드를 수정하지 않는다

### balance-designer

데이터 기반 + 플레이어 체감을 병행하는 밸런스 기획자 역할을 수행한다. Supabase에서 실데이터를 조회하고 코드의 공식을 검증한다.

```bash
/balance-designer                    # 대화 시작, 분석 주제 질문
/balance-designer 난이도별 시간당 수익률을 분석해줘   # 주제 직접 전달
```

- 산출물: `Docs/balance-design/{날짜}_{주제}.md`
- **Supabase 인증 필수** — 미인증 시 분석을 진행하지 않는다
- 코드를 수정하지 않는다. SELECT 쿼리만 사용한다

---

## 명세서 작성

기획 문서를 개발 명세서로 변환하는 스킬이다.

| 스킬 | 호출 | 역할 |
|------|------|------|
| `spec-writer` | `/spec-writer` | 기획 문서 → 개발 명세서 변환 |

### spec-writer

기획 문서를 읽고 코드베이스를 탐색하여 구현에 필요한 상세 정보를 담은 개발 명세서를 생성한다. 완료 후 구현 규모를 분석하여 `implement-spec` 또는 `implement-agent` 중 적합한 스킬을 추천한다.

```bash
/spec-writer @Docs/content-design/20260411_travel-choice.md
/spec-writer @Docs/content-design/20260411_travel-choice.md #1234   # Redmine 일감 연동
```

- 산출물: `Docs/{날짜}_{기능명}.md`

---

## 구현 단계

명세서를 기반으로 실제 코드를 구현하는 스킬이다.

| 스킬 | 호출 | 역할 | 적합한 규모 |
|------|------|------|------------|
| `implement-spec` | `/implement-spec` | 올인원 구현 | 수정 파일 5개 이하, 소규모 |
| `implement-agent` | `/implement-agent` | 파이프라인 구현 (analyzer → architect → coder → verifier) | 수정 파일 6개 이상, 대규모 |

### implement-spec

명세서를 읽고 요구사항 분석, 구현 계획 수립, 코드 구현을 단일 세션에서 수행한다.

```bash
/implement-spec @Docs/20260411_travel-choice.md
```

### implement-agent

명세서를 기반으로 서브에이전트 파이프라인을 조율하여 대규모 구현을 진행한다. git 충돌 감지 후 analyzer → architect → coder → verifier 순서로 진행한다.

```bash
/implement-agent @Docs/20260411_travel-choice.md
```

---

## 마무리 단계

구현 완료 후 문서 업데이트와 커밋을 수행하는 스킬이다.

| 스킬 | 호출 | 역할 |
|------|------|------|
| `finalize-feature` | `/finalize-feature` | 기능 구현 완료 후 문서 정리 및 커밋 |
| `finalize-minor-task` | `/finalize-minor-task` | 소규모 작업 완료 후 아카이브 및 커밋 |
| `merge-changelog` | `/merge-changelog` | changelog fragment 병합 |

### finalize-feature

`implement-spec` 또는 `implement-agent` 이후에 사용한다. 관련 문서를 업데이트하고 git 커밋을 생성한다. push는 수행하지 않는다.

```bash
/finalize-feature
```

### finalize-minor-task

명세서 없이 수행된 소규모 작업(버그 수정, 밸런스 조정 등)을 정리한다. MinorTasks 아카이브에 변경 내역을 기록하고 커밋을 생성한다.

```bash
/finalize-minor-task
```

### merge-changelog

`changelog-fragments/` 디렉토리의 개별 fragment 파일들을 합산하여 `CHANGELOG.md`를 갱신한다. 릴리스 또는 정기 정리 시점에 사용한다.

```bash
/merge-changelog
```

---

## 문서 작성

| 스킬 | 호출 | 역할 |
|------|------|------|
| `docs-writer` | `/docs-writer` | 문서 작성, 검토, 편집 |

### docs-writer

`Docs/` 디렉토리의 파일이나 저장소의 모든 `.md` 파일을 대상으로 문서 작성, 검토, 편집을 수행한다. 기술 문서 톤(`~한다` 체)을 유지하며 프로젝트 문서 표준을 준수한다.

```bash
/docs-writer
```

---

## 전체 워크플로우

일반적인 기능 개발 흐름은 다음과 같다:

```
1. /content-designer    → 컨텐츠 기획서 작성
2. /balance-designer    → 밸런스 검토 (필요 시)
3. /spec-writer         → 개발 명세서 변환
4. /implement-spec 또는 /implement-agent → 코드 구현
5. /finalize-feature    → 문서 정리 및 커밋
```

소규모 작업(버그 수정, 수치 조정 등)의 경우:

```
1. 직접 작업 수행
2. /finalize-minor-task → 아카이브 및 커밋
```
