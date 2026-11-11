import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'journey.dart';

/// One step of an exploration.
sealed class ExploreStep {
  const ExploreStep._();

  const factory ExploreStep.wait(String screenName) = ExploreWait;
  const factory ExploreStep.act(String action, [Object? input]) = ExploreAct;
}

class ExploreWait extends ExploreStep {
  const ExploreWait(this.screenName) : super._();
  final String screenName;
}

class ExploreAct extends ExploreStep {
  const ExploreAct(this.action, [this.input]) : super._();
  final String action;
  final Object? input;
}

void _emit(Map<String, Object?> line) {
  // ignore: avoid_print
  print('STACKED_EXPLORE ${jsonEncode(line)}');
}

/// Runs [steps] and prints one `STACKED_EXPLORE <json>` line per step, then a
/// final `done` line. Stops at the first failing step.
Future<void> exploreSteps(List<ExploreStep> steps) async {
  final j = requireJourney();

  final boot = await stepSettle(j, const Duration(seconds: 10));
  _emit({'step': 0, 'op': 'boot', 'ok': true, 'node': boot.toJson()});

  var executed = 0;
  var allOk = true;
  for (var i = 1; i <= steps.length; i++) {
    final step = steps[i - 1];
    final head = switch (step) {
      ExploreWait(:final screenName) => <String, Object?>{
          'step': i,
          'op': 'wait',
          'screen': screenName,
        },
      ExploreAct(:final action, :final input) => <String, Object?>{
          'step': i,
          'op': 'act',
          'action': action,
          'input': input,
        },
    };
    executed++;
    try {
      final node = switch (step) {
        ExploreWait(:final screenName) => await stepWaitFor(
            j,
            (n) => n.name == screenName,
            'screen $screenName',
            null,
          ),
        ExploreAct(:final action, :final input) =>
          await stepAct(j, action, input, null, null),
      };
      _emit({...head, 'ok': true, 'node': node.toJson()});
    } on JourneyStepException catch (e) {
      allOk = false;
      _emit({
        ...head,
        'ok': false,
        'error': {
          'code': e.code,
          'message': e.message,
          if (e.available.isNotEmpty) 'available': e.available,
        },
        'node': e.node.toJson(),
      });
      break;
    }
  }

  final blocked = [for (final b in j.guard.blocked) b.toJson()];
  final ok = allOk && blocked.isEmpty;
  _emit({
    'done': true,
    'ok': ok,
    'steps': executed,
    'networkBlocked': blocked,
  });
  j.guard.blocked.clear();

  if (!ok) fail('stacked explore failed; see STACKED_EXPLORE output.');
}
