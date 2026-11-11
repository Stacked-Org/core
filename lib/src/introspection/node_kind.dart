/// What a described ViewModel is used for.
enum NodeKind {
  /// The ViewModel of a View listed in `@StackedApp(routes:)`.
  route,

  /// The ViewModel of a class in `dialogs:`.
  dialog,

  /// The ViewModel of a class in `bottomsheets:`.
  sheet,

  /// Any other ViewModel.
  widget,
}
