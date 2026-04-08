# TravelEvent

```
ID	Name	Type	EffectType	Magnitude	MinTier	MaxTier	Description
te_find_gold_s	금화 주머니 발견	discovery	gold	20	1	2	길가에 떨어진 작은 금화 주머니를 발견했다.
te_find_gold_m	상인의 분실물 발견	discovery	gold	50	2	4	상인이 떨어뜨린 듯한 금화 자루를 발견했다.
te_find_gold_l	숨겨진 보물상자	discovery	gold	120	4	5	오래된 나무 밑에서 보물상자를 발견했다.
te_bandit_s	산적 습격	raid	gold	-30	1	3	이동 중 산적의 습격을 받아 금화를 빼앗겼다.
te_bandit_m	도적단 매복	raid	gold	-60	3	5	도적단의 매복에 걸려 상당한 금화를 잃었다.
te_bandit_injury	야수 습격	raid	injury	1	2	5	이동 중 야수의 습격을 받아 용병 한 명이 부상당했다.
te_storm_s	갑작스런 폭우	weather	delay	0.2	1	5	갑작스런 폭우로 이동이 지연되었다.
te_storm_l	거센 눈보라	weather	delay	0.5	3	5	거센 눈보라로 이동이 크게 지연되었다.
te_merchant	떠돌이 상인과 거래	luck	gold	40	1	3	떠돌이 상인에게 좋은 거래를 성사시켰다.
te_healer	방랑 치료사	luck	heal_tired	1	1	4	방랑 치료사를 만나 피곤한 용병의 기력을 회복시켰다.
te_merc_group	다른 용병단과 조우	encounter	reputation	10	1	3	다른 용병단과 우호적인 만남을 가졌다.
te_noble_encounter	귀족 호위대 조우	encounter	reputation	15	3	5	귀족의 호위대와 만나 용병단의 이름을 알렸다.
```

# Facility

```
ID	Name	EffectType	MaxLevel	Cost1	Cost2	Cost3	Cost4	Cost5	Value1	Value2	Value3	Value4	Value5
training	훈련소	xp_bonus	5	500	1000	2000	4000	8000	0.1	0.2	0.3	0.4	0.5
infirmary	의무실	recovery_reduction	5	300	600	1200	2400	4800	0.1	0.2	0.3	0.4	0.5
barracks	주둔지	max_mercenaries	5	400	800	1600	3200	6400	2	4	6	8	10
intelligence	정보망	quest_count	3	1000	3000	9000			1	2	3		
```

# Rank

```
Grade	Name	RequiredReputation	UnlockTier
F	무명	0	1
E	신출내기	500	2
D	일반	2000	3
C	숙련	8000	4
B	정예	25000	5
A	전설	80000	5
```

# MercenaryWage

```
Tier	Wage
1	10
2	25
3	50
4	100
5	200
```

# Difficulty (DispatchCost 추가분)

```
Level	EnemyPower	RewardMultiplier	SuccessPenalty	InjuryRate	DeathRate	DispatchCost
1	10	1	0	0.1	0.05	20
2	20	1.5	0.1	0.2	0.1	50
3	35	2.2	0.2	0.3	0.15	100
4	55	3.2	0.3	0.45	0.22	200
5	80	4.5	0.4	0.6	0.3	400
```
