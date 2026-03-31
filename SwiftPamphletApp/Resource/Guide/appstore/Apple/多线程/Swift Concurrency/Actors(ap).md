# Actors：终结数据竞争的护城河

在多线程编程中，最恐怖的噩梦莫过于**数据竞争 (Data Race)**：两个线程在同一微秒同时修改内存中的同一个变量，导致数据错乱、App 随机且极难复现的崩溃。

以前，我们用加锁 (`NSLock`)、信号量 (`DispatchSemaphore`) 或者串行队列来保护数据，但只要程序员手抖漏写了一处锁，系统就会立刻崩溃。

Swift 5.5 引入了一种全新的引用类型 —— **`actor`**。它在**编译器层面**强制消灭了数据竞争。

## 1. 什么是 actor？

你可以把 `actor` 当作一个带有**绝对隔离结界**的 `class`。
*   它和 `class` 一样是引用类型，存储在堆区。
*   **它的超能力是**：在同一时间，**绝对只允许一个任务 (线程) 访问它的内部可变状态**。如果有别的线程想访问，就必须排队等候！

## 2. 基础实战演示

假设我们有一个银行账户的类。如果在旧的多线程环境下：

```swift
// 旧时代的炸弹：如果有 10 个线程同时调用 deposit 和 withdraw，余额一定会错乱甚至崩溃！
class BankAccount {
    var balance: Double = 0.0
    func deposit(amount: Double) { balance += amount }
}
```

现在，我们把 `class` 改成 `actor`：

```swift
// 新时代的堡垒
actor BankAccount {
    var balance: Double = 0.0
    
    // actor 内部的方法互相调用是畅通无阻的
    func deposit(amount: Double) { 
        balance += amount 
    }
    
    func withdraw(amount: Double) {
        if balance >= amount { balance -= amount }
    }
}
```

## 3. Actor 的外部隔离规则 (Actor Isolation)

当你试图在 `actor` 的**外部**（比如在 ViewController 里）去调用它时，编译器会施加极其严格的限制：

```swift
let myAccount = BankAccount()

Task {
    // ❌ 编译报错：不能直接访问 actor 的可变状态！
    // print(myAccount.balance)
    
    // ❌ 编译报错：不能直接调用 actor 的方法！
    // myAccount.deposit(amount: 100)
    
    // ✅ 正确做法：必须使用 await！
    // await 意味着：“我知道 myAccount 可能正在处理别人的交易，我愿意在结界外面排队挂起等待，直到它空闲了再执行我的操作。”
    await myAccount.deposit(amount: 100)
    let currentBalance = await myAccount.balance
    print(currentBalance)
}
```
这就是 `actor` 保证安全的魔法：它强迫外界的所有访问必须穿过一层 `await` 的异步边界。

## 4. 非隔离方法 (nonisolated)

如果 actor 内部有一些方法完全不碰 `var` 变量，只是计算一下常量或者打印日志，你可以给它加上 `nonisolated` 修饰符。外界调用这种方法时就**不需要**加 `await` 也不用排队了。

```swift
actor BankAccount {
    let accountName = "主账号" // 常量是天生线程安全的
    
    // 明确告诉编译器：这方法不碰危险数据，大家可以随便调，不用排队！
    nonisolated func getAccountName() -> String {
        return accountName
    }
}
```

## 5. MainActor (主演员)

在所有的 actor 中，有一个系统内置的、极其特殊的全局单例 actor，叫作 **`@MainActor`**。

它的核心作用是：**确保被它标记的代码，绝对、一定、永远只在主线程 (UI 线程) 上执行！**

```swift
// 给 ViewModel 整个类打上标记
@MainActor
class UserViewModel: ObservableObject {
    @Published var name: String = ""
    
    func fetchUser() async {
        // 在后台进行耗时的网络请求
        let resultName = try? await Network.downloadName()
        
        // 因为类被 @MainActor 标记了，当你给 name 赋值时，
        // 系统绝对保证这行代码是跑在主线程的！再也不会报 "必须在主线程更新UI" 的紫雾警告了！
        self.name = resultName ?? "未知" 
    }
}
```
如果你开发的是纯 SwiftUI 或现代架构应用，给所有的 ViewModel 和 UI 视图逻辑打上 `@MainActor` 是最安逸的保命绝招。
