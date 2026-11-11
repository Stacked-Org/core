import 'dart:convert';

import 'action_param.dart';
import 'stacked_json.dart';

/// Thrown when the input an agent sent can't be turned into action parameters.
class ActionInputException implements Exception {
  const ActionInputException(this.param, this.expected, this.actual);

  final String param;

  /// For example 'string', 'int', 'one of light|dark',
  /// 'a JSON object with keys email, password'.
  final String expected;
  final Object? actual;

  /// 'Input for "{param}" must be {expected}, got {jsonEncode(actual)}.'
  /// When actual is null: 'Input for "{param}" must be {expected}, got nothing.'
  String get message {
    final got = actual == null ? 'nothing' : _encode(actual);
    return 'Input for "$param" must be $expected, got $got.';
  }

  static String _encode(Object? value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return jsonEncode(StackedJson.encode(value));
    }
  }

  @override
  String toString() => message;
}

/// Normalizes raw agent input and reads typed values from it.
abstract final class ActionInput {
  /// Turns the raw JSON an agent sent into a parameter map.
  ///  - raw == null -> {}
  ///  - params.isEmpty -> {} (raw ignored)
  ///  - params.length == 1:
  ///      raw is a Map with String keys containing params[0].name -> raw
  ///      otherwise -> {params[0].name: raw}
  ///  - params.length > 1:
  ///      raw is a Map with String keys -> raw
  ///      otherwise -> throw ActionInputException
  static Map<String, Object?> normalize(Object? raw, List<ActionParam> params) {
    if (raw == null) return <String, Object?>{};
    if (params.isEmpty) return <String, Object?>{};

    final asMap = _stringKeyedMap(raw);
    if (params.length == 1) {
      final name = params[0].name;
      if (asMap != null && asMap.containsKey(name)) return asMap;
      return <String, Object?>{name: raw};
    }

    if (asMap != null) return asMap;
    throw ActionInputException(
      '*',
      'a JSON object with keys ${params.map((p) => p.name).join(', ')}',
      raw,
    );
  }

  static Map<String, Object?>? _stringKeyedMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map && value.keys.every((k) => k is String)) {
      return Map<String, Object?>.from(value);
    }
    return null;
  }

  // ───────────────────────── readers ─────────────────────────

  static String string(Map<String, Object?> input, String name) =>
      _required(input, name, 'string', _asString);

  static String? stringOrNull(Map<String, Object?> input, String name) =>
      _optional(input, name, 'string', _asString);

  static int integer(Map<String, Object?> input, String name) =>
      _required(input, name, 'int', _asInt);

  static int? integerOrNull(Map<String, Object?> input, String name) =>
      _optional(input, name, 'int', _asInt);

  static double decimal(Map<String, Object?> input, String name) =>
      _required(input, name, 'double', _asDouble);

  static double? decimalOrNull(Map<String, Object?> input, String name) =>
      _optional(input, name, 'double', _asDouble);

  static num number(Map<String, Object?> input, String name) =>
      _required(input, name, 'num', _asNum);

  static num? numberOrNull(Map<String, Object?> input, String name) =>
      _optional(input, name, 'num', _asNum);

  static bool boolean(Map<String, Object?> input, String name) =>
      _required(input, name, 'bool', _asBool);

  static bool? booleanOrNull(Map<String, Object?> input, String name) =>
      _optional(input, name, 'bool', _asBool);

  static DateTime dateTime(Map<String, Object?> input, String name) =>
      _required(input, name, 'datetime', _asDateTime);

  static DateTime? dateTimeOrNull(Map<String, Object?> input, String name) =>
      _optional(input, name, 'datetime', _asDateTime);

  static T enumValue<T extends Enum>(
    Map<String, Object?> input,
    String name,
    List<T> values,
  ) =>
      _required(input, name, _enumExpected(values), _asEnum(values));

  static T? enumValueOrNull<T extends Enum>(
    Map<String, Object?> input,
    String name,
    List<T> values,
  ) =>
      _optional(input, name, _enumExpected(values), _asEnum(values));

  static List<T> list<T>(
    Map<String, Object?> input,
    String name,
    T Function(Object? item) convert,
  ) =>
      _required(input, name, 'list', _asList(name, convert));

  static List<T>? listOrNull<T>(
    Map<String, Object?> input,
    String name,
    T Function(Object? item) convert,
  ) =>
      _optional(input, name, 'list', _asList(name, convert));

  static Map<String, Object?> map(Map<String, Object?> input, String name) =>
      _required(input, name, 'map', _stringKeyedMap);

  static Map<String, Object?>? mapOrNull(
    Map<String, Object?> input,
    String name,
  ) =>
      _optional(input, name, 'map', _stringKeyedMap);

  static Object? any(Map<String, Object?> input, String name) => input[name];

  // ───────────────────────── helpers ─────────────────────────

  static T _required<T>(
    Map<String, Object?> input,
    String name,
    String expected,
    T? Function(Object value) convert,
  ) {
    final value = input[name];
    if (value == null) throw ActionInputException(name, expected, null);
    final converted = convert(value);
    if (converted == null) throw ActionInputException(name, expected, value);
    return converted;
  }

  static T? _optional<T>(
    Map<String, Object?> input,
    String name,
    String expected,
    T? Function(Object value) convert,
  ) {
    final value = input[name];
    if (value == null) return null;
    final converted = convert(value);
    if (converted == null) throw ActionInputException(name, expected, value);
    return converted;
  }

  static String? _asString(Object value) => value is String ? value : null;

  static int? _asInt(Object value) {
    if (value is int) return value;
    if (value is double) {
      return value.isFinite && value == value.roundToDouble()
          ? value.toInt()
          : null;
    }
    if (value is String) return int.tryParse(value);
    return null;
  }

  static num? _asNum(Object value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static double? _asDouble(Object value) => _asNum(value)?.toDouble();

  static bool? _asBool(Object value) {
    if (value is bool) return value;
    if (value is String) {
      if (value == 'true') return true;
      if (value == 'false') return false;
    }
    return null;
  }

  static DateTime? _asDateTime(Object value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static String _enumExpected(List<Enum> values) =>
      'one of ${values.map((v) => v.name).join('|')}';

  static T? Function(Object) _asEnum<T extends Enum>(List<T> values) {
    return (value) {
      if (value is! String) return null;
      for (final candidate in values) {
        if (candidate.name == value) return candidate;
      }
      return null;
    };
  }

  static List<T>? Function(Object) _asList<T>(
    String name,
    T Function(Object? item) convert,
  ) {
    return (value) {
      if (value is! List) return null;
      try {
        return [for (final item in value) convert(item)];
      } on ActionInputException {
        rethrow;
      } catch (_) {
        throw ActionInputException(name, 'list', value);
      }
    };
  }
}
