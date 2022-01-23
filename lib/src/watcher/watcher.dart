import 'dart:async';

import 'package:codenic_bloc_use_case/src/base.dart';
import 'package:codenic_bloc_use_case/src/util/ensure_async.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'verbose_stream.dart';
part 'watcher_state.dart';

/// {@template Watcher}
///
/// An abstract use case for running a stream asynchronously via a cubit which
/// accepts a [P] parameter for creating the stream.
///
/// The stream is created from the obtained [R] [VerboseStream] when [watch] is
/// executed successfully. [L] is the error returned when stream creation fails.
///
/// The created stream emits either an [LE] error event or an [RE] data event.
///
/// A custom [R] [VerboseStream] can be provided. If none, then set this to
/// `VerboseStream<LE, RE>`.
///
/// {@endtemplate}
abstract class Watcher<P, L, R extends VerboseStream<LE, RE>, LE, RE>
    extends DistinctCubit<WatcherState> with BaseUseCase<P, L, R> {
  /// {@macro Watcher}
  Watcher() : super(const WatcherInitial(DistinctCubit.initialActionToken));

  StreamSubscription<RE>? _streamSubscription;

  /// The latest value emitted by calling [watch] which can either reference
  /// the [leftValue] or the [rightValue].
  ///
  /// This can be used to determine which is latest among the two values.
  ///
  /// If [watch] has not been called even once, then this is `null`.
  @override
  Either<L, R>? get value => super.value;

  /// {@template leftValue}
  ///
  /// The error emitted by the [watch] call that prevented the creation of a
  /// stream.
  ///
  /// If [watch] call has not failed even once, then this is `null`.
  ///
  /// {@endtemplate}
  @override
  L? get leftValue => super.leftValue;

  /// {@template rightValue}
  ///
  /// The [VerboseStream] returned by a successful [watch] call.
  ///
  /// If [watch] call has not succeeded even once, then this is `null`.
  ///
  /// {@endtemplate}
  @override
  R? get rightValue => super.rightValue;

  /// {@template event}
  ///
  /// The latest value emitted by the [watch]-created stream which can either
  /// reference the [leftEvent] or the [rightEvent].
  ///
  /// This can be used to determine which is latest among the two values.
  ///
  /// If [watch]-created stream has not emitted an event even once, then this
  /// is `null`.
  ///
  /// {@endtemplate}
  Either<LE, RE>? _event;

  /// {@macro event}
  Either<LE, RE>? get event => _event;

  @protected
  set event(Either<LE, RE>? newEvent) {
    _event = newEvent;
    newEvent?.fold((l) => _leftEvent = l, (r) => _rightEvent = r);
  }

  /// {@template leftEvent}
  ///
  /// The last error event emitted by the [watch]-created stream.
  ///
  /// If any of the [watch]-created stream has not emitted an error event even
  /// once, then this is `null`.
  ///
  /// {@endtemplate}
  LE? _leftEvent;

  /// {@macro errorEvent}
  LE? get leftEvent => _leftEvent;

  /// {@template rightEvent}
  ///
  /// The last data event emitted by the [watch]-created stream.
  ///
  /// If any of the [watch]-created stream has not emitted a data event even
  /// once, then this is `null`.
  ///
  /// {@endtemplate}
  RE? _rightEvent;

  /// {@macro rightEvent}
  RE? get rightEvent => _rightEvent;

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }

  /// Starts creating the stream to watch.
  ///
  /// This will initially emit a [StartWatching] state followed either by a
  /// [StartWatchFailed] or [StartWatchSuccess].
  ///
  /// Afterwards, the generated stream may emit a [WatchDataReceived] for data
  /// events, a [WatchErrorReceived] for error events, or a [WatchDone] when
  /// the stream has been closed.
  Future<void> watch({required P params, bool cancelOnError = false}) async {
    final actionToken = requestNewActionToken();

    await (_streamSubscription?.cancel() ?? ensureAsync());

    if (distinctEmit(
          actionToken,
          () => StartWatching(actionToken),
        ) ==
        null) {
      return;
    }

    final result = await onCall(params);

    distinctEmit(actionToken, () {
      value = result;

      return result.fold(
        (l) => StartWatchFailed<L>(l, actionToken),
        (r) {
          _streamSubscription = r.listen(
            (data) => distinctEmit(
              actionToken,
              () {
                event = Right(data);

                return WatchDataReceived<RE>(data, actionToken);
              },
            ),
            onError: (error) => distinctEmit(
              actionToken,
              () {
                event = Left(error);

                return WatchErrorReceived<LE>(error, actionToken);
              },
            ),
            onDone: () => distinctEmit(
              actionToken,
              () => WatchDone(actionToken),
            ),
            cancelOnError: cancelOnError,
          );

          return StartWatchSuccess(r, actionToken);
        },
      );
    });
  }

  /// Clears all the data then emits a [WatcherInitial].
  @override
  Future<void> reset() async {
    final actionToken = requestNewActionToken();

    await (_streamSubscription?.cancel() ?? ensureAsync());

    distinctEmit(
      actionToken,
      () {
        super.reset();
        _event = null;
        _leftEvent = null;
        _rightEvent = null;
        _streamSubscription = null;
        return WatcherInitial(actionToken);
      },
    );
  }
}
