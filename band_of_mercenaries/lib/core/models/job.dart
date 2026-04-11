import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required int tier,
    required String name,
    @JsonKey(name: 'base_atk') required int baseAtk,
    @JsonKey(name: 'base_def') required int baseDef,
    @JsonKey(name: 'base_hp') required int baseHp,
    required double speed,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

@freezed
class JobList with _$JobList {
  const factory JobList({
    @JsonKey(name: 'Jobs') required List<Job> items,
  }) = _JobList;

  factory JobList.fromJson(Map<String, dynamic> json) =>
      _$JobListFromJson(json);
}
