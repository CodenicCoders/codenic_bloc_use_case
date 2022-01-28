part of 'batch_runner.dart';

/// {@template BatchRunResult}
///
/// An object output of [BatchRunner] containing all its executed
/// [BaseUseCase]s.
///
/// {@endtemplate}
class BatchRunResult with EquatableMixin {
  /// {@macro BatchRunResult}
  BatchRunResult(Iterable<BaseUseCase<dynamic, dynamic, dynamic>> useCases)
      : _useCases = useCases.toList();

  final List<BaseUseCase<dynamic, dynamic, dynamic>> _useCases;

  /// Returns all executed use cases whether failed or successful.
  ///
  /// Because [BatchRunner] lazily initializes the use cases when possible, if
  /// a given use case has not been executed yet or its `value` is `null`,
  /// then it will not be included in the list.
  List<BaseUseCase<dynamic, dynamic, dynamic>> get useCases =>
      _useCases.where((e) => e.value != null).toList();

  /// Returns a list of all failed use cases.
  List<BaseUseCase<dynamic, dynamic, dynamic>> leftUseCases() =>
      useCases.where((useCase) => useCase.value?.isLeft() ?? false).toList();

  /// Returns a list of all successfully executed use cases.
  List<BaseUseCase<dynamic, dynamic, dynamic>> rightUseCases() =>
      useCases.where((useCase) => useCase.value?.isRight() ?? false).toList();

  /// Returns a list of all failed values of [leftUseCases].
  List<L> leftValues<L>() => leftUseCases()
      .where((e) => e.leftValue is L)
      .map((e) => e.leftValue as L)
      .toList();

  /// Returns a list of all success values of [rightUseCases].
  List<R> rightValues<R>() => rightUseCases()
      .where((e) => e.rightValue is R)
      .map((e) => e.rightValue as R)
      .toList();

  /// Returns the specific [T] use case.
  ///
  /// If the specified use case is not found, then `null` is returned.
  T? call<T extends BaseUseCase<dynamic, dynamic, dynamic>>() => useCases
      .whereType<BaseUseCase<dynamic, dynamic, dynamic>?>()
      .firstWhere((element) => element is T, orElse: () => null) as T?;

  @override
  List<Object?> get props => [..._useCases];
}
