# Swift Concurrency 中的 Task

在 Swift Concurrency 模型中，`Task` 是执行异步操作的基本单位。你可以把它想象成一个轻量级的“线程”或者一个异步工作的上下文环境。所有 `async` 函数都必须在某个 `Task` 内部被调用。

## 1. 为什么需要 `Task`？

`async/await` 语法允许我们用同步的方式编写异步代码，但这些异步代码终究需要一个地方来启动和运行。`Task` 就扮演了这个“启动器”和“管理器”的角色。

当你从一个同步的上下文（比如一个按钮的点击事件、`viewDidLoad` 或 `onAppear`）需要调用一个 `async` 函数时，你必须显式地创建一个 `Task`。

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        Button("Fetch Data") {
            // 从同步的 Button action 中，开启一个异步任务
            Task {
                await fetchData()
            }
        }
    }

    func fetchData() async {
        // 这是一个异步函数
        print("Start fetching...")
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 1_000_000_000) 
        print("Data fetched!")
    }
}
```

## 2. `Task` 的种类

### 结构化并发 (Structured Concurrency)

当你在一个 `async` 函数内部直接创建 `Task`（例如使用 `async let` 或 `TaskGroup`），这些 `Task` 会成为当前任务的“子任务”，形成一个树状的层级结构。这就是所谓的“结构化并发”。

- **生命周期绑定**：子任务的生命周期不会超过父任务。如果父任务被取消，所有子任务都会被自动取消。
- **错误传递**：子任务抛出的错误会自动向上传递给父任务。

```swift
func processImages() async throws {
    print("Start processing images.")
    // async let 创建了结构化的子任务
    async let thumbnail = downloadImage(named: "thumbnail.jpg")
    async let fullImage = downloadImage(named: "full.jpg")

    // 等待两个子任务完成
    let images = try await [thumbnail, fullImage]
    print("All images processed.")
}
```

### 非结构化任务 (Unstructured Tasks)

当你使用 `Task { ... }` 初始化器时，你创建的是一个“非结构化”的任务。它独立于任何父任务，拥有自己的生命周期。

- **独立生命周期**：即使创建它的上下文（如函数）已经返回，这个 `Task` 仍然会继续执行，直到它自己完成或被显式取消。
- **常用于“即发即忘”**：非常适合那些你只关心启动，而不关心其结果或完成时间的后台操作，比如日志上报、数据预加载等。

```swift
func uploadAnalytics() {
    // 创建一个非结构化任务来上传日志
    // 这个函数会立刻返回，不会等待上传完成
    Task {
        await api.sendAnalyticsData(log: "User tapped button.")
    }
}
```

### 分离任务 (Detached Tasks)

`Task.detached { ... }` 创建一个完全独立的顶层任务。它不会继承任何来自其创建上下文的优先级、任务局部值（Task-Local Values）或 Actor 上下文。

- **完全隔离**：适用于那些需要以完全不同的优先级或完全隔离的状态运行的任务。
- **谨慎使用**：由于它完全脱离了上下文，滥用 `Task.detached` 可能会导致难以追踪的 bug 和不合理的资源分配。在绝大多数情况下，`Task { ... }` 已经足够。

## 3. 任务的控制

- **取消任务 (`.cancel()`)**：你可以持有一个 `Task` 的实例，并在需要的时候从外部取消它。
- **检查取消状态 (`Task.checkCancellation()`)**：在耗时的循环或计算中，应定期调用 `try Task.checkCancellation()` 来响应外部的取消请求。
- **休眠 (`Task.sleep()`)**：让当前任务暂停一段时间，但**不会阻塞线程**，CPU 可以去执行其他工作。

```swift
func performLongRunningTask() async {
    let task = Task {
        for i in 0..<100 {
            // 检查任务是否已被取消
            try Task.checkCancellation()
            
            print("Processing item \(i)...")
            // 模拟耗时操作
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    // 在 0.5 秒后取消任务
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        task.cancel()
        print("Task cancelled!")
    }
}
```
