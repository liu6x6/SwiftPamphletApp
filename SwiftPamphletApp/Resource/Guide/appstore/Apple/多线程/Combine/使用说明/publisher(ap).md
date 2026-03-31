# Publisher：Combine 的事件发送源

在 Combine 框架中，**\`Publisher\` (发布者)** 是整个响应式数据流的起点。它的核心职责是：**向一个或多个订阅者 (Subscribers) 随时间发送一连串的值。**

## 1. Publisher 的协议定义

要理解 Publisher，我们需要看它在底层是如何定义的。它有两个极其重要的**关联类型 (Associated Types)**：

```swift
public protocol Publisher {
    // 1. 它能发出什么类型的数据？(比如 String, Int, User模型)
    associatedtype Output

    // 2. 它在失败时会抛出什么类型的错误？
    // 如果这个 Publisher 永远不会失败，这个类型就是 Never
    associatedtype Failure : Error

    // 3. 接受订阅的方法
    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
}
```
*注意：只有当订阅者 (Subscriber) 要求的接收类型和错误类型，与发布者完全一致时，它们才能成功建立连接。*

## 2. 获取 Publisher 的常见方式

在实际开发中，我们很少需要自己从头实现一个 \`Publisher\` 协议。Apple 在各种 Foundation 框架中已经为我们内置了大量的 Publisher。

### A. 属性监听：@Published (最常用)
在 SwiftUI 的 \`ObservableObject\` 中，通过给属性加上 \`@Published\`，它就自动变成了一个 Publisher。
```swift
class UserViewModel: ObservableObject {
    @Published var username: String = ""
    
    func setupBinding() {
        // 使用 $ 符号获取底层的 Publisher
        $username.sink { newName in
            print("名字变成了: \(newName)")
        }
    }
}
```

### B. URLSession (网络请求)
网络请求天然就是一个异步事件，它发出一个 \`Data\` 或者一个 \`URLError\`。
```swift
let url = URL(string: "https://api.github.com")!
// dataTaskPublisher 自动返回一个 Publisher<(data: Data, response: URLResponse), URLError>
let publisher = URLSession.shared.dataTaskPublisher(for: url)
```

### C. NotificationCenter (通知中心)
你可以把系统的通知直接变成一个数据流。
```swift
let notifPublisher = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
```

### D. Timer (定时器)
创建一个每秒触发一次的 Publisher。
```swift
let timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
```

## 3. Publisher 的生命周期 (规则)

一个 \`Publisher\` 与 \`Subscriber\` 建立联系后，必须严格遵守以下发送规则：

1.  **无限次的值 (Value)**：Publisher 可以发送任意数量（0个、1个或无限个）的 \`Output\` 值给订阅者。
2.  **一次完成 (Completion)**：一旦 Publisher 发送了一个 \`.finished\`（正常结束）或者 \`.failure(Error)\`（发生错误），这个生命周期就**彻底终止**了。
3.  **终止后不可复活**：一旦终止，Publisher 绝对不能再发送任何新的值或完成信号。

**举个例子**：
网络请求（URLSession）的 Publisher：发出 **1个值** (Data) -> 马上发出 **结束信号**。
定时器（Timer）的 Publisher：发出 **无数个值** (Date) -> 永远**不会发出结束信号** (除非你手动 \`cancel\`)。
