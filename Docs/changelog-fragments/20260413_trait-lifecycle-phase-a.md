### Phase A: 트레잇 라이프사이클 완성

- 후천 트레잇 삭제 시스템 추가 (acquired 200G / evolved 500G, 의무실 레벨 해금)
- 용병 상세 오버레이에서 TraitDetailDialog 연결 (트레잇 탭 → 상세 다이얼로그)
- 트레잇 히스토리에 삭제 구분 표시 (`(삭제)` 라벨)
- 여행 이벤트로 빈 선천 슬롯에 트레잇 부여 (3종 신규 이벤트: 혹독한 지형/노련한 여행자/재능의 발현)
- TravelEvent 모델에 targetCategory 필드 추가
- trait_innate 이벤트 재롤링 로직 (최대 3회)
