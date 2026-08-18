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

  static Future<void> clearAll() async {
    await _box.clear();
  }
}
