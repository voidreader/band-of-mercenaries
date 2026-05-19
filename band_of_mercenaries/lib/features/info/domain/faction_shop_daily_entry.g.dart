// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faction_shop_daily_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FactionShopDailyEntryAdapter extends TypeAdapter<FactionShopDailyEntry> {
  @override
  final int typeId = 20;

  @override
  FactionShopDailyEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FactionShopDailyEntry(
      count: fields[0] as int,
      restockAt: fields[1] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FactionShopDailyEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.count)
      ..writeByte(1)
      ..write(obj.restockAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FactionShopDailyEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
