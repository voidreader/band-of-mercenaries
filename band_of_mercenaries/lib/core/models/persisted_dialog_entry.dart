import 'package:hive/hive.dart';

part 'persisted_dialog_entry.g.dart';

/// 다이얼로그 큐 항목 영속 모델.
/// 앱 종료 후에도 미표시 다이얼로그를 복원하기 위해 Hive에 저장한다.
@HiveType(typeId: 15)
class PersistedDialogEntry extends HiveObject {
  /// 중복 방지용 고유 id
  @HiveField(0)
  String id;

  /// DialogPriority.index (0=critical .. 3=low)
  @HiveField(1)
  int priority;

  /// DialogTypeRegistry 키 ('rankUp', 'constructionComplete' 등)
  @HiveField(2)
  String dialogType;

  /// payload를 jsonEncode 직렬화한 문자열
  @HiveField(3)
  String payloadJson;

  /// 24h 만료 기준 시각
  @HiveField(4)
  DateTime enqueuedAt;

  PersistedDialogEntry({
    required this.id,
    required this.priority,
    required this.dialogType,
    required this.payloadJson,
    required this.enqueuedAt,
  });
}
