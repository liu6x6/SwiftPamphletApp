# PassthroughSubject：无记忆的传声筒

作为 Combine 中两大核心 \`Subject\` 之一（另一个是 \`CurrentValueSubject\`），**\`PassthroughSubject\`** 扮演的是一个纯粹的**“广播大喇叭”或“传声筒”**的角色。

## 1. 核心特性：阅后即焚，没有记忆

与 \`CurrentValueSubject\` 形成鲜明对比的是：
*   **不需要初始值**：创建时不用塞入任何数据。
*   **没有记忆 (No State)**：它内部不保存你发送过的任何数据，也没有 \`.value\` 属性供你读取。
*   **过时不候**：如果一个订阅者（Subscriber）在数据发送**之后**才接入订阅，它**绝对收不到**之前发过的数据。它只能老老实实等下一次广播。

## 2. 基础实战演示

```swift
import Combine

// 1. 初始化，声明它将发送 String 信号，绝不报错 (Never)
let notificationSubject = PassthroughSubject<String, Never>()

// 2. 发送第一条消息
// 注意！此时没有任何人订阅它，这条消息发送后就像对着空气大喊，直接消散在风中了。
notificationSubject.send("系统启动了")

// 3. 第一个订阅者接入
let sub1 = notificationSubject.sink { print("张三听到了: \($0)") }

// 4. 发送第二条消息
notificationSubject.send("马上要发红包了")
// 输出: 张三听到了: 马上要发红包了

// 5. 第二个订阅者接入
let sub2 = notificationSubject.sink { print("李四听到了: \($0)") }

// 6. 发送第三条消息
notificationSubject.send("活动结束")
// 输出: 张三听到了: 活动结束
// 输出: 李四听到了: 活动结束
```

## 3. 最经典的应用场景

\`PassthroughSubject\` 是替换传统 iOS 开发中 **Delegate (代理)**、**Target-Action (按钮点击)** 和 **NotificationCenter (通知)** 的绝佳武器。

因为它完美契合了这些行为的本质：**它们都是瞬时的事件 (Event)，而不是持续的状态 (State)。**

### 场景 A：ViewModel 向 View 传递瞬时动作 (如弹窗、警告)

ViewModel 通常用 \`@Published\` (底层带记忆) 来驱动 UI 绑定（比如用户名、列表数据）。但如果 ViewModel 想告诉 View：“弹出一个支付失败的警告框”，如果你用 \`@Published var showError: Bool\`，会导致状态极其难管理（弹完还要手动设为 false）。

正确做法是用 \`PassthroughSubject\` 传递瞬时的“触发信号”。

```swift
class CheckoutViewModel {
    // 专门用来发送警告信号的广播
    let alertSignal = PassthroughSubject<String, Never>()
    
    func pay() {
        // 支付失败，直接向空中大喊一声！
        alertSignal.send("余额不足，请充值")
    }
}

// 在 ViewController 或 SwiftUI 中监听
viewModel.alertSignal.sink { errorMessage in
    // 收到信号的一瞬间，把 UIAlertController 弹出来。
    // 因为没有记忆，就算界面刷新，也不会重复弹窗。
    showAlert(message: errorMessage)
}
```

### 场景 B：自定义的按钮点击流

你可以用它来收集分散在屏幕各处的用户点击行为，汇聚成一条事件流，方便做防抖或数据埋点。

```swift
class MyButton: UIButton {
    let tapSubject = PassthroughSubject<Void, Never>()
    
    // ... 在按钮被点击的底层 target-action 方法中：
    @objc func tapped() {
        tapSubject.send(()) // 发出一个没有具体值的虚空信号
    }
}
```

## 总结
*   **状态与数据** (如：用户资料、当前音量、列表数组) -> 用 \`CurrentValueSubject\` (或 \`@Published\`)。
*   **动作与事件** (如：点击了按钮、发生了一次报错、触发了弹窗) -> 用 \`PassthroughSubject\`。
