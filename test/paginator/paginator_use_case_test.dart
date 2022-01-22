import 'dart:collection';

import 'package:bloc_test/bloc_test.dart';
import 'package:codenic_bloc_use_case/codenic_bloc_use_case.dart';
import 'package:codenic_bloc_use_case/src/util/ensure_async.dart';
import 'package:test/test.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

/// A dummy use case for testing the [Paginator].
///
/// A use case for loading fruits in a paginated manner.
class TestPaginateFruits
    extends Paginator<int, String, PageResult<String>, String> {
  static const _fruits = [
    'Apple',
    'Orange',
    'Lemon',
    'Kiwi',
  ];

  bool testFail = false;

  @override
  Future<Either<String, PageResult<String>>> onCall(
    int params, [
    PageResult<String>? previousPageResult,
  ]) async {
    await ensureAsync();

    if (testFail) {
      return const Left('Test failure');
    }

    if (params < 1) {
      return const Left('Page item count must be greater than 0');
    }

    final dynamic nextPageToken = previousPageResult?.nextPageToken;

    final fruits = nextPageToken == null
        ? _fruits.take(params)
        : _fruits.indexOf(nextPageToken as String) + 1 + params <=
                _fruits.length
            ? _fruits.getRange(
                _fruits.indexOf(nextPageToken) + 1,
                _fruits.indexOf(nextPageToken) + 1 + params,
              )
            : <String>[];

    final newPageToken = fruits.isNotEmpty ? fruits.last : null;

    return Right(
      PageResult(fruits, newPageToken),
    );
  }
}

void main() {
  group(
    'paginator use case',
    () {
      group(
        'load first page',
        () {
          blocTest<Paginator, PaginatorState>(
            'should return page ite vms when load first page succeeds',
            build: TestPaginateFruits.new,
            act: (paginator) => paginator.loadFirstPage(params: 2),
            expect: () => [
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should return failure value when load first page fails',
            build: TestPaginateFruits.new,
            act: (paginator) => paginator.loadFirstPage(params: 0),
            expect: () => const [
              PageLoading(0, 1),
              PageLoadFailed<String>(
                'Page item count must be greater than 0',
                0,
                1,
              ),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should not emit state from old load-first-page call when new '
            'load-first-page call is made at the same time',
            build: TestPaginateFruits.new,
            act: (paginator) async => Future.wait([
              paginator.loadFirstPage(params: 2),
              paginator.loadFirstPage(params: 2),
            ]),
            expect: () => [
              const PageLoading(0, 2),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                2,
              ),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should cancel state emission from old running load-first-page '
            'call when new load-first-page call is made',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              unawaited(paginator.loadFirstPage(params: 2));
              await Future<void>.delayed(Duration.zero);
              await paginator.loadFirstPage(params: 2);
            },
            expect: () => [
              const PageLoading(0, 1),
              const PageLoading(0, 2),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                2,
              ),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should clear previously loaded pages when load-first-page is '
            'successfully called',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.loadFirstPage(params: 2);
            },
            expect: () => [
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
              const PageLoading(0, 2),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                2,
              ),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should continue previous pagination when load-first-page '
            'fails',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.loadFirstPage(params: 0);
              await paginator.loadNextPage();
            },
            expect: () => [
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
              const PageLoading(0, 2),
              const PageLoadFailed(
                'Page item count must be greater than 0',
                0,
                2,
              ),
              const PageLoading(1, 3),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                    PageResult(
                      UnmodifiableListView(['Lemon', 'Kiwi']),
                      'Kiwi',
                    ),
                  ]),
                ),
                2,
                3,
              ),
            ],
          );
        },
      );

      group(
        'load next page',
        () {
          blocTest<Paginator, PaginatorState>(
            'should load next page when first page is loaded',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.loadNextPage();
            },
            expect: () => [
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
              const PageLoading(1, 2),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                    PageResult(
                      UnmodifiableListView(['Lemon', 'Kiwi']),
                      'Kiwi',
                    ),
                  ]),
                ),
                1,
                2,
              ),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should show error when loading next page when first page is not '
            'loaded yet',
            build: TestPaginateFruits.new,
            act: (paginator) => paginator.loadNextPage(),
            errors: () => [isA<StateError>()],
          );

          blocTest<TestPaginateFruits, PaginatorState>(
            'should return failed value when load next page fails',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              paginator.testFail = true;
              await paginator.loadNextPage();
            },
            expect: () => <PaginatorState>[
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
              const PageLoading(1, 2),
              const PageLoadFailed<String>('Test failure', 1, 2),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should inform when last page has been loaded',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.loadNextPage();
              await paginator.loadNextPage();
              await paginator.loadNextPage();
            },
            expect: () => <PaginatorState>[
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
              const PageLoading(1, 2),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                    PageResult(
                      UnmodifiableListView(['Lemon', 'Kiwi']),
                      'Kiwi',
                    ),
                  ]),
                ),
                1,
                2,
              ),
              const PageLoading(2, 3),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                    PageResult(
                      UnmodifiableListView(['Lemon', 'Kiwi']),
                      'Kiwi',
                    ),
                    PageResult(UnmodifiableListView([]), null),
                  ]),
                ),
                2,
                3,
              ),
              const LastPageLoaded(4),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should not emit state from old load-first-page call when new '
            'load-first-page call is made at the same time',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);

              await Future.wait([
                paginator.loadNextPage(),
                paginator.loadNextPage(),
              ]);
            },
            expect: () => <PaginatorState>[
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
              const PageLoading(1, 3),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                    PageResult(
                      UnmodifiableListView(['Lemon', 'Kiwi']),
                      'Kiwi',
                    ),
                  ]),
                ),
                1,
                3,
              ),
            ],
          );

          blocTest<Paginator, PaginatorState>(
            'should cancel state emission from old running load-next-page '
            'call when new load-next-page call is made',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              unawaited(paginator.loadNextPage());
              await ensureAsync();
              await paginator.loadNextPage();
            },
            expect: () => <PaginatorState>[
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
              const PageLoading(1, 2),
              const PageLoading(1, 3),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                    PageResult(
                      UnmodifiableListView(['Lemon', 'Kiwi']),
                      'Kiwi',
                    ),
                  ]),
                ),
                1,
                3,
              ),
            ],
          );
        },
      );

      group(
        'call',
        () {
          blocTest<Paginator, PaginatorState>(
            'should return page result without emitting states when call is '
            'directly triggered',
            build: TestPaginateFruits.new,
            act: (paginator) => paginator.call(1),
            verify: (paginator) => expect(paginator.value?.isRight(), true),
          );

          blocTest<Paginator, PaginatorState>(
            'should identify if last emitted value is an error value',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.loadFirstPage(params: 0);
            },
            verify: (paginator) => expect(paginator.value?.isLeft(), true),
          );

          blocTest<Paginator, PaginatorState>(
            'should clear value when reset',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.reset();
            },
            verify: (paginator) => expect(paginator.value, null),
          );
        },
      );

      group(
        'value',
        () {
          blocTest<Paginator, PaginatorState>(
            'should identify if last emitted value is a success value',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 0);
              await paginator.loadFirstPage(params: 2);
            },
            verify: (paginator) => expect(paginator.value?.isRight(), true),
          );

          blocTest<Paginator, PaginatorState>(
            'should identify if last emitted value is an error value',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.loadFirstPage(params: 0);
            },
            verify: (paginator) => expect(paginator.value?.isLeft(), true),
          );

          blocTest<Paginator, PaginatorState>(
            'should clear value when reset',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.reset();
            },
            verify: (paginator) => expect(paginator.value, null),
          );
        },
      );

      group(
        'left value',
        () {
          blocTest<Paginator, PaginatorState>(
            'should still have reference to the last error value when '
            'pagination succeeds',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.loadFirstPage(params: 0);
            },
            verify: (paginator) => expect(
              paginator.leftValue,
              'Page item count must be greater than 0',
            ),
          );

          blocTest<Paginator, PaginatorState>(
            'should clear left value when reset',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 0);
              await paginator.reset();
            },
            verify: (paginator) => expect(paginator.leftValue, null),
          );
        },
      );

      group(
        'right value',
        () {
          blocTest<Paginator, PaginatorState>(
            'should still have reference to the last success value when '
            'pagination fails',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 0);
              await paginator.loadFirstPage(params: 2);
            },
            verify: (paginator) => expect(
              paginator.rightValue,
              PageResult(
                UnmodifiableListView(['Apple', 'Orange']),
                'Orange',
              ),
            ),
          );

          blocTest<Paginator, PaginatorState>(
            'should clear right value when reset',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.reset();
            },
            verify: (paginator) => expect(paginator.rightValue, null),
          );
        },
      );

      group(
        'Current page index',
        () {
          blocTest<Paginator, PaginatorState>(
            'should set page index to initial value when reset',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.reset();
            },
            verify: (paginator) => expect(paginator.currentPageIndex, -1),
          );
        },
      );

      group(
        'page result item list',
        () {
          blocTest<Paginator, PaginatorState>(
            'should reset page result item list when first page is loaded',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.loadFirstPage(params: 2);
            },
            verify: (paginator) => expect(
              paginator.pageResultItemList,
              PageResultItemList(
                UnmodifiableListView([
                  PageResult(
                    UnmodifiableListView(['Apple', 'Orange']),
                    'Orange',
                  ),
                ]),
              ),
            ),
          );

          blocTest<Paginator, PaginatorState>(
            'should clear page result item list when reset',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.reset();
            },
            verify: (paginator) => expect(paginator.pageResultItemList, null),
          );
        },
      );

      group(
        'reset',
        () {
          blocTest<Paginator, PaginatorState>(
            'should reset paginator',
            build: TestPaginateFruits.new,
            act: (paginator) async {
              await paginator.loadFirstPage(params: 2);
              await paginator.reset();
            },
            expect: () => <PaginatorState>[
              const PageLoading(0, 1),
              PageLoadSuccess<String>(
                PageResultItemList(
                  UnmodifiableListView([
                    PageResult(
                      UnmodifiableListView(['Apple', 'Orange']),
                      'Orange',
                    ),
                  ]),
                ),
                0,
                1,
              ),
              const PaginatorInitial(2),
            ],
          );
        },
      );
    },
  );
}
