import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:greenbasket_app/utils/single_flight.dart';

void main() {
  test('callers that overlap share one run and one result', () async {
    final gate = SingleFlight<int>();
    var runs = 0;
    final release = Completer<void>();

    Future<int> task() async {
      runs++;
      await release.future;
      return 42;
    }

    final results = Future.wait([gate.run(task), gate.run(task), gate.run(task)]);
    expect(gate.isRunning, isTrue);
    release.complete();

    expect(await results, [42, 42, 42]);
    expect(runs, 1);
    expect(gate.isRunning, isFalse);
  });

  test('a call after the run finished starts a new run', () async {
    final gate = SingleFlight<int>();
    var runs = 0;
    Future<int> task() async => ++runs;

    expect(await gate.run(task), 1);
    expect(await gate.run(task), 2);
  });

  test('a failing run reports the error to everyone and then resets', () async {
    final gate = SingleFlight<int>();
    var runs = 0;
    final release = Completer<void>();

    Future<int> failing() async {
      runs++;
      await release.future;
      throw StateError('refresh failed');
    }

    final a = gate.run(failing);
    final b = gate.run(failing);
    release.complete();

    await expectLater(a, throwsStateError);
    await expectLater(b, throwsStateError);
    expect(runs, 1);
    expect(gate.isRunning, isFalse);

    expect(await gate.run(() async => 7), 7);
  });
}
