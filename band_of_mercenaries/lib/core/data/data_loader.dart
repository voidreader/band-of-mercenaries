import 'dart:convert';
import 'dart:io';

class DataLoader {
  final Directory cacheDir;

  DataLoader({required this.cacheDir});

  /// 캐시 파일이 하나라도 존재하는지 확인 (첫 실행 판별)
  bool hasCache() {
    if (!cacheDir.existsSync()) return false;
    return cacheDir.listSync().whereType<File>().any((f) => f.path.endsWith('.json'));
  }

  /// 특정 테이블의 캐시 파일 존재 여부
  bool hasCacheFor(String tableName) {
    final file = File('${cacheDir.path}/$tableName.json');
    return file.existsSync();
  }

  /// Supabase 응답을 캐시 파일로 저장
  Future<void> saveToCache(String tableName, List<Map<String, dynamic>> data) async {
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    final file = File('${cacheDir.path}/$tableName.json');
    await file.writeAsString(jsonEncode(data));
  }

  /// 캐시 파일에서 모델 리스트 로딩
  List<T> loadFromCache<T>(String tableName, T Function(Map<String, dynamic>) fromJson) {
    final file = File('${cacheDir.path}/$tableName.json');
    if (!file.existsSync()) return [];

    final jsonString = file.readAsStringSync();
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Supabase 응답(List<Map>)을 모델 리스트로 변환
  static List<T> parseList<T>(
    List<Map<String, dynamic>> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return data.map((e) => fromJson(e)).toList();
  }
}
