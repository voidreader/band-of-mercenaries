import 'package:hive/hive.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/models/user_data.dart';

class MovementRepository {
  Box<UserData> get _box => Hive.box<UserData>(HiveInitializer.userBoxName);

  UserData? get userData => _box.isNotEmpty ? _box.getAt(0) : null;

  Future<void> startMovement(int targetRegion, int targetSector, DateTime endTime) async {
    final user = userData;
    if (user == null) return;
    user.isMoving = true;
    user.moveTargetRegion = targetRegion;
    user.moveTargetSector = targetSector;
    user.moveEndTime = endTime;
    await user.save();
  }

  Future<void> completeMovement() async {
    final user = userData;
    if (user == null) return;
    user.region = user.moveTargetRegion!;
    user.sector = user.moveTargetSector!;
    user.isMoving = false;
    user.moveTargetRegion = null;
    user.moveTargetSector = null;
    user.moveEndTime = null;
    await user.save();
  }
}
