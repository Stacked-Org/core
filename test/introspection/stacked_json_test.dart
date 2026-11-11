import 'dart:convert';

import 'package:stacked_shared/stacked_introspection.dart';
import 'package:test/test.dart';

enum _Mode { light, dark }

class _WithToJson {
  _WithToJson(this.value);
  final Object? value;
  Object? toJson() => {'v': value};
}

class _Plain {
  @override
  String toString() => 'plain!';
}

class _Boom implements Exception {
  @override
  String toString() => 'boom';
}

void main() {
  group('StackedJson.encode', () {
    test('1: null, bool, String, int are as-is', () {
      expect(StackedJson.encode(null), isNull);
      expect(StackedJson.encode(true), true);
      expect(StackedJson.encode('a'), 'a');
      expect(StackedJson.encode(3), 3);
    });

    test('1: finite doubles as-is, non-finite as strings', () {
      expect(StackedJson.encode(1.5), 1.5);
      expect(StackedJson.encode(double.nan), 'NaN');
      expect(StackedJson.encode(double.infinity), 'Infinity');
      expect(StackedJson.encode(double.negativeInfinity), '-Infinity');
    });

    test('2: enum -> name', () {
      expect(StackedJson.encode(_Mode.light), 'light');
    });

    test('3: DateTime -> iso string', () {
      final d = DateTime.utc(2024, 1, 2, 3, 4, 5);
      expect(StackedJson.encode(d), d.toIso8601String());
    });

    test('4: Duration -> milliseconds', () {
      expect(StackedJson.encode(const Duration(seconds: 2)), 2000);
    });

    test('5: Uri -> string', () {
      expect(StackedJson.encode(Uri.parse('https://a.b/c')), 'https://a.b/c');
    });

    test('6: Map keys are stringified and values encoded', () {
      final encoded = StackedJson.encode({1: _Mode.dark, 'x': null});
      expect(encoded, {'1': 'dark', 'x': null});
      expect(encoded, isA<Map<String, Object?>>());
    });

    test('7: Iterable -> List', () {
      expect(StackedJson.encode({1, 2}), [1, 2]);
      expect(StackedJson.encode([_Mode.light]), ['light']);
      expect(StackedJson.encode(Iterable.generate(2)), [0, 1]);
    });

    test('8: Exception and Error', () {
      expect(
          StackedJson.encode(_Boom()), {r'$error': '_Boom', 'message': 'boom'});
      final e = StackedJson.encode(StateError('bad')) as Map;
      expect(e[r'$error'], 'StateError');
      expect(e['message'], 'Bad state: bad');
    });

    test('9: toJson is called and its result encoded', () {
      expect(
        StackedJson.encode(_WithToJson(_Mode.dark)),
        {'v': 'dark'},
      );
    });

    test('10: anything else is unsupported', () {
      expect(
        StackedJson.encode(_Plain()),
        {r'$unsupported': '_Plain', 'text': 'plain!'},
      );
    });

    test('max depth cutoff', () {
      Object? nested = 'leaf';
      for (var i = 0; i < 12; i++) {
        nested = [nested];
      }
      var encoded = StackedJson.encode(nested);
      for (var i = 0; i < 8; i++) {
        encoded = (encoded as List).single;
      }
      expect(encoded, '<max depth>');

      expect(StackedJson.encode([1], maxDepth: 0), '<max depth>');
      expect(StackedJson.encode([1], maxDepth: 1), [1]);
      expect(StackedJson.encode(1, maxDepth: 0), 1);
    });

    test('nested map/list of DateTime and enum values', () {
      final d = DateTime.utc(2020);
      final encoded = StackedJson.encode({
        'when': [d, d],
        'modes': {
          'a': _Mode.light,
          'b': [_Mode.dark]
        },
      });
      expect(
        jsonEncode(encoded),
        '{"when":["${d.toIso8601String()}","${d.toIso8601String()}"],'
        '"modes":{"a":"light","b":["dark"]}}',
      );
    });
  });

  group('StackedJson.read', () {
    test('encodes the getter result', () {
      expect(StackedJson.read(() => _Mode.dark), 'dark');
    });

    test('returns {"\$threw": ...} when the getter throws', () {
      final result = StackedJson.read(() => throw StateError('nope'));
      expect(result, {r'$threw': 'Bad state: nope'});
    });
  });
}
