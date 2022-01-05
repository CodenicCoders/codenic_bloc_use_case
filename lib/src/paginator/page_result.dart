part of 'paginator.dart';

/// {@template PageResult}
///
/// Contains all the [T] items of a page and a [nextPageToken] for fetching the
/// next page if available.
///
/// {@endtemplate}
class PageResult<T extends Object> with EquatableMixin {
  /// {@macro PageResult}
  PageResult(Iterable<T> items, this.nextPageToken)
      : items = UnmodifiableListView(items.toList());

  /// The list of items that comes with the page result.
  final UnmodifiableListView<T> items;

  /// A token for fetching the next page.
  ///
  /// If this is `null`, then this is the last page.
  final dynamic nextPageToken;

  @override
  List<Object?> get props => [...items, nextPageToken];
}
