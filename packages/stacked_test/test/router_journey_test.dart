import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_shared/stacked_introspection.dart';
import 'package:stacked_shared/stacked_shared.dart';
import 'package:stacked_test/stacked_test.dart';

/// A router v2 app. The router is a global, like the generated one.
class _AppRouter extends RootStackRouter {
  @override
  final Map<String, PageFactory> pagesMap = {
    'Start': (data) => CustomPage<dynamic>(
          routeData: data,
          child: const _Screen(label: 'start'),
        ),
    'Detail': (data) => CustomPage<dynamic>(
          routeData: data,
          child: const _Screen(label: 'detail'),
        ),
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig('Start', path: '/'),
        RouteConfig('Detail', path: '/detail'),
      ];
}

final _router = _AppRouter();

class _Screen extends StatelessWidget {
  const _Screen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(label);
}

class _ScreenModel extends BaseViewModel {}

void _setupUi() {
  StackedIntrospector.instance.registerAll([
    IntrospectionEntry<_ScreenModel>(
      kind: NodeKind.route,
      describe: (vm) => StackedNode(name: 'ScreenModel', kind: NodeKind.route),
    ),
  ]);
}

final _config = JourneyConfig(
  setupLocator: () {},
  setupUi: _setupUi,
  app: () => MaterialApp.router(
    routerDelegate: _router.delegate(),
    routeInformationParser: _router.defaultRouteParser(),
  ),
  loadFonts: false,
);

List<String?> _stack() => _router.stack.map((p) => p.routeData.name).toList();

void main() {
  stackedJourney(
    'first boot starts on the initial route, then leaves the router on Detail',
    () async {
      expect(_stack(), ['Start']);
      unawaited(_router.push(const PageRouteInfo('Detail', path: '/detail')));
      await TestWidgetsFlutterBinding.instance.pump();
      expect(_stack(), ['Start', 'Detail']);
    },
    config: _config,
  );

  stackedJourney(
    'the next journey boots a router that was reset, not left on Detail',
    () async {
      expect(_stack(), ['Start']);
    },
    config: _config,
  );
}
