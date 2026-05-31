import 'package:hive/hive.dart';

part 'battle_memory_entry.g.dart';

/// 전투 기억 항목 — 용병이 수집한 전투 중 획득 감정·스탯·위업·칭호·특수 이벤트.
@HiveType(typeId: 31)
class BattleMemoryEntry extends HiveObject {
  /// 기억 소유 용병 ID
  @HiveField(0)
  final String mercId;

  /// 기억 유형 — 6종 허용:
  /// - emotional_apply: 감정 획득
  /// - hidden_stat_unlock: 숨겨진 스탯 해금
  /// - achievement_granted: 위업 부여
  /// - title_granted: 칭호 부여
  /// - solo_great_success: 솔로 대성공
  /// - unique_elite_first_kill: 유니크 엘리트 첫 처치
  @HiveField(1)
  final String entryType;

  /// 원천 사건 ID (퀘스트/체인/엘리트 ID 등)
  @HiveField(2)
  final String sourceEventId;

  /// 기억 기록 시각
  @HiveField(3)
  final DateTime timestamp;

  /// TemplateEngine 렌더용 템플릿 키 (achievement/title은 null, lookup 렌더)
  @HiveField(4)
  final String? templateKey;

  /// TemplateEngine 변수 맵
  @HiveField(5)
  final Map<String, dynamic> templateData;

  BattleMemoryEntry({
    required this.mercId,
    required this.entryType,
    required this.sourceEventId,
    required this.timestamp,
    this.templateKey,
    this.templateData = const {},
  });
}
