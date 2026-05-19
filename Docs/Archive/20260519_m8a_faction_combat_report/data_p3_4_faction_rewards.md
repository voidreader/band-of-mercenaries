# M8a 세력 전용 보상 데이터

> 작성일: 2026-05-18
> 데이터 파일:
> - `Docs/content-data/[faction-reward]20260518_m8a-faction-rewards.csv`
> - `Docs/content-data/[item]20260518_m8a-faction-rewards.csv`
> 입력 문서:
> - `Docs/content-design/[content]20260518_m8a_faction_vertical_slice.md`
> - `Docs/balance-design/[balance]20260518_m8a_faction_shop_unlocks.md`
> - `Docs/balance-design/[balance]20260518_m8a_faction_quest_rewards.md`

## 생성 범위

- 세력 전용 보상 6개
- 신규 `items` 후보 4개
- 칭호 2개와 레시피 2개는 구현 명세용 보상 레코드로 정의했다.

## 설계 판단

현재 `items` 스펙은 장비 중심이고, `titles`와 세력 보상 지급 테이블은 M8a 전용 구조가 아직 없다. 따라서 페이즈 3에서는 실제 삽입 가능한 `items` 후보와, 페이즈 4 명세에서 풀어야 할 보상 매핑 CSV를 분리했다.

## 페이즈 4 필요 결정

- `crafting_recipes.unlock_condition_json`에 `factionReputation` 조건을 추가할지 결정한다.
- `TitleService`에 세력 보상 hook을 추가할지, 별도 세력 보상 서비스에서 칭호를 지급할지 결정한다.
- 세력 보상 지급 이력을 `FactionState`에 둘지 별도 테이블 또는 Hive 필드에 둘지 결정한다.
- `guild_equipment` T3 보상 수치가 기존 용병단 장비와 중첩될 때 상한을 검토한다.

## 자체 검증

- 전용 보상은 세력당 2개다.
- 신규 아티팩트·장비는 3~6개 목표 범위 안인 4개다.
- 전사 길드 보상은 직접 성공률 상승 대신 VIT 보조로 제한했다.
- Supabase에는 아직 쓰지 않았다.
