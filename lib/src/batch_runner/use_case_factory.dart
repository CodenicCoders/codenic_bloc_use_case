part of 'batch_runner.dart';

/// {@template UseCaseFactory}
///
/// A factory for lazily creating a [BaseUseCase] instance and for calling its
/// [BaseUseCase.call] method.
///
/// This creates a [UC] use case that emits a [L] left value and [R] right
/// value.
///
/// [SP1] is the parameter passed to the [useCaseFactory] callback to create or
/// return an existing [UC] use case.
///
/// [SP2] is the paramater passed to the [onCall] callback for executing the
/// `call` method of the [UC] use case.
///
/// {@endtemplate}
class UseCaseFactory<L, R, SP1, SP2, UC extends BaseUseCase<dynamic, L, R>> {
  /// {@UseCaseFactory}
  UseCaseFactory({
    required this.useCaseFactory,
    required this.onCall,
  });

  /// The callback for creating or returning a [T] [BaseUseCase].
  final UC Function(SP1 constructorParams) useCaseFactory;

  /// The callback triggered when [call] is executed.
  ///
  /// This is used to execute the `call` method of the [UC] use case.
  final Future<Either<L, R>> Function(SP2 callParams, UC useCase) onCall;

  /// {@template useCase}
  ///
  /// The use case created by the [useCaseFactory].
  ///
  /// {@endtemplate}
  UC? _useCase;

  /// {@macro useCase}
  UC? get useCase => _useCase;

  /// Creates the use case if not yet created then calls its [BaseUseCase.call]
  /// method. Afterwards, it's response will be returned.
  ///
  /// If the use case has previously succeeded, then its `call` method will not
  /// be invoked and its [BaseUseCase.value] will be returned instead.
  Future<Either<L, R>> call(SP1 constructorParams, SP2 callParams) async {
    if (useCase == null) {
      _useCase = useCaseFactory(constructorParams);
      return onCall(callParams, _useCase!);
    }

    final currentValue = useCase!.value;

    if (currentValue == null || currentValue.isLeft()) {
      return onCall(callParams, _useCase!);
    }

    return currentValue;
  }

  /// Removes the created use case, if any.
  void reset() => _useCase = null;
}
