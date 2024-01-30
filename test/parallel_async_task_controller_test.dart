import 'package:flutter_test/flutter_test.dart';

import 'package:parallel_async_task_controller/parallel_async_task_controller.dart';

void main() {
  test('max concurrent tasks', () async {
    final List<int> results = [];

    final taskController = ParallelAsyncTaskController<int>(concurrentLimit: 2);
    final task1 = taskController.addTask(() async {
      await Future.delayed(const Duration(seconds: 3));
      return 1;
    });
    final task2 = taskController.addTask(() async {
      await Future.delayed(const Duration(seconds: 1));
      return 2;
    });
    final task3 = taskController.addTask(() async {
      await Future.delayed(const Duration(seconds: 1));
      return 3;
    });
    task1.then((value) => results.add(value));
    task2.then((value) => results.add(value));
    task3.then((value) => results.add(value));
    await Future.wait([task1, task2, task3]);
    expect(results, equals([2,3,1]));

  });

  test('addTasks method', () async {
    final taskController = ParallelAsyncTaskController<int>(concurrentLimit: 2);
    final tasks = [
      () async {
        await Future.delayed(const Duration(seconds: 2));
        return 1;
      },
      () async {
        await Future.delayed(const Duration(seconds: 1));
        return 2;
      },
      () async {
        await Future.delayed(const Duration(seconds: 2));
        return 3;
      },
    ];
    final taskResultsStream = taskController.addTasks(tasks);
    expect(taskResultsStream, emitsInOrder([2, 1, 3, emitsDone]));
  });

  test('addTasks method with exception', () async {
    final taskController = ParallelAsyncTaskController<int>(concurrentLimit: 2);
    final tasks = [
      () async {
        await Future.delayed(const Duration(seconds: 2));
        throw Exception('Task failed');
      },
      () async {
        await Future.delayed(const Duration(seconds: 1));
        return 2;
      },
      () async {
        await Future.delayed(const Duration(seconds: 2));
        return 3;
      },
    ];
    final taskResultsStream = taskController.addTasks(tasks);
    await Future.delayed(const Duration(seconds: 3));
    expectLater(taskResultsStream, emitsInOrder([2, emitsError(isException), 3, emitsDone]));
  });

  test('concurrentLimit must be greater than 0', () {
    expect(() => ParallelAsyncTaskController<int>(concurrentLimit: 0), throwsAssertionError);
    expect(() => ParallelAsyncTaskController<int>(concurrentLimit: -1), throwsAssertionError);
  });

  test('concurrentLimit setter', () async {
    final List<int> results = [];
    final taskController = ParallelAsyncTaskController<int>(concurrentLimit: 2);
    taskController.concurrentLimit = 1;
    final task1 = taskController.addTask(() async {
      await Future.delayed(const Duration(seconds: 3));
      return 1;
    });
    final task2 = taskController.addTask(() async {
      await Future.delayed(const Duration(seconds: 1));
      return 2;
    });
    task1.then((value) => results.add(value));
    task2.then((value) => results.add(value));
    await Future.wait([task1, task2]);
    expect(results,
        equals([1, 2])); // Since the concurrent limit is 1, task2 will start after task1 is completed
    results.clear();
    final task3 = taskController.addTask(() async {
      await Future.delayed(const Duration(seconds: 3));
      return 3;
    });
    final task4 = taskController.addTask(() async {
      await Future.delayed(const Duration(seconds: 1));
      return 4;
    });
    taskController.concurrentLimit = 2;
    task3.then((value) => results.add(value));
    task4.then((value) => results.add(value));
    await Future.wait([task3, task4]);
    expect(results, equals([4,3])); // Since we raised the concurrent limit to 2, task4 should complete before task3
  });
}
