# SwiftUI 浮层组件：Sheet

`Sheet` 是 SwiftUI 中用于以模态方式（Modal）呈现新视图的一种核心组件。在 iOS 上，它通常表现为一个从屏幕底部向上滑出的卡片式视图，覆盖在当前内容之上，但通常不会完全遮挡背景。用户可以通过向下滑动手势或点击一个明确的关闭按钮来关闭它。

`.sheet()` 修饰符是实现这一功能的标准方式，它非常适合用于呈现独立的、补充性的任务，如创建新项目、编辑设置或显示详细信息。

## 核心用法

与 SwiftUI 中其他模态视图类似，`.sheet()` 的呈现也是由一个状态绑定来控制的。

### 1. 基于 `isPresented`

通过一个 `Binding<Bool>` 来控制 `Sheet` 的显示和隐藏。

```swift
import SwiftUI

struct BasicSheetExample: View {
    @State private var showSheet = false

    var body: some View {
        Button("显示 Sheet") {
            showSheet = true
        }
        .font(.largeTitle)
        .sheet(isPresented: $showSheet) {
            // 这是当 showSheet 为 true 时要显示的内容
            SheetContentView()
        }
    }
}

struct SheetContentView: View {
    // 使用 @Environment 来获取关闭操作
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("这是一个 Sheet 视图")
                .font(.title)
            Text("你可以向下滑动来关闭它。")
            
            Button("或点击这里关闭") {
                dismiss() // 调用 dismiss 来关闭视图
            }
        }
    }
}

#Preview {
    BasicSheetExample()
}
```

在这个例子中：
*   `showSheet` 状态变量控制 `Sheet` 的生命周期。
*   `.sheet()` 的 `isPresented` 参数与 `$showSheet` 双向绑定。
*   在被呈现的 `SheetContentView` 中，我们注入了 `@Environment(\.dismiss)`。调用 `dismiss()` 是关闭任何模态视图（包括 `sheet`）的**标准、推荐**的方式。它会自动将父视图中的 `isPresented` 绑定设置回 `false`。

### 2. 基于 `item`

当 `Sheet` 的内容依赖于某个特定的数据项时，使用 `.sheet(item: ...)` 是一个更强大、更具 SwiftUI 风格的方式。

```swift
struct ItemBasedSheetExample: View {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
    }
    
    @State private var selectedItem: Item?

    var body: some View {
        VStack(spacing: 20) {
            Button("显示项目 A") { selectedItem = Item(name: "项目 A") }
            Button("显示项目 B") { selectedItem = Item(name: "项目 B") }
        }
        .sheet(item: $selectedItem) { item in
            // SwiftUI 会自动解包 selectedItem 并将其传递给 content 闭包
            ItemDetailView(item: item)
        }
    }
}

struct ItemDetailView: View {
    let item: ItemBasedSheetExample.Item
    var body: some View { Text("详情: \(item.name)").font(.largeTitle) }
}
```

这种方式将 `Sheet` 的呈现与其内容的数据源绑定在了一起，使得状态管理更清晰，并且避免了为不同类型的 `Sheet` 创建多个 `Bool` 状态的麻烦。

## 自定义 `Sheet` 的外观 (iOS 16+)

从 iOS 16 开始，SwiftUI 提供了更丰富的 API 来定制 `Sheet` 的外观，主要是通过 `.presentationDetents()` 修饰符。

### `.presentationDetents()` (高度定制)

这个修饰符允许你定义 `Sheet` 可以停留的几个“档位”（Detents）。

*   `.medium`: 大约占据屏幕一半的高度。
*   `.large`: 完全展开的高度（默认值）。
*   `.fraction(_:)`: 占据屏幕高度的一个特定比例。
*   `.height(_:)`: 一个固定的高度值。

```swift
.sheet(isPresented: $showSheet) {
    MySheetContent()
        // 定义两个档位：中等高度和完全展开
        .presentationDetents([.medium, .large])
}
```

当设置了多个档位后，用户可以通过在 `Sheet` 顶部拖动抓取条（grabber）来在不同高度之间切换。

### 其他呈现相关的修饰符

*   **`.presentationDragIndicator(_:)`**: 控制顶部抓取条的可见性（`.visible` 或 `.hidden`）。
*   **`.presentationCornerRadius(_:)`**: 设置 `Sheet` 的圆角半径。
*   **`.presentationBackground(_:)`**: 设置 `Sheet` 的背景，可以是任何 `ShapeStyle`，包括颜色、渐变或材质。

```swift
.sheet(isPresented: $showSheet) {
    MySheetContent()
        .presentationDetents([.height(200), .medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(25)
        .presentationBackground(.thinMaterial)
}
```

## `.sheet` vs. `.fullScreenCover`

| 特性 | `.sheet` | `.fullScreenCover` |
| :--- | :--- | :--- |
| **外观** | 卡片式，从底部滑出，背景通常部分可见。 | **完全覆盖**整个屏幕。 |
| **交互** | **可手势关闭**（向下滑动）。 | **不可手势关闭**，必须有明确的关闭按钮。 |
| **用途** | 补充性任务、设置、选择器。 | 沉浸式任务、创建新内容、引导流程。 |

## 总结

`.sheet` 是 SwiftUI 中用于呈现模态内容的最常用、最核心的工具之一。

*   **核心用法**: 通过 `isPresented` 或 `item` 绑定来触发。
*   **关闭方式**: 可以通过向下滑动手势，或在代码中调用 `@Environment(\.dismiss)` 来关闭。
*   **高度定制 (iOS 16+)**: `.presentationDetents` 提供了前所未有的、对 `Sheet` 高度的精细控制能力。
*   **场景**: 非常适合用于显示与当前上下文相关的、临时的、补充性的任务界面。

通过熟练运用 `.sheet` 及其相关的呈现修饰符，你可以构建出既符合平台规范又具有丰富交互性的模态体验。
