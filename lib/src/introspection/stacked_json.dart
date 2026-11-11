/// Turns arbitrary values into JSON-safe data.
abstract final class StackedJson {
  /// Converts any value to JSON-safe data. Rules, checked in this order:
  ///  1. null, bool, String -> as-is. int -> as-is. double -> as-is if finite,
  ///     else its toString() ('NaN', 'Infinity', '-Infinity').
  ///  2. Enum -> .name
  ///  3. DateTime -> toIso8601String()
  ///  4. Duration -> inMilliseconds (int)
  ///  5. Uri -> toString()
  ///  6. Map -> `Map<String, Object?>` with key.toString() keys and encoded values
  ///  7. Iterable -> List of encoded values
  ///  8. Exception or Error -> {"$error": runtimeType.toString(), "message": toString()}
  ///  9. Object with a toJson() method -> encode(result)
  /// 10. anything else -> {"$unsupported": runtimeType.toString(), "text": toString()}
  ///
  /// Containers nested deeper than [maxDepth] levels become the string
  /// `<max depth>`. Scalars are always encoded.
  static Object? encode(Object? value, {int maxDepth = 8}) {
    if (value == null || value is bool || value is String || value is int) {
      return value;
    }
    if (value is double) return value.isFinite ? value : value.toString();
    if (value is Enum) return value.name;
    if (value is DateTime) return value.toIso8601String();
    if (value is Duration) return value.inMilliseconds;
    if (value is Uri) return value.toString();

    if (maxDepth <= 0) return '<max depth>';

    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key.toString(): encode(entry.value, maxDepth: maxDepth - 1),
      };
    }
    if (value is Iterable) {
      return [for (final item in value) encode(item, maxDepth: maxDepth - 1)];
    }
    if (value is Exception || value is Error) {
      return <String, Object?>{
        r'$error': value.runtimeType.toString(),
        'message': value.toString(),
      };
    }

    Object? json;
    var hasToJson = true;
    try {
      json = (value as dynamic).toJson();
    } on NoSuchMethodError {
      hasToJson = false;
    }
    if (hasToJson) return encode(json, maxDepth: maxDepth - 1);

    return <String, Object?>{
      r'$unsupported': value.runtimeType.toString(),
      'text': value.toString(),
    };
  }

  /// Calls [getter] and encodes the result. If the getter throws, returns
  /// {"$threw": error.toString()} instead of throwing.
  static Object? read(Object? Function() getter) {
    try {
      return encode(getter());
    } catch (error) {
      return <String, Object?>{r'$threw': error.toString()};
    }
  }
}
