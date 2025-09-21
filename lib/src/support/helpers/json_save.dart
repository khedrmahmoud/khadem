dynamic jsonSafe(dynamic value) {
  if (value is DateTime) return value.toIso8601String();
  if (value is Map) return value.map((k, v) => MapEntry(k, jsonSafe(v)));
  if (value is List) return value.map(jsonSafe).toList();
  return value;
} 
