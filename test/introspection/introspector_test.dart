import 'package:stacked_shared/stacked_introspection.dart';
import 'package:test/test.dart';

class _A {}

class _B {}

class _C {}

void main() {
  final introspector = StackedIntrospector.instance;

  setUp(introspector.reset);
  tearDown(introspector.reset);

  test('register and describe', () {
    introspector.register(IntrospectionEntry<_A>(
      kind: NodeKind.route,
      describe: (vm) => const StackedNode(name: 'A', kind: NodeKind.route),
    ));
    final a = _A();
    expect(introspector.isRegistered(a), isTrue);
    expect(introspector.describe(a).name, 'A');
    expect(introspector.describe(a).warnings, isEmpty);
  });

  test('registerAll registers by entry type', () {
    introspector.registerAll([
      IntrospectionEntry<_A>(
        kind: NodeKind.route,
        describe: (_) => const StackedNode(name: 'A', kind: NodeKind.route),
      ),
      IntrospectionEntry<_B>(
        kind: NodeKind.dialog,
        describe: (_) => const StackedNode(name: 'B', kind: NodeKind.dialog),
      ),
    ]);
    expect(introspector.isRegistered(_A()), isTrue);
    expect(introspector.isRegistered(_B()), isTrue);
    expect(introspector.isRegistered(_C()), isFalse);
    expect(introspector.describe(_B()).name, 'B');
  });

  test('re-registering a type replaces the entry', () {
    introspector.register(IntrospectionEntry<_A>(
      kind: NodeKind.route,
      describe: (_) => const StackedNode(name: 'old', kind: NodeKind.route),
    ));
    introspector.register(IntrospectionEntry<_A>(
      kind: NodeKind.sheet,
      describe: (_) => const StackedNode(name: 'new', kind: NodeKind.sheet),
    ));
    expect(introspector.describe(_A()).name, 'new');
    expect(introspector.kindOf(_A()), NodeKind.sheet);
  });

  test('kindOf', () {
    introspector.register(IntrospectionEntry<_A>(
      kind: NodeKind.dialog,
      describe: (_) => const StackedNode(name: 'A', kind: NodeKind.dialog),
    ));
    expect(introspector.kindOf(_A()), NodeKind.dialog);
    expect(introspector.kindOf(_B()), isNull);
  });

  test('unregistered type gives a fallback node', () {
    final node = introspector.describe(_C());
    expect(node.name, '_C');
    expect(node.kind, NodeKind.widget);
    expect(node.warnings,
        ['No introspection generated for _C. Run build_runner.']);
    expect(node.actions, isEmpty);
  });

  test('a throwing describer gives a warning node', () {
    introspector.register(IntrospectionEntry<_A>(
      kind: NodeKind.route,
      describe: (_) => throw StateError('bad'),
    ));
    final node = introspector.describe(_A());
    expect(node.name, '_A');
    expect(node.kind, NodeKind.widget);
    expect(node.warnings, ['Describing _A threw: Bad state: bad']);
  });

  test('reset clears all entries', () {
    introspector.register(IntrospectionEntry<_A>(
      kind: NodeKind.route,
      describe: (_) => const StackedNode(name: 'A', kind: NodeKind.route),
    ));
    introspector.reset();
    expect(introspector.isRegistered(_A()), isFalse);
  });

  test('entry exposes its type and describeObject', () {
    final entry = IntrospectionEntry<_A>(
      kind: NodeKind.route,
      describe: (_) => const StackedNode(name: 'A', kind: NodeKind.route),
    );
    expect(entry.type, _A);
    expect(entry.describeObject(_A()).name, 'A');
  });
}
