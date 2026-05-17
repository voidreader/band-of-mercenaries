enum DangerLevel { stable, peaceful, tension, threat }

extension DangerLevelLabel on DangerLevel {
  String get koreanLabel => switch (this) {
    DangerLevel.stable => '안정',
    DangerLevel.peaceful => '평온',
    DangerLevel.tension => '긴장',
    DangerLevel.threat => '위협',
  };

  String get lowercaseString => switch (this) {
    DangerLevel.stable => 'stable',
    DangerLevel.peaceful => 'peaceful',
    DangerLevel.tension => 'tension',
    DangerLevel.threat => 'threat',
  };

  int get cacheInt => switch (this) {
    DangerLevel.stable => 1,
    DangerLevel.peaceful => 2,
    DangerLevel.tension => 3,
    DangerLevel.threat => 4,
  };
}

class DangerLevelResolver {
  static DangerLevel resolveLevel(int score) {
    if (score >= 50) return DangerLevel.threat;
    if (score >= 0) return DangerLevel.tension;
    if (score >= -50) return DangerLevel.peaceful;
    return DangerLevel.stable;
  }

  static DangerLevel? fromCacheInt(int? cache) => switch (cache) {
    1 => DangerLevel.stable,
    2 => DangerLevel.peaceful,
    3 => DangerLevel.tension,
    4 => DangerLevel.threat,
    _ => null,
  };

  static DangerLevel? fromLowercaseString(String s) => switch (s) {
    'stable' => DangerLevel.stable,
    'peaceful' => DangerLevel.peaceful,
    'tension' => DangerLevel.tension,
    'threat' => DangerLevel.threat,
    _ => null,
  };
}
