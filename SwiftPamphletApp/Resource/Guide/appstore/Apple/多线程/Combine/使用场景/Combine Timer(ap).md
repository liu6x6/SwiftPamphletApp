# Combine 中的 Timer (定时器)

在传统的 iOS 开发中，使用 \`Timer\` (原 \`NSTimer\`) 有几个非常讨厌的痛点：
1. **循环引用 (Retain Cycle)**：一不小心闭包就捕获了 \`self\` 导致内存泄漏。
2. **RunLoop 模式问题**：如果不手动将 Timer 加到 \`RunLoop.Mode.common\` 中，当用户在屏幕上滚动列表（如 TableView）时，Timer 会被系统**强行暂停**，导致倒计时卡住。

Combine 为 \`Timer\` 提供了一套完美的封装，彻底解决了上述问题，并将其融入到了声明式的管道生态中。

## 1. 基础创建：Timer.publish

要在 Combine 中创建一个定时器，最标准的写法是这样：

```swift
import Combine
import Foundation

class TimerViewModel {
    var cancellables = Set<AnyCancellable>()
    
    init() {
        // 1. 创建一个每 1 秒触发一次的 Timer 发布者
        // on: 决定了 Timer 跑在哪个线程的 RunLoop (通常是 .main 更新UI)
        // in: .common 极其重要！它保证了即使用户在狂滑屏幕，定时器也绝对不会暂停！
        let timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        
        // 2. 必须调用 .autoconnect() ! 
        // 因为 Timer 是一个 "ConnectablePublisher"，如果不调用它，流不会自己开始工作。
        timerPublisher
            .autoconnect()
            .sink { date in
                // 每次触发，它会发送当前的绝对时间 (Date)
                print("滴答，当前时间：\(date)")
            }
            .store(in: &cancellables) // 3. 完美的内存管理，类销毁时自动掐断定时器
    }
}
```

## 2. 实战：极简的验证码倒计时

结合 Combine 的操作符，实现一个“倒数 60 秒”功能变得前所未有的优雅。不需要写变量自减，不需要在闭包里手写判断。

```swift
class CountdownViewModel: ObservableObject {
    @Published var displayString = "获取验证码"
    @Published var isButtonEnabled = true
    
    private var cancellables = Set<AnyCancellable>()
    
    func startCountdown() {
        self.isButtonEnabled = false
        let totalSeconds = 60
        
        // 创建一个每秒发一次信号的 Timer
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            // 在流的前面人为加几个操作符，实现倒计时逻辑！
            // 1. 扫描 (scan)：像 reduce 一样，但每次都把中间结果发出来。每次收到滴答，初始值就减 1
            .scan(totalSeconds) { (remaining, _) in
                return remaining - 1
            }
            // 2. 截断 (prefix)：只要剩余时间大于 0，就允许流通；等于 0 时，直接发送 .finished 强行终结这个流！
            .prefix { $0 > 0 }
            // 3. 最终落脚到接收端
            .sink(
                receiveCompletion: { [weak self] _ in
                    // 流被 prefix 截断终结时，这里被调用
                    self?.displayString = "重新获取"
                    self?.isButtonEnabled = true
                },
                receiveValue: { [weak self] remaining in
                    self?.displayString = "\(remaining)s 后重发"
                }
            )
            .store(in: &cancellables)
    }
}
```
这段代码没有任何副作用（Side Effects），没有任何外部的计数变量，所有的业务逻辑像流水线一样清晰可见。

## 3. 手动控制 Timer 的启停

如果你不想让 Timer 一创建就 \`autoconnect\` 跑起来，而是想通过按钮精确控制它的启动和暂停，你必须保留它的连接引用。

```swift
// 去掉 autoconnect，它现在只是一份图纸
let stoppableTimer = Timer.publish(every: 1.0, on: .main, in: .common)

// 必须显式连接才能启动
let connection = stoppableTimer.connect()

// 当需要暂停或停止时，直接掐断这个连接
connection.cancel()
```
