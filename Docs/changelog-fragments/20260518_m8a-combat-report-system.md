### M8a 전투 보고서 시스템 MVP — 요약·상세 영속 보고서

- 중요한 의뢰(세력 지명·기존 지명·엘리트·연계·세력 전용 고급) 완료 시 요약(1~다문장) + 상세 로그(4~8줄) 보고서가 1회 생성되어 의뢰에 영속 저장된다.
- 결과 다이얼로그에 `📜 전투 보고서` 요약 카드 노출. `[상세 보고서 보기]` 버튼 탭 시 동일 다이얼로그가 인라인으로 상세 뷰로 전환(Navigator.push 미사용, 150ms 페이드).
- 상세 뷰는 결과 색상 4종(대성공/성공/실패/대실패) 좌측 4px 보더 + 주인공·동료 칩. 닫은 후 동일 의뢰 재진입 시 동일 보고서가 동일하게 표시됨(재렌더 금지).
- `CombatReportService.generate` 14단계 helper — scope 7종(`chain_final`/`chain_step`/`settlement_event`/`unique_elite`/`elite`/`faction_named`/`quest_type`) + `scene` 보충풀 fallback 시퀀스. importance 3단계(normal/high/veryHigh)로 요약·상세 줄 수 차등.
- TemplateEngine에 `{ally.name}`·`{enemy.name}` namespace 추가. `enemy.name`은 엘리트 → 의뢰 풀 → 키워드 가중 random → `'적'` 4 우선순위 해석.
- `combat_report_templates` 96행 + `combat_report_keywords` 40행 신규 정적 테이블. 둘 다 optional table — 마이그레이션 미적용 환경에서도 빈 데이터로 fail-soft.
- Hive 신규: `CombatReport` typeId 21(HiveField 0~7), `ActiveQuest.combatReport` HiveField 27 임베드, `ActivityLogType.combatReportGenerated` HiveField 39.
- 결과 다이얼로그 닫힘 이후 장기 재열람·실제 턴 기반 전투 엔진 연결은 M8b/M8.5/M9에서 후속 처리.
