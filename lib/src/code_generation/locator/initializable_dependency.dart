/// `InitializableDependency` is an abstract class intended to be implemented by
/// any class which requires asynchronous initialization before being used.
///
/// This is particularly useful when using `InitializableSingleton`. A class implementing
/// `InitializableDependency` signifies that it has asynchronous setup work to be done
/// before it can be used effectively. The setup is done in the `init` method.
///
/// This is particularly useful for classes that depend on resources such as
/// File I/O, Network calls, Database access, etc. which cannot be performed
/// synchronously during object construction.
///
/// This abstract class contains a single method, `init()`, which is expected
/// to contain all asynchronous initialization logic for the implementing class.
abstract class InitializableDependency {
  /// Handles Asynchronously initialization.
  Future<void> init();
}
