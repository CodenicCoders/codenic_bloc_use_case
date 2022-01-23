// ignore_for_file: avoid_print

part of 'main.dart';

Future<void> batchRunner() async {
  print(
    '\n//******************** BATCH RUNNER USE CASE SAMPLE ********************',
  );

  print('\n** INITIALIZE BATCH RUNNER **');

  // Initialize the batch runner use case
  final batchFetchMeal = BatchFetchMeal(
    constructorParams: const BatchFetchMealConstructorParams(
      availableFruits: ['Apple, Orange, Mango, Lemon'],
      availableVeggies: ['Kale', 'Garlic', 'Cabbage', 'Broccoli'],
      availableGrains: ['Barley', 'Brown Rice', 'Oatmeal', 'Millet'],
    ),
  );

  printBatchRunResults(batchFetchMeal);

  print('\n** FAILED BATCH RUN (FIRST BATCH) **');

  // Execute the batch runner with an expected failed result when fetching
  // fruits
  await batchFetchMeal.batchRun(
    params: const BatchFetchMealCallParams(
      fruitCount: 0,
      veggieCount: 4,
      grainCount: 0,
    ),
  );

  // View the results
  // Expectations:
  // - Fetch fruit fails due to 0 fruit count
  // - Fetch vegetable succeeds
  // - Fetch grain not executed since preceding batch fails
  printBatchRunResults(batchFetchMeal);

  print('\n** FAILED BATCH RUN (SECOND BATCH) **');

  // Execute the batch runner with an expected failed result when fetching
  // grains
  await batchFetchMeal.batchRun(
    params: const BatchFetchMealCallParams(
      fruitCount: 2,
      veggieCount: 4,
      grainCount: 0,
    ),
  );

  // View the results
  // Expectations:
  // - Fetch fruit succeeds
  // - Fetch vegetable succeeds
  // - Fetch grain fails due to 0 grain count
  printBatchRunResults(batchFetchMeal);

  print('\n** SUCCESSFUL BATCH RUN **');

  // Execute the batch runner with an expected successful result
  await batchFetchMeal.batchRun(
    params: const BatchFetchMealCallParams(
      fruitCount: 2,
      veggieCount: 4,
      grainCount: 3,
    ),
  );

  // View the results
  // Expectations:
  // - Fetch fruit succeeds
  // - Fetch vegetable succeeds
  // - Fetch grain succeeds
  printBatchRunResults(batchFetchMeal);

  print('\n** RESET BATCH RUNNER **');

  // Reset the runner use case to its initial state
  await batchFetchMeal.reset();

  // View the results
  printBatchRunResults(batchFetchMeal);
}

void printBatchRunResults(BatchRunner batchRunner) {
  final batchRunResult = batchRunner.batchRunResult;

  print('');
  // All use cases created and called in the batch run
  print('$BatchFetchMeal batch run use cases: ${batchRunResult?.useCases}');
  // The left values by all left (failed) use cases
  print(
    '$BatchFetchMeal batch run left values: ${batchRunResult?.leftValues()}',
  );
  // The right values by all right (successful) use cases
  print(
    '$BatchFetchMeal batch run right values: ${batchRunResult?.rightValues()}',
  );

  // Reference each use cases. If `call()` returns `null`, then that use case
  // may have not been created yet by the `UseCaseFactory`
  final fetchFruits = batchRunResult?.call<FetchFruits>();
  final fetchVeggies = batchRunResult?.call<FetchVeggies>();
  final fetchGrains = batchRunResult?.call<FetchGrains>();

  print('');
  print('$FetchFruits last left value: ${fetchFruits?.leftValue}');
  print('$FetchFruits last right value: ${fetchFruits?.rightValue}');
  print('$FetchFruits current value: ${fetchFruits?.value}');
  print('');
  print('$FetchVeggies last left value: ${fetchVeggies?.leftValue}');
  print('$FetchVeggies last right value: ${fetchVeggies?.rightValue}');
  print('$FetchVeggies current value: ${fetchVeggies?.value}');
  print('');
  print('$FetchGrains last left value: ${fetchGrains?.leftValue}');
  print('$FetchGrains last right value: ${fetchGrains?.rightValue}');
  print('$FetchGrains current value: ${fetchGrains?.value}');
}

/// Fetches a meal by creating and executing the [FetchFruits] and
/// [FetchVeggies] use cases in the first batch, followed by [FetchGrains] in
/// the second batch.
class BatchFetchMeal extends BatchRunner<Failure, dynamic,
    BatchFetchMealConstructorParams, BatchFetchMealCallParams> {
  BatchFetchMeal({
    required BatchFetchMealConstructorParams constructorParams,
  }) : super(
          useCaseConstructorParams: constructorParams,
          useCaseFactories: [
            // The first batch of use cases
            [
              UseCaseFactory<Failure, dynamic, BatchFetchMealConstructorParams,
                  BatchFetchMealCallParams, FetchFruits>(
                onInitialize: (constructorParams) =>
                    FetchFruits(fruits: constructorParams.availableFruits),
                onCall: (callParams, useCase) =>
                    useCase.call(callParams.fruitCount),
              ),
              UseCaseFactory<Failure, dynamic, BatchFetchMealConstructorParams,
                  BatchFetchMealCallParams, FetchVeggies>(
                onInitialize: (constructorParams) =>
                    FetchVeggies(veggies: constructorParams.availableVeggies),
                onCall: (callParams, useCase) =>
                    useCase.call(callParams.veggieCount),
              )
            ],
            // The second batch of use cases
            [
              UseCaseFactory<Failure, dynamic, BatchFetchMealConstructorParams,
                  BatchFetchMealCallParams, FetchGrains>(
                onInitialize: (constructorParams) =>
                    FetchGrains(grains: constructorParams.availableGrains),
                onCall: (callParams, useCase) =>
                    useCase.call(callParams.grainCount),
              )
            ]
          ],
        );
}

/// The parameter passed to each [UseCaseFactory] to initialize a use case.
class BatchFetchMealConstructorParams {
  const BatchFetchMealConstructorParams({
    required this.availableFruits,
    required this.availableVeggies,
    required this.availableGrains,
  });

  final List<String> availableFruits;
  final List<String> availableVeggies;
  final List<String> availableGrains;
}

/// The parameter passed to each [UseCaseFactory] to call a use case.
class BatchFetchMealCallParams {
  const BatchFetchMealCallParams({
    required this.fruitCount,
    required this.veggieCount,
    required this.grainCount,
  });

  final int fruitCount;
  final int veggieCount;
  final int grainCount;
}

class FetchFruits extends BaseUseCase<int, Failure, List<String>> {
  FetchFruits({required this.fruits});

  final List<String> fruits;

  @override
  Future<Either<Failure, List<String>>> onCall(int params) async {
    if (params < 1) {
      return const Left(
        Failure('Number of fruits to be fetched must be greater than 0'),
      );
    }

    return Right(fruits.take(params).toList());
  }
}

class FetchVeggies extends BaseUseCase<int, Failure, List<String>> {
  FetchVeggies({required this.veggies});

  final List<String> veggies;

  @override
  Future<Either<Failure, List<String>>> onCall(int params) async {
    if (params < 1) {
      return const Left(
        Failure('Number of veggies to be fetched must be greater than 0'),
      );
    }

    return Right(veggies.take(params).toList());
  }
}

class FetchGrains extends BaseUseCase<int, Failure, List<String>> {
  FetchGrains({required this.grains});

  final List<String> grains;

  @override
  Future<Either<Failure, List<String>>> onCall(int params) async {
    if (params < 1) {
      return const Left(
        Failure('Number of grains to be fetched must be greater than 0'),
      );
    }

    return Right(grains.take(params).toList());
  }
}