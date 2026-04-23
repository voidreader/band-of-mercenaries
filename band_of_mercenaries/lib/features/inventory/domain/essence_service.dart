import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:band_of_mercenaries/core/constants/game_constants.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_model.dart';
import 'package:band_of_mercenaries/core/domain/activity_log_provider.dart';
import 'package:band_of_mercenaries/core/models/item_data.dart';
import 'package:band_of_mercenaries/features/inventory/data/inventory_repository.dart';
import 'package:band_of_mercenaries/features/inventory/domain/inventory_item_model.dart';
import 'package:band_of_mercenaries/features/mercenary/data/mercenary_repository.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

part 'essence_service.freezed.dart';

/// 정수 아이템의 effect_json에서 파싱한 기본 정보.
@freezed
sealed class EssenceDescriptor with _$EssenceDescriptor {
  const factory EssenceDescriptor({
    required String statKey, // 'str' | 'intelligence' | 'vit' | 'agi'
    required int gain, // 티어별 증가량
    required int tier, // 정수 아이템 tier
  }) = _EssenceDescriptor;
}

/// 프리뷰 결과 — UI 표시용.
@freezed
sealed class EssencePreview with _$EssencePreview {
  const factory EssencePreview({
    required String statKey,
    required int currentPermanent,
    required int cap,
    required int gain,
    required int appliedGain,
    required int lossAmount,
    required int effectiveBefore,
    required int effectiveAfter,
    required EssencePreviewLevel warningLevel,
  }) = _EssencePreview;
}

/// 적용 결과.
@freezed
sealed class EssenceApplyResult with _$EssenceApplyResult {
  const factory EssenceApplyResult.success({
    required String statKey,
    required int appliedGain,
    required int lossAmount,
    required int newPermanent,
  }) = EssenceApplySuccess;
  const factory EssenceApplyResult.failure({
    required String reason,
  }) = EssenceApplyFailure;
}

/// 상한 경고 단계.
/// - normal: 손실 없음, 다음 사용에도 여유 있음
/// - approaching: 손실 없지만 다음 1회 효과 못 받을 만큼 잔량이 적음
/// - overflow: 이번 사용에서 손실 발생
enum EssencePreviewLevel { normal, approaching, overflow }

/// 정수 소비 서비스 — 정수 아이템 파싱, 프리뷰, 실제 적용 로직을 담당하는 순수 정적 서비스.
class EssenceService {
  EssenceService._();

  /// 티어별 정수 1회 효과. balance-design 페이즈 2 확정값.
  static const Map<int, int> tierGainTable = {
    1: 1,
    2: 2,
    3: 4,
    4: 7,
    5: 11,
  };

  /// 용병 티어별 축당 permanent 상한.
  static const Map<int, int> tierCapTable = {
    1: 10,
    2: 20,
    3: 40,
    4: 70,
    5: 120,
  };

  /// 스탯 키 → 한국어 표시명.
  static const Map<String, String> statKoreanNames = {
    'str': '힘(STR)',
    'intelligence': '지혜(INT)',
    'vit': '체력(VIT)',
    'agi': '민첩(AGI)',
  };

  static const _allowedStatKeys = {'str', 'intelligence', 'vit', 'agi'};

  /// 정수 아이템의 effect_json에서 (statKey, gain)을 추출.
  /// category != 'consumable'이거나 스키마 불일치 시 null.
  static EssenceDescriptor? resolve(ItemData item) {
    if (item.category != 'consumable') return null;
    final payload = item.effectJson['permanent_stat_gain'];
    if (payload is! Map) {
      return null;
    }
    if (payload.length != 1) {
      return null;
    }
    final entry = payload.entries.first;
    final statKey = entry.key.toString();
    if (!_allowedStatKeys.contains(statKey)) {
      return null;
    }
    final rawGain = entry.value;
    if (rawGain is! int) {
      return null;
    }
    return EssenceDescriptor(statKey: statKey, gain: rawGain, tier: item.tier);
  }

  /// 용병 현재 permanent* 값 조회.
  static int _getCurrentPermanent(Mercenary merc, String statKey) {
    switch (statKey) {
      case 'str':
        return merc.permanentStr;
      case 'intelligence':
        return merc.permanentIntelligence;
      case 'vit':
        return merc.permanentVit;
      case 'agi':
        return merc.permanentAgi;
      default:
        return 0;
    }
  }

  /// 용병 기본 effective 값 조회 (permanent 반영 후).
  static int _getEffective(Mercenary merc, String statKey) {
    switch (statKey) {
      case 'str':
        return merc.effectiveStr;
      case 'intelligence':
        return merc.effectiveIntelligence;
      case 'vit':
        return merc.effectiveVit;
      case 'agi':
        return merc.effectiveAgi;
      default:
        return 0;
    }
  }

  /// 가상으로 permanent += delta 적용 후의 effective 계산.
  /// (실제 모델 수정 없이 예측값만 계산)
  /// GameConstants.levelBonusPerLevel = 0.1, tiredDebuffMultiplier = 0.8 사용.
  static int _predictEffective(Mercenary merc, String statKey, int deltaPermanent) {
    final levelBonus = (merc.level - 1) * GameConstants.levelBonusPerLevel;
    int base;
    int currentPerm;
    switch (statKey) {
      case 'str':
        base = merc.str;
        currentPerm = merc.permanentStr;
        break;
      case 'intelligence':
        base = merc.intelligence;
        currentPerm = merc.permanentIntelligence;
        break;
      case 'vit':
        base = merc.vit;
        currentPerm = merc.permanentVit;
        break;
      case 'agi':
        base = merc.agi;
        currentPerm = merc.permanentAgi;
        break;
      default:
        return 0;
    }
    final withLevel = ((base + currentPerm + deltaPermanent) * (1.0 + levelBonus)).round();
    if (merc.status == MercenaryStatus.tired) {
      return (withLevel * GameConstants.tiredDebuffMultiplier).round();
    }
    return withLevel;
  }

  /// 사용 전 프리뷰.
  /// [mercenaryTier]는 Job.tier 조회 결과.
  static EssencePreview preview({
    required Mercenary mercenary,
    required ItemData essence,
    required int mercenaryTier,
  }) {
    final descriptor = resolve(essence);
    if (descriptor == null) {
      // 스키마 오류 fallback — UI가 진입 전 차단하지만 방어적 반환.
      return const EssencePreview(
        statKey: 'str',
        currentPermanent: 0,
        cap: 0,
        gain: 0,
        appliedGain: 0,
        lossAmount: 0,
        effectiveBefore: 0,
        effectiveAfter: 0,
        warningLevel: EssencePreviewLevel.overflow,
      );
    }
    final cap = tierCapTable[mercenaryTier] ?? 0;
    final currentPermanent = _getCurrentPermanent(mercenary, descriptor.statKey);
    final jail = math.max(cap - currentPermanent, 0);
    final appliedGain = math.min(descriptor.gain, jail);
    final lossAmount = descriptor.gain - appliedGain;
    final newPermanent = currentPermanent + appliedGain;
    final remainingAfter = cap - newPermanent;

    final EssencePreviewLevel warningLevel;
    if (lossAmount > 0 || appliedGain == 0) {
      warningLevel = EssencePreviewLevel.overflow;
    } else if (remainingAfter < descriptor.gain) {
      warningLevel = EssencePreviewLevel.approaching;
    } else {
      warningLevel = EssencePreviewLevel.normal;
    }

    final effectiveBefore = _getEffective(mercenary, descriptor.statKey);
    final effectiveAfter = _predictEffective(mercenary, descriptor.statKey, appliedGain);

    return EssencePreview(
      statKey: descriptor.statKey,
      currentPermanent: currentPermanent,
      cap: cap,
      gain: descriptor.gain,
      appliedGain: appliedGain,
      lossAmount: lossAmount,
      effectiveBefore: effectiveBefore,
      effectiveAfter: effectiveAfter,
      warningLevel: warningLevel,
    );
  }

  /// 실제 소비. 성공 시 permanent* 갱신 + 인벤토리 수량 차감 + 활동 로그.
  static Future<EssenceApplyResult> apply({
    required Mercenary mercenary,
    required int mercenaryTier,
    required InventoryItem inventoryRow,
    required ItemData essence,
    required MercenaryRepository mercRepo,
    required InventoryRepository inventoryRepo,
    required ActivityLogNotifier logNotifier,
  }) async {
    final descriptor = resolve(essence);
    if (descriptor == null) {
      return const EssenceApplyResult.failure(reason: 'schema');
    }
    if (inventoryRow.quantity <= 0) {
      return const EssenceApplyResult.failure(reason: 'not_found');
    }
    final cap = tierCapTable[mercenaryTier] ?? 0;
    final currentPermanent = _getCurrentPermanent(mercenary, descriptor.statKey);
    final jail = math.max(cap - currentPermanent, 0);
    final appliedGain = math.min(descriptor.gain, jail);
    if (appliedGain <= 0) {
      return const EssenceApplyResult.failure(reason: 'full_cap');
    }
    final lossAmount = descriptor.gain - appliedGain;

    // permanent 갱신
    switch (descriptor.statKey) {
      case 'str':
        mercenary.permanentStr = currentPermanent + appliedGain;
        break;
      case 'intelligence':
        mercenary.permanentIntelligence = currentPermanent + appliedGain;
        break;
      case 'vit':
        mercenary.permanentVit = currentPermanent + appliedGain;
        break;
      case 'agi':
        mercenary.permanentAgi = currentPermanent + appliedGain;
        break;
    }
    await mercenary.save();

    // 인벤토리 수량 차감 (0 도달 시 자동 삭제)
    await inventoryRepo.decrementQuantity(inventoryRow.id);

    // 활동 로그
    final statName = statKoreanNames[descriptor.statKey] ?? descriptor.statKey;
    final lossSuffix = lossAmount > 0 ? ' (+$lossAmount 손실)' : '';
    await logNotifier.addLog(
      '${mercenary.name}이(가) ${essence.name}을(를) 각인했다. $statName +$appliedGain$lossSuffix',
      ActivityLogType.essenceApplied,
    );

    return EssenceApplyResult.success(
      statKey: descriptor.statKey,
      appliedGain: appliedGain,
      lossAmount: lossAmount,
      newPermanent: currentPermanent + appliedGain,
    );
  }
}
