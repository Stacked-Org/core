import 'dart:async';

import 'action_param.dart';

/// Invokes an action. [input] is already normalized (see ActionInput.normalize).
typedef ActionInvoker = FutureOr<void> Function(Map<String, Object?> input);

/// One action an agent can invoke on a ViewModel (or a lent action).
class ActionSpec {
  const ActionSpec({
    required this.name,
    this.params = const [],
    this.invoke,
    this.unsupported,
    this.from,
  });

  final String name;
  final List<ActionParam> params;

  /// Null when [unsupported] is set.
  final ActionInvoker? invoke;

  /// Why this action can't be invoked, or null.
  final String? unsupported;

  /// For lent actions: the provider id ('navigator', 'dialog', 'sheet', 'snackbar').
  final String? from;

  bool get isInvokable => invoke != null && unsupported == null;

  ActionSpec copyWith({String? name, String? from}) => ActionSpec(
        name: name ?? this.name,
        params: params,
        invoke: invoke,
        unsupported: unsupported,
        from: from ?? this.from,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        if (params.isNotEmpty) 'params': params.map((p) => p.toJson()).toList(),
        if (unsupported != null) 'unsupported': unsupported,
        if (from != null) 'from': from,
      };

  /// Human/agent readable one-liner, for example:
  ///   'incrementCounter()'
  ///   'login(email: string, remember?: bool)'
  ///   'setMode(mode: enum[light|dark])'
  ///   'pickFile(...) [unsupported: <reason>]'
  ///   'goBack() from navigator'
  String get signature {
    final buffer = StringBuffer(name);
    if (unsupported != null) {
      buffer.write('(...) [unsupported: $unsupported]');
    } else {
      final rendered = params.map((p) {
        final label = p.required ? p.name : '${p.name}?';
        final type = p.type == 'enum' && p.enumValues != null
            ? 'enum[${p.enumValues!.join('|')}]'
            : p.type;
        return '$label: $type';
      }).join(', ');
      buffer.write('($rendered)');
    }
    if (from != null) buffer.write(' from $from');
    return buffer.toString();
  }
}
