import 'package:codenic_bloc_use_case/src/base.dart';
import 'package:codenic_bloc_use_case/src/util/ensure_async.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'runner_state.dart';

/// {@template Runner}
///
/// An abstract use case for executing tasks asynchronously via a cubit which
/// accepts a [P] parameter and emits either an [L] failed value or an [R]
/// success value.
///
/// {@endtemplate}
abstract class Runner<P, L, R> extends DistinctCubit<RunnerState>
    with BaseUseCase<P, L, R> {
  /// {@macro Runner}
  Runner() : super(const RunnerInitial(DistinctCubit.initialActionToken));

  /// The latest value emitted by calling [run] which can either reference the
  /// [leftValue] or the [rightValue].
  ///
  /// This can be used to determine which is latest among the two values.
  ///
  /// If [run] has not been called even once, then this is `null`.
  @override
  Either<L, R>? get value => super.value;

  /// {@template leftValue}
  ///
  /// The last error value emitted by calling [run].
  ///
  /// If [run] has not failed even once, then this is `null`.
  ///
  /// {@endtemplate}
  @override
  L? get leftValue => super.leftValue;

  /// {@template rightValue}
  ///
  /// The last success value emitted by calling [run].
  ///
  /// If [run] has not succeeded even once, then this is `null`.
  ///
  /// {@endtemplate}
  @override
  R? get rightValue => super.rightValue;

  /// The use case action callback called on [run].
  @protected
  @override
  Future<Either<L, R>> onCall(P params);

  /// Executes the [onCall] use case action.
  ///
  /// This will initially emit a [Running] state followed either by a
  /// [RunFailed] or [RunSuccess].
  Future<void> run({required P params}) async {
    final actionToken = requestNewActionToken();

    await ensureAsync();

    if (distinctEmit(
          actionToken,
          () => Running(actionToken),
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
          (l) => RunFailed(l, actionToken),
          (r) => RunSuccess(r, actionToken),
        );
      },
    );
  }

  /// Clears all the data then emits a [RunnerInitial].
  @override
  Future<void> reset() async {
    final actionToken = requestNewActionToken();

    await ensureAsync();

    distinctEmit(
      actionToken,
      () {
        super.reset();
        return RunnerInitial(actionToken);
      },
    );
  }
}
