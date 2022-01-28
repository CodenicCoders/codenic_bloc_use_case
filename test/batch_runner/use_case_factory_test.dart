import 'package:codenic_bloc_use_case/codenic_bloc_use_case.dart';
import 'package:codenic_bloc_use_case/src/base.dart';
import 'package:test/test.dart';

class TestUseCase extends BaseUseCase<bool, void, void> {
  @override
  Future<Either<void, void>> onCall(bool params) async =>
      params ? const Right(null) : const Left(null);
}

void main() {
  group(
    'Use case factory',
    () {
      group(
        'call',
        () {
          test(
            'should only create use case on first call',
            () async {
              // Given
              final useCaseFactory = UseCaseFactory<void, bool, TestUseCase>(
                onInitialize: (_) => TestUseCase(),
                onCall: (params, useCase) => useCase.call(params),
              );

              // When
              await useCaseFactory.call(null, true);
              final useCase1 = useCaseFactory.useCase;

              await useCaseFactory.call(null, true);
              final useCase2 = useCaseFactory.useCase;

              // Then
              expect(useCase1, useCase2);
            },
          );

          test(
            'should not re-call use case if completed',
            () async {
              // Given
              final useCaseFactory = UseCaseFactory<void, bool, TestUseCase>(
                onInitialize: (_) => TestUseCase(),
                onCall: (params, useCase) => useCase.call(params),
              );

              // When
              await useCaseFactory.call(null, true);
              final useCaseValue1 = useCaseFactory.useCase!.value;

              await useCaseFactory.call(null, true);
              final useCaseValue2 = useCaseFactory.useCase!.value;

              // Then
              expect(useCaseValue1, useCaseValue2);
            },
          );

          test(
            'should not re-call use case if completed',
            () async {
              // Given
              final useCaseFactory = UseCaseFactory<void, bool, TestUseCase>(
                onInitialize: (_) => TestUseCase(),
                onCall: (params, useCase) => useCase.call(params),
              );

              // When
              await useCaseFactory.call(null, true);
              final useCaseValue1 = useCaseFactory.useCase!.value;

              await useCaseFactory.call(null, true);
              final useCaseValue2 = useCaseFactory.useCase!.value;

              // Then
              expect(useCaseValue1, useCaseValue2);
            },
          );

          test(
            'should re-call use case if failed',
            () async {
              // Given
              final useCaseFactory = UseCaseFactory<void, bool, TestUseCase>(
                onInitialize: (_) => TestUseCase(),
                onCall: (params, useCase) => useCase.call(params),
              );

              // When
              await useCaseFactory.call(null, false);
              final useCaseValue1 = useCaseFactory.useCase!.value!;

              await useCaseFactory.call(null, true);
              final useCaseValue2 = useCaseFactory.useCase!.value!;

              // Then
              expect(useCaseValue1.isLeft(), useCaseValue2.isRight());
            },
          );
        },
      );
    },
  );
}
