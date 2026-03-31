# Scheduler：掌控 Combine 的线程调度

在处理异步任务（比如发起网络请求，然后在 UI 上显示结果）时，**线程切换**是永恒的话题。在旧时代的 GCD 中，我们使用 \`DispatchQueue.global().async\` 和 \`DispatchQueue.main.async\` 来回跳跃。

在 Combine 中，Apple 提供了一套极其优雅和声明式的线程切换机制，那就是 **Scheduler** 以及两个关键的操作符：**\`subscribe(on:)\`** 和 **\`receive(on:)\`**。

## 1. 什么是 Scheduler？

\`Scheduler\` 是一个协议，它定义了**“何时”以及“在哪里”执行一个闭包代码**。
在实际开发中，你最常接触到的两个 Scheduler 实例就是 GCD 队列的包装：
*   **\`DispatchQueue.global()\`** (后台并发调度器，用来做脏活累活)
*   **\`RunLoop.main\` 或 \`DispatchQueue.main\`** (主线程调度器，专门用来刷新 UI)

## 2. 订阅线程：subscribe(on:)

它决定了 **Publisher 开始执行生产数据任务的源头在哪个线程**。

假设你自己写了一个耗时的读取超大本地文件的 Publisher。如果你不加 \`subscribe(on:)\`，当在主线程的 ViewController 里调用 \`.sink\` 订阅它时，它就会**死死卡住主线程**去读文件，导致界面完全卡死！

```swift
let heavyTaskPublisher = Deferred {
    Future<String, Never> { promise in
        // 假设这是一段疯狂占用 CPU 的压缩算法或者大文件 I/O
        let result = doHeavyComputation() 
        promise(.success(result))
    }
}

heavyTaskPublisher
    // 核心指令：告诉 Publisher，当你收到订阅请求开始干活时，
    // 请给我滚去后台的高优先级并发队列去慢慢干，别挡着 UI 的道！
    .subscribe(on: DispatchQueue.global(qos: .userInitiated))
    .sink { print("任务完成") }
```
**注意：** 对于 \`URLSession.dataTaskPublisher\`，苹果已经在底层自动把它丢到后台线程去了，所以你通常**不需要**对网络请求写 \`subscribe(on:)\`。

## 3. 接收线程：receive(on:)

它决定了**在它之后的管道操作符和最终的 Subscriber (.sink) 将在哪个线程接收到数据并执行。**

这是你在日常开发中使用频率最高的操作符！因为网络请求或后台计算完成后，结果数据必须回到主线程（Main Thread）才能用来更新 SwiftUI 视图或 UIKit 控件。

```swift
URLSession.shared.dataTaskPublisher(for: url)
    .map { $0.data }
    // 此时数据依然在 URLSession 的后台网络线程飘荡
    
    // 关键指令：拦截数据流，将其强行切换到主线程的 RunLoop！
    .receive(on: RunLoop.main)
    
    // 从这里开始，下面所有的代码都绝对安全地运行在主线程了
    .sink(receiveCompletion: { _ in },
          receiveValue: { data in
              // 更新 UI 是绝对安全的
              self.imageView.image = UIImage(data: data)
          })
```

## 4. 黄金组合的最佳实践

在一个标准的 MVC / MVVM 架构中，一条最规范的 Combine 数据流通常长这样：

```swift
func fetchAndProcessData() {
    api.downloadLargeData() // 1. URLSession 底层自动在后台线程拉取数据
        
        // 2. 收到后台网卡的数据后，我们在指定的后台队列执行极其耗时的 JSON 解析和过滤
        .receive(on: DispatchQueue.global(qos: .userInitiated))
        .tryMap { rawData in 
            return try JSONDecoder().decode(LargeModel.self, from: rawData)
        }
        .filter { $0.isValid }
        
        // 3. 脏活累活干完了，带着最终结果，风光地回到主线程！
        .receive(on: DispatchQueue.main)
        
        // 4. 刷新界面
        .sink(receiveCompletion: { _ in },
              receiveValue: { finalModel in
                  self.tableView.reloadData()
              })
        .store(in: &cancellables)
}
```

**记住一句话：\`subscribe(on:)\` 决定了水流从哪里喷发；\`receive(on:)\` 决定了水流中途经过和最终流向哪里。**
