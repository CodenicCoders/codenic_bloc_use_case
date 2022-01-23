// ignore_for_file: avoid_print

part of 'main.dart';

Future<void> runner() async {
  print('\n//******************** RUNNER USE CASE SAMPLE ********************');

  print('\n** INITIALIZE RUNNER **');

  // Initialize the runner use case
  final countFruit = CountFruit();

  printRunResults(countFruit);

  print('\n** FAILED RUN **');

  // Execute the runner with an expected failed result
  await countFruit.run(params: const CountFruitParams([]));

  // View the results
  printRunResults(countFruit);

  print('\n** SUCCESSFUL RUN **');

  // Execute the runner with an expected successful result
  await countFruit.run(
    params: const CountFruitParams(['Apple', 'Orange', 'Apple']),
  );

  // View the results
  printRunResults(countFruit);

  print('\n** RESET RUNNER **');

  // Reset the runner use case to its initial state
  await countFruit.reset();

  // View the results
  printRunResults(countFruit);

  print(
    '\n******************** RUNNER USE CASE SAMPLE END ********************//',
  );
}

void printRunResults(Runner runner) {
  print('');

  // The last left value returned when calling `run()`
  print('Last left value: ${runner.leftValue}');

  // The last right value returned when calling `run()`
  print('Last right value: ${runner.rightValue}');

  // The recent value returned when calling `run()`. This may either be a
  // `Left` object containing the `leftValue` or a `Right` object containing
  // the `rightValue`
  print('Current value: ${runner.value}');

  // To set all these values back to `null`, call `reset()`
}

/// A runner that counts the quantity of each given fruit.
class CountFruit extends Runner<CountFruitParams, Failure, CountFruitResult> {
  @override
  Future<Either<Failure, CountFruitResult>> onCall(
    CountFruitParams params,
  ) async {
    if (params.fruits.isEmpty) {
      // When the given fruits is empty, then a left value is returned
      return const Left(Failure('There are no fruits to count'));
    }

    final fruitCount = <String, int>{};

    for (final fruit in params.fruits) {
      fruitCount[fruit] = (fruitCount[fruit] ?? 0) + 1;
    }

    // Returns a right value containing the fruit count
    final result = CountFruitResult(fruitCount);
    return Right(result);
  }
}

/// A special parameter for [CountFruit] containing all the available fruits '
/// 'to count.
class CountFruitParams {
  const CountFruitParams(this.fruits);

  final List<String> fruits;
}

/// The right value for [CountFruit] containing the count for each fruit.
class CountFruitResult {
  const CountFruitResult(this.fruitCount);

  final Map<String, int> fruitCount;

  @override
  String toString() => '$fruitCount';
}
