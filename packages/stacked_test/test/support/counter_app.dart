import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_shared/stacked_introspection.dart';
import 'package:stacked_shared/stacked_shared.dart';
import 'package:stacked_test/stacked_test.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class Greeter {
  String get greeting => 'Hello from the real greeter';
}

class FakeGreeter implements Greeter {
  @override
  String get greeting => 'Hello from the fake greeter';
}

class CounterViewModel extends BaseViewModel {
  int count = 0;

  String get greeting => StackedLocator.instance.get<Greeter>().greeting;

  void increment() {
    count++;
    notifyListeners();
  }

  Future<void> incrementLater() async {
    await runBusyFuture(Future<void>.delayed(const Duration(seconds: 2)));
    count++;
    notifyListeners();
  }

  void add(int amount) {
    count += amount;
    notifyListeners();
  }

  Future<void> fetch() async {
    try {
      final request =
          await HttpClient().getUrl(Uri.parse('https://example.com/x'));
      await request.close();
    } catch (_) {}
  }

  void openDetail() {
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const DetailView()),
    );
  }
}

class DetailViewModel extends BaseViewModel {
  String get title => 'Detail';
}

class CounterView extends StackedView<CounterViewModel> {
  const CounterView({super.key});

  @override
  Widget builder(BuildContext context, CounterViewModel viewModel, Widget? c) {
    return Scaffold(
      body: Column(
        children: [
          Text('Count ${viewModel.count}'),
          TextButton(
            onPressed: viewModel.increment,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }

  @override
  CounterViewModel viewModelBuilder(BuildContext context) => CounterViewModel();
}

class DetailView extends StackedView<DetailViewModel> {
  const DetailView({super.key});

  @override
  Widget builder(BuildContext context, DetailViewModel viewModel, Widget? c) {
    return Scaffold(body: Text(viewModel.title));
  }

  @override
  DetailViewModel viewModelBuilder(BuildContext context) => DetailViewModel();
}

void setupLocator() {
  StackedLocator.instance.registerSingleton<Greeter>(Greeter());
}

void setupUi() {
  StackedIntrospector.instance.registerAll([
    IntrospectionEntry<CounterViewModel>(
      kind: NodeKind.route,
      describe: (vm) => StackedNode(
        name: 'CounterViewModel',
        kind: NodeKind.route,
        state: {
          'count': StackedJson.read(() => vm.count),
          'greeting': StackedJson.read(() => vm.greeting),
          'isBusy': StackedJson.read(() => vm.isBusy),
        },
        actions: [
          ActionSpec(
            name: 'increment',
            invoke: (_) {
              vm.increment();
            },
          ),
          ActionSpec(
            name: 'incrementLater',
            invoke: (_) => vm.incrementLater(),
          ),
          ActionSpec(
            name: 'add',
            params: const [ActionParam(name: 'amount', type: 'int')],
            invoke: (i) {
              vm.add(ActionInput.integer(i, 'amount'));
            },
          ),
          ActionSpec(name: 'fetch', invoke: (_) => vm.fetch()),
          ActionSpec(name: 'openDetail', invoke: (_) => vm.openDetail()),
        ],
      ),
    ),
    IntrospectionEntry<DetailViewModel>(
      kind: NodeKind.route,
      describe: (vm) => StackedNode(
        name: 'DetailViewModel',
        kind: NodeKind.route,
        state: {'title': StackedJson.read(() => vm.title)},
      ),
    ),
  ]);
}

final counterConfig = JourneyConfig(
  setupLocator: setupLocator,
  setupUi: setupUi,
  app: () => MaterialApp(
    navigatorKey: navigatorKey,
    home: const CounterView(),
  ),
  loadFonts: false,
);
