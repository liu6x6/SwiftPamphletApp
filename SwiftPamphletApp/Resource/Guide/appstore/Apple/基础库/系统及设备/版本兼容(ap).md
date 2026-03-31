# Swift 中的版本兼容与 API 可用性检查

在 iOS 和 macOS 开发中，每年 Apple 都会推出新的系统版本并引入大量新 API（如 iOS 17 的 SwiftData，iOS 13 的 SwiftUI）。为了让你的应用既能使用最新的炫酷功能，又能在老用户的旧设备上正常运行不崩溃，你必须熟练掌握**可用性检查 (Availability Checking)**。

## 1. \`#available\`：运行时的代码分支检查

这是最常用的语法，用于在普通的函数逻辑中判断当前运行设备的系统版本。

```swift
func setupUI() {
    // 检查当前设备是否是 iOS 15 及以上，或者 macOS 12 及以上
    // "*" 表示如果是其他未指定的平台（如 watchOS），默认允许通过
    if #available(iOS 15.0, macOS 12.0, *) {
        // 这段代码只有在符合条件的设备上才会被执行
        let config = UIButton.Configuration.filled() // iOS 15 新 API
        button.configuration = config
    } else {
        // Fallback: 针对老设备使用旧的 API
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
    }
}
```

从 Swift 5.6 开始，还引入了 **\`#unavailable\`** 语法，逻辑正好相反，常用于专门为老设备写补丁：
```swift
if #unavailable(iOS 15.0) {
    // 专门为低于 iOS 15 的设备执行的旧逻辑
}
```

## 2. \`@available\`：声明属性、方法或类的兼容性

如果你写了一个自定义的视图或函数，它内部大量使用了 iOS 16 的新 API。你不想在里面写满 \`if #available\`，你可以直接把这个**函数或类整体标记为仅限新系统可用**。

```swift
// 告诉编译器：只有 iOS 16+ 的设备才能调用这个视图
@available(iOS 16.0, macOS 13.0, *)
struct ModernChartView: View {
    var body: some View {
        // 这里可以肆无忌惮地使用 iOS 16 的 Charts 框架
        Chart { ... }
    }
}

// 在父视图调用时，编译器会强迫你加上 if #available
struct ParentView: View {
    var body: some View {
        if #available(iOS 16.0, *) {
            ModernChartView()
        } else {
            Text("您的系统版本过低，无法查看图表")
        }
    }
}
```

## 3. \`@available\` 的进阶用法：废弃与重命名提示

作为库的开发者，当你想要重构代码并废弃一个旧方法时，\`@available\` 提供了极其优雅的警告机制，帮助其他开发者迁移。

```swift
// 1. 标记为已废弃 (Deprecated)
// 别人调用这个方法时，Xcode 会报黄色的警告
@available(*, deprecated, message: "请使用新的 fetchUser(id:) 方法")
func getUserData() { }

// 2. 标记为已重命名 (Renamed)
// Xcode 会直接提供一个 "Fix" 按钮，点击自动把旧代码改成新代码！
@available(*, deprecated, renamed: "NetworkManager.fetchUser")
func oldFetchMethod() { }

// 3. 标记为绝对不可用 (Obsoleted)
// 别人调用这个方法时，Xcode 会直接报错阻止编译
@available(iOS, obsoleted: 14.0, message: "iOS 14 后此方法被彻底移除")
func someVeryOldMethod() { }
```

## 4. 总结

*   使用 \`if #available\` 来处理具体的代码逻辑分叉。
*   使用 \`@available\` 来对整个类或方法进行宏观的平台版本限制。
*   **兼容性陷阱**：如果你在 \`if #available\` 的新系统分支里**强制解包**了某些返回可选值的系统 API，一定要小心。因为有时候在某些特定的 Beta 版系统中，Apple 可能会临时修改 API 行为。
