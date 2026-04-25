/// 템플릿 검증 오류 코드.
enum TemplateValidationCode {
  /// 등록되지 않은 namespace.field 참조.
  unknownVariable,

  /// `[if]/[/if]` 또는 `[pick]/[/pick]` 개폐 불균형.
  unbalancedBlock,

  /// 허용되지 않은 연산자 또는 조건식 syntax error.
  invalidExpression,

  /// `has_trait:<key>`의 key가 knownTraitKeys에 없음.
  unknownTraitKey,

  /// `joined_faction:<id>`의 id가 knownFactionIds에 없음.
  unknownFactionId,

  /// pick 후보 수 2~10 범위 위반.
  pickCandidateCount,

  /// if 중첩 3단계 이상.
  nestingTooDeep,

  /// 이스케이프 아닌 비매칭 괄호.
  unmatchedBracket,

  /// 잘못된 이스케이프 시퀀스.
  escapeError,
}

/// 템플릿 검증 오류 값 객체.
class TemplateValidationError {
  final TemplateValidationCode code;
  final String message;

  /// 오류가 발생한 템플릿 내 문자 위치. null이면 위치 불명.
  final int? offset;

  const TemplateValidationError({
    required this.code,
    required this.message,
    this.offset,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TemplateValidationError &&
        other.code == code &&
        other.message == message &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(code, message, offset);

  @override
  String toString() {
    if (offset != null) {
      return '[${code.name}] $message (offset: $offset)';
    }
    return '[${code.name}] $message';
  }
}
