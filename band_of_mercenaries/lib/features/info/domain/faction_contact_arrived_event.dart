import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'faction_contact_arrived_event.freezed.dart';

/// M8a 세력 접촉점 도착 이벤트 (FR-A6)
@freezed
class FactionContactArrivedEvent with _$FactionContactArrivedEvent {
  const factory FactionContactArrivedEvent({
    required String factionId,
    required String factionName,
    required String contactId,
    required String npcName,
    required String firstReactionText,
  }) = _FactionContactArrivedEvent;
}

/// 신규 세력 접촉점 활성 시 publish하는 channel.
final factionContactArrivedProvider =
    StateProvider<FactionContactArrivedEvent?>((ref) => null);
