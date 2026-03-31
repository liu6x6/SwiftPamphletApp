# CurrentValueSubject：有记忆的信号塔

在 Combine 中，\`Subject\` 是一种特殊的 Publisher，它不仅能向外发送数据，还允许你**通过代码手动向其内部注入 (\`send\`) 数据**。
\`CurrentValueSubject\` 是最常用的两种 Subject 之一（另一种是 \`PassthroughSubject\`）。

它的核心特征是：**它拥有状态（记忆）。它总是保存着最新被发送的那一个值。**

如果你熟悉 RxSwift，它等价于 \`BehaviorSubject\`。

## 1. 核心特性

1.  **必须有初始值**：在创建 \`CurrentValueSubject\` 时，你必须给它塞一个初始数据。
2.  **新订阅者福利**：当一个新的订阅者（Subscriber）接入时，它**立刻**会收到当前保存在 Subject 里的那个最新的值。
3.  **直接读写状态**：你可以通过 \`.value\` 属性，像访问普通变量一样，随时同步地读取或修改它的当前值（修改 \`.value\` 会自动触发一次广播）。

## 2. 基础实战演示

```swift
import Combine

// 1. 初始化，指定数据类型为 String，错误类型为 Never，初始值为 "未命名"
let userNameSubject = CurrentValueSubject<String, Never>("未命名")

// 2. 随时随地读取当前值 (不需要订阅也能读！)
print("当前内存里的值是: \(userNameSubject.value)") // 输出: 未命名

// 3. 第一个订阅者接入
let sub1 = userNameSubject.sink { print("Sub 1 收到: \($0)") }
// 接入瞬间，立即输出: Sub 1 收到: 未命名

// 4. 发送新数据 (两种写法等价)
userNameSubject.send("Alice")
// 或者： userNameSubject.value = "Bob"
// 此时 sub1 会依次收到 "Alice" 和 "Bob"

// 5. 第二个订阅者迟到了，现在才接入
let sub2 = userNameSubject.sink { print("Sub 2 收到: \($0)") }
// 它不仅能收到以后的数据，而且在接入瞬间，它会立刻收到当前最新的记忆！
// 输出: Sub 2 收到: Bob
```

## 3. 为什么需要 CurrentValueSubject？

在 SwiftUI 中，\`@State\` 和 \`@Published\` 底层其实都带有一种“记住当前值”的能力。但在 ViewModel 内部处理复杂的业务逻辑流时，如果不用这两个宏，你就需要手动使用 \`CurrentValueSubject\`。

### 场景：管理全局的登录状态

假设你需要一个全局的身份管理器，它需要告诉全 App 目前有没有人登录：

```swift
class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    // 内部私有的 Subject，维护着 "是否已登录" 的状态，初始为 false
    private let loggedInSubject = CurrentValueSubject<Bool, Never>(false)
    
    // 对外暴露的 Publisher，外界只能订阅，不能修改（防止被别的类乱发 send 信号）
    // eraseToAnyPublisher() 是隐藏具体 Subject 类型的绝招
    var isLoggedIn: AnyPublisher<Bool, Never> {
        return loggedInSubject.eraseToAnyPublisher()
    }
    
    // 对外暴露一个同步读取状态的便捷方法
    var currentLoginState: Bool {
        return loggedInSubject.value
    }
    
    func performLogin() {
        // 网络请求成功后...
        // 核心：修改状态并向全 App 广播！
        loggedInSubject.send(true) 
    }
}
```

任何在 App 启动后才初始化的控制器（比如某个深层级的个人中心页），只要一订阅 \`isLoggedIn\`，就会立刻被告知当前的真实状态，而不用傻等下一次用户点击登录按钮。这就是 \`CurrentValueSubject\` 的魅力。
