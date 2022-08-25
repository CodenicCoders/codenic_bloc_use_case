// ignore_for_file: avoid_print

part of 'main.dart';

Future<void> watcher() async {
  print(
    '\n//******************** WATCHER USE CASE SAMPLE ********************',
  );

  print('\n** INITIALIZE WATCHER **');

  // Initialize the watcher use case
  final watchFruitBasket = WatchFruitBasket();

  printWatchResults(watchFruitBasket);

  print('\n** FAILED WATCHER START **');

  // Start the watcher stream with an expected failed result
  await watchFruitBasket.watch(
    params: const WatchFruitBasketParams(maxCapacity: -1),
  );

  // View the results
  printWatchResults(watchFruitBasket);

  print('\n** SUCCESSFUL WATCHER START **');

  // Start the watcher stream with an expected failed result
  await watchFruitBasket.watch(
    params: const WatchFruitBasketParams(maxCapacity: 2),
  );

  // View the results
  printWatchResults(watchFruitBasket);

  print('\n** WATCHER ERROR EVENT **');

  // Emit an error event in the watcher
  watchFruitBasket.addFruits(['Apple', 'Orange', 'Mango']);

  await Future<void>.delayed(Duration.zero);

  // View the results
  printWatchResults(watchFruitBasket);

  print('\n** WATCHER DATA EVENT **');

  // Emit a data event in the watcher
  watchFruitBasket.addFruits(['Apple', 'Orange']);

  await Future<void>.delayed(Duration.zero);

  // View the results
  printWatchResults(watchFruitBasket);

  print('\n** WATCHER STREAM CLOSED **');

  await watchFruitBasket.closeStream();

  print('\n** RESET WATCHER **');

  // Reset the watcher use case to its initial state
  await watchFruitBasket.reset();

  // View the results
  printWatchResults(watchFruitBasket);

  print(
    '\n******************** WATCHER USE CASE SAMPLE END ********************//',
  );
}

void printWatchResults(
  Watcher<WatchFruitBasketParams, Failure, FruitBasket> watcher,
) {
  print('');

  // The last left value returned when calling `watch()`
  print('Last left value: ${watcher.leftValue}');

  // The last right value instance of `VerboseStream` returned when calling
  // `watch()`
  print('Last right value: ${watcher.rightValue}');

  // The recent value returned when calling `watch()`. This may either be a
  // `Left` object containing the `leftValue` or a `Right` object containing
  // the `rightValue`
  print('Current value: ${watcher.value}');
  print('');

  // The last error event emitted by the stream created by calling
  // `watch()`
  print('Last left event: ${watcher.leftEvent}');

  // The last data event emitted by the stream created by calling
  // `watch()`
  print('Last right event: ${watcher.rightEvent}');

  // The recent value returned by the watch-created stream. This can either
  // reference the `leftEvent` or the `rightEvent`.
  print('Current event: ${watcher.event}');

  // To set all these values back to `null`, call `reset()`
}

/// A watcher for streaming fruits that goes inside the fruit basket.
class WatchFruitBasket
    extends Watcher<WatchFruitBasketParams, Failure, FruitBasket> {
  StreamController<FruitBasket>? streamController;

  int? basketCapacity;
  List<String>? fruits;

  @override
  Future<Either<Failure, VerboseStream<Failure, FruitBasket>>> onCall(
    WatchFruitBasketParams params,
  ) async {
    if (params.maxCapacity < 1) {
      // When the basket capacity is less than 1, then a left value is returned
      return const Left(Failure('Basket capacity must be greater than 0'));
    }

    basketCapacity = params.maxCapacity;
    fruits = [];
    await streamController?.close();

    streamController = StreamController<FruitBasket>();

    // Return a right value `VerboseStream` containing the stream that will be
    // listened to and its error converter
    return Right(
      VerboseStream(
        stream: streamController!.stream,
        errorConverter: (error, stackTrace) => Failure(error.toString()),
      ),
    );
  }

  void addFruits(List<String> newFruits) {
    if (fruits == null || basketCapacity == null || streamController == null) {
      return;
    }

    if (fruits!.length + newFruits.length <= basketCapacity!) {
      fruits!.addAll(newFruits);
      streamController!.add(FruitBasket(fruits!));
    } else {
      streamController!.addError(Exception('Fruit Basket is full'));
    }
  }

  Future<void> closeStream() async => streamController?.close();

  @override
  Future<void> close() {
    streamController?.close();
    return super.close();
  }
}

class WatchFruitBasketParams {
  const WatchFruitBasketParams({required this.maxCapacity});

  final int maxCapacity;
}

class FruitBasket {
  const FruitBasket(this.fruits);

  final List<String> fruits;

  @override
  String toString() => 'FruitBasket: $fruits';
}
