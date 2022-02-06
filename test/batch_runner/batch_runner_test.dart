import 'dart:collection';

import 'package:bloc_test/bloc_test.dart';
import 'package:codenic_bloc_use_case/codenic_bloc_use_case.dart';
import 'package:test/test.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

class TestDivideInteger extends BaseUseCase<int, String, int>
    with EquatableMixin {
  TestDivideInteger(this.divisor);

  final int divisor;

  @override
  Future<Either<String, int>> onCall(int params) async {
    await ensureAsync();

    final quotient = params / divisor;

    return quotient % 1 != 0
        ? Left('$this: Not an integer')
        : Right(quotient.toInt());
  }

  @override
  List<Object?> get props => [divisor];
}

void main() {
  group(
    'Batch runner',
    () {
      late BatchRunner<void, int> batchRunner;

      late TestDivideInteger testDivideIntegerByOne;
      late TestDivideInteger testDivideIntegerByTwo;
      late TestDivideInteger testDivideIntegerByThree;
      late TestDivideInteger testDivideIntegerByFive;

      setUp(() {
        testDivideIntegerByOne = TestDivideInteger(1);
        testDivideIntegerByTwo = TestDivideInteger(2);
        testDivideIntegerByThree = TestDivideInteger(3);
        testDivideIntegerByFive = TestDivideInteger(5);

        batchRunner = BatchRunner(
          useCaseConstructorParams: null,
          useCaseFactories: UnmodifiableListView([
            UnmodifiableListView([
              UseCaseFactory<void, int, TestDivideInteger>(
                onInitialize: (void constructorParams) =>
                    testDivideIntegerByOne,
                onCall: (params, useCase) => useCase.call(params),
              ),
              UseCaseFactory<void, int, TestDivideInteger>(
                onInitialize: (void constructorParams) =>
                    testDivideIntegerByTwo,
                onCall: (params, useCase) => useCase.call(params),
              ),
            ]),
            UnmodifiableListView([
              UseCaseFactory<void, int, TestDivideInteger>(
                onInitialize: (void constructorParams) =>
                    testDivideIntegerByThree,
                onCall: (params, useCase) => useCase.call(params),
              ),
            ]),
            UnmodifiableListView([
              UseCaseFactory<void, int, TestDivideInteger>(
                onInitialize: (void constructorParams) =>
                    testDivideIntegerByFive,
                onCall: (params, useCase) => useCase.call(params),
              ),
            ]),
          ]),
        );
      });
      group(
        'batch run',
        () {
          blocTest<BatchRunner, BatchRunnerState>(
            'should not call next batch of use cases when current batch fails',
            build: () => batchRunner,
            act: (batchRunner) => batchRunner.batchRun(params: 3),
            expect: () => [
              const BatchRunning(1),
              BatchRunFailed(
                BatchRunResult(
                  UnmodifiableListView([
                    testDivideIntegerByOne,
                    testDivideIntegerByTwo,
                  ]),
                ),
                1,
              ),
            ],
            verify: (batchRunner) => expect(
              batchRunner.batchRunResult?.useCases,
              [testDivideIntegerByOne, testDivideIntegerByTwo],
            ),
          );

          blocTest<BatchRunner, BatchRunnerState>(
            'should show failed use cases in batch when batch fails',
            build: () => batchRunner,
            act: (batchRunner) => batchRunner.batchRun(params: 8),
            expect: () => [
              const BatchRunning(1),
              BatchRunFailed(
                BatchRunResult(
                  UnmodifiableListView([
                    testDivideIntegerByOne,
                    testDivideIntegerByTwo,
                    testDivideIntegerByThree,
                  ]),
                ),
                1,
              ),
            ],
            verify: (batchRunner) => expect(
              batchRunner.batchRunResult?.leftUseCases(),
              [testDivideIntegerByThree],
            ),
          );

          blocTest<BatchRunner, BatchRunnerState>(
            'should show all completed use cases when batch run succeeds',
            build: () => batchRunner,
            act: (batchRunner) => batchRunner.batchRun(params: 30),
            expect: () => [
              const BatchRunning(1),
              BatchRunSuccess(
                BatchRunResult(
                  UnmodifiableListView([
                    testDivideIntegerByOne,
                    testDivideIntegerByTwo,
                    testDivideIntegerByThree,
                    testDivideIntegerByFive,
                  ]),
                ),
                1,
              ),
            ],
            verify: (batchRunner) => expect(
              batchRunner.batchRunResult?.rightUseCases(),
              [
                testDivideIntegerByOne,
                testDivideIntegerByTwo,
                testDivideIntegerByThree,
                testDivideIntegerByFive,
              ],
            ),
          );

          blocTest<BatchRunner, BatchRunnerState>(
            'should not emit state from old batch-run call when new batch-run '
            'call is made at the same time',
            build: () => BatchRunner<void, void>(
              useCaseConstructorParams: null,
              useCaseFactories: UnmodifiableListView([]),
            ),
            act: (batchRunner) async {
              await Future.wait([
                batchRunner.batchRun(params: null),
                batchRunner.batchRun(params: null),
              ]);
            },
            expect: () => [
              const BatchRunning(2),
              BatchRunSuccess(
                BatchRunResult(UnmodifiableListView([])),
                2,
              ),
            ],
          );

          blocTest<BatchRunner, BatchRunnerState>(
            'should cancel state emission from old running run call when new '
            'run call is made',
            build: () => batchRunner,
            act: (batchRunner) async {
              unawaited(batchRunner.batchRun(params: 30));
              await ensureAsync();
              await batchRunner.batchRun(params: 30);
            },
            expect: () => [
              const BatchRunning(1),
              const BatchRunning(2),
              BatchRunSuccess(
                BatchRunResult(
                  UnmodifiableListView([
                    testDivideIntegerByOne,
                    testDivideIntegerByTwo,
                    testDivideIntegerByThree,
                    testDivideIntegerByFive,
                  ]),
                ),
                2,
              ),
            ],
          );
        },
      );

      group(
        'reset',
        () {
          blocTest<BatchRunner, BatchRunnerState>(
            'should clear values when reset',
            build: () => batchRunner,
            act: (batchRunner) async {
              await batchRunner.batchRun(params: 30);
              await batchRunner.reset();
            },
            verify: (batchRunner) {
              expect(batchRunner.batchRunResult, null);

              for (final useCaseFactoryGroup in batchRunner.useCaseFactories) {
                for (final useCaseFactory in useCaseFactoryGroup) {
                  expect(useCaseFactory.useCase, null);
                }
              }
            },
          );

          blocTest<BatchRunner, BatchRunnerState>(
            'should allow re-call of completed use cases when they have been '
            'reset',
            build: () => batchRunner,
            act: (batchRunner) async {
              await batchRunner.batchRun(params: 30);
              await batchRunner.reset();
              await batchRunner.batchRun(params: 2);
            },
            expect: () => [
              const BatchRunning(1),
              BatchRunSuccess(
                BatchRunResult(
                  UnmodifiableListView([
                    testDivideIntegerByOne,
                    testDivideIntegerByTwo,
                    testDivideIntegerByThree,
                    testDivideIntegerByFive,
                  ]),
                ),
                1,
              ),
              const BatchRunnerInitial(2),
              const BatchRunning(3),
              BatchRunFailed(
                BatchRunResult(
                  UnmodifiableListView([
                    testDivideIntegerByOne,
                    testDivideIntegerByTwo,
                    testDivideIntegerByThree,
                  ]),
                ),
                3,
              ),
            ],
          );
        },
      );
    },
  );
}
