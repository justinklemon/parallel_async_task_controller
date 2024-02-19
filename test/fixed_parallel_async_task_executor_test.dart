import 'package:flutter_test/flutter_test.dart';

import 'package:parallel_async_task_controller/parallel_async_task_controller.dart';

void main() {
  group('max parallel tasks', () {
    test('tasks execute in parallel', () async {
      final Stopwatch stopwatch = Stopwatch()..start();
      final taskController = ParallelAsyncTaskController<int, String>(
        maxParallelTasks: 2,
        items: List.generate(10, (index) => index),
        task: (int value) => Future.delayed(
            Duration(milliseconds: value * 100), () => value.toString()),
      );
      await taskController.allTasksComplete;
      // Since the concurrent limit is 2, task2 will start after task1 is completed
      // The total time taken will be roughly 12.5 seconds
      expect(stopwatch.elapsed.inSeconds, greaterThanOrEqualTo(12));
      expect(stopwatch.elapsed.inSeconds, lessThan(13));
    });

    test('increase task limit', () async {
      final taskController = ParallelAsyncTaskController<int, String>(
        maxParallelTasks: 2,
        items: List.generate(10, (index) => index),
        task: (int value) {
          if (value == 3) {
            return Future.delayed(
                const Duration(milliseconds: 310), () => value.toString());
          }
          return Future.delayed(
              const Duration(milliseconds: 100), () => value.toString());
        },
      );
      taskController.maxParallelTasks = 3;
      // Since we raised the concurrent limit to 3, task3 should complete after all other tasks
      expectLater(
          taskController.results.handleError((event) {}),
          emitsInOrder([
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 0, result: '0'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 1, result: '1'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 2, result: '2'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 4, result: '4'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 5, result: '5'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 6, result: '6'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 7, result: '7'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 8, result: '8'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 9, result: '9'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 3, result: '3'),
            emitsDone,
          ])); // Since we raised the concurrent limit to 2, task4 should complete before task3
    });
    test('decrease task limit', () {
      final taskController = ParallelAsyncTaskController<int, String>(
        maxParallelTasks: 3,
        items: List.generate(10, (index) => index),
        task: (int value) {
          if (value == 3) {
            return Future.delayed(
                const Duration(milliseconds: 310), () => value.toString());
          }
          return Future.delayed(
              const Duration(milliseconds: 100), () => value.toString());
        },
      );
      taskController.maxParallelTasks = 2;
      // Since we decreased the concurrent limit to 2, task3 should complete after task 6, but before task 7
      expectLater(
          taskController.results,
          emitsInOrder([
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 0, result: '0'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 1, result: '1'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 2, result: '2'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 4, result: '4'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 5, result: '5'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 6, result: '6'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 3, result: '3'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 7, result: '7'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 8, result: '8'),
            const ParallelAsyncTaskResultWrapper<int, String>(
                task: 9, result: '9'),
            emitsDone,
          ]));
    });
  });

  test('maxParallelTasks must be greater than 0', () {
    expect(
        () => ParallelAsyncTaskController<int, String>(
              maxParallelTasks: 0,
              items: [],
              task: (int value) => Future.value(''),
            ),
        throwsAssertionError);
    expect(
        () => ParallelAsyncTaskController<int, String>(
              maxParallelTasks: -1,
              items: [],
              task: (int value) => Future.value(''),
            ),
        throwsAssertionError);
  });

  test('cancel tasks ', () async {
    final taskController = ParallelAsyncTaskController<int, String>(
      maxParallelTasks: 2,
      items: List.generate(10, (index) => index),
      task: (int value) => Future.delayed(
          Duration(milliseconds: value * 100), () => value.toString()),
    );

    await Future.delayed(const Duration(seconds: 2));
    await taskController.cancel();
    expectLater(
        taskController.results,
        emitsInOrder([
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 0, result: '0'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 1, result: '1'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 2, result: '2'),
          emitsDone,
        ]));
  });

  test('empty items complete immediately', () async {
    final taskController = ParallelAsyncTaskController<int, String>(
      maxParallelTasks: 2,
      items: [],
      task: (int value) => Future.value(''),
    );
    expectLater(taskController.allTasksComplete, completes);
  });

  test('pause and resume', () async {
    final taskController = ParallelAsyncTaskController<int, String>(
      maxParallelTasks: 2,
      items: List.generate(10, (index) => index),
      task: (int value) => Future.delayed(
          Duration(milliseconds: value * 100), () => value.toString()),
    );
    taskController.pause();
    await Future.delayed(const Duration(seconds: 2));
    taskController.resume();
    await Future.delayed(const Duration(seconds: 2));
    taskController.pause();
    await Future.delayed(const Duration(seconds: 2));
    taskController.resume();
    expectLater(
        taskController.results,
        emitsInOrder([
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 0, result: '0'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 1, result: '1'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 2, result: '2'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 3, result: '3'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 4, result: '4'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 5, result: '5'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 6, result: '6'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 7, result: '7'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 8, result: '8'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 9, result: '9'),
          emitsDone,
        ]));
  });

  test('exception in task', () async {
    final taskController = ParallelAsyncTaskController<int, String>(
      maxParallelTasks: 2,
      items: List.generate(10, (index) => index),
      task: (int value) async {
        if (value == 3) {
          await Future.delayed(const Duration(milliseconds: 10));
          throw Exception('Task 3 failed');
        }
        return Future.delayed(
            const Duration(milliseconds: 100), () => value.toString());
      },
    );
    expectLater(
        taskController.results,
        emitsInOrder([
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 0, result: '0'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 1, result: '1'),
          emitsError(predicate((error) =>
              error is ParallelAsyncTaskException<int> && error.task == 3)),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 2, result: '2'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 4, result: '4'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 5, result: '5'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 6, result: '6'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 7, result: '7'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 8, result: '8'),
          const ParallelAsyncTaskResultWrapper<int, String>(
              task: 9, result: '9'),
          emitsDone,
        ]));
  });
}