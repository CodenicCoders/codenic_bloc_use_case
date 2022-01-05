import 'dart:collection';

import 'package:codenic_bloc_use_case/src/base.dart';
import 'package:codenic_bloc_use_case/src/util/ensure_async.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'page_result.dart';
part 'page_result_item_list.dart';
part 'paginator_state.dart';

/// {@template Paginator}
///
/// An abstract use case for fetching a list of [T] items in a paginated way
/// via a cubit.
///
/// This accepts a [P] parameter when loading the first page.
///
/// If an error occurs during the of the first or next page, an [L] failed
/// value will be emitted. If the page has successfully been loaded, then a
/// [PageResultItemList] containing the latest [R] [PageResult] will be emitted.
///
/// A custom [R] [PageResult] can be provided. If none, this should be set
/// to `PageResult<T>`.
///
/// {@endtemplate}
abstract class Paginator<P, L, R extends PageResult<T>, T extends Object>
    extends DistinctCubit<PaginatorState> with BaseUseCase<P, L, R> {
  /// {@macro Paginator}
  Paginator() : super(const PaginatorInitial(DistinctCubit.initialActionToken));

  /// The parameter used for fetching the first page at [loadFirstPage]
  /// which will also be used to fetch the next page at [loadNextPage].
  P? _params;

  /// {@template value}
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
  Either<L, R>? get value => super.value;

  /// {@template leftValue}
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

  /// {@template leftValue}
  ///
  /// The last [PageResult] value emitted by calling [loadFirstPage] or
  /// [loadNextPage].
  ///
  /// If [loadFirstPage] or [loadNextPage] has not successfully fetched a page
  /// even once, then this is `null`.
  ///
  /// {@endtemplate}
  @override
  R? get rightValue => super.rightValue;

  /// {@template pageResultItemList}
  ///
  /// A collection of all [R] [PageResult]s emitted by calling [loadFirstPage]
  /// and [loadNextPage] and all their merged [T] items.
  ///
  /// This collection is reset every time [loadFirstPage] is called.
  ///
  /// {@endtemplate}
  PageResultItemList<T, R>? _pageResultItemList;

  /// {@macro pageResultItemList}
  PageResultItemList<T, R>? get pageResultItemList => _pageResultItemList;

  /// The use case action callback used by [loadFirstPage] and [loadNextPage]
  /// to fetch the next page.
  ///
  /// The [previousPageResult] represents the old [PageResult] obtained from
  /// the previous page which may be used to fetch the next page.
  @protected
  @override
  Future<Either<L, R>> onCall(P params, [R? previousPageResult]);

  @override
  Future<Either<L, R>> call(P params, [R? previousPageResult]) async {
    value = await onCall(params, previousPageResult);
    return value!;
  }

  /// Loads the first page.
  ///
  /// This will initially emit a [FirstPageLoading] state followed either by a
  /// [FirstPageLoadFailed] or [FirstPageLoadSuccess].
  Future<void> loadFirstPage({required P params}) async {
    final actionToken = requestNewActionToken();

    await ensureAsync();

    if (distinctEmit(
          actionToken,
          () => FirstPageLoading(actionToken),
        ) ==
        null) {
      return;
    }

    final result = await onCall(params);

    distinctEmit(
      actionToken,
      () {
        value = result;

        return result.fold(
          (l) => FirstPageLoadFailed<L>(l, actionToken),
          (r) {
            _params = params;

            final newPageResultItemList =
                PageResultItemList<T, R>(UnmodifiableListView([r]));

            return FirstPageLoadSuccess(
              _pageResultItemList = newPageResultItemList,
              actionToken,
            );
          },
        );
      },
    );
  }

  /// Loads the next page.
  ///
  /// If the [loadFirstPage] has not been successfully called yet, then this
  /// will throw a [StateError].
  ///
  /// This will initially emit a [NextPageLoading] state. If an error occurs
  /// while a fetching the next page, then a [NextPageLoadFailed] will be
  /// emitted. Otherwise, of the next page has successfully been fetched, then
  /// either a [NextPageLoadSuccess] or [LastPageLoaded] will be emitted.
  Future<void> loadNextPage() async {
    final actionToken = requestNewActionToken();

    if (rightValue == null) {
      throw StateError(
        'Cannot load next page when first page has not been loaded yet',
      );
    }

    await ensureAsync();

    if (distinctEmit(actionToken, () {
      if (rightValue!.nextPageToken == null) {
        return LastPageLoaded(actionToken);
      }

      return NextPageLoading(actionToken);
    }) is LastPageLoaded) {
      return;
    }

    final result = await onCall(_params as P, rightValue);

    distinctEmit(
      actionToken,
      () {
        value = result;

        return result.fold(
          (l) => NextPageLoadFailed<L>(l, actionToken),
          (r) {
            final newPageResultCollection = PageResultItemList<T, R>(
              UnmodifiableListView([..._pageResultItemList!.pageResults, r]),
            );

            return NextPageLoadSuccess(
              _pageResultItemList = newPageResultCollection,
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

    distinctEmit(
      actionToken,
      () {
        super.reset();
        _pageResultItemList = null;
        return PaginatorInitial(actionToken);
      },
    );
  }
}
