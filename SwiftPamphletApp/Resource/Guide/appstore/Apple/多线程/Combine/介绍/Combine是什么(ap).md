# Combine 框架是什么？

**Combine** 是 Apple 在 WWDC 2019 推出的原生**函数式响应式编程（FRP）**框架。它的核心目标是：提供一个声明式的 Swift API，用于随时间处理值的变化。

如果用一句话来概括：**Combine 就是 Apple 官方打造的 RxSwift 替代品。**

## 1. 为什么需要 Combine？

在没有 Combine 之前，iOS 开发者处理异步事件（如网络请求完成、按钮被点击、定时器触发、通知中心的广播）的方式五花八门：
1. Target-Action (目标-动作)
2. NotificationCenter (通知中心)
3. Delegation (代理协议)
4. Closures/Callbacks (闭包回调)
5. KVO (键值观察)

这种**碎片化**的异步处理模型会导致代码逻辑分散（俗称“回调地狱”或“意大利面条代码”），难以维护和追踪状态的改变。

**Combine 提供了一种统一的接口 (Publishers & Subscribers)**，把上述所有的异步事件，全部抽象为一条条“会随着时间不断流出数据的管道”。你可以用统一的语法去监听网络、监听按钮、监听 KVO。

## 2. Combine 的三大核心概念

理解 Combine，只需要理解这三个词：

### 1. Publisher (发布者)
它是数据的源头。它声明了它会发送什么类型的值（Output），以及它可能会报什么类型的错（Failure）。
*   *比喻*：它就像是一个电视台，负责不断地播出节目。

### 2. Subscriber (订阅者)
它是数据的终点。它负责接收 Publisher 发出的数据，并根据数据更新 UI 或执行逻辑。
*   *比喻*：它就像是你家里的电视机，接收电视台的信号并显示出来。

### 3. Operator (操作符)
它是连接 Publisher 和 Subscriber 中间的管道加工厂。在数据真正到达订阅者之前，你可以使用操作符对数据进行过滤、转换、合并、延迟等操作。
*   *比喻*：它就像是电视机顶盒里的去广告插件、或者画面色彩增强芯片。

## 3. Combine 与 SwiftUI 的绝佳搭配

Combine 和 SwiftUI 是天生一对。SwiftUI 负责声明界面的长相，而 Combine 负责声明驱动界面的数据流。

当你使用 \`@StateObject\` 或 \`@ObservedObject\` 时，底层的 \`ObservableObject\` 协议实际上就是在使用 Combine 的 \`objectWillChange\` Publisher 来通知 SwiftUI 视图需要重新渲染。

## 4. Combine 的现状与未来 (与 Swift Concurrency)

在 WWDC 2021 中，Apple 推出了语言级别的 **Swift Concurrency (async / await)**。
很多初学者会问：“既然有了 async/await，Combine 是不是死掉了？”

**答案是：没有，但定位发生了变化。**
*   **单次异步操作**（比如：发起一个网络请求并拿到结果）：**应该优先使用 \`async/await\`**。它比 Combine 更简单、更符合人类直觉。
*   **连续的事件流**（比如：监听用户的搜索框输入并实施防抖 (Debounce)、监听不断跳动的股票价格）：**依然是 Combine 的强项**。虽然 Swift 的 \`AsyncStream\` 也能处理流，但在复杂的流组合、多重过滤、节流防抖等场景下，Combine 丰富的 Operators（操作符）生态仍然不可替代。
