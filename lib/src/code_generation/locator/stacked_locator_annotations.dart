import 'dart:async';

/// `Environment` is a class that provides preset constants to identify
/// different types of environments where your app might be running.
///
/// Currently, it provides the following presets:
/// - `dev` for development environment
/// - `prod` for production environment
/// - `test` for testing environment
class Environment {
  const Environment._();

  /// preset of common env name 'dev'
  static const dev = 'dev';

  /// preset of common env name 'prod'
  static const prod = 'prod';

  /// preset of common env name 'test'
  static const test = 'test';
}

/// `DependencyRegistration` is an abstract class that provides a common structure
/// for registering dependencies with the `get_it` locator. Different subclasses
/// provide different registration methods, such as Singleton, LazySingleton, Factory, etc.
///
/// It contains several properties that subclasses can use to configure the registration:
///
/// - `classType`: The concrete class type that should be registered.
///
/// - `asType`: An optional abstract type or interface that `classType` can be registered as.
///
/// - `resolveUsing`: An optional function to generate an instance of `classType`.
///
/// - `dispose`: An optional function that can be called to dispose of the registered instance.
///
/// - `param1`, `param2`: Optional types that can be used by a factory function to create an instance.
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

/// `Singleton` is a class that extends [DependencyRegistration]. It provides a way
/// to register an object as a Singleton to the `get_it` locator.
///
/// A Singleton means the object will be instantiated during the first fetch and then will stay
/// alive in the memory and the same instance will be returned in the subsequent fetches.
///
/// Parameters:
/// - `classType`: The concrete class to be registered to the `get_it` locator.
/// - `asType`: An abstract class or interface to map the `classType` to. This is useful when
///              you want to abstract the concrete implementation and depend on interfaces.
/// - `resolveUsing`: A callback that resolves the instance. If null, `classType` is instantiated directly.
/// - `environments`: A set of environment names where this registration should be included.
///                   Useful for conditionally including a service depending on the running environment.
/// - `instanceName`: An optional instance name that can be used to register multiple objects of the
///                   same type. You will need to fetch the object by instance name from the `get_it` locator.
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

/// `LazySingleton` is a class that extends [DependencyRegistration]. It provides a way
/// to register an object as a Lazy Singleton to the `get_it` locator.
///
/// A Lazy Singleton means the object will be instantiated during the first fetch and then will stay
/// alive in the memory and the same instance will be returned in the subsequent fetches. The key
/// difference between a [Singleton] and a [LazySingleton] is that a Lazy Singleton is not created
/// until it is fetched for the first time.
///
/// Parameters:
/// - `classType`: The concrete class to be registered to the `get_it` locator.
/// - `asType`: An abstract class or interface to map the `classType` to. This is useful when
///              you want to abstract the concrete implementation and depend on interfaces.
/// - `resolveUsing`: A callback that resolves the instance. If null, `classType` is instantiated directly.
/// - `environments`: A set of environment names where this registration should be included.
///                   Useful for conditionally including a service depending on the running environment.
/// - `instanceName`: An optional instance name that can be used to register multiple objects of the
///                   same type. You will need to fetch the object by instance name from the `get_it` locator.
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

/// `Factory` is a class that extends [DependencyRegistration]. It provides a way
/// to register an object as a Factory to the `get_it` locator.
///
/// A Factory means that a new instance of the object will be created each time it is fetched.
///
/// Parameters:
/// - `classType`: The concrete class to be registered to the `get_it` locator.
/// - `asType`: An abstract class or interface to map the `classType` to. This is useful when
///              you want to abstract the concrete implementation and depend on interfaces.
/// - `environments`: A set of environment names where this registration should be included.
///                   Useful for conditionally including a service depending on the running environment.
/// - `instanceName`: An optional instance name that can be used to register multiple objects of the
///                   same type. You will need to fetch the object by instance name from the `get_it` locator.
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

/// `FactoryWithParam` is a class that extends [DependencyRegistration]. It provides a way
/// to register an object as a Factory with parameter to the `get_it` locator.
///
/// A Factory with parameter means that a new instance of the object will be created each time it
/// is fetched, and the parameters will be passed to the factory function to create the instance.
///
/// Example:
/// ```dart
///   import 'package:stacked_shared/stacked_shared.dart';
///   class FactoryService {
///     final String? data1;
///     final double? data2;
///     FactoryService(@factoryParam this.data1, {@factoryParam this.data2});
///   }
/// ```
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

/// `InitializableSingleton` is a class that extends [DependencyRegistration].
/// It provides a way to register an object as a Singleton to the `get_it` locator.
/// This means the object will be instantiated during the first fetch and then will stay
/// alive in the memory and the same instance will be returned in the subsequent fetches.
///
/// When used with a class implementing the `InitializableDependency` interface,
/// the `init` method of the class will be called upon registration, allowing any
/// necessary asynchronous initialization logic to be executed before the singleton
/// instance is fetched for the first time.
///
/// This is useful when you need to perform some setup or initialization tasks (like setting up a
/// database, making a network request, etc.) before the class can be used.
///
/// Example:
/// ```dart
/// class DataCache implements InitializableDependency {
///   // Implementation details
///
///   @override
///   Future<void> init() async {
///     // Initialization logic goes here
///   }
/// }
/// ```
/// Then register it as:
/// ```dart
/// InitializableSingleton(classType: DataCache)
/// ```
///
/// Parameters:
/// - `classType`: The concrete class to be registered to the `get_it` locator. This class
///                should implement `InitializableDependency` interface.
///
/// - `asType`: An abstract class or interface to map the `classType` to. This is useful when
///              you want to abstract the concrete implementation and depend on interfaces.
///
/// - `environments`: A set of environment names where this registration should be included.
///                   Useful for conditionally including a service depending on the running environment.
///
/// - `instanceName`: An optional instance name that can be used to register multiple objects of the
///                   same type. You will need to fetch the object by instance name from the `get_it` locator.
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
