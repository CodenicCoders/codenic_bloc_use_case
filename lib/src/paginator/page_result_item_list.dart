part of 'paginator.dart';

/// {@template PageResultItemList}
///
/// A list of [U] [PageResult]s and all their merged [T] items.
///
/// {@endtemplate}
class PageResultItemList<T extends Object, U extends PageResult<T>>
    extends UnmodifiableListView<T> with EquatableMixin {
  /// {@macro PageResultItemList}
  PageResultItemList(Iterable<U> pageResults)
      : pageResults = UnmodifiableListView(pageResults.toList()),
        super(
          pageResults.fold<List<T>>(
            <T>[],
            (previousValue, element) => previousValue..addAll(element.items),
          ),
        );

  /// The list of [PageResult]s.
  final UnmodifiableListView<U> pageResults;

  @override
  List<Object?> get props => [...pageResults];
}
