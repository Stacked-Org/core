import 'package:stacked_shared/stacked_shared.dart';

/// Replaces the registration of [T] in the locator with [instance].
class Fixture<T extends Object> {
  const Fixture(this.instance);

  final T instance;

  Type get type => T;

  void apply(StackedLocator locator) {
    if (locator.isRegistered<T>()) locator.unregister<T>();
    locator.registerSingleton<T>(instance);
  }
}

Fixture<T> fixture<T extends Object>(T instance) => Fixture<T>(instance);

/// A named group of fixtures.
class FixtureSet {
  const FixtureSet(this.fixtures, {this.name});

  static const none = FixtureSet([], name: 'none');

  final List<Fixture> fixtures;
  final String? name;

  /// Keeps this set's fixtures whose type isn't in [other], then all of
  /// [other]'s. The name is '<a>+<b>'.
  FixtureSet merge(FixtureSet other) {
    final overridden = {for (final f in other.fixtures) f.type};
    return FixtureSet(
      [
        for (final f in fixtures)
          if (!overridden.contains(f.type)) f,
        ...other.fixtures,
      ],
      name: '${name ?? 'unnamed'}+${other.name ?? 'unnamed'}',
    );
  }

  void apply(StackedLocator locator) {
    for (final f in fixtures) {
      f.apply(locator);
    }
  }
}
