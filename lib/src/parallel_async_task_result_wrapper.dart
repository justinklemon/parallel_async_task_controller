import 'package:flutter/foundation.dart';

/// A wrapper class to hold the task and its result
@immutable
class ParallelAsyncTaskResultWrapper<T, R> {
  final T task;
  final R result;

  const ParallelAsyncTaskResultWrapper({
    required this.task,
    required this.result,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParallelAsyncTaskResultWrapper<T, R> &&
        other.task == task &&
        other.result == result;
  }

  @override
  int get hashCode => task.hashCode ^ result.hashCode;

  @override
  String toString() =>
      'ParallelAsyncTaskResultWrapper(task: $task, result: $result)';
}
