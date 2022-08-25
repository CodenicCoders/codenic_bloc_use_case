part of 'batch_runner.dart';

/// {@template BatchRunnerState}
///
/// The root class of all states emitted by [BatchRunner].
///
/// {@endtemplate}
abstract class BatchRunnerState with EquatableMixin {
  /// {@macro BatchRunnerState}
  const BatchRunnerState(this.batchRunToken);

  /// Groups states executed from a single [BatchRunner.batchRun].
  ///
  /// This also prevents old [BatchRunner.batchRun] calls from emitting states
  /// when a newer [BatchRunner.batchRun] call is running in the process.
  ///
  /// Every time [BatchRunner.batchRun] is called, this gets incremented.
  final int batchRunToken;

  @override
  List<Object?> get props => [batchRunToken];
}

/// {@template BatchRunnerInitial}
///
/// The initial state of the [BatchRunner] when [BatchRunner.batchRun] has not
/// been called yet or has been reset.
///
/// {@endtemplate}
class BatchRunnerInitial extends BatchRunnerState {
  /// {@macro BatchRunnerInitial}
  const BatchRunnerInitial(super.batchRunToken);
}

/// {@template BatchRunning}
///
/// The initial state emitted when [BatchRunner.batchRun] is called.
///
/// {@endtemplate}
class BatchRunning extends BatchRunnerState {
  /// {@macro BatchRunning}
  const BatchRunning(super.batchRunToken);
}

/// {@template BatchRunFailed}
///
/// The state emitted when [BatchRunner.batchRun] call fails.
///
/// {@endtemplate}
class BatchRunFailed extends BatchRunnerState {
  /// {@macro BatchRunFailed}
  BatchRunFailed(this.leftValue, int batchRunToken) : super(batchRunToken);

  /// {@macro BatchRunner.batchRunResult}
  final BatchRunResult leftValue;

  @override
  List<Object?> get props => super.props..add(leftValue);
}

/// {@template BatchRunCompleted}
///
/// The state emitted when a [BatchRunner.batchRun] call succeeds.
///
/// {@endtemplate}
class BatchRunSuccess extends BatchRunnerState {
  /// {@macro BatchRunCompleted}
  BatchRunSuccess(this.rightValue, int batchRunToken) : super(batchRunToken);

  /// {@macro BatchRunner.batchRunResult}
  final BatchRunResult rightValue;

  @override
  List<Object?> get props => super.props..add(rightValue);
}
