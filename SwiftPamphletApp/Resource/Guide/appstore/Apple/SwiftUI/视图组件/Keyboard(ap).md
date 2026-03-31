# SwiftUI 中的键盘处理

在移动应用开发中，优雅地处理屏幕键盘的出现和消失是一个至关重要的用户体验环节。SwiftUI 提供了一系列现代化的工具和修饰符，使得键盘管理比以往任何时候都更加简单和声明式。

本指南将涵盖 SwiftUI 中与键盘交互的几个核心方面：焦点管理、键盘类型、提交操作和工具栏。

## 1. 焦点管理 (`@FocusState`)

键盘的出现总是与某个输入视图（如 `TextField` 或 `TextEditor`）获得“焦点”相关联。在 SwiftUI (iOS 15+) 中，`@FocusState` 属性包装器是控制键盘显示和隐藏的**唯一官方推荐方式**。

它允许你以编程方式命令哪个视图应该成为第一响应者，从而弹出键盘，或者让所有视图都失去焦点，从而收起键盘。

```swift
import SwiftUI

enum Field {
    case username, password
}

struct KeyboardFocusExample: View {
    @State private var username = ""
    @State private var password = ""
    // 1. 声明一个 @FocusState 变量
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack {
            TextField("Username", text: $username)
                .focused($focusedField, equals: .username) // 2. 绑定焦点

            SecureField("Password", text: $password)
                .focused($focusedField, equals: .password)

            Button("Sign In") {
                // 3. 通过改变 @FocusState 变量来收起键盘
                focusedField = nil
            }
        }
        .padding()
    }
}

#Preview {
    KeyboardFocusExample()
}
```

在这个例子中，将 `focusedField` 设置为 `nil` 是收起键盘的关键。这是最可靠、最直接的方式。

## 2. 指定键盘类型 (`.keyboardType()`)

为了优化用户的数据输入体验，你应该为 `TextField` 指定最合适的键盘类型。`.keyboardType()` 修饰符允许你从多种预设类型中进行选择。

```swift
Form {
    TextField("Email Address", text: $email)
        .keyboardType(.emailAddress)
    
    TextField("Phone Number", text: $phone)
        .keyboardType(.phonePad)
        
    TextField("Website", text: $website)
        .keyboardType(.URL)
        
    TextField("Number with Decimals", text: $amount)
        .keyboardType(.decimalPad)
}
```

选择正确的键盘类型（例如，为数字输入提供数字键盘）可以显著减少用户的输入错误和操作成本。

## 3. 自定义返回键 (`.submitLabel()`)

键盘右下角的返回键（Return Key）的标签可以被自定义，以更好地反映其上下文中的功能。`.submitLabel()` 修饰符提供了多种预设标签。

*   `.done`
*   `.go`
*   `.send`
*   `.join`
*   `.next`
*   `.search`
*   `.continue`

```swift
TextField("Search...", text: $searchText)
    .submitLabel(.search)
```

## 4. 响应提交操作 (`.onSubmit()`)

当用户点击键盘上的返回键（无论其标签是什么）时，`.onSubmit()` 修饰符允许你触发一个操作。这通常用于处理表单提交、开始搜索或将焦点移动到下一个输入框。

```swift
struct OnSubmitExample: View {
    @FocusState private var focusedField: Field?
    
    var body: some View {
        Form {
            TextField("Username", text: .constant(""))
                .focused($focusedField, equals: .username)
                .submitLabel(.next)

            SecureField("Password", text: .constant(""))
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
        }
        .onSubmit {
            // 根据当前拥有焦点的输入框来决定下一步操作
            switch focusedField {
            case .username:
                focusedField = .password // 切换焦点到密码框
            default:
                print("Form submitted!")
                focusedField = nil // 提交并关闭键盘
            }
        }
    }
}
```

## 5. 键盘工具栏 (`.toolbar()`)

`.toolbar()` 修饰符可以用来在键盘的上方添加一个附件视图（Accessory View），这通常被称为键盘工具栏。这对于提供一些快捷操作（如“完成”、“上一步/下一步”）非常有用。

你需要将 `ToolbarItemGroup` 的 `placement` 参数设置为 `.keyboard`。

```swift
struct KeyboardToolbarExample: View {
    @State private var text = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        TextField("Enter text here", text: $text)
            .focused($isTextFieldFocused)
            .toolbar {
                // 定义一个放置在键盘上方的工具栏项目组
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Copy") { /* ... */ }
                    Button("Paste") { /* ... */ }
                    Spacer() // 将“完成”按钮推到右边
                    Button("Done") {
                        isTextFieldFocused = false // 点击“完成”收起键盘
                    }
                }
            }
            .padding()
    }
}

#Preview {
    KeyboardToolbarExample()
}
```

## 总结

SwiftUI 提供了一整套声明式的 API 来优雅地管理键盘交互，其核心是 `@FocusState`。

*   **显示/隐藏键盘**: 使用 `@FocusState` 属性包装器来以编程方式控制哪个输入框获得焦点，或通过将其设置为 `nil` 来收起键盘。
*   **优化输入**: 使用 `.keyboardType()` 为不同的数据类型提供合适的键盘。
*   **响应提交**: 使用 `.submitLabel()` 自定义返回键的标签，并用 `.onSubmit()` 来处理提交事件，实现流畅的表单导航。
*   **添加快捷操作**: 使用 `.toolbar()` 和 `.keyboard` 位置，可以在键盘上方添加一个方便的工具栏。

通过组合使用这些工具，你可以构建出专业、流畅且用户体验极佳的文本输入界面。
