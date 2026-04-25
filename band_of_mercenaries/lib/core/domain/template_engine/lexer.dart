part of '../template_engine.dart';

// 템플릿 렉서 토큰 유형 상수
const int _tText = 0;
const int _tVar = 1; // {namespace.field} 또는 {namespace.field|fallback}
const int _tBlockOpen = 2; // [if expr] 또는 [pick ...]
const int _tBlockClose = 3; // [/if]
const int _tElif = 4; // [elif expr]
const int _tElse = 5; // [else]

List<(int type, String value)> _lexTemplate(String src) {
  final tokens = <(int, String)>[];
  var i = 0;
  final buf = StringBuffer();

  void flushText() {
    if (buf.isNotEmpty) {
      tokens.add((_tText, buf.toString()));
      buf.clear();
    }
  }

  while (i < src.length) {
    if (src[i] == '{') {
      final end = src.indexOf('}', i + 1);
      if (end == -1) {
        buf.write(src[i]);
        i++;
        continue;
      }
      flushText();
      tokens.add((_tVar, src.substring(i + 1, end)));
      i = end + 1;
    } else if (src[i] == '[') {
      final end = src.indexOf(']', i + 1);
      if (end == -1) {
        buf.write(src[i]);
        i++;
        continue;
      }
      final inner = src.substring(i + 1, end).trim();
      if (inner == '/if') {
        flushText();
        tokens.add((_tBlockClose, inner));
        i = end + 1;
      } else if (inner == 'else') {
        flushText();
        tokens.add((_tElse, 'else'));
        i = end + 1;
      } else if (inner.startsWith('elif ')) {
        flushText();
        tokens.add((_tElif, inner.substring(5).trim()));
        i = end + 1;
      } else if (inner.startsWith('if ')) {
        flushText();
        tokens.add((_tBlockOpen, inner));
        i = end + 1;
      } else if (inner.startsWith('pick ')) {
        // [pick A|B|C] 자기완결형 — 전체를 단일 토큰으로 처리
        flushText();
        tokens.add((_tBlockOpen, inner));
        i = end + 1;
      } else {
        // 알 수 없는 블록 형식 — 텍스트로 처리
        buf.write('[');
        buf.write(inner);
        buf.write(']');
        i = end + 1;
      }
    } else {
      buf.write(src[i]);
      i++;
    }
  }
  flushText();
  return tokens;
}

List<TemplateParseNode> _buildAst(List<(int, String)> tokens) {
  var pos = 0;

  List<TemplateParseNode> parseNodes() {
    final nodes = <TemplateParseNode>[];

    while (pos < tokens.length) {
      final (type, value) = tokens[pos];

      if (type == _tText) {
        nodes.add(TextNode(value));
        pos++;
      } else if (type == _tVar) {
        // 첫 파이프만 분리 (fallback에 파이프가 있어도 첫 번째까지만 field name)
        final pipeIdx = value.indexOf('|');
        final String rawField;
        final String? fallback;
        if (pipeIdx == -1) {
          rawField = value.trim();
          fallback = null;
        } else {
          rawField = value.substring(0, pipeIdx).trim();
          fallback = value.substring(pipeIdx + 1);
        }
        final dotIdx = rawField.indexOf('.');
        if (dotIdx == -1) {
          nodes.add(VariableNode(namespace: rawField, field: '', fallback: fallback));
        } else {
          final ns = rawField.substring(0, dotIdx);
          final field = rawField.substring(dotIdx + 1);
          nodes.add(VariableNode(namespace: ns, field: field, fallback: fallback));
        }
        pos++;
      } else if (type == _tBlockOpen) {
        if (value.startsWith('if ')) {
          pos++;
          final expr = value.substring(3).trim();
          final branches = <IfBranch>[];
          List<TemplateParseNode>? elseBody;

          final firstBody = parseNodes();
          branches.add(IfBranch(expression: expr, body: firstBody));

          while (pos < tokens.length) {
            final (t2, v2) = tokens[pos];
            if (t2 == _tBlockClose && v2 == '/if') {
              pos++;
              break;
            } else if (t2 == _tElif) {
              pos++;
              final elifBody = parseNodes();
              branches.add(IfBranch(expression: v2, body: elifBody));
            } else if (t2 == _tElse) {
              pos++;
              elseBody = parseNodes();
            } else {
              // 예상치 못한 토큰 — 상위 파서로 제어 반환
              break;
            }
          }
          nodes.add(IfNode(branches: branches, elseBody: elseBody));
        } else if (value.startsWith('pick ')) {
          // [pick A|B|C] — 파이프로 후보 분리. sentinel 복원 후 사용
          final raw = value.substring(5);
          final candidates = raw.split('|').map(_restoreEscapes).toList();
          nodes.add(PickNode(candidates));
          pos++;
        } else {
          pos++;
        }
      } else if (type == _tBlockClose || type == _tElif || type == _tElse) {
        // 상위 파서에게 제어 반환
        break;
      } else {
        pos++;
      }
    }

    return nodes;
  }

  return parseNodes();
}

/// 이스케이프 치환 완료된 [src]를 AST 노드 목록으로 변환한다.
List<TemplateParseNode> _parseTemplate(String src) {
  final rawTokens = _lexTemplate(src);
  return _buildAst(rawTokens);
}
