import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';
import 'package:band_of_mercenaries/features/info/domain/faction_state_model.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

// ---------------------------------------------------------------------------
// 더미 데이터 헬퍼
// ---------------------------------------------------------------------------

TemplateContext _ctx({
  Mercenary? merc,
  ActiveQuest? quest,
  Region? region,
  UserData? user,
  List<FactionState> factionStates = const [],
  Map<int, String>? sectorChanges,
  int? currentSectorIndex,
  List<Mercenary> rosterForTeam = const [],
  String? eliteId,
  int? seed,
  EvaluationScope evaluationScope = EvaluationScope.mercenary,
}) {
  return TemplateContext(
    merc: merc,
    quest: quest,
    region: region,
    user: user ?? _dummyUser(),
    factionStates: factionStates,
    sectorChanges: sectorChanges,
    currentSectorIndex: currentSectorIndex,
    rosterForTeam: rosterForTeam,
    eliteId: eliteId,
    seed: seed,
    evaluationScope: evaluationScope,
  );
}

Mercenary _dummyMerc({
  String name = '김철수',
  String jobId = 'scout',
  int level = 1,
  int str = 10,
  int intel = 10,
  int vit = 10,
  int agi = 10,
  List<String> traitIds = const [],
}) {
  return Mercenary(
    id: 'merc-001',
    name: name,
    jobId: jobId,
    traitId: '',
    str: str,
    intelligence: intel,
    vit: vit,
    agi: agi,
    level: level,
    traitIds: traitIds,
  );
}

UserData _dummyUser({int gold = 1000}) {
  final now = DateTime(2026, 4, 25);
  return UserData(
    gold: gold,
    region: 1,
    sector: 0,
    lastFreeRecruit: now,
    createdAt: now,
  );
}

Region _dummyRegion({
  String name = '검은 숲',
  int tier = 1,
}) {
  return Region(
    continent: 1,
    region: 1,
    regionName: name,
    regionTier: tier,
    recommendPower: 10,
    description: '테스트 리전',
  );
}

ActiveQuest _dummyQuest({
  String questName = '도적 소탕',
  String questTypeId = 'raid',
  int difficulty = 3,
  String? eliteId,
}) {
  return ActiveQuest(
    id: 'quest-001',
    questPoolId: 'pool-001',
    questTypeId: questTypeId,
    difficulty: difficulty,
    region: 1,
    questName: questName,
    eliteId: eliteId,
  );
}

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

const _engine = TemplateEngine();

void main() {
  group('TemplateEngine.render', () {
    test('빈 템플릿 → 빈 문자열', () {
      expect(_engine.render('', _ctx()), '');
    });

    test('{merc.name} 정상 치환', () {
      final merc = _dummyMerc(name: '홍길동');
      final result = _engine.render('{merc.name}이 출발했다.', _ctx(merc: merc));
      expect(result, '홍길동이 출발했다.');
    });

    test('{quest.enemy|적} fallback — quest.enemy 미존재 시 기본값 출력', () {
      final quest = _dummyQuest();
      // quest.enemy는 ActiveQuest에 없으므로 null → fallback "적" 출력
      final result = _engine.render('{quest.enemy|적}을 처치하라.', _ctx(quest: quest));
      expect(result, '적을 처치하라.');
    });

    test('{merc.unknown_field} — 미등록 변수 → [?:unknown:merc.unknown_field] 출력', () {
      final merc = _dummyMerc();
      final result = _engine.render('{merc.unknown_field}', _ctx(merc: merc));
      expect(result, '[?:unknown:merc.unknown_field]');
    });

    test('merc 컨텍스트가 null이면 → [?merc.name] 출력', () {
      // merc 없이 {merc.name} 치환 시도
      final result = _engine.render('{merc.name}', _ctx());
      expect(result, '[?merc.name]');
    });

    test('[if has_trait:empathic]A[else]B[/if] — trait 보유 시 A, 미보유 시 B', () {
      final mercWithTrait = _dummyMerc(traitIds: ['empathic']);
      final mercWithout = _dummyMerc();

      final template = '[if has_trait:empathic]A[else]B[/if]';
      expect(_engine.render(template, _ctx(merc: mercWithTrait)), 'A');
      expect(_engine.render(template, _ctx(merc: mercWithout)), 'B');
    });

    test('[if A][elif B][else]C[/if] 다단 분기 — B 조건 매칭 시', () {
      // merc.level == 2인 경우만 B 브랜치 매칭
      final merc = _dummyMerc(level: 2);
      final template =
          '[if {merc.level} == 1]레벨1[elif {merc.level} == 2]레벨2[else]기타[/if]';
      expect(_engine.render(template, _ctx(merc: merc)), '레벨2');
    });

    test('중첩 if 2단계 정상 렌더', () {
      final merc = _dummyMerc(level: 3, traitIds: ['iron_will']);
      // 외부: merc.level >= 3, 내부: has_trait:iron_will → "베테랑 의지"
      final template =
          '[if {merc.level} >= 3][if has_trait:iron_will]베테랑 의지[else]베테랑[/if][else]신참[/if]';
      expect(_engine.render(template, _ctx(merc: merc)), '베테랑 의지');
    });

    test('[pick A|B|C] seed 고정 시 결정성 — 동일 seed 두 번 호출 결과 동일', () {
      final template = '[pick 사과|바나나|오렌지]';
      final result1 = _engine.render(template, _ctx(seed: 42));
      final result2 = _engine.render(template, _ctx(seed: 42));
      expect(result1, result2);
    });

    test('[pick A] 단일 후보 — validate 오류이나 render는 단일 항목 반환 (크래시 없음)', () {
      final template = '[pick 유일]';
      expect(() => _engine.render(template, _ctx()), returnsNormally);
      // 단일 후보이면 그 항목이 반환되어야 함
      expect(_engine.render(template, _ctx()), '유일');
    });

    test('[pick 11개 후보] — render는 크래시 없이 처리', () {
      // FR-4: pick 11개 이상은 validate 오류, render는 최선 노력
      final template = '[pick A|B|C|D|E|F|G|H|I|J|K]';
      expect(() => _engine.render(template, _ctx(seed: 1)), returnsNormally);
      // 10개까지 자른 pool에서 선택하므로 K(11번째)는 나올 수 없음
      final result = _engine.render(template, _ctx(seed: 1));
      expect(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'].contains(result), isTrue);
    });

    test('이스케이프 \\{ → { 리터럴 출력', () {
      final result = _engine.render(r'\{merc.name\}', _ctx());
      expect(result, '{merc.name}');
    });

    test('이스케이프 \\[ → [ 리터럴 출력', () {
      final result = _engine.render(r'\[if 조건\]', _ctx());
      expect(result, '[if 조건]');
    });

    test('이스케이프 \\\\ → \\ 리터럴 출력', () {
      final result = _engine.render(r'경로: C:\\Users', _ctx());
      expect(result, r'경로: C:\Users');
    });

    test('미균형 블록 [if x]A — 크래시 없음 (원본 출력 또는 fail-safe)', () {
      // FR-3: 런타임 언밸런스 → 원본 그대로 또는 안전한 출력
      expect(() => _engine.render('[if has_trait:empathic]A', _ctx(merc: _dummyMerc())), returnsNormally);
    });

    test('공백 포함 변수 이름 { merc.name } 허용', () {
      final merc = _dummyMerc(name: '이순신');
      // FR 4.3: { merc.name } (앞뒤 공백) trim 후 처리
      final result = _engine.render('{ merc.name }이 전진했다.', _ctx(merc: merc));
      expect(result, '이순신이 전진했다.');
    });

    test('region.sector_type — sectorChanges + currentSectorIndex 매핑 정상 치환', () {
      final region = _dummyRegion();
      final result = _engine.render(
        '구역 유형: {region.sector_type}',
        _ctx(
          region: region,
          sectorChanges: {2: 'ruins'},
          currentSectorIndex: 2,
        ),
      );
      expect(result, '구역 유형: ruins');
    });

    test('region.sector_type — currentSectorIndex 미지정 시 standard 기본값', () {
      final region = _dummyRegion();
      final result = _engine.render(
        '{region.sector_type}',
        _ctx(region: region),
      );
      expect(result, 'standard');
    });

    test('복수 변수 동시 치환 — {merc.name}이 {region.name}에서 일했다.', () {
      final merc = _dummyMerc(name: '박문수');
      final region = _dummyRegion(name: '흰 설원');
      final result = _engine.render(
        '{merc.name}이 {region.name}에서 일했다.',
        _ctx(merc: merc, region: region),
      );
      expect(result, '박문수이 흰 설원에서 일했다.');
    });

    test('임의 깨진 입력 {[}|] — 크래시 없음', () {
      expect(() => _engine.render('{[}|]', _ctx()), returnsNormally);
    });
  });
}
