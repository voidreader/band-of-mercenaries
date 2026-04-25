import 'dart:developer' show log;
import 'dart:math' hide log;

import 'package:band_of_mercenaries/core/domain/template_context.dart';
import 'package:band_of_mercenaries/core/domain/template_parse_node.dart';
import 'package:band_of_mercenaries/core/domain/template_validation_error.dart';
import 'package:band_of_mercenaries/core/domain/template_variable_catalog.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';
import 'package:band_of_mercenaries/features/quest/domain/quest_model.dart';

part 'template_engine/escapes.dart';
part 'template_engine/lexer.dart';
part 'template_engine/resolver.dart';
part 'template_engine/renderer.dart';
part 'template_engine/expression.dart';
part 'template_engine/validator.dart';

/// 스테이트리스 템플릿 엔진.
///
/// 변수 치환 `{namespace.field}`, 조건 분기 `[if]...[/if]`,
/// 랜덤 변주 `[pick A|B|C]` 세 가지 처리를 지원.
/// 모든 공개 API는 fail-safe: 예외 발생 시 크래시 없이 안전 값 반환.
class TemplateEngine {
  const TemplateEngine();

  /// 템플릿 문자열을 [context]에 따라 렌더하여 반환한다.
  ///
  /// 파싱 실패(미균형 블록 등) 시 원본 템플릿 그대로 반환.
  String render(String template, TemplateContext context) =>
      _renderTemplate(template, context);

  /// 조건식 [expression]을 [context]에 따라 평가하여 반환한다.
  ///
  /// syntax error 시 false 반환 (크래시 금지).
  bool evaluate(String expression, TemplateContext context) =>
      _evaluateExpression(expression, context);

  /// 템플릿을 정적 검증하여 오류 목록을 반환한다.
  ///
  /// 오류 없으면 빈 리스트. 예외 발생 시 발견된 오류만 반환 (크래시 금지).
  List<TemplateValidationError> validate(
    String template, {
    Set<String>? knownTraitKeys,
    Set<String>? knownFactionIds,
  }) =>
      _runValidation(
        template,
        knownTraitKeys: knownTraitKeys,
        knownFactionIds: knownFactionIds,
      );
}
