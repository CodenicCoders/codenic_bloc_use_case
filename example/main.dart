// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:codenic_bloc_use_case/codenic_bloc_use_case.dart';
import 'package:codenic_bloc_use_case/src/base.dart';

part 'batch_runner_sample.dart';
part 'failure.dart';
part 'paginator_sample.dart';
part 'runner_sample.dart';
part 'watcher_sample.dart';

/// To view the entire code example, see
/// https://github.com/CodenicCoders/codenic_bloc_use_case/tree/master/example

Future<void> main() async {
  print(
    'Enter [0] for Runner, '
    '[1] for Watcher, '
    '[2] for Paginator, '
    '[3] for Batch Runner: ',
  );

  final input = stdin.readLineSync(encoding: utf8);

  await BlocOverrides.runZoned(
    () async {
      switch (input) {
        case '0':
          await runner();
          break;
        case '1':
          await watcher();
          break;
        case '2':
          await paginator();
          break;
        case '3':
          await batchRunner();
          break;
      }
    },
    blocObserver: SimpleBlocObserver(),
  );
}

class SimpleBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    print('\nonCreate -- bloc: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print('\nonEvent -- bloc: ${bloc.runtimeType}, event: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('\nonChange -- bloc: ${bloc.runtimeType}, change: $change');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print(
      '\nonTransition -- bloc: ${bloc.runtimeType}, transition: $transition',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('\nonError -- bloc: ${bloc.runtimeType}, error: $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    print('onClose -- bloc: ${bloc.runtimeType}');
  }
}
