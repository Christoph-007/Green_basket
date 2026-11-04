/// Remembers one value for a short time so repeat screens don't refetch it.
///
/// Only successful results are kept. If a load throws, nothing is stored and
/// the error reaches the caller. [clear] drops the value (use it after the
/// data is changed).
class TtlCache<T> {
  final Duration ttl;
  final DateTime Function() _now;

  T? _value;
  DateTime? _storedAt;

  TtlCache(this.ttl, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  bool get isFresh =>
      _value != null && _storedAt != null && _now().difference(_storedAt!) < ttl;

  /// Returns the cached value if still fresh (and [force] is false);
  /// otherwise runs [load], stores the result and returns it.
  Future<T> get(Future<T> Function() load, {bool force = false}) async {
    if (!force && isFresh) return _value as T;
    final loaded = await load();
    _value = loaded;
    _storedAt = _now();
    return loaded;
  }

  void clear() {
    _value = null;
    _storedAt = null;
  }
}
