import 'dart:convert';
import 'package:hive/hive.dart';

class DataLoader {
  final Box<String> _cacheBox;

  DataLoader({required Box<String> cacheBox}) : _cacheBox = cacheBox;

  /// 캐시가 하나라도 존재하는지 확인 (첫 실행 판별)
  bool hasCache() => _cacheBox.isNotEmpty;

  /// 특정 테이블의 캐시 존재 여부
  bool hasCacheFor(String tableName) => _cacheBox.containsKey(tableName);

  /// 캐시는 있으나 내용이 비어있는지 검사 (`null`/공백/`'[]'`).
  /// SyncService 자가치유에 사용.
  bool isCacheEmpty(String tableName) {
    final raw = _cacheBox.get(tableName);
    if (raw == null) return true;
    final trimmed = raw.trim();
    return trimmed.isEmpty || trimmed == '[]';
  }

  /// Supabase 응답을 캐시에 저장
  Future<void> saveToCache(String tableName, List<Map<String, dynamic>> data) async {
    await _cacheBox.put(tableName, jsonEncode(data));
  }

  /// 캐시에서 모델 리스트 로딩
  List<T> loadFromCache<T>(String tableName, T Function(Map<String, dynamic>) fromJson) {
    final jsonString = _cacheBox.get(tableName);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  /// Supabase 응답(List<Map>)을 모델 리스트로 변환
  static List<T> parseList<T>(
    List<Map<String, dynamic>> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return data.map((e) => fromJson(e)).toList();
  }
}
