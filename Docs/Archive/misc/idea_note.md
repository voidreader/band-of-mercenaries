## 특수 몬스터 토벌 퀘스트

- 정수 획득 (게임 속 바바리안으로 살아남기)
- 넘버스 아이템 획득 (게임 속 바바리안으로 살아남기)

## 숨겨진 필드 퀘스트

## Trait

특성 쌓는 김전사

## 용마검전

## 흑백 분위기

## 메모라이즈, 멸망한 세계의 사냥꾼 2018년 06.01까지 검색완료

프로듀서가 레퍼런스로 삼고 있는 판타지 세계관은

- '특성 쌓는 김전사' (작가 산호초)
- '메모라이즈' (작가 로유진)
- '게임 속 바바리안으로 살아남기 (작가 정윤강)
- '용마검전' (작가 김재한)

숨겨진 지역, 고대 유적, 연계 퀘스트, 유저간 경쟁, 몬스터에게 획득하는 희귀한 정수(게임속 바바리안으로 살아남기), 특수한 아이템(게임 속 바바리안으로 살아남기) , 특수직업(메모라이즈),
용마기 (용마검전), 여러 세력, 진영, 거점 혹은 도시 점령, 미궁 등 후보는 다양하다.



-----
  명세서 생성 완료

  파일: Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md

  핵심 반영사항

  - HiveField 충돌 회피: Mercenary.permanentStr/Intelligence/Vit/Agi를 사용자 지침대로 HiveField 19~22에 할당 (18은
  legendaryDeathPreventionCooldownUntil 점유 중).
  - effective 공식 통일: (base + permanent + equipment) × (1 + levelBonus) × fatigueMod — 요구사항 그대로 반영. 단 essence_system.md의 "비증폭 가산"
  서술과 충돌하는 부분은 Q-1로 기획 확인 사항에 명시(산출물 2의 장비 증폭 구현과의 일관성을 우선 채택).
  - 진입 경로 2종: 경로 A(용병 상세 → 정수 선택 시트) / 경로 B(인벤토리 → 아이템 상세 → 용병 선택 시트) 양방향 모두 필수로 구현, 공통
  EssenceApplyPreviewDialog로 재사용.
  - 3단계 경고: normal / approaching(잔량 < 다음 1회 효과) / overflow(손실 발생).
  - 사망·방출 소멸: 별도 보존 로직 없이 용병 삭제와 함께 자연 소실. 활동 로그 3종(essenceApplied/essenceLostOnDeath/essenceLostOnRelease) 추가.
  - 인벤토리 진입 위치: 정보 탭 4번째 ListTile(_showInventory) — 기존 _showGuildEquipment 패턴 재사용(Q-2).

  구현 규모: implement-agent 추천 (6/6점)

  신규 클래스 10+, HiveField 확장, 사망·방출 경로 수정, UI 신설이 얽혀 있어 파이프라인(planner→coder→verifier) 방식으로 진행 권장.

  /implement-agent @Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md  ← 추천
  /implement-spec @Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md


  공통 참고 파일(AppTheme, ItemData 등)을 1회 요약해서 planner 산출물에 포함 → coder가 재탐색 불필요.