import 'package:freezed_annotation/freezed_annotation.dart';

part 'person_name.freezed.dart';
part 'person_name.g.dart';

@freezed
class PersonName with _$PersonName {
  const factory PersonName({
    required int id,
    required String korean,
  }) = _PersonName;

  factory PersonName.fromJson(Map<String, dynamic> json) =>
      _$PersonNameFromJson(json);
}