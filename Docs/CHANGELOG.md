# CHANGELOG

## 2026-04-11

### Features
- Supabase 기반 버전별 델타 동기화 시스템 구축 (1217d8b → 50437ee)
  - `SupabaseInitializer`: dotenv(.env) 기반 Supabase 연결 초기화 (2318607)
  - `DataLoader`: 캐시 파일 I/O 및 Supabase 응답 파싱 (9b5a9fb)
  - `SyncService`: `data_versions` 테이블 비교 → 변경 테이블만 다운로드하는 델타 동기화 (15c3270)
  - 앱 생명주기(시작 + 포그라운드 복귀)에 SyncService 통합 (ed6a6ab)

### Refactors
- 번들 JSON 파일 및 `JsonLoader` 제거 → Supabase 동기화로 대체 (e735d94)
- 전체 정적 데이터 모델 `@JsonKey` 어노테이션을 snake_case로 변환 (Supabase 컬럼명 일치) (5a896e5, 321c3b5)
- 캐시 저장소를 `path_provider` → Hive `staticDataCache` 박스로 교체 (웹 호환성) (3744a76)

### Docs
- Supabase 데이터 동기화 설계 스펙 및 구현 계획 추가 (6d285db, 3e3a92c)
- CLAUDE.md Supabase 데이터 동기화 아키텍처 반영 업데이트 (86dd3d6)

---

## 2026-04-10

- `update` (e3d7a6e)

---

## 2026-04-09

### Features
- 방치형 오프라인 보상 추가 (분당 1G, 최대 480G) (e3ddfed)
- 용병 방출 기능 추가 (퇴직금: 인건비 × 레벨) (0529a2e)
- 파견 중 이동 불가 제한 추가 (33983cf)
- 홈 화면에 용병 대시보드, 활동 로그, 퀘스트 완료 알림 추가 (37a04c8)
- Hive 기반 활동 로그 시스템 추가 (f52bc2e → f52bc2e)
- 파티 선택 UI를 드래그 가능한 바텀 시트로 교체 (f52bc2e)
- 활성 퀘스트가 최대치 미만일 때 퀘스트 채우기 버튼 추가 (6643e93)
- 대기 중 퀘스트 1시간마다 자동 갱신 + 카운트다운 타이머 (fc4ed52 → e2e2ced)
- 첫 실행 시 퀘스트 자동 생성 및 `createdAt` 필드 추가 (75995d8 → fc4ed52)
- 난이도별 min~max 범위 내 파견 비용 시간 비례 계산 (23c5201 → 75995d8)

### Bug Fixes
- `_showResult` 반환 타입을 `Future<void>`로 수정 (23c5201)
- 퀘스트 결과 다이얼로그 깜빡임 및 버튼 무반응 수정 (4ae9770)
- 시간 가속 시 모든 활성 타이머 endTime 재계산 수정 (d4cf610)

### Docs
- 20260409 요구사항 구현 계획 및 설계 문서 추가 (44f8902, 6f8c915)
- 구현 현황 업데이트 (3086895)
- Android 빌드 설정 가이드 추가 (aa27f2d)

---

## 2026-04-08

### Features
- 파견 비용/수익 분석 UI 추가 및 스탯 표시 수정 (9691d4a)
- 용병 모집 시 주둔지 용량 제한 적용 (ddafea8 → 731ed72)
- 레벨/XP 표시, 랭크 배지, 이동 이벤트 다이얼로그, 리전 잠금 UI 추가 (ddafea8)
- 시설 관리 화면 및 업그레이드 UI 추가 (0127bdf)
- 명성 랭크 기반 리전 티어 잠금 추가 (3fcb8fe)
- 퀘스트 완료 흐름에 XP, 명성, 시설 효과 통합 (3a780a8)
- 퀘스트 시스템에 파견 비용 및 인건비 차감 통합 (92c68ba)
- 이동 시스템에 이동 이벤트 통합 (af86de2)
- `ReputationService`: 랭크 결정 및 리전 접근 가능 여부 계산 (3f25caf)
- `FacilityService`: 업그레이드 검증 및 효과 계산 (3ec0554)
- `ExperienceService`: XP 계산 및 레벨업 로직 (61a19d8)
- `QuestCalculator`에 인건비 및 파견 비용 계산 추가 (3ec83aa)
- `TravelEventService`: 이벤트 확률, 필터링, 지연 처리 (f83ad6f)
- `UserData` 모델에 명성 및 시설 필드 추가 (de09320 → d0bc294)
- `Mercenary` 모델에 XP/레벨 필드 및 레벨 기반 스탯 보너스 추가 (d1fe218 → de09320)
- 새 정적 데이터 모델 `JsonLoader` 및 `StaticDataProvider`에 연결 (d1fe218)
- JSON 데이터 파일 추가 및 `Difficulty`에 파견 비용 필드 추가 (93d15bd)
- 이동 이벤트, 시설, 랭크, 인건비 정적 데이터 모델 추가 (97fd136 → 174be2f)

### Docs
- 게임 깊이 및 목표 시스템 구현 계획 추가 (97fd136)
- 브레인스토밍 미래 아이디어 문서화 (f9a2e3e)
- 게임 깊이/목표 설계 스펙 및 미래 아이디어 문서 추가 (d0df72f)

### Chore
- Android 플랫폼 추가 및 테스트 오류 수정 (ab4f9ff)

---

## 2026-04-07

### Features
- `main.dart` 추가: Hive 초기화 및 앱 부트스트랩 (2edd4ae)
- 모집 화면, 용병 카드, 설정 화면 추가 (e0f1a89)
- 파견 화면 및 퀘스트 결과 다이얼로그 추가 (6014878)
- 이동 화면: 리전/섹터 선택 UI (6dd0bbb)
- 하단 네비게이션, 홈 화면(야영지 페인터), 앱 셸 추가 (c809a5e)
- 용병/퀘스트/이동 Provider 및 게임 로직 통합 (642992b)
- 용병/퀘스트/이동 Repository 추가 (3de9691)
- 정적 데이터, 타이머, 게임 상태 핵심 Provider 추가 (4a1e3aa)
- 앱 테마, `StatusBadge`, `TimerDisplay` 위젯 추가 (5228482)
- `RecruitmentService` 및 `QuestGenerator` 추가 (전체 테스트 포함) (086d478)
- `QuestCalculator` 추가: 성공률, 결과, 피해, 소요시간 로직 (5e01cbe)
- Hive 어댑터 및 `HiveInitializer`가 포함된 런타임 데이터 모델 추가 (32b096a)
- 모든 정적 데이터 파싱 메서드 포함 `JsonLoader` 추가 (b2e283c)
- freezed + json_serializable 정적 데이터 모델 추가 (f6c4f42)
- Flutter 프로젝트 초기화: 의존성 및 디렉토리 구조 (8f0f8dd)

### Docs
- 프로토타입 구현 계획 추가 (3c222f2)
- 프로토타입 설계 스펙 추가 (de75b52)

### Chore
- Claude Code 설정 파일 추가 (9ee3f86)
- `.gitignore` 추가 (2ad86de)
- 나머지 미추적 파일 추가 (Docs, Json, iOS 빌드 아티팩트) (4ae0349)
