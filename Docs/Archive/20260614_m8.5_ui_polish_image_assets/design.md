# UI 폴리싱 1차 + 이미지 에셋 적용 컨텐츠 기획서

> 작성일: 2026-06-14
> 유형: 고도화 (UI 폴리싱 + 이미지 인프라 신설)
> 마일스톤: M8.5 페이즈 4 #5
> 입력 의존: 페이즈 1 전체(특히 `[content]20260520_m8.5_livingsphere_dashboard.md`) + 페이즈 3 #1 이미지 에셋 메타데이터 통합 위임 결정(2026-05-22)

## 개요

M8.5 "재미 가시화" 마일스톤의 마지막 시각 정리 단계다. M4~M8b에서 쌓인 기능들이 각 화면에 적층되면서 정보 위계가 평평해졌고, 모든 시각 요소가 이모지/`CustomPainter`에 의존해 "텍스트 더미"처럼 보인다. 본 기획은 두 가지를 동시에 해결한다.

1. **이미지 인프라 신설** — 현재 코드베이스에 `Image` 위젯이 단 하나도 없다(이모지·`campsite_painter` 뿐). 신규 `image_assets` 테이블 + 재사용 `GameImage` 위젯 + placeholder URL 정책을 구축하고, 지역 썸네일·세력 엠블럼·아이템 아이콘·6지표 아이콘 4종 슬롯을 실제 화면에 배치한다. **실제 이미지 파일이 없는 현 상태를 graceful fallback(이모지/색상 박스)으로 흡수**하고, M9 디자인 작업 시 DB의 URL만 `UPDATE`하면 코드 변경 없이 이미지가 노출되게 한다.
2. **UI 폴리싱 1차** — 홈/파견/이동/제작 4개 화면의 정보 위계를 재정렬하고, 카드 위계를 통일하며, 요약↔상세 전환을 정비한다.

기대 효과: "지금 무엇을 완성하고 있는가"(생활권·세력)와 "내 용병이 어떤 이야기를 만들었는가"(전투·위업)가 한눈에 들어오고, M9 이미지 작업이 데이터 갱신만으로 끝나는 무중단 파이프라인을 확보한다.

## 레퍼런스 분석

- **Melvor Idle (아이콘 우선 위계)** — 순수 텍스트 게임이지만 모든 스킬·아이템·적에 일관된 정사각 아이콘을 부여해 스캔성을 극적으로 높였다. 아이콘은 의미의 "앵커" 역할을 하고 텍스트는 보조한다. 본 기획의 아이템 아이콘·6지표 아이콘 슬롯이 이 패턴을 차용한다. 단, Melvor는 전 콘텐츠 아이콘을 보유한 반면 우리는 **아이콘 부재를 fallback으로 흡수**하는 점이 다르다.
- **Kingdom of Loathing (미니멀 + 점진 도입)** — 흑백 라인 아트 위주로 시작해 점진적으로 시각을 보강한 게임. 이미지가 없어도 게임이 성립하도록 설계됐다. 우리의 "URL null → 이모지 fallback" 정책이 이 철학과 일치한다.
- **OGame / 아크메이지 (정보 위계 계층화)** — 한 화면에 정보가 많을 때 "요약 카드 → 펼침 상세" 2단계로 누르는 패턴. 홈 화면의 9개 블록 적층 문제를 카드 위계 통일 + 요약↔상세로 푼다.
- **공통 교훈** — 텍스트 기반 게임에서 이미지는 "필수"가 아니라 "스캔성 가속기"다. 따라서 이미지 인프라는 **있으면 좋고 없어도 동작**해야 하며, 이것이 fallback-first 설계의 근거다.

## 상세 설계

### A. 이미지 인프라

#### A-1. `image_assets` 테이블 (신규, Supabase 정적 데이터)

정적 데이터 동기화 파이프라인(`SyncService` → `data_versions` → 로컬 JSON 캐시 → `DataLoader` → `StaticGameData`)에 편입되는 43번째 테이블.

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `asset_key` | TEXT PK | 전역 고유 키. 예: `region_thumb_3`, `faction_emblem_adventurer_guild`, `item_icon_equip_weapon_beast_tool`, `dashboard_metric_stability`, `livingsphere_bg_dustplain` |
| `category` | TEXT NOT NULL | `region_thumbnail` / `faction_emblem` / `item_icon` / `dashboard_metric_icon` / `livingsphere_background` (CHECK 제약) |
| `entity_id` | TEXT NULL | 매핑 대상 엔티티 키. region은 INT를 TEXT로, faction은 faction key, item은 item id, dashboard_metric은 지표 key. background/글로벌은 NULL |
| `url` | TEXT NULL | 이미지 CDN URL. **M8.5 시점 전 행 NULL**(또는 placeholder CDN 경로). M9에서 `UPDATE`로만 갱신 |
| `width` | INT NULL | 권장 표시 폭(px) |
| `height` | INT NULL | 권장 표시 높이(px) |
| `fallback_emoji` | TEXT NULL | URL null/로딩 실패 시 표시할 이모지(카테고리 기본값을 행별로 오버라이드 가능) |
| `updated_at` | TIMESTAMPTZ | 갱신 추적 |

> **설계 판단**: 엔티티(region/faction/item)별로 행을 폭증시키지 않는다. M8.5 시점에는 **카테고리 대표 placeholder 행 + 실제 슬롯이 붙는 핵심 엔티티 행만** 최소 등록(아래 데이터 섹션 참조). `GameImage`는 `asset_key`로 우선 조회하고, 없으면 `category` 기본 fallback으로 떨어진다. 따라서 region 40개·item 다수에 일일이 행이 없어도 동작한다.

#### A-2. `GameImage` 재사용 위젯 (신규, `shared/widgets/`)

```
GameImage({
  required String? assetKey,      // image_assets 조회 키 (null이면 즉시 fallback)
  required ImageAssetCategory category,  // fallback 결정용
  String? fallbackEmoji,          // 행/호출부 오버라이드
  Color? fallbackBg,              // 색상 박스 배경 (예: tierBgColor, factionColor)
  double? width, height,
  BorderRadius? borderRadius,
})
```

렌더 결정 순서(결정적):
1. `assetKey`로 `staticData.imageAssets` 조회 → `url`이 non-null이고 유효 → `Image.network`(또는 `cached_network_image`) 렌더. `loadingBuilder`(shimmer/색상 박스), `errorBuilder`(fallback으로 폴백).
2. `url`이 null이거나 조회 실패 → **fallback 렌더**: 둥근 사각 색상 박스 위에 이모지(행 `fallback_emoji` > 호출부 `fallbackEmoji` > 카테고리 기본 이모지) 중앙 배치.
3. 카테고리 기본 이모지/색상: region_thumbnail=🗺/`dangerLevelColor`, faction_emblem=🔱/세력색, item_icon=`slot`별 이모지/`tierBgColor`, dashboard_metric_icon=지표별 이모지, livingsphere_background=🏕/`surfaceAlt`.

> 네트워크 이미지 캐싱은 spec 단계에서 `Image.network` 기본 캐시로 충분한지, `cached_network_image` 패키지 도입이 필요한지 결정(권장: M8.5는 전 URL null이므로 패키지 도입 보류, 기본 `Image.network` + `errorBuilder`로 시작).

#### A-3. placeholder URL 관리 정책

- M8.5 시점: 모든 `url = NULL`. 화면은 100% fallback으로 동작 → **시각 회귀 없음**(현재 이모지 표시와 동일하거나 더 정돈된 색상 박스).
- M9 디자인 작업: 이미지 파일 제작 → CDN 업로드 → `image_assets.url` `UPDATE` + 필요 시 행 추가. **코드·앱 배포 불필요**, 정적 데이터 동기화(`data_versions` 버전 증가)로 자동 반영.
- 완료 기준 충족: M8.5에서는 "슬롯이 정확히 자리잡고 fallback이 깔끔하게 동작"하는 것으로 "2종 이상 반영" 기준을 충족(슬롯 노출 자체가 반영). 실제 픽셀 이미지는 M9.

### B. 이미지 슬롯 4종 배치 위치

| 슬롯 | 화면/위젯 | 매핑 소스 | 권장 사양 | fallback |
|------|----------|----------|----------|----------|
| **지역 썸네일** | 이동 화면 지역 그리드 카드 + 생활권 대시보드(`LivingsphereSummarySection`) 헤더 배경 | `region` 테이블(`region` id) | 512×288 (16:9) | 🗺 + dangerLevel 색 박스 |
| **세력 엠블럼** | 정보 탭 `FactionCodexScreen` 리스트 leading + `FactionDetailScreen` 헤더 | `faction` 테이블(faction key) | 128×128 (정사각) | 🔱 + 세력 대표색 박스 |
| **아이템 아이콘** | 인벤토리 5탭 카드 leading + 제작 `RecipeCard` 결과/재료 | `items` 테이블(item id) | 96×96 (정사각) | slot별 이모지 + tier 배경색 |
| **6지표 카테고리 아이콘** | 생활권 대시보드 6지표(안정도·거점·사건·자원·영향력·위업) | `image_assets` dashboard_metric(고정 6키) | 96×96 | 지표별 이모지(🛡🏘📜📦🔱★) |

> 생활권 배경 썸네일(1024×512)은 대시보드 컨셉에서 언급된 글로벌 1장으로 `livingsphere_background` 카테고리에 별도 등록(선택). 핵심 4종은 위 표.

### C. 4화면 UI 폴리싱 1차

공통 원칙: **카드 위계 3단계 통일** — (1) 섹션 카드(`surfaceAlt` 배경 + `borderLight` 보더 + radius 8, 기존 대시보드/활동로그 스타일을 표준으로 승격), (2) 강조 카드(accent 보더 — chainGold/namedAccent 등 기존 유지), (3) 인라인 행. 신규 공용 위젯 `SectionCard`(헤더 + 본문 슬롯)로 반복 패턴을 흡수하되, **기존 강조 카드(간판용병/연대기/생활권)의 accent 보더는 보존**한다.

#### C-1. 홈 (`home_screen.dart`)
현재 9블록 적층(TopBar→Rank→Investigation→용병단현황→진행상황→간판용병→연대기→생활권→활동로그). 문제: 모두 같은 시각 무게라 위계가 평평함.
- **상단 고정 영역**(스크롤 밖): TopBar + Rank + Investigation 유지(상태 요약).
- **스크롤 영역 카드 위계 재정렬**: ① 진행상황 패널을 `SectionCard`로 카드화(현재 top border만 있는 평면), ② 간판용병 → 생활권 대시보드 → 연대기 순으로 "내 용병/내 거점/내 역사" 의미 그룹화(현재 간판→연대기→생활권 순을 간판→생활권→연대기로 — 거점 진행을 역사보다 위로), ③ 활동로그 최하단 유지.
- 용병단 현황(`_DashboardSection`)은 상단 요약 카드로 유지.

#### C-2. 파견 (`dispatch_screen.dart`)
현재 6계층 정렬(`sortedPendingQuestsProvider`) + `QuestCardBadges` + `LayerSidebar`는 이미 잘 구조화됨. 폴리싱 포인트:
- 퀘스트 카드 leading에 **지역 썸네일 미니(40×40 GameImage)** 추가 → 어느 지역 의뢰인지 시각 스캔. fallback 시 기존처럼 텍스트만.
- 진행 중 의뢰 블록과 가능 의뢰 목록의 시각 구분 강화(섹션 카드 헤더 통일).
- 요약↔상세: `QuestResultDialog`의 인라인 detail 전환(이미 구현됨)은 유지, 추가 작업 없음.

#### C-3. 이동 (`movement_screen.dart`)
- 지역 그리드 카드에 **지역 썸네일** 적용(카드 배경 또는 leading). `RegionStatusBadgeRow`/`LivingsphereJumpBar`는 유지.
- 변형 섹터 아이콘(🏘🏛✨)은 이모지 유지(이미 의미 확립). 썸네일과 충돌하지 않게 배지로 오버레이.

#### C-4. 제작 (`recipe_card.dart`, `material_item_card.dart`)
- `RecipeCard` 결과물 + 재료에 **아이템 아이콘** 적용. 4상태(locked/insufficient/ready) 시각은 유지하되 아이콘으로 결과물 가독성 강화.
- 인벤토리 `MaterialTab` 카드 leading에 동일 아이콘.

### D. AppTheme 확장 + 문서 정정

- **테마 정책 확정**: 현재 `AppTheme`는 실제로 **라이트 테마**(`background #F5F5F5`, `surface #FFFFFF`)다. 이를 정식으로 인정하고, `CLAUDE.md`·`Docs/game_overview.md`의 "Material 3 다크 테마" 표기를 **"Material 3 라이트 테마"로 정정**한다(코드 변경 없음, 문서만). 다크 테마 전환은 별도 마일스톤 위임.
- **AppTheme 확장**: 폴리싱에 필요한 토큰만 추가. 후보 — 카드 elevation/shadow 토큰(현 elevation 0 유지하되 강조 카드용 선택적 shadow), 이미지 fallback 박스 표준 배경색, 섹션 헤더 TextStyle 상수(현재 화면마다 `fontSize: 13~15, w600~700` 산재 → `AppTheme.sectionTitle` 등으로 통일). **신규 색상 남발 금지** — 기존 상수(tier/danger/accent) 재사용 우선.

## 현재 시스템과의 연관

- **정적 데이터 파이프라인**: `image_assets`는 기존 42개 테이블과 동일하게 `SyncService`·`DataLoader`·`StaticGameData`·`staticDataProvider`에 편입. 신규 freezed 모델 `ImageAsset` + `StaticGameData.imageAssets` 필드 추가, snake_case `@JsonKey`. 코드 생성(`build_runner`) 필요.
- **Hive 영속성**: 영향 없음. `image_assets`는 정적 데이터(로컬 JSON 캐시)이며 유저 데이터(Hive 박스)와 무관. **신규 typeId 불필요**.
- **영향받는 화면**: 홈/파견/이동/제작 + 정보 탭(세력 엠블럼)·인벤토리(아이템 아이콘). 모두 기존 위젯에 `GameImage` 삽입 + 카드 위계 정리 수준의 비파괴 변경.
- **호환성/회귀 리스크**: 낮음. URL 전부 null이므로 시각적으로는 현재와 동등하거나 개선(색상 박스 정돈). `flutter analyze`/`flutter test` 게이트는 페이즈 4 #7에서 통합 검증. 단, `Image.network` 도입으로 위젯 테스트에서 네트워크 호출 mock 필요(전 URL null이면 fallback 경로만 타므로 테스트 영향 최소).
- **선행 의존**: 페이즈 1 #1 생활권 대시보드(이미 구현, 6지표 슬롯 위치 확정). 페이즈 4 #1~#4 구현 완료 상태이므로 본 #5는 그 위에 시각 레이어만 추가.

## 구현 우선순위 제안

| 우선순위 | 항목 | 이유 |
|---------|------|------|
| **높음** | A. 이미지 인프라(`image_assets` 테이블 + `ImageAsset` 모델 + `GameImage` 위젯 + fallback) | 모든 슬롯의 토대. 이게 없으면 B 불가 |
| **높음** | B. 지역 썸네일 + 6지표 아이콘 슬롯(이동·홈 대시보드) | 완료 기준 직결 + 가장 노출 빈도 높은 동선 |
| **중간** | B. 세력 엠블럼 + 아이템 아이콘 슬롯(정보·제작·인벤토리) | 완료 기준 초과 달성. 동선 빈도 상대적 낮음 |
| **중간** | C. 4화면 카드 위계 폴리싱 + `SectionCard` 공용 위젯 | 시각 정돈. 기능 비파괴 |
| **낮음** | D. AppTheme 토큰 확장 + 문서 정정 | 코드 영향 최소, 문서 작업 |

> 단일 spec으로 묶되, spec 내 FR/TASK는 위 우선순위 순서로 배열 권장. implement-agent의 순차 격리 모드에 적합(인프라 TASK → 슬롯별 TASK → 폴리싱 TASK).

## data-generator 지시사항

> **data-generator 미사용 권장.** `image_assets`는 placeholder 메타데이터(전 URL null)이며 벌크 텍스트 생성이 불필요하다. 또한 data-generator에 `image-asset` 타입 스펙이 부재하다. 따라서 페이즈 4 #5 spec에서 **CREATE TABLE + 최소 INSERT를 SQL로 인라인 작성**(spec 산출물의 SQL 블록, 실제 Supabase 적용은 별도 승인)한다.

- **인라인 SQL 대상 테이블**: 신규 `image_assets`
- **최소 INSERT 행 구성**(M8.5 placeholder, 전 `url=NULL`):
  - `dashboard_metric_icon` 6행 — 안정도/거점/사건/자원/영향력/위업 (고정 키, 대시보드 직결)
  - `livingsphere_background` 1행 — 더스트플레인 배경
  - `region_thumbnail` — M7 핵심 7리전(3·31·127·9·10·146·38) 대표 행 7개(나머지 region은 카테고리 fallback)
  - `faction_emblem` — 대표 3세력(모험가/상인/전사) + 필요 시 핵심 세력, ~3~5행
  - `item_icon` — 카테고리 fallback으로 충분하므로 0행 시작 가능(또는 대표 1~2행 샘플)
  - 합계 ≈ 17~21행(소량, 인라인 적합)
- **톤/세계관 가이드**: `fallback_emoji`는 기존 게임 내 확립된 이모지 재사용(🗺🔱★🏘📜📦 등). 신규 이모지 도입 자제.
- **수치 출처**: 이미지 사양(px)은 본 기획 B표 + 대시보드 컨셉(썸네일 1024×512, 아이콘 96×96) 기준. 밸런스 무관.
- **특수 요구**: `url` 전 행 NULL 시작. M9 갱신 시 `data_versions` 버전 증가 필수(동기화 트리거).
