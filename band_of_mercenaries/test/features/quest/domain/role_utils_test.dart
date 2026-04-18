import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/role_utils.dart';

Mercenary _buildMerc(String id, String jobId) {
  return Mercenary(
    id: id,
    name: 'Test-$id',
    jobId: jobId,
    traitId: '',
    str: 50,
    intelligence: 50,
    vit: 50,
    agi: 50,
  );
}

Job _buildJob(String id, String role) {
  return Job(
    id: id,
    tier: 1,
    name: 'Test Job',
    baseStr: 50,
    baseIntelligence: 50,
    baseVit: 50,
    baseAgi: 50,
    role: role,
  );
}

void main() {
  group('RoleUtils.extractRoles', () {
    test('jobId 매칭 시 해당 role 반환', () {
      final jobs = [
        _buildJob('warrior_job', 'warrior'),
        _buildJob('mage_job', 'mage'),
      ];
      final mercs = [
        _buildMerc('m1', 'warrior_job'),
        _buildMerc('m2', 'mage_job'),
      ];
      expect(RoleUtils.extractRoles(mercs, jobs), ['warrior', 'mage']);
    });

    test('jobId 누락 시 specialist fallback', () {
      final jobs = [_buildJob('warrior_job', 'warrior')];
      final mercs = [
        _buildMerc('m1', 'warrior_job'),
        _buildMerc('m2', 'nonexistent_job'),
      ];
      expect(RoleUtils.extractRoles(mercs, jobs), ['warrior', 'specialist']);
    });

    test('빈 파티 → 빈 리스트', () {
      expect(
        RoleUtils.extractRoles(const [], const []),
        isEmpty,
      );
    });
  });

  group('RoleUtils.koreanName', () {
    test('6 role 한글명 매핑', () {
      expect(RoleUtils.koreanName('warrior'), '전사');
      expect(RoleUtils.koreanName('ranger'), '순찰자');
      expect(RoleUtils.koreanName('mage'), '마법사');
      expect(RoleUtils.koreanName('rogue'), '도적');
      expect(RoleUtils.koreanName('support'), '지원');
      expect(RoleUtils.koreanName('specialist'), '전문가');
    });

    test('알 수 없는 role은 전문가 fallback', () {
      expect(RoleUtils.koreanName('unknown'), '전문가');
      expect(RoleUtils.koreanName(''), '전문가');
    });
  });
}
