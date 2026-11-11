import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_shared/stacked_introspection.dart';
import 'package:stacked_shared/stacked_shared.dart' show StackedLocator;

import 'failure_format.dart';
import 'fixtures.dart';
import 'fonts.dart';
import 'journey_config.dart';
import 'network_guard.dart';

/// A step failed. [code] is a [StackedErrorCode] value.
///
/// Internal: public functions turn this into a test failure, explore turns it
/// into an error line.
class JourneyStepException implements Exception {
  JourneyStepException(
    this.code,
    this.message,
    this.node, {
    this.available = const [],
  });

  final String code;
  final String message;
  final StackedNode node;
  final List<String> available;

  @override
  String toString() => message;
}

/// The journey that is currently running. Internal.
class ActiveJourney {
  ActiveJourney(this.tester, this.config, this.fixtures, this.guard);

  final WidgetTester tester;
  final JourneyConfig config;
  final FixtureSet fixtures;
  final StackedNetworkGuard guard;
  int step = 0;
}

ActiveJourney? _current;

ActiveJourney _requireJourney() {
  final journey = _current;
  if (journey == null) {
    throw StateError('No journey is running. Call this inside a journey body.');
  }
  return journey;
}

/// The running journey, or a [StateError]. Internal, used by explore.
@internal
ActiveJourney requireJourney() => _requireJourney();

/// Runs [body] as a widget test that boots the whole app.
///
/// Boots the app with [config], applies [fixtures] over the locator, blocks the
/// network, and gives [body] the journey functions: [precondition], [act],
/// [waitFor], [expectState] and [expectOverlay].
@isTest
void stackedJourney(
  String description,
  Future<void> Function() body, {
  required JourneyConfig config,
  FixtureSet fixtures = FixtureSet.none,
  bool skip = false,
}) {
  testWidgets(description, (tester) async {
    tester.view.physicalSize = config.surfaceSize * config.devicePixelRatio;
    tester.view.devicePixelRatio = config.devicePixelRatio;
    addTearDown(tester.view.reset);
    if (config.loadFonts) await tester.runAsync(loadStackedFonts);

    final guard = StackedNetworkGuard(allowImages: config.allowImageRequests);
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = guard;
    debugNetworkImageHttpClientProvider = () => guard.createHttpClient(null);
    try {
      await StackedLocator.instance.reset();
      StackedIntrospector.instance.reset();
      LentActionProviders.reset();
      ViewModelRegistry.instance.reset();
      // The generated router is a global, so it keeps its stack between boots.
      RootStackRouter.resetAll();

      await config.setupLocator();
      fixtures.apply(StackedLocator.instance);
      await config.setupUi();

      await tester.pumpWidget(config.app());
      await tester.pump();

      final journey = ActiveJourney(tester, config, fixtures, guard);
      _current = journey;
      await body();
      failIfNetworkBlocked(journey);
    } finally {
      _current = null;
      debugNetworkImageHttpClientProvider = null;
      HttpOverrides.global = previousOverrides;
    }
  }, skip: skip);
}

/// Fails the test when the journey made network calls. Internal.
@internal
void failIfNetworkBlocked(ActiveJourney journey) {
  final blocked = journey.guard.blocked;
  if (blocked.isEmpty) return;
  final calls = blocked.map((b) => '${b.method} ${b.url}').join(', ');
  fail(
    formatJourneyFailure(
      title: 'The journey made network calls: $calls. '
          'Add fixtures for the services that make them.',
      node: StackedFocus.node(),
      journey: journey,
    ),
  );
}

/// Tracks when a node has stopped changing.
class _Settler {
  String? _last;
  int _same = 0;

  bool isSettled(StackedNode node, {required bool frameClean}) {
    final encoded = jsonEncode(node.toJson());
    if (!frameClean) {
      _same = 0;
      _last = encoded;
      return false;
    }
    if (encoded == _last) {
      _same++;
    } else {
      _same = 1;
      _last = encoded;
    }
    return _same >= 3 && node.state['isBusy'] != true;
  }
}

int _ms(Duration d) => d.inMilliseconds;

/// Invokes [action] on the focused screen and pumps fake time until the node
/// settles (or [until] holds). Throws [JourneyStepException]. Internal.
@internal
Future<StackedNode> stepAct(
  ActiveJourney j,
  String action,
  Object? input,
  bool Function(StackedNode node)? until,
  Duration? timeout,
) async {
  j.step++;

  Future<void> done;
  try {
    done = StackedFocus.invoke(action, input);
  } on ActionNotFound catch (e) {
    throw JourneyStepException(
      StackedErrorCode.unknownAction,
      e.message,
      StackedFocus.node(),
      available: e.available,
    );
  } on ActionUnsupported catch (e) {
    throw JourneyStepException(
      StackedErrorCode.unsupportedAction,
      e.message,
      StackedFocus.node(),
    );
  } on ActionInputException catch (e) {
    throw JourneyStepException(
      StackedErrorCode.invalidInput,
      e.message,
      StackedFocus.node(),
    );
  }

  // Never await [done] here: inside fake async it would hang.
  Object? error;
  done.then(
    (_) {},
    onError: (Object e, StackTrace s) {
      error = e;
    },
  );

  final limit = timeout ?? j.config.timeout;
  final settler = _Settler();
  var elapsed = Duration.zero;
  while (true) {
    await j.tester.pump(j.config.step);
    elapsed += j.config.step;

    final frameError = j.tester.takeException();
    if (frameError != null) {
      throw JourneyStepException(
        StackedErrorCode.actionThrew,
        'A frame threw after "$action": $frameError',
        StackedFocus.node(),
      );
    }
    final failed = error;
    if (failed is ActionInputException) {
      // Generated invokers read their parameters inside the invoker, so a bad
      // input surfaces here as an async error.
      throw JourneyStepException(
        StackedErrorCode.invalidInput,
        failed.message,
        StackedFocus.node(),
      );
    }
    if (failed != null) {
      throw JourneyStepException(
        StackedErrorCode.actionThrew,
        '"$action" threw: $failed',
        StackedFocus.node(),
      );
    }

    final node = StackedFocus.node();
    if (until != null) {
      if (until(node)) return node;
    } else if (settler.isSettled(node, frameClean: true)) {
      return node;
    }

    if (elapsed >= limit) {
      throw JourneyStepException(
        StackedErrorCode.timeout,
        until != null
            ? '"$action" did not reach its until condition within '
                '${_ms(limit)} ms of fake time.'
            : '"$action" did not settle within ${_ms(limit)} ms of fake time.',
        node,
      );
    }
  }
}

/// Pumps fake time until [condition] holds. Throws [JourneyStepException].
/// Internal.
@internal
Future<StackedNode> stepWaitFor(
  ActiveJourney j,
  bool Function(StackedNode node) condition,
  String description,
  Duration? timeout,
) async {
  var node = StackedFocus.node();
  if (condition(node)) return node;

  final limit = timeout ?? j.config.timeout;
  var elapsed = Duration.zero;
  while (true) {
    await j.tester.pump(j.config.step);
    elapsed += j.config.step;

    final frameError = j.tester.takeException();
    if (frameError != null) {
      throw JourneyStepException(
        StackedErrorCode.actionThrew,
        'A frame threw while waiting for $description: $frameError',
        StackedFocus.node(),
      );
    }

    node = StackedFocus.node();
    if (condition(node)) return node;

    if (elapsed >= limit) {
      throw JourneyStepException(
        StackedErrorCode.timeout,
        'Timed out after ${_ms(limit)} ms of fake time waiting for '
        '$description.',
        node,
      );
    }
  }
}

/// Pumps fake time until the node settles or [limit] passes. Never fails.
/// Internal, used by explore for the boot step.
@internal
Future<StackedNode> stepSettle(ActiveJourney j, Duration limit) async {
  final settler = _Settler();
  var elapsed = Duration.zero;
  var node = StackedFocus.node();
  while (elapsed < limit) {
    await j.tester.pump(j.config.step);
    elapsed += j.config.step;
    final frameClean = j.tester.takeException() == null;
    node = StackedFocus.node();
    if (settler.isSettled(node, frameClean: frameClean)) break;
  }
  return node;
}

Never _fail(JourneyStepException e, ActiveJourney j) => fail(
      formatJourneyFailure(title: e.message, node: e.node, journey: j),
    );

const bool _trace = bool.fromEnvironment('STACKED_TRACE');

void _printTrace(ActiveJourney j, Map<String, Object?> fields) {
  // ignore: avoid_print
  print('STACKED_TRACE ${jsonEncode({'step': j.step, ...fields})}');
}

/// Waits until the screen whose ViewModel is named [screenName] is focused.
Future<StackedNode> precondition(String screenName, {Duration? timeout}) async {
  final j = _requireJourney();
  try {
    final node = await stepWaitFor(
      j,
      (n) => n.name == screenName,
      'screen $screenName',
      timeout,
    );
    if (_trace) {
      _printTrace(
          j, {'op': 'precondition', 'screen': screenName, 'node': node});
    }
    return node;
  } on JourneyStepException catch (e) {
    _fail(e, j);
  }
}

/// Invokes [action] on the focused screen, then waits for the app to settle,
/// or until [until] holds.
Future<StackedNode> act(
  String action, {
  Object? input,
  bool Function(StackedNode node)? until,
  Duration? timeout,
}) async {
  final j = _requireJourney();
  try {
    final node = await stepAct(j, action, input, until, timeout);
    if (_trace) {
      _printTrace(j, {
        'op': 'act',
        'action': action,
        'input': StackedJson.encode(input),
        'node': node,
      });
    }
    return node;
  } on JourneyStepException catch (e) {
    _fail(e, j);
  }
}

/// Pumps fake time until [condition] holds on the focused node.
Future<StackedNode> waitFor(
  bool Function(StackedNode node) condition, {
  String? description,
  Duration? timeout,
}) async {
  final j = _requireJourney();
  try {
    return await stepWaitFor(
      j,
      condition,
      description ?? 'the condition',
      timeout,
    );
  } on JourneyStepException catch (e) {
    _fail(e, j);
  }
}

/// The focused node right now.
StackedNode currentNode() {
  _requireJourney();
  return StackedFocus.node();
}

/// Fails unless every entry of [expected] is in the focused node's state.
void expectState(Map<String, Object?> expected) {
  final j = _requireJourney();
  final node = StackedFocus.node();
  _expectSubset(j, node, node.state, expected, 'State');
}

/// Fails unless every entry of [expected] is in the open overlay.
void expectOverlay(Map<String, Object?> expected) {
  final j = _requireJourney();
  final node = StackedFocus.node();
  final overlay = node.overlay;
  if (overlay == null) {
    fail(
      formatJourneyFailure(
        title: 'Expected an overlay, but none is open.',
        node: node,
        journey: j,
      ),
    );
  }
  _expectSubset(j, node, overlay, expected, 'Overlay');
}

void _expectSubset(
  ActiveJourney j,
  StackedNode node,
  Map<String, Object?> actual,
  Map<String, Object?> expected,
  String what,
) {
  const equality = DeepCollectionEquality();
  final mismatches = <String>[];
  expected.forEach((key, value) {
    final want = StackedJson.encode(value);
    if (!actual.containsKey(key)) {
      mismatches.add('$key: expected ${jsonEncode(want)}, got nothing');
    } else if (!equality.equals(want, actual[key])) {
      mismatches.add(
        '$key: expected ${jsonEncode(want)}, got ${jsonEncode(actual[key])}',
      );
    }
  });
  if (mismatches.isEmpty) return;
  fail(
    formatJourneyFailure(
      title: '$what did not match: ${mismatches.join('; ')}',
      node: node,
      journey: j,
    ),
  );
}
