import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/recruitment_service.dart';
import 'package:band_of_mercenaries/core/domain/newbie_gate.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';

void main() {
  // ranks 테이블 시드 — Supabase 데이터와 동일한 임계값
  final ranks = [
    const Rank(grade: 'F', name: '무명', requiredReputation: 0, unlockTier: 1),
    const Rank(grade: 'E', name: '신출내기', requiredReputation: 300, unlockTier: 2),
    const Rank(grade: 'D', name: '일반', requiredReputation: 2000, unlockTier: 3),
    const Rank(grade: 'C', name: '숙련', requiredReputation: 8000, unlockTier: 4),
    const Rank(grade: 'B', name: '정예', requiredReputation: 25000, unlockTier: 5),
    const Rank(grade: 'A', name: '전설', requiredReputation: 80000, unlockTier: 5),
  ];

  group('NewbieGateResolver.resolve', () {
    test('명성 0 → F 게이트', () {
      expect(NewbieGateResolver.resolve(reputation: 0, ranks: ranks),
          NewbieGate.newbieF);
    });

    test('명성 299 → F 게이트 (E 미진입)', () {
      expect(NewbieGateResolver.resolve(reputation: 299, ranks: ranks),
          NewbieGate.newbieF);
    });

    test('명성 300 → E 게이트 (E 진입)', () {
      expect(NewbieGateResolver.resolve(reputation: 300, ranks: ranks),
          NewbieGate.newbieE);
    });

    test('명성 1999 → E 게이트 (D 미진입)', () {
      expect(NewbieGateResolver.resolve(reputation: 1999, ranks: ranks),
          NewbieGate.newbieE);
    });

    test('명성 2000 → normal 게이트 (D 진입)', () {
      expect(NewbieGateResolver.resolve(reputation: 2000, ranks: ranks),
          NewbieGate.normal);
    });

    test('명성 80000 → normal 게이트 (A)', () {
      expect(NewbieGateResolver.resolve(reputation: 80000, ranks: ranks),
          NewbieGate.normal);
    });

    test('ranks 비어있음 → StateError throw', () {
      expect(
        () => NewbieGateResolver.resolve(reputation: 0, ranks: const []),
        throwsStateError,
      );
    });
  });

  group('RecruitmentService.selectTier — 게이트별 분포', () {
    const sampleSize = 10000;

    test('newbieF: 보너스 무관 T1 100%', () {
      final random = Random(7);
      final counts = <int, int>{};
      for (var i = 0; i < sampleSize; i++) {
        final tier = RecruitmentService.selectTier(
          random,
          gate: NewbieGate.newbieF,
          recruitBonus: 0.5,
          extraHighTierBoost: 0.0,
        );
        counts[tier] = (counts[tier] ?? 0) + 1;
      }
      expect(counts[1], sampleSize, reason: 'F 단계는 보너스 0.5에도 T1 고정');
      expect(counts[2] ?? 0, 0);
      expect(counts[3] ?? 0, 0);
    });

    test('newbieE 보너스 0: T1 ~90% / T2 ~10% / T3+ 0%', () {
      final random = Random(11);
      final counts = <int, int>{};
      for (var i = 0; i < sampleSize; i++) {
        final tier = RecruitmentService.selectTier(
          random,
          gate: NewbieGate.newbieE,
          recruitBonus: 0.0,
          extraHighTierBoost: 0.0,
        );
        counts[tier] = (counts[tier] ?? 0) + 1;
      }
      final t1Ratio = (counts[1] ?? 0) / sampleSize;
      final t2Ratio = (counts[2] ?? 0) / sampleSize;
      expect(t1Ratio, inInclusiveRange(0.87, 0.93),
          reason: 'T1 90% ±3%');
      expect(t2Ratio, inInclusiveRange(0.07, 0.13),
          reason: 'T2 10% ±3%');
      expect(counts[3] ?? 0, 0);
      expect(counts[4] ?? 0, 0);
      expect(counts[5] ?? 0, 0);
    });

    test('newbieE 보너스 0.5: T2 비율 상승, T3+ 여전히 0%', () {
      final random = Random(13);
      final counts = <int, int>{};
      for (var i = 0; i < sampleSize; i++) {
        final tier = RecruitmentService.selectTier(
          random,
          gate: NewbieGate.newbieE,
          recruitBonus: 0.5,
          extraHighTierBoost: 0.0,
        );
        counts[tier] = (counts[tier] ?? 0) + 1;
      }
      final t1Ratio = (counts[1] ?? 0) / sampleSize;
      final t2Ratio = (counts[2] ?? 0) / sampleSize;
      // 보너스 0.5 → t2Prob = 0.10 + 0.5 * 0.5 = 0.35
      expect(t2Ratio, inInclusiveRange(0.30, 0.40),
          reason: '보너스 0.5 시 T2 35% ±5%');
      expect(t1Ratio, inInclusiveRange(0.60, 0.70));
      expect(counts[3] ?? 0, 0);
      expect(counts[4] ?? 0, 0);
      expect(counts[5] ?? 0, 0);
    });

    test('normal 보너스 0: 기존 분포 (T1 45 / T2 30 / T3 15 / T4 8 / T5 2)', () {
      final random = Random(17);
      final counts = <int, int>{};
      for (var i = 0; i < sampleSize; i++) {
        final tier = RecruitmentService.selectTier(
          random,
          gate: NewbieGate.normal,
          recruitBonus: 0.0,
          extraHighTierBoost: 0.0,
        );
        counts[tier] = (counts[tier] ?? 0) + 1;
      }
      expect((counts[1] ?? 0) / sampleSize, inInclusiveRange(0.42, 0.48));
      expect((counts[2] ?? 0) / sampleSize, inInclusiveRange(0.27, 0.33));
      expect((counts[3] ?? 0) / sampleSize, inInclusiveRange(0.12, 0.18));
      expect((counts[4] ?? 0) / sampleSize, inInclusiveRange(0.06, 0.10));
      expect((counts[5] ?? 0) / sampleSize, inInclusiveRange(0.005, 0.035));
    });
  });
}
