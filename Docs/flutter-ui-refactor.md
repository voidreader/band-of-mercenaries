# 목표
현재 Flutter UI 코드가 하나의 파일에 길게 작성되어 있어 가독성과 유지보수성이 떨어진다.
이를 프로젝트 아키텍처에 맞는 실무 수준의 구조로 리팩토링한다.

---

# 리팩토링 요구사항

## 1. 위젯 분리
- 하나의 Screen에 있는 UI를 의미 단위로 분리한다
- 각 UI 블록은 별도의 위젯으로 분리한다
- Provider를 읽지 않는 위젯은 StatelessWidget, Provider를 읽는 위젯은 ConsumerWidget을 사용한다
- 위젯은 재사용 가능하도록 설계한다

## 2. 파일 구조 분리
- 각 feature는 `view/`, `domain/`, `data/` 3계층을 유지한다
- 화면과 위젯은 모두 `view/` 폴더 아래에 배치한다
- 폴더 구조는 다음과 같이 구성한다:

```
features/{feature_name}/
  view/
    {feature_name}_screen.dart
    {widget_name}.dart
  domain/
  data/
```

## 3. 빌드 메서드 단순화
- build() 내부는 최대한 간결하게 유지한다
- 중첩 depth가 깊어지지 않도록 위젯으로 분리한다

## 4. 스타일 분리
- TextStyle, Color는 `core/theme/`에서 중앙 관리한다 (신규 스타일 파일을 `shared/styles/`에 별도로 만들지 않는다)
- EdgeInsets, 크기 값 등 spacing 상수는 `core/theme/` 또는 해당 위젯 파일 상단에 private 상수로 선언한다
- 매직넘버 사용 금지

## 5. const 적극 사용
- 가능한 모든 위젯에 const 키워드를 사용한다

## 6. 네이밍 규칙
- 위젯 이름은 역할 기반으로 명확하게 작성한다
  (예: QuestCardWidget, MercenaryProfileHeader)
- 파일명은 위젯 클래스명의 snake_case로 한다
  (예: quest_card_widget.dart, mercenary_profile_header.dart)

## 7. 공통 위젯 분리

- 반복적으로 사용되는 UI 요소는 공통 위젯으로 분리한다
- 공통 위젯 위치: `shared/widgets/`
- 공통 위젯도 Provider를 읽는 경우 ConsumerWidget을 사용한다

```
shared/widgets/
  bottom_nav_bar.dart       # 하단 탭 바
  timer_display.dart        # 타이머 표시
  status_badge.dart         # 용병 상태 뱃지 (정상/피곤/부상/사망)
  tier_badge.dart           # 티어 배지 (T1~T5, 색상 자동 적용)
  card_container.dart       # 카드 스타일 컨테이너 (surface + border + borderRadius)
  empty_state_widget.dart   # 빈 상태 메시지 (Center + textHint)
```

**공통 위젯 사용 가이드:**
- `TierBadge(tier: n)` — T1~T5 배지. `fontSize`, `padding` 파라미터로 크기 조정
- `CardContainer(child: ...)` — 기본 카드 스타일. `color`로 surfaceAlt 전환, `padding`으로 간격 조정
- `EmptyStateWidget(message: '...')` — 목록이 비어있을 때 사용. Center+Text 구조

**추출 기준:** 동일한 패턴이 **3개 파일 이상**에서 반복될 때 공통 위젯으로 추출한다. 변형이 있는 유사 패턴은 각 feature에 두는 것이 낫다.

---

## 8. 공통 스타일 관리

- TextStyle, Color는 `core/theme/`에서 통합 관리한다
- 기존 `core/theme/` 파일을 먼저 확인하고, 없는 경우에만 추가한다
- `shared/styles/` 디렉토리는 생성하지 않는다 (core/theme/과 역할 중복)

---

## 9. 중복 제거

- 동일한 구조의 위젯이 2회 이상 등장하면 공통 위젯으로 추출한다
- 하드코딩된 값 제거 (폰트, 색상, 패딩 등)

---

## 10. 재사용성 고려

- 공통 위젯은 다양한 상황에서 사용할 수 있도록 파라미터화한다

예:
```dart
AppButton(title: '확인', onPressed: () {})
```

---

## 11. 화면 전환

- `Navigator.push`를 사용하지 않는다
- 화면 전환은 상태 기반 렌더링으로 처리한다 (Navigator가 ConstrainedBox 바깥으로 빠져나가는 문제 방지)
- 상세 페이지는 부모 위젯의 상태 변수로 조건부 렌더링한다

예:
```dart
// 올바른 방식
if (_selectedId != null)
  return DetailPage(id: _selectedId!);
return ListPage();

// 금지
Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage()));
```

---

# 금지사항
- 하나의 파일에 모든 코드를 몰아서 작성하지 말 것
- `StatefulWidget` 남용 금지 — Provider를 읽을 때는 ConsumerWidget, 로컬 상태가 필요할 때만 StatefulWidget/ConsumerStatefulWidget 사용
- `ConsumerWidget` 대신 StatelessWidget에 억지로 props drilling하지 말 것
- 의미 없는 위젯 분리 금지 (너무 잘게 쪼개지 말 것)
- `shared/styles/` 디렉토리 신규 생성 금지 (core/theme/ 사용)
- Navigator.push 사용 금지 (상태 기반 렌더링 사용)

---

# 공용 위젯 적용 이력

## 2026-04-25 — 1차 공용 위젯 추출

**추출된 위젯 3종 (shared/widgets/)**
| 위젯 | 대체한 패턴 | 적용 파일 수 |
|---|---|---|
| `TierBadge` | `Container + BoxDecoration(tierBg) + Text('T$n')` | 5개 파일 |
| `CardContainer` | `Container + BoxDecoration(surface/surfaceAlt + borderLight)` | 3개 파일 |
| `EmptyStateWidget` | `Center(child: Text(msg, textHint))` | 1개 파일 |

**TierBadge 적용 파일:**
- `features/info/view/guild_equipment_screen.dart` — private `_TierBadge` 클래스 제거
- `features/info/view/guild_equipment_equip_sheet.dart`
- `features/inventory/view/inventory_item_card.dart`
- `features/inventory/view/item_detail_sheet.dart`
- `features/inventory/view/essence_select_sheet.dart`

**CardContainer 적용 파일:**
- `features/mercenary/view/trait_history_section.dart`
- `features/movement/view/movement_screen.dart` (2곳)
- `features/info/view/faction_detail_screen.dart` — private `_SectionCard` typedef로 교체

**EmptyStateWidget 적용 파일:**
- `features/inventory/view/inventory_screen.dart` — `_buildEmptyState()` 메서드 제거

**스킵 판단:**
- `mercenary_detail_overlay.dart` — 'T$jobTier $jobName' 형식으로 TierBadge와 다름
- `equipment_slot_grid.dart` — 매우 compact한 변형 (fontSize:9), 별도 유지
- `home_screen.dart` CardContainer — `margin` 있어 패턴 불일치, 스킵
- `SectionHeader` 패턴 — 변형이 많아 과추상화 위험, 스킵

---

## 2026-04-25 — 2차 대형 파일 위젯 분리

private 클래스 및 빌드 메서드 그룹을 별도 `view/` 파일로 추출. 분리 기준: 100줄 이상이거나 독립적인 UI 단위.

| 원본 파일 | 분리 전 | 분리 후 | 생성 파일 |
|---|---|---|---|
| `mercenary_detail_overlay.dart` | 673줄 | 448줄 | `mercenary_profile_header.dart`, `mercenary_role_synergy_section.dart` |
| `trait_detail_dialog.dart` | 703줄 | 370줄 | `trait_evolution_section.dart`, `trait_synergy_conflict_section.dart` |
| `faction_detail_screen.dart` | 695줄 | 507줄 | `faction_join_section.dart`, `faction_top_bar.dart` |

**분리된 위젯 목록:**

`mercenary/view/`
- `MercenaryStatChip`, `MercenaryXpBar` → `mercenary_profile_header.dart`
- `MercenarySynergySection`, `MercenaryRoleBonusChip` → `mercenary_role_synergy_section.dart`
- `TraitEvolutionSection` → `trait_evolution_section.dart` (단일/조합 진화 카드, 조건 진행도)
- `TraitSynergyConflictSection` → `trait_synergy_conflict_section.dart`

`info/view/`
- `FactionTopBar` → `faction_top_bar.dart`
- `FactionReputationBar`, `FactionJoinConditions`, `FactionConditionRow`, `FactionVisibilityBadge` → `faction_join_section.dart`

---

## 현재 상태 (2026-04-25 기준)

### shared/widgets/ 등록 위젯 (6개)
| 위젯 | 역할 | 주요 사용처 |
|---|---|---|
| `BottomNavBar` | 하단 6탭 바 | app.dart |
| `TimerDisplay` | 타이머 표시 | home, movement, dispatch |
| `StatusBadge` | 용병 상태 뱃지 | mercenary_card, mercenary_detail_overlay |
| `TierBadge` | T1~T5 티어 배지 | inventory, info 5개 파일 |
| `CardContainer` | 카드 스타일 컨테이너 | mercenary, movement, info 5개 파일 |
| `EmptyStateWidget` | 빈 상태 메시지 | inventory_screen |

### 잔여 대형 파일 (분리 검토 대상)
| 파일 | 라인 수 | 비고 |
|---|---|---|
| `home_screen.dart` | 604줄 | ConsumerStatefulWidget, 다이얼로그 체이닝 복잡 |
| `dispatch_screen.dart` | 540줄 | _QuestCard 이미 ConsumerWidget으로 분리됨 |
| `trait_evolution_dialog.dart` | 520줄 | StatefulWidget, 상태 중앙 관리 필요 |
| `faction_detail_screen.dart` | 507줄 | _FactionBody.build() 여전히 300줄+ |
| `investigation_widget.dart` | 499줄 | 이미 ConsumerWidget 다수 분리됨 |
| `mercenary_detail_overlay.dart` | 448줄 | 2차 분리 후 현재 수준 |

**분리 스킵 사유**: `trait_evolution_dialog`는 StatefulWidget 상태(`_selectedIndex`, `_cards`)가 모든 빌드 메서드에 공유되어 분리 시 상태 전달 복잡도 급증. `dispatch_screen`은 다이얼로그 체이닝(`_showResult` → `_showTraitEvents`)이 context/ref를 직접 사용하여 위젯으로 추출 어려움.
