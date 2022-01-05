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
class FirstPageLoading extends PaginatorState {
  /// {@macro FirstPageLoading}
  const FirstPageLoading(int paginateToken) : super(paginateToken);
}

/// {@template FirstPageLoadFailed}
///
/// The state emitted when [Paginator.loadFirstPage] call fails.
///
/// {@endtemplate}
class FirstPageLoadFailed<L> extends PaginatorState {
  /// {@macro FirstPageLoadFailed}
  const FirstPageLoadFailed(this.leftValue, int paginateToken)
      : super(paginateToken);

  /// {@macro leftValue}
  final L leftValue;

  @override
  List<Object?> get props => super.props..add(leftValue);
}

/// {@template FirstPageLoadSuccess}
///
/// The state emitted when a [Paginator.loadFirstPage] call succeeds.
///
/// {@endtemplate}
class FirstPageLoadSuccess<T extends Object> extends PaginatorState {
  /// {@macro FirstPageLoadSuccess}
  const FirstPageLoadSuccess(this.pageResultItemList, int paginateToken)
      : super(paginateToken);

  /// {@macro pageResultItemList}
  final PageResultItemList<T, PageResult<T>> pageResultItemList;

  @override
  List<Object?> get props => super.props..add(pageResultItemList);
}

/// {@template NextPageLoading}
///
/// The initial state emitted when [Paginator.loadNextPage] is called
/// and a next page is available.
///
/// {@endtemplate}
class NextPageLoading extends PaginatorState {
  /// {@macro NextPageLoading}
  const NextPageLoading(int paginateToken) : super(paginateToken);
}

/// {@template NextPageLoadFailed}
///
/// The state emitted when [Paginator.loadNextPage] call fails.
///
/// {@endtemplate}
class NextPageLoadFailed<L> extends PaginatorState {
  /// {@macro NextPageLoadFailed}
  const NextPageLoadFailed(this.leftValue, int paginateToken)
      : super(paginateToken);

  /// {@macro leftValue}
  final L leftValue;

  @override
  List<Object?> get props => super.props..add(leftValue);
}

/// {@template NextPageLoadSuccess}
///
/// The state emitted when [Paginator.loadNextPage] succeeds and a
/// next page is still available.
///
/// {@endtemplate}
class NextPageLoadSuccess<T extends Object> extends PaginatorState {
  /// {@macro NextPageLoadSuccess}
  const NextPageLoadSuccess(this.pageResultItemList, int paginateToken)
      : super(paginateToken);

  /// {@macro pageResultItemList}
  final PageResultItemList<T, PageResult<T>> pageResultItemList;

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
