import 'node_kind.dart';
import 'stacked_node.dart';

typedef NodeDescriber<T> = StackedNode Function(T viewModel);

/// Describes one ViewModel type. Generated code creates these.
class IntrospectionEntry<T extends Object> {
  const IntrospectionEntry({required this.kind, required this.describe});

  final NodeKind kind;
  final NodeDescriber<T> describe;

  Type get type => T;

  StackedNode describeObject(Object viewModel) => describe(viewModel as T);
}

/// Registry of generated describers, keyed by ViewModel type.
class StackedIntrospector {
  StackedIntrospector._();

  static final StackedIntrospector instance = StackedIntrospector._();

  final Map<Type, IntrospectionEntry> _entries = {};

  /// Keyed by entry.type. Re-registering a type replaces the old entry.
  void register<T extends Object>(IntrospectionEntry<T> entry) {
    _entries[entry.type] = entry;
  }

  void registerAll(List<IntrospectionEntry> entries) {
    for (final entry in entries) {
      _entries[entry.type] = entry;
    }
  }

  /// Looks up by viewModel.runtimeType.
  bool isRegistered(Object viewModel) =>
      _entries.containsKey(viewModel.runtimeType);

  NodeKind? kindOf(Object viewModel) => _entries[viewModel.runtimeType]?.kind;

  /// The generated node, or a fallback node with a warning when the type isn't
  /// registered or its describer throws.
  StackedNode describe(Object viewModel) {
    final type = viewModel.runtimeType;
    final entry = _entries[type];
    if (entry == null) {
      return _fallback(
        type,
        'No introspection generated for $type. Run build_runner.',
      );
    }
    try {
      return entry.describeObject(viewModel);
    } catch (error) {
      return _fallback(type, 'Describing $type threw: $error');
    }
  }

  void reset() => _entries.clear();

  StackedNode _fallback(Type type, String warning) => StackedNode(
        name: type.toString(),
        kind: NodeKind.widget,
        warnings: [warning],
      );
}
