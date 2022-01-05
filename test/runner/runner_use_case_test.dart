import 'package:bloc_test/bloc_test.dart';
import 'package:codenic_bloc_use_case/codenic_bloc_use_case.dart';
import 'package:codenic_bloc_use_case/src/util/ensure_async.dart';
import 'package:test/test.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

/// A dummy use case for testing the [Runner].
///
/// A use case that returns the next even number from the given even number
/// argument.
class TestNextEvenNumber extends Runner<int, String, int> {
  @override
  Future<Either<String, int>> onCall(int params) async {
    await ensureAsync();

    if (params % 2 != 0) {
      return const Left('Argument is not an even number');
    }

    final nextEvenNum = params + 2;

    return Right(nextEvenNum);
  }
}

void main() {
  group(
    'Runner use case',
    () {
      group(
        'run',
        () {
          blocTest<Runner, RunnerState>(
            'should return success value when run succeeds',
            build: TestNextEvenNumber.new,
            act: (runner) => runner.run(params: 2),
            expect: () => const [Running(1), RunSuccess(4, 1)],
          );

          blocTest<Runner, RunnerState>(
            'should return failure value when run fails',
            build: TestNextEvenNumber.new,
            act: (runner) => runner.run(params: 1),
            expect: () => const [
              Running(1),
              RunFailed('Argument is not an even number', 1),
            ],
          );

          blocTest<Runner, RunnerState>(
            'should not emit state from old run call when new run call is made '
            'at the same time',
            build: TestNextEvenNumber.new,
            act: (runner) async =>
                Future.wait([runner.run(params: 0), runner.run(params: 1)]),
            expect: () => const [
              Running(2),
              RunFailed('Argument is not an even number', 2),
            ],
          );

          blocTest<Runner, RunnerState>(
            'should cancel state emission from old running batch-run call when '
            'new batch-run call is made',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              unawaited(runner.run(params: 1));
              await ensureAsync();
              await runner.run(params: 2);
            },
            expect: () => const [
              Running(1),
              Running(2),
              RunSuccess(4, 2),
            ],
          );
        },
      );

      group(
        'value',
        () {
          blocTest<Runner, RunnerState>(
            'should identify if last emitted value is a success value',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              await runner.run(params: 1);
              await runner.run(params: 2);
            },
            verify: (runner) => expect(runner.value?.isRight(), true),
          );

          blocTest<Runner, RunnerState>(
            'should identify if last emitted value is an error value',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              await runner.run(params: 2);
              await runner.run(params: 1);
            },
            verify: (runner) => expect(runner.value?.isLeft(), true),
          );

          blocTest<Runner, RunnerState>(
            'should clear value when reset',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              await runner.run(params: 2);
              await runner.reset();
            },
            verify: (runner) => expect(runner.value, null),
          );
        },
      );

      group(
        'left value',
        () {
          blocTest<Runner, RunnerState>(
            'should still have reference to the last error value when runner '
            'succeeds',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              await runner.run(params: 1);
              await runner.run(params: 2);
            },
            verify: (runner) =>
                expect(runner.leftValue, 'Argument is not an even number'),
          );

          blocTest<Runner, RunnerState>(
            'should clear left value when reset',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              await runner.run(params: 1);
              await runner.reset();
            },
            verify: (runner) => expect(runner.leftValue, null),
          );
        },
      );

      group(
        'right value',
        () {
          blocTest<Runner, RunnerState>(
            'should still have reference to the last success value when runner '
            'fails',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              await runner.run(params: 2);
              await runner.run(params: 1);
            },
            verify: (runner) => expect(runner.rightValue, 4),
          );

          blocTest<Runner, RunnerState>(
            'should clear right value when reset',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              await runner.run(params: 2);
              await runner.reset();
            },
            verify: (runner) => expect(runner.rightValue, null),
          );
        },
      );

      group(
        'reset',
        () {
          blocTest<Runner, RunnerState>(
            'should reset runner',
            build: TestNextEvenNumber.new,
            act: (runner) async {
              await runner.run(params: 2);
              await runner.reset();
            },
            expect: () =>
                const [Running(1), RunSuccess(4, 1), RunnerInitial(2)],
          );
        },
      );
    },
  );
}
