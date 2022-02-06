import 'dart:collection';

import 'package:codenic_bloc_use_case/codenic_bloc_use_case.dart';
import 'package:test/test.dart';

class TestUseCaseA extends BaseUseCase<bool, Exception, int> {
  @override
  Future<Either<Exception, int>> onCall(bool params) async =>
      params ? const Right(1) : Left(Exception('Failed A'));
}

class TestUseCaseB extends BaseUseCase<bool, String, String> {
  @override
  Future<Either<String, String>> onCall(bool params) async =>
      params ? const Right('1') : const Left('Failed B');
}

void main() {
  group(
    'Batch run result',
    () {
      late TestUseCaseA testUseCaseA;
      late TestUseCaseB testUseCaseB;
      late BatchRunResult batchRunResult;

      setUp(() {
        testUseCaseA = TestUseCaseA();
        testUseCaseB = TestUseCaseB();

        batchRunResult = BatchRunResult(
          UnmodifiableListView([testUseCaseA, testUseCaseB]),
        );
      });

      test(
        'should return specific use case that has been executed',
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
        'should return all failed use cases',
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
        'should return all failed values',
        () async {
          await Future.wait(
            [testUseCaseA.call(false), testUseCaseB.call(false)],
          );
          expect(
            batchRunResult.leftValues<dynamic>(),
            [isA<Exception>(), 'Failed B'],
          );
        },
      );

      test(
        'should return all failed values with specified return type',
        () async {
          await Future.wait(
            [testUseCaseA.call(false), testUseCaseB.call(false)],
          );
          expect(batchRunResult.leftValues<String>(), ['Failed B']);
        },
      );

      test(
        'should return all success values',
        () async {
          await Future.wait(
            [testUseCaseA.call(true), testUseCaseB.call(true)],
          );
          expect(
            batchRunResult.rightValues<dynamic>(),
            [1, '1'],
          );
        },
      );

      test(
        'should return all success values with specified return type',
        () async {
          await Future.wait(
            [testUseCaseA.call(true), testUseCaseB.call(true)],
          );
          expect(
            batchRunResult.rightValues<int>(),
            [1],
          );
        },
      );
    },
  );
}
