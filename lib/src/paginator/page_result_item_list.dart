part of 'paginator.dart';

/// {@template PageResultItemList}
///
/// A list of [PageResult][T]s and all their merged [T] items.
///
/// {@endtemplate}
class PageResultItemList<T extends Object> extends UnmodifiableListView<T>
    with EquatableMixin {
  /// {@macro PageResultItemList}
  PageResultItemList(Iterable<PageResult<T>> pageResults)
      : pageResults = UnmodifiableListView(pageResults.toList()),
        super(
          pageResults.fold<List<T>>(
            <T>[],
            (previousValue, element) => previousValue..addAll(element.items),
          ),
        );

  /// The list of [PageResult]s.
  final UnmodifiableListView<PageResult<T>> pageResults;

  @override
  List<Object?> get props => [...pageResults];

  @override
  String toString() => super.toList().toString();
}
