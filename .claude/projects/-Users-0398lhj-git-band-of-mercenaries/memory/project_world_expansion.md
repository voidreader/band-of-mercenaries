---
name: 세계 확장 시스템 기획 확정
description: 지역 조사, 아이템, 엘리트 몬스터, 연계 퀘스트, 지역 변형, 세력 발견 — 6 Phase 로드맵이 2026-04-13에 확정됨
type: project
---

세계 확장 시스템 기획서가 `docs/content-design/20260413_world_expansion_system.md`에 확정 저장됨 (2026-04-13).

Phase 1~6 로드맵:
1. 지역 조사 + 지역 상태 (region_discoveries 테이블, regionStates Hive 박스)
2. 아이템 인프라 (items 테이블, inventory Hive 박스, 장비 슬롯: 개인 3종 + 용병단 2종 + 소모형)
3. 엘리트 몬스터 (elite_monsters, elite_loot_tables, 반복 파밍 가능)
4. 숨겨진 연계 퀘스트 (chain_quests, target_region_id로 지역 이동 포함)
5. 지역 변형 (village/ruins/hidden_sector)
6. 세력 발견 (factions, clue_level 1~3 점진 공개)

각 Phase에 operation-bom 웹앱 CRUD UI 포함.
개발 단계에서는 최소 검증용 데이터만 넣고 기능 완성 우선.

향후 Phase 7~13: 마을 평판, 세력 가입/기여도/상점, 스탯 세분화(근력/내구/민첩/마력/체력), 스킬 시스템, 세력 경쟁/PvP.

**Why:** 프로듀서가 "이런 것도 있어?" 반응을 유저에게 이끌어내는 자율성 강화 컨텐츠를 원함. 현재 파견→결과 단일 루프 외의 다양한 강화 경로와 세계 상호작용이 필요.
**How to apply:** 이 기획서를 기반으로 spec-writer → implement-spec 파이프라인으로 Phase별 구현 진행. 밸런스 수치는 balance-designer로 별도 검증.
