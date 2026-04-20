# M2a 실행 상태

> 시작: 2026-04-18T00:00:00+09:00
> 마지막 업데이트: 2026-04-20T08:00:00+09:00
> 현재 페이즈: 완료
> 상태: completed
> 페이즈 순서: 1 → 2 → **4 → 3** (swap: items 테이블 마이그레이션 선행 필요)

## 로드맵 요구사항 요약

- 테마: 아이템/장비 인프라 + 정수(영구 스탯 강화) 경로를 깐다. 드랍 경로 없이 operation-bom 수동 지급으로 검증
- 포함 시스템: 아이템/장비 인프라 단일 (ItemData 모델, inventory Hive 박스, 장착/해제, 정수 소모, 인벤토리 UI)
- 선행 의존성: M1 완료. M2a는 M2b/M3/M4의 선행 조건
- 스키마 확장: Supabase `items` 테이블 신설, `data_versions` 행 추가, Hive `inventory` 박스 신설
- 검증용 최소 데이터: 정수 4종, 개인 장비 6~8종, 용병단 장비 3~4종

## 페이즈 1: 컨텐츠 설계

**상태**: completed

계획된 산출물:
- [x] 1. 아이템 분류 체계 설계 — 개인 장비(무기/방어구/장신구) + 용병단 장비(군기/유물) + 소모품(정수/일반)의 계층, slot 정의, 티어 정책
  - 참고 문서: Docs/roadmap/master_roadmap.md (M2a 섹션), Docs/game_overview.md
  - 산출물: Docs/content-design/[content]20260418_item_taxonomy.md
  - 완료: 2026-04-18T18:52:00+09:00
- [x] 2. 정수 시스템 기획 — 4종(힘/수호/생명/상급) 각각의 효과, 영구 스탯 강화 규칙, 소비 UX
  - 참고 문서: 산출물 1 + 기존 STR/INT/VIT/AGI 스탯 시스템
  - 산출물: Docs/content-design/[content]20260418_essence_system.md
  - 완료: 2026-04-18T21:07:00+09:00
  - 비고: 로드맵 "정수 4종"을 "T1 대표 4종"으로 재해석, T2~T5 확장하여 총 20종 체계로 확정. 페이즈 3 데이터 수량 20종으로 조정 필요
- [x] 3. 검증용 초기 아이템 세트 컨셉 — 개인 장비 6~8종 + 용병단 장비 3~4종의 테마/서사/이름 풀
  - 참고 문서: 산출물 1, 2
  - 산출물: Docs/content-design/[content]20260418_initial_item_set.md
  - 완료: 2026-04-18T21:28:00+09:00
  - 비고: 개인 장비 6종(weapon 1/armor 1/helmet 1/boots 1/accessory 2) + 용병단 장비 4종(banner 1+artifact 3) + 정수 20종 수식어 체계 = 총 30종 생성 계획 확정. 정수 수식어 시간/연대 계열(T1 기본/T2 오래된/T3 고대의/T4 태고의/T5 태초의). 전설 1종 후보 3안 제시. 티어 분포 가이드라인(못박지 않음)

## 페이즈 2: 밸런스 확정

**상태**: completed

계획된 산출물:
- [x] 1. 장비 스탯 보정 수치표 — 티어 2~5별 무기/방어구/장신구 스탯 보정 범위, 기존 성공률 공식 대비 영향 측정
  - 입력: 페이즈 1 산출물 1
  - 산출물: Docs/balance-design/20260418_equipment_stats.md
  - 완료: 2026-04-18T22:23:00+09:00
  - 비고: B 스케일(+25~35%) + B 곡선(+3/+6/+10/+15) + 슬롯 가중치(1.0/1.0/0.8/0.8/0.6) + 전설 B+D 하이브리드(×1.2 + 유니크 효과 5카테고리 전부 허용) + effect_json 단일 주스탯 정책 확정
- [x] 2. 정수 영구 스탯 강화 수치 + 인플레이션 시뮬레이션 — 정수 1~N개 누적 사용 시 스탯 곡선, 성공률 변화율, M2b 드랍 속도 대비 장기 목표 곡선
  - 입력: 페이즈 1 산출물 2
  - 산출물: Docs/balance-design/20260418_essence_inflation.md
  - 완료: 2026-04-18T23:53:00+09:00
  - 비고: 효과 곡선 +1/+2/+4/+7/+11 유지, 상한 +10/+20/+40/+70/+120 유지(의미 재정의 "극한 투자 천장"), M6 승급 비용 옵션 B(승급 우위) T1→T5 총 140개, 사망·방출 전액 소멸 유지, 상한 초과 손실 UX 3단계 확정, M2b 드랍 역산 가이드 제공
- [x] 3. 용병단 장비 전체 효과 범위 — 군기/유물의 전체 용병 적용 효과 강도, 파티 전력 영향
  - 입력: 페이즈 1 산출물 1
  - 산출물: Docs/balance-design/20260418_guild_equipment_macro.md
  - 완료: 2026-04-19T10:16:00+09:00
  - 비고: 3슬롯 + 4종 경쟁 구조 확정(artifact 3택2), A 경미 스케일, 전설 규격 보류(M2a 범위 외), 4종 확정 수치(깃발 reputation+0.05/gold+0.02, 저울 gold+0.03, 뿔피리 recruit+0.02, 방패 injury-0.07), injury_rate_modifier 곱셈+하한 0.10, reputation_gain_modifier 신규 상한 +0.30, 효과 타입 카탈로그 16→18 확장

## 페이즈 3: 데이터 생성

**상태**: completed

계획된 산출물:
- [x] 1. 정수 데이터 × 20 — `items` 테이블에 essence 카테고리 투입 (4축 × 5티어)
  - 입력: 페이즈 1 산출물 2 + 페이즈 2 산출물 2
  - 대상 테이블: `items`
  - 선행 과제: `.claude/skills/data-generator/types/essence.md` 타입 스펙 작성 — **완료 (2026-04-19T10:27:00+09:00)**
  - 산출물: Docs/content-data/[essence]20260420_m2a-essences.csv + [essence]20260420_m2a-essences.md
  - 완료: 2026-04-20T07:38:00+09:00
  - 비고: data-generator로 20종 전체 생성 (STR/INT/VIT/AGI × T1~T5 매트릭스), Supabase `items` 20행 INSERT 완료 + `data_versions.items` version 1→2 bump. DB check constraint에 맞춰 slot은 `essence_{stat}`(tier suffix 없음) + tier 컬럼 조합 방식 채택(id는 유니크용 `essence_{stat}_t{tier}`). 수치 엄수(T1=1/T2=2/T3=4/T4=7/T5=11 단일 축). 후속 권고: `types/essence.md`의 slot 형식 표기를 DB 규약과 일치시키는 수정 필요
- [x] 2. 장비 데이터 × 10 — 개인 장비 6 + 용병단 장비 4
  - 입력: 페이즈 1 산출물 1, 3 + 페이즈 2 산출물 1, 3
  - 대상 테이블: `items`
  - 선행 과제: `.claude/skills/data-generator/types/item.md` 타입 스펙 작성 — **완료 (2026-04-19T10:29:00+09:00)**
  - 산출물: Docs/content-data/[item]20260420_m2a-equipment.csv + [item]20260420_m2a-equipment.md
  - 완료: 2026-04-20T07:55:00+09:00
  - 비고: data-generator로 10종 생성(개인 6: weapon/armor/helmet/boots/accessory×2 / 용병단 4: banner + artifact×3), Supabase `items` 10행 INSERT 완료 + `data_versions.items` version 2→3 bump. 전설 A안(멸혼결, accessory, damage_resistance category, vit+11/injury-0.10/death-0.05) 채택. 티어 분포(개인): 권장(T2×1/T3×2/T4×2/T5×1) 대신 컨셉 기획서 권장 티어대 우선으로 T2×1/T3×3/T4×1/T5×1 채택. 용병단 장비 4종은 guild_equipment_macro 고정 스펙 그대로

**선결 조건 알림:** `items` 테이블 자체가 Supabase에 미존재. 페이즈 4 spec-writer의 DB 마이그레이션 산출물 1 선행 권장. 또는 페이즈 3에서 CSV만 먼저 생성하고 마이그레이션 완료 후 INSERT 순서도 가능.

## 페이즈 4: 개발 명세

**상태**: completed

계획된 산출물:
- [x] 1. 아이템/인벤토리 인프라 명세 — `ItemData` Freezed 모델, `InventoryItem` Hive 모델, `inventory` 박스, `InventoryRepository`, SyncService 확장, Supabase `items` 테이블 마이그레이션
  - 입력: 페이즈 1 산출물 1 + 페이즈 2 산출물 1
  - 산출물: Docs/spec/[spec]20260419_m2a-item-inventory-infrastructure.md
  - 완료: 2026-04-19T15:24:00+09:00
  - 비고: **명세 작성 + implement-agent 파이프라인 완주 + Supabase MCP 마이그레이션 적용까지 본 세션에서 전부 완료**. Flutter 측 ItemData/InventoryItem/InventoryRepository/HiveInitializer/SyncService/staticDataProvider/UserData 확장 모두 반영, build_runner 재생성, flutter analyze 0 issues, flutter test 300/300 pass (신규 InventoryRepository 8건 포함). Supabase `items` 테이블 생성 + RLS 5정책 + `data_versions('items')` 행 적용 (MCP `apply_migration` 이름 `007_items_table`, 적용 후 `data_versions` 19행 확인). operation-bom `table-config.ts` 추가는 후속 일괄 작업으로 연기. 구현 결과 문서: Docs/spec/[spec]20260419_m2a-item-inventory-infrastructure_plan.md
- [x] 2. 장비 장착/해제 + effective 스탯 명세 — `ItemEffectService`, 용병 상세 오버레이 장비 슬롯 UI, effectiveStr/Agi/Int/Vit 재계산 경로, 용병단 장비 3슬롯 UI(artifact 3택2), 전설 유니크 효과 5 카테고리 분기, PassiveBonusService 확장(16→18개 효과 타입, injury_rate_modifier 곱셈, reputation_gain_modifier 가산 상한 +0.30)
  - 입력: 페이즈 4 산출물 1 + 페이즈 2 산출물 1, 3
  - 산출물: Docs/spec/[spec]20260419_m2a-item-equipment-effects.md
  - 완료: 2026-04-19T20:25:00+09:00
  - 비고: **명세 작성 + implement-agent 파이프라인 완주 본 세션에서 전부 완료**. 16 TASK 6단계 분해 → coder 병렬 실행 → verifier 2회(1차 FAIL ISSUE-1, 2차 PASS). 전설 ① success_rate_bonus 공유 ±10%p clamp 구현을 위해 QuestCalculator 3 메서드에 legendarySuccessBonus 파라미터 추가. flutter analyze 0 issues, 341/341 tests pass(신규 29건 추가). build_runner 2회 재생성(Stage 1·Stage 2 후). 구현 결과 문서: Docs/spec/[spec]20260419_m2a-item-equipment-effects_plan.md
- [x] 3. 정수 사용 + 인벤토리 UI 명세 — `EssenceService`(영구 스탯 강화), Mercenary 모델 확장(HiveField 19~22 permanent_*), effective 공식 확장, 인벤토리 화면(카테고리 필터), 아이템 상세 팝업, 정수 사용 연출, 프리뷰 팝업(상한 초과 경고), 사망·방출 시 소멸 UI
  - 입력: 페이즈 4 산출물 1 + 페이즈 2 산출물 2
  - 산출물: Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md
  - 완료: 2026-04-20T00:00:00+09:00
  - 비고: **명세 작성 + implement-agent 파이프라인 완주 본 세션에서 전부 완료**. HiveField 충돌 회피로 permanent_*를 19~22에 할당(18은 legendaryDeathPreventionCooldownUntil 점유). 16 TASK 8단계 분해 → coder 병렬 실행 → verifier 1회 PASS(with warnings) — Minor 이슈 3건 중 프리뷰 헤드 숫자 반영 1건 수정, 나머지 2건 후속 과제 이관. build_runner 2회 재생성. flutter analyze 0 issues, 363/363 tests pass(신규 22건 추가). home_screen.dart _logIcon switch 확장(enum 추가 파생 수정). 결과 문서: Docs/spec/[spec]20260419_m2a-essence-inventory-ui_plan.md

## 실행 이력

- 2026-04-18T00:00:00+09:00: 마일스톤 시작
- 2026-04-18T00:00:00+09:00: 4개 페이즈 산출물 계획 승인 (페이즈 1: 3개 / 페이즈 2: 3개 / 페이즈 3: 2개 / 페이즈 4: 3개)
- 2026-04-18T00:00:00+09:00: 페이즈 1 진입
- 2026-04-18T18:52:00+09:00: 페이즈 1 산출물 1 "아이템 분류 체계 설계" 완료 (Docs/content-design/[content]20260418_item_taxonomy.md)
- 2026-04-18T21:07:00+09:00: 페이즈 1 산출물 2 "정수 시스템 기획" 완료 (Docs/content-design/[content]20260418_essence_system.md). 정수 체계 20종(4축×5티어)로 확장, 페이즈 3 정수 데이터 수량 4→20 조정
- 2026-04-18T21:28:00+09:00: 페이즈 1 산출물 3 "검증용 초기 아이템 세트 컨셉" 완료 (Docs/content-design/[content]20260418_initial_item_set.md). 페이즈 1 전체 완료, 페이즈 3 총 데이터 수량 30종(개인 6+용병단 4+정수 20)으로 확정
- 2026-04-18T21:30:00+09:00: 페이즈 1 종료 체크포인트 승인, 페이즈 2 진입
- 2026-04-18T22:23:00+09:00: 페이즈 2 산출물 1 "장비 스탯 보정 수치표" 완료 (Docs/balance-design/20260418_equipment_stats.md). 장비 보정 공식 경로·티어 곡선·슬롯 가중치·전설 강도·effect_json 스키마 전체 확정
- 2026-04-18T23:53:00+09:00: 페이즈 2 산출물 2 "정수 영구 스탯 강화 수치 + 인플레이션 시뮬레이션" 완료 (Docs/balance-design/20260418_essence_inflation.md). 효과 곡선/상한/M6 승급 비용 가이드/사망·방출 리스크/드랍률 역산 확정. 기획서 3항 문구 갱신 권고 기록
- 2026-04-19T10:16:00+09:00: 페이즈 2 산출물 3 "용병단 장비 거시 지표 수치표" 완료 (Docs/balance-design/20260418_guild_equipment_macro.md). 3슬롯 + artifact 3택2 구조·A 경미 스케일·4종 수치·injury 곱셈/reputation 신규 상한·효과 카탈로그 16→18 확장 확정
- 2026-04-19T10:27:00+09:00: 페이즈 3 선행 과제 "essence 타입 스펙" 완료 (.claude/skills/data-generator/types/essence.md)
- 2026-04-19T10:29:00+09:00: 페이즈 3 선행 과제 "item 타입 스펙" 완료 (.claude/skills/data-generator/types/item.md). data-generator SKILL.md 지원 타입 목록 갱신
- 2026-04-19T10:35:00+09:00: 페이즈 2 산출물 3 매칭 승인, 페이즈 2 완료 처리
- 2026-04-19T10:40:00+09:00: 페이즈 2 종료 체크포인트에서 swap 선택 — 페이즈 4(개발 명세) 먼저 진행, 페이즈 3(데이터 생성)은 페이즈 4 완료 후 재진입. items 테이블 마이그레이션 선행 후 CSV 생성 → INSERT 순서 확정
- 2026-04-19T15:24:00+09:00: 페이즈 4 산출물 1 "아이템/인벤토리 인프라 명세" 완료 (Docs/spec/[spec]20260419_m2a-item-inventory-infrastructure.md). spec-writer로 명세 생성
- 2026-04-19T15:42:00+09:00: 페이즈 4 산출물 1 implement-agent 파이프라인 완주 — planner → coder(병렬 4 + 3 + 1) → verifier 1회 PASS. Supabase MCP `apply_migration('007_items_table')` 적용으로 items 테이블 + RLS + data_versions 행 생성 (DB 19행 확인). Flutter 측 인프라 코드 구현 완료 (flutter analyze 0 issues, 300/300 tests pass). 결과 문서: Docs/spec/[spec]20260419_m2a-item-inventory-infrastructure_plan.md. operation-bom table-config.ts는 사용자 지시로 후속 일괄 작업에 포함
- 2026-04-19T15:50:00+09:00: 재개 감지 — 페이즈 4 산출물 1 매칭 승인, 산출물 2 "장비 장착/해제 + effective 스탯 명세" 진입
- 2026-04-19T15:59:00+09:00: 페이즈 4 산출물 2 명세서 작성 완료 (Docs/spec/[spec]20260419_m2a-item-equipment-effects.md). spec-writer로 생성, 7 Q 항목 확정(accessory 2시각 슬롯·비캐싱·정보탭 진입·collect 시그니처 확장·쿨다운 Mercenary 저장·기존 Random 재사용·미장착만 노출)
- 2026-04-19T20:24:00+09:00: 페이즈 4 산출물 2 implement-agent 파이프라인 완주 — planner(16 TASK / 6단계) → coder 병렬 호출(Stage 1~5) → verifier 2회(1차 FAIL ISSUE-1, 2차 PASS). ISSUE-1: 전설 ① success_rate_bonus가 trait과 ±10%p 공유 clamp를 공유하도록 QuestCalculator 3 메서드에 legendarySuccessBonus 파라미터 추가. gameTickProvider/quest_provider 범위 포함(사용자 A 선택). build_runner 2회 재생성. flutter analyze 0 issues, flutter test 341/341 pass. 결과 문서: Docs/spec/[spec]20260419_m2a-item-equipment-effects_plan.md
- 2026-04-19T20:25:00+09:00: 재개 감지 — 페이즈 4 산출물 2 매칭 승인, 산출물 3 "정수 사용 + 인벤토리 UI 명세" 진입 대기
- 2026-04-19T23:07:00+09:00: 페이즈 4 산출물 3 명세서 작성 완료 (Docs/spec/[spec]20260419_m2a-essence-inventory-ui.md). spec-writer로 생성, 8 Q 항목 확정(permanent 증폭·정보탭 진입·2경로 필수·상태 포함 범위·연출 최소·경고 톤·approaching 기준·스키마 결핍 fail-soft)
- 2026-04-19T23:07:00+09:00: 페이즈 4 산출물 3 implement-agent 파이프라인 완주 — planner(16 TASK / 8단계) → coder 병렬 호출(1·2·3~4·5~8 단계) → verifier 1회 PASS(with warnings). Minor 이슈 3건 중 프리뷰 팝업 헤드 숫자 `base+permanent` 합계 반영 1건 수정, 나머지 2건(사망 로그 위치 문서화, apply 통합 테스트) 후속 이관. home_screen.dart _logIcon switch에 essenceApplied/essenceLostOnDeath/essenceLostOnRelease case 추가. build_runner 2회 재생성. flutter analyze 0 issues, flutter test 363/363 pass(신규 22건 추가). 결과 문서: Docs/spec/[spec]20260419_m2a-essence-inventory-ui_plan.md
- 2026-04-20T00:00:00+09:00: 재개 감지 — 페이즈 4 산출물 3 매칭 승인, 페이즈 4 완료 처리. swap 계획에 따라 페이즈 3(데이터 생성)으로 재진입
- 2026-04-20T00:00:00+09:00: 페이즈 3 종료 체크포인트 승인, 페이즈 3 진입. 첫 산출물 "정수 데이터 × 20" 대기
- 2026-04-20T07:38:00+09:00: 페이즈 3 산출물 1 "정수 데이터 × 20" 완료 (Docs/content-data/[essence]20260420_m2a-essences.csv + .md). data-generator로 생성, Supabase `items` 20행 INSERT + `data_versions.items` v2 bump. DB constraint 대응으로 slot=`essence_{stat}` + tier 조합 채택
- 2026-04-20T07:40:00+09:00: 재개 감지 — 페이즈 3 산출물 1 매칭 승인, 산출물 2 "장비 데이터 × 10" 진입 대기
- 2026-04-20T07:55:00+09:00: 페이즈 3 산출물 2 "장비 데이터 × 10" 완료 (Docs/content-data/[item]20260420_m2a-equipment.csv + .md). Supabase `items` 10행 INSERT + `data_versions.items` v3 bump. 전설 멸혼결 A안 채택. 페이즈 3 전체 완료 — 페이즈 3 종료 체크포인트 대기
- 2026-04-20T08:00:00+09:00: M2a 마일스톤 완료 처리. 4개 페이즈 모두 완료(swap 순서 1→2→4→3). `items` 테이블 총 30행(essence 20 + personal_equipment 6 + guild_equipment 4), `data_versions.items` v3, implement-agent 파이프라인 3회 완주(명세 3건), flutter test 363/363 pass, flutter analyze 0 issues 상태로 안정화
