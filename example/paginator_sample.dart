// ignore_for_file: avoid_print

part of 'main.dart';

Future<void> paginator() async {
  print(
    '\n//******************** PAGINATOR USE CASE SAMPLE ********************',
  );

  print('\n** INITIALIZE PAGINATOR **');

  // Initialize the paginator use case
  final paginateFruits = PaginateFruits();

  printPaginateResults(paginateFruits);

  print('\n** FAILED LOAD FIRST PAGE **');

  // Load the first page with an expected failed result
  await paginateFruits.loadFirstPage(
    params: const PaginateFruitsParams(
      fruits: ['Apple', 'Orange', 'Kiwi', 'Lime'],
      itemsPerPage: 0,
    ),
  );

  // View the results
  printPaginateResults(paginateFruits);

  print('\n** SUCCESSFUL LOAD FIRST PAGE **');

  // Load the first page with an expected successful result
  await paginateFruits.loadFirstPage(
    params: const PaginateFruitsParams(
      fruits: ['Apple', 'Orange', 'Kiwi', 'Lime'],
      itemsPerPage: 2,
    ),
  );

  // View the results
  printPaginateResults(paginateFruits);

  print('\n** FAILED LOAD NEXT PAGE **');

  // Load the next page with an expected failed result
  paginateFruits.testFail = true;

  await paginateFruits.loadNextPage();

  // View the results
  printPaginateResults(paginateFruits);

  print('\n** SUCCESSFUL LOAD NEXT PAGE **');

  // Load the next page with an expected successful result
  paginateFruits.testFail = false;

  await paginateFruits.loadNextPage();

  // View the results
  printPaginateResults(paginateFruits);

  print('\n** SUCCESSFUL LOAD LAST PAGE **');

  // Load the last page by calling the next page

  await paginateFruits.loadNextPage();

  // View the results
  printPaginateResults(paginateFruits);

  print('\n** RESET PAGINATOR **');

  // Reset the paginator use case to its initial state
  await paginateFruits.reset();

  // View the results
  printPaginateResults(paginateFruits);

  print(
    '\n******************** PAGINATOR USE CASE SAMPLE END ********************//',
  );
}

void printPaginateResults(
  Paginator<PaginateFruitsParams, Failure, PaginateFruitsResult, String>
      paginator,
) {
  print('');

  // The last left value returned when calling `loadFirstPage()` or
  // `loadNextPage()`
  print('Last left value: ${paginator.leftValue}');

  // The last right value instance of `PageResult` returned when calling
  // `loadFirstPage()` or `loadNextPage()`
  print('Last right value: ${paginator.rightValue}');

  // The recent value returned when calling `loadFirstPage()` or
  // `loadNextPage()`. This may either be a `Left` object containing the
  // `leftValue` or a `Right` object containing the `rightValue`
  print('Current value: ${paginator.value}');

  /// Contains all the page results and an aggregate of all their items
  print(
    'Page result item list: ${paginator.pageResultItemList}',
  );

  // The index of the last page loaded
  print('Current page index: ${paginator.currentPageIndex}');

  // To set all these values back to `null`, call `reset()`
}

/// A paginator that accepts a list of fruits then returns them in a paginated
/// manner.
class PaginateFruits extends Paginator<PaginateFruitsParams, Failure,
    PaginateFruitsResult, String> {
  /// If `true`, then the [loadFirstPage] and [loadNextPage] will return a
  /// [Failure]. Otherwise, if `false`, then the methods will execute
  /// accordingly.
  bool testFail = false;

  @override
  Future<Either<Failure, PaginateFruitsResult>> onCall(
    PaginateFruitsParams params, [
    PaginateFruitsResult? previousPageResult,
  ]) async {
    if (params.itemsPerPage < 1) {
      // When the items per page is less than 1, then a left value is returned
      return const Left(Failure('Page item count must be greater than 0'));
    }

    if (testFail) {
      return const Left(Failure('Test fail enabled'));
    }

    final fruits = params.fruits;
    final itemsPerPage = params.itemsPerPage;
    final dynamic nextPageToken = previousPageResult?.nextPageToken;

    final nextFruitStartIndex =
        nextPageToken == null ? 0 : fruits.indexOf(nextPageToken as String) + 1;

    final newFruits = fruits.skip(nextFruitStartIndex).take(itemsPerPage);
    final newPageToken = newFruits.isNotEmpty ? newFruits.last : null;

    // Return a right value containing the next page of fruits
    return Right(PaginateFruitsResult(newFruits, newPageToken));
  }
}

/// A special parameter for [PaginateFruits] containing all the available
/// fruits to paginate and the number of fruits per page.
class PaginateFruitsParams {
  const PaginateFruitsParams({
    required this.fruits,
    required this.itemsPerPage,
  });

  final List<String> fruits;
  final int itemsPerPage;
}

/// The right value for [PaginateFruits] containing the next page of fruits.
class PaginateFruitsResult extends PageResult<String> {
  PaginateFruitsResult(Iterable<String> items, dynamic nextPageToken)
      : super(items, nextPageToken);

  @override
  String toString() => items.toString();
}
