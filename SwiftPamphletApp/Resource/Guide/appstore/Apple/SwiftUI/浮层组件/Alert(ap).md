# SwiftUI 浮层组件：Alert

在 SwiftUI 中，警告框（Alert）是一种用于向用户显示重要信息或请求确认一个潜在破坏性操作的模态视图。它会中断用户的当前工作流，并要求用户必须做出响应后才能继续。

SwiftUI 通过 `.alert()` 修饰符来呈现警告框，其 API 在 iOS 15 中经历了一次重大的现代化改造。

## 现代用法 (iOS 15+)

从 iOS 15 开始，`.alert()` 修饰符变得更加强大和灵活。它不再依赖于 `Identifiable` 对象，而是直接与一个 `Binding<Bool>` 和一个可选的数据源绑定。

### 1. 基本警告框

最简单的警告框包含一个标题和一个“确定”按钮。

```swift
import SwiftUI

struct BasicAlertExample: View {
    @State private var showAlert = false

    var body: some View {
        Button("显示警告框") {
            showAlert = true
        }
        .alert("重要信息", isPresented: $showAlert) {
            // 这个闭包用于定义警告框中的按钮
            Button("好的") { }
        }
    }
}

#Preview {
    BasicAlertExample()
}
```

在这个例子中：
*   `showAlert` 状态变量控制警告框的显示和隐藏。
*   `.alert()` 修饰符的 `isPresented` 参数与 `$showAlert` 双向绑定。
*   当 `showAlert` 变为 `true` 时，警告框出现。
*   当用户点击“好的”按钮或系统提供的其他关闭方式时，`isPresented` 的值会自动变回 `false`，从而关闭警告框。

### 2. 添加消息和多个按钮

你可以通过 `actions` 和 `message` 闭包来添加更详细的描述和多个操作按钮。

```swift
struct DetailedAlertExample: View {
    @State private var showDeleteAlert = false

    var body: some View {
        Button("删除项目", role: .destructive) {
            showDeleteAlert = true
        }
        .alert(
            "确认删除吗？",
            isPresented: $showDeleteAlert
        ) {
            // Actions 闭包
            Button("删除", role: .destructive) { /* 执行删除操作 */ }
            Button("取消", role: .cancel) { /* 什么也不做 */ }
        } message: {
            // Message 闭包
            Text("这个操作无法撤销。")
        }
    }
}

#Preview {
    DetailedAlertExample()
}
```

*   `actions` 闭包允许你定义多个 `Button`。你可以使用 `.destructive` 和 `.cancel` 等角色（`role`）来让系统应用合适的样式。
*   `message` 闭包允许你添加一段描述性文本，为用户提供更多上下文。

### 3. 绑定到可选数据 (`item`)

当你的警告框需要根据特定的数据项来显示时（例如，删除列表中的某一项），将 `.alert` 绑定到一个可选的状态对象是更推荐的做法。当这个对象不再是 `nil` 时，警告框就会出现。

```swift
struct ItemBasedAlertExample: View {
    struct AlertInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    @State private var alertInfo: AlertInfo?

    var body: some View {
        VStack(spacing: 20) {
            Button("登录失败") {
                alertInfo = AlertInfo(title: "登录失败", message: "用户名或密码错误。")
            }
            Button("网络错误") {
                alertInfo = AlertInfo(title: "网络错误", message: "请检查你的网络连接。")
            }
        }
        .alert(item: $alertInfo) { info in
            // SwiftUI 会将 alertInfo 的值传递给这个闭包
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("确定"))
            )
        }
    }
}
```

这种方式的优势在于：
*   **状态清晰**: `alertInfo` 本身就包含了显示警告框所需的所有数据。
*   **避免多个 `Bool`**: 你不再需要为每种可能的警告框都创建一个独立的 `@State` 布尔值。
*   **自动关闭**: 当你将 `alertInfo` 设置回 `nil` 时，警告框会自动关闭。

## 旧版用法 (iOS 13-14, 已废弃)

在 iOS 15 之前，`.alert(item: ...)` 和 `.alert(isPresented: ...)` 返回的是一个 `Alert` 结构体，而不是一个按钮构建器闭包。这种方式现在已经被废弃，因为它不够灵活，并且与 `confirmationDialog` 的 API 不一致。

```swift
// --- 旧版写法，不推荐 ---
.alert(isPresented: $showAlert) {
    Alert(
        title: Text("标题"),
        message: Text("消息"),
        primaryButton: .destructive(Text("删除")) { /* ... */ },
        secondaryButton: .cancel()
    )
}
```

## 总结

`.alert()` 是 SwiftUI 中用于呈现模态警告、与用户进行关键交互的重要工具。

*   **现代 API (iOS 15+)**: 提供了基于 `Binding<Bool>` 和 `Binding<Identifiable?>` 的两种方式，并使用 `@ViewBuilder` 闭包来构建按钮和消息，更加灵活和强大。
*   **数据驱动**: 将警告框的呈现与应用的状态紧密绑定。
*   **角色与样式**: 利用 `Button` 的 `role`（如 `.destructive`, `.cancel`）来获得平台一致的、具有语义的按钮样式。
*   **优先使用 `item`**: 当警告框的内容依赖于特定数据时，使用 `.alert(item: ...)` 的方式可以让你的状态管理更清晰、更健壮。

在需要确认用户的关键操作或显示不可忽略的重要信息时，合理地使用 `.alert()` 可以有效地防止用户误操作，并提供清晰的反馈。
