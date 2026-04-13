### Phase 6: operation-bom 트레잇 웹앱 확장

- operation-bom에 트레잇 시스템 6개 테이블 CRUD 관리 기능 추가 (trait_categories, traits, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies)
- FieldType에 "json" 타입 추가 — JSONB 컬럼의 입력(Textarea + JSON 검증), 목록 축약 표시 지원
- 복합 PK 테이블(trait_conflicts) 지원 — 추가/삭제만 허용, 편집 링크 숨김
- 사이드바에 "트레잇" 카테고리 신설 (6개 테이블 + 시각화 페이지)
- 트레잇 관계 시각화 페이지 (/traits/visualization) — 충돌/단일 진화/조합 진화/시너지 4개 섹션, 카테고리 필터
