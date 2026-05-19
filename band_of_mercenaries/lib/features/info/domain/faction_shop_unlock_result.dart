/// M8a 세력 상점 해금 평가 결과 sealed type (FR-D2)
sealed class FactionShopUnlockResult {
  const FactionShopUnlockResult();
}

/// 세력 상점 해금 조건이 모두 충족되어 구매 가능한 상태.
class FactionShopUnlockReady extends FactionShopUnlockResult {
  const FactionShopUnlockReady();
}

/// 세력 상점 해금 조건 미충족 상태.
class FactionShopUnlockLocked extends FactionShopUnlockResult {
  final String reason;
  const FactionShopUnlockLocked(this.reason);
}

/// 해당 아이템이 매진(daily 한도 초과 또는 1회 한정 구매 완료)된 상태.
class FactionShopUnlockSoldOut extends FactionShopUnlockResult {
  final DateTime? restockAt;
  const FactionShopUnlockSoldOut(this.restockAt);
}
