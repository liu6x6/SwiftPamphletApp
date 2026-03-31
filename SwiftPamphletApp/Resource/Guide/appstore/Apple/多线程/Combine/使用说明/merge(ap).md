# merge：百川归海的无差别合并

在 Combine 中，如果我们想把两个（或多个）Publisher 的数据合在一起，除了死板等待的 \`zip\` 和总是打包最新状态的 \`combineLatest\`，还有一种最纯粹、最无脑的合并方式：**\`merge\`**。

## 1. 核心行为准则

\`merge\` 的哲学是：**先到先得，先来后到，原汁原味。**

当你使用 \`publisherA.merge(with: publisherB)\` 时：
1.  **毫无要求**：它不需要 A 和 B 有相同的频率，也不需要谁等谁。
2.  **绝对的时序**：谁在时间线上先发射出数据，这个数据就会立刻、原封不动地被传递给下游。下游收到的数据就像是被一条拉链强行并轨一样，完全按照它们发生的时间先后顺序排列。
3.  **终止条件**：只有当 A **和** B 都发送了 \`.finished\` 之后，合并后的流才会发出最终的 \`.finished\`。

*(注意：能够合并的 Publisher，它们的 \`Output\` 和 \`Failure\` 类型必须绝对一致。)*

## 2. 基础演示

```swift
import Combine

let keyboardEvent = PassthroughSubject<String, Never>()
let mouseEvent = PassthroughSubject<String, Never>()

// 将两个输入设备的事件流并轨成一条流
let cancellable = keyboardEvent.merge(with: mouseEvent)
    .sink { event in
        print("收到系统输入: \(event)")
    }

keyboardEvent.send("按下空格")
// 输出: 收到系统输入: 按下空格

mouseEvent.send("左键点击")
// 输出: 收到系统输入: 左键点击

keyboardEvent.send("按下回车")
// 输出: 收到系统输入: 按下回车
```

## 3. 经典实战场景：统一的多入口触发器

这是 \`merge\` 最常见的用法：当你的 App 界面上有**多种不同的操作，但它们最终都会导致同一个结果（比如刷新同一个列表）**时。

假设你有一个新闻列表页面，触发刷新的条件有三个：
1. 用户点击了右上角的“刷新”按钮。
2. 用户下拉了列表触发了下拉刷新机制 (Pull to refresh)。
3. 每隔 5 分钟的后台定时器自动刷新。

如果用传统的方法，你需要写三个事件监听，然后在三个地方去调用 \`loadData()\`。用 Combine 的 \`merge\`，你可以把它们汇聚成一条干流：

```swift
class NewsViewModel {
    let pullToRefreshSubject = PassthroughSubject<Void, Never>()
    let buttonTapSubject = PassthroughSubject<Void, Never>()
    
    // 一个每 5 分钟响一次的定时器流（需把输出的 Date 转成 Void 以统一类型）
    let timerPublisher = Timer.publish(every: 300, on: .main, in: .common)
        .autoconnect()
        .map { _ in () }

    init() {
        // 使用 merge(with:with:) 把三条支流汇聚
        // 任何一个动作发生，都会顺着这根管子流下来
        pullToRefreshSubject
            .merge(with: buttonTapSubject, timerPublisher)
            // 防抖：如果用户在 1 秒内既下拉又点按钮，只放行一次，防止网络请求风暴
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: true)
            .flatMap { [weak self] _ in
                // 发起唯一的真实网络请求
                return self?.api.fetchNews() ?? Empty().eraseToAnyPublisher()
            }
            .sink { newNews in
                // 更新 UI 列表
            }
            .store(in: &cancellables)
    }
}
```
**总结**：如果你觉得 \`zip\` 太慢，\`combineLatest\` 给的元组包太啰嗦，而你只是想把相同类型的水流汇入同一根下水管，\`merge\` 是你最完美的工具。
