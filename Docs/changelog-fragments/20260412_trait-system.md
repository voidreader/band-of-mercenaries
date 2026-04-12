### 트레잇 시스템 고도화 (Phase 1-2)

- Supabase에 트레잇 시스템 6개 테이블 생성 (trait_categories, traits, trait_conflicts, trait_transitions, trait_combo_evolutions, trait_synergies)
- 106개 트레잇 + 관계 데이터 (충돌 16쌍, 단일진화 16개, 조합진화 15개, 시너지 39개) 입력
- Flutter 모델 교체 (TraitData 구조 변경 + 5개 신규 모델 추가)
- SyncService 16개 테이블 동기화 대응
- 트레잇 카테고리 기반 색상 시스템 적용

### 트레잇 시스템 핵심 엔진 (Phase 3)

- 행동 지표 추적 시스템: 23개 지표(파견/생존/퀘스트유형/경제/연속기록) 퀘스트 완료 시 자동 갱신
- 용병 모집 변경: 선천 트레잇 1~3개 랜덤 부여 (Physical/Background/Talent 카테고리별 선택)
- 트레잇 획득 엔진: 행동 지표 → acquisition_condition 비교 → 시너지 감소 → 충돌 검증 → 자동 획득
- 데이터 드리븐 트레잇 효과: effect_json 기반 성공률/사망률/부상률 보정 (밸런스 수치는 향후 입력)
- quest type ID 변경: loot → raid (약탈)
- UI: 용병 카드에 복수 트레잇 뱃지 표시
