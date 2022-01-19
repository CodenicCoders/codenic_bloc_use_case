// ignore_for_file: avoid_print

part of 'main.dart';

Future<void> runner() async {
  print('\n//******************** RUNNER USE CASE SAMPLE ********************');

  print('\n** INITIALIZE RUNNER **');

  // Initialize the runner use case
  final fetchFruitCount = FetchFruitCount();

  printRunResults(fetchFruitCount);

  print('\n** FAILED RUN **');

  // Execute the runner with an expected failed result
  await fetchFruitCount.run(params: 'Strawberry');

  // View the results
  printRunResults(fetchFruitCount);

  print('\n** SUCCESSFUL RUN **');

  // Execute the runner with an expected successful result
  await fetchFruitCount.run(params: 'Apple');

  // View the results
  printRunResults(fetchFruitCount);

  print('\n** RESET RUNNER **');

  // Reset the runner use case to its initial state
  await fetchFruitCount.reset();

  // View the results
  printRunResults(fetchFruitCount);

  print(
    '\n******************** RUNNER USE CASE SAMPLE END ********************//',
  );
}

void printRunResults(Runner runner) {
  print('');
  print('Last left value: ${runner.leftValue}');
  print('Last right value: ${runner.rightValue}');
  print('Current value: ${runner.value}');
}

/// A sample runner use case for fetching the number of a specific fruit in a
/// fruit basket.
class FetchFruitCount extends Runner<String, Failure, int> {
  final fruitBasket = ['Apple', 'Orange', 'Mange', 'Apple'];

  @override
  Future<Either<Failure, int>> onCall(String params) async {
    var i = 0;

    for (final fruit in fruitBasket) {
      if (fruit == params) {
        i++;
      }
    }

    if (i == 0) {
      return Left(Failure('Fruit "$params" not found'));
    }

    return Right(i);
  }
}
