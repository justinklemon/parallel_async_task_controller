library parallel_async_task_controller;

import 'dart:collection';
import 'dart:async';

import 'src/async_task.dart';

/// A controller for running multiple asynchronous tasks concurrently.
/// Only a limited number of tasks can run at the same time.
class ParallelAsyncTaskController<R> {
  int _concurrentLimit;
  final Queue<AsyncTask<R>> _taskQueue = Queue();
  final List<AsyncTask<R>> _currentTasks = [];

  ParallelAsyncTaskController({required int concurrentLimit})
      : _concurrentLimit = concurrentLimit,
      assert (concurrentLimit > 0);

  /// Adds a task to the queue and starts it if possible.
  /// Returns a Future that completes with the result of the task.
  Future<R> addTask(Future<R> Function() task) {
    final taskWrapper = AsyncTask(task, onComplete: _onTaskComplete);
    _taskQueue.add(taskWrapper);
    _startTasksIfPossible();
    return taskWrapper.future;
  }

  /// Adds multiple tasks to the queue and starts them if possible.
  /// Returns a Stream that emits the results of the tasks as they complete.
  Stream<R> addTasks(List<Future<R> Function()> tasks) {
    final StreamController<R> resultsController = StreamController<R>();
    final List<AsyncTask<R>> taskWrappers = [];
    int tasksLeft = tasks.length;

    // Define a callback to handle task completion
    void addResultToStream(value, [error]) {
      if (error != null) {
        resultsController.addError(error);
      } else {
        resultsController.add(value);
      }
      if (--tasksLeft == 0) {
        resultsController.close();
      }
    }
    for (final task in tasks) {
      final taskWrapper = AsyncTask(task, onComplete: _onTaskComplete);
      taskWrappers.add(taskWrapper);
      // Handle task completion and errors
      taskWrapper.future.then((value) => addResultToStream(value),
          onError: (error) => addResultToStream(null, error));
    }
    _taskQueue.addAll(taskWrappers);
    _startTasksIfPossible();
    return resultsController.stream;
  }

  /// The maximum number of tasks that can run at the same time.
  /// If the limit is decreased, the controller will not stop running tasks that are already running, but it will not start new tasks until the number of running tasks is below the new limit.
  /// If the limit is increased, the controller will start running more tasks if possible.
  set concurrentLimit(int value) {
    _concurrentLimit = value;
    _startTasksIfPossible();
  }

  /// Starts tasks if there are less than the maximum number of running tasks and there are tasks in the queue.
  void _startTasksIfPossible() {
    while (_currentTasks.length < _concurrentLimit && _taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      _currentTasks.add(task);
      task.run();
    }
  }

  /// Removes completed tasks from the list of running tasks and starts more tasks if possible.
  void _onTaskComplete() {
    _currentTasks.removeWhere((element) => element.isCompleted);
    _startTasksIfPossible();
  }
}
