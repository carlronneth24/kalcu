class HistoryEntry {
  final String expression;
  final String result;
  final String timestamp;

  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'expression': expression,
      'result': result,
      'timestamp': timestamp,
    };
  }

  factory HistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return HistoryEntry(
      expression: map['expression'] ?? '',
      result: map['result'] ?? '',
      timestamp: map['timestamp'] ?? '',
    );
  }
}
