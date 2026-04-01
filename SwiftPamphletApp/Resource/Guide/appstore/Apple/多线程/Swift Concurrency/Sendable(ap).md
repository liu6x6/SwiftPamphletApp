# Sendable 协议与严格并发检查

`Sendable` 是 Swift Concurrency 中一个至关重要的标记协议。它用于向编译器保证，一个类型的实例可以被安全地在并发域（Concurrency Domains）之间传递，例如从主线程传递到一个后台 `Task`，或者在不同的 `actor` 之间共享，而不会引发数据竞争（Data Race）。

随着 Swift 6 的临近，**严格的并发检查（Strict Concurrency Checking）** 将成为默认选项，这意味着所有开发者都必须理解并正确使用 `Sendable`。

## 1. 什么是“可以安全传递”的？

一个类型要符合 `Sendable` 协议，它必须满足以下条件之一：

1.  **值类型（Value Types）**：所有的 `struct`、`enum` 和元组，如果它们的成员本身也都是 `Sendable` 的，那么它们默认就是 `Sendable` 的。这是因为值类型在传递时会被复制，每个并发域都拥有自己独立的副本，因此不存在共享状态。

    ```swift
    struct User: Sendable { // 显式标记，但通常是自动遵守的
        let id: Int
        let name: String
    }
    ```

2.  **Actor**：`actor` 类型天生就是 `Sendable` 的，因为它们内部的状态受到了 `actor` 隔离机制的保护。

3.  **不可变引用类型（Immutable Reference Types）**：如果一个 `class` 的所有存储属性都是不可变的（即全部用 `let` 定义），并且这些属性的类型也都是 `Sendable` 的，那么这个 `class` 也可以是 `Sendable` 的。

    ```swift
    final class Logger: Sendable { // 必须是 final class
        let module: String
        init(module: String) { self.module = module }
        func log(_ message: String) { print("[\(module)] \(message)") }
    }
    ```

4.  **内部实现线程安全的引用类型**：如果一个 `class` 内部有可变状态，但它通过其他方式（如使用 `NSLock` 或串行队列）保证了线程安全，那么你可以将其标记为 `Sendable`。但你需要对这种安全性负责。

    ```swift
    final class AtomicCounter: Sendable {
        private let lock = NSLock()
        private var value = 0

        func increment() {
            lock.withLock {
                value += 1
            }
        }
    }
    ```

5.  **函数和闭包**：如果一个函数或闭包是 `@Sendable` 的，意味着它捕获的所有值也必须是 `Sendable` 的。

## 2. 严格并发检查带来的警告

当启用严格并发检查后（在 Xcode 中设置为 `Targeted` 或 `Complete`），编译器会像鹰眼一样审查你的代码。如果你试图在并发域之间传递一个不符合 `Sendable` 的类型，编译器会立即发出警告或错误。

**常见警告场景：**

```swift
class UserSettings: ObservableObject {
    // @Published 属性包装器本身不是 Sendable 的
    @Published var score = 0
}

struct ContentView: View {
    @StateObject private var settings = UserSettings()

    var body: some View {
        Text("Score: \(settings.score)")
            .onAppear {
                Task {
                    // 警告：将非 Sendable 的 'self' 捕获到 @Sendable 闭包中
                    // 因为 settings 是 self 的一部分，而 UserSettings 不是 Sendable
                    await updateScore()
                }
            }
    }
    
    func updateScore() async {
        // 假设这是一个访问 settings 的异步函数
        settings.score += 10
    }
}
```

在这个例子中，`Task` 的闭包是一个 `@Sendable` 的上下文，但它捕获了 `self`（`ContentView`），而 `ContentView` 持有一个 `UserSettings` 的实例，`UserSettings` 因为包含 `@Published` 属性而不是 `Sendable` 的。这就构成了跨并发域传递非安全类型的风险。

## 3. 如何解决 `Sendable` 警告？

1.  **将类型重构为 `Sendable`**：
    *   尽可能使用 `struct` 代替 `class`。
    *   如果必须用 `class`，考虑将其改为 `actor` 来保护其可变状态。

2.  **使用 `@MainActor`**：如果你的目标是在主线程上更新 UI，那么将相关的类和方法标记为 `@MainActor` 是最直接的解决方案。这可以确保所有对非 `Sendable` 状态的访问都在同一个并发域（主线程）内进行。

    ```swift
    @MainActor // 将 ViewModel 标记在主线程上
    class UserSettings: ObservableObject {
        @Published var score = 0
    }
    
    // ... 在 View 中使用时，所有对 settings 的访问都会被确保在主线程
    ```

3.  **隔离参数传递**：不要传递整个非 `Sendable` 的对象，只传递你需要的数据（通常是值类型）。

    ```swift
    // 不好的写法
    Task {
        await processSettings(settings)
    }
    
    // 好的写法
    let currentScore = settings.score // 读取值
    Task {
        await processScore(currentScore) // 传递值
    }
    ```

4.  **不安全的变通方法 (`@unchecked Sendable`)**：如果你 100% 确定你的类在并发访问时是安全的，但无法向编译器证明这一点，你可以使用 `@unchecked Sendable` 来压制警告。**这是一个危险的逃生舱，请谨慎使用，因为你亲手关闭了编译器的安全检查。**

    ```swift
    // 只有在你完全理解其后果时才这样做！
    final class MyLegacyClass: @unchecked Sendable {
        // ... 内部有自己的锁来保证线程安全 ...
    }
    ```

理解和遵循 `Sendable` 约束是编写健壮、无数据竞争的 Swift 并发代码的关键。虽然在初期会带来一些挑战，但它最终会极大地提升应用的稳定性和可靠性。
