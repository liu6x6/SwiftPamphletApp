# SwiftUI 修饰符：.redacted() 隐私与占位符

`.redacted(reason:)` 是 SwiftUI 中一个非常实用的修饰符，它允许我们将视图的一部分或全部渲染为占位符（placeholder）样式。这个功能主要有两个核心用途：

1.  **加载状态**：在数据从网络加载或数据库读取时，显示一个骨架屏（Skeleton Screen），提升用户体验。
2.  **隐私保护**：在特定场景下（如应用进入后台时），隐藏敏感信息。

## 基本用法

`.redacted` 修饰符可以应用于任何视图层级。当应用于一个容器视图时，它会将其内部的所有子视图都渲染为占位符。

```swift
import SwiftUI

struct UserProfileView: View {
    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading) {
                Text("John Appleseed")
                    .font(.headline)
                Text("john.appleseed@example.com")
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

struct RedactedExampleView: View {
    var body: some View {
        UserProfileView()
            .redacted(reason: .placeholder)
    }
}

#Preview {
    RedactedExampleView()
}
```

在上面的例子中，`UserProfileView` 的所有内容（包括图片和文字）都会被渲染成灰色的占位符形状，模拟数据正在加载的视觉效果。

## `RedactionReasons`

`.redacted(reason:)` 修饰符接受一个 `RedactionReasons` 类型的参数。这是一个 `OptionSet`，意味着你可以组合多个原因。常见的值包括：

*   `.placeholder`: 最常用的原因，用于创建骨架屏或占位符 UI。
*   `.privacy`: 用于在需要保护用户隐私时隐藏内容。例如，当 App 可能在截屏或屏幕录制中暴露时。

## 模拟加载状态

`.redacted` 与 `@State` 结合使用，可以轻松地创建动态的加载效果。

```swift
struct LoadingUserProfileView: View {
    @State private var isLoading = true

    var body: some View {
        UserProfileView()
            .redacted(reason: isLoading ? .placeholder : []) // 当 isLoading 为 true 时 redacted
            .onAppear {
                // 模拟网络请求
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isLoading = false
                }
            }
    }
}

#Preview {
    LoadingUserProfileView()
}
```

在这个例子中：
1.  `isLoading` 状态变量控制着是否应用 `.placeholder` 原因。
2.  视图出现时，`isLoading` 默认为 `true`，所以 `UserProfileView` 显示为占位符。
3.  2秒后，`isLoading` 变为 `false`，`.redacted` 的 `reason` 变为空数组 `[]`，占位符效果消失，真实内容显示出来。

## 使用 `.unredacted()`

有时，你可能希望在一个被隐藏的视图层级中，让某个特定的子视图保持可见。这时，`.unredacted()` 修饰符就派上用场了。

```swift
struct PartiallyRedactedView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("用户资料")
                .font(.largeTitle)
                .unredacted() // 即使父视图被 redacted，此标题也保持可见
            
            UserProfileView()
        }
        .padding()
        .redacted(reason: .placeholder)
    }
}

#Preview {
    PartiallyRedactedView()
}
```

在这个例子中，尽管整个 `VStack` 都被应用了 `.redacted(reason: .placeholder)`，但由于标题 `Text("用户资料")` 上加了 `.unredacted()`，它将不会被渲染成占位符，而是正常显示。

## 隐私保护

除了作为占位符，`.redacted` 也是一个重要的隐私工具。例如，你可以监听场景阶段（`scenePhase`），当应用进入非活跃状态时，自动隐藏敏感内容。

```swift
struct SecureContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        SensitiveDataView()
            // 当 App 不在前台时，应用 .privacy redacted
            .redacted(reason: scenePhase == .active ? [] : .privacy)
    }
}

struct SensitiveDataView: View {
    var body: some View {
        VStack {
            Text("信用卡号: 1234-5678-9012-3456")
            Text("余额: $9,999.99")
        }
        .padding()
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    SecureContentView()
}
```

当 `SecureContentView` 所在的 App 切换到后台时，`scenePhase` 会变为 `.inactive` 或 `.background`，`.privacy` 原因会被应用，从而在应用切换器（App Switcher）的快照中隐藏用户的敏感财务信息。

## 总结

`.redacted()` 是一个多功能的修饰符，它提供了一种优雅、统一的方式来处理加载状态和保护用户隐私。通过结合 `@State` 和 `.unredacted()`，你可以精确地控制视图的占位符行为，从而构建出更专业、用户体验更佳的 SwiftUI 应用。
