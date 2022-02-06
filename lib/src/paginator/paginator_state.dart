part of 'paginator.dart';

/// {@template PaginatorState}
///
/// The root class of all states emitted by [Paginator].
///
/// {@endtemplate}
abstract class PaginatorState with EquatableMixin {
  /// {@macro PaginatorState}
  const PaginatorState(this.paginateToken);

  /// Groups states executed from a single [Paginator.loadFirstPage]
  /// or [Paginator.loadNextPage] call.
  ///
  /// This also prevents old [Paginator. loadFirstPage] or
  /// [Paginator.loadNextPage] calls from emitting states when either
  /// a newer [Paginator.loadFirstPage] or
  /// [Paginator.loadNextPage] is running in the process.
  ///
  /// Every time [Paginator.loadFirstPage] or
  /// [Paginator.loadNextPage] is called, this gets incremented.
  final int paginateToken;

  @override
  List<Object?> get props => [paginateToken];
}

/// {@template PaginatorInitial}
///
/// The initial state of the [Paginator] when
/// [Paginator.loadFirstPage] has not been called yet or has been reset.
///
/// {@endtemplate}
class PaginatorInitial extends PaginatorState {
  /// {@macro PaginatorInitial}
  const PaginatorInitial(int paginateToken) : super(paginateToken);
}

/// {@template FirstPageLoading}
///
/// The initial state emitted when [Paginator.loadFirstPage] is called.
///
/// {@endtemplate}
class PageLoading extends PaginatorState {
  /// {@macro FirstPageLoading}
  const PageLoading(this.pageIndex, int paginateToken) : super(paginateToken);

  /// {@template Paginator.pageIndex}
  ///
  /// The index of the page being loaded.
  ///
  /// {@endtemplate}
  final int pageIndex;

  @override
  List<Object?> get props => super.props..add(pageIndex);
}

/// {@template FirstPageLoadFailed}
///
/// The state emitted when [Paginator.loadFirstPage] call fails.
///
/// {@endtemplate}
class PageLoadFailed<L> extends PaginatorState {
  /// {@macro FirstPageLoadFailed}
  const PageLoadFailed(this.leftValue, this.pageIndex, int paginateToken)
      : super(paginateToken);

  /// {@macro Paginator.leftValue}
  final L leftValue;

  /// {@macro Paginator.pageIndex}
  final int pageIndex;

  @override
  List<Object?> get props => super.props..add(leftValue);
}

/// {@template FirstPageLoadSuccess}
///
/// The state emitted when a [Paginator.loadFirstPage] call succeeds.
///
/// {@endtemplate}
class PageLoadSuccess<T extends Object> extends PaginatorState {
  /// {@macro FirstPageLoadSuccess}
  const PageLoadSuccess(
    this.pageResultItemList,
    this.pageIndex,
    int paginateToken,
  ) : super(paginateToken);

  /// {@macro Paginator.pageResultItemList}
  final PageResultItemList<T, PageResult<T>> pageResultItemList;

  /// {@macro Paginator.pageIndex}
  final int pageIndex;

  @override
  List<Object?> get props => super.props..add(pageResultItemList);
}

/// {@template LastPageLoaded}
///
/// The state emitted when [Paginator.loadNextPage] succeeds and the
/// last page has been loaded.
///
/// {@endtemplate}
class LastPageLoaded extends PaginatorState {
  /// {@macro LastPageLoaded}
  const LastPageLoaded(int paginateToken) : super(paginateToken);
}
