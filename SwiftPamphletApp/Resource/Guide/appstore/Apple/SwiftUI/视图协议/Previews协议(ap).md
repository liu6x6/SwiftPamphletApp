# SwiftUI 预览协议与宏：`PreviewProvider` & `#Preview`

在 SwiftUI 中，预览（Preview）是开发流程中一个不可或缺的、革命性的功能。它允许你在 Xcode 的画布上实时地查看和交互你的视图，而无需编译和运行整个应用程序。这极大地加速了 UI 的迭代和调试速度。

这个功能的核心由 `PreviewProvider` 协议（旧版）和 `#Preview` 宏（新版，iOS 17+）提供支持。

## `#Preview` 宏 (iOS 17+, Xcode 15+)

从 Xcode 15 开始，`#Preview` 宏成为了创建预览的首选方式。它更简洁、更强大，并且可以直接在你的主应用目标中使用，无需创建额外的 target。

你只需要在任何文件的任何位置，输入 `#Preview`，并在其闭包中返回你想要预览的视图即可。

```swift
import SwiftUI

struct MyCardView: View {
    var title: String
    var value: String

    var body: some View {
        VStack {
            Text(title).font(.headline)
            Text(value).font(.largeTitle)
        }
        .padding()
        .background(Color.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }
}

// 使用 #Preview 宏
#Preview {
    MyCardView(title: "当前速度", value: "120 km/h")
}
```

### `#Preview` 的高级用法

`#Preview` 宏非常灵活，允许你进行多种配置。

#### 命名预览

你可以为预览指定一个名字，方便在预览画布中区分。

```swift
#Preview("默认卡片") {
    MyCardView(title: "默认", value: "N/A")
}
```

#### 预览多个视图

你可以在一个 `#Preview` 块中返回多个视图，它们会在画布中并排或堆叠显示。

```swift
#Preview {
    VStack(spacing: 20) {
        MyCardView(title: "心率", value: "80 BPM")
        MyCardView(title: "步数", value: "10,450")
    }
    .padding()
}
```

#### 预览不同的设备和配置

`#Preview` 可以模拟不同的设备、方向和系统设置。

```swift
#Preview("iPhone 14 Pro Max, Dark Mode") {
    MyCardView(title: "电量", value: "85%")
        .previewDevice("iPhone 14 Pro Max")
        .preferredColorScheme(.dark)
}
```

#### 预览 `UIKit` / `AppKit` 视图

`#Preview` 同样可以用于预览旧框架的视图和视图控制器，极大地便利了混合开发。

```swift
import UIKit

#Preview {
    let label = UILabel()
    label.text = "Hello from UIKit!"
    label.font = .systemFont(ofSize: 32)
    return label
}
```

## `PreviewProvider` 协议 (旧版)

在 Xcode 15 之前，`PreviewProvider` 是创建预览的唯一方式。它仍然可以在新版 Xcode 中使用，并且对于理解预览的演进很有帮助。

要使用它，你需要：
1.  创建一个独立的结构体。
2.  让它遵循 `PreviewProvider` 协议。
3.  实现一个名为 `previews` 的静态计算属性，该属性返回 `some View`。

```swift
import SwiftUI

struct MyButton: View {
    var body: some View {
        Button("Tap Me") { }
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

// 1. 创建一个遵循 PreviewProvider 的结构体
struct MyButton_Previews: PreviewProvider {
    // 2. 实现 previews 静态属性
    static var previews: some View {
        // 3. 返回你想要预览的视图
        MyButton()
    }
}
```

### `PreviewProvider` 的配置

与 `#Preview` 宏使用修饰符不同，`PreviewProvider` 通过在 `previews` 属性内部返回的视图上应用修饰符来进行配置。

```swift
struct MyButton_Previews: PreviewProvider {
    static var previews: some View {
        Group { // 使用 Group 来组合多个预览
            // 预览1: 默认外观
            MyButton()
                .previewDisplayName("默认按钮")
            
            // 预览2: 深色模式
            MyButton()
                .preferredColorScheme(.dark)
                .previewDisplayName("深色模式")
            
            // 预览3: 在特定设备上
            MyButton()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (3rd generation)"))
                .previewDisplayName("iPhone SE")
        }
    }
}
```

## `#Preview` vs. `PreviewProvider`

| 特性 | `#Preview` (新) | `PreviewProvider` (旧) |
| :--- | :--- | :--- |
| **语法** | 简洁的宏语法，`#Preview { ... }`。 | 需要定义一个完整的 `struct`。 |
| **位置** | 可以放在文件的任何位置。 | 必须是顶层结构体。 |
| **可访问性** | 默认 `internal`，可以访问文件内的 `private` 类型。 | 必须是 `public` 或 `internal`，难以访问 `private` 类型。 |
| **配置** | 直接在宏上传递参数，如 `#Preview("Name")`。 | 在返回的视图上使用 `.previewDisplayName()` 等修饰符。 |
| **推荐用法** | **强烈推荐**用于所有 Xcode 15+ 的项目。 | 用于维护旧项目，或在特定需要 `static` 上下文的场景。 |

## 总结

SwiftUI 的预览功能是其核心优势之一，它将 UI 开发从一个缓慢的“编码-编译-运行”循环，转变为一个即时的、可视化的、交互式的过程。

*   对于 **Xcode 15 及更高版本**，应始终优先使用 `#Preview` 宏。它更简洁、更灵活，并且与应用的 target 无缝集成。
*   `PreviewProvider` 协议作为其前身，在维护旧代码库时仍然有用，但新项目应避免使用。

善用预览功能，为你的视图创建多种不同的测试场景（如不同的设备、数据状态、配色方案、本地化语言等），将极大地提升你的开发效率和代码质量。
