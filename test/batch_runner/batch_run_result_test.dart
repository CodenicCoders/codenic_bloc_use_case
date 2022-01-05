import 'dart:collection';

import 'package:codenic_bloc_use_case/codenic_bloc_use_case.dart';
import 'package:codenic_bloc_use_case/src/base.dart';
import 'package:test/test.dart';

class TestUseCase extends BaseUseCase<bool, String, String> {
  TestUseCase(this.id);

  final String id;

  @override
  Future<Either<String, String>> onCall(bool params) async =>
      params ? Right('Success $id') : Left('Failed $id');
}

class TestUseCaseA extends TestUseCase {
  TestUseCaseA() : super('A');
}

class TestUseCaseB extends TestUseCase {
  TestUseCaseB() : super('B');
}

void main() {
  group(
    'Batch run result',
    () {
      late TestUseCaseA testUseCaseA;
      late TestUseCaseB testUseCaseB;
      late BatchRunResult<void, void> batchRunResult;

      setUp(() {
        testUseCaseA = TestUseCaseA();
        testUseCaseB = TestUseCaseB();

        batchRunResult = BatchRunResult(
          UnmodifiableListView([testUseCaseA, testUseCaseB]),
        );
      });

      test(
        'should return specific use case that has has been executed',
        () async {
          await testUseCaseA.call(true);
          expect(batchRunResult<TestUseCaseA>(), testUseCaseA);
        },
      );

      test(
        'should return null when fetching use case that has not been executed',
        () => expect(batchRunResult<TestUseCaseA>(), null),
      );

      test(
        'should return failed use cases',
        () async {
          await Future.wait(
            [testUseCaseA.call(false), testUseCaseB.call(false)],
          );
          expect(batchRunResult.leftUseCases(), [testUseCaseA, testUseCaseB]);
        },
      );

      test(
        'should return completed use cases',
        () async {
          await Future.wait(
            [testUseCaseA.call(true), testUseCaseB.call(true)],
          );
          expect(batchRunResult.rightUseCases(), [testUseCaseA, testUseCaseB]);
        },
      );

      test(
        'should return all use cases',
        () async {
          await Future.wait(
            [testUseCaseA.call(true), testUseCaseB.call(false)],
          );
          expect(batchRunResult.useCases, [testUseCaseA, testUseCaseB]);
        },
      );

      test(
        'should return all error values',
        () async {
          await Future.wait(
            [testUseCaseA.call(false), testUseCaseB.call(false)],
          );
          expect(batchRunResult.leftValues(), ['Failed A', 'Failed B']);
        },
      );

      test(
        'should return all success values',
        () async {
          await Future.wait(
            [testUseCaseA.call(true), testUseCaseB.call(true)],
          );
          expect(batchRunResult.rightValues(), ['Success A', 'Success B']);
        },
      );
    },
  );
}
