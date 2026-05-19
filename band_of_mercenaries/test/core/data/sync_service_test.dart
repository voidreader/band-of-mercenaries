import 'package:band_of_mercenaries/core/data/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncService', () {
    test(
      'region_sectors is optional because runtime fallback supports empty seed',
      () {
        expect(SyncService.optionalTables, contains('region_sectors'));
        expect(SyncService.requiredTables, isNot(contains('region_sectors')));
      },
    );

    test('M8a supplemental tables remain optional', () {
      expect(
        SyncService.optionalTables,
        containsAll(<String>[
          'faction_contacts',
          'faction_reactions',
          'faction_shop_items',
          'combat_report_templates',
          'combat_report_keywords',
        ]),
      );
    });
  });
}
