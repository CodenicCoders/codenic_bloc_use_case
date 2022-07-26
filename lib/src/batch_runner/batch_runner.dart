import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:codenic_bloc_use_case/src/base.dart';
import 'package:codenic_bloc_use_case/src/util/ensure_async.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

part 'batch_run_result.dart';
part 'batch_runner_state.dart';
part 'use_case_factory.dart';

/// {@template BatchRunner}
///
/// A use case for executing multiple use cases by batch and emitting its state
/// via a [Cubit].
///
/// This makes use of a [UseCaseFactory] to initialize and call the associated
/// use cases. Since [UseCaseFactory] loads use cases lazily, the use case will
/// only be initialized when it is called.
///
/// [P1] is the parameter passed to the [UseCaseFactory.call] callback to
/// create or return an existing use case.
///
/// [P2] is the parameter passed to the [onCall] callback for executing the
/// `call` method of each use case.
///
/// {@endtemplate}
class BatchRunner<P1, P2> extends DistinctCubit<BatchRunnerState> {
  /// {@macro BatchRunner}
  ///
  /// The first dimension of the [useCaseFactories] defines the use case batch,
  /// whereas the second dimension is the list of all its use cases it manages.
  BatchRunner({
    required this.useCaseConstructorParams,
    required Iterable<
            Iterable<
                UseCaseFactory<P1, P2, BaseUseCase<dynamic, dynamic, dynamic>>>>
        useCaseFactories,
  })  : useCaseFactories = UnmodifiableListView(
          useCaseFactories
              .map((e) => UnmodifiableListView(e.toList()))
              .toList(),
        ),
        super(const BatchRunnerInitial(DistinctCubit.initialActionToken));

  /// The parameter used to initialize the use case of [useCaseFactories].
  final P1 useCaseConstructorParams;

  /// A 2-Dimensional list of use case factories for creating and executing the
  /// use cases by batch.
  ///
  /// The first dimension defines the use case batch, whereas the second
  /// dimension is the list of all its use cases.
  final UnmodifiableListView<
          UnmodifiableListView<
              UseCaseFactory<P1, P2, BaseUseCase<dynamic, dynamic, dynamic>>>>
      useCaseFactories;

  /// {@template BatchRunner.batchRunResult}
  ///
  /// The output of a [batchRun] call.
  ///
  /// {@endtemplate}
  BatchRunResult? _batchRunResult;

  /// {@macro batchRunResult}
  BatchRunResult? get batchRunResult => _batchRunResult;

  /// The callback triggered when [batchRun] is called.
  @protected
  Future<Either<BatchRunResult, BatchRunResult>> onCall(
    P2 params,
  ) async {
    for (final useCaseFactoryGroup in useCaseFactories) {
      final results = await Future.wait(
        useCaseFactoryGroup
            .map((e) => e.call(useCaseConstructorParams, params)),
      );

      for (final result in results) {
        if (result.isLeft()) {
          return Left(_createBatchRunResult());
        }
      }
    }

    return Right(_createBatchRunResult());
  }

  BatchRunResult _createBatchRunResult() => BatchRunResult(
        useCaseFactories
            .expand((e) => e)
            .where((e) => e.useCase?.value != null)
            .map((e) => e.useCase!)
            .toList(),
      );

  /// Runs all the use cases in a batched manner.
  ///
  /// If the [useCaseFactories] are direct instances of [UseCaseFactory], then
  /// use cases that have succeeded will no longer be executed.
  ///
  /// This will initially emit a [BatchRunning] state followed either by a
  /// [BatchRunFailed] or [BatchRunSuccess].
  Future<void> batchRun({required P2 params}) async {
    final actionToken = requestNewActionToken();

    await ensureAsync();

    if (distinctEmit(actionToken, () => BatchRunning(actionToken)) == null) {
      return;
    }

    final result = await onCall(params);

    distinctEmit(
      actionToken,
      () => result.fold(
        (l) => BatchRunFailed(_batchRunResult = l, actionToken),
        (r) => BatchRunSuccess(_batchRunResult = r, actionToken),
      ),
    );
  }

  /// Clears all the data including the use cases then emits a
  /// [BatchRunnerInitial].
  Future<void> reset() async {
    final actionToken = requestNewActionToken();

    await ensureAsync();

    distinctEmit(
      actionToken,
      () {
        for (final useCaseFactoryGroup in useCaseFactories) {
          for (final useCaseFactory in useCaseFactoryGroup) {
            useCaseFactory.reset();
          }
        }

        _batchRunResult = null;

        return BatchRunnerInitial(actionToken);
      },
    );
  }
}
