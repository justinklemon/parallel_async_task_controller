## 0.0.1
This library allows you to run multiple async tasks concurrently, setting a max limit that can run simultaneously. You simply add functions that return futures and it will manage them, making sure that only so many run at the same time.
## 0.0.2 
Restructured the ParallelAsyncTaskController to simply take a list of items and a function to transform them asynchrounously. Results and errors are added to a results stream, wrapped in either ParallelAsyncTaskResultWrapper or ParallelAsyncTaskException respectively. (Exceptions are added as errors)
