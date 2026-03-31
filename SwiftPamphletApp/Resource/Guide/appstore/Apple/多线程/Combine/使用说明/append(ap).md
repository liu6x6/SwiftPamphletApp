# append：在数据流的尾部拼接数据

\`append\` 是 Combine 中的一个组合操作符 (Combining Operator)。顾名思义，它的作用是**等当前的 Publisher 正常结束 (\`.finished\`) 之后，紧接着在它的尾巴上追加发送额外的数据。**

这与 \`prepend\` (在开头插入) 是一对反义词。

## 1. append 的三个变体

你可以追加三种不同形式的数据：单个值、序列（数组）、或是另一个 Publisher。

### A. 追加单个或多个固定值
在原始的序列结束后，直接发射几个你写死的常量。

```swift
import Combine

let numbers = [1, 2, 3].publisher

numbers
    .append(4, 5) // 当 3 发送完并收到 finished 后，发送 4 和 5
    .sink { print($0) }

// 输出: 1, 2, 3, 4, 5
```

### B. 追加一个序列 (Sequence)
追加一个数组或者任何遵循 Sequence 协议的集合。

```swift
let numbers = [1, 2].publisher
let moreNumbers = [3, 4, 5]

numbers
    .append(moreNumbers)
    .sink { print($0) }

// 输出: 1, 2, 3, 4, 5
```

### C. 追加另一个 Publisher (最强大)
这是最常用的场景。你可以将两个异步的任务首尾相连：**必须等任务 A 彻底完成，才开始执行任务 B。**
*注意：追加的 Publisher 的 \`Output\` 和 \`Failure\` 类型必须与原 Publisher 绝对一致。*

```swift
let taskA = PassthroughSubject<String, Never>()
let taskB = PassthroughSubject<String, Never>()

// 将 taskB 接在 taskA 的屁股后面
taskA
    .append(taskB)
    .sink(
        receiveCompletion: { print("总完成: \($0)") },
        receiveValue: { print("收到: \($0)") }
    )

taskA.send("A1")
taskA.send("A2")
taskB.send("B1") // 注意：此时任务 A 还没结束，B1 会被直接忽略或缓冲（取决于内部实现），你目前收不到！

// 核心触发点：必须宣告任务 A 彻底结束！
taskA.send(completion: .finished)

// 一旦 taskA 结束，管道立刻切换到了 taskB
taskB.send("B2")
taskB.send(completion: .finished)

/* 最终输出:
收到: A1
收到: A2
收到: B2
总完成: finished
*/
```

## 2. 关键陷阱与注意事项

**如果原 Publisher 永远不结束，append 永远不会执行！**

这是一个极其容易踩坑的地方。例如，UI 的点击事件流（如按钮的 TAP）或通知中心的 \`NotificationCenter.publisher\` 默认是**无限流（不会发送 \`.finished\`）**。

如果你写了：
```swift
buttonTapPublisher.append("Extra Tap")
```
这个 `"Extra Tap"` 永远永远都不会被发送出来。因为 \`append\` 像一个在红绿灯路口死等红灯变绿的司机，而无限流的红灯永远不会变绿。

## 3. 应用场景

\`append\` 最典型的场景是：**缓存回退与分页加载**。
例如加载一篇文章：你先从本地数据库读取一个缓存（这是一个发完即死的流），等缓存发送完毕显示在屏幕上后，立刻 \`append\` 发起一个网络请求 Publisher 获取最新内容。
