# M8a 세력 상점 상품 데이터

> 작성일: 2026-05-18
> 데이터 파일: `Docs/content-data/[faction-shop]20260518_m8a-faction-shop-items.csv`
> 입력 문서:
> - `Docs/content-design/[content]20260518_m8a_faction_vertical_slice.md`
> - `Docs/balance-design/[balance]20260518_m8a_faction_shop_unlocks.md`

## 생성 범위

- 세력 상점 상품 18개
- 세력당 6개
- 가격 범위 80~700G
- 해금 평판 1, 11, 21, 31, 61 사용

## 테이블 후보

신규 테이블 `faction_shop_items`를 권장한다.

| 컬럼 | 의미 |
|------|------|
| `faction_id` | `factions.id` |
| `item_id` | 기존 또는 신규 `items.id` |
| `price_gold` | 구매 가격 |
| `min_reputation` | 세력 평판 해금 조건 |
| `requires_joined` | 정식 가입 필요 여부 |
| `unlock_type`, `unlock_value` | 접촉점, 지역 플래그, 세력 평판 조건 |
| `stock_policy` | `once` 또는 `daily` |
| `stock_limit`, `restock_hours` | 제한 재고 수량과 갱신 시간 |
| `grant_type` | 단일 아이템 또는 번들 |

## 구현 메모

- `material_bundle` 상품은 실제 구매 시 `item_id` 1개를 지급하는 단순 번들로 시작해도 된다.
- 제한 재고는 M8a에서는 24시간 기준을 권장한다.
- 신규 `item_id` 일부는 `[item]20260518_m8a-faction-rewards.csv` 또는 페이즈 4 명세에서 `items` 확장 후보로 다룬다.
- 기존 `items`에 존재하는 M7 재료는 그대로 참조한다.

## 자체 검증

- 상품 수는 페이즈 목표 15~24개 범위 안이다.
- 세력당 상품 수가 6개를 넘지 않는다.
- region_exclusive 재료는 일일 1개 제한으로 작성했다.
- Supabase에는 아직 쓰지 않았다.
