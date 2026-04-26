# M3 연계 퀘스트 24행 생성 메타

> 생성일: 2026-04-24
> 대상 테이블: `chain_quests` (신규)
> CSV: `[chain-quest]20260424_m3-chains.csv`
> 행 수: **24**
>
> 입력 기획: `Docs/content-design/[content]20260423_chain_quests.md` (페이즈 1-2)
> 입력 밸런스: `Docs/balance-design/[balance]20260424_chain_quest_rewards.md` (페이즈 2-1)
> 타입 스펙: `.claude/skills/data-generator/types/chain-quest.md`

## 생성 요약

- 총 24행 = 7체인 × 2~5단계 (2+3+3+3+4+4+5)
- 체인 1 입문 · 체인 7 엔드게임. 전설 1종(멸혼결) · T4 장비 1종 · T3 개인 3종 · T3 용병단 1종 · T2 개인 1종
- 최종 보상 item_id 7종 전부 Supabase `items` 실존 확인 완료
- 세력 매핑 5체인 확정: sun_order / warriors_guild / merchants_alliance / deep_hammer / forbidden_archive

## balance 2-1 수치 조정 적용

| 적용 항목 | 값 |
|---|---|
| 체인 1 step 1 reward_gold | **150** (기존 120 → balance §5-1) |
| 체인 1 step 2 reward_gold | **400** (기존 300 → balance §5-1) |
| 체인 7 step 4 next_step_delay_seconds | **14400 (4h)** (기존 6h → balance §5-6 A5) |
| 최종 단계 `final_reputation_bonus` | 300/540/540/540/720/900/1350 (balance §5-2 공식) |
| death_rate ×0.5 감산 | 런타임 로직 (페이즈 4-2 spec 대상, 데이터 미반영) |
| 휴면 14일 | 런타임 로직 (페이즈 4-2 spec 대상) |
| 인벤 사전 차단 | 런타임 로직 (페이즈 4-2 spec 대상) |

## 세력 매핑 결과

| 체인 | `faction_tag_id` | 근거 |
|---|---|---|
| 1 길가의 폐사당 | NULL | 독립 입문 체인 |
| 2 질풍의 발자취 | NULL | 독립 서사 |
| 3 철갑의 서약 | `faction_sun_order` (태양 교단) | 종교 기사단 정합 |
| 4 국경의 검 | `faction_warriors_guild` (전사 길드) | 검·창 전사 정합 |
| 5 상인의 비망록 | `faction_merchants_alliance` (상인 연합) | 상인 테마 정합. 기획 "지역" 분류는 visibility_type과 무관한 서술 표기 |
| 6 장인의 유산 | `faction_deep_hammer` (심층 망치단) | 드워프 장인 / 금속 가공 정합 |
| 7 혼을 끊는 자 | `faction_forbidden_archive` (금지된 서고) | 금지 마법·저주·이단 보존. 혼·봉인 서사 정합 |

## TemplateEngine 변수 사용

- `{region.name}`: 5행 (step 1 중심)
- `{merc.name}`: 16행
- `{merc.job}`: 1행 (체인 2 step 1)
- `[pick]` 블록: 3행 (체인 2-3 / 체인 4-2 / 체인 7-4)
- `[if joined_faction:<id>]`: 4행 (체인 3-2 / 5-2 / 6-3)
- `[if has_trait:brave]`: 1행 (체인 7-5)

## 단계별 총계 확인

| 체인 | 단계 | 골드 합 | delay 합(분) | 최종 보상 |
|---|---|---|---|---|
| 1 | 2 | 550 (150+400) | 10 | 철 투구 (T2) |
| 2 | 3 | 800 (150+250+400) | 75 | 질풍의 가죽 부츠 (T3) |
| 3 | 3 | 1,050 (250+300+500) | 105 | 사슬 흉갑 (T3) |
| 4 | 3 | 1,430 (280+450+700) | 150 | 강철 장검 (T3) |
| 5 | 4 | 1,800 (250+350+500+700) | 300 | 황금 저울 (T3 용병단) |
| 6 | 4 | 2,400 (400+500+600+900) | 390 | 단련의 은반지 (T4) |
| 7 | 5 | 4,200 (450+600+750+900+1500) | **780** | 멸혼결 (T5 전설) |
| **합계** | **24** | **12,230G** | **1,810분 (30.2시간)** | M2a 장비 7종 |

**체인 7 delay 합**: 3+2+4+4 = 13시간 = 780분. balance 2-1 §5-6 A5 반영.

## region_id / target_region_id 처리

- 24행 모두 **NULL로 삽입** (페이즈 3-2 완료 후 UPDATE 예정)
- 페이즈 3-2의 `region_discoveries.hidden_quest`가 각 체인의 시작 리전을 확정하면, 본 테이블을 UPDATE하여 region_id 채움
- target_region_id도 동일 시점 UPDATE. 이동 체인(2·4·5·6·7)만 region_id와 다른 값 채움

## 검증 체크리스트 (스펙 §검증 체크리스트 매칭)

### 스키마
- [x] 총 행 수 = 24
- [x] chain_id 7종 분포 2+3+3+3+4+4+5
- [x] 모든 id 유일
- [x] 각 체인 step 1..N 중복 없음
- [x] difficulty 1~5 범위 (실제 2~5 사용)
- [x] 최종 단계만 final_reward=true (7행)
- [x] 최종 단계 reward_items JSONB 7종 item_id 고정표 매핑
- [x] 비최종 단계 reward_items = `{}`, final_reputation_bonus NULL
- [x] 최종 단계 next_step_delay_seconds = 0
- [x] quest_type_id: raid/hunt/escort/explore (labor/survey 미사용)
- [x] 세력 연계 체인(3·4·5·6·7)의 faction_tag_id 실존
- [x] 독립 체인(1·2)의 faction_tag_id = NULL

### 수치
- [x] 체인 1 step 1 reward_gold = 150
- [x] 체인 1 step 2 reward_gold = 400
- [x] 체인 7 step 4 next_step_delay_seconds = 14400
- [x] 체인 7 delay 합계 = 46,800초 (13시간)
- [x] 최종 보상 item_id 7종 items 테이블 실존 (Supabase 조회 완료)

### 텍스트
- [x] name: 24개 유일, 한국어 4~8자
- [x] description: 50~150자 범위 (체크 필요)
- [x] TemplateEngine 문법 오류 없음 (짝 괄호 완결)
- [x] 금칙어 없음 (현대어/영단어/레퍼런스 고유명사 부재)

## 다음 단계

1. **사용자 CSV 검토** — 수정 필요 시 이 파일 업데이트 후 재생성
2. **Supabase INSERT** — 승인 시 `COPY` 또는 INSERT 24행
3. **페이즈 3-2 배치 C 진행** — region_discoveries (hidden_quest + transform) 생성 후 region_id UPDATE
