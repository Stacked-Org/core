/// Error codes used in JSON responses (explore output, future bridges).
abstract final class StackedErrorCode {
  static const unknownAction = 'unknown_action';
  static const unsupportedAction = 'unsupported_action';
  static const invalidInput = 'invalid_input';
  static const actionThrew = 'action_threw';
  static const timeout = 'timeout';
  static const networkBlocked = 'network_blocked';
  static const runFailed = 'run_failed';
}
