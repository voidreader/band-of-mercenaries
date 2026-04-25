sealed class TemplateParseNode {
  const TemplateParseNode();
}

class TextNode extends TemplateParseNode {
  final String text;
  const TextNode(this.text);
}

class VariableNode extends TemplateParseNode {
  final String namespace;
  final String field;
  final String? fallback;
  const VariableNode({required this.namespace, required this.field, this.fallback});
}

class IfBranch {
  final String expression;
  final List<TemplateParseNode> body;
  const IfBranch({required this.expression, required this.body});
}

class IfNode extends TemplateParseNode {
  final List<IfBranch> branches;
  final List<TemplateParseNode>? elseBody;
  const IfNode({required this.branches, this.elseBody});
}

class PickNode extends TemplateParseNode {
  // pick 블록 내 중첩(pick/if) 금지 규칙에 따라 후보는 평문 문자열만 허용
  final List<String> candidates;
  const PickNode(this.candidates);
}
