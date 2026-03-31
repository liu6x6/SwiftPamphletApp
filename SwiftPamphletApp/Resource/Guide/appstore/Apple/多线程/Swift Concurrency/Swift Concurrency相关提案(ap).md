# Swift Concurrency 相关重要提案 (Evolution Proposals)

Swift 语言的每一次重大演进都是通过 Swift Evolution (SE) 流程公开讨论并决定的。了解这些底层的 SE 提案，有助于你更深刻地理解为什么苹果要这么设计并发模型。

以下是构建整个 Swift Concurrency 大厦的几个绝对核心的基石提案：

## 1. 黎明破晓：SE-0296 Async/await
*   **状态**：Swift 5.5 实现
*   **核心内容**：这是整个并发模型的灵魂。它正式引入了 `async` 和 `await` 关键字。确立了“将异步函数的挂起和恢复，作为语言的一等公民特性”的设计方向，让开发者摆脱了闭包回调地狱。

## 2. 序列化未来：SE-0298 Async/Await: Sequences
*   **状态**：Swift 5.5 实现
*   **核心内容**：引入了 `AsyncSequence` 协议和 `for try await in` 循环语法。它填补了 `async/await` 只能处理“一次性返回值”的空白，使其具备了处理“源源不断到来的数据流”的能力。

## 3. 组织与生命周期：SE-0304 Structured Concurrency
*   **状态**：Swift 5.5 实现
*   **核心内容**：引入了 `Task`、`TaskGroup` 和 `async let`。该提案彻底否定了以前 GCD 中 `DispatchQueue.global().async` 这种“发射后不管（Fire-and-forget）”的野蛮模式，强制确立了并发任务的**父子树状层级关系**和**联动的取消机制**。

## 4. 终结数据竞争：SE-0306 Actors
*   **状态**：Swift 5.5 实现
*   **核心内容**：引入了全新的 `actor` 引用类型。提出了“Actor 隔离 (Actor Isolation)”概念，在编译期保证其内部的可变状态不会被多个线程同时破坏性读写。这是保障多线程内存安全的终极防线。

## 5. UI 的守护神：SE-0316 Global Actors
*   **状态**：Swift 5.5 实现
*   **核心内容**：扩展了 Actor 的概念，最著名的产物就是 `@MainActor`。它允许开发者给全局的类或函数打上标记，让编译器强制保证这些代码**绝对且仅在**主线程执行，从根本上消灭了 “Must be called on Main Thread” 的崩溃。

## 6. 类型安全传输：SE-0302 Sendable and @Sendable
*   **状态**：Swift 5.5 引入，并在 Swift 5.10 / 6.0 中强制开启严格检查
*   **核心内容**：这是目前开发者感受到**最痛苦，但也是最伟大**的提案。
    它引入了 `Sendable` 协议。它规定了：**只有遵循了 `Sendable` 的数据（比如值类型 struct，或者内部做了极强锁保护的 class），才被允许跨越并发边界（比如从一个 Actor 传给另一个 Actor，或者传进一个 Task 闭包里）**。
    如果没有这个提案，Actor 的隔离就会被传入的共享引用指针（Class Reference）轻易打破。

## 7. 走向分布式：SE-0336 Distributed Actor Isolation
*   **状态**：Swift 5.7 实现
*   **核心内容**：将 `actor` 的隔离边界从“同一台手机的不同线程”，扩展到了“同一网络下的不同服务器之间”！提出了 `distributed actor` 关键字。（详情见《Distributed Actors.md》）

*建议：当你遇到极其晦涩的编译报错（尤其是跨 actor 传递数据时的 \`Sendable\` 警告）时，去 github 的 swift-evolution 仓库搜索并阅读上述提案的 Motivation 和 Design 章节，是破局的唯一方法。*
