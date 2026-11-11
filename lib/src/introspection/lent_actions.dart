import 'dart:collection';

import 'action_spec.dart';

/// Something outside a ViewModel (a dialog, a sheet, a snackbar) that lends
/// actions to the focused screen while it is active.
abstract class LentActionProvider {
  /// Unique id, also used as ActionSpec.from: 'dialog', 'sheet', 'snackbar'.
  String get id;

  bool get isActive;

  /// Description of the open overlay, or null. Must include "type".
  Map<String, Object?>? get overlay;

  List<ActionSpec> get actions;
}

abstract final class LentActionProviders {
  static final LinkedHashMap<String, LentActionProvider> _providers =
      LinkedHashMap<String, LentActionProvider>();

  /// Replaces any provider with the same id.
  static void register(LentActionProvider provider) {
    _providers.remove(provider.id);
    _providers[provider.id] = provider;
  }

  static void unregister(String id) => _providers.remove(id);

  /// Providers whose isActive is true, in registration order.
  static List<LentActionProvider> get active => [
        for (final p in _providers.values)
          if (p.isActive) p
      ];

  static void reset() => _providers.clear();
}
