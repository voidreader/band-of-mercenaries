import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/features/mercenary/domain/mercenary_model.dart';

/// 파견 상성 계산용 role 추출/변환 유틸.
class RoleUtils {
  /// 용병 리스트 → role 리스트 변환. 알 수 없는 jobId는 'specialist' fallback.
  static List<String> extractRoles(List<Mercenary> mercs, List<Job> jobs) {
    return mercs.map((m) {
      final job = jobs.where((j) => j.id == m.jobId).firstOrNull;
      return job?.role ?? 'specialist';
    }).toList();
  }

  /// role 한글 표시명 매핑. 알 수 없는 role → '전문가'.
  static const Map<String, String> _koreanNames = {
    'warrior': '전사',
    'ranger': '순찰자',
    'mage': '마법사',
    'rogue': '도적',
    'support': '지원',
    'specialist': '전문가',
  };

  static String koreanName(String role) => _koreanNames[role] ?? '전문가';
}
