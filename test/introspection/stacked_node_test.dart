import 'dart:convert';

import 'package:stacked_shared/stacked_introspection.dart';
import 'package:test/test.dart';

void main() {
  group('StackedNode.toJson', () {
    test('key order matches the contract', () {
      final node = StackedNode(
        name: 'HomeViewModel',
        kind: NodeKind.route,
        route: '/home-view',
        state: const {'counterLabel': 'Counter is: 1', 'isBusy': false},
        actions: [
          ActionSpec(name: 'incrementCounter', invoke: (_) {}),
          const ActionSpec(
            name: 'login',
            params: [
              ActionParam(name: 'email', type: 'string'),
              ActionParam(name: 'remember', type: 'bool', required: false),
            ],
          ),
          const ActionSpec(name: 'pickFile', unsupported: 'No File.'),
        ],
        children: const [
          StackedNode(name: 'PostCardModel', kind: NodeKind.widget),
        ],
        lent: const [ActionSpec(name: 'goBack', from: 'navigator')],
        overlay: const {'type': 'dialog', 'title': 'Hi'},
        warnings: const ['careful'],
      );

      expect(
        jsonEncode(node.toJson()),
        '{"name":"HomeViewModel","kind":"route","route":"/home-view",'
        '"state":{"counterLabel":"Counter is: 1","isBusy":false},'
        '"actions":[{"name":"incrementCounter"},'
        '{"name":"login","params":[{"name":"email","type":"string"},'
        '{"name":"remember","type":"bool","required":false}]},'
        '{"name":"pickFile","unsupported":"No File."}],'
        '"children":[{"name":"PostCardModel","kind":"widget","state":{},"actions":[]}],'
        '"lent":[{"name":"goBack","from":"navigator"}],'
        '"overlay":{"type":"dialog","title":"Hi"},'
        '"warnings":["careful"]}',
      );
    });

    test('omits empty optional keys', () {
      const node = StackedNode(name: 'A', kind: NodeKind.widget);
      expect(
        jsonEncode(node.toJson()),
        '{"name":"A","kind":"widget","state":{},"actions":[]}',
      );
    });

    test('enum params include enumValues', () {
      const p = ActionParam(
        name: 'mode',
        type: 'enum',
        enumValues: ['light', 'dark'],
      );
      expect(jsonEncode(p.toJson()),
          '{"name":"mode","type":"enum","enumValues":["light","dark"]}');
    });
  });

  group('StackedNode.copyWith', () {
    test('replaces only the given fields', () {
      const node = StackedNode(name: 'A', kind: NodeKind.route, route: '/a');
      final copy = node.copyWith(
        children: const [StackedNode(name: 'B', kind: NodeKind.widget)],
        warnings: const ['w'],
        overlay: const {'type': 'sheet'},
        lent: const [ActionSpec(name: 'x')],
      );
      expect(copy.name, 'A');
      expect(copy.kind, NodeKind.route);
      expect(copy.route, '/a');
      expect(copy.children.single.name, 'B');
      expect(copy.warnings, ['w']);
      expect(copy.overlay, {'type': 'sheet'});
      expect(copy.lent.single.name, 'x');
      expect(node.copyWith(route: '/b').route, '/b');
    });
  });

  group('availableActions', () {
    test('own, then Child.action, then lent', () {
      const node = StackedNode(
        name: 'Home',
        kind: NodeKind.route,
        actions: [ActionSpec(name: 'a'), ActionSpec(name: 'b')],
        children: [
          StackedNode(
            name: 'Card',
            kind: NodeKind.widget,
            actions: [ActionSpec(name: 'like')],
          ),
          StackedNode(
            name: 'Footer',
            kind: NodeKind.widget,
            actions: [ActionSpec(name: 'like'), ActionSpec(name: 'share')],
          ),
        ],
        lent: [ActionSpec(name: 'goBack', from: 'navigator')],
      );
      expect(node.availableActions, [
        'a',
        'b',
        'Card.like',
        'Footer.like',
        'Footer.share',
        'goBack',
      ]);
    });
  });

  group('ActionSpec', () {
    test('signature forms', () {
      expect(const ActionSpec(name: 'incrementCounter').signature,
          'incrementCounter()');
      expect(
        const ActionSpec(name: 'login', params: [
          ActionParam(name: 'email', type: 'string'),
          ActionParam(name: 'remember', type: 'bool', required: false),
        ]).signature,
        'login(email: string, remember?: bool)',
      );
      expect(
        const ActionSpec(name: 'setMode', params: [
          ActionParam(
              name: 'mode', type: 'enum', enumValues: ['light', 'dark']),
        ]).signature,
        'setMode(mode: enum[light|dark])',
      );
      expect(
        const ActionSpec(
          name: 'pickFile',
          params: [ActionParam(name: 'file', type: 'object')],
          unsupported: 'No File.',
        ).signature,
        'pickFile(...) [unsupported: No File.]',
      );
      expect(const ActionSpec(name: 'goBack', from: 'navigator').signature,
          'goBack() from navigator');
    });

    test('isInvokable', () {
      expect(ActionSpec(name: 'a', invoke: (_) {}).isInvokable, isTrue);
      expect(const ActionSpec(name: 'a').isInvokable, isFalse);
      expect(
        ActionSpec(name: 'a', invoke: (_) {}, unsupported: 'x').isInvokable,
        isFalse,
      );
    });

    test('copyWith', () {
      final spec = ActionSpec(
        name: 'a',
        params: const [ActionParam(name: 'p', type: 'int')],
        invoke: (_) {},
      );
      final copy = spec.copyWith(name: 'B.a', from: 'dialog');
      expect(copy.name, 'B.a');
      expect(copy.from, 'dialog');
      expect(copy.params, spec.params);
      expect(copy.invoke, same(spec.invoke));
      expect(spec.copyWith().name, 'a');
    });
  });
}
