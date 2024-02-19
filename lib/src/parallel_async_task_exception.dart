/// An exception that is thrown when a parallel async task fails.
/// Provides the task that failed, the error and the stack trace.
class ParallelAsyncTaskException<T> implements Exception {
  final T task;
  final Object error;
  final StackTrace stackTrace;

  const ParallelAsyncTaskException({
    required this.task,
    required this.error,
    required this.stackTrace,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParallelAsyncTaskException<T> &&
        other.task == task &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => task.hashCode ^ error.hashCode ^ stackTrace.hashCode;

  @override
  String toString() =>
      'ParallelAsyncTaskException(task: $task, error: $error, stackTrace: $stackTrace)';
}
