import 'dart:convert';

import 'package:stacked_shared/stacked_introspection.dart';

import 'journey.dart';

/// Formats a journey failure so that an agent can act on it: what went wrong,
/// the screen it was on, and what could have been done there.
String formatJourneyFailure({
  required String title,
  required StackedNode node,
  required ActiveJourney journey,
}) {
  final kind =
      node.route != null ? '${node.kind.name}, ${node.route}' : node.kind.name;
  final buffer = StringBuffer('✗ $title\n');

  void line(String label, String value) {
    buffer.writeln('  ${'$label:'.padRight(10)} $value');
  }

  line('node', '${node.name} ($kind)');
  line('state', jsonEncode(node.state));
  line(
    'actions',
    node.actions.isEmpty
        ? '(none)'
        : node.actions.map((a) => a.signature).join(', '),
  );
  if (node.children.isNotEmpty) {
    line(
      'children',
      node.children.map((c) {
        final actions = c.actions.isEmpty
            ? '(none)'
            : c.actions.map((a) => a.signature).join(', ');
        return '${c.name}: $actions';
      }).join('; '),
    );
  }
  if (node.lent.isNotEmpty) {
    line('lent', node.lent.map((a) => a.signature).join(', '));
  }
  if (node.overlay != null) {
    line('overlay', jsonEncode(node.overlay));
  }
  if (node.warnings.isNotEmpty) {
    line('warnings', node.warnings.join('; '));
  }
  line(
    'fixtures',
    '${journey.fixtures.name ?? 'unnamed'} · network calls blocked: '
        '${journey.guard.blocked.length}',
  );
  buffer.write('  ${'step:'.padRight(10)} ${journey.step}');
  return buffer.toString();
}
