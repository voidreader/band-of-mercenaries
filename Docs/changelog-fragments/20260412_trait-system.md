### 트레잇 시스템 고도화 (Phase 1-2)

- Supabase에 트레잇 시스템 6개 테이블 생성 (trait_categories, traits, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies)
- 106개 트레잇 + 관계 데이터 (충돌 16쌍, 단일진화 16개, 조합진화 15개, 시너지 39개) 입력
- Flutter 모델 교체 (TraitData 구조 변경 + 5개 신규 모델 추가)
- SyncService 16개 테이블 동기화 대응
- 트레잇 카테고리 기반 색상 시스템 적용
- 기존 하드코딩 트레잇 효과 비활성화 (Phase 3 데이터 드리븐 구현 예정)
