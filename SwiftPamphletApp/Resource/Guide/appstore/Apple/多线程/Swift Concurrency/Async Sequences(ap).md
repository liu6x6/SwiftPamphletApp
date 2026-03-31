# AsyncSequence (异步序列)

在理解了 `async/await` 处理单次网络请求之后，一个自然的问题诞生了：**如果我想处理一连串源源不断到来的异步数据（比如每秒跳一次的倒计时、持续下载的字节流），该怎么办？**

在 Combine 中，我们用 `Publisher` 解决这个问题。而在 Swift 现代并发模型中，我们用的是 **`AsyncSequence`** 协议。

## 1. 什么是 AsyncSequence？

你可以把它理解为一个普通的 Swift 数组（`Sequence`），只不过它的元素并不是已经存在于内存中的，而是**随时间推移、在未来的某个异步时刻才会被“生产”出来的**。

## 2. 消费异步序列：for try await

由于序列里的下一个元素可能需要你等几秒钟才能拿到，因此遍历这种序列不能用普通的 `for...in`，而必须加上强大的挂起魔法：**`for await`**。

### 实战：读取大文件或网络流数据
在 iOS 15+ 的 Foundation 框架中，`URL` 被扩展出了一项名为 `lines` 的超级能力。它是一个异步序列，允许你从网络或磁盘以极其微小的内存占用，**一行一行地**读取巨型文本文件！

```swift
import Foundation

func readHugeFileLines() async throws {
    let url = URL(string: "https://example.com/huge-log-file.txt")!
    
    // url.lines 就是一个 AsyncSequence。
    // 每次循环，代码都会在 await 这里挂起，直到网卡接收并解析完下一行文本。
    for try await line in url.lines {
        // 你拿到了一行数据，但整个上百兆的文件并没有被全加载进内存！
        print("读取到一行: \(line)")
        
        // 发现目标，可以直接跳出循环，底层会自动断开网络连接！
        if line.contains("ERROR") {
            print("找到错误日志，终止读取")
            break
        }
    }
}
```

## 3. 通知中心 (NotificationCenter) 的现代变体

在 Combine 中，我们用 `.publisher(for:)` 监听通知。
在 Swift Concurrency 中，我们有对应的异步序列：`.notifications(named:)`！

```swift
func listenForKeyboard() async {
    let center = NotificationCenter.default
    // 这是一个无尽的异步序列
    let keyboardStream = center.notifications(named: UIResponder.keyboardWillShowNotification)
    
    // 这个 for 循环会永远阻塞在这里监听，直到包含这个 Task 的任务被取消
    for await notification in keyboardStream {
        print("键盘弹出了！userInfo: \(notification.userInfo ?? [:])")
    }
}
```

## 4. 高阶函数操作 (Filter, Map)

因为它是 Sequence 的亲戚，所以 `AsyncSequence` 完美支持像数组一样的链式高阶函数调用，极大简化了过滤和转换逻辑！

```swift
func processStream() async {
    let center = NotificationCenter.default
    
    let filteredStream = center.notifications(named: .myCustomEvent)
        // 只有带有特定参数的通知才允许通行
        .filter { ($0.userInfo?["isValid"] as? Bool) == true }
        // 将臃肿的通知对象映射为纯粹的 String
        .compactMap { $0.userInfo?["message"] as? String }
    
    // 直接遍历提纯过后的流
    for await message in filteredStream {
        print(message)
    }
}
```

## 5. 自己创造异步序列：AsyncStream

如果你不想只用系统提供的异步序列，想自己创造一个“倒计时流”或者封装旧的闭包 API，你可以使用 `AsyncStream`。

```swift
func createCountdown() -> AsyncStream<Int> {
    // 创建一个产出 Int 的异步流
    return AsyncStream { continuation in
        Task {
            for i in (1...5).reversed() {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                // 像外界发射数据
                continuation.yield(i)
            }
            // 发射结束信号，for await 循环会随之终止
            continuation.finish()
        }
    }
}

// 在外部使用
Task {
    for await number in createCountdown() {
        print(number) // 5...4...3...2...1
    }
    print("倒计时结束！")
}
```
