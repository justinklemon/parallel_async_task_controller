import 'dart:async';
import 'dart:collection';

import 'parallel_async_task_exception.dart';
import 'parallel_async_task_result_wrapper.dart';

class ParallelAsyncTaskController<T, R> {
  int _maxParallelTasks;
  final Queue<T> _items;
  final Future<R> Function(T) _task;
  final StreamController<ParallelAsyncTaskResultWrapper<T, R>>
      _resultsController;
  final List<ParallelAsyncTaskResultWrapper<T, R>> _cachedResults = [];
  final List<ParallelAsyncTaskException<T>> _cachedErrors = [];
  final Completer<void> _completer = Completer<void>();
  int _runningTasks = 0;
  bool _isPaused = false;
  bool _isCanceled = false;

  ParallelAsyncTaskController({
    required int maxParallelTasks,
    required List<T> items,
    required Future<R> Function(T) task,
    bool broadcast = false,
  })  : _maxParallelTasks = maxParallelTasks,
        _items = Queue.of(items),
        _task = task,
        _resultsController =
            broadcast ? StreamController.broadcast() : StreamController(),
        assert(maxParallelTasks > 0) {
    _startTasksIfPossible();
  }

  void _startTasksIfPossible() {
    if (_isPaused || _isCanceled) return;
    while (_runningTasks < _maxParallelTasks && _items.isNotEmpty) {
      final item = _items.removeFirst();
      _runningTasks++;
      _task(item).then((result) => _onTaskComplete(item, result),
          onError: (error, stackTrace) =>
              _onTaskError(item, error, stackTrace));
    }
    if (_runningTasks == 0 && _items.isEmpty) {
      _close();
    }
  }

  void _onTaskComplete(T task, R result) {
    _runningTasks--;
    if (_isPaused) {
      _cachedResults.add(
          ParallelAsyncTaskResultWrapper<T, R>(task: task, result: result));
      return;
    }
    if (_isCanceled) {
      if (_runningTasks == 0) {
        _close();
      }
      return;
    }
    _resultsController
        .add(ParallelAsyncTaskResultWrapper<T, R>(task: task, result: result));
    _startTasksIfPossible();
  }

  void _onTaskError(T task, Object error, StackTrace stackTrace) {
    print("Error: $error");
    final exception = ParallelAsyncTaskException<T>(
        task: task, error: error, stackTrace: stackTrace);
    _runningTasks--;
    if (_isPaused) {
      _cachedErrors.add(exception);
      return;
    }
    if (_isCanceled) {
      if (_runningTasks == 0) {
        _close();
      }
      return;
    }
    _resultsController.addError(exception, stackTrace);
    _startTasksIfPossible();
  }

  /// Pauses the executor. Running tasks will complete, but not be
  /// sent to the stream unless the executor is resumed.
  void pause() {
    _isPaused = true;
  }

  /// Resumes the executor. If there are cached results, they will be
  /// sent to the stream and new tasks will be started.
  /// If the executor was canceled while paused, it will not be resumed.
  void resume() {
    _isPaused = false;
    if (_isCanceled) return;
    for (final result in _cachedResults) {
      _resultsController.add(result);
    }
    for (final error in _cachedErrors) {
      _resultsController.addError(error, error.stackTrace);
    }
    _cachedResults.clear();
    _cachedErrors.clear();
    _startTasksIfPossible();
  }

  void _close() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
    if (!_resultsController.isClosed) {
      _resultsController.close();
    }
  }

  /// Cancels the executor. Running tasks will complete, but not be sent to the stream.
  /// The stream will be closed when all running tasks have completed.
  /// Returns a Future that completes when all tasks have been canceled and all running tasks have completed.
  Future<void> cancel() async {
    if (_items.isEmpty && _runningTasks == 0) {
      return;
    }
    _isCanceled = true;
    _items.clear();
    return _completer.future;
  }

  /// A Stream of results from the tasks.
  Stream<ParallelAsyncTaskResultWrapper<T,R>> get results =>
      _resultsController.stream;

  /// A Future that completes when all tasks have completed.
  /// If there are no tasks, the Future completes immediately.
  Future<void> get allTasksComplete => _completer.future;

  /// The maximum number of tasks that can run at the same time.
  /// If the limit is decreased, the controller will not stop running tasks that are already running, but it will not start new tasks until the number of running tasks is below the new limit.
  /// If the limit is increased, the controller will start running more tasks if possible.
  set maxParallelTasks(int value) {
    assert(value > 0);
    _maxParallelTasks = value;
    _startTasksIfPossible();
  }
}
