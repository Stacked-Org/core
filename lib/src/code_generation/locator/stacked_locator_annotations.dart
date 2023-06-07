import 'dart:async';

/// The class to describe a service registration on the get_it locator

class Environment {
  const Environment._();

  /// preset of common env name 'dev'
  static const dev = 'dev';

  /// preset of common env name 'prod'
  static const prod = 'prod';

  /// preset of common env name 'test'
  static const test = 'test';
}

class DependencyRegistration {
  /// The type of the service to register
  final Type? classType;

  /// An abstracted class type of service to register
  final Type? asType;

  final Function? resolveUsing;
  final String? instanceName;

  final Set<String>? environments;
  final Function? dispose;
  final Type? param1;
  final Type? param2;

  const DependencyRegistration({
    this.instanceName,
    this.environments,
    this.classType,
    this.asType,
    this.resolveUsing,
    this.dispose,
    this.param1,
    this.param2,
  });
}

/// Registers the type passed in as a singleton instance in the get_it locator
class Singleton extends DependencyRegistration {
  const Singleton({
    Type? classType,
    Type? asType,
    Function? resolveUsing,
    Set<String>? environments,
    String? instanceName,
  }) : super(
          instanceName: instanceName,
          classType: classType,
          asType: asType,
          resolveUsing: resolveUsing,
          environments: environments,
        );
}

/// Registers the type passed in as a LazySingleton instance in the get_it locator
class LazySingleton<T> extends DependencyRegistration {
  const LazySingleton({
    Type? classType,
    Type? asType,
    Function? resolveUsing,
    Set<String>? environments,
    String? instanceName,
  }) : super(
          instanceName: instanceName,
          classType: classType,
          asType: asType,
          resolveUsing: resolveUsing,
          environments: environments,
        );
}

/// Registers the type passed in as a Factory in the get_it locator
class Factory extends DependencyRegistration {
  const Factory({
    Type? classType,
    Type? asType,
    Set<String>? environments,
    String? instanceName,
  }) : super(
          instanceName: instanceName,
          classType: classType,
          asType: asType,
          environments: environments,
        );
}

/// Registers the type passed in as a Factory in the get_it locator
class FactoryWithParam extends DependencyRegistration {
  const FactoryWithParam({
    Type? asType,
    Type? classType,
    Set<String>? environments,
    String? instanceName,
  }) : super(
          instanceName: instanceName,
          asType: asType,
          classType: classType,
          environments: environments,
        );
}

/// Marks a constructor param as
/// factoryParam so it can be passed
/// to the resolver function
class FactoryParam {
  const FactoryParam._();
}

/// const instance of [FactoryParam]
/// with default arguments
const factoryParam = FactoryParam._();

/// Registers the type passed in to be presolved using the function passed in
@Deprecated('Use InitializableSingleton instead.')
class Presolve extends DependencyRegistration {
  /// The static instance Future function to use for resolving the type registered
  final Future Function() presolveUsing;

  const Presolve({
    Type? classType,
    Type? asType,
    required this.presolveUsing,
    Set<String>? environments,
    String? instanceName,
  }) : super(
          instanceName: instanceName,
          classType: classType,
          asType: asType,
          environments: environments,
        );
}

/// Registers the type passed in to be presolved using the function passed in
class InitializableSingleton extends DependencyRegistration {
  const InitializableSingleton({
    Type? classType,
    Type? asType,
    Set<String>? environments,
    String? instanceName,
  }) : super(
          instanceName: instanceName,
          classType: classType,
          asType: asType,
          environments: environments,
        );
}
