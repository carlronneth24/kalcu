import 'package:hive_flutter/hive_flutter.dart';
import '../models/history_entry.dart';

class HistoryService {
  static const String boxName = 'historyBox';

  // Call once in main.dart before runApp()
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Box get _box => Hive.box(boxName);

  static Future<void> addEntry(String expression, String result) async {
    final entry = HistoryEntry(
      expression: expression,
      result: result,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _box.add(entry.toMap());
  }

  static List<HistoryEntry> getAllEntries() {
    return _box.values
        .map((item) => HistoryEntry.fromMap(Map<dynamic, dynamic>.from(item)))
        .toList()
        .reversed
        .toList(); // newest first
  }

  /// Returns entries paired with their Hive keys, newest first.
  /// Needed so specific entries can be deleted (not just "clear all").
  static List<MapEntry<dynamic, HistoryEntry>> getAllEntriesWithKeys() {
    final keys = _box.keys.toList().reversed.toList(); // newest first
    return keys.map((key) {
      final map = Map<dynamic, dynamic>.from(_box.get(key));
      return MapEntry(key, HistoryEntry.fromMap(map));
    }).toList();
  }

  /// Deletes only the entries matching the given keys.
  static Future<void> deleteByKeys(Iterable<dynamic> keys) async {
    await _box.deleteAll(keys);
  }

  static Future<void> clearAll() async {
    await _box.clear();
  }
}