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
part 'simple_bloc_observer.dart';
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
