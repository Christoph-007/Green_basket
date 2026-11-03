import 'dart:async';

/// Runs an async task at most once at a time: callers that arrive while it is
/// still running wait for that same run and get the same result (or error).
/// Once it finishes, the next call starts a fresh run.
///
/// Used so that many requests failing with 401 together trigger ONE token
/// refresh instead of racing each other.
class SingleFlight<T> {
  Future<T>? _inFlight;

  bool get isRunning => _inFlight != null;

  Future<T> run(Future<T> Function() task) {
    final running = _inFlight;
    if (running != null) return running;
    final started = task().whenComplete(() => _inFlight = null);
    _inFlight = started;
    return started;
  }
}
