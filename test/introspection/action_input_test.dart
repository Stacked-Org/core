import 'package:stacked_shared/stacked_introspection.dart';
import 'package:test/test.dart';

enum _Mode { light, dark }

ActionParam _p(String name) => ActionParam(name: name, type: 'string');

String _msg(void Function() f) {
  try {
    f();
  } on ActionInputException catch (e) {
    return e.message;
  }
  fail('expected ActionInputException');
}

void main() {
  group('normalize', () {
    test('null -> {}', () {
      expect(ActionInput.normalize(null, [_p('a')]), isEmpty);
    });

    test('no params -> {} even when raw is given', () {
      expect(ActionInput.normalize({'a': 1}, const []), isEmpty);
      expect(ActionInput.normalize(5, const []), isEmpty);
    });

    test('one param with a bare value', () {
      expect(ActionInput.normalize('x', [_p('a')]), {'a': 'x'});
      expect(ActionInput.normalize(3, [_p('a')]), {'a': 3});
    });

    test('one param with an object containing the key', () {
      expect(
          ActionInput.normalize({'a': 1, 'b': 2}, [_p('a')]), {'a': 1, 'b': 2});
    });

    test('one param with an object missing the key wraps it', () {
      expect(ActionInput.normalize({'z': 1}, [_p('a')]), {
        'a': {'z': 1},
      });
    });

    test('several params with an object', () {
      expect(ActionInput.normalize({'a': 1, 'b': 2}, [_p('a'), _p('b')]), {
        'a': 1,
        'b': 2,
      });
    });

    test('several params with a bare value throws', () {
      expect(
        () => ActionInput.normalize('x', [_p('email'), _p('password')]),
        throwsA(
          isA<ActionInputException>()
              .having((e) => e.param, 'param', '*')
              .having(
                (e) => e.message,
                'message',
                'Input for "*" must be a JSON object with keys email, password, got "x".',
              ),
        ),
      );
    });

    test('Map<dynamic, dynamic> with String keys counts as an object', () {
      final raw = <dynamic, dynamic>{'a': 1, 'b': 2};
      final result = ActionInput.normalize(raw, [_p('a'), _p('b')]);
      expect(result, {'a': 1, 'b': 2});
      expect(result, isA<Map<String, Object?>>());

      expect(ActionInput.normalize(<dynamic, dynamic>{'a': 5}, [_p('a')]),
          {'a': 5});
    });

    test('Map with non-String keys is not an object', () {
      expect(
        () => ActionInput.normalize({1: 2}, [_p('a'), _p('b')]),
        throwsA(isA<ActionInputException>()),
      );
    });
  });

  group('ActionInputException.message', () {
    test('with a value', () {
      expect(
        const ActionInputException('age', 'int', 'abc').message,
        'Input for "age" must be int, got "abc".',
      );
      expect(
        const ActionInputException('p', 'map', [1, 2]).toString(),
        'Input for "p" must be map, got [1,2].',
      );
    });

    test('without a value', () {
      expect(
        const ActionInputException('age', 'int', null).message,
        'Input for "age" must be int, got nothing.',
      );
    });
  });

  group('readers', () {
    test('string', () {
      expect(ActionInput.string({'a': 'x'}, 'a'), 'x');
      expect(_msg(() => ActionInput.string({}, 'a')),
          'Input for "a" must be string, got nothing.');
      expect(_msg(() => ActionInput.string({'a': 1}, 'a')),
          'Input for "a" must be string, got 1.');
      expect(ActionInput.stringOrNull({}, 'a'), isNull);
      expect(ActionInput.stringOrNull({'a': null}, 'a'), isNull);
      expect(ActionInput.stringOrNull({'a': 'x'}, 'a'), 'x');
      expect(() => ActionInput.stringOrNull({'a': 1}, 'a'),
          throwsA(isA<ActionInputException>()));
    });

    test('integer', () {
      expect(ActionInput.integer({'a': 3}, 'a'), 3);
      expect(ActionInput.integer({'a': 3.0}, 'a'), 3);
      expect(ActionInput.integer({'a': '42'}, 'a'), 42);
      expect(_msg(() => ActionInput.integer({'a': 3.5}, 'a')),
          'Input for "a" must be int, got 3.5.');
      expect(_msg(() => ActionInput.integer({'a': 'x'}, 'a')),
          'Input for "a" must be int, got "x".');
      expect(_msg(() => ActionInput.integer({}, 'a')),
          'Input for "a" must be int, got nothing.');
      expect(ActionInput.integerOrNull({}, 'a'), isNull);
      expect(ActionInput.integerOrNull({'a': '7'}, 'a'), 7);
      expect(() => ActionInput.integerOrNull({'a': true}, 'a'),
          throwsA(isA<ActionInputException>()));
    });

    test('decimal', () {
      expect(ActionInput.decimal({'a': 1}, 'a'), 1.0);
      expect(ActionInput.decimal({'a': 1.5}, 'a'), 1.5);
      expect(ActionInput.decimal({'a': '2.5'}, 'a'), 2.5);
      expect(_msg(() => ActionInput.decimal({'a': 'x'}, 'a')),
          'Input for "a" must be double, got "x".');
      expect(_msg(() => ActionInput.decimal({}, 'a')),
          'Input for "a" must be double, got nothing.');
      expect(ActionInput.decimalOrNull({}, 'a'), isNull);
      expect(ActionInput.decimalOrNull({'a': '1'}, 'a'), 1.0);
      expect(() => ActionInput.decimalOrNull({'a': []}, 'a'),
          throwsA(isA<ActionInputException>()));
    });

    test('number', () {
      expect(ActionInput.number({'a': 1}, 'a'), 1);
      expect(ActionInput.number({'a': 1.5}, 'a'), 1.5);
      expect(ActionInput.number({'a': '2'}, 'a'), 2);
      expect(ActionInput.number({'a': '2.5'}, 'a'), 2.5);
      expect(_msg(() => ActionInput.number({'a': 'x'}, 'a')),
          'Input for "a" must be num, got "x".');
      expect(ActionInput.numberOrNull({}, 'a'), isNull);
      expect(() => ActionInput.numberOrNull({'a': true}, 'a'),
          throwsA(isA<ActionInputException>()));
    });

    test('boolean', () {
      expect(ActionInput.boolean({'a': true}, 'a'), true);
      expect(ActionInput.boolean({'a': 'false'}, 'a'), false);
      expect(ActionInput.boolean({'a': 'true'}, 'a'), true);
      expect(_msg(() => ActionInput.boolean({'a': 'yes'}, 'a')),
          'Input for "a" must be bool, got "yes".');
      expect(_msg(() => ActionInput.boolean({'a': 1}, 'a')),
          'Input for "a" must be bool, got 1.');
      expect(_msg(() => ActionInput.boolean({}, 'a')),
          'Input for "a" must be bool, got nothing.');
      expect(ActionInput.booleanOrNull({}, 'a'), isNull);
      expect(ActionInput.booleanOrNull({'a': false}, 'a'), false);
      expect(() => ActionInput.booleanOrNull({'a': 'x'}, 'a'),
          throwsA(isA<ActionInputException>()));
    });

    test('dateTime', () {
      final d = DateTime.utc(2024, 5, 6, 7);
      expect(ActionInput.dateTime({'a': d.toIso8601String()}, 'a'), d);
      expect(ActionInput.dateTime({'a': d.millisecondsSinceEpoch}, 'a'),
          DateTime.fromMillisecondsSinceEpoch(d.millisecondsSinceEpoch));
      expect(_msg(() => ActionInput.dateTime({'a': 'nope'}, 'a')),
          'Input for "a" must be datetime, got "nope".');
      expect(_msg(() => ActionInput.dateTime({}, 'a')),
          'Input for "a" must be datetime, got nothing.');
      expect(ActionInput.dateTimeOrNull({}, 'a'), isNull);
      expect(() => ActionInput.dateTimeOrNull({'a': true}, 'a'),
          throwsA(isA<ActionInputException>()));
    });

    test('enumValue', () {
      expect(
          ActionInput.enumValue({'a': 'dark'}, 'a', _Mode.values), _Mode.dark);
      expect(_msg(() => ActionInput.enumValue({'a': 'x'}, 'a', _Mode.values)),
          'Input for "a" must be one of light|dark, got "x".');
      expect(_msg(() => ActionInput.enumValue({}, 'a', _Mode.values)),
          'Input for "a" must be one of light|dark, got nothing.');
      expect(_msg(() => ActionInput.enumValue({'a': 1}, 'a', _Mode.values)),
          'Input for "a" must be one of light|dark, got 1.');
      expect(ActionInput.enumValueOrNull({}, 'a', _Mode.values), isNull);
      expect(ActionInput.enumValueOrNull({'a': 'light'}, 'a', _Mode.values),
          _Mode.light);
      expect(() => ActionInput.enumValueOrNull({'a': 'x'}, 'a', _Mode.values),
          throwsA(isA<ActionInputException>()));
    });

    test('list', () {
      expect(
        ActionInput.list({
          'a': [1, 2]
        }, 'a', (i) => (i as int) * 2),
        [2, 4],
      );
      expect(_msg(() => ActionInput.list({'a': 'x'}, 'a', (i) => i)),
          'Input for "a" must be list, got "x".');
      expect(_msg(() => ActionInput.list({}, 'a', (i) => i)),
          'Input for "a" must be list, got nothing.');
      expect(ActionInput.listOrNull({}, 'a', (i) => i), isNull);
      expect(
          ActionInput.listOrNull({
            'a': ['x']
          }, 'a', (i) => i as String),
          ['x']);
      expect(() => ActionInput.listOrNull({'a': 1}, 'a', (i) => i),
          throwsA(isA<ActionInputException>()));
    });

    test('list: a failing converter becomes an ActionInputException', () {
      expect(
        () => ActionInput.list({
          'a': [1, 'x']
        }, 'a', (i) => i as int),
        throwsA(isA<ActionInputException>()),
      );
      expect(
        () => ActionInput.list({
          'a': [1]
        }, 'a', (i) => throw const ActionInputException('a[0]', 'int', 1)),
        throwsA(isA<ActionInputException>()
            .having((e) => e.param, 'param', 'a[0]')),
      );
    });

    test('map', () {
      expect(
          ActionInput.map({
            'a': {'k': 1}
          }, 'a'),
          {'k': 1});
      expect(
          ActionInput.map({
            'a': <dynamic, dynamic>{'k': 1}
          }, 'a'),
          {'k': 1});
      expect(
          _msg(() => ActionInput.map({
                'a': [1]
              }, 'a')),
          'Input for "a" must be map, got [1].');
      expect(
          _msg(() => ActionInput.map({
                'a': {1: 2}
              }, 'a')),
          'Input for "a" must be map, got {"1":2}.');
      expect(_msg(() => ActionInput.map({}, 'a')),
          'Input for "a" must be map, got nothing.');
      expect(ActionInput.mapOrNull({}, 'a'), isNull);
      expect(
          ActionInput.mapOrNull({
            'a': {'k': 1}
          }, 'a'),
          {'k': 1});
      expect(() => ActionInput.mapOrNull({'a': 1}, 'a'),
          throwsA(isA<ActionInputException>()));
    });

    test('any', () {
      expect(ActionInput.any({'a': 1}, 'a'), 1);
      expect(ActionInput.any({}, 'a'), isNull);
    });
  });
}
