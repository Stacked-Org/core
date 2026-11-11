import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stacked_shared/stacked_shared.dart';
import 'package:stacked_test/stacked_test.dart';
import 'package:stacked_test/src/network_guard.dart' show kTransparentPng;

import 'support/counter_app.dart';

Future<TestFailure> _failureOf(Future<void> Function() run) async {
  try {
    await run();
  } on TestFailure catch (e) {
    return e;
  }
  fail('Expected a TestFailure, but nothing failed.');
}

void main() {
  stackedJourney(
    'precondition finds the screen and act changes state',
    () async {
      final node = await precondition('CounterViewModel');
      expect(node.kind, NodeKind.route);
      await act('increment');
      expectState({'count': 1});
    },
    config: counterConfig,
  );

  stackedJourney(
    'a delayed action finishes in fake time',
    () async {
      final watch = Stopwatch()..start();
      await precondition('CounterViewModel');
      await act('incrementLater', until: (n) => n.state['count'] == 1);
      expect(watch.elapsedMilliseconds, lessThan(1500));
      expectState({'count': 1, 'isBusy': false});
    },
    config: counterConfig,
  );

  stackedJourney(
    'without until, act settles once the ViewModel is no longer busy',
    () async {
      await precondition('CounterViewModel');
      await act('incrementLater');
      expectState({'count': 1, 'isBusy': false});
    },
    config: counterConfig,
  );

  stackedJourney(
    'act passes input to the action',
    () async {
      await act('add', input: 5);
      expectState({'count': 5});
      await act('add', input: {'amount': 2});
      expectState({'count': 7});
    },
    config: counterConfig,
  );

  stackedJourney(
    'an unknown action fails with the available actions',
    () async {
      await precondition('CounterViewModel');
      final failure = await _failureOf(() => act('nope'));
      expect(failure.message, contains('✗ No action "nope"'));
      expect(failure.message, contains('Available: increment'));
      expect(
          failure.message, contains('node:      CounterViewModel (route, /)'));
      expect(failure.message, contains('step:      1'));
    },
    config: counterConfig,
  );

  stackedJourney(
    'invalid input fails with the input message',
    () async {
      final failure = await _failureOf(() => act('add', input: 'many'));
      expect(failure.message, contains('✗ Input for "amount" must be int'));
    },
    config: counterConfig,
  );

  stackedJourney(
    'precondition times out in fake time with the current node',
    () async {
      final failure = await _failureOf(
        () => precondition('Nowhere', timeout: const Duration(seconds: 1)),
      );
      expect(
        failure.message,
        contains(
          '✗ Timed out after 1000 ms of fake time waiting for screen Nowhere.',
        ),
      );
      expect(failure.message, contains('CounterViewModel'));
    },
    config: counterConfig,
  );

  stackedJourney(
    'navigating focuses the pushed screen',
    () async {
      await act('openDetail');
      final node = await precondition('DetailViewModel');
      expect(node.state['title'], 'Detail');
      expect(node.lent.map((a) => a.name), contains('goBack'));
      await act('goBack');
      await precondition('CounterViewModel');
    },
    config: counterConfig,
  );

  stackedJourney(
    'fixtures replace locator registrations',
    () async {
      expectState({'greeting': 'Hello from the fake greeter'});
    },
    config: counterConfig,
    fixtures: FixtureSet([fixture<Greeter>(FakeGreeter())], name: 'fakes'),
  );

  stackedJourney(
    'expectState mismatch lists key, expected and actual',
    () async {
      await act('increment');
      final failure = await _failureOf(
        () async => expectState({'count': 3, 'missing': true}),
      );
      expect(failure.message, contains('✗ State did not match:'));
      expect(failure.message, contains('count: expected 3, got 1'));
      expect(failure.message, contains('missing: expected true, got nothing'));
      expect(failure.message, contains('fixtures:  none'));
    },
    config: counterConfig,
  );

  stackedJourney(
    'expectOverlay fails when no overlay is open',
    () async {
      final failure = await _failureOf(
        () async => expectOverlay({'type': 'dialog'}),
      );
      expect(
        failure.message,
        contains('✗ Expected an overlay, but none is open.'),
      );
    },
    config: counterConfig,
  );

  stackedJourney(
    'exploreSteps prints boot, steps and done',
    () async {
      final lines = <String>[];
      await runZoned(
        () => exploreSteps([
          ExploreStep.wait('CounterViewModel'),
          ExploreStep.act('increment'),
        ]),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => lines.add(line),
        ),
      );
      expect(lines, hasLength(4));
      expect(lines.every((l) => l.startsWith('STACKED_EXPLORE ')), isTrue);
      final parsed = [
        for (final l in lines)
          jsonDecode(l.substring('STACKED_EXPLORE '.length))
              as Map<String, dynamic>,
      ];
      expect(parsed[0]['op'], 'boot');
      expect(parsed[1]['op'], 'wait');
      expect(parsed[2]['op'], 'act');
      expect(parsed[2]['input'], isNull);
      expect(parsed[2]['node']['state']['count'], 1);
      expect(parsed.last, {
        'done': true,
        'ok': true,
        'steps': 2,
        'networkBlocked': <Object?>[],
      });
    },
    config: counterConfig,
  );

  stackedJourney(
    'exploreSteps stops at the first failing step',
    () async {
      final lines = <String>[];
      final failure = await _failureOf(
        () => runZoned(
          () => exploreSteps([
            ExploreStep.act('nope'),
            ExploreStep.act('increment'),
          ]),
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => lines.add(line),
          ),
        ),
      );
      expect(failure.message,
          'stacked explore failed; see STACKED_EXPLORE output.');
      expect(lines, hasLength(3));
      final step = jsonDecode(lines[1].substring('STACKED_EXPLORE '.length))
          as Map<String, dynamic>;
      expect(step['ok'], false);
      expect(step['error']['code'], 'unknown_action');
      expect(
        step['error']['message'],
        startsWith(
            'No action "nope" on CounterViewModel. Available: increment'),
      );
      expect(step['error']['available'], contains('increment'));
      final done = jsonDecode(lines[2].substring('STACKED_EXPLORE '.length))
          as Map<String, dynamic>;
      expect(done['ok'], false);
      expect(done['steps'], 1);
    },
    config: counterConfig,
  );

  stackedJourney(
    'exploreSteps reports blocked network calls and fails',
    () async {
      final lines = <String>[];
      final failure = await _failureOf(
        () => runZoned(
          () => exploreSteps([ExploreStep.act('fetch')]),
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => lines.add(line),
          ),
        ),
      );
      expect(failure.message, contains('stacked explore failed'));
      final done = jsonDecode(lines.last.substring('STACKED_EXPLORE '.length))
          as Map<String, dynamic>;
      expect(done['ok'], false);
      expect(done['networkBlocked'], [
        {'method': 'GET', 'url': 'https://example.com/x'},
      ]);
    },
    config: counterConfig,
  );

  stackedJourney(
    'loads fonts when loadFonts is true',
    () async {
      await precondition('CounterViewModel');
      await act('increment');
      expectState({'count': 1});
    },
    config: JourneyConfig(
      setupLocator: setupLocator,
      setupUi: setupUi,
      app: counterConfig.app,
    ),
  );

  test('the guard blocks requests and records them', () async {
    final guard = StackedNetworkGuard();
    final client = guard.createHttpClient(null);
    await expectLater(
      client.getUrl(Uri.parse('https://example.com/x')),
      throwsA(isA<NetworkBlockedException>()),
    );
    expect(guard.blocked, hasLength(1));
    expect(guard.blocked.single.toJson(), {
      'method': 'GET',
      'url': 'https://example.com/x',
    });
    try {
      await client.postUrl(Uri.parse('https://example.com/y'));
    } on NetworkBlockedException catch (e) {
      expect(
        e.message,
        'Network request blocked during a journey: POST https://example.com/y. '
        'Add a fixture for the service that makes this call.',
      );
    }
    expect(guard.blocked, hasLength(2));
  });

  test('the guard answers image requests with a transparent png', () async {
    final guard = StackedNetworkGuard();
    final client = guard.createHttpClient(null);
    client.autoUncompress = false;
    final request = await client.getUrl(Uri.parse('https://x/a.PNG'));
    final response = await request.close();
    expect(response.statusCode, 200);
    final bytes = await response.expand((chunk) => chunk).toList();
    expect(bytes, kTransparentPng);
    expect(guard.blocked, isEmpty);
  });

  test('the guard blocks images when allowImages is false', () async {
    final guard = StackedNetworkGuard(allowImages: false);
    await expectLater(
      guard.createHttpClient(null).getUrl(Uri.parse('https://x/a.png')),
      throwsA(isA<IOException>()),
    );
    expect(guard.blocked, hasLength(1));
  });

  test('journey functions fail outside a journey', () {
    expect(currentNode, throwsStateError);
    expect(
      () => expectState({}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'No journey is running. Call this inside a journey body.',
        ),
      ),
    );
  });

  test('FixtureSet.merge lets the other set win and joins the names', () {
    final a = FixtureSet([
      fixture<Greeter>(Greeter()),
      fixture<String>('a'),
    ], name: 'a');
    final b = FixtureSet([fixture<Greeter>(FakeGreeter())], name: 'b');
    final merged = a.merge(b);
    expect(merged.name, 'a+b');
    expect(merged.fixtures.map((f) => f.type), [String, Greeter]);
    expect(merged.fixtures.last.instance, isA<FakeGreeter>());
    expect(const FixtureSet([]).merge(b).name, 'unnamed+b');
  });

  test('Fixture.apply replaces an existing registration', () async {
    final locator = StackedLocator.asNewInstance();
    locator.registerSingleton<Greeter>(Greeter());
    fixture<Greeter>(FakeGreeter()).apply(locator);
    expect(locator.get<Greeter>(), isA<FakeGreeter>());
    fixture<String>('x').apply(locator);
    expect(locator.get<String>(), 'x');
  });
}
