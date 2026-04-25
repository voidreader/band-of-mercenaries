part of '../template_engine.dart';

/// 템플릿 렌더링 메인 함수. TemplateEngine.render에서 호출.
String _renderTemplate(String template, TemplateContext context) {
  if (template.isEmpty) return '';
  try {
    // pick 시드: render 호출당 1회 생성 (시드 지정 시 재현 가능)
    final random = context.seed != null
        ? Random(context.seed!)
        : Random();

    final escaped = _applyEscapes(template);
    final nodes = _parseTemplate(escaped);
    final result = _renderNodes(nodes, context, random);
    return _restoreEscapes(result);
  } on FormatException catch (e) {
    log('TemplateEngine: parse 오류 — $e', name: 'TemplateEngine');
    return template;
  } on Error catch (e, st) {
    assert(false, 'TemplateEngine 내부 Error: $e\n$st');
    log('TemplateEngine: 내부 Error — $e', name: 'TemplateEngine');
    return template;
  }
}

String _renderNodes(
  List<TemplateParseNode> nodes,
  TemplateContext ctx,
  Random random,
) {
  final buf = StringBuffer();
  for (final node in nodes) {
    switch (node) {
      case TextNode(:final text):
        buf.write(text);
      case VariableNode(:final namespace, :final field, :final fallback):
        buf.write(_renderVariable(namespace, field, fallback, ctx));
      case IfNode(:final branches, :final elseBody):
        var rendered = false;
        for (final branch in branches) {
          if (_evaluateExpression(branch.expression, ctx)) {
            buf.write(_renderNodes(branch.body, ctx, random));
            rendered = true;
            break;
          }
        }
        if (!rendered && elseBody != null) {
          buf.write(_renderNodes(elseBody, ctx, random));
        }
      case PickNode(:final candidates):
        // 11개 이상이면 10개까지만 사용 (FR-4 엣지케이스)
        final pool = candidates.length > 10
            ? candidates.sublist(0, 10)
            : candidates;
        if (pool.isNotEmpty) {
          buf.write(pool[random.nextInt(pool.length)]);
        }
    }
  }
  return buf.toString();
}

String _renderVariable(
  String namespace,
  String field,
  String? fallback,
  TemplateContext ctx,
) {
  if (!TemplateVariableCatalog.isKnown(namespace, field)) {
    log('미등록 변수 — $namespace.$field', name: 'TemplateEngine');
    return '[?:unknown:$namespace.$field]';
  }

  final resolved = _resolveVariable(namespace, field, ctx);

  if (resolved == null) {
    if (fallback != null) return fallback;
    log('값 null — $namespace.$field', name: 'TemplateEngine');
    return '[?$namespace.$field]';
  }

  return resolved;
}
