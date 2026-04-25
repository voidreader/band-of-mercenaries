import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/domain/template_engine.dart';
import 'package:band_of_mercenaries/core/domain/template_validation_error.dart';

void main() {
  group('TemplateEngine.validate', () {
    const engine = TemplateEngine();

    test('정상 템플릿 — 오류 없음', () {
      final errors = engine.validate('{merc.name}이 {region.name}에 도착했다.');
      expect(errors, isEmpty);
    });

    test('미등록 namespace — unknownVariable 오류 1건', () {
      final errors = engine.validate('{xx.name}');
      expect(errors.length, 1);
      expect(errors.first.code, TemplateValidationCode.unknownVariable);
    });

    test('미등록 field — unknownVariable 오류 1건', () {
      final errors = engine.validate('{merc.unknown_field}');
      expect(errors.length, 1);
      expect(errors.first.code, TemplateValidationCode.unknownVariable);
    });

    test('if 블록 닫기 누락 — unbalancedBlock 오류', () {
      final errors = engine.validate('[if merc.str > 10]A');
      expect(
        errors.where((e) => e.code == TemplateValidationCode.unbalancedBlock).length,
        1,
      );
    });

    test('pick 후보 1개 — pickCandidateCount 오류', () {
      final errors = engine.validate('[pick A]');
      expect(errors.length, 1);
      expect(errors.first.code, TemplateValidationCode.pickCandidateCount);
    });

    test('pick 후보 11개 — pickCandidateCount 오류', () {
      final errors = engine.validate('[pick A|B|C|D|E|F|G|H|I|J|K]');
      expect(errors.length, 1);
      expect(errors.first.code, TemplateValidationCode.pickCandidateCount);
    });

    test('중첩 if 3단계 — nestingTooDeep 오류', () {
      final errors = engine.validate(
        '[if merc.str > 1]'
        '[if merc.vit > 1]'
        '[if merc.agi > 1]깊다[/if]'
        '[/if]'
        '[/if]',
      );
      expect(
        errors.where((e) => e.code == TemplateValidationCode.nestingTooDeep).length,
        1,
      );
    });

    test('잘못된 연산자 — invalidExpression 오류', () {
      final errors = engine.validate('[if merc.str + 1]A[/if]');
      expect(
        errors.where((e) => e.code == TemplateValidationCode.invalidExpression).length,
        1,
      );
    });

    test('knownTraitKeys 주입 시 미등록 key — unknownTraitKey 오류', () {
      final errors = engine.validate(
        '[if has_trait:bad_key]A[/if]',
        knownTraitKeys: {'good_key'},
      );
      expect(
        errors.where((e) => e.code == TemplateValidationCode.unknownTraitKey).length,
        1,
      );
    });

    test('knownFactionIds 주입 시 미등록 id — unknownFactionId 오류', () {
      final errors = engine.validate(
        '[if joined_faction:bad_id]A[/if]',
        knownFactionIds: {'good_id'},
      );
      expect(
        errors.where((e) => e.code == TemplateValidationCode.unknownFactionId).length,
        1,
      );
    });

    test('FK 파라미터 미주입 시 — unknownTraitKey/unknownFactionId 오류 미보고', () {
      final traitErrors = engine.validate('[if has_trait:any_key]A[/if]');
      expect(
        traitErrors.where((e) => e.code == TemplateValidationCode.unknownTraitKey),
        isEmpty,
      );

      final factionErrors = engine.validate('[if joined_faction:any_id]A[/if]');
      expect(
        factionErrors.where((e) => e.code == TemplateValidationCode.unknownFactionId),
        isEmpty,
      );
    });
  });
}
