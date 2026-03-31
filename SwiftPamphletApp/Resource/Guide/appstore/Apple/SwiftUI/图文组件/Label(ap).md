# SwiftUI 中的 Label 视图

`Label` 是 SwiftUI 中一个用于将文本和图标组合在一起的便捷视图。它的设计初衷是为了以一种标准化的、具有良好语义的方式来展示图标和文字的配对，这在列表、按钮、菜单等多种 UI 场景中都非常常见。

## 核心优势

你可能会想，用一个 `HStack` 包含一个 `Image` 和一个 `Text` 不是也能实现同样的效果吗？是的，但 `Label` 提供了几个关键优势：

1.  **语义化**: 使用 `Label` 能清晰地向 SwiftUI 表明，这个图标和文本是一个逻辑上的整体，它们共同构成一个标签。这有助于提升应用的可访问性（Accessibility）。
2.  **样式自适应**: `Label` 的外观可以根据其所在的容器自动调整。例如，在某些上下文中，一个 `Label` 可能只显示图标，而在另一些上下文中，它可能只显示文本。
3.  **代码简洁**: `Label("Settings", systemImage: "gear")` 显然比 `HStack { Image(systemName: "gear"); Text("Settings") }` 更简洁、更具可读性。

## 基本用法

创建 `Label` 非常简单，最常用的初始化方法是同时提供一个标题文本和一个 SF Symbol 的名称。

```swift
import SwiftUI

struct BasicLabelExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("接收邮件", systemImage: "envelope.fill")
            Label("发送邮件", systemImage: "paperplane.fill")
            Label("收藏夹", systemImage: "star.fill")
        }
        .font(.title)
    }
}

#Preview {
    BasicLabelExample()
}
```

## 自定义 `Label` 的内容

`Label` 的初始化方法非常灵活，它允许你使用任何自定义的 `View` 作为其 `title` 和 `icon`。

```swift
struct CustomLabelExample: View {
    var body: some View {
        Label {
            // Title View
            Text("John Appleseed")
                .font(.headline)
                .foregroundColor(.primary)
        } icon: {
            // Icon View
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 44, height: 44)
                .foregroundColor(.blue)
        }
    }
}

#Preview {
    CustomLabelExample()
}
```

这个版本的 `Label` 使用了尾随闭包语法，让你能够完全控制标题和图标的外观，例如字体、颜色、尺寸等。

## `Label` 的样式：`.labelStyle()`

`.labelStyle()` 修饰符是 `Label` 最强大的特性之一。它允许你改变 `Label` 的整体外观，而无需修改 `Label` 本身的定义。SwiftUI 提供了一些内置的样式：

*   `.automatic`: 默认样式，由 `Label` 所在的容器决定。
*   `.titleAndIcon`: 同时显示标题和图标（这是最常见的样式）。
*   `.iconOnly`: 只显示图标。
*   `.titleOnly`: 只显示标题。

### 示例：在不同容器中自动改变样式

将 `Label` 放置在 `NavigationView` 的 `toolbar` 中，你会发现它会自动只显示图标，这就是 `.automatic` 样式的威力。

```swift
struct LabelStyleExample: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("默认样式:")
                Label("Settings", systemImage: "gear")
                    .labelStyle(.automatic)
                
                Text("只显示图标:")
                Label("Settings", systemImage: "gear")
                    .labelStyle(.iconOnly)
                
                Text("只显示标题:")
                Label("Settings", systemImage: "gear")
                    .labelStyle(.titleOnly)
            }
            .font(.title)
            .navigationTitle("Label 样式")
            .toolbar {
                // 在 Toolbar 中，.automatic 样式会自动变为 .iconOnly
                Label("Add Item", systemImage: "plus")
            }
        }
    }
}

#Preview {
    LabelStyleExample()
}
```

### 创建自定义 `LabelStyle`

与 `ButtonStyle` 类似，你也可以创建自己的 `LabelStyle` 来实现完全自定义的外观。

```swift
// 自定义一个将图标放在文字上方的样式
struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon
                .font(.largeTitle)
            configuration.title
                .font(.caption)
        }
    }
}

struct CustomLabelStyleExample: View {
    var body: some View {
        HStack(spacing: 40) {
            Label("Home", systemImage: "house.fill")
            Label("Search", systemImage: "magnifyingglass")
            Label("Profile", systemImage: "person.fill")
        }
        .labelStyle(VerticalLabelStyle())
    }
}

#Preview {
    CustomLabelStyleExample()
}
```

在这个例子中，我们定义了 `VerticalLabelStyle`，它使用一个 `VStack` 来垂直排列图标和标题。然后，我们通过 `.labelStyle(VerticalLabelStyle())` 将这个样式应用到一个 `HStack` 中的所有 `Label` 上，轻松地创建了一个类似 `TabBar` 的布局。

## 总结

`Label` 是一个语义化、高效且可定制的视图，专门用于展示图标和文本的组合。它的核心优势在于：

*   **代码简洁**：用一行代码替代 `HStack` + `Image` + `Text`。
*   **语义清晰**：向系统和可访问性功能表明图标和文本的关联性。
*   **样式灵活**：通过 `.labelStyle()` 修饰符，可以轻松地在只显示图标、只显示文本或图文共存之间切换，甚至可以创建完全自定义的布局。

在构建列表、菜单、按钮和工具栏等需要图文并茂的场景时，应优先考虑使用 `Label`。
