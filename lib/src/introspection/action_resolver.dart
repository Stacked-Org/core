import 'action_spec.dart';
import 'stacked_node.dart';

class ActionNotFound implements Exception {
  const ActionNotFound(
    this.action,
    this.nodeName,
    this.available, {
    this.ambiguous = const [],
  });

  final String action;
  final String nodeName;
  final List<String> available;

  /// Non-empty when the name matched several children.
  final List<String> ambiguous;

  /// Not ambiguous: 'No action "{action}" on {nodeName}. Available: {available joined ", "}.'
  /// (available empty: '... Available: none.')
  /// Ambiguous: 'Action "{action}" is ambiguous on {nodeName}. Use one of: {ambiguous joined ", "}.'
  String get message {
    if (ambiguous.isNotEmpty) {
      return 'Action "$action" is ambiguous on $nodeName. '
          'Use one of: ${ambiguous.join(', ')}.';
    }
    final list = available.isEmpty ? 'none' : available.join(', ');
    return 'No action "$action" on $nodeName. Available: $list.';
  }

  @override
  String toString() => message;
}

class ActionUnsupported implements Exception {
  const ActionUnsupported(this.action, this.nodeName, this.reason);

  final String action;
  final String nodeName;
  final String reason;

  /// 'Action "{action}" on {nodeName} can't be invoked: {reason}'
  String get message =>
      'Action "$action" on $nodeName can\'t be invoked: $reason';

  @override
  String toString() => message;
}

class ResolvedAction {
  const ResolvedAction(this.spec, this.source);

  final ActionSpec spec;

  /// 'own', 'child:{ChildName}' or 'lent:{from}'.
  final String source;
}

abstract final class ActionResolver {
  /// Resolution order:
  ///  1. node.actions with exactly this name
  ///  2. 'Child.action': the first child whose name == Child, with that action
  ///  3. unqualified name matching child actions: exactly one match -> it;
  ///     several -> ActionNotFound(ambiguous: ['ChildA.x', 'ChildB.x'])
  ///  4. node.lent with this name (first match)
  /// No match -> throws ActionNotFound. A match that isn't invokable ->
  /// throws ActionUnsupported.
  static ResolvedAction resolve(StackedNode node, String action) {
    final resolved = _find(node, action);
    final spec = resolved.spec;
    if (!spec.isInvokable) {
      throw ActionUnsupported(
        action,
        node.name,
        spec.unsupported ?? 'no invoker',
      );
    }
    return resolved;
  }

  static ResolvedAction _find(StackedNode node, String action) {
    for (final a in node.actions) {
      if (a.name == action) return ResolvedAction(a, 'own');
    }

    for (final child in node.children) {
      for (final a in child.actions) {
        if ('${child.name}.${a.name}' == action) {
          return ResolvedAction(a, 'child:${child.name}');
        }
      }
    }

    final matches = <(String, ResolvedAction)>[];
    for (final child in node.children) {
      for (final a in child.actions) {
        if (a.name == action) {
          matches.add((
            '${child.name}.${a.name}',
            ResolvedAction(a, 'child:${child.name}')
          ));
        }
      }
    }
    if (matches.length == 1) return matches.single.$2;
    if (matches.length > 1) {
      throw ActionNotFound(
        action,
        node.name,
        node.availableActions,
        ambiguous: [for (final m in matches) m.$1],
      );
    }

    for (final a in node.lent) {
      if (a.name == action) return ResolvedAction(a, 'lent:${a.from ?? ''}');
    }

    throw ActionNotFound(action, node.name, node.availableActions);
  }
}
