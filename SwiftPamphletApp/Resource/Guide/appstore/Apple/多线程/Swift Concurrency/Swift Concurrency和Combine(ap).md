# Swift Concurrency 与 Combine 的关系与抉择

很多开发者在面对 Apple 官方推出的这两大异步框架时会感到迷茫：“既然有了 `async/await`，我是不是可以把项目里的 Combine 全删了？”

答案是否定的。这两者并不是你死我活的替代关系，而是**针对不同业务场景的互补工具**。理解它们的边界，是现代 iOS 架构设计的核心。

## 1. 核心定位对比

| 特性维度 | Swift Concurrency (`async/await`, `Task`) | Combine (`Publisher`, `Subscriber`) |
| :--- | :--- | :--- |
| **设计核心** | **控制流 (Control Flow)** 的线性化 | **数据流 (Data Stream)** 的响应式处理 |
| **擅长处理** | 离散的、一次性的异步操作 (如发一个请求并等结果) | 连续的、无休止的事件流 (如用户疯狂点击、键盘输入) |
| **数据形态** | 拿到一个结果，函数就结束了 (或者抛出错误) | 随时间推移，不断发射出多个数据、状态组合 |
| **错误处理** | 原生的 `do-catch` | 操作符中的 `catch`, `mapError` |
| **状态持有** | 本身不持有状态，依赖外部 `actor` 或类 | `CurrentValueSubject` 天生自带状态记忆 |

## 2. 应该使用 async/await 的场景

**一句话总结：只要是“做一件事情 -> 等待完成 -> 拿到唯一结果 -> 继续往下走”的线性逻辑，全部无脑改写为 `async/await`。**

*   **所有的标准网络请求**：拉取用户资料、提交表单、下载单张图片。
*   **本地文件读写与数据库查询**：读取 CoreData、解码巨大 JSON。
*   **按顺序执行的异步链**：先登录获取 Token，拿到 Token 后再去拉取商品列表（使用 `await` 完美消灭了以前 Combine 里丑陋的 `flatMap` 嵌套）。

## 3. 必须保留 Combine 的场景

**一句话总结：涉及到“时间的魔法”、极其复杂的多个事件流动态合并时，Combine 的统治地位依然无法撼动。**

*   **UI 交互防抖与节流 (Debounce & Throttle)**：监听搜索框的持续输入，等用户停下半秒后再发请求。这是 Combine 的绝对统治区。
*   **复杂表单多维度联动校验**：使用 `Publishers.CombineLatest3($a, $b, $c)` 实时推导注册按钮是否可以点击。
*   **全局状态广播**：一个模块退出了登录，需要立刻通知五个毫不相干的其它模块清除数据。虽然可以通过 `AsyncStream` 做到，但用 `PassthroughSubject` 的 `sink` 显然更轻量更优雅。

## 4. 两者的融合 (Interoperability)

Apple 在底层为这两个框架打通了桥梁，允许你无缝地在它们之间来回穿梭。

### 绝招 1：用 await 消费 Publisher
如果你有一个只会发一次值的 Combine Publisher（比如网络请求），你可以直接用 `.values` 把它变成异步序列并 `await` 它！

```swift
let url = URL(string: "https://api.com")!
let publisher = URLSession.shared.dataTaskPublisher(for: url)

Task {
    // 魔法：直接用 await 等待 Publisher 吐出第一个元素！
    // 彻底告别 sink 和 cancellables 袋子
    if let firstResult = try? await publisher.values.first(where: { _ in true }) {
        print("拿到了数据：\(firstResult.data)")
    }
}
```

### 绝招 2：把 async 函数包装成 Publisher
如果你的旧代码全是 Combine 链式调用，但你想在中间混入一段别人写的 `async` 网络函数。你可以用 `Future` 包裹它。

```swift
func fetchNameAsync() async throws -> String { ... }

let combineStream = Deferred {
    Future<String, Error> { promise in
        // 开启一个 Task 桥接回到旧的 Combine 闭包里
        Task {
            do {
                let name = try await fetchNameAsync()
                promise(.success(name))
            } catch {
                promise(.failure(error))
            }
        }
    }
}
```

**终极架构建议**：
在现代 iOS 架构中，**ViewModel 内部的数据流转和 UI 绑定层**继续保持使用 Combine 的 `@Published` 和操作符；而 **ViewModel 向下游的 Repository / Network 层发起的单次数据获取任务**，全部重构为 `async/await`。
