### M8b 페이즈 4 — 턴 기반 전투 시뮬레이터 시스템 통합

- 특별 의뢰(엘리트·체인 핵심/최종·지명·고급 트랙 세력)에 결정적 4 페이즈 턴 전투 시뮬레이터(`CombatSimulator`) 도입. 일반 의뢰는 기존 `QuestCalculator` 성공률 fallback 유지.
- 시뮬레이션 결과를 `QuestCompletionService.calculate()` 내부에서 `combatSimulationEligible` 판정 후 호출하여 `resultType`·`mercDamages`를 결정. 보상·XP·명성·eliteLoot은 결정된 resultType 기반으로 재계산.
- `CombatReport`(typeId 21)에 HiveField 8~14 확장(`schemaVersion`·`combatantSnapshots`·`turns`·`exitCondition`·`objectiveProgress`·`enemySnapshots`·`statusEffectHistory`). M8a 기존 보고서는 nullable로 자연 호환.
- 신규 Hive 모델 6종 + Hive enum 3종 추가 (typeId 22~30 점유): `CombatSimulationResult`·`CombatTurn`·`CombatAction`·`StatusEffectEvent`·`CombatantSnapshot`·`EnemySnapshot` + `CombatExitCondition`·`BehaviorPattern`·`PositionRow`.
- 정적 카탈로그 freezed 모델 3종 + enum 7종 추가: `CombatSkill`·`CombatStatusEffect`·`EnemyArchetype` + `ApplyMethod`·`StackPolicy`·`ActionCost`·`TriggerKind`·`TargetingKind`·`DispelKind`·`EnemyKind`.
- Supabase 정적 데이터 신규 3 테이블 추가(`combat_skills` 16행 / `combat_status_effects` 10행 / `enemies` 26행). `combat_report_templates`에 신규 scope `combat_skill` + 85행 INSERT(M8a 96 + M8b 85 = 총 181행).
- `CombatReportService.generate()`에 `simulationResult: CombatSimulationResult?` 인자 추가. 시뮬레이션 결과 존재 시 protagonist/featuredMercIds/toneTags를 우선 사용하고 구조 필드 6종 최소 임베드. 템플릿 선택 실패 시에도 fallback 보고서 반환.
- 엘리트 유니크 첫 처치 위업 hook과 region_state trailing(`eliteRegionStateMapping`)에 `resultType ∈ {success, greatSuccess}` guard 추가 — 실패한 전투가 처치/지역 안정화로 기록되는 것을 방지.
- 체인 주인공 사망 저항 90% 상한 활성화를 위해 `_completeQuest`에서 `ChainQuestProgress.protagonistMercId`를 `quest.specialFlags['chain_protagonist_id']`에 런타임 병합.
- 시뮬레이션 결과의 deceased는 legendary ⑤ canPrevent 평가 후 다운그레이드 호환. 부상 회복 시간은 기존 공식(`difficulty.level × 10분 / speedMultiplier × infirmary × passive`) 그대로 적용.
- fail-soft fallback 5종: 일반 의뢰 / userData null / simulate null 반환 / simulate throw / quest.startTime null. 모든 경로에서 게임 흐름이 멈추지 않도록 `try/catch + debugPrint + QuestCalculator fallback` 보장.
