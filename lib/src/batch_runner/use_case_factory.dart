part of 'batch_runner.dart';

/// {@template UseCaseFactory}
///
/// A factory for lazily creating a [BaseUseCase] instance and for calling its
/// [BaseUseCase.call] method.
///
/// [P1] is the parameter passed to the [onInitialize] callback to create or
/// return an existing [UC] use case.
///
/// [P2] is the paramater passed to the [onCall] callback for executing the
/// `call` method of the [UC] use case.
///
/// {@endtemplate}
class UseCaseFactory<P1, P2,
    UC extends BaseUseCase<dynamic, dynamic, dynamic>> {
  /// {@UseCaseFactory}
  UseCaseFactory({
    required this.onInitialize,
    required this.onCall,
  });

  /// The callback for creating or returning a [UC] [BaseUseCase].
  final UC Function(P1 constructorParams) onInitialize;

  /// The callback triggered when [call] is executed.
  ///
  /// This is used to execute the `call` method of the [UC] use case.
  final Future<Either<dynamic, dynamic>> Function(P2 callParams, UC useCase)
      onCall;

  /// {@template useCase}
  ///
  /// The use case created by the [onInitialize].
  ///
  /// {@endtemplate}
  UC? _useCase;

  /// {@macro useCase}
  UC? get useCase => _useCase;

  @protected
  set useCase(UC? useCase) => _useCase = useCase;

  /// Creates the use case if not yet created then calls its [BaseUseCase.call]
  /// method. Afterwards, it's response will be returned.
  ///
  /// If the use case has previously succeeded, then its `call` method will not
  /// be invoked and its [BaseUseCase.value] will be returned instead.
  Future<Either<dynamic, dynamic>> call(
    P1 constructorParams,
    P2 callParams,
  ) async {
    if (useCase == null) {
      useCase = onInitialize(constructorParams);
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
