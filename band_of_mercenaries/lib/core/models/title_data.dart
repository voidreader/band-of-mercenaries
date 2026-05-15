import 'package:freezed_annotation/freezed_annotation.dart';

part 'title_data.freezed.dart';
part 'title_data.g.dart';

/// 칭호 정적 데이터 모델 (Supabase titles 테이블)
@freezed
class TitleData with _$TitleData {
  const factory TitleData({
    required String id,
    required String name,
    required String description,
    @JsonKey(name: 'hook_type') required String hookType,
    @JsonKey(name: 'hook_condition') @Default({}) Map<String, dynamic> hookCondition,
    @JsonKey(name: 'effect_json') @Default({}) Map<String, dynamic> effectJson,
    @JsonKey(name: 'icon_key') @Default('default') String iconKey,
    @JsonKey(name: 'narrative_hint') String? narrativeHint,
  }) = _TitleData;

  factory TitleData.fromJson(Map<String, dynamic> json) => _$TitleDataFromJson(json);
}
