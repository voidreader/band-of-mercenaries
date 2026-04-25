part of '../template_engine.dart';

/// 조건식 평가 메인 함수. TemplateEngine.evaluate 및 _renderNodes에서 호출.
bool _evaluateExpression(String expression, TemplateContext context) {
  try {
    final tokens = _tokenize(expression.trim());
    final parser = _ExprParser(
      tokens,
      context,
      resolveVariable: (ns, field) => _resolveVariable(ns, field, context),
    );
    return parser.parseOr();
  } on FormatException catch (e) {
    log('TemplateEngine: parse 오류 — $e', name: 'TemplateEngine');
    return false;
  } on Error catch (e, st) {
    assert(false, 'TemplateEngine 내부 Error: $e\n$st');
    log('TemplateEngine: 내부 Error — $e', name: 'TemplateEngine');
    return false;
  }
}

List<_Token> _tokenize(String expr) {
  final tokens = <_Token>[];
  var i = 0;

  while (i < expr.length) {
    final ch = expr[i];

    if (ch == ' ' || ch == '\t') {
      i++;
      continue;
    }

    // 문자열 리터럴 "..."
    if (ch == '"') {
      final sb = StringBuffer();
      i++;
      while (i < expr.length && expr[i] != '"') {
        sb.write(expr[i]);
        i++;
      }
      if (i < expr.length) i++; // 닫는 "
      tokens.add(_Token(_TokenType.stringLiteral, sb.toString()));
      continue;
    }

    // 변수 참조 {namespace.field}
    if (ch == '{') {
      final end = expr.indexOf('}', i + 1);
      if (end == -1) throw FormatException('비매칭 {');
      tokens.add(_Token(_TokenType.varRef, expr.substring(i + 1, end).trim()));
      i = end + 1;
      continue;
    }

    if (ch == '(') {
      tokens.add(_Token(_TokenType.lParen, '('));
      i++;
      continue;
    }
    if (ch == ')') {
      tokens.add(_Token(_TokenType.rParen, ')'));
      i++;
      continue;
    }

    // 연산자 2자리 우선
    if (i + 1 < expr.length) {
      final two = expr.substring(i, i + 2);
      if (two == '==' || two == '!=' || two == '>=' || two == '<=') {
        tokens.add(_Token(_TokenType.operator_, two));
        i += 2;
        continue;
      }
    }
    // 연산자 1자리
    if (ch == '>' || ch == '<') {
      tokens.add(_Token(_TokenType.operator_, ch));
      i++;
      continue;
    }

    // 숫자 리터럴
    final chCode = ch.codeUnitAt(0);
    if (chCode >= 48 && chCode <= 57) {
      final sb = StringBuffer();
      while (i < expr.length) {
        final c = expr[i].codeUnitAt(0);
        if (c < 48 || c > 57) break;
        sb.write(expr[i]);
        i++;
      }
      tokens.add(_Token(_TokenType.intLiteral, sb.toString()));
      continue;
    }

    // 식별자 / 키워드 / has_trait:key / joined_faction:id 등
    // 콜론(:)과 콤마(,)를 포함하여 연속 읽기 (has_any_trait:k1,k2 형태 지원)
    if (_isIdentStart(ch)) {
      final sb = StringBuffer();
      while (i < expr.length) {
        final c = expr[i];
        if (!_isIdentChar(c) && c != ':' && c != ',') break;
        sb.write(c);
        i++;
      }
      final word = sb.toString();
      switch (word) {
        case 'and':
          tokens.add(_Token(_TokenType.and_, word));
        case 'or':
          tokens.add(_Token(_TokenType.or_, word));
        case 'not':
          tokens.add(_Token(_TokenType.not_, word));
        default:
          tokens.add(_Token(_TokenType.identifier, word));
      }
      continue;
    }

    throw FormatException('알 수 없는 문자: $ch');
  }

  return tokens;
}

bool _isIdentStart(String c) {
  final code = c.codeUnitAt(0);
  return (code >= 65 && code <= 90) || // A-Z
      (code >= 97 && code <= 122) || // a-z
      code == 95; // _
}

bool _isIdentChar(String c) {
  final code = c.codeUnitAt(0);
  return _isIdentStart(c) || (code >= 48 && code <= 57); // 0-9
}

enum _TokenType {
  stringLiteral,
  intLiteral,
  varRef,
  operator_,
  identifier,
  lParen,
  rParen,
  and_,
  or_,
  not_,
}

class _Token {
  final _TokenType type;
  final String value;
  const _Token(this.type, this.value);
}

class _ExprParser {
  final List<_Token> tokens;
  // null이면 validate 모드 — 구문 파싱만 수행하고 실제 평가는 하지 않음
  final TemplateContext? context;
  // 변수 해결 콜백 — TemplateEngine 인스턴스 직접 참조를 피함
  final String? Function(String namespace, String field) resolveVariable;
  final bool validateMode;
  final Set<String>? knownTraitKeys;
  final Set<String>? knownFactionIds;
  final List<TemplateValidationError>? validationErrors;
  final int? baseOffset;

  int _pos = 0;

  _ExprParser(
    this.tokens,
    this.context, {
    required this.resolveVariable,
    this.validateMode = false,
    this.knownTraitKeys,
    this.knownFactionIds,
    this.validationErrors,
    this.baseOffset,
  });

  _Token? get _current => _pos < tokens.length ? tokens[_pos] : null;

  _Token _consume() => tokens[_pos++];

  bool _check(_TokenType type) => _current?.type == type;

  // 우선순위: not > and > or
  bool parseOr() {
    var left = _parseAnd();
    while (_current?.type == _TokenType.or_) {
      _consume();
      final right = _parseAnd();
      left = left || right;
    }
    return left;
  }

  bool _parseAnd() {
    var left = _parseNot();
    while (_current?.type == _TokenType.and_) {
      _consume();
      final right = _parseNot();
      left = left && right;
    }
    return left;
  }

  bool _parseNot({int depth = 0}) {
    if (_current?.type == _TokenType.not_) {
      if (depth > 10) {
        throw FormatException('not 중첩 깊이 초과 (max 10)');
      }
      _consume();
      return !_parseNot(depth: depth + 1);
    }
    return _parsePrimary();
  }

  bool _parsePrimary() {
    // 괄호 그룹
    if (_check(_TokenType.lParen)) {
      _consume();
      final val = parseOr();
      if (!_check(_TokenType.rParen)) throw FormatException('닫는 괄호 없음');
      _consume();
      return val;
    }

    // 변수 비교: {namespace.field} OP literal
    if (_check(_TokenType.varRef)) {
      final varToken = _consume();
      final varStr = varToken.value;
      final dotIdx = varStr.indexOf('.');
      if (dotIdx == -1) throw FormatException('변수 형식 오류: $varStr');
      final ns = varStr.substring(0, dotIdx);
      final field = varStr.substring(dotIdx + 1);

      if (!_check(_TokenType.operator_)) {
        throw FormatException('연산자 기대: $varStr 뒤');
      }
      final op = _consume().value;
      final literal = _parseLiteral();

      if (validateMode) return false;

      final resolved = resolveVariable(ns, field);
      return _compare(resolved, op, literal);
    }

    // 특수 함수: has_trait / has_any_trait / has_all_traits / joined_faction
    if (_check(_TokenType.identifier)) {
      final token = _consume();
      final id = token.value;

      if (id.startsWith('has_trait:')) {
        final key = id.substring('has_trait:'.length);
        _checkTraitKey(key);
        if (validateMode) return false;
        return _hasTrait(key);
      }

      if (id.startsWith('has_any_trait:')) {
        final keys = id.substring('has_any_trait:'.length).split(',');
        if (keys.length > 5) throw FormatException('has_any_trait 최대 5개');
        for (final k in keys) {
          _checkTraitKey(k);
        }
        if (validateMode) return false;
        return keys.any(_hasTrait);
      }

      if (id.startsWith('has_all_traits:')) {
        final keys = id.substring('has_all_traits:'.length).split(',');
        if (keys.length > 3) throw FormatException('has_all_traits 최대 3개');
        for (final k in keys) {
          _checkTraitKey(k);
        }
        if (validateMode) return false;
        return keys.every(_hasTrait);
      }

      if (id.startsWith('joined_faction:')) {
        final factionId = id.substring('joined_faction:'.length);
        _checkFactionId(factionId);
        if (validateMode) return false;
        final ctx = context!;
        return ctx.factionStates.any(
          (f) => f.factionId == factionId && f.isJoined,
        );
      }

      throw FormatException('알 수 없는 식별자: $id');
    }

    throw FormatException('예상치 못한 토큰: ${_current?.value}');
  }

  String _parseLiteral() {
    if (_check(_TokenType.stringLiteral)) return _consume().value;
    if (_check(_TokenType.intLiteral)) return _consume().value;
    if (_check(_TokenType.identifier)) return _consume().value;
    throw FormatException('리터럴 기대');
  }

  bool _compare(String? resolved, String op, String literal) {
    if (resolved == null) return false;

    final lhsInt = int.tryParse(resolved);
    final rhsInt = int.tryParse(literal);

    if (lhsInt != null && rhsInt != null) {
      switch (op) {
        case '==':
          return lhsInt == rhsInt;
        case '!=':
          return lhsInt != rhsInt;
        case '>':
          return lhsInt > rhsInt;
        case '>=':
          return lhsInt >= rhsInt;
        case '<':
          return lhsInt < rhsInt;
        case '<=':
          return lhsInt <= rhsInt;
        default:
          return false;
      }
    }

    switch (op) {
      case '==':
        return resolved == literal;
      case '!=':
        return resolved != literal;
      default:
        log('문자열에 숫자 비교 연산 불가 ($op)', name: 'TemplateEngine');
        return false;
    }
  }

  bool _hasTrait(String traitKey) {
    final ctx = context!;
    switch (ctx.evaluationScope) {
      case EvaluationScope.mercenary:
        final merc = ctx.merc;
        if (merc == null) return false;
        return merc.allTraitIds.contains(traitKey);
      case EvaluationScope.team:
        if (ctx.rosterForTeam.isEmpty) return false;
        return ctx.rosterForTeam.any((m) => m.allTraitIds.contains(traitKey));
    }
  }

  void _checkTraitKey(String key) {
    if (knownTraitKeys != null && !knownTraitKeys!.contains(key)) {
      validationErrors?.add(TemplateValidationError(
        code: TemplateValidationCode.unknownTraitKey,
        message: '미등록 trait key: $key',
        offset: baseOffset,
      ));
    }
  }

  void _checkFactionId(String id) {
    if (knownFactionIds != null && !knownFactionIds!.contains(id)) {
      validationErrors?.add(TemplateValidationError(
        code: TemplateValidationCode.unknownFactionId,
        message: '미등록 faction id: $id',
        offset: baseOffset,
      ));
    }
  }
}
