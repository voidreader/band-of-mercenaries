import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required int tier,
    required String name,
    @JsonKey(name: 'base_str') required int baseStr,
    @JsonKey(name: 'base_intelligence') required int baseIntelligence,
    @JsonKey(name: 'base_vit') required int baseVit,
    @JsonKey(name: 'base_agi') required int baseAgi,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}