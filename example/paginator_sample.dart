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
    params: const PaginateFruitParams(itemsPerPage: 0),
  );

  // View the results
  printPaginateResults(paginateFruits);

  print('\n** SUCCESSFUL LOAD FIRST PAGE **');

  // Load the first page with an expected successful result
  await paginateFruits.loadFirstPage(
    params: const PaginateFruitParams(itemsPerPage: 2),
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

void printPaginateResults(Paginator paginator) {
  print('');
  print('Last left value: ${paginator.leftValue}');
  print('Last right value: ${paginator.rightValue}');
  print('Current value: ${paginator.value}');
  print(
    'Page result item list: ${paginator.pageResultItemList?.toList()}',
  );
}

/// A sample paginator use case for fetching a list of fruits in a paginated
/// manner.
class PaginateFruits
    extends Paginator<PaginateFruitParams, Failure, FruitPageResult, String> {
  static const _fruits = [
    'Apple',
    'Orange',
    'Lemon',
    'Kiwi',
  ];

  /// If `true`, then the [loadFirstPage] and [loadNextPage] will return a
  /// [Failure]. Otherwise, if `false`, then the methods will execute
  /// accordingly.
  bool testFail = false;

  @override
  Future<Either<Failure, FruitPageResult>> onCall(
    PaginateFruitParams params, [
    FruitPageResult? previousPageResult,
  ]) async {
    if (params.itemsPerPage < 1) {
      return const Left(Failure('Page item count must be greater than 0'));
    }

    if (testFail) {
      return const Left(Failure('Test fail enabled'));
    }

    final itemsPerPage = params.itemsPerPage;
    final dynamic nextPageToken = previousPageResult?.nextPageToken;

    final fruits = nextPageToken == null
        ? _fruits.take(itemsPerPage)
        : _fruits.indexOf(nextPageToken as String) + 1 + itemsPerPage <=
                _fruits.length
            ? _fruits.getRange(
                _fruits.indexOf(nextPageToken) + 1,
                _fruits.indexOf(nextPageToken) + 1 + itemsPerPage,
              )
            : <String>[];

    final newPageToken = fruits.isNotEmpty ? fruits.last : null;

    return Right(FruitPageResult(fruits, newPageToken));
  }
}

class PaginateFruitParams {
  const PaginateFruitParams({required this.itemsPerPage});

  final int itemsPerPage;
}

class FruitPageResult extends PageResult<String> {
  FruitPageResult(Iterable<String> items, dynamic nextPageToken)
      : super(items, nextPageToken);

  @override
  String toString() => items.toString();
}
