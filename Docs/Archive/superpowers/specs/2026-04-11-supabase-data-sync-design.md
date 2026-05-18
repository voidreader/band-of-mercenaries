# Supabase 정적 데이터 동기화 설계

> 작성일: 2026-04-11
> 상태: 승인됨

## 개요

기존 번들 JSON 기반 정적 데이터 로딩을 Supabase 서버 기반으로 전환한다. 클라이언트는 서버에서 데이터를 받아 로컬 JSON 캐시에 저장하고, 이후 접속 시 변경된 데이터만 갱신한다.

### 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 첫 실행 | 서버 연결 필수 (연결 실패 시 에러 화면) |
| 이후 실행 | 로컬 캐시로 오프라인 플레이 가능 |
| 싱크 타이밍 | 앱 시작 + 포그라운드 복귀 |
| 번들 JSON | 완전 제거 |
| 캐시 형식 | 로컬 파일시스템에 JSON 파일 |
| 연결 설정 | flutter_dotenv (.env) |
| 버전 관리 | 수동 발행 (operation-bom 관리자가 버튼 클릭) |
| 유저 데이터 | 로컬 Hive 유지 (이번 스프린트에서 계정 기능 없음) |
| 인증 | anon key로 읽기 전용 접근 (로그인 미구현) |

---

## 섹션 1: Supabase 인프라 (서버 측)

### data_versions 테이블

```sql
CREATE TABLE data_versions (
  table_name TEXT PRIMARY KEY,
  version    INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

- 11개 게임 데이터 테이블 각각에 대한 행 존재
- operation-bom 웹앱에서 관리자가 "버전 발행" 시 해당 테이블의 `version` +1, `updated_at` 갱신
- 클라이언트는 이 테이블만 조회하면 변경 테이블을 즉시 식별

### 초기 데이터

11개 행 삽입 (version=1):
`jobs`, `regions`, `traits`, `difficulties`, `quest_types`, `quest_pools`, `person_names`, `travel_events`, `facilities`, `ranks`, `mercenary_wages`

### RLS 정책

- SELECT: anon + authenticated 허용
- UPDATE: editor/admin만 허용

---

## 섹션 2: 데이터 싱크 흐름

### 앱 시작 / 포그라운드 복귀 시

```
앱 시작 or 포그라운드 복귀
  │
  ├─ 로컬 캐시 존재?
  │   ├─ NO (첫 실행)
  │   │   ├─ 서버 연결 성공 → 전체 11개 테이블 다운로드 → JSON 캐시 저장 → 게임 진입
  │   │   └─ 서버 연결 실패 → 에러 화면 (재시도 버튼)
  │   │
  │   └─ YES (재실행)
  │       ├─ 서버 연결 성공 → data_versions 조회 → 로컬 버전과 비교
  │       │   ├─ 변경 있음 → 해당 테이블만 다운로드 → 캐시 갱신 → 게임 진입
  │       │   └─ 변경 없음 → 캐시에서 로딩 → 게임 진입
  │       └─ 서버 연결 실패 → 캐시에서 로딩 → 게임 진입 (오프라인)
```

### 로컬 버전 관리

- Hive `settings` 박스에 `dataVersions` 키로 `Map<String, int>` 저장
- 예: `{'jobs': 3, 'regions': 2, 'traits': 3, ...}`
- 서버의 `data_versions`와 비교하여 버전이 다른 테이블만 식별

### 캐시 파일 구조

```
앱 문서 디렉토리/
  cache/
    jobs.json
    regions.json
    traits.json
    difficulties.json
    quest_types.json
    quest_pools.json
    person_names.json
    travel_events.json
    facilities.json
    ranks.json
    mercenary_wages.json
```

- Supabase 응답 `List<Map>` → 기존 래퍼 구조로 JSON 인코딩 (예: `{"Jobs": [...]}`) → 파일 저장
- 기존 모델의 `fromJson()`으로 파싱 가능한 형태 유지

---

## 섹션 3: Flutter 앱 — 패키지 및 코드 구조

### 추가 패키지

| 패키지 | 용도 |
|--------|------|
| `supabase_flutter` | Supabase 클라이언트 |
| `flutter_dotenv` | .env 파일에서 URL/Key 로딩 |

### 새로 추가되는 파일

```
lib/core/
├── data/
│   ├── data_loader.dart         # JsonLoader 대체. 캐시 파일 읽기 + Supabase 응답→모델 변환
│   ├── sync_service.dart        # 버전 비교 → 델타 다운로드 → 캐시 갱신
│   └── supabase_initializer.dart  # Supabase.initialize() + dotenv 로딩
```

### 수정되는 기존 파일

| 파일 | 변경 내용 |
|------|----------|
| `main.dart` | Supabase 초기화 추가, SyncService 호출 후 앱 진입 |
| `app.dart` | `didChangeAppLifecycleState`에서 포그라운드 복귀 시 싱크 트리거 |
| `static_data_provider.dart` | `rootBundle` 대신 `DataLoader`로 캐시 파일에서 로딩 |
| `hive_initializer.dart` | settings 박스에 dataVersions 저장 (기존 박스 재사용) |
| `pubspec.yaml` | 패키지 추가, assets/json/ 제거 |

### 삭제되는 파일

| 대상 | 이유 |
|------|------|
| `assets/json/*.json` (11개) | Supabase로 대체 |
| `lib/core/data/json_loader.dart` | DataLoader로 대체 |

### 변경 없는 파일

- 모든 정적 데이터 모델 (`core/models/*.dart`) — `fromJson()` 재사용
- 모든 feature 코드 — `staticDataProvider`를 통해 데이터 소비하므로 변경 불필요
- 유저 데이터 Hive 박스 (user, mercenaries, quests, activityLogs)

### DataLoader 역할

```dart
class DataLoader {
  // 캐시 JSON 파일에서 읽기 (File I/O, 기존 rootBundle 대체)
  // Supabase 응답 List<Map> → 모델 직접 변환 (fromJson 재사용)
  // 캐시 저장 (래퍼 구조 JSON 인코딩 → 파일 쓰기)
}
```

### SyncService 역할

```dart
class SyncService {
  // 1. 서버 data_versions 조회
  // 2. 로컬 버전(settings 박스)과 비교 → 변경된 테이블 목록
  // 3. 변경된 테이블만 Supabase select() 호출
  // 4. DataLoader로 캐시 JSON 저장 + 로컬 버전 갱신
  // 5. 캐시 존재 여부(첫 실행 판별) + 에러 핸들링
}
```

---

## 섹션 4: operation-bom 웹앱 — 버전 발행 기능

### DB 마이그레이션

- `002_data_versions.sql`: data_versions 테이블 생성 + 초기 행 삽입 + RLS 정책

### 웹앱 UI 변경

데이터 편집 페이지 (`/data/[table]`)에 추가:
- 페이지 상단에 현재 버전 번호 표시 (예: `v3`)
- "버전 발행" 버튼
- 확인 다이얼로그: "이 변경사항을 클라이언트에 배포하시겠습니까?"
- 발행 후 change_logs에도 기록

### 동작 흐름

```
관리자가 데이터 수정 (여러 행 편집 가능)
  │
  └─ 수정 완료 후 "버전 발행" 클릭
      ├─ data_versions UPDATE SET version = version + 1, updated_at = now()
      ├─ change_logs에 발행 기록 INSERT
      └─ UI에 새 버전 번호 반영
```

---

## 섹션 5: RLS 및 인증 전략

### 이번 스프린트

- 클라이언트 앱: 로그인 없음, anon key로 접근
- 유저 데이터: 로컬 Hive에만 저장

### RLS 정책 변경

기존 게임 데이터 테이블 11개 + data_versions에 anon SELECT 정책 추가:

```sql
CREATE POLICY "Allow anon read" ON [table] FOR SELECT TO anon USING (true);
```

### 보안 고려사항

- anon key + SELECT only → 읽기만 가능, 쓰기 불가
- 게임 데이터는 공개 정보(밸런스 수치)이므로 읽기 노출 위험 낮음
- 향후 로그인 구현 시 authenticated 기반으로 전환 가능
