import 'dart:async';

/// A wrapper for an asynchronous task.
class AsyncTask<R> {
  final Future<R> Function() _task;
  final Completer<R> _completer = Completer<R>();
  final Function() _onComplete;
  final String? label;
  

  AsyncTask(this._task, {required Function() onComplete, this.label}) : _onComplete = onComplete;

  Future<R> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void run() async {
    try {
      final R result = await _task();
      _completer.complete(result);
    } catch (e) {
      _completer.completeError(e);
    } finally {
      _onComplete();
    }
  }
}