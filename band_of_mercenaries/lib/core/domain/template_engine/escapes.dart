part of '../template_engine.dart';

// 이스케이프 일시 치환용 sentinel 문자 (Private Use Area U+E000~U+E005).
// 일반 게임 텍스트에 출현하지 않는 영역을 사용하여 충돌 방지.
const _sentinelLBrace = ''; // \{
const _sentinelRBrace = ''; // \}
const _sentinelLBracket = ''; // \[
const _sentinelRBracket = ''; // \]
const _sentinelPipe = ''; // \|
const _sentinelBackslash = ''; // \\

String _applyEscapes(String src) {
  final buf = StringBuffer();
  var i = 0;
  while (i < src.length) {
    if (src[i] == '\\' && i + 1 < src.length) {
      final next = src[i + 1];
      switch (next) {
        case '{':
          buf.write(_sentinelLBrace);
          i += 2;
        case '}':
          buf.write(_sentinelRBrace);
          i += 2;
        case '[':
          buf.write(_sentinelLBracket);
          i += 2;
        case ']':
          buf.write(_sentinelRBracket);
          i += 2;
        case '|':
          buf.write(_sentinelPipe);
          i += 2;
        case '\\':
          buf.write(_sentinelBackslash);
          i += 2;
        default:
          // 정의되지 않은 이스케이프는 백슬래시 그대로 출력
          buf.write(src[i]);
          i++;
      }
    } else {
      buf.write(src[i]);
      i++;
    }
  }
  return buf.toString();
}

String _restoreEscapes(String src) {
  return src
      .replaceAll(_sentinelLBrace, '{')
      .replaceAll(_sentinelRBrace, '}')
      .replaceAll(_sentinelLBracket, '[')
      .replaceAll(_sentinelRBracket, ']')
      .replaceAll(_sentinelPipe, '|')
      .replaceAll(_sentinelBackslash, r'\');
}
