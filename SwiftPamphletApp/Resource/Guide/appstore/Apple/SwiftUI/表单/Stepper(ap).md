# SwiftUI 中的 Stepper 步进器

`Stepper` 是 SwiftUI 中一个用于让用户以固定的步长增加或减少一个数值的控件。它通常表现为一对“+”和“-”按钮，旁边带有一个描述性的标签。`Stepper` 非常适合用于需要精确、离散调整数值的场景，例如购物应用中的商品数量、设置中的字体大小或游戏中的生命值。

## 核心用法：绑定、范围和步长

创建一个 `Stepper` 的基本要素与 `Slider` 类似，但它处理的是离散的步进，而不是连续的范围。

1.  **`value`**: 一个到数值类型（如 `Int` 或 `Double`）状态变量的双向绑定 (`Binding`)。
2.  **`in`**: 一个闭区间范围（`ClosedRange`），定义了值的上限和下限。
3.  **`step`** (可选): 每次点击按钮时增加或减少的量，默认为 1。
4.  **`label`**: 一个描述 `Stepper` 用途的视图。

```swift
import SwiftUI

struct BasicStepperExample: View {
    // 1. 状态变量存储步进器的值
    @State private var quantity: Int = 1

    var body: some View {
        VStack {
            Text("当前数量: \(quantity)")
                .font(.title)
            
            // 2. 创建 Stepper
            Stepper(
                "商品数量",
                value: $quantity, // 绑定到状态变量
                in: 1...10,       // 允许的数量范围是 1 到 10
                step: 1           // 每次增减 1
            )
        }
        .padding()
    }
}

#Preview {
    BasicStepperExample()
}
```

在这个例子中：
*   `quantity` 状态变量存储了当前的商品数量。
*   `Stepper` 通过 `$quantity` 与该状态双向绑定。当用户点击“+”或“-”按钮时，`quantity` 的值会相应地增加或减少（但不会超出 `1...10` 的范围），并自动刷新 `Text` 的显示。
*   `"商品数量"` 是 `Stepper` 的标签，它向用户说明了这个控件的用途。

## 自定义标签

`Stepper` 的标签不仅仅能是简单的文本，它可以是任何 `View`。这允许你创建更丰富、更具信息量的步进器。

```swift
struct CustomLabelStepperExample: View {
    @State private var fontSize: CGFloat = 16

    var body: some View {
        Stepper(value: $fontSize, in: 12...24) {
            // 使用自定义的 Label 作为 Stepper 的标签
            Label("字体大小: \(Int(fontSize)) pt", systemImage: "textformat.size")
        }
        .padding()
    }
}

#Preview {
    CustomLabelStepperExample()
}
```

在这个例子中，我们使用了一个 `Label` 视图作为 `Stepper` 的标签，它同时显示了图标和当前的字体大小值，提供了比简单文本更丰富的视觉反馈。

## 响应值的变化

与 `Slider` 类似，`Stepper` 也提供了一个 `onEditingChanged` 闭包，用于在用户与控件交互时获得通知。

```swift
struct EditingChangedStepperExample: View {
    @State private var score: Int = 0

    var body: some View {
        Stepper("分数: \(score)", value: $score, in: 0...100) {
            // onEditingChanged 闭包会在每次值发生变化后被调用
        } onEditingChanged: { isEditing in
            // 对于 Stepper，isEditing 通常在点击时瞬间变为 true 然后变回 false
            // 我们可以利用这个时机来执行操作
            if !isEditing {
                print("分数已更新为: \(score)")
                // 在这里可以触发游戏逻辑、保存分数等
            }
        }
        .padding()
    }
}

#Preview {
    EditingChangedStepperExample()
}
```

对于 `Stepper` 来说，`onEditingChanged` 的行为是：每次用户点击“+”或“-”按钮，值发生变化后，闭包会被调用，`isEditing` 参数会短暂地变为 `true` 然后立即变回 `false`。因此，检查 `!isEditing` 可以确保你在值更新**之后**执行操作。

## `Stepper` vs. `Slider`

虽然两者都用于选择数值，但它们的适用场景有明显区别：

*   **`Stepper`**: 用于**离散的、精确的**数值调整。用户可以精确地控制增加或减少一个或多个固定的步长。它非常适合用于选择数量、次数等整数或固定间隔的浮点数。
    *   *示例*: 商品数量、游戏生命值、字体大小。

*   **`Slider`**: 用于**连续的、大致的**数值调整。用户可以在一个范围内自由地、平滑地选择一个值，但很难精确地停在某个具体的小数值上。它适合用于调整那些不需要绝对精确的模拟量。
    *   *示例*: 音量、亮度、颜色饱和度。

在设计界面时，根据用户需要调整的数值是离散的还是连续的，来选择合适的控件。

## 总结

`Stepper` 是一个简单而直观的控件，为用户提供了一种精确控制数值增减的方式。

*   **核心**: 通过与数值类型的 `@State` 变量进行双向绑定来工作。
*   **控制**: 使用 `in` 参数限制范围，使用 `step` 参数定义增减的粒度。
*   **标签**: 可以使用任何 `View` 作为其标签，以提供清晰的上下文说明。
*   **场景**: 最适合用于需要精确、步进式调整的数值，如数量或设置等级。

在需要用户以固定步长调整数值的任何场景下，`Stepper` 都是一个功能强大且用户熟悉的选择。
