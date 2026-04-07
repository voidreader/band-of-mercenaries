import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    @JsonKey(name: 'ID') required String id,
    @JsonKey(name: 'Tier') required int tier,
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'BaseAtk') required int baseAtk,
    @JsonKey(name: 'BaseDef') required int baseDef,
    @JsonKey(name: 'BaseHp') required int baseHp,
    @JsonKey(name: 'Speed') required double speed,
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
