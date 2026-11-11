import 'package:stacked_shared/stacked_introspection.dart';
import 'package:test/test.dart';

ActionSpec _spec(String name, {String? from, String? unsupported}) =>
    ActionSpec(
      name: name,
      from: from,
      unsupported: unsupported,
      invoke: unsupported == null ? (_) {} : null,
    );

StackedNode _node({
  List<ActionSpec> actions = const [],
  List<StackedNode> children = const [],
  List<ActionSpec> lent = const [],
}) =>
    StackedNode(
      name: 'Home',
      kind: NodeKind.route,
      actions: actions,
      children: children,
      lent: lent,
    );

StackedNode _child(String name, List<ActionSpec> actions) =>
    StackedNode(name: name, kind: NodeKind.widget, actions: actions);

void main() {
  test('own action beats lent action with the same name', () {
    final own = _spec('dismiss');
    final lent = _spec('dismiss', from: 'dialog');
    final r =
        ActionResolver.resolve(_node(actions: [own], lent: [lent]), 'dismiss');
    expect(r.spec, same(own));
    expect(r.source, 'own');
  });

  test('qualified child action', () {
    final like = _spec('like');
    final r = ActionResolver.resolve(
      _node(children: [
        _child('Card', [like]),
        _child('Footer', [_spec('like')]),
      ]),
      'Card.like',
    );
    expect(r.spec, same(like));
    expect(r.source, 'child:Card');
  });

  test('unique unqualified child action', () {
    final share = _spec('share');
    final r = ActionResolver.resolve(
      _node(children: [
        _child('Card', [_spec('like')]),
        _child('Footer', [share]),
      ]),
      'share',
    );
    expect(r.spec, same(share));
    expect(r.source, 'child:Footer');
  });

  test('ambiguous unqualified child action', () {
    final node = _node(children: [
      _child('Card', [_spec('like')]),
      _child('Footer', [_spec('like')]),
    ]);
    expect(
      () => ActionResolver.resolve(node, 'like'),
      throwsA(
        isA<ActionNotFound>().having((e) => e.ambiguous, 'ambiguous',
            ['Card.like', 'Footer.like']).having(
          (e) => e.message,
          'message',
          'Action "like" is ambiguous on Home. Use one of: Card.like, Footer.like.',
        ),
      ),
    );
  });

  test('lent action', () {
    final back = _spec('goBack', from: 'navigator');
    final r = ActionResolver.resolve(_node(lent: [back]), 'goBack');
    expect(r.spec, same(back));
    expect(r.source, 'lent:navigator');
  });

  test('not found lists everything available', () {
    final node = _node(
      actions: [_spec('a')],
      children: [
        _child('Card', [_spec('like')]),
      ],
      lent: [_spec('goBack', from: 'navigator')],
    );
    expect(
      () => ActionResolver.resolve(node, 'nope'),
      throwsA(
        isA<ActionNotFound>()
            .having(
                (e) => e.available, 'available', ['a', 'Card.like', 'goBack'])
            .having((e) => e.ambiguous, 'ambiguous', isEmpty)
            .having(
              (e) => e.message,
              'message',
              'No action "nope" on Home. Available: a, Card.like, goBack.',
            ),
      ),
    );
  });

  test('not found with nothing available', () {
    expect(
      () => ActionResolver.resolve(_node(), 'x'),
      throwsA(isA<ActionNotFound>().having(
        (e) => e.toString(),
        'toString',
        'No action "x" on Home. Available: none.',
      )),
    );
  });

  test('unsupported action throws ActionUnsupported', () {
    final node = _node(actions: [_spec('pickFile', unsupported: 'No File.')]);
    expect(
      () => ActionResolver.resolve(node, 'pickFile'),
      throwsA(isA<ActionUnsupported>().having(
        (e) => e.message,
        'message',
        'Action "pickFile" on Home can\'t be invoked: No File.',
      )),
    );
  });

  test('a spec without an invoker and without a reason says no invoker', () {
    final node = _node(actions: [const ActionSpec(name: 'x')]);
    expect(
      () => ActionResolver.resolve(node, 'x'),
      throwsA(isA<ActionUnsupported>()
          .having((e) => e.reason, 'reason', 'no invoker')),
    );
  });
}
