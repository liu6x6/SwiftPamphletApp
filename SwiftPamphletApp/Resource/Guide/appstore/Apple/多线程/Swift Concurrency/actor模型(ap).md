# 使用 Actor 保护可变状态

在并发编程中，最危险、最常见的 Bug 来源就是“数据竞争（Data Race）”。当多个线程在同一时间尝试读取和写入同一个内存地址（例如一个类的属性）时，就会发生数据竞争，这通常会导致难以预测的崩溃和数据损坏。

在 Swift Concurrency 出现之前，我们通常使用锁（`NSLock`）、信号量（`DispatchSemaphore`）或串行队列（`DispatchQueue`）来保护共享状态，但这些方法不仅繁琐，而且极易出错。

**`actor`** 是 Swift Concurrency 引入的一种全新的引用类型，它在语言层面提供了一种优雅且安全的方式来解决数据竞争问题。

## 1. Actor 的核心机制：隔离与排队

`actor` 的核心思想是**“隔离（Isolation）”**。一个 `actor` 会将它管理的所有可变状态（即它的属性）隔离起来，形成一个独立的“孤岛”。

- **内部同步访问**：在 `actor` 内部，你可以像访问普通 `class` 的属性一样，同步地、直接地访问自己的属性和方法。
- **外部异步访问**：任何来自 `actor` 外部的代码，如果想访问 `actor` 的属性或调用其方法，**必须**使用 `await` 关键字。这个 `await` 意味着，外部的访问请求会被放入一个队列中，`actor` 会按顺序、一次一个地处理这些请求。这就从根本上杜绝了多个线程同时修改状态的可能性。

```swift
// 定义一个管理银行账户的 Actor
actor BankAccount {
    private(set) var balance: Double

    init(initialDeposit: Double) {
        self.balance = initialDeposit
    }

    // 存款方法
    func deposit(amount: Double) {
        // 在 actor 内部，可以直接修改状态
        balance += amount
    }

    // 取款方法
    func withdraw(amount: Double) throws -> Double {
        if balance < amount {
            throw BankError.insufficientFunds
        }
        balance -= amount
        return balance
    }
}

// 在外部使用 Actor
func performTransactions() async {
    let account = BankAccount(initialDeposit: 1000)

    // 从外部访问 actor 的方法，必须使用 await
    await account.deposit(amount: 500)

    do {
        let newBalance = try await account.withdraw(amount: 200)
        // 注意：即使是读取属性，也需要 await
        print("Current balance: \(await account.balance)") // 输出: Current balance: 1300.0
    } catch {
        print(error)
    }
}
```

## 2. `nonisolated`：逃出隔离

有时候，`actor` 的某些属性或方法是不可变的（例如一个常量 `let`），或者它们本身就是线程安全的。在这种情况下，强制要求外部调用者使用 `await` 会带来不必要的性能开销。

你可以使用 `nonisolated` 关键字来标记这些属性或方法，允许外部代码同步地、无需 `await` 地访问它们。

```swift
actor UserProfile {
    let userID: String // 不可变常量
    var lastLogin: Date

    init(userID: String) {
        self.userID = userID
        self.lastLogin = Date()
    }

    func updateLoginTime() {
        lastLogin = Date()
    }

    // userID 是常量，是线程安全的，可以标记为 nonisolated
    nonisolated func getGreeting() -> String {
        // 注意：在 nonisolated 方法内部，不能访问隔离的属性，比如 lastLogin
        // return "Hello, user \(userID). Your last login was \(lastLogin)" // 编译错误！
        return "Hello, user \(userID)"
    }
}

func greetUser() async {
    let profile = UserProfile(userID: "u-12345")

    // 访问 nonisolated 方法，无需 await
    let greeting = profile.getGreeting()
    print(greeting)

    // 访问隔离的方法，仍需 await
    await profile.updateLoginTime()
}
```

## 3. `@MainActor`：UI 更新的守护神

`@MainActor` 是一个特殊的全局 `actor`，它代表了应用程序的主线程。在 iOS/macOS 开发中，所有对 UI 的更新都必须在主线程上进行。

通过将一个类、结构体或函数标记为 `@MainActor`，你可以向编译器保证，它的所有代码都将在主线程上执行。这彻底消除了手动调用 `DispatchQueue.main.async` 的需要，让 UI 更新变得前所未有的安全和简单。

```swift
import SwiftUI

// 将整个 ViewModel 标记为在主 Actor 上运行
@MainActor
class ContentViewModel: ObservableObject {
    // @Published 属性的更新会自动触发 UI 刷新，因此必须在主线程
    @Published var fetchedData: String = "Loading..."

    func fetchDataFromServer() {
        // 开启一个后台任务去执行网络请求
        Task {
            let data = await downloadData()
            
            // 当后台任务完成后，回到这里时，
            // 由于整个类被标记为 @MainActor，
            // 这行代码会自动在主线程上执行，无需手动切换！
            self.fetchedData = data
        }
    }
    
    private func downloadData() async -> String {
        // 这是一个运行在后台线程的耗时操作
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return "Hello from server!"
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        Text(viewModel.fetchedData)
            .onAppear {
                viewModel.fetchDataFromServer()
            }
    }
}
```

通过 `@MainActor`，Swift Concurrency 将 UI 更新的线程安全提升到了一个新的高度，极大地减少了因线程错误导致的界面卡顿或崩溃问题。
