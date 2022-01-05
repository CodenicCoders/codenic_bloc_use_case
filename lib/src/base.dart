import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';

/// A class for the core functionalities of a use case.
///
/// A use case represents a specific action within a system.
///
/// The [call] method represents the use case action which accepts a [P]
/// parameter which either outputs an [L] error value or an [R] success value.
abstract class BaseUseCase<P, L, R> {
  /// {@template value}
  ///
  /// The latest value which can either reference the [leftValue] or the
  /// [rightValue].
  ///
  /// This can be used to determine which is latest among the two values.
  ///
  /// {@endtemplate}
  Either<L, R>? _value;

  /// {@macro value}
  Either<L, R>? get value => _value;

  @protected
  set value(Either<L, R>? newValue) {
    _value = newValue;
    newValue?.fold((l) => _leftValue = l, (r) => _rightValue = r);
  }

  /// {@template leftValue}
  ///
  /// The last error value.
  ///
  /// {@endtemplate}
  L? _leftValue;

  /// {@macro  leftValue}
  L? get leftValue => _leftValue;

  /// {@template rightValue}
  ///
  /// The last success value.
  ///
  /// {@endtemplate}
  R? _rightValue;

  /// {@macro rightValue}
  R? get rightValue => _rightValue;

  /// The use case action callback.
  @protected
  Future<Either<L, R>> onCall(P params);

  /// Executes the use case action and assigns a new [value] once completed.
  Future<Either<L, R>> call(P params) async {
    value = await onCall(params);
    return value!;
  }

  /// Clears all the data.
  void reset() {
    _leftValue = null;
    _rightValue = null;
    _value = null;
  }
}

/// {@template DistinctCubit}
///
/// A [Cubit] that enables [state] emission from one method call at a time.
///
/// If multiple state-emitting method calls are running at the same time, then
/// this can prevent old method calls from emitting states in favor of the
/// new method call states.
///
/// {@endtemplate}
abstract class DistinctCubit<S> extends Cubit<S> {
  /// {@macro DistinctCubit}
  DistinctCubit(S initialState) : super(initialState);

  /// The initial action token.
  ///
  /// {@template actionToken}
  ///
  /// An action token identifies a method call that can emit states. The
  /// generated token is used in conjunction with [distinctEmit] to ensure that
  /// a method call can only emit states as long as their action token is not
  /// stale.
  ///
  /// {@endtemplate}
  static const initialActionToken = 0;

  /// The active action token.
  ///
  /// {@macro actionToken}
  int _activeActionToken = initialActionToken;

  /// Generates a new action token.
  ///
  /// This must be called within a method that can emit states to generate
  /// their unique action token.
  ///
  /// {@macro actionToken}
  @protected
  int requestNewActionToken() => ++_activeActionToken;

  /// Updates the Cubit's state based on the [stateCallback].
  ///
  /// If the [actionToken] is not equal to the active action token, then
  /// [stateCallback] will not be called and `null` will be returned.
  /// Otherwise, if `true`, then the state from [stateCallback] will be emitted
  /// and returned.
  ///
  /// This does nothing if:
  /// - the [actionToken] is stale.
  /// - the state being emitted is equal to the current state.
  ///
  /// To allow for the possibility of notifying listeners of the initial state,
  /// emitting a state which is equal to the initial state is allowed as long
  /// as it is the first thing emitted by the instance.
  ///
  /// * Throws a [StateError] if the bloc is closed.
  @protected
  S? distinctEmit(int actionToken, S Function() stateCallback) {
    if (actionToken != _activeActionToken) {
      return null;
    }

    final state = stateCallback();

    emit(state);

    return state;
  }

  /// Do not use directly. Instead, use [distinctEmit].
  @override
  void emit(S state) => super.emit(state);
}
