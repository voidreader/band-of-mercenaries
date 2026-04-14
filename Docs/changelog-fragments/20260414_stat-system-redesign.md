### 스탯 체계 재설계 — STR/INT/VIT/AGI 4스탯 전환

- 용병 스탯을 ATK/DEF/HP/speed에서 STR/INTELLIGENCE/VIT/AGI로 전환
- partyPower 계산을 퀘스트 유형별 가중치 공식으로 변경 (raid/hunt/escort/explore 각 가중치 차별화)
- AGI가 파견 소요 시간에 반영됨 (파티 평균 AGI 기반 속도 보정, 기준값 50)
- 기존 DEF·HP 유령 스탯 문제 해결 — VIT/INT로 퀘스트 전략 다양화
- Supabase jobs 테이블 컬럼 변환 및 85개 직업 INT 수치 직업 아키타입 기반 재설계
- operation-bom 웹앱 jobs 테이블 UI/타입 정의 갱신
