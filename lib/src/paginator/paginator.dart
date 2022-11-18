import 'dart:collection';

import 'package:codenic_bloc_use_case/src/base.dart';
import 'package:codenic_bloc_use_case/src/util/ensure_async.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

part 'page_result.dart';
part 'page_result_item_list.dart';
part 'paginator_state.dart';

/// {@template Paginator}
///
/// An abstract use case for fetching a list of [R] items in a paginated way
/// via a cubit.
///
/// This accepts a [P] parameter when loading the first page.
///
/// If an error occurs during the of the first or next page, an [L] failed
/// value will be emitted. If the page has successfully been loaded, then a
/// [PageResultItemList] containing the latest [PageResult][R] will be emitted.
///
/// {@endtemplate}
abstract class Paginator<P, L, R extends Object>
    extends DistinctCubit<PaginatorState>
    with BaseUseCase<P, L, PageResult<R>> {
  /// {@macro Paginator}
  Paginator()
      : super(
          const PaginatorInitial(DistinctCubit.initialActionToken),
        );

  static const _initialPageIndex = -1;

  int _currentPageIndex = _initialPageIndex;

  /// The index of the last page loaded.
  ///
  /// If no page is currently loaded, then this is set to `-1`.
  int get currentPageIndex => _currentPageIndex;

  /// The parameter used for fetching the first page at [loadFirstPage]
  /// which will also be used to fetch the next page at [loadNextPage].
  P? _params;

  /// {@template Paginator.value}
  ///
  /// The latest value emitted by calling [loadFirstPage] or [loadNextPage]
  /// which can either reference the [leftValue] or the [rightValue].
  ///
  /// This can be used to determine which is latest among the two values.
  ///
  /// If [loadFirstPage] or [loadNextPage]  has not been called even once, then
  /// this is `null`.
  ///
  /// {@endtemplate}
  @override
  Either<L, PageResult<R>>? get value => super.value;

  /// {@template Paginator.leftValue}
  ///
  /// The last failed value emitted by calling [loadFirstPage] or
  /// [loadNextPage].
  ///
  /// If [loadFirstPage] or [loadNextPage] has not failed even once, then this
  /// is `null`.
  ///
  /// {@endtemplate}
  @override
  L? get leftValue => super.leftValue;

  /// {@template Paginator.rightValue}
  ///
  /// The last [PageResult] value emitted by calling [loadFirstPage] or
  /// [loadNextPage].
  ///
  /// If [loadFirstPage] or [loadNextPage] has not successfully fetched a page
  /// even once, then this is `null`.
  ///
  /// {@endtemplate}
  @override
  PageResult<R>? get rightValue => super.rightValue;

  /// {@template Paginator.pageResultItemList}
  ///
  /// A collection of all [PageResult][R]s emitted by calling [loadFirstPage]
  /// and [loadNextPage] and all their merged [R] items.
  ///
  /// This collection is reset every time [loadFirstPage] is called.
  ///
  /// {@endtemplate}
  PageResultItemList<R>? _pageResultItemList;

  /// {@macro Paginator.pageResultItemList}
  PageResultItemList<R>? get pageResultItemList => _pageResultItemList;

  /// The use case action callback used by [loadFirstPage] and [loadNextPage]
  /// to fetch the next page.
  ///
  /// The [previousPageResult] represents the old [PageResult] obtained from
  /// the previous page which may be used to fetch the next page.
  @protected
  @override
  Future<Either<L, PageResult<R>>> onCall(
    P params, [
    PageResult<R>? previousPageResult,
  ]);

  @override
  Future<Either<L, PageResult<R>>> call(
    P params, [
    PageResult<R>? previousPageResult,
  ]) async {
    final value = await onCall(params, previousPageResult);

    setParamsAndValue(params, value);

    return value;
  }

  /// Loads the first page.
  ///
  /// This will initially emit a [PageLoading] state followed either by a
  /// [PageLoadFailed] or [PageLoadSuccess].
  Future<void> loadFirstPage({required P params}) async {
    final actionToken = requestNewActionToken();

    await ensureAsync();

    if (isClosed) return;

    const pageIndex = _initialPageIndex + 1;

    if (distinctEmit(
          actionToken,
          () => PageLoading(pageIndex, actionToken),
        ) ==
        null) {
      return;
    }

    final result = await onCall(params);

    if (isClosed) return;

    distinctEmit(
      actionToken,
      () {
        setParamsAndValue(params, result);

        return result.fold(
          (l) => PageLoadFailed<L>(l, pageIndex, actionToken),
          (r) {
            _params = params;
            _currentPageIndex = pageIndex;

            final newPageResultItemList =
                PageResultItemList<R>(UnmodifiableListView([r]));

            return PageLoadSuccess(
              _pageResultItemList = newPageResultItemList,
              pageIndex,
              actionToken,
            );
          },
        );
      },
    );
  }

  /// Loads the next page.
  ///
  /// If the [loadFirstPage] has not been successfully called yet or the
  /// [currentPageIndex] is equal to `-1`, then this will throw a [StateError].
  ///
  /// This will initially emit a [PageLoading] state. If an error occurs
  /// while a fetching the next page, then a [PageLoadFailed] will be
  /// emitted. Otherwise, of the next page has successfully been fetched, then
  /// either a [PageLoadSuccess] or [LastPageLoaded] will be emitted.
  Future<void> loadNextPage() async {
    final actionToken = requestNewActionToken();

    if (currentPageIndex == _initialPageIndex) {
      throw StateError(
        'Cannot load next page when first page has not been loaded yet',
      );
    }

    await ensureAsync();

    if (isClosed) return;

    final pageIndex = _currentPageIndex + 1;

    if (distinctEmit(actionToken, () {
      if (rightValue!.nextPageToken == null) {
        return LastPageLoaded(actionToken);
      }

      return PageLoading(pageIndex, actionToken);
    }) is LastPageLoaded) {
      return;
    }

    final result = await onCall(_params as P, rightValue);

    if (isClosed) return;

    distinctEmit(
      actionToken,
      () {
        setParamsAndValue(_params as P, result);

        return result.fold(
          (l) => PageLoadFailed<L>(l, pageIndex, actionToken),
          (r) {
            _currentPageIndex = pageIndex;

            final newPageResultCollection = PageResultItemList<R>(
              UnmodifiableListView([..._pageResultItemList!.pageResults, r]),
            );

            return PageLoadSuccess(
              _pageResultItemList = newPageResultCollection,
              pageIndex,
              actionToken,
            );
          },
        );
      },
    );
  }

  /// Clears all the data then emits a [PaginatorInitial].
  @override
  Future<void> reset() async {
    final actionToken = requestNewActionToken();

    await ensureAsync();

    if (isClosed) return;

    distinctEmit(
      actionToken,
      () {
        super.reset();
        _pageResultItemList = null;
        _currentPageIndex = _initialPageIndex;

        return PaginatorInitial(actionToken);
      },
    );
  }
}
