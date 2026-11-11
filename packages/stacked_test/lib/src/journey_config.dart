import 'dart:async';

import 'package:flutter/widgets.dart';

/// How a journey boots the app.
class JourneyConfig {
  const JourneyConfig({
    required this.setupLocator,
    required this.setupUi,
    required this.app,
    this.surfaceSize = const Size(390, 844),
    this.devicePixelRatio = 3.0,
    this.step = const Duration(milliseconds: 50),
    this.timeout = const Duration(seconds: 10),
    this.allowImageRequests = true,
    this.loadFonts = true,
  });

  /// Registers the app's services in the locator.
  final FutureOr<void> Function() setupLocator;

  /// Registers dialogs, bottom sheets and introspection.
  final FutureOr<void> Function() setupUi;

  /// Builds the root widget of the app.
  final Widget Function() app;

  final Size surfaceSize;
  final double devicePixelRatio;

  /// Fake time that one step advances.
  final Duration step;

  /// Default fake-time limit for one action or wait.
  final Duration timeout;

  /// When true, image requests get a transparent 1x1 PNG instead of failing.
  final bool allowImageRequests;

  /// When true, Roboto, MaterialIcons and the app's fonts are loaded.
  final bool loadFonts;
}
