# SwiftUI 中的 Form 表单

`Form` 是 SwiftUI 中一个专门用于构建数据输入界面的容器视图，例如应用的设置页面、用户个人资料编辑、联系人表单等。它会自动根据所在的平台（iOS, macOS 等）应用合适的、符合系统规范的样式来组织其内部的控件。

## 核心作用

`Form` 的主要作用是为其中的输入控件（如 `TextField`, `Toggle`, `Picker`, `Slider` 等）提供一个具有平台特色的分组和布局样式。

*   在 **iOS** 上，`Form` 通常表现为带有分组样式（inset grouped）的 `List`，行与行之间有分隔线，并且整体有圆角和边距。
*   在 **macOS** 上，`Form` 会自动对齐标签和控件，创建出整洁、规范的偏好设置窗口布局。

使用 `Form` 而不是普通的 `VStack` 或 `List` 来组织输入控件，可以确保你的应用在视觉上与系统原生应用（如“设置”）保持一致，提供更自然的用户体验。

## 基本用法

你只需要将你的输入控件放置在一个 `Form` 闭包内部即可。

```swift
import SwiftUI

struct SimpleFormExample: View {
    @State private var username: String = ""
    @State private var notificationsEnabled: Bool = true
    @State private var theme: String = "Light"
    
    let themes = ["Light", "Dark", "System"]

    var body: some View {
        NavigationView {
            Form {
                // 第一个分组
                Section(header: Text("个人信息")) {
                    TextField("用户名", text: $username)
                    Toggle("接收通知", isOn: $notificationsEnabled)
                }
                
                // 第二个分组
                Section(header: Text("外观设置")) {
                    Picker("主题", selection: $theme) {
                        ForEach(themes, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                // 提交按钮
                Section {
                    Button("保存设置") {
                        // 在这里处理保存逻辑
                        print("设置已保存: \(username), \(notificationsEnabled), \(theme)")
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SimpleFormExample()
}
```

在这个例子中：
1.  我们使用 `Form` 作为根容器。
2.  `Section` 用于将表单内容分成逻辑上的组。每个 `Section` 都可以有一个可选的 `header` 和 `footer` 来提供额外的上下文信息。
3.  我们将 `TextField`, `Toggle`, 和 `Picker` 等输入控件放置在 `Section` 内部。
4.  注意观察，在 iOS 预览中，`Form` 会自动应用分组列表样式，而在 macOS 预览中，它会自动对齐 `TextField` 的标签和输入框。

## `Form` 与 `List` 的区别

`Form` 和 `List` 在 iOS 上看起来非常相似，但它们的语义和用途是不同的。

*   **`List`**: 主要用于**展示数据**。它的设计目的是显示一列动态的、可能很长的数据行，并针对滚动性能进行了优化。虽然 `List` 也可以包含输入控件，但它的主要职责是呈现信息。

*   **`Form`**: 主要用于**收集输入**。它的设计目的是组织一组有限的、用于数据输入的控件。它会自动应用适合数据录入的平台特定样式。

**经验法则**：如果你的界面主要是为了让用户输入或修改数据（如设置页面），请使用 `Form`。如果你的界面主要是为了展示一列数据（如邮件列表、联系人列表），请使用 `List`。

## 自定义 `Form` 的样式

### `.formStyle()` (iOS 16+)

从 iOS 16 开始，你可以使用 `.formStyle()` 修饰符来更精确地控制表单的外观。

*   `.automatic`: 默认样式。
*   `.grouped`: 分组样式。
*   `.insetGrouped`: 带边距的分组样式（这是 iOS 上的默认样式）。

```swift
Form {
    // ... 表单内容
}
.formStyle(.grouped) // 使用紧凑的分组样式
```

### `Section` 的页眉和页脚

`Section` 的 `header` 和 `footer` 可以是任何 `View`，这为你提供了丰富的自定义空间。

```swift
Section(header: Text("通知设置").font(.headline), 
        footer: Text("开启后，你将收到关于新消息的推送通知。你可以随时在系统设置中更改此选项。").font(.caption)) {
    Toggle("接收通知", isOn: $notificationsEnabled)
}
```

### 禁用控件

使用 `.disabled()` 修饰符可以禁用 `Form` 中的任何控件或整个 `Section`。

```swift
Section(header: Text("高级设置")) {
    Toggle("启用开发者模式", isOn: $devMode)
    
    // 只有当开发者模式开启时，这个按钮才可用
    Button("清除缓存") {
        // ...
    }
    .disabled(!devMode)
}
```

## 总结

`Form` 是 SwiftUI 中构建结构化数据输入界面的标准方式。它通过自动应用平台特定的样式，简化了创建设置页面、个人信息表单等通用界面的过程。

关键点：

*   使用 `Form` 来组织**输入控件**。
*   使用 `Section` 来将表单内容进行**逻辑分组**。
*   `Form` 会自动适应不同平台（iOS, macOS）的 UI 规范。
*   不要将 `Form` 用于纯粹的数据展示，那种场景下应该使用 `List`。

通过熟练使用 `Form` 和 `Section`，你可以快速构建出既美观又符合系统设计规范的数据输入界面。
