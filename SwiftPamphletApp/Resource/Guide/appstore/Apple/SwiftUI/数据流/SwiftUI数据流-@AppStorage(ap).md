# SwiftUI 数据流：@AppStorage

`@AppStorage` 是 SwiftUI 提供的一个属性包装器，它专门用于将属性的值与 `UserDefaults` 进行绑定。这使得在应用中持久化存储简单的用户偏好设置（如用户名、是否开启某功能、主题选择等）变得异常简单和直观。

## 核心作用

`@AppStorage` 就像是 `@State` 和 `UserDefaults` 的结合体。它具备以下特点：

1.  **自动持久化**: 当你修改被 `@AppStorage` 包装的属性时，它的新值会自动被写入 `UserDefaults`。
2.  **自动加载**: 当视图创建时，`@AppStorage` 会自动从 `UserDefaults` 中读取之前存储的值来初始化属性。如果 `UserDefaults` 中没有对应的值，它会使用你提供的默认值。
3.  **驱动 UI 更新**: 和 `@State` 一样，当 `@AppStorage` 包装的属性值发生变化时，它会自动触发依赖该属性的视图进行刷新。

## 基本用法

要使用 `@AppStorage`，你需要在声明属性时提供两个参数：

*   一个字符串 `key`，用于在 `UserDefaults` 中唯一标识这个值。
*   一个默认值，当 `UserDefaults` 中找不到对应的 `key` 时使用。

```swift
import SwiftUI

struct AppStorageExample: View {
    // 将 username 属性与 UserDefaults 中键为 "username" 的值绑定
    @AppStorage("username") private var username: String = "Anonymous"
    
    // isDarkMode 属性与键为 "isDarkMode" 的值绑定
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("欢迎, \(username)!")
                .font(.title)
            
            // TextField 可以直接修改 @AppStorage 变量
            TextField("输入你的名字", text: $username)
                .textFieldStyle(.roundedBorder)
            
            Toggle(isOn: $isDarkMode) {
                Text("开启深色模式")
            }
        }
        .padding()
        // 整个视图的配色方案会根据 isDarkMode 的值动态改变
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    AppStorageExample()
}
```

在这个例子中：
1.  `username` 和 `isDarkMode` 两个属性被 `@AppStorage` 包装。这意味着它们的值会在应用的不同次启动之间被保留下来。
2.  你可以像使用 `@State` 变量一样，通过 `$` 符号创建双向绑定，将它们与 `TextField` 和 `Toggle` 等控件连接起来。
3.  当用户在 `TextField` 中输入名字或切换 `Toggle` 时，对应的值会立即被存入 `UserDefaults`，并且 UI 也会实时更新（例如，欢迎语和整个屏幕的配色方案）。
4.  下次用户打开应用时，`username` 和 `isDarkMode` 会自动从 `UserDefaults` 恢复上次的值。

## 支持的数据类型

`@AppStorage` 支持所有 `UserDefaults` 原生支持的数据类型，包括：

*   `Bool`
*   `Int`
*   `Double`
*   `String`
*   `URL`
*   `Data`

此外，它还特别支持符合 `RawRepresentable` 协议且其 `RawValue` 为 `Int` 或 `String` 的枚举类型。

### 示例：存储枚举

```swift
enum Theme: String {
    case light, dark, system
}

struct ThemeSelectionView: View {
    // 将 theme 属性与 UserDefaults 绑定
    // AppStorage 会自动存储枚举的 rawValue (即字符串)
    @AppStorage("selectedTheme") private var theme: Theme = .system

    var body: some View {
        Picker("选择主题", selection: $theme) {
            Text("浅色").tag(Theme.light)
            Text("深色").tag(Theme.dark)
            Text("跟随系统").tag(Theme.system)
        }
        .pickerStyle(.segmented)
        .padding()
    }
}
```

## 与 `@State` 的选择

*   **`@State`**: 用于管理**临时的、非持久化**的视图状态。当视图被销毁或应用关闭时，`@State` 变量的值会丢失。它适用于控制 UI 的瞬时状态，如一个弹窗是否显示、一个动画是否正在进行等。

*   **`@AppStorage`**: 用于管理需要**跨应用启动持久化**的用户偏好设置。它本质上是 `UserDefaults` 的一个便捷、响应式的接口。

简单来说，如果一个值需要“被记住”，即使用户关闭了应用再重新打开，也应该保持不变，那么就应该使用 `@AppStorage`。

## 注意事项

*   **性能**: `UserDefaults` 是为存储少量、简单的数据而设计的。不要用它来存储大量或复杂的数据（如图片、模型对象数组等），这会影响应用的启动速度和性能。对于复杂的数据持久化，应考虑使用 Core Data, SwiftData, 或直接写入文件。
*   **安全性**: `UserDefaults` 是以未加密的 plist 文件形式存储在设备上的，不适合存储任何敏感信息（如密码、API 密钥等）。对于敏感数据，应使用 Keychain。
*   **数据迁移**: 如果你改变了 `key` 或者存储的数据类型，`@AppStorage` 不会自动处理数据迁移。你需要手动编写代码来处理旧版本数据的读取和转换。

## 总结

`@AppStorage` 是 SwiftUI 数据流系统中一个极其方便的工具，它极大地简化了与 `UserDefaults` 的交互。通过将用户偏好设置声明为 `@AppStorage` 属性，你可以轻松实现数据的持久化、自动加载和 UI 的自动更新，而无需编写任何手动的读写 `UserDefaults` 的代码。
