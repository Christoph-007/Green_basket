import 'package:flutter_test/flutter_test.dart';
import 'package:greenbasket_app/utils/ttl_cache.dart';

void main() {
  late DateTime clock;
  late TtlCache<int> cache;
  late int loads;

  Future<int> load() async => ++loads;

  setUp(() {
    clock = DateTime(2026, 1, 1, 12);
    loads = 0;
    cache = TtlCache<int>(const Duration(minutes: 2), now: () => clock);
  });

  test('second call within the window reuses the value', () async {
    expect(await cache.get(load), 1);
    clock = clock.add(const Duration(seconds: 119));
    expect(await cache.get(load), 1);
    expect(loads, 1);
  });

  test('loads again once the window has passed', () async {
    await cache.get(load);
    clock = clock.add(const Duration(minutes: 2));
    expect(await cache.get(load), 2);
  });

  test('force bypasses a fresh value', () async {
    await cache.get(load);
    expect(await cache.get(load, force: true), 2);
  });

  test('clear drops the value', () async {
    await cache.get(load);
    cache.clear();
    expect(cache.isFresh, isFalse);
    expect(await cache.get(load), 2);
  });

  test('a failed load stores nothing and surfaces the error', () async {
    await expectLater(
      cache.get(() async => throw StateError('offline')),
      throwsStateError,
    );
    expect(cache.isFresh, isFalse);
    expect(await cache.get(load), 1);
  });

  test('a failed forced load keeps the earlier value', () async {
    await cache.get(load);
    await expectLater(
      cache.get(() async => throw StateError('offline'), force: true),
      throwsStateError,
    );
    expect(await cache.get(load), 1);
  });
}
