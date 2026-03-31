# SwiftUI 浮层组件：HUD (Heads-Up Display)

HUD (Heads-Up Display) 是一种非侵入式的、临时的信息展示方式。它通常以一个小浮层（Toast 或 Banner）的形式出现在屏幕的顶部或底部，用于向用户提供简短的状态反馈，例如“已保存”、“已复制到剪贴板”、“网络连接已断开”等。HUD 的特点是它会在显示几秒钟后自动消失，不会打断用户的当前工作流。

**SwiftUI 本身并没有提供一个名为 `HUD` 的标准组件**。然而，构建一个自定义的 HUD 是一个非常好的练习，它综合运用了 `ZStack`, `@State`, `transition`, `animation` 和 `DispatchQueue` 等多种 SwiftUI 的核心概念。

## 构建自定义 HUD 的核心思路

1.  **UI 层面**: 使用 `ZStack` 将 HUD 视图**覆盖**在你的主内容视图之上。HUD 本身通常是一个带有背景材质、图标和文本的 `HStack` 或 `VStack`。
2.  **状态管理**: 使用一个 `@State` 变量（例如 `showHUD`）来控制 HUD 的可见性。
3.  **动画**: 使用 `.transition()` 修饰符来定义 HUD 出现和消失的动画（例如，从顶部滑入/滑出并带有透明度变化）。
4.  **自动消失**: 当触发 HUD 显示时，使用 `DispatchQueue.main.asyncAfter` 来安排一个延迟任务，在几秒钟后将控制可见性的状态变量设置回 `false`。

## 示例：创建一个简单的顶部 HUD

让我们来构建一个可复用的 `HUD` 视图和一个用于管理其呈现的 `ViewModifier`。

### 1. 创建 HUD 视图

```swift
import SwiftUI

// HUD 的内容视图
struct HUDContent: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
            Text(message)
                .font(.headline)
        }
        .foregroundColor(.primary)
        .padding()
        .background(.thinMaterial, in: Capsule())
    }
}
```

这个视图定义了 HUD 的外观：一个带有图标和文本的胶囊形状浮层。

### 2. 创建 HUD 修饰符

为了方便地在任何视图上呈现 HUD，我们创建一个 `ViewModifier`。

```swift
// 用于呈现 HUD 的 ViewModifier
struct HUDModifier<HUD: View>: ViewModifier {
    @Binding var isPresented: Bool
    let hud: HUD
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content // 原始视图内容
            
            if isPresented {
                hud
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // 3 秒后自动消失
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
            }
        }
    }
}

// 为 View 创建一个便捷的扩展方法
extension View {
    func hud<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        self.modifier(HUDModifier(isPresented: isPresented, hud: content()))
    }
}
```

在这个修饰符中：
*   它使用 `ZStack` 将 HUD (`hud`) 覆盖在原始视图 (`content`) 之上。
*   `isPresented` 绑定控制了 HUD 是否被渲染。
*   `.transition` 定义了 HUD 从顶部滑入并淡入的出现动画，以及相反的消失动画。
*   `.onAppear` 是实现自动消失的关键。当 HUD 出现时，我们安排一个 3 秒后的任务，该任务会在主线程上执行，并以动画的形式将 `isPresented` 设置回 `false`。

### 3. 在视图中使用

现在，我们可以在任何视图上方便地使用 `.hud()` 修饰符了。

```swift
struct HUDExample: View {
    @State private var showSuccessHUD = false
    @State private var showErrorHUD = false

    var body: some View {
        VStack(spacing: 30) {
            Button("保存成功") {
                withAnimation {
                    showSuccessHUD = true
                }
            }
            
            Button("发生错误") {
                withAnimation {
                    showErrorHUD = true
                }
            }
        }
        // 应用 HUD 修饰符
        .hud(isPresented: $showSuccessHUD) {
            HUDContent(message: "已保存", systemImage: "checkmark.circle.fill")
        }
        .hud(isPresented: $showErrorHUD) {
            HUDContent(message: "无法连接", systemImage: "xmark.circle.fill")
        }
    }
}

#Preview {
    HUDExample()
}
```

## 总结

虽然 SwiftUI 没有内置的 `HUD` 组件，但通过组合其核心功能，我们可以轻松地构建出一个功能完善、可复用的自定义 HUD 系统。

*   **UI**: 使用 `ZStack` 进行覆盖，使用 `HStack`/`VStack` 和背景材质构建 HUD 外观。
*   **状态**: 使用 `@State` 布尔值来控制可见性。
*   **动画**: 使用 `.transition` 来定义出现和消失的动画。
*   **自动消失**: 使用 `DispatchQueue.main.asyncAfter` 来实现延时关闭。
*   **封装**: 将逻辑封装在 `ViewModifier` 中，并通过 `View` 扩展提供一个简洁的 API，是在整个应用中复用该功能的最佳实践。

这种模式不仅限于 HUD，它可以被应用于任何需要在主界面之上临时呈现、并自动消失的浮层通知。
