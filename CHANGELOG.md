# Changelog

## 2026-04-11

### 파견 화면 개선
- 바텀시트를 전체화면 파견 페이지로 교체 (`DispatchDetailPage`)
- 3단 레이아웃: 상단 퀘스트 정보 고정 / 중앙 용병 목록 스크롤 / 하단 비용 요약 + 파견 버튼 고정
- 사망/파견중 용병을 목록에서 제외하여 불필요한 스크롤 제거
- 부상 용병은 표시하되 선택 불가 + 빨간 "부상" 태그
- SafeArea 적용으로 Android/iOS 하단 가림 방지
- 웹에서 Navigator.push 대신 상태 기반 렌더링으로 ConstrainedBox 너비 유지

### 퀘스트 완료 팝업 보상 내역
- 보상 상세 섹션 추가: 기본 보상, 파견 비용, 인건비, 순수익, 획득 경험치, 획득 명성
- 성공 시 버튼 텍스트: "확인" → "🪙 NNG 보상 수령"
- 실패 시 버튼 텍스트: "확인" 유지
- `ActiveQuest` 모델에 보상 필드 5개 추가 (HiveField 12-16: rewardGold, totalWage, dispatchCost, earnedXp, earnedReputation)

### 홈 화면 최근활동 스크롤
- Column → ListView.builder로 변경하여 스크롤 지원
- 최대 표시 개수: 10개 → 100개 (스크롤)
- 저장소 최대: 50개 → 100개
