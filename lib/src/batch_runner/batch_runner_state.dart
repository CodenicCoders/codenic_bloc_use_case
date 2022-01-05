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
  const BatchRunnerInitial(int batchRunToken) : super(batchRunToken);
}

/// {@template BatchRunning}
///
/// The initial state emitted when [BatchRunner.batchRun] is called.
///
/// {@endtemplate}
class BatchRunning extends BatchRunnerState {
  /// {@macro BatchRunning}
  const BatchRunning(int batchRunToken) : super(batchRunToken);
}

/// {@template BatchRunFailed}
///
/// The state emitted when [BatchRunner.batchRun] call fails.
///
/// {@endtemplate}
class BatchRunFailed<L, R> extends BatchRunnerState {
  /// {@macro BatchRunFailed}
  BatchRunFailed(this.leftValue, int batchRunToken) : super(batchRunToken);

  /// {@macro BatchRunFailed}
  final BatchRunResult<L, R> leftValue;

  @override
  List<Object?> get props => super.props..add(leftValue);
}

/// {@template BatchRunCompleted}
///
/// The state emitted when a [BatchRunner.batchRun] call succeeds.
///
/// {@endtemplate}
class BatchRunCompleted<L, R> extends BatchRunnerState {
  /// {@macro BatchRunCompleted}
  BatchRunCompleted(this.rightValue, int batchRunToken) : super(batchRunToken);

  /// {@macro rightValue}
  final BatchRunResult<L, R> rightValue;

  @override
  List<Object?> get props => super.props..add(rightValue);
}
