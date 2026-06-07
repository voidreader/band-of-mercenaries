# M8.5 #4 용병 상세 화면 전투 기억·히든 스탯·개인 숙련도 섹션 구현 계획·결과

Skill used : implement-agent

> 명세서: `Docs/spec/[spec]20260607_m8.5_mercenary_detail_sections.md`
> 구현일: 2026-06-07
> 마일스톤: M8.5 페이즈 4 #4

## 1. 개요

M8.5 #3(커밋 `288fc71`)에서 완비된 전투 기억·히든 스탯 데이터/도메인 계층을 용병 상세 화면과 연대기 추모 카드에 노출하는 **순수 UI 표시 계층** 작업. 신규 데이터 모델·Provider·Hive 필드·build_runner 변경 없음(읽기 전용).

핵심 산출:
- 신규 섹션 위젯 3종: `HiddenStatsSection`(히든 스탯 lv1+ 진행도) / `BattleMemorySection`+공개 `BattleMemoryCard`(전투 기억 6 entryType) / `MasteryProgressSection`(솔로 숙련 카운터 + 미획득 칭호 진행도)
- `MercenaryDetailOverlay` 섹션 통합(TitlesSection→Mastery→Hidden→Battle→BehaviorStats) + FR-5 shrink 빈 공백 방지
- `ChronicleScreen._MemorialCard` 펼침 전환(동결된 titleIds/hiddenStats/battleMemories 열람)

## 2. 실행 모드 / 검증 모드

- **실행 모드**: 순차 격리 모드 (TASK 9개 ≥ 5). 의존성 순서로 1 TASK씩 처리, 각 TASK 직후 verifier(spec)→flutter-reviewer(quality) two-stage review.
- **검증 모드**: 순차 격리 final integration. PHASE 2 내부 루프에서 TASK별 검증 완료 후, PHASE 3-C에서 task 간 통합 sanity check.
- **빌드 게이트(PHASE 2.5)**: `flutter analyze` error 0(info 1건 — combat_report_service.dart:166 `use_null_aware_elements`는 #3 기존 lint, 본 작업 무관) / `flutter test` 789 PASS(기존 762 + 신규 27).

## 3. TASK별 결과 요약

| TASK | 내용 | 모델 | verifier | flutter-reviewer |
|------|------|------|----------|------------------|
| 1 | HiddenStatsSection 위젯 | sonnet | PASS (1회) | APPROVE (1회) |
| 2 | BattleMemorySection + 공개 BattleMemoryCard | opus | PASS (1회) | APPROVE with warnings (1회) |
| 3 | MasteryProgressSection 위젯 | sonnet | PASS (1회) | BLOCK→수정→APPROVE (2회) |
| 4 | MercenaryDetailOverlay 섹션 통합 (+3섹션 간격 처리) | sonnet | PASS (1회) | APPROVE (1회) |
| 5 | ChronicleScreen._MemorialCard 펼침 전환 | sonnet | PASS (1회) | APPROVE (1회) |
| 6~9 | 위젯 테스트 4종 (27 케이스) | sonnet | PASS (1회) | APPROVE (1회) |

> TASK-4는 planner 추천(haiku)에서 sonnet으로 상향 — 4파일 수정 + shrink 간격 로직 복잡도 반영.

### 수정된 이슈 (재작업)
- **TASK-3 ISSUE-1 (high, `[flutter-reviewer]`)**: `_buildCounterSummary` private 메서드가 Widget 반환 → `_CounterSummary extends StatelessWidget` 위젯 추출, `_counterLabels` static const 이동. 재검증 APPROVE.
- **TASK-3 ISSUE-2 (medium, `[flutter-reviewer]`)**: `firstWhere`+`cast`+`orElse:()=>null` → `firstWhereOrNull`(collection 패키지). 재검증 APPROVE.

### 미해결 권고 (기록, 폴리싱 위임)
- **TASK-2 (medium, APPROVE with warnings)**: `BattleMemoryCard.build`의 `_buildTemplateCard`/`_buildAchievementCard`/`_buildTitleCard`가 `ref.watch`를 패스스루하며 Widget 반환(안티패턴). 기능 위험 없음. 추후 ConsumerWidget 추출 권장(TASK-3과 달리 이 리뷰어는 medium으로 분류, 통과 처리). 향후 `/simplify` 또는 폴리싱 단계에서 정리 가능.

## 4. 변경 파일 목록

### 신규 생성 (위젯 3)
| 파일 | 설명 |
|------|------|
| `band_of_mercenaries/lib/features/mercenary/view/hidden_stats_section.dart` | `HiddenStatsSection`(ConsumerWidget) + `_HiddenStatCard` + 효과 한국어 라벨 3맵(combat/passive/postReward). lv1+ 노출, lv0 전체 시 shrink, lv5 "★ 최대 도달" 배지, 진행도 바(카운터/다음 임계), 표시 시 상단 Padding(16) |
| `band_of_mercenaries/lib/features/mercenary/view/battle_memory_section.dart` | `BattleMemorySection`(ConsumerWidget) + **공개 `BattleMemoryCard`**(ConsumerWidget, merc nullable) + `_iconColorFor`(9행)/`relativeTime`/`_fallbackLine`. timestamp desc, 6 entryType 분기(템플릿 4종 TemplateEngine·lookup 2종), 빈 캐시 fallback, achievement 탭→정보탭/ChronicleScreen 진입 |
| `band_of_mercenaries/lib/features/mercenary/view/mastery_progress_section.dart` | `MasteryProgressSection`(ConsumerWidget) + `_CounterSummary`(StatelessWidget) + `_MasteryTitleRow` + `_MasteryEntry`. 4 카운터 요약 + 전용 4 칭호(hookCondition stat_key/threshold 동적 추출 + 상수 fallback) 진행도, 보유 ✓ 배지 |

### 신규 생성 (테스트 4)
| 파일 | 케이스 |
|------|--------|
| `test/features/mercenary/view/hidden_stats_section_test.dart` | 6 |
| `test/features/mercenary/view/battle_memory_section_test.dart` | 6 |
| `test/features/mercenary/view/mastery_progress_section_test.dart` | 9 |
| `test/features/achievement/view/chronicle_screen_test.dart` | 6 |

### 수정
| 파일 | 변경 |
|------|------|
| `band_of_mercenaries/lib/features/mercenary/view/mercenary_detail_overlay.dart` | import 3개 + TitlesSection 직후 Mastery→Hidden→Battle 삽입, 3섹션 앞/사이 SizedBox 제거(섹션 내부 상단 패딩이 간격 담당), BehaviorStats 앞 SizedBox(16) 유지 |
| `band_of_mercenaries/lib/features/achievement/view/chronicle_screen.dart` | `_MemorialCard` ConsumerWidget→ConsumerStatefulWidget 전환, `_expanded` 펼침, titleIds 칩/hiddenStats lv1+ 요약/battleMemories(BattleMemoryCard merc:null 재사용) 표시, mercSnapshot null 시 펼침 비활성, 셋 다 비면 "기록 없음" |

## 5. build_runner

**불요** — freezed/json_serializable/hive/riverpod 모델 변경 없음(읽기 전용 UI).

## 6. CLAUDE.md 준수

- 위반 없음. 상태 기반 렌더링 준수(setState 펼침, 탭 점프는 currentTabProvider, Navigator.push 미사용). 색상 AppTheme 중앙 관리(슬픔 💧 옅은 블루 `_sorrowBlue`만 위젯 내 로컬 const — 명세 허용). ConsumerWidget/ConsumerStatefulWidget 적정. 주석 한국어.

## 7. 기술 노트

- **TemplateContext 매핑** (planner 발견): `TemplateContext`는 templateData Map을 직접 받지 않음. `BattleMemoryCard`는 `userDataProvider`의 user + 인자 merc 주입 + `templateData['enemy']/['ally']`→`enemyName`/`allyName` 매핑. quest 토큰은 본체 부재로 미해결 가능 → `_fallbackLine` 흡수. user null 시 원본 문자열 반환 fail-soft.
- **탭 점프**: achievement_granted 카드 탭 → `infoScreenAutoShowChronicleProvider=true` + `currentTabProvider=5`(goal_card.dart 동선 재사용). title_granted 탭 무동작(FR-8 Q-4).
- **결정성**: 전투 기억 템플릿 다중 매칭 시 `templateKey` 1순위 → `id` asc 첫 행(Math.random/hashCode 금지, 재방문 텍스트 고정).
- **테스트 격리**: `box.watch()` 무한 Stream은 mocktail Box mock(`watch()→Stream.empty()`), `gameTickProvider`는 empty Stream override로 차단(pumpAndSettle hang 방지).
