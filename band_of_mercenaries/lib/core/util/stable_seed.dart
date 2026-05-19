/// FNV-1a 32-bit 안정 해시.
///
/// Dart `String.hashCode`는 앱 실행마다 달라질 수 있으므로 결정성이 필요한
/// 시드 산출(M8b CombatSimulator PRNG 도메인 키 등)에는 본 함수를 사용한다.
int stableSeed32(String input) {
  const int offsetBasis = 0x811C9DC5;
  const int prime = 0x01000193;
  int hash = offsetBasis;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * prime) & 0xFFFFFFFF;
  }
  return hash;
}
