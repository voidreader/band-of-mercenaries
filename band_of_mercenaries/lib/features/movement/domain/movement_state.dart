class MovementState {
  final bool isMoving;
  final int? moveTargetRegion;
  final int? moveTargetSector;
  final DateTime? moveEndTime;
  final int currentRegion;
  final int currentSector;

  const MovementState({
    this.isMoving = false,
    this.moveTargetRegion,
    this.moveTargetSector,
    this.moveEndTime,
    required this.currentRegion,
    required this.currentSector,
  });
}
