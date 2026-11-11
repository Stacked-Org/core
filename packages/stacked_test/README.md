# stacked_test

Journey tests for Stacked apps. A journey drives the app by ViewModel action names, swaps services for fixtures, blocks the network, and prints failures an agent can act on, all under `flutter test` with no device.

## Install

```yaml
dev_dependencies:
  stacked_test: ^0.1.0-beta.1
```

It needs `stacked` 3.6.0-beta.1 or newer, and `stacked_generator` 2.1.0-beta.1 or newer to write `lib/stacked.introspection.dart`. Apps made with `stacked create app` already have the harness, fixtures and a sample journey. For an existing app, run `stacked skills --harness` and follow `.claude/skills/stacked/existing-app.md`.

## A journey

```dart
stackedJourney(
  'increments the counter',
  () async {
    await precondition('HomeViewModel');
    await act('incrementCounter');
    expectState({'counterLabel': 'Counter is: 1'});
  },
  config: JourneyConfig(
    setupLocator: setupLocator,
    setupUi: setupUi,
    app: () => const MainApp(),
  ),
  fixtures: FixtureSet([fixture<ApiService>(FakeApiService())], name: 'happy'),
);
```

Run journeys with `stacked test` (or `flutter test test/behavior`). Use `stacked explore` to see the focused screen's state and actions before writing one.
