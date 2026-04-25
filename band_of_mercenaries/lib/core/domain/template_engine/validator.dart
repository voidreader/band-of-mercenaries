part of '../template_engine.dart';

/// 템플릿 검증 메인 함수. TemplateEngine.validate에서 호출.
List<TemplateValidationError> _runValidation(
  String template, {
  Set<String>? knownTraitKeys,
  Set<String>? knownFactionIds,
}) {
  final errors = <TemplateValidationError>[];
  try {
    _validateTemplate(
      template,
      errors,
      knownTraitKeys: knownTraitKeys,
      knownFactionIds: knownFactionIds,
    );
  } on FormatException catch (e) {
    log('TemplateEngine: parse 오류 — $e', name: 'TemplateEngine');
  } on Error catch (e, st) {
    assert(false, 'TemplateEngine 내부 Error: $e\n$st');
    log('TemplateEngine: 내부 Error — $e', name: 'TemplateEngine');
  }
  return errors;
}

void _validateTemplate(
  String template,
  List<TemplateValidationError> errors, {
  Set<String>? knownTraitKeys,
  Set<String>? knownFactionIds,
}) {
  final src = _applyEscapes(template);

  _checkCurlyBrackets(src, errors);
  _checkVariables(src, errors);
  _checkBlocks(src, errors,
      knownTraitKeys: knownTraitKeys, knownFactionIds: knownFactionIds);
}

void _checkCurlyBrackets(String src, List<TemplateValidationError> errors) {
  var depth = 0;
  for (var i = 0; i < src.length; i++) {
    if (src[i] == '{') {
      depth++;
    } else if (src[i] == '}') {
      depth--;
      if (depth < 0) {
        errors.add(TemplateValidationError(
          code: TemplateValidationCode.unmatchedBracket,
          message: '비매칭 }',
          offset: i,
        ));
        depth = 0;
      }
    }
  }
  if (depth > 0) {
    errors.add(TemplateValidationError(
      code: TemplateValidationCode.unmatchedBracket,
      message: '닫히지 않은 {',
    ));
  }
}

void _checkVariables(String src, List<TemplateValidationError> errors) {
  var i = 0;
  while (i < src.length) {
    if (src[i] != '{') {
      i++;
      continue;
    }
    final end = src.indexOf('}', i + 1);
    if (end == -1) {
      i++;
      continue;
    }
    final inner = src.substring(i + 1, end);
    final pipeIdx = inner.indexOf('|');
    final raw = (pipeIdx == -1 ? inner : inner.substring(0, pipeIdx)).trim();
    final dotIdx = raw.indexOf('.');
    if (dotIdx != -1) {
      final ns = raw.substring(0, dotIdx);
      final field = raw.substring(dotIdx + 1);
      if (!TemplateVariableCatalog.isKnown(ns, field)) {
        errors.add(TemplateValidationError(
          code: TemplateValidationCode.unknownVariable,
          message: '미등록 변수: $ns.$field',
          offset: i,
        ));
      }
    }
    i = end + 1;
  }
}

void _checkBlocks(
  String src,
  List<TemplateValidationError> errors, {
  Set<String>? knownTraitKeys,
  Set<String>? knownFactionIds,
}) {
  final ifStack = <int>[];
  var i = 0;

  while (i < src.length) {
    if (src[i] != '[') {
      i++;
      continue;
    }
    final end = src.indexOf(']', i + 1);
    if (end == -1) {
      i++;
      continue;
    }
    final inner = src.substring(i + 1, end).trim();

    if (inner.startsWith('if ')) {
      if (ifStack.length >= 2) {
        errors.add(TemplateValidationError(
          code: TemplateValidationCode.nestingTooDeep,
          message: 'if 중첩 3단계 이상',
          offset: i,
        ));
      }
      final expr = inner.substring(3).trim();
      _validateExpression(expr, errors,
          offset: i,
          knownTraitKeys: knownTraitKeys,
          knownFactionIds: knownFactionIds);
      ifStack.add(i);
    } else if (inner.startsWith('elif ')) {
      final expr = inner.substring(5).trim();
      _validateExpression(expr, errors,
          offset: i,
          knownTraitKeys: knownTraitKeys,
          knownFactionIds: knownFactionIds);
    } else if (inner == '/if') {
      if (ifStack.isEmpty) {
        errors.add(TemplateValidationError(
          code: TemplateValidationCode.unbalancedBlock,
          message: '[/if]에 대응하는 [if] 없음',
          offset: i,
        ));
      } else {
        ifStack.removeLast();
      }
    } else if (inner.startsWith('pick ')) {
      final raw = inner.substring(5);
      final candidates = raw.split('|');
      if (candidates.length < 2 || candidates.length > 10) {
        errors.add(TemplateValidationError(
          code: TemplateValidationCode.pickCandidateCount,
          message: 'pick 후보 수는 2~10개여야 함 (현재 ${candidates.length}개)',
          offset: i,
        ));
      }
    } else if (inner == '/pick') {
      errors.add(TemplateValidationError(
        code: TemplateValidationCode.unbalancedBlock,
        message: '[/pick]은 사용하지 않음 — pick은 [pick A|B|C] 자기완결형',
        offset: i,
      ));
    }

    i = end + 1;
  }

  for (final openPos in ifStack) {
    errors.add(TemplateValidationError(
      code: TemplateValidationCode.unbalancedBlock,
      message: '[if]에 대응하는 [/if] 없음',
      offset: openPos,
    ));
  }
}

void _validateExpression(
  String expr,
  List<TemplateValidationError> errors, {
  int? offset,
  Set<String>? knownTraitKeys,
  Set<String>? knownFactionIds,
}) {
  try {
    final tokens = _tokenize(expr.trim());
    final parser = _ExprParser(
      tokens,
      null, // 검증용 더미 — 구문 파싱만 수행
      resolveVariable: (ns, field) => null,
      validateMode: true,
      knownTraitKeys: knownTraitKeys,
      knownFactionIds: knownFactionIds,
      validationErrors: errors,
      baseOffset: offset,
    );
    parser.parseOr();
  } on FormatException catch (e) {
    errors.add(TemplateValidationError(
      code: TemplateValidationCode.invalidExpression,
      message: '조건식 오류: $e (expr: $expr)',
      offset: offset,
    ));
  } on Error catch (e, st) {
    assert(false, 'TemplateEngine 내부 Error: $e\n$st');
    errors.add(TemplateValidationError(
      code: TemplateValidationCode.invalidExpression,
      message: '조건식 내부 Error: $e (expr: $expr)',
      offset: offset,
    ));
  }
}
