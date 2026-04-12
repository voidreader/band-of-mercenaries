import 'package:freezed_annotation/freezed_annotation.dart';

part 'mercenary_wage.freezed.dart';
part 'mercenary_wage.g.dart';

@freezed
class MercenaryWage with _$MercenaryWage {
  const factory MercenaryWage({
    required int tier,
    required int wage,
  }) = _MercenaryWage;

  factory MercenaryWage.fromJson(Map<String, dynamic> json) =>
      _$MercenaryWageFromJson(json);
}