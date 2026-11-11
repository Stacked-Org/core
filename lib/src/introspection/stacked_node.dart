import 'action_spec.dart';
import 'node_kind.dart';

/// Describes one ViewModel: its state, what can be done on it and what is
/// attached to it.
class StackedNode {
  const StackedNode({
    required this.name,
    required this.kind,
    this.route,
    this.state = const {},
    this.actions = const [],
    this.children = const [],
    this.lent = const [],
    this.overlay,
    this.warnings = const [],
  });

  final String name;
  final NodeKind kind;
  final String? route;

  /// Values are already JSON-safe (produced by StackedJson).
  final Map<String, Object?> state;
  final List<ActionSpec> actions;
  final List<StackedNode> children;
  final List<ActionSpec> lent;
  final Map<String, Object?>? overlay;
  final List<String> warnings;

  StackedNode copyWith({
    NodeKind? kind,
    String? route,
    List<StackedNode>? children,
    List<ActionSpec>? lent,
    Map<String, Object?>? overlay,
    List<String>? warnings,
  }) =>
      StackedNode(
        name: name,
        kind: kind ?? this.kind,
        route: route ?? this.route,
        state: state,
        actions: actions,
        children: children ?? this.children,
        lent: lent ?? this.lent,
        overlay: overlay ?? this.overlay,
        warnings: warnings ?? this.warnings,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'kind': kind.name,
        if (route != null) 'route': route,
        'state': state,
        'actions': actions.map((a) => a.toJson()).toList(),
        if (children.isNotEmpty)
          'children': children.map((c) => c.toJson()).toList(),
        if (lent.isNotEmpty) 'lent': lent.map((a) => a.toJson()).toList(),
        if (overlay != null && overlay!.isNotEmpty) 'overlay': overlay,
        if (warnings.isNotEmpty) 'warnings': warnings,
      };

  /// Every name ActionResolver accepts, in resolution order:
  /// own action names, then 'Child.action' for every child action, then lent names.
  List<String> get availableActions => [
        for (final a in actions) a.name,
        for (final c in children)
          for (final a in c.actions) '${c.name}.${a.name}',
        for (final a in lent) a.name,
      ];
}
